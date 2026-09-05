class_name StoryFigs
## ストーリーで使う図のスペック。
##
## measure の図は、動かせる点 p を受け取って毎回作り直す(数字も図に書き込む)。
## *_proof は動かない解説図。
##
## 図の描画そのものは ui/figure_view.gd。ここは「何を描くか」だけを返す。

const R := StoryDefs.R_CIRCLE
const B := StoryDefs.TRI_B
const C := StoryDefs.TRI_C
const GOLD := Color(1.0, 0.85, 0.3)
const WHITE := Color(0.92, 0.95, 1.0)
const DIM := Color(0.62, 0.72, 0.88)


static func spec(kind: String, p: Vector2) -> Dictionary:
	match kind:
		"triangle":
			return _triangle(p)
		"zigzag":
			return _zigzag(p)
		"circle":
			return _circle(p)
		"equal_area":
			return _equal_area(p)
		"pythagoras":
			return _pythagoras(p)
		"inscribed":
			return _inscribed(p)
		"similar":
			return _similar(p)
		"sine_law":
			return _sine_law(p)
		"area_sin":
			return _area_sin(p)
		"parabola":
			return _parabola(p)
		"parallel_proof":
			return _parallel_proof()
		"zigzag_proof":
			return _zigzag_proof()
		"circle_proof":
			return _circle_proof()
		"equal_area_proof":
			return _equal_area_proof()
		"pythagoras_proof":
			return _pythagoras_proof()
		"inscribed_proof":
			return _inscribed_proof()
		"similar_proof":
			return _similar_proof()
		"sine_law_proof":
			return _sine_law_proof()
		"area_sin_proof":
			return _area_sin_proof()
		"parabola_proof":
			return _parabola_proof()
	# 第11章から先の図は core/story_figs2.gd にある
	return StoryFigs2.spec(kind, p)


# ============ 第1章 三角形の内角の和 ============

static func _triangle(a: Vector2) -> Dictionary:
	var d: Array = StoryDefs.rounded_angles(StoryDefs.angles_of(a, B, C))
	return {"shapes": [
		ProblemGen.poly([a, B, C], ProblemGen.FILL_MAIN, WHITE, 4.0),
		ProblemGen.ang(a, B, C, "%d°" % int(d[0]), 1.8),
		ProblemGen.ang(B, C, a, "%d°" % int(d[1]), 1.8),
		ProblemGen.ang(C, a, B, "%d°" % int(d[2]), 1.8),
		ProblemGen.label(a + Vector2(0.0, 0.9), "A"),
		ProblemGen.label(B + Vector2(-0.8, -0.6), "B"),
		ProblemGen.label(C + Vector2(0.8, -0.6), "C"),
	]}


static func _parallel_proof() -> Dictionary:
	var a := Vector2(4.0, 6.0)
	return {"shapes": [
		ProblemGen.poly([a, B, C], ProblemGen.FILL_MAIN, WHITE, 4.0),
		ProblemGen.seg(a + Vector2(-5.0, 0.0), a + Vector2(5.0, 0.0), GOLD, 3.0, true),
		ProblemGen.ang(a, a + Vector2(-5.0, 0.0), B, "B と同じ", 1.6),
		ProblemGen.ang(a, C, a + Vector2(5.0, 0.0), "C と同じ", 1.6),
		ProblemGen.ang(B, C, a, "B", 1.8),
		ProblemGen.ang(C, a, B, "C", 1.8),
		ProblemGen.label(a + Vector2(0.0, 1.0), "A"),
	]}


# ============ 第2章 折れ線(平行線にはさまれた曲がり角) ============

## 平行な壁と、右側の 2 点を結ぶ折れ線。曲がり角 p を動かす
static func _zigzag(p: Vector2) -> Dictionary:
	var lo := StoryDefs.ZIG_LOW
	var hi := StoryDefs.ZIG_HIGH
	var z: Array = StoryDefs.zigzag_angles(p)
	return {"shapes": [
		ProblemGen.seg(Vector2(-8.0, 0.0), Vector2(14.0, 0.0), WHITE, 4.0),
		ProblemGen.seg(Vector2(-8.0, 8.0), Vector2(14.0, 8.0), WHITE, 4.0),
		ProblemGen.seg(hi, p, GOLD, 3.5),
		ProblemGen.seg(p, lo, GOLD, 3.5),
		ProblemGen.ang(hi, Vector2(-8.0, 8.0), p, "上 %d°" % roundi(z[0]), 1.8),
		ProblemGen.ang(lo, p, Vector2(-8.0, 0.0), "下 %d°" % roundi(z[1]), 1.8),
		ProblemGen.ang(p, lo, hi, "折れ %d°" % roundi(z[2]), 1.8),
		ProblemGen.label(Vector2(-6.5, 8.8), "上の壁"),
		ProblemGen.label(Vector2(-6.5, -0.9), "下の壁"),
	]}


## 曲がり角を通る平行線を引くと、折れ角が上下に分かれて錯角になる
static func _zigzag_proof() -> Dictionary:
	var lo := StoryDefs.ZIG_LOW
	var hi := StoryDefs.ZIG_HIGH
	var p := Vector2(1.0, 4.0)
	var z: Array = StoryDefs.zigzag_angles(p)
	return {"shapes": [
		ProblemGen.seg(Vector2(-8.0, 0.0), Vector2(14.0, 0.0), WHITE, 4.0),
		ProblemGen.seg(Vector2(-8.0, 8.0), Vector2(14.0, 8.0), WHITE, 4.0),
		ProblemGen.seg(Vector2(-8.0, 4.0), Vector2(14.0, 4.0), DIM, 2.5, true),
		ProblemGen.seg(hi, p, GOLD, 3.5),
		ProblemGen.seg(p, lo, GOLD, 3.5),
		ProblemGen.ang(hi, Vector2(-8.0, 8.0), p, "上 %d°" % roundi(z[0]), 1.8),
		ProblemGen.ang(lo, p, Vector2(-8.0, 0.0), "下 %d°" % roundi(z[1]), 1.8),
		ProblemGen.ang(p, Vector2(14.0, 4.0), hi, "上と同じ", 1.5),
		ProblemGen.ang(p, lo, Vector2(14.0, 4.0), "下と同じ", 2.4),
		ProblemGen.label(Vector2(-6.0, 4.8), "引いた補助線(壁と平行)"),
	]}


# ============ 第3章 円周率 ============

static func _circle(p: Vector2) -> Dictionary:
	var r: float = maxf(p.x, 0.5)
	return {"shapes": [
		ProblemGen.circle(Vector2.ZERO, r, ProblemGen.FILL_MAIN, WHITE, 4.0),
		ProblemGen.seg(Vector2(-r, 0.0), Vector2(r, 0.0), GOLD, 3.0),
		ProblemGen.label(Vector2(0.0, -0.9), "直径 %.1f" % (2.0 * r)),
		ProblemGen.label(Vector2(0.0, r + 1.0), "円周 %.2f" % (TAU * r)),
	]}


static func _circle_proof() -> Dictionary:
	var r := 5.0
	var hex: Array = []
	for i in 6:
		var a := deg_to_rad(60.0 * float(i))
		hex.append(Vector2(cos(a), sin(a)) * r)
	return {"shapes": [
		ProblemGen.circle(Vector2.ZERO, r, null, WHITE, 4.0),
		ProblemGen.poly(hex, ProblemGen.FILL_ACCENT, GOLD, 3.0),
		ProblemGen.seg(Vector2(-r, 0.0), Vector2(r, 0.0), DIM, 2.5, true),
		ProblemGen.label(Vector2(0.0, -r - 1.2), "正六角形のふち = 直径の 3 倍"),
		ProblemGen.label(Vector2(0.0, r + 1.2), "円のふち = 直径の 3.14 倍"),
	]}


# ============ 第4章 等積変形 ============

static func _equal_area(a: Vector2) -> Dictionary:
	return {"shapes": [
		ProblemGen.seg(Vector2(-5.0, 6.0), Vector2(15.0, 6.0), DIM, 2.5, true),
		ProblemGen.poly([a, B, C], ProblemGen.FILL_MAIN, WHITE, 4.0),
		ProblemGen.seg(a, Vector2(a.x, 0.0), GOLD, 3.0, true),
		ProblemGen.side_label(B, C, "底辺 10", -1.0, 0.9),
		ProblemGen.label(Vector2(a.x + 1.2, 3.0), "高さ 6"),
		ProblemGen.label(Vector2(5.0, 7.0), "面積 30"),
	]}


static func _equal_area_proof() -> Dictionary:
	var a := Vector2(3.0, 6.0)
	return {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(10, 0), Vector2(10, 6), Vector2(0, 6)],
			null, DIM, 3.0),
		ProblemGen.poly([a, B, C], ProblemGen.FILL_MAIN, WHITE, 4.0),
		ProblemGen.label(Vector2(5.0, 7.0), "長方形 10 × 6 = 60"),
		ProblemGen.label(Vector2(5.0, -1.2), "三角形はその半分 = 30"),
	]}


# ============ 第5章 三平方の定理 ============

static func _pythagoras(p: Vector2) -> Dictionary:
	var a: float = p.x
	var b: float = p.y
	var c := sqrt(a * a + b * b)
	return {"shapes": [
		# つまむ点が宙に浮いて見えないよう、点までの枠を薄く描く
		ProblemGen.poly([Vector2.ZERO, Vector2(a, 0.0), Vector2(a, b), Vector2(0.0, b)],
			null, DIM, 2.0),
		ProblemGen.poly([Vector2.ZERO, Vector2(a, 0.0), Vector2(0.0, b)],
			ProblemGen.FILL_MAIN, WHITE, 4.0),
		ProblemGen.right(Vector2.ZERO, Vector2(a, 0.0), Vector2(0.0, b)),
		ProblemGen.poly([Vector2.ZERO, Vector2(a, 0.0), Vector2(a, -a), Vector2(0.0, -a)],
			ProblemGen.FILL_SUB, DIM, 2.5),
		ProblemGen.poly([Vector2.ZERO, Vector2(0.0, b), Vector2(-b, b), Vector2(-b, 0.0)],
			ProblemGen.FILL_SUB, DIM, 2.5),
		ProblemGen.label(Vector2(a * 0.5, -a * 0.5), "a² = %.1f" % (a * a)),
		ProblemGen.label(Vector2(-b * 0.5, b * 0.5), "b² = %.1f" % (b * b)),
		ProblemGen.side_label(Vector2(a, 0.0), Vector2(0.0, b),
			"c = %.2f  (c² = %.1f)" % [c, c * c], 1.0, 1.0),
	]}


static func _pythagoras_proof() -> Dictionary:
	var a := Vector2(4.0, 0.0)
	var b := Vector2(0.0, 3.0)
	var d := b - a
	var n := Vector2(d.y, -d.x)
	return {"shapes": [
		ProblemGen.poly([Vector2.ZERO, a, b], ProblemGen.FILL_MAIN, WHITE, 4.0),
		ProblemGen.right(Vector2.ZERO, a, b),
		ProblemGen.poly([a, b, b + n, a + n], ProblemGen.FILL_ACCENT, GOLD, 3.0),
		ProblemGen.label((a + b + n) * 0.5, "c²"),
		ProblemGen.label(Vector2(2.0, -0.9), "a = 4"),
		ProblemGen.label(Vector2(-1.0, 1.5), "b = 3"),
		ProblemGen.label(Vector2(2.0, -2.2), "9 + 16 = 25 → c = 5"),
	]}


# ============ 第6章 円周角 ============

static func _stage_ends() -> Array:
	return StoryDefs.chord_ends()


static func _inscribed(a: Vector2) -> Dictionary:
	var e := _stage_ends()
	var deg := StoryDefs.inscribed_angles(a)
	return {"shapes": [
		ProblemGen.circle(Vector2.ZERO, R, null, DIM, 3.0),
		ProblemGen.poly([a, e[0], e[1]], ProblemGen.FILL_MAIN, WHITE, 3.5),
		ProblemGen.seg(Vector2.ZERO, e[0], DIM, 2.5, true),
		ProblemGen.seg(Vector2.ZERO, e[1], DIM, 2.5, true),
		ProblemGen.ang(a, e[0], e[1], "%d°" % roundi(deg[0]), 1.6),
		ProblemGen.ang(Vector2.ZERO, e[1], e[0], "%d°" % roundi(deg[1]), 1.6),
		ProblemGen.label(Vector2(0.0, 0.9), "O"),
		ProblemGen.label(a + a.normalized() * 1.0, "席"),
		ProblemGen.side_label(e[0], e[1], "舞台", -1.0, 0.8),
	]}


static func _inscribed_proof() -> Dictionary:
	var e := _stage_ends()
	var a := Vector2(0.0, R)
	return {"shapes": [
		ProblemGen.circle(Vector2.ZERO, R, null, DIM, 3.0),
		ProblemGen.poly([a, e[0], Vector2.ZERO], ProblemGen.FILL_SUB, WHITE, 3.0),
		ProblemGen.poly([a, Vector2.ZERO, e[1]], ProblemGen.FILL_ACCENT, WHITE, 3.0),
		ProblemGen.tick(Vector2.ZERO, a, 1),
		ProblemGen.tick(Vector2.ZERO, e[0], 1),
		ProblemGen.tick(Vector2.ZERO, e[1], 1),
		ProblemGen.label(Vector2(0.0, -1.2), "どれも半径 ― 二等辺三角形が 2 つ"),
	]}


# ============ 第7章 相似比と面積比 ============

static func _similar(p: Vector2) -> Dictionary:
	var k: float = p.x
	var small := StoryDefs.tri_shape(1.0)
	var big := StoryDefs.tri_shape(k)
	return {"shapes": [
		ProblemGen.poly(big, ProblemGen.FILL_SUB, GOLD, 3.5),
		ProblemGen.poly(small, ProblemGen.FILL_MAIN, WHITE, 3.5),
		ProblemGen.seg(Vector2(1.2, -2.0), Vector2(2.6, -2.0), DIM, 2.5, true),
		ProblemGen.label(Vector2(6.2, 6.0), "相似比 %.2f 倍" % k),
		ProblemGen.label(Vector2(6.2, 4.6), "小 %.2f" % StoryDefs.polygon_area(small)),
		ProblemGen.label(Vector2(6.2, 3.2), "大 %.2f" % StoryDefs.polygon_area(big)),
		ProblemGen.label(Vector2(1.9, -3.0), "← 動かすと拡大 →"),
	]}


static func _similar_proof() -> Dictionary:
	return {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(2, 0), Vector2(2, 1), Vector2(0, 1)],
			ProblemGen.FILL_MAIN, WHITE, 3.0),
		ProblemGen.poly([Vector2(3, 0), Vector2(7, 0), Vector2(7, 2), Vector2(3, 2)],
			ProblemGen.FILL_SUB, GOLD, 3.0),
		ProblemGen.label(Vector2(1.0, -0.9), "2 × 1 = 2"),
		ProblemGen.label(Vector2(5.0, -0.9), "4 × 2 = 8  (4 倍)"),
		ProblemGen.label(Vector2(3.5, 3.0), "長さ 2 倍 → 面積 4 倍"),
	]}


# ============ 第8章 正弦定理 ============

static func _sine_law(a: Vector2) -> Dictionary:
	var e := _stage_ends()
	var deg := StoryDefs.inscribed_angles(a)
	var side := StoryDefs.chord_len()
	return {"shapes": [
		ProblemGen.circle(Vector2.ZERO, R, null, DIM, 3.0),
		ProblemGen.poly([a, e[0], e[1]], ProblemGen.FILL_MAIN, WHITE, 3.5),
		ProblemGen.seg(Vector2(-R, 0.0), Vector2(R, 0.0), GOLD, 2.5, true),
		ProblemGen.ang(a, e[0], e[1], "A = %d°" % roundi(deg[0]), 1.8),
		ProblemGen.side_label(e[0], e[1], "a = %.2f" % side, -1.0, 0.8),
		ProblemGen.label(Vector2(0.0, 0.9), "2R = %.1f" % (2.0 * R)),
	]}


static func _sine_law_proof() -> Dictionary:
	var e := _stage_ends()
	var d := Vector2(-e[0].x, -e[0].y)
	return {"shapes": [
		ProblemGen.circle(Vector2.ZERO, R, null, DIM, 3.0),
		ProblemGen.seg(e[0], d, GOLD, 3.0),
		ProblemGen.poly([e[0], e[1], d], ProblemGen.FILL_MAIN, WHITE, 3.5),
		ProblemGen.right(e[1], e[0], d),
		ProblemGen.label(Vector2(0.0, 1.0), "直径 2R"),
		ProblemGen.label(Vector2(0.0, -R - 1.2), "直径を見こむ角は 90° → a = 2R sin A"),
	]}


# ============ 第9章 ½ab sin C ============

static func _area_sin(a: Vector2) -> Dictionary:
	var c0 := Vector2.ZERO
	var b0 := Vector2(StoryDefs.SIDE_A, 0.0)
	var t := atan2(a.y, a.x)
	return {"shapes": [
		ProblemGen.poly([c0, b0, a], ProblemGen.FILL_MAIN, WHITE, 4.0),
		ProblemGen.seg(a, Vector2(a.x, 0.0), GOLD, 2.5, true),
		ProblemGen.ang(c0, b0, a, "C = %d°" % roundi(rad_to_deg(t)), 1.8),
		ProblemGen.side_label(c0, b0, "a = %.0f" % StoryDefs.SIDE_A, -1.0, 0.9),
		ProblemGen.side_label(c0, a, "b = %.0f" % StoryDefs.SIDE_B, 1.0, 0.9),
		ProblemGen.label(Vector2(4.0, 7.5),
			"面積 %.2f" % (0.5 * StoryDefs.SIDE_A * StoryDefs.SIDE_B * sin(t))),
	]}


static func _area_sin_proof() -> Dictionary:
	var a := Vector2(cos(deg_to_rad(55.0)), sin(deg_to_rad(55.0))) * StoryDefs.SIDE_B
	return {"shapes": [
		ProblemGen.poly([Vector2.ZERO, Vector2(StoryDefs.SIDE_A, 0.0), a],
			ProblemGen.FILL_MAIN, WHITE, 4.0),
		ProblemGen.seg(a, Vector2(a.x, 0.0), GOLD, 3.0, true),
		ProblemGen.right(Vector2(a.x, 0.0), a, Vector2(StoryDefs.SIDE_A, 0.0)),
		ProblemGen.label(Vector2(a.x + 1.6, a.y * 0.5), "高さ = b sin C"),
		ProblemGen.label(Vector2(4.0, -1.2), "面積 = a × b sin C ÷ 2"),
	]}


# ============ 第10章 6分の1公式 ============

static func _parab_pts(from_x: float, to_x: float) -> Array:
	var pts: Array = []
	var n := 40
	for i in n + 1:
		var x := from_x + (to_x - from_x) * float(i) / float(n)
		pts.append(Vector2(x, x * x))
	return pts


static func _parabola(p: Vector2) -> Dictionary:
	var k: float = p.y
	var w := sqrt(k)
	# 弧の 両はしは ちょうど y = k(水面)の 上に ある。
	# そこへ 同じ点を もう一度 足していたので、多角形に 重なった点が 2 組でき、
	# Godot の 三角形分割が 失敗して 塗りが まるごと 消えていた
	var region: Array = _parab_pts(-w, w)
	return {"shapes": [
		ProblemGen.grid(Vector2(-3.4, -0.5), Vector2(3.4, 10.0)),
		ProblemGen.axes(Vector2(-3.4, -0.5), Vector2(3.4, 10.0)),
		ProblemGen.poly(region, ProblemGen.FILL_ACCENT, null, 0.0),
		ProblemGen.curve(_parab_pts(-3.2, 3.2), WHITE, 3.5),
		ProblemGen.seg(Vector2(-3.2, k), Vector2(3.2, k), GOLD, 3.0),
		ProblemGen.label(Vector2(0.0, k * 0.45), "面積 %.2f" % (pow(2.0 * w, 3.0) / 6.0)),
		ProblemGen.label(Vector2(2.2, k + 0.7), "水面 y = %.1f" % k),
		ProblemGen.label(Vector2(0.0, -1.4), "交点の差 %.2f" % (2.0 * w)),
	]}


static func _parabola_proof() -> Dictionary:
	var k := 4.0
	var w := sqrt(k)
	# 弧の 両はしが そのまま 水面の 上。閉じる 点は 足さない(上と 同じ)
	var region: Array = _parab_pts(-w, w)
	return {"shapes": [
		ProblemGen.axes(Vector2(-3.4, -0.5), Vector2(3.4, 8.0)),
		ProblemGen.poly(region, ProblemGen.FILL_ACCENT, null, 0.0),
		ProblemGen.curve(_parab_pts(-3.0, 3.0), WHITE, 3.5),
		ProblemGen.seg(Vector2(-3.0, k), Vector2(3.0, k), GOLD, 3.0),
		ProblemGen.label(Vector2(-w, k + 0.8), "α"),
		ProblemGen.label(Vector2(w, k + 0.8), "β"),
		ProblemGen.label(Vector2(0.0, -1.5), "面積 = (β − α)³ ÷ 6"),
	]}
