extends Control
## タイトル画面。3 コースへの入口とチャレンジ・記録。

const SECONDARY := Color(0.28, 0.32, 0.44)

var debug_btn: Button
var _deco: Array = []   # [poly, base_pos, phase]
var _t := 0.0


func _process(delta: float) -> void:
	# 背景の図形をゆっくり漂わせる
	_t += delta
	for d in _deco:
		d[0].position = d[1] + Vector2(
			sin(_t * 0.45 + d[2]) * 14.0, cos(_t * 0.35 + d[2] * 1.7) * 10.0)


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.11, 0.16, 0.3)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_add_deco()

	var portrait := get_viewport_rect().size.x < 1400.0
	var ins := GameState.safe_insets()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = float(ins["top"])
	scroll.offset_bottom = -float(ins["bottom"]) - (84.0 if portrait else 0.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	DragScroll.attach(scroll)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14 if portrait else 22)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	vbox.add_child(_spacer(26 if portrait else 50))

	var title := Label.new()
	title.text = "図形ハンター"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 78 if portrait else 96)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "角度と面積を、数字で撃ち落とせ。\n中学・高校・大学受験"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 26 if portrait else 30)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	vbox.add_child(subtitle)

	# 段位と総得点(遊ぶほど積み上がる指標)
	var rank := Label.new()
	rank.text = "%s   %d 点" % [GameState.rank_name(), GameState.total_score()]
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank.add_theme_font_size_override("font_size", 30 if portrait else 34)
	rank.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	vbox.add_child(rank)

	# 進捗のサマリー
	var done := 0
	var total := 0
	var total_stars := 0
	for c in ProblemGen.COURSES:
		for s in c["stages"]:
			total += 1
			var st := int(GameState.stars.get(String(s["id"]), 0))
			if st > 0:
				done += 1
			total_stars += st
	var progress := Label.new()
	progress.text = "クリア %d / %d   ★ %d / %d   解いた問題 %d 問" % [
		done, total, total_stars, total * 3, int(GameState.stats.get("correct", 0))]
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress.add_theme_font_size_override("font_size", 22)
	progress.add_theme_color_override("font_color", Color(0.78, 0.85, 0.96))
	vbox.add_child(progress)

	vbox.add_child(_spacer(8))
	# 3 コース(それぞれのテーマ色)
	for c in ProblemGen.COURSES:
		var cid := String(c["id"])
		var stages: Array = c["stages"]
		var cleared := 0
		for s in stages:
			if int(GameState.stars.get(String(s["id"]), 0)) > 0:
				cleared += 1
		var txt := "%s  %d/%d" % [String(c["name"]), cleared, stages.size()]
		vbox.add_child(_menu_button(txt, String(c["sub"]), c["color"], func() -> void:
			GameState.current_course = cid
			GameState.mode = "normal"
			GameState.change_scene("res://scenes/stage_select.tscn")))

	vbox.add_child(_spacer(10))
	vbox.add_child(_menu_button("チャレンジ", "タイムアタック / サバイバル", SECONDARY, func() -> void:
		GameState.change_scene("res://scenes/challenge_select.tscn"), true))
	vbox.add_child(_menu_button("記録", "段位・★・自己ベスト", SECONDARY, func() -> void:
		GameState.change_scene("res://scenes/records.tscn"), true))
	# 未購入のときだけ解放の入口を出す(買い切り 1 商品・広告なし)
	if not GameState.premium:
		vbox.add_child(_spacer(10))
		vbox.add_child(_menu_button(
			"全ステージを解放", "残り %d ステージ・挑戦・チャレンジ" % GameState.paid_stage_count(),
			Color(0.78, 0.55, 0.15), func() -> void:
				GameState.change_scene("res://scenes/store.tscn"), true))

	# デバッグ: 全ステージ解放トグル(左下に小さく)。
	# 購入しなくても全ステージが開いてしまうので、リリースビルドでは出さない
	if OS.is_debug_build():
		debug_btn = Button.new()
		debug_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		var bot_ins: float = ins["bottom"]
		debug_btn.offset_left = 20.0
		debug_btn.offset_top = -80.0 - bot_ins
		debug_btn.offset_right = 480.0
		debug_btn.offset_bottom = -16.0 - bot_ins
		debug_btn.add_theme_font_size_override("font_size", 22)
		debug_btn.pressed.connect(_toggle_debug)
		add_child(debug_btn)
		_update_debug_btn()


func _toggle_debug() -> void:
	GameState.debug_unlock_all = not GameState.debug_unlock_all
	GameState.save_game()
	_update_debug_btn()


func _update_debug_btn() -> void:
	if debug_btn == null:
		return
	if GameState.debug_unlock_all:
		debug_btn.text = "デバッグ: 全ステージ解放 ON"
		GameState.style_button(debug_btn, SECONDARY.lightened(0.12))
	else:
		debug_btn.text = "デバッグ: 全ステージ解放 OFF"
		GameState.style_button(debug_btn, SECONDARY.darkened(0.25))


func _menu_button(text: String, sub: String, color: Color, callback: Callable, small := false) -> Button:
	var portrait := get_viewport_rect().size.x < 1400.0
	var btn := Button.new()
	btn.text = text + ("\n" + sub if sub != "" else "")
	var h := (110.0 if portrait else 124.0) - (26.0 if small else 0.0)
	btn.custom_minimum_size = Vector2(minf(720.0, get_viewport_rect().size.x - 50.0), h)
	btn.add_theme_font_size_override("font_size",
		(24 if portrait else 30) if small else (28 if portrait else 34))
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		callback.call())
	GameState.style_button(btn, color)
	return btn


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _add_deco() -> void:
	# 背景の飾り(三角形・円・四角の淡いシルエット)
	var defs := [
		[Vector2(170, 260), Color(1.0, 0.9, 0.5, 0.07), "tri"],
		[Vector2(900, 200), Color(0.5, 0.8, 1.0, 0.08), "circle"],
		[Vector2(880, 1500), Color(0.95, 0.5, 0.6, 0.06), "rect"],
		[Vector2(190, 1560), Color(0.6, 1.0, 0.7, 0.07), "tri"],
	]
	var phase := 0.0
	for d in defs:
		var poly := Polygon2D.new()
		var pts := PackedVector2Array()
		match String(d[2]):
			"tri":
				pts = PackedVector2Array([Vector2(-110, 90), Vector2(110, 90), Vector2(30, -110)])
			"rect":
				pts = PackedVector2Array([Vector2(-100, -80), Vector2(100, -80), Vector2(100, 80), Vector2(-100, 80)])
			_:
				for i in 40:
					var ang := TAU * i / 40.0
					pts.append(Vector2(cos(ang), sin(ang)) * 120.0)
		poly.polygon = pts
		poly.position = d[0]
		poly.color = d[1]
		add_child(poly)
		move_child(poly, 1)   # 背景の直後
		_deco.append([poly, d[0], phase])
		phase += 1.9
