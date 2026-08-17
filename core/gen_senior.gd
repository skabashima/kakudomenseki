class_name GenSenior
## 大学受験レベル(数I・数II)の問題生成。
## 無理数が出る問題は √2 = 1.41、√3 = 1.73 と明記して小数で答えさせる。


## 余弦定理がきれいに解ける組 [a, b, C(度), c]
const COS_SETS := [
	[5, 8, 60, 7], [3, 8, 60, 7], [8, 15, 60, 13], [7, 15, 60, 13], [5, 21, 60, 19],
	[11, 35, 60, 31], [16, 21, 60, 19], [24, 35, 60, 31], [9, 24, 60, 21],
	[3, 5, 120, 7], [7, 8, 120, 13], [5, 16, 120, 19], [11, 24, 120, 31], [7, 33, 120, 37],
	[6, 10, 120, 14], [10, 32, 120, 38], [13, 35, 120, 43], [14, 16, 120, 26],
]

## ヘロンの公式で面積が整数になる三角形 [a, b, c, S]
const HERON_SETS := [
	[3, 4, 5, 6], [5, 5, 6, 12], [5, 5, 8, 12], [6, 8, 10, 24], [5, 12, 13, 30],
	[9, 12, 15, 54], [13, 14, 15, 84], [10, 10, 12, 48], [7, 15, 20, 42],
	[9, 10, 17, 36], [11, 13, 20, 66], [17, 17, 16, 120],
	[8, 15, 17, 60], [7, 24, 25, 84], [20, 21, 29, 210], [9, 40, 41, 180],
	[12, 16, 20, 96], [10, 13, 13, 60], [13, 13, 24, 60], [12, 17, 25, 90],
	[4, 13, 15, 24], [13, 20, 21, 126], [17, 25, 26, 204], [17, 25, 28, 210],
]

## 内接円・外接円がきれいな三角形 [a, b, c, S, r, R]
const INCIRCLE_SETS := [
	[3, 4, 5, 6, 1.0, 2.5], [6, 8, 10, 24, 2.0, 5.0], [5, 12, 13, 30, 2.0, 6.5],
	[9, 12, 15, 54, 3.0, 7.5], [13, 14, 15, 84, 4.0, 8.125], [10, 10, 12, 48, 3.0, 6.25],
	[7, 15, 20, 42, 2.0, 12.5], [11, 13, 20, 66, 3.0, 10.8333333], [17, 17, 16, 120, 4.8, 9.6333333],
	[8, 15, 17, 60, 3.0, 8.5], [7, 24, 25, 84, 3.0, 12.5], [20, 21, 29, 210, 6.0, 14.5],
	[9, 40, 41, 180, 4.0, 20.5], [12, 16, 20, 96, 4.0, 10.0], [13, 13, 24, 60, 2.4, 16.9],
]


static func gen(stage_id: String, rng: RandomNumberGenerator, tier: int) -> Dictionary:
	match stage_id:
		"s1": return _s1(rng, tier)
		"s2": return _s2(rng, tier)
		"s3": return _s3(rng, tier)
		"s4": return _s4(rng, tier)
		"s5": return _s5(rng, tier)
		"s6": return _s6(rng, tier)
		"s7": return _s7(rng, tier)
		"s8": return _s8(rng, tier)
		"s9": return _s9(rng, tier)
		"s11": return _s11(rng, tier)
		"s12": return _s12(rng, tier)
		_: return _s10(rng, tier)


static func _tri_fig(a: float, b: float, c: float, extra: Array = []) -> Dictionary:
	var v: Array = ProblemGen.tri_from_sides(a, b, c)
	var shapes: Array = [
		ProblemGen.poly(v, ProblemGen.FILL_MAIN),
		ProblemGen.label(v[0] + Vector2(0, 0.8), "A"),
		ProblemGen.label(v[1] + Vector2(-0.7, -0.5), "B"),
		ProblemGen.label(v[2] + Vector2(0.7, -0.5), "C"),
	]
	shapes += extra
	return {"shapes": shapes, "v": v}


## s1: 余弦定理
static func _s1(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var s: Array = COS_SETS[rng.randi_range(0, COS_SETS.size() - 1)]
	var a: int = s[0]
	var b: int = s[1]
	var cc: int = s[2]
	var c: int = s[3]
	# 図: C=(0,0)、B=(a,0)、A は角 C の方向に距離 b
	var rad := deg_to_rad(float(cc))
	var pc := Vector2.ZERO
	var pb := Vector2(float(a), 0)
	var pa := Vector2(cos(rad), sin(rad)) * b
	var ask_sq := tier >= 2 and rng.randf() < 0.5
	var fig := {"shapes": [
		ProblemGen.poly([pa, pb, pc], ProblemGen.FILL_MAIN),
		ProblemGen.label(pa + Vector2(0, 0.9), "A"), ProblemGen.label(pb + Vector2(0.8, -0.4), "B"), ProblemGen.label(pc + Vector2(-0.8, -0.4), "C"),
		ProblemGen.ang(pc, pb, pa, "%d°" % cc),
		ProblemGen.side_label(pc, pb, str(a), 1.0),
		ProblemGen.side_label(pa, pc, str(b), 1.0),
		ProblemGen.side_label(pb, pa, "c", -1.0),
	]}
	var cos_str := "1/2" if cc == 60 else "−1/2"
	var sign_str := "−" if cc == 60 else "+"
	if ask_sq:
		return {
			"q": "三角形 ABC で CA = %d、CB = %d、角 C = %d° のとき、c²(AB の 2 乗)を求めなさい。" % [b, a, cc],
			"answer": float(c * c), "unit": "",
			"hint1": "余弦定理: c² = a² + b² − 2ab cosC。cos%d° = %s だよ。" % [cc, cos_str],
			"hint2": "c² = %d² + %d² %s %d×%d" % [a, b, sign_str, a, b],
			"expl": "c² = %d² + %d² − 2×%d×%d×(%s) = %d です。" % [a, b, a, b, cos_str, c * c],
			"fig": fig,
		}
	return {
		"q": "三角形 ABC で CA = %d、CB = %d、角 C = %d° のとき、辺 AB の長さ c を求めなさい。" % [b, a, cc],
		"answer": float(c), "unit": "",
		"hint1": "余弦定理: c² = a² + b² − 2ab cosC。cos%d° = %s だよ。" % [cc, cos_str],
		"hint2": "c² = %d² + %d² %s %d×%d = %d" % [a, b, sign_str, a, b, c * c],
		"expl": "c² = %d + %d %s %d = %d。c = %d です。" % [a * a, b * b, sign_str, a * b, c * c, c],
		"fig": fig,
	}


## s2: 正弦定理と外接円
static func _s2(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var kind := mini(tier, 2)
	if rng.randf() < 0.3:
		kind = rng.randi_range(0, 2)
	var r := 5.0
	if kind == 0:
		# A = 30° または 150° → R = a(sin はどちらも 1/2)
		var deg := 30 if rng.randf() < 0.65 else 150
		var a := rng.randi_range(3, 15)
		var fig := _sine_fig(float(deg))
		return {
			"q": "三角形 ABC で、角 A = %d°、BC = %d です。この三角形の外接円の半径 R を求めなさい。" % [deg, a],
			"answer": float(a), "unit": "",
			"hint1": "正弦定理: BC / sinA = 2R。sin%d° = 1/2 だよ。" % deg,
			"hint2": "2R = %d ÷ (1/2) = %d" % [a, 2 * a],
			"expl": "2R = %d / sin%d° = %d。R = %d です。" % [a, deg, 2 * a, a],
			"fig": fig,
		}
	elif kind == 1:
		# A = 90° → R = a/2、または R 与えて a = 2R sinA
		if rng.randf() < 0.5:
			var a2 := 2 * rng.randi_range(2, 10)
			return {
				"q": "三角形 ABC で、角 A = 90°、BC = %d です。外接円の半径 R を求めなさい。" % a2,
				"answer": a2 / 2.0, "unit": "",
				"hint1": "sin90° = 1。正弦定理 BC / sinA = 2R に入れよう。BC が直径になるよ。",
				"hint2": "R = %d ÷ 2" % a2,
				"expl": "2R = %d / 1 = %d。R = %s です(直角の対辺は外接円の直径)。" % [a2, a2, ProblemGen.fmt(a2 / 2.0)],
				"fig": _sine_fig(90.0),
			}
		var rr := rng.randi_range(2, 10)
		return {
			"q": "外接円の半径が %d の三角形 ABC で、角 A = 30° です。辺 BC の長さを求めなさい。" % rr,
			"answer": float(rr), "unit": "",
			"hint1": "正弦定理 BC = 2R sinA。sin30° = 1/2 だよ。",
			"hint2": "BC = 2 × %d × 1/2" % rr,
			"expl": "BC = 2R sinA = 2 × %d × 1/2 = %d です。" % [rr, rr],
			"fig": _sine_fig(30.0),
		}
	else:
		if rng.randf() < 0.4:
			# A = 60°、R 既知 → BC = R√3(√3 = 1.73)
			var r6 := rng.randi_range(2, 12)
			var ans6 := r6 * 1.73
			return {
				"q": "外接円の半径が %d の三角形 ABC で、角 A = 60° です。辺 BC の長さを求めなさい。√3 = 1.73 として小数で答えなさい。" % r6,
				"answer": ans6, "unit": "", "tol": 0.02,
				"hint1": "正弦定理 BC = 2R sinA。sin60° = √3/2 だよ。",
				"hint2": "BC = 2 × %d × 1.73 ÷ 2 = %d × 1.73" % [r6, r6],
				"expl": "BC = 2R sin60° = %d × √3 = %s です。" % [r6, ProblemGen.fmt(ans6)],
				"fig": _sine_fig(60.0),
			}
		# A = 45° → R = a√2/2(√2 = 1.41)
		var a3 := 2 * rng.randi_range(2, 10)
		var ans := a3 * 1.41 / 2.0
		return {
			"q": "三角形 ABC で、角 A = 45°、BC = %d です。外接円の半径 R を求めなさい。√2 = 1.41 として小数で答えなさい。" % a3,
			"answer": ans, "unit": "", "tol": 0.02,
			"hint1": "2R = BC / sin45° = BC × √2 だよ。",
			"hint2": "R = %d × 1.41 ÷ 2" % a3,
			"expl": "2R = %d√2。R = %d × 1.41 / 2 = %s です。" % [a3, a3, ProblemGen.fmt(ans)],
			"fig": _sine_fig(45.0),
		}


static func _sine_fig(deg_a: float) -> Dictionary:
	var r := 5.0
	var pa: Vector2
	var pb: Vector2
	var pc: Vector2
	if deg_a <= 90.0:
		# 円周角 A に対する弧 BC: 中心角 = 2A。B, C を下側に対称に置く
		pa = Vector2(cos(deg_to_rad(110.0)), sin(deg_to_rad(110.0))) * r
		pb = Vector2(cos(deg_to_rad(270.0 - deg_a)), sin(deg_to_rad(270.0 - deg_a))) * r
		pc = Vector2(cos(deg_to_rad(270.0 + deg_a)), sin(deg_to_rad(270.0 + deg_a))) * r
	else:
		# 鈍角: A は BC の短い方の弧の上に乗る
		var half := 180.0 - deg_a
		pb = Vector2(cos(deg_to_rad(240.0 - half)), sin(deg_to_rad(240.0 - half))) * r
		pc = Vector2(cos(deg_to_rad(240.0 + half)), sin(deg_to_rad(240.0 + half))) * r
		pa = Vector2(cos(deg_to_rad(240.0 + half * 0.45)), sin(deg_to_rad(240.0 + half * 0.45))) * r
	return {"shapes": [
		ProblemGen.circle(Vector2.ZERO, r, null, ProblemGen.COL_DIM, 3.0),
		ProblemGen.poly([pa, pb, pc], ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
		ProblemGen.circle(Vector2.ZERO, 0.12, Color.WHITE),
		ProblemGen.label(Vector2(0.7, 0.4), "O"),
		ProblemGen.label(pa + Vector2(0, 0.8), "A"),
		ProblemGen.label(pb + Vector2(-0.7, -0.5), "B"), ProblemGen.label(pc + Vector2(0.7, -0.5), "C"),
		ProblemGen.ang(pa, pb, pc, "%d°" % int(deg_a)),
	]}


## s3: 面積公式 S = ½ab sinC
static func _s3(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var angles_easy := [30, 90, 150]
	var angles_hard := [45, 60, 120, 135]
	var cc: int
	var irr := tier >= 1 and rng.randf() < 0.65
	if irr:
		cc = angles_hard[rng.randi_range(0, angles_hard.size() - 1)]
	else:
		cc = angles_easy[rng.randi_range(0, angles_easy.size() - 1)]
	var a := rng.randi_range(2, 12)
	var b := rng.randi_range(2, 12)
	while (a * b) % 4 != 0:
		b = rng.randi_range(2, 12)
	var sin_v: float
	var sin_str: String
	var note := ""
	match cc:
		30, 150:
			sin_v = 0.5
			sin_str = "1/2"
		90:
			sin_v = 1.0
			sin_str = "1"
		45, 135:
			sin_v = 1.41 / 2.0
			sin_str = "√2/2"
			note = "√2 = 1.41 として小数で答えなさい。"
		_:
			sin_v = 1.73 / 2.0
			sin_str = "√3/2"
			note = "√3 = 1.73 として小数で答えなさい。"
	var ans := 0.5 * a * b * sin_v
	var rad := deg_to_rad(float(cc))
	var pc := Vector2.ZERO
	var pb := Vector2(float(a), 0)
	var pa := Vector2(cos(rad), sin(rad)) * b
	var fig := {"shapes": [
		ProblemGen.poly([pa, pb, pc], ProblemGen.FILL_MAIN),
		ProblemGen.ang(pc, pb, pa, "%d°" % cc),
		ProblemGen.side_label(pc, pb, str(a), 1.0),
		ProblemGen.side_label(pa, pc, str(b), 1.0),
	]}
	return {
		"q": ("2 辺が %d と %d で、その間の角が %d° の三角形の面積 S を求めなさい。" % [a, b, cc]) + note,
		"answer": ans, "unit": "", "tol": 0.02 if note != "" else 0.015,
		"hint1": "面積公式 S = ½ ab sinC。sin%d° = %s だよ。" % [cc, sin_str],
		"hint2": "S = ½ × %d × %d × %s" % [a, b, sin_str.replace("√2/2", "0.705").replace("√3/2", "0.865")],
		"expl": "S = ½ × %d × %d × sin%d° = %s です。" % [a, b, cc, ProblemGen.fmt(ans)],
		"fig": fig,
	}


## s4: ヘロンの公式
static func _s4(rng: RandomNumberGenerator, _tier: int) -> Dictionary:
	var s: Array = HERON_SETS[rng.randi_range(0, HERON_SETS.size() - 1)]
	var a: int = s[0]
	var b: int = s[1]
	var c: int = s[2]
	var area: int = s[3]
	var sp := (a + b + c) / 2.0
	var v: Array = ProblemGen.tri_from_sides(float(a), float(b), float(c))
	var fig := {"shapes": [
		ProblemGen.poly(v, ProblemGen.FILL_MAIN),
		ProblemGen.side_label(v[1], v[2], str(a), 1.0),
		ProblemGen.side_label(v[2], v[0], str(b), -1.0),
		ProblemGen.side_label(v[0], v[1], str(c), -1.0),
	]}
	return {
		"q": "3 辺の長さが %d、%d、%d の三角形の面積 S を求めなさい。" % [a, b, c],
		"answer": float(area), "unit": "",
		"hint1": "ヘロンの公式: s = (a+b+c)/2 として S = √(s(s−a)(s−b)(s−c))。",
		"hint2": "s = %s。S = √(%s × %s × %s × %s)" % [ProblemGen.fmt(sp), ProblemGen.fmt(sp), ProblemGen.fmt(sp - a), ProblemGen.fmt(sp - b), ProblemGen.fmt(sp - c)],
		"expl": "s = %s。S = √(%s×%s×%s×%s) = %d です。" % [ProblemGen.fmt(sp), ProblemGen.fmt(sp), ProblemGen.fmt(sp - a), ProblemGen.fmt(sp - b), ProblemGen.fmt(sp - c), area],
		"fig": fig,
	}


## s5: 内接円の半径・外接円の半径
static func _s5(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var s: Array = INCIRCLE_SETS[rng.randi_range(0, INCIRCLE_SETS.size() - 1)]
	var a: int = s[0]
	var b: int = s[1]
	var c: int = s[2]
	var area: int = s[3]
	var r: float = s[4]
	var rr: float = s[5]
	var v: Array = ProblemGen.tri_from_sides(float(a), float(b), float(c))
	var use_circum: bool = tier >= 2 and rng.randf() < 0.5
	# 内接円の中心(角の二等分線の交点 = 重み付き平均)
	var inc: Vector2 = (v[0] * a + v[1] * b + v[2] * c) / float(a + b + c)
	if use_circum:
		var fig2 := {"shapes": [
			ProblemGen.poly(v, ProblemGen.FILL_MAIN),
			ProblemGen.side_label(v[1], v[2], str(a), 1.0),
			ProblemGen.side_label(v[2], v[0], str(b), -1.0),
			ProblemGen.side_label(v[0], v[1], str(c), -1.0),
		]}
		return {
			"q": "3 辺が %d、%d、%d の三角形の外接円の半径 R を求めなさい。(この三角形の面積は %d です)" % [a, b, c, area],
			"answer": rr, "unit": "",
			"hint1": "公式 S = abc / 4R を変形して R = abc / 4S。",
			"hint2": "R = %d × %d × %d ÷ (4 × %d)" % [a, b, c, area],
			"expl": "R = abc/4S = %d/(4×%d) = %s です。" % [a * b * c, area, ProblemGen.fmt(rr)],
			"fig": fig2,
		}
	var fig := {"shapes": [
		ProblemGen.poly(v, ProblemGen.FILL_MAIN),
		ProblemGen.circle(inc, r, null, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.circle(inc, 0.1, ProblemGen.COL_YELLOW),
		ProblemGen.side_label(v[1], v[2], str(a), 1.0),
		ProblemGen.side_label(v[2], v[0], str(b), -1.0),
		ProblemGen.side_label(v[0], v[1], str(c), -1.0),
	]}
	return {
		"q": "3 辺が %d、%d、%d の三角形の内接円の半径 r を求めなさい。(この三角形の面積は %d です)" % [a, b, c, area],
		"answer": r, "unit": "",
		"hint1": "公式 S = r × s(s は周の半分)。r = S ÷ s で求まるよ。",
		"hint2": "s = %s。r = %d ÷ %s" % [ProblemGen.fmt((a + b + c) / 2.0), area, ProblemGen.fmt((a + b + c) / 2.0)],
		"expl": "s = %s。r = S/s = %d ÷ %s = %s です。" % [ProblemGen.fmt((a + b + c) / 2.0), area, ProblemGen.fmt((a + b + c) / 2.0), ProblemGen.fmt(r)],
		"fig": fig,
	}


## s6: ベクトル・座標の三角形の面積
static func _s6(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var x1 := rng.randi_range(1, 6)
	var y1 := rng.randi_range(-2, 5)
	var x2 := rng.randi_range(-3, 5)
	var y2 := rng.randi_range(2, 6)
	var det := x1 * y2 - x2 * y1
	while det == 0 or absi(det) < 4:
		x2 = rng.randi_range(-3, 5)
		y2 = rng.randi_range(2, 6)
		det = x1 * y2 - x2 * y1
	var ans := absi(det) / 2.0
	var lo := Vector2(mini(0, mini(x1, x2)) - 1, mini(0, mini(y1, y2)) - 1)
	var hi := Vector2(maxi(0, maxi(x1, x2)) + 1, maxi(0, maxi(y1, y2)) + 1)
	var fig := {"shapes": [
		ProblemGen.grid(lo, hi), ProblemGen.axes(lo, hi),
		ProblemGen.poly([Vector2.ZERO, Vector2(x1, y1), Vector2(x2, y2)], ProblemGen.FILL_MAIN, null, 0.0),
		ProblemGen.arrow(Vector2.ZERO, Vector2(x1, y1), ProblemGen.COL_YELLOW),
		ProblemGen.arrow(Vector2.ZERO, Vector2(x2, y2), Color(0.55, 0.85, 1.0)),
		ProblemGen.label(Vector2(x1, y1) + Vector2(0.9, -0.4), "a→"),
		ProblemGen.label(Vector2(x2, y2) + Vector2(0, 0.9), "b→"),
	]}
	if tier >= 1:
		return {
			"q": "a→ = (%d, %d)、b→ = (%d, %d) のとき、a→ と b→ が作る三角形 OAB の面積 S を求めなさい。" % [x1, y1, x2, y2],
			"answer": ans, "unit": "",
			"hint1": "S = ½ |x₁y₂ − x₂y₁| に成分を入れるだけだよ。",
			"hint2": "S = ½ |%d×%d − (%d)×(%d)|" % [x1, y2, x2, y1],
			"expl": "S = ½|%d − %d| = ½ × %d = %s です。" % [x1 * y2, x2 * y1, absi(det), ProblemGen.fmt(ans)],
			"fig": fig,
		}
	return {
		"q": "O(0,0)、A(%d, %d)、B(%d, %d) を頂点とする三角形の面積 S を求めなさい。" % [x1, y1, x2, y2],
		"answer": ans, "unit": "",
		"hint1": "公式 S = ½ |x₁y₂ − x₂y₁|(原点を頂点とする三角形)。",
		"hint2": "S = ½ |%d×%d − (%d)×(%d)|" % [x1, y2, x2, y1],
		"expl": "S = ½|%d×%d − (%d)×(%d)| = ½×%d = %s です。" % [x1, y2, x2, y1, absi(det), ProblemGen.fmt(ans)],
		"fig": fig,
	}


## s7: 弧度法(l = rθ、S = ½r²θ、S = ½rl)
static func _s7(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var kind := mini(tier, 2)
	if rng.randf() < 0.3:
		kind = rng.randi_range(0, 2)
	if kind == 0:
		# θ = l / r(有理数)
		var r := rng.randi_range(2, 8)
		var th_num: float = [1.0, 1.5, 2.0, 2.5, 3.0][rng.randi_range(0, 4)]
		var l := r * th_num
		return {
			"q": "半径 %d、弧の長さ %s のおうぎ形の中心角 θ は何ラジアンですか。" % [r, ProblemGen.fmt(l)],
			"answer": th_num, "unit": "rad",
			"hint1": "弧度法では 弧の長さ l = rθ。θ = l ÷ r だよ。",
			"hint2": "θ = %s ÷ %d" % [ProblemGen.fmt(l), r],
			"expl": "θ = l/r = %s/%d = %s rad です。" % [ProblemGen.fmt(l), r, ProblemGen.fmt(th_num)],
			"fig": _rad_fig(float(r), th_num),
		}
	elif kind == 1:
		# S = ½ r l(有理数)
		var r2 := rng.randi_range(2, 12)
		var l2 := rng.randi_range(2, mini(18, r2 * 5))   # θ = l/r が 5 rad を超えない範囲で
		var ans := 0.5 * r2 * l2
		return {
			"q": "半径 %d、弧の長さ %d のおうぎ形の面積 S を求めなさい。" % [r2, l2],
			"answer": ans, "unit": "",
			"hint1": "弧度法の便利な公式 S = ½ r l(半径 × 弧 ÷ 2)。",
			"hint2": "S = ½ × %d × %d" % [r2, l2],
			"expl": "S = ½rl = ½ × %d × %d = %s です。" % [r2, l2, ProblemGen.fmt(ans)],
			"fig": _rad_fig(float(r2), float(l2) / float(r2)),
		}
	else:
		# S = ½ r² θ、θ = π/k(π = 3.14)
		var opts := [[6, 6], [6, 4], [6, 3], [6, 2], [4, 4], [4, 2], [2, 2], [3, 3], [8, 4], [12, 6]]
		var o: Array = opts[rng.randi_range(0, opts.size() - 1)]
		var r3: int = o[0]
		var k: int = o[1]
		var ans2 := 0.5 * r3 * r3 * 3.14 / k
		return {
			"q": "半径 %d、中心角 π/%d ラジアンのおうぎ形の面積 S を求めなさい。π = 3.14 として小数で答えなさい。" % [r3, k],
			"answer": ans2, "unit": "", "tol": 0.02,
			"hint1": "S = ½ r² θ に入れるだけ。角度を 360° に直さなくていいのが弧度法の良さ。",
			"hint2": "S = ½ × %d² × 3.14/%d" % [r3, k],
			"expl": "S = ½ × %d × 3.14/%d = %s です。" % [r3 * r3, k, ProblemGen.fmt(ans2)],
			"fig": _rad_fig(float(r3), PI / k),
		}


static func _rad_fig(r: float, th: float) -> Dictionary:
	var deg := rad_to_deg(th)
	return {"shapes": [
		ProblemGen.sector(Vector2.ZERO, r, 0.0, deg, ProblemGen.FILL_MAIN, Color.WHITE),
		ProblemGen.ang(Vector2.ZERO, Vector2(r, 0), Vector2(cos(th), sin(th)) * r, "θ", 0.0, true),
		ProblemGen.label(Vector2(r * 0.6, -0.9), ProblemGen.fmt(r)),
	]}


## s8: 放物線と直線(6分の1公式)
static func _s8(rng: RandomNumberGenerator, _tier: int) -> Dictionary:
	# (a, β−α) → 面積 a(β−α)³/6 がきれいな組
	var sets := [[1, 3], [1, 6], [2, 3], [3, 2], [3, 4], [2, 6], [1, 4], [1, 2], [2, 2], [2, 4], [3, 6], [1, 12]]
	var s: Array = sets[rng.randi_range(0, sets.size() - 1)]
	var a: int = s[0]
	var d: int = s[1]
	var alpha := rng.randi_range(-5, 2)
	var beta := alpha + d
	var ans := a * pow(d, 3) / 6.0
	# 直線 y = m x + n が y = a x² と x=α, β で交わる: m = a(α+β), n = −aαβ
	var m := a * (alpha + beta)
	var n := -a * alpha * beta
	# グラフは縦に伸びやすいので、y をスケーリングして見やすい縦横比にする
	var k := _graph_k(beta - alpha + 1.6,
		[a * pow(alpha - 0.8, 2), a * pow(beta + 0.8, 2), m * (alpha - 0.8) + n, m * (beta + 0.8) + n])
	var pts: Array = []
	for i in 25:
		var x := alpha - 0.8 + (beta - alpha + 1.6) * i / 24.0
		pts.append(Vector2(x, a * x * x * k))
	var la := Vector2(alpha - 0.8, (m * (alpha - 0.8) + n) * k)
	var lb := Vector2(beta + 0.8, (m * (beta + 0.8) + n) * k)
	var region: Array = []
	for i in 25:
		var x := float(alpha) + d * i / 24.0
		region.append(Vector2(x, (m * x + n) * k))
	for i in 25:
		var x := float(beta) - d * i / 24.0
		region.append(Vector2(x, a * x * x * k))
	var a_str := "" if a == 1 else str(a)
	var m_str := _lin_str(m, n)
	var fig := {"shapes": [
		ProblemGen.poly(region, ProblemGen.FILL_ACCENT, null, 0.0),
		ProblemGen.curve(pts, Color.WHITE, 4.0),
		ProblemGen.seg(la, lb, ProblemGen.COL_YELLOW, 4.0),
		ProblemGen.label(Vector2(beta + 1.6, a * beta * beta * k), "y = %sx²" % a_str),
	]}
	return {
		"q": "放物線 y = %sx² と直線 y = %s は x = %d と x = %d で交わります。囲まれた部分の面積 S を求めなさい。" % [a_str, m_str, alpha, beta],
		"answer": ans, "unit": "",
		"hint1": "6分の1公式: S = |a|(β − α)³ / 6。積分を全部やらなくても一発だよ。",
		"hint2": "S = %d × (%d − (%d))³ ÷ 6 = %d × %d ÷ 6" % [a, beta, alpha, a, d * d * d],
		"expl": "S = |a|(β−α)³/6 = %d × %d³/6 = %s です。" % [a, d, ProblemGen.fmt(ans)],
		"fig": fig,
	}


## グラフ図形の y 縮尺: 幅 span_x に対して y の値域がほぼ同じ長さになる係数
static func _graph_k(span_x: float, ys: Array) -> float:
	var lo := INF
	var hi := -INF
	for y in ys:
		lo = minf(lo, float(y))
		hi = maxf(hi, float(y))
	var span_y := maxf(hi - lo, 0.001)
	return span_x / span_y


static func _lin_str(m: int, n: int) -> String:
	var s := ""
	if m == 1:
		s = "x"
	elif m == -1:
		s = "−x"
	elif m != 0:
		s = ("%d" % m).replace("-", "−") + "x"
	if n > 0:
		s += (" + %d" % n) if s != "" else str(n)
	elif n < 0:
		s += " − %d" % (-n)
	elif s == "":
		s = "0"
	return s


## s9: 2 つの放物線で囲まれた面積
static func _s9(rng: RandomNumberGenerator, _tier: int) -> Dictionary:
	# 上に凸 y = -x² + p x + q と下に凸 y = x² の差: Δa = 2
	var sets := [[2, 3], [2, 6], [3, 2], [3, 4], [4, 3], [6, 2], [2, 2], [2, 4], [3, 6], [5, 2], [4, 6]]
	var s: Array = sets[rng.randi_range(0, sets.size() - 1)]
	var da: int = s[0]
	var d: int = s[1]
	var alpha := rng.randi_range(-4, 1)
	var beta := alpha + d
	var ans := da * pow(d, 3) / 6.0
	# f(x) = x², g(x) = f + da(x−α)(β−x) → g − f = da(x−α)(β−x)
	# g(x) = x² + da(−x² + (α+β)x − αβ) = (1−da)x² + da(α+β)x − da·αβ
	var ga := 1 - da
	var gb := da * (alpha + beta)
	var gc := -da * alpha * beta
	var samples: Array = []
	for i in 29:
		var x := alpha - 0.6 + (d + 1.2) * i / 28.0
		samples.append(x * x)
		samples.append(ga * x * x + gb * x + gc)
	var k := _graph_k(d + 1.2, samples)
	var pts_f: Array = []
	var pts_g: Array = []
	for i in 29:
		var x := alpha - 0.6 + (d + 1.2) * i / 28.0
		pts_f.append(Vector2(x, x * x * k))
		pts_g.append(Vector2(x, (ga * x * x + gb * x + gc) * k))
	var region: Array = []
	for i in 25:
		var x := float(alpha) + d * i / 24.0
		region.append(Vector2(x, (ga * x * x + gb * x + gc) * k))
	for i in 25:
		var x := float(beta) - d * i / 24.0
		region.append(Vector2(x, x * x * k))
	var g_str := _quad_str(ga, gb, gc)
	var fig := {"shapes": [
		ProblemGen.poly(region, ProblemGen.FILL_ACCENT, null, 0.0),
		ProblemGen.curve(pts_f, Color.WHITE, 4.0),
		ProblemGen.curve(pts_g, ProblemGen.COL_YELLOW, 4.0),
	]}
	return {
		"q": "2 つの放物線 y = x² と y = %s は x = %d と x = %d で交わります。囲まれた部分の面積 S を求めなさい。" % [g_str, alpha, beta],
		"answer": ans, "unit": "",
		"hint1": "差をとると (上) − (下) = %d(x − α)(β − x)。6分の1公式 S = |Δa|(β−α)³/6 が使えるよ。" % da,
		"hint2": "S = %d × (%d − (%d))³ ÷ 6" % [da, beta, alpha],
		"expl": "2 次の係数の差は %d。S = %d × %d³/6 = %s です。" % [da, da, d, ProblemGen.fmt(ans)],
		"fig": fig,
	}


static func _quad_str(a: int, b: int, c: int) -> String:
	var parts: Array = []
	if a == -1:
		parts.append("−x²")
	elif a == 1:
		parts.append("x²")
	elif a != 0:
		parts.append(("%d" % a).replace("-", "−") + "x²")
	if b != 0:
		var bs := "x" if absi(b) == 1 else "%dx" % absi(b)
		parts.append(("+ " if b > 0 else "− ") + bs)
	if c != 0:
		parts.append(("+ %d" % c) if c > 0 else ("− %d" % (-c)))
	var out := " ".join(parts)
	if out.begins_with("+ "):
		out = out.substr(2)
	return out


## s10: 面積の総合問題(sin・絶対値・放物線と x 軸)
static func _s10(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var kind := mini(tier, 2)
	if rng.randf() < 0.3:
		kind = rng.randi_range(0, 2)
	if kind == 0:
		# y = a sin x (0 ≤ x ≤ π) と x 軸 → 2a
		var a := rng.randi_range(1, 6)
		var pts: Array = []
		for i in 33:
			var x := PI * i / 32.0
			pts.append(Vector2(x * 2.2, a * sin(x)))    # 横に拡大して見やすく
		var region := pts.duplicate()
		region.append(Vector2(PI * 2.2, 0))
		region.append(Vector2(0, 0))
		var fig := {"shapes": [
			ProblemGen.poly(region, ProblemGen.FILL_MAIN, null, 0.0),
			ProblemGen.curve(pts, Color.WHITE, 4.0),
			ProblemGen.seg(Vector2(-0.5, 0), Vector2(PI * 2.2 + 0.8, 0), ProblemGen.COL_DIM, 3.0),
			ProblemGen.label(Vector2(PI * 1.1, a + 0.8), "y = %s sin x" % ("" if a == 1 else str(a))),
			ProblemGen.label(Vector2(PI * 2.2, -0.7), "π"),
		]}
		return {
			"q": "曲線 y = %ssin x (0 ≤ x ≤ π) と x 軸で囲まれた部分の面積 S を求めなさい。" % ("" if a == 1 else str(a)),
			"answer": 2.0 * a, "unit": "",
			"hint1": "∫sin x dx = −cos x。0 から π まで積分しよう。",
			"hint2": "S = %s[−cos x]₀^π = %s × (1 + 1)" % [str(a), str(a)],
			"expl": "S = %d∫₀^π sin x dx = %d[−cos x]₀^π = %d × 2 = %d です。" % [a, a, a, 2 * a],
			"fig": fig,
		}
	elif kind == 1:
		# y = −|x − p| + b と x 軸 → 三角形 面積 b²
		var p := rng.randi_range(-2, 3)
		var b := rng.randi_range(2, 6)
		var fig2 := {"shapes": [
			ProblemGen.grid(Vector2(p - b - 1, -1), Vector2(p + b + 1, b + 1)),
			ProblemGen.axes(Vector2(p - b - 1, -1), Vector2(p + b + 1, b + 1)),
			ProblemGen.poly([Vector2(p - b, 0), Vector2(p + b, 0), Vector2(p, b)], ProblemGen.FILL_MAIN, ProblemGen.COL_YELLOW, 4.0),
		]}
		var p_str := ("x − %d" % p) if p > 0 else (("x + %d" % (-p)) if p < 0 else "x")
		return {
			"q": "折れ線 y = −|%s| + %d と x 軸で囲まれた部分の面積 S を求めなさい。" % [p_str, b],
			"answer": float(b * b), "unit": "",
			"hint1": "グラフは頂点 (%d, %d) の山形。x 軸との交点は %d と %d だよ。" % [p, b, p - b, p + b],
			"hint2": "底辺 %d、高さ %d の三角形。S = %d × %d ÷ 2" % [2 * b, b, 2 * b, b],
			"expl": "底辺 = %d、高さ = %d の三角形なので S = %d × %d / 2 = %d です。" % [2 * b, b, 2 * b, b, b * b],
			"fig": fig2,
		}
	else:
		# 放物線 y = a(x−p)(x−q) と x 軸(下に凸を x 軸の下で)
		var sets := [[1, 2], [1, 3], [1, 4], [1, 5], [1, 6], [2, 2], [2, 3], [2, 4], [3, 2], [2, 6], [3, 4], [3, 6]]
		var s: Array = sets[rng.randi_range(0, sets.size() - 1)]
		var a2: int = s[0]
		var d: int = s[1]
		var p2 := rng.randi_range(-3, 1)
		var q2 := p2 + d
		var ans := a2 * pow(d, 3) / 6.0
		var k := _graph_k(d + 1.4, [a2 * pow(0.7, 2) + a2 * 0.7 * d, -a2 * d * d / 4.0])
		var pts2: Array = []
		for i in 29:
			var x := p2 - 0.7 + (d + 1.4) * i / 28.0
			pts2.append(Vector2(x, a2 * (x - p2) * (x - q2) * k))
		var region2: Array = []
		for i in 25:
			var x := float(p2) + d * i / 24.0
			region2.append(Vector2(x, a2 * (x - p2) * (x - q2) * k))
		region2.append(Vector2(q2, 0))
		region2.append(Vector2(p2, 0))
		# 展開形で表示
		var bq := -a2 * (p2 + q2)
		var cq := a2 * p2 * q2
		var fig3 := {"shapes": [
			ProblemGen.poly(region2, ProblemGen.FILL_ACCENT, null, 0.0),
			ProblemGen.curve(pts2, Color.WHITE, 4.0),
			ProblemGen.seg(Vector2(p2 - 1.0, 0), Vector2(q2 + 1.0, 0), ProblemGen.COL_DIM, 3.0),
			ProblemGen.label(Vector2(p2, 0.6), str(p2)),
			ProblemGen.label(Vector2(q2, 0.6), str(q2)),
		]}
		return {
			"q": "放物線 y = %s と x 軸で囲まれた部分の面積 S を求めなさい。" % _quad_str(a2, bq, cq),
			"answer": ans, "unit": "",
			"hint1": "因数分解すると y = %d(x − (%d))(x − (%d))。x 軸との交点は %d と %d。6分の1公式だ!" % [a2, p2, q2, p2, q2],
			"hint2": "S = %d × (%d − (%d))³ ÷ 6" % [a2, q2, p2],
			"expl": "交点は x = %d, %d。S = |a|(β−α)³/6 = %d × %d³/6 = %s です。" % [p2, q2, a2, d, ProblemGen.fmt(ans)],
			"fig": fig3,
		}


## s11: 三角方程式(sin・cos・tan の値から角度を求める)
static func _s11(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	# [問題文の式, 範囲(°), 答え(°)]
	const EASY := [
		["sinθ = 1/2", 90, 30], ["sinθ = √3/2", 90, 60], ["sinθ = √2/2", 90, 45],
		["sinθ = 1", 90, 90], ["cosθ = 1/2", 90, 60], ["cosθ = √3/2", 90, 30],
		["cosθ = √2/2", 90, 45], ["tanθ = 1", 90, 45], ["tanθ = √3", 90, 60],
		["cosθ = 0", 90, 90],
	]
	const OBTUSE := [
		["cosθ = −1/2", 180, 120], ["cosθ = −√3/2", 180, 150], ["cosθ = −√2/2", 180, 135],
		["tanθ = −1", 180, 135], ["tanθ = −√3", 180, 120], ["cosθ = −1", 180, 180],
	]
	const EQUATION := [
		["2sinθ = 1", 90, 30], ["2sinθ = √3", 90, 60], ["√2 sinθ = 1", 90, 45],
		["2cosθ = 1", 90, 60], ["2cosθ + 1 = 0", 180, 120], ["tanθ + 1 = 0", 180, 135],
		["√3 tanθ = 1", 90, 30], ["2cosθ = √2", 90, 45], ["2cosθ + √3 = 0", 180, 150],
	]
	var pool: Array
	match mini(tier, 2):
		0: pool = EASY
		1: pool = OBTUSE
		_: pool = EQUATION
	if rng.randf() < 0.3:
		pool = [EASY, OBTUSE, EQUATION][rng.randi_range(0, 2)]
	var pick: Array = pool[rng.randi_range(0, pool.size() - 1)]
	var expr := String(pick[0])
	var range_max := int(pick[1])
	var ans := int(pick[2])
	# 単位円の図(答えの角の位置に半径を引く)
	var rr := 4.5
	var rad := deg_to_rad(float(ans))
	var tip := Vector2(cos(rad), sin(rad)) * rr
	var fig := {"shapes": [
		ProblemGen.axes(Vector2(-rr - 1, -1.2), Vector2(rr + 1, rr + 1)),
		ProblemGen.circle(Vector2.ZERO, rr, null, ProblemGen.COL_DIM, 3.0),
		ProblemGen.seg(Vector2.ZERO, tip, ProblemGen.COL_YELLOW, 4.0),
		ProblemGen.circle(tip, 0.15, ProblemGen.COL_YELLOW),
		ProblemGen.seg(tip, Vector2(tip.x, 0), ProblemGen.COL_DIM, 2.5, true),
		ProblemGen.ang(Vector2.ZERO, Vector2(rr, 0), tip, "θ"),
	]}
	return {
		"q": "0° ≤ θ ≤ %d° のとき、%s を満たす θ を求めなさい。" % [range_max, expr],
		"answer": float(ans), "unit": "度",
		"hint1": "30°・45°・60°(と 90°・120°・135°・150°)の sin・cos・tan の値を思い出そう。単位円をかくと確実だよ。",
		"hint2": "%s になるのは θ = %d° のとき。" % [expr, ans],
		"expl": "%s を満たすのは θ = %d° です(単位円の図の位置)。" % [expr, ans],
		"fig": fig,
	}


## s12: ベクトルのなす角(cosθ = a・b / |a||b| がきれいな値になる組)
static func _s12(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	# [ax, ay, bx, by, 角度]
	const RIGHT := [
		[2, 1, -1, 2, 90], [3, 1, -1, 3, 90], [1, 2, -2, 1, 90], [4, 1, -1, 4, 90],
		[3, 2, -2, 3, 90], [1, 3, -3, 1, 90], [2, 3, -3, 2, 90],
	]
	const OTHERS := [
		[3, 1, 2, -1, 45], [1, 3, 2, 1, 45], [2, 1, 3, -1, 45], [1, 2, 3, 1, 45],
		[0, 2, 2, 2, 45], [2, 0, 2, 2, 45],
		[1, 2, -3, -1, 135], [3, 1, -2, 1, 135], [1, 3, -2, -1, 135],
		[2, 0, -2, 2, 135], [0, 2, 2, -2, 135],
	]
	var pool: Array = RIGHT if tier == 0 else OTHERS
	if rng.randf() < 0.3:
		pool = RIGHT if pool == OTHERS else OTHERS
	var s: Array = pool[rng.randi_range(0, pool.size() - 1)]
	var ax := int(s[0])
	var ay := int(s[1])
	var bx := int(s[2])
	var by := int(s[3])
	var ans := int(s[4])
	var dot := ax * bx + ay * by
	var va := Vector2(ax, ay)
	var vb := Vector2(bx, by)
	var lo := Vector2(minf(0, minf(va.x, vb.x)) - 1, minf(0, minf(va.y, vb.y)) - 1)
	var hi := Vector2(maxf(0, maxf(va.x, vb.x)) + 1, maxf(0, maxf(va.y, vb.y)) + 1)
	var fig := {"shapes": [
		ProblemGen.grid(lo, hi), ProblemGen.axes(lo, hi),
		ProblemGen.arrow(Vector2.ZERO, va, ProblemGen.COL_YELLOW),
		ProblemGen.arrow(Vector2.ZERO, vb, Color(0.55, 0.85, 1.0)),
		ProblemGen.label(va + va.normalized() * 0.8, "a→"),
		ProblemGen.label(vb + vb.normalized() * 0.8, "b→"),
		ProblemGen.ang(Vector2.ZERO, va, vb, "θ"),
	]}
	return {
		"q": "a→ = (%d, %d)、b→ = (%d, %d) のなす角 θ を求めなさい。" % [ax, ay, bx, by],
		"answer": float(ans), "unit": "度",
		"hint1": "cosθ = (a・b) ÷ (|a→| |b→|)。まず内積 a・b を計算しよう。",
		"hint2": "a・b = %d×%d + %d×%d = %d。cosθ = %s になるよ。" % [
			ax, bx, ay, by, dot,
			"0" if dot == 0 else ("√2/2" if ans == 45 else "−√2/2")],
		"expl": "a・b = %d。cosθ = %d/(|a||b|) から θ = %d° です。" % [dot, dot, ans],
		"fig": fig,
	}
