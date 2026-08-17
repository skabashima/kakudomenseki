extends Control
## 記録画面。段位・総得点・コース別の★・チャレンジ自己ベスト。

func _ready() -> void:
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
	title.text = "記録"
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
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	# 段位
	var panel := PanelContainer.new()
	list.add_child(panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 6)
	panel.add_child(pv)
	_lbl(pv, "段位", 24, Color(0.8, 0.87, 1.0))
	_lbl(pv, GameState.rank_name(), 48, Color(1.0, 0.84, 0.3))
	_lbl(pv, "総得点 %d 点" % GameState.total_score(), 30, Color.WHITE)
	var gap: Array = GameState.next_rank_gap()
	if String(gap[0]) != "":
		_lbl(pv, "「%s」まで あと %d 点" % [gap[0], gap[1]], 22, Color(0.75, 0.83, 0.95))
	_lbl(pv, "最高コンボ ×%d" % GameState.best_combo, 24, Color(0.6, 0.95, 1.0))

	# コース別
	for c in ProblemGen.COURSES:
		var cp := PanelContainer.new()
		list.add_child(cp)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 4)
		cp.add_child(cv)
		var stages: Array = c["stages"]
		var got := 0
		var cleared := 0
		var course_score := 0
		for s in stages:
			var id := String(s["id"])
			var st := int(GameState.stars.get(id, 0))
			got += st
			if st > 0:
				cleared += 1
			course_score += int(GameState.scores.get(id, 0))
		var col: Color = c["color"]
		_lbl(cv, String(c["name"]), 28, col.lightened(0.45))
		_lbl(cv, "クリア %d/%d   ★ %d/%d   %d点" % [
			cleared, stages.size(), got, stages.size() * 3, course_score], 24, Color.WHITE)

	# チャレンジ
	var ch := PanelContainer.new()
	list.add_child(ch)
	var chv := VBoxContainer.new()
	chv.add_theme_constant_override("separation", 4)
	ch.add_child(chv)
	_lbl(chv, "チャレンジ自己ベスト", 26, Color(0.8, 0.87, 1.0))
	var any := false
	for c in ProblemGen.COURSES:
		var key := "time:" + String(c["id"])
		if GameState.challenge_best.has(key):
			_lbl(chv, "タイムアタック %s: %d 問" % [String(c["name"]), int(GameState.challenge_best[key])],
				22, Color.WHITE)
			any = true
	if GameState.challenge_best.has("time:all"):
		_lbl(chv, "タイムアタック 全コース: %d 問" % int(GameState.challenge_best["time:all"]), 22, Color.WHITE)
		any = true
	if GameState.challenge_best.has("survival"):
		_lbl(chv, "サバイバル: %d 問" % int(GameState.challenge_best["survival"]), 22, Color.WHITE)
		any = true
	if not any:
		_lbl(chv, "まだ記録がありません", 22, Color(0.7, 0.76, 0.88))


func _lbl(parent: Control, text: String, size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl
