extends Control
## チャレンジ選択。タイムアタック(コース別/全部)とサバイバル。

func _ready() -> void:
	GameState.play_bgm("map")
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.14, 0.26)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var ins := GameState.safe_insets()
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_top = 20.0 + float(ins["top"])
	vbox.offset_left = 30.0
	vbox.offset_right = -30.0
	vbox.offset_bottom = -16.0 - float(ins["bottom"])
	vbox.add_theme_constant_override("separation", 14)
	add_child(vbox)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	vbox.add_child(head)
	var back := Button.new()
	back.text = "← もどる"
	back.custom_minimum_size = Vector2(170, 64)
	back.add_theme_font_size_override("font_size", 24)
	GameState.style_button(back, Color(0.28, 0.32, 0.44))
	back.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		GameState.change_scene("res://scenes/main.tscn"))
	head.add_child(back)
	var title := Label.new()
	title.text = "チャレンジ"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	head.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	DragScroll.attach(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)

	_section(list, "タイムアタック ― 3分で何問とける?")
	for c in ProblemGen.COURSES:
		var cid := String(c["id"])
		_challenge_card(list, String(c["name"]), "time:" + cid, c["color"],
			GameState.challenge_needs_purchase("time", cid), func() -> void:
				_start("time", cid))
	_challenge_card(list, "全コースミックス", "time:all", Color(0.65, 0.5, 0.2),
		GameState.challenge_needs_purchase("time", "all"), func() -> void:
			_start("time", "all"))

	_section(list, "サバイバル ― ミス3回でおわり。どこまでいける?")
	_challenge_card(list, "サバイバル(全コース)", "survival", Color(0.6, 0.3, 0.35),
		GameState.challenge_needs_purchase("survival", "all"), func() -> void:
			_start("survival", "all"))

	# 未購入のときは、無料で遊べる範囲をはっきり書いておく
	if not GameState.premium and not GameState.debug_unlock_all:
		var note := Label.new()
		note.text = "無料で遊べるのは タイムアタック(角度編)だけです。出題は各編の最初の %d ステージから。" \
			% GameState.FREE_STAGES_PER_COURSE
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.add_theme_font_size_override("font_size", 20)
		note.add_theme_color_override("font_color", Color(0.7, 0.77, 0.9))
		list.add_child(note)


func _start(mode: String, course_id: String) -> void:
	GameState.mode = mode
	GameState.challenge_course = course_id
	GameState.change_scene("res://scenes/problem.tscn")


func _section(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.87, 1.0))
	parent.add_child(lbl)


## paid = 未購入で遊べないチャレンジ。押すと解放画面へ飛ばす(隠さずに見せて売る)
func _challenge_card(parent: Control, text: String, best_key: String, color: Color,
		paid: bool, cb: Callable) -> void:
	var btn := Button.new()
	var best := int(GameState.challenge_best.get(best_key, 0))
	btn.text = text + ("\n全ステージ解放で遊べます" if paid \
		else ("   自己ベスト %d 問" % best if best > 0 else ""))
	btn.custom_minimum_size = Vector2(0, 96)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 24 if paid else 28)
	GameState.style_button(btn, Color(0.42, 0.33, 0.14) if paid else color)
	btn.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		if paid:
			GameState.change_scene("res://scenes/store.tscn")
		else:
			cb.call())
	parent.add_child(btn)
