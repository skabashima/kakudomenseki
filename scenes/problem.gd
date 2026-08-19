extends Control
## 問題シーン。ステージ攻略(3問ミッション)とチャレンジ(タイムアタック/サバイバル)を共用。
##
## ステージ攻略: ハート3つで3問に挑む。まちがえるとハートが減り、
## 0 になるとやり直し。クリア時は残りハートがそのまま ★ になる。
## 得点は 速さ・一発正解・ノーヒント・コンボ で伸びる。

const TIME_LIMIT := 180.0     # タイムアタックの制限時間(秒)
const SURVIVAL_LIVES := 3

var course: Dictionary
var stage: Dictionary
var stage_id: String

var rng := RandomNumberGenerator.new()
var problem: Dictionary = {}
var q_index := 0              # いま何問目か(0 はじまり)
var hearts := GameState.START_HEARTS
var stage_score := 0
var tries := 0                # この問題で何回目の解答か
var hints_used := 0
var q_start_msec := 0
var input_text := ""
var locked := false           # 演出中は入力を受け付けない

# チャレンジ用
var challenge_count := 0      # 正解数
var lives := SURVIVAL_LIVES
var time_left := TIME_LIMIT
var timer_running := false

# UI ノード
var title_lbl: Label
var hearts_lbl: Label
var score_lbl: Label
var combo_lbl: Label
var progress_lbl: Label
var figure: FigureView
var question_lbl: Label
var hint_lbl: Label
var answer_lbl: Label
var unit_lbl: Label
var hint_btn: Button
var overlay: Control = null
var answer_panel: PanelContainer


## ステージにひもづくモード(通常攻略 or 挑戦 10 問)か
func _stage_based() -> bool:
	return GameState.mode == "normal" or GameState.mode == "gauntlet"


## このプレイの問数
func _q_total() -> int:
	return GameState.GAUNTLET_QUESTIONS if GameState.mode == "gauntlet" \
		else GameState.QUESTIONS_PER_STAGE


func _ready() -> void:
	rng.randomize()
	course = ProblemGen.course_by_id(GameState.current_course)
	if _stage_based():
		stage = ProblemGen.stages_of(String(course["id"]))[GameState.current_stage]
		stage_id = String(stage["id"])
	_build_ui()
	if GameState.mode == "time":
		timer_running = true
	_next_question(true)


func _process(delta: float) -> void:
	if GameState.mode == "time" and timer_running:
		time_left -= delta
		if time_left <= 0.0:
			time_left = 0.0
			timer_running = false
			_finish_challenge()
		_update_status()


# ---------------------------------------------------------
# UI 構築
# ---------------------------------------------------------

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.13, 0.24)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var ins := GameState.safe_insets()
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_top = 14.0 + float(ins["top"])
	root.offset_left = 26.0
	root.offset_right = -26.0
	root.offset_bottom = -14.0 - float(ins["bottom"])
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	# --- ヘッダー行: 戻る / タイトル / ハートまたは残り時間 ---
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	root.add_child(head)
	var back := Button.new()
	back.text = "←"
	back.custom_minimum_size = Vector2(84, 64)
	back.add_theme_font_size_override("font_size", 30)
	GameState.style_button(back, Color(0.28, 0.32, 0.44))
	back.pressed.connect(_quit)
	head.add_child(back)
	title_lbl = Label.new()
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.clip_text = true
	match GameState.mode:
		"time":
			title_lbl.text = "タイムアタック"
		"survival":
			title_lbl.text = "サバイバル"
		"gauntlet":
			title_lbl.text = "挑戦: " + String(stage["title"])
		_:
			title_lbl.text = String(stage["title"])
	head.add_child(title_lbl)
	hearts_lbl = Label.new()
	hearts_lbl.add_theme_font_size_override("font_size", 30)
	hearts_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.5))
	head.add_child(hearts_lbl)

	# --- ステータス行: 進行 / スコア / コンボ ---
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 20)
	root.add_child(status)
	progress_lbl = Label.new()
	progress_lbl.add_theme_font_size_override("font_size", 24)
	progress_lbl.add_theme_color_override("font_color", Color(0.8, 0.87, 1.0))
	status.add_child(progress_lbl)
	score_lbl = Label.new()
	score_lbl.add_theme_font_size_override("font_size", 24)
	score_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	score_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_child(score_lbl)
	combo_lbl = Label.new()
	combo_lbl.add_theme_font_size_override("font_size", 24)
	combo_lbl.add_theme_color_override("font_color", Color(0.6, 0.95, 1.0))
	status.add_child(combo_lbl)

	# --- 図形 ---
	var fig_panel := PanelContainer.new()
	fig_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fig_panel.add_theme_stylebox_override("panel",
		GameState.flat_style(Color(0.06, 0.09, 0.17, 1.0), 20))
	root.add_child(fig_panel)
	figure = FigureView.new()
	figure.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fig_panel.add_child(figure)

	# --- 補助線ツール(図の右上)---
	# ✏ を押すと図の上をなぞって補助線が引ける(頂点や中点にスナップ)。
	# ↩ で 1 本もどす。問題が変わると補助線は消える
	var undo_btn := Button.new()
	undo_btn.text = "↩"
	undo_btn.add_theme_font_size_override("font_size", 24)
	undo_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	undo_btn.offset_left = -64.0
	undo_btn.offset_top = 6.0
	undo_btn.offset_right = -6.0
	undo_btn.offset_bottom = 60.0
	GameState.style_button(undo_btn, Color(0.28, 0.32, 0.44))
	undo_btn.pressed.connect(func() -> void:
		GameState.play_sfx("type")
		figure.aux_undo())
	figure.add_child(undo_btn)
	var pen_btn := Button.new()
	pen_btn.toggle_mode = true
	pen_btn.text = "✏ 補助線"
	pen_btn.add_theme_font_size_override("font_size", 22)
	pen_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pen_btn.offset_left = -216.0
	pen_btn.offset_top = 6.0
	pen_btn.offset_right = -72.0
	pen_btn.offset_bottom = 60.0
	GameState.style_button(pen_btn, Color(0.24, 0.5, 0.35))
	pen_btn.toggled.connect(func(on: bool) -> void:
		GameState.play_sfx("tap")
		figure.aux_enabled = on)
	figure.add_child(pen_btn)

	# --- 問題文 ---
	question_lbl = Label.new()
	question_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_lbl.add_theme_font_size_override("font_size", 27)
	question_lbl.custom_minimum_size = Vector2(0, 116)
	root.add_child(question_lbl)

	# --- ヒント表示欄 ---
	hint_lbl = Label.new()
	hint_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_lbl.add_theme_font_size_override("font_size", 23)
	hint_lbl.add_theme_color_override("font_color", Color(0.65, 0.9, 1.0))
	hint_lbl.custom_minimum_size = Vector2(0, 60)
	root.add_child(hint_lbl)

	# --- 解答欄 ---
	var ans_row := HBoxContainer.new()
	ans_row.add_theme_constant_override("separation", 12)
	root.add_child(ans_row)
	answer_panel = PanelContainer.new()
	answer_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	answer_panel.add_theme_stylebox_override("panel",
		GameState.flat_style(Color(0.13, 0.19, 0.33, 1.0), 14))
	ans_row.add_child(answer_panel)
	answer_lbl = Label.new()
	answer_lbl.text = ""
	answer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	answer_lbl.add_theme_font_size_override("font_size", 44)
	answer_lbl.custom_minimum_size = Vector2(0, 72)
	answer_panel.add_child(answer_lbl)
	unit_lbl = Label.new()
	unit_lbl.add_theme_font_size_override("font_size", 30)
	unit_lbl.add_theme_color_override("font_color", Color(0.8, 0.87, 1.0))
	unit_lbl.custom_minimum_size = Vector2(70, 0)
	ans_row.add_child(unit_lbl)

	# --- キーパッド(電卓つき: 式を組んでそのまま答えられる) ---
	var pad := GridContainer.new()
	pad.columns = 5
	pad.add_theme_constant_override("h_separation", 10)
	pad.add_theme_constant_override("v_separation", 10)
	root.add_child(pad)
	var keys := [
		"7", "8", "9", "⌫", "C",
		"4", "5", "6", "×", "÷",
		"1", "2", "3", "+", "−",
		"0", ".", "(", ")", "√",
	]
	var op_col := Color(0.33, 0.3, 0.5)
	for k in keys:
		var btn := Button.new()
		btn.text = k
		btn.custom_minimum_size = Vector2(0, 80)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 32)
		var col := Color(0.2, 0.28, 0.46)
		if k == "⌫" or k == "C":
			col = Color(0.45, 0.3, 0.3)
		elif k in ["×", "÷", "+", "−", "(", ")", "√"]:
			col = op_col
		GameState.style_button(btn, col)
		btn.pressed.connect(_on_key.bind(k))
		pad.add_child(btn)

	# --- 下段: ヒント / =(計算) / こたえる ---
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	root.add_child(bottom)
	hint_btn = Button.new()
	hint_btn.text = "ヒント"
	hint_btn.custom_minimum_size = Vector2(0, 84)
	hint_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_btn.size_flags_stretch_ratio = 1.0
	hint_btn.add_theme_font_size_override("font_size", 26)
	GameState.style_button(hint_btn, Color(0.35, 0.4, 0.2))
	hint_btn.pressed.connect(_on_key.bind("ヒント"))
	bottom.add_child(hint_btn)
	var eq_btn := Button.new()
	eq_btn.text = "＝ 計算"
	eq_btn.custom_minimum_size = Vector2(0, 84)
	eq_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eq_btn.size_flags_stretch_ratio = 1.0
	eq_btn.add_theme_font_size_override("font_size", 26)
	GameState.style_button(eq_btn, Color(0.24, 0.42, 0.72))
	eq_btn.pressed.connect(_on_key.bind("="))
	bottom.add_child(eq_btn)
	var ok_btn := Button.new()
	ok_btn.text = "こたえる"
	ok_btn.custom_minimum_size = Vector2(0, 84)
	ok_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok_btn.size_flags_stretch_ratio = 1.4
	ok_btn.add_theme_font_size_override("font_size", 28)
	GameState.style_button(ok_btn, Color(0.2, 0.55, 0.35))
	ok_btn.pressed.connect(_on_key.bind("OK"))
	bottom.add_child(ok_btn)


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	var key := event as InputEventKey
	var s := char(key.unicode)
	if (s >= "0" and s <= "9") or s in [".", "(", ")"]:
		_on_key(s)
	elif s == "-":
		_on_key("−")
	elif s == "*":
		_on_key("×")
	elif s == "/":
		_on_key("÷")
	elif s == "+":
		_on_key("+")
	elif s == "=":
		_on_key("=")
	elif key.keycode == KEY_BACKSPACE:
		_on_key("⌫")
	elif key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
		_on_key("OK")


# ---------------------------------------------------------
# 出題
# ---------------------------------------------------------

func _next_question(first := false) -> void:
	if not first:
		q_index += 1
	tries = 0
	hints_used = 0
	input_text = ""
	locked = false
	var sid: String
	var tier: int
	if GameState.mode == "gauntlet":
		# 挑戦モード: 単元の難度ラダーを 1 問目から 10 問目まで登る
		# (各ステージが tier 0-9 を「解法の種類 × 難しさ」の階段に割り当てている)
		sid = stage_id
		tier = q_index
	elif GameState.mode == "normal":
		sid = stage_id
		tier = q_index
	else:
		# チャレンジ: 正解数が増えるほど難しいステージ・難しいバリエーションが出る
		var ramp := clampf(challenge_count / 15.0, 0.0, 1.0)
		sid = ProblemGen.random_stage(GameState.challenge_course, rng, ramp)
		tier = rng.randi_range(0, mini(2 + int(ramp * 7.0), 9))
	problem = ProblemGen.generate(sid, rng, tier)
	figure.set_spec(problem["fig"])
	question_lbl.text = String(problem["q"])
	# 電卓と補助線の存在をそっと知らせる(ヒントを出すと上書きされる)
	hint_lbl.text = "式のまま答えてOK(例: 12×8÷2)。✏で図に補助線も引けるよ"
	hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.62, 0.75, 0.8))
	unit_lbl.text = String(problem["unit"])
	if not _stage_based():
		title_lbl.text = ("タイムアタック  " if GameState.mode == "time" else "サバイバル  ") \
			+ ProblemGen.stage_title(sid)
	hint_btn.disabled = false
	q_start_msec = Time.get_ticks_msec()
	_update_answer()
	_update_status()


func _update_status() -> void:
	match GameState.mode:
		"time":
			progress_lbl.text = "のこり %d 秒" % int(ceil(time_left))
			hearts_lbl.text = "正解 %d" % challenge_count
		"survival":
			progress_lbl.text = "正解 %d" % challenge_count
			hearts_lbl.text = _hearts_str(lives)
		_:
			progress_lbl.text = "問 %d / %d" % [q_index + 1, _q_total()]
			hearts_lbl.text = _hearts_str(hearts)
	score_lbl.text = "%d点" % (stage_score if _stage_based() else GameState.total_score())
	combo_lbl.text = ("コンボ ×%d" % GameState.combo) if GameState.combo > 1 else ""


func _hearts_str(n: int) -> String:
	var s := ""
	for i in GameState.START_HEARTS:
		s += "♥" if i < n else "♡"
	return s


func _update_answer() -> void:
	answer_lbl.text = input_text if input_text != "" else " "
	# 長い式は文字を小さくして収める
	var n := input_text.length()
	answer_lbl.add_theme_font_size_override("font_size", 44 if n <= 12 else (34 if n <= 19 else 28))


# ---------------------------------------------------------
# 入力
# ---------------------------------------------------------

func _on_key(k: String) -> void:
	if locked:
		return
	match k:
		"OK":
			_submit()
		"=":
			_calc_in_place()
		"⌫":
			GameState.play_sfx("type")
			input_text = input_text.substr(0, input_text.length() - 1)
		"C":
			GameState.play_sfx("type")
			input_text = ""
		"ヒント":
			_show_hint()
		_:
			GameState.play_sfx("type")
			if input_text.length() >= 26:
				return
			if k == "." and _current_number_has_dot():
				return
			input_text += k
	_update_answer()


## いま入力中の数(最後の演算子より後ろ)にすでに小数点があるか
func _current_number_has_dot() -> bool:
	var tail := input_text
	for op in ["+", "−", "×", "÷", "(", ")", "√"]:
		var idx := tail.rfind(op)
		if idx >= 0:
			tail = tail.substr(idx + 1)
	return tail.contains(".")


## ＝キー: 式をその場で計算して、答え欄を計算結果に置きかえる
func _calc_in_place() -> void:
	if input_text == "":
		return
	var res: Dictionary = ExprEval.eval(input_text)
	if not res["ok"]:
		GameState.play_sfx("fail")
		_show_flash(String(res["err"]), Color(1.0, 0.75, 0.4))
		return
	GameState.play_sfx("type")
	input_text = ExprEval.fmt(float(res["value"]))


func _show_hint() -> void:
	if hints_used >= 2:
		return
	GameState.play_sfx("hint")
	hints_used += 1
	var text := String(problem["hint1"]) if hints_used == 1 else String(problem["hint2"])
	hint_lbl.text = "ヒント%d: %s" % [hints_used, text]
	hint_lbl.add_theme_color_override("font_color", Color(0.65, 0.9, 1.0))
	if hints_used >= 2:
		hint_btn.disabled = true


func _submit() -> void:
	if input_text == "" or input_text == "−" or input_text == ".":
		return
	# 式でもそのまま計算して答え合わせできる(紙とペンいらず)。
	# 式のかたちがおかしいときはハートを減らさずに教える
	var res: Dictionary = ExprEval.eval(input_text)
	if not res["ok"]:
		GameState.play_sfx("fail")
		_show_flash(String(res["err"]), Color(1.0, 0.75, 0.4))
		return
	var v := float(res["value"])
	var ans := float(problem["answer"])
	var tol := float(problem["tol"])
	tries += 1
	if absf(v - ans) <= tol:
		_on_correct()
	else:
		_on_wrong()


# ---------------------------------------------------------
# 判定
# ---------------------------------------------------------

func _on_correct() -> void:
	locked = true
	GameState.play_sfx("correct")
	var seconds := (Time.get_ticks_msec() - q_start_msec) / 1000.0
	var pts := GameState.question_score(tries, hints_used, seconds, GameState.combo)
	GameState.combo += 1
	if GameState.combo > GameState.best_combo:
		GameState.best_combo = GameState.combo
	GameState.bump_stat("correct")
	if tries == 1 and hints_used == 0:
		GameState.bump_stat("perfect")
	if _stage_based():
		stage_score += pts
		_update_status()
		var last := q_index + 1 >= _q_total()
		_show_flash("+%d点" % pts, Color(0.55, 1.0, 0.6))
		await get_tree().create_timer(0.85).timeout
		if last:
			if GameState.mode == "gauntlet":
				_finish_gauntlet()
			else:
				_finish_stage()
		else:
			_next_question()
	else:
		challenge_count += 1
		_update_status()
		_show_flash("+1  (%d問目)" % challenge_count, Color(0.55, 1.0, 0.6))
		await get_tree().create_timer(0.6).timeout
		# 演出待ちの間にタイムアップして結果画面が出ていたら何もしない
		if overlay != null:
			return
		_next_question()


func _on_wrong() -> void:
	locked = true
	GameState.play_sfx("fail")
	GameState.combo = 0
	_shake_answer()
	match GameState.mode:
		"time":
			# 時間ロスがペナルティ。答えを変えて次へ
			_show_flash("ミス!", Color(1.0, 0.5, 0.5))
			await get_tree().create_timer(0.6).timeout
			if overlay != null:
				return
			_update_status()
			_next_question()
		"survival":
			lives -= 1
			_update_status()
			if lives <= 0:
				_finish_challenge()
			else:
				_show_flash("ミス! のこり %s" % _hearts_str(lives), Color(1.0, 0.5, 0.5))
				await get_tree().create_timer(0.7).timeout
				if overlay != null:
					return
				_next_question()
		_:
			hearts -= 1
			_update_status()
			if hearts <= 0:
				_fail_stage()
			else:
				_show_flash("ちがう… %s" % _hearts_str(hearts), Color(1.0, 0.5, 0.5))
				await get_tree().create_timer(0.7).timeout
				input_text = ""
				_update_answer()
				locked = false


func _shake_answer() -> void:
	var tw := create_tween()
	var base := answer_panel.position
	for off in [12.0, -10.0, 7.0, -4.0, 0.0]:
		tw.tween_property(answer_panel, "position:x", base.x + off, 0.05)


## 画面中央に一瞬メッセージを出す
func _show_flash(text: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 56)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.14))
	lbl.add_theme_constant_override("outline_size", 10)
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.position.y -= 160.0
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 60.0, 0.7)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.7).set_delay(0.15)
	tw.tween_callback(lbl.queue_free)


# ---------------------------------------------------------
# ステージの結果
# ---------------------------------------------------------

func _finish_stage() -> void:
	GameState.play_sfx("clear")
	var earned := hearts
	GameState.bump_stat("clear")
	GameState.record_clear(stage_id, earned, stage_score)
	var panel := _overlay_panel()
	var v := panel.get_node("v") as VBoxContainer
	_add_label(v, "ステージクリア!", 52, Color(1.0, 0.9, 0.5))
	var stars_lbl := _add_label(v, "", 64, Color(1.0, 0.84, 0.3))
	_add_label(v, "スコア %d点(自己ベスト %d点)" % [stage_score, int(GameState.scores.get(stage_id, 0))],
		28, Color.WHITE)
	if GameState.combo > 1:
		_add_label(v, "コンボ継続中 ×%d" % GameState.combo, 24, Color(0.6, 0.95, 1.0))
	var stages: Array = course["stages"]
	var has_next: bool = GameState.current_stage + 1 < stages.size()
	if has_next:
		_add_button(v, "つぎのステージへ", Color(0.2, 0.55, 0.35), func() -> void:
			GameState.current_stage += 1
			GameState.change_scene("res://scenes/problem.tscn"))
	else:
		_add_label(v, "このコースはすべてクリア!", 26, Color(0.6, 1.0, 0.7))
	_add_button(v, "もういちど(べつの数値で)", Color(0.24, 0.42, 0.72), func() -> void:
		GameState.change_scene("res://scenes/problem.tscn"))
	_add_button(v, "ステージ一覧へ", Color(0.28, 0.32, 0.44), func() -> void:
		GameState.change_scene("res://scenes/stage_select.tscn"))
	# ★を 1 つずつ表示する演出
	_animate_stars(stars_lbl, earned)


func _animate_stars(lbl: Label, earned: int) -> void:
	var shown := 0
	lbl.text = "☆ ☆ ☆"
	for i in earned:
		await get_tree().create_timer(0.45).timeout
		if not is_instance_valid(lbl):
			return
		shown += 1
		GameState.play_sfx("star")
		var s := ""
		for j in 3:
			s += ("★" if j < shown else "☆") + (" " if j < 2 else "")
		lbl.text = s


func _fail_stage() -> void:
	GameState.play_sfx("fail")
	GameState.bump_stat("fail")
	if GameState.mode == "gauntlet":
		GameState.record_gauntlet(stage_id, q_index)
	var panel := _overlay_panel()
	var v := panel.get_node("v") as VBoxContainer
	if GameState.mode == "gauntlet":
		_add_label(v, "挑戦失敗… %d/%d 問まで" % [q_index, _q_total()], 40, Color(1.0, 0.55, 0.55))
	else:
		_add_label(v, "ハートがなくなった…", 44, Color(1.0, 0.55, 0.55))
	_add_label(v, "正解は %s%s" % [ProblemGen.fmt(float(problem["answer"])), String(problem["unit"])],
		34, Color(1.0, 0.9, 0.5))
	var expl := _add_label(v, String(problem["expl"]), 24, Color(0.85, 0.9, 1.0))
	expl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	expl.custom_minimum_size = Vector2(640, 0)
	_add_button(v, "リトライ(べつの数値で)", Color(0.2, 0.55, 0.35), func() -> void:
		GameState.change_scene("res://scenes/problem.tscn"))
	_add_button(v, "ステージ一覧へ", Color(0.28, 0.32, 0.44), func() -> void:
		GameState.change_scene("res://scenes/stage_select.tscn"))


## 挑戦モード(単元 10 問)クリア
func _finish_gauntlet() -> void:
	GameState.play_sfx("clear")
	GameState.bump_stat("gauntlet_clear")
	var first_crown := GameState.record_gauntlet(stage_id, _q_total())
	# 挑戦のスコアも自己ベストとして総得点に積む(ステージとは別枠)
	if stage_score > int(GameState.scores.get("g:" + stage_id, 0)):
		GameState.scores["g:" + stage_id] = stage_score
		GameState.save_game()
	var panel := _overlay_panel()
	var v := panel.get_node("v") as VBoxContainer
	_add_label(v, "👑 挑戦クリア!", 52, Color(1.0, 0.84, 0.3))
	_add_label(v, "%d 問連続クリア" % _q_total(), 34, Color.WHITE)
	_add_label(v, "スコア %d点(自己ベスト %d点)" % [stage_score, int(GameState.scores.get("g:" + stage_id, 0))],
		26, Color.WHITE)
	if first_crown:
		_add_label(v, "この単元の王冠を獲得!", 28, Color(0.6, 1.0, 0.7))
	if GameState.combo > 1:
		_add_label(v, "コンボ継続中 ×%d" % GameState.combo, 24, Color(0.6, 0.95, 1.0))
	_add_button(v, "もういちど(べつの数値で)", Color(0.24, 0.42, 0.72), func() -> void:
		GameState.change_scene("res://scenes/problem.tscn"))
	_add_button(v, "ステージ一覧へ", Color(0.28, 0.32, 0.44), func() -> void:
		GameState.change_scene("res://scenes/stage_select.tscn"))


func _finish_challenge() -> void:
	if overlay != null:
		return
	locked = true
	GameState.play_sfx("clear")
	var key := ("time:" + GameState.challenge_course) if GameState.mode == "time" else "survival"
	var improved := GameState.record_challenge(key, challenge_count)
	var panel := _overlay_panel()
	var v := panel.get_node("v") as VBoxContainer
	_add_label(v, "タイムアップ!" if GameState.mode == "time" else "ゲームオーバー",
		46, Color(1.0, 0.9, 0.5))
	_add_label(v, "正解 %d 問" % challenge_count, 56, Color.WHITE)
	if improved:
		_add_label(v, "自己ベスト更新!", 30, Color(0.6, 1.0, 0.7))
	else:
		_add_label(v, "自己ベスト %d 問" % int(GameState.challenge_best.get(key, 0)),
			26, Color(0.8, 0.87, 1.0))
	_add_button(v, "もういちど", Color(0.2, 0.55, 0.35), func() -> void:
		GameState.change_scene("res://scenes/problem.tscn"))
	_add_button(v, "チャレンジ選択へ", Color(0.28, 0.32, 0.44), func() -> void:
		GameState.change_scene("res://scenes/challenge_select.tscn"))


func _overlay_panel() -> PanelContainer:
	locked = true
	timer_running = false
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.1, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	add_child(overlay)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	overlay.add_child(panel)
	var v := VBoxContainer.new()
	v.name = "v"
	v.add_theme_constant_override("separation", 18)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	return panel


func _add_label(parent: Control, text: String, size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl


func _add_button(parent: Control, text: String, color: Color, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(560, 84)
	btn.add_theme_font_size_override("font_size", 28)
	GameState.style_button(btn, color)
	btn.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		cb.call())
	parent.add_child(btn)
	return btn


func _quit() -> void:
	GameState.play_sfx("tap")
	if _stage_based():
		GameState.change_scene("res://scenes/stage_select.tscn")
	else:
		GameState.change_scene("res://scenes/challenge_select.tscn")
