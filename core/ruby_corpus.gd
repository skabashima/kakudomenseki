class_name RubyCorpus
## ふりがなが 付く 文を ぜんぶ 集める。
##
## tests/ruby_check.gd が 見張る はんい。前は 本編の 問題文と 島取りの 画面だけを
## 見ていて、たからのちず・図鑑・解き方アニメが 抜けていた ―― そこに
## 「分度器(ぶんどうつわ)」のような 読みまちがいが のこっていた。


## ふりがなを 出す 画面が 使う 文を ぜんぶ かえす
static func texts() -> Array:
	var out: Array = []
	# 本編(中学受験レベル)の 問題まわり ― 解き方アニメの 1 行ずつも 見る
	for course in ProblemGen.COURSES:
		for st in course["stages"]:
			var sid := String(st["id"])
			if not Ruby.needed(sid):
				continue
			out.append(String(st["title"]))
			out.append(String(st["desc"]))
			for tier in 10:
				for k in 10:
					var rng := RandomNumberGenerator.new()
					rng.seed = 1200 + tier * 37 + k
					var p: Dictionary = ProblemGen.generate(sid, rng, tier)
					for key in ["q", "hint1", "hint2", "expl"]:
						out.append(String(p.get(key, "")))
					for s in p.get("steps", []):
						out.append(String((s as Dictionary).get("say", "")))
	# たからのちず(小学生)
	for u in KidDefs.UNITS:
		out.append(String(u["title"]))
		out.append(String(u["found"]))
		for ln in u["intro"]:
			out.append(String(ln))
	# 図鑑(たからのちず と ストーリーの 見つけた ことが ならぶ)
	for card in Zukan.cards():
		for key in ["name", "found", "from"]:
			out.append(String((card as Dictionary).get(key, "")))
	# 画面の 中で その場で 書いている 文
	for path in ["res://scenes/island.gd", "res://scenes/island_select.gd",
			"res://core/island_defs.gd", "res://scenes/kid_unit.gd",
			"res://scenes/kid_map.gd", "res://scenes/daily.gd",
			"res://scenes/zukan.gd", "res://scenes/stage_select.gd"]:
		out.append_array(_literals(path))
	return out


## ソースの 中の 日本語の 文字列を 取り出す
static func _literals(path: String) -> Array:
	var out: Array = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	var src := f.get_as_text()
	var i := 0
	while true:
		var a := src.find("\"", i)
		if a < 0:
			break
		var b := src.find("\"", a + 1)
		if b < 0:
			break
		var lit := src.substr(a + 1, b - a - 1)
		i = b + 1
		# ファイルの 場所を さす 文字列は 読む 文では ないので とばす。
		# 見分けに その 書き出しを そのまま 書くと、つじつまの 検査が
		# 「行き先の 無い 画面」と 取りちがえる。区切りの 記号だけで 見る
		if lit.contains("://"):
			continue
		for k in lit.length():
			var c := lit.unicode_at(k)
			if c >= 0x4E00 and c <= 0x9FFF:
				out.append(lit)
				break
	return out
