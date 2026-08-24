extends Control
## 【試作】相続ミステリー「遺産の地図」。
##
## ■ 何をする遊びか
## 遺言の条項どおりに土地を分ける。ただし境界線は**自由に引けない**。
## 使えるのは作図の道具だけ ―― 2 点を結ぶ / 平行線を引く / 中点を取る。
## 点も自由には置けない(頂点・杭・井戸・交点・中点のみ)。
## だから「指で揺らして面積の数字を合わせる」ができない。知っていないと引けない。
##
## ■ 面積は確定するまで見せない
## 途中で面積が見えると、当てずっぽうに正解判定がついてきてしまう。
## 見えるのは「作図した線」だけで、正しさは自分の手順が保証する。
##
## 第一話は三角形(中点を取れば厳密に二等分)。道具の使い方を覚える回。
## 第二話以降で四角形になり、等積変形(平行線)が要る本番になる。

const GOLD := Color(1.0, 0.85, 0.3)
const SKY := Color(0.55, 0.85, 1.0)
const INK := Color(0.92, 0.95, 1.0)
const DIM := Color(0.62, 0.72, 0.88)
const SIS := Color(0.95, 0.72, 0.30, 0.45)
const BRO := Color(0.35, 0.60, 0.95, 0.45)

enum Tool { NONE, JOIN, PARALLEL, MIDPOINT, CUT }

## 点 {"p": Vector2, "name": String, "kind": String}
var points: Array = []
## 直線 {"a": Vector2, "b": Vector2, "gold": bool}
var lines: Array = []
var land: Array = []
var well := Vector2.ZERO

var tool: int = Tool.NONE
var picked: Array = []          # 選択中の点/線
var picked_line := -1
var settled := false
var split_t := 0.0
var stars := 0
var cut_line := -1

var map: Control
var speaker: Label
var talk: Label
var hint: Label
var tool_row: HBoxContainer
var act_btn: Button
var hint_btn: Button
var used_hint := false
var step := 0

const SCRIPT := [
	["代訟人", "測量家オルドが死んだ。遺言は一通。土地の分け方だけが、こまごまと書かれている。"],
	["代訟人", "第一条 ―― わが土地を、姉と弟に等しく分けよ。境は頂点 A から引いた一本の直線とする。"],
	["弟 ロウ", "「A から引くだと? そんな指定に意味があるのか。だいたい等しいかどうか、誰が測る」"],
	["姉 セリカ", "「測れる者を呼んだのでしょう。……父は、測れない人間には渡さないつもりだった」"],
	["あなた", "縄も分度器も使わない。杭と定規だけで、等しい境を作図する。それが測量士の仕事だ。"],
]


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.13, 0.22)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build_case()

	var ins := GameState.safe_insets()
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 14
	root.offset_right = -14
	root.offset_top = float(ins["top"]) + 8.0
	root.offset_bottom = -float(ins["bottom"]) - 8.0
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var head := HBoxContainer.new()
	root.add_child(head)
	var back := Button.new()
	back.text = "←もどる"
	back.custom_minimum_size = Vector2(0, 60)
	back.add_theme_font_size_override("font_size", 23)
	GameState.style_button(back, Color(0.28, 0.32, 0.44))
	back.pressed.connect(func() -> void: GameState.change_scene("res://scenes/main.tscn"))
	head.add_child(back)
	var title := Label.new()
	title.text = "  遺産の地図 ・ 第一話「等しく分けよ」"
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", GOLD)
	head.add_child(title)

	map = Control.new()
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.custom_minimum_size = Vector2(0, 380)
	map.draw.connect(_draw_map)
	map.gui_input.connect(_on_map_input)
	root.add_child(map)

	tool_row = HBoxContainer.new()
	tool_row.add_theme_constant_override("separation", 8)
	tool_row.visible = false
	root.add_child(tool_row)
	_tool_button("結ぶ", Tool.JOIN, Color(0.30, 0.42, 0.60))
	_tool_button("平行", Tool.PARALLEL, Color(0.30, 0.42, 0.60))
	_tool_button("中点", Tool.MIDPOINT, Color(0.30, 0.42, 0.60))
	_tool_button("消す", Tool.NONE, Color(0.42, 0.30, 0.30))

	hint_btn = Button.new()
	hint_btn.text = "父の手記をのぞく(★ が 1 つ減る)"
	hint_btn.custom_minimum_size = Vector2(0, 60)
	hint_btn.add_theme_font_size_override("font_size", 22)
	GameState.style_button(hint_btn, Color(0.40, 0.34, 0.52))
	hint_btn.pressed.connect(_peek)
	hint_btn.visible = false
	root.add_child(hint_btn)

	hint = Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", SKY)
	root.add_child(hint)

	speaker = Label.new()
	speaker.add_theme_font_size_override("font_size", 23)
	speaker.add_theme_color_override("font_color", GOLD)
	root.add_child(speaker)

	talk = Label.new()
	talk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	talk.custom_minimum_size = Vector2(0, 84)
	talk.add_theme_font_size_override("font_size", 24)
	talk.add_theme_color_override("font_color", INK)
	root.add_child(talk)

	act_btn = Button.new()
	act_btn.custom_minimum_size = Vector2(0, 78)
	act_btn.add_theme_font_size_override("font_size", 27)
	GameState.style_button(act_btn, Color(0.22, 0.55, 0.35))
	act_btn.pressed.connect(_advance)
	root.add_child(act_btn)
	_show_step()


func _process(delta: float) -> void:
	if settled and split_t < 1.0:
		split_t = minf(split_t + delta * 2.2, 1.0)
		map.queue_redraw()


func _tool_button(text: String, which: int, col: Color) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 72)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 25)
	GameState.style_button(b, col)
	b.pressed.connect(func() -> void: _pick_tool(which))
	tool_row.add_child(b)


# =========================================================
# 事件(土地と点)
# =========================================================

func _build_case() -> void:
	land = [Vector2(-1.5, 8.5), Vector2(-9.0, -5.0), Vector2(9.5, -4.0)]
	points = []
	_add_point(land[0], "A", "頂点")
	_add_point(land[1], "B", "頂点")
	_add_point(land[2], "C", "頂点")
	well = Vector2(-4.6, -1.0)
	_add_point(well, "井戸", "井戸")


func _add_point(p: Vector2, name: String, kind: String) -> void:
	for q in points:
		if (q["p"] as Vector2).distance_to(p) < 0.12:
			return
	points.append({"p": p, "name": name, "kind": kind})


static func _area(poly: Array) -> float:
	var s := 0.0
	var n := poly.size()
	for i in n:
		var p: Vector2 = poly[i]
		var q: Vector2 = poly[(i + 1) % n]
		s += p.x * q.y - q.x * p.y
	return absf(s) * 0.5


static func _side(p: Vector2, a: Vector2, b: Vector2) -> float:
	return (b - a).cross(p - a)


static func _split(poly: Array, a: Vector2, b: Vector2) -> Array:
	var left: Array = []
	var right: Array = []
	var n := poly.size()
	for i in n:
		var p: Vector2 = poly[i]
		var q: Vector2 = poly[(i + 1) % n]
		var sp := _side(p, a, b)
		var sq := _side(q, a, b)
		if sp >= 0.0:
			left.append(p)
		if sp <= 0.0:
			right.append(p)
		if (sp > 0.0 and sq < 0.0) or (sp < 0.0 and sq > 0.0):
			var t := sp / (sp - sq)
			left.append(p + (q - p) * t)
			right.append(p + (q - p) * t)
	return [left, right]


static func _cross_lines(a1: Vector2, b1: Vector2, a2: Vector2, b2: Vector2) -> Array:
	var d1 := b1 - a1
	var d2 := b2 - a2
	var den := d1.cross(d2)
	if absf(den) < 0.00001:
		return []
	var t := (a2 - a1).cross(d2) / den
	return [a1 + d1 * t]


# =========================================================
# 地図
# =========================================================

func _to_screen(p: Vector2) -> Vector2:
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for q in land:
		lo = lo.min(q)
		hi = hi.max(q)
	var pad := 46.0
	var span := hi - lo
	var k := minf((map.size.x - pad * 2.0) / maxf(span.x, 0.001),
		(map.size.y - pad * 2.0) / maxf(span.y, 0.001))
	var center := (lo + hi) * 0.5
	return map.size * 0.5 + Vector2((p.x - center.x) * k, -(p.y - center.y) * k)


func _poly_screen(poly: Array, offset := Vector2.ZERO) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(_to_screen(p) + offset)
	return out


static func _centroid(poly: Array) -> Vector2:
	if poly.is_empty():
		return Vector2.ZERO
	var m := Vector2.ZERO
	for p in poly:
		m += p
	return m / float(poly.size())


func _draw_map() -> void:
	var c := map
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.13, 0.17, 0.27))
	var grid := Color(1, 1, 1, 0.05)
	var x := 0.0
	while x < c.size.x:
		c.draw_line(Vector2(x, 0), Vector2(x, c.size.y), grid, 1.0)
		x += 40.0
	var y := 0.0
	while y < c.size.y:
		c.draw_line(Vector2(0, y), Vector2(c.size.x, y), grid, 1.0)
		y += 40.0

	var font := ThemeDB.fallback_font
	if settled and cut_line >= 0:
		var ln: Dictionary = lines[cut_line]
		var parts := _split(land, ln["a"], ln["b"])
		var sis: Array = parts[0]
		var bro: Array = parts[1]
		if _side(well, ln["a"], ln["b"]) < 0.0:
			var t := sis
			sis = bro
			bro = t
		var dir := (_centroid(sis) - _centroid(bro)).normalized()
		var push := (_to_screen(dir) - _to_screen(Vector2.ZERO)) * split_t * 0.35
		c.draw_colored_polygon(_poly_screen(sis, push), SIS)
		c.draw_colored_polygon(_poly_screen(bro, -push), BRO)
		_outline(c, sis, GOLD, push)
		_outline(c, bro, SKY, -push)
		c.draw_string(font, _to_screen(_centroid(sis)) + push + Vector2(-40, 0),
			"姉  %.2f" % _area(sis), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, GOLD)
		c.draw_string(font, _to_screen(_centroid(bro)) - push + Vector2(-40, 0),
			"弟  %.2f" % _area(bro), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, SKY)
	else:
		c.draw_colored_polygon(_poly_screen(land), Color(0.35, 0.55, 0.9, 0.22))
		_outline(c, land, INK, Vector2.ZERO)

	# 作図した直線(土地の外まで伸ばす)
	for i in lines.size():
		var l: Dictionary = lines[i]
		var d := ((l["b"] as Vector2) - (l["a"] as Vector2)).normalized() * 60.0
		var col: Color = GOLD if bool(l.get("gold", false)) else Color(0.75, 0.80, 0.92)
		if i == picked_line:
			col = Color(1.0, 0.55, 0.4)
		c.draw_line(_to_screen((l["a"] as Vector2) - d), _to_screen((l["b"] as Vector2) + d),
			col, 3.0 if i == picked_line else 2.2)

	# 点
	for i in points.size():
		var pt: Dictionary = points[i]
		var s := _to_screen(pt["p"])
		var kind := String(pt["kind"])
		var col := INK
		if kind == "井戸":
			col = Color(0.35, 0.70, 1.0)
		elif kind == "中点":
			col = GOLD
		elif kind == "交点":
			col = Color(0.85, 0.75, 1.0)
		if picked.has(i):
			c.draw_circle(s, 15.0, Color(1.0, 0.55, 0.4, 0.55))
		c.draw_circle(s, 7.0, col)
		c.draw_string(font, s + Vector2(11, -8), String(pt["name"]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, col)


func _outline(c: Control, poly: Array, col: Color, offset: Vector2) -> void:
	var n := poly.size()
	for i in n:
		c.draw_line(_to_screen(poly[i]) + offset, _to_screen(poly[(i + 1) % n]) + offset, col, 3.0)


# =========================================================
# 道具
# =========================================================

func _pick_tool(which: int) -> void:
	GameState.play_sfx("tap")
	if which == Tool.NONE:
		if not lines.is_empty():
			lines.remove_at(lines.size() - 1)
		picked.clear()
		picked_line = -1
		tool = Tool.NONE
		_rebuild_points()
	else:
		tool = which
		picked.clear()
		picked_line = -1
	_update_hint()
	map.queue_redraw()


func _update_hint() -> void:
	match tool:
		Tool.JOIN:
			hint.text = "【結ぶ】通したい点を 2 つえらぶ"
		Tool.PARALLEL:
			hint.text = "【平行】まず もとにする線、つぎに 通す点をえらぶ"
		Tool.MIDPOINT:
			hint.text = "【中点】2 つの点をえらぶと、まん中に点ができる"
		Tool.CUT:
			hint.text = "【境にする】分ける線をえらんで「この線で分ける」"
		_:
			hint.text = "道具をえらんで作図する。線は自由には引けない"


## 交点を作り直す(線を消したときのため)
func _rebuild_points() -> void:
	var keep: Array = []
	for pt in points:
		if String(pt["kind"]) != "交点":
			keep.append(pt)
	points = keep
	for i in lines.size():
		for j in range(i + 1, lines.size()):
			_add_cross(lines[i], lines[j])
		for e in land.size():
			var a: Vector2 = land[e]
			var b: Vector2 = land[(e + 1) % land.size()]
			_add_cross(lines[i], {"a": a, "b": b}, true)


func _add_cross(l1: Dictionary, l2: Dictionary, on_edge := false) -> void:
	var r := _cross_lines(l1["a"], l1["b"], l2["a"], l2["b"])
	if r.is_empty():
		return
	var p: Vector2 = r[0]
	if on_edge:
		# 辺の内側に落ちた交点だけ点にする
		var a: Vector2 = l2["a"]
		var b: Vector2 = l2["b"]
		var t := (p - a).dot(b - a) / maxf((b - a).length_squared(), 0.0001)
		if t < -0.02 or t > 1.02:
			return
	if absf(p.x) > 40.0 or absf(p.y) > 40.0:
		return
	_add_point(p, "", "交点")


# =========================================================
# 地図をさわる
# =========================================================

func _on_map_input(event: InputEvent) -> void:
	if settled or step < SCRIPT.size():
		return
	var is_tap := (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed)
	if not is_tap:
		return
	var at: Vector2 = event.position
	if tool == Tool.PARALLEL and picked_line < 0:
		var li := _line_at(at)
		if li >= 0:
			picked_line = li
			hint.text = "【平行】その線に平行な線を、どの点に通す?"
			map.queue_redraw()
		return
	if tool == Tool.CUT:
		var li2 := _line_at(at)
		if li2 >= 0:
			picked_line = li2
			act_btn.disabled = false
			act_btn.text = "この線で分ける"
			map.queue_redraw()
		return
	var pi := _point_at(at)
	if pi < 0:
		return
	GameState.play_sfx("type")
	if tool == Tool.PARALLEL:
		var base: Dictionary = lines[picked_line]
		var d: Vector2 = (base["b"] as Vector2) - (base["a"] as Vector2)
		var p: Vector2 = points[pi]["p"]
		_add_line(p, p + d)
		tool = Tool.NONE
		picked_line = -1
		_update_hint()
		map.queue_redraw()
		return
	if picked.has(pi):
		picked.erase(pi)
	else:
		picked.append(pi)
	if picked.size() == 2:
		var p1: Vector2 = points[picked[0]]["p"]
		var p2: Vector2 = points[picked[1]]["p"]
		if tool == Tool.JOIN:
			_add_line(p1, p2)
		elif tool == Tool.MIDPOINT:
			_add_point((p1 + p2) * 0.5, "M", "中点")
		picked.clear()
		tool = Tool.NONE
		_update_hint()
	map.queue_redraw()


func _add_line(a: Vector2, b: Vector2) -> void:
	if a.distance_to(b) < 0.05:
		return
	lines.append({"a": a, "b": b})
	_rebuild_points()


func _point_at(s: Vector2) -> int:
	var best := -1
	var best_d := 46.0
	for i in points.size():
		var d := _to_screen(points[i]["p"]).distance_to(s)
		if d < best_d:
			best_d = d
			best = i
	return best


func _line_at(s: Vector2) -> int:
	var best := -1
	var best_d := 34.0
	for i in lines.size():
		var l: Dictionary = lines[i]
		var a := _to_screen(l["a"])
		var b := _to_screen(l["b"])
		var dir := (b - a).normalized()
		var far_a := a - dir * 3000.0
		var far_b := b + dir * 3000.0
		var d := Geometry2D.get_closest_point_to_segment(s, far_a, far_b).distance_to(s)
		if d < best_d:
			best_d = d
			best = i
	return best


# =========================================================
# 進行と判定
# =========================================================

func _show_step() -> void:
	if step < SCRIPT.size():
		speaker.text = String(SCRIPT[step][0])
		talk.text = String(SCRIPT[step][1])
		act_btn.text = "つぎへ ▶"
		act_btn.disabled = false
		return
	tool_row.visible = true
	hint_btn.visible = true
	speaker.text = "遺言 第一条"
	talk.text = "土地を、姉と弟に等しく分けよ。境は頂点 A から引いた一本の直線とする。井戸のある側を姉に。"
	_update_hint()
	act_btn.text = "境にする線をえらぶ"
	act_btn.disabled = false


## 手がかり。使うと ★ が 1 つ減る(知っている人と差がつく)
func _peek() -> void:
	GameState.play_sfx("hint")
	used_hint = true
	hint_btn.disabled = true
	hint_btn.text = "手記を見た(★ は 2 つまで)"
	speaker.text = "オルドの手記(走り書き)"
	talk.text = "「三角の地は、底辺を半分にすれば広さも半分になる。高さが同じだからだ」"


func _advance() -> void:
	GameState.play_sfx("tap")
	if step < SCRIPT.size():
		step += 1
		_show_step()
		return
	if tool != Tool.CUT and picked_line < 0:
		tool = Tool.CUT
		picked.clear()
		_update_hint()
		act_btn.disabled = true
		map.queue_redraw()
		return
	if picked_line >= 0 and not settled:
		_settle()
		return
	if settled:
		GameState.change_scene("res://scenes/main.tscn")


func _settle() -> void:
	var ln: Dictionary = lines[picked_line]
	var a: Vector2 = ln["a"]
	var b: Vector2 = ln["b"]
	# 頂点 A を通っているか(遺言の条件)
	var through_a := absf(_side(land[0], a, b)) < 0.05
	var parts := _split(land, a, b)
	var s1 := _area(parts[0])
	var s2 := _area(parts[1])
	var total := maxf(s1 + s2, 0.0001)
	var diff := absf(s1 - s2) / total
	if not through_a:
		GameState.play_sfx("fail")
		speaker.text = "代訟人"
		talk.text = "「その線は頂点 A を通っていません。遺言は 一本の直線を A から と定めています」"
		act_btn.text = "引き直す"
		return
	stars = 0
	if diff <= 0.005:
		stars = 3
	elif diff <= 0.02:
		stars = 2
	elif diff <= 0.05:
		stars = 1
	if used_hint:
		stars = mini(stars, 2)
	cut_line = picked_line
	if stars == 0:
		GameState.play_sfx("fail")
		speaker.text = "弟 ロウ"
		talk.text = "「ずいぶん大ざっぱだな。これでは受け取れない」  ―― 目分量では通らない。作図でぴたりと出すこと。"
		act_btn.text = "やり直す"
		cut_line = -1
		return
	settled = true
	split_t = 0.0
	tool_row.visible = false
	hint_btn.visible = false
	hint.text = ""
	GameState.play_sfx("clear" if stars == 3 else "correct")
	speaker.text = "代訟人   %s" % ("★".repeat(stars) + "☆".repeat(3 - stars))
	talk.text = "「境が定まりました」  差は %.2f%%。%s" % [diff * 100.0,
		"寸分の狂いもありません。" if stars == 3 else "わずかにずれています。作図で出せば ぴたりと合うはずです。"]
	act_btn.text = "手記を読む ▶"
	act_btn.pressed.disconnect(_advance)
	act_btn.pressed.connect(_show_note, CONNECT_ONE_SHOT)
	map.queue_redraw()


func _show_note() -> void:
	GameState.play_sfx("hint")
	speaker.text = "オルドの手記(一)"
	talk.text = "「境界は語る。三度引けば、あれの在り処が分かる」  ―― 父の字だ。"
	hint.text = "引いた境界が、地図に一本残った。あと二本。"
	act_btn.text = "その日は終わった ▶"
	act_btn.pressed.connect(_after_note, CONNECT_ONE_SHOT)


func _after_note() -> void:
	speaker.text = "弟 ロウ"
	talk.text = "「言い忘れていたが ―― あの井戸、去年から水が出ていない」  なぜ父は、涸れた井戸のある側を姉に指定したのか。"
	hint.text = "第二話へ続く(試作はここまで)"
	act_btn.text = "タイトルへ"
	act_btn.pressed.connect(func() -> void:
		GameState.change_scene("res://scenes/main.tscn"), CONNECT_ONE_SHOT)
