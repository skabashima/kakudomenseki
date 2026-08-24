extends Control
## 【試作】小学生むけ「たからの地図」第一話 ― 三角形の 3 つの角をちぎって ならべる。
##
## ■ なぜこの形か
## この単元を遊ぶのは小学生。定理を図に当てはめる作業はつまらないし、
## むずかしい漢字も小さい字も読めない。教室で実際にやる「角をちぎって
## 一直線にならべる」を、指でそのまま体験できるようにした。
##   ・文字は大きく(28〜40)、ことばは ひらがな中心
##   ・読まなくても、指で さわれば すすむ
##   ・3 回ためすと「どんな三角形でも まっすぐ」が自分で分かる
## そのあとに「かどが ひとつ かけた三角形」を なおす場面(180 − a − b)。

const GOLD := Color(1.0, 0.85, 0.3)
const SKY := Color(0.55, 0.85, 1.0)
const INK := Color(0.95, 0.97, 1.0)
const PINK := Color(1.0, 0.55, 0.62)
const GREEN := Color(0.45, 0.90, 0.55)
const PIECE_COL := [Color(1.0, 0.78, 0.35), Color(0.55, 0.85, 1.0), Color(1.0, 0.60, 0.68)]

var tri: Array = []             # 三角形の 3 点
var deg: Array = []             # 3 つの角(度)
var pieces: Array = []          # {"deg", "col", "placed", "drag", "pos"}
var dragging := -1
var tries := 0                  # 何回ためしたか
var phase := 0                  # 0=はなし 1=ちぎる 2=つかう
var quiz: Dictionary = {}
var cheer := 0.0                # ぴったりの演出

var map: Control
var talk: Label
var big: Label
var act_btn: Button
var choice_row: HBoxContainer
var step := 0

const SCRIPT := [
	"おじいちゃんが いなくなった。のこっていたのは、たからの 地図だけ。",
	"地図には 三角の しるし。「かどの 大きさが わかれば、ほる ばしょが わかる」",
	"でも 分度器が ない。どうやって 角を しらべる?",
	"おじいちゃんの メモ ―― 「かどを ちぎって ならべてみろ」",
]


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.14, 0.24)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_new_triangle()

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
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", GOLD)
	head.add_child(title)

	map = Control.new()
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.custom_minimum_size = Vector2(0, 420)
	map.draw.connect(_draw_map)
	map.gui_input.connect(_on_map_input)
	root.add_child(map)

	big = Label.new()
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big.add_theme_font_size_override("font_size", 40)
	big.add_theme_color_override("font_color", GOLD)
	root.add_child(big)

	talk = Label.new()
	talk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	talk.custom_minimum_size = Vector2(0, 96)
	talk.add_theme_font_size_override("font_size", 30)
	talk.add_theme_color_override("font_color", INK)
	root.add_child(talk)

	choice_row = HBoxContainer.new()
	choice_row.add_theme_constant_override("separation", 12)
	choice_row.visible = false
	root.add_child(choice_row)

	act_btn = Button.new()
	act_btn.custom_minimum_size = Vector2(0, 92)
	act_btn.add_theme_font_size_override("font_size", 32)
	GameState.style_button(act_btn, Color(0.22, 0.55, 0.35))
	act_btn.pressed.connect(_advance)
	root.add_child(act_btn)
	_show_step()


func _process(delta: float) -> void:
	if cheer > 0.0:
		cheer = maxf(cheer - delta * 0.9, 0.0)
		map.queue_redraw()


# =========================================================
# 三角形と、ちぎった かど
# =========================================================

func _new_triangle() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var b := rng.randf_range(40.0, 80.0)
	var c := rng.randf_range(40.0, 80.0)
	var a := 180.0 - b - c
	while a < 32.0 or a > 100.0:
		b = rng.randf_range(40.0, 80.0)
		c = rng.randf_range(40.0, 80.0)
		a = 180.0 - b - c
	deg = [a, b, c]
	var side := 11.0
	var p_b := Vector2(-side * 0.5, -3.0)
	var p_c := Vector2(side * 0.5, -3.0)
	var ab := side * sin(deg_to_rad(c)) / sin(deg_to_rad(a))
	var p_a := p_b + Vector2(cos(deg_to_rad(b)), sin(deg_to_rad(b))) * ab
	tri = [p_a, p_b, p_c]
	pieces = []
	cheer = 0.0      # 前の回の演出を残さない
	for i in 3:
		pieces.append({"deg": deg[i], "col": PIECE_COL[i], "placed": false,
			"pos": Vector2.ZERO, "held": false})
	dragging = -1


func _placed_count() -> int:
	var n := 0
	for p in pieces:
		if bool(p["placed"]):
			n += 1
	return n


# =========================================================
# 絵
# =========================================================

## 三角形は形によって細長くもなるので、そのつど はかって画面に収める
func _to_screen(p: Vector2) -> Vector2:
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for q in tri:
		lo = lo.min(q)
		hi = hi.max(q)
	var span := hi - lo
	# 三角形を置ける場所(せんより上。ちぎった かどのぶんの余白も残す)
	var top := 90.0
	var bottom := _line_y() - 190.0
	var k := minf((map.size.x - 200.0) / maxf(span.x, 0.001),
		(bottom - top) / maxf(span.y, 0.001))
	var center := (lo + hi) * 0.5
	return Vector2(map.size.x * 0.5 + (p.x - center.x) * k,
		(top + bottom) * 0.5 - (p.y - center.y) * k)


func _line_y() -> float:
	return map.size.y * 0.84


func _slot_start() -> float:
	return map.size.x * 0.5 - 130.0


## ちぎった かど(おうぎ形の紙きれ)を描く
func _draw_piece(c: Control, at: Vector2, base_dir: float, size_deg: float,
		col: Color, radius: float) -> void:
	var pts := PackedVector2Array()
	pts.append(at)
	var n := maxi(int(size_deg / 5.0), 5)
	for i in n + 1:
		var t := base_dir + deg_to_rad(size_deg) * float(i) / float(n)
		# ちぎった紙のギザギザ。画面の y は下向きなので、上に開くよう符号を反転する
		var r := radius * (1.0 + (0.06 if i % 2 == 0 else -0.05))
		pts.append(at + Vector2(cos(t), -sin(t)) * r)
	c.draw_colored_polygon(pts, col)
	c.draw_polyline(pts, Color(1, 1, 1, 0.75), 2.0)


func _draw_map() -> void:
	var c := map
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.13, 0.18, 0.30))
	var font := ThemeDB.fallback_font

	if phase == 2:
		_draw_quiz(c, font)
		return

	# 三角形(ちぎった かどは 三角形から消える)
	var sp := PackedVector2Array()
	for p in tri:
		sp.append(_to_screen(p))
	c.draw_colored_polygon(sp, Color(0.40, 0.60, 0.95, 0.30))
	c.draw_polyline(PackedVector2Array([sp[0], sp[1], sp[2], sp[0]]), INK, 4.0)

	for i in 3:
		var pc: Dictionary = pieces[i]
		if bool(pc["placed"]) or i == dragging:
			continue
		var at: Vector2 = sp[i]
		var d1 := _math_angle(sp[(i + 1) % 3] - at)
		var d2 := _math_angle(sp[(i + 2) % 3] - at)
		var start: float = d1
		if _wrap_diff(d1, d2) < 0.0:
			start = d2
		# ひらく向きが 三角形の内がわに なるように たしかめる
		var mid := start + deg_to_rad(float(pc["deg"])) * 0.5
		var inward := _math_angle((sp[0] + sp[1] + sp[2]) / 3.0 - at)
		if absf(_wrap_diff(mid, inward)) > PI * 0.5:
			start = start + deg_to_rad(float(pc["deg"])) - deg_to_rad(360.0)
		_draw_piece(c, at, start, float(pc["deg"]), pc["col"], 74.0)
		# ちぎった あとが分かるように、切り取り線を出す
		var cut1 := at + Vector2(cos(start), -sin(start)) * 74.0
		var cut2 := at + Vector2(cos(start + deg_to_rad(float(pc["deg"]))),
			-sin(start + deg_to_rad(float(pc["deg"])))) * 74.0
		c.draw_dashed_line(cut1, cut2, Color(1, 1, 1, 0.5), 2.0, 8.0)

	# ならべる まっすぐな せん
	var ly := _line_y()
	c.draw_line(Vector2(20, ly), Vector2(c.size.x - 20, ly), Color(1, 1, 1, 0.85), 5.0)
	if _placed_count() < 3:
		c.draw_string(font, Vector2(24, ly + 44), "ここに かどを ならべよう",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.75, 0.82, 0.95))

	# ならべた かど
	var base := 0.0
	var origin := Vector2(_slot_start(), ly)
	for i in 3:
		var pc: Dictionary = pieces[i]
		if not bool(pc["placed"]):
			continue
		_draw_piece(c, origin, deg_to_rad(base), float(pc["deg"]), pc["col"], 120.0)
		base += float(pc["deg"])

	# 指でつまんでいる かど
	if dragging >= 0:
		var pc2: Dictionary = pieces[dragging]
		_draw_piece(c, pc2["pos"], deg_to_rad(90.0 - float(pc2["deg"]) * 0.5),
			float(pc2["deg"]), pc2["col"], 88.0)

	if cheer > 0.0:
		var alpha := clampf(cheer, 0.0, 1.0)
		c.draw_arc(origin, 120.0 + (1.0 - alpha) * 50.0, PI, TAU, 40,
			Color(1.0, 0.95, 0.5, alpha), 6.0)


## 画面の向き(y が下)を、ふつうの向き(上がプラス)に直した角度
static func _math_angle(v: Vector2) -> float:
	return Vector2(v.x, -v.y).angle()


static func _wrap_diff(a: float, b: float) -> float:
	var d := b - a
	while d > PI:
		d -= TAU
	while d < -PI:
		d += TAU
	return d


# =========================================================
# 指
# =========================================================

func _on_map_input(event: InputEvent) -> void:
	if phase != 1:
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			dragging = _piece_at(event.position)
			if dragging >= 0:
				pieces[dragging]["pos"] = event.position
				GameState.play_sfx("type")
		elif dragging >= 0:
			_drop(event.position)
		map.queue_redraw()
	elif dragging >= 0:
		pieces[dragging]["pos"] = event.position
		map.queue_redraw()


func _piece_at(s: Vector2) -> int:
	var best := -1
	var best_d := 130.0
	for i in 3:
		if bool(pieces[i]["placed"]):
			continue
		var d := _to_screen(tri[i]).distance_to(s)
		if d < best_d:
			best_d = d
			best = i
	return best


func _drop(s: Vector2) -> void:
	var near_line: bool = s.y > _line_y() - 170.0
	if near_line:
		pieces[dragging]["placed"] = true
		GameState.play_sfx("correct")
		if _placed_count() == 3:
			_all_placed()
	dragging = -1
	map.queue_redraw()


func _all_placed() -> void:
	cheer = 1.0
	tries += 1
	GameState.play_sfx("clear")
	big.text = "ぴったり まっすぐ！  180 ど"
	if tries == 1:
		talk.text = "3 つの かどを ならべたら、まっすぐな せんに なった。まっすぐは 180 ど。"
		act_btn.text = "べつの 三角で ためす"
	elif tries == 2:
		talk.text = "形を かえても、また まっすぐ。ぐうぜん かな?"
		act_btn.text = "もう いちど ためす"
	else:
		talk.text = "3 回とも まっすぐ。どんな 形の 三角形でも、3 つの かどを あわせると 180 ど。"
		act_btn.text = "地図の しるしを 見る"
	act_btn.disabled = false


# =========================================================
# つかう(かどが ひとつ かけた三角形)
# =========================================================

func _make_quiz() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var b := rng.randi_range(30, 80)
	var c := rng.randi_range(30, 80)
	var a := 180 - b - c
	while a < 25 or a > 110:
		b = rng.randi_range(30, 80)
		c = rng.randi_range(30, 80)
		a = 180 - b - c
	var side := 11.0
	var p_b := Vector2(-side * 0.5, -3.0)
	var p_c := Vector2(side * 0.5, -3.0)
	var ab := side * sin(deg_to_rad(float(c))) / sin(deg_to_rad(float(a)))
	var p_a := p_b + Vector2(cos(deg_to_rad(float(b))), sin(deg_to_rad(float(b)))) * ab
	tri = [p_a, p_b, p_c]
	var wrong1 := a + rng.randi_range(12, 30)
	# (クイズの三角形も同じ理由で、極端な形は作らない)
	var wrong2 := maxi(a - rng.randi_range(12, 30), 10)
	var opts := [a, wrong1, wrong2]
	opts.shuffle()
	quiz = {"a": a, "b": b, "c": c, "opts": opts}
	for child in choice_row.get_children():
		child.queue_free()
	for v in opts:
		var btn := Button.new()
		btn.text = "%d ど" % int(v)
		btn.custom_minimum_size = Vector2(0, 96)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 34)
		GameState.style_button(btn, Color(0.34, 0.42, 0.62))
		btn.pressed.connect(func() -> void: _answer(int(v)))
		choice_row.add_child(btn)
	choice_row.visible = true


func _draw_quiz(c: Control, font: Font) -> void:
	var sp := PackedVector2Array()
	for p in tri:
		sp.append(_to_screen(p))
	c.draw_colored_polygon(sp, Color(0.40, 0.60, 0.95, 0.30))
	c.draw_polyline(PackedVector2Array([sp[0], sp[1], sp[2], sp[0]]), INK, 4.0)
	var labels := ["?", "%d ど" % int(quiz["b"]), "%d ど" % int(quiz["c"])]
	var cols := [GOLD, SKY, SKY]
	for i in 3:
		var at: Vector2 = sp[i]
		var to_in := ((sp[(i + 1) % 3] + sp[(i + 2) % 3]) * 0.5 - at).normalized()
		c.draw_string(font, at + to_in * 74.0 + Vector2(-30, 10), labels[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 34, cols[i])
	c.draw_string(font, Vector2(24, c.size.y - 24),
		"3 つ あわせて 180 ど だったね", HORIZONTAL_ALIGNMENT_LEFT, -1, 28,
		Color(0.75, 0.82, 0.95))


func _answer(v: int) -> void:
	if v == int(quiz["a"]):
		GameState.play_sfx("clear")
		big.text = "あたり！  %d ど" % v
		talk.text = "180 から %d と %d を ひくと %d。ほる ばしょが きまった。" % [
			int(quiz["b"]), int(quiz["c"]), int(quiz["a"])]
		choice_row.visible = false
		act_btn.text = "つづきを 見る"
		act_btn.disabled = false
		phase = 3
	else:
		GameState.play_sfx("fail")
		big.text = "ちがうみたい"
		talk.text = "3 つ あわせて 180 ど。のこりは いくつかな?"


# =========================================================
# すすむ
# =========================================================

func _show_step() -> void:
	if step < SCRIPT.size():
		talk.text = SCRIPT[step]
		big.text = ""
		act_btn.text = "つぎへ"
		return
	phase = 1
	big.text = ""
	talk.text = "三角形の かどを 指で つまんで、下の せんに ならべよう。3 つ ぜんぶ。"
	act_btn.text = "ならべてね"
	act_btn.disabled = true


func _advance() -> void:
	GameState.play_sfx("tap")
	if step < SCRIPT.size():
		step += 1
		_show_step()
		return
	if phase == 1:
		if tries >= 3:
			phase = 2
			big.text = ""
			talk.text = "地図の しるしは 三角。かどが ひとつ 消えている。のこりの かどは 何ど?"
			act_btn.text = "えらんでね"
			act_btn.disabled = true
			_make_quiz()
			map.queue_redraw()
			return
		_new_triangle()
		big.text = ""
		talk.text = "こんどは ちがう形。また ならべてみよう。"
		act_btn.text = "ならべてね"
		act_btn.disabled = true
		map.queue_redraw()
		return
	if phase == 3:
		talk.text = "おじいちゃんの メモの うら ―― 「まだ 二つ、しるしが ある」"
		big.text = ""
		act_btn.text = "タイトルへ"
		phase = 4
		return
	GameState.change_scene("res://scenes/main.tscn")
