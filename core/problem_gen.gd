class_name ProblemGen
## コース・ステージの定義と、問題の生成の入口。
##
## 問題は毎回パラメータを乱数で作り直す(答えの丸暗記ができない)。
## 生成される問題 Dictionary の形:
##   q      問題文
##   answer 正解(float)
##   unit   単位("度" "cm²" "cm" "" など)
##   tol    正誤判定の許容誤差(絶対値)
##   hint1  ヒント1(考え方)
##   hint2  ヒント2(ほぼ式)
##   expl   解説(まちがえたときに表示)
##   fig    図形の描画スペック(ui/figure_view.gd が描く)

## 3 コース。stages は易しい順に並び、前のステージをクリアすると次が開く
const COURSES := [
	{
		"id": "e", "name": "中学受験レベル", "sub": "小学校の図形 ― 角度と面積のきほん",
		"color": Color(0.22, 0.55, 0.35),
		"stages": [
			{"id": "e1", "title": "三角形の角", "desc": "内角の和は 180°"},
			{"id": "e2", "title": "正方形と長方形", "desc": "面積のきほん"},
			{"id": "e3", "title": "三角形の面積", "desc": "底辺 × 高さ ÷ 2"},
			{"id": "e4", "title": "平行線と角", "desc": "錯角・折れ線の角"},
			{"id": "e5", "title": "いろいろな四角形", "desc": "平行四辺形・台形・ひし形"},
			{"id": "e6", "title": "二等辺三角形", "desc": "底角は等しい"},
			{"id": "e7", "title": "多角形の角", "desc": "内角の和と正多角形"},
			{"id": "e8", "title": "円とおうぎ形", "desc": "円周率 3.14 の計算"},
			{"id": "e9", "title": "複合図形の面積", "desc": "分けて・引いて求める"},
			{"id": "e10", "title": "葉っぱ形に挑戦", "desc": "中学受験の名物問題"},
		],
	},
	{
		"id": "j", "name": "高校受験レベル", "sub": "中学数学 ― 証明いらずの計算勝負",
		"color": Color(0.24, 0.42, 0.72),
		"stages": [
			{"id": "j1", "title": "対頂角と外角", "desc": "外角 = 残りの内角の和"},
			{"id": "j2", "title": "平行線と三角形", "desc": "角の総合問題"},
			{"id": "j3", "title": "円周角の定理", "desc": "中心角の半分"},
			{"id": "j4", "title": "円と接線", "desc": "内接四角形・接線の角"},
			{"id": "j5", "title": "三平方の定理", "desc": "a² + b² = c²"},
			{"id": "j6", "title": "特別な直角三角形", "desc": "45°・30°・60°"},
			{"id": "j7", "title": "おうぎ形の計算", "desc": "弧の長さと面積"},
			{"id": "j8", "title": "相似と面積比", "desc": "相似比の 2 乗"},
			{"id": "j9", "title": "座標平面の面積", "desc": "直線とグラフ"},
			{"id": "j10", "title": "ヒポクラテスの月", "desc": "円がらみの難問"},
		],
	},
	{
		"id": "s", "name": "大学受験レベル", "sub": "数I・数II ― 三角比から積分まで",
		"color": Color(0.62, 0.32, 0.66),
		"stages": [
			{"id": "s1", "title": "余弦定理", "desc": "c² = a² + b² − 2ab cosC"},
			{"id": "s2", "title": "正弦定理と外接円", "desc": "a / sinA = 2R"},
			{"id": "s3", "title": "三角比の面積公式", "desc": "S = ½ ab sinC"},
			{"id": "s4", "title": "ヘロンの公式", "desc": "3 辺から面積"},
			{"id": "s5", "title": "内接円と外接円", "desc": "S = rs と R = abc/4S"},
			{"id": "s6", "title": "ベクトルと面積", "desc": "½|x₁y₂ − x₂y₁|"},
			{"id": "s7", "title": "弧度法", "desc": "l = rθ,S = ½r²θ"},
			{"id": "s8", "title": "放物線と直線", "desc": "6分の1公式"},
			{"id": "s9", "title": "2つの放物線", "desc": "囲まれた面積"},
			{"id": "s10", "title": "面積の総合問題", "desc": "sin・絶対値・放物線"},
		],
	},
]


static func course_by_id(course_id: String) -> Dictionary:
	for c in COURSES:
		if String(c["id"]) == course_id:
			return c
	return COURSES[0]


static func stages_of(course_id: String) -> Array:
	return course_by_id(course_id)["stages"]


## ステージ ID("e4" など)から問題を 1 問生成する。
## tier: ステージ内の何問目か (0..2)。大きいほど難しいバリエーションを選ぶ
static func generate(stage_id: String, rng: RandomNumberGenerator, tier: int = 0) -> Dictionary:
	var p: Dictionary
	match stage_id[0]:
		"e":
			p = GenElementary.gen(stage_id, rng, tier)
		"j":
			p = GenJunior.gen(stage_id, rng, tier)
		_:
			p = GenSenior.gen(stage_id, rng, tier)
	# 既定値を補う
	if not p.has("tol"):
		p["tol"] = maxf(0.015, absf(float(p["answer"])) * 0.0002)
	if not p.has("unit"):
		p["unit"] = ""
	return p


## チャレンジ用: コース("all" なら全部)からランダムにステージを 1 つ選ぶ。
## ramp (0.0-1.0) が大きいほど後半の難しいステージが出やすい
static func random_stage(course_id: String, rng: RandomNumberGenerator, ramp := 0.0) -> String:
	var pool: Array = []
	if course_id == "all":
		for c in COURSES:
			pool += c["stages"]
	else:
		pool = stages_of(course_id)
	# ramp に応じて出題範囲の重心を後ろへずらす
	var n := pool.size()
	var lo := int(floor(ramp * n * 0.6))
	var idx := rng.randi_range(mini(lo, n - 1), n - 1) if rng.randf() < 0.5 \
		else rng.randi_range(0, n - 1)
	return String(pool[idx]["id"])


static func stage_title(stage_id: String) -> String:
	for c in COURSES:
		for s in c["stages"]:
			if String(s["id"]) == stage_id:
				return String(s["title"])
	return stage_id


# =========================================================
# 図形生成の共通ヘルパー(各コースの生成器から使う)
# =========================================================

## 3 辺の長さから三角形の頂点を返す [A, B, C]。B=(0,0), C=(a,0), A は上側。
## a=BC, b=CA, c=AB
static func tri_from_sides(a: float, b: float, c: float) -> Array:
	var cos_b := (a * a + c * c - b * b) / (2.0 * a * c)
	cos_b = clampf(cos_b, -1.0, 1.0)
	var sin_b := sqrt(maxf(0.0, 1.0 - cos_b * cos_b))
	return [Vector2(c * cos_b, c * sin_b), Vector2.ZERO, Vector2(a, 0)]


## 底辺の両端の角(度)から三角形の頂点を返す [A, B, C]。B=(0,0), C=(w,0)
static func tri_from_angles(ang_b: float, ang_c: float, w := 10.0) -> Array:
	var tb := tan(deg_to_rad(ang_b))
	var tc := tan(deg_to_rad(ang_c))
	var x := w * tc / (tb + tc)
	return [Vector2(x, tb * x), Vector2.ZERO, Vector2(w, 0)]


## 図形スペックの部品を作るショートハンド
static func poly(pts: Array, fill = null, stroke = null, w := 4.0) -> Dictionary:
	var d := {"t": "poly", "p": pts, "w": w}
	if fill != null:
		d["fill"] = fill
	if stroke != null:
		d["stroke"] = stroke
	return d


static func seg(a: Vector2, b: Vector2, color = null, w := 4.0, dash := false) -> Dictionary:
	var d := {"t": "seg", "a": a, "b": b, "w": w, "dash": dash}
	if color != null:
		d["color"] = color
	return d


static func circle(c: Vector2, r: float, fill = null, stroke = null, w := 4.0) -> Dictionary:
	var d := {"t": "circle", "c": c, "r": r, "w": w}
	if fill != null:
		d["fill"] = fill
	if stroke != null:
		d["stroke"] = stroke
	return d


## at を頂点に、p1 方向から p2 方向までの角の印。unknown の角は黄色で描かれる。
## 通常は 180° 以下の側(劣角)を自動で描く。おうぎ形の中心角のように
## 180° を超える印をそのまま描きたいときだけ reflex=true にする
## (このとき p1 → p2 は反時計回りに測る)
static func ang(at: Vector2, p1: Vector2, p2: Vector2, label: String, r := 0.0, reflex := false) -> Dictionary:
	return {"t": "angle", "at": at, "p1": p1, "p2": p2, "label": label, "r": r, "reflex": reflex}


static func right(at: Vector2, p1: Vector2, p2: Vector2) -> Dictionary:
	return {"t": "right", "at": at, "p1": p1, "p2": p2}


static func label(at: Vector2, s: String, color = null, size := 30) -> Dictionary:
	var d := {"t": "text", "at": at, "s": s, "size": size}
	if color != null:
		d["color"] = color
	return d


## 辺 ab の外側(法線 side 方向)に寄せた位置に文字を置く
static func side_label(a: Vector2, b: Vector2, s: String, side := 1.0, gap := 0.6) -> Dictionary:
	var mid := (a + b) * 0.5
	var n := (b - a).normalized().orthogonal() * side * gap
	return label(mid + n, s)


static func tick(a: Vector2, b: Vector2, n := 1) -> Dictionary:
	return {"t": "tick", "a": a, "b": b, "n": n}


static func sector(c: Vector2, r: float, a0: float, a1: float, fill = null, stroke = null) -> Dictionary:
	var d := {"t": "sector", "c": c, "r": r, "a0": a0, "a1": a1}
	if fill != null:
		d["fill"] = fill
	if stroke != null:
		d["stroke"] = stroke
	return d


static func arc(c: Vector2, r: float, a0: float, a1: float, color = null, w := 4.0) -> Dictionary:
	var d := {"t": "arc", "c": c, "r": r, "a0": a0, "a1": a1, "w": w}
	if color != null:
		d["color"] = color
	return d


static func curve(pts: Array, color = null, w := 4.0) -> Dictionary:
	var d := {"t": "curve", "p": pts, "w": w}
	if color != null:
		d["color"] = color
	return d


static func grid(from: Vector2, to: Vector2) -> Dictionary:
	return {"t": "grid", "from": from, "to": to}


static func axes(from: Vector2, to: Vector2) -> Dictionary:
	return {"t": "axes", "from": from, "to": to}


static func arrow(a: Vector2, b: Vector2, color = null, w := 5.0) -> Dictionary:
	var d := {"t": "arrow", "a": a, "b": b, "w": w}
	if color != null:
		d["color"] = color
	return d


## よく使う塗り色
const FILL_MAIN := Color(0.35, 0.55, 0.9, 0.25)
const FILL_ACCENT := Color(1.0, 0.75, 0.25, 0.4)
const FILL_SUB := Color(0.5, 0.85, 0.6, 0.25)
const COL_YELLOW := Color(1.0, 0.85, 0.3)
const COL_DIM := Color(0.7, 0.78, 0.9, 0.8)


## 小数を見やすい文字列に(整数なら整数で)
static func fmt(v: float) -> String:
	if absf(v - round(v)) < 0.0005:
		return str(int(round(v)))
	return String.num(v, 2)
