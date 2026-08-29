extends SceneTree
## 全体の つじつま を 機械で 見る(--headless 可)。
##   godot --headless --path . -s tests/consistency_check.gd
##
## ひとつひとつの 遊びは ほかの テストが 通しているので、ここでは
## **つなぎ目**を 見る ―― データとコード、画面と画面、実装とストア文書。
##
## 見るところ:
##   1. change_scene などで 書いた res:// の 行き先が 実在するか(打ちまちがい)
##   2. たからのちず: 単元の ステージが 実在し、さわり方が 実装されているか
##   3. 島取り: 島の 範囲が はみ出していないか、全ステージが どこかの 島に 入るか
##   4. ストーリー: 場面の 種類・図・依頼が そろっているか
##   5. セーブ: 書いた 鍵を ぜんぶ 読み戻しているか(進みぐあいが 消えないか)
##   6. ストア文書に 書いた 数が 実装と 合っているか
##   7. 鳴らそうとしている 音が 実在するか
##   8. 絵の部品(Icons)の 呼び出しが 実在するか
##   9. どこからも 行けない 画面が ないか

var fails: Array = []


func _init() -> void:
	_check_scene_paths()
	_check_kid()
	_check_island()
	_check_story()
	_check_save_keys()
	_check_store_numbers()
	_check_sfx()
	_check_icons()
	_check_reachable()

	if fails.is_empty():
		print("CONSISTENCY OK: つなぎ目に くいちがい なし")
		quit(0)
	else:
		for f in fails:
			print("FAIL: " + str(f))
		print("CONSISTENCY FAILED: %d 件" % fails.size())
		quit(1)


func _sources() -> Array:
	var out: Array = []
	for dir in ["res://core", "res://scenes", "res://ui"]:
		var d := DirAccess.open(dir)
		if d == null:
			continue
		for f in d.get_files():
			if f.ends_with(".gd"):
				out.append(dir + "/" + f)
	return out


func _text(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	return "" if f == null else f.get_as_text()


## 1. res:// の 行き先が 実在するか
func _check_scene_paths() -> void:
	for src in _sources():
		var s := _text(src)
		var i := 0
		while true:
			var a := s.find("res://", i)
			if a < 0:
				break
			var b := a
			while b < s.length() and s.substr(b, 1) != "\"":
				b += 1
			var path := s.substr(a, b - a)
			i = b + 1
			if path.contains("%s") or path.contains("*"):
				continue          # 組み立てて使うものは ここでは 見ない
			if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
				fails.append("%s: 行き先が 無い %s" % [src.get_file(), path])


## 2. たからのちず(小学生)
func _check_kid() -> void:
	var acts := _text("res://scenes/kid_unit.gd")
	var seen := {}
	for u in KidDefs.UNITS:
		var id := String(u["id"])
		if seen.has(id):
			fails.append("たからのちず: id が かぶっている %s" % id)
		seen[id] = true
		var stage := String(u["stage"])
		if ProblemGen.stage_title(stage) == "":
			fails.append("たからのちず %s: ステージ %s が 無い" % [id, stage])
		var act := String(u["act"])
		if not acts.contains("\"%s\":" % act):
			fails.append("たからのちず %s: さわり方 %s が 実装されていない" % [id, act])
		if (u["intro"] as Array).is_empty():
			fails.append("たからのちず %s: おはなしが 空" % id)
		if String(u["found"]) == "":
			fails.append("たからのちず %s: 見つけたことが 空" % id)


## 3. 島取り
func _check_island() -> void:
	var levels := {}
	for r in IslandDefs.RANGES:
		if String(r["level"]) != "":
			levels[String(r["level"])] = true
	var covered := {"kaku": {}, "men": {}}
	for i in IslandDefs.count():
		var d := IslandDefs.of(i)
		var course := String(d["course"])
		var stages: Array = ProblemGen.stages_of(course)
		var lo := int(d["from"])
		var hi := int(d["to"])
		if lo > hi:
			fails.append("島 %d: from が to より 後ろ" % (i + 1))
		if hi >= stages.size():
			fails.append("島 %d: to=%d が %s の ステージ数 %d を こえている" % [
				i + 1, hi, course, stages.size()])
		if not levels.has(String(d["level"])):
			fails.append("島 %d: はんい %s が えらび画面に 無い" % [i + 1, String(d["level"])])
		if int(d["turns"]) < 5:
			fails.append("島 %d: ターンが 少なすぎる" % (i + 1))
		for k in range(lo, mini(hi + 1, stages.size())):
			covered[course][k] = true
	for course in ["kaku", "men"]:
		var n: int = (ProblemGen.stages_of(course) as Array).size()
		if covered[course].size() < n:
			fails.append("島取り: %s の %d / %d ステージしか 島に 入っていない" % [
				course, covered[course].size(), n])


## 4. ストーリー(中学生・高校生)
func _check_story() -> void:
	var story := _text("res://scenes/story.gd")
	for mode in ["jhs", "hs"]:
		var seen := {}
		for ch in StoryDefs.chapters_of(mode):
			var cid := String(ch["id"])
			if seen.has(cid):
				fails.append("ストーリー(%s): 章 id が かぶっている %s" % [mode, cid])
			seen[cid] = true
			if String(ch.get("found", "")) == "":
				fails.append("%s %s: 見つけたことが 空" % [mode, cid])
			var scenes: Array = ch["scenes"]
			if scenes.is_empty():
				fails.append("%s %s: 場面が 無い" % [mode, cid])
			for si in scenes.size():
				var sc: Dictionary = scenes[si]
				var t := String(sc.get("type", ""))
				if not t in ["talk", "measure", "solve"]:
					fails.append("%s %s の %d 場めの 種類 %s は 実装に 無い" % [mode, cid, si + 1, t])
					continue
				if not story.contains("\"%s\":" % t):
					fails.append("%s: 場面の 種類 %s を story.gd が 扱っていない" % [mode, t])
				if t == "measure":
					for key in ["fig", "answer", "choices"]:
						if not sc.has(key):
							fails.append("%s %s の %d 場め(measure): %s が 無い" % [
								mode, cid, si + 1, key])
					var kind := String(sc.get("fig", ""))
					if StoryDefs.start_of(kind) == Vector2.ZERO:
						fails.append("%s %s: 測る図 %s の はじめの点が 無い" % [mode, cid, kind])
				if t == "solve":
					if not sc.has("fig"):
						fails.append("%s %s の %d 場め(solve): fig が 無い" % [mode, cid, si + 1])
					else:
						var rng := RandomNumberGenerator.new()
						rng.seed = 1234
						var task: Dictionary = StoryTasks.make(String(sc["fig"]), rng)
						if not task.has("answer") or not task.has("q"):
							fails.append("%s %s: 依頼 %s が 作れない" % [mode, cid, String(sc["fig"])])
				if sc.has("fig") and t != "solve":
					var spec: Dictionary = StoryFigs.spec(String(sc["fig"]), Vector2(0, 5))
					if (spec.get("shapes", []) as Array).is_empty():
						fails.append("%s %s: 図 %s が 描けない" % [mode, cid, String(sc["fig"])])


## 5. セーブ: 書いた 鍵を ぜんぶ 読み戻しているか
func _check_save_keys() -> void:
	var src := _text("res://core/game_state.gd")
	var i := src.find("func save_game")
	var j := src.find("func load_game")
	if i < 0 or j < 0:
		fails.append("セーブの 場所が 見つからない")
		return
	var save_part := src.substr(i, j - i)
	var load_part := src.substr(j)
	var k := 0
	while true:
		var a := save_part.find("\"", k)
		if a < 0:
			break
		var b := save_part.find("\"", a + 1)
		if b < 0:
			break
		var key := save_part.substr(a + 1, b - a - 1)
		k = b + 1
		if key == "" or key.contains("/") or key.contains(" ") or key.contains("%"):
			continue
		if key == "version":
			continue          # 保存の 版番号。読み戻す ものでは ない
		if not load_part.contains("\"%s\"" % key):
			fails.append("セーブ: 書いた 鍵 \"%s\" を 読み戻していない(進みぐあいが 消える)" % key)


## 6. ストア文書の 数が 実装と 合っているか
func _check_store_numbers() -> void:
	var stages := 0
	for c in ProblemGen.COURSES:
		stages += (c["stages"] as Array).size()
	var isles := IslandDefs.count()
	var problems := 0
	for i in isles:
		problems += int(IslandDefs.of(i)["turns"])
	var kid := KidDefs.UNITS.size()
	var jhs: int = (StoryDefs.chapters_of("jhs") as Array).size()
	var hs: int = (StoryDefs.chapters_of("hs") as Array).size()
	var want := {
		"全65ステージ": stages == 65,
		"全 65 ステージ": stages == 65,
		"24 島": isles == 24,
		"337 問": problems == 337,
		"全23歩": kid == 23,
		"全 23 歩": kid == 23,
		"全21章": jhs == 21,
		"全 21 章": jhs == 21,
		"全9章": hs == 9,
		"全 9 章": hs == 9,
	}
	for doc in ["res://store/ストア掲載情報.md", "res://store/APPSTORE.md",
			"res://store/プレスリリース案.md", "res://store/課金登録情報.md"]:
		var s := _text(doc)
		if s == "":
			continue
		for phrase in want:
			if s.contains(phrase) and not bool(want[phrase]):
				fails.append("%s: 「%s」と 書いてあるが 実装と ちがう(ステージ %d / 島 %d / %d 問 / 小 %d / 中 %d / 高 %d)" % [
					doc.get_file(), phrase, stages, isles, problems, kid, jhs, hs])


## 7. 鳴らそうとしている 音が 実在するか(打ちまちがい)
func _check_sfx() -> void:
	var gs := _text("res://core/game_state.gd")
	var names := {}
	var i := gs.find("func _init_sfx")
	var j := gs.find("for sfx_name in defs", i)
	var defs := gs.substr(i, maxi(j - i, 0))
	var k := 0
	while true:
		var a := defs.find("\"", k)
		if a < 0:
			break
		var b := defs.find("\"", a + 1)
		if b < 0:
			break
		names[defs.substr(a + 1, b - a - 1)] = true
		k = b + 1
	for src in _sources():
		var s := _text(src)
		var p := 0
		while true:
			var a := s.find("play_sfx(\"", p)
			if a < 0:
				break
			var b := s.find("\"", a + 10)
			var nm := s.substr(a + 10, b - a - 10)
			p = b + 1
			if not names.has(nm):
				fails.append("%s: 音 \"%s\" は 作られていない" % [src.get_file(), nm])


## 8. 絵の部品(Icons)の 呼び出しが 実在するか
func _check_icons() -> void:
	var icons := _text("res://ui/icons.gd")
	for src in _sources():
		if src.ends_with("icons.gd"):
			continue
		var s := _text(src)
		var p := 0
		while true:
			var a := s.find("Icons.", p)
			if a < 0:
				break
			var b := s.find("(", a)
			if b < 0:
				break
			var fn := s.substr(a + 6, b - a - 6)
			p = b + 1
			if fn.strip_edges() == "" or fn.contains(" "):
				continue
			if not icons.contains("func %s(" % fn):
				fails.append("%s: Icons.%s() が 無い" % [src.get_file(), fn])


## 9. どこからも 行けない 画面が ないか
func _check_reachable() -> void:
	var all_refs := ""
	for src in _sources():
		all_refs += _text(src)
	var d := DirAccess.open("res://scenes")
	if d == null:
		return
	for f in d.get_files():
		if not f.ends_with(".tscn"):
			continue
		if f == "main.tscn":
			continue          # 起動画面
		if not all_refs.contains(f):
			fails.append("scenes/%s: どこからも 開かれていない(消し忘れ?)" % f)
