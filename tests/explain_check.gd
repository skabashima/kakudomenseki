extends Node
## 「説明」が その問題の ものに なっているかを 機械で 見る(--headless 可)。
##   godot --headless --path . res://tests/explain_check.tscn
##
## kid_unit を 立てて ことばを 読むので、シーンとして 動かす(GameState が いる)。
##
## ほかのテストは「進めるか」を 見ている。ここは **中身が 合っているか** を 見る。
## どれも 実際に 起きた こと ―― 見た目には 進めてしまうので、
## 通しプレイでは 気づけなかった。
##
## 見るところ:
##   1. さわって 見つける 回の ことばが、単元ごとに ちがうか
##      (さわり方が 同じ 単元どうしで 文を 使い回すと、まるきり 逆の ことを
##       言ってしまう ―― k21 は「進んだ ぶん ふえる」回なのに、k13 の
##       「動かしても 変わらない」が 出ていた)
##   2. 塗る 多角形が ちゃんと 塗れるか
##      (自分と 交わる 形や、同じ点が 続く 形は Godot が 三角形分割 できず、
##       エラーを 1 行 出して **塗りを まるごと 描かない**。線だけ 残るので、
##       絵は それらしく 見えてしまう ―― 星形と 放物線が そうなっていた)
##   3. 解き方アニメの さいごの 一文と 解説が、その問題の 答えを 言っているか
##      (ほかの 問題むけの 説明が ついていないか)
##   4. ストーリーの 依頼で、みちびきの 一言が 依頼の 中身と 合っているか
##      (第26章は 辺の数を 聞く 回と 頂点の数を 聞く 回が あるのに、
##       「辺の数を数えて伝えよう」と 決め打ちに なっていた)

var fails: Array = []


func _ready() -> void:
	await get_tree().process_frame
	_check_kid_words()
	_check_fillable()
	_check_answer_in_words()
	_check_story_lead()

	if fails.is_empty():
		print("EXPLAIN OK: 説明は どれも その問題の ものに なっている")
		get_tree().quit(0)
	else:
		for f in fails:
			print("FAIL: " + str(f))
		print("EXPLAIN FAILED: %d 件" % fails.size())
		get_tree().quit(1)


# =========================================================
# 1. さわり方が 同じ 単元どうしで、ことばを 使い回していないか
# =========================================================

## kid_unit の ことばは unit と st から 決まる。場面を 立てずに 読むため、
## 単元を 差しかえながら 3 つの ことばを 取り出す
func _kid_words() -> Dictionary:
	var out := {}
	var keep := GameState.kid_unit
	for u in KidDefs.UNITS:
		var id := String(u["id"])
		GameState.kid_unit = id
		var inst: Node = (load("res://scenes/kid_unit.tscn") as PackedScene).instantiate()
		get_tree().root.add_child(inst)
		# _reset_act まで 走らせてから ことばを 読む(st を 使う 文が ある)
		out[id] = [inst._act_lead(), inst._act_after(), inst._act_cheer()]
		inst.free()
	GameState.kid_unit = keep
	return out


func _check_kid_words() -> void:
	var words := _kid_words()
	var names := ["さそいの ことば", "つぎへの ことば", "できた ときの ことば"]
	for i in KidDefs.UNITS.size():
		for j in range(i + 1, KidDefs.UNITS.size()):
			var a: Dictionary = KidDefs.UNITS[i]
			var b: Dictionary = KidDefs.UNITS[j]
			if String(a["act"]) != String(b["act"]):
				continue
			var wa: Array = words[String(a["id"])]
			var wb: Array = words[String(b["id"])]
			for k in 3:
				if String(wa[k]) == String(wb[k]):
					fails.append("%s と %s(どちらも %s)で %s が 同じ: 「%s」" % [
						String(a["id"]), String(b["id"]), String(a["act"]),
						String(names[k]), String(wa[k])])


# =========================================================
# 2. 塗る 多角形が ちゃんと 塗れるか
# =========================================================

func _check_poly(where: String, fig: Dictionary, seen: Dictionary) -> void:
	for sh in fig.get("shapes", []):
		if String(sh.get("t", "")) != "poly" or not sh.has("fill"):
			continue
		var pv := PackedVector2Array()
		for q in sh["p"]:
			pv.append(q as Vector2)
		if Geometry2D.triangulate_polygon(pv).is_empty() and not seen.has(where):
			seen[where] = true
			fails.append("%s: 塗る はずの %d 点の 形が 三角形に 分けられない(塗りが 消える)" % [
				where, pv.size()])


func _check_fillable() -> void:
	var seen := {}
	# 本編
	for c in ProblemGen.COURSES:
		for st in c["stages"]:
			var sid := String(st["id"])
			for tier in 10:
				for k in 6:
					var rng := RandomNumberGenerator.new()
					rng.seed = 6100 + tier * 31 + k
					var p: Dictionary = ProblemGen.generate(sid, rng, tier)
					_check_poly("本編 %s tier=%d" % [sid, tier], p.get("fig", {}), seen)
	# ストーリー
	for ch in StoryDefs.CHAPTERS:
		var cid := String(ch["id"])
		for sc in ch["scenes"]:
			var f := String(sc.get("fig", ""))
			if f == "":
				continue
			match String(sc.get("type", "")):
				"measure":
					# 動かせる はんいの すみずみで ためす
					for ix in 13:
						for iy in 13:
							var raw := Vector2(-6.0 + float(ix), -6.0 + float(iy)) * 2.0
							_check_poly("%s の %s" % [cid, f],
								StoryFigs.spec(f, StoryDefs.clamp_of(f, raw)), seen)
				"solve":
					for k2 in 40:
						var rng2 := RandomNumberGenerator.new()
						rng2.seed = 6200 + k2
						_check_poly("%s の依頼 %s" % [cid, f],
							StoryTasks.make(f, rng2)["fig"], seen)
				_:
					_check_poly("%s の %s" % [cid, f], StoryFigs.spec(f, Vector2.ZERO), seen)


# =========================================================
# 3. 解き方アニメと 解説が、その問題の 答えを 言っているか
# =========================================================

static func _says(text: String, v: float) -> bool:
	for f in [ProblemGen.fmt(v), String.num(v, 1), String.num(v, 2), str(int(round(v)))]:
		if text.find(String(f)) >= 0:
			return true
	return false


func _check_answer_in_words() -> void:
	var seen := {}
	for c in ProblemGen.COURSES:
		for st in c["stages"]:
			var sid := String(st["id"])
			for tier in 10:
				for k in 8:
					var rng := RandomNumberGenerator.new()
					rng.seed = 7300 + tier * 41 + k
					var p: Dictionary = ProblemGen.generate(sid, rng, tier)
					var a := float(p["answer"])
					var where := "%s tier=%d" % [sid, tier]
					var steps: Array = p.get("steps", [])
					if not steps.is_empty():
						var last := String((steps[steps.size() - 1] as Dictionary).get("say", ""))
						if not _says(last, a) and not seen.has(where + "s"):
							seen[where + "s"] = true
							fails.append("%s: 解き方の さいごが 答え %s を 言っていない ―「%s」"
								% [where, ProblemGen.fmt(a), last])
					var expl := String(p.get("expl", ""))
					if expl != "" and not _says(expl, a) and not seen.has(where + "e"):
						seen[where + "e"] = true
						fails.append("%s: 解説が 答え %s を 言っていない ―「%s」" % [
							where, ProblemGen.fmt(a), expl])


# =========================================================
# 4. ストーリーの 依頼で、みちびきの 一言が 中身と 合っているか
# =========================================================

## lead に 書いた ことばが、依頼の 何とおりかの うち 一方にしか 当てはまらない
## ことが あった。依頼文が 変わる 章は、lead が どの回でも 通る 言い方か 見る
func _check_story_lead() -> void:
	for ch in StoryDefs.CHAPTERS:
		for sc in ch["scenes"]:
			if String(sc.get("type", "")) != "solve":
				continue
			var kind := String(sc.get("fig", ""))
			var lead := String(sc.get("lead", ""))
			# 依頼文が 何とおり 出るか 集める
			var qs := {}
			for k in 60:
				var rng := RandomNumberGenerator.new()
				rng.seed = 8400 + k
				qs[String(StoryTasks.make(kind, rng)["q"]).substr(0, 40)] = true
			if qs.size() < 2:
				continue
			# 依頼が 何とおりも あるのに、lead が その うち 1 つの ことばを
			# そのまま 指していないか(「辺の数を数えて」など)
			for word in ["辺の数", "頂点の数", "面の数"]:
				if lead.find(word) < 0:
					continue
				var all_have := true
				for q in qs.keys():
					if String(q).find(word) < 0:
						all_have = false
				if not all_have:
					fails.append("%s の依頼: みちびきが「%s」と 決めうちだが、"
						% [String(ch["id"]), word]
						+ "そう 聞かない 回も ある ―「%s」" % lead)
