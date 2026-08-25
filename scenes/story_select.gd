extends Control
## ストーリーの章えらび。中学受験 → 高校受験 → 大学受験 の順に 10 章。
## 前の章をクリアすると次が開く(本編のステージ一覧と同じ流儀)。
## クリア済みの章には「見つけたこと」を出して、何を持ち帰ったかが分かるようにする。

const HEAD := Color(1.0, 0.88, 0.45)


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.11, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var ins := GameState.safe_insets()
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_top = 20.0 + float(ins["top"])
	root.offset_left = 26.0
	root.offset_right = -26.0
	root.offset_bottom = -14.0 - float(ins["bottom"])
	root.add_theme_constant_override("separation", 12)
	add_child(root)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	root.add_child(head)
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
	title.text = "ストーリー"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", HEAD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var done := Label.new()
	done.text = "%d / %d 章" % [_cleared_count(), StoryDefs.CHAPTERS.size()]
	done.add_theme_font_size_override("font_size", 24)
	done.add_theme_color_override("font_color", Color(0.8, 0.87, 1.0))
	head.add_child(done)

	var lead := Label.new()
	lead.text = "図を動かして「変わらないもの」を見つける。見つけた決まりが本編の武器になる。"
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lead.add_theme_font_size_override("font_size", 21)
	lead.add_theme_color_override("font_color", Color(0.78, 0.85, 0.96))
	root.add_child(lead)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	DragScroll.attach(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	var last_level := ""
	for i in StoryDefs.CHAPTERS.size():
		var ch: Dictionary = StoryDefs.CHAPTERS[i]
		var lv := String(ch["level"])
		if lv != last_level:
			last_level = lv
			var h := Label.new()
			h.text = "― %sレベル ―" % lv
			h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			h.add_theme_font_size_override("font_size", 24)
			h.add_theme_color_override("font_color", Color(0.75, 0.68, 0.95))
			list.add_child(h)
		list.add_child(_card(i, ch))


func _cleared_count() -> int:
	var n := 0
	for ch in StoryDefs.CHAPTERS:
		if GameState.story_clear.has(String(ch["id"])):
			n += 1
	return n


func _card(index: int, ch: Dictionary) -> Control:
	var id := String(ch["id"])
	var cleared: bool = GameState.story_clear.has(id)
	var unlocked: bool = StoryDefs.is_unlocked(id, GameState.story_clear) or GameState.debug_unlock_all

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 112)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.disabled = not unlocked
	GameState.style_button(btn,
		Color(0.45, 0.35, 0.62) if unlocked else Color(0.16, 0.18, 0.24))
	if unlocked:
		btn.pressed.connect(func() -> void:
			GameState.play_sfx("tap")
			GameState.story_chapter = id
			if cleared or GameState.story_chapter != id:
				GameState.story_scene = 0
			GameState.change_scene("res://scenes/story.tscn"))
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
	num.add_theme_font_size_override("font_size", 38)
	num.add_theme_color_override("font_color",
		Color(1, 1, 1, 0.9) if unlocked else Color(0.7, 0.72, 0.8, 0.5))
	num.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(num)

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.add_theme_constant_override("separation", 2)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(mid)
	var t := Label.new()
	# 章の名前は開いていなくても見せる(何が待っているか分かるほうが進めたくなる)
	t.text = _kids(ch, String(ch["title"]))
	t.add_theme_font_size_override("font_size", 28)
	t.add_theme_color_override("font_color",
		Color.WHITE if unlocked else Color(0.78, 0.82, 0.9))
	mid.add_child(t)
	var d := Label.new()
	d.text = _kids(ch, String(ch["found"]) if cleared else String(ch["place"]))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_font_size_override("font_size", 19)
	d.add_theme_color_override("font_color",
		Color(0.7, 1.0, 0.8) if cleared else Color(0.85, 0.9, 1.0, 0.75))
	mid.add_child(d)

	var right := VBoxContainer.new()
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(right)
	if not unlocked:
		right.add_child(Icons.lock(34.0, Color(0.75, 0.8, 0.9, 0.6)))
	elif cleared:
		var ok := Label.new()
		ok.text = "✓"
		ok.add_theme_font_size_override("font_size", 34)
		ok.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7))
		right.add_child(ok)
	row.add_child(btn)
	return row


## 小学生が読む章(中学受験レベル)なら、漢字によみを付ける
func _kids(ch: Dictionary, text: String) -> String:
	if String(ch.get("level", "")) == "中学受験":
		return Ruby.apply(text)
	return text
