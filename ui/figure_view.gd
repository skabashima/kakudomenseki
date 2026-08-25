extends Control
class_name FigureView
## 問題の図形を描く Control。
## ProblemGen が作る「図形スペック」(shapes の配列)を受け取り、
## 論理座標(y 上向き)を自動でスケーリング・上下反転して描画する。

var spec: Dictionary = {}

## 論理座標 → 画面座標の変換
var _scale := 1.0
var _offset := Vector2.ZERO

const MARGIN := 60.0
const COL_LINE := Color(0.92, 0.95, 1.0)
const COL_ANGLE := Color(0.75, 0.85, 1.0)
const COL_UNKNOWN := Color(1.0, 0.85, 0.3)

# ---------------------------------------------------------
# 補助線: ペンモード中は図の上をなぞって直線が引ける。
# 端点は頂点・中点・円の中心などにスナップする
# ---------------------------------------------------------
const COL_AUX := Color(0.45, 1.0, 0.6, 0.95)
## 手書き(補助線モードでないときの書き込み)の色。補助線と見分けがつく色にする
const COL_FREE := Color(1.0, 0.92, 0.55, 0.95)
const COL_SNAP := Color(0.6, 0.9, 1.0, 0.4)
const SNAP_PX := 36.0

var aux_enabled := false:
	set(v):
		aux_enabled = v
		queue_redraw()

# ---------------------------------------------------------
# 解き方アニメ: ステップごとに図形をフェードインで重ねる
# ---------------------------------------------------------
## {"sh": 図形スペック, "born": 追加時刻 msec} の配列
var overlay_shapes: Array = []
## 描画中の透明度係数(オーバーレイのフェードインに使う)
var _omul := 1.0


func add_overlay(shapes: Array) -> void:
	var now := Time.get_ticks_msec()
	for sh in shapes:
		overlay_shapes.append({"sh": sh, "born": now})
	set_process(true)
	queue_redraw()


func clear_overlay() -> void:
	overlay_shapes.clear()
	queue_redraw()


func _process(_delta: float) -> void:
	# フェードイン中だけ毎フレーム描き直す(_draw 側で完了を検知して止める)
	queue_redraw()


## 色にオーバーレイの透明度を適用する
func _c(col: Color) -> Color:
	col.a *= _omul
	return col
## 引いた補助線([始点, 終点] の論理座標)
var aux_lines: Array = []
## 物語モード: つまんで動かせる点(論理座標)。空のときは従来どおり描くだけ。
## 動かすと point_dragged が飛ぶので、受け手が図のスペックを作り直す
signal point_dragged(index: int, to: Vector2)
var drag_points: Array = []
var _drag_idx := -1

## 手書きを受け付けるか。本編では true、ストーリーでは false
var free_draw_enabled := true

## 手書きの線(論理座標の点列)。補助線モードでないときに指でなぞると増える
var free_strokes: Array = []
var _free_cur := PackedVector2Array()
## 「もどす」で最後に描いたものを消すための順番("aux" / "free")
var _undo_order: Array = []
## スナップ候補(論理座標)。set_spec で図形から集める
var _snap_pts: Array = []
var _aux_start = null      # Vector2 or null
var _aux_preview = null


func set_spec(s: Dictionary) -> void:
	spec = s
	aux_lines.clear()
	free_strokes.clear()
	_free_cur = PackedVector2Array()
	_undo_order.clear()
	overlay_shapes.clear()
	_aux_start = null
	_aux_preview = null
	_collect_snap_points()
	queue_redraw()


## 「もどす」: 最後に描いたものを 1 つ消す(補助線と手書きのどちらでも)
func aux_undo() -> void:
	if _undo_order.is_empty():
		return
	var kind := String(_undo_order.pop_back())
	if kind == "aux" and not aux_lines.is_empty():
		aux_lines.pop_back()
	elif kind == "free" and not free_strokes.is_empty():
		free_strokes.pop_back()
	queue_redraw()


## 図形から補助線の吸着先(頂点・中点・中心)を集める
func _collect_snap_points() -> void:
	_snap_pts.clear()
	var add := func(p: Vector2) -> void:
		for q in _snap_pts:
			if p.distance_to(q) < 0.05:
				return
		_snap_pts.append(p)
	for sh in spec.get("shapes", []):
		match String(sh["t"]):
			"poly":
				var pts: Array = sh["p"]
				for i in pts.size():
					add.call(pts[i])
					add.call((pts[i] + pts[(i + 1) % pts.size()]) * 0.5)
			"seg", "arrow":
				add.call(sh["a"])
				add.call(sh["b"])
				add.call((sh["a"] + sh["b"]) * 0.5)
			"circle", "sector", "arc":
				add.call(sh["c"])
			"angle":
				add.call(sh["at"])


func _to_logical(px: Vector2) -> Vector2:
	if _scale == 0.0:
		return Vector2.ZERO
	return Vector2((px.x - _offset.x) / _scale, -(px.y - _offset.y) / _scale)


func _snap(logical: Vector2) -> Vector2:
	var best := logical
	var best_d := SNAP_PX / _scale
	for p in _snap_pts:
		var d: float = logical.distance_to(p)
		if d < best_d:
			best_d = d
			best = p
	return best


## 図の上の入力。
##   補助線モード(aux_enabled): 2 点を結ぶまっすぐな線。端点は頂点・中点・中心に吸着する
##   ふつうのとき: 指でなぞったとおりに書ける(図への書き込み・メモ用)
func _gui_input(event: InputEvent) -> void:
	var pos: Vector2
	var pressed_change := false
	var pressed := false
	if event is InputEventScreenTouch:
		pos = event.position
		pressed_change = true
		pressed = event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
		pressed_change = true
		pressed = event.pressed
	elif event is InputEventScreenDrag:
		pos = event.position
	elif event is InputEventMouseMotion:
		if not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			return
		pos = event.position
	else:
		return
	accept_event()
	if not drag_points.is_empty():
		_input_drag(pos, pressed_change, pressed)
		return
	if aux_enabled:
		_input_aux(pos, pressed_change, pressed)
	elif free_draw_enabled:
		_input_free(pos, pressed_change, pressed)


## 物語モード: 近くの点をつまんで動かす(離すまで追従する)
func _input_drag(pos: Vector2, pressed_change: bool, pressed: bool) -> void:
	if pressed_change and not pressed:
		_drag_idx = -1
		return
	var lp := _to_logical(pos)
	if pressed_change and pressed:
		var best := -1
		var best_d := 70.0 / maxf(_scale, 0.001)
		for i in drag_points.size():
			var d: float = lp.distance_to(drag_points[i])
			if d < best_d:
				best_d = d
				best = i
		_drag_idx = best
	if _drag_idx >= 0:
		point_dragged.emit(_drag_idx, lp)


## 補助線モード: 押した点から離した点までを直線で結ぶ(端点は吸着)
func _input_aux(pos: Vector2, pressed_change: bool, pressed: bool) -> void:
	if pressed_change:
		if pressed:
			_aux_start = _snap(_to_logical(pos))
			_aux_preview = _aux_start
		else:
			var far_enough := _aux_start != null and _aux_preview != null
			if far_enough and (_aux_start as Vector2).distance_to(_aux_preview) * _scale > 14.0:
				aux_lines.append([_aux_start, _aux_preview])
				_undo_order.append("aux")
			_aux_start = null
			_aux_preview = null
		queue_redraw()
	elif _aux_start != null:
		_aux_preview = _snap(_to_logical(pos))
		queue_redraw()


## 手書き: なぞった点をそのまま線にする。点が増えすぎないよう間引く
func _input_free(pos: Vector2, pressed_change: bool, pressed: bool) -> void:
	var lp := _to_logical(pos)
	if pressed_change:
		if pressed:
			_free_cur = PackedVector2Array([lp])
		else:
			if _free_cur.size() >= 2:
				free_strokes.append(_free_cur)
				_undo_order.append("free")
			_free_cur = PackedVector2Array()
		queue_redraw()
	elif not _free_cur.is_empty():
		if _free_cur[_free_cur.size() - 1].distance_to(lp) * _scale > 3.0:
			_free_cur.append(lp)
			queue_redraw()


func _px(p: Vector2) -> Vector2:
	return Vector2(p.x * _scale, -p.y * _scale) + _offset


func _collect_bounds() -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var pts: Array = []
	# 解き方アニメで 図の外に 形を たす台本(台形を もう 1 つ ならべる 等)も
	# 入るように、オーバーレイも 縮尺の 計算に 含める(出た時点で 引きで 収まる)
	var shapes: Array = spec.get("shapes", []).duplicate()
	for e in overlay_shapes:
		shapes.append(e["sh"])
	for sh in shapes:
		match String(sh["t"]):
			"poly", "curve":
				for p in sh["p"]:
					pts.append(p)
			"seg", "arrow", "tick":
				pts.append(sh["a"])
				pts.append(sh["b"])
			"circle":
				var c: Vector2 = sh["c"]
				var r: float = sh["r"]
				pts.append(c + Vector2(r, r))
				pts.append(c - Vector2(r, r))
			"sector", "arc":
				var c2: Vector2 = sh["c"]
				var r2: float = sh["r"]
				pts.append(c2 + Vector2(r2, r2))
				pts.append(c2 - Vector2(r2, r2))
			"text":
				pts.append(sh["at"])
			"grid", "axes":
				pts.append(sh["from"])
				pts.append(sh["to"])
			"leaf":
				pts.append(Vector2.ZERO)
				pts.append(Vector2(sh["a"], sh["a"]))
			"lune":
				# 半円が三角形の外へふくらむ分も正確に含める。
				# 左は縦の辺の半円(x = −a/2)か斜辺半円の左端、
				# 下は横の辺の半円(y = −b/2)か斜辺半円の下端の遠い方
				var a: float = sh["a"]
				var b: float = sh["b"]
				var hyp_r := sqrt(a * a + b * b) * 0.5
				pts.append(Vector2(minf(-a * 0.5, b * 0.5 - hyp_r),
					minf(-b * 0.5, a * 0.5 - hyp_r)))
				pts.append(Vector2(b, a))
	for p in pts:
		lo.x = minf(lo.x, p.x)
		lo.y = minf(lo.y, p.y)
		hi.x = maxf(hi.x, p.x)
		hi.y = maxf(hi.y, p.y)
	if lo.x > hi.x:
		return Rect2(0, 0, 1, 1)
	# ラベルの文字がはみ出ないよう少し広げる
	var pad := maxf(hi.x - lo.x, hi.y - lo.y) * 0.12 + 0.001
	lo -= Vector2(pad, pad)
	hi += Vector2(pad, pad)
	return Rect2(lo, hi - lo)


func _draw() -> void:
	if spec.is_empty():
		return
	var b := _collect_bounds()
	var avail := size - Vector2(MARGIN, MARGIN) * 2.0
	if avail.x <= 0 or avail.y <= 0:
		return
	_scale = minf(avail.x / b.size.x, avail.y / b.size.y)
	# 中央寄せ(y は反転するので上端が -hi.y)
	var center_logical := b.position + b.size * 0.5
	_offset = size * 0.5 - Vector2(center_logical.x * _scale, -center_logical.y * _scale)

	for sh in spec.get("shapes", []):
		_draw_one(sh)

	# --- 解き方アニメのオーバーレイ ---
	# 線や弧は「端からすっと引かれ」、多角形は「輪郭をなぞってから塗られ」、
	# from_p つきの形は「元の場所から動いて」現れる(ease in-out)
	var now := Time.get_ticks_msec()
	var animating := false
	for e in overlay_shapes:
		var sh: Dictionary = e["sh"]
		var el := float(now - int(e["born"])) - float(sh.get("delay", 0.0))
		if el <= 0.0:
			animating = true
			continue
		var t := clampf(el / float(sh.get("dur", 450.0)), 0.0, 1.0)
		if t < 1.0:
			animating = true
		_draw_overlay_shape(sh, t)
	_omul = 1.0
	if not animating:
		set_process(false)

	# --- 補助線(ペンモード)---
	if aux_enabled:
		for p in _snap_pts:
			draw_circle(_px(p), 5.0, COL_SNAP)
	for ln in aux_lines:
		_draw_aux_line(ln[0], ln[1], 1.0)
	if _aux_start != null and _aux_preview != null:
		_draw_aux_line(_aux_start, _aux_preview, 0.55)

	# --- つまんで動かせる点(物語モード)---
	for p in drag_points:
		draw_circle(_px(p), 15.0, Color(1.0, 0.85, 0.35, 0.25))
		draw_circle(_px(p), 9.0, Color(1.0, 0.85, 0.35, 0.95))

	# --- 手書き(補助線モードでないときの書き込み)---
	for st in free_strokes:
		_draw_free(st)
	_draw_free(_free_cur)


## なぞった点列を線でつなぐ
func _draw_free(pts: PackedVector2Array) -> void:
	if pts.size() < 2:
		return
	var px := PackedVector2Array()
	for p in pts:
		px.append(_px(p))
	draw_polyline(px, COL_FREE, 3.5, true)


func _draw_aux_line(a: Vector2, b: Vector2, alpha: float) -> void:
	var col := COL_AUX
	col.a *= alpha
	draw_dashed_line(_px(a), _px(b), col, 3.5, 14.0)
	draw_circle(_px(a), 4.5, col)
	draw_circle(_px(b), 4.5, col)


func _draw_one(sh: Dictionary) -> void:
	match String(sh["t"]):
		"grid":
			_draw_grid(sh)
		"axes":
			_draw_axes(sh)
		"poly":
			_draw_poly(sh)
		"curve":
			_draw_curve(sh)
		"seg":
			_draw_seg(sh)
		"circle":
			_draw_circle_sh(sh)
		"sector":
			_draw_sector(sh)
		"arc":
			_draw_arc_sh(sh)
		"angle":
			_draw_angle(sh)
		"right":
			_draw_right(sh)
		"tick":
			_draw_tick(sh)
		"text":
			_draw_label(sh)
		"arrow":
			_draw_arrow(sh)
		"leaf":
			_draw_leaf(sh)
		"lune":
			_draw_lune(sh)


## オーバーレイ 1 つ分を、進みぐあい t(0..1)に合わせて描く。
## anim 指定が無くても、線・矢印・弧は「引かれていく」動きにする
func _draw_overlay_shape(sh: Dictionary, t: float) -> void:
	var k := t * t * (3.0 - 2.0 * t)      # ease in-out
	var kind := String(sh["t"])
	var anim := String(sh.get("anim", ""))
	if sh.has("from_p") or sh.has("from_at"):
		anim = "morph"
	elif anim == "":
		anim = "draw" if kind in ["seg", "arrow", "arc", "poly"] else "fade"
	match anim:
		"draw":
			_omul = 1.0
			match kind:
				"seg", "arrow":
					var d := sh.duplicate()
					d["b"] = (sh["a"] as Vector2).lerp(sh["b"], k)
					_draw_one(d)
				"arc":
					var d2 := sh.duplicate()
					d2["a1"] = lerpf(float(sh["a0"]), float(sh["a1"]), k)
					if absf(float(d2["a1"]) - float(sh["a0"])) > 0.5:
						_draw_one(d2)
				"poly":
					_draw_poly_partial(sh, t, k)
				_:
					_omul = maxf(k, 0.06)
					_draw_one(sh)
		"morph":
			# 元の場所(from_p / from_at)から本来の場所へ動かしながら描く
			_omul = minf(t * 4.0 + 0.1, 1.0)
			var d3 := sh.duplicate()
			if kind == "poly" and sh.has("from_p"):
				var from: Array = sh["from_p"]
				var to: Array = sh["p"]
				var pts: Array = []
				var spread := 0.0
				for i in to.size():
					var p: Vector2 = (from[i % from.size()] as Vector2).lerp(to[i], k)
					pts.append(p)
					spread = maxf(spread, p.distance_to(pts[0]))
				# 点対称の移動(さかさま くっつけ 等)は 中間で 1 点に つぶれる。
				# その瞬間だけ 描かない(裏返る カードフリップに 見える)
				if spread < 0.05:
					return
				d3["p"] = pts
			elif kind == "text" and sh.has("from_at"):
				d3["at"] = (sh["from_at"] as Vector2).lerp(sh["at"], k)
			_draw_one(d3)
		_:
			_omul = maxf(k, 0.06)
			_draw_one(sh)


## 多角形の「なぞり描き」: 輪郭を一筆書きで引いてから、塗りをふわっと入れる
func _draw_poly_partial(sh: Dictionary, t: float, k: float) -> void:
	var pts := _pts_px(sh["p"])
	if pts.size() < 2:
		return
	var closed := pts.duplicate()
	closed.append(pts[0])
	var total := 0.0
	for i in closed.size() - 1:
		total += closed[i].distance_to(closed[i + 1])
	if sh.has("fill"):
		var fill: Color = sh["fill"]
		fill.a *= clampf((t - 0.55) / 0.45, 0.0, 1.0) * _omul
		if fill.a > 0.004:
			var tmp := sh.duplicate()
			tmp["w"] = 0.0
			tmp["fill"] = fill
			var keep := _omul
			_omul = 1.0
			_draw_one(tmp)
			_omul = keep
	var w: float = sh.get("w", 4.0)
	if w <= 0.0 or total <= 0.0:
		return
	var stroke: Color = sh.get("stroke", COL_LINE) if sh.get("stroke") != null else COL_LINE
	stroke.a *= _omul
	var left := total * k
	var out := PackedVector2Array([closed[0]])
	for i in closed.size() - 1:
		var seg_len := closed[i].distance_to(closed[i + 1])
		if seg_len >= left:
			out.append(closed[i].lerp(closed[i + 1], left / maxf(seg_len, 0.001)))
			break
		out.append(closed[i + 1])
		left -= seg_len
	if out.size() >= 2:
		draw_polyline(out, stroke, w, true)


func _pts_px(arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in arr:
		out.append(_px(p))
	return out


func _draw_poly(sh: Dictionary) -> void:
	var pts := _pts_px(sh["p"])
	if sh.has("fill"):
		# 凹多角形(ブーメラン形など)も正しく塗れるよう三角形に分割して描く
		var indices := Geometry2D.triangulate_polygon(pts)
		if indices.is_empty():
			draw_colored_polygon(pts, _c(sh["fill"]))
		else:
			for i in range(0, indices.size(), 3):
				var q1 := pts[indices[i]]
				var q2 := pts[indices[i + 1]]
				var q3 := pts[indices[i + 2]]
				# ほぼ面積 0 の三角形は描画エラーになる(見た目にも影響しない)ので飛ばす
				if absf((q2 - q1).cross(q3 - q1)) < 0.01:
					continue
				draw_colored_polygon(PackedVector2Array([q1, q2, q3]), _c(sh["fill"]))
	var w: float = sh.get("w", 4.0)
	if w > 0.0:
		var stroke: Color = sh.get("stroke", COL_LINE) if sh.get("stroke") != null else COL_LINE
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, _c(stroke), w, true)


func _draw_curve(sh: Dictionary) -> void:
	var pts := _pts_px(sh["p"])
	draw_polyline(pts, _c(sh.get("color", COL_LINE)), sh.get("w", 4.0), true)


func _draw_seg(sh: Dictionary) -> void:
	var a := _px(sh["a"])
	var b := _px(sh["b"])
	var col: Color = sh.get("color", COL_LINE)
	if sh.get("dash", false):
		draw_dashed_line(a, b, _c(col), sh.get("w", 4.0), 12.0)
	else:
		draw_line(a, b, _c(col), sh.get("w", 4.0), true)


func _draw_circle_sh(sh: Dictionary) -> void:
	var c := _px(sh["c"])
	var r: float = sh["r"] * _scale
	if sh.has("fill"):
		draw_circle(c, r, _c(sh["fill"]))
	if sh.get("w", 4.0) > 0.0 and (sh.has("stroke") or not sh.has("fill")):
		var stroke: Color = sh.get("stroke", COL_LINE) if sh.get("stroke") != null else COL_LINE
		draw_arc(c, r, 0.0, TAU, 64, _c(stroke), sh.get("w", 4.0), true)


func _draw_sector(sh: Dictionary) -> void:
	var c := _px(sh["c"])
	var r: float = sh["r"] * _scale
	var a0: float = deg_to_rad(sh["a0"])
	var a1: float = deg_to_rad(sh["a1"])
	var pts := PackedVector2Array([c])
	var n := 48
	for i in n + 1:
		var t: float = a0 + (a1 - a0) * i / n
		pts.append(c + Vector2(cos(t), -sin(t)) * r)
	if sh.has("fill"):
		draw_colored_polygon(pts, _c(sh["fill"]))
	var stroke: Color = sh.get("stroke", COL_LINE) if sh.get("stroke") != null else COL_LINE
	var closed := pts.duplicate()
	closed.append(c)
	draw_polyline(closed, _c(stroke), 4.0, true)


func _draw_arc_sh(sh: Dictionary) -> void:
	var c := _px(sh["c"])
	var r: float = sh["r"] * _scale
	# y 反転のため角度は符号を変えて描く
	draw_arc(c, r, -deg_to_rad(sh["a0"]), -deg_to_rad(sh["a1"]),
		48, _c(sh.get("color", COL_LINE)), sh.get("w", 4.0), true)


func _draw_angle(sh: Dictionary) -> void:
	var at: Vector2 = sh["at"]
	var d1: Vector2 = (sh["p1"] - at).normalized()
	var d2: Vector2 = (sh["p2"] - at).normalized()
	var label: String = sh["label"]
	var unknown := label.begins_with("x") or label.begins_with("θ") or label == "?"
	var col := COL_UNKNOWN if unknown else COL_ANGLE
	var a1 := atan2(d1.y, d1.x)
	var a2 := atan2(d2.y, d2.x)
	# a1 → a2 を反時計回り(正方向)で描く。差を 0..TAU に正規化
	var sweep := fposmod(a2 - a1, TAU)
	if sweep > PI * 1.999:
		sweep = TAU
	# 指定がなければ 180° 以下の側(劣角)を描く。呼び出し側の p1/p2 の順序に
	# よらず、図形として意味のある内側の角に印が付く
	if sweep > PI and not sh.get("reflex", false):
		a1 = a2
		sweep = TAU - sweep
	# 角の印の半径: 図形サイズに応じて。狭い角は少し大きく
	var r_px := 44.0 if sh.get("r", 0.0) == 0.0 else float(sh["r"]) * _scale
	if sweep < deg_to_rad(35.0):
		r_px *= 1.35
	var c := _px(at)
	draw_arc(c, r_px, -a1, -(a1 + sweep), 32, _c(col), 3.5, true)
	# ラベルは二等分線方向の少し外側
	var bis := a1 + sweep * 0.5
	var pos := c + Vector2(cos(bis), -sin(bis)) * (r_px + 30.0)
	_draw_text_at(pos, label, col, 30 if not unknown else 34)


func _draw_right(sh: Dictionary) -> void:
	var at: Vector2 = sh["at"]
	var d1: Vector2 = (sh["p1"] - at).normalized()
	var d2: Vector2 = (sh["p2"] - at).normalized()
	var s := 16.0
	var c := _px(at)
	var e1 := Vector2(d1.x, -d1.y) * s
	var e2 := Vector2(d2.x, -d2.y) * s
	draw_polyline(PackedVector2Array([c + e1, c + e1 + e2, c + e2]), _c(COL_ANGLE), 3.0, true)


func _draw_tick(sh: Dictionary) -> void:
	var a := _px(sh["a"])
	var b := _px(sh["b"])
	var mid := (a + b) * 0.5
	var dir := (b - a).normalized()
	var n := dir.orthogonal()
	var count: int = sh.get("n", 1)
	for i in count:
		var off := dir * (float(i) - (count - 1) * 0.5) * 8.0
		draw_line(mid + off - n * 9.0, mid + off + n * 9.0, _c(COL_LINE), 3.0, true)


func _draw_label(sh: Dictionary) -> void:
	var col: Color = sh.get("color", COL_LINE)
	_draw_text_at(_px(sh["at"]), sh["s"], col, sh.get("size", 30))


func _draw_arrow(sh: Dictionary) -> void:
	var a := _px(sh["a"])
	var b := _px(sh["b"])
	var col: Color = sh.get("color", COL_LINE)
	var w: float = sh.get("w", 5.0)
	draw_line(a, b, _c(col), w, true)
	var dir := (b - a).normalized()
	var n := dir.orthogonal()
	draw_colored_polygon(PackedVector2Array([
		b, b - dir * 18.0 + n * 8.0, b - dir * 18.0 - n * 8.0]), _c(col))


func _draw_grid(sh: Dictionary) -> void:
	var from: Vector2 = sh["from"]
	var to: Vector2 = sh["to"]
	var col := Color(0.5, 0.6, 0.8, 0.25)
	var x := ceilf(from.x)
	while x <= to.x:
		draw_line(_px(Vector2(x, from.y)), _px(Vector2(x, to.y)), col, 1.5)
		x += 1.0
	var y := ceilf(from.y)
	while y <= to.y:
		draw_line(_px(Vector2(from.x, y)), _px(Vector2(to.x, y)), col, 1.5)
		y += 1.0


func _draw_axes(sh: Dictionary) -> void:
	var from: Vector2 = sh["from"]
	var to: Vector2 = sh["to"]
	var col := Color(0.85, 0.9, 1.0, 0.9)
	# x 軸(y=0)・y 軸(x=0)が範囲内にあれば描く
	if from.y <= 0.0 and to.y >= 0.0:
		var a := _px(Vector2(from.x, 0))
		var b := _px(Vector2(to.x, 0))
		draw_line(a, b, col, 2.5, true)
		draw_colored_polygon(PackedVector2Array([
			b, b + Vector2(-14, 6), b + Vector2(-14, -6)]), col)
		_draw_text_at(b + Vector2(-6, 22), "x", col, 24)
	if from.x <= 0.0 and to.x >= 0.0:
		var a2 := _px(Vector2(0, from.y))
		var b2 := _px(Vector2(0, to.y))
		draw_line(a2, b2, col, 2.5, true)
		draw_colored_polygon(PackedVector2Array([
			b2, b2 + Vector2(6, 14), b2 + Vector2(-6, 14)]), col)
		_draw_text_at(b2 + Vector2(20, 8), "y", col, 24)


## 葉っぱ形: 1 辺 a の正方形内の 2 つの四分円が重なる部分
func _draw_leaf(sh: Dictionary) -> void:
	var a: float = sh["a"]
	var n := 36
	var pts := PackedVector2Array()
	# 左下中心の四分円(0,0 中心・半径 a)の弧: 0°→90°
	for i in n + 1:
		var t := PI * 0.5 * i / n
		pts.append(_px(Vector2(cos(t), sin(t)) * a))
	# 右上中心の四分円((a,a) 中心)の弧: 180°→270° を逆順にたどって閉じる
	for i in n + 1:
		var t := PI * (1.0 + 0.5 * i / n)
		pts.append(_px(Vector2(a, a) + Vector2(cos(t), sin(t)) * a))
	draw_colored_polygon(pts, sh.get("fill", ProblemGen.FILL_ACCENT))
	draw_polyline(pts, COL_LINE, 3.5, true)


## ヒポクラテスの月: 直角三角形(直角が原点、たて a・よこ b)の 2 つの三日月
func _draw_lune(sh: Dictionary) -> void:
	var a: float = sh["a"]
	var b: float = sh["b"]
	var pa := Vector2(0, a)
	var pb := Vector2.ZERO
	var pc := Vector2(b, 0)
	var n := 40
	# 三日月 = 小半円 − 斜辺半円。ポリゴンのブーリアン(Geometry2D.clip)で正確に塗る
	var hyp_c := (pa + pc) * 0.5
	var hyp_r := (pa - pc).length() * 0.5
	var ang_a := (pa - hyp_c).angle()
	var leg1_c := (pa + pb) * 0.5
	var leg1_r := a * 0.5
	var small1 := PackedVector2Array()
	for i in n + 1:
		var t := PI * 0.5 + PI * i / n
		small1.append(leg1_c + Vector2(cos(t), sin(t)) * leg1_r)
	var small2 := PackedVector2Array()
	for i in n + 1:
		var t := PI * i / n
		small2.append((pb + pc) * 0.5 + Vector2(cos(t), -sin(t)) * b * 0.5)
	var big := PackedVector2Array()
	for i in n + 1:
		var t: float = ang_a + PI * float(i) / n
		big.append(hyp_c + Vector2(cos(t), sin(t)) * hyp_r)
	for lune_pts in [Geometry2D.clip_polygons(small1, big), Geometry2D.clip_polygons(small2, big)]:
		for piece in lune_pts:
			if piece.size() >= 3:
				var px_pts := PackedVector2Array()
				for p in piece:
					px_pts.append(_px(p))
				draw_colored_polygon(px_pts, ProblemGen.FILL_ACCENT)
	# 輪郭: 半円たち
	_stroke_pts(small1)
	_stroke_pts(small2)
	_stroke_pts(big)


func _stroke_pts(logical: PackedVector2Array) -> void:
	var px_pts := PackedVector2Array()
	for p in logical:
		px_pts.append(_px(p))
	draw_polyline(px_pts, COL_LINE, 3.0, true)


func _draw_text_at(pos: Vector2, text: String, col: Color, font_size: int) -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	# 縁取り(読みやすさのため背景色で細く)
	draw_string_outline(font, pos + Vector2(-sz.x * 0.5, sz.y * 0.3), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, _c(Color(0.05, 0.08, 0.14, 0.9)))
	draw_string(font, pos + Vector2(-sz.x * 0.5, sz.y * 0.3), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, _c(col))
