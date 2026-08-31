extends Control
## 「今日の図形」の 画面。1 日 1 問、みんな 同じ 問題。
##
## 解いたら れんぞく日数が のび、ネタバレ なしの 文を 写して 貼れる。
## 通信は しない(日付から たねを 作るので、どの 端末でも 同じ 問題に なる)。

var problem: Dictionary = {}
var figure: FigureView
var keypad: Keypad
var msg: RubyLabel
var head: RubyLabel
var input_text := ""
var miss := 0
var start_msec := 0
var done := false
var answer_row: HBoxContainer
var share_btn: Button


func _ready() -> void:
	GameState.play_bgm("think")
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.13, 0.22)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var ins := GameState.safe_insets()
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 14
	root.offset_right = -14
	root.offset_top = float(ins["top"]) + 8.0
	root.offset_bottom = -float(ins["bottom"]) - 8.0
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	var back := Button.new()
	back.text = "もどる"
	back.custom_minimum_size = Vector2(140, 62)
	back.add_theme_font_size_override("font_size", 24)
	back.focus_mode = Control.FOCUS_NONE
	GameState.style_button(back, Color(0.28, 0.32, 0.44))
	back.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		GameState.change_scene("res://scenes/main.tscn"))
	top.add_child(back)
	head = RubyLabel.new()
	head.font_size = 26
	head.ruby_size = 13
	head.color = Color(1.0, 0.88, 0.45)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(head)

	figure = FigureView.new()
	figure.size_flags_vertical = Control.SIZE_EXPAND_FILL
	figure.custom_minimum_size = Vector2(0, 320)
	root.add_child(figure)
	figure.add_tools()

	msg = RubyLabel.new()
	msg.font_size = 25
	msg.ruby_size = 13
	msg.color = Color(0.92, 0.95, 1.0)
	msg.custom_minimum_size = Vector2(0, 108)
	root.add_child(msg)

	keypad = Keypad.new()
	keypad.key_pressed.connect(_on_key)
	root.add_child(keypad)

	answer_row = HBoxContainer.new()
	answer_row.add_theme_constant_override("separation", 10)
	root.add_child(answer_row)
	var calc := Button.new()
	calc.text = "＝ 計算"
	calc.custom_minimum_size = Vector2(0, 84)
	calc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calc.focus_mode = Control.FOCUS_NONE
	calc.add_theme_font_size_override("font_size", 27)
	GameState.style_button(calc, Color(0.24, 0.42, 0.72))
	calc.pressed.connect(_calc)
	answer_row.add_child(calc)
	var ans := Button.new()
	ans.text = "こたえる"
	ans.custom_minimum_size = Vector2(0, 84)
	ans.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ans.size_flags_stretch_ratio = 1.6
	ans.focus_mode = Control.FOCUS_NONE
	ans.add_theme_font_size_override("font_size", 29)
	GameState.style_button(ans, Color(0.22, 0.55, 0.35))
	ans.pressed.connect(_submit)
	answer_row.add_child(ans)

	share_btn = Button.new()
	share_btn.text = "けっかを 写す"
	share_btn.custom_minimum_size = Vector2(0, 84)
	share_btn.focus_mode = Control.FOCUS_NONE
	share_btn.add_theme_font_size_override("font_size", 27)
	share_btn.visible = false
	GameState.style_button(share_btn, Color(0.30, 0.40, 0.56))
	share_btn.pressed.connect(_share)
	root.add_child(share_btn)

	problem = Daily.make(GameState.free_stage_limit())
	figure.set_spec(problem["fig"])
	keypad.unit_lbl.text = String(problem.get("unit", ""))
	start_msec = Time.get_ticks_msec()
	_refresh()


func _refresh() -> void:
	head.set_ruby_text("  今日の図形 %s   %d日れんぞく" % [
		Daily.date_label(), GameState.daily_streak], true)
	if done:
		msg.set_ruby_text("できた! %s  ―  みんな 今日は 同じ 問題です" % String(problem["q"]), true)
		keypad.visible = false
		answer_row.visible = false
		share_btn.visible = true
	elif GameState.daily_done():
		msg.set_ruby_text("今日の分は もう 解きました。また あした。\n%s" % String(problem["q"]), true)
	else:
		msg.set_ruby_text(String(problem["q"]), true)


func _on_key(k: String) -> void:
	if done:
		return
	GameState.play_sfx("type")
	input_text = Keypad.apply(input_text, k)
	keypad.answer_lbl.text = input_text


func _calc() -> void:
	if input_text == "" or done:
		return
	var res: Dictionary = ExprEval.eval(input_text)
	if not bool(res["ok"]):
		GameState.play_sfx("fail")
		msg.set_ruby_text(String(res["err"]), true)
		return
	GameState.play_sfx("type")
	input_text = ExprEval.fmt(float(res["value"]))
	keypad.answer_lbl.text = input_text


func _submit() -> void:
	if done:
		return
	var v := Keypad.value_of(input_text)
	if is_nan(v):
		GameState.play_sfx("fail")
		msg.set_ruby_text("数を いれてね(式のままでも いいよ)", true)
		return
	if absf(v - float(problem["answer"])) > maxf(float(problem.get("tol", 0.01)), 0.01):
		miss += 1
		GameState.play_sfx("fail")
		input_text = ""
		keypad.answer_lbl.text = ""
		msg.set_ruby_text("ちがうみたい(%d回め)。もう一度。\n%s" % [miss, String(problem["q"])], true)
		return
	done = true
	GameState.play_sfx("win")
	GameState.record_daily()
	_refresh()


func _share() -> void:
	var sec := float(Time.get_ticks_msec() - start_msec) / 1000.0
	var text := Daily.share_text(miss, sec, GameState.daily_streak,
		String(problem["stage_title"]))
	DisplayServer.clipboard_set(text)
	GameState.play_sfx("tap")
	msg.set_ruby_text("写しました。SNS などに 貼れます。\n" + text, false)
