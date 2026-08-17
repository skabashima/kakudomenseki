class_name GenElementary
## 中学受験レベル(小学校の図形)の問題生成。値は毎回ランダム。
## 円周率は 3.14 で計算する(問題文に明記)。



static func gen(stage_id: String, rng: RandomNumberGenerator, tier: int) -> Dictionary:
	match stage_id:
		"e1": return _e1(rng, tier)
		"e2": return _e2(rng, tier)
		"e3": return _e3(rng, tier)
		"e4": return _e4(rng, tier)
		"e5": return _e5(rng, tier)
		"e6": return _e6(rng, tier)
		"e7": return _e7(rng, tier)
		"e8": return _e8(rng, tier)
		"e9": return _e9(rng, tier)
		"e11": return _e11(rng, tier)
		"e12": return _e12(rng, tier)
		"e13": return _e13(rng, tier)
		"e14": return _e14(rng, tier)
		"e15": return _e15(rng, tier)
		"e16": return _e16(rng, tier)
		"e17": return _e17(rng, tier)
		_: return _e10(rng, tier)


## e1: 三角形の内角(2 つ与えて残りを求める)
static func _e1(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	# 1 問目はキリのいい 5° 刻み、2 問目からは 1° 刻みで無数に出る
	var step := 5 if tier == 0 else 1
	var a := step * rng.randi_range(25 / step, 100 / step)
	var b := step * rng.randi_range(25 / step, 100 / step)
	var x := 180 - a - b
	while x < 25 or x > 110:
		a = step * rng.randi_range(25 / step, 100 / step)
		b = step * rng.randi_range(25 / step, 100 / step)
		x = 180 - a - b
	var v: Array = ProblemGen.tri_from_angles(float(a), float(b), 10.0)
	var fig := {"shapes": [
		ProblemGen.poly(v, ProblemGen.FILL_MAIN),
		ProblemGen.ang(v[1], v[2], v[0], "%d°" % a),
		ProblemGen.ang(v[2], v[0], v[1], "%d°" % b),
		ProblemGen.ang(v[0], v[1], v[2], "x"),
	]}
	return {
		"q": "三角形の角 x は何度ですか。",
		"answer": float(x), "unit": "度",
		"hint1": "三角形の 3 つの角をぜんぶたすと 180° になるよ。",
		"hint2": "x = 180 − %d − %d" % [a, b],
		"expl": "三角形の内角の和は 180°。だから x = 180 − %d − %d = %d° です。" % [a, b, x],
		"fig": fig,
	}


## e2: 正方形・長方形の面積(まわりの長さからの逆算も)
static func _e2(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var kind := rng.randi_range(0, 1) if tier < 2 else 2
	if kind == 0:
		var a := rng.randi_range(3, 15)
		var b := rng.randi_range(3, 15)
		while b == a:
			b = rng.randi_range(3, 15)
		var fig := {"shapes": [
			ProblemGen.poly([Vector2(0, 0), Vector2(a, 0), Vector2(a, b), Vector2(0, b)], ProblemGen.FILL_MAIN),
			ProblemGen.side_label(Vector2(0, 0), Vector2(a, 0), "%dcm" % a, -1.0),
			ProblemGen.side_label(Vector2(a, 0), Vector2(a, b), "%dcm" % b, -1.0),
			ProblemGen.right(Vector2(0, 0), Vector2(a, 0), Vector2(0, b)),
		]}
		return {
			"q": "たて %dcm、よこ %dcm の長方形の面積は何 cm² ですか。" % [b, a],
			"answer": float(a * b), "unit": "cm²",
			"hint1": "長方形の面積 = たて × よこ だよ。",
			"hint2": "%d × %d を計算しよう。" % [b, a],
			"expl": "長方形の面積 = たて × よこ = %d × %d = %d cm² です。" % [b, a, a * b],
			"fig": fig,
		}
	elif kind == 1:
		var a := rng.randi_range(4, 13)
		var fig := {"shapes": [
			ProblemGen.poly([Vector2(0, 0), Vector2(a, 0), Vector2(a, a), Vector2(0, a)], ProblemGen.FILL_MAIN),
			ProblemGen.side_label(Vector2(0, 0), Vector2(a, 0), "%dcm" % a, -1.0),
			ProblemGen.right(Vector2(0, 0), Vector2(a, 0), Vector2(0, a)),
			ProblemGen.tick(Vector2(0, 0), Vector2(a, 0)),
			ProblemGen.tick(Vector2(a, 0), Vector2(a, a)),
		]}
		return {
			"q": "1 辺が %dcm の正方形の面積は何 cm² ですか。" % a,
			"answer": float(a * a), "unit": "cm²",
			"hint1": "正方形の面積 = 1辺 × 1辺 だよ。",
			"hint2": "%d × %d を計算しよう。" % [a, a],
			"expl": "正方形の面積 = 1辺 × 1辺 = %d × %d = %d cm² です。" % [a, a, a * a],
			"fig": fig,
		}
	else:
		# まわりの長さ → 面積(ひとひねり)
		var s := rng.randi_range(4, 12)
		var perim := s * 4
		var fig := {"shapes": [
			ProblemGen.poly([Vector2(0, 0), Vector2(s, 0), Vector2(s, s), Vector2(0, s)], ProblemGen.FILL_ACCENT),
			ProblemGen.label(Vector2(s * 0.5, s * 0.5), "?", ProblemGen.COL_YELLOW, 40),
			ProblemGen.label(Vector2(s * 0.5, -1.2), "まわりの長さ %dcm" % perim),
		]}
		return {
			"q": "まわりの長さが %dcm の正方形があります。この正方形の面積は何 cm² ですか。" % perim,
			"answer": float(s * s), "unit": "cm²",
			"hint1": "まず 1 辺の長さを求めよう。まわりの長さは 1 辺の 4 倍だよ。",
			"hint2": "1 辺 = %d ÷ 4 = %d cm。面積は %d × %d。" % [perim, s, s, s],
			"expl": "1 辺 = %d ÷ 4 = %d cm。面積 = %d × %d = %d cm² です。" % [perim, s, s, s, s * s],
			"fig": fig,
		}


## e3: 三角形の面積(高さを図から読む/面積からの逆算)
static func _e3(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var b := 2 * rng.randi_range(2, 8)       # 底辺(偶数 4..16)
	var h := rng.randi_range(3, 12)
	if tier >= 2 and rng.randf() < 0.6:
		# 逆算: 面積と底辺 → 高さ
		var s := b * h / 2
		var apex := Vector2(b * rng.randf_range(0.3, 0.7), h)
		var fig := {"shapes": [
			ProblemGen.poly([Vector2(0, 0), Vector2(b, 0), apex], ProblemGen.FILL_MAIN),
			ProblemGen.seg(Vector2(apex.x, 0), apex, ProblemGen.COL_YELLOW, 3.0, true),
			ProblemGen.right(Vector2(apex.x, 0), Vector2(b, 0), apex),
			ProblemGen.side_label(Vector2(0, 0), Vector2(b, 0), "%dcm" % b, 1.0),
			ProblemGen.label(Vector2(apex.x + 1.3, h * 0.5), "?cm", ProblemGen.COL_YELLOW),
			ProblemGen.label(Vector2(b * 0.5, h + 1.5), "面積 %dcm²" % s),
		]}
		return {
			"q": "面積が %dcm² で底辺が %dcm の三角形があります。高さは何 cm ですか。" % [s, b],
			"answer": float(h), "unit": "cm",
			"hint1": "面積 = 底辺 × 高さ ÷ 2。高さ = 面積 × 2 ÷ 底辺 で逆算できるよ。",
			"hint2": "高さ = %d × 2 ÷ %d" % [s, b],
			"expl": "高さ = 面積 × 2 ÷ 底辺 = %d × 2 ÷ %d = %d cm です。" % [s, b, h],
			"fig": fig,
		}
	var apex_x := b * rng.randf_range(0.25, 0.75)
	var apex := Vector2(apex_x, h)
	var fig := {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(b, 0), apex], ProblemGen.FILL_MAIN),
		ProblemGen.seg(Vector2(apex_x, 0), apex, ProblemGen.COL_YELLOW, 3.0, true),
		ProblemGen.right(Vector2(apex_x, 0), Vector2(b, 0), apex),
		ProblemGen.side_label(Vector2(0, 0), Vector2(b, 0), "%dcm" % b, 1.0),
		ProblemGen.label(Vector2(apex_x + 1.4, h * 0.5), "%dcm" % h),
	]}
	return {
		"q": "底辺 %dcm、高さ %dcm の三角形の面積は何 cm² ですか。" % [b, h],
		"answer": float(b * h / 2), "unit": "cm²",
		"hint1": "三角形の面積 = 底辺 × 高さ ÷ 2 だよ。",
		"hint2": "%d × %d ÷ 2 を計算しよう。" % [b, h],
		"expl": "三角形の面積 = 底辺 × 高さ ÷ 2 = %d × %d ÷ 2 = %d cm² です。" % [b, h, b * h / 2],
		"fig": fig,
	}


## e4: 平行線と角(錯角/折れ線)
static func _e4(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var w := 12.0
	var step := 5 if tier == 0 else 1
	if tier == 0 or rng.randf() < 0.4:
		# 錯角: 平行線を横切る直線
		var a := step * rng.randi_range(35 / step, 120 / step)
		var rad := deg_to_rad(float(a))
		# 横切る線は下の平行線上 p_low から上の平行線上 p_high へ
		var p_low := Vector2(4, 0)
		var p_high := p_low + Vector2(5.0 / tan(rad), 5.0)
		var fig := {"shapes": [
			ProblemGen.seg(Vector2(0, 0), Vector2(w, 0)), ProblemGen.seg(Vector2(0, 5), Vector2(w, 5)),
			ProblemGen.label(Vector2(w + 0.7, 0), "m"), ProblemGen.label(Vector2(w + 0.7, 5), "l"),
			ProblemGen.seg(p_low - (p_high - p_low) * 0.25, p_high + (p_high - p_low) * 0.25, ProblemGen.COL_DIM, 4.0),
			ProblemGen.ang(p_low, Vector2(w, 0), p_high, "%d°" % a),
			ProblemGen.ang(p_high, p_low, Vector2(0, 5), "x"),
		]}
		return {
			"q": "直線 l と m は平行です。角 x は何度ですか。",
			"answer": float(a), "unit": "度",
			"hint1": "平行線の錯角(Z の形の角)は等しいよ。",
			"hint2": "x は %d° の錯角。そのまま等しい。" % a,
			"expl": "平行線の錯角は等しいので x = %d° です。" % a,
			"fig": fig,
		}
	# 折れ線: 間の点の角 = 上下の角の和
	var a2 := step * rng.randi_range(20 / step, 60 / step)
	var b2 := step * rng.randi_range(20 / step, 60 / step)
	var p := Vector2(6, 2.5)
	# l 上の点(y=5)と m 上の点(y=0)へ、指定角度で線を引く
	var la := deg_to_rad(float(a2))
	var lb := deg_to_rad(float(b2))
	var q_l := p + Vector2(-2.5 / tan(la), 2.5)
	var q_m := p + Vector2(-2.5 / tan(lb), -2.5)
	var fig2 := {"shapes": [
		ProblemGen.seg(Vector2(0, 5), Vector2(w, 5)), ProblemGen.seg(Vector2(0, 0), Vector2(w, 0)),
		ProblemGen.label(Vector2(w + 0.7, 5), "l"), ProblemGen.label(Vector2(w + 0.7, 0), "m"),
		ProblemGen.seg(q_l, p, ProblemGen.COL_DIM), ProblemGen.seg(p, q_m, ProblemGen.COL_DIM),
		ProblemGen.ang(q_l, Vector2(w, 5), p, "%d°" % a2),
		ProblemGen.ang(q_m, p, Vector2(w, 0), "%d°" % b2),
		ProblemGen.ang(p, q_l, q_m, "x"),
	]}
	return {
		"q": "直線 l と m は平行です。折れ線の角 x は何度ですか。",
		"answer": float(a2 + b2), "unit": "度",
		"hint1": "折れ曲がった点を通る、l と m に平行な線を引いてみよう。角が 2 つに分かれるよ。",
		"hint2": "x = %d + %d(錯角で上下に分けられる)" % [a2, b2],
		"expl": "折れ点を通る平行線を引くと、錯角により x は %d° と %d° に分かれます。x = %d + %d = %d° です。" % [a2, b2, a2, b2, a2 + b2],
		"fig": fig2,
	}


## e5: 平行四辺形・台形・ひし形の面積
static func _e5(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var kind: int = [0, 1, 2][mini(tier, 2)] if rng.randf() < 0.7 else rng.randi_range(0, 2)
	if kind == 0:
		var a := rng.randi_range(5, 14)
		var h := rng.randi_range(3, 10)
		var sk := 2.5
		var fig := {"shapes": [
			ProblemGen.poly([Vector2(0, 0), Vector2(a, 0), Vector2(a + sk, h), Vector2(sk, h)], ProblemGen.FILL_MAIN),
			ProblemGen.seg(Vector2(sk, 0), Vector2(sk, h), ProblemGen.COL_YELLOW, 3.0, true),
			ProblemGen.right(Vector2(sk, 0), Vector2(a, 0), Vector2(sk, h)),
			ProblemGen.side_label(Vector2(0, 0), Vector2(a, 0), "%dcm" % a, 1.0),
			ProblemGen.label(Vector2(sk - 1.3, h * 0.5), "%dcm" % h),
		]}
		return {
			"q": "底辺 %dcm、高さ %dcm の平行四辺形の面積は何 cm² ですか。" % [a, h],
			"answer": float(a * h), "unit": "cm²",
			"hint1": "平行四辺形の面積 = 底辺 × 高さ。÷2 はいらないよ。",
			"hint2": "%d × %d を計算しよう。" % [a, h],
			"expl": "平行四辺形の面積 = 底辺 × 高さ = %d × %d = %d cm² です。" % [a, h, a * h],
			"fig": fig,
		}
	elif kind == 1:
		var a := rng.randi_range(3, 8)        # 上底
		var b := rng.randi_range(a + 2, 14)   # 下底
		if (a + b) % 2 == 1:
			b += 1
		var h := rng.randi_range(3, 9)
		var off := (b - a) * 0.5
		var fig := {"shapes": [
			ProblemGen.poly([Vector2(0, 0), Vector2(b, 0), Vector2(off + a, h), Vector2(off, h)], ProblemGen.FILL_MAIN),
			ProblemGen.seg(Vector2(off + a * 0.5, 0), Vector2(off + a * 0.5, h), ProblemGen.COL_YELLOW, 3.0, true),
			ProblemGen.side_label(Vector2(off, h), Vector2(off + a, h), "%dcm" % a, 1.0),
			ProblemGen.side_label(Vector2(0, 0), Vector2(b, 0), "%dcm" % b, 1.0),
			ProblemGen.label(Vector2(off + a * 0.5 + 1.4, h * 0.5), "%dcm" % h),
		]}
		return {
			"q": "上底 %dcm、下底 %dcm、高さ %dcm の台形の面積は何 cm² ですか。" % [a, b, h],
			"answer": float((a + b) * h / 2), "unit": "cm²",
			"hint1": "台形の面積 = (上底 + 下底) × 高さ ÷ 2 だよ。",
			"hint2": "(%d + %d) × %d ÷ 2 を計算しよう。" % [a, b, h],
			"expl": "台形の面積 = (上底+下底)×高さ÷2 = (%d+%d)×%d÷2 = %d cm² です。" % [a, b, h, (a + b) * h / 2],
			"fig": fig,
		}
	else:
		var d1 := 2 * rng.randi_range(2, 8)
		var d2 := 2 * rng.randi_range(2, 8)
		var fig := {"shapes": [
			ProblemGen.poly([Vector2(0, d2 * 0.5), Vector2(d1 * 0.5, 0), Vector2(d1, d2 * 0.5), Vector2(d1 * 0.5, d2)], ProblemGen.FILL_MAIN),
			ProblemGen.seg(Vector2(0, d2 * 0.5), Vector2(d1, d2 * 0.5), ProblemGen.COL_YELLOW, 3.0, true),
			ProblemGen.seg(Vector2(d1 * 0.5, 0), Vector2(d1 * 0.5, d2), ProblemGen.COL_YELLOW, 3.0, true),
			ProblemGen.side_label(Vector2(0, d2 * 0.5), Vector2(d1, d2 * 0.5), "%dcm" % d1, -1.0, 0.9),
			ProblemGen.label(Vector2(d1 * 0.5 + 1.5, d2 * 0.9), "%dcm" % d2),
		]}
		return {
			"q": "対角線が %dcm と %dcm のひし形の面積は何 cm² ですか。" % [d1, d2],
			"answer": float(d1 * d2 / 2), "unit": "cm²",
			"hint1": "ひし形の面積 = 対角線 × 対角線 ÷ 2 だよ。",
			"hint2": "%d × %d ÷ 2 を計算しよう。" % [d1, d2],
			"expl": "ひし形の面積 = 対角線×対角線÷2 = %d×%d÷2 = %d cm² です。" % [d1, d2, d1 * d2 / 2],
			"fig": fig,
		}


## e6: 二等辺三角形の角
static func _e6(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	if tier < 2 and rng.randf() < 0.6:
		# 頂角 → 底角
		var a := 2 * rng.randi_range(12, 55)    # 24..110(偶数)
		var x := (180 - a) / 2
		var v: Array = ProblemGen.tri_from_angles(float(x), float(x), 10.0)
		var fig := {"shapes": [
			ProblemGen.poly(v, ProblemGen.FILL_MAIN),
			ProblemGen.tick(v[0], v[1]), ProblemGen.tick(v[0], v[2]),
			ProblemGen.ang(v[0], v[1], v[2], "%d°" % a),
			ProblemGen.ang(v[1], v[2], v[0], "x"),
		]}
		return {
			"q": "AB = AC の二等辺三角形で、頂角が %d° のとき、底角 x は何度ですか。" % a,
			"answer": float(x), "unit": "度",
			"hint1": "二等辺三角形の 2 つの底角は等しいよ。3 つの角の和は 180°。",
			"hint2": "x = (180 − %d) ÷ 2" % a,
			"expl": "底角は 2 つとも等しいので x = (180 − %d) ÷ 2 = %d° です。" % [a, x],
			"fig": fig,
		}
	# 底角 → 頂角(または外角がらみ)
	var b := rng.randi_range(25, 80)
	var x2 := 180 - 2 * b
	var v2: Array = ProblemGen.tri_from_angles(float(b), float(b), 10.0)
	var fig2 := {"shapes": [
		ProblemGen.poly(v2, ProblemGen.FILL_MAIN),
		ProblemGen.tick(v2[0], v2[1]), ProblemGen.tick(v2[0], v2[2]),
		ProblemGen.ang(v2[1], v2[2], v2[0], "%d°" % b),
		ProblemGen.ang(v2[2], v2[0], v2[1], "%d°" % b),
		ProblemGen.ang(v2[0], v2[1], v2[2], "x"),
	]}
	return {
		"q": "AB = AC の二等辺三角形で、底角が %d° のとき、頂角 x は何度ですか。" % b,
		"answer": float(x2), "unit": "度",
		"hint1": "底角が 2 つあるから、その分を 180° から引こう。",
		"hint2": "x = 180 − %d × 2" % b,
		"expl": "x = 180 − %d × 2 = %d° です。" % [b, x2],
		"fig": fig2,
	}


## e7: 多角形の内角の和・正多角形の角
static func _e7(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var kind := 0 if tier == 0 else (1 if tier == 1 else 2 + rng.randi_range(0, 1))
	if rng.randf() < 0.3:
		kind = rng.randi_range(0, 3)
	if kind == 3:
		# 逆算: 外角から何角形かを当てる
		var choices3 := [5, 6, 8, 9, 10, 12, 15, 18, 20, 24, 30, 36, 40, 45]
		var n4: int = choices3[rng.randi_range(0, choices3.size() - 1)]
		return {
			"q": "1 つの外角が %d° の正多角形は、正何角形ですか。(数字で答えなさい)" % (360 / n4),
			"answer": float(n4), "unit": "角形",
			"hint1": "外角の和はどんな多角形でも 360°。1 つ分でわれば角の数がわかるよ。",
			"hint2": "360 ÷ %d" % (360 / n4),
			"expl": "360 ÷ %d = %d なので正%d角形です。" % [360 / n4, n4, n4],
			"fig": _regular_polygon_fig(mini(n4, 12), true),
		}
	if kind == 0:
		var n := rng.randi_range(5, 12)
		var fig := _regular_polygon_fig(n, false)
		var names := {5: "五", 6: "六", 7: "七", 8: "八", 9: "九", 10: "十", 11: "十一", 12: "十二"}
		return {
			"q": "%s角形の内角の和は何度ですか。" % names[n],
			"answer": float((n - 2) * 180), "unit": "度",
			"hint1": "1 つの頂点から対角線を引くと、三角形が (ちょう点の数 − 2) こできるよ。",
			"hint2": "(%d − 2) × 180 を計算しよう。" % n,
			"expl": "%s角形は三角形 %d こに分けられるので、内角の和は %d × 180 = %d° です。" % [names[n], n - 2, n - 2, (n - 2) * 180],
			"fig": fig,
		}
	elif kind == 1:
		var choices := [5, 6, 8, 9, 10, 12, 15, 18, 20, 24]
		var n2: int = choices[rng.randi_range(0, choices.size() - 1)]
		var x := 180 - 360 / n2
		return {
			"q": "正%d角形の 1 つの内角は何度ですか。" % n2,
			"answer": float(x), "unit": "度",
			"hint1": "内角の和 (%d−2)×180 を、角の数 %d でわればいいよ。" % [n2, n2],
			"hint2": "(%d − 2) × 180 ÷ %d" % [n2, n2],
			"expl": "内角の和は (%d−2)×180 = %d°。それを %d でわって %d° です。" % [n2, (n2 - 2) * 180, n2, x],
			"fig": _regular_polygon_fig(n2, true),
		}
	else:
		var choices2 := [5, 6, 8, 9, 10, 12, 15, 18, 20, 24, 30, 36, 40, 45]
		var n3: int = choices2[rng.randi_range(0, choices2.size() - 1)]
		return {
			"q": "正%d角形の 1 つの外角は何度ですか。" % n3,
			"answer": float(360 / n3), "unit": "度",
			"hint1": "どんな多角形でも、外角の和はぐるっと 1 周で 360° だよ。",
			"hint2": "360 ÷ %d" % n3,
			"expl": "外角の和は 360°。正%d角形では全部等しいので 360 ÷ %d = %d° です。" % [n3, n3, 360 / n3],
			"fig": _regular_polygon_fig(mini(n3, 12), true),
		}


static func _regular_polygon_fig(n: int, mark_one: bool) -> Dictionary:
	var pts: Array = []
	for i in n:
		var a := TAU * i / n + PI / 2.0
		pts.append(Vector2(cos(a), sin(a)) * 5.0)
	var shapes: Array = [ProblemGen.poly(pts, ProblemGen.FILL_MAIN)]
	if mark_one:
		shapes.append(ProblemGen.ang(pts[0], pts[n - 1], pts[1], "x"))
	return {"shapes": shapes}


## e8: 円とおうぎ形(円周率 3.14)
static func _e8(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var kind := mini(tier, 2)
	if rng.randf() < 0.3:
		kind = rng.randi_range(0, 2)
	if kind == 0:
		var r := rng.randi_range(3, 10)
		var ans := r * r * 3.14
		var fig := {"shapes": [
			ProblemGen.circle(Vector2.ZERO, float(r), ProblemGen.FILL_MAIN),
			ProblemGen.seg(Vector2.ZERO, Vector2(r, 0), ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.circle(Vector2.ZERO, 0.12, ProblemGen.COL_YELLOW),
			ProblemGen.label(Vector2(r * 0.5, 0.7), "%dcm" % r),
		]}
		return {
			"q": "半径 %dcm の円の面積は何 cm² ですか。円周率は 3.14 とします。" % r,
			"answer": ans, "unit": "cm²", "tol": 0.02,
			"hint1": "円の面積 = 半径 × 半径 × 3.14 だよ。",
			"hint2": "%d × %d × 3.14 を計算しよう。" % [r, r],
			"expl": "円の面積 = %d × %d × 3.14 = %s cm² です。" % [r, r, ProblemGen.fmt(ans)],
			"fig": fig,
		}
	elif kind == 1:
		var d := 2 * rng.randi_range(2, 10)
		var ans2 := d * 3.14
		var fig2 := {"shapes": [
			ProblemGen.circle(Vector2.ZERO, d * 0.5, ProblemGen.FILL_MAIN),
			ProblemGen.seg(Vector2(-d * 0.5, 0), Vector2(d * 0.5, 0), ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.label(Vector2(0, 0.8), "%dcm" % d),
		]}
		return {
			"q": "直径 %dcm の円の円周の長さは何 cm ですか。円周率は 3.14 とします。" % d,
			"answer": ans2, "unit": "cm", "tol": 0.02,
			"hint1": "円周 = 直径 × 3.14 だよ。",
			"hint2": "%d × 3.14 を計算しよう。" % d,
			"expl": "円周 = 直径 × 3.14 = %d × 3.14 = %s cm です。" % [d, ProblemGen.fmt(ans2)],
			"fig": fig2,
		}
	else:
		var rs := [4, 6, 8, 10, 12]
		var r3: int = rs[rng.randi_range(0, rs.size() - 1)]
		var angs := [45, 90, 120, 180, 270]
		var th: int = angs[rng.randi_range(0, angs.size() - 1)]
		var ans3 := r3 * r3 * 3.14 * th / 360.0
		var fig3 := {"shapes": [
			ProblemGen.sector(Vector2.ZERO, float(r3), 0.0, float(th), ProblemGen.FILL_ACCENT, Color.WHITE),
			ProblemGen.ang(Vector2.ZERO, Vector2(r3, 0), Vector2(cos(deg_to_rad(float(th))), sin(deg_to_rad(float(th)))) * r3, "%d°" % th, 0.0, true),
			ProblemGen.label(Vector2(r3 * 0.6, -0.9), "%dcm" % r3),
		]}
		return {
			"q": "半径 %dcm、中心角 %d° のおうぎ形の面積は何 cm² ですか。円周率は 3.14 とします。" % [r3, th],
			"answer": ans3, "unit": "cm²", "tol": 0.02,
			"hint1": "おうぎ形は円の一部。円の面積 × (中心角 ÷ 360) だよ。",
			"hint2": "%d × %d × 3.14 × %d/360" % [r3, r3, th],
			"expl": "面積 = %d × %d × 3.14 × %d/360 = %s cm² です。" % [r3, r3, th, ProblemGen.fmt(ans3)],
			"fig": fig3,
		}


## e9: 複合図形(L字・額縁・正方形から円を引く)
static func _e9(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var kind := mini(tier, 2)
	if rng.randf() < 0.3:
		kind = rng.randi_range(0, 2)
	if kind == 0:
		var big_w := rng.randi_range(8, 15)
		var big_h := rng.randi_range(6, 12)
		var cut_w := rng.randi_range(3, big_w - 3)
		var cut_h := rng.randi_range(2, big_h - 3)
		var ans := big_w * big_h - cut_w * cut_h
		# L 字: 右上を切り取る
		var p := [
			Vector2(0, 0), Vector2(big_w, 0), Vector2(big_w, big_h - cut_h),
			Vector2(big_w - cut_w, big_h - cut_h), Vector2(big_w - cut_w, big_h), Vector2(0, big_h),
		]
		var fig := {"shapes": [
			ProblemGen.poly(p, ProblemGen.FILL_MAIN),
			ProblemGen.side_label(Vector2(0, 0), Vector2(big_w, 0), "%dcm" % big_w, 1.0),
			ProblemGen.side_label(Vector2(0, 0), Vector2(0, big_h), "%dcm" % big_h, -1.0),
			ProblemGen.side_label(Vector2(big_w - cut_w, big_h), Vector2(big_w - cut_w, big_h - cut_h), "%dcm" % cut_h, 1.0),
			ProblemGen.side_label(Vector2(big_w - cut_w, big_h), Vector2(big_w, big_h), "%dcm" % cut_w, -1.0),
		]}
		return {
			"q": "図の L 字形の面積は何 cm² ですか。(角はすべて直角です)",
			"answer": float(ans), "unit": "cm²",
			"hint1": "大きい長方形から、切り取られた長方形を引こう。",
			"hint2": "%d × %d − %d × %d" % [big_w, big_h, cut_w, cut_h],
			"expl": "大きい長方形 %d×%d = %d から、切り取り %d×%d = %d を引いて %d cm² です。" % [big_w, big_h, big_w * big_h, cut_w, cut_h, cut_w * cut_h, ans],
			"fig": fig,
		}
	elif kind == 1:
		var outer := rng.randi_range(7, 14)
		var inner := rng.randi_range(3, outer - 3)
		var off := (outer - inner) * 0.5
		var ans2 := outer * outer - inner * inner
		var fig2 := {"shapes": [
			ProblemGen.poly([Vector2(0, 0), Vector2(outer, 0), Vector2(outer, outer), Vector2(0, outer)], ProblemGen.FILL_ACCENT),
			ProblemGen.poly([Vector2(off, off), Vector2(off + inner, off), Vector2(off + inner, off + inner), Vector2(off, off + inner)], Color(0.06, 0.09, 0.16, 1.0)),
			ProblemGen.side_label(Vector2(0, 0), Vector2(outer, 0), "%dcm" % outer, 1.0),
			ProblemGen.side_label(Vector2(off, off), Vector2(off + inner, off), "%dcm" % inner, 1.0),
		]}
		return {
			"q": "1 辺 %dcm の正方形から、1 辺 %dcm の正方形をくりぬきました。残った色のついた部分の面積は何 cm² ですか。" % [outer, inner],
			"answer": float(ans2), "unit": "cm²",
			"hint1": "外の正方形の面積から、くりぬいた正方形の面積を引こう。",
			"hint2": "%d × %d − %d × %d" % [outer, outer, inner, inner],
			"expl": "%d² − %d² = %d − %d = %d cm² です。" % [outer, inner, outer * outer, inner * inner, ans2],
			"fig": fig2,
		}
	else:
		var r := rng.randi_range(2, 7)
		var s := r * 2
		var ans3 := s * s - r * r * 3.14
		var fig3 := {"shapes": [
			ProblemGen.poly([Vector2(0, 0), Vector2(s, 0), Vector2(s, s), Vector2(0, s)], ProblemGen.FILL_ACCENT),
			ProblemGen.circle(Vector2(r, r), float(r), Color(0.06, 0.09, 0.16, 1.0), Color.WHITE, 3.0),
			ProblemGen.side_label(Vector2(0, 0), Vector2(s, 0), "%dcm" % s, 1.0),
		]}
		return {
			"q": "1 辺 %dcm の正方形に、ぴったり入る円をかきました。正方形から円を引いた色のついた部分の面積は何 cm² ですか。円周率は 3.14 とします。" % s,
			"answer": ans3, "unit": "cm²", "tol": 0.02,
			"hint1": "円の半径は正方形の 1 辺の半分 = %dcm だよ。" % r,
			"hint2": "%d × %d − %d × %d × 3.14" % [s, s, r, r],
			"expl": "正方形 %d² = %d、円 %d×%d×3.14 = %s。差は %s cm² です。" % [s, s * s, r, r, ProblemGen.fmt(r * r * 3.14), ProblemGen.fmt(ans3)],
			"fig": fig3,
		}


## e10: 葉っぱ形(名物問題)
static func _e10(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var a := rng.randi_range(3, 20)
	if tier >= 2 and rng.randf() < 0.5:
		# 発展: 正方形から葉っぱを引いた残り(= 1辺×1辺×0.43)
		var rest := a * a * 0.43
		var fig4 := {"shapes": [
			ProblemGen.poly([Vector2(0, 0), Vector2(a, 0), Vector2(a, a), Vector2(0, a)], ProblemGen.FILL_ACCENT),
			{"t": "leaf", "a": float(a), "fill": Color(0.06, 0.09, 0.16, 1.0)},
			ProblemGen.side_label(Vector2(0, 0), Vector2(a, 0), "%dcm" % a, 1.0),
		]}
		return {
			"q": "1 辺 %dcm の正方形から、2 つの四分円が重なってできる葉っぱ形をのぞいた、色のついた部分の面積は何 cm² ですか。円周率は 3.14 とします。" % a,
			"answer": rest, "unit": "cm²", "tol": 0.02,
			"hint1": "まず葉っぱ形の面積(1辺×1辺×0.57)を求めて、正方形から引こう。",
			"hint2": "%d×%d − %d×%d×0.57" % [a, a, a, a],
			"expl": "葉っぱ = %s。正方形 %d − %s = %s cm²(1辺×1辺×0.43)。" % [ProblemGen.fmt(a * a * 0.57), a * a, ProblemGen.fmt(a * a * 0.57), ProblemGen.fmt(rest)],
			"fig": fig4,
		}
	if tier < 1 and rng.randf() < 0.5:
		# ウォームアップ: 四分円 − 三角形(2 桁小数に収まるよう偶数の辺で)
		a = 2 * rng.randi_range(2, 10)
		var ans := a * a * 3.14 / 4.0 - a * a / 2.0
		var fig := {"shapes": [
			ProblemGen.sector(Vector2.ZERO, float(a), 0.0, 90.0, ProblemGen.FILL_MAIN, Color.WHITE),
			ProblemGen.poly([Vector2.ZERO, Vector2(a, 0), Vector2(0, a)], Color(0.06, 0.09, 0.16, 0.85)),
			ProblemGen.side_label(Vector2.ZERO, Vector2(a, 0), "%dcm" % a, 1.0),
			ProblemGen.right(Vector2.ZERO, Vector2(a, 0), Vector2(0, a)),
		]}
		return {
			"q": "半径 %dcm の四分円(円の 4 分の 1)から、直角三角形を切り取った色のついた部分の面積は何 cm² ですか。円周率は 3.14 とします。" % a,
			"answer": ans, "unit": "cm²", "tol": 0.02,
			"hint1": "四分円の面積から三角形の面積を引こう。",
			"hint2": "%d×%d×3.14÷4 − %d×%d÷2" % [a, a, a, a],
			"expl": "四分円 %s − 三角形 %s = %s cm² です。" % [ProblemGen.fmt(a * a * 3.14 / 4.0), ProblemGen.fmt(a * a / 2.0), ProblemGen.fmt(ans)],
			"fig": fig,
		}
	var leaf := a * a * 0.57
	var fig2 := {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(a, 0), Vector2(a, a), Vector2(0, a)]),
		{"t": "leaf", "a": float(a)},
		ProblemGen.side_label(Vector2(0, 0), Vector2(a, 0), "%dcm" % a, 1.0),
	]}
	return {
		"q": "1 辺 %dcm の正方形の中に、2 つの四分円をかいてできる葉っぱ形(色のついた部分)の面積は何 cm² ですか。円周率は 3.14 とします。" % a,
		"answer": leaf, "unit": "cm²", "tol": 0.02,
		"hint1": "四分円 2 つをたすと、葉っぱが 2 重に、残りが 1 重に数えられる。そこから正方形を引くと葉っぱだけ残るよ。",
		"hint2": "%d×%d×3.14÷4 × 2 − %d×%d = %d×%d×0.57" % [a, a, a, a, a, a],
		"expl": "葉っぱ = 四分円×2 − 正方形 = %s − %d = %s cm²。「1辺×1辺×0.57」と覚えてもOK。" % [ProblemGen.fmt(a * a * 3.14 / 2.0), a * a, ProblemGen.fmt(leaf)],
		"fig": fig2,
	}


## e11: 時計の針の角(中学受験の定番応用)
static func _e11(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var step_m := 10 if tier == 0 else 5
	var h := rng.randi_range(1, 12)
	var m := step_m * rng.randi_range(0, 60 / step_m - 1)
	var diff := absf(30.0 * h + 0.5 * m - 6.0 * m)
	var x := minf(diff, 360.0 - diff)
	while x < 6.0:
		h = rng.randi_range(1, 12)
		m = step_m * rng.randi_range(0, 60 / step_m - 1)
		diff = absf(30.0 * h + 0.5 * m - 6.0 * m)
		x = minf(diff, 360.0 - diff)
	var r := 5.0
	# 時計は 12 時方向(=数学角 90°)から時計回りに進む
	var hour_deg := 90.0 - (30.0 * h + 0.5 * m)
	var min_deg := 90.0 - 6.0 * m
	var hour_tip := Vector2(cos(deg_to_rad(hour_deg)), sin(deg_to_rad(hour_deg))) * 2.8
	var min_tip := Vector2(cos(deg_to_rad(min_deg)), sin(deg_to_rad(min_deg))) * 4.2
	var shapes: Array = [ProblemGen.circle(Vector2.ZERO, r)]
	for i in 12:
		var d := Vector2(cos(TAU * i / 12.0), sin(TAU * i / 12.0))
		shapes.append(ProblemGen.seg(d * (r - 0.45), d * r, ProblemGen.COL_DIM, 3.0))
	shapes += [
		ProblemGen.label(Vector2(0, r - 1.1), "12", null, 24),
		ProblemGen.label(Vector2(r - 1.1, 0), "3", null, 24),
		ProblemGen.label(Vector2(0, -r + 1.1), "6", null, 24),
		ProblemGen.label(Vector2(-r + 1.1, 0), "9", null, 24),
		ProblemGen.arrow(Vector2.ZERO, hour_tip, Color.WHITE, 7.0),
		ProblemGen.arrow(Vector2.ZERO, min_tip, ProblemGen.COL_YELLOW, 5.0),
		ProblemGen.ang(Vector2.ZERO, hour_tip, min_tip, "x", 1.2),
		ProblemGen.circle(Vector2.ZERO, 0.15, Color.WHITE),
	]
	return {
		"q": "時計が %d 時 %d 分をさしています。長針と短針のつくる角のうち、小さい方の角 x は何度ですか。" % [h, m],
		"answer": x, "unit": "度",
		"hint1": "長針は 1 分で 6°、短針は 1 時間で 30°(1 分で 0.5°)進むよ。",
		"hint2": "短針は 12 時から %s°、長針は %s°。差をとろう。" % [ProblemGen.fmt(30.0 * h + 0.5 * m), ProblemGen.fmt(6.0 * m)],
		"expl": "短針 = 30×%d + 0.5×%d = %s°、長針 = 6×%d = %s°。差は %s° で、小さい方の角は %s° です。" % [
			h, m, ProblemGen.fmt(30.0 * h + 0.5 * m), m, ProblemGen.fmt(6.0 * m),
			ProblemGen.fmt(diff), ProblemGen.fmt(x)],
		"fig": {"shapes": shapes},
	}


## e12: ブーメラン形(へこみ四角形)の角。x = a + b + c(中学受験の定番応用)
static func _e12(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var step := 5 if tier == 0 else 1
	var a := step * rng.randi_range(20 / step, 50 / step)
	var b := step * rng.randi_range(20 / step, 50 / step)
	var c := step * rng.randi_range(20 / step, 50 / step)
	var x := a + b + c
	# D はへこみの頂点。D から見て上に開く形で A・C を置き、
	# A・C から角 a・c で伸ばした辺の交点が B(角 b は自動的に一致する)
	var pd := Vector2.ZERO
	var dir_a := deg_to_rad(90.0 + x * 0.5)
	var dir_c := deg_to_rad(90.0 - x * 0.5)
	var pa := Vector2(cos(dir_a), sin(dir_a)) * 5.0
	var pc := Vector2(cos(dir_c), sin(dir_c)) * 5.0
	var v_ad := (pd - pa).normalized()
	var v_cd := (pd - pc).normalized()
	var pb_v = Geometry2D.line_intersects_line(pa, v_ad.rotated(deg_to_rad(-float(a))),
		pc, v_cd.rotated(deg_to_rad(float(c))))
	var pb: Vector2 = pb_v if pb_v != null else Vector2(0, -5)
	var fig := {"shapes": [
		ProblemGen.poly([pa, pb, pc, pd], ProblemGen.FILL_MAIN, Color.WHITE, 3.5),
		ProblemGen.ang(pa, pd, pb, "%d°" % a),
		ProblemGen.ang(pb, pa, pc, "%d°" % b),
		ProblemGen.ang(pc, pd, pb, "%d°" % c),
		ProblemGen.ang(pd, pa, pc, "x"),
	]}
	return {
		"q": "図のようなブーメラン形(へこみのある四角形)で、角 x は何度ですか。",
		"answer": float(x), "unit": "度",
		"hint1": "へこみの頂点ととがった頂点を線で結ぶと、外角の定理が 2 回使えるよ。",
		"hint2": "x = %d + %d + %d(3 つの角をぜんぶたす)" % [a, b, c],
		"expl": "ブーメラン形のへこみの角は、残り 3 つの角の和。x = %d + %d + %d = %d° です。" % [a, b, c, x],
		"fig": fig,
	}


## e13: 紙テープの折り返し。x = 180 − 2a(中学受験の定番応用)
static func _e13(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var step := 5 if tier == 0 else 1
	var a := step * rng.randi_range(50 / step, 80 / step)
	var x := 180 - 2 * a
	var p := Vector2(7, 0)
	var d := Vector2(cos(deg_to_rad(float(a))), sin(deg_to_rad(float(a))))
	var q := p + d * (2.5 / sin(deg_to_rad(float(a))))
	# 折り返し: P を通る折り目の直線で右側を上へ折る(点は折り目で鏡映)
	var reflect := func(v: Vector2) -> Vector2:
		var w := v - p
		return p + d * (2.0 * w.dot(d)) - w
	var r1: Vector2 = reflect.call(Vector2(12, 0))
	var r2: Vector2 = reflect.call(Vector2(12, 2.5))
	var fig := {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(12, 0), Vector2(12, 2.5), Vector2(0, 2.5)], null, ProblemGen.COL_DIM, 2.5),
		ProblemGen.seg(p, Vector2(12, 0), ProblemGen.COL_DIM, 2.0, true),
		ProblemGen.poly([p, r1, r2, q], ProblemGen.FILL_ACCENT, Color.WHITE, 3.5),
		ProblemGen.seg(p, q, ProblemGen.COL_YELLOW, 4.0),
		ProblemGen.ang(p, Vector2(12, 0), q, "%d°" % a),
		ProblemGen.ang(p, r1, Vector2(0, 0), "x"),
	]}
	return {
		"q": "長方形の紙テープを、図のように直線 PQ で折り返しました。角 x は何度ですか。",
		"answer": float(x), "unit": "度",
		"hint1": "折り返した角はもとの角と等しい。P のまわりに %d° の角が 2 つできるよ。" % a,
		"hint2": "x = 180 − %d × 2(P のまわりは一直線で 180°)" % a,
		"expl": "折り返しで %d° の角が 2 つ。一直線 180° から x = 180 − 2×%d = %d° です。" % [a, a, x],
		"fig": fig,
	}


## e14: 道の面積(道を端に寄せて考える。中学受験の定番応用)
static func _e14(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var aw := rng.randi_range(8, 16)     # よこ
	var ah := rng.randi_range(6, 12)     # たて
	var w := rng.randi_range(1, 3)
	var kind := mini(tier, 2)
	if rng.randf() < 0.3:
		kind = rng.randi_range(0, 2)
	var road := Color(0.42, 0.36, 0.3, 0.95)
	var vx := rng.randi_range(2, aw - w - 2)   # 縦の道の位置(答えに影響しない)
	var hy := rng.randi_range(2, ah - w - 2)   # 横の道の位置
	var base: Array = [ProblemGen.poly([Vector2(0, 0), Vector2(aw, 0), Vector2(aw, ah), Vector2(0, ah)], ProblemGen.FILL_SUB),
		ProblemGen.side_label(Vector2(0, 0), Vector2(aw, 0), "%dm" % aw, 1.0),
		ProblemGen.side_label(Vector2(0, 0), Vector2(0, ah), "%dm" % ah, -1.0)]
	if kind == 0:
		var ans := (aw - w) * ah
		base.append(ProblemGen.poly([Vector2(vx, 0), Vector2(vx + w, 0), Vector2(vx + w, ah), Vector2(vx, ah)], road))
		base.append(ProblemGen.label(Vector2(vx + w * 0.5, ah + 1.0), "はば%dm" % w, ProblemGen.COL_YELLOW, 24))
		return {
			"q": "たて %dm・よこ %dm の長方形の土地に、はば %dm のまっすぐな道を 1 本通しました。道をのぞいた残りの面積は何 m² ですか。" % [ah, aw, w],
			"answer": float(ans), "unit": "m²",
			"hint1": "道を土地のはしに寄せて考えると、残りは 1 つの長方形になるよ。",
			"hint2": "(%d − %d) × %d" % [aw, w, ah],
			"expl": "道を寄せると残りは よこ %d−%d = %dm、たて %dm の長方形。面積は %d m² です。" % [aw, w, aw - w, ah, ans],
			"fig": {"shapes": base},
		}
	elif kind == 1:
		var ans := (aw - w) * (ah - w)
		base.append(ProblemGen.poly([Vector2(vx, 0), Vector2(vx + w, 0), Vector2(vx + w, ah), Vector2(vx, ah)], road))
		base.append(ProblemGen.poly([Vector2(0, hy), Vector2(aw, hy), Vector2(aw, hy + w), Vector2(0, hy + w)], road))
		base.append(ProblemGen.label(Vector2(vx + w * 0.5, ah + 1.0), "はば%dm" % w, ProblemGen.COL_YELLOW, 24))
		return {
			"q": "たて %dm・よこ %dm の長方形の土地に、はば %dm の道をたてとよこに 1 本ずつ通しました。道をのぞいた残りの面積は何 m² ですか。" % [ah, aw, w],
			"answer": float(ans), "unit": "m²",
			"hint1": "たての道もよこの道もはしに寄せると、残りは 1 つの長方形にまとまるよ。",
			"hint2": "(%d − %d) × (%d − %d)" % [aw, w, ah, w],
			"expl": "道を寄せると残りは (%d−%d) × (%d−%d) = %d × %d = %d m² です。" % [aw, w, ah, w, aw - w, ah - w, (aw - w) * (ah - w)],
			"fig": {"shapes": base},
		}
	else:
		# 縦 2 本 + 横 1 本
		var vx2 := rng.randi_range(vx + w + 1, aw - w - 1)
		if aw - 2 * w < 4:
			aw += 4
			vx2 = rng.randi_range(vx + w + 1, aw - w - 1)
		var ans := (aw - 2 * w) * (ah - w)
		base[0] = ProblemGen.poly([Vector2(0, 0), Vector2(aw, 0), Vector2(aw, ah), Vector2(0, ah)], ProblemGen.FILL_SUB)
		base[1] = ProblemGen.side_label(Vector2(0, 0), Vector2(aw, 0), "%dm" % aw, 1.0)
		base.append(ProblemGen.poly([Vector2(vx, 0), Vector2(vx + w, 0), Vector2(vx + w, ah), Vector2(vx, ah)], road))
		base.append(ProblemGen.poly([Vector2(vx2, 0), Vector2(vx2 + w, 0), Vector2(vx2 + w, ah), Vector2(vx2, ah)], road))
		base.append(ProblemGen.poly([Vector2(0, hy), Vector2(aw, hy), Vector2(aw, hy + w), Vector2(0, hy + w)], road))
		base.append(ProblemGen.label(Vector2(vx + w * 0.5, ah + 1.0), "はばはすべて%dm" % w, ProblemGen.COL_YELLOW, 24))
		return {
			"q": "たて %dm・よこ %dm の長方形の土地に、はば %dm の道をたてに 2 本、よこに 1 本通しました。道をのぞいた残りの面積は何 m² ですか。" % [ah, aw, w],
			"answer": float(ans), "unit": "m²",
			"hint1": "道をぜんぶはしに寄せよう。たての道 2 本分、よこの道 1 本分だけ小さくなるよ。",
			"hint2": "(%d − %d×2) × (%d − %d)" % [aw, w, ah, w],
			"expl": "残りは (%d−%d) × (%d−%d) = %d × %d = %d m² です。" % [aw, 2 * w, ah, w, aw - 2 * w, ah - w, ans],
			"fig": {"shapes": base},
		}


## e15: 長方形の中の 1 点(向かい合う三角形の面積の和は等しい。応用)
static func _e15(rng: RandomNumberGenerator, _tier: int) -> Dictionary:
	var aw := 2 * rng.randi_range(4, 8)
	var ah := 2 * rng.randi_range(3, 6)
	var px := rng.randi_range(2, aw - 2)
	var py := rng.randi_range(1, ah - 1)
	# 4 つの三角形(下・右・上・左)。上下の和 = 左右の和 = 長方形の半分
	var s_bottom := aw * py / 2
	var s_top := aw * (ah - py) / 2
	var s_right := (aw - px) * ah / 2
	var s_left := px * ah / 2
	var x := s_left
	var p := Vector2(px, py)
	var fig := {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(aw, 0), Vector2(aw, ah), Vector2(0, ah)], null, Color.WHITE, 3.5),
		ProblemGen.seg(p, Vector2(0, 0), ProblemGen.COL_DIM, 2.5),
		ProblemGen.seg(p, Vector2(aw, 0), ProblemGen.COL_DIM, 2.5),
		ProblemGen.seg(p, Vector2(aw, ah), ProblemGen.COL_DIM, 2.5),
		ProblemGen.seg(p, Vector2(0, ah), ProblemGen.COL_DIM, 2.5),
		ProblemGen.circle(p, 0.12, ProblemGen.COL_YELLOW),
		ProblemGen.label(Vector2(aw * 0.5, py * 0.4), "%d" % s_bottom),
		ProblemGen.label(Vector2(px + (aw - px) * 0.55, py + (ah - py) * 0.4 - (py * 0.4 - ah * 0.0)), "%d" % s_right),
		ProblemGen.label(Vector2(aw * 0.5, ah - (ah - py) * 0.4), "%d" % s_top),
		ProblemGen.label(Vector2(px * 0.4, py + (ah * 0.5 - py) * 0.5), "x", ProblemGen.COL_YELLOW, 34),
	]}
	return {
		"q": "長方形の中の 1 つの点と 4 つの頂点を結んで、4 つの三角形に分けました。3 つの三角形の面積が図の通り(cm²)のとき、x の面積は何 cm² ですか。",
		"answer": float(x), "unit": "cm²",
		"hint1": "上の三角形と下の三角形の面積の和は、長方形のちょうど半分。左と右の和も半分で、たがいに等しいよ。",
		"hint2": "x = %d + %d − %d(上下の和 = 左右の和)" % [s_top, s_bottom, s_right],
		"expl": "上下の和 %d+%d = %d は長方形の半分。左右の和も %d なので x = %d − %d = %d cm² です。" % [
			s_top, s_bottom, s_top + s_bottom, s_top + s_bottom, s_top + s_bottom, s_right, x],
		"fig": fig,
	}


## e16: 底辺の比と面積比(高さが同じ三角形。応用)
static func _e16(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var m := rng.randi_range(1, 4)
	var n := rng.randi_range(1, 5)
	while n == m and m == 1:
		n = rng.randi_range(1, 5)
	var k := rng.randi_range(2, 9)
	var total := (m + n) * k
	var pb := Vector2(0, 0)
	var pc := Vector2(10, 0)
	var pa := Vector2(rng.randf_range(3.0, 6.0), 6.5)
	var pd: Vector2 = pb + (pc - pb) * (float(m) / float(m + n))
	var shapes: Array = [
		ProblemGen.poly([pa, pb, pc], ProblemGen.FILL_MAIN),
		ProblemGen.seg(pa, pd, ProblemGen.COL_YELLOW, 3.5),
		ProblemGen.label(pa + Vector2(0, 0.8), "A"),
		ProblemGen.label(pb + Vector2(-0.7, -0.5), "B"), ProblemGen.label(pc + Vector2(0.7, -0.5), "C"),
		ProblemGen.label(pd + Vector2(0, -0.9), "D"),
		ProblemGen.label((pb + pd) * 0.5 + Vector2(0, -1.6), "%d" % m, ProblemGen.COL_YELLOW, 26),
		ProblemGen.label((pd + pc) * 0.5 + Vector2(0, -1.6), "%d" % n, ProblemGen.COL_YELLOW, 26),
	]
	if tier >= 2 and rng.randf() < 0.5:
		# 逆算: 部分から全体
		var part := m * k
		shapes.append(ProblemGen.label(Vector2(pa.x, 7.6), "三角形ABD = %d cm²" % part, null, 24))
		return {
			"q": "点 D は辺 BC を BD : DC = %d : %d に分けます。三角形 ABD の面積が %d cm² のとき、三角形 ABC 全体の面積は何 cm² ですか。" % [m, n, part],
			"answer": float(total), "unit": "cm²",
			"hint1": "ABD と ADC は高さが同じ。面積の比は底辺の比 %d : %d と同じだよ。" % [m, n],
			"hint2": "全体 = %d × (%d + %d) ÷ %d" % [part, m, n, m],
			"expl": "ABD は全体の %d/%d。全体 = %d × %d/%d = %d cm² です。" % [m, m + n, part, m + n, m, total],
			"fig": {"shapes": shapes},
		}
	shapes.append(ProblemGen.label(Vector2(pa.x, 7.6), "三角形ABC = %d cm²" % total, null, 24))
	return {
		"q": "三角形 ABC の面積は %d cm² です。点 D は辺 BC を BD : DC = %d : %d に分けます。三角形 ABD の面積は何 cm² ですか。" % [total, m, n],
		"answer": float(m * k), "unit": "cm²",
		"hint1": "ABD と ADC は高さが同じだから、面積の比は底辺の比と同じ %d : %d になるよ。" % [m, n],
		"hint2": "%d × %d ÷ (%d + %d)" % [total, m, m, n],
		"expl": "面積比 = 底辺比 %d : %d。ABD = %d × %d/%d = %d cm² です。" % [m, n, total, m, m + n, m * k],
		"fig": {"shapes": shapes},
	}


## e17: 正多角形と対角線の角(応用)。頂点は同じ円の上 → 1 区切り分の角は 180/n °
static func _e17(rng: RandomNumberGenerator, _tier: int) -> Dictionary:
	# (n, span) で角が整数になる組だけ使う
	var combos: Array = []
	for n in [5, 6, 8, 9, 10, 12]:
		for span in range(1, n - 1):
			if (span * 180) % n == 0 and span * 180 / n <= 150:
				combos.append([n, span])
	var pick: Array = combos[rng.randi_range(0, combos.size() - 1)]
	var n: int = pick[0]
	var span: int = pick[1]
	var x := span * 180 / n
	# 頂点 0 から、span だけ離れた 2 頂点への線(辺または対角線)を引く
	var i := rng.randi_range(1, n - 1 - span)
	var j := i + span
	var pts: Array = []
	for t in n:
		var ang := TAU * t / n + PI / 2.0
		pts.append(Vector2(cos(ang), sin(ang)) * 5.0)
	var fig := {"shapes": [
		ProblemGen.poly(pts, ProblemGen.FILL_MAIN),
		ProblemGen.seg(pts[0], pts[i], ProblemGen.COL_YELLOW, 3.5),
		ProblemGen.seg(pts[0], pts[j], ProblemGen.COL_YELLOW, 3.5),
		ProblemGen.ang(pts[0], pts[i], pts[j], "x"),
	]}
	return {
		"q": "正%d角形の 1 つの頂点から図のように線を引きました。角 x は何度ですか。" % n,
		"answer": float(x), "unit": "度",
		"hint1": "正%d角形の頂点はぜんぶ同じ円の上にある。頂点 1 区切り分の弧に対する角は 180 ÷ %d ° だよ。" % [n, n],
		"hint2": "x = 180 ÷ %d × %d(%d 区切り分)" % [n, span, span],
		"expl": "頂点 1 区切り分の角は 180/%d °。線の間は %d 区切りなので x = %d° です。" % [n, span, x],
		"fig": fig,
	}
