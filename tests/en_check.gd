extends Node
## 英語で 出した とき、日本語が 残らないかを 調べる(--headless 可)。
##   godot --headless --path . res://tests/en_check.tscn
##
## 1) 表(i18n/en/*.json): 値が 空、値に 日本語、%d %s の 並びが 元と ちがう
## 2) 全ステージ × 10 段 × SEEDS で 問題を 作り、文・ヒント・解説・図の 文字の
##    どれにも 日本語が 残らないか(表に 無い 文は そのまま 出て くるので 見つかる)
## 3) ストーリー・たからのちず・島・展開図・段位・コース の データの 文
## 4) StoryTasks の 依頼文(章ごと × SEEDS)
##
## 画面に 出る 文字の 見張りは GameState の ZUKEI_SCAN_JA(既存の 画面テストを
## ZUKEI_LANG=en と いっしょに 走らせると、JA_LEAK として 出る)。

const SEEDS := 24

var bad: Array = []
var seen: Dictionary = {}
var checked := 0


func _ready() -> void:
	TranslationServer.set_locale("en")
	_check_table()
	_check_problems()
	_check_data()
	_check_tasks()
	if bad.is_empty():
		print("EN CHECK OK: %d strings checked" % checked)
		get_tree().quit(0)
	else:
		for b in bad:
			print("FAIL: " + str(b))
		print("EN CHECK FAILED: %d issues" % bad.size())
		get_tree().quit(1)


# ---------------------------------------------------------
# 1) 表
# ---------------------------------------------------------

func _check_table() -> void:
	var dir := DirAccess.open("res://i18n/en")
	if dir == null:
		bad.append("i18n/en が 開けない")
		return
	var spec := RegEx.new()
	spec.compile("%[-+0#]*\\d*(\\.\\d+)?([dsfx])")
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var fa := FileAccess.open("res://i18n/en/" + f, FileAccess.READ)
		var data = JSON.parse_string(fa.get_as_text())
		if typeof(data) != TYPE_DICTIONARY:
			bad.append("%s: 表に なっていない" % f)
			continue
		for k in data:
			checked += 1
			var v := String(data[k])
			if v == "":
				bad.append("%s: 未訳 %s" % [f, k])
			elif L.has_ja(v) and v != String(k):
				bad.append("%s: 訳に 日本語 %s → %s" % [f, k, v])
			elif _specs(spec, String(k)) != _specs(spec, v):
				bad.append("%s: %% の 並びが ちがう %s → %s" % [f, k, v])


func _specs(re: RegEx, s: String) -> String:
	var out := ""
	for m in re.search_all(s.replace("%%", "")):
		out += m.get_string(2)
	return out


# ---------------------------------------------------------
# 2) 問題
# ---------------------------------------------------------

func _check_problems() -> void:
	for course in ProblemGen.COURSES:
		for stage in course["stages"]:
			var sid := String(stage["id"])
			for i in SEEDS:
				var rng := RandomNumberGenerator.new()
				rng.seed = hash(sid) + i * 7919
				var p: Dictionary = ProblemGen.generate(sid, rng, i % 10)
				_walk(p, "problem " + sid)


## 文字列の 葉を ぜんぶ 見る。表を 引いた あとに 日本語が 残れば 失敗
func _walk(v: Variant, where: String) -> void:
	match typeof(v):
		TYPE_STRING:
			checked += 1
			var s := String(v)
			if s == "":
				return
			var t := L.t(s)
			if L.has_ja(t) and not seen.has(t):
				seen[t] = true
				bad.append("%s: %s" % [where, t.replace("\n", "⏎")])
		TYPE_DICTIONARY:
			for k in v:
				_walk(v[k], where)
		TYPE_ARRAY:
			for e in v:
				_walk(e, where)


# ---------------------------------------------------------
# 3) データ
# ---------------------------------------------------------

func _check_data() -> void:
	_walk(ProblemGen.COURSES, "courses")
	_walk(GameState.RANKS, "ranks")
	_walk(KidDefs.UNITS, "kid_defs")
	_walk(StoryDefs.CHAPTERS, "story_defs")
	_walk(StoryHS.chapters(), "story_hs")
	_walk(IslandDefs.ISLANDS, "islands")
	_walk(IslandDefs.RANGES, "island_ranges")
	_walk(Zukan.cards(), "zukan")
	for n in NetDefs.all():
		_walk(n.get("hint", ""), "net " + String(n["id"]))
		_walk(n.get("solid", ""), "net " + String(n["id"]))
	for i in 3:
		var rng := RandomNumberGenerator.new()
		rng.seed = 100 + i
		_walk(Daily.make(0), "daily")


# ---------------------------------------------------------
# 4) ストーリーの 依頼
# ---------------------------------------------------------

func _check_tasks() -> void:
	var kinds: Dictionary = {}
	for ch in StoryDefs.CHAPTERS:
		for sc in ch["scenes"]:
			if String(sc.get("type", "")) == "solve":
				kinds[String(sc["fig"])] = true
	for ch in StoryHS.chapters():
		for sc in ch["scenes"]:
			if String(sc.get("type", "")) == "solve":
				kinds[String(sc["fig"])] = true
	for k in kinds:
		for i in SEEDS:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(k) + i
			_walk(StoryTasks.make(k, rng), "task " + k)
