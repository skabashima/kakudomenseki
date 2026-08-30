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

## 島の 大きさなどは 島ごとに 変わる(core/island_defs.gd)
var W := 10                    # 島の よこマス数
var H := 14                    # 島の たてマス数
var MAX_TURN := 12
var isle := 0                  # いま 挑んでいる 島の 番号
var isle_def: Dictionary = {}

# マスの中身
enum {SEA, EMPTY, MINE, CROW, ROCK, SPRING, RUIN, SHRINE}

const COL := {
	SEA: Color(0.16, 0.31, 0.44),
	EMPTY: Color(0.80, 0.73, 0.56),
	MINE: Color(0.24, 0.52, 0.80),
	CROW: Color(0.22, 0.20, 0.26),
	ROCK: Color(0.55, 0.52, 0.48),
	SPRING: Color(0.35, 0.70, 0.72),
	RUIN: Color(0.62, 0.48, 0.30),
	SHRINE: Color(0.72, 0.66, 0.52),
}

## 石碑を 1 つ 持っていると、毎ターン これだけ 多く 取れる
const SHRINE_GAIN := 2

## 難しさ(★の数)ごとの: 出す tier / 答え を 何で わるか / 何回まで まちがえられるか
## 難しさごとの: 出す tier / 答えを 何で わるか / まちがえられる 回数 /
## もらえる マスの 下と 上。
##
## わり算だけで 決めると、答えが 小さい 問題(角度の 30° など)では
## むずかしい を 正解しても 3 マスしか もらえない ―― えらぶ 意味が 消える。
## だから 難しさごとに 下限と 上限を 置く(むずかしい は 必ず 8 マス以上)。
##
## span は tier を 毎回 どれだけ ふり直すか(tier 〜 tier + span)。
## やさしい を えらんだのに 時計の「8 時 10 分の 角」など、
## 上の 段の 問題が 出ていた ―― どの 段も +0〜2 と 同じだけ ふっていたため。
## t=2 から 逆算や 分きざみが 始まるので、やさしい は 0〜1 までに とめる。
const LEVELS := [
	{"name": "やさしい", "star": "★", "tier": 0, "span": 1, "per": 12.0, "miss": 3,
		"low": 3, "high": 7, "color": Color(0.26, 0.50, 0.36)},
	{"name": "ふつう", "star": "★★", "tier": 2, "span": 2, "per": 10.0, "miss": 2,
		"low": 5, "high": 10, "color": Color(0.30, 0.42, 0.62)},
	{"name": "むずかしい", "star": "★★★", "tier": 4, "span": 2, "per": 7.0, "miss": 1,
		"low": 8, "high": 14, "color": Color(0.58, 0.30, 0.26)},
]
## となりの 4 方向(型を付けておかないと Vector2i の足し算が Variant になる)
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const INK := Color(0.16, 0.12, 0.08)
const GOLD := Color(0.95, 0.78, 0.30)

var cell: Array = []           # cell[y][x]
var shrines: Array = []        # 石碑の 場所 [Vector2i]。持ち主は その マスの 色で 決まる
var turn := 1
var need := 0                  # いま取れるマス数(0 なら問題を解く番)
var marked: Array = []         # なぞって選んだマス [Vector2i]
var last_drag := Vector2i(-1, -1)   # 直前に 指が あった マス(あいだを 埋めるため)
var bonus := 0                 # 泉で増える ぶん
var last_take := 4             # 前のターンに じぶんが 取った マス数(カラスの強さの目安)
var crow_extra := 0            # 立て札を 取り逃した ぶん、カラスが 多く広げる
var cut_text_override := ""    # 切り取りなど、特別な ひとことが あるとき
var rng := RandomNumberGenerator.new()      # 島の かたち(島ごとに 決まっている)
var prng := RandomNumberGenerator.new()     # 出す問題(毎回 変わる)
var over := false
var result_layer: Control
var auto_fill := false         # 決着が 見えたので 残りを 自動で 塗っている
var auto_t := 0.0
var draw_t := 0.0              # 描き直しの 間引き(電池と 発熱を おさえる)
var pot_mine := 0              # 伸ばせる 先(盤面が 変わったときだけ 数える)
var pot_crow := 0
var _t := 0.0

var bar: Control                    # 上の 帯(顔と 占有率)
var cutin: Control                  # カラスのターンの カットイン
var cut_band: Control               # その中の 帯(ここだけに 絵を 描く)
var cut_t := 0.0
var cut_mood := "calm"
var cut_text := ""
var board: Control
var msg: RubyLabel
var head_lbl: RubyLabel
var act_btn: Button
var redo_btn: Button
var auto_btn: Button
var quiz: Control              # 問題の重ね画面
var figure: FigureView
var keypad: Keypad
var q_lbl: RubyLabel
var problem: Dictionary = {}
var last_stage := ""           # いま 出している ステージと 段(検分で 使う)
var last_tier := 0
var input_text := ""
var level := 1                      # いま えらんでいる 難しさ(0..2)
var miss := 0                       # その問題で まちがえた回数
var pick_row: HBoxContainer         # 難しさを えらぶ ボタン
var claim_row: HBoxContainer        # なぞる ときの ボタン


func _ready() -> void:
	isle = clampi(GameState.island_index, 0, IslandDefs.count() - 1)
	var in_range: Array = IslandDefs.islands_in(GameState.island_range)
	if not in_range.has(isle):
		isle = IslandDefs.first_open_in(GameState.island_range, GameState.island_clear)
	if GameState.island_needs_purchase(isle):
		# ここから先は 買い切りで 開く
		GameState.change_scene.call_deferred("res://scenes/store.tscn")
		return
	isle_def = IslandDefs.of(isle)
	W = int(isle_def["w"])
	H = int(isle_def["h"])
	MAX_TURN = int(isle_def["turns"])
	# 島の かたちは 島ごとに 決まっている(同じ島は 何度でも 同じ かたち)
	rng.seed = 7919 * (isle + 1) + 104729
	prng.randomize()
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
		GameState.change_scene("res://scenes/island_select.tscn"))
	head.add_child(back)
	# 小学生から 遊べるように、画面の 文には ふりがなを のせる
	head_lbl = RubyLabel.new()
	head_lbl.font_size = 22
	head_lbl.ruby_size = 11
	head_lbl.color = Color(0.88, 0.92, 1.0)
	head_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(head_lbl)

	bar = Control.new()
	bar.custom_minimum_size = Vector2(0, 112)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.draw.connect(_draw_bar)
	root.add_child(bar)

	board = Control.new()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.custom_minimum_size = Vector2(0, 420)
	board.draw.connect(_draw_board)
	board.gui_input.connect(_on_board_input)
	root.add_child(board)

	msg = RubyLabel.new()
	msg.font_size = 24
	msg.ruby_size = 12
	msg.color = GOLD
	msg.custom_minimum_size = Vector2(0, 76)
	root.add_child(msg)

	# 難しさを えらぶ 段(問題を 解く 番)
	pick_row = HBoxContainer.new()
	pick_row.add_theme_constant_override("separation", 10)
	root.add_child(pick_row)
	for i in LEVELS.size():
		var lv: Dictionary = LEVELS[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 92)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 24)
		b.text = "%s
%s" % [String(lv["star"]), String(lv["name"])]
		GameState.style_button(b, lv["color"])
		b.pressed.connect(_pick_level.bind(i))
		pick_row.add_child(b)

	# なぞる 段(取る土地を 決める 番)
	claim_row = HBoxContainer.new()
	claim_row.add_theme_constant_override("separation", 10)
	claim_row.visible = false
	root.add_child(claim_row)
	redo_btn = Button.new()
	redo_btn.text = "なぞりなおす"
	redo_btn.custom_minimum_size = Vector2(0, 92)
	redo_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	redo_btn.add_theme_font_size_override("font_size", 24)
	GameState.style_button(redo_btn, Color(0.42, 0.34, 0.30))
	redo_btn.pressed.connect(_clear_marks)
	claim_row.add_child(redo_btn)
	auto_btn = Button.new()
	auto_btn.text = "おまかせ"
	auto_btn.custom_minimum_size = Vector2(0, 92)
	auto_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	auto_btn.add_theme_font_size_override("font_size", 24)
	GameState.style_button(auto_btn, Color(0.30, 0.40, 0.56))
	auto_btn.pressed.connect(_auto_mark)
	claim_row.add_child(auto_btn)
	act_btn = Button.new()
	act_btn.custom_minimum_size = Vector2(0, 92)
	act_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	act_btn.size_flags_stretch_ratio = 1.5
	act_btn.add_theme_font_size_override("font_size", 26)
	GameState.style_button(act_btn, Color(0.22, 0.55, 0.35))
	act_btn.pressed.connect(_on_act)
	claim_row.add_child(act_btn)

	_build_quiz()
	cutin = Control.new()
	cutin.set_anchors_preset(Control.PRESET_FULL_RECT)
	cutin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cutin.visible = false
	cutin.draw.connect(_draw_cutin)
	add_child(cutin)
	# カラスは 帯の 中だけに 描く(全身を 出すと 盤面が 見えなくなる)
	cut_band = Control.new()
	cut_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cut_band.clip_contents = true
	cut_band.draw.connect(_draw_cut_band)
	cutin.add_child(cut_band)
	_make_island()
	msg.set_ruby_text("難しさをえらんで 問題を解くと、答えの数だけ 土地を 広げられる。石碑は 毎ターン +2 マス(取られたら 戻らない)", true)
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
	_sprinkle(ROCK, int(isle_def["rocks"]))
	_sprinkle(SPRING, 3)
	_sprinkle(RUIN, 2)
	# 出発点。じぶんは 下、カラスは 上
	_seed_owner(MINE, H - 1)
	_seed_owner(CROW, 0)
	_place_shrines()


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


## 石碑を 3 つ 置く。どちらの 出発点からも 離れた ところに 散らす。
## 石碑は 持っている あいだ ずっと 毎ターン +2 マス ―― だから 取り合いに なる
func _place_shrines() -> void:
	shrines.clear()
	# まん中は 取り合い、あとの 2 つは たがいの 側に 1 つずつ
	var want := [Vector2i(W / 2, H / 2), Vector2i(1, H - 5), Vector2i(W - 2, 4)]
	for w in want:
		var best := Vector2i(-1, -1)
		var best_d := 999
		for y in H:
			for x in W:
				if cell[y][x] != EMPTY:
					continue
				var far := mini(_dist_to(Vector2i(x, y), MINE), _dist_to(Vector2i(x, y), CROW))
				if far < 3:
					continue
				var near_other := false
				for sh in shrines:
					if absi(sh.x - x) + absi(sh.y - y) < 4:
						near_other = true
				if near_other:
					continue
				var d := absi(x - w.x) + absi(y - w.y)
				if d < best_d:
					best_d = d
					best = Vector2i(x, y)
		if best.x >= 0:
			cell[best.y][best.x] = SHRINE
			shrines.append(best)


## その持ち主が 石碑を いくつ 持っているか
func _shrine_count(kind: int) -> int:
	var n := 0
	for sh in shrines:
		if cell[sh.y][sh.x] == kind:
			n += 1
	return n


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
				if k != EMPTY and k != SPRING and k != RUIN and k != SHRINE:
					continue
				if _cost_of(cv) > need - _marked_cost():
					continue
				if not _touches_claim(cv):
					continue
				var gr := Rect2(o + Vector2(float(x), float(y)) * s, Vector2(s, s))
				c.draw_rect(gr.grow(-3.0), Color(GOLD.r, GOLD.g, GOLD.b, puls), false, 3.0)
	# 陣地の ふちを 太く(かたちが 読めるように)
	_draw_outline(c, MINE, COL[MINE].lightened(0.45), o, s)
	_draw_outline(c, CROW, Color(0.72, 0.68, 0.80), o, s)
	# なぞって選んだマス
	for m in marked:
		var mr := Rect2(o + Vector2(float(m.x), float(m.y)) * s, Vector2(s, s))
		c.draw_rect(mr, Color(COL[MINE].r, COL[MINE].g, COL[MINE].b, 0.55))
		c.draw_rect(mr, GOLD, false, 3.0)
	# 石碑(拠点)。持ち主の 色の 旗が 立ち、毎ターン +2 マス
	var font := ThemeDB.fallback_font
	for i in shrines.size():
		var sh: Vector2i = shrines[i]
		var owner: int = cell[sh.y][sh.x]
		var at := o + Vector2(float(sh.x) + 0.5, float(sh.y) + 0.5) * s
		var puls := 1.0 + sin(float(Time.get_ticks_msec()) * 0.004 + float(i)) * 0.06
		# 台座と 柱
		c.draw_rect(Rect2(at + Vector2(-s * 0.30, s * 0.18), Vector2(s * 0.60, s * 0.14)),
			Color(0.55, 0.50, 0.42))
		c.draw_rect(Rect2(at + Vector2(-s * 0.16, -s * 0.30), Vector2(s * 0.32, s * 0.50)),
			Color(0.80, 0.76, 0.66))
		c.draw_rect(Rect2(at + Vector2(-s * 0.16, -s * 0.30), Vector2(s * 0.32, s * 0.50)),
			INK, false, 2.0)
		# 持ち主の 旗
		var flag_col: Color = GOLD
		if owner == MINE:
			flag_col = COL[MINE].lightened(0.25)
		elif owner == CROW:
			flag_col = Color(0.75, 0.72, 0.82)
		c.draw_line(at + Vector2(0, -s * 0.30), at + Vector2(0, -s * 0.62 * puls), INK, 3.0)
		c.draw_colored_polygon(PackedVector2Array([
			at + Vector2(2, -s * 0.62 * puls), at + Vector2(s * 0.34, -s * 0.52 * puls),
			at + Vector2(2, -s * 0.42 * puls)]), flag_col)
		c.draw_string(font, at + Vector2(-s * 0.5, s * 0.46), "+%d" % SHRINE_GAIN,
			HORIZONTAL_ALIGNMENT_CENTER, s, int(s * 0.30), flag_col)


# =========================================================
# 指の操作
# =========================================================

func _on_board_input(event: InputEvent) -> void:
	if over or quiz.visible or auto_fill:
		return
	var pressed := false
	var at := Vector2.ZERO
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if not event.pressed:
			last_drag = Vector2i(-1, -1)
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
		last_drag = Vector2i(-1, -1)
		return
	if pressed or last_drag.x < 0:
		last_drag = cv
		_mark(cv)
		return
	# 速く なぞると 点と点の 間の マスが 飛ぶ。あいだを 埋めながら 取る
	while last_drag != cv:
		var step := Vector2i(signi(cv.x - last_drag.x), 0)
		if step.x == 0:
			step = Vector2i(0, signi(cv.y - last_drag.y))
		last_drag += step
		_mark(last_drag)


## 難しさを えらんで 問題を 開く。むずかしいほど 大きく 取れるが、
## まちがえられる 回数が 少ない(むずかしい は 1 回で おしまい)
func _pick_level(i: int) -> void:
	if need > 0 or over or auto_fill:
		return
	level = clampi(i, 0, LEVELS.size() - 1)
	miss = 0
	_open_quiz(int(LEVELS[level]["tier"]))


## そのマスを 取るのに いくつ つかうか。カラスの陣地は 押し返すので 2 つぶん
## 取れるのは 空きマスだけ。取られた ところは もう 戻らない ―
## 押し返せると、どこを どう 取るかの 読み合いが うすくなるため
func _cost_of(_cv: Vector2i) -> int:
	return 1


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
	if k != EMPTY and k != SPRING and k != RUIN and k != SHRINE:
		return
	if _marked_cost() + _cost_of(cv) > need:
		return
	if not _touches_claim(cv):
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
			if k != EMPTY and k != SPRING and k != RUIN and k != SHRINE:
				continue
			if _cost_of(cv) > left:
				continue
			if _touches_claim(cv):
				n += 1
	return n


## 伸ばせるのは、**自分の陣地の となり**か、いま なぞっている かたまりの となり。
## 旗(立て札)も 陣地の 1 つに なるので、そこからも 伸ばせる。
##
## 「旗からしか 伸ばせない」に すると、どこに 旗を 立てるかだけの 遊びに なって
## 陣取りの 読み合いが 消えてしまう。旗は「その 1 マスを ただで もらえる
## 足がかり」に とどめて、伸ばす 先は 自分で えらぶ
func _touches_claim(cv: Vector2i) -> bool:
	for d in DIRS:
		var n := cv + d
		if n.x < 0 or n.x >= W or n.y < 0 or n.y >= H:
			continue
		if marked.has(n) or cell[n.y][n.x] == MINE:
			return true
	return false


## なぞり直し。旗は 残す ― 旗まで 消すと 伸ばす 起点が 無くなり、
## どこも なぞれなくなって しまう(実際に そうなった)
func _clear_marks() -> void:
	if marked.is_empty():
		return
	GameState.play_sfx("tap")
	marked.clear()
	msg.set_ruby_text("もう一度 なぞろう", true)
	_refresh()


# =========================================================
# ターンの流れ
# =========================================================

func _on_act() -> void:
	if auto_fill:
		return
	if over:
		GameState.change_scene("res://scenes/main.tscn")
		return
	if need <= 0:
		GameState.play_sfx("fail")
		msg.set_ruby_text("下の 3 つから 難しさを えらぼう", true)
		return
	if marked.is_empty() and _markable_left() == 0:
		# まわりを ぜんぶ カラスと岩に 囲まれた。ここで 勝負あり
		msg.set_ruby_text("囲まれた! もう 広げられない。", true)
		_finish()
		return
	if _marked_cost() != need and _markable_left() > 0:
		GameState.play_sfx("fail")
		msg.set_ruby_text("あと %d マスぶん" % (need - _marked_cost()), true)
		return
	if marked.is_empty():
		GameState.play_sfx("fail")
		msg.set_ruby_text("広げられる ところが ない。ふちの マスを なぞろう", true)
		return
	_take_marked()


## 取った土地を 自分のものにする
func _take_marked() -> void:
	GameState.play_sfx("clear")
	var got_spring := 0
	var got_ruin := 0
	var got_shrine := 0
	last_take = marked.size()
	for m in marked:
		if cell[m.y][m.x] == SPRING:
			got_spring += 1
		elif cell[m.y][m.x] == RUIN:
			got_ruin += 1
		elif cell[m.y][m.x] == SHRINE:
			got_shrine += 1
		cell[m.y][m.x] = MINE
	marked.clear()
	need = 0
	bonus = got_spring * 3
	var extra := ""
	if got_spring > 0:
		extra += "  泉! つぎは +%d マス" % bonus
	if got_ruin > 0:
		extra += "  遺跡を見つけた!"
	if got_shrine > 0:
		extra += "  石碑を %d こ 取った! 毎ターン +%d マス" % [got_shrine,
			got_shrine * SHRINE_GAIN]
	msg.set_ruby_text("土地を広げた。" + extra, true)
	# ここで待たせない。待つと「カラスの番」が遅れて、
	# 先に つぎの問題を開けてしまう(カラスが 一度も 広げられなかった)
	_crow_turn()


## まちがえ すぎたとき ― そのターンは 何も 取れずに カラスの番へ
func _lose_turn(why: String) -> void:
	GameState.play_sfx("fail")
	need = 0
	marked.clear()
	cut_text_override = _crow_says("laugh")
	msg.set_ruby_text(why, true)
	_crow_turn()


## カラスの番。じぶんに 近いところから 広げ、細いところを 1 つ 切り取る
func _crow_turn() -> void:
	# カラスは じぶんが 取ったのと 同じくらい 広げる(競り合いに なるように)
	# 石碑を 持っている ぶん、カラスも 毎ターン 多く 広げる
	var n := int(round(float(clampi(last_take, 3, 7)) * float(isle_def["crow"]))) 		+ crow_extra + _shrine_count(CROW) * SHRINE_GAIN
	crow_extra = 0
	var dmap := _dist_map(MINE)
	for i in n:
		var best := Vector2i(-1, -1)
		var best_score := -999
		for y in H:
			for x in W:
				var cv := Vector2i(x, y)
				var ck: int = cell[y][x]
				if ck != EMPTY and ck != SPRING and ck != RUIN and ck != SHRINE:
					continue
				if not _touches(cv, CROW):
					continue
				# じぶんの陣地に 近いマスほど 高い点(にらみ合いに なる)
				var score := 40 - mini(int(dmap[y][x]), 30) * 3
				if cell[y][x] == SPRING:
					score += 12
				if cell[y][x] == SHRINE:
					score += 22          # 石碑は ねらうが、一直線には ならない
				if score > best_score:
					best_score = score
					best = cv
		if best.x < 0:
			break
		var was_shrine: bool = shrines.has(best)
		cell[best.y][best.x] = CROW
		if was_shrine:
			msg.set_ruby_text("石碑を カラスに 取られた! 取り返しに 行こう", true)
			cut_text_override = "この石碑は もらった。毎ターン 2 マスずつ 頂こう"
	if turn % 2 == 0:
		_crow_cut()
	turn += 1
	if turn > MAX_TURN or _count(EMPTY) + _count(SPRING) + _count(RUIN) + _count(SHRINE) == 0:
		_finish()
		return
	GameState.play_sfx("type")
	# 何を されたのかが 分かるように、カラスを 大きく 出す
	var mine := _count(MINE)
	var crow := _count(CROW)
	var mood := "calm" if crow >= mine else "panic"
	var line := _crow_says("win" if crow >= mine else "lose")
	if cut_text_override != "":
		line = cut_text_override
		mood = "angry"
		cut_text_override = ""
	_cut_in(mood, line)
	_refresh()
	if _decided() and not over:
		# もう 追いつけない。残りは 自動で 塗って 見せる
		auto_fill = true
		var mine2 := _count(MINE)
		var crow2 := _count(CROW)
		var win_side := mine2 > crow2
		var left_n := _potential(CROW) if win_side else _potential(MINE)
		var who := "カラス" if win_side else "こちら"
		msg.set_ruby_text("勝負あり ― %s は もう %d マスまでしか 伸ばせない。のこりは 自動で ぬる"
			% [who, left_n], true)


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
				msg.set_ruby_text("カラスに 細いところを 切られた!", true)
				cut_text_override = _crow_says("cut")
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
	back.color = Color(0.07, 0.10, 0.17, 1.0)
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

	q_lbl = RubyLabel.new()
	q_lbl.font_size = 26
	q_lbl.ruby_size = 13
	q_lbl.color = Color(0.92, 0.95, 1.0)
	q_lbl.custom_minimum_size = Vector2(0, 124)
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
## 出す問題は **その島の 範囲**から。難しさで はばの 中の どこを 使うかが
## 変わり、難度ラダーの 段(解き方の 種類)も 毎回 ふり直す
func _open_quiz(_tier: int) -> void:
	# 島そのものが 買い切りの ゲートに なっているので、ここでは 範囲を そのまま 使う
	var stages: Array = ProblemGen.stages_of(String(isle_def["course"]))
	var top := stages.size()
	var band: Array = IslandDefs.stage_range(isle, level)
	var lo := clampi(int(band[0]), 0, top - 1)
	var hi := clampi(int(band[1]), lo, top - 1)
	var idx := prng.randi_range(lo, hi)
	var base := int(LEVELS[level]["tier"])
	var tier2 := clampi(base + prng.randi_range(0, int(LEVELS[level]["span"])), 0, 8)
	last_stage = String(stages[idx]["id"])
	last_tier = tier2
	problem = ProblemGen.generate(last_stage, prng, tier2)
	figure.set_spec(problem["fig"])
	input_text = ""
	keypad.answer_lbl.text = ""
	keypad.unit_lbl.text = String(problem.get("unit", ""))
	q_lbl.set_ruby_text("%s\n%s" % [String(problem["q"]), _reward_note()], true)
	# カットインが 出たままだと 電卓の 上に かぶる。ここで 引っこめる
	cut_t = 0.0
	cutin.visible = false
	quiz.visible = true
	GameState.play_sfx("tap")


## 答え → 取れるマス数の 決め方(ためし版の 目安)
func _cells_for(v: float) -> int:
	var unit := String(problem.get("unit", ""))
	var per := float(LEVELS[level]["per"])
	if unit == "度":
		per *= 1.5                      # 角度は 数が 大きいので ならす
	var lo := int(LEVELS[level]["low"])
	var hi := int(LEVELS[level]["high"])
	var n := clampi(int(round(absf(v) / per)), lo, hi)
	if miss > 0:
		# まちがえた ぶん 減る。ただし 下限の 半分は のこす
		n = maxi(int(float(n) / pow(2.0, float(miss))), lo / 2)
	return n


## 何マスもらえるかは 答えの 大きさで 変わるが、難しさごとの 下限と 上限の 中。
## 「答え ÷ 7 マスぶん」は 7 マスもらえると 読めてしまうので、
## そう 書かずに もらえる 数の はばで 出す
func _reward_note() -> String:
	var lv: Dictionary = LEVELS[level]
	var lost := "" if miss == 0 else "  ※ まちがえたので もらえる マスは %d 分の 1" % int(pow(2, miss))
	return "正解すると %d〜%d マス(%s。答えが 大きいほど 多い)%s" % [
		int(lv["low"]), int(lv["high"]), String(lv["name"]), lost]


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
		q_lbl.set_ruby_text(String(res["err"]), true)
		return
	GameState.play_sfx("type")
	input_text = ExprEval.fmt(float(res["value"]))
	keypad.answer_lbl.text = input_text


func _submit() -> void:
	var v := Keypad.value_of(input_text)
	if is_nan(v):
		GameState.play_sfx("fail")
		q_lbl.set_ruby_text("数を入れてね(式のままでもよい)", true)
		return
	if absf(v - float(problem["answer"])) > maxf(float(problem.get("tol", 0.01)), 0.01):
		GameState.play_sfx("fail")
		miss += 1
		input_text = ""
		keypad.answer_lbl.text = ""
		var can: int = int(LEVELS[level]["miss"])
		if miss >= can:
			# えらんだ 難しさの ぶんだけ しか まちがえられない
			quiz.visible = false
			_lose_turn("%s を はずした。このターンは 何も 取れない" % String(LEVELS[level]["name"]))
			return
		q_lbl.set_ruby_text("ちがう ― もらえる マスが 半分に なった(のこり %d 回)\n%s\n%s" % [
			can - miss, String(problem["q"]), _reward_note()], true)
		return
	GameState.play_sfx("correct")
	var shrine_bonus := _shrine_count(MINE) * SHRINE_GAIN
	var got := _cells_for(float(problem["answer"]))
	need = got + bonus + shrine_bonus
	bonus = 0
	quiz.visible = false
	marked.clear()
	var note := ""
	if shrine_bonus > 0:
		note += " + 石碑 %d" % shrine_bonus
	msg.set_ruby_text("正解! 答え %s → %d マス%s = %d マスぶん なぞろう" % [
		ProblemGen.fmt(float(problem["answer"])), got, note, need], true)
	_refresh()


# =========================================================
# 画面の更新・おわり
# =========================================================

func _refresh() -> void:
	pot_mine = _potential(MINE)
	pot_crow = _potential(CROW)
	var mine := _count(MINE)
	var crow := _count(CROW)
	var all := maxi(mine + crow + _count(EMPTY) + _count(SPRING) + _count(RUIN) + _count(SHRINE), 1)
	# 割合は 下の 帯(顔つき)に 出すので、ここは ターン数だけ
	head_lbl.set_ruby_text("  %d島 %s  %d/%d ターン  石碑 %d-%d" % [isle + 1,
		String(isle_def["name"]), mini(turn, MAX_TURN), MAX_TURN,
		_shrine_count(MINE), _shrine_count(CROW)], true)
	pick_row.visible = need <= 0 and not over and not auto_fill
	claim_row.visible = not pick_row.visible
	if over:
		act_btn.text = "もどる"
	elif need <= 0:
		pass
	else:
		act_btn.text = "ここに きめる(%d/%d)" % [_marked_cost(), need]
		if _marked_cost() < need and _markable_left() == 0 and not marked.is_empty():
			act_btn.text = "ここまでで きめる(%d/%d)" % [_marked_cost(), need]
	redo_btn.disabled = marked.is_empty()
	auto_btn.disabled = need <= 0 or _markable_left() <= 0
	board.queue_redraw()


func _finish() -> void:
	over = true
	var mine := _count(MINE)
	var crow := _count(CROW)
	var all := maxi(mine + crow + _count(EMPTY) + _count(SPRING) + _count(RUIN) + _count(SHRINE), 1)
	var pct := int(round(100.0 * float(mine) / float(all)))
	var cpct := int(round(100.0 * float(crow) / float(all)))

	msg.set_ruby_text("おわり ― じぶん %d%% / カラス %d%%" % [pct, cpct], true)
	_refresh()
	_show_result(pct, cpct)


func _process(delta: float) -> void:
	_t += delta
	if quiz.visible and cutin.visible:
		cut_t = 0.0
		cutin.visible = false
	if cut_t > 0.0:
		cut_t -= delta / 2.6
		cutin.queue_redraw()
		if cut_t <= 0.0:
			cut_t = 0.0
			cutin.visible = false
	if auto_fill and cut_t <= 0.0:
		auto_t += delta
		while auto_t > 0.045:
			auto_t -= 0.045
			_auto_fill_step()
	# 光り方の 点滅・カットイン・自動ぬり ― 動いている ときだけ、
	# それも 20 回/秒 で 足りる。ずっと 60 回/秒 で 描き直すと
	# 電池が 減り、端末も 熱くなる
	if over or quiz.visible:
		return
	var moving := need > 0 or cut_t > 0.0 or auto_fill
	if not moving:
		return
	draw_t += delta
	if draw_t < 0.05:
		return
	draw_t = 0.0
	board.queue_redraw()
	bar.queue_redraw()


# =========================================================
# 登場人物(カラス と たんけんか)
# =========================================================

## カラスの ひとこと。いまの 形勢と 出来事で 変える
const CROW_LINES := {
	"win": [
		"その計算、500円で売ってやろうか?",
		"ふむ。土地の広さも 分からんとはな",
		"わたしの島だ。もう名前も決めてある",
	],
	"lose": [
		"…なぜ 合っている?",
		"まぐれだ。つぎは そうはいかん",
		"その公式、どこで 手に入れた!",
	],
	"laugh": [
		"はずれ! だから 買えと 言ったのだ",
		"ほら見ろ。だから 公式は 売り物なのだ",
	],
	"cut": [
		"細い道は 切らせてもらう",
		"そこは わたしの ものだ",
	],
}


func _crow_says(kind: String) -> String:
	var list: Array = CROW_LINES.get(kind, CROW_LINES["win"])
	return String(list[prng.randi_range(0, list.size() - 1)])


## カラスの番の カットイン。大きく出して、何をされたのか 分かるようにする
func _cut_in(mood: String, text: String) -> void:
	cut_mood = mood
	cut_text = text
	cut_t = 1.0
	cutin.visible = true
	cutin.queue_redraw()


func _draw_cutin() -> void:
	# 盤面は 見えたまま。うっすら 暗くする だけに する
	var e := clampf(cut_t, 0.0, 1.0)
	var fade := minf(e * 6.0, 1.0)
	cutin.draw_rect(Rect2(Vector2.ZERO, cutin.size), Color(0.04, 0.05, 0.09, 0.22 * fade))
	# 帯は 盤面の 下ぞろえ(指を 置く ところを ふさがない)
	var bh := minf(cutin.size.y * 0.30, 268.0)
	var top := board.global_position.y + board.size.y - bh
	cut_band.position = Vector2(0, top)
	cut_band.size = Vector2(cutin.size.x, bh)
	cut_band.queue_redraw()


func _draw_cut_band() -> void:
	var c := cut_band
	var w := c.size.x
	var h := c.size.y
	var e := clampf(cut_t, 0.0, 1.0)
	var slide := (1.0 - ease(minf(e * 6.0, 1.0), 0.4)) * w
	# 帯の 地は 明るく する(黒い カラスを 黒地に 出すと 見えない)
	c.draw_rect(Rect2(slide, 0, w, h), Color(0.93, 0.88, 0.78, 0.98))
	c.draw_rect(Rect2(slide, 0, w, h), Color(0.42, 0.32, 0.22), false, 3.0)
	c.draw_line(Vector2(slide, 0), Vector2(w + slide, 0), GOLD, 5.0)
	# カラスは 胸から 上だけ(足もとは 帯の 下に かくれる)
	Chars.crow(c, Vector2(w * 0.78 + slide, h * 1.55), h * 1.3, cut_mood, _t, -1.0)
	Chars.bubble(c, Vector2(w * 0.31 + slide, h * 0.80), Vector2(w * 0.54, h * 0.52),
		cut_text, 1.0, 23)
	c.draw_string(ThemeDB.fallback_font, Vector2(slide + 16.0, h - 14.0),
		"カラスのターン", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.55, 0.22, 0.14))


## 上の 帯。両はしに 顔を 出して、いま 誰と 戦っているかを 見せる
func _draw_bar() -> void:
	var c := bar
	var w := c.size.x
	var h := c.size.y
	var mine := _count(MINE)
	var crow := _count(CROW)
	var all := maxi(mine + crow + _count(EMPTY) + _count(SPRING) + _count(RUIN) + _count(SHRINE), 1)
	var mp := float(mine) / float(all)
	var cp := float(crow) / float(all)
	var x0 := 104.0
	var x1 := w - 104.0
	var bw := x1 - x0
	var y := h * 0.52
	c.draw_rect(Rect2(x0, y - 13.0, bw, 26.0), Color(0.80, 0.73, 0.56))
	# うすい ところ = このまま 伸ばせば 届く ところ(行ける 空きマス)。
	# 盤面ぜんぶを たどる 数え方なので、毎フレームでは なく
	# 盤面が 変わったときだけ 数え直す(_refresh)
	var mpp := float(pot_mine) / float(all)
	var cpp := float(pot_crow) / float(all)
	c.draw_rect(Rect2(x0, y - 13.0, bw * mpp, 26.0), Color(COL[MINE].r, COL[MINE].g,
		COL[MINE].b, 0.35))
	c.draw_rect(Rect2(x1 - bw * cpp, y - 13.0, bw * cpp, 26.0),
		Color(0.55, 0.52, 0.62, 0.45))
	c.draw_rect(Rect2(x0, y - 13.0, bw * mp, 26.0), COL[MINE])
	c.draw_rect(Rect2(x1 - bw * cp, y - 13.0, bw * cp, 26.0), COL[CROW].lightened(0.12))
	c.draw_rect(Rect2(x0, y - 13.0, bw, 26.0), Color(0, 0, 0, 0.35), false, 2.0)
	var font := ThemeDB.fallback_font
	c.draw_string(font, Vector2(x0 + 6.0, y + 8.0), "%d%%" % int(round(mp * 100.0)),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.95))
	c.draw_string(font, Vector2(x1 - 60.0, y + 8.0), "%d%%" % int(round(cp * 100.0)),
		HORIZONTAL_ALIGNMENT_RIGHT, 54, 22, Color(1, 1, 1, 0.95))
	# 顔(左=あなた、右=カラス)
	Chars.hero(c, Vector2(46.0, h - 4.0), h * 0.94, "guts" if mp > cp else "calm", _t)
	Chars.crow(c, Vector2(w - 44.0, h - 4.0), h * 0.94,
		"calm" if cp >= mp else "panic", _t)


# =========================================================
# 決着が 見えたら 自動で 塗る
# =========================================================

## そのがわが これから 最大 いくつまで 増やせるか。
## 空きマスを たどって 行ける ところ だけを 数える ―― 岩や 相手の 陣地に
## 囲まれて 出られなければ、空きマスが たくさん 残っていても もう 伸びない
func _potential(kind: int) -> int:
	var seen := {}
	var stack: Array[Vector2i] = []
	for y in H:
		for x in W:
			if cell[y][x] == kind:
				stack.append(Vector2i(x, y))
	var reach := 0
	while not stack.is_empty():
		var cur: Vector2i = stack.pop_back()
		for d in DIRS:
			var n := cur + d
			if n.x < 0 or n.x >= W or n.y < 0 or n.y >= H:
				continue
			if seen.has(n):
				continue
			var k: int = cell[n.y][n.x]
			if k != EMPTY and k != SPRING and k != RUIN and k != SHRINE:
				continue
			seen[n] = true
			reach += 1
			stack.append(n)
	return _count(kind) + reach


## 勝負が 決まったか。
##   ・残り 全部を 取っても 追いつけない
##   ・または、伸ばせる 先が なくなって、めいっぱい 取っても 届かない
## 「もう 決まっているのに 続く」のは ただの 作業なので、そこで 切り上げる
func _decided() -> bool:
	var mine := _count(MINE)
	var crow := _count(CROW)
	var rest := _count(EMPTY) + _count(SPRING) + _count(RUIN) + _count(SHRINE)
	if absi(mine - crow) > rest:
		return true
	# 取り返しは できないので、伸ばせる 先が すべて。少しだけ 余裕を みる
	var slack := 2
	if _potential(CROW) + slack < mine:
		return true
	if _potential(MINE) + slack < crow:
		return true
	return false


## 残りのマスを、近いほうの 陣地に 順ぐりに 塗って 終わらせる。
## 決まった 勝負を なぞり続けるのは ただの 作業なので、そこは 見せるだけにする
func _auto_fill_step() -> void:
	# 距離は 1 マス塗るたびに 全マスを 数え直すと 重い。
	# 幅優先で 一度に 全部の 距離を 作って 使いまわす
	var dmap_mine := _dist_map(MINE)
	var dmap_crow := _dist_map(CROW)
	var best := Vector2i(-1, -1)
	var best_kind := EMPTY
	var best_d := 9999
	for y in H:
		for x in W:
			var k: int = cell[y][x]
			if k != EMPTY and k != SPRING and k != RUIN and k != SHRINE:
				continue
			var dm: int = dmap_mine[y][x]
			var dc: int = dmap_crow[y][x]
			var d := mini(dm, dc)
			if d < best_d:
				best_d = d
				best = Vector2i(x, y)
				best_kind = MINE if dm <= dc else CROW
	if best.x < 0:
		auto_fill = false
		_finish()
		return
	cell[best.y][best.x] = best_kind
	GameState.play_sfx("type")
	board.queue_redraw()
	bar.queue_redraw()


## その持ち主の 陣地からの 距離を、盤面ぜんぶぶん 一度に 作る(幅優先)。
## 1 マスごとに 全マスを 数え直すと、マスの 数の 2 乗ぶん かかる
func _dist_map(kind: int) -> Array:
	var d: Array = []
	var q: Array[Vector2i] = []
	for y in H:
		var row: Array = []
		for x in W:
			if cell[y][x] == kind:
				row.append(0)
				q.append(Vector2i(x, y))
			else:
				row.append(9999)
		d.append(row)
	var head := 0
	while head < q.size():
		var cur: Vector2i = q[head]
		head += 1
		for dir in DIRS:
			var n := cur + dir
			if n.x < 0 or n.x >= W or n.y < 0 or n.y >= H:
				continue
			if cell[n.y][n.x] == SEA or cell[n.y][n.x] == ROCK:
				continue
			if int(d[n.y][n.x]) <= int(d[cur.y][cur.x]) + 1:
				continue
			d[n.y][n.x] = int(d[cur.y][cur.x]) + 1
			q.append(n)
	return d


func _dist_to(cv: Vector2i, kind: int) -> int:
	var best := 999
	for y in H:
		for x in W:
			if cell[y][x] == kind:
				best = mini(best, absi(x - cv.x) + absi(y - cv.y))
	return best


## いま 取れる マスの 中から、それらしい ところを 自動で えらぶ。
## 泉と遺跡 → カラスと 接する ところ → 旗の 近く の 順
func _auto_mark() -> void:
	var guard := 0
	while _marked_cost() < need and guard < 200:
		guard += 1
		var best := Vector2i(-1, -1)
		var best_score := -9999
		var left := need - _marked_cost()
		for y in H:
			for x in W:
				var cv := Vector2i(x, y)
				if marked.has(cv):
					continue
				var k: int = cell[y][x]
				if k != EMPTY and k != SPRING and k != RUIN and k != SHRINE:
					continue
				if _cost_of(cv) > left:
					continue
				if not _touches_claim(cv):
					continue
				var score := 0
				if k == SHRINE:
					score += 120          # 石碑は 毎ターン +2 マス。まっさきに
				elif k == SPRING:
					score += 60
				elif k == RUIN:
					score += 40
				if _touches(cv, CROW):
					score += 12           # 前線を 広げると 切られにくい
				if score > best_score:
					best_score = score
					best = cv
		if best.x < 0:
			break
		var was := marked.size()
		_mark(best)
		if marked.size() == was:
			break                      # 取れない ものを えらび続けない ための 保険
	GameState.play_sfx("tap")
	_refresh()


# =========================================================
# 決着の 画面
# =========================================================

## 勝ち負けを ちゃんと 見せる。勝ったら つぎの島が 開く
func _show_result(mine_pct: int, crow_pct: int) -> void:
	var win := mine_pct > crow_pct
	var star := 0
	if win:
		GameState.record_island_clear(isle)
		GameState.bump_stat("island_clear")
		GameState.record_island_star(isle, mine_pct)
		star = int(GameState.island_star.get(str(isle), 0))
	var layer := Control.new()
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(layer)
	result_layer = layer
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.06, 0.11, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)

	# 大きな 絵(勝ったら カラスが くやしがる、負けたら 高笑い)
	var art := Control.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.draw.connect(func() -> void:
		var w := art.size.x
		var h := art.size.y
		var tall := h * 0.34
		Chars.crow(art, Vector2(w * 0.74, h * 0.56), tall, "panic" if win else "laugh", _t, -1.0)
		Chars.hero(art, Vector2(w * 0.26, h * 0.56), tall * 0.92, "guts" if win else "calm", _t))
	layer.add_child(art)

	var ins := GameState.safe_insets()
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 24
	v.offset_right = -24
	v.offset_top = float(ins["top"]) + 20.0
	v.offset_bottom = -float(ins["bottom"]) - 20.0
	v.add_theme_constant_override("separation", 10)
	layer.add_child(v)

	var top_pad := Control.new()
	top_pad.custom_minimum_size = Vector2(0, 26)
	v.add_child(top_pad)
	var big := Label.new()
	big.text = "島を 取った!" if win else "島を 取られた…"
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big.add_theme_font_size_override("font_size", 52)
	big.add_theme_color_override("font_color", GOLD if win else Color(0.85, 0.6, 0.55))
	v.add_child(big)

	var sub := Label.new()
	var stars := ""
	for k in 3:
		stars += "★" if k < star else "☆"
	sub.text = "%d島 %s   じぶん %d%%  ―  カラス %d%%%s" % [isle + 1, String(isle_def["name"]),
		mine_pct, crow_pct, ("   " + stars) if win else ""]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 26)
	sub.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	v.add_child(sub)

	if win and star < 3:
		var more := Label.new()
		more.text = "もっと 広く 取ると ★が ふえる(70%で ★★ / 85%で ★★★)"
		more.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		more.add_theme_font_size_override("font_size", 22)
		more.add_theme_color_override("font_color", Color(0.80, 0.84, 0.96))
		v.add_child(more)

	var say := Label.new()
	say.text = "「%s」" % (_crow_says("lose") if win else _crow_says("win"))
	say.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	say.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	say.add_theme_font_size_override("font_size", 24)
	say.add_theme_color_override("font_color", Color(0.80, 0.84, 0.96))
	v.add_child(say)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)

	var nxt_i := IslandDefs.next_in(GameState.island_range, isle)
	if win and nxt_i >= 0:
		var nxt: Dictionary = IslandDefs.of(nxt_i)
		var open := Label.new()
		open.text = "つぎの島が 開いた ― %d島 %s(%s)" % [nxt_i + 1, String(nxt["name"]),
			String(nxt["level"])]
		open.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		open.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		open.add_theme_font_size_override("font_size", 25)
		open.add_theme_color_override("font_color", Color(0.65, 1.0, 0.75))
		v.add_child(open)
		var go := Button.new()
		go.text = "つぎの島へ ▶"
		go.custom_minimum_size = Vector2(0, 96)
		go.add_theme_font_size_override("font_size", 30)
		GameState.style_button(go, Color(0.22, 0.55, 0.35))
		if GameState.island_needs_purchase(nxt_i):
			go.text = "つぎの島を ひらく"
			GameState.style_button(go, Color(0.78, 0.55, 0.15))
		go.pressed.connect(func() -> void:
			GameState.play_sfx("tap")
			GameState.island_index = nxt_i
			GameState.change_scene("res://scenes/island.tscn"))
		v.add_child(go)
	elif win:
		var all_done := Label.new()
		var pr := IslandDefs.progress_in(GameState.island_range, GameState.island_clear)
		all_done.text = "%s の島を すべて 取った!(%d / %d)" % [
			String(IslandDefs.range_of(GameState.island_range)["name"]), int(pr[0]), int(pr[1])]
		all_done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		all_done.add_theme_font_size_override("font_size", 27)
		all_done.add_theme_color_override("font_color", GOLD)
		v.add_child(all_done)

	var again := Button.new()
	again.text = "もう一度 この島" if not win else "この島を もう一度"
	again.custom_minimum_size = Vector2(0, 88)
	again.add_theme_font_size_override("font_size", 27)
	GameState.style_button(again, Color(0.30, 0.40, 0.56))
	again.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		GameState.island_index = isle
		GameState.change_scene("res://scenes/island.tscn"))
	v.add_child(again)

	var back := Button.new()
	back.text = "はんいを えらび直す"
	back.custom_minimum_size = Vector2(0, 80)
	back.add_theme_font_size_override("font_size", 26)
	GameState.style_button(back, Color(0.28, 0.32, 0.44))
	back.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		GameState.change_scene("res://scenes/island_select.tscn"))
	v.add_child(back)
	GameState.play_sfx("clear" if win else "fail")
