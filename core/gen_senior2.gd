class_name GenSenior2
## 大学受験レベルの追加ステージ(s13 以降)。
## gen_senior.gd が数I(三角比)と数III(放物線の面積)を受け持つのに対して、
## こちらは入試で頻出なのに手薄だった範囲をまとめて受け持つ:
##   数A 図形の性質  … 五心・方べきの定理・チェバ/メネラウス・角の二等分線・中線定理
##   数II 図形と方程式 … 2 直線のなす角・点と直線の距離・円の方程式
##   空間図形        … 立方体/正四面体のなす角と体積
##   数III           … 回転体の体積・媒介変数と極座標の面積・曲線の長さ
## 無理数は √2 = 1.41 のように値を問題文に明記して小数で答えさせる(本編と同じ約束)。


## 角の二等分線がきれいな三角形 [AB(=c), AC(=b), BC(=a), BD, DC, AD]
## BD:DC = AB:AC。AD² = AB×AC − BD×DC がちょうど平方数になる組だけを載せている
const BISECT_SETS := [
	[8, 6, 7, 4, 3, 6], [16, 12, 14, 8, 6, 12], [15, 12, 18, 10, 8, 10],
	[18, 9, 21, 14, 7, 8], [21, 14, 25, 15, 10, 12], [22, 11, 21, 14, 7, 12],
	[24, 18, 21, 12, 9, 18], [20, 5, 20, 16, 4, 6], [5, 5, 6, 3, 3, 4],
	[13, 13, 10, 5, 5, 12], [17, 17, 16, 8, 8, 15], [15, 15, 18, 9, 9, 12],
]

## 中線定理がきれいな三角形 [AB, AC, BC, AM(中線)]
const MEDIAN_SETS := [
	[7, 9, 8, 7], [7, 9, 14, 4], [7, 11, 12, 7], [7, 11, 14, 6], [8, 14, 14, 9],
	[8, 14, 18, 7], [9, 13, 10, 10], [9, 13, 20, 5], [9, 17, 16, 11], [9, 17, 22, 8],
	[9, 19, 20, 11], [6, 8, 10, 5], [10, 20, 18, 13], [5, 5, 6, 4], [10, 10, 16, 6],
]

## 円の外の点 P からの割線 2 本 [d(中心までの距離), R, PC, PD]
## 軸上の割線は PA = d − R、PB = d + R。斜めの割線が PC・PD になる
const POWER_OUT := [
	[7, 5, 3, 8], [7, 5, 4, 6], [8, 6, 4, 7], [8, 7, 3, 5], [9, 7, 4, 8],
	[6, 4, 4, 5], [9, 6, 5, 9], [9, 5, 7, 8], [10, 4, 7, 12], [7, 3, 5, 8],
	[8, 4, 6, 8], [12, 8, 6, 10],
]

## 円の中で交わる 2 本の弦 [R, p(中心から交点までの距離), PC, PD]
const POWER_IN := [
	[7, 5, 3, 8], [7, 5, 4, 6], [8, 6, 4, 7], [8, 7, 3, 5], [9, 7, 4, 8],
	[6, 4, 4, 5], [9, 6, 5, 9], [9, 5, 7, 8], [10, 4, 7, 12], [12, 8, 6, 10],
]

## 接線の長さが整数になる組 [d, R, PT]
const TANGENT_SETS := [
	[5, 3, 4], [5, 4, 3], [10, 6, 8], [10, 8, 6], [13, 5, 12], [13, 12, 5],
	[15, 9, 12], [15, 12, 9], [17, 8, 15], [17, 15, 8], [20, 12, 16], [25, 7, 24],
]

## 直角三角形の 3 数(点と直線の距離・弦の長さで分母をきれいにするのに使う)
const PYTH := [[3, 4, 5], [4, 3, 5], [6, 8, 10], [8, 6, 10], [5, 12, 13], [12, 5, 13],
	[8, 15, 17], [15, 8, 17], [7, 24, 25], [20, 21, 29], [9, 12, 15], [12, 9, 15]]


static func gen(stage_id: String, rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var t := clampi(tier, 0, 9)
	match stage_id:
		"s13":
			# 内心の角 → 外心の角 → 垂心の角 → 重心の 2:1 → 内心の角の逆算
			match [0, 0, 1, 1, 2, 2, 3, 3, 4, 4][t]:
				0: return _s13(rng, 0)
				1: return _s13(rng, 1)
				2: return _s13(rng, 2)
				3: return _s13_median(rng)
				_: return _s13_rev(rng)
		"s14":
			# 2 直線のなす角 → tan の加法定理 → 有名角の差(15°) → 三角関数の合成
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _s14(rng, 0)
				1: return _s14(rng, 1)
				2: return _s14(rng, 2)
				_: return _s14_wave(rng)
		"s15":
			# 立方体の中のなす角 → 正四面体の辺 → 対角線と面の対角線
			match [0, 0, 0, 1, 1, 1, 2, 2, 2, 2][t]:
				0: return _s15(rng, 0)
				1: return _s15(rng, 1)
				_: return _s15(rng, 2)
		"s16":
			# 円の中の 2 弦 → 円の外の割線 2 本 → 接線と割線
			match [0, 0, 0, 1, 1, 1, 2, 2, 2, 2][t]:
				0: return _s16(rng, 0)
				1: return _s16(rng, 1)
				_: return _s16(rng, 2)
		"s17":
			# メネラウス(比) → チェバ(比) → メネラウスで長さ → 重心以外の交点比
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _s17(rng, 0)
				1: return _s17(rng, 1)
				2: return _s17(rng, 2)
				_: return _s17_mass(rng)
		"s18":
			# 二等分線と比 → 二等分線の長さ → 中線定理 → 中線から辺の逆算
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _s18(rng, 0)
				1: return _s18(rng, 1)
				2: return _s18(rng, 2)
				_: return _s18_rev(rng)
		"s19":
			# 点と直線の距離 → 平行 2 直線の距離 → 距離を使って三角形の面積
			match [0, 0, 0, 1, 1, 1, 2, 2, 2, 2][t]:
				0: return _s19(rng, 0)
				1: return _s19(rng, 1)
				_: return _s19(rng, 2)
		"s20":
			# 一般形から半径 → 弦の長さ → 接線の長さ → アポロニウスの円
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _s20(rng, 0)
				1: return _s20(rng, 1)
				2: return _s20(rng, 2)
				_: return _s20_apollo(rng)
		"s21":
			# 座標の四面体 → 立方体を切った三角錐 → 正四面体の高さと体積 → 外接球
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _s21(rng, 0)
				1: return _s21(rng, 1)
				2: return _s21(rng, 2)
				_: return _s21_ball(rng)
		_:
			# s22: 回転体 → 円錐と球 → 媒介変数・極座標の面積 → 曲線の長さ
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _s22(rng, 0)
				1: return _s22(rng, 1)
				2: return _s22(rng, 2)
				_: return _s22_length(rng)


# =========================================================
# 共通の小道具
# =========================================================

## 3 つの内角(度)から三角形の頂点 [A, B, C] を作る。B=(0,0)、C=(w,0)
static func _tri_by_angles(ang_b: float, ang_c: float, w := 10.0) -> Array:
	return ProblemGen.tri_from_angles(ang_b, ang_c, w)


## 内心(角の二等分線の交点)
static func _incenter(v: Array) -> Vector2:
	var a: float = (v[1] as Vector2).distance_to(v[2])
	var b: float = (v[2] as Vector2).distance_to(v[0])
	var c: float = (v[0] as Vector2).distance_to(v[1])
	return ((v[0] as Vector2) * a + (v[1] as Vector2) * b + (v[2] as Vector2) * c) / (a + b + c)


## 外心(垂直二等分線の交点)
static func _circumcenter(v: Array) -> Vector2:
	var a: Vector2 = v[0]
	var b: Vector2 = v[1]
	var c: Vector2 = v[2]
	var d := 2.0 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))
	var ux := (a.length_squared() * (b.y - c.y) + b.length_squared() * (c.y - a.y)
		+ c.length_squared() * (a.y - b.y)) / d
	var uy := (a.length_squared() * (c.x - b.x) + b.length_squared() * (a.x - c.x)
		+ c.length_squared() * (b.x - a.x)) / d
	return Vector2(ux, uy)


## 垂心(3 頂点と外心から出る)
static func _orthocenter(v: Array) -> Vector2:
	return (v[0] as Vector2) + (v[1] as Vector2) + (v[2] as Vector2) - _circumcenter(v) * 2.0


## 三角形の頂点に A・B・C の文字を置く
static func _abc_labels(v: Array) -> Array:
	return [
		ProblemGen.label((v[0] as Vector2) + Vector2(0, 0.9), "A"),
		ProblemGen.label((v[1] as Vector2) + Vector2(-0.8, -0.5), "B"),
		ProblemGen.label((v[2] as Vector2) + Vector2(0.8, -0.5), "C"),
	]


## 立体を斜めに投影して 2D の座標にする(向きは他の立体ステージと共通)
static func _proj(p: Vector3) -> Vector2:
	return ProblemGen.proj3(p)


## 分数の見た目("3/4" / 整数ならそのまま)
static func _frac(num: int, den: int) -> String:
	var g := _gcd(absi(num), absi(den))
	if g > 0:
		num /= g
		den /= g
	if den == 1:
		return str(num)
	return "%d/%d" % [num, den]


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := b
		b = a % b
		a = t
	return a


# =========================================================
# s13: 三角形の五心(内心・外心・垂心・重心)
# =========================================================

## 五心の図。center が中心、mark は ∠B?C につける文字
static func _center_fig(v: Array, center: Vector2, a_deg: int, mark: String,
		extra: Array = []) -> Dictionary:
	var shapes: Array = [ProblemGen.poly(v, ProblemGen.FILL_MAIN)]
	shapes += _abc_labels(v)
	shapes += extra
	shapes += [
		ProblemGen.seg(v[1], center, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.seg(v[2], center, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.ang(v[0], v[1], v[2], "%d°" % a_deg, 1.9),
		ProblemGen.ang(center, v[1], v[2], mark, 1.5),
	]
	return {"shapes": shapes}


static func _s13(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	var a_deg := rng.randi_range(10, 25) * 4      # 40°..100°(偶数なので答えも整数)
	if kind > 0:
		a_deg = rng.randi_range(10, 20) * 4       # 鋭角三角形にしたいので 40°..80°
	var rest := 180 - a_deg
	var b_deg := rng.randi_range(int(rest * 0.35), int(rest * 0.65))
	if kind > 0:
		b_deg = clampi(b_deg, rest - 85, 85)
	var c_deg := rest - b_deg
	var v := _tri_by_angles(float(b_deg), float(c_deg), 11.0)
	if kind == 0:
		var inc := _incenter(v)
		var r_in := _dist_to_line(inc, v[1], v[2])
		return {
			"q": "三角形 ABC の内心を I とします。∠A = %d° のとき ∠BIC は何度ですか。" % a_deg,
			"answer": 90.0 + a_deg * 0.5, "unit": "度",
			"hint1": "内心は角の二等分線の交点。∠IBC = B/2、∠ICB = C/2 だよ。",
			"hint2": "∠BIC = 180 − (B + C)/2 = 180 − (180 − %d)/2" % a_deg,
			"expl": "∠BIC = 90 + A/2 = 90 + %d = %d° です。どの三角形でもこの形になります。" % [
				a_deg / 2, int(90 + a_deg * 0.5)],
			"fig": _center_fig(v, inc, a_deg, "x", [
				ProblemGen.circle(inc, r_in, null, ProblemGen.COL_DIM, 2.0),
				ProblemGen.label(inc + Vector2(0.0, -1.0), "I", ProblemGen.COL_YELLOW),
			]),
		}
	if kind == 1:
		var o := _circumcenter(v)
		var r_out: float = o.distance_to(v[0])
		return {
			"q": "三角形 ABC の外心を O とします。∠A = %d° のとき ∠BOC は何度ですか。" % a_deg,
			"answer": float(a_deg * 2), "unit": "度",
			"hint1": "外心は外接円の中心。∠BOC は弧 BC に対する中心角だよ。",
			"hint2": "中心角は円周角の 2 倍。∠A が円周角にあたる。",
			"expl": "∠BOC = 2∠A = %d° です(中心角は円周角の 2 倍)。" % (a_deg * 2),
			"fig": _center_fig(v, o, a_deg, "x", [
				ProblemGen.circle(o, r_out, null, ProblemGen.COL_DIM, 2.0),
				ProblemGen.label(o + Vector2(0.0, -1.0), "O", ProblemGen.COL_YELLOW),
			]),
		}
	var h := _orthocenter(v)
	var foot_b := _foot(v[1], v[0], v[2])
	var foot_c := _foot(v[2], v[0], v[1])
	return {
		"q": "三角形 ABC の垂心を H とします。∠A = %d° のとき ∠BHC は何度ですか。" % a_deg,
		"answer": float(180 - a_deg), "unit": "度",
		"hint1": "垂心は 3 本の垂線の交点。四角形 AFHE の角の和 360° を使おう。",
		"hint2": "∠BHC = 360 − 90 − 90 − ∠A",
		"expl": "∠BHC = 180 − ∠A = %d° です。垂足を結んだ四角形の角の和から出ます。" % (180 - a_deg),
		"fig": _center_fig(v, h, a_deg, "x", [
			ProblemGen.seg(v[1], foot_b, ProblemGen.COL_DIM, 2.0, true),
			ProblemGen.seg(v[2], foot_c, ProblemGen.COL_DIM, 2.0, true),
			ProblemGen.right(foot_b, v[0], v[1]),
			ProblemGen.label(h + Vector2(0.0, -1.0), "H", ProblemGen.COL_YELLOW),
		]),
	}


## 点 p から直線 ab までの距離
static func _dist_to_line(p: Vector2, a: Vector2, b: Vector2) -> float:
	var d := b - a
	return absf(d.x * (a.y - p.y) - d.y * (a.x - p.x)) / d.length()


## 点 p から直線 ab に下ろした垂線の足
static func _foot(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var d := b - a
	return a + d * ((p - a).dot(d) / d.length_squared())


## s13-重心: 中線を 2:1 に内分する
static func _s13_median(rng: RandomNumberGenerator) -> Dictionary:
	var am := rng.randi_range(2, 8) * 3        # 3 の倍数なので AG も整数
	var ask_g := rng.randf() < 0.6
	# 中線の長さを図に書くので、AM が本当に am になる大きさで三角形を作る
	# (図に書いた数と実際の長さが食い違わないようにする)
	var base := _tri_by_angles(62.0, 54.0, 11.0)
	var base_am: float = (base[0] as Vector2).distance_to(
		((base[1] as Vector2) + (base[2] as Vector2)) * 0.5)
	var k := float(am) / base_am
	var v: Array = [(base[0] as Vector2) * k, (base[1] as Vector2) * k, (base[2] as Vector2) * k]
	var m: Vector2 = ((v[1] as Vector2) + (v[2] as Vector2)) * 0.5
	var g: Vector2 = ((v[0] as Vector2) + (v[1] as Vector2) + (v[2] as Vector2)) / 3.0
	var mb: Vector2 = ((v[2] as Vector2) + (v[0] as Vector2)) * 0.5
	# shapes += ... は新しい配列を作って入れ直すので、辞書は最後に作ること
	# (先に辞書へ入れると、あとから足した中線やラベルが図に出ない)
	var shapes: Array = [ProblemGen.poly(v, ProblemGen.FILL_MAIN)]
	shapes += _abc_labels(v)
	shapes += [
		ProblemGen.seg(v[0], m, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.seg(v[1], mb, ProblemGen.COL_DIM, 2.5),
		ProblemGen.tick(v[1], m, 1), ProblemGen.tick(m, v[2], 1),
		ProblemGen.label(g + Vector2(0.7, 0.2), "G", ProblemGen.COL_YELLOW),
		ProblemGen.label(m + Vector2(0.0, -0.9), "M"),
		ProblemGen.side_label(v[0], m, "%d" % am, -1.0),
	]
	var fig := {"shapes": shapes}
	if ask_g:
		return {
			"q": "三角形 ABC の重心を G、辺 BC の中点を M とします。中線 AM = %d のとき AG の長さは?" % am,
			"answer": am * 2.0 / 3.0, "unit": "",
			"hint1": "重心は中線を 頂点側から 2:1 に分けるよ。",
			"hint2": "AG = AM × 2/3 = %d × 2 ÷ 3" % am,
			"expl": "AG:GM = 2:1 なので AG = %d × 2/3 = %s です。" % [am, ProblemGen.fmt(am * 2.0 / 3.0)],
			"fig": fig,
		}
	return {
		"q": "三角形 ABC の重心を G、辺 BC の中点を M とします。中線 AM = %d のとき GM の長さは?" % am,
		"answer": am / 3.0, "unit": "",
		"hint1": "重心は中線を 頂点側から 2:1 に分けるよ。M 側が 1 の方。",
		"hint2": "GM = AM × 1/3 = %d ÷ 3" % am,
		"expl": "AG:GM = 2:1 なので GM = %d ÷ 3 = %s です。" % [am, ProblemGen.fmt(am / 3.0)],
		"fig": fig,
	}


## s13-逆算: ∠BIC から ∠A を出す
static func _s13_rev(rng: RandomNumberGenerator) -> Dictionary:
	var a_deg := rng.randi_range(10, 25) * 4
	var bic := 90 + a_deg / 2
	var rest := 180 - a_deg
	var b_deg := rng.randi_range(int(rest * 0.4), int(rest * 0.6))
	var v := _tri_by_angles(float(b_deg), float(rest - b_deg), 11.0)
	var inc := _incenter(v)
	var shapes: Array = [ProblemGen.poly(v, ProblemGen.FILL_MAIN)]
	shapes += _abc_labels(v)
	shapes += [
		ProblemGen.seg(v[1], inc, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.seg(v[2], inc, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.ang(v[0], v[1], v[2], "x", 1.9),
		ProblemGen.ang(inc, v[1], v[2], "%d°" % bic, 1.5),
		ProblemGen.label(inc + Vector2(0.0, -1.0), "I", ProblemGen.COL_YELLOW),
	]
	return {
		"q": "三角形 ABC の内心を I とします。∠BIC = %d° のとき ∠A は何度ですか。" % bic,
		"answer": float(a_deg), "unit": "度",
		"hint1": "∠BIC = 90 + A/2 だったね。これを A について解こう。",
		"hint2": "A = (%d − 90) × 2" % bic,
		"expl": "A = 2 × (%d − 90) = %d° です。" % [bic, a_deg],
		"fig": {"shapes": shapes},
	}


# =========================================================
# s14: 2 直線のなす角・加法定理・三角関数の合成
# =========================================================

## なす角が 45° か 90° になる傾きの組 [m1 の分子, 分母, m2 の分子, 分母, 答え]
const SLOPE_SETS := [
	[2, 1, 1, 3, 45], [3, 1, 1, 2, 45], [4, 1, 3, 5, 45], [5, 1, 2, 3, 45],
	[1, 1, 0, 1, 45], [1, 2, -1, 3, 45], [1, 3, -1, 2, 45], [2, 3, -1, 5, 45],
	[2, 1, -1, 2, 90], [3, 1, -1, 3, 90], [1, 1, -1, 1, 90], [5, 1, -1, 5, 90],
	[3, 2, -2, 3, 90], [4, 1, -1, 4, 90],
]

## tan の加法定理できれいな角になる組 [tanα の分子, 分母, tanβ の分子, 分母, α+β]
const TAN_SETS := [
	[1, 2, 1, 3, 45], [1, 4, 3, 5, 45], [2, 3, 1, 5, 45], [1, 7, 3, 4, 45],
	[1, 5, 2, 3, 45], [3, 5, 1, 4, 45], [1, 6, 5, 7, 45],
	[2, 1, 3, 1, 135], [3, 1, 2, 1, 135], [4, 1, 5, 3, 135], [5, 1, 3, 2, 135],
	[2, 1, 1, 2, 90], [3, 1, 1, 3, 90], [4, 1, 1, 4, 90], [5, 1, 1, 5, 90],
]

## 傾角がわかっている有名な直線 [傾角(度), 表示]
const FAMOUS_LINES := [
	[0, "x 軸"], [30, "y = x/√3"], [45, "y = x"], [60, "y = √3 x"],
	[90, "y 軸"], [120, "y = −√3 x"], [135, "y = −x"], [150, "y = −x/√3"],
]


## 傾き m = num/den の直線の表示("y = 2x" "y = x/3" "y = −x/2" など)
static func _line_text(num: int, den: int) -> String:
	if num == 0:
		return "y = 0(x 軸)"
	var sign_s := "−" if num < 0 else ""
	var n := absi(num)
	if den == 1:
		return "y = %s%sx" % [sign_s, "" if n == 1 else str(n)]
	return "y = %s%sx/%d" % [sign_s, "" if n == 1 else str(n), den]


## 原点を通る傾き m の直線を、はみ出さない長さの線分にする
static func _line_seg(m: float, half: float, color) -> Dictionary:
	var x := half
	if absf(m) > 1.0:
		x = half / absf(m)
	return ProblemGen.seg(Vector2(-x, -x * m), Vector2(x, x * m), color, 3.0)


static func _s14(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		var s: Array = SLOPE_SETS[rng.randi_range(0, SLOPE_SETS.size() - 1)]
		var m1 := float(s[0]) / float(s[1])
		var m2 := float(s[2]) / float(s[3])
		var ans: int = s[4]
		var lo := Vector2(-6, -6)
		var hi := Vector2(6, 6)
		var d1 := Vector2(1, m1).normalized() * 4.0
		var d2 := Vector2(1, m2).normalized() * 4.0
		var fig := {"shapes": [
			ProblemGen.grid(lo, hi), ProblemGen.axes(lo, hi),
			_line_seg(m1, 5.5, ProblemGen.COL_YELLOW),
			_line_seg(m2, 5.5, Color(0.55, 0.85, 1.0)),
			ProblemGen.ang(Vector2.ZERO, d1, d2, "θ", 1.6),
			ProblemGen.label(d1 * 1.35, _line_text(s[0], s[1]), ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(d2 * 1.35 + Vector2(0, -0.7), _line_text(s[2], s[3]),
				Color(0.55, 0.85, 1.0), 26),
		]}
		if ans == 90:
			return {
				"q": "2 直線 %s と %s のなす角 θ を求めなさい。" % [
					_line_text(s[0], s[1]), _line_text(s[2], s[3])],
				"answer": 90.0, "unit": "度",
				"hint1": "まず 2 つの傾きをかけてみよう。−1 になったら特別な関係だよ。",
				"hint2": "傾きの積 = (%s) × (%s) = −1" % [_frac(s[0], s[1]), _frac(s[2], s[3])],
				"expl": "傾きの積が −1 なので 2 直線は垂直。θ = 90° です。",
				"fig": fig,
			}
		return {
			"q": "2 直線 %s と %s のなす角 θ を求めなさい。" % [
				_line_text(s[0], s[1]), _line_text(s[2], s[3])],
			"answer": float(ans), "unit": "度",
			"hint1": "なす角の公式 tanθ = |(m1 − m2) ÷ (1 + m1 m2)| を使おう。",
			"hint2": "m1 = %s、m2 = %s を入れると tanθ = 1 になるよ。" % [
				_frac(s[0], s[1]), _frac(s[2], s[3])],
			"expl": "tanθ = 1 なので θ = 45° です。",
			"fig": fig,
		}
	if kind == 1:
		var s2: Array = TAN_SETS[rng.randi_range(0, TAN_SETS.size() - 1)]
		var p := float(s2[0]) / float(s2[1])
		var q := float(s2[2]) / float(s2[3])
		var ans2: int = s2[4]
		var t1: Array = [Vector2(-7.5, 0), Vector2(-4.0, 0), Vector2(-4.0, 3.5 * p)]
		var t2: Array = [Vector2(1.0, 0), Vector2(4.5, 0), Vector2(4.5, 3.5 * q)]
		var fig2 := {"shapes": [
			ProblemGen.poly(t1, ProblemGen.FILL_MAIN),
			ProblemGen.poly(t2, ProblemGen.FILL_SUB),
			ProblemGen.right(t1[1], t1[0], t1[2]), ProblemGen.right(t2[1], t2[0], t2[2]),
			ProblemGen.ang(t1[0], t1[1], t1[2], "α", 1.3),
			ProblemGen.ang(t2[0], t2[1], t2[2], "β", 1.3),
			ProblemGen.label(Vector2(-5.9, -1.1), "tanα = " + _frac(s2[0], s2[1]),
				ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(Vector2(2.6, -1.1), "tanβ = " + _frac(s2[2], s2[3]),
				ProblemGen.COL_YELLOW, 26),
		]}
		if ans2 == 90:
			return {
				"q": "α、β は鋭角で tanα = %s、tanβ = %s です。α + β は何度ですか。" % [
					_frac(s2[0], s2[1]), _frac(s2[2], s2[3])],
				"answer": 90.0, "unit": "度",
				"hint1": "tanα × tanβ を計算してみよう。1 になったら足して 90° だよ。",
				"hint2": "tanβ = 1 ÷ tanα のとき β = 90° − α になる。",
				"expl": "tanα tanβ = 1 なので β = 90° − α。α + β = 90° です。",
				"fig": fig2,
			}
		return {
			"q": "α、β は鋭角で tanα = %s、tanβ = %s です。α + β は何度ですか。" % [
				_frac(s2[0], s2[1]), _frac(s2[2], s2[3])],
			"answer": float(ans2), "unit": "度",
			"hint1": "加法定理 tan(α+β) = (tanα + tanβ) ÷ (1 − tanα tanβ)。",
			"hint2": "分子 = %s + %s、分母 = 1 − %s" % [
				_frac(s2[0], s2[1]), _frac(s2[2], s2[3]), _frac(s2[0] * s2[2], s2[1] * s2[3])],
			"expl": "tan(α+β) = %s なので α + β = %d° です(α、β が鋭角なので 0° < α+β < 180°)。" % [
				"1" if ans2 == 45 else "−1", ans2],
			"fig": fig2,
		}
	var i1 := rng.randi_range(0, FAMOUS_LINES.size() - 1)
	var i2 := rng.randi_range(0, FAMOUS_LINES.size() - 1)
	while i2 == i1:
		i2 = rng.randi_range(0, FAMOUS_LINES.size() - 1)
	var a1: int = FAMOUS_LINES[i1][0]
	var a2: int = FAMOUS_LINES[i2][0]
	var diff := absi(a1 - a2)
	var ans3 := mini(diff, 180 - diff)
	var u1 := Vector2(cos(deg_to_rad(float(a1))), sin(deg_to_rad(float(a1))))
	var u2 := Vector2(cos(deg_to_rad(float(a2))), sin(deg_to_rad(float(a2))))
	var lo3 := Vector2(-6, -6)
	var hi3 := Vector2(6, 6)
	var fig3 := {"shapes": [
		ProblemGen.grid(lo3, hi3), ProblemGen.axes(lo3, hi3),
		ProblemGen.seg(-u1 * 5.0, u1 * 5.0, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.seg(-u2 * 5.0, u2 * 5.0, Color(0.55, 0.85, 1.0), 3.0),
		ProblemGen.ang(Vector2.ZERO, u1 * 4.0, u2 * 4.0, "θ", 1.7),
		ProblemGen.label(u1 * 5.8, "%d°" % a1, ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(u2 * 5.8 + Vector2(0, -0.7), "%d°" % a2, Color(0.55, 0.85, 1.0), 26),
	]}
	return {
		"q": "2 直線 %s と %s のなす角 θ を求めなさい。" % [
			String(FAMOUS_LINES[i1][1]), String(FAMOUS_LINES[i2][1])],
		"answer": float(ans3), "unit": "度",
		"hint1": "それぞれが x 軸となす角(傾角)を思い出そう。傾き 1 なら 45°、√3 なら 60°。",
		"hint2": "傾角は %d° と %d°。その差を考えて、90° を超えたら 180° から引く。" % [a1, a2],
		"expl": "傾角の差は %d°。なす角は 90° 以下で答えるので θ = %d° です。" % [diff, ans3],
		"fig": fig3,
	}


## s14-合成: a sinθ + b cosθ = R sin(θ + φ)
static func _s14_wave(rng: RandomNumberGenerator) -> Dictionary:
	if rng.randf() < 0.5:
		var sets: Array = [
			[1.0, 1.7320508, "sinθ + √3 cosθ", 60, "2", "√3"],
			[1.7320508, 1.0, "√3 sinθ + cosθ", 30, "2", "1/√3"],
			[1.0, 1.0, "sinθ + cosθ", 45, "√2", "1"],
		]
		var s: Array = sets[rng.randi_range(0, sets.size() - 1)]
		var a: float = s[0]
		var b: float = s[1]
		var phi: int = s[3]
		var lo := Vector2(-1, -1)
		var hi := Vector2(3, 3)
		var fig := {"shapes": [
			ProblemGen.grid(lo, hi), ProblemGen.axes(lo, hi),
			ProblemGen.arc(Vector2.ZERO, sqrt(a * a + b * b), 0.0, float(phi),
				ProblemGen.COL_DIM, 2.0),
			ProblemGen.arrow(Vector2.ZERO, Vector2(a, b), ProblemGen.COL_YELLOW),
			ProblemGen.ang(Vector2.ZERO, Vector2(2, 0), Vector2(a, b), "%d°" % phi, 0.9),
			ProblemGen.label(Vector2(a, b) + Vector2(0.5, 0.5), "(a, b)", ProblemGen.COL_YELLOW, 26),
		]}
		return {
			"q": "%s を R sin(θ + φ) の形に直します。0° < φ < 90° のとき φ は何度ですか。" % String(s[2]),
			"answer": float(phi), "unit": "度",
			"hint1": "点 (a, b) を取ると、φ はその点と x 軸のなす角。tanφ = b ÷ a だよ。",
			"hint2": "tanφ = %s なので、有名角のどれかになる。" % String(s[5]),
			"expl": "R = %s、tanφ = b/a より φ = %d° です。" % [String(s[4]), phi],
			"fig": fig,
		}
	var tri: Array = PYTH[rng.randi_range(0, PYTH.size() - 1)]
	var a2: int = tri[0]
	var b2: int = tri[1]
	var r: int = tri[2]
	var lo2 := Vector2(-1, -1)
	var hi2 := Vector2(a2 + 2, b2 + 2)
	var fig2 := {"shapes": [
		ProblemGen.grid(lo2, hi2), ProblemGen.axes(lo2, hi2),
		ProblemGen.arrow(Vector2.ZERO, Vector2(a2, b2), ProblemGen.COL_YELLOW),
		ProblemGen.seg(Vector2(a2, b2), Vector2(a2, 0), ProblemGen.COL_DIM, 2.0, true),
		ProblemGen.right(Vector2(a2, 0), Vector2.ZERO, Vector2(a2, b2)),
		ProblemGen.label(Vector2(a2, b2) + Vector2(0.6, 0.6), "(%d, %d)" % [a2, b2],
			ProblemGen.COL_YELLOW, 26),
	]}
	return {
		"q": "%d sinθ + %d cosθ の最大値を求めなさい。" % [a2, b2],
		"answer": float(r), "unit": "",
		"hint1": "合成すると R sin(θ + φ)。sin の最大は 1 なので、最大値は R そのもの。",
		"hint2": "R = √(a² + b²) = √(%d + %d)" % [a2 * a2, b2 * b2],
		"expl": "R = √(%d² + %d²) = √%d = %d。最大値は %d です。" % [
			a2, b2, a2 * a2 + b2 * b2, r, r],
		"fig": fig2,
	}


# =========================================================
# s15: 空間のなす角(立方体・正四面体)
# =========================================================

## 立方体の頂点。A から D が下の面、E から H が上の面(A の真上が E)
const CUBE_V := {
	"A": Vector3(0, 0, 0), "B": Vector3(1, 0, 0), "C": Vector3(1, 1, 0), "D": Vector3(0, 1, 0),
	"E": Vector3(0, 0, 1), "F": Vector3(1, 0, 1), "G": Vector3(1, 1, 1), "H": Vector3(0, 1, 1),
}

## なす角がきれいな線分の組 [線分1, 線分2, 答え(度)]
const CUBE_PAIRS := [
	["AF", "CH", 90], ["AF", "BG", 60], ["AC", "BD", 90], ["AC", "AF", 60],
	["AC", "FH", 90], ["AG", "BD", 90], ["AF", "CF", 60], ["BD", "EG", 90],
	["AH", "CF", 90], ["AH", "BD", 60], ["AC", "AH", 60], ["CE", "BD", 90],
]

## 立方体の 12 本の辺(頂点名のペア)
const CUBE_EDGES := ["AB", "BC", "CD", "DA", "EF", "FG", "GH", "HE", "AE", "BF", "CG", "DH"]

## 立方体を斜めから見た図。hi1 と hi2 の線分を色でめだたせる
static func _cube_fig(a: float, hi1: String, hi2: String) -> Dictionary:
	var shapes: Array = []
	for e in CUBE_EDGES:
		var en := String(e)
		var p: Vector3 = CUBE_V[en[0]] * a
		var q: Vector3 = CUBE_V[en[1]] * a
		# 奥に隠れる頂点 D につながる辺は点線にする
		var hidden := en.contains("D")
		shapes.append(ProblemGen.seg(_proj(p), _proj(q),
			ProblemGen.COL_DIM if hidden else Color(0.92, 0.95, 1.0), 2.5, hidden))
	for vn in CUBE_V:
		var pv: Vector3 = CUBE_V[vn] * a
		var off := Vector2(-0.8, -0.8) if pv.x < a * 0.5 else Vector2(0.8, -0.5)
		if pv.z > a * 0.5:
			off.y = 0.9
		shapes.append(ProblemGen.label(_proj(pv) + off, vn, ProblemGen.COL_DIM, 26))
	shapes.append(ProblemGen.seg(_proj(CUBE_V[hi1[0]] * a), _proj(CUBE_V[hi1[1]] * a),
		ProblemGen.COL_YELLOW, 4.5))
	shapes.append(ProblemGen.seg(_proj(CUBE_V[hi2[0]] * a), _proj(CUBE_V[hi2[1]] * a),
		Color(0.55, 0.85, 1.0), 4.5))
	return {"shapes": shapes}


static func _s15(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	var a := float(rng.randi_range(4, 7))
	if kind == 0:
		var s: Array = CUBE_PAIRS[rng.randi_range(0, CUBE_PAIRS.size() - 1)]
		var n1 := String(s[0])
		var n2 := String(s[1])
		var ans: int = s[2]
		var v1: Vector3 = CUBE_V[n1[1]] - CUBE_V[n1[0]]
		var v2: Vector3 = CUBE_V[n2[1]] - CUBE_V[n2[0]]
		var dot := v1.dot(v2)
		var expl := "内積が 0 なので 2 直線は垂直。なす角は 90° です。"
		if ans != 90:
			expl = "内積 %s、長さは両方 √2 倍。cos = 1/2 なので 60° です。" % ProblemGen.fmt(dot)
		return {
			"q": "1 辺 %s の立方体 ABCD-EFGH で、線分 %s と 線分 %s のなす角を求めなさい。" % [
				ProblemGen.fmt(a), n1, n2],
			"answer": float(ans), "unit": "度",
			"hint1": "A を原点にして各頂点に座標をつけよう。なす角は内積で出る。",
			"hint2": "cosθ = (内積) ÷ (長さ × 長さ)。内積は %s になるよ。" % ProblemGen.fmt(dot),
			"expl": expl,
			"fig": _cube_fig(a, n1, n2),
		}
	if kind == 1:
		# 立方体の A・C・F・H は正四面体になる(定番の見方)
		var opposite := rng.randf() < 0.5
		var e1 := "AC"
		var e2 := "FH" if opposite else "AF"
		var ans2 := 90 if opposite else 60
		var hint2 := "正四面体の面は正三角形。隣り合う 2 辺の間の角がそのまま答え。"
		if opposite:
			hint2 = "向かい合う辺どうしは内積が 0 になる。"
		return {
			"q": "1 辺 %s の正四面体で、%s 2 辺のなす角を求めなさい。" % [
				ProblemGen.fmt(a * 1.41), "向かい合う" if opposite else "隣り合う"],
			"answer": float(ans2), "unit": "度",
			"hint1": "正四面体は立方体の 4 頂点(A・C・F・H)を結んだ形。座標で考えよう。",
			"hint2": hint2,
			"expl": "%s なので、なす角は %d° です。" % [
				"向かい合う辺は垂直" if opposite else "面が正三角形", ans2],
			"fig": _cube_fig(a, e1, e2),
		}
	# kind 2: 切り口の角(正三角形 ACF と、中点を通る正六角形)
	if rng.randf() < 0.5:
		return {
			"q": "1 辺 %s の立方体 ABCD-EFGH を、3 点 A・C・F を通る平面で切ります。切り口の三角形の 1 つの角は何度ですか。" % ProblemGen.fmt(a),
			"answer": 60.0, "unit": "度",
			"hint1": "AC・CF・FA はどれも面の対角線。長さを比べてみよう。",
			"hint2": "3 辺とも同じ長さ = 正三角形。",
			"expl": "AC = CF = FA(面の対角線)なので切り口は正三角形。角は 60° です。",
			"fig": _cube_fig(a, "AC", "AF"),
		}
	return {
		"q": "1 辺 %s の立方体を、6 本の辺の中点を通る平面で切ると切り口は正六角形になります。その 1 つの内角は何度ですか。" % ProblemGen.fmt(a),
		"answer": 120.0, "unit": "度",
		"hint1": "正六角形の内角の和は (6 − 2) × 180°。",
		"hint2": "720 ÷ 6 を計算しよう。",
		"expl": "正六角形の内角の和は 720°。1 つの角は 720 ÷ 6 = 120° です。",
		"fig": _hexcut_fig(a),
	}


## 立方体を中点で切った正六角形の断面
static func _hexcut_fig(a: float) -> Dictionary:
	var shapes: Array = []
	for e in CUBE_EDGES:
		var en := String(e)
		var p: Vector3 = CUBE_V[en[0]] * a
		var q: Vector3 = CUBE_V[en[1]] * a
		var hidden := en.contains("D")
		shapes.append(ProblemGen.seg(_proj(p), _proj(q),
			ProblemGen.COL_DIM if hidden else Color(0.92, 0.95, 1.0), 2.5, hidden))
	var hex3: Array = [
		Vector3(1, 0.5, 0), Vector3(1, 0, 0.5), Vector3(0.5, 0, 1),
		Vector3(0, 0.5, 1), Vector3(0, 1, 0.5), Vector3(0.5, 1, 0),
	]
	var pts: Array = []
	for h in hex3:
		pts.append(_proj((h as Vector3) * a))
	shapes.append(ProblemGen.poly(pts, ProblemGen.FILL_ACCENT, ProblemGen.COL_YELLOW, 3.5))
	return {"shapes": shapes}


# =========================================================
# s16: 方べきの定理
# =========================================================

## 長さの目印(線分の中ほどに数字を置く)
static func _len_label(a: Vector2, b: Vector2, s: String, side := 1.0) -> Dictionary:
	return ProblemGen.side_label(a, b, s, side, 0.75)


static func _s16(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		# 円の中で 2 本の弦が交わる: PA・PB = PC・PD
		var s: Array = POWER_IN[rng.randi_range(0, POWER_IN.size() - 1)]
		var r: int = s[0]
		var p: int = s[1]
		var pc: int = s[2]
		var pd: int = s[3]
		var pa := r - p
		var pb := r + p
		var pp := Vector2(-p, 0)
		var cosf := float(pd - pc) / float(2 * p)
		var u := Vector2(cosf, sqrt(maxf(0.0, 1.0 - cosf * cosf)))
		var cpt := pp - u * float(pc)
		var dpt := pp + u * float(pd)
		var fig := {"shapes": [
			ProblemGen.circle(Vector2.ZERO, float(r), null, Color(0.92, 0.95, 1.0), 3.0),
			ProblemGen.seg(Vector2(-r, 0), Vector2(r, 0), ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.seg(cpt, dpt, Color(0.55, 0.85, 1.0), 3.0),
			ProblemGen.label(pp + Vector2(0.1, -0.9), "P", ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(Vector2(-r, 0) + Vector2(-0.8, 0.2), "A", ProblemGen.COL_DIM, 26),
			ProblemGen.label(Vector2(r, 0) + Vector2(0.8, 0.2), "B", ProblemGen.COL_DIM, 26),
			ProblemGen.label(cpt + Vector2(-0.9, -0.3), "C", ProblemGen.COL_DIM, 26),
			ProblemGen.label(dpt + Vector2(0.7, 0.5), "D", ProblemGen.COL_DIM, 26),
			_len_label(pp, Vector2(-r, 0), str(pa), 1.0),
			_len_label(pp, Vector2(r, 0), str(pb), 1.0),
			_len_label(pp, cpt, str(pc), -1.0),
		]}
		return {
			"q": "円の 2 本の弦 AB と CD が円の中の点 P で交わっています。PA = %d、PB = %d、PC = %d のとき PD の長さを求めなさい。" % [pa, pb, pc],
			"answer": float(pd), "unit": "",
			"hint1": "方べきの定理: 交わる 2 本の弦では PA × PB = PC × PD が成り立つよ。",
			"hint2": "PD = (%d × %d) ÷ %d" % [pa, pb, pc],
			"expl": "PA×PB = %d なので PD = %d ÷ %d = %d です。" % [pa * pb, pa * pb, pc, pd],
			"fig": fig,
		}
	if kind == 1:
		# 円の外の点から割線 2 本: PA・PB = PC・PD
		var s2: Array = POWER_OUT[rng.randi_range(0, POWER_OUT.size() - 1)]
		var d: int = s2[0]
		var r2: int = s2[1]
		var pc2: int = s2[2]
		var pd2: int = s2[3]
		var pa2 := d - r2
		var pb2 := d + r2
		var pp2 := Vector2(-d, 0)
		var cosf2 := float(pc2 + pd2) / float(2 * d)
		var u2 := Vector2(cosf2, sqrt(maxf(0.0, 1.0 - cosf2 * cosf2)))
		var cpt2 := pp2 + u2 * float(pc2)
		var dpt2 := pp2 + u2 * float(pd2)
		var fig2 := {"shapes": [
			ProblemGen.circle(Vector2.ZERO, float(r2), null, Color(0.92, 0.95, 1.0), 3.0),
			ProblemGen.seg(pp2, Vector2(r2, 0), ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.seg(pp2, dpt2, Color(0.55, 0.85, 1.0), 3.0),
			ProblemGen.label(pp2 + Vector2(-0.9, 0.0), "P", ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(Vector2(-r2, 0) + Vector2(-0.3, -1.0), "A", ProblemGen.COL_DIM, 26),
			ProblemGen.label(Vector2(r2, 0) + Vector2(0.8, 0.2), "B", ProblemGen.COL_DIM, 26),
			ProblemGen.label(cpt2 + Vector2(-0.2, 0.9), "C", ProblemGen.COL_DIM, 26),
			ProblemGen.label(dpt2 + Vector2(0.7, 0.5), "D", ProblemGen.COL_DIM, 26),
			_len_label(pp2, Vector2(-r2, 0), str(pa2), -1.0),
			_len_label(pp2, Vector2(r2, 0), str(pb2), 1.0),
			_len_label(pp2, cpt2, str(pc2), -1.0),
		]}
		return {
			"q": "円の外の点 P から 2 本の直線を引き、円と A・B、C・D で交わりました。PA = %d、PB = %d、PC = %d のとき PD の長さを求めなさい。" % [pa2, pb2, pc2],
			"answer": float(pd2), "unit": "",
			"hint1": "外から引いた 2 本でも PA × PB = PC × PD。近い方 × 遠い方でそろえるのがコツ。",
			"hint2": "PD = (%d × %d) ÷ %d" % [pa2, pb2, pc2],
			"expl": "PA×PB = %d。PD = %d ÷ %d = %d です。" % [pa2 * pb2, pa2 * pb2, pc2, pd2],
			"fig": fig2,
		}
	# kind 2: 接線と割線 PT² = PA・PB
	var s3: Array = TANGENT_SETS[rng.randi_range(0, TANGENT_SETS.size() - 1)]
	var d3: int = s3[0]
	var r3: int = s3[1]
	var pt: int = s3[2]
	var pa3 := d3 - r3
	var pb3 := d3 + r3
	var pp3 := Vector2(-d3, 0)
	var tx := -float(r3 * r3) / float(d3)
	var ty := sqrt(maxf(0.0, float(r3 * r3) - tx * tx))
	var tpt := Vector2(tx, ty)
	var ask_pt := rng.randf() < 0.6
	var fig3 := {"shapes": [
		ProblemGen.circle(Vector2.ZERO, float(r3), null, Color(0.92, 0.95, 1.0), 3.0),
		ProblemGen.seg(pp3, Vector2(r3, 0), ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.seg(pp3, tpt, Color(0.55, 0.85, 1.0), 3.0),
		ProblemGen.seg(Vector2.ZERO, tpt, ProblemGen.COL_DIM, 2.0, true),
		ProblemGen.right(tpt, Vector2.ZERO, pp3),
		ProblemGen.label(pp3 + Vector2(-0.9, 0.0), "P", ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(Vector2(-r3, 0) + Vector2(-0.2, -1.0), "A", ProblemGen.COL_DIM, 26),
		ProblemGen.label(Vector2(r3, 0) + Vector2(0.8, 0.2), "B", ProblemGen.COL_DIM, 26),
		ProblemGen.label(tpt + Vector2(0.2, 0.9), "T", ProblemGen.COL_DIM, 26),
		_len_label(pp3, Vector2(-r3, 0), str(pa3), -1.0),
		_len_label(pp3, Vector2(r3, 0), str(pb3), 1.0),
		_len_label(pp3, tpt, "x" if ask_pt else str(pt), -1.0),
	]}
	if ask_pt:
		return {
			"q": "円の外の点 P から接線 PT と割線 PAB を引きました。PA = %d、PB = %d のとき、接線の長さ PT を求めなさい。" % [pa3, pb3],
			"answer": float(pt), "unit": "",
			"hint1": "接線のときは PT × PT = PA × PB(接線は 2 つの交点が重なったもの)。",
			"hint2": "PT = √(%d × %d) = √%d" % [pa3, pb3, pa3 * pb3],
			"expl": "PT² = %d × %d = %d なので PT = %d です。" % [pa3, pb3, pa3 * pb3, pt],
			"fig": fig3,
		}
	return {
		"q": "円の外の点 P から接線 PT と割線 PAB を引きました。PT = %d、PA = %d のとき PB の長さを求めなさい。" % [pt, pa3],
		"answer": float(pb3), "unit": "",
		"hint1": "PT² = PA × PB。PB について解こう。",
		"hint2": "PB = %d ÷ %d" % [pt * pt, pa3],
		"expl": "PT² = %d なので PB = %d ÷ %d = %d です。" % [pt * pt, pt * pt, pa3, pb3],
		"fig": fig3,
	}


# =========================================================
# s17: メネラウスの定理・チェバの定理
# =========================================================

## メネラウス [AF:FB の f1, f2, CE:EA の e1, e2, BC の長さ]
const MENELAUS_SETS := [
	[1, 2, 1, 1, 6], [1, 3, 1, 1, 6], [1, 2, 1, 2, 6], [2, 3, 2, 4, 6],
	[2, 3, 3, 4, 8], [1, 4, 1, 1, 9], [2, 5, 1, 1, 9], [3, 4, 2, 3, 10],
	[1, 3, 1, 1, 12], [1, 2, 1, 1, 10],
]

## チェバ [BD:DC の d1, d2, CE:EA の e1, e2, AB の長さ]
const CEVA_SETS := [
	[1, 2, 1, 2, 10], [2, 3, 1, 1, 10], [1, 1, 2, 3, 10], [2, 1, 3, 2, 8],
	[3, 2, 2, 1, 8], [1, 3, 2, 1, 10], [3, 1, 1, 2, 10], [1, 2, 2, 3, 12],
]

## 2 本のチェバ線の交点比 [AF:FB の f1, f2, BD:DC の d1, d2]
const MASS_SETS := [
	[2, 1, 1, 2], [1, 1, 1, 1], [1, 2, 1, 1], [3, 1, 1, 2], [1, 1, 1, 2],
	[2, 1, 2, 1], [1, 2, 2, 1], [3, 2, 1, 1], [1, 1, 2, 1], [2, 1, 1, 1],
]


## 三角形 ABC の頂点。B=(0,0)、C=(w,0)、A は左寄りの上
static func _tri_bc(w: float) -> Array:
	return [Vector2(w * 0.34, w * 0.85), Vector2.ZERO, Vector2(w, 0)]


## 2 直線 p1p2 と p3p4 の交点
static func _cross_pt(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2) -> Vector2:
	var d1 := p2 - p1
	var d2 := p4 - p3
	var den := d1.x * d2.y - d1.y * d2.x
	if absf(den) < 0.000001:
		return p1
	var t := ((p3.x - p1.x) * d2.y - (p3.y - p1.y) * d2.x) / den
	return p1 + d1 * t


static func _s17(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0 or kind == 2:
		var s: Array = MENELAUS_SETS[rng.randi_range(0, MENELAUS_SETS.size() - 1)]
		var f1: int = s[0]
		var f2: int = s[1]
		var e1: int = s[2]
		var e2: int = s[3]
		var bc: int = s[4]
		var v := _tri_bc(float(bc))
		var a: Vector2 = v[0]
		var b: Vector2 = v[1]
		var c: Vector2 = v[2]
		var f := a + (b - a) * (float(f1) / float(f1 + f2))
		var e := c + (a - c) * (float(e1) / float(e1 + e2))
		var pp := _cross_pt(f, e, b, c)
		var bp := pp.distance_to(b)
		var pc := pp.distance_to(c)
		var fig := {"shapes": [
			ProblemGen.poly(v, ProblemGen.FILL_MAIN),
			ProblemGen.seg(b, pp, ProblemGen.COL_DIM, 2.5, true),
			ProblemGen.seg(f, pp, Color(0.55, 0.85, 1.0), 3.0),
			ProblemGen.label(a + Vector2(0, 0.9), "A"),
			ProblemGen.label(b + Vector2(-0.8, -0.5), "B"),
			ProblemGen.label(c + Vector2(0.2, -0.9), "C"),
			ProblemGen.label(f + Vector2(-0.9, 0.0), "F", ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(e + Vector2(0.6, 0.5), "E", ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(pp + Vector2(0.4, -0.8), "P", ProblemGen.COL_YELLOW, 26),
			_len_label(b, c, "%d" % bc, -1.0),
		]}
		if kind == 0:
			return {
				"q": "三角形 ABC で、辺 AB 上に AF:FB = %d:%d となる点 F、辺 CA 上に CE:EA = %d:%d となる点 E をとります。直線 FE と直線 BC の交点を P とするとき、BP の長さを求めなさい。BC = %d です。" % [f1, f2, e1, e2, bc],
				"answer": bp, "unit": "",
				"hint1": "メネラウスの定理: (AF/FB) × (BP/PC) × (CE/EA) = 1。三角形を一周するようにかけ算する。",
				"hint2": "BP/PC = (FB/AF) × (EA/CE) = (%d/%d) × (%d/%d)" % [f2, f1, e2, e1],
				"expl": "BP:PC = %s:1 で、その差が BC = %d。BP = %s です。" % [
					ProblemGen.fmt(bp / pc), bc, ProblemGen.fmt(bp)],
				"fig": fig,
			}
		return {
			"q": "三角形 ABC で、辺 AB 上に AF:FB = %d:%d となる点 F、辺 CA 上に CE:EA = %d:%d となる点 E をとります。直線 FE と直線 BC の交点を P とするとき、PC の長さを求めなさい。BC = %d です。" % [f1, f2, e1, e2, bc],
			"answer": pc, "unit": "",
			"hint1": "メネラウスの定理で BP:PC を出してから、BP − PC = BC を使おう。",
			"hint2": "BP/PC = (%d/%d) × (%d/%d)。PC = BC ÷ (その値 − 1)" % [f2, f1, e2, e1],
			"expl": "BP:PC = %s:1 なので PC = %d ÷ %s = %s です。" % [
				ProblemGen.fmt(bp / pc), bc, ProblemGen.fmt(bp / pc - 1.0), ProblemGen.fmt(pc)],
			"fig": fig,
		}
	# kind 1: チェバの定理
	var s2: Array = CEVA_SETS[rng.randi_range(0, CEVA_SETS.size() - 1)]
	var d1: int = s2[0]
	var d2: int = s2[1]
	var e1b: int = s2[2]
	var e2b: int = s2[3]
	var ab: int = s2[4]
	var ratio := (float(d2) / float(d1)) * (float(e2b) / float(e1b))
	var af := float(ab) * ratio / (ratio + 1.0)
	var w := 10.0
	var v2 := _tri_bc(w)
	var a2: Vector2 = v2[0]
	var b2: Vector2 = v2[1]
	var c2: Vector2 = v2[2]
	var dpt := b2 + (c2 - b2) * (float(d1) / float(d1 + d2))
	var ept := c2 + (a2 - c2) * (float(e1b) / float(e1b + e2b))
	var fpt := a2 + (b2 - a2) * (1.0 / (ratio + 1.0))
	var opt := _cross_pt(a2, dpt, c2, fpt)
	var fig2 := {"shapes": [
		ProblemGen.poly(v2, ProblemGen.FILL_MAIN),
		ProblemGen.seg(a2, dpt, ProblemGen.COL_DIM, 2.5),
		ProblemGen.seg(b2, ept, ProblemGen.COL_DIM, 2.5),
		ProblemGen.seg(c2, fpt, Color(0.55, 0.85, 1.0), 3.0),
		ProblemGen.label(a2 + Vector2(0, 0.9), "A"),
		ProblemGen.label(b2 + Vector2(-0.8, -0.5), "B"),
		ProblemGen.label(c2 + Vector2(0.8, -0.5), "C"),
		ProblemGen.label(dpt + Vector2(0, -0.9), "D", ProblemGen.COL_DIM, 26),
		ProblemGen.label(ept + Vector2(0.7, 0.3), "E", ProblemGen.COL_DIM, 26),
		ProblemGen.label(fpt + Vector2(-0.9, 0.0), "F", ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(opt + Vector2(0.5, -0.6), "O", ProblemGen.COL_YELLOW, 26),
	]}
	return {
		"q": "三角形 ABC の 3 頂点から引いた線分 AD・BE・CF が 1 点で交わっています。BD:DC = %d:%d、CE:EA = %d:%d、AB = %d のとき AF の長さを求めなさい。" % [d1, d2, e1b, e2b, ab],
		"answer": af, "unit": "",
		"hint1": "チェバの定理: (AF/FB) × (BD/DC) × (CE/EA) = 1。1 点で交わるときに使える。",
		"hint2": "AF/FB = (DC/BD) × (EA/CE) = (%d/%d) × (%d/%d) = %s" % [
			d2, d1, e2b, e1b, ProblemGen.fmt(ratio)],
		"expl": "AF:FB = %s:1 で AB = %d。AF = %s です。" % [
			ProblemGen.fmt(ratio), ab, ProblemGen.fmt(af)],
		"fig": fig2,
	}


## s17-交点比: 2 本のチェバ線の交点が中線を何対何に分けるか
static func _s17_mass(rng: RandomNumberGenerator) -> Dictionary:
	var s: Array = MASS_SETS[rng.randi_range(0, MASS_SETS.size() - 1)]
	var f1: int = s[0]
	var f2: int = s[1]
	var d1: int = s[2]
	var d2: int = s[3]
	var m_a := float(f2)
	var m_b := float(f1)
	var m_c := m_b * float(d1) / float(d2)
	var ratio := (m_b + m_c) / m_a
	var w := 10.0
	var v := _tri_bc(w)
	var a: Vector2 = v[0]
	var b: Vector2 = v[1]
	var c: Vector2 = v[2]
	var fpt := a + (b - a) * (float(f1) / float(f1 + f2))
	var dpt := b + (c - b) * (float(d1) / float(d1 + d2))
	var opt := _cross_pt(a, dpt, c, fpt)
	var fig := {"shapes": [
		ProblemGen.poly(v, ProblemGen.FILL_MAIN),
		ProblemGen.seg(a, dpt, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.seg(c, fpt, Color(0.55, 0.85, 1.0), 3.0),
		ProblemGen.label(a + Vector2(0, 0.9), "A"),
		ProblemGen.label(b + Vector2(-0.8, -0.5), "B"),
		ProblemGen.label(c + Vector2(0.8, -0.5), "C"),
		ProblemGen.label(dpt + Vector2(0, -0.9), "D", ProblemGen.COL_DIM, 26),
		ProblemGen.label(fpt + Vector2(-0.9, 0.0), "F", ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(opt + Vector2(0.5, -0.6), "O", ProblemGen.COL_YELLOW, 26),
	]}
	return {
		"q": "三角形 ABC で AF:FB = %d:%d、BD:DC = %d:%d です。AD と CF の交点を O とするとき、AO は OD の何倍ですか。" % [f1, f2, d1, d2],
		"answer": ratio, "unit": "倍",
		"hint1": "三角形 ABD と直線 CF にメネラウスの定理を使うと AO:OD が出るよ。",
		"hint2": "(AO/OD) × (DC/CB) × (BF/FA) = 1 を AO/OD について解こう。",
		"expl": "AO:OD = %s:1 なので %s 倍です。" % [ProblemGen.fmt(ratio), ProblemGen.fmt(ratio)],
		"fig": fig,
	}


# =========================================================
# s18: 角の二等分線と線分比・中線定理
# =========================================================

static func _s18(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind < 2:
		var s: Array = BISECT_SETS[rng.randi_range(0, BISECT_SETS.size() - 1)]
		var c: int = s[0]      # AB
		var b: int = s[1]      # AC
		var a: int = s[2]      # BC
		var bd: int = s[3]
		var dc: int = s[4]
		var ad: int = s[5]
		var v: Array = ProblemGen.tri_from_sides(float(a), float(b), float(c))
		var apex: Vector2 = v[0]
		var bpt: Vector2 = v[1]
		var cpt: Vector2 = v[2]
		var dpt := bpt + (cpt - bpt) * (float(bd) / float(a))
		var shapes: Array = [
			ProblemGen.poly(v, ProblemGen.FILL_MAIN),
			ProblemGen.seg(apex, dpt, ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.ang(apex, bpt, dpt, "", 1.5),
			ProblemGen.ang(apex, dpt, cpt, "", 2.1),
		]
		shapes += _abc_labels(v)
		shapes += [
			ProblemGen.label(dpt + Vector2(0, -0.9), "D", ProblemGen.COL_YELLOW, 26),
			_len_label(apex, bpt, str(c), -1.0),
			_len_label(apex, cpt, str(b), 1.0),
		]
		if kind == 0:
			shapes.append(_len_label(bpt, cpt, str(a), -1.0))
			return {
				"q": "三角形 ABC で AB = %d、AC = %d、BC = %d です。∠A の二等分線と BC の交点を D とするとき、BD の長さを求めなさい。" % [c, b, a],
				"answer": float(bd), "unit": "",
				"hint1": "角の二等分線は、向かい合う辺を となりの 2 辺の比に分けるよ(BD:DC = AB:AC)。",
				"hint2": "BD = BC × AB ÷ (AB + AC) = %d × %d ÷ %d" % [a, c, b + c],
				"expl": "BD:DC = %d:%d なので BD = %d × %d/%d = %d です。" % [c, b, a, c, b + c, bd],
				"fig": {"shapes": shapes},
			}
		shapes.append(_len_label(bpt, dpt, str(bd), -1.0))
		shapes.append(_len_label(dpt, cpt, str(dc), -1.0))
		return {
			"q": "三角形 ABC で AB = %d、AC = %d、∠A の二等分線と BC の交点を D とすると BD = %d、DC = %d でした。AD の長さを求めなさい。" % [c, b, bd, dc],
			"answer": float(ad), "unit": "",
			"hint1": "二等分線の長さは AD² = AB × AC − BD × DC で出せるよ。",
			"hint2": "AD² = %d × %d − %d × %d = %d" % [c, b, bd, dc, c * b - bd * dc],
			"expl": "AD² = %d なので AD = %d です。" % [c * b - bd * dc, ad],
			"fig": {"shapes": shapes},
		}
	# kind 2: 中線定理
	var s2: Array = MEDIAN_SETS[rng.randi_range(0, MEDIAN_SETS.size() - 1)]
	var ab: int = s2[0]
	var ac: int = s2[1]
	var bc: int = s2[2]
	var am: int = s2[3]
	var v2: Array = ProblemGen.tri_from_sides(float(bc), float(ac), float(ab))
	var apex2: Vector2 = v2[0]
	var b2: Vector2 = v2[1]
	var c2: Vector2 = v2[2]
	var m := (b2 + c2) * 0.5
	var shapes2: Array = [
		ProblemGen.poly(v2, ProblemGen.FILL_MAIN),
		ProblemGen.seg(apex2, m, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.tick(b2, m, 1), ProblemGen.tick(m, c2, 1),
	]
	shapes2 += _abc_labels(v2)
	shapes2 += [
		ProblemGen.label(m + Vector2(0, -0.9), "M", ProblemGen.COL_YELLOW, 26),
		_len_label(apex2, b2, str(ab), -1.0),
		_len_label(apex2, c2, str(ac), 1.0),
		_len_label(b2, c2, str(bc), -1.0),
	]
	return {
		"q": "三角形 ABC で AB = %d、AC = %d、BC = %d です。BC の中点を M とするとき、中線 AM の長さを求めなさい。" % [ab, ac, bc],
		"answer": float(am), "unit": "",
		"hint1": "中線定理: AB² + AC² = 2(AM² + BM²)。BM は BC の半分だよ。",
		"hint2": "%d + %d = 2(AM² + %d)" % [ab * ab, ac * ac, (bc / 2) * (bc / 2)],
		"expl": "AM² = (%d + %d) ÷ 2 − %d = %d なので AM = %d です。" % [
			ab * ab, ac * ac, (bc / 2) * (bc / 2), am * am, am],
		"fig": {"shapes": shapes2},
	}


## s18-逆算: 中線の長さから残りの辺を出す
static func _s18_rev(rng: RandomNumberGenerator) -> Dictionary:
	var s: Array = MEDIAN_SETS[rng.randi_range(0, MEDIAN_SETS.size() - 1)]
	var ab: int = s[0]
	var ac: int = s[1]
	var bc: int = s[2]
	var am: int = s[3]
	var half := bc / 2
	var v: Array = ProblemGen.tri_from_sides(float(bc), float(ac), float(ab))
	var apex: Vector2 = v[0]
	var b: Vector2 = v[1]
	var c: Vector2 = v[2]
	var m := (b + c) * 0.5
	var shapes: Array = [
		ProblemGen.poly(v, ProblemGen.FILL_MAIN),
		ProblemGen.seg(apex, m, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.tick(b, m, 1), ProblemGen.tick(m, c, 1),
	]
	shapes += _abc_labels(v)
	shapes += [
		ProblemGen.label(m + Vector2(0, -0.9), "M", ProblemGen.COL_YELLOW, 26),
		_len_label(apex, b, str(ab), -1.0),
		_len_label(apex, c, "x", 1.0),
		_len_label(b, c, str(bc), -1.0),
		_len_label(apex, m, str(am), 1.0),
	]
	return {
		"q": "三角形 ABC で AB = %d、BC = %d、BC の中点を M として AM = %d です。AC の長さ x を求めなさい。" % [ab, bc, am],
		"answer": float(ac), "unit": "",
		"hint1": "中線定理 AB² + AC² = 2(AM² + BM²) を AC について解こう。",
		"hint2": "AC² = 2(%d + %d) − %d" % [am * am, half * half, ab * ab],
		"expl": "AC² = 2 × (%d + %d) − %d = %d なので AC = %d です。" % [
			am * am, half * half, ab * ab, ac * ac, ac],
		"fig": {"shapes": shapes},
	}


# =========================================================
# s19: 点と直線の距離
# =========================================================

## ax + by + c = 0 の式の見た目("3x + 4y − 5 = 0" など)
static func _line_eq(a: int, b: int, c: int) -> String:
	var s := "%dx" % a if a != 1 else "x"
	if a == -1:
		s = "−x"
	elif a < 0:
		s = "−%dx" % absi(a)
	s += _signed_term(b, "y") + _signed_num(c) + " = 0"
	return s


## " + 4y" / " − 4y" のような続きの項(係数が 0 なら空)
static func _signed_term(v: int, sym: String) -> String:
	if v == 0:
		return ""
	var head := " + " if v > 0 else " − "
	var n := absi(v)
	return head + ("" if n == 1 else str(n)) + sym


## " + 5" / " − 5"(0 なら空)
static func _signed_num(v: int) -> String:
	if v == 0:
		return ""
	return (" + " if v > 0 else " − ") + str(absi(v))


## 直線 ax+by+c=0 を、表示範囲に収まる線分にする
static func _eq_seg(a: int, b: int, c: int, lo: Vector2, hi: Vector2, color) -> Dictionary:
	var pts: Array = []
	if b != 0:
		pts.append(Vector2(lo.x, -(a * lo.x + c) / float(b)))
		pts.append(Vector2(hi.x, -(a * hi.x + c) / float(b)))
	else:
		pts.append(Vector2(-c / float(a), lo.y))
		pts.append(Vector2(-c / float(a), hi.y))
	return ProblemGen.seg(pts[0], pts[1], color, 3.0)


static func _s19(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	var tri: Array = [[3, 4, 5], [4, 3, 5], [6, 8, 10], [8, 6, 10], [3, -4, 5], [4, -3, 5]]
	var t: Array = tri[rng.randi_range(0, tri.size() - 1)]
	var a: int = t[0]
	var b: int = t[1]
	var n: int = t[2]
	if kind == 0:
		var x0 := rng.randi_range(-4, 5)
		var y0 := rng.randi_range(-4, 5)
		var c := rng.randi_range(-8, 8)
		var val := a * x0 + b * y0 + c
		while absi(val) < n or absi(val) > n * 6:
			c = rng.randi_range(-10, 10)
			val = a * x0 + b * y0 + c
		var ans := absf(float(val)) / float(n)
		var lo := Vector2(-7, -7)
		var hi := Vector2(7, 7)
		var pt := Vector2(x0, y0)
		var foot := pt - Vector2(a, b) * (float(val) / float(n * n))
		var fig := {"shapes": [
			ProblemGen.grid(lo, hi), ProblemGen.axes(lo, hi),
			_eq_seg(a, b, c, lo, hi, Color(0.92, 0.95, 1.0)),
			ProblemGen.seg(pt, foot, ProblemGen.COL_YELLOW, 3.0, true),
			ProblemGen.right(foot, pt, foot + Vector2(-b, a)),
			ProblemGen.circle(pt, 0.22, ProblemGen.COL_YELLOW, null, 0.0),
			ProblemGen.label(pt + Vector2(0.8, 0.7), "(%d, %d)" % [x0, y0], ProblemGen.COL_YELLOW, 26),
			_len_label(pt, foot, "d", 1.0),
		]}
		return {
			"q": "点 (%d, %d) と 直線 %s の距離 d を求めなさい。" % [x0, y0, _line_eq(a, b, c)],
			"answer": ans, "unit": "",
			"hint1": "点と直線の距離は d = |a x0 + b y0 + c| ÷ √(a² + b²)。",
			"hint2": "分子 = |%d| 、分母 = √(%d + %d) = %d" % [val, a * a, b * b, n],
			"expl": "d = %d ÷ %d = %s です。" % [absi(val), n, ProblemGen.fmt(ans)],
			"fig": fig,
		}
	if kind == 1:
		var c1 := rng.randi_range(-9, 0)
		var c2 := c1 + rng.randi_range(1, 4) * n
		var ans2 := float(c2 - c1) / float(n)
		var lo2 := Vector2(-7, -7)
		var hi2 := Vector2(7, 7)
		var fig2 := {"shapes": [
			ProblemGen.grid(lo2, hi2), ProblemGen.axes(lo2, hi2),
			_eq_seg(a, b, c1, lo2, hi2, Color(0.92, 0.95, 1.0)),
			_eq_seg(a, b, c2, lo2, hi2, Color(0.55, 0.85, 1.0)),
		]}
		return {
			"q": "平行な 2 直線 %s と %s の距離を求めなさい。" % [
				_line_eq(a, b, c1), _line_eq(a, b, c2)],
			"answer": ans2, "unit": "",
			"hint1": "片方の直線の上の点を 1 つ取って、もう片方との距離を出せばいいよ。",
			"hint2": "距離 = |%d − %d| ÷ √(%d + %d)" % [c2, c1, a * a, b * b],
			"expl": "定数項の差 %d を √(a²+b²) = %d でわって %s です。" % [
				c2 - c1, n, ProblemGen.fmt(ans2)],
			"fig": fig2,
		}
	# kind 2: 頂点から対辺までの距離(高さ)
	var bx := rng.randi_range(-4, 0)
	var by := rng.randi_range(-3, 2)
	var cx := bx + a
	var cy := by + b
	var ax2 := bx + rng.randi_range(-4, 4)
	var ay2 := by + rng.randi_range(3, 6)
	var det := (cx - bx) * (ay2 - by) - (ax2 - bx) * (cy - by)
	while absi(det) < n or absi(det) % n != 0:
		ax2 = bx + rng.randi_range(-5, 5)
		ay2 = by + rng.randi_range(3, 7)
		det = (cx - bx) * (ay2 - by) - (ax2 - bx) * (cy - by)
	var h := absf(float(det)) / float(n)
	var apex := Vector2(ax2, ay2)
	var bpt := Vector2(bx, by)
	var cpt := Vector2(cx, cy)
	var foot2 := _foot(apex, bpt, cpt)
	var lo3 := Vector2(mini(mini(bx, cx), ax2) - 2, mini(mini(by, cy), ay2) - 2)
	var hi3 := Vector2(maxi(maxi(bx, cx), ax2) + 2, maxi(maxi(by, cy), ay2) + 2)
	var fig3 := {"shapes": [
		ProblemGen.grid(lo3, hi3), ProblemGen.axes(lo3, hi3),
		ProblemGen.poly([apex, bpt, cpt], ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
		ProblemGen.seg(apex, foot2, ProblemGen.COL_YELLOW, 3.0, true),
		ProblemGen.right(foot2, apex, cpt),
		ProblemGen.label(apex + Vector2(0, 0.9), "A(%d, %d)" % [ax2, ay2], ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(bpt + Vector2(-1.0, -0.6), "B(%d, %d)" % [bx, by], ProblemGen.COL_DIM, 26),
		ProblemGen.label(cpt + Vector2(0.9, -0.5), "C(%d, %d)" % [cx, cy], ProblemGen.COL_DIM, 26),
		_len_label(apex, foot2, "h", 1.0),
	]}
	return {
		"q": "3 点 A(%d, %d)、B(%d, %d)、C(%d, %d) があります。A から直線 BC に下ろした垂線の長さ h を求めなさい。" % [
			ax2, ay2, bx, by, cx, cy],
		"answer": h, "unit": "",
		"hint1": "まず直線 BC の式を作ろう。そのあと点と直線の距離の公式を使う。",
		"hint2": "三角形の面積 S = %s、BC = %d。h = 2S ÷ BC でもいいよ。" % [
			ProblemGen.fmt(absf(float(det)) * 0.5), n],
		"expl": "BC = %d、面積 = %s なので h = 2 × 面積 ÷ %d = %s です。" % [
			n, ProblemGen.fmt(absf(float(det)) * 0.5), n, ProblemGen.fmt(h)],
		"fig": fig3,
	}


# =========================================================
# s20: 円の方程式(半径・弦・接線・アポロニウスの円)
# =========================================================

## 弦の長さがきれいになる [中心からの距離 d, 半弦 h, 半径 r]
const CHORD_SETS := [[3, 4, 5], [4, 3, 5], [6, 8, 10], [8, 6, 10], [5, 12, 13],
	[12, 5, 13], [9, 12, 15], [8, 15, 17], [15, 8, 17], [7, 24, 25]]

## アポロニウスの円 [m, n, AB の長さ, 半径]
const APOLLO_SETS := [[2, 1, 6, 4], [2, 1, 3, 2], [3, 1, 8, 3], [1, 2, 6, 4],
	[1, 3, 8, 3], [3, 2, 10, 12], [2, 1, 9, 6], [3, 1, 16, 6], [1, 2, 9, 6]]


static func _s20(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		# 一般形を平方完成して半径(または中心)を出す
		var p := rng.randi_range(-5, 5)
		var q := rng.randi_range(-5, 5)
		var r := rng.randi_range(2, 7)
		var cc := p * p + q * q - r * r
		var lo := Vector2(p - r - 2, q - r - 2)
		var hi := Vector2(p + r + 2, q + r + 2)
		var fig := {"shapes": [
			ProblemGen.grid(lo, hi), ProblemGen.axes(lo, hi),
			ProblemGen.circle(Vector2(p, q), float(r), ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
			ProblemGen.seg(Vector2(p, q), Vector2(p + r, q), ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.label(Vector2(p, q) + Vector2(0, -0.9), "中心", ProblemGen.COL_DIM, 24),
			_len_label(Vector2(p, q), Vector2(p + r, q), "r", 1.0),
		]}
		var ask_r := rng.randf() < 0.65
		if ask_r:
			return {
				"q": "円 x² + y²%s%s%s = 0 の半径 r を求めなさい。" % [
					_signed_term(-2 * p, "x"), _signed_term(-2 * q, "y"), _signed_num(cc)],
				"answer": float(r), "unit": "",
				"hint1": "x と y をそれぞれ平方完成して (x − a)² + (y − b)² = r² の形にしよう。",
				"hint2": "中心は (%d, %d)。r² = %d + %d − (%d)" % [p, q, p * p, q * q, cc],
				"expl": "(x − (%d))² + (y − (%d))² = %d なので r = %d です。" % [p, q, r * r, r],
				"fig": fig,
			}
		return {
			"q": "円 x² + y²%s%s%s = 0 の中心の x 座標を求めなさい。" % [
				_signed_term(-2 * p, "x"), _signed_term(-2 * q, "y"), _signed_num(cc)],
			"answer": float(p), "unit": "",
			"hint1": "x の係数の半分に −1 をかけると、中心の x 座標になるよ。",
			"hint2": "x の係数は %d。その半分の符号を変える。" % (-2 * p),
			"expl": "平方完成すると中心は (%d, %d)。x 座標は %d です。" % [p, q, p],
			"fig": fig,
		}
	if kind == 1:
		# 円と直線が切り取る弦の長さ
		var s: Array = CHORD_SETS[rng.randi_range(0, CHORD_SETS.size() - 1)]
		var d: int = s[0]
		var h: int = s[1]
		var r2: int = s[2]
		var la := 3
		var lb := 4
		var ln := 5
		var p2 := rng.randi_range(-3, 3)
		var q2 := rng.randi_range(-3, 3)
		var c2 := d * ln - la * p2 - lb * q2
		var center := Vector2(p2, q2)
		var foot := center - Vector2(la, lb) * (float(la * p2 + lb * q2 + c2) / float(ln * ln))
		var dir := Vector2(-lb, la) / float(ln)
		var lo2 := Vector2(p2 - r2 - 2, q2 - r2 - 2)
		var hi2 := Vector2(p2 + r2 + 2, q2 + r2 + 2)
		var fig2 := {"shapes": [
			ProblemGen.grid(lo2, hi2), ProblemGen.axes(lo2, hi2),
			ProblemGen.circle(center, float(r2), null, Color.WHITE, 3.0),
			_eq_seg(la, lb, c2, lo2, hi2, Color(0.55, 0.85, 1.0)),
			ProblemGen.seg(foot - dir * float(h), foot + dir * float(h), ProblemGen.COL_YELLOW, 4.0),
			ProblemGen.seg(center, foot, ProblemGen.COL_DIM, 2.0, true),
			ProblemGen.right(foot, center, foot + dir),
			ProblemGen.label(center + Vector2(0, -0.9), "中心", ProblemGen.COL_DIM, 24),
		]}
		return {
			"q": "中心 (%d, %d)、半径 %d の円が、直線 %s によって切り取られる弦の長さを求めなさい。" % [
				p2, q2, r2, _line_eq(la, lb, c2)],
			"answer": float(2 * h), "unit": "",
			"hint1": "中心から直線までの距離 d を出そう。弦の半分と d と半径で直角三角形ができる。",
			"hint2": "d = %d なので、弦の半分は √(%d − %d) = %d" % [d, r2 * r2, d * d, h],
			"expl": "弦の長さ = 2√(r² − d²) = 2 × %d = %d です。" % [h, 2 * h],
			"fig": fig2,
		}
	if kind == 2:
		# 円の外の点からの接線の長さ
		var s3: Array = TANGENT_SETS[rng.randi_range(0, TANGENT_SETS.size() - 1)]
		var d3: int = s3[0]
		var r3: int = s3[1]
		var t3: int = s3[2]
		var legs := {5: Vector2(3, 4), 10: Vector2(6, 8), 13: Vector2(5, 12), 15: Vector2(9, 12),
			17: Vector2(8, 15), 20: Vector2(12, 16), 25: Vector2(7, 24)}
		if not legs.has(d3):
			return _s20(rng, 1)
		var off: Vector2 = legs[d3]
		var p3 := rng.randi_range(-2, 2)
		var q3 := rng.randi_range(-2, 2)
		var center3 := Vector2(p3, q3)
		var pt := center3 + off
		var tx := center3 + (pt - center3).rotated(-acos(float(r3) / float(d3))).normalized() * float(r3)
		var lo3 := Vector2(minf(center3.x - r3, pt.x) - 2, minf(center3.y - r3, pt.y) - 2)
		var hi3 := Vector2(maxf(center3.x + r3, pt.x) + 2, maxf(center3.y + r3, pt.y) + 2)
		var fig3 := {"shapes": [
			ProblemGen.grid(lo3, hi3), ProblemGen.axes(lo3, hi3),
			ProblemGen.circle(center3, float(r3), null, Color.WHITE, 3.0),
			ProblemGen.seg(pt, tx, ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.seg(center3, tx, ProblemGen.COL_DIM, 2.0, true),
			ProblemGen.seg(center3, pt, ProblemGen.COL_DIM, 2.0, true),
			ProblemGen.right(tx, center3, pt),
			ProblemGen.label(pt + Vector2(0.6, 0.6), "P", ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(tx + Vector2(0.6, 0.4), "T", ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(center3 + Vector2(0, -0.9), "中心", ProblemGen.COL_DIM, 24),
		]}
		return {
			"q": "中心 (%d, %d)、半径 %d の円に、点 P(%s, %s) から接線を引きます。接点を T とするとき接線の長さ PT を求めなさい。" % [
				p3, q3, r3, ProblemGen.fmt(pt.x), ProblemGen.fmt(pt.y)],
			"answer": float(t3), "unit": "",
			"hint1": "中心と P と接点 T で直角三角形ができる(接線と半径は垂直)。",
			"hint2": "中心と P の距離は %d。PT = √(%d − %d)" % [d3, d3 * d3, r3 * r3],
			"expl": "PT = √(中心までの距離² − 半径²) = √(%d − %d) = %d です。" % [
				d3 * d3, r3 * r3, t3],
			"fig": fig3,
		}
	return _s20_apollo(rng)


## s20-アポロニウス: 2 定点からの距離の比が一定な点の軌跡は円
static func _s20_apollo(rng: RandomNumberGenerator) -> Dictionary:
	var s: Array = APOLLO_SETS[rng.randi_range(0, APOLLO_SETS.size() - 1)]
	var m: int = s[0]
	var n: int = s[1]
	var ab: int = s[2]
	var rad: int = s[3]
	# A(0,0)、B(ab,0)。AP:BP = m:n の軌跡の中心は x = ab m² / (m² − n²)
	var cx := float(ab) * float(m * m) / float(m * m - n * n)
	var lo := Vector2(minf(-2.0, cx - rad - 2), -rad - 2)
	var hi := Vector2(maxf(float(ab) + 2, cx + rad + 2), rad + 2)
	var fig := {"shapes": [
		ProblemGen.grid(lo, hi), ProblemGen.axes(lo, hi),
		ProblemGen.circle(Vector2(cx, 0), float(rad), ProblemGen.FILL_MAIN, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.circle(Vector2.ZERO, 0.22, Color.WHITE, null, 0.0),
		ProblemGen.circle(Vector2(ab, 0), 0.22, Color.WHITE, null, 0.0),
		ProblemGen.label(Vector2(0, -1.0), "A", ProblemGen.COL_DIM, 26),
		ProblemGen.label(Vector2(ab, -1.0), "B", ProblemGen.COL_DIM, 26),
		_len_label(Vector2(cx, 0), Vector2(cx + rad, 0), "r", 1.0),
	]}
	return {
		"q": "2 点 A(0, 0)、B(%d, 0) からの距離の比が AP:BP = %d:%d である点 P の軌跡は円になります。その半径を求めなさい。" % [ab, m, n],
		"answer": float(rad), "unit": "",
		"hint1": "AP:BP = %d:%d を式にすると %d²(x² + y²) = %d²((x − %d)² + y²)。整理して平方完成しよう。" % [
			m, n, n, m, ab],
		"hint2": "アポロニウスの円。半径は m n × AB ÷ |m² − n²| でも出せるよ。",
		"expl": "半径 = %d × %d × %d ÷ |%d − %d| = %d です。" % [
			m, n, ab, m * m, n * n, rad],
		"fig": fig,
	}


# =========================================================
# s21: 空間図形の体積(四面体・立方体・正四面体・球)
# =========================================================

## 立方体の枠だけを描く(体積の問題で共通に使う)
static func _cube_frame(a: float) -> Array:
	var shapes: Array = []
	for e in CUBE_EDGES:
		var en := String(e)
		var p: Vector3 = CUBE_V[en[0]] * a
		var q: Vector3 = CUBE_V[en[1]] * a
		var hidden := en.contains("D")
		shapes.append(ProblemGen.seg(_proj(p), _proj(q),
			ProblemGen.COL_DIM if hidden else Color(0.92, 0.95, 1.0), 2.5, hidden))
	return shapes


static func _s21(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		# 座標の四面体 OABC。体積 = |行列式| ÷ 6
		# 見た目がつぶれないように、どの向きにもある程度の長さを持たせる
		var ax := rng.randi_range(2, 5)
		var by := rng.randi_range(2, 5)
		var cz := rng.randi_range(2, 5)
		var bx := rng.randi_range(0, 2)
		var cy := rng.randi_range(0, 2)
		# O を頂点にした四面体の体積は |行列式| ÷ 6。この置き方だと ax × by × cz になる
		var det := ax * by * cz
		while det % 3 != 0:      # 体積が 0.5 きざみに収まるようにする
			cz = rng.randi_range(2, 6)
			det = ax * by * cz
		var v := float(det) / 6.0
		var o3 := Vector3.ZERO
		var a3 := Vector3(ax, 0, 0)
		var b3 := Vector3(bx, by, 0)
		var c3 := Vector3(0, cy, cz)
		var shapes: Array = [
			ProblemGen.poly([_proj(o3), _proj(a3), _proj(b3)], ProblemGen.FILL_MAIN, Color.WHITE, 2.5),
			ProblemGen.seg(_proj(o3), _proj(c3), Color(0.92, 0.95, 1.0), 2.5),
			ProblemGen.seg(_proj(a3), _proj(c3), Color(0.92, 0.95, 1.0), 2.5),
			ProblemGen.seg(_proj(b3), _proj(c3), ProblemGen.COL_YELLOW, 2.5),
			ProblemGen.label(_proj(o3) + Vector2(-0.8, -0.6), "O", ProblemGen.COL_DIM, 26),
			ProblemGen.label(_proj(a3) + Vector2(0.7, -0.5), "A", ProblemGen.COL_DIM, 26),
			ProblemGen.label(_proj(b3) + Vector2(0.7, 0.4), "B", ProblemGen.COL_DIM, 26),
			ProblemGen.label(_proj(c3) + Vector2(0.0, 0.9), "C", ProblemGen.COL_DIM, 26),
		]
		return {
			"q": "O(0, 0, 0)、A(%d, 0, 0)、B(%d, %d, 0)、C(0, %d, %d) を頂点とする四面体の体積を求めなさい。" % [
				ax, bx, by, cy, cz],
			"answer": v, "unit": "",
			"hint1": "四面体の体積は (底面積) × (高さ) ÷ 3。底面を三角形 OAB にすると高さは C の z 座標だよ。",
			"hint2": "底面積 = %d × %d ÷ 2、高さ = %d" % [ax, by, cz],
			"expl": "底面積 %s、高さ %d なので 体積 = %s × %d ÷ 3 = %s です。" % [
				ProblemGen.fmt(ax * by * 0.5), cz, ProblemGen.fmt(ax * by * 0.5), cz,
				ProblemGen.fmt(v)],
			"fig": {"shapes": shapes},
		}
	if kind == 1:
		# 立方体を切り取ってできる三角錐
		var a := float(rng.randi_range(2, 6) * 3)
		var half := rng.randf() < 0.5
		var shapes2: Array = _cube_frame(a)
		if half:
			var p1 := Vector3(a * 0.5, 0, 0)
			var p2 := Vector3(0, a * 0.5, 0)
			var p3 := Vector3(0, 0, a * 0.5)
			shapes2.append(ProblemGen.poly([_proj(Vector3.ZERO), _proj(p1), _proj(p2)],
				ProblemGen.FILL_ACCENT, ProblemGen.COL_YELLOW, 3.0))
			shapes2.append(ProblemGen.poly([_proj(Vector3.ZERO), _proj(p1), _proj(p3)],
				ProblemGen.FILL_ACCENT, ProblemGen.COL_YELLOW, 3.0))
			shapes2.append(ProblemGen.poly([_proj(p1), _proj(p2), _proj(p3)],
				ProblemGen.FILL_SUB, ProblemGen.COL_YELLOW, 3.0))
			var vol := a * a * a / 48.0
			return {
				"q": "1 辺 %s の立方体の頂点 A から、A に集まる 3 本の辺の中点を通る平面で切り取ります。切り取った三角錐の体積を求めなさい。" % ProblemGen.fmt(a),
				"answer": vol, "unit": "",
				"hint1": "直角がそろっているので、底面積 × 高さ ÷ 3 がそのまま使えるよ。3 辺はどれも半分の長さ。",
				"hint2": "体積 = (%s × %s ÷ 2) × %s ÷ 3" % [
					ProblemGen.fmt(a * 0.5), ProblemGen.fmt(a * 0.5), ProblemGen.fmt(a * 0.5)],
				"expl": "3 辺が %s の直角三角錐なので 体積 = %s です。" % [
					ProblemGen.fmt(a * 0.5), ProblemGen.fmt(vol)],
				"fig": {"shapes": shapes2},
			}
		shapes2.append(ProblemGen.poly([_proj(Vector3.ZERO), _proj(Vector3(a, 0, 0)),
			_proj(Vector3(0, a, 0))], ProblemGen.FILL_ACCENT, ProblemGen.COL_YELLOW, 3.0))
		shapes2.append(ProblemGen.poly([_proj(Vector3.ZERO), _proj(Vector3(a, 0, 0)),
			_proj(Vector3(0, 0, a))], ProblemGen.FILL_SUB, ProblemGen.COL_YELLOW, 3.0))
		var vol2 := a * a * a / 6.0
		return {
			"q": "1 辺 %s の立方体 ABCD-EFGH で、三角錐 ABDE の体積を求めなさい(A に集まる 3 辺だけでできる立体です)。" % ProblemGen.fmt(a),
			"answer": vol2, "unit": "",
			"hint1": "底面を三角形 ABD にすると、高さは辺 AE そのものだよ。",
			"hint2": "体積 = (%s × %s ÷ 2) × %s ÷ 3" % [
				ProblemGen.fmt(a), ProblemGen.fmt(a), ProblemGen.fmt(a)],
			"expl": "立方体の 6 分の 1 になるので 体積 = %s です。" % ProblemGen.fmt(vol2),
			"fig": {"shapes": shapes2},
		}
	# kind 2: 正四面体の高さと体積
	var e := float(rng.randi_range(2, 6) * 3)
	var tetra: Array = [Vector3(0, 0, 0), Vector3(1, 1, 0), Vector3(1, 0, 1), Vector3(0, 1, 1)]
	var scale := e / 1.4142136
	var pts: Array = []
	for t3 in tetra:
		pts.append(_proj((t3 as Vector3) * scale))
	var shapes3: Array = [
		ProblemGen.poly([pts[0], pts[1], pts[2]], ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
		ProblemGen.poly([pts[0], pts[1], pts[3]], ProblemGen.FILL_SUB, Color.WHITE, 3.0),
		ProblemGen.seg(pts[2], pts[3], Color(0.92, 0.95, 1.0), 3.0),
		ProblemGen.label(pts[0] + Vector2(-0.8, -0.6), "A", ProblemGen.COL_DIM, 26),
		ProblemGen.label(pts[1] + Vector2(0.8, -0.4), "B", ProblemGen.COL_DIM, 26),
		ProblemGen.label(pts[2] + Vector2(0.6, 0.6), "C", ProblemGen.COL_DIM, 26),
		ProblemGen.label(pts[3] + Vector2(-0.6, 0.7), "D", ProblemGen.COL_DIM, 26),
	]
	if rng.randf() < 0.5:
		var hgt := e * 2.45 / 3.0
		return {
			"q": "1 辺 %s の正四面体の高さを求めなさい。√6 = 2.45 として小数で答えなさい。" % ProblemGen.fmt(e),
			"answer": hgt, "unit": "", "tol": 0.05,
			"hint1": "頂点から底面に下ろした足は、底面の正三角形の重心。重心までは 中線の 2/3 だよ。",
			"hint2": "高さ = 1 辺 × √6 ÷ 3 = %s × 2.45 ÷ 3" % ProblemGen.fmt(e),
			"expl": "高さ = %s × √6/3 = %s です。" % [ProblemGen.fmt(e), ProblemGen.fmt(hgt)],
			"fig": {"shapes": shapes3},
		}
	var vol3 := e * e * e * 1.41 / 12.0
	return {
		"q": "1 辺 %s の正四面体の体積を求めなさい。√2 = 1.41 として小数で答えなさい。" % ProblemGen.fmt(e),
		"answer": vol3, "unit": "", "tol": 0.05,
		"hint1": "正四面体は立方体の中に入る。体積は 1 辺 × 1 辺 × 1 辺 × √2 ÷ 12 で出せるよ。",
		"hint2": "体積 = %s × 1.41 ÷ 12" % ProblemGen.fmt(e * e * e),
		"expl": "体積 = %s × √2/12 = %s です。" % [ProblemGen.fmt(e * e * e), ProblemGen.fmt(vol3)],
		"fig": {"shapes": shapes3},
	}


## s21-球: 外接球の半径と球の体積
static func _s21_ball(rng: RandomNumberGenerator) -> Dictionary:
	if rng.randf() < 0.5:
		var a := float(rng.randi_range(2, 8))
		var rad := a * 1.73 / 2.0
		var shapes: Array = _cube_frame(a)
		shapes.append(ProblemGen.seg(_proj(Vector3.ZERO), _proj(Vector3(a, a, a)),
			ProblemGen.COL_YELLOW, 3.0))
		shapes.append(ProblemGen.circle(_proj(Vector3(a, a, a) * 0.5), a * 0.87,
			null, ProblemGen.COL_DIM, 2.0))
		return {
			"q": "1 辺 %s の立方体の 8 頂点をすべて通る球(外接球)の半径を求めなさい。√3 = 1.73 として小数で答えなさい。" % ProblemGen.fmt(a),
			"answer": rad, "unit": "", "tol": 0.05,
			"hint1": "立方体の対角線が、そのまま球の直径になるよ。",
			"hint2": "対角線 = 1 辺 × √3。半径はその半分。",
			"expl": "対角線 = %s × 1.73 = %s。半径はその半分で %s です。" % [
				ProblemGen.fmt(a), ProblemGen.fmt(a * 1.73), ProblemGen.fmt(rad)],
			"fig": {"shapes": shapes},
		}
	var r := float(rng.randi_range(2, 9))
	var vol := 4.0 / 3.0 * 3.14 * r * r * r
	var fig := {"shapes": [
		ProblemGen.circle(Vector2.ZERO, r, ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
		ProblemGen.seg(Vector2.ZERO, Vector2(r, 0), ProblemGen.COL_YELLOW, 3.0),
		_len_label(Vector2.ZERO, Vector2(r, 0), ProblemGen.fmt(r), 1.0),
	]}
	return {
		"q": "半径 %s の球の体積を求めなさい。π = 3.14 として小数で答えなさい。" % ProblemGen.fmt(r),
		"answer": vol, "unit": "", "tol": 0.05,
		"hint1": "球の体積は 4/3 × π × 半径の 3 乗。",
		"hint2": "体積 = 4 ÷ 3 × 3.14 × %s" % ProblemGen.fmt(r * r * r),
		"expl": "体積 = 4/3 × 3.14 × %s = %s です。" % [
			ProblemGen.fmt(r * r * r), ProblemGen.fmt(vol)],
		"fig": fig,
	}


# =========================================================
# s22: 回転体の体積・媒介変数と極座標の面積・曲線の長さ(数III)
# =========================================================

## y = f(x) と、その x 軸対称のコピーを描いて回転体らしく見せる
static func _rot_fig(pts: Array, axis_to: float) -> Dictionary:
	var mirror: Array = []
	for p in pts:
		mirror.append(Vector2((p as Vector2).x, -(p as Vector2).y))
	var last: Vector2 = pts[pts.size() - 1]
	# 回す前の面(曲線と x 軸ではさまれたところ)をそのままの形で塗る
	var area: Array = pts.duplicate()
	area.append(Vector2(last.x, 0))
	area.append(Vector2(0, 0))
	return {"shapes": [
		ProblemGen.axes(Vector2(-1, -last.y - 1.5), Vector2(axis_to + 1.5, last.y + 1.5)),
		ProblemGen.poly(area, ProblemGen.FILL_MAIN, null, 0.0),
		ProblemGen.curve(pts, ProblemGen.COL_YELLOW, 3.5),
		ProblemGen.curve(mirror, ProblemGen.COL_DIM, 2.5),
		ProblemGen.seg(Vector2(last.x, last.y), Vector2(last.x, -last.y),
			Color(0.55, 0.85, 1.0), 3.0),
	]}


static func _s22(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		# y = √x を x 軸のまわりに回す
		var a := float(rng.randi_range(2, 8))
		var vol := 3.14 * a * a / 2.0
		var pts: Array = []
		for i in 25:
			var x := a * i / 24.0
			pts.append(Vector2(x * 2.0, sqrt(x) * 2.0))
		return {
			"q": "曲線 y = √x (0 ≤ x ≤ %s) を x 軸のまわりに 1 回転させてできる立体の体積を求めなさい。π = 3.14 として小数で答えなさい。" % ProblemGen.fmt(a),
			"answer": vol, "unit": "", "tol": 0.02,
			"hint1": "回転体の体積は V = π ∫ y² dx。y² = x だから中身はただの x だよ。",
			"hint2": "V = π × [x²/2] = 3.14 × %s ÷ 2" % ProblemGen.fmt(a * a),
			"expl": "V = π × %s²/2 = 3.14 × %s = %s です。" % [
				ProblemGen.fmt(a), ProblemGen.fmt(a * a / 2.0), ProblemGen.fmt(vol)],
			"fig": _rot_fig(pts, a * 2.0),
		}
	if kind == 1:
		# 直線を回して円錐(または放物線を回す)
		if rng.randf() < 0.5:
			var r := float(rng.randi_range(2, 6))
			var h := float(rng.randi_range(3, 9))
			var vol2 := 3.14 * r * r * h / 3.0
			var pts2: Array = []
			for i in 13:
				var x := h * i / 12.0
				pts2.append(Vector2(x * 1.6, r * x / h * 1.6))
			return {
				"q": "直線 y = %s x ÷ %s (0 ≤ x ≤ %s) を x 軸のまわりに 1 回転させてできる円錐の体積を求めなさい。π = 3.14 として小数で答えなさい。" % [
					ProblemGen.fmt(r), ProblemGen.fmt(h), ProblemGen.fmt(h)],
				"answer": vol2, "unit": "", "tol": 0.02,
				"hint1": "できる立体は 底面の半径 %s、高さ %s の円錐だよ。" % [
					ProblemGen.fmt(r), ProblemGen.fmt(h)],
				"hint2": "V = π r² h ÷ 3 = 3.14 × %s × %s ÷ 3" % [
					ProblemGen.fmt(r * r), ProblemGen.fmt(h)],
				"expl": "V = 3.14 × %s × %s ÷ 3 = %s です。" % [
					ProblemGen.fmt(r * r), ProblemGen.fmt(h), ProblemGen.fmt(vol2)],
				"fig": _rot_fig(pts2, h * 1.6),
			}
		var a2 := float(rng.randi_range(1, 3))
		var vol3 := 3.14 * pow(a2, 5) / 5.0
		var pts3: Array = []
		for i in 25:
			var x := a2 * i / 24.0
			pts3.append(Vector2(x * 3.0, x * x * 1.5))
		return {
			"q": "曲線 y = x² (0 ≤ x ≤ %s) を x 軸のまわりに 1 回転させてできる立体の体積を求めなさい。π = 3.14 として小数で答えなさい。" % ProblemGen.fmt(a2),
			"answer": vol3, "unit": "", "tol": 0.02,
			"hint1": "V = π ∫ y² dx。y² = x⁴ だから、積分すると x の 5 乗 ÷ 5 になるよ。",
			"hint2": "V = 3.14 × %s ÷ 5" % ProblemGen.fmt(pow(a2, 5)),
			"expl": "V = π × (%s の 5 乗) ÷ 5 = 3.14 × %s = %s です。" % [
				ProblemGen.fmt(a2), ProblemGen.fmt(pow(a2, 5) / 5.0), ProblemGen.fmt(vol3)],
			"fig": _rot_fig(pts3, a2 * 3.0),
		}
	# kind 2: 媒介変数(サイクロイド)と極座標(カージオイド)の面積
	var a3 := float(rng.randi_range(1, 4))
	if rng.randf() < 0.5:
		var area := 3.0 * 3.14 * a3 * a3
		var pts4: Array = []
		for i in 49:
			var th := TAU * i / 48.0
			pts4.append(Vector2(a3 * (th - sin(th)), a3 * (1.0 - cos(th))))
		var fig4 := {"shapes": [
			ProblemGen.axes(Vector2(-1, -1), Vector2(a3 * TAU + 1, a3 * 2.0 + 1)),
			ProblemGen.curve(pts4, ProblemGen.COL_YELLOW, 3.5),
			ProblemGen.seg(Vector2(0, 0), Vector2(a3 * TAU, 0), Color(0.55, 0.85, 1.0), 3.0),
		]}
		return {
			"q": "サイクロイド x = %s(θ − sinθ)、y = %s(1 − cosθ) (0 ≤ θ ≤ 2π) と x 軸で囲まれた面積を求めなさい。π = 3.14 として小数で答えなさい。" % [
				ProblemGen.fmt(a3), ProblemGen.fmt(a3)],
			"answer": area, "unit": "", "tol": 0.02,
			"hint1": "面積は ∫ y dx。dx = %s(1 − cosθ)dθ に置きかえて θ で積分しよう。" % ProblemGen.fmt(a3),
			"hint2": "答えは 3πa² の形になる。a = %s を入れよう。" % ProblemGen.fmt(a3),
			"expl": "サイクロイド 1 山の面積は 3πa² = 3 × 3.14 × %s = %s です(転がる円の 3 倍)。" % [
				ProblemGen.fmt(a3 * a3), ProblemGen.fmt(area)],
			"fig": fig4,
		}
	var area2 := 1.5 * 3.14 * a3 * a3
	var pts5: Array = []
	for i in 73:
		var th := TAU * i / 72.0
		var rr := a3 * (1.0 + cos(th))
		pts5.append(Vector2(rr * cos(th), rr * sin(th)))
	var fig5 := {"shapes": [
		ProblemGen.axes(Vector2(-a3 - 1, -a3 * 1.5), Vector2(a3 * 2.0 + 1, a3 * 1.5)),
		ProblemGen.poly(pts5, ProblemGen.FILL_MAIN, ProblemGen.COL_YELLOW, 3.0),
	]}
	return {
		"q": "カージオイド r = %s(1 + cosθ) で囲まれた面積を求めなさい。π = 3.14 として小数で答えなさい。" % ProblemGen.fmt(a3),
		"answer": area2, "unit": "", "tol": 0.02,
		"hint1": "極座標の面積は S = ½ ∫ r² dθ(0 から 2π まで)。",
		"hint2": "展開すると cos²θ が出る。答えは 1.5πa² の形になるよ。",
		"expl": "S = 3πa²/2 = 1.5 × 3.14 × %s = %s です。" % [
			ProblemGen.fmt(a3 * a3), ProblemGen.fmt(area2)],
		"fig": fig5,
	}


## s22-曲線の長さ: y = (2/3)x^(3/2) の 0 から a まで(1 + a が平方数の組だけ)
static func _s22_length(rng: RandomNumberGenerator) -> Dictionary:
	var sets: Array = [[3, 4], [8, 9], [15, 16], [24, 25], [35, 36]]
	var s: Array = sets[rng.randi_range(0, sets.size() - 1)]
	var a: int = s[0]
	var k: int = s[1]                       # 1 + a = k(平方数の元)
	var root := int(sqrt(float(k)))
	var ans := 2.0 / 3.0 * (pow(float(k), 1.5) - 1.0)
	var pts: Array = []
	for i in 25:
		var x := float(a) * i / 24.0
		pts.append(Vector2(x * 8.0 / float(a), 2.0 / 3.0 * pow(x, 1.5) * 8.0 / float(a)))
	var fig := {"shapes": [
		ProblemGen.axes(Vector2(-1, -1), Vector2(10, 10)),
		ProblemGen.curve(pts, ProblemGen.COL_YELLOW, 3.5),
		ProblemGen.label(Vector2(8.4, 8.0), "y = (2/3)x√x", ProblemGen.COL_YELLOW, 26),
	]}
	return {
		"q": "曲線 y = (2/3)x√x の 0 ≤ x ≤ %d の部分の長さを求めなさい。" % a,
		"answer": ans, "unit": "", "tol": 0.02,
		"hint1": "曲線の長さは L = ∫ √(1 + (y')²) dx。y' = √x だから中身は 1 + x になるよ。",
		"hint2": "L = ∫ √(1 + x) dx = (2/3)[(1 + x)√(1 + x)] を 0 から %d まで。" % a,
		"expl": "L = (2/3)(%d√%d − 1) = (2/3)(%d − 1) = %s です。" % [
			k, k, root * k, ProblemGen.fmt(ans)],
		"fig": fig,
	}
