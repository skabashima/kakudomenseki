extends Control
## ストーリー(中学生・高校生)の 章えらび ― 一覧ではなく **1 枚の図**。
##
## 小学生の「たからのちず」と同じ遊び心地(1 章 = 1 歩、進むと道がのび、
## その先は見えない)を、学年に合わせて絵柄だけ変えたもの。
##
##   中学生「はかる旅」    … 測量野帳の街道図。三角点をたどって国を測っていく
##   高校生「軌道計算室」  … 星図。基地から探査機を飛ばして、遠い星へ近づく
##
## 絵は画像を持たず、その場で描いている(ほかの画面と同じ方針)。

const STEP := 190.0            # 1 歩の たて幅
const SWING := 230.0           # 道の くねり(よこ)
const WALK_TIME := 1.4

## 学年ごとの 色と 名前。ここだけ差し替えれば 絵柄が 変わる
const THEME := {
	"jhs": {
		"bg": Color(0.09, 0.14, 0.20), "land": Color(0.13, 0.20, 0.27),
		"ink": Color(0.80, 0.89, 0.97), "path": Color(0.55, 0.85, 1.00),
		"done": Color(0.45, 0.85, 0.65), "accent": Color(1.00, 0.85, 0.45),
		"edge": Color(0.16, 0.26, 0.34), "mist": Color(0.09, 0.14, 0.20, 0.90),
		"title": "はかる旅", "unit": "章",
		"veil": "この先はまだ測っていない",
	},
	"hs": {
		"bg": Color(0.04, 0.05, 0.11), "land": Color(0.07, 0.08, 0.16),
		"ink": Color(0.82, 0.86, 1.00), "path": Color(0.62, 0.70, 1.00),
		"done": Color(0.55, 0.90, 0.80), "accent": Color(1.00, 0.82, 0.42),
		"edge": Color(0.13, 0.15, 0.28), "mist": Color(0.04, 0.05, 0.11, 0.90),
		"title": "軌道計算室", "unit": "章",
		"veil": "この先はまだ観測できていない",
	},
}

var mode := "jhs"
var th: Dictionary = {}
var chapters: Array = []
var canvas: Control
var scroll: ScrollContainer
var nodes: Array = []
var _t := 0.0
var _draw_t := 0.0
var walk_from := -1
var walk_t := -1.0


func _ready() -> void:
	GameState.play_bgm("map")
	mode = GameState.story_mode
	if not THEME.has(mode):
		mode = "jhs"
	th = THEME[mode]
	chapters = StoryDefs.chapters_of(mode)

	var bg := ColorRect.new()
	bg.color = th["bg"]
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
	canvas.custom_minimum_size = Vector2(0, STEP * float(chapters.size()) + 420.0)
	canvas.draw.connect(_draw_map)
	scroll.add_child(canvas)

	await get_tree().process_frame
	_build_nodes()
	if GameState.story_walk_from != "":
		walk_from = StoryDefs.chapter_index_in(chapters, GameState.story_walk_from)
		GameState.story_walk_from = ""
		if walk_from >= 0 and walk_from < chapters.size() - 1:
			walk_t = 0.0
		else:
			walk_from = -1
	set_process(true)
	await get_tree().process_frame
	_scroll_to(_mark_pos(), true)


func _process(delta: float) -> void:
	_t += delta
	if walk_t >= 0.0:
		walk_t += delta / WALK_TIME
		if walk_t >= 1.0:
			walk_t = -1.0
			walk_from = -1
			GameState.play_sfx("tap")
		_scroll_to(_mark_pos(), false)
	# 光っている ところの 点滅は 20 回/秒 で 足りる。
	# 地図ぜんぶを 毎フレーム 描き直すと 電池を 食う
	_draw_t += delta
	if _draw_t >= 0.05:
		_draw_t = 0.0
		canvas.queue_redraw()


func _header() -> Control:
	var head := HBoxContainer.new()
	head.custom_minimum_size = Vector2(0, 92)
	var back := Button.new()
	back.text = "← もどる"
	back.custom_minimum_size = Vector2(170, 68)
	back.add_theme_font_size_override("font_size", 24)
	GameState.style_button(back, Color(0.28, 0.32, 0.44))
	back.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		GameState.change_scene("res://scenes/main.tscn"))
	head.add_child(back)
	var title := Label.new()
	title.text = "  " + String(th["title"])
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", th["accent"])
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title)
	var done := Label.new()
	done.text = "%d / %d %s" % [_cleared_count(), chapters.size(), String(th["unit"])]
	done.add_theme_font_size_override("font_size", 26)
	done.add_theme_color_override("font_color", th["ink"])
	done.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(done)
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(16, 0)
	head.add_child(pad)
	return head


func _cleared_count() -> int:
	var n := 0
	for ch in chapters:
		if GameState.story_clear.has(String(ch["id"])):
			n += 1
	return n


func _current_index() -> int:
	for i in chapters.size():
		if not GameState.story_clear.has(String(chapters[i]["id"])):
			return i
	return chapters.size() - 1


func _unlocked(i: int) -> bool:
	return StoryDefs.is_unlocked_in(chapters, String(chapters[i]["id"]),
		GameState.story_clear) or GameState.debug_unlock_all


## 図の上での 1 歩の場所。下(出発)から 上(目あて)へ
func _node_pos(i: int) -> Vector2:
	var w := maxf(canvas.size.x, 400.0)
	var y := canvas.custom_minimum_size.y - 210.0 - STEP * float(i)
	var x := w * 0.5 + sin(float(i) * 0.85) * minf(SWING, w * 0.30)
	return Vector2(x, y)


func _path_point(i: int, t: float) -> Vector2:
	var a := _node_pos(i)
	var b := _node_pos(i + 1)
	var mid := (a + b) * 0.5 + Vector2(sin(float(i)) * 26.0, 0)
	return a.lerp(mid, t).lerp(mid.lerp(b, t), t)


## いまいる印(中学生は 測量士、高校生は 探査機)の場所
func _mark_pos() -> Vector2:
	if walk_t >= 0.0 and walk_from >= 0:
		return _path_point(walk_from, ease(clampf(walk_t, 0.0, 1.0), 0.6))
	if _cleared_count() >= chapters.size():
		return _node_pos(chapters.size() - 1) + Vector2(-96, -150)
	return _node_pos(_current_index()) + Vector2(-126, -18)


func _build_nodes() -> void:
	for c in canvas.get_children():
		c.queue_free()
	nodes.clear()
	for i in chapters.size():
		var ch: Dictionary = chapters[i]
		var id := String(ch["id"])
		var open := _unlocked(i)
		var pos := _node_pos(i)
		nodes.append({"pos": pos, "ch": ch, "index": i})
		var paid := GameState.story_chapter_needs_purchase(mode, id)
		var btn := Button.new()
		btn.size = Vector2(132, 132)
		btn.position = pos - Vector2(66, 66)
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.disabled = not open and not paid
		if paid:
			btn.disabled = false
			btn.pressed.connect(func() -> void:
				GameState.play_sfx("tap")
				GameState.change_scene("res://scenes/store.tscn"))
		elif open:
			btn.pressed.connect(func() -> void:
				GameState.play_sfx("tap")
				GameState.story_chapter = id
				GameState.story_scene = 0
				GameState.change_scene("res://scenes/story.tscn"))
		canvas.add_child(btn)


func _scroll_to(p: Vector2, jump: bool) -> void:
	var want := int(maxf(p.y - scroll.size.y * 0.6, 0.0))
	if jump:
		scroll.scroll_vertical = want
	else:
		scroll.scroll_vertical = int(lerpf(float(scroll.scroll_vertical), float(want), 0.15))


# =========================================================
# 図を描く
# =========================================================

func _draw_map() -> void:
	var c := canvas
	var w := c.size.x
	var h := c.custom_minimum_size.y
	c.draw_rect(Rect2(0, 0, w, h), th["bg"])
	if mode == "hs":
		_draw_stars(c, w, h)
	else:
		_draw_grid(c, w, h)
	if mode == "hs":
		_draw_lane(c)
	else:
		_draw_ground(c, w, h)
	_draw_scenery(c)
	_draw_path(c)
	_draw_levels(c)
	_draw_nodes(c)
	_draw_goal(c)
	_draw_mark(c, _mark_pos())
	_draw_veil(c, w)


## 高校生: 星空
func _draw_stars(c: Control, w: float, h: float) -> void:
	for i in int(h / 26.0):
		var y := 13.0 + 26.0 * float(i)
		var x := fposmod(sin(float(i) * 12.9898) * 43758.5453, w)
		var r := 1.2 + fposmod(float(i) * 0.37, 1.0) * 1.8
		c.draw_circle(Vector2(x, y), r, Color(1, 1, 1, 0.25 + 0.35 * fposmod(float(i) * 0.21, 1.0)))


## 中学生: 野帳の方眼
func _draw_grid(c: Control, w: float, h: float) -> void:
	var s := 56.0
	var col := Color(th["edge"].r, th["edge"].g, th["edge"].b, 0.7)
	for i in int(w / s) + 1:
		c.draw_line(Vector2(s * float(i), 0), Vector2(s * float(i), h), col, 1.0)
	for j in int(h / s) + 1:
		c.draw_line(Vector2(0, s * float(j)), Vector2(w, s * float(j)), col, 1.0)


## 進む帯(中学生は測る土地、高校生は航路の帯)
func _draw_ground(c: Control, w: float, h: float) -> void:
	var pts := PackedVector2Array()
	var n := chapters.size()
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
	c.draw_colored_polygon(pts, th["land"])
	c.draw_polyline(pts, th["edge"], 3.0)


## 高校生: 航路の すじ(道にそった うすい 帯)
func _draw_lane(c: Control) -> void:
	# 丸を つないで 帯に する(太い 線を つなぐと ふちが ぎざぎざに なるため)
	var col := Color(th["land"].r, th["land"].g, th["land"].b, 0.95)
	for i in chapters.size() - 1:
		for s in 13:
			c.draw_circle(_path_point(i, float(s) / 12.0), 78.0, col)
	c.draw_circle(_node_pos(chapters.size() - 1), 78.0, col)
	c.draw_circle(_node_pos(chapters.size() - 1) + Vector2(0, -170.0), 96.0, col)


## 道(中学生は測線、高校生は軌道)。進んだところは濃く
func _draw_path(c: Control) -> void:
	var reached := _cleared_count()
	for i in chapters.size() - 1:
		var col: Color = th["path"] if i < reached else Color(
			th["path"].r, th["path"].g, th["path"].b, 0.28)
		var prev := _node_pos(i)
		for s in range(1, 13):
			var p := _path_point(i, float(s) / 12.0)
			if mode == "hs":
				# 軌道は 破線
				if s % 2 == 0:
					c.draw_line(prev, p, col, 5.0)
			else:
				c.draw_line(prev, p, col, 4.0)
				# 測線の 目もり
				if s % 4 == 0:
					var d := (p - prev).normalized().orthogonal() * 9.0
					c.draw_line(p - d, p + d, col, 2.5)
			prev = p


## 道ぞいの けしき。中学生は 町・橋・塔、高校生は 衛星・小惑星帯・彗星
func _draw_scenery(c: Control) -> void:
	var n := chapters.size()
	for k in range(0, n, 4):
		var p := _node_pos(k) + Vector2(0, 118.0)
		# けしきは 道の 反対がわ、少し 外に(章の 名前と かさならないように)
		var side := -1.0 if _node_pos(mini(k + 1, n - 1)).x >= _node_pos(k).x else 1.0
		var at := Vector2(clampf(p.x + side * 268.0, 100.0, canvas.size.x - 100.0), p.y)
		if mode == "hs":
			match (k / 4) % 3:
				0:
					_moon(c, at)
				1:
					_belt(c, p)
				_:
					_comet(c, at)
		else:
			match (k / 4) % 3:
				0:
					_town(c, at)
				1:
					_bridge(c, p)
				_:
					_tower(c, at)


func _town(c: Control, at: Vector2) -> void:
	for i in 3:
		var w := 34.0 + 8.0 * float(i % 2)
		var h := 40.0 + 18.0 * float((i + 1) % 2)
		var x := at.x - 60.0 + 52.0 * float(i)
		c.draw_rect(Rect2(x, at.y - h, w, h), th["edge"])
		c.draw_rect(Rect2(x, at.y - h, w, h), th["ink"], false, 2.0)
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(x - 6, at.y - h), Vector2(x + w * 0.5, at.y - h - 22),
			Vector2(x + w + 6, at.y - h)]), th["ink"] * Color(1, 1, 1, 0.75))


func _bridge(c: Control, p: Vector2) -> void:
	c.draw_line(p + Vector2(-250, 6), p + Vector2(250, -6), th["edge"], 14.0)
	var pts := PackedVector2Array()
	for k in 9:
		var t := float(k) / 8.0
		pts.append(Vector2(p.x - 110.0 + 220.0 * t, p.y - 6.0 - sin(t * PI) * 30.0))
	c.draw_polyline(pts, th["ink"], 3.0)
	for k in 5:
		var t := float(k) / 4.0
		var top := Vector2(p.x - 110.0 + 220.0 * t, p.y - 6.0 - sin(t * PI) * 30.0)
		c.draw_line(top, Vector2(top.x, p.y + 2.0), th["ink"] * Color(1, 1, 1, 0.6), 2.0)


func _tower(c: Control, at: Vector2) -> void:
	c.draw_colored_polygon(PackedVector2Array([
		at + Vector2(-22, 0), at + Vector2(-14, -78), at + Vector2(14, -78),
		at + Vector2(22, 0)]), th["edge"])
	c.draw_polyline(PackedVector2Array([
		at + Vector2(-22, 0), at + Vector2(-14, -78), at + Vector2(14, -78),
		at + Vector2(22, 0)]), th["ink"], 2.0)
	c.draw_colored_polygon(PackedVector2Array([
		at + Vector2(-20, -78), at + Vector2(0, -112), at + Vector2(20, -78)]),
		th["accent"] * Color(1, 1, 1, 0.8))


func _moon(c: Control, at: Vector2) -> void:
	c.draw_circle(at + Vector2(0, -40), 32.0, th["edge"])
	c.draw_arc(at + Vector2(0, -40), 32.0, 0.0, TAU, 28, th["ink"], 2.0)
	for k in 3:
		c.draw_circle(at + Vector2(-12.0 + 12.0 * float(k), -46.0 + 9.0 * float(k % 2)),
			5.0, th["ink"] * Color(1, 1, 1, 0.35))


func _belt(c: Control, p: Vector2) -> void:
	for k in 16:
		var t := float(k) / 15.0
		var q := Vector2(p.x - 250.0 + 500.0 * t, p.y - 10.0 + sin(t * 6.0) * 16.0)
		c.draw_circle(q, 3.0 + fposmod(float(k) * 0.7, 1.0) * 4.0,
			th["ink"] * Color(1, 1, 1, 0.5))


func _comet(c: Control, at: Vector2) -> void:
	c.draw_circle(at + Vector2(0, -36), 11.0, th["accent"])
	for k in 7:
		c.draw_circle(at + Vector2(14.0 + 13.0 * float(k), -36.0 + 5.0 * float(k)),
			7.0 - float(k) * 0.8, Color(th["accent"].r, th["accent"].g, th["accent"].b,
			0.5 - 0.06 * float(k)))


## レベル(小学校の復習 / 高校受験 …)の 立て札
func _draw_levels(c: Control) -> void:
	var font := ThemeDB.fallback_font
	var last := ""
	for i in chapters.size():
		var lv := String(chapters[i]["level"])
		if lv == last:
			continue
		last = lv
		var here := _node_pos(i)
		var name := StoryDefs.level_label(lv)
		var w := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + 32.0
		var side := -1.0 if _node_pos(mini(i + 1, chapters.size() - 1)).x >= here.x else 1.0
		var x := here.x + side * 250.0
		if x - w * 0.5 < 70.0 or x + w * 0.5 > canvas.size.x - 70.0:
			x = here.x - side * 250.0
		var board := Rect2(x - w * 0.5, here.y - 62.0, w, 52)
		c.draw_rect(board, th["land"])
		c.draw_rect(board, th["accent"], false, 2.0)
		c.draw_string(font, Vector2(board.position.x + 16, board.position.y + 34), name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, th["accent"])


## 1 章ごとの 印。中学生は 三角点、高校生は 星
func _draw_nodes(c: Control) -> void:
	var font := ThemeDB.fallback_font
	var current := _current_index()
	for e in nodes:
		var i: int = e["index"]
		var p: Vector2 = e["pos"]
		var ch: Dictionary = e["ch"]
		var cleared := GameState.story_clear.has(String(ch["id"]))
		var open := _unlocked(i)
		if i == current and walk_t < 0.0:
			var pulse := 1.0 + sin(_t * 3.0) * 0.08
			c.draw_circle(p, 58.0 * pulse, Color(th["accent"].r, th["accent"].g,
				th["accent"].b, 0.28))
		var face: Color = th["land"] if open else Color(th["land"], 0.75)
		var edge: Color = th["ink"] if open else Color(th["ink"].r, th["ink"].g,
			th["ink"].b, 0.45)
		if cleared:
			edge = th["done"]
		if mode == "hs":
			c.draw_circle(p, 42.0, face)
			c.draw_arc(p, 42.0, 0.0, TAU, 30, edge, 3.5)
			# 惑星の 輪
			c.draw_arc(p, 56.0, deg_to_rad(190.0), deg_to_rad(350.0), 20,
				Color(edge.r, edge.g, edge.b, 0.6), 2.5)
		else:
			# 三角点
			var tri := PackedVector2Array([p + Vector2(0, -46), p + Vector2(42, 30),
				p + Vector2(-42, 30)])
			c.draw_colored_polygon(tri, face)
			var closed := PackedVector2Array(tri)
			closed.append(tri[0])
			c.draw_polyline(closed, edge, 3.5)
		c.draw_string(font, p + Vector2(-16, 14 if mode == "hs" else 22), str(i + 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 30, edge)
		if GameState.story_chapter_needs_purchase(mode, String(ch["id"])):
			# かぎ(ここから先は 買い切りで 開く)
			var k := p + Vector2(0, -34)
			c.draw_arc(k + Vector2(0, -12), 9.0, PI, TAU, 16, th["accent"], 4.0)
			c.draw_rect(Rect2(k + Vector2(-12, -5), Vector2(24, 19)), th["accent"])
		if cleared:
			c.draw_string(font, p + Vector2(24, -26), "✓",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 30, th["done"])
		if i == current:
			c.draw_string(font, p + Vector2(60, 6), "ここ",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 26, th["accent"])
		# 章の名前は 開いているところだけ
		if open:
			var name := String(ch["title"])
			c.draw_string(font, p + Vector2(-160, 84), name,
				HORIZONTAL_ALIGNMENT_CENTER, 320, 23, th["ink"])
			if cleared:
				# 見つけたことは 長いので、はみ出さないように 折りかえす
				var lines := _wrap(font, String(ch["found"]), 330.0, 17)
				for k in lines.size():
					c.draw_string(font, p + Vector2(-165, 110.0 + 22.0 * float(k)),
						String(lines[k]), HORIZONTAL_ALIGNMENT_CENTER, 330, 17,
						Color(th["done"].r, th["done"].g, th["done"].b, 0.85))


## 幅に あわせて 文を 2 行までに 折る(draw_string は 折り返さないため)
func _wrap(font: Font, text: String, width: float, size: int) -> Array:
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= width:
		return [text]
	var cut := text.length()
	while cut > 1 and font.get_string_size(text.substr(0, cut),
			HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
		cut -= 1
	var rest := text.substr(cut)
	if font.get_string_size(rest, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
		var cut2 := rest.length()
		while cut2 > 1 and font.get_string_size(rest.substr(0, cut2 - 1) + "…",
				HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			cut2 -= 1
		rest = rest.substr(0, cut2 - 1) + "…"
	return [text.substr(0, cut), rest]


## いま いる 印(中学生は 測量士、高校生は 探査機)
func _draw_mark(c: Control, p: Vector2) -> void:
	var bob := sin(_t * (7.0 if walk_t >= 0.0 else 3.0)) * 4.0
	var at := p + Vector2(0, bob - 24.0)
	if mode == "hs":
		# 探査機(丸い胴に 太陽電池の 羽)
		c.draw_line(at + Vector2(-34, 0), at + Vector2(-16, 0), th["ink"], 3.0)
		c.draw_line(at + Vector2(16, 0), at + Vector2(34, 0), th["ink"], 3.0)
		c.draw_rect(Rect2(at + Vector2(-52, -14), Vector2(20, 28)), th["path"])
		c.draw_rect(Rect2(at + Vector2(32, -14), Vector2(20, 28)), th["path"])
		c.draw_circle(at, 16.0, th["accent"])
		c.draw_arc(at, 16.0, 0.0, TAU, 20, th["ink"], 2.0)
		c.draw_line(at + Vector2(0, -16), at + Vector2(0, -34), th["ink"], 2.0)
		return
	# 測量士(三脚と 人)
	c.draw_line(at + Vector2(-16, 34), at + Vector2(0, -4), th["ink"], 3.0)
	c.draw_line(at + Vector2(16, 34), at + Vector2(0, -4), th["ink"], 3.0)
	c.draw_line(at + Vector2(0, 34), at + Vector2(0, -4), th["ink"], 3.0)
	c.draw_rect(Rect2(at + Vector2(-14, -20), Vector2(28, 16)), th["accent"])
	c.draw_line(at + Vector2(14, -12), at + Vector2(30, -12), th["ink"], 3.0)
	c.draw_circle(at + Vector2(-30, -12), 12.0, Color(0.98, 0.86, 0.72))
	c.draw_colored_polygon(PackedVector2Array([
		at + Vector2(-42, 24), at + Vector2(-38, -2), at + Vector2(-20, -2),
		at + Vector2(-18, 24)]), th["path"])


## いちばん奥の 目あて。中学生は 測り終えた 国、高校生は 遠い 星
func _draw_goal(c: Control) -> void:
	var all_done := _cleared_count() >= chapters.size()
	var p := _node_pos(chapters.size() - 1) + Vector2(0, -170.0)
	var font := ThemeDB.fallback_font
	if mode == "hs":
		var r := 54.0 + (6.0 * sin(_t * 2.0) if all_done else 0.0)
		if all_done:
			for k in 9:
				var a := TAU * float(k) / 9.0 + _t * 0.3
				c.draw_line(p + Vector2(cos(a), sin(a)) * (r + 10.0),
					p + Vector2(cos(a), sin(a)) * (r + 60.0),
					Color(th["accent"].r, th["accent"].g, th["accent"].b, 0.55), 4.0)
		c.draw_circle(p, r, th["accent"] if all_done else th["land"])
		c.draw_arc(p, r, 0.0, TAU, 40, th["ink"], 3.0)
		c.draw_arc(p, r + 26.0, deg_to_rad(200.0), deg_to_rad(340.0), 26,
			Color(th["ink"].r, th["ink"].g, th["ink"].b, 0.7), 3.0)
	else:
		# 完成した 地図(巻物)
		var box := Rect2(p.x - 86, p.y - 56, 172, 112)
		c.draw_rect(box, th["accent"] if all_done else th["land"])
		c.draw_rect(box, th["ink"], false, 3.0)
		for k in 3:
			c.draw_line(Vector2(box.position.x + 14, box.position.y + 30.0 + 26.0 * float(k)),
				Vector2(box.position.x + box.size.x - 14,
					box.position.y + 30.0 + 26.0 * float(k)),
				Color(th["ink"].r, th["ink"].g, th["ink"].b, 0.7), 3.0)
		c.draw_circle(Vector2(box.position.x + 40, box.position.y + 22), 8.0, th["path"])
	var msg := ""
	if all_done:
		msg = "すべての星に届いた!" if mode == "hs" else "国じゅうを測り終えた!"
	else:
		msg = "あと %d %s" % [chapters.size() - _cleared_count(), String(th["unit"])]
	c.draw_string(font, p + Vector2(-170, -86), msg,
		HORIZONTAL_ALIGNMENT_CENTER, 340, 30, th["accent"] if all_done else th["ink"])


## この先はまだ見えない。進むと 開ける
func _draw_veil(c: Control, w: float) -> void:
	var i := _current_index() + 3
	if i >= chapters.size():
		return
	var y := _node_pos(i).y
	c.draw_rect(Rect2(0, 0, w, y), th["mist"])
	for k in int(w / 70.0) + 1:
		c.draw_circle(Vector2(35.0 + 70.0 * float(k), y), 44.0, th["mist"])
	c.draw_string(ThemeDB.fallback_font, Vector2(0, y - 46), String(th["veil"]),
		HORIZONTAL_ALIGNMENT_CENTER, w, 24,
		Color(th["ink"].r, th["ink"].g, th["ink"].b, 0.55))
