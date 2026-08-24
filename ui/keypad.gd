class_name Keypad
extends VBoxContainer
## 解答欄と電卓のキーパッド。本編(problem.gd)と試作で同じものを使う。
##
## ここは見た目と入力だけを持ち、押されたキーを key_pressed で知らせる。
## 入力した文字をどう扱うか(式として計算するか、単位を何にするか)は
## 使う側が決める ―― 画面ごとに答え方が違っても、指の感触は同じにしたいため。

signal key_pressed(k: String)

var answer_lbl: Label
var unit_lbl: Label
var answer_panel: PanelContainer     # まちがえたときに ゆらす

const KEYS := [
	"7", "8", "9", "BS", "C",
	"4", "5", "6", "×", "÷",
	"1", "2", "3", "+", "−",
	"0", ".", "(", ")", "√",
]


func _init() -> void:
	add_theme_constant_override("separation", 12)

	var ans_row := HBoxContainer.new()
	ans_row.add_theme_constant_override("separation", 12)
	add_child(ans_row)
	answer_panel = PanelContainer.new()
	answer_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	answer_panel.add_theme_stylebox_override("panel",
		GameState.flat_style(Color(0.13, 0.19, 0.33, 1.0), 14))
	ans_row.add_child(answer_panel)
	answer_lbl = Label.new()
	answer_lbl.text = ""
	answer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	answer_lbl.add_theme_font_size_override("font_size", 44)
	answer_lbl.custom_minimum_size = Vector2(0, 72)
	answer_panel.add_child(answer_lbl)
	unit_lbl = Label.new()
	unit_lbl.add_theme_font_size_override("font_size", 30)
	unit_lbl.add_theme_color_override("font_color", Color(0.8, 0.87, 1.0))
	unit_lbl.custom_minimum_size = Vector2(70, 0)
	ans_row.add_child(unit_lbl)

	var pad := GridContainer.new()
	pad.columns = 5
	pad.add_theme_constant_override("h_separation", 10)
	pad.add_theme_constant_override("v_separation", 10)
	add_child(pad)
	var op_col := Color(0.33, 0.3, 0.5)
	for k in KEYS:
		var btn := Button.new()
		# けすキーは同梱フォントに ⌫(U+232B)が無いので図形で描く
		if k == "BS":
			var bs := Icons.backspace(42.0, Color(0.95, 0.9, 0.9))
			bs.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
			btn.add_child(bs)
		else:
			btn.text = k
		btn.custom_minimum_size = Vector2(0, 80)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 32)
		var col := Color(0.2, 0.28, 0.46)
		if k == "BS" or k == "C":
			col = Color(0.45, 0.3, 0.3)
		elif k in ["×", "÷", "+", "−", "(", ")", "√"]:
			col = op_col
		GameState.style_button(btn, col)
		btn.pressed.connect(func() -> void: key_pressed.emit(k))
		pad.add_child(btn)


## 押されたキーを、いま入力中の文字に反映する(共通の決まり)
static func apply(text: String, k: String) -> String:
	match k:
		"BS":
			return text.substr(0, text.length() - 1)
		"C":
			return ""
		_:
			if text.length() >= 26:
				return text
			return text + k


## 入力を数にする。式でもよい(12×8÷2 など)。読めなければ NAN
static func value_of(text: String) -> float:
	if text.strip_edges() == "":
		return NAN
	var res: Dictionary = ExprEval.eval(text)
	if not bool(res.get("ok", false)):
		return NAN
	return float(res["value"])
