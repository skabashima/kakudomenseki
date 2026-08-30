extends Control
## 「ストーリー(小学生)」の 1 単元。
##
## ながれ: おはなし → さわって見つける(3 回) → 見つけたこと → しるしを解く(電卓) → おわり
## さわり方(act)は単元ごとに違うが、画面のつくりは同じ。
##   tear  … かどを ちぎって ならべる      slide … 平行線の間で かどを ずらす
##   fold  … 折って 重ねる                diag  … 対角線で 三角形に分ける
##   clock … 時計の 針を まわす

const GOLD := Color(1.0, 0.85, 0.3)
const SKY := Color(0.55, 0.85, 1.0)
const INK := Color(0.95, 0.97, 1.0)
const DIM := Color(0.66, 0.74, 0.88)
const OK_COL := Color(0.45, 1.0, 0.62)   # できた しるしの ○
const PIECE_COL := [Color(1.0, 0.78, 0.35), Color(0.55, 0.85, 1.0), Color(1.0, 0.60, 0.68),
	Color(0.65, 0.95, 0.70), Color(0.85, 0.75, 1.0), Color(1.0, 0.85, 0.55)]

var unit: Dictionary = {}
var phase := 0                  # 0=おはなし 1=さわる 2=しるし 3=おわり
var step := 0
var tries := 0
var cheer := 0.0

# さわる図の状態(act ごとに使う中身が変わる)
var st: Dictionary = {}
var dragging := -1

# しるし(本編の問題を 1 問)
var problem: Dictionary = {}
var input_text := ""

var map: Control
var big: Label
var talk: RubyLabel
var keypad: Keypad
var answer_row: HBoxContainer
var answer_btn: Button
var act_btn: Button
var figure: FigureView


func _ready() -> void:
	unit = KidDefs.by_id(GameState.kid_unit)
	if unit.is_empty():
		unit = KidDefs.UNITS[0]
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.14, 0.24)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

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
	back.text = "もどる"
	back.custom_minimum_size = Vector2(0, 66)
	back.add_theme_font_size_override("font_size", 26)
	GameState.style_button(back, Color(0.28, 0.32, 0.44))
	back.pressed.connect(func() -> void:
		GameState.change_scene("res://scenes/kid_map.tscn"))
	head.add_child(back)
	var title := RubyLabel.new()
	title.font_size = 30
	title.ruby_size = 15
	title.color = GOLD
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.set_ruby_text("  " + String(unit["title"]), true)
	head.add_child(title)

	map = Control.new()
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map.custom_minimum_size = Vector2(0, 400)
	map.draw.connect(_draw_map)
	map.gui_input.connect(_on_map_input)
	root.add_child(map)

	figure = FigureView.new()
	figure.size_flags_vertical = Control.SIZE_EXPAND_FILL
	figure.custom_minimum_size = Vector2(0, 400)
	# しるし(問題)を 解くときは、図に 線を 引いて 考えられるように する
	# (ゆびで なぞると 手書き、「せんを ひく」を 押すと まっすぐな 線)
	figure.visible = false
	root.add_child(figure)
	figure.add_tools(true)

	big = Label.new()
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big.add_theme_font_size_override("font_size", 38)
	big.add_theme_color_override("font_color", GOLD)
	root.add_child(big)

	talk = RubyLabel.new()
	talk.font_size = 29
	talk.ruby_size = 16
	talk.color = INK
	talk.custom_minimum_size = Vector2(0, 104)
	talk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(talk)

	keypad = Keypad.new()
	keypad.key_pressed.connect(_on_key)
	keypad.visible = false
	root.add_child(keypad)
	# ＝(計算)と こたえる を ならべる(本編 problem.gd と 同じ 使いごこち)
	answer_row = HBoxContainer.new()
	answer_row.add_theme_constant_override("separation", 10)
	answer_row.visible = false
	root.add_child(answer_row)
	var calc_btn := Button.new()
	calc_btn.text = "＝ 計算"
	calc_btn.custom_minimum_size = Vector2(0, 88)
	calc_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calc_btn.add_theme_font_size_override("font_size", 28)
	GameState.style_button(calc_btn, Color(0.24, 0.42, 0.72))
	calc_btn.pressed.connect(_calc_in_place)
	answer_row.add_child(calc_btn)
	answer_btn = Button.new()
	answer_btn.text = "こたえる"
	answer_btn.custom_minimum_size = Vector2(0, 88)
	answer_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	answer_btn.size_flags_stretch_ratio = 1.6
	answer_btn.add_theme_font_size_override("font_size", 30)
	GameState.style_button(answer_btn, Color(0.22, 0.55, 0.35))
	answer_btn.pressed.connect(_submit)
	answer_row.add_child(answer_btn)

	act_btn = Button.new()
	act_btn.custom_minimum_size = Vector2(0, 88)
	act_btn.add_theme_font_size_override("font_size", 30)
	GameState.style_button(act_btn, Color(0.22, 0.55, 0.35))
	act_btn.pressed.connect(_advance)
	root.add_child(act_btn)

	_reset_act()
	_show_step()


func _process(delta: float) -> void:
	if cheer > 0.0:
		cheer = maxf(cheer - delta * 0.9, 0.0)
		map.queue_redraw()


# =========================================================
# ながれ
# =========================================================

func _show_step() -> void:
	var intro: Array = unit["intro"]
	if step < intro.size():
		talk.set_ruby_text(String(intro[step]), true)
		big.text = ""
		act_btn.text = "つぎへ"
		act_btn.disabled = false
		return
	phase = 1
	big.text = ""
	talk.set_ruby_text(_act_lead(), true)
	act_btn.text = "さわってね"
	act_btn.disabled = true


func _advance() -> void:
	GameState.play_sfx("tap")
	var intro: Array = unit["intro"]
	if step < intro.size():
		step += 1
		_show_step()
		return
	if phase == 1:
		if tries >= 3:
			_start_quiz()
			return
		_reset_act()
		big.text = ""
		# 回ごとに やる ことが 変わる さわり方が あるので、そのつど 言いなおす
		talk.set_ruby_text(_act_lead(), true)
		act_btn.text = "さわってね"
		act_btn.disabled = true
		map.queue_redraw()
		return
	if phase == 3:
		GameState.change_scene("res://scenes/kid_map.tscn")


## 1 回 できた(3 回 くりかえして たしかめる)
func _act_done() -> void:
	cheer = 1.0
	tries += 1
	st["done"] = true          # 図の 上に 大きな ○ を 出す しるし
	GameState.play_sfx("clear" if tries >= 3 else "correct")
	big.text = _act_cheer()
	if tries >= 3:
		talk.set_ruby_text("3 回とも 合っていた。%s" % String(unit["found"]), true)
		act_btn.text = "しるしを 見る"
	else:
		# 「もう いちど」だと、まちがえて やりなおしだと 思われた。
		# 合っていた うえで つぎの 形を ためす、と 分かる ことばにする
		talk.set_ruby_text("合っていたよ。" + _act_after(), true)
		act_btn.text = "%d かいめを ためす" % (tries + 1)
	act_btn.disabled = false


func _start_quiz() -> void:
	phase = 2
	map.visible = false
	figure.visible = true
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	problem = ProblemGen.generate(String(unit["stage"]), rng, 0)
	figure.set_spec(problem["fig"])
	input_text = ""
	keypad.answer_lbl.text = " "
	keypad.unit_lbl.text = String(problem.get("unit", ""))
	keypad.visible = true
	answer_row.visible = true
	act_btn.visible = false
	big.text = ""
	talk.set_ruby_text("地図の しるし。" + _short(String(problem["q"])), true)


func _short(text: String) -> String:
	var t := text.replace("を求めなさい。", "は?")
	t = t.replace("は何度ですか。", "は何度?")
	return t.replace("ですか。", "?")


func _on_key(k: String) -> void:
	GameState.play_sfx("type")
	input_text = Keypad.apply(input_text, k)
	keypad.answer_lbl.text = input_text if input_text != "" else " "


## ＝キー: 式をその場で計算して、答え欄を計算結果に置きかえる(本編と同じ)
func _calc_in_place() -> void:
	if input_text == "":
		return
	var res: Dictionary = ExprEval.eval(input_text)
	if not bool(res["ok"]):
		GameState.play_sfx("fail")
		big.text = String(res["err"])
		return
	GameState.play_sfx("type")
	big.text = ""
	input_text = ExprEval.fmt(float(res["value"]))
	keypad.answer_lbl.text = input_text


func _submit() -> void:
	var v := Keypad.value_of(input_text)
	if is_nan(v):
		GameState.play_sfx("fail")
		big.text = "数を いれてね"
		return
	if absf(v - float(problem["answer"])) < maxf(float(problem.get("tol", 0.01)), 0.01):
		GameState.play_sfx("clear")
		big.text = "あたり！"
		talk.set_ruby_text("しるしが とけた。%s" % String(unit["found"]), true)
		keypad.visible = false
		answer_row.visible = false
		act_btn.visible = true
		act_btn.text = "もどる"
		phase = 3
		if GameState.record_kid_clear(String(unit["id"])):
			GameState.kid_walk_from = String(unit["id"])
	else:
		GameState.play_sfx("fail")
		big.text = "ちがうみたい"
		talk.set_ruby_text(String(unit["found"]) + "  もう いちど。", true)
		input_text = ""
		keypad.answer_lbl.text = " "


# =========================================================
# さわり方(act)ごとの ことば
# =========================================================

func _act_lead() -> String:
	match String(unit["act"]):
		"tear":
			if String(unit["id"]) == "k7":
				return "外がわの かどを つまんで、下の わくの ○ へ はこぼう。3 つ ぜんぶ。まん中の へこんだ かどと くらべて。"
			return "三角形の かどを ゆびで つまんで、下の わくの ○ へ はこぼう。3 つ ぜんぶ。"
		"slide":
			return "金色の かどを ゆびで つまんで、下の 線の 交わるところまで ずらそう。"
		"fold":
			if String(unit["id"]) == "k8":
				return "紙テープを ななめの 点線で 折り返そう。右はしを ゆびで つまんで、○ まで はこぶよ。"
			return "点線で 折ってみよう。金色の ところを ゆびで つまんで、反対がわへ たおす。"
		"diag":
			return "金色の 点から、白い 点まで ゆびで なぞって 線を 引こう。三角形 1 つで 180°。いくつに 分かれるかな?"
		"clock":
			match mini(tries, 2):
				0:
					return "数字 1 つ分(1 じかん)は 30°。金色の 針を つまんで、12 から ぐるっと 1 しゅう まわそう。30° が 何 こ分かな?"
				1:
					return "こんどは 半分だけ。針が まっすぐに なる ところまで。30° が 何 こ分?"
				_:
					return "さいごは 直角(かどが 四角い ところ)まで。30° が 何 こ分?"
		"grid":
			return "金色の 点を つまんで、うすい 形に あわせよう。ますを 数えてみて。"
		"cut":
			return "金色の ところを つまんで、反対がわへ 運ぼう。"
		"roll":
			return "円を 右へ ころがそう。1 まわりで さしわたし 何こ分 進むかな?"
		"shift":
			return "金色の 点を つまんで、左右に 動かしてみよう。"
		"stack":
			return "はこの 中を タップして、さいころを つもう。"
		"open":
			return "まん中を ゆびで つまんで、右へ ゆっくり ひらこう。"
		"pour":
			return "右の 器の はばを 変えてみよう。水の 深さは どうなる?"
		_:
			return "太陽を 上下に 動かして、くいと 木の 影を くらべよう。"


func _act_after() -> String:
	match String(unit["act"]):
		"tear":
			if String(unit["id"]) == "k7":
				return "3 つ あわせると へこんだ かどと 同じだった。形を かえても?"
			return "3 つ ならべたら まっすぐ。形を かえても 同じかな?"
		"slide":
			return "ずらしても かどの 大きさは 同じだった。ほかの ななめでも 同じ?"
		"fold":
			if String(unit["id"]) == "k8":
				return "折り線を はさんで、同じ かどが 2 つ できた。ななめの むきを 変えても 同じかな?"
			return "ぴったり 重なった。ほかの 形でも そうかな?"
		"diag":
			return "三角形 %d こ × 180° ＝ %d° に 分けられた。角の 数が ちがっても 同じ やり方かな?" % [
				int(st.get("tri", 3)), int(st.get("tri", 3)) * 180]
		"clock":
			if tries == 1:
				return "30° が 12 こで 1 しゅう 360° だった。半分なら 何 こ分?"
			return "30° が 6 こで まっすぐ 180°。では 直角は?"
		"grid":
			return "ますの 数は たて × よこ に なっていた。ほかの 大きさでも 同じかな?"
		"cut":
			return "切って 運んでも 広さは 変わらない。ほかの 形でも 同じ?"
		"roll":
			return "さしわたし 3 こ分と ちょっとだった。大きさを 変えても 同じかな?"
		"shift":
			return "動かしても 数は 変わらなかった。ほかの 場所でも?"
		"stack":
			return "たて × よこ × 高さ の 数だけ 入った。ほかの はこでも 同じ?"
		"open":
			return "ひらいても、面の 数は 変わらない。"
		"pour":
			return "はばを 変えると 深さが 変わる。でも かけ算は 同じ。"
		_:
			return "太陽が 動いても、2 つの わり算は 同じ だった。"


func _act_cheer() -> String:
	match String(unit["act"]):
		"tear":
			if String(unit["id"]) == "k7":
				return "へこんだ かどと 同じ！ %d°" % roundi(float(st.get("dent", 0.0)))
			return "ぴったり まっすぐ！ 180°"
		"slide":
			return "ぴったり 重なった！"
		"fold":
			if String(unit["id"]) == "k8":
				return "同じ かどが 2 つ！ %d° と %d°" % [
					roundi(float(st.get("angle", 45.0))), roundi(float(st.get("angle", 45.0)))]
			return "ぴったり 重なった！"
		"diag":
			return "三角形 %d こ × 180° ＝ %d°" % [
				int(st.get("tri", 3)), int(st.get("tri", 3)) * 180]
		"clock":
			match int(float(st.get("goal", 360.0))):
				360:
					return "30° × 12 ＝ 360°(1 しゅう)"
				180:
					return "30° × 6 ＝ 180°(まっすぐ)"
				_:
					return "30° × 3 ＝ 90°(直角)"
		"grid":
			return "%d × %d ＝ %d ます" % [int(st.get("h", 1)), int(st.get("w", 1)),
				int(st.get("w", 1)) * int(st.get("h", 1))]
		"cut":
			return "広さは そのまま！"
		"roll":
			return "1 まわり ＝ さしわたし 3.14 こ分"
		"shift":
			return "ぴったり 同じ！"
		"stack":
			return "%d × %d × %d ＝ %d こ" % [int(st.get("bh", 1)), int(st.get("bd", 1)),
				int(st.get("bw", 1)), int(st.get("bw", 1)) * int(st.get("bd", 1)) * int(st.get("bh", 1))]
		"open":
			return "ひらいた！"
		"pour":
			return "かけ算は いつも 24"
		_:
			return "どちらも 同じ わり算！"


# =========================================================
# さわる図をつくる
# =========================================================

func _reset_act() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	st = {}
	dragging = -1
	cheer = 0.0
	match String(unit["act"]):
		"tear":
			var b := rng.randf_range(40.0, 80.0)
			var c := rng.randf_range(40.0, 80.0)
			while 180.0 - b - c < 32.0 or 180.0 - b - c > 100.0:
				b = rng.randf_range(40.0, 80.0)
				c = rng.randf_range(40.0, 80.0)
			var a := 180.0 - b - c
			var side := 11.0
			var pb := Vector2(-side * 0.5, -3.0)
			var pc := Vector2(side * 0.5, -3.0)
			var ab := side * sin(deg_to_rad(c)) / sin(deg_to_rad(a))
			var pa := pb + Vector2(cos(deg_to_rad(b)), sin(deg_to_rad(b))) * ab
			if String(unit["id"]) == "k7":
				# 矢じりの形。外がわの 3 つの かどを ちぎると、へこんだ かどに なる
				var da := Vector2(0.0, 7.5)
				var db := Vector2(-6.0, -3.0)
				var dc := Vector2(6.0, -3.0)
				var dp := Vector2(0.0, 1.2 + rng.randf_range(-0.5, 1.2))
				var ang_a := rad_to_deg(absf((db - da).angle_to(dc - da)))
				var ang_b := rad_to_deg(absf((da - db).angle_to(dp - db)))
				var ang_c := rad_to_deg(absf((da - dc).angle_to(dp - dc)))
				st = {"tri": [da, db, dc], "deg": [ang_a, ang_b, ang_c],
					"placed": [false, false, false], "poly": [da, db, dp, dc],
					"dent": ang_a + ang_b + ang_c, "dent_at": dp}
			else:
				st = {"tri": [pa, pb, pc], "deg": [a, b, c], "placed": [false, false, false],
					"poly": [pa, pb, pc]}
		"slide":
			# 3 回で「同じ むき(同位角)」→「向かい側(対頂角)」→「ななめ 向かい(錯角)」
			# と 運ぶ 先を 変える。しるしの 問題は ななめ 向かいを 使うので、
			# そこまで 手で たしかめてから 進む
			var slope := rng.randf_range(28.0, 62.0)
			st = {"slope": slope, "at": Vector2.ZERO, "moved": false, "gap": 7.0,
				"step": mini(tries, 2)}
		"fold":
			if String(unit["id"]) == "k8":
				# 「折り返した かど」は 本編の 問題が 長方形の 紙テープの ななめ折り。
				# 二等辺三角形の 半分折り(k3)の 使い回しでは 問題と つながらないので、
				# 同じ「テープを ななめの 線で 折り返す」を そのまま さわれるようにする。
				# ななめの むきは 回ごとに 変える(45° は 本編の 問題と 同じ)
				st = {"angle": [45.0, 58.0, 36.0][mini(tries, 2)], "fold": 0.0, "tape": true}
			else:
				st = {"angle": rng.randf_range(35.0, 70.0), "fold": 0.0}
		"diag":
			var n: int = [4, 5, 6][mini(tries, 2)]
			st = {"n": n, "picked": [], "tri": n - 2}
		"grid":
			st = {"w": 2, "h": 2, "tw": rng.randi_range(3, 8), "th": rng.randi_range(2, 5)}
		"cut":
			st = {"moved": 0.0}
		"roll":
			st = {"turns": 0.0}
		"shift":
			st = {"pos": 0.0 if String(unit["id"]) == "k21" else 4.0, "from": 0.0}
		"stack":
			st = {"n": 0, "bw": rng.randi_range(2, 4), "bd": rng.randi_range(2, 3),
				"bh": rng.randi_range(2, 3)}
		"open":
			st = {"open": 0.0}
		"pour":
			st = {"w": 3.0, "from": 3.0}
		"shadow":
			st = {"sun": 45.0, "from": 45.0}
		"clock":
			# 1 しゅう → 半分(まっすぐ)→ 4 分の 1(直角)の 順に まわす
			st = {"deg": 0.0, "last": 0.0, "ticks": 0, "set": false,
				"goal": [360.0, 180.0, 90.0][mini(tries, 2)]}


# =========================================================
# さわる図を描く
# =========================================================

func _to_screen(p: Vector2) -> Vector2:
	# ちぎった かど(半径 74)のぶんも 入るように、少し小さめに置く
	var k := minf(map.size.x / 16.0, map.size.y / 26.0)
	var ox := map.size.x * 0.5
	var oy := map.size.y * 0.46
	if st.has("poly"):
		# 細長い 三角形は 決めうちの 倍率だと 図の上端が map の外に 出てしまい、
		# 外に出た かどは タッチが 届かず つかめない。図の 外わくに あわせて
		# 倍率と 置き場所を 直し、かならず map の 中に おさめる
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for q in st["poly"]:
			lo = lo.min(q)
			hi = hi.max(q)
		var top := 24.0
		# _release の「ならべた」判定(_line_y() - 170 より下)に かからない ところまで
		var bottom := _line_y() - 210.0
		var side := 30.0
		k = minf(k, (map.size.x - side * 2.0) / maxf(hi.x - lo.x, 0.001))
		k = minf(k, (bottom - top) / maxf(hi.y - lo.y, 0.001))
		oy = clampf(oy, top + hi.y * k, bottom + lo.y * k)
		ox = clampf(ox, side - lo.x * k, map.size.x - side - hi.x * k)
	return Vector2(ox + p.x * k, oy - p.y * k)


func _line_y() -> float:
	return map.size.y * 0.86


## ちぎった かどを ならべる 台。
## 「どこに 置けば いいのか 分からない」と 言われたので、当たり判定と ぴったり
## 同じ わくを 絵にも 出す(ここを 変えたら 置ける ところも 一緒に 変わる)
func _tear_zone() -> Rect2:
	var top := _line_y() - 170.0
	return Rect2(12.0, top, maxf(map.size.x - 24.0, 1.0), maxf(map.size.y - top - 6.0, 1.0))


## 図の 上に 数を 書く。ぬった 色や できた しるしの ○ と 重なっても 読めるよう、
## 暗い 下じきを 敷いてから 書く(まん中ぞろえ)
func _draw_tag(c: Control, at: Vector2, text: String, size: int, col: Color) -> void:
	var f := ThemeDB.fallback_font
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var lt := at + Vector2(-w * 0.5, float(size) * 0.36)
	c.draw_rect(Rect2(lt + Vector2(-6.0, -float(size) * 0.86),
		Vector2(w + 12.0, float(size) * 1.18)), Color(0.06, 0.10, 0.18, 0.72))
	c.draw_string(f, lt, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## 「ここへ はこぶ」の 矢じるし
func _draw_arrow(c: Control, from: Vector2, to: Vector2, col: Color) -> void:
	var d := to - from
	if d.length() < 40.0:
		return
	var u := d.normalized()
	c.draw_line(from, to - u * 20.0, col, 5.0)
	var w := Vector2(-u.y, u.x) * 13.0
	c.draw_colored_polygon(PackedVector2Array([to, to - u * 26.0 + w, to - u * 26.0 - w]), col)


## ちぎった かど(おうぎ形の紙きれ)
func _draw_piece(c: Control, at: Vector2, base_dir: float, size_deg: float,
		col: Color, radius: float) -> void:
	var pts := PackedVector2Array()
	pts.append(at)
	var n := maxi(int(size_deg / 5.0), 5)
	for i in n + 1:
		var t := base_dir + deg_to_rad(size_deg) * float(i) / float(n)
		var r := radius * (1.0 + (0.06 if i % 2 == 0 else -0.05))
		pts.append(at + Vector2(cos(t), -sin(t)) * r)
	c.draw_colored_polygon(pts, col)
	c.draw_polyline(pts, Color(1, 1, 1, 0.75), 2.0)


static func _math_angle(v: Vector2) -> float:
	return Vector2(v.x, -v.y).angle()


static func _wrap_diff(a: float, b: float) -> float:
	var d := b - a
	while d > PI:
		d -= TAU
	while d < -PI:
		d += TAU
	return d


func _draw_map() -> void:
	var c := map
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(0.13, 0.18, 0.30))
	match String(unit["act"]):
		"tear":
			_draw_tear(c)
		"slide":
			_draw_slide(c)
		"fold":
			_draw_fold(c)
		"diag":
			_draw_diag(c)
		"clock":
			_draw_clock(c)
		"grid":
			_draw_grid(c)
		"cut":
			_draw_cut(c)
		"roll":
			_draw_roll(c)
		"shift":
			_draw_shift(c)
		"stack":
			_draw_stack(c)
		"open":
			_draw_open(c)
		"pour":
			_draw_pour(c)
		_:
			_draw_shadow(c)
	_draw_rounds(c)
	if bool(st.get("done", false)):
		_draw_ok(c)


## 3 回 たしかめる うちの 何回めか。
## 「もう いちど」が 出るのを『まちがえた』と 取られたので、進みぐあいを 絵で 出す
func _draw_rounds(c: Control) -> void:
	var f := ThemeDB.fallback_font
	var x := c.size.x - 22.0 - 3.0 * 30.0
	var lab := "たしかめ"
	var lw := f.get_string_size(lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	c.draw_string(f, Vector2(x - lw - 12.0, 31.0), lab, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, DIM)
	for i in 3:
		var at := Vector2(x + float(i) * 30.0 + 12.0, 24.0)
		if i < tries:
			c.draw_circle(at, 11.0, OK_COL)
		else:
			c.draw_arc(at, 11.0, 0.0, TAU, 20, Color(1, 1, 1, 0.30), 2.5)


## できた しるしの ○。
## 前は ことばだけで、ちゃんと 置けたのか 分からないと 言われた。
## 大きな ○ を ぽんと 出して、合っていた ことを ひと目で 見せる
func _draw_ok(c: Control) -> void:
	var mid := Vector2(c.size.x * 0.5, c.size.y * 0.44)
	var r := minf(c.size.x, c.size.y) * 0.29
	# 出た しゅんかんだけ ぽんと 大きくなる(そのあとは 出したまま のこす)
	var t := clampf(1.0 - cheer, 0.0, 1.0)
	var pop := 1.0 if t >= 0.35 else 0.55 + t / 0.35 * 0.45
	c.draw_arc(mid, r * pop * 1.12, 0.0, TAU, 64, Color(OK_COL.r, OK_COL.g, OK_COL.b,
		0.16 + cheer * 0.30), 22.0)
	c.draw_arc(mid, r * pop, 0.0, TAU, 64, Color(OK_COL.r, OK_COL.g, OK_COL.b, 0.95), 12.0)
	# ことばは ○ の 上に。図と 重なっても 読めるように 下じきを 敷く
	var f := ThemeDB.fallback_font
	var s := "せいかい！" if tries < 3 else "3 回とも せいかい！"
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 32).x
	var at := mid + Vector2(-w * 0.5, -r * pop - 20.0)
	c.draw_rect(Rect2(at + Vector2(-14.0, -34.0), Vector2(w + 28.0, 46.0)),
		Color(0.06, 0.10, 0.18, 0.80))
	c.draw_string(f, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, OK_COL)


func _draw_tear(c: Control) -> void:
	var tri: Array = st["tri"]
	var placed: Array = st["placed"]
	var deg: Array = st["deg"]
	var poly: Array = st.get("poly", tri)
	var shape := PackedVector2Array()
	for p in poly:
		shape.append(_to_screen(p))
	var center := Vector2.ZERO
	for q in shape:
		center += q
	center /= float(shape.size())
	c.draw_colored_polygon(shape, Color(0.40, 0.60, 0.95, 0.30))
	c.draw_polyline(shape + PackedVector2Array([shape[0]]), INK, 4.0)
	if st.has("dent_at"):
		# へこんだ かども 見せておく(ちぎった 3 つと くらべるため)
		var dp := _to_screen(st["dent_at"])
		c.draw_arc(dp, 46.0, 0.0, TAU, 24, Color(1, 1, 1, 0.18), 2.0)
		c.draw_string(ThemeDB.fallback_font, dp + Vector2(-26.0, -18.0),
			"%d°" % roundi(float(st["dent"])), HORIZONTAL_ALIGNMENT_LEFT, -1, 26, SKY)
	var sp := PackedVector2Array()
	for p in tri:
		sp.append(_to_screen(p))
	for i in 3:
		if bool(placed[i]) or i == dragging:
			continue
		var at: Vector2 = sp[i]
		var d1 := _math_angle(sp[(i + 1) % 3] - at)
		var d2 := _math_angle(sp[(i + 2) % 3] - at)
		if st.has("dent_at") and i > 0:
			# 矢じりのときは、外の かどは A と へこみ P にはさまれている
			d2 = _math_angle(_to_screen(st["dent_at"]) - at)
			d1 = _math_angle(sp[0] - at)
		var start: float = d1
		if _wrap_diff(d1, d2) < 0.0:
			start = d2
		var mid_dir := start + deg_to_rad(float(deg[i])) * 0.5
		if absf(_wrap_diff(mid_dir, _math_angle(center - at))) > PI * 0.5:
			start = start + deg_to_rad(float(deg[i])) - deg_to_rad(360.0)
		_draw_piece(c, at, start, float(deg[i]), PIECE_COL[i], 74.0)
	var ly := _line_y()
	var origin := Vector2(c.size.x * 0.5 - 130.0, ly)
	var zone := _tear_zone()
	var n_placed := 0
	for i in 3:
		if bool(placed[i]):
			n_placed += 1
	# ならべる 台(ここに 置けば いい)。ゆびが 台に 入ったら 色が 濃くなる
	var hot := false
	if dragging >= 0:
		var finger: Vector2 = st.get("drag_pos", Vector2.ZERO)
		hot = finger.y > zone.position.y
	c.draw_rect(zone, Color(1.0, 0.85, 0.35, 0.20 if hot else 0.08))
	c.draw_rect(zone, Color(1.0, 0.88, 0.45, 0.95 if hot else 0.45), false, 3.0)
	var lab := "ここに ならべる"
	if n_placed >= 3:
		lab = "そろった！"
	elif n_placed > 0:
		lab = "つぎも ここへ(あと %d こ)" % (3 - n_placed)
	c.draw_string(ThemeDB.fallback_font, zone.position + Vector2(16.0, 36.0), lab,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 28, GOLD)
	c.draw_line(Vector2(20, ly), Vector2(c.size.x - 20, ly), Color(1, 1, 1, 0.85), 5.0)
	var base := 0.0
	for i in 3:
		if not bool(placed[i]):
			continue
		_draw_piece(c, origin, deg_to_rad(base), float(deg[i]), PIECE_COL[i], 120.0)
		base += float(deg[i])
	# つぎの かどが 入る ところを うすい 形で 見せる。台の どこへ 置くのか、
	# 「かどの とがった ところを ○ に あわせる」まで 分かるようにする
	if n_placed < 3:
		var nxt := -1
		for i in 3:
			if not bool(placed[i]) and i != dragging:
				nxt = i
				break
		if nxt < 0:
			nxt = dragging
		if nxt >= 0:
			var ghost: Color = PIECE_COL[nxt]
			ghost.a = 0.50 if hot else 0.34
			_draw_piece(c, origin, deg_to_rad(base), float(deg[nxt]), ghost, 120.0)
		if dragging < 0 and nxt >= 0 and n_placed == 0:
			# はじめの 1 こだけ、どの かどを どこへ 運ぶか 矢じるしで 見せる
			# (2 こめからは うすい 形と ○ で 分かる。線が ごちゃつかない ように)
			var from: Vector2 = sp[nxt]
			var u := (origin - from).normalized()
			_draw_arrow(c, from + u * 92.0, origin - u * 40.0, Color(1, 0.85, 0.4, 0.55))
		var puls := 1.0 + sin(float(Time.get_ticks_msec()) * 0.005) * 0.12
		c.draw_arc(origin, 26.0 * puls, 0.0, TAU, 26, Color(1, 0.85, 0.4, 0.95), 3.0)
		c.draw_circle(origin, 7.0, GOLD)
	elif not st.has("dent_at"):
		# 3 つで まっすぐ に なった ことを、線と 数で 見せる
		c.draw_line(origin - Vector2(126.0, 0), origin + Vector2(126.0, 0),
			Color(1.0, 0.95, 0.5, 0.95), 7.0)
		c.draw_string(ThemeDB.fallback_font, origin + Vector2(-40.0, 42.0), "180°",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 30, GOLD)
	if dragging >= 0:
		_draw_piece(c, st["drag_pos"], deg_to_rad(90.0 - float(deg[dragging]) * 0.5),
			float(deg[dragging]), PIECE_COL[dragging], 88.0)
	if cheer > 0.0:
		c.draw_arc(origin, 120.0 + (1.0 - cheer) * 50.0, PI, TAU, 40,
			Color(1.0, 0.95, 0.5, cheer), 6.0)


## 平行な 2 本の線と、ななめの線。金色の かどを もう一方の交点へ運ぶ。
## 画面の座標だけで組み立てる(y は下向き)。前は上下の向きを取りちがえて、
## ななめの線が 交点を 通らずに 浮いていた
func _slide_points() -> Array:
	var y_top := map.size.y * 0.30
	var y_bottom := map.size.y * 0.64
	# ゆるい かたむきだと 左端(90)から 引いても 下の交点が 右へ はみ出す。
	# 画面の はばに 入る かたむきまで 立ててから 使う
	var slope := maxf(float(st["slope"]),
		rad_to_deg(atan((y_bottom - y_top) / maxf(map.size.x - 220.0, 1.0))))
	var dir := Vector2(cos(deg_to_rad(slope)), sin(deg_to_rad(slope)))
	# 下の交点が 右へ はみ出さない ところから 引く
	var dx := (y_bottom - y_top) / maxf(tan(deg_to_rad(slope)), 0.05)
	var p_top := Vector2(clampf(map.size.x - 130.0 - dx, 90.0, map.size.x * 0.34), y_top)
	var p_bottom := p_top + dir * ((y_bottom - y_top) / maxf(dir.y, 0.05))
	return [p_top, p_bottom, dir, y_top, y_bottom, slope]


## 何回めかで 運ぶ 先が 変わる。[運ぶ先, かどを 置く 点, 向かい側か]
func _slide_target() -> Array:
	var pts := _slide_points()
	var p_top: Vector2 = pts[0]
	var p_bottom: Vector2 = pts[1]
	var slope: float = pts[5]
	# かどの まん中が むいている 向き(画面は y が 下むき)
	var bis := Vector2(cos(deg_to_rad(slope * 0.5)), sin(deg_to_rad(slope * 0.5)))
	match int(st.get("step", 0)):
		0:
			return [p_bottom, p_bottom, false]
		1:
			return [p_top - bis * 104.0, p_top, true]
		_:
			return [p_bottom - bis * 104.0, p_bottom, true]


func _draw_slide(c: Control) -> void:
	var pts := _slide_points()
	var p_top: Vector2 = pts[0]
	var p_bottom: Vector2 = pts[1]
	var dir: Vector2 = pts[2]
	var y_top: float = pts[3]
	var y_bottom: float = pts[4]
	# 平行な 2 本
	c.draw_line(Vector2(20, y_top), Vector2(c.size.x - 20, y_top), INK, 4.0)
	c.draw_line(Vector2(20, y_bottom), Vector2(c.size.x - 20, y_bottom), INK, 4.0)
	# ななめの線(2 本を つらぬく)
	c.draw_line(p_top - dir * 140.0, p_bottom + dir * 140.0, Color(1, 0.85, 0.4, 0.85), 4.0)
	# 交わる ところ
	c.draw_circle(p_top, 10.0, Color(0.85, 0.9, 1.0))
	c.draw_circle(p_bottom, 10.0, Color(0.85, 0.9, 1.0))
	var tg := _slide_target()
	var goal: Vector2 = tg[0]
	var vertex: Vector2 = tg[1]
	var flip: bool = tg[2]
	var slope: float = pts[5]
	var base := deg_to_rad(180.0 - slope) if flip else deg_to_rad(-slope)
	if not bool(st["moved"]):
		# 運ぶ 先の 目じるし(ここへ もっていく)
		var puls := 1.0 + sin(float(Time.get_ticks_msec()) * 0.005) * 0.12
		c.draw_arc(goal, 30.0 * puls, 0.0, TAU, 26, Color(1, 0.85, 0.4, 0.85), 3.0)
		c.draw_circle(goal, 6.0, GOLD)
	# 運ぶ かど
	var here: Vector2 = vertex if bool(st["moved"]) else p_top
	if dragging >= 0:
		here = st["drag_pos"]
	var dir_now := base if bool(st["moved"]) else deg_to_rad(-slope)
	_draw_piece(c, here, dir_now, slope, PIECE_COL[0], 82.0)
	if bool(st["moved"]):
		# くらべる ため、はじめの かども うすく のこす
		_draw_piece(c, p_top, deg_to_rad(-slope), slope, Color(1.0, 0.78, 0.35, 0.35), 82.0)
	c.draw_string(ThemeDB.fallback_font, Vector2(24, c.size.y - 18), _slide_note(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, GOLD if bool(st["moved"]) else DIM)


## 図の 下に 出す 一言
func _slide_note() -> String:
	var done := bool(st["moved"])
	match int(st.get("step", 0)):
		0:
			return "下でも 同じ 大きさ" if done else "金色の かどを 下の ○ まで はこぼう"
		1:
			return "向かい側の かども 同じ 大きさ" if done 				else "こんどは 同じ 交わる ところの 向かい側(○)へ"
		_:
			return "ななめ 向かいでも 同じ 大きさ" if done 				else "下の 交わる ところの 向かい側(○)へ"


## 二等辺三角形を まん中で 折る
## 「折り返した かど」(k8)の 紙テープ。図の 中の 長さ(y は 上むき)
const TAPE_HW := 6.0     # よこ半分
const TAPE_HH := 2.0     # たて半分
const TAPE_PX := -2.0    # 折り線が 下の辺と 交わる ところ


## 折り線 PQ。P は 下の辺、Q は 上の辺
func _tape_p() -> Vector2:
	return Vector2(TAPE_PX, -TAPE_HH)


func _tape_dir() -> Vector2:
	var a := deg_to_rad(float(st["angle"]))
	return Vector2(cos(a), sin(a))


func _tape_q() -> Vector2:
	var d := _tape_dir()
	return _tape_p() + d * (TAPE_HH * 2.0 / maxf(d.y, 0.001))


## つまむ ところ(折り返す 側の 右はしの まん中)
func _tape_handle() -> Vector2:
	return Vector2(TAPE_HW, 0.0)


## PQ より 右(折り返す ぶぶん)
func _tape_flap() -> Array:
	return [_tape_p(), Vector2(TAPE_HW, -TAPE_HH), Vector2(TAPE_HW, TAPE_HH), _tape_q()]


## 折り線 PQ を 軸に くるりと 回したときの 場所。
## 真上から 見ると 線からの きょりは perp × cos で、とちゅうは 0 に なる ――
## それだけだと 紙が 消えて 見えるので、立った ぶんを 上へ 持ち上げて 見せる。
## t=0 と t=1 では 持ち上げが 0 に なるので、終わりは きっちり 鏡うつし
func _tape_fold_pt(v: Vector2, t: float) -> Vector2:
	var p := _tape_p()
	var d := _tape_dir()
	var n := Vector2(-d.y, d.x)
	var r := v - p
	var perp := r.dot(n)
	return p + d * r.dot(d) + n * (perp * cos(PI * t)) \
		+ Vector2(0.0, absf(perp) * sin(PI * t) * 0.5)


## 折り返した ところまで ぜんぶ 入るように、この 図だけの 倍率で 置く。
## 共通の _to_screen は たて 26 ますぶんを 見こむので、テープだと 小さすぎた
func _tape_box() -> Array:
	var pts: Array = [Vector2(-TAPE_HW, -TAPE_HH), Vector2(TAPE_HW, -TAPE_HH),
		Vector2(TAPE_HW, TAPE_HH), Vector2(-TAPE_HW, TAPE_HH)]
	for q in _tape_flap():
		pts.append(_tape_fold_pt(q, 1.0))
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for q in pts:
		lo = lo.min(q)
		hi = hi.max(q)
	var pad := 46.0
	var k := minf((map.size.x - pad * 2.0) / maxf(hi.x - lo.x, 0.001),
		(map.size.y - pad * 2.0 - 46.0) / maxf(hi.y - lo.y, 0.001))
	return [k, (lo + hi) * 0.5]


func _tape_screen(v: Vector2) -> Vector2:
	var box := _tape_box()
	var k: float = box[0]
	var mid: Vector2 = box[1]
	return Vector2(map.size.x * 0.5 + (v.x - mid.x) * k,
		map.size.y * 0.48 - (v.y - mid.y) * k)


## 長方形の 紙テープを ななめの 線で 折り返す。
## 折ると、折り線を はさんで 同じ 大きさの かどが もう 1 つ できる ――
## 本編の 問題(角 x)が そのまま 手で たしかめられる
func _draw_fold_tape(c: Control) -> void:
	var t: float = st["fold"]
	var ang: float = st["angle"]
	var f := ThemeDB.fallback_font
	var k: float = _tape_box()[0]
	var p := _tape_p()
	var sp := _tape_screen(p)
	# テープ ぜんたいの わく(折っても もとの かたちが 分かるように のこす)
	var rect := PackedVector2Array()
	for v in [Vector2(-TAPE_HW, -TAPE_HH), Vector2(TAPE_HW, -TAPE_HH),
			Vector2(TAPE_HW, TAPE_HH), Vector2(-TAPE_HW, TAPE_HH)]:
		rect.append(_tape_screen(v))
	c.draw_polyline(rect + PackedVector2Array([rect[0]]), Color(1, 1, 1, 0.30), 2.0)
	# 折らない ぶぶん
	var left := PackedVector2Array()
	for v in [p, _tape_q(), Vector2(-TAPE_HW, TAPE_HH), Vector2(-TAPE_HW, -TAPE_HH)]:
		left.append(_tape_screen(v))
	c.draw_colored_polygon(left, Color(0.40, 0.60, 0.95, 0.30))
	c.draw_polyline(left + PackedVector2Array([left[0]]), INK, 4.0)
	# 折り返す ぶぶん
	var flap := PackedVector2Array()
	for v in _tape_flap():
		flap.append(_tape_screen(_tape_fold_pt(v, t)))
	c.draw_colored_polygon(flap, Color(1.0, 0.78, 0.35, 0.55))
	c.draw_polyline(flap + PackedVector2Array([flap[0]]), GOLD, 3.0)
	# 折り線。どこで 折るのかが ひと目で 分かるよう、テープの 外まで のばす
	var ext := _tape_dir() * 0.9
	var la := _tape_screen(p - ext)
	var lb := _tape_screen(_tape_q() + ext)
	if t > 0.95:
		c.draw_line(la, lb, GOLD, 5.0)
	else:
		c.draw_dashed_line(la, lb, Color(1, 1, 1, 0.9), 4.0, 14.0)
	# 折る前の かど(下の辺と 折り線の あいだ)。本編の 問題で 分かっている 角
	c.draw_arc(sp, 2.2 * k, -deg_to_rad(ang), 0.0, 26, SKY, 4.0)
	_draw_tag(c, sp + _dir_px(ang * 0.5, 3.2 * k), "%d°" % roundi(ang), 24, SKY)
	if t > 0.95:
		# 折ったら、折り線の 向こう側に 同じ かどが もう 1 つ できる
		c.draw_arc(sp, 3.6 * k, -deg_to_rad(ang * 2.0), -deg_to_rad(ang), 26, GOLD, 4.0)
		_draw_tag(c, sp + _dir_px(ang * 1.5, 4.6 * k), "%d°" % roundi(ang), 24, GOLD)
	else:
		# 運ぶ 先(ここまで 持ってくると ぴったり 折れる)
		var goal := _tape_screen(_tape_fold_pt(_tape_handle(), 1.0))
		var here := _tape_screen(_tape_fold_pt(_tape_handle(), t))
		if dragging < 0:
			# どこを つまんで どこへ 運ぶのか、はじめに 矢じるしで 見せる
			var u := (goal - here).normalized()
			_draw_arrow(c, here + u * 26.0, goal - u * 40.0, Color(1, 0.85, 0.4, 0.55))
		var puls := 1.0 + sin(float(Time.get_ticks_msec()) * 0.005) * 0.12
		c.draw_arc(goal, 30.0 * puls, 0.0, TAU, 26, Color(1, 0.85, 0.4, 0.85), 3.0)
		c.draw_circle(goal, 6.0, GOLD)
	# つまむ ところ
	c.draw_circle(_tape_screen(_tape_fold_pt(_tape_handle(), t)), 13.0, GOLD)
	c.draw_string(f, Vector2(24, c.size.y - 20),
		"同じ かどが もう 1 つ できた" if t > 0.95 else "右はしを つまんで ○ まで 折り返そう",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, GOLD if t > 0.95 else DIM)


## 図の 角度(y は 上むき)を、画面の 向き(y は 下むき)の ずれに 直す
func _dir_px(deg: float, r: float) -> Vector2:
	var a := deg_to_rad(deg)
	return Vector2(cos(a), -sin(a)) * r


func _draw_fold(c: Control) -> void:
	if bool(st.get("tape", false)):
		_draw_fold_tape(c)
		return
	var a: float = st["angle"]
	var t: float = st["fold"]
	var top := _to_screen(Vector2(0, 6.5))
	var bl := _to_screen(Vector2(-5.0, -3.5))
	var br := _to_screen(Vector2(5.0, -3.5))
	c.draw_colored_polygon(PackedVector2Array([top, bl, br]), Color(0.40, 0.60, 0.95, 0.28))
	c.draw_polyline(PackedVector2Array([top, bl, br, top]), INK, 4.0)
	var mid := (bl + br) * 0.5
	c.draw_dashed_line(top, mid, Color(1, 1, 1, 0.6), 2.5, 10.0)
	# 右半分を 左へ たおす(t = 0..1)
	var moved_br := br.lerp(bl, t)
	var moved_mid := mid.lerp(mid, t)
	c.draw_colored_polygon(PackedVector2Array([top, moved_mid, moved_br]),
		Color(1.0, 0.78, 0.35, 0.6))
	c.draw_polyline(PackedVector2Array([top, moved_mid, moved_br, top]), GOLD, 3.0)
	c.draw_string(ThemeDB.fallback_font, Vector2(24, c.size.y - 20),
		"右がわを つまんで、左へ たおそう" if t < 0.95 else "ぴったり 重なった",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, DIM if t < 0.95 else GOLD)


## 多角形を 対角線で 三角形に 分ける
## 対角線で 分けた 三角形は、1 つが かならず 180°。
## 分けた 三角形を 1 つずつ 色分けして まん中に「180°」と 書き、下に
## 「三角形 3 こ × 180° ＝ 540°」と 式のまま 出す ―― 数えた ものが
## そのまま 式に なる ところまで、図の 中で 分かるようにする
func _draw_diag(c: Control) -> void:
	var n: int = st["n"]
	var picked: Array = st["picked"]
	var pts: Array = _diag_points()
	var f := ThemeDB.fallback_font
	var poly := PackedVector2Array()
	for p in pts:
		poly.append(p)
	c.draw_colored_polygon(poly, Color(0.40, 0.60, 0.95, 0.28))
	var made := _diag_triangles()
	for j in made.size():
		var i: int = made[j]
		var col: Color = PIECE_COL[j % PIECE_COL.size()]
		col.a = 0.45
		c.draw_colored_polygon(PackedVector2Array([pts[0], pts[i], pts[i + 1]]), col)
	for i in n:
		c.draw_line(pts[i], pts[(i + 1) % n], INK, 4.0)
	for i in picked:
		c.draw_line(pts[0], pts[int(i)], GOLD, 3.5)
	# できた 三角形の まん中に「180°」。三角形 1 つが 180° だと ここで 見せる
	for j in made.size():
		var i: int = made[j]
		var mid: Vector2 = (pts[0] + pts[i] + pts[i + 1]) / 3.0
		_draw_tag(c, mid, "180°", 26, Color(1.0, 0.97, 0.85))
	# ゆびで なぞって いる とちゅうの 線
	if dragging >= 0 and st.has("drag_pos"):
		c.draw_line(pts[0], st["drag_pos"], Color(1, 0.85, 0.4, 0.7), 3.0)
	var puls := 1.0 + sin(float(Time.get_ticks_msec()) * 0.005) * 0.15
	for i in n:
		if i == 0:
			c.draw_circle(pts[i], 15.0 * puls, GOLD)
		elif i >= 2 and i <= n - 2 and not picked.has(i):
			# まだ つないでいない 点は、大きめの 輪で さそう
			c.draw_arc(pts[i], 22.0, 0.0, TAU, 24, Color(1, 1, 1, 0.35), 2.0)
			c.draw_circle(pts[i], 11.0, Color(0.85, 0.9, 1.0))
		else:
			c.draw_circle(pts[i], 11.0, Color(0.85, 0.9, 1.0))
	var k := made.size()
	var sum_msg := "三角形 1 つで 180°"
	if k > 0:
		sum_msg = "三角形 %d こ × 180° ＝ %d°" % [k, k * 180]
	c.draw_string(f, Vector2(24, c.size.y - 58), sum_msg,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 30, GOLD if k >= n - 2 else Color(0.85, 0.9, 1.0))
	c.draw_string(f, Vector2(24, c.size.y - 20),
		"金色の 点から 白い 点まで なぞろう(タップでも いい)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, DIM)


## いま 分かれている 三角形。(0, i, i+1) の i を ならべて かえす。
## 0-1 と 0-(n-1) は もとから ある 辺なので、その 2 つは 引かなくても いい
func _diag_triangles() -> Array:
	var n: int = st["n"]
	var picked: Array = st["picked"]
	var made: Array = []
	for i in range(1, n - 1):
		if not (i == 1 or picked.has(i)):
			continue
		if not (i + 1 == n - 1 or picked.has(i + 1)):
			continue
		made.append(i)
	return made


## 時計の 文字ばん。針を まわした ぶんだけ 金色に ぬられ、
## 数字 1 つ分ごとに 目もりで 区切れる ―― 「何 こ分 まわしたか」が 目で 数えられる。
##
## 3 回で 1 しゅう(360°)→ 半分(まっすぐ 180°)→ 4 分の 1(直角 90°)と まわし、
## どれも 数字 1 つ分が 30° に なることを じぶんで 確かめる。
func _clock_center() -> Vector2:
	return Vector2(map.size.x * 0.5, map.size.y * 0.52)


func _clock_radius() -> float:
	return minf(map.size.x * 0.40, map.size.y * 0.36)


func _draw_clock(c: Control) -> void:
	var f := ThemeDB.fallback_font
	var center := _clock_center()
	var r := _clock_radius()
	var deg := float(st["deg"])
	var goal := float(st["goal"])
	var done := bool(st["set"])
	# まわした ぶんを、数字 1 つ分ずつ 色を かえて ぬる(数えられるように)
	var blocks := int(ceil(deg / 30.0))
	for k in blocks:
		var a0 := deg_to_rad(-90.0 + 30.0 * float(k))
		var a1 := deg_to_rad(-90.0 + minf(30.0 * float(k + 1), deg))
		if a1 <= a0:
			continue
		var fan := PackedVector2Array([center])
		var steps := maxi(int(rad_to_deg(a1 - a0) / 3.0), 2)
		for i in steps + 1:
			var t := a0 + (a1 - a0) * float(i) / float(steps)
			fan.append(center + Vector2(cos(t), sin(t)) * (r - 6.0))
		c.draw_colored_polygon(fan, Color(1.0, 0.78, 0.35, 0.34 if k % 2 == 0 else 0.20))
		c.draw_line(center, center + Vector2(cos(a0), sin(a0)) * (r - 6.0),
			Color(1, 0.9, 0.6, 0.55), 2.0)
		# 1 こ分は かならず 30°。ぬった ところ ぜんぶに 書いて、
		# 「数字 1 つ分 = 1 じかん = 30°」を 目で 分かるようにする。
		# 何こめかは 上の「N こ分」で 数えられる
		if 30.0 * float(k + 1) <= deg + 0.5:
			var mid := deg_to_rad(-90.0 + 30.0 * float(k) + 15.0)
			# できた しるしの ○(_draw_ok の 半径)より 内がわに 置く
			_draw_tag(c, center + Vector2(cos(mid), sin(mid)) * (r * 0.52), "30°", 22,
				Color(1, 0.97, 0.85))
	# 文字ばん
	c.draw_arc(center, r, 0.0, TAU, 60, INK, 4.0)
	for i in 12:
		var th := deg_to_rad(-90.0 + 30.0 * float(i))
		var d := Vector2(cos(th), sin(th))
		c.draw_line(center + d * (r - 14.0), center + d * r, Color(0.8, 0.86, 1.0), 3.0)
		c.draw_string(f, center + d * (r + 26.0) + Vector2(-10, 9),
			str(12 if i == 0 else i), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)
	# まだ まわしていない うちは、12 から 1 までの 1 こ分が 30° だと 見せておく
	# (まわしはじめれば、ぬった ところ ぜんぶに 30° が 出る)
	if deg < 30.0:
		var a0 := deg_to_rad(-90.0)
		var a1 := deg_to_rad(-60.0)
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		var fan := PackedVector2Array([center])
		for i in 11:
			var t := a0 + (a1 - a0) * float(i) / 10.0
			fan.append(center + Vector2(cos(t), sin(t)) * (r - 6.0))
		c.draw_colored_polygon(fan, Color(SKY.r, SKY.g, SKY.b, 0.18))
		c.draw_line(center, center + d0 * (r - 6.0), SKY, 3.0)
		c.draw_line(center, center + d1 * (r - 6.0), SKY, 3.0)
		c.draw_arc(center, r * 0.46, a0, a1, 14, SKY, 4.0)
		var md := Vector2(cos(deg_to_rad(-75.0)), sin(deg_to_rad(-75.0)))
		_draw_tag(c, center + md * (r * 0.70), "30°", 28, SKY)
		_draw_tag(c, center + md * (r * 0.90), "1 こ分", 24, Color(SKY.r, SKY.g, SKY.b, 0.9))
	# 目じるし(どこまで まわすか)
	if not done:
		var tg := deg_to_rad(-90.0 + goal)
		c.draw_dashed_line(center, center + Vector2(cos(tg), sin(tg)) * (r - 10.0),
			Color(0.55, 0.85, 1.0, 0.9), 3.0, 12.0)
	# 針
	var th_h := deg_to_rad(-90.0 + deg)
	c.draw_line(center, center + Vector2(cos(th_h), sin(th_h)) * (r - 16.0), GOLD, 8.0)
	c.draw_circle(center, 9.0, GOLD)
	# そろったら、知っている 形で 見せる
	if done:
		if int(goal) == 90:
			var q := 34.0
			c.draw_rect(Rect2(center + Vector2(0, -q), Vector2(q, q)), Color(0.55, 0.85, 1.0), false, 3.0)
		elif int(goal) == 180:
			c.draw_line(center + Vector2(-r, 0), center + Vector2(r, 0),
				Color(0.55, 0.85, 1.0), 4.0)
		else:
			c.draw_arc(center, r + 12.0, 0.0, TAU, 60, Color(0.55, 0.85, 1.0, 0.8), 4.0)
	# 何 こ分 まわしたかを 大きく
	var whole := int(floor(deg / 30.0 + 0.01))
	c.draw_string(f, Vector2(0, 52), "%d こ分" % whole,
		HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 44, GOLD if done else Color(0.85, 0.9, 1.0))
	# 数えた 1 こ分(30°)が、そのまま 式に なる ところまで 出す
	var sum_msg := "1 こ分 ＝ 30°"
	if whole > 0:
		sum_msg = "30° × %d こ ＝ %d°" % [whole, whole * 30]
	c.draw_string(f, Vector2(24, c.size.y - 58), sum_msg,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 30, GOLD if done else Color(0.85, 0.9, 1.0))
	c.draw_string(f, Vector2(24, c.size.y - 20), _clock_note(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, GOLD if done else DIM)


func _clock_note() -> String:
	if bool(st["set"]):
		match int(float(st["goal"])):
			360:
				return "1 しゅう ＝ 12 こ分。30° が 12 こで 360°"
			180:
				return "半分 ＝ 6 こ分。30° が 6 こで 180°"
			_:
				return "4 分の 1 ＝ 3 こ分。30° が 3 こで 90°"
	match int(float(st["goal"])):
		360:
			return "数字 1 つ分(1 じかん)が 30°。12 から ぐるっと 1 しゅう"
		180:
			return "1 こ分は 30°。半分(6)の 青い 点線まで まわそう"
		_:
			return "1 こ分は 30°。3 の 青い 点線まで まわそう"


## 針を まわす。ぐるっと 1 しゅうも できるように、
## 指の 角度の「差」を ためていく(0° を またいでも もどらない)
func _turn_clock(at: Vector2) -> void:
	var v := at - _clock_center()
	if v.length() < 24.0:
		return
	var now := rad_to_deg(atan2(v.x, -v.y))    # 12 時が 0、右まわりが プラス
	var last := float(st["last"])
	var d := now - last
	while d > 180.0:
		d -= 360.0
	while d < -180.0:
		d += 360.0
	st["last"] = now
	st["deg"] = clampf(float(st["deg"]) + d, 0.0, 366.0)
	var before := int(st["ticks"])
	var ticks := int(floor(float(st["deg"]) / 30.0 + 0.01))
	if ticks != before:
		st["ticks"] = ticks
		GameState.play_sfx("type")


# =========================================================
# 面積の さわり方
# =========================================================

## ますの 1 目もりを 画面の 何ドットに するか
func _cell() -> float:
	return minf(map.size.x / 13.0, map.size.y / 12.0)


func _grid_origin() -> Vector2:
	return Vector2(map.size.x * 0.5 - _cell() * 4.0, map.size.y * 0.62)


func _draw_grid_bg(c: Control, cols: int, rows: int) -> void:
	var s := _cell()
	var o := _grid_origin()
	for i in cols + 1:
		c.draw_line(o + Vector2(s * i, 0), o + Vector2(s * i, -s * rows),
			Color(1, 1, 1, 0.10), 1.5)
	for j in rows + 1:
		c.draw_line(o + Vector2(0, -s * j), o + Vector2(s * cols, -s * j),
			Color(1, 1, 1, 0.10), 1.5)


## ますに合わせて 四角を つくる(たて × よこ)
func _draw_grid(c: Control) -> void:
	var s := _cell()
	var o := _grid_origin()
	var w: int = st["w"]
	var h: int = st["h"]
	var tw: int = st["tw"]
	var th: int = st["th"]
	_draw_grid_bg(c, 9, 7)
	# めあての 形
	c.draw_rect(Rect2(o + Vector2(0, -s * th), Vector2(s * tw, s * th)),
		Color(1.0, 0.85, 0.3, 0.18))
	c.draw_rect(Rect2(o + Vector2(0, -s * th), Vector2(s * tw, s * th)),
		Color(1.0, 0.85, 0.3, 0.7), false, 3.0)
	# いまの 形
	var r := Rect2(o + Vector2(0, -s * h), Vector2(s * w, s * h))
	c.draw_rect(r, Color(0.40, 0.60, 0.95, 0.45))
	c.draw_rect(r, INK, false, 4.0)
	var uid := String(unit["id"])
	if uid == "k10":
		# 三角の 広さ: ななめに 分ける
		c.draw_line(o + Vector2(0, 0), o + Vector2(s * w, -s * h), GOLD, 4.0)
		c.draw_colored_polygon(PackedVector2Array([o, o + Vector2(s * w, 0),
			o + Vector2(s * w, -s * h)]), Color(1.0, 0.78, 0.35, 0.35))
	elif uid == "k15":
		# 四角の 中の 点から 四すみへ
		var p := o + Vector2(s * w * 0.42, -s * h * 0.6)
		for corner in [o, o + Vector2(s * w, 0), o + Vector2(s * w, -s * h), o + Vector2(0, -s * h)]:
			c.draw_line(p, corner, GOLD, 3.0)
		c.draw_colored_polygon(PackedVector2Array([o, o + Vector2(s * w, 0), p]),
			Color(0.55, 0.85, 1.0, 0.35))
		c.draw_colored_polygon(PackedVector2Array([o + Vector2(0, -s * h),
			o + Vector2(s * w, -s * h), p]), Color(0.55, 0.85, 1.0, 0.35))
	elif uid == "k16":
		# 底辺だけ のばす
		c.draw_colored_polygon(PackedVector2Array([o, o + Vector2(s * w, 0),
			o + Vector2(s * w * 0.35, -s * h)]), Color(1.0, 0.78, 0.35, 0.40))
	# つまむ ところ
	c.draw_circle(o + Vector2(s * w, -s * h), 16.0, GOLD)
	var font := ThemeDB.fallback_font
	c.draw_string(font, o + Vector2(s * w * 0.5 - 30.0, 34.0), "よこ %d" % w,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, INK)
	c.draw_string(font, o + Vector2(-96.0, -s * h * 0.5), "たて %d" % h,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, INK)
	c.draw_string(font, Vector2(24, map.size.y - 18),
		"金色の 点を つまんで、うすい 形に あわせよう(たて %d よこ %d)" % [th, tw],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 25, DIM)


## 切って 反対がわへ 運ぶ。運んだ あとに もとの形が 残らないよう、
## 「切ったあとの のこり」と「運ぶ かけら」を 別々に 持つ
func _cut_shapes() -> Array:
	var s := _cell()
	var o := _grid_origin()
	var uid := String(unit["id"])
	if uid == "k11":
		# かたむいた四角。左の三角を 切って 右へ
		var slant := s * 2.0
		var w := s * 5.0
		var h := s * 4.0
		var a := o + Vector2(slant, 0)
		var b := a + Vector2(w, 0)
		var t := o + Vector2(slant, -h)
		var d := o + Vector2(0, -h)
		return [PackedVector2Array([a, b, b + Vector2(0, -h), t]),
			PackedVector2Array([d, a, t]), Vector2(w, 0)]
	if uid == "k14":
		# L の字。下の 出っぱりを 切りはなす
		var w2 := s * 4.0
		var h2 := s * 5.0
		return [PackedVector2Array([o, o + Vector2(s * 3.0, 0), o + Vector2(s * 3.0, -h2),
				o + Vector2(0, -h2)]),
			PackedVector2Array([o + Vector2(s * 3.0, 0), o + Vector2(s * 3.0 + w2, 0),
				o + Vector2(s * 3.0 + w2, -s * 2.0), o + Vector2(s * 3.0, -s * 2.0)]),
			Vector2(s * 1.2, s * 1.6)]
	# 葉っぱ。右の おうぎ形を 左へ 重ねる
	var r := s * 5.0
	var corner := o
	var fan1 := PackedVector2Array([corner])
	for i in 13:
		var th := deg_to_rad(-90.0 * float(i) / 12.0)
		fan1.append(corner + Vector2(cos(th), sin(th)) * r)
	var corner2 := o + Vector2(r, -r)
	var fan2 := PackedVector2Array([corner2])
	for i in 13:
		var th2 := deg_to_rad(90.0 + 90.0 * float(i) / 12.0)
		fan2.append(corner2 + Vector2(cos(th2), sin(th2)) * r)
	return [fan1, fan2, Vector2(-s * 5.5, 0)]


func _draw_cut(c: Control) -> void:
	var s := _cell()
	var t: float = st["moved"]
	var parts := _cut_shapes()
	var rest: PackedVector2Array = parts[0]
	var piece: PackedVector2Array = parts[1]
	var shift: Vector2 = parts[2] * t
	_draw_grid_bg(c, 9, 7)
	if String(unit["id"]) == "k17":
		# 葉っぱは「重ねる」ので、動かす前の 位置に うすく 出しておく
		var ghost := PackedVector2Array()
		for p in piece:
			ghost.append(p + parts[2])
		c.draw_colored_polygon(ghost, Color(1, 1, 1, 0.06))
	c.draw_colored_polygon(rest, Color(0.40, 0.60, 0.95, 0.45))
	c.draw_polyline(rest + PackedVector2Array([rest[0]]), INK, 4.0)
	var moved := PackedVector2Array()
	for p in piece:
		moved.append(p + shift)
	c.draw_colored_polygon(moved, Color(1.0, 0.78, 0.35, 0.55))
	c.draw_polyline(moved + PackedVector2Array([moved[0]]), GOLD, 3.0)
	# つまむ ところ
	var grab := Vector2.ZERO
	for p in moved:
		grab += p
	grab /= float(moved.size())
	c.draw_circle(grab, 15.0, Color(1, 1, 1, 0.35))
	var done := t > 0.9
	var msg := "金色の ところを つまんで、反対がわへ 運ぼう"
	if String(unit["id"]) == "k14":
		msg = "金色の ところを つまんで、切りはなそう"
	elif String(unit["id"]) == "k17":
		msg = "金色の おうぎ形を 左へ 運んで、重ねよう"
	var done_msg := "ぴったり 四角に なった"
	if String(unit["id"]) == "k14":
		done_msg = "2 つの 四角に 分かれた"
	elif String(unit["id"]) == "k17":
		done_msg = "重なった ところが 葉っぱの 形"
	c.draw_string(ThemeDB.fallback_font, Vector2(24, map.size.y - 18),
		done_msg if done else msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, GOLD if done else DIM)


## 円を ころがす
func _draw_roll(c: Control) -> void:
	# 1 まわり(円周 = 2πr)ぶん ころがしても はみ出さない 大きさにする
	var r := minf((c.size.x - 90.0) / (TAU + 2.0), c.size.y * 0.16)
	var y := c.size.y * 0.52
	var start_x := 50.0 + r
	var turns: float = st["turns"]
	var x := start_x + TAU * r * turns
	c.draw_line(Vector2(30, y + r), Vector2(map.size.x - 30, y + r), INK, 4.0)
	# さしわたし 何こ分か の 目もり
	for i in 8:
		var mx := start_x + 2.0 * r * float(i)
		if mx > map.size.x - 30.0:
			break
		c.draw_line(Vector2(mx, y + r), Vector2(mx, y + r + 22.0), Color(0.8, 0.86, 1.0), 3.0)
		c.draw_string(ThemeDB.fallback_font, Vector2(mx - 8.0, y + r + 50.0), str(i),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24, DIM)
	c.draw_arc(Vector2(x, y), r, 0.0, TAU, 40, GOLD, 5.0)
	var mark := deg_to_rad(-90.0 + 360.0 * turns)
	c.draw_line(Vector2(x, y), Vector2(x, y) + Vector2(cos(mark), sin(mark)) * r, SKY, 4.0)
	c.draw_string(ThemeDB.fallback_font, Vector2(24, map.size.y - 18),
		"円を 右へ ころがそう(いま %.2f まわり ＝ さしわたし %.2f こ分)" % [
			turns, TAU * turns * 0.5], HORIZONTAL_ALIGNMENT_LEFT, -1, 25, DIM)


## 道を ずらす / 板を 動かす
func _draw_shift(c: Control) -> void:
	var s := _cell()
	var o := _grid_origin()
	var pos: float = st["pos"]
	_draw_grid_bg(c, 9, 7)
	if String(unit["id"]) == "k13":
		# 畑と 道
		var field := Rect2(o + Vector2(0, -s * 5.0), Vector2(s * 9.0, s * 5.0))
		c.draw_rect(field, Color(0.35, 0.62, 0.42, 0.45))
		c.draw_rect(field, INK, false, 4.0)
		var rx := o.x + s * pos
		c.draw_rect(Rect2(Vector2(rx, o.y - s * 5.0), Vector2(s, s * 5.0)),
			Color(0.60, 0.52, 0.40, 0.9))
		c.draw_circle(Vector2(rx + s * 0.5, o.y + 26.0), 16.0, GOLD)
		c.draw_string(ThemeDB.fallback_font, Vector2(24, map.size.y - 18),
			"道を 左右に 動かそう。のこりの 畑は たて 5 × よこ 8 の まま",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 25, DIM)
	else:
		# 門と 動く板
		var gate := Rect2(o + Vector2(s * 3.0, -s * 4.0), Vector2(s * 6.0, s * 4.0))
		c.draw_rect(gate, Color(0.30, 0.36, 0.52, 0.7))
		c.draw_rect(gate, INK, false, 4.0)
		var bx := o.x + s * pos
		var board := Rect2(Vector2(bx, o.y - s * 4.0), Vector2(s * 5.0, s * 4.0))
		c.draw_rect(board, Color(1.0, 0.78, 0.35, 0.35))
		c.draw_rect(board, GOLD, false, 3.0)
		var left := maxf(bx, gate.position.x)
		var right := minf(bx + s * 5.0, gate.position.x + gate.size.x)
		if right > left:
			c.draw_rect(Rect2(Vector2(left, gate.position.y), Vector2(right - left, gate.size.y)),
				Color(1.0, 0.85, 0.3, 0.55))
		c.draw_circle(Vector2(bx + s * 2.5, o.y + 26.0), 16.0, GOLD)
		c.draw_string(ThemeDB.fallback_font, Vector2(24, map.size.y - 18),
			"板を 右へ 動かそう。重なった ところが 広がっていく",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 25, DIM)


## つみ木を つむ
func _draw_stack(c: Control) -> void:
	var n: int = st["n"]
	var w: int = st["bw"]
	var d: int = st["bd"]
	var h: int = st["bh"]
	# はこが 画面いっぱいに 見えるように、そのつど 大きさを 決める
	var s := minf(map.size.x / (float(w) + float(d) * 0.42 + 1.6),
		map.size.y / (float(h) + float(d) * 0.30 + 2.2))
	var base := Vector2(map.size.x * 0.5 - s * (float(w) + float(d) * 0.42) * 0.5,
		map.size.y * 0.5 + s * (float(h) + float(d) * 0.30) * 0.5)
	# 箱の わく
	var box_pts: Array = []
	for p in [Vector3(0, 0, 0), Vector3(w, 0, 0), Vector3(w, d, 0), Vector3(0, d, 0),
			Vector3(0, 0, h), Vector3(w, 0, h), Vector3(w, d, h), Vector3(0, d, h)]:
		box_pts.append(base + Vector2(ProblemGen.proj3(p).x, -ProblemGen.proj3(p).y) * s)
	for e in [[0, 1], [1, 2], [2, 3], [3, 0], [4, 5], [5, 6], [6, 7], [7, 4],
			[0, 4], [1, 5], [2, 6], [3, 7]]:
		c.draw_line(box_pts[e[0]], box_pts[e[1]], Color(1, 1, 1, 0.45), 2.5)
	# つんだ さいころ
	var placed := 0
	for z in h:
		for y in d:
			for x in w:
				if placed >= n:
					break
				var o3 := Vector3(x, y, z)
				var quad := PackedVector2Array()
				for q in [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)]:
					var pr := ProblemGen.proj3(o3 + q)
					quad.append(base + Vector2(pr.x, -pr.y) * s)
				c.draw_colored_polygon(quad, Color(0.55, 0.75, 1.0, 0.85))
				c.draw_polyline(quad + PackedVector2Array([quad[0]]), Color(1, 1, 1, 0.5), 1.5)
				placed += 1
	c.draw_string(ThemeDB.fallback_font, Vector2(24, map.size.y - 18),
		"タップして さいころを つもう(%d / %d こ)" % [n, w * d * h],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 25, DIM)


## 箱を ひらく / ななめに 切る
func _draw_open(c: Control) -> void:
	var t: float = st["open"]
	var s := _cell()
	var mid := Vector2(map.size.x * 0.5, map.size.y * 0.45)
	if String(unit["id"]) == "k19":
		# 十字に ひらく
		var faces := [Vector2(0, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(2, 0),
			Vector2(0, -1), Vector2(0, 1)]
		for i in faces.size():
			var f: Vector2 = faces[i]
			var pos := mid + f * s * 1.7 * t + Vector2(-s * 0.85, -s * 0.85)
			c.draw_rect(Rect2(pos, Vector2(s * 1.7, s * 1.7)),
				Color(0.55, 0.75, 1.0, 0.85 if i == 0 else 0.6))
			c.draw_rect(Rect2(pos, Vector2(s * 1.7, s * 1.7)), INK, false, 3.0)
		c.draw_string(ThemeDB.fallback_font, Vector2(24, map.size.y - 18),
			"つまんで ひらこう(面は 6 つ)" if t < 0.9 else "ひらいた! 面は 6 つ",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 25, DIM if t < 0.9 else GOLD)
	else:
		# ななめに 切った 箱と、さかさに した 同じ 箱
		var w := s * 4.0
		var h1 := s * 1.6
		var h2 := s * 4.2
		var o := mid + Vector2(-w, s * 1.6)
		c.draw_colored_polygon(PackedVector2Array([o, o + Vector2(w, 0),
			o + Vector2(w, -h2), o + Vector2(0, -h1)]), Color(0.40, 0.60, 0.95, 0.45))
		var flip_o := o + Vector2(w, 0) + Vector2(w, 0) * t
		c.draw_colored_polygon(PackedVector2Array([flip_o, flip_o + Vector2(w, 0),
			flip_o + Vector2(w, -h1), flip_o + Vector2(0, -h2)]),
			Color(1.0, 0.78, 0.35, 0.55))
		c.draw_string(ThemeDB.fallback_font, Vector2(24, map.size.y - 18),
			"さかさの 箱を 右へ 運ぼう" if t < 0.9 else "2 つで まっすぐな 箱に なった",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 25, DIM if t < 0.9 else GOLD)


## 水を 移す
func _draw_pour(c: Control) -> void:
	var s := _cell()
	var o := _grid_origin()
	var vol := 24.0
	var w: float = st["w"]
	var depth := vol / w
	# もとの 器(はば 3・水は いっぱい)
	c.draw_rect(Rect2(o + Vector2(0, -s * 8.0), Vector2(s * 3.0, s * 8.0)), INK, false, 4.0)
	c.draw_rect(Rect2(o + Vector2(0, -s * 8.0), Vector2(s * 3.0, s * 8.0)),
		Color(0.30, 0.60, 0.95, 0.5))
	var rx := o.x + s * 4.0
	c.draw_rect(Rect2(Vector2(rx, o.y - s * 8.0), Vector2(s * w, s * 8.0)), INK, false, 4.0)
	c.draw_rect(Rect2(Vector2(rx, o.y - s * depth), Vector2(s * w, s * depth)),
		Color(0.30, 0.60, 0.95, 0.5))
	c.draw_circle(Vector2(rx + s * w, o.y + 26.0), 16.0, GOLD)
	c.draw_string(ThemeDB.fallback_font, Vector2(24, map.size.y - 18),
		"右の 器の はばを 変えよう(はば %.1f・深さ %.1f・かけると %.0f)" % [w, depth, w * depth],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 25, DIM)


## 影で 測る。影の長さは 太陽の 高さで 大きく変わるので、
## そのつど 全体が 収まる 倍率を 決める(前は 右へ はみ出していた)
func _draw_shadow(c: Control) -> void:
	var th: float = st["sun"]
	var pole := 2.0
	var tree := 5.0
	var tree_x := 4.0
	var s1 := pole / tan(deg_to_rad(th))
	var s2 := tree / tan(deg_to_rad(th))
	var need_w := tree_x + s2 + 2.0
	var need_h := tree + 3.5
	var k := minf((c.size.x - 60.0) / need_w, (c.size.y - 150.0) / need_h)
	var ground := c.size.y * 0.74
	var ox := 40.0
	var font := ThemeDB.fallback_font
	c.draw_line(Vector2(20, ground), Vector2(c.size.x - 20, ground), INK, 4.0)
	# くい と 木
	for item in [[0.0, pole, s1, "くい"], [tree_x, tree, s2, "木"]]:
		var x: float = ox + float(item[0]) * k
		var h: float = float(item[1]) * k
		var sh: float = float(item[2]) * k
		c.draw_line(Vector2(x, ground), Vector2(x, ground - h), GOLD, 7.0)
		c.draw_line(Vector2(x, ground), Vector2(x + sh, ground), SKY, 6.0)
		c.draw_dashed_line(Vector2(x, ground - h), Vector2(x + sh, ground),
			Color(1, 1, 1, 0.35), 2.0, 9.0)
		c.draw_string(font, Vector2(x - 34.0, ground - h - 12.0), String(item[3]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24, GOLD)
	# 太陽(光の 向きに 置く)
	var dir := Vector2(-cos(deg_to_rad(th)), -sin(deg_to_rad(th)))
	# 太陽は 木の 上から 光の 向きへ(画面の 外に 出ないように)
	var sun := Vector2(ox + tree_x * k, ground - tree * k) + dir * (k * 1.8)
	sun.x = clampf(sun.x, 40.0, c.size.x - 40.0)
	sun.y = clampf(sun.y, 46.0, ground - 40.0)
	c.draw_circle(sun, 24.0, Color(1.0, 0.9, 0.4))
	c.draw_string(font, sun + Vector2(-18.0, -32.0), "太陽", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, DIM)
	c.draw_string(font, Vector2(24, c.size.y - 18),
		"太陽を 上下に 動かそう(くい %.1f ÷ %.1f ＝ %.2f ・ 木 %.1f ÷ %.1f ＝ %.2f)" % [
			pole, s1, pole / s1, tree, s2, tree / s2],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 24, DIM)


# =========================================================
# さわる(ゆび)
# =========================================================

func _on_map_input(event: InputEvent) -> void:
	if phase != 1:
		return
	var act := String(unit["act"])
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_press(act, event.position)
		else:
			_release(act, event.position)
		map.queue_redraw()
	elif dragging >= 0:
		st["drag_pos"] = event.position
		_drag_to(act, event.position)
		map.queue_redraw()


func _press(act: String, at: Vector2) -> void:
	match act:
		"tear":
			var tri: Array = st["tri"]
			var placed: Array = st["placed"]
			var best := -1
			var best_d := 130.0
			for i in 3:
				if bool(placed[i]):
					continue
				var d := _to_screen(tri[i]).distance_to(at)
				if d < best_d:
					best_d = d
					best = i
			if best >= 0:
				dragging = best
				st["drag_pos"] = at
				GameState.play_sfx("type")
		"slide":
			if not bool(st["moved"]):
				dragging = 0
				st["drag_pos"] = at
				GameState.play_sfx("type")
		"fold":
			dragging = 0
			_fold_by(at)
		"diag":
			# 金色の 点を つまんだら、そこから ゆびで なぞって 線を 引く。
			# (タップ 2 回でも つなげる)
			var from_p: Vector2 = _diag_points()[0]
			if at.distance_to(from_p) < 120.0:
				dragging = 0
				st["drag_pos"] = at
				GameState.play_sfx("type")
			else:
				_tap_diag(at)
		"clock":
			dragging = 0
			var v := at - _clock_center()
			st["last"] = rad_to_deg(atan2(v.x, -v.y))
		"stack":
			var total: int = int(st["bw"]) * int(st["bd"]) * int(st["bh"])
			st["n"] = mini(int(st["n"]) + 1, total)
			GameState.play_sfx("type")
			if int(st["n"]) >= total:
				GameState.play_sfx("correct")
				_act_done()
		_:
			dragging = 0
			_drag_to(act, at)


func _release(act: String, at: Vector2) -> void:
	if dragging < 0:
		return
	match act:
		"diag":
			# なぞった 先に 点が あれば つなぐ
			st["drag_pos"] = at
			_tap_diag(at)
		"tear":
			if at.y > _tear_zone().position.y:
				var placed: Array = st["placed"]
				placed[dragging] = true
				GameState.play_sfx("correct")
				var n := 0
				for p in placed:
					if bool(p):
						n += 1
				if n == 3:
					_act_done()
		"slide":
			var goal: Vector2 = _slide_target()[0]
			if at.distance_to(goal) < 130.0:
				st["moved"] = true
				GameState.play_sfx("correct")
				_act_done()
		"fold":
			if float(st["fold"]) > 0.95:
				GameState.play_sfx("correct")
				_act_done()
		"clock":
			if absf(float(st["deg"]) - float(st["goal"])) < 9.0:
				st["set"] = true
				GameState.play_sfx("correct")
				_act_done()
		"grid":
			if int(st["w"]) == int(st["tw"]) and int(st["h"]) == int(st["th"]):
				GameState.play_sfx("correct")
				_act_done()
		"cut", "open":
			var key := "moved" if act == "cut" else "open"
			if float(st[key]) > 0.9:
				GameState.play_sfx("correct")
				_act_done()
		"roll":
			if float(st["turns"]) >= 1.0:
				GameState.play_sfx("correct")
				_act_done()
		"shift":
			if absf(float(st["pos"]) - float(st["from"])) >= 2.0:
				GameState.play_sfx("correct")
				_act_done()
		"pour":
			if absf(float(st["w"]) - float(st["from"])) >= 1.5:
				GameState.play_sfx("correct")
				_act_done()
		"shadow":
			if absf(float(st["sun"]) - float(st["from"])) >= 12.0:
				GameState.play_sfx("correct")
				_act_done()
	dragging = -1


## ゆびの 位置から、その さわり方の 値を 決める
func _drag_to(act: String, at: Vector2) -> void:
	var s := _cell()
	var o := _grid_origin()
	match act:
		"diag":
			st["drag_pos"] = at
		"clock":
			_turn_clock(at)
		"fold":
			_fold_by(at)
		"grid":
			st["w"] = clampi(int(round((at.x - o.x) / s)), 1, 9)
			st["h"] = clampi(int(round((o.y - at.y) / s)), 1, 7)
		"cut":
			# かけらの もとの まん中から、運び先までの 進みぐあい
			var parts := _cut_shapes()
			var piece: PackedVector2Array = parts[1]
			var from := Vector2.ZERO
			for q in piece:
				from += q
			from /= float(piece.size())
			var to_v: Vector2 = parts[2]
			st["moved"] = clampf((at - from).dot(to_v) / maxf(to_v.length_squared(), 1.0), 0.0, 1.0)
		"roll":
			var rr := minf((map.size.x - 90.0) / (TAU + 2.0), map.size.y * 0.16)
			st["turns"] = clampf((at.x - (50.0 + rr)) / maxf(TAU * rr, 1.0), 0.0, 1.05)
		"shift":
			st["pos"] = clampf((at.x - o.x) / s - 0.5, 0.0, 8.0)
		"open":
			# 右へ なぞった ぶんだけ ひらく(これが 無いと、ゆびで 動かしても
			# 何も 起きない ―― 実際に そうなっていた)
			st["open"] = clampf((at.x - map.size.x * 0.5) / (s * 3.0), 0.0, 1.0)
		"pour":
			st["w"] = clampf((at.x - (o.x + s * 4.0)) / s, 1.5, 6.0)
		"shadow":
			st["sun"] = clampf(30.0 + (o.y - at.y) / s * 6.0, 25.0, 70.0)


## 折る量(0..1)を 指の位置から決める
func _fold_by(at: Vector2) -> void:
	if bool(st.get("tape", false)):
		# 紙テープは、右はしを つかんで 折り返し先(鏡うつしの 場所)まで 運ぶ
		var from_p := _tape_screen(_tape_handle())
		var to_p := _tape_screen(_tape_fold_pt(_tape_handle(), 1.0))
		var v := to_p - from_p
		st["fold"] = clampf((at - from_p).dot(v) / maxf(v.length_squared(), 1.0), 0.0, 1.0)
		return
	var bl := _to_screen(Vector2(-5.0, -3.5))
	var br := _to_screen(Vector2(5.0, -3.5))
	var t := clampf((br.x - at.x) / maxf(br.x - bl.x, 1.0), 0.0, 1.0)
	st["fold"] = t


## 対角線を 1 本ずつ引く
## 多角形の 点(画面の 場所)
func _diag_points() -> Array:
	var n: int = st["n"]
	var pts: Array = []
	for i in n:
		var th := TAU * float(i) / float(n) + PI * 0.5
		pts.append(_to_screen(Vector2(cos(th), sin(th)) * 7.0))
	return pts


func _tap_diag(at: Vector2) -> void:
	var n: int = st["n"]
	var picked: Array = st["picked"]
	var pts := _diag_points()
	# いちばん 近い、まだ つないでいない 点に つなぐ
	var best := -1
	var best_d := 130.0
	for i in range(2, n - 1):
		var p: Vector2 = pts[i]
		var d := at.distance_to(p)
		if d < best_d and not picked.has(i):
			best_d = d
			best = i
	if best < 0:
		return
	picked.append(best)
	GameState.play_sfx("type")
	if picked.size() >= n - 3:
		GameState.play_sfx("correct")
		st["tri"] = n - 2
		_act_done()
