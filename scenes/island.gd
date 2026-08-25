extends Control
## 島取り(ためし) ― 問題を解いた答えが、そのまま取れる土地の広さになる陣取り。
##
## 1 ターンの流れ:
##   立て札をタップ → 問題(電卓で答える)→ 正解なら「◯マス取れる」
##   → 島を指でなぞって陣地を広げる → カラスのターン → つぎへ
##
## 島が埋まるか 15 ターンで終わり。占有率が成績。通信はしない(カラスは AI)。
##
## ためし版なので、泉・遺跡・週替わりの島までは入れて、
## 定理カードとの連携と角度編の扇形取りはまだ入れていない。

const W := 10                  # 島の よこマス数
const H := 14                  # 島の たてマス数
const MAX_TURN := 12

# マスの中身
enum {SEA, EMPTY, MINE, CROW, ROCK, SPRING, RUIN}

const COL := {
	SEA: Color(0.16, 0.31, 0.44),
	EMPTY: Color(0.80, 0.73, 0.56),
	MINE: Color(0.24, 0.52, 0.80),
	CROW: Color(0.22, 0.20, 0.26),
	ROCK: Color(0.55, 0.52, 0.48),
	SPRING: Color(0.35, 0.70, 0.72),
	RUIN: Color(0.62, 0.48, 0.30),
}
## となりの 4 方向(型を付けておかないと Vector2i の足し算が Variant になる)
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const INK := Color(0.16, 0.12, 0.08)
const GOLD := Color(0.95, 0.78, 0.30)

var cell: Array = []           # cell[y][x]
var posts: Array = []          # 立て札 {"x","y","tier"}
var turn := 1
var need := 0                  # いま取れるマス数(0 なら問題を解く番)
var marked: Array = []         # なぞって選んだマス [Vector2i]
var bonus := 0                 # 泉で増える ぶん
var last_take := 4             # 前のターンに じぶんが 取った マス数(カラスの強さの目安)
var crow_extra := 0            # 立て札を 取り逃した ぶん、カラスが 多く広げる
var rng := RandomNumberGenerator.new()
var over := false

var board: Control
var msg: Label
var head_lbl: Label
var act_btn: Button
var redo_btn: Button
var quiz: Control              # 問題の重ね画面
var figure: FigureView
var keypad: Keypad
var q_lbl: Label
var problem: Dictionary = {}
var input_text := ""
var picked_post := -1
var post_cell := Vector2i(-1, -1)   # いま挑んでいる立て札の場所
var miss := 0                       # その問題で まちがえた回数


func _ready() -> void:
	# 週替わりの島。同じ週なら誰の端末でも同じ島になる(通信しないで話を合わせる)
	rng.seed = _week() * 7919
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.13, 0.20)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var ins := GameState.safe_insets()
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 12
	root.offset_right = -12
	root.offset_top = float(ins["top"]) + 8.0
	root.offset_bottom = -float(ins["bottom"]) - 8.0
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var head := HBoxContainer.new()
	root.add_child(head)
	var back := Button.new()
	back.text = "もどる"
	back.custom_minimum_size = Vector2(140, 62)
	back.add_theme_font_size_override("font_size", 24)
	GameState.style_button(back, Color(0.28, 0.32, 0.44))
	back.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		GameState.change_scene("res://scenes/main.tscn"))
	head.add_child(back)
	head_lbl = Label.new()
	head_lbl.add_theme_font_size_override("font_size", 24)
	head_lbl.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	head_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(head_lbl)

	board = Control.new()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size = Vector2(0, 420)
	board.draw.connect(_draw_board)
	board.gui_input.connect(_on_board_input)
	root.add_child(board)

	msg = Label.new()
	msg.add_theme_font_size_override("font_size", 25)
	msg.add_theme_color_override("font_color", GOLD)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.custom_minimum_size = Vector2(0, 66)
	root.add_child(msg)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)
	redo_btn = Button.new()
	redo_btn.text = "なぞり直す"
	redo_btn.custom_minimum_size = Vector2(0, 84)
	redo_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	redo_btn.add_theme_font_size_override("font_size", 26)
	GameState.style_button(redo_btn, Color(0.42, 0.34, 0.30))
	redo_btn.pressed.connect(_clear_marks)
	row.add_child(redo_btn)
	act_btn = Button.new()
	act_btn.custom_minimum_size = Vector2(0, 84)
	act_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	act_btn.size_flags_stretch_ratio = 1.6
	act_btn.add_theme_font_size_override("font_size", 28)
	GameState.style_button(act_btn, Color(0.22, 0.55, 0.35))
	act_btn.pressed.connect(_on_act)
	row.add_child(act_btn)

	_build_quiz()
	_make_island()
	msg.text = "立て札の問題を解くと、答えの数だけ土地が取れる。カラスより広く取ろう"
	_refresh()


## いまが何週めか(1970 年からの通し。週替わりの島のたね)
func _week() -> int:
	return int(Time.get_unix_time_from_system() / 604800.0)


# =========================================================
# 島をつくる
# =========================================================

func _make_island() -> void:
	cell = []
	for y in H:
		var row: Array = []
		for x in W:
			row.append(SEA)
		cell.append(row)
	# まん中がふくらんだ形。ふちは たねしだいで でこぼこ
	var cx := float(W - 1) * 0.5
	var cy := float(H - 1) * 0.5
	for y in H:
		for x in W:
			var dx := (float(x) - cx) / (float(W) * 0.52)
			var dy := (float(y) - cy) / (float(H) * 0.52)
			var d := sqrt(dx * dx + dy * dy) + rng.randf_range(-0.16, 0.16)
			if d < 0.95:
				cell[y][x] = EMPTY
	_keep_main_island()
	# 岩・泉・遺跡を まく
	_sprinkle(ROCK, 7)
	_sprinkle(SPRING, 3)
	_sprinkle(RUIN, 2)
	# 出発点。じぶんは 下、カラスは 上
	_seed_owner(MINE, H - 1)
	_seed_owner(CROW, 0)
	_spawn_posts()


## まん中と つながっていない 離れ小島は 海に もどす
## (行けない土地が あると、取れないマスが 残って 勝負が 終わらない)
func _keep_main_island() -> void:
	var start := Vector2i(-1, -1)
	var cx := W / 2
	for r in W + H:
		for y in H:
			for x in W:
				if cell[y][x] == EMPTY and absi(x - cx) + absi(y - H / 2) == r:
					start = Vector2i(x, y)
					break
			if start.x >= 0:
				break
		if start.x >= 0:
			break
	if start.x < 0:
		return
	var seen := {}
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var cv: Vector2i = stack.pop_back()
		if seen.has(cv):
			continue
		seen[cv] = true
		for d in DIRS:
			var n := cv + d
			if n.x < 0 or n.x >= W or n.y < 0 or n.y >= H:
				continue
			if cell[n.y][n.x] == EMPTY and not seen.has(n):
				stack.append(n)
	for y in H:
		for x in W:
			if cell[y][x] == EMPTY and not seen.has(Vector2i(x, y)):
				cell[y][x] = SEA


func _sprinkle(kind: int, n: int) -> void:
	var put := 0
	var guard := 0
	while put < n and guard < 400:
		guard += 1
		var x := rng.randi_range(0, W - 1)
		var y := rng.randi_range(2, H - 3)
		if cell[y][x] == EMPTY:
			cell[y][x] = kind
			put += 1


## 島の 上端 / 下端の あたりに 出発点を 2 マス
func _seed_owner(kind: int, from_y: int) -> void:
	var step := 1 if from_y == 0 else -1
	var y := from_y
	while y >= 0 and y < H:
		for x in range(W - 1):
			# となりあった 2 マスを 出発点に する(いきなり 飛び地に しない)
			if cell[y][x] == EMPTY and cell[y][x + 1] == EMPTY:
				cell[y][x] = kind
				cell[y][x + 1] = kind
				return
		y += step


## 立て札は 空きマスに 3 本。じぶんの陣地から 遠いほど 難しく、取れるマスも多い
func _spawn_posts() -> void:
	posts.clear()
	var guard := 0
	while posts.size() < 3 and guard < 500:
		guard += 1
		var x := rng.randi_range(0, W - 1)
		var y := rng.randi_range(0, H - 1)
		if cell[y][x] != EMPTY:
			continue
		var dup := false
		for p in posts:
			if int(p["x"]) == x and int(p["y"]) == y:
				dup = true
		if dup:
			continue
		posts.append({"x": x, "y": y, "tier": clampi(int(_dist_to_mine(x, y) / 3), 0, 5)})


## じぶんの陣地からの おおよその 遠さ
func _dist_to_mine(x: int, y: int) -> int:
	var best := 99
	for yy in H:
		for xx in W:
			if cell[yy][xx] == MINE:
				best = mini(best, absi(xx - x) + absi(yy - y))
	return best


# =========================================================
# 盤面を描く
# =========================================================

func _cell_size() -> float:
	return minf(board.size.x / float(W), board.size.y / float(H))


func _origin() -> Vector2:
	var s := _cell_size()
	return Vector2((board.size.x - s * float(W)) * 0.5, (board.size.y - s * float(H)) * 0.5)


func _cell_at(p: Vector2) -> Vector2i:
	var s := _cell_size()
	var o := _origin()
	var x := int(floor((p.x - o.x) / s))
	var y := int(floor((p.y - o.y) / s))
	if x < 0 or x >= W or y < 0 or y >= H:
		return Vector2i(-1, -1)
	return Vector2i(x, y)


## その持ち主の 外がわの ふちだけを なぞって 太い線を 引く
func _draw_outline(c: Control, kind: int, col: Color, o: Vector2, s: float) -> void:
	for y in H:
		for x in W:
			if cell[y][x] != kind:
				continue
			var at := o + Vector2(float(x), float(y)) * s
			for d in DIRS:
				var nx := x + d.x
				var ny := y + d.y
				var same := false
				if nx >= 0 and nx < W and ny >= 0 and ny < H:
					same = cell[ny][nx] == kind
				if same:
					continue
				var from := at
				var to := at
				if d == Vector2i(1, 0):
					from = at + Vector2(s, 0)
					to = at + Vector2(s, s)
				elif d == Vector2i(-1, 0):
					to = at + Vector2(0, s)
				elif d == Vector2i(0, 1):
					from = at + Vector2(0, s)
					to = at + Vector2(s, s)
				else:
					to = at + Vector2(s, 0)
				c.draw_line(from, to, col, 4.0)


func _draw_board() -> void:
	var c := board
	var s := _cell_size()
	var o := _origin()
	c.draw_rect(Rect2(o, Vector2(s * float(W), s * float(H))), COL[SEA])
	for y in H:
		for x in W:
			var kind: int = cell[y][x]
			var r := Rect2(o + Vector2(float(x), float(y)) * s, Vector2(s, s))
			var fill: Color = COL[EMPTY] if kind in [ROCK, SPRING, RUIN] else COL[kind]
			c.draw_rect(r, fill)
			if kind != SEA:
				c.draw_rect(r, Color(0, 0, 0, 0.18), false, 1.5)
			match kind:
				ROCK:
					c.draw_circle(r.get_center(), s * 0.28, COL[ROCK])
					c.draw_circle(r.get_center() + Vector2(s * 0.12, s * 0.06), s * 0.16,
						COL[ROCK].lightened(0.15))
				SPRING:
					c.draw_circle(r.get_center(), s * 0.30, COL[SPRING])
					c.draw_arc(r.get_center(), s * 0.16, 0.0, TAU, 16, Color(1, 1, 1, 0.7), 2.0)
				RUIN:
					var b := Rect2(r.position + Vector2(s * 0.24, s * 0.20),
						Vector2(s * 0.52, s * 0.60))
					c.draw_rect(b, COL[RUIN])
					c.draw_rect(b, INK, false, 2.0)
	# いま なぞれる ところを 光らせる(どこに 広げられるか 分かるように)
	if need > 0 and not over:
		var puls := 0.35 + 0.25 * sin(float(Time.get_ticks_msec()) * 0.006)
		for y in H:
			for x in W:
				var cv := Vector2i(x, y)
				if marked.has(cv):
					continue
				var k: int = cell[y][x]
				if k != EMPTY and k != SPRING and k != RUIN and k != CROW:
					continue
				if _cost_of(cv) > need - _marked_cost():
					continue
				if not _touches_mine(cv):
					continue
				var gr := Rect2(o + Vector2(float(x), float(y)) * s, Vector2(s, s))
				# カラスのマスは 赤っぽく(2 マスぶん つかう)
				var gc := Color(1.0, 0.45, 0.35, puls) if k == CROW else Color(GOLD.r, GOLD.g, GOLD.b, puls)
				c.draw_rect(gr.grow(-3.0), gc, false, 3.0)
	# ねらっている 立て札を 目立たせる(どこへ 伸ばすかの 目じるし)
	if need > 0 and post_cell.x >= 0:
		var tr := Rect2(o + Vector2(float(post_cell.x), float(post_cell.y)) * s, Vector2(s, s))
		var tp := 1.0 + sin(float(Time.get_ticks_msec()) * 0.006) * 0.10
		c.draw_arc(tr.get_center(), s * 0.62 * tp, 0.0, TAU, 28, GOLD, 4.0)
	# 陣地の ふちを 太く(かたちが 読めるように)
	_draw_outline(c, MINE, COL[MINE].lightened(0.45), o, s)
	_draw_outline(c, CROW, Color(0.72, 0.68, 0.80), o, s)
	# なぞって選んだマス
	for m in marked:
		var mr := Rect2(o + Vector2(float(m.x), float(m.y)) * s, Vector2(s, s))
		c.draw_rect(mr, Color(COL[MINE].r, COL[MINE].g, COL[MINE].b, 0.55))
		c.draw_rect(mr, GOLD, false, 3.0)
	# 立て札
	var font := ThemeDB.fallback_font
	for i in posts.size():
		var p: Dictionary = posts[i]
		var at := o + Vector2(float(p["x"]) + 0.5, float(p["y"]) + 0.5) * s
		var puls := 1.0 + sin(float(Time.get_ticks_msec()) * 0.004 + float(i)) * 0.08
		c.draw_line(at + Vector2(0, s * 0.30), at + Vector2(0, -s * 0.05), Color(0.50, 0.36, 0.22),
			maxf(s * 0.08, 3.0))
		# 板には「ここまで 何マスで 届くか」を 書く。
		# 遠い立て札ほど 問題は 難しく、もらえる マスも 多い ―
		# どれに 挑むかが この遊びの 判断どころ なので、数を 読める 大きさで 出す
		var d := _dist_to_mine(int(p["x"]), int(p["y"]))
		var bw := s * 1.06 * puls
		var br := Rect2(at + Vector2(-bw * 0.5, -s * 0.60), Vector2(bw, s * 0.52))
		c.draw_rect(br, Color(0.90, 0.78, 0.50))
		c.draw_rect(br, INK, false, 2.0)
		c.draw_string(font, br.position + Vector2(0, s * 0.38), "%d マス" % d,
			HORIZONTAL_ALIGNMENT_CENTER, bw, int(s * 0.32), INK)
		c.draw_circle(at + Vector2(0, -s * 0.72), s * 0.16, GOLD)
		c.draw_string(font, at + Vector2(-s * 0.16, -s * 0.64), "?",
			HORIZONTAL_ALIGNMENT_CENTER, s * 0.32, int(s * 0.26), INK)


# =========================================================
# 指の操作
# =========================================================

func _on_board_input(event: InputEvent) -> void:
	if over or quiz.visible:
		return
	var pressed := false
	var at := Vector2.ZERO
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if not event.pressed:
			return
		pressed = true
		at = event.position
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		at = event.position
		if event is InputEventMouseMotion and event.button_mask == 0:
			return
	else:
		return
	var cv := _cell_at(at)
	if cv.x < 0:
		return
	if need <= 0:
		if pressed:
			_tap_post(cv)
		return
	_mark(cv)


## 立て札を たたく → 問題
func _tap_post(cv: Vector2i) -> void:
	for i in posts.size():
		var p: Dictionary = posts[i]
		if int(p["x"]) == cv.x and int(p["y"]) == cv.y:
			picked_post = i
			post_cell = cv
			miss = 0
			_open_quiz(int(p["tier"]))
			return
	GameState.play_sfx("fail")
	msg.text = "「?」の立て札をタップすると 問題が出る"


## そのマスを 取るのに いくつ つかうか。カラスの陣地は 押し返すので 2 つぶん
func _cost_of(cv: Vector2i) -> int:
	return 2 if cell[cv.y][cv.x] == CROW else 1


## いま 何マスぶん つかっているか
func _marked_cost() -> int:
	var n := 0
	for m in marked:
		n += _cost_of(m)
	return n


## なぞったマスを 選ぶ。じぶんの陣地か、選んだマスに となりあっていること。
## カラスのマスも 取れる(2 マスぶん つかう)ので、囲まれても 押し返せる
func _mark(cv: Vector2i) -> void:
	if marked.has(cv):
		return
	var k: int = cell[cv.y][cv.x]
	if k != EMPTY and k != SPRING and k != RUIN and k != CROW:
		return
	if _marked_cost() + _cost_of(cv) > need:
		return
	if not _touches_mine(cv):
		return
	marked.append(cv)
	GameState.play_sfx("type")
	_refresh()


## まだ なぞれる マスが いくつ あるか(囲まれて 置けない ときの ため)
func _markable_left() -> int:
	var n := 0
	var left := need - _marked_cost()
	for y in H:
		for x in W:
			var cv := Vector2i(x, y)
			if marked.has(cv):
				continue
			var k: int = cell[y][x]
			if k != EMPTY and k != SPRING and k != RUIN and k != CROW:
				continue
			if _cost_of(cv) > left:
				continue
			if _touches_mine(cv):
				n += 1
	return n


func _touches_mine(cv: Vector2i) -> bool:
	for d in DIRS:
		var n := cv + d
		if n.x < 0 or n.x >= W or n.y < 0 or n.y >= H:
			continue
		if cell[n.y][n.x] == MINE or marked.has(n):
			return true
	return false


func _clear_marks() -> void:
	if marked.is_empty():
		return
	GameState.play_sfx("tap")
	marked.clear()
	_refresh()


# =========================================================
# ターンの流れ
# =========================================================

func _on_act() -> void:
	if over:
		GameState.change_scene("res://scenes/main.tscn")
		return
	if need <= 0:
		# どの立て札に 挑むかは 自分で えらぶ(ここが この遊びの 判断どころ)
		if posts.is_empty():
			_spawn_posts()
		if posts.is_empty():
			_finish()
			return
		GameState.play_sfx("fail")
		msg.text = "立て札を タップして えらぼう。遠いほど 問題は 難しく、もらえる マスも 多い"
		return
	if marked.is_empty() and _markable_left() == 0:
		# まわりを ぜんぶ カラスと岩に 囲まれた。ここで 勝負あり
		msg.text = "囲まれた! もう 広げられない。"
		_finish()
		return
	if _marked_cost() != need and _markable_left() > 0:
		GameState.play_sfx("fail")
		msg.text = "あと %d マスぶん" % (need - _marked_cost())
		return
	if marked.is_empty():
		GameState.play_sfx("fail")
		msg.text = "広げられる ところが ない。ふちの マスを なぞろう"
		return
	_take_marked()


## 取った土地を 自分のものにする
func _take_marked() -> void:
	GameState.play_sfx("clear")
	var got_spring := 0
	var got_ruin := 0
	last_take = marked.size()
	var reached_post := post_cell.x >= 0 and marked.has(post_cell)
	for m in marked:
		if cell[m.y][m.x] == SPRING:
			got_spring += 1
		elif cell[m.y][m.x] == RUIN:
			got_ruin += 1
		cell[m.y][m.x] = MINE
	marked.clear()
	need = 0
	bonus = got_spring * 3
	# 立て札が 陣地に のまれたら 立て直す
	var keep: Array = []
	for p in posts:
		if cell[int(p["y"])][int(p["x"])] == EMPTY:
			keep.append(p)
	posts = keep
	var extra := ""
	if got_spring > 0:
		extra += "  泉! つぎは +%d マス" % bonus
	if got_ruin > 0:
		extra += "  遺跡を見つけた!"
	# 立て札まで 届いたか ― ここが 立て札を えらぶ 意味
	if reached_post:
		bonus += 4
		extra += "  立て札に とどいた! つぎは +4 マス"
		GameState.play_sfx("clear")
	elif post_cell.x >= 0:
		extra += "  立て札には とどかなかった(まだ 立っている)"
	post_cell = Vector2i(-1, -1)
	msg.text = "土地を広げた。" + extra
	# ここで待たせない。待つと「カラスの番」が遅れて、
	# 先に つぎの問題を開けてしまう(カラスが 一度も 広げられなかった)
	_crow_turn()


## 3 回はずしたとき ― その立て札は カラスの ものに なり、こちらは 何も 取れない
func _lose_post(why: String) -> void:
	GameState.play_sfx("fail")
	need = 0
	marked.clear()
	_drop_post("")
	post_cell = Vector2i(-1, -1)
	msg.text = why
	_crow_turn()


## 立て札を 消して、その場所を カラスの ものに する
func _drop_post(why: String) -> void:
	if picked_post >= 0 and picked_post < posts.size():
		posts.remove_at(picked_post)
	picked_post = -1
	# その場所を そのまま カラスに すると、自陣の 真ん中に カラスが 湧いて
	# 立て直せなくなる。かわりに カラスの その番の 手数を 増やす
	crow_extra += 2
	if why != "":
		msg.text = why


## カラスの番。じぶんに 近いところから 広げ、細いところを 1 つ 切り取る
func _crow_turn() -> void:
	# カラスは じぶんが 取ったのと 同じくらい 広げる(競り合いに なるように)
	var n := clampi(last_take, 3, 8) + crow_extra
	crow_extra = 0
	for i in n:
		var best := Vector2i(-1, -1)
		var best_score := -999
		for y in H:
			for x in W:
				var cv := Vector2i(x, y)
				if cell[y][x] != EMPTY and cell[y][x] != SPRING and cell[y][x] != RUIN:
					continue
				if not _touches(cv, CROW):
					continue
				# じぶんの陣地に 近いマスほど 高い点(にらみ合いに なる)
				var score := 40 - _dist_to_mine(x, y) * 3
				if cell[y][x] == SPRING:
					score += 12
				if score > best_score:
					best_score = score
					best = cv
		if best.x < 0:
			break
		cell[best.y][best.x] = CROW
		# 立て札の 上を 取られたら、その立て札は カラスの ものに なる
		for pi in range(posts.size() - 1, -1, -1):
			if int(posts[pi]["x"]) == best.x and int(posts[pi]["y"]) == best.y:
				posts.remove_at(pi)
				crow_extra += 2
				msg.text = "立て札を カラスに 取られた! 早く 取りに 行こう"
	if turn % 2 == 0:
		_crow_cut()
	turn += 1
	if turn > MAX_TURN or _count(EMPTY) + _count(SPRING) + _count(RUIN) == 0:
		_finish()
		return
	if posts.size() < 3:
		_spawn_posts()
	GameState.play_sfx("type")
	_refresh()


## 細い所を 切る。まわりが 3 方カラスの 自分のマスを 1 つ 奪う
func _crow_cut() -> void:
	for y in H:
		for x in W:
			if cell[y][x] != MINE:
				continue
			var crows := 0
			for d in DIRS:
				var nx := x + d.x
				var ny := y + d.y
				if nx < 0 or nx >= W or ny < 0 or ny >= H:
					continue
				if cell[ny][nx] == CROW:
					crows += 1
			if crows >= 3:
				cell[y][x] = CROW
				msg.text = "カラスに 細いところを 切られた!"
				return


func _touches(cv: Vector2i, kind: int) -> bool:
	for d in DIRS:
		var n := cv + d
		if n.x < 0 or n.x >= W or n.y < 0 or n.y >= H:
			continue
		if cell[n.y][n.x] == kind:
			return true
	return false


func _count(kind: int) -> int:
	var n := 0
	for y in H:
		for x in W:
			if cell[y][x] == kind:
				n += 1
	return n


# =========================================================
# 問題(重ね画面)
# =========================================================

func _build_quiz() -> void:
	quiz = Control.new()
	quiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	quiz.visible = false
	add_child(quiz)
	var back := ColorRect.new()
	back.color = Color(0.07, 0.10, 0.17, 0.97)
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	quiz.add_child(back)

	var ins := GameState.safe_insets()
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14
	v.offset_right = -14
	v.offset_top = float(ins["top"]) + 10.0
	v.offset_bottom = -float(ins["bottom"]) - 10.0
	v.add_theme_constant_override("separation", 8)
	quiz.add_child(v)

	figure = FigureView.new()
	figure.size_flags_vertical = Control.SIZE_EXPAND_FILL
	figure.custom_minimum_size = Vector2(0, 320)
	v.add_child(figure)
	figure.add_tools()

	q_lbl = Label.new()
	q_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q_lbl.add_theme_font_size_override("font_size", 27)
	q_lbl.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	q_lbl.custom_minimum_size = Vector2(0, 92)
	v.add_child(q_lbl)

	keypad = Keypad.new()
	keypad.key_pressed.connect(_on_key)
	v.add_child(keypad)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var calc := Button.new()
	calc.text = "＝ 計算"
	calc.custom_minimum_size = Vector2(0, 84)
	calc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calc.add_theme_font_size_override("font_size", 27)
	GameState.style_button(calc, Color(0.24, 0.42, 0.72))
	calc.pressed.connect(_calc_in_place)
	row.add_child(calc)
	var ans := Button.new()
	ans.text = "答える"
	ans.custom_minimum_size = Vector2(0, 84)
	ans.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ans.size_flags_stretch_ratio = 1.6
	ans.add_theme_font_size_override("font_size", 29)
	GameState.style_button(ans, Color(0.22, 0.55, 0.35))
	ans.pressed.connect(_submit)
	row.add_child(ans)


## 立て札の 遠さで 難度が 上がる。無料の 範囲は 守る
func _open_quiz(tier: int) -> void:
	var courses: Array = ProblemGen.COURSES
	var c: Dictionary = courses[rng.randi_range(0, courses.size() - 1)]
	var stages: Array = c["stages"]
	var limit: int = GameState.free_stage_limit()
	var top := stages.size() if limit <= 0 else mini(limit, stages.size())
	var idx := clampi(tier, 0, top - 1)
	problem = ProblemGen.generate(String(stages[idx]["id"]), rng, clampi(tier, 0, 4))
	figure.set_spec(problem["fig"])
	input_text = ""
	keypad.answer_lbl.text = ""
	keypad.unit_lbl.text = String(problem.get("unit", ""))
	q_lbl.text = "%s\n%s" % [String(problem["q"]), _reward_note()]
	quiz.visible = true
	GameState.play_sfx("tap")


## 答え → 取れるマス数の 決め方(ためし版の 目安)
func _cells_for(v: float) -> int:
	var unit := String(problem.get("unit", ""))
	var per := 15.0 if unit == "度" else 10.0
	var n := int(round(absf(v) / per))
	n = int(float(n) / pow(2.0, float(miss)))       # まちがえた ぶん 減る
	return clampi(n, 3, 10)


func _reward_note() -> String:
	var unit := String(problem.get("unit", ""))
	var per := "÷ 15" if unit == "度" else "÷ 10"
	var d := _dist_to_mine(post_cell.x, post_cell.y) if post_cell.x >= 0 else 0
	var lost := "" if miss == 0 else "  ※ まちがえたので もらえる マスは %d 分の 1" % int(pow(2, miss))
	return "正解すると 答え %s マス。この立て札まで %d マス%s" % [per, d, lost]


func _on_key(k: String) -> void:
	GameState.play_sfx("type")
	input_text = Keypad.apply(input_text, k)
	keypad.answer_lbl.text = input_text


func _calc_in_place() -> void:
	if input_text == "":
		return
	var res: Dictionary = ExprEval.eval(input_text)
	if not bool(res["ok"]):
		GameState.play_sfx("fail")
		q_lbl.text = String(res["err"])
		return
	GameState.play_sfx("type")
	input_text = ExprEval.fmt(float(res["value"]))
	keypad.answer_lbl.text = input_text


func _submit() -> void:
	var v := Keypad.value_of(input_text)
	if is_nan(v):
		GameState.play_sfx("fail")
		q_lbl.text = "数を入れてね(式のままでもよい)"
		return
	if absf(v - float(problem["answer"])) > maxf(float(problem.get("tol", 0.01)), 0.01):
		GameState.play_sfx("fail")
		miss += 1
		input_text = ""
		keypad.answer_lbl.text = ""
		if miss >= 3:
			# 3 回はずすと この立て札は カラスの ものに なる
			quiz.visible = false
			_lose_post("3 回はずした。立て札は カラスに 取られた!")
			return
		q_lbl.text = "ちがう ― もらえる マスが 半分に なった(のこり %d 回)\n%s\n%s" % [
			3 - miss, String(problem["q"]), _reward_note()]
		return
	GameState.play_sfx("correct")
	need = _cells_for(float(problem["answer"])) + bonus
	bonus = 0
	quiz.visible = false
	msg.text = "正解! %d マスぶん。立て札まで とどけば 占領。カラスのマスは 2 マスぶんで 押し返せる" % need
	_refresh()


# =========================================================
# 画面の更新・おわり
# =========================================================

func _refresh() -> void:
	var mine := _count(MINE)
	var crow := _count(CROW)
	var all := maxi(mine + crow + _count(EMPTY) + _count(SPRING) + _count(RUIN), 1)
	head_lbl.text = "  %d/%d ターン   じぶん %d%%  カラス %d%%" % [
		mini(turn, MAX_TURN), MAX_TURN,
		int(round(100.0 * float(mine) / float(all))),
		int(round(100.0 * float(crow) / float(all)))]
	if over:
		act_btn.text = "もどる"
	elif need <= 0:
		act_btn.text = "立て札の 問題を とく"
		if msg.text == "":
			msg.text = "「?」の立て札をタップ(近いほど やさしい)"
	else:
		act_btn.text = "ここに 決める(%d/%d)" % [_marked_cost(), need]
		if _marked_cost() < need and _markable_left() == 0 and not marked.is_empty():
			act_btn.text = "ここまでで 決める(%d/%d)" % [_marked_cost(), need]
	redo_btn.disabled = marked.is_empty()
	board.queue_redraw()


func _finish() -> void:
	over = true
	var mine := _count(MINE)
	var crow := _count(CROW)
	var all := maxi(mine + crow + _count(EMPTY) + _count(SPRING) + _count(RUIN), 1)
	var pct := int(round(100.0 * float(mine) / float(all)))
	var cpct := int(round(100.0 * float(crow) / float(all)))
	posts.clear()
	GameState.play_sfx("clear" if pct > cpct else "fail")
	msg.text = "おわり ― じぶん %d%% / カラス %d%%  %s" % [pct, cpct,
		"島は こちらのものだ!" if pct > cpct else "カラスに 取られた…"]
	_refresh()


func _process(_delta: float) -> void:
	if not over and not quiz.visible:
		board.queue_redraw()
