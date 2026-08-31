class_name GenSolid
## 立体図形と、平面図形の残り(図形の移動・相似)の問題生成。
## 中学受験と高校受験で大問ひとつ分になる範囲なのに手薄だったところをまとめている:
##   e18 立体の体積と表面積(直方体・三角柱・円柱・組み合わせ)
##   e19 水そうと水位(水の深さ・石を沈める・毎分の給水)
##   e20 図形の移動と重なり(動く長方形・点の移動・転がり)
##   e21 相似で長さを出す(ピラミッド型・砂時計型・影・台形)
##   j13 角錐と円錐(体積・表面積・展開図の中心角・球)
##   j14 空間の三平方(直方体の対角線・表面の最短経路・立方体の対角線)
##   j15 平行線と線分の比(ピラミッド型・3 本の平行線・台形・中点連結)
##   j16 相似比と体積比(3 乗の比・円錐を切る・水の深さ)
## 立体は ProblemGen.proj3 で斜めに投影して描く(向きは全ステージ共通)。
## 円周率は π = 3.14、無理数は √2 = 1.41 のように問題文で決めてから答えさせる。


## 直方体の対角線が整数になる 3 辺 [a, b, c, 対角線]
const DIAG_SETS := [
	[1, 2, 2, 3], [2, 3, 6, 7], [1, 4, 8, 9], [4, 4, 7, 9], [2, 6, 9, 11],
	[6, 6, 7, 11], [3, 4, 12, 13], [2, 10, 11, 15], [2, 5, 14, 15],
	[8, 9, 12, 17], [1, 12, 12, 17], [4, 13, 16, 21],
]

## 円錐の展開図の中心角が整数になる [底面の半径 r, 母線 l, 中心角]
const CONE_SETS := [
	[3, 5, 216], [2, 5, 144], [4, 5, 288], [1, 2, 180], [2, 3, 240], [3, 4, 270],
	[5, 6, 300], [2, 8, 90], [3, 8, 135], [5, 8, 225], [4, 9, 160], [2, 9, 80],
	[5, 9, 200], [3, 10, 108], [7, 10, 252], [5, 12, 150], [7, 12, 210],
]

## 直角三角形の 3 辺(三角柱で長さをきれいにするのに使う)
const TRIPLES := [[3, 4, 5], [6, 8, 10], [5, 12, 13], [8, 15, 17], [9, 12, 15], [7, 24, 25]]

## 表面の最短経路用 [よこ+おくゆき, 高さ, 答え]。細長すぎる形は入れない
const SHORT_SETS := [[3, 4, 5], [4, 3, 5], [6, 8, 10], [8, 6, 10], [9, 12, 15],
	[12, 9, 15], [5, 12, 13], [12, 5, 13], [15, 8, 17]]


static func gen(stage_id: String, rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var t := clampi(tier, 0, 9)
	match stage_id:
		"e18":
			# 直方体 → 三角柱 → 円柱 → 組み合わせた立体
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _e18(rng, 0)
				1: return _e18(rng, 1)
				2: return _e18(rng, 2)
				_: return _e18_combo(rng)
		"e19":
			# 水の深さ → 石を沈める → 毎分の給水 → 水を移す
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _e19(rng, 0)
				1: return _e19(rng, 1)
				2: return _e19(rng, 2)
				_: return _e19_move(rng)
		"e20":
			# 重なりの面積 → 点の移動 → 転がる正方形 → 転がる円
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _e20(rng, 0)
				1: return _e20(rng, 1)
				2: return _e20(rng, 2)
				_: return _e20_roll(rng)
		"e21":
			# ピラミッド型 → 砂時計型 → 影 → 台形の対角線
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _e21(rng, 0)
				1: return _e21(rng, 1)
				2: return _e21(rng, 2)
				_: return _e21_trapezoid(rng)
		"j13":
			# 角錐の体積 → 円錐の体積 → 展開図の中心角 → 表面積(円錐・球)
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _j13(rng, 0)
				1: return _j13(rng, 1)
				2: return _j13(rng, 2)
				_: return _j13_surface(rng)
		"j14":
			# 直方体の対角線 → 表面を這う最短経路 → 立方体の対角線(√3)
			match [0, 0, 0, 0, 1, 1, 1, 2, 2, 2][t]:
				0: return _j14(rng, 0)
				1: return _j14(rng, 1)
				_: return _j14(rng, 2)
		"j15":
			# ピラミッド型 → 3 本の平行線 → 台形の対角線 → 中点連結
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _j15(rng, 0)
				1: return _j15(rng, 1)
				2: return _j15(rng, 2)
				_: return _j15_mid(rng)
		_:
			# j16: 体積比 → 円錐を切る → 表面積比 → 水の深さ
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _j16(rng, 0)
				1: return _j16(rng, 1)
				2: return _j16(rng, 2)
				_: return _j16_water(rng)


# =========================================================
# 立体を描く共通の部品(すべて ProblemGen.proj3 の向き)
# =========================================================

## 直方体の枠。奥に隠れる頂点(0, d, 0)につながる辺は点線
static func _box(w: float, d: float, h: float, col := Color(0.92, 0.95, 1.0)) -> Array:
	var v: Array = [
		Vector3(0, 0, 0), Vector3(w, 0, 0), Vector3(w, d, 0), Vector3(0, d, 0),
		Vector3(0, 0, h), Vector3(w, 0, h), Vector3(w, d, h), Vector3(0, d, h),
	]
	var edges: Array = [[0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7]]
	var shapes: Array = []
	for e in edges:
		var i: int = e[0]
		var j: int = e[1]
		var hidden := i == 3 or j == 3
		shapes.append(ProblemGen.seg(ProblemGen.proj3(v[i]), ProblemGen.proj3(v[j]),
			ProblemGen.COL_DIM if hidden else col, 2.5, hidden))
	return shapes


## 高さ lv までの水(直方体の中)
static func _water(w: float, d: float, lv: float) -> Array:
	var top: Array = [
		ProblemGen.proj3(Vector3(0, 0, lv)), ProblemGen.proj3(Vector3(w, 0, lv)),
		ProblemGen.proj3(Vector3(w, d, lv)), ProblemGen.proj3(Vector3(0, d, lv)),
	]
	var front: Array = [
		ProblemGen.proj3(Vector3(0, 0, 0)), ProblemGen.proj3(Vector3(w, 0, 0)),
		ProblemGen.proj3(Vector3(w, 0, lv)), ProblemGen.proj3(Vector3(0, 0, lv)),
	]
	return [
		ProblemGen.poly(front, Color(0.3, 0.6, 0.95, 0.35), null, 0.0),
		ProblemGen.poly(top, Color(0.45, 0.75, 1.0, 0.5), Color(0.55, 0.85, 1.0), 2.5),
	]


## 高さ z のところの円(投影すると楕円になる)を線でつくる
static func _ring(r: float, z: float, from_deg := 0.0, to_deg := 360.0) -> Array:
	var pts: Array = []
	var n := 36
	for i in n + 1:
		var th := deg_to_rad(from_deg + (to_deg - from_deg) * i / float(n))
		pts.append(ProblemGen.proj3(Vector3(r * cos(th), r * sin(th), z)))
	return pts


## 円柱
static func _cylinder(r: float, h: float) -> Array:
	var col := Color(0.92, 0.95, 1.0)
	return [
		ProblemGen.curve(_ring(r, h), col, 2.5),
		ProblemGen.curve(_ring(r, 0.0, 180.0, 360.0), col, 2.5),
		ProblemGen.curve(_ring(r, 0.0, 0.0, 180.0), ProblemGen.COL_DIM, 2.0),
		ProblemGen.seg(ProblemGen.proj3(Vector3(-r, 0, 0)), ProblemGen.proj3(Vector3(-r, 0, h)), col, 2.5),
		ProblemGen.seg(ProblemGen.proj3(Vector3(r, 0, 0)), ProblemGen.proj3(Vector3(r, 0, h)), col, 2.5),
	]


## 円錐(頂点は真上)
static func _cone(r: float, h: float) -> Array:
	var col := Color(0.92, 0.95, 1.0)
	var apex := ProblemGen.proj3(Vector3(0, 0, h))
	return [
		ProblemGen.curve(_ring(r, 0.0, 180.0, 360.0), col, 2.5),
		ProblemGen.curve(_ring(r, 0.0, 0.0, 180.0), ProblemGen.COL_DIM, 2.0),
		ProblemGen.seg(ProblemGen.proj3(Vector3(-r, 0, 0)), apex, col, 2.5),
		ProblemGen.seg(ProblemGen.proj3(Vector3(r, 0, 0)), apex, col, 2.5),
	]


## 正四角錐(底面は 1 辺 a の正方形)
static func _pyramid(a: float, h: float) -> Array:
	var col := Color(0.92, 0.95, 1.0)
	var half := a * 0.5
	var b: Array = [
		Vector3(-half, -half, 0), Vector3(half, -half, 0),
		Vector3(half, half, 0), Vector3(-half, half, 0),
	]
	var apex := ProblemGen.proj3(Vector3(0, 0, h))
	var shapes: Array = []
	for i in 4:
		var hidden := i == 2 or i == 3     # 奥の 2 辺
		shapes.append(ProblemGen.seg(ProblemGen.proj3(b[i]), ProblemGen.proj3(b[(i + 1) % 4]),
			ProblemGen.COL_DIM if hidden else col, 2.5, hidden))
	for i in 4:
		shapes.append(ProblemGen.seg(ProblemGen.proj3(b[i]), apex,
			ProblemGen.COL_DIM if i == 3 else col, 2.5, i == 3))
	return shapes


## 三角柱(底面は直角三角形 a × b、奥行き h)
static func _prism(a: float, b: float, h: float) -> Array:
	var col := Color(0.92, 0.95, 1.0)
	var f: Array = [Vector3(0, 0, 0), Vector3(a, 0, 0), Vector3(0, 0, b)]
	var shapes: Array = []
	for i in 3:
		shapes.append(ProblemGen.seg(ProblemGen.proj3(f[i]), ProblemGen.proj3(f[(i + 1) % 3]), col, 2.5))
	for i in 3:
		var back: Vector3 = (f[i] as Vector3) + Vector3(0, h, 0)
		var back2: Vector3 = (f[(i + 1) % 3] as Vector3) + Vector3(0, h, 0)
		shapes.append(ProblemGen.seg(ProblemGen.proj3(back), ProblemGen.proj3(back2), col, 2.5))
		shapes.append(ProblemGen.seg(ProblemGen.proj3(f[i]), ProblemGen.proj3(back), col, 2.5))
	return shapes


## 立体の辺に長さを書く
static func _edge_label(p: Vector3, q: Vector3, s: String, off := Vector2(0, -0.9)) -> Dictionary:
	var mid := (ProblemGen.proj3(p) + ProblemGen.proj3(q)) * 0.5
	return ProblemGen.label(mid + off, s, ProblemGen.COL_YELLOW, 26)


# =========================================================
# e18: 立体の体積と表面積
# =========================================================

static func _e18(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		var w := rng.randi_range(3, 9)
		var d := rng.randi_range(3, 8)
		var h := rng.randi_range(2, 8)
		var ask_vol := rng.randf() < 0.6
		var vol := w * d * h
		var surf := 2 * (w * d + d * h + h * w)
		var shapes: Array = _box(float(w), float(d), float(h))
		shapes += [
			_edge_label(Vector3(0, 0, 0), Vector3(w, 0, 0), "%d cm" % w, Vector2(0, -1.0)),
			_edge_label(Vector3(w, 0, float(h) * 1.5), Vector3(w, 0, h), "%d cm" % h, Vector2(1.5, 0)),
			_edge_label(Vector3(w, 0, 0), Vector3(w, d, 0), "%d cm" % d, Vector2(0.9, -0.7)),
		]
		var base_face: Array = [ProblemGen.proj3(Vector3(0, 0, 0)),
			ProblemGen.proj3(Vector3(w, 0, 0)), ProblemGen.proj3(Vector3(w, d, 0)),
			ProblemGen.proj3(Vector3(0, d, 0))]
		var side_face: Array = [ProblemGen.proj3(Vector3(0, 0, 0)),
			ProblemGen.proj3(Vector3(w, 0, 0)), ProblemGen.proj3(Vector3(w, 0, h)),
			ProblemGen.proj3(Vector3(0, 0, h))]
		if ask_vol:
			var steps18 := [
				{"say": "まず 下の 面(底面)の 広さ。%d × %d = %d cm²。" % [d, w, w * d],
					"add": [ProblemGen.poly(base_face, Color(1.0, 0.85, 0.3, 0.35))]},
				{"say": "その 面が、高さ %d cm ぶん つみ上がって いる。" % h,
					"add": [ProblemGen.seg(ProblemGen.proj3(Vector3(w, 0, 0)),
						ProblemGen.proj3(Vector3(w, 0, h)),
						Color(0.45, 1.0, 0.6, 0.95), 4.0)]},
				{"say": "%d × %d × %d = %d cm³。入力してみよう!" % [d, w, h, vol]},
			]
			return {
				"q": "たて %d cm、よこ %d cm、高さ %d cm の直方体の体積を求めなさい。" % [d, w, h],
				"answer": float(vol), "unit": "cm³",
				"steps": steps18,
				"hint1": "直方体の体積は たて × よこ × 高さ。",
				"hint2": "%d × %d × %d" % [d, w, h],
				"expl": "体積 = %d × %d × %d = %d cm³ です。" % [d, w, h, vol],
				"fig": {"shapes": shapes},
			}
		var steps18b := [
			{"say": "面は 6 つ。まず 上下の 面 ― %d × %d = %d が 2 まい。" % [d, w, w * d],
				"add": [ProblemGen.poly(base_face, Color(1.0, 0.85, 0.3, 0.35))]},
			{"say": "つぎに 手前と おくの 面 ― %d × %d = %d が 2 まい。のこりの 横の 面は %d × %d = %d が 2 まい。" % [
				w, h, w * h, d, h, d * h],
				"add": [ProblemGen.poly(side_face, Color(0.45, 1.0, 0.6, 0.35))]},
			{"say": "(%d + %d + %d) × 2 = %d cm²。入力してみよう!" % [
				w * d, d * h, h * w, surf]},
		]
		return {
			"q": "たて %d cm、よこ %d cm、高さ %d cm の直方体の表面積を求めなさい。" % [d, w, h],
			"answer": float(surf), "unit": "cm²",
			"steps": steps18b,
			"hint1": "面は 6 つ。向かい合う面は同じ大きさだから、3 種類を求めて 2 倍しよう。",
			"hint2": "(%d×%d + %d×%d + %d×%d) × 2" % [w, d, d, h, h, w],
			"expl": "(%d + %d + %d) × 2 = %d cm² です。" % [w * d, d * h, h * w, surf],
			"fig": {"shapes": shapes},
		}
	if kind == 1:
		var tri: Array = TRIPLES[rng.randi_range(0, TRIPLES.size() - 1)]
		var a: int = tri[0]
		var b: int = tri[1]
		var c: int = tri[2]
		var h2 := rng.randi_range(3, 10)
		var vol2 := a * b * h2 / 2.0
		var surf2 := float(a * b) + float(a + b + c) * h2
		var ask_vol2 := rng.randf() < 0.6
		var shapes2: Array = _prism(float(a), float(b), float(h2))
		shapes2 += [
			_edge_label(Vector3(0, 0, 0), Vector3(a, 0, 0), "%d" % a, Vector2(0, -1.0)),
			_edge_label(Vector3(0, 0, 0), Vector3(0, 0, b), "%d" % b, Vector2(-1.2, 0)),
			_edge_label(Vector3(a, 0, 0), Vector3(a, h2, 0), "%d" % h2, Vector2(1.0, -0.6)),
			ProblemGen.right(ProblemGen.proj3(Vector3.ZERO), ProblemGen.proj3(Vector3(a, 0, 0)),
				ProblemGen.proj3(Vector3(0, 0, b))),
		]
		if ask_vol2:
			return {
				"q": "底面が 直角をはさむ 2 辺 %d cm と %d cm の直角三角形、高さ(奥ゆき)が %d cm の三角柱の体積を求めなさい。" % [a, b, h2],
				"answer": vol2, "unit": "cm³",
				"hint1": "角柱の体積は 底面積 × 高さ。底面は直角三角形だよ。",
				"hint2": "(%d × %d ÷ 2) × %d" % [a, b, h2],
				"expl": "底面積 = %s、体積 = %s × %d = %s cm³ です。" % [
					ProblemGen.fmt(a * b / 2.0), ProblemGen.fmt(a * b / 2.0), h2, ProblemGen.fmt(vol2)],
				"fig": {"shapes": shapes2},
			}
		return {
			"q": "底面が 3 辺 %d cm・%d cm・%d cm の直角三角形、高さ(奥ゆき)が %d cm の三角柱の表面積を求めなさい。" % [a, b, c, h2],
			"answer": surf2, "unit": "cm²",
			"hint1": "表面積 = 底面 2 つ + 側面。側面は 底面の周 × 高さ の長方形になるよ。",
			"hint2": "%d × 2 ÷ 2 + (%d + %d + %d) × %d" % [a * b, a, b, c, h2],
			"expl": "底面 2 つで %d、側面は %d × %d = %d。合わせて %s cm² です。" % [
				a * b, a + b + c, h2, (a + b + c) * h2, ProblemGen.fmt(surf2)],
			"fig": {"shapes": shapes2},
		}
	# kind 2: 円柱
	var r := rng.randi_range(2, 7)
	var h3 := rng.randi_range(3, 10)
	var ask_vol3 := rng.randf() < 0.6
	var vol3 := 3.14 * r * r * h3
	var surf3 := 2.0 * 3.14 * r * r + 2.0 * 3.14 * r * h3
	var shapes3: Array = _cylinder(float(r), float(h3))
	shapes3 += [
		ProblemGen.seg(ProblemGen.proj3(Vector3(0, 0, h3)), ProblemGen.proj3(Vector3(r, 0, h3)),
			ProblemGen.COL_YELLOW, 2.5),
		_edge_label(Vector3(0, 0, h3), Vector3(r, 0, h3), "%d" % r, Vector2(0, 0.9)),
		_edge_label(Vector3(r, 0, 0), Vector3(r, 0, h3), "%d" % h3, Vector2(1.2, 0)),
	]
	if ask_vol3:
		return {
			"q": "底面の半径 %d cm、高さ %d cm の円柱の体積を求めなさい。円周率は 3.14 とします。" % [r, h3],
			"answer": vol3, "unit": "cm³", "tol": 0.02,
			"hint1": "円柱の体積も 底面積 × 高さ。底面は円だから 半径 × 半径 × 3.14。",
			"hint2": "%d × %d × 3.14 × %d" % [r, r, h3],
			"expl": "底面積 = %s、体積 = %s cm³ です。" % [
				ProblemGen.fmt(3.14 * r * r), ProblemGen.fmt(vol3)],
			"fig": {"shapes": shapes3},
		}
	return {
		"q": "底面の半径 %d cm、高さ %d cm の円柱の表面積を求めなさい。円周率は 3.14 とします。" % [r, h3],
		"answer": surf3, "unit": "cm²", "tol": 0.02,
		"hint1": "上下の円 2 つと、側面の長方形。側面のよこは 底面の円周と同じ長さだよ。",
		"hint2": "%s × 2 + %s × %d" % [ProblemGen.fmt(3.14 * r * r), ProblemGen.fmt(2 * 3.14 * r), h3],
		"expl": "円 2 つで %s、側面は %s。合わせて %s cm² です。" % [
			ProblemGen.fmt(2 * 3.14 * r * r), ProblemGen.fmt(2 * 3.14 * r * h3), ProblemGen.fmt(surf3)],
		"fig": {"shapes": shapes3},
	}


## e18-組み合わせ: 直方体を 2 つくっつけた立体の体積
static func _e18_combo(rng: RandomNumberGenerator) -> Dictionary:
	var w := rng.randi_range(6, 12)
	var d := rng.randi_range(3, 6)
	var h := rng.randi_range(2, 5)
	var w2 := rng.randi_range(2, w - 3)
	var h2 := rng.randi_range(2, 6)
	var vol := w * d * h + w2 * d * h2
	var shapes: Array = _box(float(w), float(d), float(h))
	shapes += _box(float(w2), float(d), float(h + h2), ProblemGen.COL_YELLOW)
	shapes += [
		_edge_label(Vector3(0, 0, 0), Vector3(w, 0, 0), "%d" % w, Vector2(0, -1.0)),
		_edge_label(Vector3(w, 0, 0), Vector3(w, 0, h), "%d" % h, Vector2(1.2, 0)),
		_edge_label(Vector3(0, 0, h), Vector3(0, 0, h + h2), "%d" % h2, Vector2(-1.2, 0)),
		_edge_label(Vector3(0, 0, h + h2), Vector3(w2, 0, h + h2), "%d" % w2, Vector2(0, 0.9)),
		_edge_label(Vector3(w, 0, 0), Vector3(w, d, 0), "%d" % d, Vector2(0.9, -0.7)),
	]
	return {
		"q": "下の段が たて %d cm・よこ %d cm・高さ %d cm、その上に よこ %d cm・高さ %d cm の部分が乗った立体があります(奥ゆきはどちらも %d cm)。体積を求めなさい。" % [
			d, w, h, w2, h2, d],
		"answer": float(vol), "unit": "cm³",
		"hint1": "2 つの直方体に分けて、それぞれの体積をたそう。",
		"hint2": "%d×%d×%d + %d×%d×%d" % [w, d, h, w2, d, h2],
		"expl": "%d + %d = %d cm³ です。" % [w * d * h, w2 * d * h2, vol],
		"fig": {"shapes": shapes},
	}


# =========================================================
# e19: 水そうと水位
# =========================================================

## 水そうの図(直方体 + 水)
static func _tank_fig(w: int, d: int, h: int, lv: float, extra: Array = []) -> Dictionary:
	var shapes: Array = _box(float(w), float(d), float(h))
	if lv > 0.0:
		shapes += _water(float(w), float(d), lv)
	shapes += [
		_edge_label(Vector3(0, 0, 0), Vector3(w, 0, 0), "%d cm" % w, Vector2(0, -1.1)),
		_edge_label(Vector3(w, 0, 0), Vector3(w, d, 0), "%d cm" % d, Vector2(1.0, -0.8)),
		_edge_label(Vector3(w, 0, 0), Vector3(w, 0, h), "%d cm" % h, Vector2(1.4, 0)),
	]
	shapes += extra
	return {"shapes": shapes}


static func _e19(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		var w := rng.randi_range(5, 12)
		var d := rng.randi_range(4, 10)
		var lv := rng.randi_range(2, 8)
		var h := lv + rng.randi_range(2, 6)
		var vol := w * d * lv
		var steps19 := [
			{"say": "水の 形も 直方体。下の 面は 水そうと 同じ %d × %d = %d cm²。" % [
				d, w, w * d],
				"add": [ProblemGen.poly([ProblemGen.proj3(Vector3(0, 0, 0)),
					ProblemGen.proj3(Vector3(w, 0, 0)), ProblemGen.proj3(Vector3(w, d, 0)),
					ProblemGen.proj3(Vector3(0, d, 0))], Color(1.0, 0.85, 0.3, 0.35))]},
			{"say": "底面積 × 深さ = 水の 体積 %d cm³ に なる。深さを 求めよう。" % vol},
			{"say": "%d ÷ %d = %d cm。入力してみよう!" % [vol, w * d, lv]},
		]
		return {
			"q": "たて %d cm、よこ %d cm、高さ %d cm の直方体の水そうに、%d cm³ の水を入れました。水の深さは何 cm になりますか。" % [
				d, w, h, vol],
			"answer": float(lv), "unit": "cm",
			"steps": steps19,
			"hint1": "水の形も直方体。底面積 × 深さ = 水の体積 だよ。",
			"hint2": "深さ = %d ÷ (%d × %d)" % [vol, w, d],
			"expl": "底面積は %d cm²。%d ÷ %d = %d cm です。" % [w * d, vol, w * d, lv],
			"fig": _tank_fig(w, d, h, float(lv)),
		}
	if kind == 1:
		# 石を沈めると水位が上がる(a の 3 乗が底面積で割り切れる組を選ぶ)
		var sets: Array = [[6, 8, 3, 9], [4, 4, 4, 4], [10, 20, 5, 10], [5, 5, 5, 5],
			[6, 9, 4, 6], [8, 16, 4, 8], [3, 3, 3, 3], [6, 6, 6, 6], [9, 27, 3, 9]]
		var s: Array = sets[rng.randi_range(0, sets.size() - 1)]
		var a: int = s[0]
		var w2: int = s[1]
		var d2: int = s[2]
		var up: int = s[3]
		var lv2 := rng.randi_range(a + 1, a + 5)
		var h2 := lv2 + up + rng.randi_range(1, 4)
		var stone: Array = _box(float(a), float(a), float(a), ProblemGen.COL_YELLOW)
		return {
			"q": "たて %d cm、よこ %d cm の直方体の水そうに、深さ %d cm まで水が入っています。1 辺 %d cm の立方体の石を完全にしずめると、水面は何 cm 上がりますか。" % [
				d2, w2, lv2, a],
			"answer": float(up), "unit": "cm",
			"hint1": "石の体積の分だけ、水がおし上げられるよ。",
			"hint2": "上がる高さ = %d ÷ (%d × %d)" % [a * a * a, w2, d2],
			"expl": "石の体積は %d cm³。底面積 %d cm² でわって %d cm 上がります。" % [
				a * a * a, w2 * d2, up],
			"fig": _tank_fig(w2, d2, h2, float(lv2), stone),
		}
	# kind 2: 毎分 x L 入れて満水まで何分
	# 底面を 25 × 40 = 1000 cm² にしておくと、深さ 1 cm = 1 L でぴったり合う
	# (乱数を引き直して条件が合うのを待つ書き方だと、組み合わせによっては
	#  永久に合わなくて止まらなくなる。答えの方から作れば必ず 1 回で決まる)
	var w3 := 25
	var d3 := 40
	var per := rng.randi_range(2, 12)
	var minutes := float(rng.randi_range(2, 15))
	var h3 := int(float(per) * minutes)
	while h3 > 60:
		minutes = float(rng.randi_range(2, 15))
		per = rng.randi_range(2, 12)
		h3 = int(float(per) * minutes)
	var cap := float(w3 * d3 * h3) / 1000.0
	return {
		"q": "たて %d cm、よこ %d cm、高さ %d cm の直方体の水そうが空です。毎分 %d L の水を入れると、満水まで何分かかりますか(1 L = 1000 cm³)。" % [
			d3, w3, h3, per],
		"answer": minutes, "unit": "分",
		"hint1": "まず水そうの容積を求めて、L に直そう(1000 cm³ = 1 L)。",
		"hint2": "容積 = %d cm³ = %s L。これを %d でわる。" % [w3 * d3 * h3, ProblemGen.fmt(cap), per],
		"expl": "容積 %s L ÷ 毎分 %d L = %s 分です。" % [
			ProblemGen.fmt(cap), per, ProblemGen.fmt(minutes)],
		"fig": _tank_fig(w3 / 5, d3 / 5, h3 / 5, 0.0),
	}


## e19-移しかえ: 別の水そうに全部移すと深さはどうなるか。
## 底面積がきれいな倍数になる組だけを使う(深さが必ず整数で出る)
const TANK_PAIRS := [
	[12, 5, 10, 3], [15, 4, 10, 3], [10, 9, 15, 3], [12, 10, 8, 5], [10, 6, 12, 5],
	[8, 5, 10, 4], [20, 6, 15, 4], [18, 5, 15, 3], [16, 5, 10, 4], [24, 5, 20, 3],
]

static func _e19_move(rng: RandomNumberGenerator) -> Dictionary:
	var s: Array = TANK_PAIRS[rng.randi_range(0, TANK_PAIRS.size() - 1)]
	var w1: int = s[0]
	var d1: int = s[1]
	var w2: int = s[2]
	var d2: int = s[3]
	var lv1 := rng.randi_range(3, 10)
	var vol := w1 * d1 * lv1
	var lv2 := float(vol) / float(w2 * d2)
	return {
		"q": "たて %d cm、よこ %d cm の水そうに深さ %d cm まで水が入っています。この水を全部、たて %d cm、よこ %d cm の水そうに移すと、深さは何 cm になりますか。" % [
			d1, w1, lv1, d2, w2],
		"answer": lv2, "unit": "cm",
		"hint1": "水の量は移しても変わらない。まず水の体積を出そう。",
		"hint2": "%d ÷ (%d × %d)" % [vol, w2, d2],
		"expl": "水は %d cm³。新しい底面積 %d cm² でわって %s cm です。" % [
			vol, w2 * d2, ProblemGen.fmt(lv2)],
		"fig": _tank_fig(w2, d2, int(ceil(lv2)) + 3, lv2),
	}


# =========================================================
# e20: 図形の移動と重なり
# =========================================================

static func _e20(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		# 長方形が右へ動いて、止まっている長方形と重なる
		var hgt := rng.randi_range(3, 8)
		var w_move := rng.randi_range(5, 10)
		var w_fix := rng.randi_range(5, 12)
		var v := rng.randi_range(1, 3)
		var t := rng.randi_range(1, mini(w_move, w_fix) / v)
		var over := v * t
		var area := over * hgt
		var fix_x := 0.0
		var mv_x := fix_x - w_move + over          # 重なり始めてから t 秒後の位置
		var fix: Array = [Vector2(fix_x, 0), Vector2(fix_x + w_fix, 0),
			Vector2(fix_x + w_fix, hgt), Vector2(fix_x, hgt)]
		var mv: Array = [Vector2(mv_x, 0), Vector2(mv_x + w_move, 0),
			Vector2(mv_x + w_move, hgt), Vector2(mv_x, hgt)]
		var ov: Array = [Vector2(fix_x, 0), Vector2(fix_x + over, 0),
			Vector2(fix_x + over, hgt), Vector2(fix_x, hgt)]
		var fig := {"shapes": [
			ProblemGen.poly(fix, ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
			ProblemGen.poly(mv, null, ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.poly(ov, ProblemGen.FILL_ACCENT, ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.arrow(Vector2(mv_x - 2.5, hgt * 0.5), Vector2(mv_x - 0.5, hgt * 0.5),
				ProblemGen.COL_YELLOW),
			ProblemGen.label(Vector2(fix_x + w_fix * 0.6, hgt + 1.0),
				"止まっている長方形", ProblemGen.COL_DIM, 24),
			ProblemGen.label(Vector2(mv_x + 0.2, -1.2), "動く長方形", ProblemGen.COL_YELLOW, 24),
		]}
		var steps20 := [
			{"say": "%d 秒間に 動く 長方形は %d × %d = %d cm 進む。" % [t, v, t, over],
				"add": [ProblemGen.arrow(Vector2(fix_x, hgt + 0.6),
					Vector2(fix_x + over, hgt + 0.6), Color(0.45, 1.0, 0.6, 0.95))]},
			{"say": "重なった ところは いつも 長方形。よこ %d cm、たては %d cm の まま。" % [
				over, hgt],
				"add": [ProblemGen.poly(ov, Color(1.0, 0.85, 0.3, 0.40))]},
			{"say": "%d × %d = %d cm²。入力してみよう!" % [over, hgt, area]},
		]
		return {
			"q": "たて %d cm、よこ %d cm の長方形が、毎秒 %d cm で右へ動いて、止まっている長方形(たて %d cm、よこ %d cm)に重なっていきます。重なり始めてから %d 秒後の重なった部分の面積を求めなさい。" % [
				hgt, w_move, v, hgt, w_fix, t],
			"answer": float(area), "unit": "cm²",
			"steps": steps20,
			"hint1": "重なった部分はいつも長方形。たては変わらないので、よこの長さだけ考えよう。",
			"hint2": "よこ = %d × %d = %d cm。面積 = %d × %d" % [v, t, over, over, hgt],
			"expl": "%d 秒で %d cm 進むので、重なりは よこ %d cm・たて %d cm。面積 %d cm² です。" % [
				t, over, over, hgt, area],
			"fig": fig,
		}
	if kind == 1:
		# 長方形の辺を動く点 P
		var w := rng.randi_range(6, 12)
		var h := rng.randi_range(4, 9)
		var v2 := rng.randi_range(1, 3)
		var t2 := rng.randi_range(1, w / v2)
		var ap := v2 * t2
		var area2 := h * ap / 2.0
		var a := Vector2(0, 0)
		var b := Vector2(w, 0)
		var c := Vector2(w, h)
		var d := Vector2(0, h)
		var pp := Vector2(ap, 0)
		var fig2 := {"shapes": [
			ProblemGen.poly([a, b, c, d], null, Color.WHITE, 3.0),
			ProblemGen.poly([a, pp, d], ProblemGen.FILL_ACCENT, ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.label(a + Vector2(-0.8, -0.8), "A"),
			ProblemGen.label(b + Vector2(0.8, -0.8), "B"),
			ProblemGen.label(c + Vector2(0.8, 0.7), "C"),
			ProblemGen.label(d + Vector2(-0.8, 0.7), "D"),
			ProblemGen.label(pp + Vector2(0, -1.2), "P", ProblemGen.COL_YELLOW, 26),
			ProblemGen.arrow(pp + Vector2(0.3, 0.6), pp + Vector2(2.0, 0.6), ProblemGen.COL_YELLOW),
		]}
		return {
			"q": "長方形 ABCD は AB = %d cm、AD = %d cm です。点 P は A を出発して毎秒 %d cm で B に向かって辺 AB 上を動きます。%d 秒後の三角形 APD の面積を求めなさい。" % [
				w, h, v2, t2],
			"answer": area2, "unit": "cm²",
			"hint1": "三角形 APD の底辺を AP、高さを AD と見よう。",
			"hint2": "AP = %d × %d = %d cm。面積 = %d × %d ÷ 2" % [v2, t2, ap, ap, h],
			"expl": "AP = %d cm なので 面積 = %d × %d ÷ 2 = %s cm² です。" % [
				ap, ap, h, ProblemGen.fmt(area2)],
			"fig": fig2,
		}
	# kind 2: 正方形が直線の上を転がる
	var a2 := rng.randi_range(2, 9)
	var dist := snappedf(3.14 / 2.0 * float(a2) * (2.0 + 1.41), 0.01)
	# P は左上から出発して、対角線(a×√2)→ 辺(a)→ 0 → 辺(a) の順に円弧をえがく。
	# 3 回目は P 自身が回転の中心になるので動かない
	var af := float(a2)
	var shapes: Array = [
		ProblemGen.seg(Vector2(-1, 0), Vector2(af * 5.5, 0), Color(0.92, 0.95, 1.0), 3.0),
	]
	for i in 5:
		var x := af * i
		shapes.append(ProblemGen.poly([Vector2(x, 0), Vector2(x + af, 0),
			Vector2(x + af, af), Vector2(x, af)],
			ProblemGen.FILL_MAIN if i == 0 else null, ProblemGen.COL_DIM, 2.0))
	shapes.append(ProblemGen.arc(Vector2(af, 0), af * 1.41421, 45.0, 135.0,
		ProblemGen.COL_YELLOW, 3.0))
	shapes.append(ProblemGen.arc(Vector2(af * 2.0, 0), af, 0.0, 90.0, ProblemGen.COL_YELLOW, 3.0))
	shapes.append(ProblemGen.arc(Vector2(af * 4.0, 0), af, 90.0, 180.0, ProblemGen.COL_YELLOW, 3.0))
	shapes.append(ProblemGen.label(Vector2(0, af + 0.9), "P", ProblemGen.COL_YELLOW, 26))
	shapes.append(ProblemGen.label(Vector2(af * 4.0, af + 0.9), "P", ProblemGen.COL_DIM, 26))
	return {
		"q": "1 辺 %d cm の正方形が直線の上をすべらずに右へ 4 回転がって、もとの向きにもどります。左上の頂点 P が動いた道のりを求めなさい。円周率は 3.14、√2 = 1.41 とします。" % a2,
		"answer": dist, "unit": "cm", "tol": 0.05,
		"hint1": "P は 90° ずつの円弧を 3 回えがくよ(4 回目は P が中心になるので動かない)。",
		"hint2": "半径は %d、%d×1.41、%d の 3 回。どれも 4 分の 1 円だから (半径の和) × 2 × 3.14 ÷ 4。" % [
			a2, a2, a2],
		"expl": "半径の和は %s cm。道のり = %s × 2 × 3.14 ÷ 4 = %s cm です。" % [
			ProblemGen.fmt(a2 * (2.0 + 1.41)), ProblemGen.fmt(a2 * (2.0 + 1.41)),
			ProblemGen.fmt(dist)],
		"fig": {"shapes": shapes},
	}


## e20-転がる円: 円が図形のまわりを 1 周するとき中心が動く道のり
static func _e20_roll(rng: RandomNumberGenerator) -> Dictionary:
	var r := rng.randi_range(1, 5)
	var n: int = [3, 4, 6][rng.randi_range(0, 2)]
	var a := rng.randi_range(4, 12)
	var dist := float(n * a) + 2.0 * 3.14 * float(r)
	var poly_pts: Array = []
	for i in n:
		var th: float = TAU * i / float(n) + PI * 0.5
		poly_pts.append(Vector2(cos(th), sin(th)) * float(a) * 0.6)
	var out_pts: Array = []
	for i in poly_pts.size():
		out_pts.append((poly_pts[i] as Vector2) * 1.35)
	var fig := {"shapes": [
		ProblemGen.poly(poly_pts, ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
		ProblemGen.poly(out_pts, null, ProblemGen.COL_DIM, 2.0),
		ProblemGen.circle((poly_pts[0] as Vector2) * 1.35, float(a) * 0.2, null,
			ProblemGen.COL_YELLOW, 2.5),
	]}
	return {
		"q": "1 辺 %d cm の正%d角形のまわりを、半径 %d cm の円がすべらずに 1 周します。円の中心が動いた道のりを求めなさい。円周率は 3.14 とします。" % [
			a, n, r],
		"answer": dist, "unit": "cm", "tol": 0.02,
		"hint1": "まっすぐ進むところは辺と同じ長さ。角では中心が円弧をえがくよ。",
		"hint2": "角の弧を全部あわせると、ちょうど半径 %d cm の円 1 個分になる。" % r,
		"expl": "直線部分 %d cm + 円 1 個分 %s cm = %s cm です。" % [
			n * a, ProblemGen.fmt(2 * 3.14 * r), ProblemGen.fmt(dist)],
		"fig": fig,
	}


# =========================================================
# e21: 相似で長さを出す(ピラミッド型・砂時計型・影)
# =========================================================

static func _e21(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		# ピラミッド型: DE と BC が平行
		var m := rng.randi_range(1, 4)
		var n := rng.randi_range(1, 4)
		var unit := rng.randi_range(2, 5)
		var bc := (m + n) * unit
		var de := m * unit
		var a := Vector2(3.5, 9.0)
		var b := Vector2(0, 0)
		var c := Vector2(11.0, 0)
		var d := a + (b - a) * (float(m) / float(m + n))
		var e := a + (c - a) * (float(m) / float(m + n))
		var fig := {"shapes": [
			ProblemGen.poly([a, b, c], ProblemGen.FILL_MAIN),
			ProblemGen.seg(d, e, ProblemGen.COL_YELLOW, 3.5),
			ProblemGen.label(a + Vector2(0, 0.9), "A"),
			ProblemGen.label(b + Vector2(-0.8, -0.6), "B"),
			ProblemGen.label(c + Vector2(0.8, -0.6), "C"),
			ProblemGen.label(d + Vector2(-0.9, 0), "D", ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(e + Vector2(0.9, 0), "E", ProblemGen.COL_YELLOW, 26),
			ProblemGen.side_label(a, d, str(m), -1.0, 0.8),
			ProblemGen.side_label(d, b, str(n), -1.0, 0.8),
			ProblemGen.side_label(b, c, "%d cm" % bc, -1.0, 0.9),
			ProblemGen.side_label(d, e, "x", 1.0, 0.8),
		]}
		var steps21 := [
			{"say": "DE と BC は 平行。だから 三角形 ADE は、ABC を 小さく した 同じ 形。",
				"add": [ProblemGen.poly([a, d, e], Color(1.0, 0.85, 0.3, 0.35))]},
			{"say": "AD : AB = %d : %d だから、辺は ぜんぶ %d/%d の 大きさ。" % [
				m, m + n, m, m + n],
				"add": [ProblemGen.seg(a, b, Color(0.45, 1.0, 0.6, 0.9), 3.0),
					ProblemGen.seg(a, d, Color(1.0, 0.85, 0.3, 0.95), 5.0)]},
			{"say": "x = %d × %d ÷ %d = %d cm。入力してみよう!" % [bc, m, m + n, de]},
		]
		return {
			"q": "三角形 ABC で、辺 AB 上の点 D と辺 AC 上の点 E を結んだ DE が BC と平行です。AD:DB = %d:%d、BC = %d cm のとき、DE の長さ x を求めなさい。" % [
				m, n, bc],
			"answer": float(de), "unit": "cm",
			"steps": steps21,
			"hint1": "三角形 ADE と三角形 ABC は同じ形(相似)。辺の比は AD:AB になるよ。",
			"hint2": "AD:AB = %d:%d なので x = %d × %d ÷ %d" % [m, m + n, bc, m, m + n],
			"expl": "相似比は %d:%d。x = %d × %d/%d = %d cm です。" % [
				m, m + n, bc, m, m + n, de],
			"fig": fig,
		}
	if kind == 1:
		# 砂時計型: AB と CD が平行で、対角線が O で交わる
		var k := rng.randi_range(2, 5)
		var ab := rng.randi_range(2, 6) * 2
		var cd := ab * k
		var ao := rng.randi_range(2, 6)
		var oc := ao * k
		var a := Vector2(-ab * 0.5, 4.0)
		var b := Vector2(ab * 0.5, 4.0)
		var c := Vector2(cd * 0.5, -4.0)
		var d := Vector2(-cd * 0.5, -4.0)
		var o := Vector2.ZERO
		var fig2 := {"shapes": [
			ProblemGen.seg(a, b, Color.WHITE, 3.0),
			ProblemGen.seg(d, c, Color.WHITE, 3.0),
			ProblemGen.seg(a, c, ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.seg(b, d, ProblemGen.COL_DIM, 2.5),
			ProblemGen.label(a + Vector2(-0.8, 0.5), "A"),
			ProblemGen.label(b + Vector2(0.8, 0.5), "B"),
			ProblemGen.label(c + Vector2(0.8, -0.6), "C"),
			ProblemGen.label(d + Vector2(-0.8, -0.6), "D"),
			ProblemGen.label(o + Vector2(0.8, 0.3), "O", ProblemGen.COL_YELLOW, 26),
			ProblemGen.side_label(a, b, "%d cm" % ab, 1.0, 0.8),
			ProblemGen.side_label(d, c, "%d cm" % cd, -1.0, 0.8),
			ProblemGen.side_label(a, o, "%d cm" % ao, -1.0, 0.8),
			ProblemGen.side_label(o, c, "x", -1.0, 0.8),
		]}
		return {
			"q": "AB と CD が平行で、AC と BD が点 O で交わっています。AB = %d cm、CD = %d cm、AO = %d cm のとき、OC の長さ x を求めなさい。" % [
				ab, cd, ao],
			"answer": float(oc), "unit": "cm",
			"hint1": "三角形 OAB と三角形 OCD は、向かい合った同じ形(砂時計型の相似)。",
			"hint2": "AO:OC = AB:CD = %d:%d だから x = %d × %d ÷ %d" % [ab, cd, ao, cd, ab],
			"expl": "AO:OC = %d:%d なので x = %d cm です。" % [ab, cd, oc],
			"fig": fig2,
		}
	# kind 2: 影の長さから高さを出す
	var pole := rng.randi_range(1, 3)
	var shadow := rng.randi_range(2, 6)
	var tree_shadow := shadow * rng.randi_range(2, 8)
	var tree := float(pole) * float(tree_shadow) / float(shadow)
	var sun := Vector2(-3.0, 9.0)
	var fig3 := {"shapes": [
		ProblemGen.seg(Vector2(-2, 0), Vector2(16, 0), Color(0.92, 0.95, 1.0), 3.0),
		ProblemGen.seg(Vector2(0, 0), Vector2(0, pole * 1.2), ProblemGen.COL_YELLOW, 4.0),
		ProblemGen.seg(Vector2(0, pole * 1.2), Vector2(shadow * 1.2, 0), ProblemGen.COL_DIM, 2.0, true),
		ProblemGen.seg(Vector2(9, 0), Vector2(9, tree * 1.2), ProblemGen.COL_YELLOW, 4.0),
		ProblemGen.seg(Vector2(9, tree * 1.2), Vector2(9 + tree_shadow * 1.2, 0),
			ProblemGen.COL_DIM, 2.0, true),
		ProblemGen.label(Vector2(0.4, pole * 0.6), "%d m" % pole, ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(Vector2(shadow * 0.5, -1.0), "%d m" % shadow, ProblemGen.COL_DIM, 24),
		ProblemGen.label(Vector2(9.5, tree * 0.6), "x", ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(Vector2(9 + tree_shadow * 0.6, -1.0), "%d m" % tree_shadow,
			ProblemGen.COL_DIM, 24),
		ProblemGen.label(sun, "太陽", ProblemGen.COL_DIM, 24),
	]}
	return {
		"q": "同じ時刻に、%d m の棒の影の長さは %d m でした。このとき影の長さが %d m の木の高さ x は何 m ですか。" % [
			pole, shadow, tree_shadow],
		"answer": tree, "unit": "m",
		"hint1": "太陽の光は平行だから、棒と影でできる三角形と、木と影でできる三角形は同じ形。",
		"hint2": "高さ:影 = %d:%d。x = %d × %d ÷ %d" % [pole, shadow, tree_shadow, pole, shadow],
		"expl": "高さ:影 = %d:%d なので x = %s m です。" % [pole, shadow, ProblemGen.fmt(tree)],
		"fig": fig3,
	}


## e21-台形: 対角線の交点で分かれる長さ
static func _e21_trapezoid(rng: RandomNumberGenerator) -> Dictionary:
	var k := rng.randi_range(2, 4)
	var ad := rng.randi_range(2, 6)
	var bc := ad * k
	var diag := rng.randi_range(2, 6) * (k + 1)
	var ao := float(diag) / float(k + 1)
	var a := Vector2(-ad * 0.5, 4.5)
	var d := Vector2(ad * 0.5, 4.5)
	var b := Vector2(-bc * 0.5, -3.5)
	var c := Vector2(bc * 0.5, -3.5)
	var o := Vector2(0, 4.5 - 8.0 / float(k + 1))
	var fig := {"shapes": [
		ProblemGen.poly([a, d, c, b], ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
		ProblemGen.seg(a, c, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.seg(d, b, ProblemGen.COL_DIM, 2.5),
		ProblemGen.label(a + Vector2(-0.8, 0.5), "A"),
		ProblemGen.label(d + Vector2(0.8, 0.5), "D"),
		ProblemGen.label(b + Vector2(-0.8, -0.6), "B"),
		ProblemGen.label(c + Vector2(0.8, -0.6), "C"),
		ProblemGen.label(o + Vector2(0.8, 0.2), "O", ProblemGen.COL_YELLOW, 26),
		ProblemGen.side_label(a, d, "%d cm" % ad, 1.0, 0.8),
		ProblemGen.side_label(b, c, "%d cm" % bc, -1.0, 0.8),
		ProblemGen.side_label(a, c, "%d cm" % diag, 1.0, 0.9),
	]}
	return {
		"q": "AD と BC が平行な台形 ABCD で、AD = %d cm、BC = %d cm です。対角線 AC = %d cm のとき、対角線どうしの交点 O について AO の長さを求めなさい。" % [
			ad, bc, diag],
		"answer": ao, "unit": "cm",
		"hint1": "三角形 OAD と三角形 OCB は砂時計型の相似。相似比は AD:BC だよ。",
		"hint2": "AO:OC = %d:%d なので AO = %d × %d ÷ %d" % [ad, bc, diag, ad, ad + bc],
		"expl": "AO:OC = %d:%d。AO = %d × %d/%d = %s cm です。" % [
			ad, bc, diag, ad, ad + bc, ProblemGen.fmt(ao)],
		"fig": fig,
	}


# =========================================================
# j13: 角錐と円錐(体積・表面積・展開図)
# =========================================================

static func _j13(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		# 正四角錐の体積
		var a := rng.randi_range(3, 10)
		var h := rng.randi_range(1, 4) * 3      # 高さを 3 の倍数にして体積を整数にする
		var vol := float(a * a * h) / 3.0
		var shapes: Array = _pyramid(float(a), float(h))
		shapes += [
			ProblemGen.seg(ProblemGen.proj3(Vector3(0, 0, 0)), ProblemGen.proj3(Vector3(0, 0, h)),
				ProblemGen.COL_YELLOW, 2.5, true),
			_edge_label(Vector3(0, 0, 0), Vector3(0, 0, h), "%d" % h, Vector2(0.9, 0)),
			_edge_label(Vector3(-a * 0.5, -a * 0.5, 0), Vector3(a * 0.5, -a * 0.5, 0),
				"%d" % a, Vector2(0, -1.0)),
		]
		var steps13 := [
			{"say": "まず 底面の 広さを 出す。1 辺 %d の 正方形 なので %d cm²。" % [a, a * a]},
			{"say": "同じ 底面・同じ 高さの 角柱に 入れると、角錐は ちょうど その 3 分の 1。"},
			{"say": "体積 = %d × %d ÷ 3 = %s cm³。入力してみよう!" % [
				a * a, h, ProblemGen.fmt(vol)]},
		]
		return {
			"q": "底面が 1 辺 %d cm の正方形、高さが %d cm の正四角錐の体積を求めなさい。" % [a, h],
			"answer": vol, "unit": "cm³",
			"steps": steps13,
			"hint1": "角錐の体積は 底面積 × 高さ ÷ 3。同じ底面と高さの角柱の 3 分の 1 だよ。",
			"hint2": "%d × %d × %d ÷ 3" % [a, a, h],
			"expl": "底面積 %d cm²。体積 = %d × %d ÷ 3 = %s cm³ です。" % [
				a * a, a * a, h, ProblemGen.fmt(vol)],
			"fig": {"shapes": shapes},
		}
	if kind == 1:
		# 円錐の体積
		var r := rng.randi_range(2, 8)
		var h2 := rng.randi_range(1, 5) * 3
		var vol2 := 3.14 * r * r * h2 / 3.0
		var shapes2: Array = _cone(float(r), float(h2))
		shapes2 += [
			ProblemGen.seg(ProblemGen.proj3(Vector3(0, 0, 0)), ProblemGen.proj3(Vector3(0, 0, h2)),
				ProblemGen.COL_YELLOW, 2.5, true),
			ProblemGen.seg(ProblemGen.proj3(Vector3(0, 0, 0)), ProblemGen.proj3(Vector3(r, 0, 0)),
				ProblemGen.COL_YELLOW, 2.5),
			_edge_label(Vector3(0, 0, 0), Vector3(0, 0, h2), "%d" % h2, Vector2(-1.1, 0)),
			_edge_label(Vector3(0, 0, 0), Vector3(r, 0, 0), "%d" % r, Vector2(0, -1.0)),
		]
		return {
			"q": "底面の半径 %d cm、高さ %d cm の円錐の体積を求めなさい。円周率は 3.14 とします。" % [r, h2],
			"answer": vol2, "unit": "cm³", "tol": 0.02,
			"hint1": "円錐の体積も 底面積 × 高さ ÷ 3。",
			"hint2": "%d × %d × 3.14 × %d ÷ 3" % [r, r, h2],
			"expl": "底面積 %s cm²。体積 = %s cm³ です。" % [
				ProblemGen.fmt(3.14 * r * r), ProblemGen.fmt(vol2)],
			"fig": {"shapes": shapes2},
		}
	# kind 2: 展開図の側面のおうぎ形の中心角
	var s: Array = CONE_SETS[rng.randi_range(0, CONE_SETS.size() - 1)]
	var r3: int = s[0]
	var l: int = s[1]
	var ang: int = s[2]
	var sector_r := float(l) * 0.8
	var fig3 := {"shapes": [
		ProblemGen.sector(Vector2(0, 0), sector_r, 0.0, float(ang), ProblemGen.FILL_ACCENT,
			ProblemGen.COL_YELLOW),
		ProblemGen.ang(Vector2.ZERO, Vector2(sector_r, 0),
			Vector2(cos(deg_to_rad(float(ang))), sin(deg_to_rad(float(ang)))) * sector_r,
			"x", 1.6, ang > 180),
		ProblemGen.seg(Vector2.ZERO, Vector2(sector_r, 0), ProblemGen.COL_YELLOW, 2.5),
		ProblemGen.label(Vector2(sector_r * 0.5, -0.9), "母線 %d cm" % l, ProblemGen.COL_DIM, 24),
		ProblemGen.circle(Vector2(sector_r + float(r3) * 0.8 + 2.0, -2.0), float(r3) * 0.8, null,
			Color(0.92, 0.95, 1.0), 2.5),
		ProblemGen.label(Vector2(sector_r + float(r3) * 0.8 + 2.0, -float(r3) * 0.8 - 3.0),
			"底面 半径 %d cm" % r3, ProblemGen.COL_DIM, 24),
	]}
	return {
		"q": "底面の半径 %d cm、母線の長さ %d cm の円錐の展開図で、側面のおうぎ形の中心角 x を求めなさい。" % [r3, l],
		"answer": float(ang), "unit": "度",
		"hint1": "おうぎ形の弧の長さと、底面の円周は同じ長さになるよ。",
		"hint2": "中心角 = 360 × (底面の半径 ÷ 母線) = 360 × %d ÷ %d" % [r3, l],
		"expl": "中心角 = 360 × %d/%d = %d° です。" % [r3, l, ang],
		"fig": fig3,
	}


## j13-表面積: 円錐の表面積と球の表面積・体積
static func _j13_surface(rng: RandomNumberGenerator) -> Dictionary:
	if rng.randf() < 0.6:
		var s: Array = CONE_SETS[rng.randi_range(0, CONE_SETS.size() - 1)]
		var r: int = s[0]
		var l: int = s[1]
		var area := 3.14 * float(r) * float(r + l)
		var shapes: Array = _cone(float(r), sqrt(maxf(1.0, float(l * l - r * r))))
		shapes += [
			ProblemGen.seg(ProblemGen.proj3(Vector3(0, 0, 0)), ProblemGen.proj3(Vector3(r, 0, 0)),
				ProblemGen.COL_YELLOW, 2.5),
			_edge_label(Vector3(0, 0, 0), Vector3(r, 0, 0), "%d" % r, Vector2(0, -1.0)),
			ProblemGen.label(Vector2(float(r) * 0.55, float(l) * 0.45), "母線 %d" % l,
				ProblemGen.COL_YELLOW, 26),
		]
		return {
			"q": "底面の半径 %d cm、母線の長さ %d cm の円錐の表面積を求めなさい。円周率は 3.14 とします。" % [r, l],
			"answer": area, "unit": "cm²", "tol": 0.02,
			"hint1": "底面の円と、側面のおうぎ形をたす。側面積は 3.14 × 半径 × 母線 で出せるよ。",
			"hint2": "3.14 × %d × %d + 3.14 × %d × %d" % [r, r, r, l],
			"expl": "底面 %s + 側面 %s = %s cm² です。" % [
				ProblemGen.fmt(3.14 * r * r), ProblemGen.fmt(3.14 * r * l), ProblemGen.fmt(area)],
			"fig": {"shapes": shapes},
		}
	var r2 := rng.randi_range(2, 9)
	var ask_area := rng.randf() < 0.5
	var fig := {"shapes": [
		ProblemGen.circle(Vector2.ZERO, float(r2), ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
		ProblemGen.curve(_ring(float(r2), 0.0), ProblemGen.COL_DIM, 2.0),
		ProblemGen.seg(Vector2.ZERO, Vector2(r2, 0), ProblemGen.COL_YELLOW, 2.5),
		ProblemGen.label(Vector2(float(r2) * 0.5, -0.9), "%d" % r2, ProblemGen.COL_YELLOW, 26),
	]}
	if ask_area:
		var sa := 4.0 * 3.14 * r2 * r2
		return {
			"q": "半径 %d cm の球の表面積を求めなさい。円周率は 3.14 とします。" % r2,
			"answer": sa, "unit": "cm²", "tol": 0.02,
			"hint1": "球の表面積は 4 × 3.14 × 半径 × 半径。",
			"hint2": "4 × 3.14 × %d" % (r2 * r2),
			"expl": "表面積 = 4 × 3.14 × %d = %s cm² です。" % [r2 * r2, ProblemGen.fmt(sa)],
			"fig": fig,
		}
	var vol := 4.0 / 3.0 * 3.14 * r2 * r2 * r2
	return {
		"q": "半径 %d cm の球の体積を求めなさい。円周率は 3.14 とします。" % r2,
		"answer": vol, "unit": "cm³", "tol": 0.05,
		"hint1": "球の体積は 4 ÷ 3 × 3.14 × 半径を 3 回かけたもの。",
		"hint2": "4 ÷ 3 × 3.14 × %d" % (r2 * r2 * r2),
		"expl": "体積 = 4/3 × 3.14 × %d = %s cm³ です。" % [r2 * r2 * r2, ProblemGen.fmt(vol)],
		"fig": fig,
	}


# =========================================================
# j14: 空間の三平方(対角線・最短経路)
# =========================================================

static func _j14(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		var s: Array = DIAG_SETS[rng.randi_range(0, DIAG_SETS.size() - 1)]
		var a: int = s[0]
		var b: int = s[1]
		var c: int = s[2]
		var diag: int = s[3]
		var shapes: Array = _box(float(a), float(b), float(c))
		shapes += [
			ProblemGen.seg(ProblemGen.proj3(Vector3(0, 0, 0)), ProblemGen.proj3(Vector3(a, b, c)),
				ProblemGen.COL_YELLOW, 3.5),
			ProblemGen.seg(ProblemGen.proj3(Vector3(0, 0, 0)), ProblemGen.proj3(Vector3(a, b, 0)),
				Color(0.55, 0.85, 1.0), 2.5, true),
			_edge_label(Vector3(0, 0, 0), Vector3(a, 0, 0), "%d" % a, Vector2(0, -1.0)),
			_edge_label(Vector3(a, 0, 0), Vector3(a, b, 0), "%d" % b, Vector2(0.9, -0.7)),
			_edge_label(Vector3(a, b, 0), Vector3(a, b, c), "%d" % c, Vector2(1.2, 0)),
		]
		var steps14 := [
			{"say": "まず 底面の 対角線。三平方で √(%d² + %d²) = √%d。" % [a, b, a * a + b * b],
				"add": [ProblemGen.seg(ProblemGen.proj3(Vector3(0, 0, 0)),
					ProblemGen.proj3(Vector3(a, b, 0)), Color(1.0, 0.85, 0.3, 0.95), 4.0)]},
			{"say": "その 対角線と 高さ %d で、もう一度 三平方(立てた 直角三角形)。" % c,
				"add": [ProblemGen.seg(ProblemGen.proj3(Vector3(a, b, 0)),
						ProblemGen.proj3(Vector3(a, b, c)), Color(0.45, 1.0, 0.6, 0.95), 4.0),
					ProblemGen.seg(ProblemGen.proj3(Vector3(0, 0, 0)),
						ProblemGen.proj3(Vector3(a, b, c)), Color(0.45, 1.0, 0.6, 0.95), 4.0)]},
			{"say": "対角線 = √(%d + %d + %d) = %d cm。入力してみよう!" % [
				a * a, b * b, c * c, diag]},
		]
		return {
			"q": "たて %d cm、よこ %d cm、高さ %d cm の直方体の対角線の長さを求めなさい。" % [b, a, c],
			"answer": float(diag), "unit": "cm",
			"steps": steps14,
			"hint1": "まず底面の対角線を三平方で出して、それと高さでもう一度三平方を使おう。",
			"hint2": "対角線 = √(%d + %d + %d)" % [a * a, b * b, c * c],
			"expl": "対角線 = √(%d² + %d² + %d²) = √%d = %d cm です。" % [
				a, b, c, a * a + b * b + c * c, diag],
			"fig": {"shapes": shapes},
		}
	if kind == 1:
		var tri: Array = SHORT_SETS[rng.randi_range(0, SHORT_SETS.size() - 1)]
		var sum_ab: int = tri[0]
		var c2: int = tri[1]
		var ans: int = tri[2]
		var a2 := rng.randi_range(1, sum_ab - 1)
		var b2 := sum_ab - a2
		# 展開したときに折り目を通る高さ。ここを通るのが最短になる
		var cross_z := float(c2) * float(a2) / float(sum_ab)
		var shapes2: Array = _box(float(a2), float(b2), float(c2))
		shapes2 += [
			ProblemGen.seg(ProblemGen.proj3(Vector3(0, 0, 0)),
				ProblemGen.proj3(Vector3(a2, 0, cross_z)), ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.seg(ProblemGen.proj3(Vector3(a2, 0, cross_z)),
				ProblemGen.proj3(Vector3(a2, b2, c2)), ProblemGen.COL_YELLOW, 3.0),
			_edge_label(Vector3(0, 0, 0), Vector3(a2, 0, 0), "%d" % a2, Vector2(0, -1.0)),
			_edge_label(Vector3(a2, 0, 0), Vector3(a2, b2, 0), "%d" % b2, Vector2(0.9, -0.7)),
			_edge_label(Vector3(a2, b2, 0), Vector3(a2, b2, c2), "%d" % c2, Vector2(1.2, 0)),
		]
		return {
			"q": "たて %d cm、よこ %d cm、高さ %d cm の直方体があります。ある頂点から、いちばん遠い頂点まで表面をはって進むときの最短の道のりを求めなさい。" % [
				b2, a2, c2],
			"answer": float(ans), "unit": "cm",
			"hint1": "立体のままでは分からない。となり合う 2 つの面をひらいて 1 枚の長方形にしてみよう。",
			"hint2": "ひらくと たて %d、よこ %d の長方形。その対角線が答え。" % [c2, a2 + b2],
			"expl": "展開すると %d と %d の直角三角形。最短は √(%d + %d) = %d cm です。" % [
				a2 + b2, c2, (a2 + b2) * (a2 + b2), c2 * c2, ans],
			"fig": {"shapes": shapes2},
		}
	var a3 := rng.randi_range(2, 10)
	var face := rng.randf() < 0.5
	var val := float(a3) * 1.73
	if face:
		val = float(a3) * 1.41
	var to := Vector3(a3, a3, a3)
	if face:
		to = Vector3(a3, a3, 0)
	var shapes3: Array = _box(float(a3), float(a3), float(a3))
	shapes3 += [
		ProblemGen.seg(ProblemGen.proj3(Vector3.ZERO), ProblemGen.proj3(to),
			ProblemGen.COL_YELLOW, 3.5),
		_edge_label(Vector3(0, 0, 0), Vector3(a3, 0, 0), "%d" % a3, Vector2(0, -1.0)),
	]
	var what := "立方体の対角線"
	var root := "√3"
	var root_val := "1.73"
	if face:
		what = "1 つの面の対角線"
		root = "√2"
		root_val = "1.41"
	return {
		"q": "1 辺 %d cm の立方体で、%s の長さを求めなさい。%s = %s とします。" % [
			a3, what, root, root_val],
		"answer": val, "unit": "cm", "tol": 0.05,
		"hint1": "面の対角線は 1 辺 × √2、立方体の対角線は 1 辺 × √3 になるよ。",
		"hint2": "%d × %s" % [a3, root_val],
		"expl": "%s = %d × %s = %s cm です。" % [what, a3, root, ProblemGen.fmt(val)],
		"fig": {"shapes": shapes3},
	}


# =========================================================
# j15: 平行線と線分の比
# =========================================================

static func _j15(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	var a := Vector2(3.5, 9.0)
	var b := Vector2(0, 0)
	var c := Vector2(11.0, 0)
	if kind == 0:
		# DE と BC が平行。AD:DB から AE:EC へ
		var m := rng.randi_range(2, 6)
		var n := rng.randi_range(2, 6)
		var ae := rng.randi_range(2, 6) * m
		var ec := ae * n / m
		var d := a + (b - a) * (float(m) / float(m + n))
		var e := a + (c - a) * (float(m) / float(m + n))
		var fig := {"shapes": [
			ProblemGen.poly([a, b, c], ProblemGen.FILL_MAIN),
			ProblemGen.seg(d, e, ProblemGen.COL_YELLOW, 3.5),
			ProblemGen.label(a + Vector2(0, 0.9), "A"),
			ProblemGen.label(b + Vector2(-0.8, -0.6), "B"),
			ProblemGen.label(c + Vector2(0.8, -0.6), "C"),
			ProblemGen.label(d + Vector2(-0.9, 0), "D", ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(e + Vector2(0.9, 0), "E", ProblemGen.COL_YELLOW, 26),
			ProblemGen.side_label(a, d, "%d" % m, -1.0, 0.8),
			ProblemGen.side_label(d, b, "%d" % n, -1.0, 0.8),
			ProblemGen.side_label(a, e, "%d cm" % ae, 1.0, 0.8),
			ProblemGen.side_label(e, c, "x", 1.0, 0.8),
		]}
		var steps15 := [
			{"say": "DE と BC が 平行だから、三角形 ADE と 三角形 ABC は 同じ かたち(相似)。",
				"add": [ProblemGen.poly([a, d, e], Color(1.0, 0.85, 0.3, 0.22),
					Color(1.0, 0.85, 0.3, 0.9), 3.0)]},
			{"say": "だから 2 つの 辺は 同じ 比に 分かれる ― AD:DB = AE:EC = %d:%d。" % [m, n]},
			{"say": "%d:%d = %d:x なので x = %d × %d ÷ %d = %d cm。入力してみよう!" % [
				m, n, ae, ae, n, m, ec]},
		]
		return {
			"q": "三角形 ABC で DE と BC が平行です。AD:DB = %d:%d、AE = %d cm のとき、EC の長さ x を求めなさい。" % [
				m, n, ae],
			"answer": float(ec), "unit": "cm",
			"steps": steps15,
			"hint1": "平行な線で切ると、2 つの辺は同じ比に分かれる(AD:DB = AE:EC)。",
			"hint2": "%d:%d = %d:x を解こう。" % [m, n, ae],
			"expl": "AE:EC = %d:%d なので x = %d × %d ÷ %d = %d cm です。" % [m, n, ae, n, m, ec],
			"fig": fig,
		}
	if kind == 1:
		# 3 本の平行線に 2 本の直線が交わる
		var p := rng.randi_range(2, 8)
		var q := rng.randi_range(2, 8)
		var r := rng.randi_range(2, 6) * p
		var x := r * q / p
		var y0 := 0.0
		var y1 := -4.0
		var y2 := -4.0 - 4.0 * float(q) / float(p)
		var fig2 := {"shapes": [
			ProblemGen.seg(Vector2(-6, y0), Vector2(6, y0), Color(0.92, 0.95, 1.0), 2.5),
			ProblemGen.seg(Vector2(-6, y1), Vector2(6, y1), Color(0.92, 0.95, 1.0), 2.5),
			ProblemGen.seg(Vector2(-6, y2), Vector2(6, y2), Color(0.92, 0.95, 1.0), 2.5),
			ProblemGen.seg(Vector2(-4.5, y0 + 1.0), Vector2(-1.5, y2 - 1.0), ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.seg(Vector2(2.0, y0 + 1.0), Vector2(4.5, y2 - 1.0),
				Color(0.55, 0.85, 1.0), 3.0),
			ProblemGen.label(Vector2(-5.0, (y0 + y1) * 0.5), "%d" % p, ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(Vector2(-5.0, (y1 + y2) * 0.5), "%d" % q, ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(Vector2(5.0, (y0 + y1) * 0.5), "%d cm" % r, Color(0.55, 0.85, 1.0), 26),
			ProblemGen.label(Vector2(5.0, (y1 + y2) * 0.5), "x", Color(0.55, 0.85, 1.0), 26),
		]}
		return {
			"q": "3 本の平行な直線に 2 本の直線が交わっています。左の直線が %d cm と %d cm に切られるとき、右の直線の上の部分は %d cm でした。下の部分 x を求めなさい。" % [
				p, q, r],
			"answer": float(x), "unit": "cm",
			"hint1": "平行線にはさまれた線分の比は、どちらの直線でも同じになるよ。",
			"hint2": "%d:%d = %d:x" % [p, q, r],
			"expl": "%d:%d = %d:x なので x = %d × %d ÷ %d = %d cm です。" % [p, q, r, r, q, p, x],
			"fig": fig2,
		}
	# kind 2: 台形の対角線の交点を通り、底辺に平行な線分
	var sets: Array = [[6, 12, 8], [4, 12, 6], [3, 6, 4], [10, 15, 12], [6, 3, 4],
		[12, 4, 6], [8, 8, 8], [5, 20, 8], [9, 18, 12], [2, 6, 3]]
	var s2: Array = sets[rng.randi_range(0, sets.size() - 1)]
	var ad: int = s2[0]
	var bc: int = s2[1]
	var ef: int = s2[2]
	var ax := Vector2(-ad * 0.4, 4.0)
	var dx := Vector2(ad * 0.4, 4.0)
	var bx := Vector2(-bc * 0.4, -4.0)
	var cx := Vector2(bc * 0.4, -4.0)
	var oy := 4.0 - 8.0 * float(ad) / float(ad + bc)
	var fig3 := {"shapes": [
		ProblemGen.poly([ax, dx, cx, bx], ProblemGen.FILL_MAIN, Color.WHITE, 3.0),
		ProblemGen.seg(ax, cx, ProblemGen.COL_DIM, 2.0),
		ProblemGen.seg(dx, bx, ProblemGen.COL_DIM, 2.0),
		ProblemGen.seg(Vector2(-ef * 0.4, oy), Vector2(ef * 0.4, oy), ProblemGen.COL_YELLOW, 3.5),
		ProblemGen.label(ax + Vector2(-0.8, 0.5), "A"),
		ProblemGen.label(dx + Vector2(0.8, 0.5), "D"),
		ProblemGen.label(bx + Vector2(-0.8, -0.6), "B"),
		ProblemGen.label(cx + Vector2(0.8, -0.6), "C"),
		ProblemGen.side_label(ax, dx, "%d cm" % ad, 1.0, 0.8),
		ProblemGen.side_label(bx, cx, "%d cm" % bc, -1.0, 0.8),
		ProblemGen.label(Vector2(ef * 0.4 + 1.2, oy), "x", ProblemGen.COL_YELLOW, 26),
	]}
	return {
		"q": "AD と BC が平行な台形 ABCD で、AD = %d cm、BC = %d cm です。対角線の交点を通り BC に平行な線分の長さ x を求めなさい。" % [
			ad, bc],
		"answer": float(ef), "unit": "cm",
		"hint1": "交点は対角線を AD:BC に分ける。三角形の相似を 2 回使おう。",
		"hint2": "x = 2 × %d × %d ÷ (%d + %d)" % [ad, bc, ad, bc],
		"expl": "x = 2 × %d × %d ÷ %d = %d cm です(2 つの底辺の調和平均)。" % [
			ad, bc, ad + bc, ef],
		"fig": fig3,
	}


## j15-中点連結: 中点を結んでできる線分と、四角形の中点四角形
static func _j15_mid(rng: RandomNumberGenerator) -> Dictionary:
	if rng.randf() < 0.5:
		var bc := rng.randi_range(2, 12) * 2
		var a := Vector2(3.0, 8.0)
		var b := Vector2(0, 0)
		var c := Vector2(float(bc) * 0.7, 0)
		var m := (a + b) * 0.5
		var n := (a + c) * 0.5
		var fig := {"shapes": [
			ProblemGen.poly([a, b, c], ProblemGen.FILL_MAIN),
			ProblemGen.seg(m, n, ProblemGen.COL_YELLOW, 3.5),
			ProblemGen.tick(a, m, 1), ProblemGen.tick(m, b, 1),
			ProblemGen.tick(a, n, 2), ProblemGen.tick(n, c, 2),
			ProblemGen.label(a + Vector2(0, 0.9), "A"),
			ProblemGen.label(b + Vector2(-0.8, -0.6), "B"),
			ProblemGen.label(c + Vector2(0.8, -0.6), "C"),
			ProblemGen.label(m + Vector2(-0.9, 0), "M", ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(n + Vector2(0.9, 0), "N", ProblemGen.COL_YELLOW, 26),
			ProblemGen.side_label(b, c, "%d cm" % bc, -1.0, 0.9),
		]}
		return {
			"q": "三角形 ABC で、辺 AB の中点を M、辺 AC の中点を N とします。BC = %d cm のとき MN の長さを求めなさい。" % bc,
			"answer": float(bc) * 0.5, "unit": "cm",
			"hint1": "中点どうしを結んだ線分は、残りの辺と平行で長さは半分(中点連結定理)。",
			"hint2": "MN = %d ÷ 2" % bc,
			"expl": "MN = BC ÷ 2 = %s cm です。" % ProblemGen.fmt(bc * 0.5),
			"fig": fig,
		}
	var d1 := rng.randi_range(4, 16)
	var d2 := rng.randi_range(4, 16)
	var quad: Array = [Vector2(-4.5, 1.0), Vector2(-0.5, 5.5), Vector2(5.0, 0.5), Vector2(0.0, -4.5)]
	var mids: Array = []
	for i in 4:
		mids.append(((quad[i] as Vector2) + (quad[(i + 1) % 4] as Vector2)) * 0.5)
	var fig2 := {"shapes": [
		ProblemGen.poly(quad, null, Color.WHITE, 3.0),
		ProblemGen.poly(mids, ProblemGen.FILL_ACCENT, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.seg(quad[0], quad[2], ProblemGen.COL_DIM, 2.0, true),
		ProblemGen.seg(quad[1], quad[3], ProblemGen.COL_DIM, 2.0, true),
		ProblemGen.label((quad[0] as Vector2) + Vector2(-0.8, 0), "A"),
		ProblemGen.label((quad[1] as Vector2) + Vector2(0, 0.9), "B"),
		ProblemGen.label((quad[2] as Vector2) + Vector2(0.8, 0), "C"),
		ProblemGen.label((quad[3] as Vector2) + Vector2(0, -0.9), "D"),
	]}
	return {
		"q": "四角形 ABCD の各辺の中点を結ぶと平行四辺形ができます。対角線 AC = %d cm、BD = %d cm のとき、この平行四辺形の周の長さを求めなさい。" % [
			d1, d2],
		"answer": float(d1 + d2), "unit": "cm",
		"hint1": "中点連結定理を 4 回使おう。向かい合う辺はどちらかの対角線の半分になるよ。",
		"hint2": "周 = (%d ÷ 2) × 2 + (%d ÷ 2) × 2" % [d1, d2],
		"expl": "各辺は対角線の半分。周 = %d + %d = %d cm(対角線の和)です。" % [d1, d2, d1 + d2],
		"fig": fig2,
	}


# =========================================================
# j16: 相似比と体積比
# =========================================================

static func _j16(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		var m := rng.randi_range(1, 4)
		var n := m + rng.randi_range(1, 3)
		var small := rng.randi_range(1, 6) * m * m * m
		var big := small * n * n * n / (m * m * m)
		var shapes: Array = _box(3.0, 2.0, 2.5)
		var k := float(n) / float(m)
		shapes += _box(3.0 * k, 2.0 * k, 2.5 * k, ProblemGen.COL_YELLOW)
		var steps16 := [
			{"say": "長さの 比が %d:%d の とき、たて・よこ・高さ の 3 つとも その 比に なる。" % [m, n]},
			{"say": "だから 体積は %d × %d × %d と %d × %d × %d の 比 ― %d : %d。" % [
				m, m, m, n, n, n, m * m * m, n * n * n]},
			{"say": "%d × %d ÷ %d = %d cm³。入力してみよう!" % [
				small, n * n * n, m * m * m, big]},
		]
		return {
			"q": "相似比が %d:%d の 2 つの立体があります。小さい方の体積が %d cm³ のとき、大きい方の体積を求めなさい。" % [
				m, n, small],
			"answer": float(big), "unit": "cm³",
			"steps": steps16,
			"hint1": "長さが k 倍になると、体積は k を 3 回かけた分だけ大きくなるよ。",
			"hint2": "体積比 = %d:%d。%d × %d ÷ %d" % [m * m * m, n * n * n, small, n * n * n, m * m * m],
			"expl": "体積比は %d:%d なので %d cm³ です。" % [m * m * m, n * n * n, big],
			"fig": {"shapes": shapes},
		}
	if kind == 1:
		# 円錐を高さの途中で切る
		var part := rng.randi_range(1, 3)
		var whole := part + rng.randi_range(1, 3)
		var total := rng.randi_range(1, 6) * whole * whole * whole
		var upper := total * part * part * part / (whole * whole * whole)
		var r := 5.0
		var h := 7.0
		var ratio := float(part) / float(whole)
		var shapes2: Array = _cone(r, h)
		shapes2 += [
			ProblemGen.curve(_ring(r * ratio, h * (1.0 - ratio)), ProblemGen.COL_YELLOW, 3.0),
			_edge_label(Vector3(0, 0, 0), Vector3(0, 0, h), "%d" % whole, Vector2(-1.2, 0)),
			_edge_label(Vector3(0, 0, h * (1.0 - ratio)), Vector3(0, 0, h), "%d" % part,
				Vector2(1.2, 0)),
		]
		return {
			"q": "円錐を、頂点から測って高さの %d 分の %d のところで底面と平行に切ります。もとの円錐の体積が %d cm³ のとき、切り取った小さい円錐の体積を求めなさい。" % [
				whole, part, total],
			"answer": float(upper), "unit": "cm³",
			"hint1": "小さい円錐ともとの円錐は相似。相似比は高さの比そのままだよ。",
			"hint2": "体積比 = %d:%d。%d × %d ÷ %d" % [
				part * part * part, whole * whole * whole, total, part * part * part,
				whole * whole * whole],
			"expl": "相似比 %d:%d → 体積比 %d:%d。答えは %d cm³ です。" % [
				part, whole, part * part * part, whole * whole * whole, upper],
			"fig": {"shapes": shapes2},
		}
	# kind 2: 表面積比
	var m2 := rng.randi_range(1, 4)
	var n2 := m2 + rng.randi_range(1, 3)
	var small2 := rng.randi_range(1, 8) * m2 * m2
	var big2 := small2 * n2 * n2 / (m2 * m2)
	var shapes3: Array = _box(3.0, 2.0, 2.5)
	shapes3 += _box(3.0 * float(n2) / float(m2), 2.0 * float(n2) / float(m2),
		2.5 * float(n2) / float(m2), ProblemGen.COL_YELLOW)
	return {
		"q": "相似比が %d:%d の 2 つの立体があります。小さい方の表面積が %d cm² のとき、大きい方の表面積を求めなさい。" % [
			m2, n2, small2],
		"answer": float(big2), "unit": "cm²",
		"hint1": "表面積は面の集まりなので、長さが k 倍なら k × k 倍になるよ。",
		"hint2": "表面積比 = %d:%d" % [m2 * m2, n2 * n2],
		"expl": "表面積比は %d:%d なので %d cm² です。" % [m2 * m2, n2 * n2, big2],
		"fig": {"shapes": shapes3},
	}


## j16-水: 円錐の容器に入れた水の深さと体積
static func _j16_water(rng: RandomNumberGenerator) -> Dictionary:
	var part := rng.randi_range(1, 3)
	var whole := part + rng.randi_range(1, 3)
	var total := rng.randi_range(1, 8) * whole * whole * whole
	var water := total * part * part * part / (whole * whole * whole)
	var r := 5.0
	var h := 7.0
	var ratio := float(part) / float(whole)
	var shapes: Array = _cone(r, h)
	shapes += [
		ProblemGen.curve(_ring(r * ratio, h * (1.0 - ratio)), Color(0.55, 0.85, 1.0), 3.0),
		ProblemGen.poly([ProblemGen.proj3(Vector3(-r * ratio, 0, h * (1.0 - ratio))),
			ProblemGen.proj3(Vector3(r * ratio, 0, h * (1.0 - ratio))),
			ProblemGen.proj3(Vector3(0, 0, h))], Color(0.3, 0.6, 0.95, 0.3), null, 0.0),
		_edge_label(Vector3(0, 0, h * (1.0 - ratio)), Vector3(0, 0, h), "%d" % part, Vector2(1.2, 0)),
		_edge_label(Vector3(0, 0, 0), Vector3(0, 0, h), "%d" % whole, Vector2(-1.2, 0)),
	]
	return {
		"q": "頂点を下にした円錐の容器があります。容器いっぱいで %d cm³ 入ります。水の深さが容器の深さの %d 分の %d のとき、水の体積を求めなさい。" % [
			total, whole, part],
		"answer": float(water), "unit": "cm³",
		"hint1": "水の部分ともとの容器は相似。深さの比がそのまま相似比になるよ。",
		"hint2": "体積比 = %d:%d。%d × %d ÷ %d" % [
			part * part * part, whole * whole * whole, total, part * part * part,
			whole * whole * whole],
		"expl": "深さの比 %d:%d → 体積比 %d:%d。水は %d cm³ です。" % [
			part, whole, part * part * part, whole * whole * whole, water],
		"fig": {"shapes": shapes},
	}
