extends Control
## 「ストーリー(小学生)」の単元えらび。
## 中学受験レベルのステージ 1 つに対して 1 回。前をクリアすると次が開く。

const HEAD := Color(1.0, 0.85, 0.3)
const INK := Color(0.95, 0.97, 1.0)


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.14, 0.24)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var ins := GameState.safe_insets()
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 14
	root.offset_right = -14
	root.offset_top = float(ins["top"]) + 8.0
	root.offset_bottom = -float(ins["bottom"]) - 8.0
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var head := HBoxContainer.new()
	root.add_child(head)
	var back := Button.new()
	back.text = "もどる"
	back.custom_minimum_size = Vector2(0, 72)
	back.add_theme_font_size_override("font_size", 28)
	GameState.style_button(back, Color(0.28, 0.32, 0.44))
	back.pressed.connect(func() -> void: GameState.change_scene("res://scenes/main.tscn"))
	head.add_child(back)
	var title := Label.new()
	title.text = "  たからの地図"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", HEAD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var count := Label.new()
	count.text = "%d / %d" % [_cleared_count(), KidDefs.UNITS.size()]
	count.add_theme_font_size_override("font_size", 26)
	count.add_theme_color_override("font_color", INK)
	head.add_child(count)

	var lead := RubyLabel.new()
	lead.font_size = 26
	lead.ruby_size = 15
	lead.color = Color(0.78, 0.86, 0.98)
	lead.set_ruby_text("ゆびで さわって、じぶんで 見つける。見つけた 決まりで しるしを 1 つ 解く。", true)
	root.add_child(lead)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	DragScroll.attach(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	var course := ""
	for i in KidDefs.UNITS.size():
		var u: Dictionary = KidDefs.UNITS[i]
		if String(u["course"]) != course:
			course = String(u["course"])
			var band := Label.new()
			band.text = "― %s ―" % course
			band.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			band.add_theme_font_size_override("font_size", 24)
			band.add_theme_color_override("font_color", Color(0.7, 0.78, 0.92))
			list.add_child(band)
		list.add_child(_card(i, u))


func _cleared_count() -> int:
	var n := 0
	for u in KidDefs.UNITS:
		if GameState.kid_clear.has(String(u["id"])):
			n += 1
	return n


func _card(i: int, u: Dictionary) -> Button:
	var uid := String(u["id"])
	var open := KidDefs.is_unlocked(uid, GameState.kid_clear)
	var cleared := GameState.kid_clear.has(uid)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 116)
	btn.disabled = not open
	GameState.style_button(btn, Color(0.30, 0.45, 0.35) if cleared
		else (Color(0.52, 0.30, 0.34) if open else Color(0.22, 0.25, 0.34)))
	if open:
		btn.pressed.connect(func() -> void:
			GameState.play_sfx("tap")
			GameState.kid_unit = uid
			GameState.change_scene("res://scenes/kid_unit.tscn"))
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 18
	h.offset_right = -18
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 14)
	btn.add_child(h)
	var no := Label.new()
	no.text = "%d" % (i + 1)
	no.add_theme_font_size_override("font_size", 34)
	no.add_theme_color_override("font_color", Color(1, 1, 1, 0.55 if open else 0.3))
	no.custom_minimum_size = Vector2(48, 0)
	no.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(no)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var t := RubyLabel.new()
	t.font_size = 30
	t.ruby_size = 15
	t.color = INK if open else Color(0.6, 0.65, 0.75)
	t.set_ruby_text(String(u["title"]), true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(t)
	var d := RubyLabel.new()
	d.font_size = 21
	d.ruby_size = 12
	d.color = Color(0.72, 0.86, 0.98) if cleared else Color(0.65, 0.72, 0.85)
	d.set_ruby_text(String(u["found"]) if cleared else "さわって 見つけよう", true)
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(d)
	if not open:
		var lock := Icons.lock(34.0, Color(0.7, 0.75, 0.85))
		var holder := CenterContainer.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(lock)
		h.add_child(holder)
	elif cleared:
		var ok := Label.new()
		ok.text = "✓"
		ok.add_theme_font_size_override("font_size", 34)
		ok.add_theme_color_override("font_color", Color(0.55, 0.95, 0.65))
		ok.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		h.add_child(ok)
	return btn
