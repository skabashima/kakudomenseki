class_name StoryTasks
## ストーリーの「使ってみる」場面で出す依頼。
##
## ■ 本編の問題をそのまま出してはいけない
## 「直線 l と m は平行です。折れ線の角 x は何度ですか」を出すと、
## 本編とまったく同じ画面になり、章の物語も、直前に自分で見つけた関係も、
## どこにも効いてこない。**その章の依頼として書き直す**こと。
##   × 直線 l と m は平行です。折れ線の角 x は何度ですか
##   ○ 足場が無くて曲がり角には登れない。上下の角だけ測ってきた。梁は何度で切る?
##
## 数値は毎回変わる(rng)。図もその数値どおりに描く。
## 戻り値: {"q": 問題文, "answer": 正解, "unit": 単位, "tol": 許容差, "fig": 図}

const GOLD := Color(1.0, 0.85, 0.3)
const WHITE := Color(0.92, 0.95, 1.0)
const DIM := Color(0.62, 0.72, 0.88)


static func make(kind: String, rng: RandomNumberGenerator) -> Dictionary:
	match kind:
		"triangle":
			return _t_triangle(rng)
		"zigzag":
			return _t_zigzag(rng)
		"circle":
			return _t_circle(rng)
		"equal_area":
			return _t_equal_area(rng)
		"pythagoras":
			return _t_pythagoras(rng)
		"inscribed":
			return _t_inscribed(rng)
		"similar":
			return _t_similar(rng)
		"sine_law":
			return _t_sine_law(rng)
		"area_sin":
			return _t_area_sin(rng)
		"parabola":
			return _t_parabola(rng)
	return {"q": "", "answer": 0.0, "unit": "", "tol": 0.01, "fig": {"shapes": []}}


## 第1章 石碑が欠けた畑の角(内角の和)
static func _t_triangle(rng: RandomNumberGenerator) -> Dictionary:
	var b := rng.randi_range(35, 75)
	var c := rng.randi_range(35, 75)
	var pts: Array = ProblemGen.tri_from_angles(float(b), float(c), 10.0)
	return {
		"q": "農夫の畑。読める角は %d 度と %d 度だけで、残りひとつは石碑が欠けている。"
			% [b, c] + "杭を打ち直すには、あと何度と分かればいい?",
		"answer": float(180 - b - c), "unit": "度", "tol": 0.5,
		"fig": {"shapes": [
			ProblemGen.poly(pts, ProblemGen.FILL_MAIN, WHITE, 4.0),
			ProblemGen.ang(pts[1], pts[2], pts[0], "%d°" % b, 1.8),
			ProblemGen.ang(pts[2], pts[0], pts[1], "%d°" % c, 1.8),
			ProblemGen.ang(pts[0], pts[1], pts[2], "?", 1.8),
			ProblemGen.label(pts[0] + Vector2(0.0, 1.0), "欠けた石碑"),
		]}}


## 第2章 登れない曲がり角(折れ角 = 上 + 下)
static func _t_zigzag(rng: RandomNumberGenerator) -> Dictionary:
	var up := rng.randi_range(18, 48)
	var low := rng.randi_range(18, 48)
	var hi := StoryDefs.ZIG_HIGH
	var lo := StoryDefs.ZIG_LOW
	var d1 := Vector2(-cos(deg_to_rad(float(up))), -sin(deg_to_rad(float(up))))
	var d2 := Vector2(-cos(deg_to_rad(float(low))), sin(deg_to_rad(float(low))))
	var p := _cross(hi, d1, lo, d2)
	return {
		"q": "曲がり角には足場が無くて登れない。壁ぎわで測れたのは上の角 %d 度と下の角 %d 度だけだ。"
			% [up, low] + "大工に伝える梁の角は何度?",
		"answer": float(up + low), "unit": "度", "tol": 0.5,
		"fig": {"shapes": [
			ProblemGen.seg(Vector2(-8.0, 0.0), Vector2(14.0, 0.0), WHITE, 4.0),
			ProblemGen.seg(Vector2(-8.0, 8.0), Vector2(14.0, 8.0), WHITE, 4.0),
			ProblemGen.seg(hi, p, GOLD, 3.5),
			ProblemGen.seg(p, lo, GOLD, 3.5),
			ProblemGen.ang(hi, Vector2(-8.0, 8.0), p, "%d°" % up, 1.8),
			ProblemGen.ang(lo, p, Vector2(-8.0, 0.0), "%d°" % low, 1.8),
			ProblemGen.ang(p, lo, hi, "?", 1.8),
			ProblemGen.label(Vector2(-6.0, 8.8), "上の壁"),
			ProblemGen.label(Vector2(-6.0, -0.9), "下の壁"),
		]}}


## 第3章 車輪にはめる鉄の輪(円周 = 直径 × 3.14)
static func _t_circle(rng: RandomNumberGenerator) -> Dictionary:
	var d := rng.randi_range(6, 24) * 2
	var r := float(d) * 0.5
	return {
		"q": "さしわたし %d cm の車輪に、ふちを一周する鉄の輪をはめたい。" % d
			+ "鉄は何 cm 切ればいい? 円周率は 3.14 とする。",
		"answer": float(d) * 3.14, "unit": "cm", "tol": 0.05,
		"fig": {"shapes": [
			ProblemGen.circle(Vector2.ZERO, r, ProblemGen.FILL_MAIN, WHITE, 4.0),
			ProblemGen.seg(Vector2(-r, 0.0), Vector2(r, 0.0), GOLD, 3.0),
			ProblemGen.label(Vector2(0.0, -r * 0.22), "さしわたし %d cm" % d),
			ProblemGen.label(Vector2(0.0, r + 1.2), "ここに鉄の輪をはめる"),
		]}}


## 第4章 兄弟の畑(底辺と高さが同じなら面積は同じ)
static func _t_equal_area(rng: RandomNumberGenerator) -> Dictionary:
	var base := rng.randi_range(6, 16)
	var h := rng.randi_range(4, 12)
	var shift := rng.randf_range(-3.0, 5.0)
	return {
		"q": "兄の畑は頂点が右に寄り、弟の畑は左に寄っている。どちらも底辺 %d m、高さ %d m。"
			% [base, h] + "一人分の広さは何 m²?",
		"answer": float(base) * float(h) * 0.5, "unit": "m²", "tol": 0.05,
		"fig": {"shapes": [
			ProblemGen.seg(Vector2(-4.0, float(h)), Vector2(float(base) + 5.0, float(h)),
				DIM, 2.5, true),
			ProblemGen.poly([Vector2(float(base) * 0.5 + shift, float(h)),
				Vector2.ZERO, Vector2(float(base), 0.0)], ProblemGen.FILL_MAIN, WHITE, 4.0),
			ProblemGen.seg(Vector2(float(base) * 0.5 + shift, float(h)),
				Vector2(float(base) * 0.5 + shift, 0.0), GOLD, 2.5, true),
			ProblemGen.side_label(Vector2.ZERO, Vector2(float(base), 0.0),
				"底辺 %d m" % base, -1.0, 0.9),
			ProblemGen.label(Vector2(float(base) * 0.5 + shift + 1.4, float(h) * 0.5),
				"高さ %d m" % h),
		]}}


## 第5章 土台の筋交い(三平方)
static func _t_pythagoras(rng: RandomNumberGenerator) -> Dictionary:
	var sets := [[3, 4, 5], [6, 8, 10], [5, 12, 13], [9, 12, 15], [8, 15, 17], [7, 24, 25]]
	var s: Array = sets[rng.randi_range(0, sets.size() - 1)]
	var a := float(s[0])
	var b := float(s[1])
	return {
		"q": "土台の直角を出す。柱から %d 尺、もう一方へ %d 尺のところに印をつけた。"
			% [int(a), int(b)] + "この二点を結ぶ筋交いは何尺で切ればいい?",
		"answer": float(s[2]), "unit": "尺", "tol": 0.05,
		"fig": {"shapes": [
			ProblemGen.poly([Vector2.ZERO, Vector2(a, 0.0), Vector2(0.0, b)],
				ProblemGen.FILL_MAIN, WHITE, 4.0),
			ProblemGen.right(Vector2.ZERO, Vector2(a, 0.0), Vector2(0.0, b)),
			ProblemGen.side_label(Vector2.ZERO, Vector2(a, 0.0), "%d 尺" % int(a), -1.0, 0.9),
			ProblemGen.side_label(Vector2.ZERO, Vector2(0.0, b), "%d 尺" % int(b), -1.0, 0.9),
			ProblemGen.side_label(Vector2(a, 0.0), Vector2(0.0, b), "筋交い ?", 1.0, 0.9),
		]}}


## 第6章 券の値段(円周角は中心角の半分)
static func _t_inscribed(rng: RandomNumberGenerator) -> Dictionary:
	var cen := rng.randi_range(20, 78) * 2
	var e := StoryDefs.chord_ends()
	var a := Vector2(cos(deg_to_rad(95.0)), sin(deg_to_rad(95.0))) * StoryDefs.R_CIRCLE
	return {
		"q": "舞台の端から端を、中心から見ると %d 度だった。" % cen
			+ "客席から見こむ角は何度? これが同じなら、券は同じ値段でいい。",
		"answer": float(cen) * 0.5, "unit": "度", "tol": 0.5,
		"fig": {"shapes": [
			ProblemGen.circle(Vector2.ZERO, StoryDefs.R_CIRCLE, null, DIM, 3.0),
			ProblemGen.poly([a, e[0], e[1]], ProblemGen.FILL_MAIN, WHITE, 3.5),
			ProblemGen.seg(Vector2.ZERO, e[0], DIM, 2.5, true),
			ProblemGen.seg(Vector2.ZERO, e[1], DIM, 2.5, true),
			ProblemGen.ang(Vector2.ZERO, e[1], e[0], "%d°" % cen, 1.6),
			ProblemGen.ang(a, e[0], e[1], "?", 1.6),
			ProblemGen.label(a + a.normalized() * 1.1, "客席"),
			ProblemGen.side_label(e[0], e[1], "舞台", -1.0, 0.8),
		]}}


## 第7章 帆の布(面積比は相似比の 2 乗)
static func _t_similar(rng: RandomNumberGenerator) -> Dictionary:
	var k := rng.randi_range(2, 4)
	var cloth := rng.randi_range(6, 20) * 2
	var small := StoryDefs.tri_shape(1.0)
	var big := StoryDefs.tri_shape(float(k))
	return {
		"q": "いまの帆に布が %d 反かかっている。長さを %d 倍にした帆を張りたい。"
			% [cloth, k] + "布は何反いる?",
		"answer": float(cloth * k * k), "unit": "反", "tol": 0.05,
		"fig": {"shapes": [
			ProblemGen.poly(big, ProblemGen.FILL_SUB, GOLD, 3.5),
			ProblemGen.poly(small, ProblemGen.FILL_MAIN, WHITE, 3.5),
			ProblemGen.label(Vector2(1.4, 1.0), "いま %d 反" % cloth),
			ProblemGen.label(Vector2(float(k) * 2.2, float(k) * 2.4), "%d 倍の帆 ?" % k),
		]}}


## 第8章 星をつなぐ円(正弦定理)
static func _t_sine_law(rng: RandomNumberGenerator) -> Dictionary:
	var ang: int = [30, 90, 150][rng.randi_range(0, 2)]
	var side := rng.randi_range(4, 12)
	var e := StoryDefs.chord_ends()
	var a := Vector2(cos(deg_to_rad(100.0)), sin(deg_to_rad(100.0))) * StoryDefs.R_CIRCLE
	return {
		"q": "二つの星の隔たりは %d、その向かいの角は %d 度と測れた。" % [side, ang]
			+ "三つの星を通る円の直径はいくつ? sin30° = 0.5、sin90° = 1、sin150° = 0.5 とする。",
		"answer": float(side) / (0.5 if ang != 90 else 1.0), "unit": "", "tol": 0.05,
		"fig": {"shapes": [
			ProblemGen.circle(Vector2.ZERO, StoryDefs.R_CIRCLE, null, DIM, 3.0),
			ProblemGen.poly([a, e[0], e[1]], ProblemGen.FILL_MAIN, WHITE, 3.5),
			ProblemGen.ang(a, e[0], e[1], "%d°" % ang, 1.8),
			ProblemGen.side_label(e[0], e[1], "%d" % side, -1.0, 0.8),
			ProblemGen.label(Vector2(0.0, 0.9), "直径 ?"),
		]}}


## 第9章 崖の上の土地(½ab sin C)
static func _t_area_sin(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(6, 16)
	var b := rng.randi_range(6, 16)
	var tbl := [[30, 0.5], [90, 1.0], [150, 0.5]]
	var pick: Array = tbl[rng.randi_range(0, tbl.size() - 1)]
	var deg := int(pick[0])
	var sn := float(pick[1])
	var c0 := Vector2.ZERO
	var b0 := Vector2(float(a), 0.0)
	var ap := Vector2(cos(deg_to_rad(float(deg))), sin(deg_to_rad(float(deg)))) * float(b)
	return {
		"q": "崖の上の土地。二辺は %d m と %d m、そのはさむ角は %d 度。高さは測れない。"
			% [a, b, deg] + "広さは何 m²? sin%d° = %s とする。" % [deg, ProblemGen.fmt(sn)],
		"answer": 0.5 * float(a) * float(b) * sn, "unit": "m²", "tol": 0.05,
		"fig": {"shapes": [
			ProblemGen.poly([c0, b0, ap], ProblemGen.FILL_MAIN, WHITE, 4.0),
			ProblemGen.ang(c0, b0, ap, "%d°" % deg, 1.8),
			ProblemGen.side_label(c0, b0, "%d m" % a, -1.0, 0.9),
			ProblemGen.side_label(c0, ap, "%d m" % b, 1.0, 0.9),
			ProblemGen.label(Vector2(float(a) * 0.5, -2.0), "広さ ?"),
		]}}


## 第10章 噴水の石(6分の1公式)
static func _t_parabola(rng: RandomNumberGenerator) -> Dictionary:
	var w := rng.randi_range(2, 6)
	var half := float(w) * 0.5
	var k := half * half
	var region: Array = []
	var n := 30
	for i in n + 1:
		var x := -half + 2.0 * half * float(i) / float(n)
		region.append(Vector2(x, x * x))
	region.append(Vector2(half, k))
	region.append(Vector2(-half, k))
	return {
		"q": "噴水の水が描く放物線を、水面が切り取っている。水面との交点の隔たりは %d m。" % w
			+ "石を敷く面積は何 m²? (交点の差)³ ÷ 6 で出る。",
		"answer": pow(float(w), 3.0) / 6.0, "unit": "m²", "tol": 0.05,
		"fig": {"shapes": [
			ProblemGen.axes(Vector2(-half - 1.5, -0.5), Vector2(half + 1.5, k + 2.0)),
			ProblemGen.poly(region, ProblemGen.FILL_ACCENT, null, 0.0),
			ProblemGen.curve(_parab(-half - 1.0, half + 1.0), WHITE, 3.5),
			ProblemGen.seg(Vector2(-half - 1.0, k), Vector2(half + 1.0, k), GOLD, 3.0),
			ProblemGen.label(Vector2(0.0, k + 1.2), "水面"),
			ProblemGen.label(Vector2(0.0, -1.3), "交点の隔たり %d m" % w),
		]}}


static func _parab(from_x: float, to_x: float) -> Array:
	var pts: Array = []
	var n := 30
	for i in n + 1:
		var x := from_x + (to_x - from_x) * float(i) / float(n)
		pts.append(Vector2(x, x * x))
	return pts


## 2 直線 (p + s*d1) と (q + t*d2) の交点
static func _cross(p: Vector2, d1: Vector2, q: Vector2, d2: Vector2) -> Vector2:
	var den := d1.x * d2.y - d1.y * d2.x
	if absf(den) < 0.0001:
		return p
	var s := ((q.x - p.x) * d2.y - (q.y - p.y) * d2.x) / den
	return p + d1 * s
