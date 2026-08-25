class_name Chars
## 登場人物を その場で 描く(画像は 持たない ― ほかの絵と 同じ方針)。
##
##   カラス   … 渡りの学者。公式を高く売りつける。ストーリー本編の敵役
##   たんけんか … あなた。たからのちず・島取りで 地図の上に立っている人
##
## 気分(mood)で 顔と 姿勢が 変わる。相手が いま どう思っているかが
## 見えないと、ただ 黒いマスが 増えるだけの 画面に なってしまう。
##
##   "calm"  … 余裕(勝っている)
##   "laugh" … 嘲笑(こちらが まちがえた)
##   "panic" … あせり(負けている)
##   "angry" … 怒り(陣地を 取られた)
##   "guts"  … ガッツポーズ(たんけんか用)

const BLACK := Color(0.13, 0.12, 0.18)
const CLOAK := Color(0.20, 0.18, 0.28)
const BEAK := Color(0.92, 0.76, 0.28)
const EYE := Color(0.98, 0.86, 0.30)
const SKIN := Color(0.98, 0.86, 0.72)


## カラス。at = 足もとの まん中、tall = 全身の 高さ
static func crow(c: CanvasItem, at: Vector2, tall: float, mood := "calm", t := 0.0,
		face := 1.0) -> void:
	var u := tall / 100.0                       # 1 単位 = 身長の 1/100
	var fx := face                              # -1 なら 左むき(カットインで 使う)
	var sway := sin(t * 2.4) * u * 1.6 * fx
	var head := at + Vector2(sway, -tall * 0.80)
	# 外套(下ほど 広がる)
	c.draw_colored_polygon(PackedVector2Array([
		at + Vector2(-30.0 * u * fx, 0), at + Vector2(-16.0 * u * fx, -62.0 * u),
		at + Vector2(16.0 * u * fx, -62.0 * u), at + Vector2(30.0 * u * fx, 0)]), CLOAK)
	# 羽(両肩から 垂れる)
	for sgn in [-1.0, 1.0]:
		var w0 := at + Vector2(sgn * 15.0 * u * fx, -60.0 * u)
		var flap := (sin(t * 3.0) * 0.25 if mood == "angry" or mood == "panic" else 0.0)
		c.draw_colored_polygon(PackedVector2Array([
			w0,
			w0 + Vector2(sgn * (26.0 + flap * 20.0) * u, 16.0 * u),
			w0 + Vector2(sgn * (20.0 + flap * 16.0) * u, 34.0 * u),
			w0 + Vector2(sgn * 6.0 * u * fx, 26.0 * u)]), BLACK)
	# 首もと
	c.draw_colored_polygon(PackedVector2Array([
		at + Vector2(-10.0 * u * fx, -58.0 * u), at + Vector2(-8.0 * u + sway * fx, -70.0 * u),
		at + Vector2(8.0 * u + sway * fx, -70.0 * u), at + Vector2(10.0 * u * fx, -58.0 * u)]), CLOAK)
	# 頭(鳥のかたち)
	c.draw_circle(head, 16.0 * u, BLACK)
	# くちばし
	var beak_dir := 1.0
	var beak_len := 26.0 * u
	if mood == "panic":
		beak_len = 20.0 * u
	c.draw_colored_polygon(PackedVector2Array([
		head + Vector2(10.0 * u * fx, -3.0 * u), head + Vector2(10.0 * u + beak_dir * beak_len * fx, 3.0 * u),
		head + Vector2(10.0 * u * fx, 8.0 * u)]), BEAK)
	# 目(気分で かたちが 変わる)
	var eye_at := head + Vector2(4.0 * u * fx, -4.0 * u)
	match mood:
		"laugh":
			c.draw_arc(eye_at, 6.0 * u, PI, TAU, 12, EYE, 2.5 * u)
		"panic":
			c.draw_circle(eye_at, 7.0 * u, Color(1, 1, 1, 0.9))
			c.draw_circle(eye_at + Vector2(1.5 * u * fx, 1.0 * u), 3.0 * u, BLACK)
		"angry":
			c.draw_circle(eye_at, 6.0 * u, EYE)
			c.draw_line(eye_at + Vector2(-7.0 * u * fx, -8.0 * u), eye_at + Vector2(6.0 * u * fx, -3.0 * u),
				Color(0.9, 0.3, 0.2), 3.0 * u)
		_:
			c.draw_circle(eye_at, 5.5 * u, EYE)
			c.draw_line(eye_at + Vector2(-6.0 * u * fx, -6.0 * u), eye_at + Vector2(6.0 * u * fx, -6.0 * u),
				BLACK, 2.5 * u)
	# つばの広い 帽子
	c.draw_colored_polygon(PackedVector2Array([
		head + Vector2(-30.0 * u * fx, -10.0 * u), head + Vector2(30.0 * u * fx, -10.0 * u),
		head + Vector2(22.0 * u * fx, -16.0 * u), head + Vector2(-22.0 * u * fx, -16.0 * u)]), BLACK)
	c.draw_colored_polygon(PackedVector2Array([
		head + Vector2(-15.0 * u * fx, -16.0 * u), head + Vector2(15.0 * u * fx, -16.0 * u),
		head + Vector2(11.0 * u * fx, -40.0 * u), head + Vector2(-11.0 * u * fx, -40.0 * u)]), BLACK)
	c.draw_line(head + Vector2(-15.0 * u * fx, -20.0 * u), head + Vector2(15.0 * u * fx, -20.0 * u),
		Color(0.55, 0.45, 0.25), 4.0 * u)
	# 手の 金貨(公式を 売りつける 学者)
	var coin := at + Vector2(30.0 * u, -44.0 * u + sin(t * 3.2) * 2.0 * u)
	c.draw_circle(coin, 9.0 * u, Color(0.90, 0.72, 0.24))
	c.draw_arc(coin, 9.0 * u, 0.0, TAU, 18, Color(0.60, 0.45, 0.12), 2.0 * u)
	c.draw_string(ThemeDB.fallback_font, coin + Vector2(-5.0 * u * fx, 5.0 * u), "¥",
		HORIZONTAL_ALIGNMENT_LEFT, -1, int(12.0 * u), Color(0.45, 0.32, 0.06))


## たんけんか(あなた)
static func hero(c: CanvasItem, at: Vector2, tall: float, mood := "calm", t := 0.0) -> void:
	var u := tall / 100.0
	var bob := sin(t * 3.0) * u * 1.5
	var body := at + Vector2(0, bob)
	var up := -1.0 if mood == "guts" else 0.0
	# あし
	c.draw_line(body + Vector2(-7.0 * u, -22.0 * u), body + Vector2(-9.0 * u, 0), BLACK, 6.0 * u)
	c.draw_line(body + Vector2(7.0 * u, -22.0 * u), body + Vector2(9.0 * u, 0), BLACK, 6.0 * u)
	# せなかの ふくろ
	c.draw_colored_polygon(PackedVector2Array([
		body + Vector2(12.0 * u, -52.0 * u), body + Vector2(26.0 * u, -46.0 * u),
		body + Vector2(23.0 * u, -26.0 * u), body + Vector2(11.0 * u, -28.0 * u)]),
		Color(0.55, 0.40, 0.24))
	# からだ
	c.draw_colored_polygon(PackedVector2Array([
		body + Vector2(-15.0 * u, -22.0 * u), body + Vector2(-12.0 * u, -56.0 * u),
		body + Vector2(12.0 * u, -56.0 * u), body + Vector2(15.0 * u, -22.0 * u)]),
		Color(0.30, 0.46, 0.62))
	# うで(ガッツポーズなら 上げる)
	c.draw_line(body + Vector2(-12.0 * u, -52.0 * u),
		body + Vector2(-24.0 * u, -52.0 * u + up * 22.0 * u), Color(0.30, 0.46, 0.62), 6.0 * u)
	c.draw_line(body + Vector2(12.0 * u, -52.0 * u),
		body + Vector2(24.0 * u, -52.0 * u + up * 22.0 * u), Color(0.30, 0.46, 0.62), 6.0 * u)
	# かお
	var head := body + Vector2(0, -70.0 * u)
	c.draw_circle(head, 15.0 * u, SKIN)
	c.draw_circle(head + Vector2(-5.0 * u, -2.0 * u), 2.2 * u, BLACK)
	c.draw_circle(head + Vector2(5.0 * u, -2.0 * u), 2.2 * u, BLACK)
	if mood == "guts":
		c.draw_arc(head + Vector2(0, 3.0 * u), 5.0 * u, 0.0, PI, 12, BLACK, 2.0 * u)
	# ぼうし
	c.draw_colored_polygon(PackedVector2Array([
		head + Vector2(-24.0 * u, -8.0 * u), head + Vector2(24.0 * u, -8.0 * u),
		head + Vector2(14.0 * u, -12.0 * u), head + Vector2(10.0 * u, -26.0 * u),
		head + Vector2(-10.0 * u, -26.0 * u), head + Vector2(-14.0 * u, -12.0 * u)]),
		Color(0.62, 0.44, 0.24))


## ふきだし(左右どちらから 出すか side = -1 / 1)
static func bubble(c: CanvasItem, at: Vector2, size: Vector2, text: String, side: float,
		font_size := 24) -> void:
	var r := Rect2(at - Vector2(size.x * 0.5, size.y), size)
	c.draw_rect(r, Color(0.98, 0.97, 0.94), true)
	c.draw_rect(r, Color(0.20, 0.18, 0.24), false, 3.0)
	var tip := Vector2(r.position.x + (size.x * 0.72 if side > 0.0 else size.x * 0.28),
		r.position.y + size.y)
	c.draw_colored_polygon(PackedVector2Array([
		tip + Vector2(-10, 0), tip + Vector2(10, 0), tip + Vector2(side * 6.0, 20.0)]),
		Color(0.98, 0.97, 0.94))
	c.draw_multiline_string(ThemeDB.fallback_font, r.position + Vector2(14, 30), text,
		HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, font_size, -1, Color(0.16, 0.14, 0.20))
