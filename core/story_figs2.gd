class_name StoryFigs2
## ストーリーの追加した章(第11章〜第18章)で使う図。
## 本編に足した範囲 ― 立体・水そう・図形の移動・相似・方べき・チェバ ― を
## 「動かして見つける」形にしたもの。図の作り方は core/story_figs.gd と同じで、
## measure の図は動かせる点 p を受け取り、*_proof は動かない解説図。

const GOLD := Color(1.0, 0.85, 0.3)
const WHITE := Color(0.92, 0.95, 1.0)
const DIM := Color(0.62, 0.72, 0.88)
const WATER := Color(0.3, 0.6, 0.95, 0.4)
const SKY := Color(0.55, 0.85, 1.0)


static func spec(kind: String, p: Vector2) -> Dictionary:
	match kind:
		"tank":
			return _tank(p)
		"tank_proof":
			return _tank_proof()
		"shadow":
			return _shadow(p)
		"shadow_proof":
			return _shadow_proof()
		"overlap":
			return _overlap(p)
		"overlap_proof":
			return _overlap_proof()
		"box_diag":
			return _box_diag(p)
		"box_diag_proof":
			return _box_diag_proof()
		"cube_scale":
			return _cube_scale(p)
		"cube_scale_proof":
			return _cube_scale_proof()
		"cone_net":
			return _cone_net(p)
		"cone_net_proof":
			return _cone_net_proof()
		"power":
			return _power(p)
		"power_proof":
			return _power_proof()
		"ceva":
			return _ceva(p)
		"ceva_proof":
			return _ceva_proof()
	# 第19章から先の図は core/story_figs3.gd にある
	return StoryFigs3.spec(kind, p)


# ============ 第11章 水そうの深さ ============

## 水そうの右の壁を動かすと、同じ量の水でも深さが変わる
static func _tank(p: Vector2) -> Dictionary:
	var w: float = p.x
	var depth := StoryDefs.TANK_V / w
	var h := StoryDefs.TANK_H
	return {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(w, 0), Vector2(w, depth), Vector2(0, depth)],
			WATER, SKY, 3.0),
		ProblemGen.seg(Vector2(0, h), Vector2(0, 0), WHITE, 4.0),
		ProblemGen.seg(Vector2(0, 0), Vector2(w, 0), WHITE, 4.0),
		ProblemGen.seg(Vector2(w, 0), Vector2(w, h), WHITE, 4.0),
		ProblemGen.seg(Vector2(0, depth), Vector2(-1.2, depth), GOLD, 2.5, true),
		ProblemGen.label(Vector2(w * 0.5, -1.0), "幅 %.1f" % w, GOLD, 28),
		ProblemGen.label(Vector2(-2.6, depth), "深さ %.1f" % depth, GOLD, 28),
		ProblemGen.label(Vector2(w * 0.5, depth * 0.5), "水", SKY, 28),
	]}


## 同じ量の水を、幅のちがう水そうに入れてみた図
static func _tank_proof() -> Dictionary:
	var out: Array = []
	var pairs: Array = [[4.0, 0.0], [8.0, 7.0]]
	for pr in pairs:
		var w: float = pr[0]
		var x: float = pr[1]
		var d := StoryDefs.TANK_V / w
		out += [
			ProblemGen.poly([Vector2(x, 0), Vector2(x + w, 0), Vector2(x + w, d), Vector2(x, d)],
				WATER, SKY, 3.0),
			ProblemGen.seg(Vector2(x, 13.0), Vector2(x, 0), WHITE, 3.5),
			ProblemGen.seg(Vector2(x, 0), Vector2(x + w, 0), WHITE, 3.5),
			ProblemGen.seg(Vector2(x + w, 0), Vector2(x + w, 13.0), WHITE, 3.5),
			ProblemGen.label(Vector2(x + w * 0.5, -1.1), "幅 %.0f" % w, DIM, 26),
			ProblemGen.label(Vector2(x + w * 0.5, d + 0.9), "深さ %.0f" % d, GOLD, 26),
		]
	out.append(ProblemGen.label(Vector2(7.5, 14.5), "水の量はどちらも同じ", GOLD, 28))
	return {"shapes": out}


# ============ 第12章 影と相似 ============

## 太陽の向きを動かすと、杭と木の影が同時にのびちぢみする
static func _shadow(p: Vector2) -> Dictionary:
	var th := atan2(p.y, maxf(p.x, 0.1))
	var pole := StoryDefs.SHADOW_POLE
	var tree := StoryDefs.SHADOW_TREE
	var tx := StoryDefs.SHADOW_TREE_X
	var s1 := pole / tan(th)
	var s2 := tree / tan(th)
	return {"shapes": [
		ProblemGen.seg(Vector2(-2.0, 0), Vector2(tx + s2 + 2.0, 0), WHITE, 4.0),
		ProblemGen.seg(Vector2(0, 0), Vector2(0, pole), GOLD, 4.5),
		ProblemGen.seg(Vector2(0, pole), Vector2(s1, 0), DIM, 2.5, true),
		ProblemGen.seg(Vector2(0, 0), Vector2(s1, 0), SKY, 4.0),
		ProblemGen.seg(Vector2(tx, 0), Vector2(tx, tree), GOLD, 4.5),
		ProblemGen.seg(Vector2(tx, tree), Vector2(tx + s2, 0), DIM, 2.5, true),
		ProblemGen.seg(Vector2(tx, 0), Vector2(tx + s2, 0), SKY, 4.0),
		ProblemGen.label(Vector2(-1.6, pole * 0.5), "杭 %.0f" % pole, GOLD, 26),
		ProblemGen.label(Vector2(s1 * 0.5, -1.1), "影 %.1f" % s1, SKY, 26),
		ProblemGen.label(Vector2(tx - 1.8, tree * 0.5), "木 %.0f" % tree, GOLD, 26),
		ProblemGen.label(Vector2(tx + s2 * 0.5, -1.1), "影 %.1f" % s2, SKY, 26),
		ProblemGen.label(Vector2(0.6, pole + 1.6), "太陽の光", DIM, 24),
	]}


## 光は平行。だから杭の三角形と木の三角形は同じ形になる
static func _shadow_proof() -> Dictionary:
	var th := deg_to_rad(40.0)
	var pole := StoryDefs.SHADOW_POLE
	var tree := StoryDefs.SHADOW_TREE
	var tx := StoryDefs.SHADOW_TREE_X
	var s1 := pole / tan(th)
	var s2 := tree / tan(th)
	return {"shapes": [
		ProblemGen.seg(Vector2(-2.0, 0), Vector2(tx + s2 + 2.0, 0), WHITE, 4.0),
		ProblemGen.poly([Vector2(0, 0), Vector2(s1, 0), Vector2(0, pole)],
			ProblemGen.FILL_MAIN, GOLD, 3.0),
		ProblemGen.poly([Vector2(tx, 0), Vector2(tx + s2, 0), Vector2(tx, tree)],
			ProblemGen.FILL_SUB, GOLD, 3.0),
		ProblemGen.ang(Vector2(s1, 0), Vector2(0, 0), Vector2(0, pole), "同じ角", 1.8),
		ProblemGen.ang(Vector2(tx + s2, 0), Vector2(tx, 0), Vector2(tx, tree), "同じ角", 1.8),
		ProblemGen.right(Vector2(0, 0), Vector2(s1, 0), Vector2(0, pole)),
		ProblemGen.right(Vector2(tx, 0), Vector2(tx + s2, 0), Vector2(tx, tree)),
		ProblemGen.label(Vector2(tx * 0.5, tree + 1.5), "光は平行 → 2 つの三角形は同じ形", GOLD, 26),
	]}


# ============ 第13章 図形の移動と重なり ============

## 動く板が、止まっている板にどれだけ重なったか
static func _overlap(p: Vector2) -> Dictionary:
	var moved: float = p.x
	var h := StoryDefs.OVER_H
	var fix := StoryDefs.OVER_FIX
	var mv := StoryDefs.OVER_MOVE
	var left := moved - mv
	return {"shapes": [
		ProblemGen.poly([Vector2(0, 0), Vector2(fix, 0), Vector2(fix, h), Vector2(0, h)],
			ProblemGen.FILL_MAIN, WHITE, 3.0),
		ProblemGen.poly([Vector2(left, 0), Vector2(moved, 0), Vector2(moved, h), Vector2(left, h)],
			null, GOLD, 3.0),
		ProblemGen.poly([Vector2(0, 0), Vector2(moved, 0), Vector2(moved, h), Vector2(0, h)],
			ProblemGen.FILL_ACCENT, GOLD, 3.0),
		ProblemGen.arrow(Vector2(left - 2.5, h * 0.5), Vector2(left - 0.5, h * 0.5), GOLD),
		ProblemGen.label(Vector2(moved * 0.5, h * 0.5), "重なり", GOLD, 26),
		ProblemGen.label(Vector2(fix * 0.7, h + 1.0), "止まっている板", DIM, 24),
		ProblemGen.label(Vector2(left + 0.4, -1.1), "動く板", GOLD, 24),
		ProblemGen.label(Vector2(moved * 0.5, -1.1), "進んだ %.1f" % moved, SKY, 26),
	]}


## 重なりはいつも長方形。たては変わらず、よこだけが進んだ分のびる
static func _overlap_proof() -> Dictionary:
	var h := StoryDefs.OVER_H
	var out: Array = []
	for i in 3:
		var w := 2.0 + 2.5 * float(i)
		var x := float(i) * 8.0
		out += [
			ProblemGen.poly([Vector2(x, 0), Vector2(x + w, 0), Vector2(x + w, h), Vector2(x, h)],
				ProblemGen.FILL_ACCENT, GOLD, 3.0),
			ProblemGen.label(Vector2(x + w * 0.5, -1.1), "よこ %.1f" % w, SKY, 26),
			ProblemGen.label(Vector2(x - 1.4, h * 0.5), "%.0f" % h, GOLD, 26),
		]
	out.append(ProblemGen.label(Vector2(9.0, h + 1.6), "たてはいつも同じ。のびるのは よこ だけ", GOLD, 26))
	return {"shapes": out}


# ============ 第14章 直方体の対角線(空間の三平方) ============

## 直方体の枠を斜めから描く
static func _box_frame(w: float, d: float, h: float) -> Array:
	var v: Array = [
		Vector3(0, 0, 0), Vector3(w, 0, 0), Vector3(w, d, 0), Vector3(0, d, 0),
		Vector3(0, 0, h), Vector3(w, 0, h), Vector3(w, d, h), Vector3(0, d, h),
	]
	var edges: Array = [[0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7]]
	var out: Array = []
	for e in edges:
		var i: int = e[0]
		var j: int = e[1]
		var hidden := i == 3 or j == 3
		out.append(ProblemGen.seg(ProblemGen.proj3(v[i]), ProblemGen.proj3(v[j]),
			DIM if hidden else WHITE, 2.5, hidden))
	return out


## おくゆきと高さを動かすと、対角線の長さが変わる
static func _box_diag(p: Vector2) -> Dictionary:
	var w := StoryDefs.BOX_W
	var d: float = p.x
	var h: float = p.y
	var out: Array = _box_frame(w, d, h)
	out += [
		ProblemGen.seg(ProblemGen.proj3(Vector3.ZERO), ProblemGen.proj3(Vector3(w, d, h)),
			GOLD, 4.0),
		ProblemGen.seg(ProblemGen.proj3(Vector3.ZERO), ProblemGen.proj3(Vector3(w, d, 0)),
			SKY, 2.5, true),
		ProblemGen.label(ProblemGen.proj3(Vector3(w * 0.5, 0, 0)) + Vector2(0, -1.1),
			"よこ %.0f" % w, DIM, 26),
		ProblemGen.label(ProblemGen.proj3(Vector3(w, d * 0.5, 0)) + Vector2(1.2, -0.8),
			"おくゆき %.1f" % d, DIM, 26),
		ProblemGen.label(ProblemGen.proj3(Vector3(w, d, h * 0.5)) + Vector2(1.4, 0),
			"高さ %.1f" % h, DIM, 26),
		ProblemGen.label(ProblemGen.proj3(Vector3(w * 0.45, d * 0.45, h * 0.6)) + Vector2(-1.6, 0.6),
			"対角線 %.2f" % Vector3(w, d, h).length(), GOLD, 26),
	]
	return {"shapes": out}


## 三平方を 2 回。まず底面、つぎに高さ
static func _box_diag_proof() -> Dictionary:
	var w := StoryDefs.BOX_W
	var d := 4.0
	var h := 6.0
	var out: Array = _box_frame(w, d, h)
	out += [
		ProblemGen.poly([ProblemGen.proj3(Vector3.ZERO), ProblemGen.proj3(Vector3(w, d, 0)),
			ProblemGen.proj3(Vector3(w, d, h))], ProblemGen.FILL_ACCENT, GOLD, 3.0),
		ProblemGen.seg(ProblemGen.proj3(Vector3.ZERO), ProblemGen.proj3(Vector3(w, d, 0)),
			SKY, 3.0),
		ProblemGen.right(ProblemGen.proj3(Vector3(w, d, 0)), ProblemGen.proj3(Vector3.ZERO),
			ProblemGen.proj3(Vector3(w, d, h))),
		ProblemGen.label(ProblemGen.proj3(Vector3(w * 0.45, d * 0.45, 0)) + Vector2(0.4, -1.2),
			"底面の対角線", SKY, 26),
		ProblemGen.label(ProblemGen.proj3(Vector3(w * 0.4, d * 0.4, h * 0.7)) + Vector2(-1.2, 0.8),
			"ここでもう一度 三平方", GOLD, 26),
	]
	return {"shapes": out}


# ============ 第15章 相似比と体積比 ============

## 小さい箱と、それを k 倍にした箱を並べる
static func _cube_scale(p: Vector2) -> Dictionary:
	var k: float = p.x
	var b := StoryDefs.SCALE_BOX
	var out: Array = _box_frame(b.x, b.y, b.z)
	var shift := Vector2(b.x * 1.6 + 3.0, 0)
	var big: Array = _box_frame(b.x * k, b.y * k, b.z * k)
	for sh in big:
		var d: Dictionary = sh
		out.append(ProblemGen.seg((d["a"] as Vector2) + shift, (d["b"] as Vector2) + shift,
			GOLD if not bool(d.get("dash", false)) else DIM, 2.5, bool(d.get("dash", false))))
	out += [
		ProblemGen.label(ProblemGen.proj3(Vector3(b.x * 0.5, 0, 0)) + Vector2(0, -1.2),
			"もとの箱", DIM, 26),
		ProblemGen.label(ProblemGen.proj3(Vector3(b.x * k * 0.5, 0, 0)) + shift + Vector2(0, -1.2),
			"%.2f 倍にした箱" % k, GOLD, 26),
		ProblemGen.label(ProblemGen.proj3(Vector3(0, 0, b.z)) + Vector2(-1.0, 1.2),
			"体積 %.1f" % (b.x * b.y * b.z), DIM, 26),
		ProblemGen.label(ProblemGen.proj3(Vector3(0, 0, b.z * k)) + shift + Vector2(-1.0, 1.2),
			"体積 %.1f" % (b.x * b.y * b.z * k * k * k), GOLD, 26),
	]
	return {"shapes": out}


## たて・よこ・高さがそれぞれ 2 倍 → 小さい箱が 8 個入る
static func _cube_scale_proof() -> Dictionary:
	var b := StoryDefs.SCALE_BOX
	var out: Array = _box_frame(b.x * 2.0, b.y * 2.0, b.z * 2.0)
	for ix in 2:
		for iy in 2:
			for iz in 2:
				var o := Vector3(b.x * ix, b.y * iy, b.z * iz)
				out.append(ProblemGen.poly([
					ProblemGen.proj3(o), ProblemGen.proj3(o + Vector3(b.x, 0, 0)),
					ProblemGen.proj3(o + Vector3(b.x, 0, b.z)), ProblemGen.proj3(o + Vector3(0, 0, b.z)),
				], ProblemGen.FILL_MAIN, DIM, 1.5))
	out.append(ProblemGen.label(ProblemGen.proj3(Vector3(b.x, b.y * 2.0, b.z * 2.6)),
		"2 倍にすると 2×2×2 = 8 個分", GOLD, 28))
	return {"shapes": out}


# ============ 第16章 円錐の展開図 ============

## 母線を動かすと、側面のおうぎ形の中心角が変わる
static func _cone_net(p: Vector2) -> Dictionary:
	var l: float = p.x
	var r := StoryDefs.CONE_R
	var ang := 360.0 * r / l
	var arc_len := l * deg_to_rad(ang)
	var cx := l + r + 3.0
	return {"shapes": [
		ProblemGen.sector(Vector2.ZERO, l, 0.0, ang, ProblemGen.FILL_ACCENT, GOLD),
		ProblemGen.seg(Vector2.ZERO, Vector2(l, 0), GOLD, 3.0),
		ProblemGen.label(Vector2(l * 0.5, -1.0), "母線 %.1f" % l, GOLD, 26),
		ProblemGen.ang(Vector2.ZERO, Vector2(l, 0),
			Vector2(cos(deg_to_rad(ang)), sin(deg_to_rad(ang))) * l,
			"%d°" % roundi(ang), 1.7, ang > 180.0),
		ProblemGen.circle(Vector2(cx, -r - 1.0), r, ProblemGen.FILL_MAIN, WHITE, 3.0),
		ProblemGen.label(Vector2(cx, -2.0 * r - 2.4), "底面 半径 %.0f" % r, DIM, 26),
		ProblemGen.label(Vector2(cx, r + 0.6), "円周 %.2f" % (TAU * r), SKY, 26),
		ProblemGen.label(Vector2(l * 0.35, l * 0.75), "弧 %.2f" % arc_len, SKY, 26),
	]}


## ひらいた側面の弧が、底面の円のまわりにぴったり重なる
static func _cone_net_proof() -> Dictionary:
	var r := StoryDefs.CONE_R
	var l := 6.0
	var h := sqrt(maxf(l * l - r * r, 0.1))
	return {"shapes": [
		ProblemGen.seg(Vector2(-r, 0), Vector2(r, 0), WHITE, 3.0),
		ProblemGen.seg(Vector2(-r, 0), Vector2(0, h), WHITE, 3.0),
		ProblemGen.seg(Vector2(r, 0), Vector2(0, h), GOLD, 3.0),
		ProblemGen.arc(Vector2.ZERO, r, 180.0, 360.0, WHITE, 2.5),
		ProblemGen.arc(Vector2.ZERO, r, 0.0, 180.0, DIM, 2.0),
		ProblemGen.label(Vector2(r * 0.7, h * 0.55), "母線", GOLD, 26),
		ProblemGen.label(Vector2(0, -1.2), "この円のまわりの長さ", SKY, 26),
		ProblemGen.label(Vector2(0, h + 1.4), "ひらくと この長さが 弧 になる", GOLD, 26),
	]}


# ============ 第17章 方べきの定理 ============

## 円の外の点から引く割線の向きを変える
static func _power(p: Vector2) -> Dictionary:
	var pp := StoryDefs.POWER_P
	var r := StoryDefs.POWER_R
	var t: Array = StoryDefs.power_lengths(p)
	var u := (p - pp).normalized()
	var a := pp + u * float(t[0])
	var b := pp + u * float(t[1])
	return {"shapes": [
		ProblemGen.circle(Vector2.ZERO, r, ProblemGen.FILL_MAIN, WHITE, 3.0),
		ProblemGen.seg(pp, p, GOLD, 3.5),
		ProblemGen.circle(a, 0.22, GOLD, null, 0.0),
		ProblemGen.circle(b, 0.22, GOLD, null, 0.0),
		ProblemGen.label(pp + Vector2(-1.0, 0.0), "P", GOLD, 28),
		ProblemGen.label((pp + a) * 0.5 + Vector2(0, 1.0), "近い方 %.2f" % float(t[0]), SKY, 26),
		ProblemGen.label(b + Vector2(1.4, 1.0), "遠い方 %.2f" % float(t[1]), SKY, 26),
		ProblemGen.label(Vector2(0, -r - 1.4), "池", DIM, 24),
	]}


## 2 本の割線でできる三角形は、円周角が等しいので同じ形になる
static func _power_proof() -> Dictionary:
	var pp := StoryDefs.POWER_P
	var r := StoryDefs.POWER_R
	var u1 := Vector2(cos(deg_to_rad(14.0)), sin(deg_to_rad(14.0)))
	var u2 := Vector2(cos(deg_to_rad(-16.0)), sin(deg_to_rad(-16.0)))
	var t1: Array = StoryDefs.power_lengths(pp + u1 * 7.0)
	var t2: Array = StoryDefs.power_lengths(pp + u2 * 7.0)
	var a := pp + u1 * float(t1[0])
	var b := pp + u1 * float(t1[1])
	var c := pp + u2 * float(t2[0])
	var d := pp + u2 * float(t2[1])
	return {"shapes": [
		ProblemGen.circle(Vector2.ZERO, r, null, WHITE, 3.0),
		ProblemGen.seg(pp, b, GOLD, 3.0),
		ProblemGen.seg(pp, d, SKY, 3.0),
		ProblemGen.poly([pp, a, d], ProblemGen.FILL_ACCENT, GOLD, 2.5),
		ProblemGen.poly([pp, c, b], ProblemGen.FILL_SUB, SKY, 2.5),
		ProblemGen.label(pp + Vector2(-1.0, 0.0), "P", GOLD, 28),
		ProblemGen.label(a + Vector2(-0.2, 0.9), "A", DIM, 24),
		ProblemGen.label(b + Vector2(0.6, 0.6), "B", DIM, 24),
		ProblemGen.label(c + Vector2(-0.2, -1.0), "C", DIM, 24),
		ProblemGen.label(d + Vector2(0.6, -0.6), "D", DIM, 24),
		ProblemGen.label(Vector2(-2.0, -r - 2.0), "同じ弧を見る角は等しい → 2 つの三角形は同じ形", GOLD, 26),
	]}


# ============ 第18章 チェバの定理 ============

## 三角形の中の点を動かすと、3 つの比が同時に変わる
static func _ceva(p: Vector2) -> Dictionary:
	var a := StoryDefs.CEVA_A
	var b := StoryDefs.CEVA_B
	var c := StoryDefs.CEVA_C
	var pts: Array = StoryDefs.ceva_points(p)
	var d: Vector2 = pts[0]
	var e: Vector2 = pts[1]
	var f: Vector2 = pts[2]
	var r: Array = StoryDefs.ceva_ratios(p)
	return {"shapes": [
		ProblemGen.poly([a, b, c], ProblemGen.FILL_MAIN, WHITE, 3.5),
		ProblemGen.seg(a, d, GOLD, 3.0),
		ProblemGen.seg(b, e, GOLD, 3.0),
		ProblemGen.seg(c, f, GOLD, 3.0),
		ProblemGen.circle(p, 0.22, GOLD, null, 0.0),
		ProblemGen.label(a + Vector2(0, 0.9), "A"),
		ProblemGen.label(b + Vector2(-0.8, -0.6), "B"),
		ProblemGen.label(c + Vector2(0.8, -0.6), "C"),
		ProblemGen.label(d + Vector2(0, -1.0), "D", SKY, 24),
		ProblemGen.label(e + Vector2(0.9, 0.2), "E", SKY, 24),
		ProblemGen.label(f + Vector2(-0.9, 0.2), "F", SKY, 24),
		ProblemGen.label(p + Vector2(0.7, -0.5), "O", GOLD, 26),
		ProblemGen.label((a + f) * 0.5 + Vector2(-1.3, 0.2), "%.2f" % r[0], SKY, 24),
		ProblemGen.label((b + d) * 0.5 + Vector2(0, -1.0), "%.2f" % r[1], SKY, 24),
		ProblemGen.label((c + e) * 0.5 + Vector2(1.2, 0.2), "%.2f" % r[2], SKY, 24),
	]}


## 3 つの比は、どれも面積の比で書ける。かけると打ち消し合って 1 になる
static func _ceva_proof() -> Dictionary:
	var a := StoryDefs.CEVA_A
	var b := StoryDefs.CEVA_B
	var c := StoryDefs.CEVA_C
	var o := Vector2(4.3, 2.6)
	return {"shapes": [
		ProblemGen.poly([a, b, o], ProblemGen.FILL_MAIN, WHITE, 2.5),
		ProblemGen.poly([b, c, o], ProblemGen.FILL_SUB, WHITE, 2.5),
		ProblemGen.poly([c, a, o], ProblemGen.FILL_ACCENT, WHITE, 2.5),
		ProblemGen.label(a + Vector2(0, 0.9), "A"),
		ProblemGen.label(b + Vector2(-0.8, -0.6), "B"),
		ProblemGen.label(c + Vector2(0.8, -0.6), "C"),
		ProblemGen.label(o + Vector2(0.7, -0.5), "O", GOLD, 26),
		ProblemGen.label(Vector2(2.0, 1.2), "①", DIM, 28),
		ProblemGen.label(Vector2(4.6, 0.8), "②", DIM, 28),
		ProblemGen.label(Vector2(6.4, 3.4), "③", DIM, 28),
		ProblemGen.label(Vector2(4.0, 9.4), "AF:FB = ③:②   BD:DC = ①:③   CE:EA = ②:①", GOLD, 26),
		ProblemGen.label(Vector2(4.0, 10.8), "かけると 分母と分子がすべて消えて 1", GOLD, 26),
	]}
