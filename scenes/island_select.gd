extends Control
## 島取りの まえに、出題の はんいを えらぶ 画面。
##
## 小学生から 遊べるように、漢字には ふりがなを のせる(RubyLabel)。
## えらんだ はんいの 島だけを 順に 通す。

const HEAD := Color(1.0, 0.88, 0.45)


func _ready() -> void:
	GameState.play_bgm("map")
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.11, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var ins := GameState.safe_insets()
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_top = 16.0 + float(ins["top"])
	root.offset_left = 22.0
	root.offset_right = -22.0
	root.offset_bottom = -14.0 - float(ins["bottom"])
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	root.add_child(head)
	var back := Button.new()
	back.text = "もどる"
	back.custom_minimum_size = Vector2(150, 66)
	back.add_theme_font_size_override("font_size", 26)
	back.focus_mode = Control.FOCUS_NONE
	GameState.style_button(back, Color(0.28, 0.32, 0.44))
	back.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		GameState.change_scene("res://scenes/main.tscn"))
	head.add_child(back)
	var title := RubyLabel.new()
	title.font_size = 36
	title.ruby_size = 17
	title.color = HEAD
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.set_ruby_text("  島取り", true)
	head.add_child(title)

	var lead := RubyLabel.new()
	lead.font_size = 24
	lead.ruby_size = 12
	lead.color = Color(0.82, 0.88, 1.0)
	lead.custom_minimum_size = Vector2(0, 78)
	lead.set_ruby_text("問題を といた 答えの 数だけ 島の 土地が 広がる。"
		+ "カラスより 広く 取ろう。どの はんいで 遊ぶ?", true)
	root.add_child(lead)

	for r in IslandDefs.RANGES:
		root.add_child(_card(r))
	root.add_child(_spacer(8))


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _card(r: Dictionary) -> Control:
	var id := String(r["id"])
	var prog := IslandDefs.progress_in(id, GameState.island_clear)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 128)
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	GameState.style_button(btn, r["color"])
	btn.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		GameState.island_range = id
		var go := IslandDefs.first_open_in(id, GameState.island_clear)
		if GameState.island_needs_purchase(go):
			GameState.change_scene("res://scenes/store.tscn")
			return
		GameState.island_index = go
		GameState.change_scene("res://scenes/island.tscn"))

	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 26
	h.offset_right = -22
	h.add_theme_constant_override("separation", 18)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(h)

	var icon := CenterContainer.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_child(Icons.flag(58.0, Color(1, 1, 1, 0.95)))
	h.add_child(icon)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 4)
	h.add_child(v)

	var name := RubyLabel.new()
	name.font_size = 34
	name.ruby_size = 15
	name.color = Color.WHITE
	name.custom_minimum_size = Vector2(0, 46)
	name.set_ruby_text(String(r["name"]), true)
	v.add_child(name)

	var sub := RubyLabel.new()
	sub.font_size = 22
	sub.ruby_size = 11
	sub.color = Color(1, 1, 1, 0.86)
	sub.custom_minimum_size = Vector2(0, 34)
	var lv := String(r["level"])
	var got := GameState.island_stars_in(IslandDefs.islands_in(id))
	var free_note := ""
	if not GameState.premium and not GameState.debug_unlock_all:
		free_note = "   ここから %d 島 まで 無料" % GameState.FREE_ISLANDS_PER_RANGE
	sub.set_ruby_text("%s%d / %d の 島   ★ %d / %d%s" % ["%s ・ " % lv if lv != "" else "",
		int(prog[0]), int(prog[1]), got, int(prog[1]) * 3, free_note], true)
	v.add_child(sub)
	return btn
