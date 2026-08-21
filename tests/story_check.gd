extends SceneTree
## ストーリーのデータ検証(--headless 可)。
##   godot --headless --path . -s tests/story_check.gd
##
## 見るところ:
##   1. 章のシーンが type ごとに必要な項目を持っているか
##   2. **measure で「一定」と言っている量が、本当に動かしても一定か**
##      (図の点をランダムに動かして readout の値を見る。ここがずれていると
##       プレイヤーは表を見ながら正解を選べない)
##   3. solve で使う生成器のステージが実在するか
##   4. 図のスペックが全種類ちゃんと作れて、座標が有限か
##   5. 章タイトル・見つけたことが空でないか

var bad: Array = []


func _init() -> void:
	for ch in StoryDefs.CHAPTERS:
		_check_chapter(ch)
	if bad.is_empty():
		print("STORY CHECK OK: %d 章 / %d シーン" % [
			StoryDefs.CHAPTERS.size(), _scene_count()])
		quit(0)
	else:
		for b in bad:
			print("FAIL: " + String(b))
		print("STORY CHECK FAILED: %d 件" % bad.size())
		quit(1)


func _scene_count() -> int:
	var n := 0
	for ch in StoryDefs.CHAPTERS:
		n += (ch["scenes"] as Array).size()
	return n


func _check_chapter(ch: Dictionary) -> void:
	var cid := String(ch.get("id", "?"))
	for key in ["title", "level", "place", "found", "scenes"]:
		if not ch.has(key) or String(ch[key]) == "":
			bad.append("%s: %s が無い" % [cid, key])
	for i in (ch.get("scenes", []) as Array).size():
		_check_scene(cid, i, ch["scenes"][i])


func _check_scene(cid: String, i: int, sc: Dictionary) -> void:
	var where := "%s のシーン %d" % [cid, i + 1]
	if not sc.has("title"):
		bad.append(where + ": title が無い")
	match String(sc.get("type", "")):
		"talk":
			if (sc.get("lines", []) as Array).is_empty():
				bad.append(where + ": lines が空")
			if sc.has("fig"):
				_check_fig(where, String(sc["fig"]), Vector2.ZERO)
		"measure":
			for key in ["lead", "question", "choices", "answer", "trials", "fig", "invariant"]:
				if not sc.has(key):
					bad.append(where + ": %s が無い" % key)
					return
			var n: int = (sc["choices"] as Array).size()
			if int(sc["answer"]) < 0 or int(sc["answer"]) >= n:
				bad.append(where + ": answer が選択肢の範囲外")
			_check_invariant(where, sc)
		"solve":
			_check_solve_matches(where, sc)
		_:
			bad.append(where + ": 知らない type")


## 依頼(solve)がちゃんと作れるか。
## 本編の問題をそのまま出すのは禁止(同じ画面になって物語も発見も効かない)。
## ここでは章ごとの依頼が、毎回きちんと文章・答え・図を返すかを見る
func _check_solve_matches(where: String, sc: Dictionary) -> void:
	var kind := String(sc.get("fig", ""))
	if kind == "":
		bad.append(where + ": fig(依頼の種類)が無い")
		return
	var rng := RandomNumberGenerator.new()
	for i in 60:
		rng.seed = 500 + i
		var t: Dictionary = StoryTasks.make(kind, rng)
		if String(t.get("q", "")) == "":
			bad.append("%s(%s): 依頼の文が空" % [where, kind])
			return
		if not is_finite(float(t.get("answer", NAN))):
			bad.append("%s(%s): 答えが数でない" % [where, kind])
			return
		if float(t.get("answer", 0.0)) <= 0.0:
			bad.append("%s(%s): 答えが 0 以下(%s)" % [where, kind, str(t.get("answer"))])
			return
		if (t.get("fig", {}) as Dictionary).get("shapes", []).is_empty():
			bad.append("%s(%s): 図が空" % [where, kind])
			return
		# 本編の問題文をそのまま使っていないか(教科書調の言い回しを弾く)
		for ng in ["何度ですか。", "求めなさい。"]:
			if String(t["q"]).ends_with(ng):
				bad.append("%s(%s): 本編と同じ言い回しになっている" % [where, kind])
				return


## 動かしても「一定」と言っている量が本当に一定か
func _check_invariant(where: String, sc: Dictionary) -> void:
	var kind := String(sc["fig"])
	var want: float = float(sc["invariant"]["value"])
	var tol: float = float(sc["invariant"]["tol"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260821
	var worst := 0.0
	for t in 300:
		var raw := Vector2(rng.randf_range(-20.0, 20.0), rng.randf_range(-20.0, 20.0))
		var p: Vector2 = StoryDefs.clamp_of(kind, raw)
		var out: Dictionary = StoryDefs.readout_of(kind, p)
		var v := float(out["value"])
		if not is_finite(v):
			bad.append("%s(%s): 値が数でない" % [where, kind])
			return
		if String(out["row"]) == "":
			bad.append("%s(%s): 表示する行が空" % [where, kind])
			return
		worst = maxf(worst, absf(v - want))
		if worst > tol:
			bad.append("%s(%s): 一定のはずが %.4f(ねらい %.4f ± %.4f)。点 (%.2f, %.2f)" % [
				where, kind, v, want, tol, p.x, p.y])
			return
		_check_fig(where, kind, p)
		if not bad.is_empty():
			return


## 図が作れて、座標がすべて有限か
func _check_fig(where: String, kind: String, p: Vector2) -> void:
	var fig: Dictionary = StoryFigs.spec(kind, p)
	var shapes: Array = fig.get("shapes", [])
	if shapes.is_empty():
		bad.append("%s: 図 %s が空" % [where, kind])
		return
	for sh in shapes:
		for key in ["a", "b", "c", "at", "p1", "p2"]:
			if sh.has(key) and not _finite_v(sh[key]):
				bad.append("%s: 図 %s の %s が数でない" % [where, kind, key])
				return
		if sh.has("p"):
			for q in sh["p"]:
				if not _finite_v(q):
					bad.append("%s: 図 %s の頂点が数でない" % [where, kind])
					return


func _finite_v(v) -> bool:
	if typeof(v) != TYPE_VECTOR2:
		return true
	return is_finite((v as Vector2).x) and is_finite((v as Vector2).y)
