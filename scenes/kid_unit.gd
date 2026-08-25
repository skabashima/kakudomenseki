extends Control
## 「ストーリー(小学生)」の 1 単元。
##
## ながれ: おはなし → さわって見つける(3 回) → 見つけたこと → しるしを解く(電卓) → おわり
## さわり方(act)は単元ごとに違うが、画面のつくりは同じ。
##   tear  … かどを ちぎって ならべる      slide … 平行線の間で かどを ずらす
##   fold  … 折って 重ねる                diag  … 対角線で 三角形に分ける
##   clock … 時計の 針を まわす

const GOLD := Color(1.0, 0.85, 0.3)
const SKY := Color(0.55, 0.85, 1.0)
const INK := Color(0.95, 0.97, 1.0)
const DIM := Color(0.66, 0.74, 0.88)
const PIECE_COL := [Color(1.0, 0.78, 0.35), Color(0.55, 0.85, 1.0), Color(1.0, 0.60, 0.68),
	Color(0.65, 0.95, 0.70), Color(0.85, 0.75, 1.0), Color(1.0, 0.85, 0.55)]

var unit: Dictionary = {}
var phase := 0                  # 0=おはなし 1=さわる 2=しるし 3=おわり
var step := 0
var tries := 0
var cheer := 0.0

# さわる図の状態(act ごとに使う中身が変わる)
var st: Dictionary = {}
var dragging := -1

# しるし(本編の問題を 1 問)
var problem: Dictionary = {}
var input_text := ""

var map: Control
var big: Label
var talk: RubyLabel
var keypad: Keypad
var answer_btn: Button
var act_btn: Button
var figure: FigureView


func _ready() -> void:
	unit = KidDefs.by_id(GameState.kid_unit)
	if unit.is_empty():
		unit = KidDefs.UNITS[0]
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
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var head := HBoxContainer.new()
	root.add_child(head)
	var back := Button.new()
	back.text = "もどる"
	back.custom_minimum_size = Vector2(0, 66)
	back.add_theme_font_size_override("font_size", 26)
	GameState.style_button(back, Color(0.28, 0.32, 0.44))
	back.pressed.connect(func() -> void:
		GameState.change_scene("res://scenes/kid_select.tscn"))
	head.add_child(back)
	var title := RubyLabel.new()
	title.font_size = 30
	title.ruby_size = 15
	title.color = GOLD
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.set_ruby_text("  " + String(unit["title"]), true)
	head.add_child(title)

	map = Control.new()
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.custom_minimum_size = Vector2(0, 400)
	map.draw.connect(_draw_map)
	map.gui_input.connect(_on_map_input)
	root.add_child(map)

	figure = FigureView.new()
	figure.size_flags_vertical = Control.SIZE_EXPAND_FILL
	figure.custom_minimum_size = Vector2(0, 400)
	figure.free_draw_enabled = false
	figure.visible = false
	root.add_child(figure)

	big = Label.new()
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big.add_theme_font_size_override("font_size", 38)
	big.add_theme_color_override("font_color", GOLD)
	root.add_child(big)

	talk = RubyLabel.new()
	talk.font_size = 29
	talk.ruby_size = 16
	talk.color = INK
	talk.custom_minimum_size = Vector2(0, 104)
	talk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(talk)

	keypad = Keypad.new()
	keypad.key_pressed.connect(_on_key)
	keypad.visible = false
	root.add_child(keypad)
	answer_btn = Button.new()
	answer_btn.text = "こたえる"
	answer_btn.custom_minimum_size = Vector2(0, 88)
	answer_btn.add_theme_font_size_override("font_size", 30)
	GameState.style_button(answer_btn, Color(0.22, 0.55, 0.35))
	answer_btn.pressed.connect(_submit)
	answer_btn.visible = false
	root.add_child(answer_btn)

	act_btn = Button.new()
	act_btn.custom_minimum_size = Vector2(0, 88)
	act_btn.add_theme_font_size_override("font_size", 30)
	GameState.style_button(act_btn, Color(0.22, 0.55, 0.35))
	act_btn.pressed.connect(_advance)
	root.add_child(act_btn)

	_reset_act()
	_show_step()


func _process(delta: float) -> void:
	if cheer > 0.0:
		cheer = maxf(cheer - delta * 0.9, 0.0)
		map.queue_redraw()


# =========================================================
# ながれ
# =========================================================

func _show_step() -> void:
	var intro: Array = unit["intro"]
	if step < intro.size():
		talk.set_ruby_text(String(intro[step]), true)
		big.text = ""
		act_btn.text = "つぎへ"
		act_btn.disabled = false
		return
	phase = 1
	big.text = ""
	talk.set_ruby_text(_act_lead(), true)
	act_btn.text = "さわってね"
	act_btn.disabled = true


func _advance() -> void:
	GameState.play_sfx("tap")
	var intro: Array = unit["intro"]
	if step < intro.size():
		step += 1
		_show_step()
		return
	if phase == 1:
		if tries >= 3:
			_start_quiz()
			return
		_reset_act()
		big.text = ""
		talk.set_ruby_text("こんどは ちがう形。また やってみよう。", true)
		act_btn.text = "さわってね"
		act_btn.disabled = true
		map.queue_redraw()
		return
	if phase == 3:
		GameState.change_scene("res://scenes/kid_select.tscn")


## 3 回できた
func _act_done() -> void:
	cheer = 1.0
	tries += 1
	GameState.play_sfx("clear" if tries >= 3 else "correct")
	big.text = _act_cheer()
	if tries >= 3:
		talk.set_ruby_text("3 回とも 同じだった。%s" % String(unit["found"]), true)
		act_btn.text = "しるしを 見る"
	else:
		talk.set_ruby_text(_act_after(), true)
		act_btn.text = "もう いちど"
	act_btn.disabled = false


func _start_quiz() -> void:
	phase = 2
	map.visible = false
	figure.visible = true
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	problem = ProblemGen.generate(String(unit["stage"]), rng, 0)
	figure.set_spec(problem["fig"])
	input_text = ""
	keypad.answer_lbl.text = " "
	keypad.unit_lbl.text = String(problem.get("unit", ""))
	keypad.visible = true
	answer_btn.visible = true
	act_btn.visible = false
	big.text = ""
	talk.set_ruby_text("地図の しるし。" + _short(String(problem["q"])), true)


func _short(text: String) -> String:
	var t := text.replace("を求めなさい。", "は?")
	t = t.replace("は何度ですか。", "は何度?")
	return t.replace("ですか。", "?")


func _on_key(k: String) -> void:
	GameState.play_sfx("type")
	input_text = Keypad.apply(input_text, k)
	keypad.answer_lbl.text = input_text if input_text != "" else " "


func _submit() -> void:
	var v := Keypad.value_of(input_text)
	if is_nan(v):
		GameState.play_sfx("fail")
		big.text = "数を いれてね"
		return
	if absf(v - float(problem["answer"])) < maxf(float(problem.get("tol", 0.01)), 0.01):
		GameState.play_sfx("clear")
		big.text = "あたり！"
		talk.set_ruby_text("しるしが とけた。%s" % String(unit["found"]), true)
		keypad.visible = false
		answer_btn.visible = false
		act_btn.visible = true
		act_btn.text = "もどる"
		phase = 3
		GameState.record_kid_clear(String(unit["id"]))
	else:
		GameState.play_sfx("fail")
		big.text = "ちがうみたい"
		talk.set_ruby_text(String(unit["found"]) + "  もう いちど。", true)
		input_text = ""
		keypad.answer_lbl.text = " "


# =========================================================
# さわり方(act)ごとの ことば
# =========================================================

func _act_lead() -> String:
	match String(unit["act"]):
		"tear":
			return "三角形の かどを ゆびで つまんで、下の せんに ならべよう。3 つ ぜんぶ。"
		"slide":
			return "金色の かどを ゆびで つまんで、下の 線の 交わるところまで ずらそう。"
		"fold":
			return "点線で 折ってみよう。金色の ところを ゆびで つまんで、反対がわへ たおす。"
		"diag":
			return "左上の 点から、ほかの 点へ 線を 引こう。三角形が いくつ できるかな?"
		_:
			return "長い 針を ゆびで まわして、数字 1 つ分の かどを しらべよう。"


func _act_after() -> String:
	match String(unit["act"]):
		"tear":
			return "3 つ ならべたら まっすぐ。形を かえても 同じかな?"
		"slide":
			return "ずらしても かどの 大きさは 同じだった。ほかの ななめでも 同じ?"
		"fold":
			return "ぴったり 重なった。ほかの 形でも そうかな?"
		"diag":
			return "三角形に 分けられた。角の 数が ちがっても 同じ やり方かな?"
		_:
			return "数字 1 つ分は いつも 同じ大きさ。ほかの ところでも たしかめよう。"


func _act_cheer() -> String:
	match String(unit["act"]):
		"tear":
			return "ぴったり まっすぐ！ 180°"
		"slide":
			return "ぴったり 重なった！"
		"fold":
			return "ぴったり 重なった！"
		"diag":
			return "三角形 %d こ ＝ %d°" % [int(st.get("tri", 3)), int(st.get("tri", 3)) * 180]
		_:
			return "1 つ分 ＝ 30°"


# =========================================================
# さわる図をつくる
# =========================================================

func _reset_act() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	st = {}
	dragging = -1
	cheer = 0.0
	match String(unit["act"]):
		"tear":
			var b := rng.randf_range(40.0, 80.0)
			var c := rng.randf_range(40.0, 80.0)
			while 180.0 - b - c < 32.0 or 180.0 - b - c > 100.0:
				b = rng.randf_range(40.0, 80.0)
				c = rng.randf_range(40.0, 80.0)
			var a := 180.0 - b - c
			var side := 11.0
			var pb := Vector2(-side * 0.5, -3.0)
			var pc := Vector2(side * 0.5, -3.0)
			var ab := side * sin(deg_to_rad(c)) / sin(deg_to_rad(a))
			var pa := pb + Vector2(cos(deg_to_rad(b)), sin(deg_to_rad(b))) * ab
			st = {"tri": [pa, pb, pc], "deg": [a, b, c], "placed": [false, false, false]}
		"slide":
			var slope := rng.randf_range(28.0, 62.0)
			st = {"slope": slope, "at": Vector2.ZERO, "moved": false, "gap": 7.0}
		"fold":
			st = {"angle": rng.randf_range(35.0, 70.0), "fold": 0.0}
		"diag":
			var n: int = [4, 5, 6][mini(tries, 2)]
			st = {"n": n, "picked": [], "tri": n - 2}
		_:
			st = {"hand": rng.randi_range(1, 11), "target": rng.randi_range(1, 11), "set": false}
	if String(unit["act"]) == "clock":
		while int(st["target"]) == int(st["hand"]):
			st["target"] = rng.randi_range(1, 11)


# =========================================================
# さわる図を描く
# =========================================================

func _to_screen(p: Vector2) -> Vector2:
	var k := minf(map.size.x / 16.0, map.size.y / 22.0)
	return Vector2(map.size.x * 0.5 + p.x * k, map.size.y * 0.42 - p.y * k)


func _line_y() -> float:
	return map.size.y * 0.86


## ちぎった かど(おうぎ形の紙きれ)
func _draw_piece(c: Control, at: Vector2, base_dir: float, size_deg: float,
		col: Color, radius: float) -> void:
	var pts := PackedVector2Array()
	pts.append(at)
	var n := maxi(int(size_deg / 5.0), 5)
	for i in n + 1:
		var t := base_dir + deg_to_rad(size_deg) * float(i) / float(n)
		var r := radius * (1.0 + (0.06 if i % 2 == 0 else -0.05))
		pts.append(at + Vector2(cos(t), -sin(t)) * r)
	c.draw_colored_polygon(pts, col)
	c.draw_polyline(pts, Color(1, 1, 1, 0.75), 2.0)


static func _math_angle(v: Vector2) -> float:
	return Vector2(v.x, -v.y).angle()


static func _wrap_diff(a: float, b: float) -> float:
	var d := b - a
	while d > PI:
		d -= TAU
	while d < -PI:
		d += TAU
	return d


func _draw_map() -> void:
	var c := map
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.13, 0.18, 0.30))
	match String(unit["act"]):
		"tear":
			_draw_tear(c)
		"slide":
			_draw_slide(c)
		"fold":
			_draw_fold(c)
		"diag":
			_draw_diag(c)
		_:
			_draw_clock(c)


func _draw_tear(c: Control) -> void:
	var tri: Array = st["tri"]
	var placed: Array = st["placed"]
	var deg: Array = st["deg"]
	var sp := PackedVector2Array()
	for p in tri:
		sp.append(_to_screen(p))
	c.draw_colored_polygon(sp, Color(0.40, 0.60, 0.95, 0.30))
	c.draw_polyline(PackedVector2Array([sp[0], sp[1], sp[2], sp[0]]), INK, 4.0)
	for i in 3:
		if bool(placed[i]) or i == dragging:
			continue
		var at: Vector2 = sp[i]
		var d1 := _math_angle(sp[(i + 1) % 3] - at)
		var d2 := _math_angle(sp[(i + 2) % 3] - at)
		var start: float = d1
		if _wrap_diff(d1, d2) < 0.0:
			start = d2
		_draw_piece(c, at, start, float(deg[i]), PIECE_COL[i], 74.0)
	var ly := _line_y()
	c.draw_line(Vector2(20, ly), Vector2(c.size.x - 20, ly), Color(1, 1, 1, 0.85), 5.0)
	var origin := Vector2(c.size.x * 0.5 - 130.0, ly)
	var base := 0.0
	for i in 3:
		if not bool(placed[i]):
			continue
		_draw_piece(c, origin, deg_to_rad(base), float(deg[i]), PIECE_COL[i], 120.0)
		base += float(deg[i])
	if dragging >= 0:
		_draw_piece(c, st["drag_pos"], deg_to_rad(90.0 - float(deg[dragging]) * 0.5),
			float(deg[dragging]), PIECE_COL[dragging], 88.0)
	if cheer > 0.0:
		c.draw_arc(origin, 120.0 + (1.0 - cheer) * 50.0, PI, TAU, 40,
			Color(1.0, 0.95, 0.5, cheer), 6.0)


## 平行な 2 本の線と、ななめの線。金色の かどを もう一方の交点へ運ぶ
func _draw_slide(c: Control) -> void:
	var gap: float = st["gap"]
	var slope: float = st["slope"]
	var top := _to_screen(Vector2(0, gap * 0.5))
	var bottom := _to_screen(Vector2(0, -gap * 0.5))
	var dx := c.size.x * 0.5
	c.draw_line(Vector2(20, top.y), Vector2(c.size.x - 20, top.y), INK, 4.0)
	c.draw_line(Vector2(20, bottom.y), Vector2(c.size.x - 20, bottom.y), INK, 4.0)
	var dir := Vector2(cos(deg_to_rad(slope)), -sin(deg_to_rad(slope)))
	var cross_top := Vector2(dx - 90.0, top.y)
	var cross_bottom := cross_top + dir * ((bottom.y - top.y) / dir.y)
	c.draw_line(cross_top - dir * 200.0, cross_bottom + dir * 200.0, Color(1, 0.85, 0.4), 4.0)
	# 交点の しるし
	for p in [cross_top, cross_bottom]:
		c.draw_circle(p, 9.0, Color(0.8, 0.86, 1.0))
	# 上の交点の かど(これを運ぶ)
	var here: Vector2 = cross_top if not bool(st["moved"]) else cross_bottom
	if dragging >= 0:
		here = st["drag_pos"]
	var ang := deg_to_rad(slope)
	_draw_piece(c, here, 0.0, slope, PIECE_COL[0], 78.0)
	if bool(st["moved"]):
		c.draw_string(ThemeDB.fallback_font, Vector2(24, c.size.y - 20),
			"下の 交わるところでも 同じ 大きさ", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, GOLD)
	else:
		c.draw_string(ThemeDB.fallback_font, Vector2(24, c.size.y - 20),
			"金色の かどを 下の ● まで はこぼう", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, DIM)


## 二等辺三角形を まん中で 折る
func _draw_fold(c: Control) -> void:
	var a: float = st["angle"]
	var t: float = st["fold"]
	var top := _to_screen(Vector2(0, 6.5))
	var bl := _to_screen(Vector2(-5.0, -3.5))
	var br := _to_screen(Vector2(5.0, -3.5))
	c.draw_colored_polygon(PackedVector2Array([top, bl, br]), Color(0.40, 0.60, 0.95, 0.28))
	c.draw_polyline(PackedVector2Array([top, bl, br, top]), INK, 4.0)
	var mid := (bl + br) * 0.5
	c.draw_dashed_line(top, mid, Color(1, 1, 1, 0.6), 2.5, 10.0)
	# 右半分を 左へ たおす(t = 0..1)
	var moved_br := br.lerp(bl, t)
	var moved_mid := mid.lerp(mid, t)
	c.draw_colored_polygon(PackedVector2Array([top, moved_mid, moved_br]),
		Color(1.0, 0.78, 0.35, 0.6))
	c.draw_polyline(PackedVector2Array([top, moved_mid, moved_br, top]), GOLD, 3.0)
	c.draw_string(ThemeDB.fallback_font, Vector2(24, c.size.y - 20),
		"右がわを つまんで、左へ たおそう" if t < 0.95 else "ぴったり 重なった",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, DIM if t < 0.95 else GOLD)


## 多角形を 対角線で 三角形に 分ける
func _draw_diag(c: Control) -> void:
	var n: int = st["n"]
	var picked: Array = st["picked"]
	var pts: Array = []
	for i in n:
		var th := TAU * float(i) / float(n) + PI * 0.5
		pts.append(_to_screen(Vector2(cos(th), sin(th)) * 7.0))
	var poly := PackedVector2Array()
	for p in pts:
		poly.append(p)
	c.draw_colored_polygon(poly, Color(0.40, 0.60, 0.95, 0.28))
	for i in n:
		c.draw_line(pts[i], pts[(i + 1) % n], INK, 4.0)
	for i in picked:
		c.draw_line(pts[0], pts[int(i)], GOLD, 3.5)
	for i in n:
		c.draw_circle(pts[i], 11.0, GOLD if i == 0 else Color(0.85, 0.9, 1.0))
	c.draw_string(ThemeDB.fallback_font, Vector2(24, c.size.y - 20),
		"金色の 点から、まだ つないでいない 点へ", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, DIM)


## 時計の 針を まわす
func _draw_clock(c: Control) -> void:
	var center := Vector2(c.size.x * 0.5, c.size.y * 0.46)
	var r := minf(c.size.x, c.size.y) * 0.34
	c.draw_arc(center, r, 0.0, TAU, 60, INK, 4.0)
	for i in 12:
		var th := deg_to_rad(-90.0 + 30.0 * float(i))
		var d := Vector2(cos(th), sin(th))
		c.draw_line(center + d * (r - 16.0), center + d * r, Color(0.8, 0.86, 1.0), 3.0)
		if i % 3 == 0:
			c.draw_string(ThemeDB.fallback_font, center + d * (r - 46.0) + Vector2(-10, 10),
				str(12 if i == 0 else i), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, INK)
	var hand := int(st["hand"])
	var target := int(st["target"])
	var th_t := deg_to_rad(-90.0 + 30.0 * float(target))
	c.draw_line(center, center + Vector2(cos(th_t), sin(th_t)) * (r - 26.0),
		Color(0.55, 0.85, 1.0), 6.0)
	var th_h := deg_to_rad(-90.0 + 30.0 * float(hand))
	c.draw_line(center, center + Vector2(cos(th_h), sin(th_h)) * (r - 26.0), GOLD, 7.0)
	var diff: int = absi(target - hand)
	diff = mini(diff, 12 - diff)
	c.draw_string(ThemeDB.fallback_font, Vector2(24, c.size.y - 20),
		"金色の 針を まわして、数字 %d に あわせよう(いま %d こ分 ＝ %d°)" % [target, diff, diff * 30],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, DIM)


# =========================================================
# さわる(ゆび)
# =========================================================

func _on_map_input(event: InputEvent) -> void:
	if phase != 1:
		return
	var act := String(unit["act"])
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_press(act, event.position)
		else:
			_release(act, event.position)
		map.queue_redraw()
	elif dragging >= 0:
		st["drag_pos"] = event.position
		if act == "fold":
			_fold_by(event.position)
		map.queue_redraw()


func _press(act: String, at: Vector2) -> void:
	match act:
		"tear":
			var tri: Array = st["tri"]
			var placed: Array = st["placed"]
			var best := -1
			var best_d := 130.0
			for i in 3:
				if bool(placed[i]):
					continue
				var d := _to_screen(tri[i]).distance_to(at)
				if d < best_d:
					best_d = d
					best = i
			if best >= 0:
				dragging = best
				st["drag_pos"] = at
				GameState.play_sfx("type")
		"slide":
			if not bool(st["moved"]):
				dragging = 0
				st["drag_pos"] = at
				GameState.play_sfx("type")
		"fold":
			dragging = 0
			_fold_by(at)
		"diag":
			_tap_diag(at)
		"clock":
			dragging = 0
			_turn_clock(at)


func _release(act: String, at: Vector2) -> void:
	if dragging < 0:
		return
	match act:
		"tear":
			if at.y > _line_y() - 170.0:
				var placed: Array = st["placed"]
				placed[dragging] = true
				GameState.play_sfx("correct")
				var n := 0
				for p in placed:
					if bool(p):
						n += 1
				if n == 3:
					_act_done()
		"slide":
			var gap: float = st["gap"]
			var bottom := _to_screen(Vector2(0, -gap * 0.5))
			var dir := Vector2(cos(deg_to_rad(float(st["slope"]))), -sin(deg_to_rad(float(st["slope"]))))
			var cross_top := Vector2(map.size.x * 0.5 - 90.0, _to_screen(Vector2(0, gap * 0.5)).y)
			var cross_bottom := cross_top + dir * ((bottom.y - cross_top.y) / dir.y)
			if at.distance_to(cross_bottom) < 120.0:
				st["moved"] = true
				GameState.play_sfx("correct")
				_act_done()
		"fold":
			if float(st["fold"]) > 0.95:
				GameState.play_sfx("correct")
				_act_done()
		"clock":
			if int(st["hand"]) == int(st["target"]):
				GameState.play_sfx("correct")
				_act_done()
	dragging = -1


## 折る量(0..1)を 指の位置から決める
func _fold_by(at: Vector2) -> void:
	var bl := _to_screen(Vector2(-5.0, -3.5))
	var br := _to_screen(Vector2(5.0, -3.5))
	var t := clampf((br.x - at.x) / maxf(br.x - bl.x, 1.0), 0.0, 1.0)
	st["fold"] = t


## 対角線を 1 本ずつ引く
func _tap_diag(at: Vector2) -> void:
	var n: int = st["n"]
	var picked: Array = st["picked"]
	for i in range(2, n - 1):
		var th := TAU * float(i) / float(n) + PI * 0.5
		var p := _to_screen(Vector2(cos(th), sin(th)) * 7.0)
		if at.distance_to(p) < 90.0 and not picked.has(i):
			picked.append(i)
			GameState.play_sfx("type")
			if picked.size() >= n - 3:
				GameState.play_sfx("correct")
				st["tri"] = n - 2
				_act_done()
			return


## 針を まわす
func _turn_clock(at: Vector2) -> void:
	var center := Vector2(map.size.x * 0.5, map.size.y * 0.46)
	var v := at - center
	var deg := rad_to_deg(atan2(v.y, v.x)) + 90.0
	while deg < 0.0:
		deg += 360.0
	st["hand"] = int(round(deg / 30.0)) % 12
