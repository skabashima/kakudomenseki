extends Control
class_name NetView
## 展開図が 立ち上がって 立体に なる ところを 見せる Control。
##
## t = 0 で 展開図(まっすぐ 正面から 見た 形)、t = 1 で 立体。
## ★ 見え方も いっしょに 変える。立体の 図は ななめ から 見る 向き
##   (ProblemGen.proj3)で 描いているが、展開図を その 向きで 描くと
##   ゆがんで 見えて「展開図に 見えない」。t で 正面 → ななめ へ 混ぜる。
##
## 折り方そのものは NetDefs が 持っている(閉じるかは tests/net_check.gd が 見る)。

const MARGIN := 26.0
const FOLD_SECONDS := 1.7
const SPIN_SPEED := 0.35

## 面の 色。となり合う 面が 同じ 色に ならないように 順に つかう
const FACE_COLS: Array = [
	Color(0.36, 0.62, 0.92), Color(0.42, 0.76, 0.62), Color(0.92, 0.66, 0.30),
	Color(0.80, 0.48, 0.62), Color(0.55, 0.55, 0.86), Color(0.40, 0.72, 0.82),
]
const EDGE_COL := Color(0.13, 0.17, 0.24, 0.9)
## まるい 立体(円柱・円錐)の 側面。細かく 分けた 面を 1 色で 塗って 曲面に 見せる
const ROUND_COL := Color(0.40, 0.70, 0.86)
## その 底面と ふた。★ ぜんぶ 同じ 色に すると どこが 何か 分からない
const CAP_COL := Color(0.92, 0.66, 0.30)

var net: Dictionary = {}
## 面に 書く 文字(面の 番号ごと)。さいころの 目など。空なら 何も 書かない
var pips: Array = []
var t := 0.0
var spin := 0.0
var _playing := false
var _spinning := false
## 折れぐあい 0〜1 を 8 等分した ところの 大きさ。間は つないで つかう。
## 展開図(横に 長い)と 立体(小さくまとまる)では 入れ物の 形が まるで ちがうので、
## どちらかに 合わせると 片方が すみに 小さく 出る
var _samples: Array = []
## まわす ときの 軸(立体の まん中)
var _spin_pivot := Vector2.ZERO

signal folded


## ★ 見せるだけの Control。ボタンの 上に のせても タップを 食わないように、
##   はじめから 入力を 通す(ここを STOP のままに すると ボタンが 押せなくなる)
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## still = true は 一覧の 小さな 見本。動かさないので、展開図の ときの
## 大きさだけ 測る(101 まいぶん 全部 測ると 一覧を 開くのが おそくなる)
func show_net(n: Dictionary, still := false) -> void:
	net = n
	t = 0.0
	spin = 0.0
	_playing = false
	_spinning = false
	set_process(false)
	_measure(still)
	queue_redraw()


## 立ち上げる。終わったら ゆっくり 回りつづける
func fold_up() -> void:
	if net.is_empty():
		return
	_playing = true
	_spinning = false
	set_process(true)


## 展開図に もどす
func unfold() -> void:
	t = 0.0
	spin = 0.0
	_playing = false
	_spinning = false
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	if _playing:
		t = minf(1.0, t + delta / FOLD_SECONDS)
		if t >= 1.0:
			_playing = false
			_spinning = true
			folded.emit()
	elif _spinning:
		spin += delta * SPIN_SPEED
	queue_redraw()


## 展開図の ときと 立体の ときの 両方が 入る 大きさを 先に 決めておく。
## 毎コマ 測ると 折れる たびに 拡大率が 変わって 画面が はねる
func _measure(still := false) -> void:
	_samples.clear()
	var steps := 1 if still else 9
	for i in steps:
		var tt := 0.0 if still else float(i) / 8.0
		var faces: Array = NetDefs.fold(net, _ease(tt))
		var pivot := _pivot(faces)
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		# まわして 見せる ぶんも 入れておく(回っても はみ出さない)
		for turn in [0.0, PI * 0.5, PI]:
			for f in faces:
				for p in f:
					var q := _screen(_spun(p as Vector3, turn * tt, pivot), tt, 0.0)
					lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
					hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
		var pad := (hi - lo) * 0.06
		_samples.append(Rect2(lo - pad, (hi - lo) + pad * 2.0))


## いまの 折れぐあいの 入れ物。測った ところの 間は つないで 出す
func _bounds_at(tt: float) -> Rect2:
	if _samples.is_empty():
		return Rect2(-1, -1, 2, 2)
	if _samples.size() == 1:
		return _samples[0]
	var f := clampf(tt, 0.0, 1.0) * float(_samples.size() - 1)
	var i := mini(int(f), _samples.size() - 2)
	var k := f - float(i)
	var a: Rect2 = _samples[i]
	var b: Rect2 = _samples[i + 1]
	return Rect2(a.position.lerp(b.position, k), a.size.lerp(b.size, k))


## 折れぐあいを なめらかに(はじめ ゆっくり、おわり ゆっくり)
static func _ease(v: float) -> float:
	return v * v * (3.0 - 2.0 * v)


## 3D の 点を 画面の 向きへ。t = 0 は 正面、t = 1 は ななめ(proj3 と 同じ)
static func _screen(p: Vector3, tt: float, _unused: float) -> Vector2:
	return Vector2(p.x + 0.42 * tt * p.y, (1.0 - tt) * p.y + tt * (p.z + 0.30 * p.y))


## ★ まわすときは 立体の まん中を 軸に する。原点まわりに 回すと、
##   まん中が 原点から はなれている 展開図(円錐など)が 大きく ふりまわされて、
##   入れ物だけ 巨大に なり 立体が 豆つぶに なる
static func _spun(p: Vector3, a: float, pivot: Vector2) -> Vector3:
	if a == 0.0:
		return p
	var d := Vector2(p.x - pivot.x, p.y - pivot.y).rotated(a)
	return Vector3(pivot.x + d.x, pivot.y + d.y, p.z)


## 折れた 形の まん中(x, y)
static func _pivot(faces: Array) -> Vector2:
	var c := Vector2.ZERO
	var n := 0
	for f in faces:
		for p in f:
			var v: Vector3 = p
			c += Vector2(v.x, v.y)
			n += 1
	return c / float(maxi(1, n))


## 奥行き(大きいほど 遠い)。proj3 で つぶれる 向きに そって 測る
static func _depth(p: Vector3) -> float:
	return -0.42 * p.x + p.y - 0.30 * p.z


func _draw() -> void:
	if net.is_empty():
		return
	var e := _ease(t)
	var faces: Array = NetDefs.fold(net, e)
	_spin_pivot = _pivot(faces)
	var box := _bounds_at(t)
	var scale := minf((size.x - MARGIN * 2.0) / maxf(0.001, box.size.x),
		(size.y - MARGIN * 2.0) / maxf(0.001, box.size.y))
	var mid := box.position + box.size * 0.5
	var center := size * 0.5

	# 奥に ある 面から 先に 塗る(手前の 面が あとから かぶさる)
	var order: Array = []
	for i in faces.size():
		var d := 0.0
		var pts: Array = faces[i]
		for p in pts:
			d += _depth(_turned(p as Vector3, e))
		order.append({"i": i, "d": d / float(maxi(1, pts.size()))})
	order.sort_custom(func(a, b): return float(a["d"]) > float(b["d"]))

	var round_net := bool(net.get("round", false))
	var caps: Array = net.get("cap", [])
	for row in order:
		var idx := int(row["i"])
		# まるい 立体の 側面だけ 線を 描かない。ふた(円)は ふつうに 描く
		var soft := round_net and not caps.has(idx)
		var poly := PackedVector2Array()
		for p in faces[idx]:
			var q := _screen(_turned(p as Vector3, e), t, 0.0)
			poly.append(center + Vector2((q.x - mid.x) * scale, -(q.y - mid.y) * scale))
		if poly.size() < 3:
			continue
		# ★ 円柱・円錐は 24 に 分けた 角柱・角錐として 折っている。
		#   面ごとに 色を 変えると しま模様に 見えて 曲面に ならないので、
		#   まるい ものは 1 色で 塗り、分け目の 線も 描かない
		var col: Color = FACE_COLS[idx % FACE_COLS.size()]
		if round_net:
			col = CAP_COL if caps.has(idx) else ROUND_COL
		# 立体に なるほど 面ごとの 明るさに 差を つける(向きが 分かる)
		col = col.lightened(_shade(faces[idx]) * (0.22 if soft else 0.35) * t)
		draw_colored_polygon(poly, col)
		if not soft:
			var line := PackedVector2Array(poly)
			line.append(poly[0])
			draw_polyline(line, EDGE_COL, 3.0, true)
		# 面の 文字(さいころの 目)。奥の 面から 順に 描いているので、
		# 手前の 面に かくれる ものは そのまま かくれる ―― それで 正しい
		if idx < pips.size() and String(pips[idx]) != "":
			var mid_p := Vector2.ZERO
			for q2 in poly:
				mid_p += q2
			mid_p /= float(poly.size())
			var font := ThemeDB.fallback_font
			var txt := String(pips[idx])
			var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
			draw_string(font, mid_p + Vector2(-w * 0.5, 11), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(0.12, 0.16, 0.22))
	if round_net:
		# 側面の 分け目は 描いていないので、外がわの わくを なぞって 輪かくを 出す
		_draw_outline(faces, e, scale, mid, center)


## まわして 見せる ぶん(立体に なってから)
func _turned(p: Vector3, e: float) -> Vector3:
	if spin == 0.0:
		return p
	return _spun(p, spin * e, _spin_pivot)


## 上を 向いている 面ほど 明るく
func _shade(pts: Array) -> float:
	if pts.size() < 3:
		return 0.0
	var a: Vector3 = pts[0]
	var b: Vector3 = pts[1]
	var c: Vector3 = pts[2]
	var n := (b - a).cross(c - a)
	if n.length() < 0.0001:
		return 0.0
	return absf(n.normalized().z)


## 円柱・円錐の わく。面が 24 枚 あって 分けた 線は うすくしてあるので、
## 外がわに 見える 形(凸包)だけを 濃く なぞって 輪かくを 出す
func _draw_outline(faces: Array, e: float, scale: float, mid: Vector2,
		center: Vector2) -> void:
	var pts := PackedVector2Array()
	for f in faces:
		for p in f:
			var q := _screen(_turned(p as Vector3, e), t, 0.0)
			pts.append(center + Vector2((q.x - mid.x) * scale, -(q.y - mid.y) * scale))
	var hull := Geometry2D.convex_hull(pts)
	if hull.size() >= 3:
		draw_polyline(hull, EDGE_COL, 3.0, true)
