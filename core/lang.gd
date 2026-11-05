class_name L
## 言語(日本語 / English)。
##
## ■ しくみ
## ソースの 文は すべて 日本語の まま。英語は res://i18n/en.json に
## 「日本語の 文 → 英語の 文」の 表で 持つ(tools/i18n_sync.py が 表を そろえる)。
##   ・Label / Button の 文字は Godot が 自動で 表を 引く(auto_translate)
##   ・組み立てる 文("%d 問" % n など)は 組み立てる 前に L.t() で 型を 引く
##   ・RubyLabel と 図の 文字は 出す ところで L.t() を 通す
## 表に 無い 文は 日本語の まま 出る(tests/en_check.gd と ZUKEI_SCAN_JA が 見張る)。
##
## ■ 言語の 決まり方
## GameState.lang が "auto" なら 端末の 言語(日本語なら ja、それ以外は en)。
## タイトル画面の ボタンで ja / en を 切り替えられる(セーブに 残る)。
## テストでは 環境変数 ZUKEI_LANG=en で 強制できる。

const TABLE := "res://i18n/en.json"

static var _installed := false


## 日本語の 文を いまの 言語に。表に 無ければ そのまま
static func t(s: String) -> String:
	return TranslationServer.translate(s)


## いま 英語か
static func en() -> bool:
	return TranslationServer.get_locale().begins_with("en")


## 表を Godot に 登録する(起動時に 1 回)
static func install() -> void:
	if _installed:
		return
	_installed = true
	var f := FileAccess.open(TABLE, FileAccess.READ)
	if f == null:
		push_warning("i18n: %s が 読めない" % TABLE)
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("i18n: %s が 表に なっていない" % TABLE)
		return
	var tr := Translation.new()
	tr.locale = "en"
	for k in data:
		var v := String(data[k])
		if v != "":
			tr.add_message(String(k), v)
	TranslationServer.add_translation(tr)


## "ja" / "en" に 切り替える。"auto" なら 端末の 言語から 決める
static func apply(code: String) -> void:
	var c := code
	var forced := OS.get_environment("ZUKEI_LANG")
	if forced != "":
		c = forced
	if c == "auto" or c == "":
		c = "ja" if OS.get_locale_language() == "ja" else "en"
	TranslationServer.set_locale(c)


## 日本語(かな・漢字・全角の 記号)が 入っているか
static func has_ja(s: String) -> bool:
	for i in s.length():
		var u := s.unicode_at(i)
		if (u >= 0x3040 and u <= 0x30FF) or (u >= 0x4E00 and u <= 0x9FFF) \
				or (u >= 0x3001 and u <= 0x3003) or (u >= 0x3008 and u <= 0x3011) \
				or (u >= 0xFF01 and u <= 0xFF5E):
			return true
	return false
