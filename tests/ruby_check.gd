extends SceneTree
## 小学生むけの文が「小 1 の漢字＋ふりがな」だけで書けているかを見張る。
##   godot --headless --path . -s tests/ruby_check.gd
##
## 見るところ(どれも 実際に 出ていた まちがい):
##   1. 小 1 で習わない漢字が「よみ なし」で のこっていないか
##   2. 漢字の かたまりが、人が 確かめていない 割れ方を していないか
##      ―― 「分度器」が 分(ぶん)+度(ど)+器(うつわ)= **ぶんどうつわ** に
##      なっていた。よみは 付いているので 1 だけでは 気づけない。
##      新しい 割れ方が 出たら、声に 出して 確かめてから
##      core/ruby.gd の SPLIT_OK に 足すか、WORDS に 語として 入れる。
##
## 見るはんい(core/ruby_corpus.gd)は「ふりがなを 出す 画面が 使う 文」ぜんぶ。
## 前は 本編の 問題文と 島取りの 画面だけで、たからのちず・図鑑・解き方アニメが
## 抜けていた ―― まちがいは そこに のこっていた。

var missing := {}          # 漢字の かたまり → 出てきた回数
var examples := {}         # かたまり → 出てきた文の例
var unreviewed := {}       # 見ていない 割れ方 → その読み


func _init() -> void:
	for t in RubyCorpus.texts():
		_scan(String(t))
	_report()


## 漢字の かたまりごとに、よみ が 付いているか・割れ方を 見ているか
func _scan(text: String) -> void:
	var i := 0
	while i < text.length():
		if not _is_kanji(text.unicode_at(i)):
			i += 1
			continue
		var j := i
		while j < text.length() and _is_kanji(text.unicode_at(j)):
			j += 1
		var run := text.substr(i, j - i)
		_check_run(run, text)
		i = j


func _check_run(run: String, text: String) -> void:
	var parts: Array = Ruby.parts(run)
	# 1. よみ が 付かないまま のこった 漢字(小 1 の字は そのままでよい)
	for p in parts:
		var seg: Dictionary = p
		if String(seg["r"]) != "":
			continue
		var s := String(seg["s"])
		for k in s.length():
			var ch := s.substr(k, 1)
			if _is_kanji(s.unicode_at(k)) and not Ruby.plain_ok(ch):
				missing[run] = int(missing.get(run, 0)) + 1
				if not examples.has(run):
					examples[run] = text
				return
	# 2. 2 つ以上に 割れたら、その 読みを 人が 見ているか
	if parts.size() <= 1 or Ruby.SPLIT_OK.has(run):
		return
	var yomi := ""
	for p2 in parts:
		var seg2: Dictionary = p2
		var r := String(seg2["r"])
		yomi += r if r != "" else String(seg2["s"])
	unreviewed[run] = yomi
	if not examples.has(run):
		examples[run] = text


func _report() -> void:
	if missing.is_empty() and unreviewed.is_empty():
		print("RUBY CHECK OK: 小 1 の漢字と ふりがな だけで書けている" \
			+ "(割れ方も %d とおり ぜんぶ 見たもの)" % Ruby.SPLIT_OK.size())
		quit(0)
		return
	var keys: Array = missing.keys()
	keys.sort_custom(func(a, b): return int(missing[a]) > int(missing[b]))
	for k in keys:
		print("よみ なし: %s  (%d 回)  例: %s" % [k, int(missing[k]), String(examples.get(k, ""))])
	var uk: Array = unreviewed.keys()
	uk.sort()
	for k in uk:
		print("見ていない 割れ方: %s → 「%s」  例: %s" % [
			k, String(unreviewed[k]), String(examples.get(k, ""))])
	print("RUBY CHECK FAILED: よみ なし %d 語 / 見ていない 割れ方 %d 語" % [
		keys.size(), uk.size()])
	quit(1)


func _is_kanji(code: int) -> bool:
	return code >= 0x4E00 and code <= 0x9FFF
