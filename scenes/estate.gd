extends Control
## 【試作】相続ミステリー「遺産の地図」第一話 ― 角の推理盤。
##
## ■ 遊び方の核
## 図には「分かっている角」と「?」がある。プレイヤーは**定理をえらんで、図の場所に当てる**。
## 当たれば、その場の角がひとつ埋まる。埋まった角を材料に次の定理を当てる ―― その連鎖で
## 目当ての角 x にたどりつく。数字を打ちこむ場面は無く、当てずっぽうも効かない。
## 「どの定理を、どこに、どの順で当てるか」だけが問われる。
##
## ■ 単元の進み方
## 第一単元は 三角形の内角の和 180° と、一直線 180°、角の分割 の 3 枚。
## 単元が進むごとに定理カードが増え(平行線・二等辺・外角・円周角…)、
## 前の単元のカードも使い続ける。だから最初の単元から順に積み上がる。

const GOLD := Color(1.0, 0.85, 0.3)
const SKY := Color(0.55, 0.85, 1.0)
const INK := Color(0.92, 0.95, 1.0)
const DIM := Color(0.62, 0.72, 0.88)
const DONE := Color(0.55, 0.95, 0.65)

enum Card { NONE, TRIANGLE, LINE, SPLIT }

## 点
var pts := {}
## 角 {"at": 点名, "from": 点名, "to": 点名, "value": float or -1, "target": bool}
var angles: Array = []
## 定理をあてる場所 {"card": Card, "terms": [[角の番号, 係数]...], "rhs": float, "hit": ...}
var rules: Array = []

var card: int = Card.NONE
var picked: Array = []          # 指さした点の名前
var moves := 0
var solved := false
var flash := -1                 # いま埋まった角(光らせる)
var flash_t := 0.0

var map: Control
var speaker: Label
var talk: Label
var hint: Label
var cards_row: HBoxContainer
var act_btn: Button
var step := 0

const SCRIPT := [
	["代訟人", "測量家オルドが死んだ。遺言は一通。土地の分け方だけが、こまごまと書かれている。"],
	["代訟人", "第一条 ―― 姉と弟の境は、頂点 A から杭 D へ張った縄とする。その角度を記録に残せ。"],
	["弟 ロウ", "「角度だと? 分度器を当てればいいだろう」  代訟人が首を振る。「土地は焼けました。残ったのは、この覚え書きだけです」"],
	["姉 セリカ", "「三か所だけ角が書いてある。……父は、これだけで足りると思っていたのね」"],
	["あなた", "縄も分度器もいらない。分かっている角から、順に埋めていけばいい。"],
]


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.13, 0.22)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build_case()

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
	back.text = "←もどる"
	back.custom_minimum_size = Vector2(0, 60)
	back.add_theme_font_size_override("font_size", 23)
	GameState.style_button(back, Color(0.28, 0.32, 0.44))
	back.pressed.connect(func() -> void: GameState.change_scene("res://scenes/main.tscn"))
	head.add_child(back)
	var title := Label.new()
	title.text = "  遺産の地図 ・ 第一話「覚え書きの角」"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", GOLD)
	head.add_child(title)

	map = Control.new()
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.custom_minimum_size = Vector2(0, 360)
	map.draw.connect(_draw_map)
	map.gui_input.connect(_on_map_input)
	root.add_child(map)

	cards_row = HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 8)
	cards_row.visible = false
	root.add_child(cards_row)
	_card_button("三角形の和\n180°", Card.TRIANGLE)
	_card_button("一直線\n180°", Card.LINE)
	_card_button("角を分ける\nたし引き", Card.SPLIT)

	hint = Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", SKY)
	root.add_child(hint)

	speaker = Label.new()
	speaker.add_theme_font_size_override("font_size", 23)
	speaker.add_theme_color_override("font_color", GOLD)
	root.add_child(speaker)

	talk = Label.new()
	talk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	talk.custom_minimum_size = Vector2(0, 84)
	talk.add_theme_font_size_override("font_size", 24)
	talk.add_theme_color_override("font_color", INK)
	root.add_child(talk)

	act_btn = Button.new()
	act_btn.custom_minimum_size = Vector2(0, 78)
	act_btn.add_theme_font_size_override("font_size", 27)
	GameState.style_button(act_btn, Color(0.22, 0.55, 0.35))
	act_btn.pressed.connect(_advance)
	root.add_child(act_btn)
	_show_step()


func _process(delta: float) -> void:
	if flash >= 0:
		flash_t += delta * 2.4
		if flash_t >= 1.0:
			flash = -1
			flash_t = 0.0
		map.queue_redraw()


func _card_button(text: String, which: int) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 84)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 21)
	GameState.style_button(b, Color(0.34, 0.30, 0.52))
	b.pressed.connect(func() -> void: _pick_card(which))
	cards_row.add_child(b)


# =========================================================
# 事件(図と、当てられる定理)
# =========================================================

## 三角形 ABC。BC 上に杭 D があり、A と結ばれている。
## 分かっているのは ∠B・∠C・∠BAD の 3 つだけ。求めるのは ∠DAC。
func _build_case() -> void:
	var ang_b := 50.0
	var ang_c := 60.0
	var ang_bad := 35.0
	var bc := 12.0
	var ab := bc * sin(deg_to_rad(ang_c)) / sin(deg_to_rad(180.0 - ang_b - ang_c))
	var b := Vector2(0, 0)
	var c := Vector2(bc, 0)
	var a := b + Vector2(cos(deg_to_rad(ang_b)), sin(deg_to_rad(ang_b))) * ab
	var bd := ab * sin(deg_to_rad(ang_bad)) / sin(deg_to_rad(180.0 - ang_b - ang_bad))
	var d := Vector2(bd, 0)
	pts = {"A": a, "B": b, "C": c, "D": d}

	angles = [
		{"at": "B", "from": "A", "to": "C", "value": ang_b},          # 0 ∠B
		{"at": "C", "from": "A", "to": "B", "value": ang_c},          # 1 ∠C
		{"at": "A", "from": "B", "to": "D", "value": ang_bad},        # 2 ∠BAD
		{"at": "A", "from": "D", "to": "C", "value": -1.0, "target": true},   # 3 ∠DAC = x
		{"at": "A", "from": "B", "to": "C", "value": -1.0},           # 4 ∠BAC
		{"at": "D", "from": "A", "to": "B", "value": -1.0},           # 5 ∠ADB
		{"at": "D", "from": "A", "to": "C", "value": -1.0},           # 6 ∠ADC
	]
	rules = [
		{"card": Card.TRIANGLE, "name": "三角形 ABD",
			"terms": [[0, 1.0], [2, 1.0], [5, 1.0]], "rhs": 180.0,
			"verts": ["A", "B", "D"]},
		{"card": Card.TRIANGLE, "name": "三角形 ADC",
			"terms": [[3, 1.0], [1, 1.0], [6, 1.0]], "rhs": 180.0,
			"verts": ["A", "D", "C"]},
		{"card": Card.TRIANGLE, "name": "三角形 ABC",
			"terms": [[0, 1.0], [1, 1.0], [4, 1.0]], "rhs": 180.0,
			"verts": ["A", "B", "C"]},
		{"card": Card.LINE, "name": "一直線 D",
			"terms": [[5, 1.0], [6, 1.0]], "rhs": 180.0, "verts": ["D"]},
		{"card": Card.SPLIT, "name": "角 A の分割",
			"terms": [[2, 1.0], [3, 1.0], [4, -1.0]], "rhs": 0.0, "verts": ["A"]},
	]


# =========================================================
# 定理を当てる
# =========================================================

func _pick_card(which: int) -> void:
	GameState.play_sfx("tap")
	card = which
	picked.clear()
	match card:
		Card.TRIANGLE:
			hint.text = "【三角形の和】どの三角形に当てる? 頂点を 3 つタップ"
		Card.LINE:
			hint.text = "【一直線】どの点で当てる? 一直線の上にある点をタップ"
		Card.SPLIT:
			hint.text = "【角を分ける】大きい角が 2 つに分かれている点をタップ"
	map.queue_redraw()


func _on_map_input(event: InputEvent) -> void:
	if solved or step < SCRIPT.size():
		return
	var is_tap := (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed)
	if not is_tap:
		return
	# 黙って無視しない。押しても何も起きない、が一番わかりにくい
	if card == Card.NONE:
		GameState.play_sfx("fail")
		hint.text = "先に下の定理カードをえらぶ(三角形の和 / 一直線 / 角を分ける)"
		return
	var name := _point_at(event.position)
	if name == "":
		GameState.play_sfx("fail")
		hint.text = "点から離れている。A・B・C・D のどれかをタップ  " + _picked_text()
		return
	GameState.play_sfx("type")
	if picked.has(name):
		picked.erase(name)
	else:
		picked.append(name)
	var need := 3 if card == Card.TRIANGLE else 1
	map.queue_redraw()
	if picked.size() < need:
		hint.text = "%s  ―― あと %d つ  %s" % [_card_help(), need - picked.size(), _picked_text()]
		return
	var target := -1
	for i in rules.size():
		var r: Dictionary = rules[i]
		if int(r["card"]) != card:
			continue
		var vs: Array = r["verts"]
		var same := vs.size() == picked.size()
		if same:
			for v in vs:
				if not picked.has(v):
					same = false
					break
		if same:
			target = i
			break
	picked.clear()
	if target < 0:
		GameState.play_sfx("fail")
		hint.text = "そこには当てられない。%s" % _card_help()
		map.queue_redraw()
		return
	_apply(target)


## タップした場所にいちばん近い点
func _point_at(s: Vector2) -> String:
	var best := ""
	var best_d := 110.0
	for name in pts.keys():
		var d := _to_screen(pts[name]).distance_to(s)
		if d < best_d:
			best_d = d
			best = String(name)
	return best


## いま指さしている点
func _picked_text() -> String:
	if picked.is_empty():
		return ""
	return "(えらんだ点: %s)" % " ".join(picked)


func _card_help() -> String:
	match card:
		Card.TRIANGLE:
			return "三角形の頂点を 3 つタップ"
		Card.LINE:
			return "一直線の上にある点をタップ"
		_:
			return "角が 2 つに分かれている点をタップ"


## その定理を当てる。分からない角がちょうど 1 つなら埋まる
func _apply(index: int) -> void:
	var r: Dictionary = rules[index]
	var unknown: Array = []
	var sum := 0.0
	for t in r["terms"]:
		var ai: int = t[0]
		var k: float = t[1]
		var v: float = float(angles[ai]["value"])
		if v < 0.0:
			unknown.append([ai, k])
		else:
			sum += k * v
	if unknown.is_empty():
		GameState.play_sfx("fail")
		hint.text = "%s は、もう全部わかっている" % String(r["name"])
		return
	if unknown.size() > 1:
		GameState.play_sfx("fail")
		hint.text = "%s は、まだ分からない角が %d つある。先に別のところを埋めよう" % [
			String(r["name"]), unknown.size()]
		return
	var ai: int = unknown[0][0]
	var k: float = unknown[0][1]
	var value := (float(r["rhs"]) - sum) / k
	angles[ai]["value"] = value
	moves += 1
	flash = ai
	flash_t = 0.0
	GameState.play_sfx("correct")
	hint.text = "%s から、%s = %s° が決まった(%d 手目)" % [
		String(r["name"]), _angle_name(ai), ProblemGen.fmt(value), moves]
	card = Card.NONE
	picked.clear()
	if bool(angles[3].get("target", false)) and float(angles[3]["value"]) >= 0.0:
		_solved()
	map.queue_redraw()


func _angle_name(i: int) -> String:
	var a: Dictionary = angles[i]
	return "∠%s%s%s" % [String(a["from"]), String(a["at"]), String(a["to"])]


func _solved() -> void:
	solved = true
	cards_row.visible = false
	GameState.play_sfx("clear")
	var stars := 1
	if moves <= 2:
		stars = 3
	elif moves <= 3:
		stars = 2
	speaker.text = "代訟人   %s" % ("★".repeat(stars) + "☆".repeat(3 - stars))
	talk.text = "「境の角、%s度。記録しました」  ―― %d 手。%s" % [
		ProblemGen.fmt(float(angles[3]["value"])), moves,
		"最短だ。" if stars == 3 else "遠まわりでも、答えは同じ。"]
	hint.text = ""
	act_btn.text = "手記を読む ▶"
	act_btn.pressed.disconnect(_advance)
	act_btn.pressed.connect(_show_note, CONNECT_ONE_SHOT)


# =========================================================
# 図
# =========================================================

func _to_screen(p: Vector2) -> Vector2:
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for q in pts.values():
		lo = lo.min(q)
		hi = hi.max(q)
	var pad := 52.0
	var span := hi - lo
	var k := minf((map.size.x - pad * 2.0) / maxf(span.x, 0.001),
		(map.size.y - pad * 2.0) / maxf(span.y, 0.001))
	var center := (lo + hi) * 0.5
	return map.size * 0.5 + Vector2((p.x - center.x) * k, -(p.y - center.y) * k)


func _to_world(s: Vector2) -> Vector2:
	var o := _to_screen(Vector2.ZERO)
	var ux := _to_screen(Vector2(1, 0)) - o
	return Vector2((s.x - o.x) / ux.x, -(s.y - o.y) / ux.x)


func _draw_map() -> void:
	var c := map
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.13, 0.17, 0.27))
	var font := ThemeDB.fallback_font

	# 当てられる場所をうっすら見せる(どこを押せるか分かるように)
	if card != Card.NONE:
		for name in pts.keys():
			c.draw_circle(_to_screen(pts[name]), 22.0, Color(0.55, 0.45, 0.85, 0.28))
	for name in picked:
		c.draw_circle(_to_screen(pts[name]), 17.0, Color(1.0, 0.55, 0.4, 0.75))

	# 土地(三角形 ABC)と、中の縄 AD
	var a: Vector2 = pts["A"]
	var b: Vector2 = pts["B"]
	var cc: Vector2 = pts["C"]
	var d: Vector2 = pts["D"]
	c.draw_colored_polygon(PackedVector2Array([_to_screen(a), _to_screen(b), _to_screen(cc)]),
		Color(0.35, 0.55, 0.9, 0.16))
	for e in [[a, b], [b, cc], [cc, a]]:
		c.draw_line(_to_screen(e[0]), _to_screen(e[1]), INK, 3.0)
	c.draw_line(_to_screen(a), _to_screen(d), GOLD, 3.0)

	# 角
	for i in angles.size():
		_draw_angle(c, font, i)

	# 点
	for name in pts.keys():
		var s := _to_screen(pts[name])
		if card != Card.NONE:
			c.draw_arc(s, 20.0, 0.0, TAU, 20, Color(0.75, 0.68, 1.0, 0.55), 2.0)
		c.draw_circle(s, 10.0, INK)
		c.draw_string(font, s + Vector2(12, -10), String(name),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)

	c.draw_string(font, Vector2(16, c.size.y - 16), "手数 %d" % moves,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 24, DIM)


## 同じ点に集まる角は、内側から順に弧を大きくして重ならないようにする
## (角 A のように 3 つ重なる場所があるため)
func _arc_radius(index: int) -> float:
	var at := String(angles[index]["at"])
	var mine := _angle_width(index)
	var rank := 0
	for j in angles.size():
		if j == index or String(angles[j]["at"]) != at:
			continue
		var w := _angle_width(j)
		if w < mine or (absf(w - mine) < 0.001 and j < index):
			rank += 1
	return 38.0 + 20.0 * float(rank)


## その角の広さ(ラジアン)。図の座標から計算する
func _angle_width(index: int) -> float:
	var a: Dictionary = angles[index]
	var at: Vector2 = pts[String(a["at"])]
	var d1: Vector2 = (pts[String(a["from"])] as Vector2) - at
	var d2: Vector2 = (pts[String(a["to"])] as Vector2) - at
	return absf(d1.angle_to(d2))


func _draw_angle(c: Control, font: Font, i: int) -> void:
	var a: Dictionary = angles[i]
	var at: Vector2 = pts[String(a["at"])]
	var p1: Vector2 = pts[String(a["from"])]
	var p2: Vector2 = pts[String(a["to"])]
	var v: float = float(a["value"])
	var known := v >= 0.0
	var is_target := bool(a.get("target", false))
	var r := _arc_radius(i)
	var s := _to_screen(at)
	var d1 := (_to_screen(p1) - s).normalized()
	var d2 := (_to_screen(p2) - s).normalized()
	var a1 := d1.angle()
	var a2 := d2.angle()
	while a2 - a1 > PI:
		a2 -= TAU
	while a1 - a2 > PI:
		a1 -= TAU
	var col := DIM
	if is_target:
		col = GOLD
	if known:
		col = DONE if not is_target else GOLD
	if i == flash:
		col = Color(1.0, 1.0, 0.75).lerp(col, flash_t)
	c.draw_arc(s, r, a1, a2, 24, col, 3.0)
	var mid := s + Vector2(cos((a1 + a2) * 0.5), sin((a1 + a2) * 0.5)) * (r + 18.0)
	var text := "?"
	if known:
		text = "%s°" % ProblemGen.fmt(v)
	elif is_target:
		text = "x"
	c.draw_string(font, mid + Vector2(-14, 8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, col)


# =========================================================
# 進行
# =========================================================

func _show_step() -> void:
	if step < SCRIPT.size():
		speaker.text = String(SCRIPT[step][0])
		talk.text = String(SCRIPT[step][1])
		act_btn.text = "つぎへ ▶"
		return
	cards_row.visible = true
	speaker.text = "遺言 第一条"
	talk.text = "境は頂点 A から杭 D へ張った縄。その角 x を記録せよ。覚え書きにある角は 3 つだけだ。"
	hint.text = "定理カードをえらび、図の当てる場所をタップする"
	act_btn.text = "覚え書きを見る"


func _advance() -> void:
	GameState.play_sfx("tap")
	if step < SCRIPT.size():
		step += 1
		_show_step()
		return
	speaker.text = "覚え書き"
	talk.text = "∠B = 50°、∠C = 60°、A のところで縄が作る手前の角 ∠BAD = 35°。書いてあるのはこれだけ。"


func _show_note() -> void:
	GameState.play_sfx("hint")
	speaker.text = "オルドの手記(一)"
	talk.text = "「角は語る。三度たどれば、あれの在り処が分かる」  ―― 父の字だ。"
	hint.text = "記録した角が、一つ目の手がかりになった。あと二つ。"
	act_btn.text = "その日は終わった ▶"
	act_btn.pressed.connect(_after_note, CONNECT_ONE_SHOT)


func _after_note() -> void:
	speaker.text = "弟 ロウ"
	talk.text = "「言い忘れていたが ―― その杭 D、去年まで無かったぞ」  父は死ぬ前に、杭を一本打っている。"
	hint.text = "第二話へ続く(試作はここまで)"
	act_btn.text = "タイトルへ"
	act_btn.pressed.connect(func() -> void:
		GameState.change_scene("res://scenes/main.tscn"), CONNECT_ONE_SHOT)
