extends SceneTree
## 小学生むけの文が「小 1 の漢字＋ふりがな」だけで書けているかを見張る。
##   godot --headless --path . -s tests/ruby_check.gd
##
## 中学受験レベルの問題文・ヒント・解説・ステージ名と、ストーリーの中学受験の章、
## それに試作の画面の文を、ふりがなを付けたあとで走査する。
## 小 1 で習わない漢字が「よみ なし」で残っていたら落とす。

var missing := {}          # 漢字の かたまり → 出てきた回数
var examples := {}         # かたまり → 出てきた文の例


func _init() -> void:
	for course in ProblemGen.COURSES:
		for st in course["stages"]:
			var sid := String(st["id"])
			if not Ruby.needed(sid):
				continue
			_scan(Ruby.apply(String(st["title"])), sid + " の名前")
			_scan(Ruby.apply(String(st["desc"])), sid + " の説明")
			var rng := RandomNumberGenerator.new()
			for seed_i in 12:
				rng.seed = 900 + seed_i
				var p: Dictionary = ProblemGen.generate(sid, rng, seed_i % 10)
				for key in ["q", "hint1", "hint2", "expl"]:
					_scan(Ruby.apply(String(p.get(key, ""))), sid)
	for ch in StoryDefs.CHAPTERS:
		if String(ch.get("level", "")) != "中学受験":
			continue
		_scan(Ruby.apply(String(ch["title"])), String(ch["id"]))
		_scan(Ruby.apply(String(ch["found"])), String(ch["id"]))
		_scan(Ruby.apply(String(ch["place"])), String(ch["id"]))
		_scan(Ruby.apply("第%d章 %s" % [StoryDefs.chapter_index(String(ch["id"])) + 1,
			String(ch["title"])]), String(ch["id"]))
		for sc in ch["scenes"]:
			for key in ["title", "lead", "question", "after"]:
				_scan(Ruby.apply(String((sc as Dictionary).get(key, ""))), String(ch["id"]))
			for line in (sc as Dictionary).get("lines", []):
				_scan(Ruby.apply(String(line)), String(ch["id"]))
			for c in (sc as Dictionary).get("choices", []):
				_scan(Ruby.apply(String(c)), String(ch["id"]))

	_report()


func _report() -> void:
	if missing.is_empty():
		print("RUBY CHECK OK: 小 1 の漢字と ふりがな だけで書けている")
		quit(0)
	else:
		var keys: Array = missing.keys()
		keys.sort_custom(func(a, b): return int(missing[a]) > int(missing[b]))
		for k in keys:
			print("よみ なし: %s  (%d 回)  例: %s" % [k, int(missing[k]), String(examples.get(k, ""))])
		print("RUBY CHECK FAILED: %d 語" % keys.size())
		quit(1)


## 漢字の かたまり ごとに見て、うしろに (よみ) が付いていなければ小 1 の字だけか確かめる
func _scan(text: String, where: String) -> void:
	var i := 0
	while i < text.length():
		if not _is_kanji(text.unicode_at(i)):
			i += 1
			continue
		var j := i
		while j < text.length() and _is_kanji(text.unicode_at(j)):
			j += 1
		var run := text.substr(i, j - i)
		var has_ruby := j < text.length() and text.substr(j, 1) == "("
		if not has_ruby:
			var need := false
			for k in run.length():
				if not Ruby.plain_ok(run.substr(k, 1)):
					need = true
			if need:
				missing[run] = int(missing.get(run, 0)) + 1
				if not examples.has(run):
					examples[run] = text.substr(maxi(i - 12, 0), 34)
		i = j


func _is_kanji(code: int) -> bool:
	return code >= 0x4E00 and code <= 0x9FFF
