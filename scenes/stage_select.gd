extends Control
## ステージ一覧。コース内で前のステージをクリアすると次が開く。

var course: Dictionary


func _ready() -> void:
	GameState.play_bgm("map")
	course = ProblemGen.course_by_id(GameState.current_course)
	var col: Color = course["color"]

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
	vbox.add_theme_constant_override("separation", 12)
	add_child(vbox)

	# ヘッダー: 戻る + コース名
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
	title.text = String(course["name"])
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", col.lightened(0.45))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)

	var sub := Label.new()
	sub.text = String(course["sub"])
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.75, 0.82, 0.94))
	vbox.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	DragScroll.attach(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	var stages: Array = course["stages"]
	var last_level := ""
	for i in stages.size():
		# レベルが変わるところに見出しを入れる(中学受験 → 高校受験 → 大学受験)
		var lv := ProblemGen.level_name(String(stages[i]["id"]))
		if lv != last_level:
			last_level = lv
			var head_lbl := Label.new()
			head_lbl.text = "― %s ―" % lv
			head_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			head_lbl.add_theme_font_size_override("font_size", 24)
			head_lbl.add_theme_color_override("font_color", col.lightened(0.5))
			list.add_child(head_lbl)
		list.add_child(_stage_card(i, stages[i], col))


func _stage_card(index: int, stage: Dictionary, col: Color) -> Control:
	var id := String(stage["id"])
	var unlocked: bool = GameState.is_stage_unlocked(String(course["id"]), index)
	# 有料ステージ(未購入)は「見せて売る」: タイトルは見せたまま、タップで解放画面へ
	var paid := GameState.needs_purchase(index)
	var star_count := int(GameState.stars.get(id, 0))
	var best := int(GameState.scores.get(id, 0))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 108)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.disabled = not unlocked and not paid
	if paid:
		GameState.style_button(btn, Color(0.42, 0.33, 0.14))
		btn.pressed.connect(func() -> void:
			GameState.play_sfx("tap")
			GameState.change_scene("res://scenes/store.tscn"))
	elif unlocked:
		GameState.style_button(btn, col if star_count == 0 else col.darkened(0.15))
		btn.pressed.connect(func() -> void:
			GameState.play_sfx("tap")
			GameState.current_stage = index
			GameState.mode = "normal"
			GameState.change_scene("res://scenes/problem.tscn"))
	btn.clip_contents = true

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 22.0
	hbox.offset_right = -18.0
	hbox.add_theme_constant_override("separation", 14)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)

	var num := Label.new()
	num.text = "%02d" % (index + 1)
	num.add_theme_font_size_override("font_size", 40)
	num.add_theme_color_override("font_color",
		Color(1, 1, 1, 0.9) if (unlocked or paid) else Color(0.7, 0.72, 0.8, 0.5))
	num.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(num)

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_theme_constant_override("separation", 2)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(mid)
	# 名前は未開放でも見せる(何が待っているか分かるほうが進めたくなる)。
	# 開いていないことは右の錠前とボタンの色で示す。
	# 中学受験(小学生が遊ぶ)のステージは、漢字の上に よみ を付ける
	var kids := Ruby.needed(String(stage["id"]))
	var t := RubyLabel.new()
	t.font_size = 30
	t.ruby_size = 15
	t.color = Color.WHITE if (unlocked or paid) else Color(0.78, 0.82, 0.9)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.set_ruby_text(String(stage["title"]), kids)
	mid.add_child(t)
	var d := RubyLabel.new()
	d.font_size = 21
	d.ruby_size = 12
	d.color = Color(0.85, 0.9, 1.0, 0.75)
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	d.set_ruby_text("全ステージ解放で遊べます" if paid else String(stage["desc"]), kids)
	mid.add_child(d)

	var right := VBoxContainer.new()
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.add_theme_constant_override("separation", 0)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(right)
	if not unlocked and not paid:
		# 錠前は絵文字だと Android で豆腐になるので図形で描く
		right.add_child(Icons.lock(34.0, Color(0.75, 0.8, 0.9, 0.6)))
	else:
		var stars_lbl := Label.new()
		var s := ""
		for i in 3:
			s += "★" if i < star_count else "☆"
		stars_lbl.text = "解放" if paid else s
		stars_lbl.add_theme_font_size_override("font_size", 26 if paid else 30)
		stars_lbl.add_theme_color_override("font_color",
			Color(1.0, 0.84, 0.3) if (paid or star_count > 0) else Color(0.75, 0.8, 0.9, 0.6))
		right.add_child(stars_lbl)
	if best > 0:
		var b := Label.new()
		b.text = "%d点" % best
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		b.add_theme_font_size_override("font_size", 20)
		b.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0, 0.8))
		right.add_child(b)
	row.add_child(btn)

	# クリア済みなら「挑戦」(高難度 10 問連続)。10 問クリアで王冠
	if star_count > 0 and not paid:
		var g_best := int(GameState.gauntlet_best.get(id, 0))
		var crowned := g_best >= GameState.GAUNTLET_QUESTIONS
		var gbtn := Button.new()
		gbtn.custom_minimum_size = Vector2(120, 108)
		gbtn.text = "" if crowned else ("挑戦\n%d/%d" % [g_best, GameState.GAUNTLET_QUESTIONS] if g_best > 0 else "挑戦\n10問")
		gbtn.add_theme_font_size_override("font_size", 22)
		GameState.style_button(gbtn,
			Color(0.72, 0.56, 0.14) if crowned else Color(0.5, 0.36, 0.5))
		gbtn.pressed.connect(func() -> void:
			GameState.play_sfx("tap")
			GameState.current_stage = index
			GameState.mode = "gauntlet"
			GameState.change_scene("res://scenes/problem.tscn"))
		if crowned:
			# 王冠も絵文字を使わず図形で描く(ボタンの中央に置く)
			var mark := Icons.crown(52.0, Color(1.0, 0.92, 0.6))
			mark.position = Vector2(34.0, 28.0)
			gbtn.add_child(mark)
		row.add_child(gbtn)
	return row
