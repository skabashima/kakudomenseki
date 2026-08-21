class_name StoryDefs
## 発見モード(物語)。図形の「動かしても変わらない量」を自分で見つけていく筋書き。
##
## ■ 本編と何が違うか
## 本編(problem.tscn)は「図が出る → 公式を使って値を答える」。
## ここは逆で、**公式を知らないところから、図を動かして、変わらないものを見つける**。
## 動詞が違うので、同じ単元でも遊びが重ならない。
##
## 判定は選択肢だが、**自分で何度か動かして記録するまで選択肢が開かない**。
## 角度は図の座標から計算して出しているので、当てずっぽうでは進めない。
##
## シーンの種類:
##   talk    … 会話。art があれば挿絵、fig があれば図を上に出す
##   measure … 図の点を指で動かして記録し、「何が一定か」を選ぶ
##   solve   … 見つけたことを使って、本編と同じ生成器の問題を 1 問解く(4択)
##
## 章を足すときは CHAPTERS に足す。measure の図は _spec_* を新しく書く。

const CHAPTERS := [
	{
		"id": "ch1",
		"title": "三角形の秘密",
		"place": "ギリシャ、紀元前300年ごろ",
		"intro": "三角形の角を全部たすと、いつも同じ数になる ― 本当だろうか。",
		"scenes": [
			{
				"type": "talk",
				"title": "測量師の見習い",
				"art": "field",
				"lines": [
					"あなたは土地を測る仕事の見習いだ。畑の形はどれも三角形をしている。",
					"親方が言う。「三角形の 3 つの角を全部たすと、いつも同じ数になる」",
					"「どんな三角形でもですか」と聞くと、親方は笑って砂に三角形を描いた。",
					"「自分で確かめてみろ。それが測量師の仕事だ」",
				],
			},
			{
				"type": "measure",
				"title": "頂点を動かしてみる",
				"lead": "三角形の上の頂点(金色の点)を指で動かすと、3 つの角が変わる。"
					+ "形をいくつか作って、そのたびに「この形を記録する」を押そう。",
				"fig": "triangle",
				"trials": 3,
				"question": "頂点を動かすと、3 つの角の和はどうなった?",
				"choices": [
					"とがった三角形ほど、和は小さくなった",
					"どんな形にしても、和は 180° のままだった",
					"大きい三角形ほど、和は大きくなった",
				],
				"answer": 1,
				"after": "どう動かしても和は 180°。これが三角形の決まりごとだ。",
			},
			{
				"type": "talk",
				"title": "なぜ 180° なのか",
				"fig": "parallel",
				"lines": [
					"親方が、頂点 A を通って底辺と平行な線を引いた。",
					"「錯角は等しい。だから左の角は ∠B と同じ、右の角は ∠C と同じだ」",
					"平行線の上で、3 つの角がぴったり一直線に並んだ。",
					"一直線は 180°。だから三角形の内角の和は 180° になる。",
				],
			},
			{
				"type": "solve",
				"title": "畑の角を求める",
				"lead": "見つけたことを使ってみよう。",
				"stage": "e1",
				"tier": 1,
				"after": "測量師として一人前に近づいた。",
			},
			{
				"type": "talk",
				"title": "次の謎へ",
				"art": "dusk",
				"lines": [
					"「では四角形は?」あなたは砂に四角形を描いてみる。",
					"対角線を 1 本引くと、三角形が 2 つ。ということは 180° が 2 つぶん ―",
					"数えてみたくなる。だが日は暮れかけている。確かめるのは次の機会に。",
					"変わらないものを見つける。それが図形をあばく第一歩だ。",
				],
			},
		],
	},
]


static func chapter_by_id(id: String) -> Dictionary:
	for c in CHAPTERS:
		if String(c["id"]) == id:
			return c
	return CHAPTERS[0]


# =========================================================
# measure の図。頂点 A を動かすたびに作り直す
# =========================================================

## 底辺 BC は固定。A だけ動かせる
const TRI_B := Vector2(0.0, 0.0)
const TRI_C := Vector2(10.0, 0.0)
## A が動ける範囲(つぶれた三角形にしない)
const TRI_MIN_Y := 2.0
const TRI_MAX_Y := 9.0
const TRI_MIN_X := -4.0
const TRI_MAX_X := 14.0


## A の位置を動ける範囲に収める
static func clamp_apex(a: Vector2) -> Vector2:
	return Vector2(clampf(a.x, TRI_MIN_X, TRI_MAX_X), clampf(a.y, TRI_MIN_Y, TRI_MAX_Y))


## 三角形の 3 つの角(度)を座標から計算する [∠A, ∠B, ∠C]
static func angles_of(a: Vector2, b: Vector2, c: Vector2) -> Array:
	var ang := func(at: Vector2, p: Vector2, q: Vector2) -> float:
		var d1 := (p - at).normalized()
		var d2 := (q - at).normalized()
		return rad_to_deg(acos(clampf(d1.dot(d2), -1.0, 1.0)))
	return [ang.call(a, b, c), ang.call(b, a, c), ang.call(c, a, b)]


## 3 つの角を整数に丸める。**丸めても和が 180 になるように**誤差を分配する。
## そのまま四捨五入すると 40 + 12 + 129 = 181 のように見えて、
## 「和は 180」という発見そのものが濁ってしまうため
static func rounded_angles(deg: Array) -> Array:
	var base: Array = []
	var rest: Array = []
	var total := 0
	for i in 3:
		var f := floori(float(deg[i]))
		base.append(f)
		rest.append([float(deg[i]) - float(f), i])
		total += f
	rest.sort_custom(func(x, y): return float(x[0]) > float(y[0]))
	var lack := clampi(180 - total, 0, 3)
	for k in lack:
		base[int(rest[k][1])] += 1
	return base


## measure シーンの図。角の印と、いまの角度を書き込む
static func triangle_spec(a: Vector2) -> Dictionary:
	var deg: Array = rounded_angles(angles_of(a, TRI_B, TRI_C))
	return {"shapes": [
		ProblemGen.poly([a, TRI_B, TRI_C], ProblemGen.FILL_MAIN, Color(0.92, 0.95, 1.0), 4.0),
		ProblemGen.ang(a, TRI_B, TRI_C, "%d°" % int(deg[0]), 1.8),
		ProblemGen.ang(TRI_B, TRI_C, a, "%d°" % int(deg[1]), 1.8),
		ProblemGen.ang(TRI_C, a, TRI_B, "%d°" % int(deg[2]), 1.8),
		ProblemGen.label(a + Vector2(0.0, 0.9), "A"),
		ProblemGen.label(TRI_B + Vector2(-0.8, -0.6), "B"),
		ProblemGen.label(TRI_C + Vector2(0.8, -0.6), "C"),
	]}


## 解説シーンの図。A を通る平行線を引き、錯角に同じ印をつける
static func parallel_spec() -> Dictionary:
	var a := Vector2(4.0, 6.0)
	return {"shapes": [
		ProblemGen.poly([a, TRI_B, TRI_C], ProblemGen.FILL_MAIN, Color(0.92, 0.95, 1.0), 4.0),
		ProblemGen.seg(a + Vector2(-5.0, 0.0), a + Vector2(5.0, 0.0),
			ProblemGen.COL_YELLOW, 3.0, true),
		ProblemGen.ang(a, a + Vector2(-5.0, 0.0), TRI_B, "B と同じ", 1.6),
		ProblemGen.ang(a, TRI_C, a + Vector2(5.0, 0.0), "C と同じ", 1.6),
		ProblemGen.ang(TRI_B, TRI_C, a, "B", 1.8),
		ProblemGen.ang(TRI_C, a, TRI_B, "C", 1.8),
		ProblemGen.label(a + Vector2(0.0, 1.0), "A"),
	]}


static func spec_of(kind: String, a: Vector2) -> Dictionary:
	match kind:
		"triangle":
			return triangle_spec(a)
		"parallel":
			return parallel_spec()
	return {"shapes": []}
