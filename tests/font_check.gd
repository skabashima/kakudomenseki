extends SceneTree
## 画面に出る文字が同梱フォントに入っているかを全部調べる(--headless 可)。
##   godot --headless --path . -s tests/font_check.gd
##
## Android は OS のフォント補完が効かない(テーマのフォントを差し替えているため)。
## 同梱の Noto Sans JP に無い字を使うと **豆腐(□)** になる。実機でしか気づけないので、
## ソースの文字列リテラルを機械で洗い出して照合する。
##
## 実際に踏んだ例: 👑(U+1F451) 🔒(U+1F512) ✏(U+270F) が豆腐になっていた。
## ★☆♥♡→←▶◆ などはフォントに入っているので使ってよい。

const FONT_PATH := "res://assets/fonts/NotoSansJP.ttf"
## 調べるソース(addons はプラグイン提供なので対象外)
const DIRS := ["res://core", "res://scenes", "res://ui", "res://tools"]

var font: FontFile
var missing: Dictionary = {}   # 文字 -> [出てくる場所, ...]
var checked := 0


func _init() -> void:
	font = load(FONT_PATH)
	if font == null:
		print("FONT CHECK FAILED: %s が読めない" % FONT_PATH)
		quit(1)
		return
	for d in DIRS:
		_scan_dir(d)
	if missing.is_empty():
		print("FONT CHECK OK: %d 種類の文字はすべて同梱フォントにある" % checked)
		quit(0)
		return
	for ch in missing:
		var locs: Array = missing[ch]
		print("FAIL: %s U+%04X が同梱フォントに無い(%d 箇所) 例: %s" % [
			ch, String(ch).unicode_at(0), locs.size(), String(locs[0])])
	print("FONT CHECK FAILED: %d 種類が豆腐になる" % missing.size())
	quit(1)


func _scan_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var full := path.path_join(name)
		if dir.current_is_dir():
			_scan_dir(full)
		elif name.ends_with(".gd"):
			_scan_file(full)
		name = dir.get_next()
	dir.list_dir_end()


func _scan_file(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		return
	var line_no := 0
	for line in text.split("\n"):
		line_no += 1
		var stripped := line.strip_edges()
		if stripped.begins_with("#"):
			continue   # コメントは画面に出ない
		for s in _string_literals(line):
			for ch in s:
				_check_char(ch, "%s:%d" % [path, line_no])


## 行の中の "..." を取り出す(エスケープは考慮しない。豆腐の検出には十分)
func _string_literals(line: String) -> Array:
	var out: Array = []
	var i := 0
	while true:
		var a := line.find("\"", i)
		if a < 0:
			break
		var b := line.find("\"", a + 1)
		if b < 0:
			break
		out.append(line.substr(a + 1, b - a - 1))
		i = b + 1
	return out


var _seen: Dictionary = {}


func _check_char(ch: String, where: String) -> void:
	if ch == "" or ch.unicode_at(0) < 0x80:
		return   # ASCII はどのフォントにもある
	if _seen.has(ch):
		if missing.has(ch):
			(missing[ch] as Array).append(where)
		return
	_seen[ch] = true
	checked += 1
	if not font.has_char(ch.unicode_at(0)):
		missing[ch] = [where]
