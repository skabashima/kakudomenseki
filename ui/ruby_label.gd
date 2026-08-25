class_name RubyLabel
extends Control
## 漢字の上に よみ を 小さく乗せて描くラベル(ルビ)。
##
## Godot の Label にはルビが無いので、文字を 1 つずつ置いて自分で描く。
## かっこ書き「面積(めんせき)」だと文が長くなって読みにくいので、
## 小学生むけの画面はこちらを使う。
##
## 使い方:
##   var l := RubyLabel.new()
##   l.font_size = 32
##   l.set_ruby_text("三角形の面積は?", true)   # 第 2 引数が false なら ふりがな なし

var font_size := 30
var ruby_size := 16
var color := Color(0.95, 0.97, 1.0)
var line_gap := 1.28            # 行の高さの倍率

var _atoms: Array = []          # {"s": 文字, "r": よみ, "w": はば}
var _font: Font


func _init() -> void:
	_font = ThemeDB.fallback_font
	clip_contents = false
	# 見せるだけのラベル。ボタンの上に置いても、指の操作を邪魔しない
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## 文をセットする。with_ruby が true なら 小 1 以外の漢字に よみ を付ける
func set_ruby_text(text: String, with_ruby: bool) -> void:
	_atoms = []
	var parts: Array = Ruby.parts(text) if with_ruby else [{"s": text, "r": ""}]
	for p in parts:
		var seg: Dictionary = p
		if String(seg["r"]) != "":
			_atoms.append(_atom(String(seg["s"]), String(seg["r"])))
		else:
			# ふりがなの付かないところは 1 文字ずつ(どこでも行を折り返せる)
			var s := String(seg["s"])
			for i in s.length():
				_atoms.append(_atom(s.substr(i, 1), ""))
	update_minimum_size()
	queue_redraw()


func _atom(s: String, r: String) -> Dictionary:
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	if r != "":
		# よみ が長いときは少しはみ出させる(そのぶん字間が空きすぎない)
		w = maxf(w, _font.get_string_size(r, HORIZONTAL_ALIGNMENT_LEFT, -1, ruby_size).x * 0.86)
	return {"s": s, "r": r, "w": w}


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		update_minimum_size()
		queue_redraw()


## 行に分ける。行頭に来てほしくない文字は、前の行にぶら下げる
func _lines(width: float) -> Array:
	var out: Array = []
	var line: Array = []
	var x := 0.0
	for i in _atoms.size():
		var a: Dictionary = _atoms[i]
		var s := String(a["s"])
		if s == "\n":
			out.append(line)
			line = []
			x = 0.0
			continue
		if x + float(a["w"]) > width and not line.is_empty() and not _hangs(s):
			out.append(line)
			line = []
			x = 0.0
		line.append(a)
		x += float(a["w"])
	if not line.is_empty():
		out.append(line)
	return out


static func _hangs(s: String) -> bool:
	return s in ["。", "、", "」", ")", "?", "!", "・", "°"]


## ふりがなが 1 つも無い文では、上の空きを取らない(空白だけが空くのを防ぐ)
func _has_ruby() -> bool:
	for a in _atoms:
		if String((a as Dictionary)["r"]) != "":
			return true
	return false


func _line_height() -> float:
	return font_size * line_gap + (ruby_size * 1.05 if _has_ruby() else 0.0)


func _get_minimum_size() -> Vector2:
	var w := size.x
	if w < 10.0:
		return Vector2(0, _line_height())
	return Vector2(0, _lines(w).size() * _line_height())


func _draw() -> void:
	if _atoms.is_empty():
		return
	var lines := _lines(size.x)
	var lh := _line_height()
	var ruby_h := ruby_size * 1.05 if _has_ruby() else 0.0
	for li in lines.size():
		var y := li * lh
		var baseline := y + ruby_h + _font.get_ascent(font_size)
		var x := 0.0
		for a in lines[li]:
			var seg: Dictionary = a
			draw_string(_font, Vector2(x, baseline), String(seg["s"]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
			if String(seg["r"]) != "":
				var base_w := _font.get_string_size(String(seg["s"]),
					HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				var rw := _font.get_string_size(String(seg["r"]),
					HORIZONTAL_ALIGNMENT_LEFT, -1, ruby_size).x
				draw_string(_font, Vector2(x + (base_w - rw) * 0.5,
					y + _font.get_ascent(ruby_size)), String(seg["r"]),
					HORIZONTAL_ALIGNMENT_LEFT, -1, ruby_size, color)
			x += float(seg["w"])
