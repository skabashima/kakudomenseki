class_name StoryArt
## ストーリーの会話につける挿絵。
##
## 文字だけの画面は読み飛ばされる。その章で「どこにいて、何を見ているのか」を
## 一枚の絵で見せる。画像ファイルは持たず、その場で図形として描く
## (どの端末でもぼやけず、アプリの容量も増えない。効果音やアイコンと同じ方針)。
##
## 使い方: body.add_child(StoryArt.make("field", 320.0))

const SKY_DAY := Color(0.40, 0.60, 0.85)
const SKY_DUSK := Color(0.85, 0.55, 0.35)
const SAND := Color(0.78, 0.66, 0.44)
const SAND_DARK := Color(0.62, 0.51, 0.33)
const GREEN := Color(0.36, 0.55, 0.32)
const GREEN2 := Color(0.28, 0.45, 0.27)
const INK := Color(0.16, 0.14, 0.12)
const CLOTH := Color(0.85, 0.83, 0.78)


## 挿絵を 1 枚作る。高さを渡すと、その高さいっぱいに描く
static func make(kind: String, h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.clip_contents = true
	# 描画はラムダの外に出す(ラムダの中に match を書くと構文解析に失敗する)
	c.draw.connect(func() -> void: _render(c, kind, maxf(c.size.x, 10.0), h))
	c.resized.connect(c.queue_redraw)
	return c


static func _render(c: Control, kind: String, w: float, h: float) -> void:
	match kind:
		"field":
			_field(c, w, h)
		"master":
			_master(c, w, h)
		"dusk":
			_dusk(c, w, h)
		_:
			c.draw_rect(Rect2(0, 0, w, h), SKY_DAY)


## 三角形の畑が広がる丘。手前に測量の見習い(あなた)
static func _field(c: Control, w: float, h: float) -> void:
	_sky(c, w, h, SKY_DAY, Color(0.72, 0.84, 0.95))
	c.draw_circle(Vector2(w * 0.82, h * 0.22), h * 0.09, Color(1.0, 0.93, 0.6))
	# 遠くの山
	_poly(c, [Vector2(0, h * 0.55), Vector2(w * 0.22, h * 0.30), Vector2(w * 0.45, h * 0.55)],
		Color(0.35, 0.40, 0.52))
	_poly(c, [Vector2(w * 0.3, h * 0.55), Vector2(w * 0.55, h * 0.34), Vector2(w * 0.8, h * 0.55)],
		Color(0.30, 0.35, 0.47))
	# 地面
	c.draw_rect(Rect2(0, h * 0.55, w, h * 0.45), GREEN2)
	# 三角形の畑(奥から手前へ)
	_field_plot(c, [Vector2(w * 0.08, h * 0.72), Vector2(w * 0.34, h * 0.72), Vector2(w * 0.2, h * 0.57)])
	_field_plot(c, [Vector2(w * 0.38, h * 0.68), Vector2(w * 0.62, h * 0.68), Vector2(w * 0.56, h * 0.56)])
	_field_plot(c, [Vector2(w * 0.62, h * 0.80), Vector2(w * 0.95, h * 0.80), Vector2(w * 0.78, h * 0.62)])
	# 見習い(あなた)と測量棒
	_person(c, Vector2(w * 0.20, h * 0.95), h * 0.30, CLOTH)
	var rod_x := w * 0.30
	c.draw_line(Vector2(rod_x, h * 0.95), Vector2(rod_x, h * 0.60), Color(0.92, 0.9, 0.85), 4.0)
	for i in 4:
		var y := h * (0.66 + 0.07 * i)
		c.draw_line(Vector2(rod_x - h * 0.02, y), Vector2(rod_x + h * 0.02, y), INK, 3.0)


## 親方が砂に三角形を描く(手元)
static func _master(c: Control, w: float, h: float) -> void:
	c.draw_rect(Rect2(0, 0, w, h), SAND)
	# 砂の粒
	for i in 40:
		var x := w * fmod(0.137 * float(i * 7 + 3), 1.0)
		var y := h * fmod(0.219 * float(i * 5 + 1), 1.0)
		c.draw_circle(Vector2(x, y), 2.0, SAND_DARK)
	# 砂に描いた三角形(彫った線に見えるよう二重に描く)
	var a := Vector2(w * 0.30, h * 0.28)
	var b := Vector2(w * 0.16, h * 0.78)
	var cc := Vector2(w * 0.66, h * 0.78)
	for p in [[a, b], [b, cc], [cc, a]]:
		c.draw_line(p[0] + Vector2(0, 3), p[1] + Vector2(0, 3), Color(1.0, 0.95, 0.85, 0.7), 7.0)
		c.draw_line(p[0], p[1], SAND_DARK, 6.0)
	# 棒(親方の手)
	c.draw_line(Vector2(w * 0.70, h * 0.20), Vector2(w * 0.60, h * 0.70), Color(0.45, 0.32, 0.2), 7.0)
	_person(c, Vector2(w * 0.86, h * 0.96), h * 0.62, Color(0.75, 0.68, 0.55))


## 夕暮れ。砂に四角形と対角線 ― 次の謎
static func _dusk(c: Control, w: float, h: float) -> void:
	_sky(c, w, h, SKY_DUSK, Color(0.45, 0.35, 0.45))
	c.draw_circle(Vector2(w * 0.5, h * 0.52), h * 0.13, Color(1.0, 0.82, 0.45))
	c.draw_rect(Rect2(0, h * 0.55, w, h * 0.45), SAND_DARK)
	# 砂に描いた四角形と対角線
	var p := [Vector2(w * 0.22, h * 0.68), Vector2(w * 0.72, h * 0.64),
		Vector2(w * 0.80, h * 0.90), Vector2(w * 0.30, h * 0.94)]
	for i in 4:
		c.draw_line(p[i], p[(i + 1) % 4], Color(1.0, 0.95, 0.85, 0.85), 5.0)
	c.draw_line(p[0], p[2], Color(1.0, 0.9, 0.5, 0.9), 4.0)
	_person(c, Vector2(w * 0.10, h * 0.97), h * 0.34, Color(0.35, 0.30, 0.34))


# =========================================================
# 部品
# =========================================================

static func _sky(c: Control, w: float, h: float, top: Color, bottom: Color) -> void:
	var bands := 12
	for i in bands:
		var t := float(i) / float(bands - 1)
		c.draw_rect(Rect2(0, h * t * 0.6, w, h * 0.6 / float(bands) + 1.0),
			top.lerp(bottom, t))


static func _poly(c: Control, pts: Array, col: Color) -> void:
	var pv := PackedVector2Array()
	for p in pts:
		pv.append(p)
	c.draw_colored_polygon(pv, col)


## 三角形の畑。輪郭をつけて「区画」に見せる
static func _field_plot(c: Control, pts: Array) -> void:
	_poly(c, pts, GREEN)
	var pv := PackedVector2Array()
	for p in pts:
		pv.append(p)
	pv.append(pts[0])
	c.draw_polyline(pv, Color(0.9, 0.92, 0.85, 0.8), 2.5)


## 棒人間。足元の座標と身長を渡す
static func _person(c: Control, foot: Vector2, tall: float, cloth: Color) -> void:
	var head_r := tall * 0.13
	var hip := foot - Vector2(0, tall * 0.42)
	var neck := foot - Vector2(0, tall * 0.74)
	# 服(胴)
	_poly(c, [neck + Vector2(-tall * 0.14, 0), neck + Vector2(tall * 0.14, 0),
		hip + Vector2(tall * 0.17, 0), hip + Vector2(-tall * 0.17, 0)], cloth)
	# 足
	c.draw_line(hip, foot + Vector2(-tall * 0.10, 0), INK, tall * 0.06)
	c.draw_line(hip, foot + Vector2(tall * 0.10, 0), INK, tall * 0.06)
	# 腕
	c.draw_line(neck + Vector2(0, tall * 0.05), neck + Vector2(tall * 0.22, tall * 0.20),
		cloth.darkened(0.15), tall * 0.05)
	# 頭
	c.draw_circle(neck - Vector2(0, head_r * 0.8), head_r, Color(0.86, 0.72, 0.56))
