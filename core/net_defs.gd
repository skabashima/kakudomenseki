class_name NetDefs
## 展開図と、それが 立ち上がって 立体に なる 折り方。
##
## 面を 平らな ところ(z = 0)に ならべた ものが 展開図。面ごとに
## 「親の 面」「親と つながる ちょうつがい(辺)」「折る 角度」を 持たせて、
## 親から 順に 回すと 立体に なる。t = 0 で 展開図、t = 1 で 立体。
##
## 折る 角度は 立体ごとに 決まっている:
##   角柱   … となりの 側面へ 折る 角は 底面の 外角(180° − 内角)。底面と 側面は 90°
##   角錐   … 側面を 起こす 角は arccos(−m ÷ s)
##             (m = 底面の 中心から その 辺までの 長さ、s = その 側面の 高さ)。
##             正四面体なら arccos(−1/3) = 109.47°
##   正八面体 … どの 辺も 同じ。180° − 二面角(109.47°) = 70.53° = arccos(1/3)
##
## ★ 帯を まっすぐ 8 枚 つないでも 正八面体には ならない。
##   6 枚で ひとまわりして 元に もどって しまう(帯は 6 枚で 閉じる)。
##   帯 6 枚 + ふた 2 枚 が 正しい。ここは 実際に まちがえた ところなので、
##   折り上がりが 閉じているかを tests/net_check.gd が 毎回 数えて 見張る。

## 円柱と 円錐は、まるい ぶんを 24 に 分けた 角柱・角錐として 折る。
## こうすると 丸める ための 特別な しくみが いらず、ほかの 展開図と 同じ
## しかけ(と 同じ 検査)で 立ち上がる。round が true の ものは
## 分けた 線を うすく 描いて、見た目を 曲面に 近づける。

const OCTA_ANGLE := 1.2309594173408    # acos(1/3)  正八面体の 折り角


## クイズが 使う 展開図。中学受験で 出る 立体を、
## 「同じ 立体でも ひらき方が いろいろ ある」ところまで ふくめて ならべる。
## ★ 立方体の 展開図は 11 とおり ある ―― 手で 書き写すのでは なく、
##   立体の ほうから ひらいて 作る(_enumerate)。だから 数を ふやしても
##   ぜんぶ「ほんとうに その 立体に なる」ことが 保証される。
##
## 立体ごとに [3D の 面, 名まえ, id, 何とおり 作るか]。やさしい 順
const PLAN := [
	["cube", "立方体", 11],
	["box_tall", "直方体", 10],
	["box_flat", "直方体", 8],
	["prism3", "三角柱", 8],
	["prism3r", "三角柱", 8],
	["prism4", "四角柱", 8],
	["prism5", "五角柱", 6],
	["prism6", "六角柱", 6],
	["tetra", "正四面体", 2],
	["pyr3", "三角錐", 4],
	["pyr4", "四角錐", 8],
	["pyr5", "五角錐", 6],
	["pyr6", "六角錐", 6],
	["octa", "正八面体", 8],
]

## 作った ものを おぼえておく(タイトルや 解放画面から 何度も 呼ばれる)
static var _all_cache: Array = []


static func all() -> Array:
	if not _all_cache.is_empty():
		return _all_cache
	var groups: Array = []
	for row in PLAN:
		var key := String(row[0])
		groups.append(_enumerate(_solid(key), String(row[1]), key, int(row[2])))
	# 円柱・円錐は ひらき方が ほぼ 1 つ。見なれた 形(長方形 + 円 / おうぎ形 + 円)を
	# 手で 作った ものを つかう
	groups.append([round_prism(2.2, 5.0)])
	groups.append([round_pyramid(2.0, 6.0)])
	# ★ 立体ごとに かためて 出すと、はじめの 11 問が ぜんぶ 立方体に なって
	#   考えずに 答えられて しまう。立体を 1 つずつ 順ぐりに 取り出して まぜる
	var out: Array = []
	var round_i := 0
	var left := true
	while left:
		left = false
		for g in groups:
			var group: Array = g
			if round_i < group.size():
				out.append(group[round_i])
				left = true
		round_i += 1
	_all_cache = out
	return out


## id から 立体の 3D の 面を 作る
static func _solid(key: String) -> Array:
	match key:
		"cube": return _prism3d(_rect(4.0, 4.0), 4.0)
		"box_tall": return _prism3d(_rect(4.0, 2.6), 5.4)
		"box_flat": return _prism3d(_rect(5.0, 3.2), 2.0)
		"prism3": return _prism3d(_regular(3, 4.0), 5.0)
		"prism3r": return _prism3d([Vector2(0, 0), Vector2(4.0, 0), Vector2(0, 3.0)], 4.5)
		"prism4": return _prism3d(_regular(4, 3.4), 5.0)
		"prism5": return _prism3d(_regular(5, 3.0), 4.6)
		"prism6": return _prism3d(_regular(6, 2.6), 4.4)
		"tetra": return _pyramid3d(_regular(3, 5.0), 4.0824829046386)
		"pyr3": return _pyramid3d(_regular(3, 4.6), 5.6)
		"pyr4": return _pyramid3d(_regular(4, 4.0), 4.4)
		"pyr5": return _pyramid3d(_regular(5, 3.2), 4.6)
		"pyr6": return _pyramid3d(_regular(6, 2.8), 4.6)
		_: return _octa3d(3.2)


static func _rect(w: float, d: float) -> Array:
	return [Vector2(-w * 0.5, -d * 0.5), Vector2(w * 0.5, -d * 0.5),
		Vector2(w * 0.5, d * 0.5), Vector2(-w * 0.5, d * 0.5)]


## ---- 問題(e23)が つかう、番号の ならびが 決まった 展開図 ----
## クイズの ならびは 立体から 作るので 面の 順が 変わりうる。
## 問題文が「1 の 辺」のように 番号で さす ものは、ここの 決まった 形を つかう

## 正四面体 ― 大きな 三角形を 中点で 4 つに 分けた かたち。
## 面は [まん中, 側面 0, 側面 1, 側面 2] の 順
static func tetra_fixed() -> Dictionary:
	return pyramid(_regular(3, 5.0), 4.0824829046386, "正四面体", "tetra_fixed",
		"大きな 三角形を 4 つに 分けた かたち")


## 立方体 ― 十字の かたち
static func cube_fixed() -> Dictionary:
	return cube_net([Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(2, 0),
		Vector2i(0, 1), Vector2i(0, -1)], "cube_fixed", "十字の かたち")


## 正八面体 ― 帯 6 枚 + ふた 2 枚
static func octa_fixed() -> Dictionary:
	return octa(3.4)


static func by_id(id: String) -> Dictionary:
	for n in all():
		if String(n["id"]) == id:
			return n
	return {}


## 折り上がった ときの 面ごとの 3D の 点。t = 0 で 展開図、t = 1 で 立体
static func fold(net: Dictionary, t: float) -> Array:
	var faces: Array = net["faces"]
	var cache: Array = []
	cache.resize(faces.size())
	var out: Array = []
	for i in faces.size():
		var xf := _xform(net, i, t, cache)
		var pts: Array = []
		for p in faces[i]:
			var p2: Vector2 = p
			pts.append(xf * Vector3(p2.x, p2.y, 0.0))
		out.append(pts)
	return out


## 面 i を 立てる 変換。親から 順に かけていく
static func _xform(net: Dictionary, i: int, t: float, cache: Array) -> Transform3D:
	if cache[i] != null:
		return cache[i]
	var parent: int = int(net["parent"][i])
	if parent < 0:
		cache[i] = Transform3D.IDENTITY
		return cache[i]
	var tp := _xform(net, parent, t, cache)
	var hinge: Array = net["hinge"][i]
	var a2: Vector2 = hinge[0]
	var b2: Vector2 = hinge[1]
	# 子の 面が ちょうつがいの 左に くるように そろえる。
	# こうすると 右ねじの 回転が いつも「起き上がる」向きに なる
	if (b2 - a2).cross(_center(net["faces"][i]) - a2) < 0.0:
		var sw := a2
		a2 = b2
		b2 = sw
	var a3: Vector3 = tp * Vector3(a2.x, a2.y, 0.0)
	var b3: Vector3 = tp * Vector3(b2.x, b2.y, 0.0)
	var axis := (b3 - a3).normalized()
	var basis := Basis(axis, float(net["angle"][i]) * t)
	cache[i] = Transform3D(basis, a3 - basis * a3) * tp
	return cache[i]


static func _center(pts: Array) -> Vector2:
	var c := Vector2.ZERO
	for p in pts:
		c += p as Vector2
	return c / float(maxi(1, pts.size()))


# =========================================================
# 立体を ひらいて 展開図に する
#
# 面の つながりを 木に して、親から 子へ 順に 平らに たおす。
# 木の 選び方を 変えると、同じ 立体から ちがう 展開図が 出る
# (立方体は 11 とおり ある)。重なった ものは すてる。
# =========================================================

## 立体から 展開図を want まいまで 作る。同じ 形は 1 つに まとめる
static func _enumerate(faces3: Array, solid_name: String, key: String,
		want: int) -> Array:
	var adj := _adjacency(faces3)
	var verts := _count_verts(faces3)
	var edges := _count_edges(faces3)
	var out: Array = []
	var seen := {}
	var rng := RandomNumberGenerator.new()
	# 種を 固定する。毎回 同じ ならびに ならないと、どの 展開図を 当てたかの
	# 記録が つぎに 開いた ときに ずれる
	rng.seed = hash(key)
	var tries := 0
	while out.size() < want and tries < 400:
		tries += 1
		var net := _unfold(faces3, _tree(adj, rng))
		if net.is_empty():
			continue
		var sig := _signature(net["faces"])
		if seen.has(sig):
			continue
		seen[sig] = true
		net["id"] = "%s_%d" % [key, out.size()]
		net["solid"] = solid_name
		net["hint"] = _describe(net["faces"])
		net["verts"] = verts
		net["edges"] = edges
		out.append(net)
	return out


## 面どうしの となり(辺を 共有する 相手)
static func _adjacency(faces3: Array) -> Array:
	var adj: Array = []
	for i in faces3.size():
		adj.append([])
	for i in faces3.size():
		for j in range(i + 1, faces3.size()):
			var e := _common_edge(faces3[i], faces3[j])
			if e.is_empty():
				continue
			(adj[i] as Array).append({"to": j, "edge": e})
			(adj[j] as Array).append({"to": i, "edge": e})
	return adj


## 2 つの 面が 共有する 辺(3D の 2 点)。無ければ 空
static func _common_edge(f1: Array, f2: Array) -> Array:
	var same: Array = []
	for p in f1:
		for q in f2:
			if (p as Vector3).distance_to(q as Vector3) < 0.0001:
				same.append(p)
				break
	if same.size() == 2:
		return same
	return []


## 面の つながりを 木に する。
##
## ★ 「その 面の となりを まとめて つなぐ」やり方では だめ。
##   立方体だと 台の 面に となり 4 枚が いっぺんに つき、いつも 十字の
##   仲間に なって しまう ―― 400 回 ためして 1 とおりしか 出なかった。
##   つながっている 辺の 中から 1 本ずつ でたらめに 選んで のばすこと。
static func _tree(adj: Array, rng: RandomNumberGenerator) -> Array:
	var n := adj.size()
	var parent: Array = []
	var via: Array = []
	for i in n:
		parent.append(-1)
		via.append([])
	var root := rng.randi_range(0, n - 1)
	var seen := {root: true}
	var frontier: Array = []
	for link in adj[root]:
		frontier.append({"from": root, "link": link})
	while not frontier.is_empty():
		var k := rng.randi_range(0, frontier.size() - 1)
		var pick: Dictionary = frontier[k]
		frontier.remove_at(k)
		var link2: Dictionary = pick["link"]
		var to: int = int(link2["to"])
		if seen.has(to):
			continue
		seen[to] = true
		parent[to] = int(pick["from"])
		via[to] = link2["edge"]
		for nx in adj[to]:
			if not seen.has(int((nx as Dictionary)["to"])):
				frontier.append({"from": to, "link": nx})
	return [parent, via, root]


## 木の とおりに ひらいて 2D に する。重なったら 空を かえす
static func _unfold(faces3: Array, tree: Array) -> Dictionary:
	var parent: Array = tree[0]
	var via: Array = tree[1]
	var root: int = tree[2]
	var n := faces3.size()
	var faces2: Array = []
	var hinge: Array = []
	var angle: Array = []
	faces2.resize(n)
	hinge.resize(n)
	angle.resize(n)
	faces2[root] = _flatten(faces3[root])
	hinge[root] = []
	angle[root] = 0.0
	var todo: Array = []
	for i in n:
		if i != root:
			todo.append(i)
	var guard := 0
	while not todo.is_empty() and guard < n * n + 8:
		guard += 1
		var left: Array = []
		for i in todo:
			var pi: int = int(parent[i])
			if pi < 0:
				return {}
			if faces2[pi] == null:
				left.append(i)
				continue
			var e3: Array = via[i]
			var placed := _place_child(faces3[pi], faces2[pi], faces3[i], e3)
			if placed.is_empty():
				return {}
			faces2[i] = placed["pts"]
			hinge[i] = placed["hinge"]
			angle[i] = _fold_angle(e3[0], e3[1], _center3(faces3[pi]),
				_center3(faces3[i]))
		todo = left
	for i in n:
		if faces2[i] == null:
			return {}
	if _overlaps(faces2):
		return {}
	return {"kind": "poly", "faces": faces2, "parent": parent.duplicate(),
		"hinge": hinge, "angle": angle}


## 台に する 面を、その 面の 上の 座標で 2D に する
static func _flatten(f3: Array) -> Array:
	var a: Vector3 = f3[0]
	var ex := ((f3[1] as Vector3) - a).normalized()
	var ey := _normal3(f3).cross(ex).normalized()
	var out: Array = []
	for p in f3:
		var d: Vector3 = (p as Vector3) - a
		out.append(Vector2(d.dot(ex), d.dot(ey)))
	return out


## 子の 面を、親を 置いた ところから ひらいた 先へ 置く。
## 共有する 辺の 上での 位置(u)と 辺からの きょり(w)は ひらいても 変わらない
static func _place_child(pf3: Array, pf2: Array, cf3: Array, e3: Array) -> Dictionary:
	var ia := _index_of(pf3, e3[0])
	var ib := _index_of(pf3, e3[1])
	if ia < 0 or ib < 0:
		return {}
	var a2: Vector2 = pf2[ia]
	var b2: Vector2 = pf2[ib]
	if (b2 - a2).length() < 0.0001:
		return {}
	var e2 := (b2 - a2).normalized()
	var n2 := Vector2(-e2.y, e2.x)
	# 親は 辺の どちらがわに あるか。子は その 反対がわへ ひらく
	var pc := _center(pf2) - a2
	var side := -signf(e2.x * pc.y - e2.y * pc.x)
	if side == 0.0:
		side = 1.0
	var a3: Vector3 = e3[0]
	var e3d := ((e3[1] as Vector3) - a3).normalized()
	var out: Array = []
	for p in cf3:
		var d: Vector3 = (p as Vector3) - a3
		var u := d.dot(e3d)
		var w := (d - e3d * u).length()
		out.append(a2 + e2 * u + n2 * (w * side))
	return {"pts": out, "hinge": [a2, b2]}


static func _index_of(f3: Array, p: Vector3) -> int:
	for i in f3.size():
		if (f3[i] as Vector3).distance_to(p) < 0.0001:
			return i
	return -1


static func _normal3(f3: Array) -> Vector3:
	var a: Vector3 = f3[0]
	for i in range(2, f3.size()):
		var nz := ((f3[i - 1] as Vector3) - a).cross((f3[i] as Vector3) - a)
		if nz.length() > 0.0001:
			return nz.normalized()
	return Vector3(0, 0, 1)


static func _center3(f3: Array) -> Vector3:
	var c := Vector3.ZERO
	for p in f3:
		c += p as Vector3
	return c / float(maxi(1, f3.size()))


## どこかの 2 面が 重なっていないか。重なる ものは 展開図に ならない
static func _overlaps(faces2: Array) -> bool:
	var shrunk: Array = []
	for f in faces2:
		var poly := PackedVector2Array()
		var c := _center(f)
		for p in f:
			# 辺で さわっている だけの ものを 重なりと 数えないよう、少し 縮める
			poly.append(c + ((p as Vector2) - c) * 0.94)
		shrunk.append(poly)
	for i in shrunk.size():
		for j in range(i + 1, shrunk.size()):
			if not Geometry2D.intersect_polygons(shrunk[i], shrunk[j]).is_empty():
				return true
	return false


## 同じ 形の 展開図を 1 つに まとめる ための しるし。
## 面の まん中どうしの きょりを ぜんぶ ならべた もの ―― 動かしても 回しても
## 裏返しても 変わらないので、同じ 形は 同じ しるしに なる
static func _signature(faces2: Array) -> String:
	var cs: Array = []
	for f in faces2:
		cs.append(_center(f))
	var ds: Array = []
	for i in cs.size():
		for j in range(i + 1, cs.size()):
			ds.append(snappedf((cs[i] as Vector2).distance_to(cs[j] as Vector2), 0.01))
	ds.sort()
	var parts := PackedStringArray()
	for d in ds:
		parts.append("%.2f" % float(d))
	return ",".join(parts)


static func _count_verts(faces3: Array) -> int:
	var pts: Array = []
	for f in faces3:
		for p in f:
			var found := false
			for q in pts:
				if (q as Vector3).distance_to(p as Vector3) < 0.0001:
					found = true
					break
			if not found:
				pts.append(p)
	return pts.size()


static func _count_edges(faces3: Array) -> int:
	var n := 0
	for f in faces3:
		n += f.size()
	return n / 2       # どの 辺も ちょうど 2 つの 面で つかわれる


## 展開図の 中みを ことばに する(答えた あとに 出す)
static func _describe(faces2: Array) -> String:
	var count := {}
	var order: Array = []
	for f in faces2:
		var shape := _shape_name(f)
		if not count.has(shape):
			count[shape] = 0
			order.append(shape)
		count[shape] = int(count[shape]) + 1
	var parts := PackedStringArray()
	for shape in order:
		parts.append("%s %d 枚" % [shape, int(count[shape])])
	return "と ".join(parts)


static func _shape_name(f: Array) -> String:
	var n := f.size()
	if n >= 12:
		return "円"
	var sides: Array = []
	for i in n:
		sides.append((f[(i + 1) % n] as Vector2).distance_to(f[i] as Vector2))
	var same := true
	for v in sides:
		if absf(float(v) - float(sides[0])) > 0.06:
			same = false
			break
	match n:
		3:
			return "正三角形" if same else "三角形"
		4:
			return "正方形" if same else "長方形"
		5:
			return "五角形"
		6:
			return "六角形"
	return "%d 角形" % n


# =========================================================
# 立体(3D)
# =========================================================

static func _prism3d(base: Array, h: float) -> Array:
	var n := base.size()
	var bot: Array = []
	var top: Array = []
	for p in base:
		var q: Vector2 = p
		bot.append(Vector3(q.x, q.y, 0.0))
		top.append(Vector3(q.x, q.y, h))
	var out: Array = [bot, top]
	for i in n:
		out.append([bot[i], bot[(i + 1) % n], top[(i + 1) % n], top[i]])
	return out


static func _pyramid3d(base: Array, h: float) -> Array:
	var n := base.size()
	var ring: Array = []
	for p in base:
		var q: Vector2 = p
		ring.append(Vector3(q.x, q.y, 0.0))
	var out: Array = [ring]
	var apex := Vector3(0, 0, h)
	for i in n:
		out.append([ring[i], ring[(i + 1) % n], apex])
	return out


static func _octa3d(r: float) -> Array:
	var v: Array = [Vector3(r, 0, 0), Vector3(0, r, 0), Vector3(-r, 0, 0),
		Vector3(0, -r, 0), Vector3(0, 0, r), Vector3(0, 0, -r)]
	var out: Array = []
	for i in 4:
		out.append([v[i], v[(i + 1) % 4], v[4]])
		out.append([v[(i + 1) % 4], v[i], v[5]])
	return out


# =========================================================
# 立方体 ― マス目で 書いた 展開図(十字・T 字・かいだん)
# =========================================================

## cells は 1 辺 1 の マス目の 位置。となり合う マスを つないで 木に する。
## 立方体は どの 辺も 90° で 折れる
static func cube_net(cells: Array, id: String, hint: String, a := 3.2) -> Dictionary:
	var faces: Array = []
	for c in cells:
		var g: Vector2i = c
		var x := float(g.x) * a
		var y := float(g.y) * a
		faces.append([Vector2(x, y), Vector2(x + a, y), Vector2(x + a, y + a), Vector2(x, y + a)])
	var parent: Array = []
	var hinge: Array = []
	var angle: Array = []
	parent.resize(cells.size())
	hinge.resize(cells.size())
	angle.resize(cells.size())
	for i in cells.size():
		parent[i] = -1
		hinge[i] = []
		angle[i] = 0.0
	# 0 番の マスを 台にして、となりへ 順に たどる(幅優先)
	var queue: Array = [0]
	var seen := {0: true}
	while not queue.is_empty():
		var i: int = queue.pop_front()
		var gi: Vector2i = cells[i]
		for j in cells.size():
			if seen.has(j):
				continue
			var gj: Vector2i = cells[j]
			var d := gj - gi
			if absi(d.x) + absi(d.y) != 1:
				continue
			seen[j] = true
			parent[j] = i
			angle[j] = PI * 0.5
			hinge[j] = _shared_edge(faces[i], faces[j])
			queue.append(j)
	return {"id": id, "solid": "立方体", "hint": hint, "kind": "poly",
		"faces": faces, "parent": parent, "hinge": hinge, "angle": angle,
		"verts": 8, "edges": 12}


## 2 つの 面が 共有する 辺(2 点)を 探す
static func _shared_edge(f1: Array, f2: Array) -> Array:
	var same: Array = []
	for p in f1:
		for q in f2:
			if (p as Vector2).distance_to(q as Vector2) < 0.001:
				same.append(p)
				break
	if same.size() >= 2:
		return [same[0], same[1]]
	return [Vector2.ZERO, Vector2(1, 0)]


# =========================================================
# 角柱 ― 側面を 帯に ならべ、底面と ふたを つける
# =========================================================

## base は 底面の 多角形(反時計まわり)。h は 高さ。
## attach は 底面と ふたを つける 側面の 番号。
## ★ 円柱のように 側面を 細かく 分ける ときは まん中に つける ―
##   はしの 1 枚に つけると、大きな 円が 帯に かぶさって 展開図に 見えない
static func prism(base: Array, h: float, solid: String, id: String,
		hint: String, attach := 0) -> Dictionary:
	var n := base.size()
	var side: Array = []
	for i in n:
		side.append((base[(i + 1) % n] as Vector2).distance_to(base[i] as Vector2))
	# 側面の 帯(左から 順に ならべる)
	var xs: Array = [0.0]
	for i in n:
		xs.append(float(xs[i]) + float(side[i]))
	var b := posmod(attach, n)
	var bx0 := float(xs[b])
	var bx1 := float(xs[b + 1])
	var faces: Array = []
	var parent: Array = []
	var hinge: Array = []
	var angle: Array = []
	# 0 番 = 底面(台)。つける 側面の 下に 置く
	faces.append(_place(base, base[b], base[(b + 1) % n], Vector2(bx1, 0), Vector2(bx0, 0)))
	parent.append(-1)
	hinge.append([])
	angle.append(0.0)
	for i in n:
		var x0 := float(xs[i])
		var x1 := float(xs[i + 1])
		faces.append([Vector2(x0, 0), Vector2(x1, 0), Vector2(x1, h), Vector2(x0, h)])
		if i == b:
			parent.append(0)
			hinge.append([Vector2(x0, 0), Vector2(x1, 0)])
			angle.append(PI * 0.5)
		elif i > b:
			parent.append(i)              # 1 つ 左の 側面
			hinge.append([Vector2(x0, 0), Vector2(x0, h)])
			# となりの 側面へ 折る 角 = 底面の 外角
			angle.append(PI - _interior(base, i))
		else:
			parent.append(i + 2)          # 1 つ 右の 側面(番号は 底面の ぶん +1)
			hinge.append([Vector2(x1, 0), Vector2(x1, h)])
			angle.append(PI - _interior(base, (i + 1) % n))
	# ふた(つけた 側面の 上)
	faces.append(_place(base, base[b], base[(b + 1) % n], Vector2(bx0, h), Vector2(bx1, h)))
	parent.append(b + 1)
	hinge.append([Vector2(bx0, h), Vector2(bx1, h)])
	angle.append(PI * 0.5)
	return {"id": id, "solid": solid, "hint": hint, "kind": "poly",
		"faces": faces, "parent": parent, "hinge": hinge, "angle": angle,
		"verts": n * 2, "edges": n * 3}


## 多角形の 頂点 i の 内角
static func _interior(poly: Array, i: int) -> float:
	var n := poly.size()
	var p0: Vector2 = poly[(i - 1 + n) % n]
	var p1: Vector2 = poly[i]
	var p2: Vector2 = poly[(i + 1) % n]
	return absf((p0 - p1).angle_to(p2 - p1))


## 多角形を「点 a → 点 b」が「to_a → to_b」に なるように 動かして 置く
static func _place(poly: Array, a: Vector2, b: Vector2, to_a: Vector2,
		to_b: Vector2) -> Array:
	var ang := (to_b - to_a).angle() - (b - a).angle()
	var out: Array = []
	for p in poly:
		out.append(to_a + ((p as Vector2) - a).rotated(ang))
	return out


# =========================================================
# 角錐 ― 底面の まわりに 側面を ひらく
# =========================================================

## base は 底面の 多角形(反時計まわり)、h は 高さ。
## 側面を 起こす 角は arccos(−m ÷ s)。m は 中心から 辺までの 長さ、s は 側面の 高さ
static func pyramid(base: Array, h: float, solid: String, id: String,
		hint: String) -> Dictionary:
	var n := base.size()
	var c := _center(base)
	var faces: Array = [base.duplicate()]
	var parent: Array = [-1]
	var hinge: Array = [[]]
	var angle: Array = [0.0]
	for i in n:
		var p1: Vector2 = base[i]
		var p2: Vector2 = base[(i + 1) % n]
		var mid := (p1 + p2) * 0.5
		var out_dir := (mid - c).normalized()
		var m := (mid - c).length()
		var s := sqrt(h * h + m * m)
		faces.append([p1, p2, mid + out_dir * s])
		parent.append(0)
		hinge.append([p1, p2])
		angle.append(acos(clampf(-m / s, -1.0, 1.0)))
	return {"id": id, "solid": solid, "hint": hint, "kind": "poly",
		"faces": faces, "parent": parent, "hinge": hinge, "angle": angle,
		"verts": n + 1, "edges": n * 2}


## 1 辺 s の 正 n 角形(反時計まわり)
static func _regular(n: int, s: float) -> Array:
	var r := s / (2.0 * sin(PI / float(n)))
	var out: Array = []
	for i in n:
		var th := PI * 0.5 + TAU * float(i) / float(n)
		out.append(Vector2(cos(th), sin(th)) * r)
	return out


# =========================================================
# 正八面体 ― 帯 6 枚 + ふた 2 枚
# =========================================================

## ★ 帯は 6 枚で ひとまわり 閉じる。8 枚 つないでは いけない
static func octa(s: float) -> Dictionary:
	var hgt := s * sqrt(3.0) * 0.5
	var faces: Array = []
	var parent: Array = []
	var hinge: Array = []
	var angle: Array = []
	# 帯: 上向き・下向きを かわりばんこに 3 組
	for i in 3:
		var x := float(i) * s
		faces.append([Vector2(x, 0), Vector2(x + s, 0), Vector2(x + s * 0.5, hgt)])
		faces.append([Vector2(x + s * 0.5, hgt), Vector2(x + s * 1.5, hgt),
			Vector2(x + s, 0)])
	parent = [-1, 0, 1, 2, 3, 4]
	for i in 6:
		if i == 0:
			hinge.append([])
			angle.append(0.0)
		else:
			hinge.append(_shared_edge(faces[i - 1], faces[i]))
			angle.append(OCTA_ANGLE)
	# ふた 2 枚(帯の 下と 上に 1 枚ずつ)
	faces.append([Vector2(0, 0), Vector2(s, 0), Vector2(s * 0.5, -hgt)])
	parent.append(0)
	hinge.append([Vector2(0, 0), Vector2(s, 0)])
	angle.append(OCTA_ANGLE)
	faces.append([Vector2(s * 0.5, hgt), Vector2(s * 1.5, hgt), Vector2(s, hgt * 2.0)])
	parent.append(1)
	hinge.append([Vector2(s * 0.5, hgt), Vector2(s * 1.5, hgt)])
	angle.append(OCTA_ANGLE)
	return {"id": "octa", "solid": "正八面体", "hint": "三角形 8 枚。帯 6 枚に ふた 2 枚",
		"kind": "poly", "faces": faces, "parent": parent, "hinge": hinge, "angle": angle,
		"verts": 6, "edges": 12}


# =========================================================
# 円柱・円錐 ― まるい ぶんを 24 に 分けて、角柱・角錐として 折る
# =========================================================

const ROUND_N := 24


## 半径 r の 円に 近い 正 24 角形
static func _circle_poly(r: float, n := ROUND_N) -> Array:
	var out: Array = []
	for i in n:
		var th := PI * 0.5 + TAU * float(i) / float(n)
		out.append(Vector2(cos(th), sin(th)) * r)
	return out


static func round_prism(r: float, h: float) -> Dictionary:
	var net := prism(_circle_poly(r), h, "円柱", "cyl", "長方形 1 枚と 円 2 枚",
		ROUND_N / 2)
	net["round"] = true
	# 底面と ふたは 側面と 別の 色で 塗る(1 色だと どこが 何か 分からない)
	net["cap"] = [0, (net["faces"] as Array).size() - 1]
	return net


## 円錐 ― おうぎ形 1 枚(24 に 分けた 三角形の 帯)と 底面の 円。
##
## ★ 角錐の 作り(底面の まわりに 側面を ひらく)を そのまま 使うと、
##   まん中の 円から 24 本の 三角形が 出た「太陽」の 形に なって、
##   見なれた 円錐の 展開図(おうぎ形 + 円)に ならない。
##   ここでは 側面を 横に つないで おうぎ形に し、円は その はしに つける。
##
## 折る 角は 立体の ほうから 出す。おうぎ形の 三角形は ぴったり 同じ 形なので、
## 手で 出した 角より 立体から 測った ほうが 合う(閉じるかは net_check が 見る)
static func round_pyramid(r: float, l: float, n := ROUND_N) -> Dictionary:
	var h := sqrt(maxf(0.01, l * l - r * r))
	var apex := Vector3(0, 0, h)
	var ring: Array = []
	for i in n:
		var th := TAU * float(i) / float(n)
		ring.append(Vector3(cos(th) * r, sin(th) * r, 0.0))
	# 展開図: かなめを 原点に して 三角形を 横に ならべる
	var chord := (ring[1] as Vector3).distance_to(ring[0] as Vector3)
	var step := 2.0 * asin(clampf(chord / (2.0 * l), -1.0, 1.0))
	var pts: Array = []
	for i in n + 1:
		var a := -step * float(n) * 0.5 + step * float(i)
		pts.append(Vector2(sin(a), -cos(a)) * l)
	var faces: Array = [[]]            # 0 番は 底面の 円。あとで 置く
	var parent: Array = [-1]
	var hinge: Array = [[]]
	var angle: Array = [0.0]
	for i in n:
		faces.append([pts[i], pts[i + 1], Vector2.ZERO])
		if i == 0:
			parent.append(0)
			hinge.append([pts[0], pts[1]])
			# 底面と 側面の あいだ
			angle.append(_fold_angle(ring[0], ring[1], Vector3.ZERO, apex))
		else:
			parent.append(i)
			hinge.append([pts[i], Vector2.ZERO])
			# となりの 側面との あいだ
			angle.append(_fold_angle(ring[i % n], apex, ring[i - 1], ring[(i + 1) % n]))
	# 底面の 円を おうぎ形の はしの 辺に つける(かなめの 反対がわ)
	var base := _circle_poly(r, n)
	var f1: Array = _place(base, base[0], base[1], pts[1], pts[0])
	var f2: Array = _place(base, base[0], base[1], pts[0], pts[1])
	faces[0] = f1 if _center(f1).length() > _center(f2).length() else f2
	return {"id": "cone", "solid": "円錐", "hint": "おうぎ形 1 枚と 円 1 枚",
		"kind": "poly", "round": true, "cap": [0],
		"faces": faces, "parent": parent, "hinge": hinge, "angle": angle,
		"verts": n + 1, "edges": n * 2}


## 立体の ほうから 折る 角を 出す。a-b が ちょうつがい、p は 親の 面の 残りの 点、
## q は 子の 面の 残りの 点。ひらいた ときが 180° なので 180° − 二面角
static func _fold_angle(a: Vector3, b: Vector3, p: Vector3, q: Vector3) -> float:
	var e := (b - a).normalized()
	var u := (p - a) - e * (p - a).dot(e)
	var v := (q - a) - e * (q - a).dot(e)
	if u.length() < 0.0001 or v.length() < 0.0001:
		return 0.0
	return PI - acos(clampf(u.normalized().dot(v.normalized()), -1.0, 1.0))


## 立体の 名まえの 一覧(クイズの 選択肢に つかう)
static func solid_names() -> Array:
	var out: Array = []
	for n in all():
		var s := String(n["solid"])
		if not out.has(s):
			out.append(s)
	return out
