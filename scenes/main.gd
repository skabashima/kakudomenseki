extends Control
## タイトル画面。3 コースへの入口とチャレンジ・記録。

const SECONDARY := Color(0.28, 0.32, 0.44)

var debug_btn: Button
var _deco: Array = []   # [poly, base_pos, phase]
var _t := 0.0
var _deco_t := 0.0


func _process(delta: float) -> void:
	# 背景の図形をゆっくり漂わせる。
	# ゆっくりした 動きなので 毎フレーム 動かす 必要は ない。
	# 20 回/秒 に 落として、電池と 発熱を おさえる
	_t += delta
	_deco_t += delta
	if _deco_t < 0.05:
		return
	_deco_t = 0.0
	for d in _deco:
		d[0].position = d[1] + Vector2(
			sin(_t * 0.45 + d[2]) * 14.0, cos(_t * 0.35 + d[2] * 1.7) * 10.0)


func _ready() -> void:
	GameState.play_bgm("map")
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
	subtitle.text = "中学・高校・大学受験の 角度と面積"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 26 if portrait else 30)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	vbox.add_child(subtitle)

	# 遊びぐあいは 1 行だけ(こまかい内訳は「きろく」で見られる)
	var done := 0
	var total := 0
	var total_stars := 0
	for c in ProblemGen.COURSES:
		for st in c["stages"]:
			total += 1
			var got := int(GameState.stars.get(String(st["id"]), 0))
			if got > 0:
				done += 1
			total_stars += got
	var rank := Label.new()
	rank.text = "%s ・ ★ %d ・ %s 点" % [GameState.rank_name(), total_stars,
		GameState.comma(GameState.total_score())]
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank.add_theme_font_size_override("font_size", 28 if portrait else 32)
	rank.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	vbox.add_child(rank)

	vbox.add_child(_spacer(6))
	# ■ 主役は 3 つの ストーリー。学年で えらぶ
	vbox.add_child(_band("― ストーリー ―"))
	var kid_done := 0
	for u in KidDefs.UNITS:
		if GameState.kid_clear.has(String(u["id"])):
			kid_done += 1
	var story_side := clampf(get_viewport_rect().size.x * 0.11, 40.0, 160.0)
	vbox.add_child(_narrow(_story_card("たからのちず", "小学生",
		"%d / %d" % [kid_done, KidDefs.UNITS.size()], Color(0.52, 0.30, 0.34),
		Icons.flag(64.0, Color(1, 1, 1, 0.95)), func() -> void:
			GameState.change_scene("res://scenes/kid_map.tscn")), story_side))
	var jhs: Array = StoryDefs.chapters_of("jhs")
	vbox.add_child(_narrow(_story_card("はかる旅", "中学生",
		"%d / %d 章" % [_story_done(jhs), jhs.size()], Color(0.45, 0.35, 0.62),
		Icons.book(64.0, Color(1, 1, 1, 0.95)), func() -> void:
			GameState.story_mode = "jhs"
			GameState.story_chapter = "ch1"
			GameState.story_scene = 0
			GameState.change_scene("res://scenes/story_map.tscn")), story_side))
	var hs: Array = StoryDefs.chapters_of("hs")
	vbox.add_child(_narrow(_story_card("軌道計算室", "高校生",
		"%d / %d 章" % [_story_done(hs), hs.size()], Color(0.24, 0.42, 0.58),
		Icons.timer(64.0, Color(1, 1, 1, 0.95)), func() -> void:
			GameState.story_mode = "hs"
			GameState.story_chapter = "ch17"
			GameState.story_scene = 0
			GameState.change_scene("res://scenes/story_map.tscn")), story_side))

	# ■ ストーリーの つぎは 戦略ゲーム(島取り)
	vbox.add_child(_spacer(6))
	vbox.add_child(_band("― せんりゃく ―"))
	var isles := 0
	for i in IslandDefs.count():
		if GameState.island_clear.has(str(i)):
			isles += 1
	vbox.add_child(_narrow(_story_card("島取り", "カラスと 島を とりあう",
		"%d / %d 島" % [isles, IslandDefs.count()], Color(0.24, 0.46, 0.40),
		Icons.flag(64.0, Color(1, 1, 1, 0.95)), func() -> void:
			GameState.change_scene("res://scenes/island_select.tscn")), story_side))

	# ■ その下に「問題にチャレンジ」(2 編・チャレンジ・きろく)
	vbox.add_child(_spacer(6))
	vbox.add_child(_band("― 問題にチャレンジ ―"))
	var pair := HBoxContainer.new()
	pair.add_theme_constant_override("separation", 12)
	vbox.add_child(pair)
	var icon_of := {"kaku": Icons.angle_mark(72.0, Color(1, 1, 1, 0.95)),
		"men": Icons.area_mark(72.0, Color(1, 1, 1, 0.95))}
	for c in ProblemGen.COURSES:
		var cid := String(c["id"])
		var stages: Array = c["stages"]
		var cleared := 0
		for st in stages:
			if int(GameState.stars.get(String(st["id"]), 0)) > 0:
				cleared += 1
		pair.add_child(_course_card(String(c["name"]).replace("編", ""),
			"%d / %d" % [cleared, stages.size()], c["color"], icon_of[cid], func() -> void:
				GameState.current_course = cid
				GameState.mode = "normal"
				GameState.change_scene("res://scenes/stage_select.tscn")))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)
	row.add_child(_small_card("チャレンジ", SECONDARY,
		Icons.timer(52.0, Color(1, 1, 1, 0.92)), func() -> void:
			GameState.change_scene("res://scenes/challenge_select.tscn")))
	row.add_child(_small_card("きろく", SECONDARY,
		Icons.chart(52.0, Color(1, 1, 1, 0.92)), func() -> void:
			GameState.change_scene("res://scenes/records.tscn")))


	# 未購入のときだけ解放の入口を出す(買い切り 1 商品・広告なし)
	if not GameState.premium:
		vbox.add_child(_spacer(10))
		vbox.add_child(_menu_button(
			"すべてを解放", "残り %d ステージ・ストーリー %d・島 %d・挑戦・チャレンジ" % [
				int(GameState.paid_content_count()["stage"]),
				int(GameState.paid_content_count()["kid"])
					+ int(GameState.paid_content_count()["chapter"]),
				int(GameState.paid_content_count()["island"])],
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


## 見出しの帯
func _band(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color(0.72, 0.79, 0.92))
	return l


## クリアした章の数
func _story_done(list: Array) -> int:
	var n := 0
	for ch in list:
		if GameState.story_clear.has(String(ch["id"])):
			n += 1
	return n


## 左右に すきまを あけて、はばを せまくする
func _narrow(c: Control, side: float) -> Control:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", int(side))
	m.add_theme_constant_override("margin_right", int(side))
	m.add_child(c)
	return m


## ストーリーのカード(絵 + 題名 + 学年 + すすみぐあい)
func _story_card(name: String, grade: String, progress_text: String, color: Color,
		icon: Control, callback: Callable) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 124)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameState.style_button(btn, color)
	btn.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		callback.call())
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 28
	h.offset_right = -28
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 20)
	btn.add_child(h)
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(icon)
	h.add_child(holder)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	h.add_child(v)
	var t := Label.new()
	t.text = name
	t.add_theme_font_size_override("font_size", 38)
	v.add_child(t)
	var g := Label.new()
	g.text = "%s   %s" % [grade, progress_text]
	g.add_theme_font_size_override("font_size", 24)
	g.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	v.add_child(g)
	return btn


## 2 編のカード(絵 + 名前 + すすみぐあい)。ことばは 2 語だけ
func _course_card(name: String, progress_text: String, color: Color,
		icon: Control, callback: Callable) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 250)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameState.style_button(btn, color)
	btn.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		callback.call())
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 6)
	btn.add_child(v)
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(icon)
	v.add_child(holder)
	var lbl := Label.new()
	lbl.text = name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 42)
	v.add_child(lbl)
	var sub := Label.new()
	sub.text = progress_text
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 26)
	sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	v.add_child(sub)
	return btn


## そのほかのカード(小さめ。絵と名前だけ)
## そのほかのカード。絵の右に 名前(と、あれば 学年)を きっちり寄せて置く
func _small_card(name: String, color: Color, icon: Control, callback: Callable,
		sub := "") -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 108)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameState.style_button(btn, color)
	btn.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		callback.call())
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 12)
	btn.add_child(h)
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(icon)
	h.add_child(holder)
	if sub == "":
		var one := Label.new()
		one.text = name
		one.add_theme_font_size_override("font_size", 27)
		h.add_child(one)
		return btn
	# 2 行のときは、行の間を詰めて 1 かたまりに見せる
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	h.add_child(v)
	var top := Label.new()
	top.text = name
	top.add_theme_font_size_override("font_size", 22)
	top.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	v.add_child(top)
	var bottom := Label.new()
	bottom.text = sub
	bottom.add_theme_font_size_override("font_size", 30)
	v.add_child(bottom)
	return btn


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
