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
		"tank":
			return _t_tank(rng)
		"shadow":
			return _t_shadow(rng)
		"overlap":
			return _t_overlap(rng)
		"box_diag":
			return _t_box_diag(rng)
		"cube_scale":
			return _t_cube_scale(rng)
		"cone_net":
			return _t_cone_net(rng)
		"power":
			return _t_power(rng)
		"ceva":
			return _t_ceva(rng)
		"polygon":
			return _t_polygon(rng)
		"dart":
			return _t_dart(rng)
		"fold":
			return _t_fold(rng)
		"road":
			return _t_road(rng)
		"star":
			return _t_star(rng)
		"tangent_chord":
			return _t_tangent_chord(rng)
		"special_tri":
			return _t_special_tri(rng)
		"euler":
			return _t_euler(rng)
		"cosine":
			return _t_cosine(rng)
		"incenter":
			return _t_incenter(rng)
		"radian":
			return _t_radian(rng)
		"circle_eq":
			return _t_circle_eq(rng)
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
	# 弧の 両はしは ちょうど 水面(y = k)の 上。同じ点を もう一度 足すと
	# 多角形の 三角形分割が 失敗して、塗った 面が 出なくなる
	var region: Array = []
	var n := 30
	for i in n + 1:
		var x := -half + 2.0 * half * float(i) / float(n)
		region.append(Vector2(x, x * x))
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


## 第11章 水そうに水を移す(底面積 × 深さ = 水の量)
static func _t_tank(rng: RandomNumberGenerator) -> Dictionary:
	var w := rng.randi_range(4, 12)
	var d := rng.randi_range(3, 8)
	var depth := rng.randi_range(2, 9)
	var vol := w * d * depth
	var hh := float(depth) + 3.0
	return {
		"q": "村の水そうは 底が %d × %d。井戸から汲んだ水は %d ぶんある。" % [w, d, vol]
			+ "ふちから何をどれだけ空けておけばいいか知りたい ― 水はどこまで来る?",
		"answer": float(depth), "unit": "", "tol": 0.05,
		"fig": {"shapes": [
			ProblemGen.poly([Vector2(0, 0), Vector2(w, 0), Vector2(w, depth), Vector2(0, depth)],
				Color(0.3, 0.6, 0.95, 0.4), Color(0.55, 0.85, 1.0), 3.0),
			ProblemGen.seg(Vector2(0, hh), Vector2(0, 0), WHITE, 4.0),
			ProblemGen.seg(Vector2(0, 0), Vector2(w, 0), WHITE, 4.0),
			ProblemGen.seg(Vector2(w, 0), Vector2(w, hh), WHITE, 4.0),
			ProblemGen.label(Vector2(w * 0.5, -1.0), "幅 %d" % w, GOLD, 28),
			ProblemGen.label(Vector2(w * 0.5, depth * 0.5), "水 %d" % vol, DIM, 26),
			ProblemGen.label(Vector2(-1.6, depth), "?", GOLD, 30),
		]}}


## 第12章 影から高さを出す
static func _t_shadow(rng: RandomNumberGenerator) -> Dictionary:
	var pole := rng.randi_range(1, 4)
	var s_pole := rng.randi_range(2, 5)
	var mult := rng.randi_range(3, 9)
	var s_tower := s_pole * mult
	var tower := pole * mult
	return {
		"q": "塔の高さを知りたいが、登る手だてがない。同じ時刻に、%d の杭の影が %d、" % [pole, s_pole]
			+ "塔の影は %d だった。塔はどれくらいの高さか?" % s_tower,
		"answer": float(tower), "unit": "", "tol": 0.05,
		"fig": {"shapes": [
			ProblemGen.seg(Vector2(-1, 0), Vector2(float(s_tower) * 0.6 + 8.0, 0), WHITE, 4.0),
			ProblemGen.seg(Vector2(0, 0), Vector2(0, pole), GOLD, 4.5),
			ProblemGen.seg(Vector2(0, pole), Vector2(s_pole, 0), DIM, 2.5, true),
			ProblemGen.label(Vector2(-1.2, float(pole) * 0.5), "%d" % pole, GOLD, 26),
			ProblemGen.label(Vector2(float(s_pole) * 0.5, -1.1), "%d" % s_pole,
				Color(0.55, 0.85, 1.0), 26),
			ProblemGen.seg(Vector2(s_pole + 4.0, 0), Vector2(s_pole + 4.0, tower), GOLD, 4.5),
			ProblemGen.seg(Vector2(s_pole + 4.0, tower), Vector2(s_pole + 4.0 + s_tower, 0),
				DIM, 2.5, true),
			ProblemGen.label(Vector2(s_pole + 2.6, float(tower) * 0.5), "?", GOLD, 30),
			ProblemGen.label(Vector2(s_pole + 4.0 + float(s_tower) * 0.5, -1.1), "%d" % s_tower,
				Color(0.55, 0.85, 1.0), 26),
		]}}


## 第13章 動く板が戸口をふさぐ面積
static func _t_overlap(rng: RandomNumberGenerator) -> Dictionary:
	var speed := rng.randi_range(2, 6)
	var h := rng.randi_range(3, 9)
	var sec := rng.randi_range(2, 6)
	var moved := speed * sec
	var area := moved * h
	return {
		"q": "荷車の板が、毎秒 %d ずつ戸口の前を横切っていく。板のたては %d。" % [speed, h]
			+ "%d 秒たった今、戸口はどれだけふさがれている?" % sec,
		"answer": float(area), "unit": "", "tol": 0.5,
		"fig": {"shapes": [
			ProblemGen.poly([Vector2(0, 0), Vector2(moved + 4.0, 0), Vector2(moved + 4.0, h),
				Vector2(0, h)], ProblemGen.FILL_MAIN, WHITE, 3.0),
			ProblemGen.poly([Vector2(0, 0), Vector2(moved, 0), Vector2(moved, h), Vector2(0, h)],
				ProblemGen.FILL_ACCENT, GOLD, 3.0),
			ProblemGen.arrow(Vector2(-3.0, float(h) * 0.5), Vector2(-0.8, float(h) * 0.5), GOLD),
			ProblemGen.label(Vector2(float(moved) * 0.5, float(h) * 0.5), "?", GOLD, 30),
			ProblemGen.label(Vector2(float(moved) * 0.5, -1.1), "毎秒 %d × %d 秒" % [speed, sec],
				Color(0.55, 0.85, 1.0), 26),
			ProblemGen.label(Vector2(-1.4, float(h) * 0.5), "%d" % h, GOLD, 26),
			ProblemGen.label(Vector2(float(moved) + 2.0, float(h) + 1.0), "戸口", DIM, 24),
		]}}


## 第14章 倉に渡す梁(直方体の対角線)
static func _t_box_diag(rng: RandomNumberGenerator) -> Dictionary:
	var sets: Array = [[1, 2, 2, 3], [2, 3, 6, 7], [4, 4, 7, 9], [3, 4, 12, 13],
		[6, 6, 7, 11], [2, 6, 9, 11], [1, 4, 8, 9], [8, 9, 12, 17], [2, 10, 11, 15]]
	var s: Array = sets[rng.randi_range(0, sets.size() - 1)]
	var w: int = s[0]
	var d: int = s[1]
	var h: int = s[2]
	var diag: int = s[3]
	var out: Array = StoryFigs2._box_frame(float(w), float(d), float(h))
	out += [
		ProblemGen.seg(ProblemGen.proj3(Vector3.ZERO), ProblemGen.proj3(Vector3(w, d, h)),
			GOLD, 4.0),
		ProblemGen.label(ProblemGen.proj3(Vector3(float(w) * 0.5, 0, 0)) + Vector2(0, -1.1),
			"%d" % w, DIM, 26),
		ProblemGen.label(ProblemGen.proj3(Vector3(w, float(d) * 0.5, 0)) + Vector2(1.2, -0.8),
			"%d" % d, DIM, 26),
		ProblemGen.label(ProblemGen.proj3(Vector3(w, d, float(h) * 0.5)) + Vector2(1.3, 0),
			"%d" % h, DIM, 26),
		ProblemGen.label(ProblemGen.proj3(Vector3(float(w) * 0.4, float(d) * 0.4, float(h) * 0.6))
			+ Vector2(-1.2, 0.6), "?", GOLD, 30),
	]
	return {
		"q": "倉のすみからすみへ、斜めに梁を一本渡したい。倉は よこ %d・おくゆき %d・高さ %d。" % [w, d, h]
			+ "梁は何ぶんの長さに切ればいい?",
		"answer": float(diag), "unit": "", "tol": 0.05,
		"fig": {"shapes": out}}


## 第15章 同じ形の樽(長さの比と入る量の比)
static func _t_cube_scale(rng: RandomNumberGenerator) -> Dictionary:
	var sets: Array = [[2, 8], [3, 27], [4, 64], [5, 125]]
	var s: Array = sets[rng.randi_range(0, sets.size() - 1)]
	var k: int = s[0]
	var cube: int = s[1]
	var small := rng.randi_range(2, 9)
	var big := small * cube
	var b := Vector3(3.0, 2.0, 2.0)
	var out: Array = StoryFigs2._box_frame(b.x, b.y, b.z)
	var shift := Vector2(b.x * 1.6 + 3.0, 0)
	for sh in StoryFigs2._box_frame(b.x * k, b.y * k, b.z * k):
		var dd: Dictionary = sh
		out.append(ProblemGen.seg((dd["a"] as Vector2) + shift, (dd["b"] as Vector2) + shift,
			GOLD, 2.5, bool(dd.get("dash", false))))
	out += [
		ProblemGen.label(ProblemGen.proj3(Vector3(b.x * 0.5, 0, 0)) + Vector2(0, -1.2),
			"%d 入る" % small, DIM, 26),
		ProblemGen.label(ProblemGen.proj3(Vector3(b.x * k * 0.5, 0, 0)) + shift + Vector2(0, -1.2),
			"長さ %d 倍" % k, GOLD, 26),
		ProblemGen.label(ProblemGen.proj3(Vector3(b.x * k * 0.5, 0, b.z * k)) + shift
			+ Vector2(0, 1.2), "?", GOLD, 30),
	]
	return {
		"q": "樽づくりの親方が、いまの樽と同じ形で 長さだけ %d 倍の樽を注文された。" % k
			+ "いまの樽には %d 入る。大きい樽にはどれだけ入るか答えてやろう。" % small,
		"answer": float(big), "unit": "", "tol": 0.5,
		"fig": {"shapes": out}}


## 第16章 三角帽子の型紙(展開図の中心角)
static func _t_cone_net(rng: RandomNumberGenerator) -> Dictionary:
	var sets: Array = [[3, 5, 216], [2, 5, 144], [4, 5, 288], [2, 3, 240], [3, 4, 270],
		[5, 6, 300], [3, 8, 135], [5, 8, 225], [4, 9, 160], [5, 12, 150], [7, 12, 210]]
	var s: Array = sets[rng.randi_range(0, sets.size() - 1)]
	var r: int = s[0]
	var l: int = s[1]
	var ang: int = s[2]
	var lf := float(l)
	return {
		"q": "祭りの三角帽子を布から切り出す。かぶる口の半径は %d、横から見た斜めの辺は %d。" % [r, l]
			+ "布は何度のおうぎ形に切ればちょうど巻ける?",
		"answer": float(ang), "unit": "度", "tol": 0.5,
		"fig": {"shapes": [
			ProblemGen.sector(Vector2.ZERO, lf, 0.0, float(ang), ProblemGen.FILL_ACCENT, GOLD),
			ProblemGen.seg(Vector2.ZERO, Vector2(lf, 0), GOLD, 3.0),
			ProblemGen.ang(Vector2.ZERO, Vector2(lf, 0),
				Vector2(cos(deg_to_rad(float(ang))), sin(deg_to_rad(float(ang)))) * lf,
				"?", 1.7, ang > 180),
			ProblemGen.label(Vector2(lf * 0.5, -1.0), "斜めの辺 %d" % l, GOLD, 26),
			ProblemGen.circle(Vector2(lf + float(r) + 3.0, -float(r) - 1.0), float(r),
				ProblemGen.FILL_MAIN, WHITE, 3.0),
			ProblemGen.label(Vector2(lf + float(r) + 3.0, -2.0 * float(r) - 2.4),
				"かぶる口 半径 %d" % r, DIM, 26),
		]}}


## 第17章 池ごしに渡す板(方べきの定理)
static func _t_power(rng: RandomNumberGenerator) -> Dictionary:
	var sets: Array = [[3, 8, 4], [4, 6, 3], [2, 18, 4], [6, 6, 4], [3, 12, 6],
		[4, 9, 6], [2, 24, 8], [6, 8, 4], [4, 12, 8], [3, 16, 6]]
	var s: Array = sets[rng.randi_range(0, sets.size() - 1)]
	var a: int = s[0]
	var b: int = s[1]
	var c: int = s[2]
	var ans := float(a * b) / float(c)
	var r := 4.5
	var pp := Vector2(-8.0, 0.0)
	var u1 := Vector2(cos(deg_to_rad(12.0)), sin(deg_to_rad(12.0)))
	var u2 := Vector2(cos(deg_to_rad(-14.0)), sin(deg_to_rad(-14.0)))
	return {
		"q": "丸い池の外の杭 P から、島へ板を渡す。1 本目の板は岸に %d と %d のところで当たった。" % [a, b]
			+ "2 本目は向きを変えて、近い岸まで %d だった。遠い岸まではどれだけある?" % c,
		"answer": ans, "unit": "", "tol": 0.05,
		"fig": {"shapes": [
			ProblemGen.circle(Vector2.ZERO, r, ProblemGen.FILL_MAIN, WHITE, 3.0),
			ProblemGen.seg(pp, pp + u1 * 13.0, GOLD, 3.0),
			ProblemGen.seg(pp, pp + u2 * 13.0, Color(0.55, 0.85, 1.0), 3.0),
			ProblemGen.label(pp + Vector2(-1.0, 0.0), "P", GOLD, 28),
			ProblemGen.label(pp + u1 * 4.5 + Vector2(0, 0.9), "%d" % a, GOLD, 26),
			ProblemGen.label(pp + u1 * 10.5 + Vector2(0, 0.9), "%d" % b, GOLD, 26),
			ProblemGen.label(pp + u2 * 4.5 + Vector2(0, -1.0), "%d" % c,
				Color(0.55, 0.85, 1.0), 26),
			ProblemGen.label(pp + u2 * 10.5 + Vector2(0, -1.0), "?", GOLD, 30),
			ProblemGen.label(Vector2(0, -r - 1.4), "池", DIM, 24),
		]}}


## 第18章 一点で交わる三本の綱(チェバの定理)
static func _t_ceva(rng: RandomNumberGenerator) -> Dictionary:
	var f1 := rng.randi_range(1, 4)
	var f2 := rng.randi_range(1, 4)
	var d1 := rng.randi_range(1, 4)
	var d2 := rng.randi_range(1, 4)
	var ans := (float(f2) / float(f1)) * (float(d2) / float(d1))
	var a := StoryDefs.CEVA_A
	var b := StoryDefs.CEVA_B
	var c := StoryDefs.CEVA_C
	var f := a + (b - a) * (float(f1) / float(f1 + f2))
	var d := b + (c - b) * (float(d1) / float(d1 + d2))
	var o := _cross(a, d - a, c, f - c)
	var e := _cross(b, o - b, c, a - c)
	return {
		"q": "見張り台をつなぐ綱を三本、一点で交わるように張る。二本の張り方は決まっていて、"
			+ "AF:FB = %d:%d、BD:DC = %d:%d。残る一本の CE:EA を x:1 で伝えたい ― x はいくつか?" % [
				f1, f2, d1, d2],
		"answer": ans, "unit": "", "tol": 0.02,
		"fig": {"shapes": [
			ProblemGen.poly([a, b, c], ProblemGen.FILL_MAIN, WHITE, 3.5),
			ProblemGen.seg(a, d, GOLD, 3.0),
			ProblemGen.seg(c, f, GOLD, 3.0),
			ProblemGen.seg(b, e, Color(0.55, 0.85, 1.0), 3.0, true),
			ProblemGen.circle(o, 0.22, GOLD, null, 0.0),
			ProblemGen.label(a + Vector2(0, 0.9), "A"),
			ProblemGen.label(b + Vector2(-0.8, -0.6), "B"),
			ProblemGen.label(c + Vector2(0.8, -0.6), "C"),
			ProblemGen.label(f + Vector2(-1.0, 0.2), "F", GOLD, 24),
			ProblemGen.label(d + Vector2(0, -1.0), "D", GOLD, 24),
			ProblemGen.label(e + Vector2(1.0, 0.2), "E", Color(0.55, 0.85, 1.0), 24),
			ProblemGen.label((a + f) * 0.5 + Vector2(-1.4, 0.2), "%d:%d" % [f1, f2], DIM, 24),
			ProblemGen.label((b + d) * 0.5 + Vector2(0, -1.1), "%d:%d" % [d1, d2], DIM, 24),
			ProblemGen.label((c + e) * 0.5 + Vector2(1.4, 0.2), "x:1", GOLD, 26),
		]}}


## 五角形の飾り窓(内角の和)
static func _t_polygon(rng: RandomNumberGenerator) -> Dictionary:
	var known: Array = []
	var rest := 540
	for i in 4:
		var v := rng.randi_range(80, 130)
		known.append(v)
		rest -= v
	while rest < 60 or rest > 170:
		known[3] = int(known[3]) + (1 if rest > 170 else -1)
		rest = 540 - int(known[0]) - int(known[1]) - int(known[2]) - int(known[3])
	var pts: Array = StoryDefs.penta_points(Vector2(0.0, 7.0))
	var out: Array = [ProblemGen.poly(pts, ProblemGen.FILL_MAIN, WHITE, 3.5)]
	for i in 5:
		var txt := "?" if i == 0 else "%d°" % int(known[i - 1])
		out.append(ProblemGen.ang(pts[i], pts[(i + 4) % 5], pts[(i + 1) % 5], txt, 1.6))
	return {
		"q": "五角形の飾り窓に鉄の骨を入れる。読めるのは %d°・%d°・%d°・%d° の 4 か所だけで、"
			% [known[0], known[1], known[2], known[3]]
			+ "残る 1 か所は塗りつぶされている。そこは何度で組めばいい?",
		"answer": float(rest), "unit": "度", "tol": 0.5,
		"fig": {"shapes": out}}


## 矢じり形の紋章(ブーメラン形)
static func _t_dart(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(30, 70)
	var b := rng.randi_range(20, 50)
	var c := rng.randi_range(20, 50)
	var x := a + b + c
	var pa := StoryDefs.DART_A
	var pb := StoryDefs.DART_B
	var pc := StoryDefs.DART_C
	var pp := Vector2(0.0, 1.0)
	return {
		"q": "矢じりの形をした紋章を鋳型で作る。先の角が %d°、左右の角が %d° と %d°。" % [a, b, c]
			+ "へこんだところは何度で彫ればいい?",
		"answer": float(x), "unit": "度", "tol": 0.5,
		"fig": {"shapes": [
			ProblemGen.poly([pa, pb, pp, pc], ProblemGen.FILL_MAIN, WHITE, 3.5),
			ProblemGen.ang(pa, pb, pc, "%d°" % a, 1.8),
			ProblemGen.ang(pb, pa, pp, "%d°" % b, 1.8),
			ProblemGen.ang(pc, pp, pa, "%d°" % c, 1.8),
			ProblemGen.ang(pp, pb, pc, "?", 1.6),
		]}}


## テープの折り返し
static func _t_fold(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(30, 70)
	var x := 180 - 2 * a
	var h := StoryDefs.TAPE_H
	var f := Vector2.ZERO
	var g := Vector2(h / tan(deg_to_rad(float(a))), h)
	var dir := Vector2(cos(deg_to_rad(180.0 + 2.0 * float(a))),
		sin(deg_to_rad(180.0 + 2.0 * float(a))))
	var k := g + dir * (h / maxf(absf(dir.y), 0.0001))
	return {
		"q": "帯を斜めに一度だけ折って、包みのふたにする。折り目が帯のふちと作る角は %d°。" % a
			+ "折り返した辺は、ふちと何度で交わることになる?",
		"answer": float(x), "unit": "度", "tol": 0.5,
		"fig": {"shapes": [
			ProblemGen.seg(Vector2(-10.0, 0), Vector2(10.0, 0), WHITE, 4.0),
			ProblemGen.seg(Vector2(-10.0, h), Vector2(10.0, h), WHITE, 4.0),
			ProblemGen.poly([f, g, k], ProblemGen.FILL_ACCENT, GOLD, 3.0),
			ProblemGen.ang(f, Vector2(6.0, 0), g, "%d°" % a, 1.7),
			ProblemGen.ang(k, Vector2(-8.0, 0), g, "?", 1.7),
		]}}


## 畑に通す道
static func _t_road(rng: RandomNumberGenerator) -> Dictionary:
	var w := rng.randi_range(8, 20)
	var h := rng.randi_range(6, 15)
	var rw := rng.randi_range(1, 3)
	var rest := (w - rw) * (h - rw)
	var rx := float(rng.randi_range(2, w - rw - 2))
	var ry := float(rng.randi_range(2, h - rw - 2))
	var road := Color(0.55, 0.50, 0.42, 0.75)
	return {
		"q": "%d × %d の畑に、はば %d の道をたてとよこに 1 本ずつ通す。" % [w, h, rw]
			+ "道を引いたあと、畑として残るのはどれだけか?",
		"answer": float(rest), "unit": "", "tol": 0.5,
		"fig": {"shapes": [
			ProblemGen.poly([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)],
				ProblemGen.FILL_SUB, WHITE, 3.5),
			ProblemGen.poly([Vector2(rx, 0), Vector2(rx + rw, 0), Vector2(rx + rw, h),
				Vector2(rx, h)], road, null, 0.0),
			ProblemGen.poly([Vector2(0, ry), Vector2(w, ry), Vector2(w, ry + rw),
				Vector2(0, ry + rw)], road, null, 0.0),
			ProblemGen.label(Vector2(float(w) * 0.5, -1.2), "%d × %d、道のはば %d" % [w, h, rw],
				DIM, 26),
			ProblemGen.label(Vector2(rx * 0.5, ry * 0.5), "?", GOLD, 30),
		]}}


## 星形の飾り
static func _t_star(rng: RandomNumberGenerator) -> Dictionary:
	var known: Array = []
	var rest := 180
	for i in 4:
		var v := rng.randi_range(20, 45)
		known.append(v)
		rest -= v
	while rest < 15 or rest > 60:
		known[3] = int(known[3]) + (1 if rest > 60 else -1)
		rest = 180 - int(known[0]) - int(known[1]) - int(known[2]) - int(known[3])
	var pts: Array = StoryDefs.star_points(Vector2(0.0, StoryDefs.STAR_R))
	var order: Array = [pts[0], pts[2], pts[4], pts[1], pts[3]]
	# 塗りは 交点を 入れた 10 点の 外わくで。5 点の ままだと 自分と 交わって 塗れない
	var out: Array = [
		ProblemGen.poly(StoryDefs.star_outline(Vector2(0.0, StoryDefs.STAR_R)),
			ProblemGen.FILL_MAIN, null, 0.0),
		ProblemGen.poly(order, null, GOLD, 3.0)]
	for i in 5:
		var txt := "?" if i == 0 else "%d°" % int(known[i - 1])
		out.append(ProblemGen.ang(pts[i], pts[(i + 2) % 5], pts[(i + 3) % 5], txt, 1.5))
	return {
		"q": "祭りの星形の飾りを、五本の板を組んで作る。とがった先のうち 4 つは "
			+ "%d°・%d°・%d°・%d° に切ってある。最後の一本は何度に切る?" % [
				known[0], known[1], known[2], known[3]],
		"answer": float(rest), "unit": "度", "tol": 0.5,
		"fig": {"shapes": out}}


## 岸に接する道(接弦定理)
static func _t_tangent_chord(rng: RandomNumberGenerator) -> Dictionary:
	var deg := rng.randi_range(25, 75)
	var r := StoryDefs.TC_R
	var t := Vector2(0.0, -r)
	var b := Vector2(0.0, r)
	var a := Vector2(cos(deg_to_rad(90.0 - 2.0 * float(deg))),
		sin(deg_to_rad(90.0 - 2.0 * float(deg)))) * r
	return {
		"q": "円い堀のふちに、接するように道が走っている。道と、接点から対岸の杭 A へ張った縄との角が"
			+ " %d°。堀の向こう側の点 B から同じ縄を見こむ角は、どれだけになる?" % deg,
		"answer": float(deg), "unit": "度", "tol": 0.5,
		"fig": {"shapes": [
			ProblemGen.circle(Vector2.ZERO, r, ProblemGen.FILL_MAIN, WHITE, 3.0),
			ProblemGen.seg(Vector2(-r - 3.0, -r), Vector2(r + 3.0, -r), Color(0.55, 0.85, 1.0), 3.5),
			ProblemGen.seg(t, a, GOLD, 3.5),
			ProblemGen.seg(b, t, DIM, 2.5),
			ProblemGen.seg(b, a, DIM, 2.5),
			ProblemGen.ang(t, Vector2(r + 3.0, -r), a, "%d°" % deg, 1.6),
			ProblemGen.ang(b, t, a, "?", 1.6),
			ProblemGen.label(t + Vector2(-0.2, -1.1), "接点", Color(0.55, 0.85, 1.0), 24),
			ProblemGen.label(a + Vector2(0.8, 0.5), "A", GOLD, 26),
			ProblemGen.label(b + Vector2(0.0, 0.9), "B", DIM, 26),
		]}}


## 屋根の勾配(30-60-90 の比)
static func _t_special_tri(rng: RandomNumberGenerator) -> Dictionary:
	var short_side := rng.randi_range(2, 12)
	var hyp := short_side * 2
	var long_side := float(short_side) * 1.73
	var b := Vector2.ZERO
	var c := Vector2(long_side, 0.0)
	var a := Vector2(long_side, float(short_side))
	return {
		"q": "屋根を 30° の勾配で葺く。棟から軒までの高さは %d。" % short_side
			+ "垂木は何ぶんの長さに切ればいい?",
		"answer": float(hyp), "unit": "", "tol": 0.05,
		"fig": {"shapes": [
			ProblemGen.poly([b, c, a], ProblemGen.FILL_MAIN, WHITE, 3.5),
			ProblemGen.right(c, b, a),
			ProblemGen.ang(b, c, a, "30°", 1.8),
			ProblemGen.side_label(c, a, "%d" % short_side, 1.0, 0.8),
			ProblemGen.side_label(b, a, "?", 1.0, 0.9),
		]}}


## 見張り小屋の骨組み(角柱の辺の数)
static func _t_euler(rng: RandomNumberGenerator) -> Dictionary:
	var n := rng.randi_range(3, 10)
	var ask_edge := rng.randf() < 0.6
	var ans := 3 * n if ask_edge else 2 * n
	var out: Array = StoryFigs3._prism(n, 4.0, 5.0, WHITE)
	out.append(ProblemGen.label(Vector2(0.0, 9.2), "%d 角柱" % n, GOLD, 30))
	return {
		"q": "見張り小屋を %d 角柱の形に組む。" % n
			+ ("材木は何本いるか(辺の数)、棟梁に伝えたい。" if ask_edge
				else "継ぎ手をいくつ作ればいいか(頂点の数)、鍛冶屋に伝えたい。"),
		"answer": float(ans), "unit": "", "tol": 0.05,
		"fig": {"shapes": out}}


## 向こう岸までの距離(余弦定理)
static func _t_cosine(rng: RandomNumberGenerator) -> Dictionary:
	var sets: Array = [[5, 8, 60, 7], [3, 8, 60, 7], [8, 15, 60, 13], [7, 15, 60, 13],
		[5, 21, 60, 19], [3, 5, 120, 7], [7, 8, 120, 13], [5, 16, 120, 19],
		[6, 10, 120, 14], [14, 16, 120, 26]]
	var s: Array = sets[rng.randi_range(0, sets.size() - 1)]
	var a: int = s[0]
	var b: int = s[1]
	var deg: int = s[2]
	var c: int = s[3]
	var pc := Vector2.ZERO
	var pb := Vector2(float(a), 0.0)
	var pa := Vector2(cos(deg_to_rad(float(deg))), sin(deg_to_rad(float(deg)))) * float(b)
	return {
		"q": "川の手前の一点から、両岸の杭までの距離が %d と %d、そのはさむ角が %d° と測れた。" % [
			a, b, deg] + "杭と杭のあいだ ― 川はばはどれだけある?",
		"answer": float(c), "unit": "", "tol": 0.05,
		"fig": {"shapes": [
			ProblemGen.poly([pa, pb, pc], ProblemGen.FILL_MAIN, WHITE, 3.5),
			ProblemGen.ang(pc, pb, pa, "%d°" % deg, 1.8),
			ProblemGen.side_label(pc, pb, "%d" % a, -1.0, 0.8),
			ProblemGen.side_label(pc, pa, "%d" % b, 1.0, 0.8),
			ProblemGen.side_label(pa, pb, "?", 1.0, 0.9),
		]}}


## 三方から等しい距離の井戸(内心の角)
static func _t_incenter(rng: RandomNumberGenerator) -> Dictionary:
	var a_deg := rng.randi_range(10, 25) * 4
	var ans := 90 + a_deg / 2
	var rest := 180 - a_deg
	var b_deg := rng.randi_range(int(rest * 0.4), int(rest * 0.6))
	var v: Array = ProblemGen.tri_from_angles(float(b_deg), float(rest - b_deg), 11.0)
	var inc := StoryDefs._incenter_of(v[0], v[1], v[2])
	return {
		"q": "三つの村から等しい距離になる場所に井戸を掘る。村を結ぶと三角形になり、"
			+ "頂点の村から見た角は %d°。井戸から残り二つの村を見こむ角はいくつになる?" % a_deg,
		"answer": float(ans), "unit": "度", "tol": 0.5,
		"fig": {"shapes": [
			ProblemGen.poly(v, ProblemGen.FILL_MAIN, WHITE, 3.5),
			ProblemGen.seg(v[1], inc, GOLD, 3.0),
			ProblemGen.seg(v[2], inc, GOLD, 3.0),
			ProblemGen.ang(v[0], v[1], v[2], "%d°" % a_deg, 1.8),
			ProblemGen.ang(inc, v[1], v[2], "?", 1.5),
			ProblemGen.label(inc + Vector2(0.0, -1.0), "井戸", GOLD, 24),
		]}}


## 巻き取り機(弧度法)
static func _t_radian(rng: RandomNumberGenerator) -> Dictionary:
	var r := rng.randi_range(2, 12)
	var th: float = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0][rng.randi_range(0, 5)]
	var ans := float(r) * th
	return {
		"q": "縄の巻き取り機。軸の半径は %d で、%s ラジアンだけ回した。" % [r, ProblemGen.fmt(th)]
			+ "縄はどれだけ出たか ― 印をつけて確かめたい。",
		"answer": ans, "unit": "", "tol": 0.05,
		"fig": {"shapes": [
			ProblemGen.sector(Vector2.ZERO, float(r), 0.0, rad_to_deg(th),
				ProblemGen.FILL_ACCENT, GOLD),
			ProblemGen.arc(Vector2.ZERO, float(r), 0.0, rad_to_deg(th),
				Color(0.55, 0.85, 1.0), 4.5),
			ProblemGen.seg(Vector2.ZERO, Vector2(r, 0), GOLD, 3.0),
			ProblemGen.label(Vector2(float(r) * 0.5, -1.0), "半径 %d" % r, GOLD, 26),
			ProblemGen.label(Vector2(cos(th * 0.5), sin(th * 0.5)) * (float(r) + 1.6), "?",
				Color(0.55, 0.85, 1.0), 30),
			ProblemGen.ang(Vector2.ZERO, Vector2(r, 0),
				Vector2(cos(th), sin(th)) * float(r), "%s rad" % ProblemGen.fmt(th), 1.5),
		]}}


## 円形の柵(円の方程式)
static func _t_circle_eq(rng: RandomNumberGenerator) -> Dictionary:
	var tri: Array = [[3, 4, 5], [6, 8, 10], [5, 12, 13], [8, 15, 17], [9, 12, 15], [7, 24, 25]]
	var t: Array = tri[rng.randi_range(0, tri.size() - 1)]
	var dx: int = t[0]
	var dy: int = t[1]
	var r: int = t[2]
	var cx := rng.randi_range(-4, 4)
	var cy := rng.randi_range(-4, 4)
	var px := cx + dx
	var py := cy + dy
	var c := Vector2(cx, cy)
	var p := Vector2(px, py)
	var lo := Vector2(minf(c.x, p.x) - float(r) - 1.0, minf(c.y, p.y) - float(r) - 1.0)
	var hi := Vector2(maxf(c.x, p.x) + float(r) + 1.0, maxf(c.y, p.y) + float(r) + 1.0)
	return {
		"q": "羊の囲いを円く作る。杭は (%d, %d) に打ってあり、囲いは (%d, %d) の木を通す。" % [
			cx, cy, px, py] + "縄はどれだけの長さがいる?",
		"answer": float(r), "unit": "", "tol": 0.05,
		"fig": {"shapes": [
			ProblemGen.grid(lo, hi), ProblemGen.axes(lo, hi),
			ProblemGen.circle(c, float(r), ProblemGen.FILL_MAIN, WHITE, 3.0),
			ProblemGen.seg(c, p, GOLD, 3.0),
			ProblemGen.seg(c, Vector2(p.x, c.y), Color(0.55, 0.85, 1.0), 2.5, true),
			ProblemGen.seg(Vector2(p.x, c.y), p, Color(0.55, 0.85, 1.0), 2.5, true),
			ProblemGen.right(Vector2(p.x, c.y), c, p),
			ProblemGen.label(c + Vector2(-1.2, -0.9), "杭", DIM, 24),
			ProblemGen.label(p + Vector2(0.8, 0.7), "木", GOLD, 26),
			ProblemGen.label((c + p) * 0.5 + Vector2(-0.6, 0.8), "?", GOLD, 30),
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
