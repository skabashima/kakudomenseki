class_name GenExtra
## 「数値ひとつで答えられるのに、まだ入っていなかった」範囲の問題生成。
##   e22 立体の切断        切り口の面積・斜めに切った立体の体積・角を落とした残り
##   e23 展開図と組み立て  サイコロの目・円柱の側面・直方体の展開図から体積
##   j17 作図でできる角    垂直二等分線・角の二等分線・60°の作図・接線の作図
##   j18 多面体とオイラー  v − e + f = 2・角柱と角錐・正多面体・サッカーボール型
##   s23 領域と最大最小    不等式の表す領域の面積・線形計画法・円と直線の領域
##   s24 空間ベクトルと平面 2 点間の距離・点と平面の距離・内分点
## 立体は ProblemGen.proj3 の向きで描く(他の立体ステージと同じ見え方にそろえる)。


## オイラーの多面体定理の表 [名前, 頂点 v, 辺 e, 面 f]
const SOLIDS := [
	["正四面体", 4, 6, 4], ["立方体", 8, 12, 6], ["正八面体", 6, 12, 8],
	["正十二面体", 20, 30, 12], ["正二十面体", 12, 30, 20],
	["三角柱", 6, 9, 5], ["四角錐", 5, 8, 5], ["五角柱", 10, 15, 7],
	["六角柱", 12, 18, 8], ["五角錐", 6, 10, 6], ["六角錐", 7, 12, 7],
]

## 点と平面の距離で分母がきれいになる法線 [a, b, c, 長さ]
const NORMALS := [
	[1, 2, 2, 3], [2, 3, 6, 7], [1, 4, 8, 9], [2, 6, 9, 11], [3, 4, 12, 13],
	[2, 1, 2, 3], [6, 2, 3, 7], [4, 4, 7, 9], [1, 2, 2, 3], [8, 9, 12, 17],
]

## 線形計画法 [制約1(a,b,c), 制約2(d,e,f), 目的(p,q), 最大値]
## どれも x >= 0、y >= 0 と合わせて考える。最大値は整数の頂点で取れる組だけ
const LINPROG := [
	[2, 1, 10, 1, 2, 8, 3, 4, 20], [1, 1, 6, 2, 1, 8, 3, 2, 14],
	[3, 1, 9, 1, 2, 8, 2, 3, 14], [1, 2, 10, 3, 1, 15, 4, 3, 22],
	[2, 3, 12, 3, 2, 12, 5, 4, 26], [1, 1, 8, 1, 3, 12, 3, 4, 26],
]


static func gen(stage_id: String, rng: RandomNumberGenerator, tier: int) -> Dictionary:
	var t := clampi(tier, 0, 9)
	match stage_id:
		"e22":
			# 立方体の切り口 → 斜めに切った直方体 → 斜めに切った三角柱 → 角を落とす
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _e22(rng, 0)
				1: return _e22(rng, 1)
				2: return _e22(rng, 2)
				_: return _e22_corner(rng)
		"e23":
			# サイコロの目 → 直方体の展開図 → 円柱の展開図 → 角柱の展開図
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _e23(rng, 0)
				1: return _e23(rng, 1)
				2: return _e23(rng, 2)
				_: return _e23_prism(rng)
		"j17":
			# 垂直二等分線 → 角の二等分線 → 60°の作図と二等分 → 接線の作図
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _j17(rng, 0)
				1: return _j17(rng, 1)
				2: return _j17(rng, 2)
				_: return _j17_tangent(rng)
		"j18":
			# オイラーの定理 → 角柱と角錐の辺の数 → 正多面体 → サッカーボール型
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _j18(rng, 0)
				1: return _j18(rng, 1)
				2: return _j18(rng, 2)
				_: return _j18_ball(rng)
		"s23":
			# 領域の面積 → 線形計画法 → 円がふくまれる領域 → 4 本の直線で囲む
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _s23(rng, 0)
				1: return _s23(rng, 1)
				2: return _s23(rng, 2)
				_: return _s23_quad(rng)
		_:
			# s24: 2 点間の距離 → 点と平面の距離 → 内分点 → 原点と平面の距離
			match [0, 0, 0, 1, 1, 1, 2, 2, 3, 3][t]:
				0: return _s24(rng, 0)
				1: return _s24(rng, 1)
				2: return _s24(rng, 2)
				_: return _s24_origin(rng)


## 立方体の枠(切断の図で共通に使う)
static func _cube(a: float) -> Array:
	var v: Array = [
		Vector3(0, 0, 0), Vector3(a, 0, 0), Vector3(a, a, 0), Vector3(0, a, 0),
		Vector3(0, 0, a), Vector3(a, 0, a), Vector3(a, a, a), Vector3(0, a, a),
	]
	var edges: Array = [[0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7]]
	var shapes: Array = []
	for e in edges:
		var i: int = e[0]
		var j: int = e[1]
		var hidden := i == 3 or j == 3
		shapes.append(ProblemGen.seg(ProblemGen.proj3(v[i]), ProblemGen.proj3(v[j]),
			ProblemGen.COL_DIM if hidden else Color(0.92, 0.95, 1.0), 2.5, hidden))
	return shapes


## 空間の座標軸(x は手前右、y は奥、z は上)
static func _axes3(len_v: float) -> Array:
	return [
		ProblemGen.arrow(ProblemGen.proj3(Vector3.ZERO), ProblemGen.proj3(Vector3(len_v, 0, 0)),
			ProblemGen.COL_DIM, 2.5),
		ProblemGen.arrow(ProblemGen.proj3(Vector3.ZERO), ProblemGen.proj3(Vector3(0, len_v, 0)),
			ProblemGen.COL_DIM, 2.5),
		ProblemGen.arrow(ProblemGen.proj3(Vector3.ZERO), ProblemGen.proj3(Vector3(0, 0, len_v)),
			ProblemGen.COL_DIM, 2.5),
		ProblemGen.label(ProblemGen.proj3(Vector3(len_v + 0.6, 0, 0)), "x", ProblemGen.COL_DIM, 24),
		ProblemGen.label(ProblemGen.proj3(Vector3(0, len_v + 0.6, 0)), "y", ProblemGen.COL_DIM, 24),
		ProblemGen.label(ProblemGen.proj3(Vector3(0, 0, len_v + 0.6)), "z", ProblemGen.COL_DIM, 24),
	]


## 式の項の見た目。係数 1 は書かない("x" "2x" "−3x")
static func _term(coef: int, sym: String) -> String:
	if coef == 1:
		return sym
	if coef == -1:
		return "−" + sym
	if coef < 0:
		return "−%d%s" % [absi(coef), sym]
	return "%d%s" % [coef, sym]


## 続きの項(" + 2y" / " − y")。係数 0 なら空
static func _plus(coef: int, sym: String) -> String:
	if coef == 0:
		return ""
	return (" + " if coef > 0 else " − ") + _term(absi(coef), sym)


## 続きの定数(" + 5" / " − 5")。0 なら空
static func _pnum(v: int) -> String:
	if v == 0:
		return ""
	return (" + " if v > 0 else " − ") + str(absi(v))


## 展開図の 1 マス(長方形)を描く
static func _cell(x: float, y: float, w: float, h: float, fill = null, text := "") -> Array:
	var out: Array = [ProblemGen.poly([Vector2(x, y), Vector2(x + w, y),
		Vector2(x + w, y + h), Vector2(x, y + h)], fill, Color(0.92, 0.95, 1.0), 2.5)]
	if text != "":
		out.append(ProblemGen.label(Vector2(x + w * 0.5, y + h * 0.5 - 0.3), text,
			ProblemGen.COL_YELLOW, 28))
	return out


# =========================================================
# e22: 立体の切断
# =========================================================

static func _e22(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		# 立方体を A・C・F の 3 点で切る(切り口は正三角形)
		var a := rng.randi_range(2, 8)
		var af := float(a)
		var ask_area := rng.randf() < 0.5
		var cut: Array = [ProblemGen.proj3(Vector3(0, 0, 0)), ProblemGen.proj3(Vector3(af, af, 0)),
			ProblemGen.proj3(Vector3(af, 0, af))]
		var shapes: Array = _cube(af)
		shapes.append(ProblemGen.poly(cut, ProblemGen.FILL_ACCENT, ProblemGen.COL_YELLOW, 3.0))
		shapes += [
			ProblemGen.label(ProblemGen.proj3(Vector3(0, 0, 0)) + Vector2(-0.9, -0.6), "A",
				ProblemGen.COL_DIM, 26),
			ProblemGen.label(ProblemGen.proj3(Vector3(af, af, 0)) + Vector2(0.9, -0.5), "C",
				ProblemGen.COL_DIM, 26),
			ProblemGen.label(ProblemGen.proj3(Vector3(af, 0, af)) + Vector2(0.9, 0.5), "F",
				ProblemGen.COL_DIM, 26),
			ProblemGen.label(ProblemGen.proj3(Vector3(af, 0, 0)) + Vector2(0.5, -1.0), "B",
				ProblemGen.COL_DIM, 26),
		]
		if ask_area:
			var area := 0.865 * af * af       # (√3 / 2) × a × a、√3 = 1.73
			return {
				"q": "1 辺 %d cm の立方体 ABCD-EFGH を、3 点 A・C・F を通る平面で切ります。切り口の面積を求めなさい。√3 = 1.73 とします。" % a,
				"answer": area, "unit": "cm²", "tol": 0.05,
				"hint1": "AC・CF・FA はどれも面の対角線。切り口は正三角形になるよ。",
				"hint2": "1 辺 %d × 1.41 の正三角形。面積は 1 辺 × 1 辺 × 1.73 ÷ 4。" % a,
				"expl": "切り口は 1 辺 %s cm の正三角形。面積 = %s cm² です。" % [
					ProblemGen.fmt(af * 1.41), ProblemGen.fmt(area)],
				"fig": {"shapes": shapes},
			}
		var vol := af * af * af / 6.0
		return {
			"q": "1 辺 %d cm の立方体 ABCD-EFGH を、3 点 A・C・F を通る平面で切ります。頂点 B をふくむ方の立体の体積を求めなさい。" % a,
			"answer": vol, "unit": "cm³",
			"hint1": "B に集まる 3 辺 BA・BC・BF はどれも垂直。三角錐の公式が使えるよ。",
			"hint2": "(%d × %d ÷ 2) × %d ÷ 3" % [a, a, a],
			"expl": "三角錐 B-ACF の体積 = %d × %d × %d ÷ 6 = %s cm³(立方体の 6 分の 1)です。" % [
				a, a, a, ProblemGen.fmt(vol)],
			"fig": {"shapes": shapes},
		}
	if kind == 1:
		# 直方体を斜めに切った立体(前と後ろで高さがちがう)
		var w := rng.randi_range(3, 8)
		var d := rng.randi_range(3, 8)
		var h1 := rng.randi_range(2, 6)
		var h2 := h1 + rng.randi_range(2, 8)
		if (h1 + h2) % 2 != 0:
			h2 += 1
		var vol2 := float(w * d) * float(h1 + h2) / 2.0
		var wf := float(w)
		var df := float(d)
		var shapes2: Array = [
			ProblemGen.seg(ProblemGen.proj3(Vector3(0, 0, 0)), ProblemGen.proj3(Vector3(wf, 0, 0)),
				Color(0.92, 0.95, 1.0), 2.5),
			ProblemGen.seg(ProblemGen.proj3(Vector3(wf, 0, 0)), ProblemGen.proj3(Vector3(wf, df, 0)),
				Color(0.92, 0.95, 1.0), 2.5),
			ProblemGen.seg(ProblemGen.proj3(Vector3(0, 0, 0)), ProblemGen.proj3(Vector3(0, df, 0)),
				ProblemGen.COL_DIM, 2.0, true),
			ProblemGen.seg(ProblemGen.proj3(Vector3(0, df, 0)), ProblemGen.proj3(Vector3(wf, df, 0)),
				ProblemGen.COL_DIM, 2.0, true),
			ProblemGen.seg(ProblemGen.proj3(Vector3(0, 0, 0)), ProblemGen.proj3(Vector3(0, 0, h1)),
				Color(0.92, 0.95, 1.0), 2.5),
			ProblemGen.seg(ProblemGen.proj3(Vector3(wf, 0, 0)), ProblemGen.proj3(Vector3(wf, 0, h1)),
				Color(0.92, 0.95, 1.0), 2.5),
			ProblemGen.seg(ProblemGen.proj3(Vector3(wf, df, 0)), ProblemGen.proj3(Vector3(wf, df, h2)),
				Color(0.92, 0.95, 1.0), 2.5),
			ProblemGen.seg(ProblemGen.proj3(Vector3(0, df, 0)), ProblemGen.proj3(Vector3(0, df, h2)),
				ProblemGen.COL_DIM, 2.0, true),
			ProblemGen.poly([ProblemGen.proj3(Vector3(0, 0, h1)), ProblemGen.proj3(Vector3(wf, 0, h1)),
				ProblemGen.proj3(Vector3(wf, df, h2)), ProblemGen.proj3(Vector3(0, df, h2))],
				ProblemGen.FILL_ACCENT, ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.label(ProblemGen.proj3(Vector3(0, 0, float(h1) * 0.5)) + Vector2(-1.2, 0),
				"%d" % h1, ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(ProblemGen.proj3(Vector3(wf, df, float(h2) * 0.5)) + Vector2(1.2, 0),
				"%d" % h2, ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(ProblemGen.proj3(Vector3(wf * 0.5, 0, 0)) + Vector2(0, -1.1),
				"%d" % w, ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(ProblemGen.proj3(Vector3(wf, df * 0.5, 0)) + Vector2(1.0, -0.8),
				"%d" % d, ProblemGen.COL_YELLOW, 26),
		]
		return {
			"q": "底面が たて %d cm・よこ %d cm の長方形で、手前の高さが %d cm、奥の高さが %d cm になるように斜めに切られた立体があります。体積を求めなさい。" % [
				d, w, h1, h2],
			"answer": vol2, "unit": "cm³",
			"hint1": "同じ立体をもう 1 つ、さかさまにしてくっつけると直方体になるよ。",
			"hint2": "体積 = 底面積 × (手前の高さ + 奥の高さ) ÷ 2 = %d × (%d + %d) ÷ 2" % [w * d, h1, h2],
			"expl": "高さの平均は %s cm。体積 = %d × %s = %s cm³ です。" % [
				ProblemGen.fmt(float(h1 + h2) * 0.5), w * d, ProblemGen.fmt(float(h1 + h2) * 0.5),
				ProblemGen.fmt(vol2)],
			"fig": {"shapes": shapes2},
		}
	# kind 2: 三角柱を斜めに切る(高さの平均は 3 本の平均)
	var ba := rng.randi_range(3, 8)
	var bb := rng.randi_range(3, 8)
	var t1 := rng.randi_range(2, 6)
	var t2 := rng.randi_range(2, 8)
	var t3 := rng.randi_range(2, 8)
	while (t1 + t2 + t3) % 3 != 0:
		t3 = rng.randi_range(2, 8)
	var base_area := float(ba * bb) * 0.5
	var vol3 := base_area * float(t1 + t2 + t3) / 3.0
	var p1 := Vector3(0, 0, 0)
	var p2 := Vector3(float(ba), 0, 0)
	var p3 := Vector3(0, float(bb), 0)
	var shapes3: Array = [
		ProblemGen.poly([ProblemGen.proj3(p1), ProblemGen.proj3(p2), ProblemGen.proj3(p3)],
			ProblemGen.FILL_MAIN, Color(0.92, 0.95, 1.0), 2.5),
		ProblemGen.seg(ProblemGen.proj3(p1), ProblemGen.proj3(p1 + Vector3(0, 0, t1)),
			Color(0.92, 0.95, 1.0), 2.5),
		ProblemGen.seg(ProblemGen.proj3(p2), ProblemGen.proj3(p2 + Vector3(0, 0, t2)),
			Color(0.92, 0.95, 1.0), 2.5),
		ProblemGen.seg(ProblemGen.proj3(p3), ProblemGen.proj3(p3 + Vector3(0, 0, t3)),
			ProblemGen.COL_DIM, 2.0, true),
		ProblemGen.poly([ProblemGen.proj3(p1 + Vector3(0, 0, t1)),
			ProblemGen.proj3(p2 + Vector3(0, 0, t2)), ProblemGen.proj3(p3 + Vector3(0, 0, t3))],
			ProblemGen.FILL_ACCENT, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.label(ProblemGen.proj3(p1 + Vector3(0, 0, float(t1) * 0.5)) + Vector2(-1.2, 0),
			"%d" % t1, ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(ProblemGen.proj3(p2 + Vector3(0, 0, float(t2) * 0.5)) + Vector2(1.2, 0),
			"%d" % t2, ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(ProblemGen.proj3(p3 + Vector3(0, 0, float(t3) * 0.5)) + Vector2(-1.2, 0.5),
			"%d" % t3, ProblemGen.COL_DIM, 26),
	]
	return {
		"q": "底面が 直角をはさむ 2 辺 %d cm と %d cm の直角三角形の三角柱を、斜めに切りました。3 本の柱の高さが %d cm・%d cm・%d cm のとき、この立体の体積を求めなさい。" % [
			ba, bb, t1, t2, t3],
		"answer": vol3, "unit": "cm³",
		"hint1": "斜めに切った柱の体積は 底面積 × (高さの平均)。三角柱なら 3 本の平均だよ。",
		"hint2": "(%d × %d ÷ 2) × (%d + %d + %d) ÷ 3" % [ba, bb, t1, t2, t3],
		"expl": "底面積 %s cm²、高さの平均 %s cm。体積 = %s cm³ です。" % [
			ProblemGen.fmt(base_area), ProblemGen.fmt(float(t1 + t2 + t3) / 3.0),
			ProblemGen.fmt(vol3)],
		"fig": {"shapes": shapes3},
	}


## e22-角を落とす: 立方体の 8 すみを、辺の中点で切り落とした残りの体積
static func _e22_corner(rng: RandomNumberGenerator) -> Dictionary:
	var a := rng.randi_range(1, 5) * 12       # 12 の倍数にすると答えが整数になる
	var af := float(a)
	var corners := rng.randi_range(1, 4)
	var one := af * af * af / 48.0
	var vol := af * af * af - one * float(corners)
	var shapes: Array = _cube(af)
	var picks: Array = [Vector3(0, 0, 0), Vector3(af, 0, 0), Vector3(af, af, 0), Vector3(0, 0, af)]
	for i in corners:
		var c: Vector3 = picks[i]
		var to_center := (Vector3(af, af, af) * 0.5 - c).normalized()
		var p1 := c + Vector3(sign(to_center.x), 0, 0) * (af * 0.5)
		var p2 := c + Vector3(0, sign(to_center.y), 0) * (af * 0.5)
		var p3 := c + Vector3(0, 0, sign(to_center.z)) * (af * 0.5)
		shapes.append(ProblemGen.poly([ProblemGen.proj3(p1), ProblemGen.proj3(p2),
			ProblemGen.proj3(p3)], ProblemGen.FILL_ACCENT, ProblemGen.COL_YELLOW, 3.0))
	return {
		"q": "1 辺 %d cm の立方体の頂点を %d か所、その頂点に集まる 3 辺の中点を通る平面で切り落とします。残った立体の体積を求めなさい。" % [
			a, corners],
		"answer": vol, "unit": "cm³",
		"hint1": "切り落とす 1 つ分は、3 辺が半分の長さの三角錐だよ。",
		"hint2": "%d − (%s × %d)" % [a * a * a, ProblemGen.fmt(one), corners],
		"expl": "1 か所で %s cm³ 減る。%d − %s = %s cm³ です。" % [
			ProblemGen.fmt(one), a * a * a, ProblemGen.fmt(one * float(corners)),
			ProblemGen.fmt(vol)],
		"fig": {"shapes": shapes},
	}


# =========================================================
# e23: 展開図と組み立て
# =========================================================

static func _e23(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		# サイコロ(向かい合う面の目の和は 7)
		var shown := rng.randi_range(1, 6)
		var ans := 7 - shown
		var s := 3.0
		var shapes: Array = []
		# 十字型の展開図。真ん中の列に 4 枚、左右に 1 枚ずつ
		var pos: Array = [Vector2(0, 0), Vector2(s, 0), Vector2(s * 2, 0), Vector2(s * 3, 0),
			Vector2(s, s), Vector2(s, -s)]
		for i in pos.size():
			var p: Vector2 = pos[i]
			var txt := ""
			if i == 0:
				txt = str(shown)
			elif i == 2:
				txt = "?"
			shapes += _cell(p.x, p.y, s, s,
				ProblemGen.FILL_ACCENT if i == 2 else ProblemGen.FILL_MAIN, txt)
		return {
			"q": "サイコロの展開図です。向かい合う面の目の和はいつも 7 になります。%d の面と向かい合う「?」の面の目はいくつですか。" % shown,
			"answer": float(ans), "unit": "",
			"hint1": "展開図で 1 つおいた先にある面どうしが、組み立てると向かい合うよ。",
			"hint2": "7 − %d" % shown,
			"expl": "向かい合う面の和は 7 なので %d です。" % ans,
			"fig": {"shapes": shapes},
		}
	if kind == 1:
		# 直方体の展開図から体積
		var w := rng.randi_range(2, 7)
		var d := rng.randi_range(2, 7)
		var h := rng.randi_range(2, 7)
		var vol := w * d * h
		var wf := float(w)
		var df := float(d)
		var hf := float(h)
		var shapes2: Array = []
		shapes2 += _cell(0, 0, wf, hf, ProblemGen.FILL_MAIN)
		shapes2 += _cell(wf, 0, df, hf, ProblemGen.FILL_MAIN)
		shapes2 += _cell(wf + df, 0, wf, hf, ProblemGen.FILL_MAIN)
		shapes2 += _cell(wf + df + wf, 0, df, hf, ProblemGen.FILL_MAIN)
		shapes2 += _cell(wf, hf, df, df, ProblemGen.FILL_SUB)
		shapes2 += _cell(wf, -df, df, df, ProblemGen.FILL_SUB)
		shapes2 += [
			ProblemGen.label(Vector2(wf * 0.5, -0.9), "%d" % w, ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(Vector2(-0.9, hf * 0.5), "%d" % h, ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(Vector2(wf + df * 0.5, hf + df * 0.5), "%d" % d,
				ProblemGen.COL_YELLOW, 26),
		]
		return {
			"q": "直方体の展開図です。組み立ててできる直方体の体積を求めなさい。" ,
			"answer": float(vol), "unit": "cm³",
			"hint1": "たて・よこ・高さがどの辺にあたるかを、展開図から読み取ろう。",
			"hint2": "%d × %d × %d" % [w, d, h],
			"expl": "たて %d cm、よこ %d cm、高さ %d cm。体積 = %d cm³ です。" % [d, w, h, vol],
			"fig": {"shapes": shapes2},
		}
	# kind 2: 円柱の展開図(側面の長方形のよこ = 底面の円周)
	var r := rng.randi_range(2, 8)
	var h2 := rng.randi_range(3, 10)
	var ask_len := rng.randf() < 0.5
	var around := 2.0 * 3.14 * float(r)
	var side := around * float(h2)
	var rf := float(r)
	var shapes3: Array = []
	shapes3 += _cell(0, 0, around * 0.5, float(h2), ProblemGen.FILL_MAIN)
	shapes3.append(ProblemGen.circle(Vector2(-rf * 0.5 - 1.5, float(h2) + rf * 0.5 + 1.0), rf * 0.5,
		ProblemGen.FILL_SUB, Color(0.92, 0.95, 1.0), 2.5))
	shapes3.append(ProblemGen.circle(Vector2(-rf * 0.5 - 1.5, -rf * 0.5 - 1.0), rf * 0.5,
		ProblemGen.FILL_SUB, Color(0.92, 0.95, 1.0), 2.5))
	shapes3.append(ProblemGen.label(Vector2(around * 0.25, -1.1), "?" if ask_len else
		ProblemGen.fmt(around), ProblemGen.COL_YELLOW, 26))
	shapes3.append(ProblemGen.label(Vector2(-0.9, float(h2) * 0.5), "%d" % h2,
		ProblemGen.COL_YELLOW, 26))
	if ask_len:
		return {
			"q": "底面の半径 %d cm、高さ %d cm の円柱の展開図です。側面の長方形のよこの長さを求めなさい。円周率は 3.14 とします。" % [
				r, h2],
			"answer": around, "unit": "cm", "tol": 0.02,
			"hint1": "側面をひらいた長方形のよこは、底面の円をぐるっと 1 周した長さと同じだよ。",
			"hint2": "2 × 3.14 × %d" % r,
			"expl": "よこ = 底面の円周 = 2 × 3.14 × %d = %s cm です。" % [r, ProblemGen.fmt(around)],
			"fig": {"shapes": shapes3},
		}
	return {
		"q": "底面の半径 %d cm、高さ %d cm の円柱の側面積(展開図の長方形の面積)を求めなさい。円周率は 3.14 とします。" % [
			r, h2],
		"answer": side, "unit": "cm²", "tol": 0.02,
		"hint1": "側面をひらくと長方形。よこは底面の円周、たては高さだよ。",
		"hint2": "(2 × 3.14 × %d) × %d" % [r, h2],
		"expl": "側面積 = %s × %d = %s cm² です。" % [
			ProblemGen.fmt(around), h2, ProblemGen.fmt(side)],
		"fig": {"shapes": shapes3},
	}


## e23-角柱: 展開図から表面積
static func _e23_prism(rng: RandomNumberGenerator) -> Dictionary:
	var sets: Array = [[3, 4, 5], [6, 8, 10], [5, 12, 13], [9, 12, 15], [8, 15, 17]]
	var s: Array = sets[rng.randi_range(0, sets.size() - 1)]
	var a: int = s[0]
	var b: int = s[1]
	var c: int = s[2]
	var h := rng.randi_range(3, 10)
	var area := float(a * b) + float(a + b + c) * float(h)
	var hf := float(h)
	var shapes: Array = []
	var x := 0.0
	for side_len in [a, b, c]:
		shapes += _cell(x, 0, float(side_len), hf, ProblemGen.FILL_MAIN,
			str(side_len))
		x += float(side_len)
	shapes.append(ProblemGen.poly([Vector2(0, hf), Vector2(float(a), hf),
		Vector2(0, hf + float(b))], ProblemGen.FILL_SUB, Color(0.92, 0.95, 1.0), 2.5))
	shapes.append(ProblemGen.poly([Vector2(0, 0), Vector2(float(a), 0),
		Vector2(0, -float(b))], ProblemGen.FILL_SUB, Color(0.92, 0.95, 1.0), 2.5))
	shapes.append(ProblemGen.label(Vector2(-0.9, hf * 0.5), "%d" % h, ProblemGen.COL_YELLOW, 26))
	return {
		"q": "底面が 3 辺 %d cm・%d cm・%d cm の直角三角形、高さ %d cm の三角柱の展開図です。表面積を求めなさい。" % [
			a, b, c, h],
		"answer": area, "unit": "cm²",
		"hint1": "長方形 3 枚(側面)と、直角三角形 2 枚(上下の底面)に分けて考えよう。",
		"hint2": "(%d + %d + %d) × %d + %d × %d ÷ 2 × 2" % [a, b, c, h, a, b],
		"expl": "側面 %d + 底面 %d = %s cm² です。" % [
			(a + b + c) * h, a * b, ProblemGen.fmt(area)],
		"fig": {"shapes": shapes},
	}


# =========================================================
# j17: 作図でできる角と長さ
# =========================================================

## コンパスの弧を 2 つ描く(作図のあとが分かるように)
static func _compass(c1: Vector2, c2: Vector2, r: float) -> Array:
	var d := (c2 - c1).angle()
	var deg := rad_to_deg(d)
	return [
		ProblemGen.arc(c1, r, deg - 55.0, deg + 55.0, ProblemGen.COL_DIM, 2.0),
		ProblemGen.arc(c2, r, deg + 125.0, deg + 235.0, ProblemGen.COL_DIM, 2.0),
	]


static func _j17(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		# 垂直二等分線
		var ab := rng.randi_range(2, 12) * 2
		var ask_len := rng.randf() < 0.5
		var a := Vector2(-float(ab) * 0.35, 0)
		var b := Vector2(float(ab) * 0.35, 0)
		var m := (a + b) * 0.5
		var r := a.distance_to(b) * 0.75
		var shapes: Array = [ProblemGen.seg(a, b, Color(0.92, 0.95, 1.0), 3.0)]
		shapes += _compass(a, b, r)
		shapes += [
			ProblemGen.seg(m + Vector2(0, -r * 0.9), m + Vector2(0, r * 0.9),
				ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.right(m, b, m + Vector2(0, r * 0.9)),
			ProblemGen.label(a + Vector2(-0.8, -0.6), "A"),
			ProblemGen.label(b + Vector2(0.8, -0.6), "B"),
			ProblemGen.label(m + Vector2(0.3, -1.0), "M", ProblemGen.COL_YELLOW, 26),
		]
		if ask_len:
			return {
				"q": "長さ %d cm の線分 AB の垂直二等分線をコンパスと定規で作図しました。垂直二等分線と AB の交点を M とするとき、AM の長さを求めなさい。" % ab,
				"answer": float(ab) * 0.5, "unit": "cm",
				"hint1": "垂直二等分線は、その名のとおり線分をまん中で 2 つに分ける線だよ。",
				"hint2": "AM = %d ÷ 2" % ab,
				"expl": "M は AB の中点なので AM = %s cm です。" % ProblemGen.fmt(ab * 0.5),
				"fig": {"shapes": shapes},
			}
		return {
			"q": "線分 AB の垂直二等分線を作図しました。作図した線と AB が作る角は何度ですか。",
			"answer": 90.0, "unit": "度",
			"hint1": "A からも B からも同じ長さのところを通る線。「垂直」の 2 文字が答えそのものだよ。",
			"hint2": "垂直 = 直角。",
			"expl": "垂直二等分線は AB と直角に交わるので 90° です。",
			"fig": {"shapes": shapes},
		}
	if kind == 1:
		# 角の二等分線
		var ang := rng.randi_range(10, 40) * 4
		var half := ang / 2
		var o := Vector2.ZERO
		var u1 := Vector2(1, 0) * 8.0
		var u2 := Vector2(cos(deg_to_rad(float(ang))), sin(deg_to_rad(float(ang)))) * 8.0
		var mid := (u1.normalized() + u2.normalized()).normalized() * 8.0
		var shapes2: Array = [
			ProblemGen.seg(o, u1, Color(0.92, 0.95, 1.0), 3.0),
			ProblemGen.seg(o, u2, Color(0.92, 0.95, 1.0), 3.0),
			ProblemGen.arc(o, 3.0, 0.0, float(ang), ProblemGen.COL_DIM, 2.0),
			ProblemGen.seg(o, mid, ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.ang(o, u1, mid, "x", 5.0),
			ProblemGen.label(u1 + Vector2(0.7, -0.3), "A", ProblemGen.COL_DIM, 26),
			ProblemGen.label(u2 + Vector2(0.4, 0.7), "B", ProblemGen.COL_DIM, 26),
		]
		return {
			"q": "%d° の角 AOB の二等分線を作図しました。作図した線と OA が作る角 x は何度ですか。" % ang,
			"answer": float(half), "unit": "度",
			"hint1": "二等分線は角をちょうど半分に分けるよ。",
			"hint2": "%d ÷ 2" % ang,
			"expl": "x = %d ÷ 2 = %d° です。" % [ang, half],
			"fig": {"shapes": shapes2},
		}
	# kind 2: 正三角形を使った 60° の作図と、その二等分
	var times := rng.randi_range(0, 3)
	var base := 60.0
	var ans := base / pow(2.0, float(times))
	var o2 := Vector2(-4.0, -2.0)
	var b2 := o2 + Vector2(7.0, 0)
	var apex := o2 + Vector2(3.5, 6.06)
	var shapes3: Array = [
		ProblemGen.poly([o2, b2, apex], ProblemGen.FILL_MAIN, Color(0.92, 0.95, 1.0), 2.5),
		ProblemGen.arc(o2, 7.0, 0.0, 70.0, ProblemGen.COL_DIM, 2.0),
		ProblemGen.arc(b2, 7.0, 110.0, 180.0, ProblemGen.COL_DIM, 2.0),
		ProblemGen.ang(o2, b2, apex, "60°", 2.2),
	]
	var dir := Vector2(cos(deg_to_rad(ans)), sin(deg_to_rad(ans))) * 7.0
	if times > 0:
		shapes3.append(ProblemGen.seg(o2, o2 + dir, ProblemGen.COL_YELLOW, 3.0))
		shapes3.append(ProblemGen.ang(o2, b2, o2 + dir, "x", 4.4))
	return {
		"q": "コンパスと定規で正三角形を作図して 60° を作りました。%sできる角 x は何度ですか。" % [
			"この角をそのまま使うとき" if times == 0 else "この角を %d 回二等分したとき、" % times],
		"answer": ans, "unit": "度",
		"hint1": "正三角形の 1 つの角は 60°。二等分するたびに半分になるよ。",
		"hint2": "60 ÷ 2 を %d 回" % times,
		"expl": "60° を %d 回半分にして %s° です。" % [times, ProblemGen.fmt(ans)],
		"fig": {"shapes": shapes3},
	}


## j17-接線: 円の接線の作図(半径と接線は垂直)
static func _j17_tangent(rng: RandomNumberGenerator) -> Dictionary:
	var r := rng.randi_range(2, 6)
	var d := r + rng.randi_range(3, 8)
	var pp := Vector2(-float(d), 0)
	var tx := -float(r * r) / float(d)
	var ty := sqrt(maxf(0.0, float(r * r) - tx * tx))
	var tpt := Vector2(tx, ty)
	var mid := (pp + Vector2.ZERO) * 0.5
	var shapes: Array = [
		ProblemGen.circle(Vector2.ZERO, float(r), null, Color(0.92, 0.95, 1.0), 2.5),
		ProblemGen.arc(mid, pp.distance_to(Vector2.ZERO) * 0.5, 0.0, 360.0, ProblemGen.COL_DIM, 2.0),
		ProblemGen.seg(pp, tpt, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.seg(Vector2.ZERO, tpt, ProblemGen.COL_DIM, 2.0, true),
		ProblemGen.seg(pp, Vector2.ZERO, ProblemGen.COL_DIM, 2.0, true),
		ProblemGen.right(tpt, Vector2.ZERO, pp),
		ProblemGen.label(pp + Vector2(-0.9, 0), "P", ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(tpt + Vector2(0.3, 0.9), "T", ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(Vector2(0.3, -1.0), "O", ProblemGen.COL_DIM, 26),
	]
	return {
		"q": "円の外の点 P から円への接線を作図しました(OP を直径とする円をかいて、交点 T を求める作図です)。接点 T で、半径 OT と接線 PT が作る角は何度ですか。",
		"answer": 90.0, "unit": "度",
		"hint1": "OP を直径とする円をかくのは、直径を見こむ角が 90° になる性質を使うためだよ。",
		"hint2": "接線と、接点を通る半径の関係を思い出そう。",
		"expl": "接線は接点を通る半径と垂直なので 90° です。この作図はその性質を利用しています。",
		"fig": {"shapes": shapes},
	}


# =========================================================
# j18: 多面体とオイラーの定理
# =========================================================

## 立体のかんたんな見取り図(角柱・角錐・正多面体は代表の形で描く)
static func _solid_sketch(name: String) -> Array:
	if name.contains("柱"):
		var n := 3
		if name.begins_with("四"):
			n = 4
		elif name.begins_with("五"):
			n = 5
		elif name.begins_with("六"):
			n = 6
		return _prism_sketch(n, 4.0, 5.0)
	if name.contains("錐"):
		var n2 := 4
		if name.begins_with("三"):
			n2 = 3
		elif name.begins_with("五"):
			n2 = 5
		elif name.begins_with("六"):
			n2 = 6
		return _pyramid_sketch(n2, 4.0, 6.0)
	if name == "立方体":
		return _cube(5.0)
	if name == "正四面体":
		return _pyramid_sketch(3, 4.0, 5.5)
	if name == "正八面体":
		return _octa_sketch(4.0)
	# 正十二面体・正二十面体は面の形だけを見せる(見取り図はかえって分かりにくい)
	var sides := 5 if name == "正十二面体" else 3
	var pts: Array = []
	for i in sides:
		var th := TAU * i / float(sides) + PI * 0.5
		pts.append(Vector2(cos(th), sin(th)) * 3.5)
	return [
		ProblemGen.poly(pts, ProblemGen.FILL_MAIN, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.label(Vector2(0, -5.2), "面の形(正%s角形)" % ("五" if sides == 5 else "三"),
			ProblemGen.COL_DIM, 24),
	]


## n 角柱の見取り図
static func _prism_sketch(n: int, r: float, h: float) -> Array:
	var shapes: Array = []
	var bottom: Array = []
	var top: Array = []
	for i in n:
		var th := TAU * i / float(n) + PI * 0.5
		var p := Vector3(cos(th) * r, sin(th) * r, 0)
		bottom.append(ProblemGen.proj3(p))
		top.append(ProblemGen.proj3(p + Vector3(0, 0, h)))
	for i in n:
		shapes.append(ProblemGen.seg(bottom[i], bottom[(i + 1) % n], ProblemGen.COL_DIM, 2.0))
		shapes.append(ProblemGen.seg(top[i], top[(i + 1) % n], Color(0.92, 0.95, 1.0), 2.5))
		shapes.append(ProblemGen.seg(bottom[i], top[i], Color(0.92, 0.95, 1.0), 2.5))
	return shapes


## n 角錐の見取り図
static func _pyramid_sketch(n: int, r: float, h: float) -> Array:
	var shapes: Array = []
	var bottom: Array = []
	for i in n:
		var th := TAU * i / float(n) + PI * 0.5
		bottom.append(ProblemGen.proj3(Vector3(cos(th) * r, sin(th) * r, 0)))
	var apex := ProblemGen.proj3(Vector3(0, 0, h))
	for i in n:
		shapes.append(ProblemGen.seg(bottom[i], bottom[(i + 1) % n], ProblemGen.COL_DIM, 2.0))
		shapes.append(ProblemGen.seg(bottom[i], apex, Color(0.92, 0.95, 1.0), 2.5))
	return shapes


## 正八面体の見取り図
static func _octa_sketch(r: float) -> Array:
	var v: Array = [Vector3(r, 0, 0), Vector3(0, r, 0), Vector3(-r, 0, 0), Vector3(0, -r, 0),
		Vector3(0, 0, r), Vector3(0, 0, -r)]
	var shapes: Array = []
	for i in 4:
		shapes.append(ProblemGen.seg(ProblemGen.proj3(v[i]), ProblemGen.proj3(v[(i + 1) % 4]),
			ProblemGen.COL_DIM, 2.0))
		shapes.append(ProblemGen.seg(ProblemGen.proj3(v[i]), ProblemGen.proj3(v[4]),
			Color(0.92, 0.95, 1.0), 2.5))
		shapes.append(ProblemGen.seg(ProblemGen.proj3(v[i]), ProblemGen.proj3(v[5]),
			Color(0.92, 0.95, 1.0), 2.5))
	return shapes


static func _j18(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		# オイラーの多面体定理で、残りの 1 つを求める
		var s: Array = SOLIDS[rng.randi_range(0, SOLIDS.size() - 1)]
		var name := String(s[0])
		var v: int = s[1]
		var e: int = s[2]
		var f: int = s[3]
		var which := rng.randi_range(0, 2)
		var ans := v
		var q := "頂点が %d 個、辺が %d 本、面が %d 枚" % [v, e, f]
		if which == 0:
			q = "辺が %d 本、面が %d 枚の多面体の頂点の数" % [e, f]
		elif which == 1:
			ans = e
			q = "頂点が %d 個、面が %d 枚の多面体の辺の数" % [v, f]
		else:
			ans = f
			q = "頂点が %d 個、辺が %d 本の多面体の面の数" % [v, e]
		return {
			"q": "オイラーの多面体定理を使います。%s を求めなさい。" % q,
			"answer": float(ans), "unit": "",
			"hint1": "どんな多面体でも (頂点) − (辺) + (面) = 2 が成り立つよ。",
			"hint2": "v − e + f = 2 に、分かっている数を入れて解こう。",
			"expl": "%d − %d + %d = 2 になっている(%s)。答えは %d です。" % [v, e, f, name, ans],
			"fig": {"shapes": _solid_sketch(name)},
		}
	if kind == 1:
		# n 角柱・n 角錐の頂点・辺・面の数
		var n := rng.randi_range(3, 12)
		var is_prism := rng.randf() < 0.5
		var pick := rng.randi_range(0, 2)
		var name2 := "%d 角柱" % n
		var vv := 2 * n
		var ee := 3 * n
		var ff := n + 2
		if not is_prism:
			name2 = "%d 角錐" % n
			vv = n + 1
			ee = 2 * n
			ff = n + 1
		var ans2 := vv
		var what := "頂点の数"
		if pick == 1:
			ans2 = ee
			what = "辺の数"
		elif pick == 2:
			ans2 = ff
			what = "面の数"
		var sketch_name := "六角柱" if is_prism else "六角錐"
		return {
			"q": "%sの%sを求めなさい。" % [name2, what],
			"answer": float(ans2), "unit": "",
			"hint1": "底面の %d 角形をもとに数えよう。%s" % [n,
				"角柱は上下に 2 つの底面があるよ。" if is_prism else "角錐は頂点が 1 つだけ上にあるよ。"],
			"hint2": "%s" % ("角柱: 頂点 2n、辺 3n、面 n + 2" if is_prism
				else "角錐: 頂点 n + 1、辺 2n、面 n + 1"),
			"expl": "%s は 頂点 %d・辺 %d・面 %d。%s は %d です。" % [name2, vv, ee, ff, what, ans2],
			"fig": {"shapes": _solid_sketch(sketch_name)},
		}
	# kind 2: 正多面体の表から
	var solids: Array = [["正四面体", 4, 6, 4], ["立方体", 8, 12, 6], ["正八面体", 6, 12, 8],
		["正十二面体", 20, 30, 12], ["正二十面体", 12, 30, 20]]
	var s3: Array = solids[rng.randi_range(0, solids.size() - 1)]
	var name3 := String(s3[0])
	var pick3 := rng.randi_range(0, 2)
	var ans3: int = s3[1]
	var what3 := "頂点の数"
	if pick3 == 1:
		ans3 = s3[2]
		what3 = "辺の数"
	elif pick3 == 2:
		ans3 = s3[3]
		what3 = "面の数"
	return {
		"q": "%sの%sを求めなさい。" % [name3, what3],
		"answer": float(ans3), "unit": "",
		"hint1": "面の形と、1 つの頂点に集まる面の数から数えられるよ。オイラーの定理でも確かめられる。",
		"hint2": "%s は 面が %d 枚、辺が %d 本、頂点が %d 個。" % [name3, s3[3], s3[2], s3[1]],
		"expl": "%s の %s は %d です(%d − %d + %d = 2)。" % [
			name3, what3, ans3, s3[1], s3[2], s3[3]],
		"fig": {"shapes": _solid_sketch(name3)},
	}


## j18-サッカーボール: 正五角形 12 枚と正六角形 20 枚でできた立体
static func _j18_ball(rng: RandomNumberGenerator) -> Dictionary:
	var pent := 12
	var hexa := 20
	var edges := (pent * 5 + hexa * 6) / 2
	var verts := (pent * 5 + hexa * 6) / 3
	var pick := rng.randi_range(0, 1)
	var ans := edges
	var what := "辺の数"
	if pick == 1:
		ans = verts
		what = "頂点の数"
	var shapes: Array = [ProblemGen.circle(Vector2.ZERO, 5.0, null, ProblemGen.COL_DIM, 2.0)]
	var pent_pts: Array = []
	for i in 5:
		var th := TAU * i / 5.0 + PI * 0.5
		pent_pts.append(Vector2(cos(th), sin(th)) * 1.8)
	shapes.append(ProblemGen.poly(pent_pts, ProblemGen.FILL_ACCENT, ProblemGen.COL_YELLOW, 2.5))
	for k in 5:
		var th2 := TAU * k / 5.0 + PI * 0.5
		var center := Vector2(cos(th2), sin(th2)) * 3.4
		var hex_pts: Array = []
		for i in 6:
			var th3 := TAU * i / 6.0 + th2
			hex_pts.append(center + Vector2(cos(th3), sin(th3)) * 1.6)
		shapes.append(ProblemGen.poly(hex_pts, ProblemGen.FILL_MAIN, ProblemGen.COL_DIM, 2.0))
	return {
		"q": "サッカーボールの形(正五角形 12 枚と正六角形 20 枚でできた多面体)の%sを求めなさい。" % what,
		"answer": float(ans), "unit": "",
		"hint1": "面の辺を全部数えると、1 本の辺を 2 回ずつ数えたことになるよ。頂点は 3 回ずつ。",
		"hint2": "(12 × 5 + 20 × 6) = %d。これを %d でわる。" % [pent * 5 + hexa * 6,
			2 if pick == 0 else 3],
		"expl": "面の辺の合計は %d。辺は %d 本、頂点は %d 個です(%d − %d + 32 = 2)。" % [
			pent * 5 + hexa * 6, edges, verts, verts, edges],
		"fig": {"shapes": shapes},
	}


# =========================================================
# s23: 領域と最大最小(数II)
# =========================================================

static func _s23(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		# x >= 0、y >= 0、ax + by <= c の表す領域の面積
		var a := rng.randi_range(1, 6)
		var b := rng.randi_range(1, 6)
		var k := rng.randi_range(2, 6)
		var c := a * b * k
		var xi := float(c) / float(a)
		var yi := float(c) / float(b)
		var area := xi * yi * 0.5
		var lo := Vector2(-1, -1)
		var hi := Vector2(xi + 2.0, yi + 2.0)
		var fig := {"shapes": [
			ProblemGen.grid(lo, hi), ProblemGen.axes(lo, hi),
			ProblemGen.poly([Vector2.ZERO, Vector2(xi, 0), Vector2(0, yi)],
				ProblemGen.FILL_ACCENT, ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.label(Vector2(xi, -1.0), ProblemGen.fmt(xi), ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(Vector2(-1.0, yi), ProblemGen.fmt(yi), ProblemGen.COL_YELLOW, 26),
		]}
		return {
			"q": "不等式 x ≥ 0、y ≥ 0、%s%s ≤ %d が表す領域の面積を求めなさい。" % [
				_term(a, "x"), _plus(b, "y"), c],
			"answer": area, "unit": "",
			"hint1": "3 本の境界線で囲まれた三角形になる。まず x 切片と y 切片を出そう。",
			"hint2": "x 切片 %s、y 切片 %s。面積 = 底辺 × 高さ ÷ 2" % [
				ProblemGen.fmt(xi), ProblemGen.fmt(yi)],
			"expl": "直角三角形なので 面積 = %s × %s ÷ 2 = %s です。" % [
				ProblemGen.fmt(xi), ProblemGen.fmt(yi), ProblemGen.fmt(area)],
			"fig": fig,
		}
	if kind == 1:
		# 線形計画法(最大値は整数の頂点で取れる組だけを使う)
		var s: Array = LINPROG[rng.randi_range(0, LINPROG.size() - 1)]
		var a1: int = s[0]
		var b1: int = s[1]
		var c1: int = s[2]
		var a2: int = s[3]
		var b2: int = s[4]
		var c2: int = s[5]
		var p: int = s[6]
		var q: int = s[7]
		var best: int = s[8]
		var den := a1 * b2 - a2 * b1
		var cx := float(c1 * b2 - c2 * b1) / float(den)
		var cy := float(a1 * c2 - a2 * c1) / float(den)
		var pts: Array = [Vector2.ZERO, Vector2(float(c1) / float(a1), 0), Vector2(cx, cy),
			Vector2(0, float(c2) / float(b2))]
		var lo2 := Vector2(-1, -1)
		var hi2 := Vector2(float(c1) / float(a1) + 2.0, float(c2) / float(b2) + 2.0)
		var fig2 := {"shapes": [
			ProblemGen.grid(lo2, hi2), ProblemGen.axes(lo2, hi2),
			ProblemGen.poly(pts, ProblemGen.FILL_ACCENT, ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.circle(Vector2(cx, cy), 0.25, ProblemGen.COL_YELLOW, null, 0.0),
			ProblemGen.label(Vector2(cx + 0.6, cy + 0.8),
				"(%s, %s)" % [ProblemGen.fmt(cx), ProblemGen.fmt(cy)], ProblemGen.COL_YELLOW, 26),
		]}
		return {
			"q": "x ≥ 0、y ≥ 0、%s%s ≤ %d、%s%s ≤ %d のとき、%s%s の最大値を求めなさい。" % [
				_term(a1, "x"), _plus(b1, "y"), c1,
				_term(a2, "x"), _plus(b2, "y"), c2,
				_term(p, "x"), _plus(q, "y")],
			"answer": float(best), "unit": "",
			"hint1": "領域は 4 つの点で囲まれた形。最大値はかならず角(頂点)のどれかで取るよ。",
			"hint2": "2 直線の交点は (%s, %s)。ほかの頂点でも計算して比べよう。" % [
				ProblemGen.fmt(cx), ProblemGen.fmt(cy)],
			"expl": "頂点をすべて調べると最大値は %d です。" % best,
			"fig": fig2,
		}
	# kind 2: 円がふくまれる領域(半円・4 分円)の面積
	var r := rng.randi_range(2, 8)
	var quarter := rng.randf() < 0.5
	var area2 := 3.14 * float(r * r) * (0.25 if quarter else 0.5)
	var lo3 := Vector2(-float(r) - 2, -float(r) - 2)
	var hi3 := Vector2(float(r) + 2, float(r) + 2)
	var fig3 := {"shapes": [
		ProblemGen.grid(lo3, hi3), ProblemGen.axes(lo3, hi3),
		ProblemGen.sector(Vector2.ZERO, float(r), 0.0, 90.0 if quarter else 180.0,
			ProblemGen.FILL_ACCENT, ProblemGen.COL_YELLOW),
		ProblemGen.circle(Vector2.ZERO, float(r), null, ProblemGen.COL_DIM, 2.0),
	]}
	var cond := "x ≥ 0、y ≥ 0" if quarter else "y ≥ 0"
	return {
		"q": "不等式 x² + y² ≤ %d、%s が表す領域の面積を求めなさい。円周率は 3.14 とします。" % [
			r * r, cond],
		"answer": area2, "unit": "", "tol": 0.02,
		"hint1": "x² + y² ≤ r² は半径 r の円の内側。あとの条件で切り取られる分だけ考えよう。",
		"hint2": "半径 %d の円の %s。" % [r, "4 分の 1" if quarter else "半分"],
		"expl": "円の面積 %s の %s で %s です。" % [
			ProblemGen.fmt(3.14 * r * r), "4 分の 1" if quarter else "半分",
			ProblemGen.fmt(area2)],
		"fig": fig3,
	}


## s23-四角形: 2 本の直線と 2 本の軸で囲まれた台形の面積
static func _s23_quad(rng: RandomNumberGenerator) -> Dictionary:
	var w := rng.randi_range(2, 8)
	var h1 := rng.randi_range(1, 6)
	var h2 := h1 + rng.randi_range(1, 6)
	var area := float(w) * float(h1 + h2) * 0.5
	var lo := Vector2(-1, -1)
	var hi := Vector2(float(w) + 2, float(h2) + 2)
	var fig := {"shapes": [
		ProblemGen.grid(lo, hi), ProblemGen.axes(lo, hi),
		ProblemGen.poly([Vector2.ZERO, Vector2(w, 0), Vector2(w, h2), Vector2(0, h1)],
			ProblemGen.FILL_ACCENT, ProblemGen.COL_YELLOW, 3.0),
		ProblemGen.label(Vector2(-1.0, float(h1)), "%d" % h1, ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(Vector2(float(w) + 0.9, float(h2)), "%d" % h2, ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(Vector2(float(w), -1.0), "%d" % w, ProblemGen.COL_YELLOW, 26),
	]}
	var slope := float(h2 - h1) / float(w)
	return {
		"q": "0 ≤ x ≤ %d、0 ≤ y ≤ %sx + %d が表す領域の面積を求めなさい。" % [
			w, "" if absf(slope - 1.0) < 0.001 else ProblemGen.fmt(slope), h1],
		"answer": area, "unit": "",
		"hint1": "上の境界は直線。できる形は台形になるよ。",
		"hint2": "左の高さ %d、右の高さ %d、よこ %d の台形。" % [h1, h2, w],
		"expl": "台形の面積 = (%d + %d) × %d ÷ 2 = %s です。" % [h1, h2, w, ProblemGen.fmt(area)],
		"fig": fig,
	}


# =========================================================
# s24: 空間ベクトルと平面(数C)
# =========================================================

static func _s24(rng: RandomNumberGenerator, kind: int) -> Dictionary:
	if kind == 0:
		# 空間の 2 点間の距離
		var s: Array = NORMALS[rng.randi_range(0, NORMALS.size() - 1)]
		var dx: int = s[0]
		var dy: int = s[1]
		var dz: int = s[2]
		var dist: int = s[3]
		var x0 := rng.randi_range(-3, 3)
		var y0 := rng.randi_range(-3, 3)
		var z0 := rng.randi_range(-3, 3)
		var a3 := Vector3(x0, y0, z0)
		var b3 := Vector3(x0 + dx, y0 + dy, z0 + dz)
		var shapes: Array = _axes3(6.0)
		shapes += [
			ProblemGen.seg(ProblemGen.proj3(a3), ProblemGen.proj3(b3), ProblemGen.COL_YELLOW, 3.0),
			ProblemGen.circle(ProblemGen.proj3(a3), 0.25, ProblemGen.COL_YELLOW, null, 0.0),
			ProblemGen.circle(ProblemGen.proj3(b3), 0.25, ProblemGen.COL_YELLOW, null, 0.0),
			ProblemGen.label(ProblemGen.proj3(a3) + Vector2(-0.9, -0.7), "A",
				ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(ProblemGen.proj3(b3) + Vector2(0.9, 0.5), "B",
				ProblemGen.COL_YELLOW, 26),
		]
		return {
			"q": "空間の 2 点 A(%d, %d, %d)、B(%d, %d, %d) の距離を求めなさい。" % [
				x0, y0, z0, x0 + dx, y0 + dy, z0 + dz],
			"answer": float(dist), "unit": "",
			"hint1": "座標の差を出して、三平方の定理を 空間の形 √(x² + y² + z²) で使おう。",
			"hint2": "√(%d + %d + %d)" % [dx * dx, dy * dy, dz * dz],
			"expl": "差は (%d, %d, %d)。距離 = √%d = %d です。" % [
				dx, dy, dz, dx * dx + dy * dy + dz * dz, dist],
			"fig": {"shapes": shapes},
		}
	if kind == 1:
		# 点と平面の距離
		var s2: Array = NORMALS[rng.randi_range(0, NORMALS.size() - 1)]
		var na: int = s2[0]
		var nb: int = s2[1]
		var nc: int = s2[2]
		var nn: int = s2[3]
		var px := rng.randi_range(-4, 4)
		var py := rng.randi_range(-4, 4)
		var pz := rng.randi_range(-4, 4)
		var k := rng.randi_range(1, 5)
		var d := k * nn - (na * px + nb * py + nc * pz)     # 距離が整数 k になるように決める
		var shapes2: Array = _axes3(6.0)
		var pv := Vector3(px, py, pz)
		var foot := pv - Vector3(na, nb, nc) * (float(k) / float(nn))
		# 平面は、垂線の足 H のまわりの正方形として描く(法線に垂直な 2 方向を取る)
		var nrm := Vector3(na, nb, nc).normalized()
		var u := nrm.cross(Vector3(0, 0, 1))
		if u.length() < 0.1:
			u = nrm.cross(Vector3(1, 0, 0))
		u = u.normalized() * 3.0
		var vv2 := nrm.cross(u).normalized() * 3.0
		shapes2.append(ProblemGen.poly([ProblemGen.proj3(foot + u + vv2),
			ProblemGen.proj3(foot - u + vv2), ProblemGen.proj3(foot - u - vv2),
			ProblemGen.proj3(foot + u - vv2)], ProblemGen.FILL_MAIN, ProblemGen.COL_DIM, 2.0))
		shapes2 += [
			ProblemGen.seg(ProblemGen.proj3(pv), ProblemGen.proj3(foot), ProblemGen.COL_YELLOW,
				3.0, true),
			ProblemGen.circle(ProblemGen.proj3(pv), 0.25, ProblemGen.COL_YELLOW, null, 0.0),
			ProblemGen.label(ProblemGen.proj3(pv) + Vector2(0.9, 0.6), "P",
				ProblemGen.COL_YELLOW, 26),
			ProblemGen.label(ProblemGen.proj3(foot) + Vector2(0.9, -0.6), "H",
				ProblemGen.COL_DIM, 26),
		]
		return {
			"q": "点 P(%d, %d, %d) と 平面 %s%s%s%s = 0 の距離を求めなさい。" % [
				px, py, pz, _term(na, "x"), _plus(nb, "y"), _plus(nc, "z"), _pnum(d)],
			"answer": float(k), "unit": "",
			"hint1": "点と平面の距離は |a x + b y + c z + d| ÷ √(a² + b² + c²)。平面版の公式だよ。",
			"hint2": "分母は √(%d + %d + %d) = %d" % [na * na, nb * nb, nc * nc, nn],
			"expl": "分子 = %d、分母 = %d なので 距離 = %d です。" % [k * nn, nn, k],
			"fig": {"shapes": shapes2},
		}
	# kind 2: 内分点(位置ベクトル)
	var m := rng.randi_range(1, 4)
	var n := rng.randi_range(1, 4)
	var ax := rng.randi_range(-4, 4)
	var ay := rng.randi_range(-4, 4)
	var az := rng.randi_range(-4, 4)
	var step := rng.randi_range(1, 3)
	var bx := ax + (m + n) * step
	var by := ay + (m + n) * step
	var bz := az - (m + n) * step
	var px2 := float(n * ax + m * bx) / float(m + n)
	var py2 := float(n * ay + m * by) / float(m + n)
	var pz2 := float(n * az + m * bz) / float(m + n)
	var which := rng.randi_range(0, 2)
	var ans := px2
	var label := "x"
	if which == 1:
		ans = py2
		label = "y"
	elif which == 2:
		ans = pz2
		label = "z"
	var a3b := Vector3(ax, ay, az)
	var b3b := Vector3(bx, by, bz)
	var p3b := Vector3(px2, py2, pz2)
	var shapes3: Array = _axes3(6.0)
	shapes3 += [
		ProblemGen.seg(ProblemGen.proj3(a3b), ProblemGen.proj3(b3b), Color(0.55, 0.85, 1.0), 3.0),
		ProblemGen.circle(ProblemGen.proj3(p3b), 0.25, ProblemGen.COL_YELLOW, null, 0.0),
		ProblemGen.label(ProblemGen.proj3(a3b) + Vector2(-0.9, -0.7), "A", ProblemGen.COL_DIM, 26),
		ProblemGen.label(ProblemGen.proj3(b3b) + Vector2(0.9, 0.5), "B", ProblemGen.COL_DIM, 26),
		ProblemGen.label(ProblemGen.proj3(p3b) + Vector2(0.9, -0.6), "P",
			ProblemGen.COL_YELLOW, 26),
	]
	return {
		"q": "空間の 2 点 A(%d, %d, %d)、B(%d, %d, %d) を %d:%d に内分する点 P の %s 座標を求めなさい。" % [
			ax, ay, az, bx, by, bz, m, n, label],
		"answer": ans, "unit": "",
		"hint1": "内分点の位置ベクトルは (n×A + m×B) ÷ (m + n)。座標ごとに同じ計算をすればいいよ。",
		"hint2": "(%d × A の %s 座標 + %d × B の %s 座標) ÷ %d" % [n, label, m, label, m + n],
		"expl": "P = ((%d×A + %d×B) ÷ %d) なので %s 座標は %s です。" % [
			n, m, m + n, label, ProblemGen.fmt(ans)],
		"fig": {"shapes": shapes3},
	}


## s24-原点: 原点と平面の距離、平面と座標軸の交点
static func _s24_origin(rng: RandomNumberGenerator) -> Dictionary:
	var s: Array = NORMALS[rng.randi_range(0, NORMALS.size() - 1)]
	var na: int = s[0]
	var nb: int = s[1]
	var nc: int = s[2]
	var nn: int = s[3]
	var k := rng.randi_range(1, 6)
	var d := k * nn
	var ask_dist := rng.randf() < 0.6
	var foot := Vector3(na, nb, nc) * (float(k) / float(nn))
	var shapes: Array = _axes3(6.0)
	shapes += [
		ProblemGen.seg(ProblemGen.proj3(Vector3.ZERO), ProblemGen.proj3(foot),
			ProblemGen.COL_YELLOW, 3.0, true),
		ProblemGen.circle(ProblemGen.proj3(foot), 0.25, ProblemGen.COL_YELLOW, null, 0.0),
		ProblemGen.label(ProblemGen.proj3(foot) + Vector2(0.9, 0.5), "H", ProblemGen.COL_YELLOW, 26),
		ProblemGen.label(ProblemGen.proj3(Vector3.ZERO) + Vector2(-0.9, -0.7), "O",
			ProblemGen.COL_DIM, 26),
	]
	if ask_dist:
		return {
			"q": "原点 O と 平面 %s%s%s = %d の距離を求めなさい。" % [
				_term(na, "x"), _plus(nb, "y"), _plus(nc, "z"), d],
			"answer": float(k), "unit": "",
			"hint1": "原点との距離なら公式の分子は |定数項| だけになるよ。",
			"hint2": "%d ÷ √(%d + %d + %d)" % [d, na * na, nb * nb, nc * nc],
			"expl": "距離 = %d ÷ %d = %d です。" % [d, nn, k],
			"fig": {"shapes": shapes},
		}
	return {
		"q": "平面 %s%s%s = %d が x 軸と交わる点の x 座標を求めなさい。" % [
			_term(na, "x"), _plus(nb, "y"), _plus(nc, "z"), d],
		"answer": float(d) / float(na), "unit": "",
		"hint1": "x 軸の上では y も z も 0。式に入れてみよう。",
		"hint2": "%dx = %d" % [na, d],
		"expl": "y = z = 0 を入れて x = %d ÷ %d = %s です。" % [
			d, na, ProblemGen.fmt(float(d) / float(na))],
		"fig": {"shapes": shapes},
	}
