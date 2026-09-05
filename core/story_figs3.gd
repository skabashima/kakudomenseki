class_name StoryFigs3
## ストーリーの第19章以降で使う図。
## 本編の単元のうち「動かして見つける」に向くものを章にしたぶん:
##   多角形の角・ブーメラン形・折り返し・道の面積・星形・接弦定理・
##   三角定規の比・多面体・余弦定理・内心・弧度法・円の方程式
## 作り方は core/story_figs.gd と同じ(measure は動かせる点 p を受け取る)。

const GOLD := Color(1.0, 0.85, 0.3)
const WHITE := Color(0.92, 0.95, 1.0)
const DIM := Color(0.62, 0.72, 0.88)
const SKY := Color(0.55, 0.85, 1.0)


static func spec(kind: String, p: Vector2) -> Dictionary:
	match kind:
		"polygon":
			return _polygon(p)
		"polygon_proof":
			return _polygon_proof()
		"dart":
			return _dart(p)
		"dart_proof":
			return _dart_proof()
		"fold":
			return _fold(p)
		"fold_proof":
			return _fold_proof()
		"road":
			return _road(p)
		"road_proof":
			return _road_proof()
		"star":
			return _star(p)
		"star_proof":
			return _star_proof()
		"tangent_chord":
			return _tangent_chord(p)
		"tangent_chord_proof":
			return _tangent_chord_proof()
		"special_tri":
			return _special_tri(p)
		"special_tri_proof":
			return _special_tri_proof()
		"euler":
			return _euler(p)
		"euler_proof":
			return _euler_proof()
		"cosine":
			return _cosine(p)
		"cosine_proof":
			return _cosine_proof()
		"incenter":
			return _incenter(p)
		"incenter_proof":
			return _incenter_proof()
		"radian":
			return _radian(p)
		"radian_proof":
			return _radian_proof()
		"circle_eq":
			return _circle_eq(p)
		"circle_eq_proof":
			return _circle_eq_proof()
	return {"shapes": []}


# ============ 多角形の角 ============

static func _polygon(p: Vector2) -> Dictionary:
	var pts: Array = StoryDefs.penta_points(p)
	var deg: Array = StoryDefs.rounded_sum(StoryDefs.polygon_angles(pts), 540)
	var out: Array = [ProblemGen.poly(pts, ProblemGen.FILL_MAIN, WHITE, 3.5)]
	var n := pts.size()
	for i in n:
		out.append(ProblemGen.ang(pts[i], pts[(i + n - 1) % n], pts[(i + 1) % n],
			"%d°" % int(deg[i]), 1.6))
	return {"shapes": out}


static func _polygon_proof() -> Dictionary:
	var pts: Array = StoryDefs.penta_points(Vector2(0.0, 7.0))
	var out: Array = [ProblemGen.poly(pts, ProblemGen.FILL_MAIN, WHITE, 3.0)]
	for i in range(2, 4):
		out.append(ProblemGen.seg(pts[0], pts[i], GOLD, 3.0))
	out += [
		ProblemGen.label(Vector2(-3.4, 1.5), "180°", GOLD, 26),
		ProblemGen.label(Vector2(0.0, -0.4), "180°", GOLD, 26),
		ProblemGen.label(Vector2(3.4, 1.5), "180°", GOLD, 26),
		ProblemGen.label(Vector2(0.0, -6.6), "3 つの三角形に分かれる → 180 × 3 = 540", GOLD, 26),
	]
	return {"shapes": out}


# ============ ブーメラン形 ============

static func _dart(p: Vector2) -> Dictionary:
	var a := StoryDefs.DART_A
	var b := StoryDefs.DART_B
	var c := StoryDefs.DART_C
	var d: Array = StoryDefs.dart_angles(p)
	return {"shapes": [
		ProblemGen.poly([a, b, p, c], ProblemGen.FILL_MAIN, WHITE, 3.5),
		ProblemGen.ang(a, b, c, "%d°" % roundi(d[0]), 1.8),
		ProblemGen.ang(b, a, p, "%d°" % roundi(d[1]), 1.8),
		ProblemGen.ang(c, p, a, "%d°" % roundi(d[2]), 1.8),
		ProblemGen.ang(p, b, c, "%d°" % roundi(d[3]), 1.6),
		ProblemGen.label(a + Vector2(0, 0.9), "A"),
		ProblemGen.label(b + Vector2(-0.8, -0.6), "B"),
		ProblemGen.label(c + Vector2(0.8, -0.6), "C"),
		ProblemGen.label(p + Vector2(0, -1.0), "P", GOLD, 26),
	]}


static func _dart_proof() -> Dictionary:
	var a := StoryDefs.DART_A
	var b := StoryDefs.DART_B
	var c := StoryDefs.DART_C
	var p := Vector2(0.0, 1.0)
	return {"shapes": [
		ProblemGen.poly([a, b, p, c], ProblemGen.FILL_MAIN, WHITE, 3.0),
		ProblemGen.seg(a, p, GOLD, 3.0, true),
		ProblemGen.seg(p, p + (p - a).normalized() * 4.0, GOLD, 2.5, true),
		ProblemGen.label(Vector2(0.0, 4.6), "A と P を結んで のばす", GOLD, 26),
		ProblemGen.label(Vector2(-4.6, -1.4), "外角", SKY, 24),
		ProblemGen.label(Vector2(4.6, -1.4), "外角", SKY, 24),
		ProblemGen.label(Vector2(0.0, -6.4), "三角形の外角 = 残り 2 つの和。それが 2 回", GOLD, 26),
	]}


# ============ 折り返しの角 ============

static func _fold(p: Vector2) -> Dictionary:
	var h := StoryDefs.TAPE_H
	var a := rad_to_deg(atan2(p.y, maxf(p.x, 0.1)))
	var f := Vector2.ZERO
	var g := Vector2(h / tan(deg_to_rad(a)), h)
	var dir := Vector2(cos(deg_to_rad(180.0 + 2.0 * a)), sin(deg_to_rad(180.0 + 2.0 * a)))
	var k := g + dir * (h / maxf(absf(dir.y), 0.0001))
	return {"shapes": [
		ProblemGen.seg(Vector2(-10.0, 0), Vector2(10.0, 0), WHITE, 4.0),
		ProblemGen.seg(Vector2(-10.0, h), Vector2(10.0, h), WHITE, 4.0),
		ProblemGen.poly([f, g, k], ProblemGen.FILL_ACCENT, GOLD, 3.0),
		ProblemGen.seg(f, g, GOLD, 3.5),
		ProblemGen.seg(g, k, SKY, 3.5),
		ProblemGen.ang(f, Vector2(6.0, 0), g, "%d°" % roundi(a), 1.7),
		ProblemGen.ang(k, Vector2(-8.0, 0), g, "%d°" % roundi(180.0 - 2.0 * a), 1.7),
		ProblemGen.label(Vector2(-8.0, h + 0.9), "テープ", DIM, 24),
		ProblemGen.label(g + Vector2(0.4, 0.9), "折り目", GOLD, 24),
	]}


static func _fold_proof() -> Dictionary:
	var h := StoryDefs.TAPE_H
	var a := 55.0
	var f := Vector2.ZERO
	var g := Vector2(h / tan(deg_to_rad(a)), h)
	var dir := Vector2(cos(deg_to_rad(180.0 + 2.0 * a)), sin(deg_to_rad(180.0 + 2.0 * a)))
	var k := g + dir * (h / maxf(absf(dir.y), 0.0001))
	return {"shapes": [
		ProblemGen.seg(Vector2(-10.0, 0), Vector2(10.0, 0), WHITE, 4.0),
		ProblemGen.seg(Vector2(-10.0, h), Vector2(10.0, h), WHITE, 4.0),
		ProblemGen.poly([f, g, k], ProblemGen.FILL_ACCENT, GOLD, 3.0),
		ProblemGen.seg(f, g, GOLD, 3.5),
		ProblemGen.ang(f, Vector2(6.0, 0), g, "a", 1.7),
		ProblemGen.ang(g, f, k, "a", 1.7),
		ProblemGen.ang(k, Vector2(-8.0, 0), g, "x", 1.7),
		ProblemGen.label(Vector2(0.0, h + 1.6), "折ると、同じ角がもう一つできる(重ねただけだから)", GOLD, 26),
		ProblemGen.label(Vector2(0.0, -1.6), "一直線は 180°。a が 2 つと x で 180°", GOLD, 26),
	]}


# ============ 道の面積 ============

static func _road(p: Vector2) -> Dictionary:
	var w := StoryDefs.FIELD_W
	var h := StoryDefs.FIELD_H
	var rw := StoryDefs.ROAD_W
	var rx: float = p.x
	var ry: float = p.y
	var left := rx
	var right := w - rx - rw
	var low := ry
	var high := h - ry - rw
	var road := Color(0.55, 0.50, 0.42, 0.75)
	return {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)],
			ProblemGen.FILL_SUB, WHITE, 3.5),
		ProblemGen.poly([Vector2(rx, 0), Vector2(rx + rw, 0), Vector2(rx + rw, h), Vector2(rx, h)],
			road, null, 0.0),
		ProblemGen.poly([Vector2(0, ry), Vector2(w, ry), Vector2(w, ry + rw), Vector2(0, ry + rw)],
			road, null, 0.0),
		ProblemGen.label(Vector2(rx * 0.5, ry * 0.5), "%.1f" % (left * low), GOLD, 24),
		ProblemGen.label(Vector2(rx + rw + right * 0.5, ry * 0.5), "%.1f" % (right * low), GOLD, 24),
		ProblemGen.label(Vector2(rx * 0.5, ry + rw + high * 0.5), "%.1f" % (left * high), GOLD, 24),
		ProblemGen.label(Vector2(rx + rw + right * 0.5, ry + rw + high * 0.5),
			"%.1f" % (right * high), GOLD, 24),
		ProblemGen.label(Vector2(w * 0.5, -1.1), "畑 %.0f × %.0f、道のはば %.0f" % [w, h, rw], DIM, 26),
	]}


static func _road_proof() -> Dictionary:
	var w := StoryDefs.FIELD_W
	var h := StoryDefs.FIELD_H
	var rw := StoryDefs.ROAD_W
	var road := Color(0.55, 0.50, 0.42, 0.75)
	return {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)],
			null, WHITE, 3.0),
		ProblemGen.poly([Vector2(w - rw, 0), Vector2(w, 0), Vector2(w, h), Vector2(w - rw, h)],
			road, null, 0.0),
		ProblemGen.poly([Vector2(0, h - rw), Vector2(w, h - rw), Vector2(w, h), Vector2(0, h)],
			road, null, 0.0),
		ProblemGen.poly([Vector2(0, 0), Vector2(w - rw, 0), Vector2(w - rw, h - rw),
			Vector2(0, h - rw)], ProblemGen.FILL_ACCENT, GOLD, 3.0),
		ProblemGen.label(Vector2((w - rw) * 0.5, (h - rw) * 0.5),
			"%.0f × %.0f" % [w - rw, h - rw], GOLD, 28),
		ProblemGen.label(Vector2(w * 0.5, -1.4), "道を端に寄せると、残りは 1 つの長方形", GOLD, 26),
	]}


# ============ 星形の角 ============

static func _star(p: Vector2) -> Dictionary:
	var pts: Array = StoryDefs.star_points(p)
	var deg: Array = StoryDefs.star_angles(p)
	var order: Array = [pts[0], pts[2], pts[4], pts[1], pts[3]]
	# 塗りは 交点を 入れた 10 点の 外わくで(自分と 交わる 5 点の ままだと 塗れない)。
	# 5 本の 線じたいは その上に 引いて、どこを 結んだのか 見えるように のこす
	var out: Array = [
		ProblemGen.poly(StoryDefs.star_outline(p), ProblemGen.FILL_MAIN, null, 0.0),
		ProblemGen.poly(order, null, GOLD, 3.0)]
	for i in 5:
		out.append(ProblemGen.ang(pts[i], pts[(i + 2) % 5], pts[(i + 3) % 5],
			"%d°" % roundi(deg[i]), 1.5))
	return {"shapes": out}


static func _star_proof() -> Dictionary:
	var pts: Array = StoryDefs.star_points(Vector2(0.0, StoryDefs.STAR_R))
	var order: Array = [pts[0], pts[2], pts[4], pts[1], pts[3]]
	return {"shapes": [
		ProblemGen.poly(StoryDefs.star_outline(Vector2(0.0, StoryDefs.STAR_R)),
			ProblemGen.FILL_MAIN, null, 0.0),
		ProblemGen.poly(order, null, DIM, 2.5),
		ProblemGen.poly([pts[0], pts[2], pts[3]], ProblemGen.FILL_ACCENT, GOLD, 3.0),
		ProblemGen.label(Vector2(0.0, StoryDefs.STAR_R + 1.4),
			"とがった角を 1 つの三角形に集める", GOLD, 26),
		ProblemGen.label(Vector2(0.0, -StoryDefs.STAR_R - 1.6),
			"外角をたどると 5 つの角が三角形の 3 つの角に化ける → 180°", GOLD, 26),
	]}


# ============ 接弦定理 ============

static func _tangent_chord(p: Vector2) -> Dictionary:
	var r := StoryDefs.TC_R
	var t := Vector2(0.0, -r)
	var b := Vector2(0.0, r)
	var d: Array = StoryDefs.tangent_chord_angles(p)
	return {"shapes": [
		ProblemGen.circle(Vector2.ZERO, r, ProblemGen.FILL_MAIN, WHITE, 3.0),
		ProblemGen.seg(Vector2(-r - 3.0, -r), Vector2(r + 3.0, -r), SKY, 3.5),
		ProblemGen.seg(t, p, GOLD, 3.5),
		ProblemGen.seg(b, t, DIM, 2.5),
		ProblemGen.seg(b, p, DIM, 2.5),
		ProblemGen.ang(t, Vector2(r + 3.0, -r), p, "%d°" % roundi(d[0]), 1.6),
		ProblemGen.ang(b, t, p, "%d°" % roundi(d[1]), 1.6),
		ProblemGen.label(t + Vector2(-0.2, -1.1), "T(接点)", SKY, 24),
		ProblemGen.label(p + Vector2(0.8, 0.5), "A", GOLD, 26),
		ProblemGen.label(b + Vector2(0.0, 0.9), "B", DIM, 26),
	]}


static func _tangent_chord_proof() -> Dictionary:
	var r := StoryDefs.TC_R
	var t := Vector2(0.0, -r)
	var top := Vector2(0.0, r)
	var a := Vector2(cos(deg_to_rad(35.0)), sin(deg_to_rad(35.0))) * r
	return {"shapes": [
		ProblemGen.circle(Vector2.ZERO, r, null, WHITE, 3.0),
		ProblemGen.seg(Vector2(-r - 3.0, -r), Vector2(r + 3.0, -r), SKY, 3.5),
		ProblemGen.seg(t, top, GOLD, 3.0, true),
		ProblemGen.seg(t, a, GOLD, 3.0),
		ProblemGen.seg(top, a, DIM, 2.5),
		ProblemGen.right(t, top, Vector2(r + 3.0, -r)),
		ProblemGen.ang(a, t, top, "90°", 1.5),
		ProblemGen.label(t + Vector2(-0.2, -1.1), "T", SKY, 24),
		ProblemGen.label(Vector2(0.0, r + 1.4), "直径を引くと、そこに 90° が 2 つ出る", GOLD, 26),
		ProblemGen.label(Vector2(0.0, -r - 2.2), "残りの角どうしが等しくなる", GOLD, 26),
	]}


# ============ 三角定規(30-60-90)の比 ============

static func _special_tri(p: Vector2) -> Dictionary:
	var hyp: float = p.x
	var short_side := hyp * 0.5
	var long_side := hyp * 0.5 * sqrt(3.0)
	var b := Vector2.ZERO
	var c := Vector2(long_side, 0.0)
	var a := Vector2(long_side, short_side)
	return {"shapes": [
		ProblemGen.poly([b, c, a], ProblemGen.FILL_MAIN, WHITE, 3.5),
		ProblemGen.right(c, b, a),
		ProblemGen.ang(b, c, a, "30°", 1.8),
		ProblemGen.ang(a, b, c, "60°", 1.5),
		ProblemGen.side_label(c, a, "%.2f" % short_side, 1.0, 0.8),
		ProblemGen.side_label(b, c, "%.2f" % long_side, -1.0, 0.8),
		ProblemGen.side_label(b, a, "%.2f" % hyp, 1.0, 0.9),
	]}


static func _special_tri_proof() -> Dictionary:
	var s := 8.0
	var h := s * 0.5 * sqrt(3.0)
	return {"shapes": [
		ProblemGen.poly([Vector2(-s * 0.5, 0), Vector2(s * 0.5, 0), Vector2(0, h)],
			ProblemGen.FILL_MAIN, WHITE, 3.0),
		ProblemGen.poly([Vector2(0, 0), Vector2(s * 0.5, 0), Vector2(0, h)],
			ProblemGen.FILL_ACCENT, GOLD, 3.0),
		ProblemGen.seg(Vector2(0, 0), Vector2(0, h), GOLD, 3.0, true),
		ProblemGen.right(Vector2(0, 0), Vector2(s * 0.5, 0), Vector2(0, h)),
		ProblemGen.label(Vector2(s * 0.25, -1.0), "半分", GOLD, 26),
		ProblemGen.label(Vector2(0.0, h + 1.4), "正三角形を半分に折った形", GOLD, 26),
		ProblemGen.label(Vector2(0.0, -2.4), "斜辺は もとの辺、短い辺は その半分 → いつも 2 倍", GOLD, 26),
	]}


# ============ 多面体とオイラーの定理 ============

## n 角柱の見取り図
static func _prism(n: int, r: float, h: float, col: Color) -> Array:
	var out: Array = []
	var bottom: Array = []
	var top: Array = []
	for i in n:
		var th := TAU * float(i) / float(n) + PI * 0.5
		var q := Vector3(cos(th) * r, sin(th) * r, 0)
		bottom.append(ProblemGen.proj3(q))
		top.append(ProblemGen.proj3(q + Vector3(0, 0, h)))
	for i in n:
		out.append(ProblemGen.seg(bottom[i], bottom[(i + 1) % n], DIM, 2.0))
		out.append(ProblemGen.seg(top[i], top[(i + 1) % n], col, 2.5))
		out.append(ProblemGen.seg(bottom[i], top[i], col, 2.5))
	return out


static func _euler(p: Vector2) -> Dictionary:
	var n := int(round(p.x))
	var out: Array = _prism(n, 4.0, 5.0, WHITE)
	out += [
		ProblemGen.label(Vector2(0.0, 9.5), "%d 角柱" % n, GOLD, 30),
		ProblemGen.label(Vector2(0.0, -7.0), "頂点 %d ・ 辺 %d ・ 面 %d" % [2 * n, 3 * n, n + 2],
			SKY, 26),
	]
	return {"shapes": out}


static func _euler_proof() -> Dictionary:
	var out: Array = _prism(5, 3.5, 4.5, WHITE)
	var apex := ProblemGen.proj3(Vector3(0, 0, 4.5))
	for i in 5:
		var th := TAU * float(i) / 5.0 + PI * 0.5
		out.append(ProblemGen.seg(ProblemGen.proj3(Vector3(cos(th) * 3.5 + 12.0,
			sin(th) * 3.5, 0)), ProblemGen.proj3(Vector3(12.0, 0, 4.5)), GOLD, 2.5))
		out.append(ProblemGen.seg(
			ProblemGen.proj3(Vector3(cos(th) * 3.5 + 12.0, sin(th) * 3.5, 0)),
			ProblemGen.proj3(Vector3(cos(TAU * float(i + 1) / 5.0 + PI * 0.5) * 3.5 + 12.0,
				sin(TAU * float(i + 1) / 5.0 + PI * 0.5) * 3.5, 0)), DIM, 2.0))
	out += [
		ProblemGen.label(Vector2(0.0, 8.6), "角柱", DIM, 26),
		ProblemGen.label(Vector2(13.0, 8.6), "角錐", GOLD, 26),
		ProblemGen.label(apex + Vector2(-3.0, -9.5), "どちらでも 頂点 − 辺 + 面 = 2", GOLD, 26),
	]
	return {"shapes": out}


# ============ 余弦定理 ============

static func _cosine(p: Vector2) -> Dictionary:
	var a := StoryDefs.COS_A
	var c := Vector2.ZERO
	var b := Vector2(a, 0.0)
	var deg := rad_to_deg(atan2(p.y, p.x))
	return {"shapes": [
		ProblemGen.poly([p, b, c], ProblemGen.FILL_MAIN, WHITE, 3.5),
		ProblemGen.ang(c, b, p, "%d°" % roundi(deg), 1.8),
		ProblemGen.label(c + Vector2(-0.8, -0.6), "C"),
		ProblemGen.label(b + Vector2(0.8, -0.6), "B"),
		ProblemGen.label(p + Vector2(0.0, 0.9), "A"),
		ProblemGen.side_label(c, b, "a %.0f" % a, -1.0, 0.8),
		ProblemGen.side_label(c, p, "b %.0f" % StoryDefs.COS_B, 1.0, 0.8),
		ProblemGen.side_label(p, b, "c %.2f" % p.distance_to(b), 1.0, 0.9),
	]}


static func _cosine_proof() -> Dictionary:
	var a := StoryDefs.COS_A
	var c := Vector2.ZERO
	var b := Vector2(a, 0.0)
	var ap := Vector2(cos(deg_to_rad(60.0)), sin(deg_to_rad(60.0))) * StoryDefs.COS_B
	var foot := Vector2(ap.x, 0.0)
	return {"shapes": [
		ProblemGen.poly([ap, b, c], ProblemGen.FILL_MAIN, WHITE, 3.0),
		ProblemGen.seg(ap, foot, GOLD, 3.0, true),
		ProblemGen.right(foot, c, ap),
		ProblemGen.label(foot + Vector2(0.0, -1.1), "b cos C", GOLD, 26),
		ProblemGen.label(ap + Vector2(-1.6, 0.6), "b sin C", GOLD, 26),
		ProblemGen.label(Vector2(a * 0.5, -2.6), "垂線を下ろすと、三平方が使える形になる", GOLD, 26),
		ProblemGen.label(Vector2(a * 0.5, -4.0), "c² = (a − b cos C)² + (b sin C)²", GOLD, 26),
	]}


# ============ 内心 ============

static func _incenter(p: Vector2) -> Dictionary:
	var b := StoryDefs.TRI_B
	var c := StoryDefs.TRI_C
	var d: Array = StoryDefs.angles_of(p, b, c)
	var inc := StoryDefs._incenter_of(p, b, c)
	var bic: float = StoryDefs.angles_of(inc, b, c)[0]
	return {"shapes": [
		ProblemGen.poly([p, b, c], ProblemGen.FILL_MAIN, WHITE, 3.5),
		ProblemGen.seg(b, inc, GOLD, 3.0),
		ProblemGen.seg(c, inc, GOLD, 3.0),
		ProblemGen.seg(p, inc, DIM, 2.0, true),
		ProblemGen.ang(p, b, c, "%d°" % roundi(d[0]), 1.8),
		ProblemGen.ang(inc, b, c, "%d°" % roundi(bic), 1.5),
		ProblemGen.label(p + Vector2(0.0, 0.9), "A"),
		ProblemGen.label(b + Vector2(-0.8, -0.6), "B"),
		ProblemGen.label(c + Vector2(0.8, -0.6), "C"),
		ProblemGen.label(inc + Vector2(0.0, -1.0), "I", GOLD, 26),
	]}


static func _incenter_proof() -> Dictionary:
	var a := Vector2(4.0, 7.0)
	var b := StoryDefs.TRI_B
	var c := StoryDefs.TRI_C
	var inc := StoryDefs._incenter_of(a, b, c)
	return {"shapes": [
		ProblemGen.poly([a, b, c], ProblemGen.FILL_MAIN, WHITE, 3.0),
		ProblemGen.seg(b, inc, GOLD, 3.0),
		ProblemGen.seg(c, inc, GOLD, 3.0),
		ProblemGen.ang(b, a, inc, "B ÷ 2", 1.5),
		ProblemGen.ang(b, inc, c, "B ÷ 2", 2.4),
		ProblemGen.ang(c, inc, a, "C ÷ 2", 1.5),
		ProblemGen.label(inc + Vector2(0.0, -1.1), "I", GOLD, 26),
		ProblemGen.label(Vector2(5.0, 8.6), "三角形 IBC の角の和は 180°", GOLD, 26),
		ProblemGen.label(Vector2(5.0, -1.8), "∠BIC = 180 − (B + C) ÷ 2 = 90 + A ÷ 2", GOLD, 26),
	]}


# ============ 弧度法 ============

static func _radian(p: Vector2) -> Dictionary:
	var r: float = p.x
	var th := StoryDefs.RAD_TH
	var deg := rad_to_deg(th)
	return {"shapes": [
		ProblemGen.sector(Vector2.ZERO, r, 0.0, deg, ProblemGen.FILL_ACCENT, GOLD),
		ProblemGen.seg(Vector2.ZERO, Vector2(r, 0), GOLD, 3.0),
		ProblemGen.seg(Vector2.ZERO, Vector2(cos(th), sin(th)) * r, GOLD, 3.0),
		ProblemGen.arc(Vector2.ZERO, r, 0.0, deg, SKY, 4.5),
		ProblemGen.label(Vector2(r * 0.5, -1.0), "半径 %.1f" % r, GOLD, 26),
		ProblemGen.label(Vector2(cos(th * 0.5), sin(th * 0.5)) * (r + 1.6),
			"弧 %.2f" % (r * th), SKY, 26),
		ProblemGen.ang(Vector2.ZERO, Vector2(r, 0), Vector2(cos(th), sin(th)) * r, "同じ角", 1.5),
	]}


static func _radian_proof() -> Dictionary:
	var out: Array = []
	for i in 3:
		var r := 2.0 + 2.0 * float(i)
		out.append(ProblemGen.arc(Vector2.ZERO, r, 0.0, rad_to_deg(StoryDefs.RAD_TH),
			SKY if i == 2 else DIM, 3.0))
	out += [
		ProblemGen.seg(Vector2.ZERO, Vector2(6.0, 0), WHITE, 3.0),
		ProblemGen.seg(Vector2.ZERO, Vector2(cos(StoryDefs.RAD_TH), sin(StoryDefs.RAD_TH)) * 6.0,
			WHITE, 3.0),
		ProblemGen.label(Vector2(1.0, 3.2), "半径 1 のときの弧の長さ = その角の大きさ", GOLD, 26),
		ProblemGen.label(Vector2(1.0, -1.6), "半径が何倍でも、弧も同じだけ何倍になる", GOLD, 26),
	]
	return {"shapes": out}


# ============ 円の方程式 ============

static func _circle_eq(p: Vector2) -> Dictionary:
	var c := StoryDefs.CIRCLE_EQ_C
	var r := StoryDefs.CIRCLE_EQ_R
	var lo := Vector2(c.x - r - 2.0, c.y - r - 2.0)
	var hi := Vector2(c.x + r + 2.0, c.y + r + 2.0)
	return {"shapes": [
		ProblemGen.grid(lo, hi), ProblemGen.axes(lo, hi),
		ProblemGen.circle(c, r, ProblemGen.FILL_MAIN, WHITE, 3.0),
		ProblemGen.seg(c, p, GOLD, 3.0),
		ProblemGen.seg(c, Vector2(p.x, c.y), SKY, 2.5, true),
		ProblemGen.seg(Vector2(p.x, c.y), p, SKY, 2.5, true),
		ProblemGen.right(Vector2(p.x, c.y), c, p),
		ProblemGen.circle(p, 0.22, GOLD, null, 0.0),
		ProblemGen.label(p + Vector2(0.8, 0.7), "(%.1f, %.1f)" % [p.x, p.y], GOLD, 26),
		ProblemGen.label(c + Vector2(-1.4, -0.8), "中心 (%.0f, %.0f)" % [c.x, c.y], DIM, 24),
	]}


static func _circle_eq_proof() -> Dictionary:
	var c := StoryDefs.CIRCLE_EQ_C
	var r := StoryDefs.CIRCLE_EQ_R
	var p := c + Vector2(cos(deg_to_rad(38.0)), sin(deg_to_rad(38.0))) * r
	var lo := Vector2(c.x - r - 2.0, c.y - r - 2.0)
	var hi := Vector2(c.x + r + 2.0, c.y + r + 3.0)
	return {"shapes": [
		ProblemGen.grid(lo, hi), ProblemGen.axes(lo, hi),
		ProblemGen.circle(c, r, null, WHITE, 3.0),
		ProblemGen.poly([c, Vector2(p.x, c.y), p], ProblemGen.FILL_ACCENT, GOLD, 3.0),
		ProblemGen.right(Vector2(p.x, c.y), c, p),
		ProblemGen.label(Vector2((c.x + p.x) * 0.5, c.y - 1.0), "x − a", GOLD, 26),
		ProblemGen.label(Vector2(p.x + 1.2, (c.y + p.y) * 0.5), "y − b", GOLD, 26),
		ProblemGen.label(c + Vector2(0.6, r + 1.6), "どの点でも同じ直角三角形ができる", GOLD, 26),
		ProblemGen.label(c + Vector2(0.6, r + 2.8), "(x − a)² + (y − b)² = r²", GOLD, 26),
	]}
