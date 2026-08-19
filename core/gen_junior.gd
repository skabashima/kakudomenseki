class_name GenJunior
## 高校受験レベル(中学数学)の問題生成。


## 三平方の定理で使うピタゴラス数 [a, b, c](a² + b² = c²)
const TRIPLES := [
	[3, 4, 5], [6, 8, 10], [5, 12, 13], [8, 15, 17], [9, 12, 15],
	[7, 24, 25], [12, 16, 20], [15, 20, 25], [10, 24, 26], [20, 21, 29],
	[9, 40, 41], [16, 30, 34], [18, 24, 30], [28, 45, 53], [33, 56, 65],
	[48, 55, 73], [65, 72, 97], [21, 28, 35], [24, 32, 40], [27, 36, 45],
]


## 各ステージの「難度ラダー」。tier(0-9)を解法の種類に割り当てる。
## 挑戦モード 10 問は 1 問ごとに解法そのものが変わっていく。
static func gen(stage_id: String, rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var t := clampi(tier, 0, 9)
	match stage_id:
		"j1":
			# 外角の和 → 逆算 → 3 直線の交点
			match [0, 0, 0, 1, 1, 1, 2, 2, 2, 2][t]:
				0: return _j1(rng, 0)
				1: return _j1(rng, 1)
				_: return _j1_three(rng)
		"j2":
			# 平行線と三角形 → 逆算 → 二等辺との複合
			match [0, 0, 0, 1, 1, 1, 2, 2, 2, 2][t]:
				0: return _j2(rng, 0)
				1: return _j2_rev(rng)
				_: return _j2_iso(rng)
		"j3":
			# 中心角→円周角 → 円周角→中心角 → タレス → 半径の二等辺
			match [0, 0, 1, 1, 2, 2, 3, 3, 3, 3][t]:
				0: return _j3(rng, 0)
				1: return _j3(rng, 1)
				2: return _j3(rng, 2)
				_: return _j3_iso(rng)
		"j4":
			# 内接四角形 → 接線 2 本 → 接弦定理
			match [0, 0, 0, 1, 1, 1, 2, 2, 2, 2][t]:
				0: return _j4(rng, 0)
				1: return _j4(rng, 1)
				_: return _j4_tanchord(rng)
		"j5":
			# 斜辺 → 残りの辺 → 面積 → 長方形の対角線 → 2 点間の距離
			match [0, 0, 1, 1, 2, 2, 3, 3, 4, 4][t]:
				0: return _j5(rng, 0)
				1: return _j5(rng, 1)
				2: return _j5(rng, 2)
				3: return _j5_diag(rng)
				_: return _j5_dist(rng)
		"j6":
			# 45°面積 → 30°短辺 → 45°斜辺(√2) → 30°長辺(√3) → 正三角形の高さ
			match [0, 0, 2, 2, 1, 1, 3, 3, 4, 4][t]:
				0: return _j6(rng, 0)
				1: return _j6(rng, 1)
				2: return _j6(rng, 2)
				3: return _j6(rng, 3)
				_: return _j6(rng, 4)
		"j7":
			# 弧 → 面積 → 中心角逆算 → 弓形 → 半円−三角形
			match [0, 1, 1, 2, 2, 3, 3, 4, 4, 4][t]:
				0: return _j7(rng, 0)
				1: return _j7(rng, 1)
				2: return _j7(rng, 2)
				3: return _j7_segment(rng)
				_: return _j7_semi(rng)
		"j8":
			# 相似比→面積 → 中点連結 → 面積比→辺 → 周の比
			match [0, 0, 0, 1, 1, 2, 2, 2, 3, 3][t]:
				0: return _j8(rng, 0)
				1: return _j8(rng, 1)
				2: return _j8_side(rng)
				_: return _j8_perim(rng)
		"j9":
			# 原点三角形 → 切片三角形 → 格子点の三角形(囲み法)
			match [0, 0, 0, 1, 1, 1, 2, 2, 2, 2][t]:
				0: return _j9(rng, 0)
				1: return _j9(rng, 1)
				_: return _j9_shoelace(rng)
		"j11":
			# 星形五芒 → 細かい角度 → 六芒星
			match [0, 0, 0, 1, 1, 1, 2, 2, 2, 2][t]:
				0: return _j11(rng, 0)
				1: return _j11(rng, 1)
				_: return _j11_hex(rng)
		"j12":
			# 弧の比→円周角 → 弧の比→中心角 → 別の頂点の角
			match [0, 0, 0, 1, 1, 1, 2, 2, 2, 2][t]:
				0: return _j12(rng, 0)
				1: return _j12_central(rng)
				_: return _j12_other(rng)
		_:
			# j10: ドーナツ → ヒポクラテスの月 → 半円から半円 2 つ
			match [0, 0, 1, 1, 1, 1, 2, 2, 2, 2][t]:
				0: return _j10(rng, 0)
				1: return _j10(rng, 1)
				_: return _j10_semi(rng)


## j1: 三角形の外角(外角 = 残り 2 つの内角の和)
static func _j1(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	var step := 5 if kind == 0 else 1
	var a := step * rng.randi_range(30 / step, 80 / step)
	var b := step * rng.randi_range(30 / step, 80 / step)
	var ext := a + b
	while ext >= 150:
		b = step * rng.randi_range(30 / step, 80 / step)
		ext = a + b
	var v: Array = ProblemGen.tri_from_angles(float(a), 180.0 - float(ext), 10.0)
	var far: Vector2 = v[2] + (v[2] - v[1]).normalized() * 3.5
	if kind == 1:
		# 外角と 1 つの内角から残りの内角
		var fig2 := {"shapes": [
			ProblemGen.poly(v, ProblemGen.FILL_MAIN),
			ProblemGen.seg(v[2], far, ProblemGen.COL_DIM),
			ProblemGen.ang(v[1], v[2], v[0], "%d°" % a),
			ProblemGen.ang(v[0], v[1], v[2], "x"),
			ProblemGen.ang(v[2], v[0], far, "%d°" % ext),
		]}
		return {
			"q": "三角形の外角が %d°、内角の 1 つが %d° のとき、角 x は何度ですか。" % [ext, a],
			"answer": float(b), "unit": "度",
			"hint1": "三角形の外角は、となり合わない 2 つの内角の和に等しいよ。",
			"hint2": "x = %d − %d" % [ext, a],
			"expl": "外角の定理より %d = %d + x。x = %d° です。" % [ext, a, b],
			"fig": fig2,
		}
	var fig := {"shapes": [
		ProblemGen.poly(v, ProblemGen.FILL_MAIN),
		ProblemGen.seg(v[2], far, ProblemGen.COL_DIM),
		ProblemGen.ang(v[1], v[2], v[0], "%d°" % a),
		ProblemGen.ang(v[0], v[1], v[2], "%d°" % b),
		ProblemGen.ang(v[2], v[0], far, "x"),
	]}
	return {
		"q": "図の三角形で、外角 x は何度ですか。",
		"answer": float(ext), "unit": "度",
		"hint1": "外角は、となり合わない 2 つの内角の和。180 から引かなくても一発で出るよ。",
		"hint2": "x = %d + %d" % [a, b],
		"expl": "外角の定理より x = %d + %d = %d° です。" % [a, b, ext],
		"fig": fig,
	}


## j2: 平行線と三角形の複合(平行線 + 三角形の内角)
static func _j2(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	# 平行線の間に三角形。上の平行線との角 a、下の平行線との角 b、頂点の角 x
	var step := 5 if kind == 0 else 1
	var a := step * rng.randi_range(35 / step, 75 / step)
	var b := step * rng.randi_range(35 / step, 75 / step)
	var x := 180 - a - b
	while x < 30 or x > 110:
		a = step * rng.randi_range(35 / step, 75 / step)
		b = step * rng.randi_range(35 / step, 75 / step)
		x = 180 - a - b
	var w := 12.0
	# 三角形 ABC: 頂点 A は上の直線 l 上、B・C は下の直線 m 上。
	# A で l の左向きと AB がつくる角 a は、錯角で三角形の角 B に等しい。
	# C の内角を b とすると、頂点の角 x = 180 − a − b(内角の和)
	var pa := Vector2(6.0, 5.0)
	var pb := Vector2(6.0 - 5.0 / tan(deg_to_rad(float(a))), 0.0)
	var pc := Vector2(6.0 + 5.0 / tan(deg_to_rad(float(b))), 0.0)
	var fig := {"shapes": [
		ProblemGen.seg(Vector2(-2, 5), Vector2(w, 5)), ProblemGen.seg(Vector2(-2, 0), Vector2(w, 0)),
		ProblemGen.label(Vector2(w + 0.7, 5), "l"), ProblemGen.label(Vector2(w + 0.7, 0), "m"),
		ProblemGen.poly([pa, pb, pc], ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
		ProblemGen.ang(pa, Vector2(-2, 5), pb, "%d°" % a),
		ProblemGen.ang(pc, pa, pb, "%d°" % b),
		ProblemGen.ang(pa, pb, pc, "x"),
	]}
	var steps := [
		{"say": "%d° の角は、平行線の錯角(Z の形)! 三角形の左下の角へそのまま移せる。" % a,
			"add": [ProblemGen.seg(Vector2(-2, 5), pa, Color(0.45, 1.0, 0.6, 0.9), 3.0, true),
				ProblemGen.seg(pa, pb, Color(0.45, 1.0, 0.6, 0.9), 3.0, true),
				ProblemGen.ang(pb, pa, pc, "%d°" % a)]},
		{"say": "これで三角形の 2 つの角(%d° と %d°)がわかった。内角の和は 180°。" % [a, b]},
		{"say": "x = 180 − %d − %d = %d°。入力してみよう!" % [a, b, x]},
	]
	return {
		"q": "直線 l と m は平行です。三角形の角 x は何度ですか。",
		"answer": float(x), "unit": "度",
		"hint1": "%d° の角は、錯角で三角形の左下の角にそのまま移せるよ。" % a,
		"hint2": "x = 180 − %d − %d(三角形の内角の和)" % [a, b],
		"steps": steps,
		"expl": "錯角より左下の内角は %d°。内角の和から x = 180 − %d − %d = %d° です。" % [a, a, b, x],
		"fig": fig,
	}


## j3: 円周角の定理
static func _j3(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var kind := clampi(tier, 0, 2)
	var r := 5.0
	if kind == 0:
		# 中心角 → 円周角(図は出題値どおりの角度で描く)
		var c := 2 * rng.randi_range(20, 80)    # 40..160(偶数)
		var x := c / 2
		var pa := _on_circle(r, 270.0 - c * 0.5)
		var pb := _on_circle(r, 270.0 + c * 0.5)
		var pt := _on_circle(r, 90.0)
		var fig := {"shapes": [
			ProblemGen.circle(Vector2.ZERO, r),
			ProblemGen.poly([pt, pa, pb], null, ProblemGen.COL_DIM, 3.0),
			ProblemGen.seg(Vector2.ZERO, pa, ProblemGen.COL_YELLOW, 3.0), ProblemGen.seg(Vector2.ZERO, pb, ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.circle(Vector2.ZERO, 0.12, Color.WHITE),
			ProblemGen.label(Vector2(0.7, 0.5), "O"),
			ProblemGen.ang(Vector2.ZERO, pa, pb, "%d°" % c),
			ProblemGen.ang(pt, pa, pb, "x"),
		]}
		return {
			"q": "円 O で、中心角が %d° のとき、同じ弧に対する円周角 x は何度ですか。" % c,
			"answer": float(x), "unit": "度",
			"hint1": "円周角は中心角の半分だよ。",
			"hint2": "x = %d ÷ 2" % c,
			"expl": "円周角の定理より x = %d ÷ 2 = %d° です。" % [c, x],
			"fig": fig,
		}
	elif kind == 1:
		# 円周角 → 中心角(中心角 2a になるよう弧を張る)
		var a := rng.randi_range(25, 85)
		var pa := _on_circle(r, 270.0 - float(a))
		var pb := _on_circle(r, 270.0 + float(a))
		var pt := _on_circle(r, 90.0)
		var fig2 := {"shapes": [
			ProblemGen.circle(Vector2.ZERO, r),
			ProblemGen.poly([pt, pa, pb], null, ProblemGen.COL_DIM, 3.0),
			ProblemGen.seg(Vector2.ZERO, pa, ProblemGen.COL_YELLOW, 3.0), ProblemGen.seg(Vector2.ZERO, pb, ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.circle(Vector2.ZERO, 0.12, Color.WHITE),
			ProblemGen.label(Vector2(0.7, 0.5), "O"),
			ProblemGen.ang(pt, pa, pb, "%d°" % a),
			ProblemGen.ang(Vector2.ZERO, pa, pb, "x"),
		]}
		return {
			"q": "円 O で、円周角が %d° のとき、同じ弧に対する中心角 x は何度ですか。" % a,
			"answer": float(2 * a), "unit": "度",
			"hint1": "中心角は円周角の 2 倍だよ。",
			"hint2": "x = %d × 2" % a,
			"expl": "円周角の定理より x = %d × 2 = %d° です。" % [a, 2 * a],
			"fig": fig2,
		}
	else:
		# 直径 → 90°(タレスの定理)。T の位置は角 A が a2 になる場所
		var a2 := rng.randi_range(20, 70)
		var x2 := 90 - a2
		var pa := Vector2(-r, 0)
		var pb := Vector2(r, 0)
		var pt := _on_circle(r, 2.0 * a2)
		var fig3 := {"shapes": [
			ProblemGen.circle(Vector2.ZERO, r),
			ProblemGen.seg(pa, pb, ProblemGen.COL_DIM, 3.0),
			ProblemGen.poly([pt, pa, pb], null, Color.WHITE, 3.0),
			ProblemGen.circle(Vector2.ZERO, 0.12, Color.WHITE),
			ProblemGen.label(Vector2(0, -0.7), "O"),
			ProblemGen.ang(pa, pb, pt, "%d°" % a2),
			ProblemGen.ang(pb, pt, pa, "x"),
			ProblemGen.right(pt, pa, pb),
		]}
		return {
			"q": "AB は円 O の直径です。角 A が %d° のとき、角 x は何度ですか。" % a2,
			"answer": float(x2), "unit": "度",
			"hint1": "直径に対する円周角は 90°(タレスの定理)。頂点の角は直角だよ。",
			"hint2": "x = 180 − 90 − %d" % a2,
			"expl": "直径に立つ円周角は 90°。三角形の内角の和から x = 90 − %d = %d° です。" % [a2, x2],
			"fig": fig3,
		}


static func _on_circle(r: float, deg: float) -> Vector2:
	return Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg))) * r


## j4: 内接四角形・接線の角
static func _j4(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	if tier == 0:
		# 円に内接する四角形: 向かい合う角の和 180°。
		# 頂点 B の円周角が a になるよう、B を含まない弧 CA を 2a に張る
		var a := rng.randi_range(55, 125)
		var r := 5.0
		var pa := _on_circle(r, fposmod(300.0 + 2.0 * a, 360.0))
		var pb := _on_circle(r, 220.0)
		var pc := _on_circle(r, 300.0)
		var pd := _on_circle(r, 340.0)
		var fig := {"shapes": [
			ProblemGen.circle(Vector2.ZERO, r),
			ProblemGen.poly([pa, pb, pc, pd], ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
			ProblemGen.ang(pb, pc, pa, "%d°" % a),
			ProblemGen.ang(pd, pa, pc, "x"),
		]}
		return {
			"q": "四角形は円に内接しています。1 つの角が %d° のとき、向かいの角 x は何度ですか。" % a,
			"answer": float(180 - a), "unit": "度",
			"hint1": "円に内接する四角形は、向かい合う角の和が 180° だよ。",
			"hint2": "x = 180 − %d" % a,
			"expl": "内接四角形の対角の和は 180°。x = 180 − %d = %d° です。" % [a, 180 - a],
			"fig": fig,
		}
	# 外部の点からの 2 本の接線: 接線どうしの角 a → 中心角 x = 180 − a
	var a2 := rng.randi_range(30, 80)
	var r2 := 4.0
	var dist := r2 / sin(deg_to_rad(a2 * 0.5))
	var p := Vector2(dist, 0)
	# 接点: 中心 O=(0,0)、P=(dist,0)。cosθ = r/dist
	var th := acos(r2 / dist)
	var q1 := Vector2(cos(th), sin(th)) * r2
	var q2 := Vector2(cos(th), -sin(th)) * r2
	var fig2 := {"shapes": [
		ProblemGen.circle(Vector2.ZERO, r2),
		ProblemGen.seg(p, q1, ProblemGen.COL_DIM), ProblemGen.seg(p, q2, ProblemGen.COL_DIM),
		ProblemGen.seg(Vector2.ZERO, q1, ProblemGen.COL_YELLOW, 3.0), ProblemGen.seg(Vector2.ZERO, q2, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.circle(Vector2.ZERO, 0.12, Color.WHITE),
		ProblemGen.label(Vector2(-0.7, 0), "O"), ProblemGen.label(p + Vector2(0.7, 0), "P"),
		ProblemGen.right(q1, Vector2.ZERO, p), ProblemGen.right(q2, Vector2.ZERO, p),
		ProblemGen.ang(p, q2, q1, "%d°" % a2),
		ProblemGen.ang(Vector2.ZERO, q1, q2, "x"),
	]}
	return {
		"q": "点 P から円 O に 2 本の接線を引きました。接線の間の角が %d° のとき、中心角 x は何度ですか。" % a2,
		"answer": float(180 - a2), "unit": "度",
		"hint1": "接線と半径は接点で垂直(90°)。四角形の内角の和 360° を使おう。",
		"hint2": "x = 360 − 90 − 90 − %d" % a2,
		"expl": "接点の角は 2 つとも 90°。四角形の内角の和から x = 360 − 180 − %d = %d° です。" % [a2, 180 - a2],
		"fig": fig2,
	}


## j5: 三平方の定理
static func _j5(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var t: Array = TRIPLES[rng.randi_range(0, TRIPLES.size() - 1)]
	var a: int = t[0]
	var b: int = t[1]
	var c: int = t[2]
	var v: Array = [Vector2(0, float(a)), Vector2(0, 0), Vector2(float(b), 0)]
	var kind := clampi(tier, 0, 2)
	if kind == 0:
		var fig := {"shapes": [
			ProblemGen.poly(v, ProblemGen.FILL_MAIN),
			ProblemGen.right(v[1], v[0], v[2]),
			ProblemGen.side_label(v[1], v[2], str(b), 1.0),
			ProblemGen.side_label(v[0], v[1], str(a), -1.0),
			ProblemGen.side_label(v[2], v[0], "x", -1.0),
		]}
		return {
			"q": "直角をはさむ 2 辺が %d と %d の直角三角形で、斜辺 x の長さを求めなさい。" % [a, b],
			"answer": float(c), "unit": "",
			"hint1": "三平方の定理: (斜辺)² = (1辺)² + (もう1辺)² だよ。",
			"hint2": "x² = %d² + %d² = %d" % [a, b, c * c],
			"expl": "x² = %d² + %d² = %d + %d = %d。x = %d です。" % [a, b, a * a, b * b, c * c, c],
			"fig": fig,
		}
	elif kind == 1:
		var fig2 := {"shapes": [
			ProblemGen.poly(v, ProblemGen.FILL_MAIN),
			ProblemGen.right(v[1], v[0], v[2]),
			ProblemGen.side_label(v[1], v[2], str(b), 1.0),
			ProblemGen.side_label(v[0], v[1], "x", -1.0),
			ProblemGen.side_label(v[2], v[0], str(c), -1.0),
		]}
		return {
			"q": "斜辺が %d、1 辺が %d の直角三角形で、残りの辺 x の長さを求めなさい。" % [c, b],
			"answer": float(a), "unit": "",
			"hint1": "斜辺の 2 乗から、わかっている辺の 2 乗を引こう。",
			"hint2": "x² = %d² − %d² = %d" % [c, b, a * a],
			"expl": "x² = %d² − %d² = %d − %d = %d。x = %d です。" % [c, b, c * c, b * b, a * a, a],
			"fig": fig2,
		}
	else:
		var fig3 := {"shapes": [
			ProblemGen.poly(v, ProblemGen.FILL_MAIN),
			ProblemGen.right(v[1], v[0], v[2]),
			ProblemGen.side_label(v[0], v[1], str(a), -1.0),
			ProblemGen.side_label(v[2], v[0], str(c), -1.0),
			ProblemGen.label(Vector2(b * 0.45, a * 0.35), "?", ProblemGen.COL_YELLOW, 40),
		]}
		return {
			"q": "斜辺が %d、高さが %d の直角三角形の面積を求めなさい。" % [c, a],
			"answer": float(a * b) / 2.0, "unit": "",
			"hint1": "まず三平方の定理で底辺を求めよう。",
			"hint2": "底辺 = √(%d² − %d²) = %d。面積 = %d × %d ÷ 2" % [c, a, b, b, a],
			"expl": "底辺 = √(%d²−%d²) = %d。面積 = %d × %d ÷ 2 = %s です。" % [c, a, b, b, a, ProblemGen.fmt(a * b / 2.0)],
			"fig": fig3,
		}


## j6: 特別な直角三角形(45°/30°/60°、√2=1.41・√3=1.73)
static func _j6(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	# kind 0: 45° 斜辺→面積 / 1: 45° 辺→斜辺(√2) / 2: 30° 斜辺→短辺
	# kind 3: 30° 短辺→長辺(√3) / 4: 正三角形の高さ
	var kind := clampi(tier, 0, 4)
	if kind == 1:
			# 直角二等辺: 1 辺 → 斜辺(√2 = 1.41)
			var leg := rng.randi_range(2, 20)
			var ans_h := leg * 1.41
			var vv := [Vector2(0, 0), Vector2(float(leg), 0), Vector2(0, float(leg))]
			var fig_h := {"shapes": [
				ProblemGen.poly(vv, ProblemGen.FILL_MAIN),
				ProblemGen.right(vv[0], vv[1], vv[2]),
				ProblemGen.side_label(vv[0], vv[1], str(leg), 1.0),
				ProblemGen.side_label(vv[1], vv[2], "x", -1.0),
				ProblemGen.tick(vv[0], vv[1]), ProblemGen.tick(vv[0], vv[2]),
			]}
			return {
				"q": "直角をはさむ 2 辺がどちらも %d の直角二等辺三角形で、斜辺 x を求めなさい。√2 = 1.41 として小数で答えなさい。" % leg,
				"answer": ans_h, "unit": "", "tol": 0.02,
				"hint1": "辺の比は 1 : 1 : √2。斜辺 = 1辺 × √2 だよ。",
				"hint2": "x = %d × 1.41" % leg,
				"expl": "x = %d × √2 = %d × 1.41 = %s です。" % [leg, leg, ProblemGen.fmt(ans_h)],
				"fig": fig_h,
			}
	if kind == 3:
			# 30-60-90: 短辺 → 長辺(√3 = 1.73)
			var sh := rng.randi_range(2, 12)
			var ans_l := sh * 1.73
			var vv := [Vector2(0, 0), Vector2(sh * 1.73, 0), Vector2(sh * 1.73, float(sh))]
			var fig_l := {"shapes": [
				ProblemGen.poly(vv, ProblemGen.FILL_MAIN),
				ProblemGen.ang(vv[0], vv[1], vv[2], "30°"),
				ProblemGen.right(vv[1], vv[0], vv[2]),
				ProblemGen.side_label(vv[1], vv[2], str(sh), 1.0),
				ProblemGen.side_label(vv[0], vv[1], "x", 1.0),
			]}
			return {
				"q": "30°、60°、90° の直角三角形で、いちばん短い辺が %d のとき、直角をはさむもう 1 つの辺 x を求めなさい。√3 = 1.73 として小数で答えなさい。" % sh,
				"answer": ans_l, "unit": "", "tol": 0.02,
				"hint1": "辺の比は 1 : 2 : √3。長い方の辺 = 短い辺 × √3 だよ。",
				"hint2": "x = %d × 1.73" % sh,
				"expl": "x = %d × √3 = %d × 1.73 = %s です。" % [sh, sh, ProblemGen.fmt(ans_l)],
				"fig": fig_l,
			}
	if kind == 2:
		# 30-60-90: 斜辺 → 最短辺
		var h2 := 2 * rng.randi_range(2, 15)
		var short := h2 / 2
		var lng := short * 1.73
		var v2 := [Vector2(0, 0), Vector2(lng, 0), Vector2(lng, float(short))]
		var fig2 := {"shapes": [
		ProblemGen.poly(v2, ProblemGen.FILL_MAIN),
		ProblemGen.ang(v2[0], v2[1], v2[2], "30°"),
		ProblemGen.right(v2[1], v2[0], v2[2]),
		ProblemGen.side_label(v2[0], v2[2], str(h2), -1.0),
		ProblemGen.side_label(v2[1], v2[2], "x", 1.0),
		]}
		return {
		"q": "30°、60°、90° の直角三角形で、斜辺が %d のとき、30° の角と向かい合う辺 x を求めなさい。" % h2,
		"answer": float(short), "unit": "",
		"hint1": "30° の対辺は斜辺のちょうど半分だよ(1 : 2 : √3)。",
		"hint2": "x = %d ÷ 2" % h2,
		"expl": "辺の比は 1 : 2 : √3。30° の対辺 = 斜辺 ÷ 2 = %d です。" % short,
		"fig": fig2,
		}
	if kind == 4:
		# 正三角形の高さ(√3=1.73 として)
		var a := 2 * rng.randi_range(2, 12)
		var ans := a * 1.73 / 2.0
		var v3 := [Vector2(0, 0), Vector2(float(a), 0), Vector2(a * 0.5, a * 0.866)]
		var fig3 := {"shapes": [
			ProblemGen.poly(v3, ProblemGen.FILL_MAIN),
			ProblemGen.seg(Vector2(a * 0.5, 0), v3[2], ProblemGen.COL_YELLOW, 3.0, true),
			ProblemGen.right(Vector2(a * 0.5, 0), Vector2(float(a), 0), v3[2]),
			ProblemGen.side_label(v3[0], v3[1], str(a), 1.0),
			ProblemGen.tick(v3[0], v3[2]), ProblemGen.tick(v3[1], v3[2]), ProblemGen.tick(v3[0], v3[1]),
		]}
		return {
			"q": "1 辺 %d の正三角形の高さを求めなさい。√3 = 1.73 として小数で答えなさい。" % a,
			"answer": ans, "unit": "", "tol": 0.02,
			"hint1": "高さで半分に切ると 30-60-90 の直角三角形。高さ = 1辺 × √3 ÷ 2 だよ。",
			"hint2": "%d × 1.73 ÷ 2" % a,
			"expl": "高さ = %d × √3 ÷ 2 = %d × 1.73 ÷ 2 = %s です。" % [a, a, ProblemGen.fmt(ans)],
			"fig": fig3,
		}
	# kind 0: 直角二等辺 斜辺 → 面積(h²/4 で有理数)
	var h := 2 * rng.randi_range(2, 12)
	var half := h * 0.5
	var v := [Vector2(0, 0), Vector2(float(h), 0), Vector2(half, half)]
	var fig := {"shapes": [
		ProblemGen.poly(v, ProblemGen.FILL_MAIN),
		ProblemGen.ang(v[0], v[1], v[2], "45°"), ProblemGen.ang(v[1], v[2], v[0], "45°"),
		ProblemGen.right(v[2], v[0], v[1]),
		ProblemGen.side_label(v[0], v[1], str(h), 1.0),
	]}
	return {
		"q": "斜辺が %d の直角二等辺三角形の面積を求めなさい。" % h,
		"answer": h * h / 4.0, "unit": "",
		"hint1": "斜辺を底辺と見ると、高さは斜辺の半分になるよ。",
		"hint2": "面積 = %d × %d ÷ 2" % [h, h / 2],
		"expl": "高さは斜辺の半分の %s。面積 = %d × %s ÷ 2 = %s です。" % [ProblemGen.fmt(half), h, ProblemGen.fmt(half), ProblemGen.fmt(h * h / 4.0)],
		"fig": fig,
	}


## j7: おうぎ形の弧・面積・中心角(3.14)
static func _j7(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	# (r × θ) が 90 の倍数になる組だけ使う → 3.14 × (0.5 きざみ) で 2 桁小数に収まる
	var pairs: Array = []
	for r in [3, 4, 6, 9, 10, 12, 15, 18]:
		for th in [30, 45, 60, 90, 120, 135, 150, 210, 240, 270]:
			if (r * th) % 90 == 0:
				pairs.append([r, th])
	var pick: Array = pairs[rng.randi_range(0, pairs.size() - 1)]
	var r: int = pick[0]
	var th: int = pick[1]
	var kind := clampi(tier, 0, 2)
	var arc_len := 2.0 * 3.14 * r * th / 360.0
	var fig := {"shapes": [
		ProblemGen.sector(Vector2.ZERO, float(r), 0.0, float(th), ProblemGen.FILL_MAIN, Color.WHITE),
		ProblemGen.ang(Vector2.ZERO, Vector2(float(r), 0), _on_circle(float(r), float(th)), "%d°" % th, 0.0, true),
		ProblemGen.label(Vector2(r * 0.6, -0.9), "%dcm" % r),
	]}
	if kind == 0:
		return {
			"q": "半径 %dcm、中心角 %d° のおうぎ形の弧の長さは何 cm ですか。円周率は 3.14 とします。" % [r, th],
			"answer": arc_len, "unit": "cm", "tol": 0.02,
			"hint1": "弧の長さ = 円周 × (中心角 ÷ 360) だよ。",
			"hint2": "2 × 3.14 × %d × %d/360" % [r, th],
			"expl": "弧 = 2 × 3.14 × %d × %d/360 = %s cm です。" % [r, th, ProblemGen.fmt(arc_len)],
			"fig": fig,
		}
	elif kind == 1:
		# 面積は (r²θ) % 90 == 0 が必要。満たすまで選び直す
		while (r * r * th) % 90 != 0:
			pick = pairs[rng.randi_range(0, pairs.size() - 1)]
			r = pick[0]
			th = pick[1]
		var area := 3.14 * r * r * th / 360.0
		fig = {"shapes": [
			ProblemGen.sector(Vector2.ZERO, float(r), 0.0, float(th), ProblemGen.FILL_ACCENT, Color.WHITE),
			ProblemGen.ang(Vector2.ZERO, Vector2(float(r), 0), _on_circle(float(r), float(th)), "%d°" % th, 0.0, true),
			ProblemGen.label(Vector2(r * 0.6, -0.9), "%dcm" % r),
		]}
		return {
			"q": "半径 %dcm、中心角 %d° のおうぎ形の面積は何 cm² ですか。円周率は 3.14 とします。" % [r, th],
			"answer": area, "unit": "cm²", "tol": 0.02,
			"hint1": "面積 = 円の面積 × (中心角 ÷ 360) だよ。",
			"hint2": "3.14 × %d × %d × %d/360" % [r, r, th],
			"expl": "面積 = 3.14 × %d² × %d/360 = %s cm² です。" % [r, th, ProblemGen.fmt(area)],
			"fig": fig,
		}
	else:
		return {
			"q": "半径 %dcm のおうぎ形の弧の長さが %scm のとき、中心角 x は何度ですか。円周率は 3.14 とします。" % [r, ProblemGen.fmt(arc_len)],
			"answer": float(th), "unit": "度",
			"hint1": "半径 %d の円周は 2 × 3.14 × %d = %s cm。弧はその何分のいくつかな?" % [r, r, ProblemGen.fmt(2.0 * 3.14 * r)],
			"hint2": "x = 360 × %s ÷ %s" % [ProblemGen.fmt(arc_len), ProblemGen.fmt(2.0 * 3.14 * r)],
			"expl": "x = 360 × (弧 ÷ 円周) = 360 × %s ÷ %s = %d° です。" % [ProblemGen.fmt(arc_len), ProblemGen.fmt(2.0 * 3.14 * r), th],
			"fig": fig,
		}


## j8: 相似と面積比
static func _j8(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	if tier >= 1:
		# 中点連結: 中点三角形の面積は 1/4
		var s := 4 * rng.randi_range(3, 15)
		var v := [Vector2(0, 0), Vector2(10, 0), Vector2(3.5, 7)]
		var m01: Vector2 = (v[0] + v[1]) * 0.5
		var m12: Vector2 = (v[1] + v[2]) * 0.5
		var m20: Vector2 = (v[2] + v[0]) * 0.5
		var fig := {"shapes": [
			ProblemGen.poly(v, ProblemGen.FILL_MAIN),
			ProblemGen.poly([m01, m12, m20], ProblemGen.FILL_ACCENT, Color.WHITE, 3.0),
			ProblemGen.label(Vector2(4.5, 5.8), "全体 %d" % s),
		]}
		return {
			"q": "三角形の 3 辺の中点を結んで小さな三角形を作りました。もとの三角形の面積が %d のとき、小さな三角形の面積を求めなさい。" % s,
			"answer": s / 4.0, "unit": "",
			"hint1": "中点を結んだ三角形は、もとの三角形と相似で相似比は 1:2。面積比は 2 乗だよ。",
			"hint2": "%d ÷ 4" % s,
			"expl": "相似比 1:2 → 面積比 1:4。%d ÷ 4 = %s です。" % [s, ProblemGen.fmt(s / 4.0)],
			"fig": fig,
		}
	var m := rng.randi_range(2, 4)
	var n := rng.randi_range(m + 1, 5)
	var k := rng.randi_range(2, 9)
	var small := m * m * k
	var big := n * n * k
	var v1: Array = ProblemGen.tri_from_sides(6.0, 5.0, 4.0)
	var scale := float(n) / float(m) * 0.9
	var v2: Array = []
	for p in v1:
		v2.append(Vector2(p.x * scale + 8.0, p.y * scale))
	var fig2 := {"shapes": [
		ProblemGen.poly(v1, ProblemGen.FILL_MAIN),
		ProblemGen.poly(v2, ProblemGen.FILL_ACCENT),
		ProblemGen.label(Vector2(3.0, -1.2), "面積 %d" % small),
		ProblemGen.label(Vector2(8.0 + 3.0 * scale, -1.2), "面積 x"),
		ProblemGen.label(Vector2(7.2, 6.5), "相似比 %d : %d" % [m, n]),
	]}
	return {
		"q": "相似比が %d : %d の相似な三角形があります。小さい方の面積が %d のとき、大きい方の面積 x を求めなさい。" % [m, n, small],
		"answer": float(big), "unit": "",
		"hint1": "相似比が %d : %d なら、面積比はその 2 乗で %d : %d だよ。" % [m, n, m * m, n * n],
		"hint2": "x = %d × %d ÷ %d" % [small, n * n, m * m],
		"expl": "面積比は %d² : %d² = %d : %d。x = %d × %d/%d = %d です。" % [m, n, m * m, n * n, small, n * n, m * m, big],
		"fig": fig2,
	}


## j9: 座標平面の面積
static func _j9(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	if tier == 0:
		# 原点・x軸上の点・任意の点の三角形
		var a := rng.randi_range(4, 10)
		var cx := rng.randi_range(1, a - 1)
		var cy := rng.randi_range(3, 8)
		var fig := {"shapes": [
			ProblemGen.grid(Vector2(-1, -1), Vector2(11, 9)),
			ProblemGen.axes(Vector2(-1, -1), Vector2(11, 9)),
			ProblemGen.poly([Vector2(0, 0), Vector2(a, 0), Vector2(cx, cy)], ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
			ProblemGen.label(Vector2(-0.6, -0.6), "O"),
			ProblemGen.label(Vector2(a, -0.7), "(%d, 0)" % a),
			ProblemGen.label(Vector2(cx, cy + 0.8), "(%d, %d)" % [cx, cy]),
		]}
		return {
			"q": "3 点 O(0, 0)、A(%d, 0)、B(%d, %d) を結んだ三角形 OAB の面積を求めなさい。" % [a, cx, cy],
			"answer": a * cy / 2.0, "unit": "",
			"hint1": "OA を底辺と見ると、高さは B の y 座標だよ。",
			"hint2": "%d × %d ÷ 2" % [a, cy],
			"expl": "底辺 OA = %d、高さ = %d。面積 = %d × %d ÷ 2 = %s です。" % [a, cy, a, cy, ProblemGen.fmt(a * cy / 2.0)],
			"fig": fig,
		}
	# 直線 y = -p x + q と両軸で囲む三角形(q は p の倍数)
	var p := rng.randi_range(1, 3)
	var q := p * rng.randi_range(2, 6)
	var xi := q / p
	var ans := q * xi / 2.0
	var pts: Array = []
	for i in 2:
		pts.append(Vector2(0, float(q)) if i == 0 else Vector2(float(xi), 0))
	var fig2 := {"shapes": [
		ProblemGen.grid(Vector2(-1, -1), Vector2(xi + 2, q + 2)),
		ProblemGen.axes(Vector2(-1, -1), Vector2(xi + 2, q + 2)),
		ProblemGen.seg(Vector2(-0.5, q + 0.5 * p), Vector2(xi + 0.5, -0.5 * p), ProblemGen.COL_YELLOW, 4.0),
		ProblemGen.poly([Vector2(0, 0), Vector2(float(xi), 0), Vector2(0, float(q))], ProblemGen.FILL_MAIN, null, 0.0),
		ProblemGen.label(Vector2(-0.6, -0.6), "O"),
		ProblemGen.label(Vector2(xi + 1.2, q * 0.35), "y = −%dx + %d" % [p, q] if p > 1 else "y = −x + %d" % q),
	]}
	return {
		"q": "直線 y = %sx + %d と x 軸、y 軸で囲まれた三角形の面積を求めなさい。" % ["−%d" % p if p > 1 else "−", q],
		"answer": ans, "unit": "",
		"hint1": "x 軸との交点(y = 0)と、y 軸との交点(x = 0)を求めよう。",
		"hint2": "交点は (%d, 0) と (0, %d)。面積 = %d × %d ÷ 2" % [xi, q, xi, q],
		"expl": "x 切片 %d、y 切片 %d。面積 = %d × %d ÷ 2 = %s です。" % [xi, q, xi, q, ProblemGen.fmt(ans)],
		"fig": fig2,
	}


## j10: ヒポクラテスの月(円がらみの難問。答えは意外ときれい)
static func _j10(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	if tier == 0:
		# ウォームアップ: 同心円のリング
		var r_out := rng.randi_range(4, 13)
		var r_in := rng.randi_range(1, r_out - 2)
		var ans := 3.14 * (r_out * r_out - r_in * r_in)
		var fig := {"shapes": [
			ProblemGen.circle(Vector2.ZERO, float(r_out), ProblemGen.FILL_ACCENT),
			ProblemGen.circle(Vector2.ZERO, float(r_in), Color(0.06, 0.09, 0.16, 1.0), Color.WHITE, 3.0),
			ProblemGen.seg(Vector2.ZERO, _on_circle(float(r_out), 40.0), ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.seg(Vector2.ZERO, Vector2(-float(r_in), 0), ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.label(_on_circle(float(r_out), 40.0) * 0.6 + Vector2(0.4, -0.6), str(r_out)),
			ProblemGen.label(Vector2(-r_in * 0.5, 0.7), str(r_in)),
		]}
		return {
			"q": "半径 %d の円から半径 %d の円をくりぬいたドーナツ形の面積を求めなさい。円周率は 3.14 とします。" % [r_out, r_in],
			"answer": ans, "unit": "", "tol": 0.02,
			"hint1": "大きい円の面積から小さい円の面積を引こう。",
			"hint2": "3.14 × (%d² − %d²)" % [r_out, r_in],
			"expl": "3.14 × (%d − %d) = 3.14 × %d = %s です。" % [r_out * r_out, r_in * r_in, r_out * r_out - r_in * r_in, ProblemGen.fmt(ans)],
			"fig": fig,
		}
	# ヒポクラテスの月: 三日月 2 つの面積の和 = 直角三角形の面積(π が消える!)
	var t: Array = TRIPLES[rng.randi_range(0, 4)]
	var a: int = t[0]
	var b: int = t[1]
	var ans2 := a * b / 2.0
	var v := [Vector2(0, float(a)), Vector2(0, 0), Vector2(float(b), 0)]
	var fig2 := {"shapes": [
		{"t": "lune", "a": float(a), "b": float(b)},
		ProblemGen.poly(v, null, Color.WHITE, 3.0),
		ProblemGen.right(v[1], v[0], v[2]),
		ProblemGen.side_label(v[1], v[2], str(b), 1.0),
		ProblemGen.side_label(v[0], v[1], str(a), -1.0),
	]}
	var hyp := sqrt(float(a * a + b * b))
	var mid := Vector2(b * 0.5, a * 0.5)
	var th1 := rad_to_deg(atan2(-float(a), float(b)))
	var th2 := rad_to_deg(atan2(float(a), -float(b)))
	var steps := [
		{"say": "まず、小さい半円 2 つと三角形を、ぜんぶ色でぬってみる。",
			"add": [ProblemGen.sector(Vector2(0, a * 0.5), a * 0.5, 90.0, 270.0, Color(1.0, 0.85, 0.3, 0.3)),
				ProblemGen.sector(Vector2(b * 0.5, 0), b * 0.5, 180.0, 360.0, Color(1.0, 0.85, 0.3, 0.3)),
				ProblemGen.poly(v, Color(0.35, 0.75, 1.0, 0.3))]},
		{"say": "ここから、斜辺を直径とする大きい半円(緑の弧)を引くと、三日月 2 つだけが残る!",
			"add": [ProblemGen.arc(mid, hyp * 0.5, th1, th2, Color(0.45, 1.0, 0.6, 0.9), 4.0)]},
		{"say": "式は 半円(%d) + 半円(%d) + 三角形 − 半円(斜辺)。三平方の定理 %d² + %d² = 斜辺² で、π の項がぜんぶ消える!" % [a, b, a, b]},
		{"say": "残るのは三角形の面積だけ。%d × %d ÷ 2 = %s。入力してみよう!" % [b, a, ProblemGen.fmt(ans2)]},
	]
	return {
		"q": "直角三角形の各辺を直径とする半円をかきました(斜辺の半円は外側の大きい半円)。色のついた 2 つの三日月の面積の和を求めなさい。",
		"answer": ans2, "unit": "",
		"hint1": "小さい半円 2 つ + 三角形 − 大きい半円 で求まる。三平方の定理で π の項が消えるよ!",
		"hint2": "実は 三日月の和 = 三角形の面積。%d × %d ÷ 2" % [b, a],
		"steps": steps,
		"expl": "半円(%d)+半円(%d)+三角形−半円(斜辺) を計算すると、三平方の定理で π が消えて三角形の面積だけ残ります。答えは %d × %d ÷ 2 = %s(ヒポクラテスの月)。" % [a, b, b, a, ProblemGen.fmt(ans2)],
		"fig": fig2,
	}


## j11: 星形五角形のとがった角(和は 180°)
static func _j11(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	var step := 5 if kind == 0 else 1
	var tips: Array = []
	var x := 0
	# 4 つのとがった角を決め、残り 1 つが x。ありえない形にならない範囲で選び直す
	while true:
		tips = []
		var sum4 := 0
		for i in 4:
			var t := step * rng.randi_range(20 / step, 48 / step)
			tips.append(t)
			sum4 += t
		x = 180 - sum4
		if x >= 15 and x <= 70:
			break
	tips.append(x)
	# 星のとがった角は「向かいの弧の半分」。弧(となり合う頂点の間)を
	# gap[(i+2) % 5] = 2 × tips[i] にすれば、指定どおりの角の星が描ける
	var gaps: Array = [0, 0, 0, 0, 0]
	for i in 5:
		gaps[(i + 2) % 5] = 2 * tips[i]
	var pts: Array = []
	var deg := 90.0
	for i in 5:
		pts.append(Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg))) * 5.0)
		deg += float(gaps[i])
	var shapes: Array = []
	for i in 5:
		shapes.append(ProblemGen.seg(pts[i], pts[(i + 2) % 5], Color.WHITE, 3.5))
	for i in 5:
		var lbl := "x" if i == 4 else "%d°" % int(tips[i])
		shapes.append(ProblemGen.ang(pts[i], pts[(i + 2) % 5], pts[(i + 3) % 5], lbl))
	return {
		"q": "星形の 5 つのとがった角のうち 4 つが図の通りのとき、角 x は何度ですか。",
		"answer": float(x), "unit": "度",
		"hint1": "星形五角形のとがった 5 つの角の和は、いつでも 180° だよ。",
		"hint2": "x = 180 − (%d + %d + %d + %d)" % [tips[0], tips[1], tips[2], tips[3]],
		"expl": "とがった角の和は 180°。x = 180 − %d = %d° です。" % [180 - x, x],
		"fig": {"shapes": shapes},
	}


## j12: 弧の長さの比と円周角(円周角は弧に比例する)
static func _j12(rng: RandomNumberGenerator, _kind: int) -> Dictionary:
	# 比 p:q:r で、答えの角 180p/(p+q+r) が整数になる組だけ使う
	var p := 0
	var q := 0
	var r := 0
	var x := 0
	while true:
		p = rng.randi_range(1, 6)
		q = rng.randi_range(1, 6)
		r = rng.randi_range(1, 6)
		var sum := p + q + r
		if (180 * p) % sum == 0 and 180 * p / sum >= 20 and 180 * p / sum <= 120:
			x = 180 * p / sum
			break
	var sum := p + q + r
	var rr := 5.0
	# A から反時計回りに、弧 AB = p、弧 BC = q、弧 CA = r の割合で置く
	var deg_a := 90.0
	var deg_b := deg_a + 360.0 * p / sum
	var deg_c := deg_b + 360.0 * q / sum
	var pa := Vector2(cos(deg_to_rad(deg_a)), sin(deg_to_rad(deg_a))) * rr
	var pb := Vector2(cos(deg_to_rad(deg_b)), sin(deg_to_rad(deg_b))) * rr
	var pc := Vector2(cos(deg_to_rad(deg_c)), sin(deg_to_rad(deg_c))) * rr
	var mid_ab := deg_a + 180.0 * p / sum
	var mid_bc := deg_b + 180.0 * q / sum
	var mid_ca := deg_c + 180.0 * r / sum
	var fig := {"shapes": [
		ProblemGen.circle(Vector2.ZERO, rr),
		ProblemGen.poly([pa, pb, pc], ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
		ProblemGen.label(pa * 1.18, "A"), ProblemGen.label(pb * 1.18, "B"), ProblemGen.label(pc * 1.18, "C"),
		ProblemGen.label(Vector2(cos(deg_to_rad(mid_ab)), sin(deg_to_rad(mid_ab))) * (rr + 0.9), str(p), ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(Vector2(cos(deg_to_rad(mid_bc)), sin(deg_to_rad(mid_bc))) * (rr + 0.9), str(q), ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(Vector2(cos(deg_to_rad(mid_ca)), sin(deg_to_rad(mid_ca))) * (rr + 0.9), str(r), ProblemGen.COL_YELLOW, 26),
		ProblemGen.ang(pc, pa, pb, "x"),
	]}
	return {
		"q": "円周上の点 A・B・C は、弧の長さの比が AB : BC : CA = %d : %d : %d になっています。角 x(∠ACB)は何度ですか。" % [p, q, r],
		"answer": float(x), "unit": "度",
		"hint1": "円周角は弧の長さに比例する。円周ぜんぶの弧に対する円周角の合計は 180° だよ。",
		"hint2": "x = 180 × %d ÷ (%d + %d + %d)" % [p, p, q, r],
		"expl": "∠ACB は弧 AB に対する円周角。x = 180 × %d/%d = %d° です。" % [p, sum, x],
		"fig": fig,
	}


# =========================================================
# 挑戦モード用の追加解法(高校受験の入試定番から)
# =========================================================

## j1-交点: 1 点で交わる 3 本の直線(一直線 180° と対頂角)
static func _j1_three(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(30, 75)
	var b := rng.randi_range(30, 75)
	var x := 180 - a - b
	while x < 25:
		b = rng.randi_range(30, 75)
		x = 180 - a - b
	var r := 6.0
	var d1 := Vector2(1, 0)
	var d2 := Vector2(cos(deg_to_rad(float(a))), sin(deg_to_rad(float(a))))
	var d3 := Vector2(cos(deg_to_rad(float(a + b))), sin(deg_to_rad(float(a + b))))
	var fig := {"shapes": [
		ProblemGen.seg(-d1 * r, d1 * r), ProblemGen.seg(-d2 * r, d2 * r), ProblemGen.seg(-d3 * r, d3 * r),
		ProblemGen.ang(Vector2.ZERO, d1, d2, "%d°" % a, 1.3),
		ProblemGen.ang(Vector2.ZERO, d2, d3, "%d°" % b, 1.9),
		ProblemGen.ang(Vector2.ZERO, d3, -d1, "x", 1.3),
	]}
	return {
		"q": "3 本の直線が 1 点で交わっています。角 x は何度ですか。",
		"answer": float(x), "unit": "度",
		"hint1": "上半分の 3 つの角をたすと一直線で 180° だよ。",
		"hint2": "x = 180 − %d − %d" % [a, b],
		"expl": "一直線の上側で %d + %d + x = 180。x = %d° です。" % [a, b, x],
		"fig": fig,
	}


## j2-逆算: 頂点の角がわかっていて、下の角を求める
static func _j2_rev(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(35, 75)
	var b := rng.randi_range(35, 75)
	var apex := 180 - a - b
	while apex < 30 or apex > 110:
		b = rng.randi_range(35, 75)
		apex = 180 - a - b
	var w := 12.0
	var pa := Vector2(6.0, 5.0)
	var pb := Vector2(6.0 - 5.0 / tan(deg_to_rad(float(a))), 0.0)
	var pc := Vector2(6.0 + 5.0 / tan(deg_to_rad(float(b))), 0.0)
	var fig := {"shapes": [
		ProblemGen.seg(Vector2(-2, 5), Vector2(w, 5)), ProblemGen.seg(Vector2(-2, 0), Vector2(w, 0)),
		ProblemGen.label(Vector2(w + 0.7, 5), "l"), ProblemGen.label(Vector2(w + 0.7, 0), "m"),
		ProblemGen.poly([pa, pb, pc], ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
		ProblemGen.ang(pa, Vector2(-2, 5), pb, "%d°" % a),
		ProblemGen.ang(pa, pb, pc, "%d°" % apex),
		ProblemGen.ang(pc, pa, pb, "x"),
	]}
	return {
		"q": "直線 l と m は平行です。三角形の角 x は何度ですか。",
		"answer": float(b), "unit": "度",
		"hint1": "%d° は錯角で三角形の左下の角に移せる。あとは内角の和だよ。" % a,
		"hint2": "x = 180 − %d − %d" % [a, apex],
		"expl": "左下の内角は錯角で %d°。x = 180 − %d − %d = %d° です。" % [a, a, apex, b],
		"fig": fig,
	}


## j2-二等辺: 平行線の間の二等辺三角形
static func _j2_iso(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(35, 74)
	var x := 180 - 2 * a
	var w := 12.0
	var pa := Vector2(6.0, 5.0)
	var pb := Vector2(6.0 - 5.0 / tan(deg_to_rad(float(a))), 0.0)
	var pc := Vector2(6.0 + 5.0 / tan(deg_to_rad(float(a))), 0.0)
	var fig := {"shapes": [
		ProblemGen.seg(Vector2(-2, 5), Vector2(w, 5)), ProblemGen.seg(Vector2(-2, 0), Vector2(w, 0)),
		ProblemGen.label(Vector2(w + 0.7, 5), "l"), ProblemGen.label(Vector2(w + 0.7, 0), "m"),
		ProblemGen.poly([pa, pb, pc], ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
		ProblemGen.tick(pa, pb), ProblemGen.tick(pa, pc),
		ProblemGen.ang(pa, Vector2(-2, 5), pb, "%d°" % a),
		ProblemGen.ang(pa, pb, pc, "x"),
	]}
	return {
		"q": "直線 l と m は平行で、三角形は AB = AC の二等辺三角形です。角 x は何度ですか。",
		"answer": float(x), "unit": "度",
		"hint1": "%d° は錯角で底角に移る。二等辺だからもう一方の底角も %d° だよ。" % [a, a],
		"hint2": "x = 180 − %d × 2" % a,
		"expl": "底角は錯角と二等辺の性質からどちらも %d°。x = 180 − 2×%d = %d° です。" % [a, a, x],
		"fig": fig,
	}


## j3-二等辺: 半径 2 本がつくる二等辺三角形と円周角
static func _j3_iso(rng: RandomNumberGenerator) -> Dictionary:
	var t := rng.randi_range(20, 70)
	var x := 90 - t
	var r := 5.0
	var half := 90.0 - t
	var pa := _on_circle(r, 270.0 - half)
	var pb := _on_circle(r, 270.0 + half)
	var pt := _on_circle(r, 90.0)
	var fig := {"shapes": [
		ProblemGen.circle(Vector2.ZERO, r),
		ProblemGen.poly([Vector2.ZERO, pa, pb], null, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.seg(pt, pa, ProblemGen.COL_DIM, 3.0), ProblemGen.seg(pt, pb, ProblemGen.COL_DIM, 3.0),
		ProblemGen.circle(Vector2.ZERO, 0.12, Color.WHITE),
		ProblemGen.label(Vector2(0.7, 0.5), "O"),
		ProblemGen.tick(Vector2.ZERO, pa), ProblemGen.tick(Vector2.ZERO, pb),
		ProblemGen.ang(pa, Vector2.ZERO, pb, "%d°" % t),
		ProblemGen.ang(pt, pa, pb, "x"),
	]}
	return {
		"q": "OA・OB は円 O の半径です。∠OAB = %d° のとき、円周角 x は何度ですか。" % t,
		"answer": float(x), "unit": "度",
		"hint1": "OA = OB だから三角形 OAB は二等辺。まず中心角 ∠AOB を求めよう。",
		"hint2": "中心角 = 180 − %d×2 = %d。x はその半分。" % [t, 180 - 2 * t],
		"expl": "中心角 = 180 − 2×%d = %d°。円周角はその半分で x = %d° です。" % [t, 180 - 2 * t, x],
		"fig": fig,
	}


## j4-接弦: 接線と弦のつくる角(接弦定理)
static func _j4_tanchord(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(25, 70)
	var c := Vector2(0, 5)
	var r := 5.0
	var p := Vector2(0, 0)
	var q: Vector2 = c + Vector2(cos(deg_to_rad(-90.0 + 2 * a)), sin(deg_to_rad(-90.0 + 2 * a))) * r
	var rr: Vector2 = c + Vector2(cos(deg_to_rad(90.0 + a)), sin(deg_to_rad(90.0 + a))) * r
	var fig := {"shapes": [
		ProblemGen.circle(c, r),
		ProblemGen.seg(Vector2(-6.5, 0), Vector2(6.5, 0), ProblemGen.COL_DIM, 3.5),
		ProblemGen.poly([p, q, rr], null, Color.WHITE, 3.0),
		ProblemGen.label(p + Vector2(-0.5, -0.8), "P"),
		ProblemGen.label(q + (q - c).normalized() * 0.9, "Q"),
		ProblemGen.label(rr + (rr - c).normalized() * 0.9, "R"),
		ProblemGen.ang(p, Vector2(6.5, 0), q, "%d°" % a),
		ProblemGen.ang(rr, q, p, "x"),
	]}
	return {
		"q": "直線は点 P で円に接しています。接線と弦 PQ のつくる角が %d° のとき、円周角 x(∠PRQ)は何度ですか。" % a,
		"answer": float(a), "unit": "度",
		"hint1": "接線と弦のつくる角は、その弦に対する円周角と等しい(接弦定理)。",
		"hint2": "x = %d°(そのまま等しい)" % a,
		"expl": "接弦定理より x = %d° です。" % a,
		"fig": fig,
	}


## j5-対角線: 長方形の対角線(三平方の応用)
static func _j5_diag(rng: RandomNumberGenerator) -> Dictionary:
	var t: Array = TRIPLES[rng.randi_range(0, TRIPLES.size() - 1)]
	var a: int = t[0]
	var b: int = t[1]
	var c: int = t[2]
	var fig := {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(b, 0), Vector2(b, a), Vector2(0, a)], ProblemGen.FILL_MAIN),
		ProblemGen.seg(Vector2(0, 0), Vector2(b, a), ProblemGen.COL_YELLOW, 3.5),
		ProblemGen.side_label(Vector2(0, 0), Vector2(b, 0), str(b), 1.0),
		ProblemGen.side_label(Vector2(b, 0), Vector2(b, a), str(a), -1.0),
	]}
	return {
		"q": "たて %d、よこ %d の長方形の対角線の長さを求めなさい。" % [a, b],
		"answer": float(c), "unit": "",
		"hint1": "対角線で長方形を切ると直角三角形。三平方の定理が使えるよ。",
		"hint2": "対角線² = %d² + %d² = %d" % [a, b, c * c],
		"expl": "対角線² = %d² + %d² = %d。対角線 = %d です。" % [a, b, c * c, c],
		"fig": fig,
	}


## j5-距離: 座標平面の 2 点間の距離
static func _j5_dist(rng: RandomNumberGenerator) -> Dictionary:
	var small := [[3, 4, 5], [6, 8, 10], [5, 12, 13], [9, 12, 15], [8, 6, 10], [4, 3, 5]]
	var t: Array = small[rng.randi_range(0, small.size() - 1)]
	var dx: int = t[0]
	var dy: int = t[1]
	var c: int = t[2]
	var x0 := rng.randi_range(0, 2)
	var y0 := rng.randi_range(0, 2)
	var pa := Vector2(x0, y0)
	var pb := Vector2(x0 + dx, y0 + dy)
	var corner := Vector2(x0 + dx, y0)
	var fig := {"shapes": [
		ProblemGen.grid(Vector2(-1, -1), pb + Vector2(1.5, 1.5)),
		ProblemGen.axes(Vector2(-1, -1), pb + Vector2(1.5, 1.5)),
		ProblemGen.seg(pa, pb, ProblemGen.COL_YELLOW, 3.5),
		ProblemGen.seg(pa, corner, ProblemGen.COL_DIM, 2.5, true),
		ProblemGen.seg(corner, pb, ProblemGen.COL_DIM, 2.5, true),
		ProblemGen.circle(pa, 0.14, Color.WHITE), ProblemGen.circle(pb, 0.14, Color.WHITE),
		ProblemGen.label(pa + Vector2(-0.9, -0.5), "A"),
		ProblemGen.label(pb + Vector2(0.9, 0.4), "B"),
	]}
	return {
		"q": "2 点 A(%d, %d)、B(%d, %d) の間の距離を求めなさい。" % [x0, y0, x0 + dx, y0 + dy],
		"answer": float(c), "unit": "",
		"hint1": "よこに %d、たてに %d 進む直角三角形を作って三平方の定理だよ。" % [dx, dy],
		"hint2": "距離² = %d² + %d² = %d" % [dx, dy, c * c],
		"expl": "距離 = √(%d² + %d²) = %d です。" % [dx, dy, c],
		"fig": fig,
	}


## j7-弓形: 四分円から三角形を引いた弓形の面積
static func _j7_segment(rng: RandomNumberGenerator) -> Dictionary:
	var r := 2 * rng.randi_range(2, 6)
	var ans := 3.14 * r * r / 4.0 - r * r / 2.0
	var fig := {"shapes": [
		ProblemGen.sector(Vector2.ZERO, float(r), 0.0, 90.0, ProblemGen.FILL_ACCENT, Color.WHITE),
		ProblemGen.poly([Vector2.ZERO, Vector2(r, 0), Vector2(0, r)], Color(0.06, 0.09, 0.16, 0.9), Color.WHITE, 3.0),
		ProblemGen.seg(Vector2(r, 0), Vector2(0, r), ProblemGen.COL_YELLOW, 3.5),
		ProblemGen.label(Vector2(r * 0.55, -0.9), "%d" % r),
	]}
	return {
		"q": "半径 %d、中心角 90° のおうぎ形から、2 つの半径と弦で囲まれた三角形を除いた「弓形」の面積を求めなさい。円周率は 3.14 とします。" % r,
		"answer": ans, "unit": "", "tol": 0.02,
		"hint1": "弓形 = おうぎ形 − 直角二等辺三角形 だよ。",
		"hint2": "3.14×%d²÷4 − %d×%d÷2" % [r, r, r],
		"expl": "おうぎ形 %s − 三角形 %s = %s です。" % [ProblemGen.fmt(3.14 * r * r / 4.0), ProblemGen.fmt(r * r / 2.0), ProblemGen.fmt(ans)],
		"fig": fig,
	}


## j7-半円: 半円から内接する三角形を除いた面積
static func _j7_semi(rng: RandomNumberGenerator) -> Dictionary:
	var opts := [4, 6, 8, 10, 12]
	var r: int = opts[rng.randi_range(0, opts.size() - 1)]
	var half_area := 3.14 * r * r / 2.0
	var tri := float(r) * r
	var ans := half_area - tri
	var fig := {"shapes": [
		ProblemGen.sector(Vector2.ZERO, float(r), 0.0, 180.0, ProblemGen.FILL_ACCENT, Color.WHITE),
		ProblemGen.poly([Vector2(-r, 0), Vector2(float(r), 0), Vector2(0, float(r))], Color(0.06, 0.09, 0.16, 0.9), Color.WHITE, 3.0),
		ProblemGen.side_label(Vector2(-r, 0), Vector2(float(r), 0), "%d" % (2 * r), 1.0),
	]}
	return {
		"q": "直径 %d の半円から、直径を底辺とし円周上の頂点がいちばん高い位置にある三角形を切り取った、残りの面積を求めなさい。円周率は 3.14 とします。" % (2 * r),
		"answer": ans, "unit": "", "tol": 0.02,
		"hint1": "三角形の高さは半径と同じ %d だよ。" % r,
		"hint2": "3.14×%d²÷2 − %d×%d÷2" % [r, 2 * r, r],
		"expl": "半円 %s − 三角形 %s = %s です。" % [ProblemGen.fmt(half_area), ProblemGen.fmt(tri), ProblemGen.fmt(ans)],
		"fig": fig,
	}


## j8-辺: 面積比から対応する辺を求める(比の逆向き)
static func _j8_side(rng: RandomNumberGenerator) -> Dictionary:
	var m := rng.randi_range(2, 4)
	var n := rng.randi_range(m + 1, 6)
	var k := rng.randi_range(1, 3)
	var s1 := m * m * k
	var s2 := n * n * k
	var j := rng.randi_range(2, 5)
	var side_small := m * j
	var side_big := n * j
	var v1: Array = ProblemGen.tri_from_sides(6.0, 5.0, 4.0)
	var scale := float(n) / float(m) * 0.85
	var v2: Array = []
	for pt in v1:
		v2.append(Vector2(pt.x * scale + 8.0, pt.y * scale))
	var fig := {"shapes": [
		ProblemGen.poly(v1, ProblemGen.FILL_MAIN),
		ProblemGen.poly(v2, ProblemGen.FILL_ACCENT),
		ProblemGen.label(Vector2(3.0, -1.2), "面積 %d・辺 %d" % [s1, side_small], null, 24),
		ProblemGen.label(Vector2(8.0 + 3.0 * scale, -1.2), "面積 %d・辺 x" % s2, null, 24),
	]}
	return {
		"q": "相似な 2 つの三角形の面積は %d と %d です。小さい方の 1 辺が %d のとき、大きい方の対応する辺 x を求めなさい。" % [s1, s2, side_small],
		"answer": float(side_big), "unit": "",
		"hint1": "面積比 %d : %d は相似比の 2 乗。相似比は %d : %d だよ。" % [s1, s2, m, n],
		"hint2": "x = %d × %d ÷ %d" % [side_small, n, m],
		"expl": "面積比 %d:%d → 相似比 %d:%d。x = %d×%d/%d = %d です。" % [s1, s2, m, n, side_small, n, m, side_big],
		"fig": fig,
	}


## j8-周: 相似な図形の周の長さ(周は相似比そのまま)
static func _j8_perim(rng: RandomNumberGenerator) -> Dictionary:
	var m := rng.randi_range(2, 4)
	var n := rng.randi_range(m + 1, 6)
	var j := rng.randi_range(3, 8)
	var p_small := m * j
	var p_big := n * j
	var v1: Array = ProblemGen.tri_from_sides(6.0, 5.0, 4.0)
	var scale := float(n) / float(m) * 0.85
	var v2: Array = []
	for pt in v1:
		v2.append(Vector2(pt.x * scale + 8.0, pt.y * scale))
	var fig := {"shapes": [
		ProblemGen.poly(v1, ProblemGen.FILL_MAIN),
		ProblemGen.poly(v2, ProblemGen.FILL_ACCENT),
		ProblemGen.label(Vector2(3.0, -1.2), "周 %d" % p_small, null, 24),
		ProblemGen.label(Vector2(8.0 + 3.0 * scale, -1.2), "周 x", null, 24),
		ProblemGen.label(Vector2(7.0, 6.8), "相似比 %d : %d" % [m, n]),
	]}
	return {
		"q": "相似比が %d : %d の相似な三角形があります。小さい方の周の長さが %d のとき、大きい方の周の長さ x を求めなさい。" % [m, n, p_small],
		"answer": float(p_big), "unit": "",
		"hint1": "周の長さの比は相似比とまったく同じ(2 乗するのは面積だけ)。",
		"hint2": "x = %d × %d ÷ %d" % [p_small, n, m],
		"expl": "周の比 = 相似比 %d:%d。x = %d×%d/%d = %d です。" % [m, n, p_small, n, m, p_big],
		"fig": fig,
	}


## j9-囲み: 格子点の三角形(囲む長方形から引く)
static func _j9_shoelace(rng: RandomNumberGenerator) -> Dictionary:
	var pa := Vector2(rng.randi_range(0, 2), rng.randi_range(0, 2))
	var pb := Vector2(rng.randi_range(4, 7), rng.randi_range(0, 3))
	var pc := Vector2(rng.randi_range(1, 5), rng.randi_range(4, 7))
	var det := (pb.x - pa.x) * (pc.y - pa.y) - (pc.x - pa.x) * (pb.y - pa.y)
	while absf(det) < 8.0:
		pc = Vector2(rng.randi_range(1, 5), rng.randi_range(4, 7))
		det = (pb.x - pa.x) * (pc.y - pa.y) - (pc.x - pa.x) * (pb.y - pa.y)
	var ans := absf(det) / 2.0
	var lo := Vector2(minf(pa.x, minf(pb.x, pc.x)) - 1, minf(pa.y, minf(pb.y, pc.y)) - 1)
	var hi := Vector2(maxf(pa.x, maxf(pb.x, pc.x)) + 1, maxf(pa.y, maxf(pb.y, pc.y)) + 1)
	var fig := {"shapes": [
		ProblemGen.grid(lo, hi), ProblemGen.axes(lo, hi),
		ProblemGen.poly([pa, pb, pc], ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
		ProblemGen.label(pa + Vector2(-0.7, -0.5), "A"),
		ProblemGen.label(pb + Vector2(0.8, -0.4), "B"),
		ProblemGen.label(pc + Vector2(0, 0.9), "C"),
	]}
	return {
		"q": "3 点 A(%d, %d)、B(%d, %d)、C(%d, %d) を頂点とする三角形の面積を求めなさい。" % [int(pa.x), int(pa.y), int(pb.x), int(pb.y), int(pc.x), int(pc.y)],
		"answer": ans, "unit": "",
		"hint1": "三角形を囲む長方形をかいて、まわりの直角三角形を引くと求められるよ。",
		"hint2": "囲む長方形 − 角の直角三角形 3 つ",
		"expl": "囲み法(または公式)で面積 = %s です。" % ProblemGen.fmt(ans),
		"fig": fig,
	}


## j10-半円: 大きい半円から小さい半円 2 つを引く
static func _j10_semi(rng: RandomNumberGenerator) -> Dictionary:
	var r := 2 * rng.randi_range(2, 6)
	var ans := 3.14 * r * r / 4.0     # πR²/2 − 2·π(R/2)²/2 = πR²/4
	var half := r / 2
	var fig := {"shapes": [
		ProblemGen.sector(Vector2.ZERO, float(r), 0.0, 180.0, ProblemGen.FILL_ACCENT, Color.WHITE),
		ProblemGen.sector(Vector2(-half, 0), float(half), 0.0, 180.0, Color(0.06, 0.09, 0.16, 0.95), Color.WHITE),
		ProblemGen.sector(Vector2(half, 0), float(half), 0.0, 180.0, Color(0.06, 0.09, 0.16, 0.95), Color.WHITE),
		ProblemGen.side_label(Vector2(-r, 0), Vector2(float(r), 0), "%d" % (2 * r), 1.0),
	]}
	return {
		"q": "直径 %d の半円から、直径 %d の半円を 2 つ切り取った、残りの面積を求めなさい。円周率は 3.14 とします。" % [2 * r, r],
		"answer": ans, "unit": "", "tol": 0.02,
		"hint1": "小さい半円の半径は %d。大きい半円から 2 つ分を引こう。" % half,
		"hint2": "3.14×%d²÷2 − 3.14×%d²÷2 × 2" % [r, half],
		"expl": "%s − %s×2 = %s です。" % [ProblemGen.fmt(3.14 * r * r / 2.0), ProblemGen.fmt(3.14 * half * half / 2.0), ProblemGen.fmt(ans)],
		"fig": fig,
	}


## j11-六芒星: 星形六角形は 2 つの三角形の重なり
static func _j11_hex(rng: RandomNumberGenerator) -> Dictionary:
	# 偶数番の頂点の三角形と奇数番の三角形、それぞれ先端の和は 180°
	var tips: Array = []
	var gaps: Array = []
	while true:
		var t0 := rng.randi_range(40, 80)
		var t2 := rng.randi_range(40, 80)
		var t4 := 180 - t0 - t2
		var t1 := rng.randi_range(40, 80)
		var t3 := rng.randi_range(40, 80)
		var t5 := 180 - t1 - t3
		if t4 < 30 or t5 < 25 or t5 > 95:
			continue
		tips = [t0, t1, t2, t3, t4, t5]
		# 弧の長さを逆算(g2 を自由に選び、正になる組を探す)
		var found := false
		for g2 in range(20, 2 * t0 - 19):
			var g3 := 2 * t0 - g2
			var g4 := 2 * t1 - g3
			var g5 := 2 * t2 - g4
			var g0 := 2 * t3 - g5
			var g1 := 2 * t4 - g0
			if g3 >= 20 and g4 >= 20 and g5 >= 20 and g0 >= 20 and g1 >= 20:
				gaps = [g0, g1, g2, g3, g4, g5]
				found = true
				break
		if found:
			break
	var pts: Array = []
	var deg := 90.0
	for i in 6:
		pts.append(Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg))) * 5.0)
		deg += float(gaps[i])
	var shapes: Array = []
	for i in 6:
		shapes.append(ProblemGen.seg(pts[i], pts[(i + 2) % 6], Color.WHITE, 3.0))
	for i in 6:
		var lbl := "x" if i == 5 else "%d°" % int(tips[i])
		shapes.append(ProblemGen.ang(pts[i], pts[(i + 2) % 6], pts[(i + 4) % 6], lbl))
	return {
		"q": "星形六角形(六芒星)のとがった 6 つの角のうち 5 つが図の通りのとき、角 x は何度ですか。",
		"answer": float(tips[5]), "unit": "度",
		"hint1": "六芒星は 2 つの三角形が重なった形。x と同じ三角形の先端は、1 つおきの 2 か所だよ。",
		"hint2": "x = 180 − %d − %d" % [tips[1], tips[3]],
		"expl": "x をふくむ三角形の先端は %d° と %d°。x = 180 − %d − %d = %d° です。" % [tips[1], tips[3], tips[1], tips[3], tips[5]],
		"fig": {"shapes": shapes},
	}


## j12-中心角: 弧の比から中心角を求める
static func _j12_central(rng: RandomNumberGenerator) -> Dictionary:
	var p := 0
	var q := 0
	var r := 0
	var x := 0
	while true:
		p = rng.randi_range(1, 6)
		q = rng.randi_range(1, 6)
		r = rng.randi_range(1, 6)
		var sum := p + q + r
		if (360 * p) % sum == 0 and 360 * p / sum >= 40 and 360 * p / sum <= 160:
			x = 360 * p / sum
			break
	var sum := p + q + r
	var rr := 5.0
	var deg_a := 90.0
	var deg_b := deg_a + 360.0 * p / sum
	var deg_c := deg_b + 360.0 * q / sum
	var pa := _on_circle(rr, deg_a)
	var pb := _on_circle(rr, deg_b)
	var pc := _on_circle(rr, deg_c)
	var mid_ab := deg_a + 180.0 * p / sum
	var mid_bc := deg_b + 180.0 * q / sum
	var mid_ca := deg_c + 180.0 * r / sum
	var fig := {"shapes": [
		ProblemGen.circle(Vector2.ZERO, rr),
		ProblemGen.poly([pa, pb, pc], null, ProblemGen.COL_DIM, 2.5),
		ProblemGen.seg(Vector2.ZERO, pa, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.seg(Vector2.ZERO, pb, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.circle(Vector2.ZERO, 0.12, Color.WHITE),
		ProblemGen.label(Vector2(0.8, -0.5), "O"),
		ProblemGen.label(pa * 1.18, "A"), ProblemGen.label(pb * 1.18, "B"), ProblemGen.label(pc * 1.18, "C"),
		ProblemGen.label(_on_circle(rr + 0.9, mid_ab), str(p), ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(_on_circle(rr + 0.9, mid_bc), str(q), ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(_on_circle(rr + 0.9, mid_ca), str(r), ProblemGen.COL_YELLOW, 26),
		ProblemGen.ang(Vector2.ZERO, pa, pb, "x"),
	]}
	return {
		"q": "円周上の点 A・B・C は、弧の長さの比が AB : BC : CA = %d : %d : %d になっています。中心角 x(∠AOB)は何度ですか。" % [p, q, r],
		"answer": float(x), "unit": "度",
		"hint1": "中心角も弧の長さに比例する。ぐるっと 1 周で 360° だよ。",
		"hint2": "x = 360 × %d ÷ %d" % [p, sum],
		"expl": "x = 360 × %d/%d = %d° です。" % [p, sum, x],
		"fig": fig,
	}


## j12-別頂点: 弧の比から別の頂点の円周角を求める
static func _j12_other(rng: RandomNumberGenerator) -> Dictionary:
	var p := 0
	var q := 0
	var r := 0
	var x := 0
	while true:
		p = rng.randi_range(1, 6)
		q = rng.randi_range(1, 6)
		r = rng.randi_range(1, 6)
		var sum := p + q + r
		if (180 * q) % sum == 0 and 180 * q / sum >= 20 and 180 * q / sum <= 120:
			x = 180 * q / sum
			break
	var sum := p + q + r
	var rr := 5.0
	var deg_a := 90.0
	var deg_b := deg_a + 360.0 * p / sum
	var deg_c := deg_b + 360.0 * q / sum
	var pa := _on_circle(rr, deg_a)
	var pb := _on_circle(rr, deg_b)
	var pc := _on_circle(rr, deg_c)
	var mid_ab := deg_a + 180.0 * p / sum
	var mid_bc := deg_b + 180.0 * q / sum
	var mid_ca := deg_c + 180.0 * r / sum
	var fig := {"shapes": [
		ProblemGen.circle(Vector2.ZERO, rr),
		ProblemGen.poly([pa, pb, pc], ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
		ProblemGen.label(pa * 1.18, "A"), ProblemGen.label(pb * 1.18, "B"), ProblemGen.label(pc * 1.18, "C"),
		ProblemGen.label(_on_circle(rr + 0.9, mid_ab), str(p), ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(_on_circle(rr + 0.9, mid_bc), str(q), ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(_on_circle(rr + 0.9, mid_ca), str(r), ProblemGen.COL_YELLOW, 26),
		ProblemGen.ang(pa, pb, pc, "x"),
	]}
	return {
		"q": "円周上の点 A・B・C は、弧の長さの比が AB : BC : CA = %d : %d : %d になっています。角 x(∠BAC)は何度ですか。" % [p, q, r],
		"answer": float(x), "unit": "度",
		"hint1": "∠BAC は弧 BC に対する円周角。どの弧を見ている角なのかに注意!",
		"hint2": "x = 180 × %d ÷ %d(弧 BC の割合)" % [q, sum],
		"expl": "∠BAC は弧 BC に対する円周角なので x = 180 × %d/%d = %d° です。" % [q, sum, x],
		"fig": fig,
	}
