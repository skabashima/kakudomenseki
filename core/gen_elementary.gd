class_name GenElementary
## 中学受験レベル(小学校の図形)の問題生成。値は毎回ランダム。
## 円周率は 3.14 で計算する(問題文に明記)。



## 各ステージの「難度ラダー」。tier(0-9)を配列で解法の種類に割り当てる。
## 挑戦モード 10 問は 1 問ごとにこの階段を登るので、
## 数字が変わるだけでなく解法そのものが変わっていく。
static func gen(stage_id: String, rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var t := clampi(tier, 0, 9)
	# e18 以降(立体・水そう・図形の移動・相似)は別ファイル
	if stage_id.substr(1).to_int() >= 18:
		return GenSolid.gen(stage_id, rng, t)
	match stage_id:
		"e1":
			# 内角の和 → 角の比 → 三角定規 → 外角 → 外角2つ
			match [0, 0, 1, 2, 2, 3, 3, 4, 5, 5][t]:
				0: return _e1(rng, 0)
				1: return _e1(rng, 1)
				2: return _e1_ratio(rng)
				3: return _e1_jougi(rng)
				4: return _e1_ext(rng)
				_: return _e1_hard(rng, 1)
		"e2":
			# 長方形 → 正方形 → 周→面積 → 面積→辺 → 半分に折る → 周が同じ差
			match [0, 1, 2, 3, 3, 4, 4, 5, 5, 5][t]:
				0: return _e2(rng, 0)
				1: return _e2(rng, 1)
				2: return _e2(rng, 2)
				3: return _e2_missing_side(rng)
				4: return _e2_fold(rng)
				_: return _e2_diff(rng)
		"e3":
			# 基本 → 高さ逆算 → 斜辺への高さ → 合体 → 等積変形
			match [0, 0, 1, 1, 2, 2, 3, 3, 4, 4][t]:
				0: return _e3(rng, 0)
				1: return _e3(rng, 1)
				2: return _e3_hyp_height(rng)
				3: return _e3_double(rng)
				_: return _e3_equal(rng)
		"e4":
			# 錯角 → 同側内角 → 折れ線 → ジグザグ2 → ジグザグ3
			match [0, 1, 2, 2, 3, 3, 3, 4, 4, 4][t]:
				0: return _e4_alt(rng, 5 if t == 0 else 1)
				1: return _e4_coint(rng)
				2: return _e4_fold(rng, 5 if t <= 2 else 1)
				3: return _e4_zigzag(rng, 1, false)
				_: return _e4_zigzag(rng, 1, true)
		"e5":
			# 平行四辺形 → 台形 → ひし形 → 高さ逆算 → 台形の高さ → 上底
			match [0, 1, 2, 3, 3, 4, 4, 5, 5, 5][t]:
				0: return _e5(rng, 0)
				1: return _e5(rng, 1)
				2: return _e5(rng, 2)
				3: return _e5_para_rev(rng)
				4: return _e5_trap_rev(rng)
				_: return _e5_trap_top(rng)
		"e6":
			# 頂角→底角 → 底角→頂角 → 差がわかっている → 外角
			match [0, 0, 1, 1, 2, 2, 3, 3, 3, 3][t]:
				0: return _e6(rng, 0)
				1: return _e6(rng, 1)
				2: return _e6_diff(rng)
				_: return _e6_hard(rng, 1)
		"e7":
			# 内角の和 → 正n内角 → 正n外角 → 外角→何角形 → 内角の和→何角形
			match [0, 1, 1, 2, 2, 3, 3, 4, 4, 4][t]:
				0: return _e7(rng, 0)
				1: return _e7(rng, 1)
				2: return _e7(rng, 2)
				3: return _e7(rng, 3)
				_: return _e7_sum_rev(rng)
		"e8":
			# 円の面積 → 円周 → おうぎ形 → 半円の周 → まわりの長さ → 面積→半径
			match [0, 1, 2, 2, 3, 3, 4, 4, 5, 5][t]:
				0: return _e8(rng, 0)
				1: return _e8(rng, 1)
				2: return _e8(rng, 2)
				3: return _e8_semi_perim(rng)
				4: return _e8_hard(rng)
				_: return _e8_area_rev(rng)
		"e9":
			# L字 → 額縁 → 正方形−円 → 階段の周 → 十字形
			match [0, 1, 1, 2, 2, 3, 3, 4, 4, 4][t]:
				0: return _e9(rng, 0)
				1: return _e9(rng, 1)
				2: return _e9(rng, 2)
				3: return _e9_stairs(rng)
				_: return _e9_hard(rng)
		"e11":
			# 文字盤 → ちょうどの時刻 → 10分きざみ → 5分きざみ → 逆算
			match [0, 1, 2, 2, 2, 3, 3, 3, 4, 4][t]:
				0: return _e11_dial(rng)
				1: return _e11_oclock(rng)
				2: return _e11_hands(rng, 10)
				3: return _e11_hands(rng, 5)
				_: return _e11_rev(rng)
		"e12":
			# ブーメラン基本 → 細かい角度 → 逆算
			match [0, 0, 0, 1, 1, 1, 1, 2, 2, 2][t]:
				0: return _e12(rng, 0)
				1: return _e12(rng, 1)
				_: return _e12_rev(rng)
		"e13":
			# 折り返し基本 → 細かい角度 → 逆算(折り目の角)
			match [0, 0, 0, 1, 1, 1, 1, 2, 2, 2][t]:
				0: return _e13(rng, 0)
				1: return _e13(rng, 1)
				_: return _e13_rev(rng)
		"e14":
			# 道1本 → 縦横 → 縦2横1 → 斜めの道
			match [0, 1, 1, 2, 2, 2, 3, 3, 3, 3][t]:
				0: return _e14(rng, 0)
				1: return _e14(rng, 1)
				2: return _e14(rng, 2)
				_: return _e14_slant(rng)
		"e15":
			# x を求める → 長方形全体を求める
			match [0, 0, 0, 0, 1, 1, 1, 1, 1, 1][t]:
				0: return _e15(rng, 0)
				_: return _e15_whole(rng)
		"e16":
			# 基本 → 逆算 → 3つに分ける
			match [0, 0, 0, 1, 1, 1, 2, 2, 2, 2][t]:
				0: return _e16(rng, 0)
				1: return _e16(rng, 2)
				_: return _e16_three(rng)
		"e17":
			# 中心角 → 辺と対角線 → 対角線どうし
			match [0, 0, 1, 1, 1, 2, 2, 2, 2, 2][t]:
				0: return _e17_center(rng)
				1: return _e17(rng, 1)
				_: return _e17(rng, 2)
		_:
			# e10: 四分円−三角形 → 葉っぱ → 正方形−葉っぱ
			match [0, 0, 1, 1, 1, 1, 2, 2, 2, 2][t]:
				0: return _e10(rng, 0)
				1: return _e10(rng, 1)
				_: return _e10(rng, 2)


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
	var kind := clampi(tier, 0, 2)
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
	if tier >= 1:
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


## e4-a: 平行線の錯角
static func _e4_alt(rng: RandomNumberGenerator, step: int) -> Dictionary:
	var w := 12.0
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


## e4-b: 折れ線(間の点の角 = 上下の角の和)
static func _e4_fold(rng: RandomNumberGenerator, step: int) -> Dictionary:
	var w := 12.0
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
	var steps := [
		{"say": "折れ点を通って、l と m に平行な補助線を引く!",
			"add": [ProblemGen.seg(p + Vector2(-4.5, 0), p + Vector2(4.5, 0), Color(0.45, 1.0, 0.6, 0.9), 3.0, true)]},
		{"say": "上半分を見ると… l との錯角(Z の形)だから %d°!" % a2,
			"add": [ProblemGen.ang(p, q_l, p + Vector2(-4.5, 0), "%d°" % a2)]},
		{"say": "下半分も m との錯角だから %d°!" % b2,
			"add": [ProblemGen.ang(p, p + Vector2(-4.5, 0), q_m, "%d°" % b2)]},
		{"say": "x は 2 つをあわせた角。x = %d + %d = %d°。答えを入力してみよう!" % [a2, b2, a2 + b2]},
	]
	return {
		"q": "直線 l と m は平行です。折れ線の角 x は何度ですか。",
		"answer": float(a2 + b2), "unit": "度",
		"hint1": "折れ曲がった点を通る、l と m に平行な線を引いてみよう。角が 2 つに分かれるよ。",
		"hint2": "x = %d + %d(錯角で上下に分けられる)" % [a2, b2],
		"expl": "折れ点を通る平行線を引くと、錯角により x は %d° と %d° に分かれます。x = %d + %d = %d° です。" % [a2, b2, a2, b2, a2 + b2],
		"steps": steps,
		"fig": fig2,
	}


## e5: 平行四辺形・台形・ひし形の面積
static func _e5(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var kind := clampi(tier, 0, 2)
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
	if tier == 0:
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
	var kind := clampi(tier, 0, 3)
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
	var kind := clampi(tier, 0, 2)
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
	var kind := clampi(tier, 0, 2)
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
	if tier >= 2:
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
	if tier == 0:
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
	var steps := [
		{"say": "左下を中心とする四分円に色をぬる。面積は %d×%d×3.14÷4。" % [a, a],
			"add": [ProblemGen.sector(Vector2(0, 0), float(a), 0.0, 90.0, Color(1.0, 0.85, 0.3, 0.3))]},
		{"say": "右上を中心とする四分円も同じ大きさ。重ねると、葉っぱの部分だけ 2 回ぬられる!",
			"add": [ProblemGen.sector(Vector2(a, a), float(a), 180.0, 270.0, Color(0.35, 0.75, 1.0, 0.3))]},
		{"say": "四分円 2 つの和から正方形 1 つ分を引くと、2 回ぬった分 = 葉っぱだけが残る。",
			"add": [ProblemGen.poly([Vector2(0, 0), Vector2(a, 0), Vector2(a, a), Vector2(0, a)], null, Color(0.45, 1.0, 0.6, 0.9), 3.0)]},
		{"say": "葉っぱ = %s − %d = %s cm²。入力してみよう!" % [ProblemGen.fmt(a * a * 3.14 / 2.0), a * a, ProblemGen.fmt(leaf)]},
	]
	return {
		"q": "1 辺 %dcm の正方形の中に、2 つの四分円をかいてできる葉っぱ形(色のついた部分)の面積は何 cm² ですか。円周率は 3.14 とします。" % a,
		"answer": leaf, "unit": "cm²", "tol": 0.02,
		"hint1": "四分円 2 つをたすと、葉っぱが 2 重に、残りが 1 重に数えられる。そこから正方形を引くと葉っぱだけ残るよ。",
		"hint2": "%d×%d×3.14÷4 × 2 − %d×%d = %d×%d×0.57" % [a, a, a, a, a, a],
		"steps": steps,
		"expl": "葉っぱ = 四分円×2 − 正方形 = %s − %d = %s cm²。「1辺×1辺×0.57」と覚えてもOK。" % [ProblemGen.fmt(a * a * 3.14 / 2.0), a * a, ProblemGen.fmt(leaf)],
		"fig": fig2,
	}


## e11: 時計の針の角(中学受験の定番応用)
static func _e11_hands(rng: RandomNumberGenerator, step_m: int) -> Dictionary:
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
	var ha := fmod(30.0 * h + 0.5 * m, 360.0)
	var ma := 6.0 * m
	var dd := absf(ha - ma)
	var up := Vector2(0, 1)
	var steps: Array = [
		{"say": "12 時の方向に補助線を引く。針の角度は、ここから時計回りに何度進んだかで考える!",
			"add": [ProblemGen.seg(Vector2.ZERO, Vector2(0, r), Color(0.45, 1.0, 0.6, 0.9), 3.0, true)]},
	]
	var h_mark: Dictionary
	if ha > 180.0:
		h_mark = ProblemGen.ang(Vector2.ZERO, hour_tip, up, "%s°" % ProblemGen.fmt(ha), 1.7, true)
	else:
		h_mark = ProblemGen.ang(Vector2.ZERO, up, hour_tip, "%s°" % ProblemGen.fmt(ha), 1.7)
	steps.append({"say": "短針は 1 時間で 30°(1 分で 0.5°)。12 時から 30×%d + 0.5×%d で %s° 進んでいる。" % [h, m, ProblemGen.fmt(ha)],
		"add": [h_mark]})
	if m == 0:
		steps.append({"say": "長針は 1 分で 6°。0 分だから 12 時ちょうどの方向(0°)をさしたまま。"})
	elif ma > 180.0:
		steps.append({"say": "長針は 1 分で 6°。12 時から 6×%d = %s° 進んでいる。" % [m, ProblemGen.fmt(ma)],
			"add": [ProblemGen.ang(Vector2.ZERO, min_tip, up, "%s°" % ProblemGen.fmt(ma), 3.4, true)]})
	else:
		steps.append({"say": "長針は 1 分で 6°。12 時から 6×%d = %s° 進んでいる。" % [m, ProblemGen.fmt(ma)],
			"add": [ProblemGen.ang(Vector2.ZERO, up, min_tip, "%s°" % ProblemGen.fmt(ma), 3.4)]})
	steps.append({"say": "2 つの差は %s°。180° より大きいときは 360° から引いて、小さい方の角 x = %s°。入力してみよう!" % [ProblemGen.fmt(dd), ProblemGen.fmt(x)]})
	return {
		"q": "時計が %d 時 %d 分をさしています。長針と短針のつくる角のうち、小さい方の角 x は何度ですか。" % [h, m],
		"answer": x, "unit": "度",
		"hint1": "長針は 1 分で 6°、短針は 1 時間で 30°(1 分で 0.5°)進むよ。",
		"hint2": "短針は 12 時から %s°、長針は %s°。差をとろう。" % [ProblemGen.fmt(30.0 * h + 0.5 * m), ProblemGen.fmt(6.0 * m)],
		"expl": "短針 = 30×%d + 0.5×%d = %s°、長針 = 6×%d = %s°。差は %s° で、小さい方の角は %s° です。" % [
			h, m, ProblemGen.fmt(30.0 * h + 0.5 * m), m, ProblemGen.fmt(6.0 * m),
			ProblemGen.fmt(diff), ProblemGen.fmt(x)],
		"steps": steps,
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
	var pe := pd + (pd - pb).normalized() * 2.5
	var steps := [
		{"say": "とがった頂点 B と、へこみの頂点(x の角)を結んで、その先までのばす補助線を引く!",
			"add": [ProblemGen.seg(pb, pe, Color(0.45, 1.0, 0.6, 0.9), 3.0, true)]},
		{"say": "左の三角形に注目。外角の定理で、左側の角 = %d° + (%d° の左半分)。" % [a, b],
			"add": [ProblemGen.poly([pa, pb, pd], Color(1.0, 0.85, 0.3, 0.3)), ProblemGen.ang(pd, pa, pe, "", 1.0)]},
		{"say": "右の三角形も同じ。右側の角 = %d° + (%d° の右半分)。" % [c, b],
			"add": [ProblemGen.poly([pc, pb, pd], Color(0.35, 0.75, 1.0, 0.3)), ProblemGen.ang(pd, pe, pc, "", 1.3)]},
		{"say": "2 つをあわせると、x = %d + %d + %d = %d°(3 つの角の和)。入力してみよう!" % [a, b, c, x]},
	]
	return {
		"q": "図のようなブーメラン形(へこみのある四角形)で、角 x は何度ですか。",
		"answer": float(x), "unit": "度",
		"hint1": "へこみの頂点ととがった頂点を線で結ぶと、外角の定理が 2 回使えるよ。",
		"hint2": "x = %d + %d + %d(3 つの角をぜんぶたす)" % [a, b, c],
		"steps": steps,
		"expl": "ブーメラン形のへこみの角は、残り 3 つの角の和。x = %d + %d + %d = %d° です。" % [a, b, c, x],
		"fig": fig,
	}


## e13: 紙テープの折り返し。x = 180 − 2a(中学受験の定番応用)
static func _e13(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var step := 5 if tier == 0 else 1
	var a := step * rng.randi_range(40 / step, 82 / step)
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
	var steps := [
		{"say": "折り返した角は、もとの角と同じ! 折り目の右にも %d° がある。" % a,
			"add": [ProblemGen.ang(p, q, r1, "%d°" % a)]},
		{"say": "P のまわり(下の直線の上側)は、一直線で 180°。",
			"add": [ProblemGen.seg(Vector2(0, 0), Vector2(12, 0), Color(0.45, 1.0, 0.6, 0.9), 3.0)]},
		{"say": "だから x = 180 − %d − %d = %d°。入力してみよう!" % [a, a, x]},
	]
	return {
		"q": "長方形の紙テープを、図のように直線 PQ で折り返しました。角 x は何度ですか。",
		"answer": float(x), "unit": "度",
		"hint1": "折り返した角はもとの角と等しい。P のまわりに %d° の角が 2 つできるよ。" % a,
		"hint2": "x = 180 − %d × 2(P のまわりは一直線で 180°)" % a,
		"expl": "折り返しで %d° の角が 2 つ。一直線 180° から x = 180 − 2×%d = %d° です。" % [a, a, x],
		"steps": steps,
		"fig": fig,
	}


## e14: 道の面積(道を端に寄せて考える。中学受験の定番応用)
static func _e14(rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var aw := rng.randi_range(8, 16)     # よこ
	var ah := rng.randi_range(6, 12)     # たて
	var w := rng.randi_range(1, 3)
	var kind := clampi(tier, 0, 2)
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
	var aw := 2 * rng.randi_range(4, 10)
	var ah := 2 * rng.randi_range(3, 8)
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
	var steps := [
		{"say": "下の三角形と上の三角形に色をぬる。底辺はどちらも「よこ」、高さの和はちょうど「たて」。",
			"add": [ProblemGen.poly([Vector2(0, 0), Vector2(aw, 0), p], Color(1.0, 0.85, 0.3, 0.3)),
				ProblemGen.poly([Vector2(0, ah), Vector2(aw, ah), p], Color(1.0, 0.85, 0.3, 0.3))]},
		{"say": "だから 下 + 上 = 長方形のちょうど半分! %d + %d = %d。" % [s_bottom, s_top, s_bottom + s_top]},
		{"say": "左と右の三角形も同じ理由で半分になる。だから 左 + 右 も %d のはず。" % [s_bottom + s_top],
			"add": [ProblemGen.poly([Vector2(0, 0), Vector2(0, ah), p], Color(0.35, 0.75, 1.0, 0.3)),
				ProblemGen.poly([Vector2(aw, 0), Vector2(aw, ah), p], Color(0.35, 0.75, 1.0, 0.3))]},
		{"say": "x = %d − %d = %d cm²。入力してみよう!" % [s_bottom + s_top, s_right, x]},
	]
	return {
		"q": "長方形の中の 1 つの点と 4 つの頂点を結んで、4 つの三角形に分けました。3 つの三角形の面積が図の通り(cm²)のとき、x の面積は何 cm² ですか。",
		"answer": float(x), "unit": "cm²",
		"hint1": "上の三角形と下の三角形の面積の和は、長方形のちょうど半分。左と右の和も半分で、たがいに等しいよ。",
		"hint2": "x = %d + %d − %d(上下の和 = 左右の和)" % [s_top, s_bottom, s_right],
		"steps": steps,
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
	if tier >= 2:
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
static func _e17(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	# (n, span) で角が整数になる組だけ使う。
	# kind 1: 辺と対角線の間の角 / kind 2: 対角線どうしの角(より応用)
	var combos: Array = []
	for n in [5, 6, 8, 9, 10, 12]:
		for span in range(1, n - 1):
			if (span * 180) % n == 0 and span * 180 / n <= 150:
				if kind >= 2 and span > n - 4:
					continue   # 対角線 2 本を引く余地を残す
				combos.append([n, span])
	var pick: Array = combos[rng.randi_range(0, combos.size() - 1)]
	var n: int = pick[0]
	var span: int = pick[1]
	var x := span * 180 / n
	# 頂点 0 から、span だけ離れた 2 頂点への線を引く。
	# kind 1 は辺から、kind 2 は対角線どうし
	var i := 1 if kind <= 1 else rng.randi_range(2, maxi(2, n - 1 - span))
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


## e4 の応用: ジグザグの折れ線(折れ点 2 つ)。
## ask_mid=false: 最後の角を問う(x = a + b − c)
## ask_mid=true:  途中の折れ点の角を問う ― 逆向きの推論が必要
## 各線分の傾きを先に決めて座標を作るので、図は必ず出題値と一致する
static func _e4_zigzag(rng: RandomNumberGenerator, step: int, ask_mid: bool) -> Dictionary:
	var t1 := step * rng.randi_range(25 / step, 50 / step)   # l との角
	var t2 := step * rng.randi_range(20 / step, 45 / step)   # 中段の線分の傾き
	var t3 := step * rng.randi_range(20 / step, 55 / step)   # 最後の線分の傾き
	var b := 180 - t1 - t2      # 折れ点 1 の角
	var c := 180 - t2 - t3      # 折れ点 2 の角
	var p0 := Vector2(1.0, 6.0)
	var p1 := p0 + Vector2(cos(deg_to_rad(-float(t1))), sin(deg_to_rad(-float(t1)))) * (4.6 / sin(deg_to_rad(float(t1))))
	var p2 := p1 + Vector2(cos(deg_to_rad(float(t2))), sin(deg_to_rad(float(t2)))) * (3.2 / sin(deg_to_rad(float(t2))))
	var p3 := p2 + Vector2(cos(deg_to_rad(-float(t3))), sin(deg_to_rad(-float(t3)))) * (4.6 / sin(deg_to_rad(float(t3))))
	var w := maxf(12.0, p3.x + 1.5)
	var shapes: Array = [
		ProblemGen.seg(Vector2(0, 6), Vector2(w, 6)), ProblemGen.seg(Vector2(0, 0), Vector2(w, 0)),
		ProblemGen.label(Vector2(w + 0.7, 6), "l"), ProblemGen.label(Vector2(w + 0.7, 0), "m"),
		ProblemGen.seg(p0, p1, ProblemGen.COL_DIM), ProblemGen.seg(p1, p2, ProblemGen.COL_DIM),
		ProblemGen.seg(p2, p3, ProblemGen.COL_DIM),
		ProblemGen.ang(p0, Vector2(w, 6), p1, "%d°" % t1),
	]
	var steps := [
		{"say": "2 つの折れ点それぞれに、l・m と平行な補助線を引く!",
			"add": [ProblemGen.seg(p1 + Vector2(-4.5, 0), p1 + Vector2(4.5, 0), Color(0.45, 1.0, 0.6, 0.9), 3.0, true),
				ProblemGen.seg(p2 + Vector2(-4.5, 0), p2 + Vector2(4.5, 0), Color(0.45, 1.0, 0.6, 0.9), 3.0, true)]},
		{"say": "1 本目の線の傾きは、l との錯角でそのまま %d°。" % t1,
			"add": [ProblemGen.ang(p1, p0, p1 + Vector2(-4.5, 0), "%d°" % t1)]},
		{"say": "折れ点の角から、まん中の線の傾きは 180 − %d − %d = %d°。" % [t1, b, t2],
			"add": [ProblemGen.ang(p1, p2, p1 + Vector2(4.5, 0), "%d°" % t2)]},
		{"say": "この傾き %d° は、下の折れ点でも錯角で同じ!" % t2,
			"add": [ProblemGen.ang(p2, p1, p2 + Vector2(-4.5, 0), "%d°" % t2)]},
		{"say": "最後の線の傾きは 180 − %d − %d = %d°。" % [t2, c, t3],
			"add": [ProblemGen.ang(p2, p3, p2 + Vector2(4.5, 0), "%d°" % t3)]},
	]
	if ask_mid:
		shapes += [
			ProblemGen.ang(p1, p0, p2, "x"),
			ProblemGen.ang(p2, p1, p3, "%d°" % c),
			ProblemGen.ang(p3, p2, Vector2(0, 0), "%d°" % t3),
		]
		steps[4] = {"say": "x は折れ点の角。180 − %d − %d = %d°。入力してみよう!" % [t1, t2, b]}
		return {
			"q": "直線 l と m は平行です。ジグザグの折れ線の角 x は何度ですか。",
			"answer": float(b), "unit": "度",
			"hint1": "いちばん下の %d° から順に、平行線の錯角で角を上へ運んでいこう。" % t3,
			"hint2": "x = %d + %d − %d" % [c, t3, t1],
			"expl": "下から順に錯角で分けると x = %d + %d − %d = %d° になります。" % [c, t3, t1, b],
			"steps": steps,
			"fig": {"shapes": shapes},
		}
	shapes += [
		ProblemGen.ang(p1, p0, p2, "%d°" % b),
		ProblemGen.ang(p2, p1, p3, "%d°" % c),
		ProblemGen.ang(p3, p2, Vector2(0, 0), "x"),
	]
	steps.append({"say": "m との錯角で、x = %d°。入力してみよう!" % t3})
	return {
		"q": "直線 l と m は平行です。ジグザグの折れ線の角 x は何度ですか。",
		"answer": float(t3), "unit": "度",
		"hint1": "それぞれの折れ点を通る、l・m に平行な線を引いて、角を上下に分けよう。",
		"hint2": "x = %d + %d − %d" % [t1, b, c],
		"expl": "平行線を 2 本補助して錯角で移すと、x = %d + %d − %d = %d° になります。" % [t1, b, c, t3],
		"steps": steps,
		"fig": {"shapes": shapes},
	}


## e1 の高難度: 2 つの外角から残りの内角(挑戦用)
static func _e1_hard(rng: RandomNumberGenerator, step: int) -> Dictionary:
	var eb := step * rng.randi_range(95 / step, 150 / step)
	var ec := step * rng.randi_range(95 / step, 150 / step)
	var x := eb + ec - 180
	while x < 20 or x > 110:
		eb = step * rng.randi_range(95 / step, 150 / step)
		ec = step * rng.randi_range(95 / step, 150 / step)
		x = eb + ec - 180
	var ib := 180 - eb
	var ic := 180 - ec
	var v: Array = ProblemGen.tri_from_angles(float(ib), float(ic), 10.0)
	var far_b: Vector2 = v[1] + (v[1] - v[2]).normalized() * 3.0
	var far_c: Vector2 = v[2] + (v[2] - v[1]).normalized() * 3.0
	var fig := {"shapes": [
		ProblemGen.poly(v, ProblemGen.FILL_MAIN),
		ProblemGen.seg(v[1], far_b, ProblemGen.COL_DIM), ProblemGen.seg(v[2], far_c, ProblemGen.COL_DIM),
		ProblemGen.ang(v[1], far_b, v[0], "%d°" % eb),
		ProblemGen.ang(v[2], v[0], far_c, "%d°" % ec),
		ProblemGen.ang(v[0], v[1], v[2], "x"),
	]}
	return {
		"q": "三角形の 2 つの外角が図の通りのとき、角 x は何度ですか。",
		"answer": float(x), "unit": "度",
		"hint1": "外角のとなりの内角は 180° から引けば出るよ。内角 2 つがわかれば x も出せる。",
		"hint2": "x = 180 − (180−%d) − (180−%d) = %d + %d − 180" % [eb, ec, eb, ec],
		"expl": "内角は %d° と %d°。x = 180 − %d − %d = %d° です。" % [ib, ic, ib, ic, x],
		"fig": fig,
	}


## e6 の高難度: 二等辺三角形と外角
static func _e6_hard(rng: RandomNumberGenerator, step: int) -> Dictionary:
	# 底角の外角 a を与えて頂角 x を求める。底角 = 180 − a、x = 2a − 180
	var a := step * rng.randi_range(100 / step, 145 / step)
	var base := 180 - a
	var x := 180 - 2 * base
	var v: Array = ProblemGen.tri_from_angles(float(base), float(base), 10.0)
	var far: Vector2 = v[2] + (v[2] - v[1]).normalized() * 3.2
	var fig := {"shapes": [
		ProblemGen.poly(v, ProblemGen.FILL_MAIN),
		ProblemGen.tick(v[0], v[1]), ProblemGen.tick(v[0], v[2]),
		ProblemGen.seg(v[2], far, ProblemGen.COL_DIM),
		ProblemGen.ang(v[2], v[0], far, "%d°" % a),
		ProblemGen.ang(v[0], v[1], v[2], "x"),
	]}
	return {
		"q": "AB = AC の二等辺三角形で、底角の外角が %d° のとき、頂角 x は何度ですか。" % a,
		"answer": float(x), "unit": "度",
		"hint1": "底角は 180 − %d = %d°。二等辺だから底角は 2 つとも同じだよ。" % [a, base],
		"hint2": "x = 180 − %d × 2" % base,
		"expl": "底角 = 180 − %d = %d°。x = 180 − 2×%d = %d° です。" % [a, base, base, x],
		"fig": fig,
	}


## e8 の高難度: おうぎ形の「まわりの長さ」(弧 + 半径 2 本)
static func _e8_hard(rng: RandomNumberGenerator) -> Dictionary:
	var pairs: Array = []
	for r in [3, 4, 6, 9, 10, 12, 15, 18]:
		for th in [30, 45, 60, 90, 120, 135, 150, 180, 270]:
			if (r * th) % 90 == 0:
				pairs.append([r, th])
	var pick: Array = pairs[rng.randi_range(0, pairs.size() - 1)]
	var r: int = pick[0]
	var th: int = pick[1]
	var arc := 2.0 * 3.14 * r * th / 360.0
	var ans := arc + 2.0 * r
	var fig := {"shapes": [
		ProblemGen.sector(Vector2.ZERO, float(r), 0.0, float(th), ProblemGen.FILL_ACCENT, Color.WHITE),
		ProblemGen.ang(Vector2.ZERO, Vector2(float(r), 0),
			Vector2(cos(deg_to_rad(float(th))), sin(deg_to_rad(float(th)))) * r, "%d°" % th, 0.0, true),
		ProblemGen.label(Vector2(r * 0.6, -0.9), "%dcm" % r),
	]}
	return {
		"q": "半径 %dcm、中心角 %d° のおうぎ形の、まわりの長さ(弧と半径 2 本ぜんぶ)は何 cm ですか。円周率は 3.14 とします。" % [r, th],
		"answer": ans, "unit": "cm", "tol": 0.02,
		"hint1": "まわりの長さ = 弧の長さ + 半径 × 2。半径をわすれずに!",
		"hint2": "2 × 3.14 × %d × %d/360 + %d × 2" % [r, th, r],
		"expl": "弧 = %s cm、半径 2 本 = %d cm。合わせて %s cm です。" % [ProblemGen.fmt(arc), 2 * r, ProblemGen.fmt(ans)],
		"fig": fig,
	}


## e9 の高難度: 十字形の面積(たての帯 + よこの帯 − 重なり)
static func _e9_hard(rng: RandomNumberGenerator) -> Dictionary:
	var aw := rng.randi_range(9, 15)      # よこの帯の長さ
	var ah := rng.randi_range(8, 13)      # たての帯の長さ
	var w := rng.randi_range(2, 4)        # 帯のはば
	var ans := aw * w + ah * w - w * w
	var cx := aw * 0.5
	var cy := ah * 0.5
	var half := w * 0.5
	var p := [
		Vector2(cx - half, 0), Vector2(cx + half, 0),
		Vector2(cx + half, cy - half), Vector2(float(aw), cy - half),
		Vector2(float(aw), cy + half), Vector2(cx + half, cy + half),
		Vector2(cx + half, float(ah)), Vector2(cx - half, float(ah)),
		Vector2(cx - half, cy + half), Vector2(0, cy + half),
		Vector2(0, cy - half), Vector2(cx - half, cy - half),
	]
	var fig := {"shapes": [
		ProblemGen.poly(p, ProblemGen.FILL_MAIN),
		ProblemGen.label(Vector2(cx, -1.1), "たての長さ %dcm・よこの長さ %dcm" % [ah, aw], null, 24),
		ProblemGen.label(Vector2(cx, ah + 1.1), "はばはどちらも %dcm" % w, ProblemGen.COL_YELLOW, 24),
	]}
	return {
		"q": "はば %dcm の長方形の帯を、たて(長さ %dcm)とよこ(長さ %dcm)に重ねた十字形です。十字形の面積は何 cm² ですか。" % [w, ah, aw],
		"answer": float(ans), "unit": "cm²",
		"hint1": "たての帯とよこの帯をたすと、まん中の正方形を 2 回数えてしまうよ。1 回分引こう。",
		"hint2": "%d×%d + %d×%d − %d×%d" % [aw, w, ah, w, w, w],
		"expl": "帯 2 本の和 %d + %d から重なりの正方形 %d を引いて %d cm² です。" % [aw * w, ah * w, w * w, ans],
		"fig": fig,
	}


# =========================================================
# 挑戦モード用の追加解法(中学受験の入試定番から)
# =========================================================

## e1-比: 角の大きさの比から角度を求める
static func _e1_ratio(rng: RandomNumberGenerator) -> Dictionary:
	var p := 0
	var q := 0
	var r := 0
	var x := 0
	while true:
		p = rng.randi_range(1, 8)
		q = rng.randi_range(1, 8)
		r = rng.randi_range(1, 8)
		var m := maxi(p, maxi(q, r))
		var sum := p + q + r
		if (180 * m) % sum == 0 and 180 * m / sum <= 120 and 180 * m / sum >= 40:
			x = 180 * m / sum
			break
	var sum := p + q + r
	var ang_b := 180.0 * p / sum
	var ang_c := 180.0 * q / sum
	var v: Array = ProblemGen.tri_from_angles(ang_b, ang_c, 10.0)
	var fig := {"shapes": [
		ProblemGen.poly(v, ProblemGen.FILL_MAIN),
		ProblemGen.label(v[1] + Vector2(0.9, 0.55), str(p), ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(v[2] + Vector2(-0.9, 0.55), str(q), ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(v[0] + Vector2(0, -1.2), str(r), ProblemGen.COL_YELLOW, 26),
	]}
	return {
		"q": "三角形の 3 つの角の大きさの比が %d : %d : %d のとき、いちばん大きい角は何度ですか。" % [p, q, r],
		"answer": float(x), "unit": "度",
		"hint1": "3 つの角の和は 180°。比の合計 %d でわって 1 つ分を出そう。" % sum,
		"hint2": "1 つ分 = 180 ÷ %d。いちばん大きい角はその %d 倍。" % [sum, maxi(p, maxi(q, r))],
		"expl": "1 つ分は 180÷%d。最大の角 = 180×%d/%d = %d° です。" % [sum, maxi(p, maxi(q, r)), sum, x],
		"fig": fig,
	}


## e1-定規: 三角定規 2 枚を組み合わせた角
static func _e1_jougi(rng: RandomNumberGenerator) -> Dictionary:
	var opts := [30, 45, 60]
	var p: int = opts[rng.randi_range(0, 2)]
	var q: int = opts[rng.randi_range(0, 2)]
	var x := p + q
	var b1 := Vector2(4.4, 0)
	var apex1 := Vector2(4.4, 4.4 * tan(deg_to_rad(float(p))))
	var b2 := Vector2(cos(deg_to_rad(float(p))), sin(deg_to_rad(float(p)))) * 4.4
	var apex2: Vector2 = b2 + Vector2(cos(deg_to_rad(p + 90.0)), sin(deg_to_rad(p + 90.0))) * (4.4 * tan(deg_to_rad(float(q))))
	var fig := {"shapes": [
		ProblemGen.poly([Vector2.ZERO, b1, apex1], ProblemGen.FILL_MAIN),
		ProblemGen.poly([Vector2.ZERO, b2, apex2], ProblemGen.FILL_SUB),
		ProblemGen.right(b1, Vector2.ZERO, apex1),
		ProblemGen.right(b2, Vector2.ZERO, apex2),
		ProblemGen.ang(Vector2.ZERO, b1, b2, "%d°" % p, 1.1),
		ProblemGen.ang(Vector2.ZERO, b2, apex2, "%d°" % q, 1.9),
		ProblemGen.ang(Vector2.ZERO, b1, apex2, "x", 2.9),
	]}
	return {
		"q": "三角定規を 2 枚、図のように重ならないように並べました。いちばん外側の角 x は何度ですか。",
		"answer": float(x), "unit": "度",
		"hint1": "角 x は 2 枚の定規の角をたしたものだよ。",
		"hint2": "x = %d + %d" % [p, q],
		"expl": "x = %d + %d = %d° です。" % [p, q, x],
		"fig": fig,
	}


## e1-外角: 外角と内角 1 つから残りの内角
static func _e1_ext(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(30, 80)
	var ext := rng.randi_range(a + 25, 145)
	var x := ext - a
	var v: Array = ProblemGen.tri_from_angles(float(a), 180.0 - float(ext), 10.0)
	var far: Vector2 = v[2] + (v[2] - v[1]).normalized() * 3.2
	var fig := {"shapes": [
		ProblemGen.poly(v, ProblemGen.FILL_MAIN),
		ProblemGen.seg(v[2], far, ProblemGen.COL_DIM),
		ProblemGen.ang(v[1], v[2], v[0], "%d°" % a),
		ProblemGen.ang(v[0], v[1], v[2], "x"),
		ProblemGen.ang(v[2], v[0], far, "%d°" % ext),
	]}
	return {
		"q": "三角形の外角が %d°、内角の 1 つが %d° のとき、角 x は何度ですか。" % [ext, a],
		"answer": float(x), "unit": "度",
		"hint1": "外角は、となり合わない 2 つの内角の和に等しいよ。",
		"hint2": "x = %d − %d" % [ext, a],
		"expl": "外角の定理より %d = %d + x。x = %d° です。" % [ext, a, x],
		"fig": fig,
	}


## e2-逆算: 面積とよこの長さから、たての長さ
static func _e2_missing_side(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(3, 12)      # たて(答え)
	var b := rng.randi_range(4, 15)      # よこ
	var s := a * b
	var fig := {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(b, 0), Vector2(b, a), Vector2(0, a)], ProblemGen.FILL_MAIN),
		ProblemGen.side_label(Vector2(0, 0), Vector2(b, 0), "%dcm" % b, 1.0),
		ProblemGen.label(Vector2(-1.4, a * 0.5), "?cm", ProblemGen.COL_YELLOW),
		ProblemGen.label(Vector2(b * 0.5, a * 0.5), "面積 %dcm²" % s),
	]}
	return {
		"q": "面積が %dcm²、よこの長さが %dcm の長方形の、たての長さは何 cm ですか。" % [s, b],
		"answer": float(a), "unit": "cm",
		"hint1": "面積 = たて × よこ。たて = 面積 ÷ よこ で逆算しよう。",
		"hint2": "%d ÷ %d" % [s, b],
		"expl": "たて = %d ÷ %d = %d cm です。" % [s, b, a],
		"fig": fig,
	}


## e2-折り: 正方形を半分に折った長方形のまわりの長さから、もとの面積
static func _e2_fold(rng: RandomNumberGenerator) -> Dictionary:
	var a := 2 * rng.randi_range(2, 9)   # もとの 1 辺(偶数)
	var perim := 3 * a                   # 折ったあとの周 = a + a + a/2 + a/2
	var fig := {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(a, 0), Vector2(a, a), Vector2(0, a)], null, ProblemGen.COL_DIM, 2.5),
		ProblemGen.seg(Vector2(0, a * 0.5), Vector2(a, a * 0.5), ProblemGen.COL_YELLOW, 3.0, true),
		ProblemGen.poly([Vector2(0, 0), Vector2(a, 0), Vector2(a, a * 0.5), Vector2(0, a * 0.5)], ProblemGen.FILL_ACCENT),
		ProblemGen.label(Vector2(a * 0.5, -1.2), "折ったあとの まわりの長さ %dcm" % perim, null, 24),
	]}
	return {
		"q": "正方形の紙を半分に折ると、まわりの長さが %dcm の長方形になりました。もとの正方形の面積は何 cm² ですか。" % perim,
		"answer": float(a * a), "unit": "cm²",
		"hint1": "折った長方形の周は、もとの 1 辺を □ とすると □ + □ + □/2 + □/2 = □ × 3 だよ。",
		"hint2": "1 辺 = %d ÷ 3 = %d。面積は %d × %d。" % [perim, a, a, a],
		"expl": "1 辺 = %d ÷ 3 = %d cm。面積 = %d² = %d cm² です。" % [perim, a, a, a * a],
		"fig": fig,
	}


## e2-差: まわりの長さが同じ長方形と正方形の面積の差
static func _e2_diff(rng: RandomNumberGenerator) -> Dictionary:
	var b := rng.randi_range(3, 9)
	var a := b + 2 * rng.randi_range(1, 5)    # a > b、a+b は偶数
	var sq := (a + b) / 2
	var diff := sq * sq - a * b
	var fig := {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(a, 0), Vector2(a, b), Vector2(0, b)], ProblemGen.FILL_MAIN),
		ProblemGen.side_label(Vector2(0, 0), Vector2(a, 0), "%dcm" % a, 1.0),
		ProblemGen.side_label(Vector2(0, 0), Vector2(0, b), "%dcm" % b, -1.0),
		ProblemGen.poly([Vector2(a + 3, 0), Vector2(a + 3 + sq, 0), Vector2(a + 3 + sq, sq), Vector2(a + 3, sq)], ProblemGen.FILL_ACCENT),
		ProblemGen.label(Vector2(a + 3 + sq * 0.5, sq * 0.5), "?", ProblemGen.COL_YELLOW, 34),
	]}
	return {
		"q": "たて %dcm・よこ %dcm の長方形と、まわりの長さが同じ正方形を作ります。正方形の面積は長方形の面積より何 cm² 大きいですか。" % [b, a],
		"answer": float(diff), "unit": "cm²",
		"hint1": "周は %d cm。正方形の 1 辺はその 4 分の 1 = %d cm だよ。" % [2 * (a + b), sq],
		"hint2": "%d × %d − %d × %d" % [sq, sq, a, b],
		"expl": "正方形 %d² = %d、長方形 %d×%d = %d。差は %d cm² です。" % [sq, sq * sq, a, b, a * b, diff],
		"fig": fig,
	}


## e3-斜辺: 直角三角形の斜辺を底辺と見たときの高さ(面積の 2 通り表し)
static func _e3_hyp_height(rng: RandomNumberGenerator) -> Dictionary:
	var k := rng.randi_range(1, 5)
	var a := 3 * k
	var b := 4 * k
	var c := 5 * k
	var h := 2.4 * k
	var foot := Vector2(1.8 * k, 0)
	var top := Vector2(1.8 * k, 2.4 * k)
	var fig := {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(float(c), 0), top], ProblemGen.FILL_MAIN),
		ProblemGen.seg(foot, top, ProblemGen.COL_YELLOW, 3.0, true),
		ProblemGen.right(foot, Vector2(float(c), 0), top),
		ProblemGen.right(top, Vector2(0, 0), Vector2(float(c), 0)),
		ProblemGen.side_label(Vector2(0, 0), Vector2(float(c), 0), str(c), 1.0),
		ProblemGen.side_label(top, Vector2(0, 0), str(a), 1.0),
		ProblemGen.side_label(Vector2(float(c), 0), top, str(b), 1.0),
		ProblemGen.label(foot + Vector2(1.2, 1.0), "x", ProblemGen.COL_YELLOW, 32),
	]}
	return {
		"q": "直角をはさむ 2 辺が %d と %d、斜辺が %d の直角三角形で、斜辺を底辺と見たときの高さ x を求めなさい。" % [a, b, c],
		"answer": h, "unit": "cm",
		"hint1": "面積を 2 通りで表そう。%d×%d÷2 と %d×x÷2 は同じ面積だよ。" % [a, b, c],
		"hint2": "x = %d × %d ÷ %d" % [a, b, c],
		"expl": "面積 = %d×%d÷2 = %s。x = 2×面積÷%d = %s cm です。" % [a, b, ProblemGen.fmt(a * b / 2.0), c, ProblemGen.fmt(h)],
		"fig": fig,
	}


## e3-合体: 対角線で 2 つの三角形に分かれた四角形の面積
static func _e3_double(rng: RandomNumberGenerator) -> Dictionary:
	var d := 2 * rng.randi_range(3, 7)    # 対角線(偶数)
	var h1 := rng.randi_range(2, 6)
	var h2 := rng.randi_range(2, 7)
	var ans := d * (h1 + h2) / 2
	var pa := Vector2(0, 0)
	var pc := Vector2(float(d), 0)
	var pb := Vector2(d * rng.randf_range(0.3, 0.7), -float(h1))
	var pd := Vector2(d * rng.randf_range(0.3, 0.7), float(h2))
	var fig := {"shapes": [
		ProblemGen.poly([pa, pb, pc, pd], ProblemGen.FILL_MAIN),
		ProblemGen.seg(pa, pc, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.seg(pb, Vector2(pb.x, 0), ProblemGen.COL_DIM, 2.5, true),
		ProblemGen.seg(pd, Vector2(pd.x, 0), ProblemGen.COL_DIM, 2.5, true),
		ProblemGen.side_label(pa, pc, "%dcm" % d, -1.0),
		ProblemGen.label(Vector2(pb.x + 1.2, -h1 * 0.5), "%dcm" % h1),
		ProblemGen.label(Vector2(pd.x + 1.2, h2 * 0.5), "%dcm" % h2),
	]}
	return {
		"q": "対角線 AC の長さが %dcm の四角形で、B と D から AC までの高さがそれぞれ %dcm と %dcm です。四角形の面積は何 cm² ですか。" % [d, h1, h2],
		"answer": float(ans), "unit": "cm²",
		"hint1": "対角線で上下 2 つの三角形に分けよう。底辺はどちらも %dcm だよ。" % d,
		"hint2": "%d×%d÷2 + %d×%d÷2" % [d, h1, d, h2],
		"expl": "上下の三角形の和 = %d×(%d+%d)÷2 = %d cm² です。" % [d, h1, h2, ans],
		"fig": fig,
	}


## e3-等積: 面積を保ったまま底辺を変えると高さは?(2 段階の計算)
static func _e3_equal(rng: RandomNumberGenerator) -> Dictionary:
	var b1 := 2 * rng.randi_range(2, 7)
	var h1 := rng.randi_range(3, 9)
	var s := b1 * h1 / 2
	# 2S を割り切る別の底辺を選ぶ
	var cands: Array = []
	for b2 in range(3, 16):
		if b2 != b1 and (2 * s) % b2 == 0:
			cands.append(b2)
	var b2: int = cands[rng.randi_range(0, cands.size() - 1)]
	var h2 := 2 * s / b2
	var fig := {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(b1, 0), Vector2(b1 * 0.4, h1)], ProblemGen.FILL_MAIN),
		ProblemGen.side_label(Vector2(0, 0), Vector2(b1, 0), "%dcm" % b1, 1.0),
		ProblemGen.label(Vector2(b1 * 0.4 + 1.3, h1 * 0.55), "%dcm" % h1),
		ProblemGen.poly([Vector2(b1 + 3, 0), Vector2(b1 + 3 + b2, 0), Vector2(b1 + 3 + b2 * 0.45, float(h2))], ProblemGen.FILL_ACCENT),
		ProblemGen.side_label(Vector2(b1 + 3, 0), Vector2(b1 + 3 + b2, 0), "%dcm" % b2, 1.0),
		ProblemGen.label(Vector2(b1 + 3 + b2 * 0.45 + 1.3, h2 * 0.55), "x", ProblemGen.COL_YELLOW, 30),
	]}
	return {
		"q": "底辺 %dcm・高さ %dcm の三角形と面積が等しい、底辺 %dcm の三角形を作ります。高さ x は何 cm ですか。" % [b1, h1, b2],
		"answer": float(h2), "unit": "cm",
		"hint1": "まず左の三角形の面積を求めよう。%d×%d÷2 = %d cm² だよ。" % [b1, h1, s],
		"hint2": "x = %d × 2 ÷ %d" % [s, b2],
		"expl": "面積は %d cm²。x = %d×2÷%d = %d cm です。" % [s, s, b2, h2],
		"fig": fig,
	}


## e4-同側内角: 平行線の同じ側の内角(たすと 180°)
static func _e4_coint(rng: RandomNumberGenerator) -> Dictionary:
	var w := 12.0
	var a := rng.randi_range(35, 145)
	var rad := deg_to_rad(float(a))
	var p_low := Vector2(4, 0)
	var p_high := p_low + Vector2(5.0 / tan(rad), 5.0)
	var fig := {"shapes": [
		ProblemGen.seg(Vector2(0, 0), Vector2(w, 0)), ProblemGen.seg(Vector2(0, 5), Vector2(w, 5)),
		ProblemGen.label(Vector2(w + 0.7, 0), "m"), ProblemGen.label(Vector2(w + 0.7, 5), "l"),
		ProblemGen.seg(p_low - (p_high - p_low) * 0.25, p_high + (p_high - p_low) * 0.25, ProblemGen.COL_DIM, 4.0),
		ProblemGen.ang(p_low, Vector2(w, 0), p_high, "%d°" % a),
		ProblemGen.ang(p_high, Vector2(w, 5), p_low, "x"),
	]}
	return {
		"q": "直線 l と m は平行です。角 x は何度ですか。",
		"answer": float(180 - a), "unit": "度",
		"hint1": "x と %d° は平行線の同じ側にある内角。たすと 180° になるよ。" % a,
		"hint2": "x = 180 − %d" % a,
		"expl": "同側内角の和は 180°。x = 180 − %d = %d° です。" % [a, 180 - a],
		"fig": fig,
	}


## e5-逆算: 平行四辺形の面積と底辺から高さ
static func _e5_para_rev(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(5, 14)
	var h := rng.randi_range(3, 10)
	var s := a * h
	var sk := 2.5
	var fig := {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(a, 0), Vector2(a + sk, h), Vector2(sk, h)], ProblemGen.FILL_MAIN),
		ProblemGen.side_label(Vector2(0, 0), Vector2(a, 0), "%dcm" % a, 1.0),
		ProblemGen.label(Vector2(a * 0.55, h * 0.5), "面積 %dcm²" % s),
	]}
	return {
		"q": "面積が %dcm²、底辺が %dcm の平行四辺形の高さは何 cm ですか。" % [s, a],
		"answer": float(h), "unit": "cm",
		"hint1": "面積 = 底辺 × 高さ。高さ = 面積 ÷ 底辺 だよ(÷2 はいらない)。",
		"hint2": "%d ÷ %d" % [s, a],
		"expl": "高さ = %d ÷ %d = %d cm です。" % [s, a, h],
		"fig": fig,
	}


## e5-台形の高さ: 面積と上底・下底から高さ
static func _e5_trap_rev(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(3, 8)
	var b := rng.randi_range(a + 2, 14)
	if (a + b) % 2 == 1:
		b += 1
	var h := rng.randi_range(3, 9)
	var s := (a + b) * h / 2
	var off := (b - a) * 0.5
	var fig := {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(b, 0), Vector2(off + a, h), Vector2(off, h)], ProblemGen.FILL_MAIN),
		ProblemGen.side_label(Vector2(off, h), Vector2(off + a, h), "%dcm" % a, 1.0),
		ProblemGen.side_label(Vector2(0, 0), Vector2(b, 0), "%dcm" % b, 1.0),
		ProblemGen.label(Vector2(b * 0.5, h * 0.45), "面積 %dcm²" % s),
	]}
	return {
		"q": "上底 %dcm、下底 %dcm、面積 %dcm² の台形の高さは何 cm ですか。" % [a, b, s],
		"answer": float(h), "unit": "cm",
		"hint1": "面積 = (上底+下底)×高さ÷2 を逆に使おう。",
		"hint2": "高さ = %d × 2 ÷ (%d + %d)" % [s, a, b],
		"expl": "高さ = %d×2÷%d = %d cm です。" % [s, a + b, h],
		"fig": fig,
	}


## e5-上底: 面積・高さ・下底から上底を逆算(2 段階)
static func _e5_trap_top(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(3, 8)       # 上底(答え)
	var b := rng.randi_range(a + 2, 14)  # 下底
	if (a + b) % 2 == 1:
		b += 1
	var h := rng.randi_range(3, 9)
	var s := (a + b) * h / 2
	var off := (b - a) * 0.5
	var fig := {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(b, 0), Vector2(off + a, h), Vector2(off, h)], ProblemGen.FILL_ACCENT),
		ProblemGen.label(Vector2(b * 0.5, h + 1.0), "?cm", ProblemGen.COL_YELLOW),
		ProblemGen.side_label(Vector2(0, 0), Vector2(b, 0), "%dcm" % b, 1.0),
		ProblemGen.label(Vector2(b * 0.5, h * 0.45), "面積 %dcm²・高さ %dcm" % [s, h], null, 24),
	]}
	return {
		"q": "下底 %dcm、高さ %dcm、面積 %dcm² の台形の上底は何 cm ですか。" % [b, h, s],
		"answer": float(a), "unit": "cm",
		"hint1": "まず (上底+下底) を出そう。面積×2÷高さ = %d だよ。" % (a + b),
		"hint2": "上底 = %d × 2 ÷ %d − %d" % [s, h, b],
		"expl": "上底+下底 = %d×2÷%d = %d。上底 = %d − %d = %d cm です。" % [s, h, a + b, a + b, b, a],
		"fig": fig,
	}


## e6-差: 頂角と底角の差から底角を求める
static func _e6_diff(rng: RandomNumberGenerator) -> Dictionary:
	var bigger := rng.randf() < 0.5
	var b := rng.randi_range(25, 55) if bigger else rng.randi_range(63, 84)
	var d := (180 - 3 * b) if bigger else (3 * b - 180)
	var v: Array = ProblemGen.tri_from_angles(float(b), float(b), 10.0)
	var rel := "大きい" if bigger else "小さい"
	var fig := {"shapes": [
		ProblemGen.poly(v, ProblemGen.FILL_MAIN),
		ProblemGen.tick(v[0], v[1]), ProblemGen.tick(v[0], v[2]),
		ProblemGen.ang(v[1], v[2], v[0], "x"),
		ProblemGen.label(v[0] + Vector2(0, 1.2), "頂角は底角より %d° %s" % [d, rel], null, 24),
	]}
	return {
		"q": "AB = AC の二等辺三角形で、頂角は底角より %d° %sくなっています。底角 x は何度ですか。" % [d, rel],
		"answer": float(b), "unit": "度",
		"hint1": "底角を □ とすると、頂角は □ %s %d°。3 つの角の和で式を立てよう。" % ["+" if bigger else "−", d],
		"hint2": "□ × 3 %s %d = 180" % ["+" if bigger else "−", d],
		"expl": "底角×3 %s %d = 180 なので、底角 = %d° です。" % ["+" if bigger else "−", d, b],
		"fig": fig,
	}


## e7-逆算: 内角の和から何角形かを求める
static func _e7_sum_rev(rng: RandomNumberGenerator) -> Dictionary:
	var n := rng.randi_range(5, 14)
	var sum := (n - 2) * 180
	var fig := {"shapes": [
		ProblemGen.circle(Vector2.ZERO, 4.5, null, ProblemGen.COL_DIM, 3.0),
		ProblemGen.label(Vector2(0, 0.6), "内角の和", null, 28),
		ProblemGen.label(Vector2(0, -0.9), "%d°" % sum, ProblemGen.COL_YELLOW, 40),
	]}
	return {
		"q": "内角の和が %d° の多角形は、何角形ですか。(数字で答えなさい)" % sum,
		"answer": float(n), "unit": "角形",
		"hint1": "内角の和 = (角の数 − 2) × 180° を逆に使おう。",
		"hint2": "%d ÷ 180 + 2" % sum,
		"expl": "%d ÷ 180 = %d なので、角の数は %d + 2 = %d。%d角形です。" % [sum, n - 2, n - 2, n, n],
		"fig": fig,
	}


## e8-半円: 半円のまわりの長さ(曲線 + 直径)
static func _e8_semi_perim(rng: RandomNumberGenerator) -> Dictionary:
	var r := rng.randi_range(2, 12)
	var ans := 3.14 * r + 2.0 * r
	var fig := {"shapes": [
		ProblemGen.sector(Vector2.ZERO, float(r), 0.0, 180.0, ProblemGen.FILL_MAIN, Color.WHITE),
		ProblemGen.label(Vector2(0, -1.0), "半径 %dcm" % r),
	]}
	return {
		"q": "半径 %dcm の半円の、まわりの長さ(曲線と直径ぜんぶ)は何 cm ですか。円周率は 3.14 とします。" % r,
		"answer": ans, "unit": "cm", "tol": 0.02,
		"hint1": "曲線部分は円周の半分。まっすぐな直径の分をたし忘れないでね。",
		"hint2": "%d × 2 × 3.14 ÷ 2 + %d" % [r, 2 * r],
		"expl": "曲線 %s + 直径 %d = %s cm です。" % [ProblemGen.fmt(3.14 * r), 2 * r, ProblemGen.fmt(ans)],
		"fig": fig,
	}


## e8-逆算: 円の面積から半径を求める
static func _e8_area_rev(rng: RandomNumberGenerator) -> Dictionary:
	var r := rng.randi_range(2, 9)
	var s := 3.14 * r * r
	var fig := {"shapes": [
		ProblemGen.circle(Vector2.ZERO, float(r), ProblemGen.FILL_ACCENT),
		ProblemGen.label(Vector2.ZERO, "面積 %scm²" % ProblemGen.fmt(s), null, 26),
	]}
	return {
		"q": "面積が %scm² の円の半径は何 cm ですか。円周率は 3.14 とします。" % ProblemGen.fmt(s),
		"answer": float(r), "unit": "cm",
		"hint1": "面積 ÷ 3.14 = 半径 × 半径。同じ数を 2 回かけて %d になる数をさがそう。" % (r * r),
		"hint2": "%s ÷ 3.14 = %d = %d × %d" % [ProblemGen.fmt(s), r * r, r, r],
		"expl": "半径×半径 = %s÷3.14 = %d。半径 = %d cm です。" % [ProblemGen.fmt(s), r * r, r],
		"fig": fig,
	}


## e9-階段: 階段の形のまわりの長さ(たてよこに寄せると長方形と同じ)
static func _e9_stairs(rng: RandomNumberGenerator) -> Dictionary:
	var w := rng.randi_range(7, 13)
	var h := rng.randi_range(6, 11)
	var w1 := rng.randi_range(3, w - 3)
	var w2 := rng.randi_range(1, w1 - 1)
	var s1 := rng.randi_range(2, h - 3)
	var s2 := rng.randi_range(s1 + 1, h - 1)
	var pts := [
		Vector2(0, 0), Vector2(w, 0), Vector2(w, s1), Vector2(w1, s1),
		Vector2(w1, s2), Vector2(w2, s2), Vector2(w2, h), Vector2(0, h),
	]
	var fig := {"shapes": [
		ProblemGen.poly(pts, ProblemGen.FILL_MAIN),
		ProblemGen.side_label(Vector2(0, 0), Vector2(w, 0), "%dcm" % w, 1.0),
		ProblemGen.side_label(Vector2(0, 0), Vector2(0, h), "%dcm" % h, -1.0),
	]}
	return {
		"q": "図のような階段の形の、まわりの長さは何 cm ですか。(角はすべて直角です)",
		"answer": float(2 * (w + h)), "unit": "cm",
		"hint1": "でこぼこのたての線を右に、よこの線を上に寄せて考えると、大きな長方形のまわりとぴったり同じになるよ。",
		"hint2": "(%d + %d) × 2" % [w, h],
		"expl": "階段の周は たて・よこに寄せると %d×%d の長方形の周と同じ。(%d+%d)×2 = %d cm です。" % [w, h, w, h, 2 * (w + h)],
		"fig": fig,
	}


## e11-文字盤: 文字盤の数字と数字の間の角
static func _e11_dial(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(1, 12)
	var b := a
	while b == a:
		b = rng.randi_range(1, 12)
	var diff := absi(a - b)
	diff = mini(diff, 12 - diff)
	var x := diff * 30
	var da := 90.0 - a * 30.0
	var db := 90.0 - b * 30.0
	var r := 5.0
	var shapes: Array = [ProblemGen.circle(Vector2.ZERO, r)]
	for i in 12:
		var d := Vector2(cos(TAU * i / 12.0), sin(TAU * i / 12.0))
		shapes.append(ProblemGen.seg(d * (r - 0.45), d * r, ProblemGen.COL_DIM, 3.0))
	shapes += [
		ProblemGen.label(Vector2(0, r - 1.1), "12", null, 24),
		ProblemGen.label(Vector2(r - 1.1, 0), "3", null, 24),
		ProblemGen.label(Vector2(0, -r + 1.1), "6", null, 24),
		ProblemGen.label(Vector2(-r + 1.1, 0), "9", null, 24),
		ProblemGen.seg(Vector2.ZERO, Vector2(cos(deg_to_rad(da)), sin(deg_to_rad(da))) * (r - 0.6), ProblemGen.COL_YELLOW, 4.0),
		ProblemGen.seg(Vector2.ZERO, Vector2(cos(deg_to_rad(db)), sin(deg_to_rad(db))) * (r - 0.6), ProblemGen.COL_YELLOW, 4.0),
		ProblemGen.ang(Vector2.ZERO, Vector2(cos(deg_to_rad(da)), sin(deg_to_rad(da))), Vector2(cos(deg_to_rad(db)), sin(deg_to_rad(db))), "x", 1.2),
	]
	return {
		"q": "時計の文字盤で、中心から %d と %d へ線を引きました。間の角(小さい方)は何度ですか。" % [a, b],
		"answer": float(x), "unit": "度",
		"hint1": "文字盤の数字 1 つ分の角は 360 ÷ 12 = 30° だよ。",
		"hint2": "30 × %d" % diff,
		"expl": "1 区切り 30° × %d 区切り = %d° です。" % [diff, x],
		"fig": {"shapes": shapes},
	}


## e11-ちょうど: ○時ちょうどの針の角
static func _e11_oclock(rng: RandomNumberGenerator) -> Dictionary:
	var h := rng.randi_range(1, 11)
	var x := mini(30 * h, 360 - 30 * h)
	var r := 5.0
	var hour_deg := 90.0 - 30.0 * h
	var shapes: Array = [ProblemGen.circle(Vector2.ZERO, r)]
	for i in 12:
		var d := Vector2(cos(TAU * i / 12.0), sin(TAU * i / 12.0))
		shapes.append(ProblemGen.seg(d * (r - 0.45), d * r, ProblemGen.COL_DIM, 3.0))
	shapes += [
		ProblemGen.label(Vector2(0, r - 1.1), "12", null, 24),
		ProblemGen.label(Vector2(0, -r + 1.1), "6", null, 24),
		ProblemGen.arrow(Vector2.ZERO, Vector2(cos(deg_to_rad(hour_deg)), sin(deg_to_rad(hour_deg))) * 2.8, Color.WHITE, 7.0),
		ProblemGen.arrow(Vector2.ZERO, Vector2(0, 4.2), ProblemGen.COL_YELLOW, 5.0),
		ProblemGen.ang(Vector2.ZERO, Vector2(cos(deg_to_rad(hour_deg)), sin(deg_to_rad(hour_deg))) * 2.8, Vector2(0, 4.2), "x", 1.2),
		ProblemGen.circle(Vector2.ZERO, 0.15, Color.WHITE),
	]
	return {
		"q": "%d 時ちょうどのとき、長針と短針のつくる角(小さい方)は何度ですか。" % h,
		"answer": float(x), "unit": "度",
		"hint1": "長針は 12 をさしている。短針は 1 時間で 30° 進むよ。",
		"hint2": "30 × %d(180° をこえたら 360 から引く)" % h,
		"expl": "30°×%d = %d°%s なので答えは %d° です。" % [h, 30 * h, "(大きい方なので 360 から引く)" if 30 * h > 180 else "", x],
		"fig": {"shapes": shapes},
	}


## e11-逆算: 針の角からちょうどの時刻を求める
static func _e11_rev(rng: RandomNumberGenerator) -> Dictionary:
	var h := rng.randi_range(1, 6)
	var deg := 30 * h
	var r := 5.0
	var shapes: Array = [ProblemGen.circle(Vector2.ZERO, r)]
	for i in 12:
		var d := Vector2(cos(TAU * i / 12.0), sin(TAU * i / 12.0))
		shapes.append(ProblemGen.seg(d * (r - 0.45), d * r, ProblemGen.COL_DIM, 3.0))
	shapes.append(ProblemGen.label(Vector2.ZERO, "?", ProblemGen.COL_YELLOW, 44))
	return {
		"q": "1 時から 6 時までの「ちょうどの時刻」のうち、長針と短針の角が %d° になるのは何時ですか。(数字で答えなさい)" % deg,
		"answer": float(h), "unit": "時",
		"hint1": "ちょうどの時刻の角は 30° × (時)。",
		"hint2": "%d ÷ 30" % deg,
		"expl": "%d ÷ 30 = %d なので %d 時です。" % [deg, h, h],
		"fig": {"shapes": shapes},
	}


## e12-逆算: へこみの角がわかっていて、1 つの角を求める
static func _e12_rev(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(20, 50)
	var b := rng.randi_range(20, 50)
	var c := rng.randi_range(20, 50)
	var x := a + b + c
	while x < 60 or x > 150:
		c = rng.randi_range(20, 50)
		x = a + b + c
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
		ProblemGen.ang(pc, pd, pb, "x"),
		ProblemGen.ang(pd, pa, pc, "%d°" % x),
	]}
	return {
		"q": "ブーメラン形のへこみの角が %d° のとき、角 x は何度ですか。" % x,
		"answer": float(c), "unit": "度",
		"hint1": "へこみの角は残り 3 つの角の和。逆に引けば x が出るよ。",
		"hint2": "x = %d − %d − %d" % [x, a, b],
		"expl": "%d = %d + %d + x なので、x = %d° です。" % [x, a, b, c],
		"fig": fig,
	}


## e13-逆算: 折り返してできた角から折り目の角を求める
static func _e13_rev(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(42, 80)       # 折り目の角(答え)
	var x := 180 - 2 * a                   # 図に見えている角
	var p := Vector2(7, 0)
	var d := Vector2(cos(deg_to_rad(float(a))), sin(deg_to_rad(float(a))))
	var q := p + d * (2.5 / sin(deg_to_rad(float(a))))
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
		ProblemGen.ang(p, Vector2(12, 0), q, "x"),
		ProblemGen.ang(p, r1, Vector2(0, 0), "%d°" % x),
	]}
	return {
		"q": "長方形の紙テープを折り返したら、図の位置に %d° の角ができました。折り目の角 x は何度ですか。" % x,
		"answer": float(a), "unit": "度",
		"hint1": "P のまわりは一直線で 180°。折り目の角 x が 2 つと %d° でぴったりだよ。" % x,
		"hint2": "x = (180 − %d) ÷ 2" % x,
		"expl": "x×2 + %d = 180 なので、x = %d° です。" % [x, a],
		"fig": fig,
	}


## e14-ななめ: ななめの道(平行四辺形の帯)でも考え方は同じ
static func _e14_slant(rng: RandomNumberGenerator) -> Dictionary:
	var aw := rng.randi_range(9, 16)
	var ah := rng.randi_range(6, 12)
	var w := rng.randi_range(1, 3)
	var ans := (aw - w) * ah
	var vx := rng.randi_range(1, aw - w - 4)
	var sh := rng.randi_range(1, 3)      # 上端のずれ(ななめ具合)
	var road := Color(0.42, 0.36, 0.3, 0.95)
	var fig := {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(aw, 0), Vector2(aw, ah), Vector2(0, ah)], ProblemGen.FILL_SUB),
		ProblemGen.poly([Vector2(vx, 0), Vector2(vx + w, 0), Vector2(vx + w + sh, ah), Vector2(vx + sh, ah)], road),
		ProblemGen.side_label(Vector2(0, 0), Vector2(aw, 0), "%dm" % aw, 1.0),
		ProblemGen.side_label(Vector2(0, 0), Vector2(0, ah), "%dm" % ah, -1.0),
		ProblemGen.label(Vector2(vx + w * 0.5, -1.0), "下のはば %dm" % w, ProblemGen.COL_YELLOW, 24),
	]}
	return {
		"q": "たて %dm・よこ %dm の長方形の土地に、下のはばが %dm のななめの道を通しました。道をのぞいた残りの面積は何 m² ですか。" % [ah, aw, w],
		"answer": float(ans), "unit": "m²",
		"hint1": "ななめの道も、左右の土地をくっつければ まっすぐの道と同じ。よこが %dm 減るだけだよ。" % w,
		"hint2": "(%d − %d) × %d" % [aw, w, ah],
		"expl": "道の左右を寄せると (%d−%d)×%d = %d m² です。" % [aw, w, ah, ans],
		"fig": fig,
	}


## e15-全体: 上下の三角形から長方形全体の面積を求める
static func _e15_whole(rng: RandomNumberGenerator) -> Dictionary:
	var aw := 2 * rng.randi_range(4, 10)
	var ah := 2 * rng.randi_range(3, 8)
	var px := rng.randi_range(2, aw - 2)
	var py := rng.randi_range(1, ah - 1)
	var s_bottom := aw * py / 2
	var s_top := aw * (ah - py) / 2
	var total := aw * ah
	var p := Vector2(px, py)
	var fig := {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(aw, 0), Vector2(aw, ah), Vector2(0, ah)], null, Color.WHITE, 3.5),
		ProblemGen.seg(p, Vector2(0, 0), ProblemGen.COL_DIM, 2.5),
		ProblemGen.seg(p, Vector2(aw, 0), ProblemGen.COL_DIM, 2.5),
		ProblemGen.seg(p, Vector2(aw, ah), ProblemGen.COL_DIM, 2.5),
		ProblemGen.seg(p, Vector2(0, ah), ProblemGen.COL_DIM, 2.5),
		ProblemGen.circle(p, 0.12, ProblemGen.COL_YELLOW),
		ProblemGen.label(Vector2(aw * 0.5, py * 0.4), "%d" % s_bottom),
		ProblemGen.label(Vector2(aw * 0.5, ah - (ah - py) * 0.4), "%d" % s_top),
		ProblemGen.label(Vector2(aw * 0.5, ah + 1.1), "長方形全体 = ?", ProblemGen.COL_YELLOW, 26),
	]}
	return {
		"q": "長方形の中の点と 4 つの頂点を結びました。上の三角形が %d cm²、下の三角形が %d cm² のとき、長方形全体の面積は何 cm² ですか。" % [s_top, s_bottom],
		"answer": float(total), "unit": "cm²",
		"hint1": "上の三角形と下の三角形をたすと、長方形のちょうど半分になるよ。",
		"hint2": "(%d + %d) × 2" % [s_top, s_bottom],
		"expl": "上下の和 %d は全体の半分。全体 = %d × 2 = %d cm² です。" % [s_top + s_bottom, s_top + s_bottom, total],
		"fig": fig,
	}


## e16-三分割: 底辺を 3 つに分けたときの真ん中の三角形
static func _e16_three(rng: RandomNumberGenerator) -> Dictionary:
	var p := rng.randi_range(1, 4)
	var q := rng.randi_range(1, 4)
	var r := rng.randi_range(1, 4)
	var k := rng.randi_range(2, 8)
	var total := (p + q + r) * k
	var pb := Vector2(0, 0)
	var pc := Vector2(12, 0)
	var pa := Vector2(rng.randf_range(4.0, 7.0), 7.0)
	var pd: Vector2 = pb + (pc - pb) * (float(p) / float(p + q + r))
	var pe: Vector2 = pb + (pc - pb) * (float(p + q) / float(p + q + r))
	var fig := {"shapes": [
		ProblemGen.poly([pa, pb, pc], ProblemGen.FILL_MAIN),
		ProblemGen.seg(pa, pd, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.seg(pa, pe, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.label(pa + Vector2(0, 0.8), "A"),
		ProblemGen.label(pb + Vector2(-0.7, -0.5), "B"), ProblemGen.label(pc + Vector2(0.7, -0.5), "C"),
		ProblemGen.label(pd + Vector2(0, -0.9), "D"), ProblemGen.label(pe + Vector2(0, -0.9), "E"),
		ProblemGen.label((pb + pd) * 0.5 + Vector2(0, -1.7), str(p), ProblemGen.COL_YELLOW, 26),
		ProblemGen.label((pd + pe) * 0.5 + Vector2(0, -1.7), str(q), ProblemGen.COL_YELLOW, 26),
		ProblemGen.label((pe + pc) * 0.5 + Vector2(0, -1.7), str(r), ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(Vector2(pa.x, 8.2), "三角形ABC = %d cm²" % total, null, 24),
	]}
	return {
		"q": "三角形 ABC の面積は %d cm² です。辺 BC を %d : %d : %d に分ける点 D・E をとるとき、真ん中の三角形 ADE の面積は何 cm² ですか。" % [total, p, q, r],
		"answer": float(q * k), "unit": "cm²",
		"hint1": "3 つの三角形は高さが同じ。面積の比は底辺の比 %d : %d : %d と同じだよ。" % [p, q, r],
		"hint2": "%d × %d ÷ (%d + %d + %d)" % [total, q, p, q, r],
		"expl": "ADE は全体の %d/%d。%d × %d/%d = %d cm² です。" % [q, p + q + r, total, q, p + q + r, q * k],
		"fig": fig,
	}


## e17-中心: 正多角形の中心角(360 ÷ n)
static func _e17_center(rng: RandomNumberGenerator) -> Dictionary:
	var opts := [5, 6, 8, 9, 10, 12, 15, 18]
	var n: int = opts[rng.randi_range(0, opts.size() - 1)]
	var x := 360 / n
	var pts: Array = []
	for t in n:
		var ang := TAU * t / n + PI / 2.0
		pts.append(Vector2(cos(ang), sin(ang)) * 5.0)
	var fig := {"shapes": [
		ProblemGen.poly(pts, ProblemGen.FILL_MAIN),
		ProblemGen.seg(Vector2.ZERO, pts[0], ProblemGen.COL_YELLOW, 3.5),
		ProblemGen.seg(Vector2.ZERO, pts[1], ProblemGen.COL_YELLOW, 3.5),
		ProblemGen.circle(Vector2.ZERO, 0.12, Color.WHITE),
		ProblemGen.label(Vector2(0.8, -0.6), "O"),
		ProblemGen.ang(Vector2.ZERO, pts[0], pts[1], "x"),
	]}
	return {
		"q": "正%d角形の中心 O と、となり合う 2 つの頂点を結びました。角 x は何度ですか。" % n,
		"answer": float(x), "unit": "度",
		"hint1": "中心のまわりの 360° が、頂点の数だけ等分されているよ。",
		"hint2": "360 ÷ %d" % n,
		"expl": "360 ÷ %d = %d° です。" % [n, x],
		"fig": fig,
	}
