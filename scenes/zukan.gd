extends Control
## 図鑑 ―「見つけた 決まり」を 集める 画面。
##
## 遊んで 手に入れた ものが 一覧で 見える。まだの ところは 名前だけ 見せて、
## 何が 待っているかが 分かるようにする(集めたく なる)。

const HEAD := Color(1.0, 0.88, 0.45)


func _ready() -> void:
	GameState.play_bgm("map")
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.12, 0.21)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var ins := GameState.safe_insets()
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_top = 16.0 + float(ins["top"])
	root.offset_left = 20.0
	root.offset_right = -20.0
	root.offset_bottom = -14.0 - float(ins["bottom"])
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	root.add_child(head)
	var back := Button.new()
	back.text = "もどる"
	back.custom_minimum_size = Vector2(150, 64)
	back.add_theme_font_size_override("font_size", 25)
	back.focus_mode = Control.FOCUS_NONE
	GameState.style_button(back, Color(0.28, 0.32, 0.44))
	back.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		GameState.change_scene("res://scenes/main.tscn"))
	head.add_child(back)
	var prog := Zukan.progress(GameState.kid_clear, GameState.story_clear)
	var title := RubyLabel.new()
	title.font_size = 32
	title.ruby_size = 15
	title.color = HEAD
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.set_ruby_text("  図鑑  %d / %d" % [int(prog[0]), int(prog[1])], true)
	head.add_child(title)

	var lead := RubyLabel.new()
	lead.font_size = 22
	lead.ruby_size = 11
	lead.color = Color(0.80, 0.86, 1.0)
	lead.custom_minimum_size = Vector2(0, 58)
	lead.set_ruby_text("ストーリーで 見つけた 決まりが たまっていきます。"
		+ "まだの ところは 名前だけ 出ています。", true)
	root.add_child(lead)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	DragScroll.attach(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	var last_from := ""
	for c in Zukan.cards():
		var card: Dictionary = c
		var from := String(card["from"])
		if from != last_from:
			last_from = from
			var band := RubyLabel.new()
			band.font_size = 24
			band.ruby_size = 12
			band.color = Color(0.75, 0.82, 0.96)
			band.custom_minimum_size = Vector2(0, 38)
			band.set_ruby_text("― %s ―" % from, true)
			list.add_child(band)
		list.add_child(_card(card))


func _card(card: Dictionary) -> Control:
	var got := Zukan.has(card, GameState.kid_clear, GameState.story_clear)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", GameState.flat_style(
		Color(0.17, 0.24, 0.36) if got else Color(0.12, 0.15, 0.22), 14))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	panel.add_child(v)
	var name := RubyLabel.new()
	name.font_size = 25
	name.ruby_size = 12
	name.color = Color.WHITE if got else Color(0.62, 0.68, 0.80)
	name.custom_minimum_size = Vector2(0, 34)
	name.set_ruby_text(("● " if got else "○ ") + String(card["name"]), true)
	v.add_child(name)
	var found := RubyLabel.new()
	found.font_size = 21
	found.ruby_size = 11
	found.color = Color(0.70, 1.0, 0.80) if got else Color(0.50, 0.56, 0.68)
	found.custom_minimum_size = Vector2(0, 30)
	found.set_ruby_text(String(card["found"]) if got else "まだ 見つけていない", true)
	v.add_child(found)
	return panel
