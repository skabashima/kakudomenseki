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
	# もらえた 高さ いっぱいに 描く(画面の 余白を つぶすため。h は 下限)
	c.draw.connect(func() -> void: _render(c, kind, maxf(c.size.x, 10.0), maxf(c.size.y, h)))
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
		"theater":
			_theater(c, w, h)
		"fountain":
			_fountain(c, w, h)
		"wheel":
			_wheel(c, w, h)
		"roof":
			_roof(c, w, h)
		"night":
			_night(c, w, h)
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


## 円形の劇場。客席の弧と、下手の舞台
static func _theater(c: Control, w: float, h: float) -> void:
	_sky(c, w, h, SKY_DAY, Color(0.80, 0.86, 0.94))
	c.draw_rect(Rect2(0, h * 0.52, w, h * 0.48), SAND)
	var cx := w * 0.5
	var cy := h * 0.92
	# 客席(同心の弧)
	for i in 5:
		var r := h * (0.30 + 0.09 * float(i))
		c.draw_arc(Vector2(cx, cy), r, PI, TAU, 48, SAND_DARK, h * 0.035)
	# 舞台
	_poly(c, [Vector2(cx - w * 0.16, cy - h * 0.02), Vector2(cx + w * 0.16, cy - h * 0.02),
		Vector2(cx + w * 0.12, cy - h * 0.16), Vector2(cx - w * 0.12, cy - h * 0.16)],
		Color(0.55, 0.44, 0.30))
	# 観客(点)
	for i in 12:
		var a := PI + PI * (0.12 + 0.76 * fmod(0.191 * float(i * 3 + 1), 1.0))
		var rr := h * (0.34 + 0.28 * fmod(0.137 * float(i * 5 + 2), 1.0))
		c.draw_circle(Vector2(cx + cos(a) * rr, cy + sin(a) * rr), h * 0.018, INK)
	_person(c, Vector2(cx, cy - h * 0.04), h * 0.16, CLOTH)


## 噴水。放物線を描いて落ちる水
static func _fountain(c: Control, w: float, h: float) -> void:
	_sky(c, w, h, Color(0.20, 0.28, 0.48), Color(0.55, 0.60, 0.78))
	c.draw_rect(Rect2(0, h * 0.70, w, h * 0.30), Color(0.28, 0.34, 0.44))
	# 水盤
	c.draw_rect(Rect2(w * 0.20, h * 0.68, w * 0.60, h * 0.10), Color(0.42, 0.62, 0.75))
	# 水の放物線(左右対称に 2 本)
	for sgn_v in [-1.0, 1.0]:
		var sgn := float(sgn_v)
		var pts := PackedVector2Array()
		for i in 21:
			var t := float(i) / 20.0
			var x: float = w * 0.5 + sgn * w * 0.26 * t
			var y: float = h * (0.68 - 0.34 * (1.0 - (2.0 * t - 1.0) * (2.0 * t - 1.0)))
			pts.append(Vector2(x, y))
		c.draw_polyline(pts, Color(0.75, 0.90, 1.0, 0.9), 4.0)
	_person(c, Vector2(w * 0.12, h * 0.95), h * 0.30, CLOTH)


# =========================================================
# 部品
# =========================================================

## 車輪の工房。大小の車輪が立てかけてある(第3章)
static func _wheel(c: Control, w: float, h: float) -> void:
	_sky(c, w, h, SKY_DAY, Color(0.82, 0.78, 0.68))
	c.draw_rect(Rect2(0, h * 0.62, w, h * 0.38), SAND)
	# 工房の壁と屋根
	c.draw_rect(Rect2(w * 0.06, h * 0.26, w * 0.44, h * 0.40), Color(0.46, 0.36, 0.26))
	_poly(c, [Vector2(w * 0.02, h * 0.28), Vector2(w * 0.54, h * 0.28),
		Vector2(w * 0.28, h * 0.10)], Color(0.36, 0.28, 0.20))
	# 大小の車輪
	var wheels: Array = [[w * 0.66, h * 0.52, h * 0.22], [w * 0.86, h * 0.60, h * 0.14],
		[w * 0.40, h * 0.60, h * 0.13]]
	for wd in wheels:
		var cx: float = wd[0]
		var cy: float = wd[1]
		var r: float = wd[2]
		c.draw_arc(Vector2(cx, cy), r, 0.0, TAU, 40, Color(0.55, 0.42, 0.28), h * 0.030)
		for k in 8:
			var a := TAU * float(k) / 8.0
			c.draw_line(Vector2(cx, cy), Vector2(cx + cos(a) * r, cy + sin(a) * r),
				Color(0.62, 0.50, 0.34), h * 0.012)
		c.draw_circle(Vector2(cx, cy), r * 0.16, Color(0.40, 0.31, 0.21))
	_person(c, Vector2(w * 0.22, h * 0.66), h * 0.20, CLOTH)


## 大工の作業場。組みかけの家の骨組み(第5章)
static func _roof(c: Control, w: float, h: float) -> void:
	_sky(c, w, h, SKY_DAY, Color(0.86, 0.84, 0.74))
	c.draw_rect(Rect2(0, h * 0.70, w, h * 0.30), SAND)
	# 土台と柱
	c.draw_rect(Rect2(w * 0.12, h * 0.66, w * 0.66, h * 0.05), Color(0.50, 0.38, 0.26))
	for k in 4:
		var x := w * (0.16 + 0.20 * float(k))
		c.draw_rect(Rect2(x, h * 0.34, w * 0.035, h * 0.33), Color(0.58, 0.44, 0.30))
	# 屋根の骨(三角)
	_poly(c, [Vector2(w * 0.10, h * 0.36), Vector2(w * 0.80, h * 0.36),
		Vector2(w * 0.45, h * 0.12)], Color(0.44, 0.34, 0.23))
	c.draw_line(Vector2(w * 0.10, h * 0.36), Vector2(w * 0.80, h * 0.36),
		Color(0.66, 0.52, 0.34), h * 0.02)
	# 立てかけた縄(結び目つき)
	c.draw_line(Vector2(w * 0.84, h * 0.70), Vector2(w * 0.92, h * 0.40),
		Color(0.80, 0.72, 0.52), h * 0.014)
	for k in 3:
		c.draw_circle(Vector2(w * (0.85 + 0.025 * float(k)), h * (0.63 - 0.10 * float(k))),
			h * 0.014, Color(0.86, 0.78, 0.58))
	_person(c, Vector2(w * 0.30, h * 0.70), h * 0.22, CLOTH)


## 夜の天文台。星と観測の筒(第8章・第18章)
static func _night(c: Control, w: float, h: float) -> void:
	_sky(c, w, h, Color(0.06, 0.08, 0.22), Color(0.16, 0.20, 0.38))
	# 星(規則的に散らす。乱数は使わないので毎回同じ空になる)
	for i in 40:
		var fx := fmod(0.6180339 * float(i * 7 + 3), 1.0)
		var fy := fmod(0.4142135 * float(i * 5 + 1), 1.0)
		var rr := h * (0.006 + 0.006 * fmod(0.7320508 * float(i), 1.0))
		c.draw_circle(Vector2(w * fx, h * (0.06 + 0.52 * fy)), rr, Color(0.92, 0.94, 1.0))
	# 遠くの山なみ
	_poly(c, [Vector2(0, h * 0.82), Vector2(w * 0.22, h * 0.60), Vector2(w * 0.44, h * 0.82)],
		Color(0.10, 0.12, 0.20))
	_poly(c, [Vector2(w * 0.30, h * 0.82), Vector2(w * 0.52, h * 0.66), Vector2(w * 0.74, h * 0.82)],
		Color(0.09, 0.11, 0.18))
	# 地面と天文台のドーム
	c.draw_rect(Rect2(0, h * 0.82, w, h * 0.18), Color(0.12, 0.14, 0.20))
	var cx := w * 0.66
	var cy := h * 0.82
	c.draw_rect(Rect2(cx - w * 0.15, h * 0.66, w * 0.30, h * 0.16), Color(0.22, 0.24, 0.32))
	c.draw_arc(Vector2(cx, h * 0.66), w * 0.15, PI, TAU, 32, Color(0.30, 0.33, 0.42), h * 0.06)
	# 観測の筒(星のほうを向いている)
	c.draw_line(Vector2(cx, h * 0.64), Vector2(cx + w * 0.15, h * 0.40),
		Color(0.70, 0.74, 0.86), h * 0.030)
	_person(c, Vector2(w * 0.26, h * 0.86), h * 0.22, Color(0.62, 0.66, 0.78))


static func _sky(c: Control, w: float, h: float, top: Color, bottom: Color) -> void:
	# 帯の 数は 高さに あわせる(のばしたときに すきまの すじが 出ないように)
	var bands := maxi(12, int(h / 12.0))
	for i in bands:
		var t := float(i) / float(bands - 1)
		c.draw_rect(Rect2(0, h * t * 0.6, w, h * 0.6 / float(bands - 1) + 1.5),
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
