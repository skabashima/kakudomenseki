extends Node
class_name Icons
## 絵文字を使わずに描くアイコン。
##
## 同梱の Noto Sans JP には 王冠(U+1F451)・錠前(U+1F512)・鉛筆(U+270F)といった
## 絵文字が入っておらず、フォントを差し替えている Android では **豆腐(□)になる**。
## ★☆♥♡→←▶◆ などの記号はフォントに入っているのでそのまま使ってよい
## (同梱フォントに字があるかは FontFile.has_char() で確かめられる)。
##
## 使い方: row.add_child(Icons.crown(30.0, Color(1.0, 0.84, 0.3)))


## 王冠(挑戦モードを完走した印)
static func crown(sz: float, col: Color) -> Control:
	var c := _base(sz)
	c.draw.connect(func() -> void:
		var pts := PackedVector2Array([
			Vector2(0.10, 0.32), Vector2(0.29, 0.56), Vector2(0.50, 0.22),
			Vector2(0.71, 0.56), Vector2(0.90, 0.32), Vector2(0.86, 0.74),
			Vector2(0.14, 0.74),
		])
		for i in pts.size():
			pts[i] = pts[i] * sz
		c.draw_colored_polygon(pts, col)
		# 台座(冠のふち)
		c.draw_rect(Rect2(sz * 0.14, sz * 0.76, sz * 0.72, sz * 0.14), col)
		# とがりの先の玉
		for x in [0.10, 0.50, 0.90]:
			var y: float = 0.22 if is_equal_approx(float(x), 0.50) else 0.32
			c.draw_circle(Vector2(sz * float(x), sz * y), sz * 0.075, col))
	return c


## 角度編の印(2 本の線と、その間の弧)
static func angle_mark(sz: float, col: Color) -> Control:
	var c := _base(sz)
	c.draw.connect(func() -> void:
		var at := Vector2(sz * 0.16, sz * 0.82)
		var w := sz * 0.14
		c.draw_line(at, at + Vector2(sz * 0.76, 0), col, w * 0.6)
		c.draw_line(at, at + Vector2(sz * 0.62, -sz * 0.62), col, w * 0.6)
		c.draw_arc(at, sz * 0.34, -PI * 0.25, 0.0, 18, col, w * 0.45))
	return c


## 面積編の印(ぬりつぶした四角と三角)
static func area_mark(sz: float, col: Color) -> Control:
	var c := _base(sz)
	c.draw.connect(func() -> void:
		# ぬりつぶした四角(面積のイメージ)と、その中の ます目
		var r := Rect2(sz * 0.12, sz * 0.24, sz * 0.62, sz * 0.62)
		c.draw_rect(r, col)
		for i in 2:
			var t := float(i + 1) / 3.0
			c.draw_line(Vector2(r.position.x + r.size.x * t, r.position.y),
				Vector2(r.position.x + r.size.x * t, r.position.y + r.size.y),
				Color(0, 0, 0, 0.25), sz * 0.035)
			c.draw_line(Vector2(r.position.x, r.position.y + r.size.y * t),
				Vector2(r.position.x + r.size.x, r.position.y + r.size.y * t),
				Color(0, 0, 0, 0.25), sz * 0.035)
		# 右上に小さな三角(図形の合わせ)
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(sz * 0.62, sz * 0.10), Vector2(sz * 0.92, sz * 0.10),
			Vector2(sz * 0.92, sz * 0.40)]), col.lightened(0.3)))
	return c


## ものがたりの印(開いた本)
static func book(sz: float, col: Color) -> Control:
	var c := _base(sz)
	c.draw.connect(func() -> void:
		var left := PackedVector2Array([
			Vector2(sz * 0.10, sz * 0.26), Vector2(sz * 0.48, sz * 0.34),
			Vector2(sz * 0.48, sz * 0.82), Vector2(sz * 0.10, sz * 0.74)])
		var right := PackedVector2Array([
			Vector2(sz * 0.90, sz * 0.26), Vector2(sz * 0.52, sz * 0.34),
			Vector2(sz * 0.52, sz * 0.82), Vector2(sz * 0.90, sz * 0.74)])
		c.draw_colored_polygon(left, col)
		c.draw_colored_polygon(right, col.darkened(0.18)))
	return c


## たからの地図の印(旗)
static func flag(sz: float, col: Color) -> Control:
	var c := _base(sz)
	c.draw.connect(func() -> void:
		c.draw_line(Vector2(sz * 0.26, sz * 0.14), Vector2(sz * 0.26, sz * 0.88), col, sz * 0.10)
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(sz * 0.30, sz * 0.16), Vector2(sz * 0.84, sz * 0.32),
			Vector2(sz * 0.30, sz * 0.50)]), col))
	return c


## チャレンジの印(すな時計)
static func timer(sz: float, col: Color) -> Control:
	var c := _base(sz)
	c.draw.connect(func() -> void:
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(sz * 0.18, sz * 0.14), Vector2(sz * 0.82, sz * 0.14),
			Vector2(sz * 0.50, sz * 0.50)]), col)
		c.draw_colored_polygon(PackedVector2Array([
			Vector2(sz * 0.50, sz * 0.50), Vector2(sz * 0.82, sz * 0.86),
			Vector2(sz * 0.18, sz * 0.86)]), col)
		c.draw_line(Vector2(sz * 0.14, sz * 0.12), Vector2(sz * 0.86, sz * 0.12), col, sz * 0.08)
		c.draw_line(Vector2(sz * 0.14, sz * 0.88), Vector2(sz * 0.86, sz * 0.88), col, sz * 0.08))
	return c


## きろくの印(棒グラフ)
static func chart(sz: float, col: Color) -> Control:
	var c := _base(sz)
	c.draw.connect(func() -> void:
		var xs := [0.16, 0.42, 0.68]
		var hs := [0.34, 0.56, 0.74]
		for i in 3:
			var x: float = xs[i] * sz
			var h: float = hs[i] * sz
			c.draw_rect(Rect2(x, sz * 0.86 - h, sz * 0.16, h), col))
	return c


## 南京錠(まだ開いていないステージの印)
static func lock(sz: float, col: Color) -> Control:
	var c := _base(sz)
	c.draw.connect(func() -> void:
		# つる(上半分の弧)
		c.draw_arc(Vector2(sz * 0.5, sz * 0.44), sz * 0.22, PI, TAU, 20, col, sz * 0.11)
		# 本体
		c.draw_rect(Rect2(sz * 0.16, sz * 0.42, sz * 0.68, sz * 0.46), col)
		# 鍵穴
		c.draw_circle(Vector2(sz * 0.5, sz * 0.62), sz * 0.075,
			Color(0.1, 0.12, 0.18, 0.85)))
	return c


## けす(バックスペース)。⌫(U+232B)は同梱フォントに無いので図形で描く
static func backspace(sz: float, col: Color) -> Control:
	var c := _base(sz)
	c.draw.connect(func() -> void:
		var pts := PackedVector2Array([
			Vector2(0.08, 0.50), Vector2(0.34, 0.20), Vector2(0.92, 0.20),
			Vector2(0.92, 0.80), Vector2(0.34, 0.80),
		])
		for i in pts.size():
			pts[i] = pts[i] * sz
		c.draw_colored_polygon(pts, col)
		var ink := Color(0.12, 0.14, 0.2)
		var w := sz * 0.075
		c.draw_line(Vector2(sz * 0.50, sz * 0.38), Vector2(sz * 0.76, sz * 0.64), ink, w)
		c.draw_line(Vector2(sz * 0.76, sz * 0.38), Vector2(sz * 0.50, sz * 0.64), ink, w))
	return c


## もどす(1 手前へ)。↩(U+21A9)は同梱フォントに無いので図形で描く
static func undo(sz: float, col: Color) -> Control:
	var c := _base(sz)
	c.draw.connect(func() -> void:
		# 上半分の弧(右まわりに戻る形)
		c.draw_arc(Vector2(sz * 0.52, sz * 0.60), sz * 0.28, PI, TAU, 24, col, sz * 0.12)
		# 左端の矢じり
		var head := PackedVector2Array([
			Vector2(0.24, 0.44), Vector2(0.24, 0.80), Vector2(0.02, 0.62),
		])
		for i in head.size():
			head[i] = head[i] * sz
		c.draw_colored_polygon(head, col))
	return c

## 今日の図形むけ: 光が さす 星
static func star(sz: float, col: Color) -> Control:
	var c := _base(sz)
	c.draw.connect(func() -> void:
		var m := sz * 0.5
		var pts := PackedVector2Array()
		for i in 10:
			var r := sz * (0.46 if i % 2 == 0 else 0.20)
			var a := -PI * 0.5 + PI * float(i) / 5.0
			pts.append(Vector2(m, m) + Vector2(cos(a), sin(a)) * r)
		c.draw_colored_polygon(pts, col)
		for i in 4:
			var a2 := PI * 0.25 + PI * 0.5 * float(i)
			c.draw_line(Vector2(m, m) + Vector2(cos(a2), sin(a2)) * sz * 0.30,
				Vector2(m, m) + Vector2(cos(a2), sin(a2)) * sz * 0.46,
				Color(col.r, col.g, col.b, 0.7), sz * 0.05))
	return c


static func _base(sz: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(sz, sz)
	c.size = Vector2(sz, sz)
	# 表示専用。ボタンの上に載せてもタップを食わないようにする
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
