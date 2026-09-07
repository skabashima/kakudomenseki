extends SceneTree
## 展開図が ほんとうに その 立体に 折り上がるかを 数えて 見る。
##   godot --headless --path . -s tests/net_check.gd
##
## 見た目の アニメだけ 作ると、閉じていない 形でも「それらしく」動いて しまう。
## ★ 実際に まちがえた: 正八面体を 三角形 8 枚の まっすぐな 帯に したら、
##   帯は 6 枚で ひとまわり 閉じて しまい、7 枚目と 8 枚目が 前の 面に
##   重なって いた。絵は それらしいのに 立体に なっていない。
##
## 見るところ:
##   1. t = 0 は 展開図(ぜんぶ 平ら)
##   2. t = 1 で 頂点が ちょうど その 立体の 数に 重なる
##   3. どの 辺も ちょうど 2 つの 面で 共有される(すきま も 重なりも ない)
##   4. 立体に なった とき、面が つぶれていない

var fails: Array = []


func _init() -> void:
	var by_solid := {}
	for net in NetDefs.all():
		var name := String(net["solid"])
		by_solid[name] = int(by_solid.get(name, 0)) + 1
		_check(net)
	var parts := PackedStringArray()
	for name in by_solid:
		parts.append("%s %d" % [name, int(by_solid[name])])
	print("展開図 %d とおり ― %s" % [NetDefs.all().size(), " / ".join(parts)])
	if fails.is_empty():
		print("NET CHECK OK: %d とおり ぜんぶ 立体に 閉じる" % NetDefs.all().size())
		quit(0)
	else:
		for f in fails:
			print("FAIL: " + str(f))
		print("NET CHECK FAILED: %d 件" % fails.size())
		quit(1)


func _check(net: Dictionary) -> void:
	var id := String(net["id"])
	var flat: Array = NetDefs.fold(net, 0.0)
	for f in flat:
		for p in f:
			if absf((p as Vector3).z) > 0.0001:
				fails.append("%s: t=0 なのに 平らでない" % id)
				return

	var solid: Array = NetDefs.fold(net, 1.0)
	var scale := _size(solid)
	if scale <= 0.0:
		fails.append("%s: 立体の 大きさが 0" % id)
		return
	var eps := scale * 0.02

	# 頂点を まとめる(近い ものは 同じ 頂点)
	var verts: Array = []
	var ids: Array = []
	for f in solid:
		var row: Array = []
		for p in f:
			var v: Vector3 = p
			if is_nan(v.x) or is_nan(v.y) or is_nan(v.z):
				fails.append("%s: 座標が 数に なっていない" % id)
				return
			var found := -1
			for i in verts.size():
				if (verts[i] as Vector3).distance_to(v) < eps:
					found = i
					break
			if found < 0:
				verts.append(v)
				found = verts.size() - 1
			row.append(found)
		ids.append(row)
	if verts.size() != int(net["verts"]):
		fails.append("%s(%s): 頂点が %d こ。%d こに ならないと 閉じていない" % [
			id, String(net["solid"]), verts.size(), int(net["verts"])])

	# 辺は どれも 2 つの 面で 共有される
	var edges := {}
	for row in ids:
		var n: int = row.size()
		for i in n:
			var a: int = row[i]
			var b: int = row[(i + 1) % n]
			if a == b:
				fails.append("%s: 面が つぶれている" % id)
				return
			var key := "%d-%d" % [mini(a, b), maxi(a, b)]
			edges[key] = int(edges.get(key, 0)) + 1
	if edges.size() != int(net["edges"]):
		fails.append("%s(%s): 辺が %d 本。%d 本に ならないと 閉じていない" % [
			id, String(net["solid"]), edges.size(), int(net["edges"])])
	for key in edges:
		if int(edges[key]) != 2:
			fails.append("%s: 辺 %s を つかう 面が %d つ(2 つで ないと 閉じない)" % [
				id, key, int(edges[key])])
			return


func _size(faces: Array) -> float:
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for f in faces:
		for p in f:
			var v: Vector3 = p
			lo = Vector3(minf(lo.x, v.x), minf(lo.y, v.y), minf(lo.z, v.z))
			hi = Vector3(maxf(hi.x, v.x), maxf(hi.y, v.y), maxf(hi.z, v.z))
	return (hi - lo).length()
