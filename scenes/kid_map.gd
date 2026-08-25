extends Control
## 「たからのちず」― 小学生の ストーリー(たからさがし)の 地図画面。
##
## 一覧ではなく **1 まいの 地図**。はまべ から 出発して、もり・かわ・どうくつ・
## やま を こえ、いちばん 上の たからばこ を 目ざす。単元 1 つ = 地図の 1 歩。
##
## ゲームらしく するために:
##   ・じぶんの 人(たんけんか)が 地図の 上に 立っている
##   ・単元を クリアして もどると、**つぎの ばしょまで 歩いて いく**
##   ・その先は きり が かかって 見えない。進むと 晴れて 地図が ひろがる
##   ・4 歩ごとに「エリア」の 立て札が 立ち、いま どこまで 来たかが わかる
##
## 地図そのものは 画像を持たず、その場で描いている(ほかの絵と同じ方針)。

const PAPER := Color(0.90, 0.83, 0.66)
const PAPER_DARK := Color(0.82, 0.73, 0.55)
const INK := Color(0.36, 0.24, 0.14)
const SEA := Color(0.55, 0.72, 0.76)
const PATH := Color(0.72, 0.28, 0.22)
const GREEN := Color(0.36, 0.50, 0.28)
const GOLD := Color(0.85, 0.65, 0.20)
const MIST := Color(0.93, 0.90, 0.82, 0.86)

## 地図の エリア(何歩めから / けしき / 立て札の 名前)
const AREAS := [
	{"at": 0, "kind": "はまべ", "name": "はじまりの はまべ"},
	{"at": 4, "kind": "もり", "name": "ささやきの もり"},
	{"at": 8, "kind": "かわ", "name": "わたりの かわ"},
	{"at": 12, "kind": "どうくつ", "name": "くらやみの どうくつ"},
	{"at": 16, "kind": "やま", "name": "かぜの やま"},
	{"at": 20, "kind": "たにま", "name": "さいごの たにま"},
]

const STEP := 190.0            # 1 歩の たて幅
const SWING := 230.0           # 道の くねり(よこ)
const WALK_TIME := 1.4         # つぎの ばしょまで 歩く 時間(びょう)

var canvas: Control
var scroll: ScrollContainer
var done_lbl: Label
var nodes: Array = []          # {"pos": Vector2, "unit": Dictionary, "index": int}
var _t := 0.0
var walk_from := -1            # 歩いている とちゅうなら 出発の 歩数
var walk_t := -1.0             # 0.0 → 1.0。-1 は 歩いていない


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = PAPER
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var ins := GameState.safe_insets()
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_top = float(ins["top"])
	root.offset_bottom = -float(ins["bottom"])
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	root.add_child(_header())

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	DragScroll.attach(scroll)

	canvas = Control.new()
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.custom_minimum_size = Vector2(0, STEP * float(KidDefs.UNITS.size()) + 420.0)
	canvas.draw.connect(_draw_map)
	scroll.add_child(canvas)

	await get_tree().process_frame
	_build_nodes()
	# クリアした ばかりなら、その ばしょから つぎへ 歩いて見せる
	if GameState.kid_walk_from != "":
		walk_from = KidDefs.index_of(GameState.kid_walk_from)
		GameState.kid_walk_from = ""
		if walk_from >= 0 and walk_from < KidDefs.UNITS.size() - 1:
			walk_t = 0.0
		else:
			walk_from = -1
	set_process(true)
	await get_tree().process_frame
	_scroll_to(_hero_pos(), true)


func _process(delta: float) -> void:
	_t += delta
	if walk_t >= 0.0:
		walk_t += delta / WALK_TIME
		if walk_t >= 1.0:
			walk_t = -1.0
			walk_from = -1
			GameState.play_sfx("tap")
		_scroll_to(_hero_pos(), false)
	canvas.queue_redraw()


func _header() -> Control:
	var head := HBoxContainer.new()
	head.custom_minimum_size = Vector2(0, 92)
	var back := Button.new()
	back.text = "もどる"
	back.custom_minimum_size = Vector2(150, 72)
	back.add_theme_font_size_override("font_size", 28)
	GameState.style_button(back, Color(0.42, 0.32, 0.22))
	back.pressed.connect(func() -> void: GameState.change_scene("res://scenes/main.tscn"))
	head.add_child(back)
	var title := Label.new()
	title.text = "  たからのちず"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title)
	done_lbl = Label.new()
	done_lbl.text = "%d / %d" % [_cleared_count(), KidDefs.UNITS.size()]
	done_lbl.add_theme_font_size_override("font_size", 30)
	done_lbl.add_theme_color_override("font_color", INK)
	done_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(done_lbl)
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(16, 0)
	head.add_child(pad)
	return head


func _cleared_count() -> int:
	var n := 0
	for u in KidDefs.UNITS:
		if GameState.kid_clear.has(String(u["id"])):
			n += 1
	return n


## いま いる 歩数(まだ クリアしていない いちばん 手前)
func _current_index() -> int:
	for i in KidDefs.UNITS.size():
		if not GameState.kid_clear.has(String(KidDefs.UNITS[i]["id"])):
			return i
	return KidDefs.UNITS.size() - 1


## 地図の 上での 1 歩の 場所。下(はまべ)から 上(たから)へ 進む
func _node_pos(i: int) -> Vector2:
	var w := maxf(canvas.size.x, 400.0)
	var y := canvas.custom_minimum_size.y - 210.0 - STEP * float(i)
	var x := w * 0.5 + sin(float(i) * 0.85) * minf(SWING, w * 0.30)
	return Vector2(x, y)


## i 歩めと i+1 歩めを つなぐ 道の 上の 点(t = 0.0 → 1.0)
func _path_point(i: int, t: float) -> Vector2:
	var a := _node_pos(i)
	var b := _node_pos(i + 1)
	var mid := (a + b) * 0.5 + Vector2(sin(float(i)) * 26.0, 0)
	return a.lerp(mid, t).lerp(mid.lerp(b, t), t)


## たんけんか が 立っている 場所
func _hero_pos() -> Vector2:
	if walk_t >= 0.0 and walk_from >= 0:
		return _path_point(walk_from, ease(clampf(walk_t, 0.0, 1.0), 0.6))
	if _cleared_count() >= KidDefs.UNITS.size():
		return _node_pos(KidDefs.UNITS.size() - 1) + Vector2(-96, -150)
	return _node_pos(_current_index()) + Vector2(-100, -16)


func _build_nodes() -> void:
	for c in canvas.get_children():
		c.queue_free()
	nodes.clear()
	for i in KidDefs.UNITS.size():
		var u: Dictionary = KidDefs.UNITS[i]
		var uid := String(u["id"])
		var open := KidDefs.is_unlocked(uid, GameState.kid_clear)
		var pos := _node_pos(i)
		nodes.append({"pos": pos, "unit": u, "index": i})
		var btn := Button.new()
		btn.size = Vector2(132, 132)
		btn.position = pos - Vector2(66, 66)
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.disabled = not open
		if open:
			btn.pressed.connect(func() -> void:
				GameState.play_sfx("tap")
				GameState.kid_unit = uid
				GameState.change_scene("res://scenes/kid_unit.tscn"))
		canvas.add_child(btn)


## その 場所が まん中あたりに 来るように 地図を 動かす
func _scroll_to(p: Vector2, jump: bool) -> void:
	var want := int(maxf(p.y - scroll.size.y * 0.6, 0.0))
	if jump:
		scroll.scroll_vertical = want
	else:
		scroll.scroll_vertical = int(lerpf(float(scroll.scroll_vertical), float(want), 0.15))


# =========================================================
# 地図を描く
# =========================================================

func _draw_map() -> void:
	var c := canvas
	var w := c.size.x
	var h := c.custom_minimum_size.y
	c.draw_rect(Rect2(0, 0, w, h), PAPER)
	_draw_sea(c, w, h)
	_draw_land(c, w, h)
	_draw_dots(c)
	_draw_compass(c, w, h)
	_draw_areas(c)
	_draw_path(c)
	_draw_nodes(c)
	_draw_treasure(c)
	_draw_hero(c, _hero_pos())
	_draw_mist(c, w)


## 紙のふち(海)。左右に 波を 少しだけ
func _draw_sea(c: Control, w: float, h: float) -> void:
	var band := 46.0
	c.draw_rect(Rect2(0, 0, band, h), SEA)
	c.draw_rect(Rect2(w - band, 0, band, h), SEA)
	for i in int(h / 60.0):
		var y := 30.0 + 60.0 * float(i)
		for x in [band * 0.5, w - band * 0.5]:
			c.draw_arc(Vector2(x, y), 10.0, PI, TAU, 8, Color(1, 1, 1, 0.35), 2.0)


## 島のかたち(道の まわりに 陸を 置く)
func _draw_land(c: Control, w: float, h: float) -> void:
	var pts := PackedVector2Array()
	var n := KidDefs.UNITS.size()
	for i in range(-1, n + 2):
		var p := _node_pos(clampi(i, 0, n - 1))
		if i < 0:
			p.y = h - 60.0
		elif i > n:
			p.y = 120.0
		pts.append(Vector2(p.x - 250.0 + sin(float(i) * 1.7) * 40.0, p.y))
	for i in range(n + 1, -2, -1):
		var q := _node_pos(clampi(i, 0, n - 1))
		if i < 0:
			q.y = h - 60.0
		elif i > n:
			q.y = 120.0
		pts.append(Vector2(q.x + 250.0 + cos(float(i) * 1.3) * 40.0, q.y))
	c.draw_colored_polygon(pts, PAPER_DARK)
	c.draw_polyline(pts, Color(0.62, 0.52, 0.36), 3.0)


## 進んできた道(点線)。行けるところまでは 濃く、その先は うすく
func _draw_path(c: Control) -> void:
	var reached := _cleared_count()
	for i in KidDefs.UNITS.size() - 1:
		var col := PATH if i < reached else Color(PATH.r, PATH.g, PATH.b, 0.30)
		var prev := _node_pos(i)
		for s in range(1, 13):
			var p := _path_point(i, float(s) / 12.0)
			if s % 2 == 0:
				c.draw_line(prev, p, col, 6.0)
			prev = p


## エリアの けしき と 立て札
func _draw_areas(c: Control) -> void:
	var font := ThemeDB.fallback_font
	var n := KidDefs.UNITS.size()
	for a in AREAS:
		var area: Dictionary = a
		var at := int(area["at"])
		if at >= n:
			continue
		var p := _node_pos(at) + Vector2(0, 120.0)
		match String(area["kind"]):
			"もり":
				for k in 4:
					_tree(c, p + Vector2(-210.0 + 140.0 * float(k), -16.0 * float(k % 2)))
			"かわ":
				_river(c, p)
			"どうくつ":
				_cave(c, p + Vector2(190, 0))
				_tree(c, p + Vector2(-190, 0))
			"やま":
				for k in 2:
					_mountain(c, Vector2(p.x - 130.0 + 260.0 * float(k), p.y + 10.0))
			"たにま":
				_valley(c, p)
			_:
				_beach(c, p)
		# 立て札は 道の 反対がわに 立てて、単元の 名前と かさならないように
		# 立て札は 道が つぎに 行く 方の 反対がわに 立てる(印と かさならない)。
		# ただし 紙から はみ出るなら 反対がわへ まわす
		var here := _node_pos(at)
		var side := -1.0 if _node_pos(mini(at + 1, n - 1)).x >= here.x else 1.0
		var bw := font.get_string_size(String(area["name"]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 34.0
		var sx := here.x + side * 250.0
		if sx - bw * 0.5 < 70.0 or sx + bw * 0.5 > canvas.size.x - 70.0:
			sx = here.x - side * 250.0
		_signpost(c, font, Vector2(sx, here.y - 60.0), area, at)


func _tree(c: Control, at: Vector2) -> void:
	c.draw_line(at, at + Vector2(0, -30), Color(0.45, 0.33, 0.20), 6.0)
	c.draw_circle(at + Vector2(0, -46), 26.0, GREEN)
	c.draw_circle(at + Vector2(-16, -30), 18.0, GREEN.lightened(0.12))
	c.draw_circle(at + Vector2(16, -32), 17.0, GREEN.darkened(0.10))


func _mountain(c: Control, at: Vector2) -> void:
	c.draw_colored_polygon(PackedVector2Array([
		at + Vector2(-100, 0), at + Vector2(0, -120), at + Vector2(100, 0)]),
		Color(0.55, 0.47, 0.36))
	c.draw_colored_polygon(PackedVector2Array([
		at + Vector2(-34, -80), at + Vector2(0, -120), at + Vector2(34, -80)]),
		Color(0.95, 0.94, 0.90))


func _river(c: Control, p: Vector2) -> void:
	var pts := PackedVector2Array()
	for k in 9:
		var t := float(k) / 8.0
		pts.append(Vector2(p.x - 280.0 + 560.0 * t, p.y + sin(t * 5.0) * 22.0))
	c.draw_polyline(pts, SEA, 20.0)
	c.draw_polyline(pts, Color(1, 1, 1, 0.30), 6.0)
	# 丸太の はし
	c.draw_line(Vector2(p.x - 40, p.y - 26), Vector2(p.x + 60, p.y + 20),
		Color(0.55, 0.40, 0.24), 9.0)


func _cave(c: Control, p: Vector2) -> void:
	c.draw_colored_polygon(PackedVector2Array([
		p + Vector2(-110, 20), p + Vector2(-60, -70), p + Vector2(60, -80),
		p + Vector2(110, 20)]), Color(0.58, 0.50, 0.40))
	c.draw_arc(p + Vector2(0, 20), 46.0, PI, TAU, 20, Color(0.22, 0.17, 0.12), 8.0)
	c.draw_circle(p + Vector2(0, 26), 40.0, Color(0.22, 0.17, 0.12))


func _valley(c: Control, p: Vector2) -> void:
	for s in [-1.0, 1.0]:
		c.draw_colored_polygon(PackedVector2Array([
			p + Vector2(240.0 * s, -60), p + Vector2(70.0 * s, 30),
			p + Vector2(250.0 * s, 40)]), Color(0.60, 0.52, 0.40))
	# つり橋
	var pts := PackedVector2Array()
	for k in 9:
		var t := float(k) / 8.0
		pts.append(Vector2(p.x - 90.0 + 180.0 * t, p.y - 10.0 + sin(t * PI) * 26.0))
	c.draw_polyline(pts, Color(0.50, 0.36, 0.22), 5.0)


func _beach(c: Control, p: Vector2) -> void:
	c.draw_arc(p + Vector2(0, 30), 150.0, PI, TAU, 24, Color(0.86, 0.80, 0.62), 12.0)
	# 小舟
	c.draw_colored_polygon(PackedVector2Array([
		p + Vector2(-190, 10), p + Vector2(-100, 10), p + Vector2(-120, 34),
		p + Vector2(-170, 34)]), Color(0.55, 0.40, 0.24))
	c.draw_line(p + Vector2(-145, 10), p + Vector2(-145, -40), INK, 4.0)


## エリアの 立て札(名前と、そこの 進みぐあい)
func _signpost(c: Control, font: Font, at: Vector2, area: Dictionary, at_i: int) -> void:
	var name := String(area["name"])
	var n := KidDefs.UNITS.size()
	var last := mini(at_i + 4, n)
	var done := 0
	for i in range(at_i, last):
		if GameState.kid_clear.has(String(KidDefs.UNITS[i]["id"])):
			done += 1
	var w := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 34.0
	at -= Vector2(w * 0.5, 0)   # まん中ぞろえ
	var board := Rect2(at.x, at.y, w, 62)
	c.draw_line(Vector2(at.x + w * 0.5, at.y + 58), Vector2(at.x + w * 0.5, at.y + 108),
		Color(0.50, 0.36, 0.22), 8.0)
	c.draw_rect(board, Color(0.78, 0.62, 0.40))
	c.draw_rect(board, INK, false, 3.0)
	c.draw_string(font, at + Vector2(17, 28), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)
	c.draw_string(font, at + Vector2(17, 52), "%d / %d" % [done, last - at_i],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 20, PATH if done < last - at_i else GREEN)


## 1 歩ごとの 印。クリア = 旗、いま = 光る、まだ = うすい
func _draw_nodes(c: Control) -> void:
	var font := ThemeDB.fallback_font
	var current := _current_index()
	for e in nodes:
		var i: int = e["index"]
		var p: Vector2 = e["pos"]
		var uid := String((e["unit"] as Dictionary)["id"])
		var cleared := GameState.kid_clear.has(uid)
		var open := KidDefs.is_unlocked(uid, GameState.kid_clear)
		if i == current and walk_t < 0.0:
			var pulse := 1.0 + sin(_t * 3.0) * 0.08
			c.draw_circle(p, 58.0 * pulse, Color(0.95, 0.78, 0.25, 0.35))
		c.draw_circle(p, 44.0, Color(0.98, 0.94, 0.84) if open else Color(0.78, 0.72, 0.60))
		c.draw_arc(p, 44.0, 0.0, TAU, 28, INK if open else Color(0.60, 0.54, 0.44), 4.0)
		if cleared:
			# 旗を立てる
			c.draw_line(p + Vector2(0, -6), p + Vector2(0, -54), INK, 5.0)
			c.draw_colored_polygon(PackedVector2Array([
				p + Vector2(2, -54), p + Vector2(48, -42), p + Vector2(2, -30)]), PATH)
		c.draw_string(font, p + Vector2(-14, 12), str(i + 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 34, INK if open else Color(0.55, 0.50, 0.42))
		# 名前は 開いているところだけ(小学生が読むので ふりがな つき)
		if open:
			_draw_ruby(c, font, p + Vector2(0, 82), String((e["unit"] as Dictionary)["title"]))


## たんけんか(じぶん)。ぼうしを かぶって、せなかに ふくろ
func _draw_hero(c: Control, p: Vector2) -> void:
	var bob := sin(_t * (7.0 if walk_t >= 0.0 else 3.0)) * 4.0
	var at := p + Vector2(0, bob - 24.0)
	c.draw_circle(at + Vector2(0, 44), 20.0, Color(0, 0, 0, 0.12))     # かげ
	c.draw_line(at + Vector2(-9, 20), at + Vector2(-9, 40), INK, 6.0)  # あし
	c.draw_line(at + Vector2(9, 20), at + Vector2(9, 40), INK, 6.0)
	c.draw_colored_polygon(PackedVector2Array([                        # ふくろ
		at + Vector2(14, -4), at + Vector2(30, 2), at + Vector2(26, 22),
		at + Vector2(12, 20)]), Color(0.55, 0.40, 0.24))
	c.draw_colored_polygon(PackedVector2Array([                        # からだ
		at + Vector2(-16, 22), at + Vector2(-12, -8), at + Vector2(12, -8),
		at + Vector2(16, 22)]), Color(0.30, 0.46, 0.62))
	c.draw_circle(at + Vector2(0, -22), 16.0, Color(0.98, 0.86, 0.72)) # かお
	c.draw_circle(at + Vector2(-5, -24), 2.5, INK)
	c.draw_circle(at + Vector2(5, -24), 2.5, INK)
	c.draw_colored_polygon(PackedVector2Array([                        # ぼうし
		at + Vector2(-24, -30), at + Vector2(24, -30), at + Vector2(14, -34),
		at + Vector2(10, -46), at + Vector2(-10, -46), at + Vector2(-14, -34)]),
		Color(0.62, 0.44, 0.24))


## いちばん奥の たからばこ
func _draw_treasure(c: Control) -> void:
	var all_done := _cleared_count() >= KidDefs.UNITS.size()
	var p := _node_pos(KidDefs.UNITS.size() - 1) + Vector2(0, -170.0)
	var font := ThemeDB.fallback_font
	# ×じるし
	c.draw_line(p + Vector2(-46, -46), p + Vector2(46, 46), PATH, 9.0)
	c.draw_line(p + Vector2(46, -46), p + Vector2(-46, 46), PATH, 9.0)
	var box := Rect2(p.x - 62, p.y + 40, 124, 84)
	if all_done:
		# ふたが 開いて 光が あふれる
		for k in 7:
			var a := -PI * 0.9 + PI * 0.8 * float(k) / 6.0
			c.draw_line(p + Vector2(0, 60), p + Vector2(0, 60) + Vector2(cos(a), sin(a)) * 120.0,
				Color(GOLD.r, GOLD.g, GOLD.b, 0.35 + 0.25 * sin(_t * 3.0 + float(k))), 6.0)
		c.draw_rect(Rect2(box.position.x, box.position.y + 26, box.size.x, box.size.y - 26),
			Color(0.52, 0.36, 0.20))
		c.draw_colored_polygon(PackedVector2Array([
			box.position + Vector2(0, 26), box.position + Vector2(-14, -18),
			box.position + Vector2(box.size.x + 14, -18),
			box.position + Vector2(box.size.x, 26)]), Color(0.44, 0.30, 0.16))
		for k in 5:
			c.draw_circle(box.position + Vector2(24.0 + 20.0 * float(k), 34.0), 11.0, GOLD)
		c.draw_string(font, p + Vector2(-160, -78), "たからを 見つけた！",
			HORIZONTAL_ALIGNMENT_CENTER, 320, 32, PATH)
	else:
		c.draw_rect(box, Color(0.52, 0.36, 0.20))
		c.draw_rect(box, INK, false, 4.0)
		c.draw_line(Vector2(box.position.x, box.position.y + 30),
			Vector2(box.position.x + box.size.x, box.position.y + 30), INK, 4.0)
		c.draw_circle(Vector2(box.position.x + box.size.x * 0.5, box.position.y + 30), 9.0, GOLD)
		c.draw_string(font, p + Vector2(-160, -78), "あと %d こ" % [
			KidDefs.UNITS.size() - _cleared_count()],
			HORIZONTAL_ALIGNMENT_CENTER, 320, 30, INK)


## この先は まだ きり の 中。進むと 晴れて 地図が 見えてくる
func _draw_mist(c: Control, w: float) -> void:
	var i := _current_index() + 3
	if i >= KidDefs.UNITS.size():
		return
	var y := _node_pos(i).y
	c.draw_rect(Rect2(0, 0, w, y), MIST)
	for k in int(w / 70.0) + 1:
		c.draw_circle(Vector2(35.0 + 70.0 * float(k), y), 44.0, MIST)
	c.draw_string(ThemeDB.fallback_font, Vector2(0, y - 46), "この さきは きりの 中",
		HORIZONTAL_ALIGNMENT_CENTER, w, 26, Color(INK.r, INK.g, INK.b, 0.55))


## 地図の すきまの かざり(石・くさ)。同じ場所に いつも 同じものが 出る
func _draw_dots(c: Control) -> void:
	for i in KidDefs.UNITS.size():
		var p := _node_pos(i)
		var s := 1.0 if i % 2 == 0 else -1.0
		var q := p + Vector2(s * (172.0 + 34.0 * sin(float(i) * 2.1)),
			-56.0 + 52.0 * cos(float(i) * 1.3))
		match i % 3:
			0:
				c.draw_circle(q, 15.0, Color(0.66, 0.60, 0.50))
				c.draw_circle(q + Vector2(14, 6), 10.0, Color(0.72, 0.66, 0.55))
			1:
				c.draw_circle(q, 13.0, GREEN.lightened(0.18))
				c.draw_circle(q + Vector2(-13, 5), 10.0, GREEN.lightened(0.30))
			_:
				for k in 3:
					c.draw_line(q + Vector2(-12.0 + 12.0 * float(k), 8),
						q + Vector2(-16.0 + 12.0 * float(k), -12), GREEN, 3.0)


## 方位じるし
func _draw_compass(c: Control, w: float, _h: float) -> void:
	var at := Vector2(w * 0.5 - 200.0, 112.0)
	c.draw_circle(at, 40.0, Color(0.86, 0.79, 0.62))
	c.draw_arc(at, 40.0, 0.0, TAU, 28, INK, 3.0)
	c.draw_colored_polygon(PackedVector2Array([
		at + Vector2(0, -34), at + Vector2(10, 0), at + Vector2(-10, 0)]), PATH)
	c.draw_colored_polygon(PackedVector2Array([
		at + Vector2(0, 34), at + Vector2(10, 0), at + Vector2(-10, 0)]),
		Color(0.72, 0.66, 0.55))
	c.draw_string(ThemeDB.fallback_font, at + Vector2(-30, -46), "きた",
		HORIZONTAL_ALIGNMENT_CENTER, 60, 16, INK)


## 漢字の上に よみ を のせて、まん中ぞろえで 描く(地図の上は Label が使えないため)
func _draw_ruby(c: Control, font: Font, center: Vector2, text: String) -> void:
	var parts: Array = Ruby.parts(text)
	var total := 0.0
	for seg in parts:
		total += font.get_string_size(String((seg as Dictionary)["s"]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var x := center.x - total * 0.5
	for seg in parts:
		var d: Dictionary = seg
		var body := String(d["s"])
		var bw := font.get_string_size(body, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		c.draw_string(font, Vector2(x, center.y), body, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)
		if String(d["r"]) != "":
			var rw := font.get_string_size(String(d["r"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			c.draw_string(font, Vector2(x + (bw - rw) * 0.5, center.y - 24.0), String(d["r"]),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, INK)
		x += bw
