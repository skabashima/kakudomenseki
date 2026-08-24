extends Control
## 【試作】相続ミステリー「遺産の地図」第一話。
##
## 本編・ストーリーとは別のモード。ここでのプレイヤーの仕事は「測って答える」ではなく、
## **遺言の条件どおりに土地を線で分ける**こと。指で線を引くだけで進み、
## 数字を入力する場面は無い。判定は本物の幾何(面積とどちら側か)で行う。
##
## 話のつくり: 遺言の条項 → 相続人の言い分 → 分ける → 判定 → 手記の 1 ページ。
## 引いた境界線は地図に残り、話が進むほど「あれの在り処」に近づいていく。

const GOLD := Color(1.0, 0.85, 0.3)
const SKY := Color(0.55, 0.85, 1.0)
const INK := Color(0.92, 0.95, 1.0)
const DIM := Color(0.62, 0.72, 0.88)
const SIS := Color(0.95, 0.72, 0.30, 0.45)     # 姉の側
const BRO := Color(0.35, 0.60, 0.95, 0.45)     # 弟の側

## 判定のきびしさ(面積の差の割合)
const TOL3 := 0.02
const TOL2 := 0.05
const TOL1 := 0.10

var land: Array = []            # 土地の頂点(図の座標)
var well := Vector2.ZERO        # 井戸の位置
var cut_a := Vector2.ZERO       # 引いた線の 2 点
var cut_b := Vector2.ZERO
var has_cut := false
var settled := false            # 分け終わったか
var split_t := 0.0              # 分かれるアニメ(0→1)
var stars := 0

var map: Control
var talk: Label
var speaker: Label
var status: Label
var act_btn: Button
var redo_btn: Button
var step := 0

## 第一話の台本。話者と台詞
const SCRIPT := [
	["代訟人", "測量家オルドが死んだ。生涯を土地の測量に費やし、遺言を一通だけ残していった。"],
	["代訟人", "第一条 ―― わが土地を、姉と弟に等しく分けよ。ただし井戸は姉に。境は一本の直線とする。"],
	["弟 ロウ", "「井戸が姉のものなら、等しくないだろう。父は姉びいきだったんだ」"],
	["姉 セリカ", "「遺言のとおりに。……ただ、なぜ井戸を指定したのかは、私にも分からない」"],
	["あなた", "測量士として雇われた以上、やることは一つ。条件を満たす線を、一本だけ引く。"],
]


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.13, 0.22)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build_land()

	var ins := GameState.safe_insets()
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_right = -16
	root.offset_top = float(ins["top"]) + 10.0
	root.offset_bottom = -float(ins["bottom"]) - 10.0
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var head := HBoxContainer.new()
	root.add_child(head)
	var back := Button.new()
	back.text = "←もどる"
	back.custom_minimum_size = Vector2(0, 64)
	back.add_theme_font_size_override("font_size", 24)
	GameState.style_button(back, Color(0.28, 0.32, 0.44))
	back.pressed.connect(func() -> void: GameState.change_scene("res://scenes/main.tscn"))
	head.add_child(back)
	var title := Label.new()
	title.text = "  遺産の地図 ・ 第一話「等しく分けよ」"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", GOLD)
	head.add_child(title)

	map = Control.new()
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.custom_minimum_size = Vector2(0, 420)
	map.draw.connect(_draw_map)
	map.gui_input.connect(_on_map_input)
	root.add_child(map)

	speaker = Label.new()
	speaker.add_theme_font_size_override("font_size", 24)
	speaker.add_theme_color_override("font_color", GOLD)
	root.add_child(speaker)

	talk = Label.new()
	talk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	talk.custom_minimum_size = Vector2(0, 92)
	talk.add_theme_font_size_override("font_size", 25)
	talk.add_theme_color_override("font_color", INK)
	root.add_child(talk)

	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 23)
	status.add_theme_color_override("font_color", DIM)
	root.add_child(status)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	root.add_child(row)
	redo_btn = Button.new()
	redo_btn.text = "引き直す"
	redo_btn.custom_minimum_size = Vector2(0, 84)
	redo_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	redo_btn.add_theme_font_size_override("font_size", 26)
	GameState.style_button(redo_btn, Color(0.42, 0.34, 0.28))
	redo_btn.pressed.connect(_redo)
	redo_btn.visible = false
	row.add_child(redo_btn)
	act_btn = Button.new()
	act_btn.custom_minimum_size = Vector2(0, 84)
	act_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	act_btn.size_flags_stretch_ratio = 2.0
	act_btn.add_theme_font_size_override("font_size", 28)
	GameState.style_button(act_btn, Color(0.22, 0.55, 0.35))
	act_btn.pressed.connect(_advance)
	row.add_child(act_btn)

	_show_step()


func _process(delta: float) -> void:
	if settled and split_t < 1.0:
		split_t = minf(split_t + delta * 2.2, 1.0)
		map.queue_redraw()


# =========================================================
# 土地
# =========================================================

## 不整形だが凸な土地を作る(線一本できれいに二つに分かれる形)
func _build_land() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260824
	land = []
	var n := 6
	for i in n:
		var a := TAU * float(i) / float(n) + rng.randf_range(-0.16, 0.16)
		var r := rng.randf_range(7.0, 11.0)
		land.append(Vector2(cos(a) * r, sin(a) * r * 0.95))
	well = Vector2(-3.4, 2.6)


static func _area(poly: Array) -> float:
	var s := 0.0
	var n := poly.size()
	for i in n:
		var p: Vector2 = poly[i]
		var q: Vector2 = poly[(i + 1) % n]
		s += p.x * q.y - q.x * p.y
	return absf(s) * 0.5


static func _side(p: Vector2, a: Vector2, b: Vector2) -> float:
	return (b - a).cross(p - a)


## 直線 ab で多角形を二つに切る [左側, 右側]
static func _split(poly: Array, a: Vector2, b: Vector2) -> Array:
	var left: Array = []
	var right: Array = []
	var n := poly.size()
	for i in n:
		var p: Vector2 = poly[i]
		var q: Vector2 = poly[(i + 1) % n]
		var sp := _side(p, a, b)
		var sq := _side(q, a, b)
		if sp >= 0.0:
			left.append(p)
		if sp <= 0.0:
			right.append(p)
		if (sp > 0.0 and sq < 0.0) or (sp < 0.0 and sq > 0.0):
			var t := sp / (sp - sq)
			left.append(p + (q - p) * t)
			right.append(p + (q - p) * t)
	return [left, right]


## いまの線での [姉の側, 弟の側, 面積差の割合]
func _pieces() -> Array:
	var parts := _split(land, cut_a, cut_b)
	var first: Array = parts[0]
	var second: Array = parts[1]
	# 井戸のある側を姉の側にする
	if _side(well, cut_a, cut_b) < 0.0:
		var tmp := first
		first = second
		second = tmp
	var a1 := _area(first)
	var a2 := _area(second)
	var total := maxf(a1 + a2, 0.0001)
	return [first, second, absf(a1 - a2) / total, a1, a2]


# =========================================================
# 地図を描く
# =========================================================

## 図の座標 → 画面の座標
func _to_screen(p: Vector2) -> Vector2:
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for q in land:
		lo = lo.min(q)
		hi = hi.max(q)
	var pad := 24.0
	var size := map.size
	var span := hi - lo
	var k := minf((size.x - pad * 2.0) / maxf(span.x, 0.001),
		(size.y - pad * 2.0) / maxf(span.y, 0.001))
	var center := (lo + hi) * 0.5
	return size * 0.5 + Vector2((p.x - center.x) * k, -(p.y - center.y) * k)


func _to_world(s: Vector2) -> Vector2:
	var o := _to_screen(Vector2.ZERO)
	var ux := _to_screen(Vector2(1, 0)) - o
	return Vector2((s.x - o.x) / ux.x, -(s.y - o.y) / ux.x)


func _poly_screen(poly: Array, offset := Vector2.ZERO) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(_to_screen(p) + offset)
	return out


func _draw_map() -> void:
	var c := map
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.13, 0.17, 0.27))
	# 方眼(地図らしさ)
	var grid := Color(1, 1, 1, 0.05)
	var stepv := 40.0
	var x := 0.0
	while x < c.size.x:
		c.draw_line(Vector2(x, 0), Vector2(x, c.size.y), grid, 1.0)
		x += stepv
	var y := 0.0
	while y < c.size.y:
		c.draw_line(Vector2(0, y), Vector2(c.size.x, y), grid, 1.0)
		y += stepv

	if has_cut:
		var pr := _pieces()
		var sis: Array = pr[0]
		var bro: Array = pr[1]
		# 二つの重心が離れる向きへ、少しだけずらして見せる
		var dir := (_centroid(sis) - _centroid(bro)).normalized()
		var push := (_to_screen(dir) - _to_screen(Vector2.ZERO)) * split_t * 0.35
		c.draw_colored_polygon(_poly_screen(sis, push), SIS)
		c.draw_colored_polygon(_poly_screen(bro, -push), BRO)
		_outline(c, sis, GOLD, push)
		_outline(c, bro, SKY, -push)
		# 面積の数字
		_area_label(c, sis, "姉  %.1f" % float(pr[3]), GOLD, push)
		_area_label(c, bro, "弟  %.1f" % float(pr[4]), SKY, -push)
	else:
		c.draw_colored_polygon(_poly_screen(land), Color(0.35, 0.55, 0.9, 0.25))
		_outline(c, land, INK, Vector2.ZERO)

	# 引いている線(土地からはみ出して伸ばす)
	if has_cut and not settled:
		var d := (cut_b - cut_a).normalized() * 40.0
		c.draw_line(_to_screen(cut_a - d), _to_screen(cut_b + d), GOLD, 3.0)

	# 井戸
	var w := _to_screen(well)
	c.draw_circle(w, 11.0, Color(0.2, 0.45, 0.8))
	c.draw_arc(w, 11.0, 0.0, TAU, 24, INK, 2.5)
	var font := ThemeDB.fallback_font
	c.draw_string(font, w + Vector2(16, 8), "井戸", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, DIM)

	if not has_cut and step >= SCRIPT.size():
		c.draw_string(font, Vector2(20, c.size.y - 18), "地図を指でなぞって、境の線を引く",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24, GOLD)


static func _centroid(poly: Array) -> Vector2:
	if poly.is_empty():
		return Vector2.ZERO
	var m := Vector2.ZERO
	for p in poly:
		m += p
	return m / float(poly.size())


func _outline(c: Control, poly: Array, col: Color, offset: Vector2) -> void:
	var n := poly.size()
	for i in n:
		c.draw_line(_to_screen(poly[i]) + offset, _to_screen(poly[(i + 1) % n]) + offset, col, 3.0)


func _area_label(c: Control, poly: Array, text: String, col: Color, offset: Vector2) -> void:
	if poly.is_empty():
		return
	var mid := Vector2.ZERO
	for p in poly:
		mid += p
	mid /= float(poly.size())
	c.draw_string(ThemeDB.fallback_font, _to_screen(mid) + offset + Vector2(-40, 0), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, col)


# =========================================================
# 線を引く
# =========================================================

func _on_map_input(event: InputEvent) -> void:
	if settled or step < SCRIPT.size():
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed: bool = event.pressed
		var at: Vector2 = event.position
		if pressed:
			cut_a = _to_world(at)
			cut_b = cut_a + Vector2(0.01, 0)
			has_cut = true
			map.queue_redraw()
		else:
			_update_status()
	elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and has_cut:
		var moving: bool = event is InputEventScreenDrag \
			or (event as InputEventMouseMotion).button_mask != 0
		if moving:
			cut_b = _to_world(event.position)
			if cut_a.distance_to(cut_b) > 0.4:
				map.queue_redraw()
				_update_status()


func _update_status() -> void:
	if not has_cut:
		return
	var pr := _pieces()
	var diff := float(pr[2])
	var ok_well := _area(pr[0]) > 0.001
	status.text = "面積の差 %.1f%%   井戸: %s" % [
		diff * 100.0, "姉の側" if ok_well else "―"]
	act_btn.text = "この線で分ける"
	act_btn.disabled = false
	redo_btn.visible = true


func _redo() -> void:
	has_cut = false
	settled = false
	split_t = 0.0
	status.text = ""
	redo_btn.visible = false
	act_btn.text = "地図に線を引く"
	act_btn.disabled = true
	status.text = "面積の差 2% 以内で ★★★ ／ 5% で ★★ ／ 10% で ★"
	map.queue_redraw()


# =========================================================
# 進行
# =========================================================

func _show_step() -> void:
	if step < SCRIPT.size():
		speaker.text = String(SCRIPT[step][0])
		talk.text = String(SCRIPT[step][1])
		act_btn.text = "つぎへ ▶"
		act_btn.disabled = false
		return
	# 分ける場面
	speaker.text = "遺言 第一条"
	talk.text = "土地を、姉と弟に等しく分けよ。ただし井戸は姉に。境は一本の直線とする。"
	act_btn.text = "地図に線を引く"
	act_btn.disabled = true


func _advance() -> void:
	GameState.play_sfx("tap")
	if step < SCRIPT.size():
		step += 1
		_show_step()
		return
	if not settled:
		_settle()
		return
	GameState.change_scene("res://scenes/main.tscn")


## 引いた線で確定する
func _settle() -> void:
	var pr := _pieces()
	var diff := float(pr[2])
	stars = 0
	if diff <= TOL3:
		stars = 3
	elif diff <= TOL2:
		stars = 2
	elif diff <= TOL1:
		stars = 1
	if stars == 0:
		GameState.play_sfx("fail")
		speaker.text = "弟 ロウ"
		talk.text = "「ずいぶん大ざっぱだな。これでは受け取れない」  ―― 面積の差が %.0f%% では、誰も納得しない。" % (diff * 100.0)
		act_btn.text = "引き直す"
		act_btn.disabled = false
		redo_btn.visible = false
		act_btn.pressed.disconnect(_advance)
		act_btn.pressed.connect(_redo_and_rewire, CONNECT_ONE_SHOT)
		return
	settled = true
	split_t = 0.0
	redo_btn.visible = false
	GameState.play_sfx("clear" if stars == 3 else "correct")
	var mark := "★".repeat(stars) + "☆".repeat(3 - stars)
	speaker.text = "代訟人   %s" % mark
	talk.text = "「境が定まりました」  姉の側 %.1f、弟の側 %.1f。差は %.1f%%。" % [
		float(pr[3]), float(pr[4]), diff * 100.0]
	status.text = "遺言のとおり、井戸は姉の側にある。"
	act_btn.text = "手記を読む ▶"
	act_btn.pressed.disconnect(_advance)
	act_btn.pressed.connect(_show_note, CONNECT_ONE_SHOT)
	map.queue_redraw()


func _redo_and_rewire() -> void:
	_redo()
	act_btn.pressed.connect(_advance)


## 事件の手がかり
func _show_note() -> void:
	GameState.play_sfx("hint")
	speaker.text = "オルドの手記(一)"
	talk.text = "「境界は語る。三度引けば、あれの在り処が分かる」  ―― 父の字だ。"
	status.text = "引いた境界線が、地図に一本残った。あと二本。"
	act_btn.text = "その日は終わった ▶"
	act_btn.pressed.connect(_after_note, CONNECT_ONE_SHOT)


func _after_note() -> void:
	speaker.text = "弟 ロウ"
	talk.text = "「言い忘れていたが ―― あの井戸、去年から水が出ていない」  なぜ父は、涸れた井戸を姉に指定したのか。"
	status.text = "第二話へ続く(試作はここまで)"
	act_btn.text = "タイトルへ"
	act_btn.pressed.connect(func() -> void:
		GameState.change_scene("res://scenes/main.tscn"), CONNECT_ONE_SHOT)
