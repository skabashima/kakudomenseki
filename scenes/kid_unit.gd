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
var answer_row: HBoxContainer
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
	# ＝(計算)と こたえる を ならべる(本編 problem.gd と 同じ 使いごこち)
	answer_row = HBoxContainer.new()
	answer_row.add_theme_constant_override("separation", 10)
	answer_row.visible = false
	root.add_child(answer_row)
	var calc_btn := Button.new()
	calc_btn.text = "＝ 計算"
	calc_btn.custom_minimum_size = Vector2(0, 88)
	calc_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calc_btn.add_theme_font_size_override("font_size", 28)
	GameState.style_button(calc_btn, Color(0.24, 0.42, 0.72))
	calc_btn.pressed.connect(_calc_in_place)
	answer_row.add_child(calc_btn)
	answer_btn = Button.new()
	answer_btn.text = "こたえる"
	answer_btn.custom_minimum_size = Vector2(0, 88)
	answer_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	answer_btn.size_flags_stretch_ratio = 1.6
	answer_btn.add_theme_font_size_override("font_size", 30)
	GameState.style_button(answer_btn, Color(0.22, 0.55, 0.35))
	answer_btn.pressed.connect(_submit)
	answer_row.add_child(answer_btn)

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
	answer_row.visible = true
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


## ＝キー: 式をその場で計算して、答え欄を計算結果に置きかえる(本編と同じ)
func _calc_in_place() -> void:
	if input_text == "":
		return
	var res: Dictionary = ExprEval.eval(input_text)
	if not bool(res["ok"]):
		GameState.play_sfx("fail")
		big.text = String(res["err"])
		return
	GameState.play_sfx("type")
	big.text = ""
	input_text = ExprEval.fmt(float(res["value"]))
	keypad.answer_lbl.text = input_text


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
		answer_row.visible = false
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
			if String(unit["id"]) == "k7":
				return "外がわの かどを 3 つ ならべよう。まん中の へこんだ かどと くらべて。"
			return "三角形の かどを ゆびで つまんで、下の せんに ならべよう。3 つ ぜんぶ。"
		"slide":
			return "金色の かどを ゆびで つまんで、下の 線の 交わるところまで ずらそう。"
		"fold":
			return "点線で 折ってみよう。金色の ところを ゆびで つまんで、反対がわへ たおす。"
		"diag":
			return "左上の 点から、ほかの 点へ 線を 引こう。三角形が いくつ できるかな?"
		"clock":
			return "長い 針を ゆびで まわして、数字 1 つ分の かどを しらべよう。"
		"grid":
			return "金色の 点を つまんで、うすい 形に あわせよう。ますを 数えてみて。"
		"cut":
			return "金色の ところを つまんで、反対がわへ 運ぼう。"
		"roll":
			return "円を 右へ ころがそう。1 まわりで さしわたし 何こ分 進むかな?"
		"shift":
			return "金色の 点を つまんで、左右に 動かしてみよう。"
		"stack":
			return "はこの 中を タップして、さいころを つもう。"
		"open":
			return "金色の ところを つまんで、ゆっくり ひらこう。"
		"pour":
			return "右の 器の はばを 変えてみよう。水の 深さは どうなる?"
		_:
			return "太陽を 上下に 動かして、くいと 木の 影を くらべよう。"


func _act_after() -> String:
	match String(unit["act"]):
		"tear":
			if String(unit["id"]) == "k7":
				return "3 つ あわせると へこんだ かどと 同じだった。形を かえても?"
			return "3 つ ならべたら まっすぐ。形を かえても 同じかな?"
		"slide":
			return "ずらしても かどの 大きさは 同じだった。ほかの ななめでも 同じ?"
		"fold":
			return "ぴったり 重なった。ほかの 形でも そうかな?"
		"diag":
			return "三角形に 分けられた。角の 数が ちがっても 同じ やり方かな?"
		"clock":
			return "数字 1 つ分は いつも 同じ大きさ。ほかの ところでも たしかめよう。"
		"grid":
			return "ますの 数は たて × よこ に なっていた。ほかの 大きさでも 同じかな?"
		"cut":
			return "切って 運んでも 広さは 変わらない。ほかの 形でも 同じ?"
		"roll":
			return "さしわたし 3 こ分と ちょっとだった。大きさを 変えても 同じかな?"
		"shift":
			return "動かしても 数は 変わらなかった。ほかの 場所でも?"
		"stack":
			return "たて × よこ × 高さ の 数だけ 入った。ほかの はこでも 同じ?"
		"open":
			return "ひらいても、面の 数は 変わらない。"
		"pour":
			return "はばを 変えると 深さが 変わる。でも かけ算は 同じ。"
		_:
			return "太陽が 動いても、2 つの わり算は 同じ だった。"


func _act_cheer() -> String:
	match String(unit["act"]):
		"tear":
			if String(unit["id"]) == "k7":
				return "へこんだ かどと 同じ！ %d°" % roundi(float(st.get("dent", 0.0)))
			return "ぴったり まっすぐ！ 180°"
		"slide":
			return "ぴったり 重なった！"
		"fold":
			return "ぴったり 重なった！"
		"diag":
			return "三角形 %d こ ＝ %d°" % [int(st.get("tri", 3)), int(st.get("tri", 3)) * 180]
		"clock":
			return "1 つ分 ＝ 30°"
		"grid":
			return "%d × %d ＝ %d ます" % [int(st.get("h", 1)), int(st.get("w", 1)),
				int(st.get("w", 1)) * int(st.get("h", 1))]
		"cut":
			return "広さは そのまま！"
		"roll":
			return "1 まわり ＝ さしわたし 3.14 こ分"
		"shift":
			return "ぴったり 同じ！"
		"stack":
			return "%d × %d × %d ＝ %d こ" % [int(st.get("bh", 1)), int(st.get("bd", 1)),
				int(st.get("bw", 1)), int(st.get("bw", 1)) * int(st.get("bd", 1)) * int(st.get("bh", 1))]
		"open":
			return "ひらいた！"
		"pour":
			return "かけ算は いつも 24"
		_:
			return "どちらも 同じ わり算！"


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
			if String(unit["id"]) == "k7":
				# 矢じりの形。外がわの 3 つの かどを ちぎると、へこんだ かどに なる
				var da := Vector2(0.0, 7.5)
				var db := Vector2(-6.0, -3.0)
				var dc := Vector2(6.0, -3.0)
				var dp := Vector2(0.0, 1.2 + rng.randf_range(-0.5, 1.2))
				var ang_a := rad_to_deg(absf((db - da).angle_to(dc - da)))
				var ang_b := rad_to_deg(absf((da - db).angle_to(dp - db)))
				var ang_c := rad_to_deg(absf((da - dc).angle_to(dp - dc)))
				st = {"tri": [da, db, dc], "deg": [ang_a, ang_b, ang_c],
					"placed": [false, false, false], "poly": [da, db, dp, dc],
					"dent": ang_a + ang_b + ang_c, "dent_at": dp}
			else:
				st = {"tri": [pa, pb, pc], "deg": [a, b, c], "placed": [false, false, false],
					"poly": [pa, pb, pc]}
		"slide":
			var slope := rng.randf_range(28.0, 62.0)
			st = {"slope": slope, "at": Vector2.ZERO, "moved": false, "gap": 7.0}
		"fold":
			st = {"angle": rng.randf_range(35.0, 70.0), "fold": 0.0}
		"diag":
			var n: int = [4, 5, 6][mini(tries, 2)]
			st = {"n": n, "picked": [], "tri": n - 2}
		"grid":
			st = {"w": 2, "h": 2, "tw": rng.randi_range(3, 8), "th": rng.randi_range(2, 5)}
		"cut":
			st = {"moved": 0.0}
		"roll":
			st = {"turns": 0.0}
		"shift":
			st = {"pos": 0.0 if String(unit["id"]) == "k21" else 4.0, "from": 0.0}
		"stack":
			st = {"n": 0, "bw": rng.randi_range(2, 4), "bd": rng.randi_range(2, 3),
				"bh": rng.randi_range(2, 3)}
		"open":
			st = {"open": 0.0}
		"pour":
			st = {"w": 3.0, "from": 3.0}
		"shadow":
			st = {"sun": 45.0, "from": 45.0}
		"clock":
			st = {"hand": rng.randi_range(1, 11), "target": rng.randi_range(1, 11), "set": false}
	if String(unit["act"]) == "clock":
		while int(st["target"]) == int(st["hand"]):
			st["target"] = rng.randi_range(1, 11)


# =========================================================
# さわる図を描く
# =========================================================

func _to_screen(p: Vector2) -> Vector2:
	# ちぎった かど(半径 74)のぶんも 入るように、少し小さめに置く
	var k := minf(map.size.x / 16.0, map.size.y / 26.0)
	var ox := map.size.x * 0.5
	var oy := map.size.y * 0.46
	if st.has("poly"):
		# 細長い 三角形は 決めうちの 倍率だと 図の上端が map の外に 出てしまい、
		# 外に出た かどは タッチが 届かず つかめない。図の 外わくに あわせて
		# 倍率と 置き場所を 直し、かならず map の 中に おさめる
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for q in st["poly"]:
			lo = lo.min(q)
			hi = hi.max(q)
		var top := 24.0
		# _release の「ならべた」判定(_line_y() - 170 より下)に かからない ところまで
		var bottom := _line_y() - 210.0
		var side := 30.0
		k = minf(k, (map.size.x - side * 2.0) / maxf(hi.x - lo.x, 0.001))
		k = minf(k, (bottom - top) / maxf(hi.y - lo.y, 0.001))
		oy = clampf(oy, top + hi.y * k, bottom + lo.y * k)
		ox = clampf(ox, side - lo.x * k, map.size.x - side - hi.x * k)
	return Vector2(ox + p.x * k, oy - p.y * k)


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
		"clock":
			_draw_clock(c)
		"grid":
			_draw_grid(c)
		"cut":
			_draw_cut(c)
		"roll":
			_draw_roll(c)
		"shift":
			_draw_shift(c)
		"stack":
			_draw_stack(c)
		"open":
			_draw_open(c)
		"pour":
			_draw_pour(c)
		_:
			_draw_shadow(c)


func _draw_tear(c: Control) -> void:
	var tri: Array = st["tri"]
	var placed: Array = st["placed"]
	var deg: Array = st["deg"]
	var poly: Array = st.get("poly", tri)
	var shape := PackedVector2Array()
	for p in poly:
		shape.append(_to_screen(p))
	var center := Vector2.ZERO
	for q in shape:
		center += q
	center /= float(shape.size())
	c.draw_colored_polygon(shape, Color(0.40, 0.60, 0.95, 0.30))
	c.draw_polyline(shape + PackedVector2Array([shape[0]]), INK, 4.0)
	if st.has("dent_at"):
		# へこんだ かども 見せておく(ちぎった 3 つと くらべるため)
		var dp := _to_screen(st["dent_at"])
		c.draw_arc(dp, 46.0, 0.0, TAU, 24, Color(1, 1, 1, 0.18), 2.0)
		c.draw_string(ThemeDB.fallback_font, dp + Vector2(-26.0, -18.0),
			"%d°" % roundi(float(st["dent"])), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, SKY)
	var sp := PackedVector2Array()
	for p in tri:
		sp.append(_to_screen(p))
	for i in 3:
		if bool(placed[i]) or i == dragging:
			continue
		var at: Vector2 = sp[i]
		var d1 := _math_angle(sp[(i + 1) % 3] - at)
		var d2 := _math_angle(sp[(i + 2) % 3] - at)
		if st.has("dent_at") and i > 0:
			# 矢じりのときは、外の かどは A と へこみ P にはさまれている
			d2 = _math_angle(_to_screen(st["dent_at"]) - at)
			d1 = _math_angle(sp[0] - at)
		var start: float = d1
		if _wrap_diff(d1, d2) < 0.0:
			start = d2
		var mid_dir := start + deg_to_rad(float(deg[i])) * 0.5
		if absf(_wrap_diff(mid_dir, _math_angle(center - at))) > PI * 0.5:
			start = start + deg_to_rad(float(deg[i])) - deg_to_rad(360.0)
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


## 平行な 2 本の線と、ななめの線。金色の かどを もう一方の交点へ運ぶ。
## 画面の座標だけで組み立てる(y は下向き)。前は上下の向きを取りちがえて、
## ななめの線が 交点を 通らずに 浮いていた
func _slide_points() -> Array:
	var y_top := map.size.y * 0.30
	var y_bottom := map.size.y * 0.64
	# ゆるい かたむきだと 左端(90)から 引いても 下の交点が 右へ はみ出す。
	# 画面の はばに 入る かたむきまで 立ててから 使う
	var slope := maxf(float(st["slope"]),
		rad_to_deg(atan((y_bottom - y_top) / maxf(map.size.x - 220.0, 1.0))))
	var dir := Vector2(cos(deg_to_rad(slope)), sin(deg_to_rad(slope)))
	# 下の交点が 右へ はみ出さない ところから 引く
	var dx := (y_bottom - y_top) / maxf(tan(deg_to_rad(slope)), 0.05)
	var p_top := Vector2(clampf(map.size.x - 130.0 - dx, 90.0, map.size.x * 0.34), y_top)
	var p_bottom := p_top + dir * ((y_bottom - y_top) / maxf(dir.y, 0.05))
	return [p_top, p_bottom, dir, y_top, y_bottom, slope]


func _draw_slide(c: Control) -> void:
	var pts := _slide_points()
	var p_top: Vector2 = pts[0]
	var p_bottom: Vector2 = pts[1]
	var dir: Vector2 = pts[2]
	var y_top: float = pts[3]
	var y_bottom: float = pts[4]
	# 平行な 2 本
	c.draw_line(Vector2(20, y_top), Vector2(c.size.x - 20, y_top), INK, 4.0)
	c.draw_line(Vector2(20, y_bottom), Vector2(c.size.x - 20, y_bottom), INK, 4.0)
	# ななめの線(2 本を つらぬく)
	c.draw_line(p_top - dir * 140.0, p_bottom + dir * 140.0, Color(1, 0.85, 0.4, 0.85), 4.0)
	# 交わる ところ
	c.draw_circle(p_top, 10.0, Color(0.85, 0.9, 1.0))
	c.draw_circle(p_bottom, 14.0 if not bool(st["moved"]) else 10.0,
		GOLD if not bool(st["moved"]) else Color(0.85, 0.9, 1.0))
	# 運ぶ かど(上の交点 → 下の交点)
	var here: Vector2 = p_bottom if bool(st["moved"]) else p_top
	if dragging >= 0:
		here = st["drag_pos"]
	# かどの 大きさも、実際に 引いた 線の かたむきに あわせる
	var slope: float = pts[5]
	_draw_piece(c, here, deg_to_rad(-slope), slope, PIECE_COL[0], 82.0)
	if bool(st["moved"]):
		# くらべる ため、上の かども うすく のこす
		_draw_piece(c, p_top, deg_to_rad(-slope), slope, Color(1.0, 0.78, 0.35, 0.35), 82.0)
	c.draw_string(ThemeDB.fallback_font, Vector2(24, c.size.y - 18),
		"下の 交わる ところでも 同じ 大きさ" if bool(st["moved"])
			else "金色の かどを 下の ● まで はこぼう",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, GOLD if bool(st["moved"]) else DIM)


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
# 面積の さわり方
# =========================================================

## ますの 1 目もりを 画面の 何ドットに するか
func _cell() -> float:
	return minf(map.size.x / 13.0, map.size.y / 12.0)


func _grid_origin() -> Vector2:
	return Vector2(map.size.x * 0.5 - _cell() * 4.0, map.size.y * 0.62)


func _draw_grid_bg(c: Control, cols: int, rows: int) -> void:
	var s := _cell()
	var o := _grid_origin()
	for i in cols + 1:
		c.draw_line(o + Vector2(s * i, 0), o + Vector2(s * i, -s * rows),
			Color(1, 1, 1, 0.10), 1.5)
	for j in rows + 1:
		c.draw_line(o + Vector2(0, -s * j), o + Vector2(s * cols, -s * j),
			Color(1, 1, 1, 0.10), 1.5)


## ますに合わせて 四角を つくる(たて × よこ)
func _draw_grid(c: Control) -> void:
	var s := _cell()
	var o := _grid_origin()
	var w: int = st["w"]
	var h: int = st["h"]
	var tw: int = st["tw"]
	var th: int = st["th"]
	_draw_grid_bg(c, 9, 7)
	# めあての 形
	c.draw_rect(Rect2(o + Vector2(0, -s * th), Vector2(s * tw, s * th)),
		Color(1.0, 0.85, 0.3, 0.18))
	c.draw_rect(Rect2(o + Vector2(0, -s * th), Vector2(s * tw, s * th)),
		Color(1.0, 0.85, 0.3, 0.7), false, 3.0)
	# いまの 形
	var r := Rect2(o + Vector2(0, -s * h), Vector2(s * w, s * h))
	c.draw_rect(r, Color(0.40, 0.60, 0.95, 0.45))
	c.draw_rect(r, INK, false, 4.0)
	var uid := String(unit["id"])
	if uid == "k10":
		# 三角の 広さ: ななめに 分ける
		c.draw_line(o + Vector2(0, 0), o + Vector2(s * w, -s * h), GOLD, 4.0)
		c.draw_colored_polygon(PackedVector2Array([o, o + Vector2(s * w, 0),
			o + Vector2(s * w, -s * h)]), Color(1.0, 0.78, 0.35, 0.35))
	elif uid == "k15":
		# 四角の 中の 点から 四すみへ
		var p := o + Vector2(s * w * 0.42, -s * h * 0.6)
		for corner in [o, o + Vector2(s * w, 0), o + Vector2(s * w, -s * h), o + Vector2(0, -s * h)]:
			c.draw_line(p, corner, GOLD, 3.0)
		c.draw_colored_polygon(PackedVector2Array([o, o + Vector2(s * w, 0), p]),
			Color(0.55, 0.85, 1.0, 0.35))
		c.draw_colored_polygon(PackedVector2Array([o + Vector2(0, -s * h),
			o + Vector2(s * w, -s * h), p]), Color(0.55, 0.85, 1.0, 0.35))
	elif uid == "k16":
		# 底辺だけ のばす
		c.draw_colored_polygon(PackedVector2Array([o, o + Vector2(s * w, 0),
			o + Vector2(s * w * 0.35, -s * h)]), Color(1.0, 0.78, 0.35, 0.40))
	# つまむ ところ
	c.draw_circle(o + Vector2(s * w, -s * h), 16.0, GOLD)
	var font := ThemeDB.fallback_font
	c.draw_string(font, o + Vector2(s * w * 0.5 - 30.0, 34.0), "よこ %d" % w,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, INK)
	c.draw_string(font, o + Vector2(-96.0, -s * h * 0.5), "たて %d" % h,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, INK)
	c.draw_string(font, Vector2(24, map.size.y - 18),
		"金色の 点を つまんで、うすい 形に あわせよう(たて %d よこ %d)" % [th, tw],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 25, DIM)


## 切って 反対がわへ 運ぶ。運んだ あとに もとの形が 残らないよう、
## 「切ったあとの のこり」と「運ぶ かけら」を 別々に 持つ
func _cut_shapes() -> Array:
	var s := _cell()
	var o := _grid_origin()
	var uid := String(unit["id"])
	if uid == "k11":
		# かたむいた四角。左の三角を 切って 右へ
		var slant := s * 2.0
		var w := s * 5.0
		var h := s * 4.0
		var a := o + Vector2(slant, 0)
		var b := a + Vector2(w, 0)
		var t := o + Vector2(slant, -h)
		var d := o + Vector2(0, -h)
		return [PackedVector2Array([a, b, b + Vector2(0, -h), t]),
			PackedVector2Array([d, a, t]), Vector2(w, 0)]
	if uid == "k14":
		# L の字。下の 出っぱりを 切りはなす
		var w2 := s * 4.0
		var h2 := s * 5.0
		return [PackedVector2Array([o, o + Vector2(s * 3.0, 0), o + Vector2(s * 3.0, -h2),
				o + Vector2(0, -h2)]),
			PackedVector2Array([o + Vector2(s * 3.0, 0), o + Vector2(s * 3.0 + w2, 0),
				o + Vector2(s * 3.0 + w2, -s * 2.0), o + Vector2(s * 3.0, -s * 2.0)]),
			Vector2(s * 1.2, s * 1.6)]
	# 葉っぱ。右の おうぎ形を 左へ 重ねる
	var r := s * 5.0
	var corner := o
	var fan1 := PackedVector2Array([corner])
	for i in 13:
		var th := deg_to_rad(-90.0 * float(i) / 12.0)
		fan1.append(corner + Vector2(cos(th), sin(th)) * r)
	var corner2 := o + Vector2(r, -r)
	var fan2 := PackedVector2Array([corner2])
	for i in 13:
		var th2 := deg_to_rad(90.0 + 90.0 * float(i) / 12.0)
		fan2.append(corner2 + Vector2(cos(th2), sin(th2)) * r)
	return [fan1, fan2, Vector2(-s * 5.5, 0)]


func _draw_cut(c: Control) -> void:
	var s := _cell()
	var t: float = st["moved"]
	var parts := _cut_shapes()
	var rest: PackedVector2Array = parts[0]
	var piece: PackedVector2Array = parts[1]
	var shift: Vector2 = parts[2] * t
	_draw_grid_bg(c, 9, 7)
	if String(unit["id"]) == "k17":
		# 葉っぱは「重ねる」ので、動かす前の 位置に うすく 出しておく
		var ghost := PackedVector2Array()
		for p in piece:
			ghost.append(p + parts[2])
		c.draw_colored_polygon(ghost, Color(1, 1, 1, 0.06))
	c.draw_colored_polygon(rest, Color(0.40, 0.60, 0.95, 0.45))
	c.draw_polyline(rest + PackedVector2Array([rest[0]]), INK, 4.0)
	var moved := PackedVector2Array()
	for p in piece:
		moved.append(p + shift)
	c.draw_colored_polygon(moved, Color(1.0, 0.78, 0.35, 0.55))
	c.draw_polyline(moved + PackedVector2Array([moved[0]]), GOLD, 3.0)
	# つまむ ところ
	var grab := Vector2.ZERO
	for p in moved:
		grab += p
	grab /= float(moved.size())
	c.draw_circle(grab, 15.0, Color(1, 1, 1, 0.35))
	var done := t > 0.9
	var msg := "金色の ところを つまんで、反対がわへ 運ぼう"
	if String(unit["id"]) == "k14":
		msg = "金色の ところを つまんで、切りはなそう"
	elif String(unit["id"]) == "k17":
		msg = "金色の おうぎ形を 左へ 運んで、重ねよう"
	var done_msg := "ぴったり 四角に なった"
	if String(unit["id"]) == "k14":
		done_msg = "2 つの 四角に 分かれた"
	elif String(unit["id"]) == "k17":
		done_msg = "重なった ところが 葉っぱの 形"
	c.draw_string(ThemeDB.fallback_font, Vector2(24, map.size.y - 18),
		done_msg if done else msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, GOLD if done else DIM)


## 円を ころがす
func _draw_roll(c: Control) -> void:
	# 1 まわり(円周 = 2πr)ぶん ころがしても はみ出さない 大きさにする
	var r := minf((c.size.x - 90.0) / (TAU + 2.0), c.size.y * 0.16)
	var y := c.size.y * 0.52
	var start_x := 50.0 + r
	var turns: float = st["turns"]
	var x := start_x + TAU * r * turns
	c.draw_line(Vector2(30, y + r), Vector2(map.size.x - 30, y + r), INK, 4.0)
	# さしわたし 何こ分か の 目もり
	for i in 8:
		var mx := start_x + 2.0 * r * float(i)
		if mx > map.size.x - 30.0:
			break
		c.draw_line(Vector2(mx, y + r), Vector2(mx, y + r + 22.0), Color(0.8, 0.86, 1.0), 3.0)
		c.draw_string(ThemeDB.fallback_font, Vector2(mx - 8.0, y + r + 50.0), str(i),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24, DIM)
	c.draw_arc(Vector2(x, y), r, 0.0, TAU, 40, GOLD, 5.0)
	var mark := deg_to_rad(-90.0 + 360.0 * turns)
	c.draw_line(Vector2(x, y), Vector2(x, y) + Vector2(cos(mark), sin(mark)) * r, SKY, 4.0)
	c.draw_string(ThemeDB.fallback_font, Vector2(24, map.size.y - 18),
		"円を 右へ ころがそう(いま %.2f まわり ＝ さしわたし %.2f こ分)" % [
			turns, TAU * turns * 0.5], HORIZONTAL_ALIGNMENT_LEFT, -1, 25, DIM)


## 道を ずらす / 板を 動かす
func _draw_shift(c: Control) -> void:
	var s := _cell()
	var o := _grid_origin()
	var pos: float = st["pos"]
	_draw_grid_bg(c, 9, 7)
	if String(unit["id"]) == "k13":
		# 畑と 道
		var field := Rect2(o + Vector2(0, -s * 5.0), Vector2(s * 9.0, s * 5.0))
		c.draw_rect(field, Color(0.35, 0.62, 0.42, 0.45))
		c.draw_rect(field, INK, false, 4.0)
		var rx := o.x + s * pos
		c.draw_rect(Rect2(Vector2(rx, o.y - s * 5.0), Vector2(s, s * 5.0)),
			Color(0.60, 0.52, 0.40, 0.9))
		c.draw_circle(Vector2(rx + s * 0.5, o.y + 26.0), 16.0, GOLD)
		c.draw_string(ThemeDB.fallback_font, Vector2(24, map.size.y - 18),
			"道を 左右に 動かそう。のこりの 畑は たて 5 × よこ 8 の まま",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 25, DIM)
	else:
		# 門と 動く板
		var gate := Rect2(o + Vector2(s * 3.0, -s * 4.0), Vector2(s * 6.0, s * 4.0))
		c.draw_rect(gate, Color(0.30, 0.36, 0.52, 0.7))
		c.draw_rect(gate, INK, false, 4.0)
		var bx := o.x + s * pos
		var board := Rect2(Vector2(bx, o.y - s * 4.0), Vector2(s * 5.0, s * 4.0))
		c.draw_rect(board, Color(1.0, 0.78, 0.35, 0.35))
		c.draw_rect(board, GOLD, false, 3.0)
		var left := maxf(bx, gate.position.x)
		var right := minf(bx + s * 5.0, gate.position.x + gate.size.x)
		if right > left:
			c.draw_rect(Rect2(Vector2(left, gate.position.y), Vector2(right - left, gate.size.y)),
				Color(1.0, 0.85, 0.3, 0.55))
		c.draw_circle(Vector2(bx + s * 2.5, o.y + 26.0), 16.0, GOLD)
		c.draw_string(ThemeDB.fallback_font, Vector2(24, map.size.y - 18),
			"板を 右へ 動かそう。重なった ところが 広がっていく",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 25, DIM)


## つみ木を つむ
func _draw_stack(c: Control) -> void:
	var n: int = st["n"]
	var w: int = st["bw"]
	var d: int = st["bd"]
	var h: int = st["bh"]
	# はこが 画面いっぱいに 見えるように、そのつど 大きさを 決める
	var s := minf(map.size.x / (float(w) + float(d) * 0.42 + 1.6),
		map.size.y / (float(h) + float(d) * 0.30 + 2.2))
	var base := Vector2(map.size.x * 0.5 - s * (float(w) + float(d) * 0.42) * 0.5,
		map.size.y * 0.5 + s * (float(h) + float(d) * 0.30) * 0.5)
	# 箱の わく
	var box_pts: Array = []
	for p in [Vector3(0, 0, 0), Vector3(w, 0, 0), Vector3(w, d, 0), Vector3(0, d, 0),
			Vector3(0, 0, h), Vector3(w, 0, h), Vector3(w, d, h), Vector3(0, d, h)]:
		box_pts.append(base + Vector2(ProblemGen.proj3(p).x, -ProblemGen.proj3(p).y) * s)
	for e in [[0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6], [6, 7], [7, 4],
			[0, 4], [1, 5], [2, 6], [3, 7]]:
		c.draw_line(box_pts[e[0]], box_pts[e[1]], Color(1, 1, 1, 0.45), 2.5)
	# つんだ さいころ
	var placed := 0
	for z in h:
		for y in d:
			for x in w:
				if placed >= n:
					break
				var o3 := Vector3(x, y, z)
				var quad := PackedVector2Array()
				for q in [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)]:
					var pr := ProblemGen.proj3(o3 + q)
					quad.append(base + Vector2(pr.x, -pr.y) * s)
				c.draw_colored_polygon(quad, Color(0.55, 0.75, 1.0, 0.85))
				c.draw_polyline(quad + PackedVector2Array([quad[0]]), Color(1, 1, 1, 0.5), 1.5)
				placed += 1
	c.draw_string(ThemeDB.fallback_font, Vector2(24, map.size.y - 18),
		"タップして さいころを つもう(%d / %d こ)" % [n, w * d * h],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 25, DIM)


## 箱を ひらく / ななめに 切る
func _draw_open(c: Control) -> void:
	var t: float = st["open"]
	var s := _cell()
	var mid := Vector2(map.size.x * 0.5, map.size.y * 0.45)
	if String(unit["id"]) == "k19":
		# 十字に ひらく
		var faces := [Vector2(0, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(2, 0),
			Vector2(0, -1), Vector2(0, 1)]
		for i in faces.size():
			var f: Vector2 = faces[i]
			var pos := mid + f * s * 1.7 * t + Vector2(-s * 0.85, -s * 0.85)
			c.draw_rect(Rect2(pos, Vector2(s * 1.7, s * 1.7)),
				Color(0.55, 0.75, 1.0, 0.85 if i == 0 else 0.6))
			c.draw_rect(Rect2(pos, Vector2(s * 1.7, s * 1.7)), INK, false, 3.0)
		c.draw_string(ThemeDB.fallback_font, Vector2(24, map.size.y - 18),
			"つまんで ひらこう(面は 6 つ)" if t < 0.9 else "ひらいた! 面は 6 つ",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 25, DIM if t < 0.9 else GOLD)
	else:
		# ななめに 切った 箱と、さかさに した 同じ 箱
		var w := s * 4.0
		var h1 := s * 1.6
		var h2 := s * 4.2
		var o := mid + Vector2(-w, s * 1.6)
		c.draw_colored_polygon(PackedVector2Array([o, o + Vector2(w, 0),
			o + Vector2(w, -h2), o + Vector2(0, -h1)]), Color(0.40, 0.60, 0.95, 0.45))
		var flip_o := o + Vector2(w, 0) + Vector2(w, 0) * t
		c.draw_colored_polygon(PackedVector2Array([flip_o, flip_o + Vector2(w, 0),
			flip_o + Vector2(w, -h1), flip_o + Vector2(0, -h2)]),
			Color(1.0, 0.78, 0.35, 0.55))
		c.draw_string(ThemeDB.fallback_font, Vector2(24, map.size.y - 18),
			"さかさの 箱を 右へ 運ぼう" if t < 0.9 else "2 つで まっすぐな 箱に なった",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 25, DIM if t < 0.9 else GOLD)


## 水を 移す
func _draw_pour(c: Control) -> void:
	var s := _cell()
	var o := _grid_origin()
	var vol := 24.0
	var w: float = st["w"]
	var depth := vol / w
	# もとの 器(はば 3・水は いっぱい)
	c.draw_rect(Rect2(o + Vector2(0, -s * 8.0), Vector2(s * 3.0, s * 8.0)), INK, false, 4.0)
	c.draw_rect(Rect2(o + Vector2(0, -s * 8.0), Vector2(s * 3.0, s * 8.0)),
		Color(0.30, 0.60, 0.95, 0.5))
	var rx := o.x + s * 4.0
	c.draw_rect(Rect2(Vector2(rx, o.y - s * 8.0), Vector2(s * w, s * 8.0)), INK, false, 4.0)
	c.draw_rect(Rect2(Vector2(rx, o.y - s * depth), Vector2(s * w, s * depth)),
		Color(0.30, 0.60, 0.95, 0.5))
	c.draw_circle(Vector2(rx + s * w, o.y + 26.0), 16.0, GOLD)
	c.draw_string(ThemeDB.fallback_font, Vector2(24, map.size.y - 18),
		"右の 器の はばを 変えよう(はば %.1f・深さ %.1f・かけると %.0f)" % [w, depth, w * depth],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 25, DIM)


## 影で 測る。影の長さは 太陽の 高さで 大きく変わるので、
## そのつど 全体が 収まる 倍率を 決める(前は 右へ はみ出していた)
func _draw_shadow(c: Control) -> void:
	var th: float = st["sun"]
	var pole := 2.0
	var tree := 5.0
	var tree_x := 4.0
	var s1 := pole / tan(deg_to_rad(th))
	var s2 := tree / tan(deg_to_rad(th))
	var need_w := tree_x + s2 + 2.0
	var need_h := tree + 3.5
	var k := minf((c.size.x - 60.0) / need_w, (c.size.y - 150.0) / need_h)
	var ground := c.size.y * 0.74
	var ox := 40.0
	var font := ThemeDB.fallback_font
	c.draw_line(Vector2(20, ground), Vector2(c.size.x - 20, ground), INK, 4.0)
	# くい と 木
	for item in [[0.0, pole, s1, "くい"], [tree_x, tree, s2, "木"]]:
		var x: float = ox + float(item[0]) * k
		var h: float = float(item[1]) * k
		var sh: float = float(item[2]) * k
		c.draw_line(Vector2(x, ground), Vector2(x, ground - h), GOLD, 7.0)
		c.draw_line(Vector2(x, ground), Vector2(x + sh, ground), SKY, 6.0)
		c.draw_dashed_line(Vector2(x, ground - h), Vector2(x + sh, ground),
			Color(1, 1, 1, 0.35), 2.0, 9.0)
		c.draw_string(font, Vector2(x - 34.0, ground - h - 12.0), String(item[3]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24, GOLD)
	# 太陽(光の 向きに 置く)
	var dir := Vector2(-cos(deg_to_rad(th)), -sin(deg_to_rad(th)))
	# 太陽は 木の 上から 光の 向きへ(画面の 外に 出ないように)
	var sun := Vector2(ox + tree_x * k, ground - tree * k) + dir * (k * 1.8)
	sun.x = clampf(sun.x, 40.0, c.size.x - 40.0)
	sun.y = clampf(sun.y, 46.0, ground - 40.0)
	c.draw_circle(sun, 24.0, Color(1.0, 0.9, 0.4))
	c.draw_string(font, sun + Vector2(-18.0, -32.0), "太陽", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, DIM)
	c.draw_string(font, Vector2(24, c.size.y - 18),
		"太陽を 上下に 動かそう(くい %.1f ÷ %.1f ＝ %.2f ・ 木 %.1f ÷ %.1f ＝ %.2f)" % [
			pole, s1, pole / s1, tree, s2, tree / s2],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 24, DIM)


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
		_drag_to(act, event.position)
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
		"stack":
			var total: int = int(st["bw"]) * int(st["bd"]) * int(st["bh"])
			st["n"] = mini(int(st["n"]) + 1, total)
			GameState.play_sfx("type")
			if int(st["n"]) >= total:
				GameState.play_sfx("correct")
				_act_done()
		_:
			dragging = 0
			_drag_to(act, at)


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
			var cross_bottom: Vector2 = _slide_points()[1]
			if at.distance_to(cross_bottom) < 130.0:
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
		"grid":
			if int(st["w"]) == int(st["tw"]) and int(st["h"]) == int(st["th"]):
				GameState.play_sfx("correct")
				_act_done()
		"cut", "open":
			var key := "moved" if act == "cut" else "open"
			if float(st[key]) > 0.9:
				GameState.play_sfx("correct")
				_act_done()
		"roll":
			if float(st["turns"]) >= 1.0:
				GameState.play_sfx("correct")
				_act_done()
		"shift":
			if absf(float(st["pos"]) - float(st["from"])) >= 2.0:
				GameState.play_sfx("correct")
				_act_done()
		"pour":
			if absf(float(st["w"]) - float(st["from"])) >= 1.5:
				GameState.play_sfx("correct")
				_act_done()
		"shadow":
			if absf(float(st["sun"]) - float(st["from"])) >= 12.0:
				GameState.play_sfx("correct")
				_act_done()
	dragging = -1


## ゆびの 位置から、その さわり方の 値を 決める
func _drag_to(act: String, at: Vector2) -> void:
	var s := _cell()
	var o := _grid_origin()
	match act:
		"fold":
			_fold_by(at)
		"grid":
			st["w"] = clampi(int(round((at.x - o.x) / s)), 1, 9)
			st["h"] = clampi(int(round((o.y - at.y) / s)), 1, 7)
		"cut":
			# かけらの もとの まん中から、運び先までの 進みぐあい
			var parts := _cut_shapes()
			var piece: PackedVector2Array = parts[1]
			var from := Vector2.ZERO
			for q in piece:
				from += q
			from /= float(piece.size())
			var to_v: Vector2 = parts[2]
			st["moved"] = clampf((at - from).dot(to_v) / maxf(to_v.length_squared(), 1.0), 0.0, 1.0)
		"roll":
			var rr := minf((map.size.x - 90.0) / (TAU + 2.0), map.size.y * 0.16)
			st["turns"] = clampf((at.x - (50.0 + rr)) / maxf(TAU * rr, 1.0), 0.0, 1.05)
		"shift":
			st["pos"] = clampf((at.x - o.x) / s - 0.5, 0.0, 8.0)
		"pour":
			st["w"] = clampf((at.x - (o.x + s * 4.0)) / s, 1.5, 6.0)
		"shadow":
			st["sun"] = clampf(30.0 + (o.y - at.y) / s * 6.0, 25.0, 70.0)


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
