extends Node
## 日本語 ⇄ 英語の 切り替えが 本当に 効くかを 調べる(--headless 可)。
##   godot --headless --path . res://tests/lang_check.tscn
##
## 1.4.0 の 書き出し前に、日本語の 端末でも 英語が 出て、右上の ボタンで
## 切り替えても 英語の ままに なる 不具合が あった(英語の 表を 登録した ままだと、
## Godot は 日本語に 表が 無いので 予備の 言語 = en の 表を 引いて しまう)。
## L.t() と、Label が 自動で 引く 訳(atr)の 両方を 見る。

var bad: Array = []


func _ready() -> void:
	# ZUKEI_LANG で 言語を 固定して 走らせても、ここでは 切り替えを 見たいので 外す
	OS.set_environment("ZUKEI_LANG", "")
	var lbl := Label.new()
	add_child(lbl)
	for code in ["ja", "en", "ja", "en", "auto", "ja"]:
		L.apply(code)
		var want_en: bool = code == "en" or (code == "auto" and OS.get_locale_language() != "ja")
		for s in ["図形ハンター", "角度", "面積"]:
			var a := L.t(s)
			var b := lbl.atr(s)
			if want_en:
				if L.has_ja(a) or L.has_ja(b):
					bad.append("%s: 英語のはずが 日本語 %s / %s" % [code, a, b])
			elif a != s or b != s:
				bad.append("%s: 日本語のはずが %s / %s" % [code, a, b])
		if L.en() != want_en:
			bad.append("%s: L.en() = %s" % [code, L.en()])
	# セーブの 言語を 切り替えた ときも 同じ(タイトル画面の ボタンが 通る 道)
	var keep := GameState.lang
	GameState.lang = "en"
	L.apply(GameState.lang)
	if L.has_ja(L.t("角度")):
		bad.append("GameState.lang=en で 英語に ならない")
	GameState.lang = "ja"
	L.apply(GameState.lang)
	if L.t("角度") != "角度":
		bad.append("GameState.lang=ja で 日本語に もどらない")
	GameState.lang = keep
	L.apply(keep)
	if bad.is_empty():
		print("LANG CHECK OK")
		get_tree().quit(0)
	else:
		for b in bad:
			print("FAIL: " + str(b))
		print("LANG CHECK FAILED: %d issues" % bad.size())
		get_tree().quit(1)
