extends Control
class_name FigureView
## 問題の図形を描く Control。
## ProblemGen が作る「図形スペック」(shapes の配列)を受け取り、
## 論理座標(y 上向き)を自動でスケーリング・上下反転して描画する。

var spec: Dictionary = {}

## 論理座標 → 画面座標の変換
var _scale := 1.0
var _offset := Vector2.ZERO

const MARGIN := 60.0
const COL_LINE := Color(0.92, 0.95, 1.0)
const COL_ANGLE := Color(0.75, 0.85, 1.0)
const COL_UNKNOWN := Color(1.0, 0.85, 0.3)


func set_spec(s: Dictionary) -> void:
	spec = s
	queue_redraw()


func _px(p: Vector2) -> Vector2:
	return Vector2(p.x * _scale, -p.y * _scale) + _offset


func _collect_bounds() -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var pts: Array = []
	for sh in spec.get("shapes", []):
		match String(sh["t"]):
			"poly", "curve":
				for p in sh["p"]:
					pts.append(p)
			"seg", "arrow", "tick":
				pts.append(sh["a"])
				pts.append(sh["b"])
			"circle":
				var c: Vector2 = sh["c"]
				var r: float = sh["r"]
				pts.append(c + Vector2(r, r))
				pts.append(c - Vector2(r, r))
			"sector", "arc":
				var c2: Vector2 = sh["c"]
				var r2: float = sh["r"]
				pts.append(c2 + Vector2(r2, r2))
				pts.append(c2 - Vector2(r2, r2))
			"text":
				pts.append(sh["at"])
			"grid", "axes":
				pts.append(sh["from"])
				pts.append(sh["to"])
			"leaf":
				pts.append(Vector2.ZERO)
				pts.append(Vector2(sh["a"], sh["a"]))
			"lune":
				# 半円が三角形の外へふくらむ分も含める
				var a: float = sh["a"]
				var b: float = sh["b"]
				pts.append(Vector2(-a * 0.5, -0.5))
				pts.append(Vector2(b + 0.5, a + b * 0.35))
				pts.append(Vector2(b * 0.2, a + a * 0.4))
	for p in pts:
		lo.x = minf(lo.x, p.x)
		lo.y = minf(lo.y, p.y)
		hi.x = maxf(hi.x, p.x)
		hi.y = maxf(hi.y, p.y)
	if lo.x > hi.x:
		return Rect2(0, 0, 1, 1)
	# ラベルの文字がはみ出ないよう少し広げる
	var pad := maxf(hi.x - lo.x, hi.y - lo.y) * 0.12 + 0.001
	lo -= Vector2(pad, pad)
	hi += Vector2(pad, pad)
	return Rect2(lo, hi - lo)


func _draw() -> void:
	if spec.is_empty():
		return
	var b := _collect_bounds()
	var avail := size - Vector2(MARGIN, MARGIN) * 2.0
	if avail.x <= 0 or avail.y <= 0:
		return
	_scale = minf(avail.x / b.size.x, avail.y / b.size.y)
	# 中央寄せ(y は反転するので上端が -hi.y)
	var center_logical := b.position + b.size * 0.5
	_offset = size * 0.5 - Vector2(center_logical.x * _scale, -center_logical.y * _scale)

	for sh in spec.get("shapes", []):
		match String(sh["t"]):
			"grid":
				_draw_grid(sh)
			"axes":
				_draw_axes(sh)
			"poly":
				_draw_poly(sh)
			"curve":
				_draw_curve(sh)
			"seg":
				_draw_seg(sh)
			"circle":
				_draw_circle_sh(sh)
			"sector":
				_draw_sector(sh)
			"arc":
				_draw_arc_sh(sh)
			"angle":
				_draw_angle(sh)
			"right":
				_draw_right(sh)
			"tick":
				_draw_tick(sh)
			"text":
				_draw_label(sh)
			"arrow":
				_draw_arrow(sh)
			"leaf":
				_draw_leaf(sh)
			"lune":
				_draw_lune(sh)


func _pts_px(arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in arr:
		out.append(_px(p))
	return out


func _draw_poly(sh: Dictionary) -> void:
	var pts := _pts_px(sh["p"])
	if sh.has("fill"):
		draw_colored_polygon(pts, sh["fill"])
	var w: float = sh.get("w", 4.0)
	if w > 0.0:
		var stroke: Color = sh.get("stroke", COL_LINE) if sh.get("stroke") != null else COL_LINE
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, stroke, w, true)


func _draw_curve(sh: Dictionary) -> void:
	var pts := _pts_px(sh["p"])
	draw_polyline(pts, sh.get("color", COL_LINE), sh.get("w", 4.0), true)


func _draw_seg(sh: Dictionary) -> void:
	var a := _px(sh["a"])
	var b := _px(sh["b"])
	var col: Color = sh.get("color", COL_LINE)
	if sh.get("dash", false):
		draw_dashed_line(a, b, col, sh.get("w", 4.0), 12.0)
	else:
		draw_line(a, b, col, sh.get("w", 4.0), true)


func _draw_circle_sh(sh: Dictionary) -> void:
	var c := _px(sh["c"])
	var r: float = sh["r"] * _scale
	if sh.has("fill"):
		draw_circle(c, r, sh["fill"])
	if sh.get("w", 4.0) > 0.0 and (sh.has("stroke") or not sh.has("fill")):
		var stroke: Color = sh.get("stroke", COL_LINE) if sh.get("stroke") != null else COL_LINE
		draw_arc(c, r, 0.0, TAU, 64, stroke, sh.get("w", 4.0), true)


func _draw_sector(sh: Dictionary) -> void:
	var c := _px(sh["c"])
	var r: float = sh["r"] * _scale
	var a0: float = deg_to_rad(sh["a0"])
	var a1: float = deg_to_rad(sh["a1"])
	var pts := PackedVector2Array([c])
	var n := 48
	for i in n + 1:
		var t: float = a0 + (a1 - a0) * i / n
		pts.append(c + Vector2(cos(t), -sin(t)) * r)
	if sh.has("fill"):
		draw_colored_polygon(pts, sh["fill"])
	var stroke: Color = sh.get("stroke", COL_LINE) if sh.get("stroke") != null else COL_LINE
	var closed := pts.duplicate()
	closed.append(c)
	draw_polyline(closed, stroke, 4.0, true)


func _draw_arc_sh(sh: Dictionary) -> void:
	var c := _px(sh["c"])
	var r: float = sh["r"] * _scale
	# y 反転のため角度は符号を変えて描く
	draw_arc(c, r, -deg_to_rad(sh["a0"]), -deg_to_rad(sh["a1"]),
		48, sh.get("color", COL_LINE), sh.get("w", 4.0), true)


func _draw_angle(sh: Dictionary) -> void:
	var at: Vector2 = sh["at"]
	var d1: Vector2 = (sh["p1"] - at).normalized()
	var d2: Vector2 = (sh["p2"] - at).normalized()
	var label: String = sh["label"]
	var unknown := label.begins_with("x") or label.begins_with("θ") or label == "?"
	var col := COL_UNKNOWN if unknown else COL_ANGLE
	var a1 := atan2(d1.y, d1.x)
	var a2 := atan2(d2.y, d2.x)
	# a1 → a2 を反時計回り(正方向)で描く。差を 0..TAU に正規化
	var sweep := fposmod(a2 - a1, TAU)
	if sweep > PI * 1.999:
		sweep = TAU
	# 角の印の半径: 図形サイズに応じて。狭い角は少し大きく
	var r_px := 44.0 if sh.get("r", 0.0) == 0.0 else float(sh["r"]) * _scale
	if sweep < deg_to_rad(35.0):
		r_px *= 1.35
	var c := _px(at)
	draw_arc(c, r_px, -a1, -(a1 + sweep), 32, col, 3.5, true)
	# ラベルは二等分線方向の少し外側
	var bis := a1 + sweep * 0.5
	var pos := c + Vector2(cos(bis), -sin(bis)) * (r_px + 30.0)
	_draw_text_at(pos, label, col, 30 if not unknown else 34)


func _draw_right(sh: Dictionary) -> void:
	var at: Vector2 = sh["at"]
	var d1: Vector2 = (sh["p1"] - at).normalized()
	var d2: Vector2 = (sh["p2"] - at).normalized()
	var s := 16.0
	var c := _px(at)
	var e1 := Vector2(d1.x, -d1.y) * s
	var e2 := Vector2(d2.x, -d2.y) * s
	draw_polyline(PackedVector2Array([c + e1, c + e1 + e2, c + e2]), COL_ANGLE, 3.0, true)


func _draw_tick(sh: Dictionary) -> void:
	var a := _px(sh["a"])
	var b := _px(sh["b"])
	var mid := (a + b) * 0.5
	var dir := (b - a).normalized()
	var n := dir.orthogonal()
	var count: int = sh.get("n", 1)
	for i in count:
		var off := dir * (float(i) - (count - 1) * 0.5) * 8.0
		draw_line(mid + off - n * 9.0, mid + off + n * 9.0, COL_LINE, 3.0, true)


func _draw_label(sh: Dictionary) -> void:
	var col: Color = sh.get("color", COL_LINE)
	_draw_text_at(_px(sh["at"]), sh["s"], col, sh.get("size", 30))


func _draw_arrow(sh: Dictionary) -> void:
	var a := _px(sh["a"])
	var b := _px(sh["b"])
	var col: Color = sh.get("color", COL_LINE)
	var w: float = sh.get("w", 5.0)
	draw_line(a, b, col, w, true)
	var dir := (b - a).normalized()
	var n := dir.orthogonal()
	draw_colored_polygon(PackedVector2Array([
		b, b - dir * 18.0 + n * 8.0, b - dir * 18.0 - n * 8.0]), col)


func _draw_grid(sh: Dictionary) -> void:
	var from: Vector2 = sh["from"]
	var to: Vector2 = sh["to"]
	var col := Color(0.5, 0.6, 0.8, 0.25)
	var x := ceilf(from.x)
	while x <= to.x:
		draw_line(_px(Vector2(x, from.y)), _px(Vector2(x, to.y)), col, 1.5)
		x += 1.0
	var y := ceilf(from.y)
	while y <= to.y:
		draw_line(_px(Vector2(from.x, y)), _px(Vector2(to.x, y)), col, 1.5)
		y += 1.0


func _draw_axes(sh: Dictionary) -> void:
	var from: Vector2 = sh["from"]
	var to: Vector2 = sh["to"]
	var col := Color(0.85, 0.9, 1.0, 0.9)
	# x 軸(y=0)・y 軸(x=0)が範囲内にあれば描く
	if from.y <= 0.0 and to.y >= 0.0:
		var a := _px(Vector2(from.x, 0))
		var b := _px(Vector2(to.x, 0))
		draw_line(a, b, col, 2.5, true)
		draw_colored_polygon(PackedVector2Array([
			b, b + Vector2(-14, 6), b + Vector2(-14, -6)]), col)
		_draw_text_at(b + Vector2(-6, 22), "x", col, 24)
	if from.x <= 0.0 and to.x >= 0.0:
		var a2 := _px(Vector2(0, from.y))
		var b2 := _px(Vector2(0, to.y))
		draw_line(a2, b2, col, 2.5, true)
		draw_colored_polygon(PackedVector2Array([
			b2, b2 + Vector2(6, 14), b2 + Vector2(-6, 14)]), col)
		_draw_text_at(b2 + Vector2(20, 8), "y", col, 24)


## 葉っぱ形: 1 辺 a の正方形内の 2 つの四分円が重なる部分
func _draw_leaf(sh: Dictionary) -> void:
	var a: float = sh["a"]
	var n := 36
	var pts := PackedVector2Array()
	# 左下中心の四分円(0,0 中心・半径 a)の弧: 0°→90°
	for i in n + 1:
		var t := PI * 0.5 * i / n
		pts.append(_px(Vector2(cos(t), sin(t)) * a))
	# 右上中心の四分円((a,a) 中心)の弧: 180°→270° を逆順にたどって閉じる
	for i in n + 1:
		var t := PI * (1.0 + 0.5 * i / n)
		pts.append(_px(Vector2(a, a) + Vector2(cos(t), sin(t)) * a))
	draw_colored_polygon(pts, ProblemGen.FILL_ACCENT)
	draw_polyline(pts, COL_LINE, 3.5, true)


## ヒポクラテスの月: 直角三角形(直角が原点、たて a・よこ b)の 2 つの三日月
func _draw_lune(sh: Dictionary) -> void:
	var a: float = sh["a"]
	var b: float = sh["b"]
	var pa := Vector2(0, a)
	var pb := Vector2.ZERO
	var pc := Vector2(b, 0)
	var n := 40
	# 三日月 = 小半円 − 斜辺半円。ポリゴンのブーリアン(Geometry2D.clip)で正確に塗る
	var hyp_c := (pa + pc) * 0.5
	var hyp_r := (pa - pc).length() * 0.5
	var ang_a := (pa - hyp_c).angle()
	var leg1_c := (pa + pb) * 0.5
	var leg1_r := a * 0.5
	var small1 := PackedVector2Array()
	for i in n + 1:
		var t := PI * 0.5 + PI * i / n
		small1.append(leg1_c + Vector2(cos(t), sin(t)) * leg1_r)
	var small2 := PackedVector2Array()
	for i in n + 1:
		var t := PI * i / n
		small2.append((pb + pc) * 0.5 + Vector2(cos(t), -sin(t)) * b * 0.5)
	var big := PackedVector2Array()
	for i in n + 1:
		var t: float = ang_a + PI * float(i) / n
		big.append(hyp_c + Vector2(cos(t), sin(t)) * hyp_r)
	for lune_pts in [Geometry2D.clip_polygons(small1, big), Geometry2D.clip_polygons(small2, big)]:
		for piece in lune_pts:
			if piece.size() >= 3:
				var px_pts := PackedVector2Array()
				for p in piece:
					px_pts.append(_px(p))
				draw_colored_polygon(px_pts, ProblemGen.FILL_ACCENT)
	# 輪郭: 半円たち
	_stroke_pts(small1)
	_stroke_pts(small2)
	_stroke_pts(big)


func _stroke_pts(logical: PackedVector2Array) -> void:
	var px_pts := PackedVector2Array()
	for p in logical:
		px_pts.append(_px(p))
	draw_polyline(px_pts, COL_LINE, 3.0, true)


func _draw_text_at(pos: Vector2, text: String, col: Color, font_size: int) -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	# 縁取り(読みやすさのため背景色で細く)
	draw_string_outline(font, pos + Vector2(-sz.x * 0.5, sz.y * 0.3), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color(0.05, 0.08, 0.14, 0.9))
	draw_string(font, pos + Vector2(-sz.x * 0.5, sz.y * 0.3), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
