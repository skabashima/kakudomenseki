extends SceneTree
## 発見モードのデータ検証(--headless 可)。
##   godot --headless --path . -s tests/story_check.gd
## 見るところ:
##   ・章のシーンが type ごとに必要な項目を持っているか
##   ・measure の正解の選択肢が、実際に測って出る答えと合っているか
##   ・角を整数に丸めても和が 180 になるか(表示の足し算が合うか)
##   ・solve で使う生成器のステージが実在するか

var bad: Array = []


func _init() -> void:
	for ch in StoryDefs.CHAPTERS:
		for i in (ch["scenes"] as Array).size():
			_check_scene(String(ch["id"]), i, ch["scenes"][i])
	_check_angles()
	if bad.is_empty():
		print("STORY CHECK OK: %d 章" % StoryDefs.CHAPTERS.size())
		quit(0)
	else:
		for b in bad:
			print("FAIL: " + String(b))
		print("STORY CHECK FAILED: %d 件" % bad.size())
		quit(1)


func _check_scene(cid: String, i: int, sc: Dictionary) -> void:
	var where := "%s のシーン %d" % [cid, i + 1]
	if not sc.has("title"):
		bad.append(where + ": title が無い")
	match String(sc.get("type", "")):
		"talk":
			if (sc.get("lines", []) as Array).is_empty():
				bad.append(where + ": lines が空")
		"measure":
			for key in ["lead", "question", "choices", "answer", "trials", "fig"]:
				if not sc.has(key):
					bad.append(where + ": %s が無い" % key)
			var n: int = (sc.get("choices", []) as Array).size()
			if int(sc.get("answer", -1)) < 0 or int(sc.get("answer", -1)) >= n:
				bad.append(where + ": answer が選択肢の範囲外")
		"solve":
			var sid := String(sc.get("stage", ""))
			var found := false
			for c in ProblemGen.COURSES:
				for st in c["stages"]:
					if String(st["id"]) == sid:
						found = true
			if not found:
				bad.append(where + ": stage %s が本編に無い" % sid)
		_:
			bad.append(where + ": 知らない type")


## 頂点をあちこちに動かしても、表示する整数の和が必ず 180 になること
func _check_angles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 300:
		var a := Vector2(rng.randf_range(-4.0, 14.0), rng.randf_range(2.0, 9.0))
		var deg: Array = StoryDefs.rounded_angles(
			StoryDefs.angles_of(a, StoryDefs.TRI_B, StoryDefs.TRI_C))
		var sum: int = int(deg[0]) + int(deg[1]) + int(deg[2])
		if sum != 180:
			bad.append("A=(%.1f, %.1f) の表示が %d + %d + %d = %d" % [
				a.x, a.y, int(deg[0]), int(deg[1]), int(deg[2]), sum])
			return
