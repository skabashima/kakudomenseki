extends Control
## 発見モード(物語)の画面。章の中のシーンを 1 つずつ進める。
##
## talk    … 文を順に見せる(図があれば上に出す)
## measure … 図の点を指で動かして記録し、「何が一定か」を選ぶ。
##           **記録が規定回数たまるまで選択肢は出さない**(当てずっぽう防止)
## solve   … 本編と同じ生成器の問題を 1 問、4 択で解く
##
## 章のデータは core/story_defs.gd。

const HEAD := Color(1.0, 0.88, 0.45)
const BODY := Color(0.9, 0.94, 1.0)
const NEWLINE_CH := "\n"

var chapter: Dictionary = {}
var idx := 0
var scene_data: Dictionary = {}

var body: VBoxContainer
var figure: FigureView
var fig_panel: PanelContainer
var status_lbl: Label
var next_btn: Button
var choice_box: VBoxContainer
var keypad: Keypad
var answer_row: HBoxContainer
var answer_btn: Button
var input_text := ""
var answered := false

## measure 用
var apex := Vector2(4.0, 6.0)
var trials: Array = []          # 記録した行(表示用の文字列)
var guess := -1                 # 測る前の予想(-1 = まだ予想していない)
## solve 用
var problem: Dictionary = {}


func _ready() -> void:
	# そのモードの並びから取り出す(高校生モードは文が差し替わっている)
	var list: Array = StoryDefs.chapters_of(GameState.story_mode)
	chapter = StoryDefs.chapter_in(list, GameState.story_chapter)
	GameState.story_chapter = String(chapter["id"])
	idx = clampi(GameState.story_scene, 0, (chapter["scenes"] as Array).size() - 1)
	_build_frame()
	_show_scene()


func _build_frame() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.11, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var ins := GameState.safe_insets()
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_top = 16.0 + float(ins["top"])
	root.offset_left = 26.0
	root.offset_right = -26.0
	root.offset_bottom = -14.0 - float(ins["bottom"])
	root.add_theme_constant_override("separation", 10)
	add_child(root)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	root.add_child(head)
	var back := Button.new()
	back.text = "← もどる"
	back.custom_minimum_size = Vector2(170, 62)
	back.add_theme_font_size_override("font_size", 24)
	GameState.style_button(back, Color(0.28, 0.32, 0.44))
	back.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		GameState.story_scene = idx
		GameState.save_game()
		GameState.change_scene("res://scenes/story_select.tscn"))
	head.add_child(back)
	var title := Label.new()
	title.text = _kids("第%d章 %s" % [
		StoryDefs.chapter_index_in(StoryDefs.chapters_of(GameState.story_mode), String(chapter["id"])) + 1,
		String(chapter["title"])])
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", HEAD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	status_lbl = Label.new()
	status_lbl.add_theme_font_size_override("font_size", 22)
	status_lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
	head.add_child(status_lbl)

	var place := Label.new()
	place.text = "%s ・ %s" % [String(chapter["place"]),
		StoryDefs.level_label(String(chapter["level"]))]
	place.add_theme_font_size_override("font_size", 22)
	place.add_theme_color_override("font_color", Color(0.7, 0.78, 0.92))
	root.add_child(place)

	fig_panel = PanelContainer.new()
	fig_panel.add_theme_stylebox_override("panel",
		GameState.flat_style(Color(0.06, 0.09, 0.16, 1.0), 16))
	fig_panel.custom_minimum_size = Vector2(0, 480)
	fig_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fig_panel.size_flags_stretch_ratio = 1.4
	root.add_child(fig_panel)
	figure = FigureView.new()
	figure.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# 測る場面は 点を つかんで 動かすので 手書きは しない。
	# 依頼(solve)の 場面だけ、考えるための 線を 引けるように する
	figure.free_draw_enabled = false
	figure.point_dragged.connect(_on_dragged)
	fig_panel.add_child(figure)
	figure.add_tools()

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 420)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	DragScroll.attach(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)

	# 答えは 選ぶのではなく、計算して 入れる(本編・小学生モードと 同じ 電卓)
	keypad = Keypad.new()
	keypad.key_pressed.connect(_on_key)
	keypad.visible = false
	root.add_child(keypad)
	answer_row = HBoxContainer.new()
	answer_row.add_theme_constant_override("separation", 10)
	answer_row.visible = false
	root.add_child(answer_row)
	var calc_btn := Button.new()
	calc_btn.text = "＝ 計算"
	calc_btn.custom_minimum_size = Vector2(0, 84)
	calc_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	calc_btn.add_theme_font_size_override("font_size", 28)
	GameState.style_button(calc_btn, Color(0.24, 0.42, 0.72))
	calc_btn.pressed.connect(_calc_in_place)
	answer_row.add_child(calc_btn)
	answer_btn = Button.new()
	answer_btn.text = "答える"
	answer_btn.custom_minimum_size = Vector2(0, 84)
	answer_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	answer_btn.size_flags_stretch_ratio = 1.6
	answer_btn.add_theme_font_size_override("font_size", 30)
	GameState.style_button(answer_btn, Color(0.22, 0.55, 0.35))
	answer_btn.pressed.connect(_submit_answer)
	answer_row.add_child(answer_btn)


# =========================================================
# シーンの組み立て
# =========================================================

## 中学生むけのモードなので ふりがな は付けない
## (小学生むけは「ストーリー(小学生)」= scenes/kid_unit.gd のほう)
func _kids(text: String) -> String:
	return text


func _show_scene() -> void:
	answered = false
	trials.clear()
	next_btn = null      # 前の場面のボタンを「まだある」と誤認しないように
	if String((chapter["scenes"] as Array)[idx].get("type", "")) != "measure":
		guess = -1
	for c in body.get_children():
		c.queue_free()
	figure.drag_points = []
	figure.set_spec({"shapes": []})
	fig_panel.visible = false
	keypad.visible = false
	answer_row.visible = false
	input_text = ""
	keypad.answer_lbl.text = ""
	fig_panel.custom_minimum_size = Vector2(0, 480)
	var scenes: Array = chapter["scenes"]
	scene_data = scenes[idx]
	status_lbl.text = "%d / %d" % [idx + 1, scenes.size()]
	_add_label(_kids(String(scene_data["title"])), 34, HEAD)
	match String(scene_data["type"]):
		"talk":
			_build_talk()
		"measure":
			_build_measure()
		"solve":
			_build_solve()


func _build_talk() -> void:
	if scene_data.has("fig"):
		fig_panel.visible = true
		figure.set_spec(StoryFigs.spec(String(scene_data["fig"]), apex))
	elif scene_data.has("art"):
		# 文字だけの画面にしない。挿絵はその場で図形として描く(画像は持たない)
		var art := StoryArt.make(String(scene_data["art"]), 300.0)
		art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var frame := PanelContainer.new()
		frame.add_theme_stylebox_override("panel",
			GameState.flat_style(Color(0.06, 0.09, 0.16, 1.0), 16))
		# あまった たては 挿絵に わたす(下に 大きな 余白を 作らない)
		frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
		frame.add_child(art)
		body.add_child(frame)
	for line in scene_data["lines"]:
		_add_label(_kids(String(line)), 29, BODY)
	_add_next("つぎへ ▶")


func _build_measure() -> void:
	fig_panel.visible = true
	apex = StoryDefs.start_of(_fig_kind())
	_refresh_figure()
	if guess < 0:
		# 測る前に賭けさせる。当たっても外れても、そのあとの表の見え方が変わる
		_add_label(_kids("測る前に予想しよう。" + String(scene_data["question"])), 28, HEAD)
		var gb := VBoxContainer.new()
		gb.add_theme_constant_override("separation", 10)
		body.add_child(gb)
		for i in (scene_data["choices"] as Array).size():
			var g := Button.new()
			g.text = _kids(String(scene_data["choices"][i]))
			g.custom_minimum_size = Vector2(0, 92)
			g.add_theme_font_size_override("font_size", 26)
			g.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			GameState.style_button(g, Color(0.34, 0.3, 0.52))
			g.pressed.connect(_do_guess.bind(i))
			gb.add_child(g)
		return
	_add_label(_kids(String(scene_data["lead"])), 27, BODY)
	var rec := Button.new()
	rec.text = "この形を記録する"
	rec.custom_minimum_size = Vector2(0, 78)
	rec.add_theme_font_size_override("font_size", 30)
	GameState.style_button(rec, Color(0.2, 0.55, 0.35))
	rec.pressed.connect(_record)
	body.add_child(rec)
	_add_label("", 24, BODY).name = "table"
	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 10)
	body.add_child(choice_box)
	_refresh_table()


func _build_solve() -> void:
	fig_panel.visible = true
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# 本編の問題をそのまま出すと、章の物語も直前の発見も効かない画面になる。
	# その章の依頼として書き直したものを出す(数値は毎回変わる)
	problem = StoryTasks.make(String(scene_data["fig"]), rng)
	figure.set_spec(problem["fig"])
	_add_label(_kids(String(scene_data.get("lead", ""))), 27, BODY)
	_add_label(String(problem["q"]), 30, BODY)
	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 10)
	body.add_child(choice_box)
	# 電卓で 答える(式のまま 入れてもよい)。図と文を つぶさないよう 図は 少し 低く
	fig_panel.custom_minimum_size = Vector2(0, 300)
	keypad.unit_lbl.text = String(problem.get("unit", ""))
	keypad.visible = true
	answer_row.visible = true


# =========================================================
# measure の操作
# =========================================================

## 予想を選んだら、測る画面に切り替える
func _do_guess(pick: int) -> void:
	GameState.play_sfx("tap")
	guess = pick
	_show_scene()


func _fig_kind() -> String:
	return String(scene_data.get("fig", "triangle"))


func _on_dragged(_index: int, to: Vector2) -> void:
	if String(scene_data.get("type", "")) != "measure" or answered:
		return
	apex = StoryDefs.clamp_of(_fig_kind(), to)
	_refresh_figure()


func _refresh_figure() -> void:
	figure.set_spec(StoryFigs.spec(_fig_kind(), apex))
	figure.drag_points = [apex]


func _record() -> void:
	if answered:
		return
	GameState.play_sfx("type")
	# 図に出ている数字と表の数字を必ず一致させる(計算は StoryDefs 側の 1 か所)
	trials.append(String(StoryDefs.readout_of(_fig_kind(), apex)["row"]))
	_refresh_table()


func _refresh_table() -> void:
	var lbl := body.find_child("table", false, false) as Label
	if lbl != null:
		if trials.is_empty():
			lbl.text = "まだ記録していない"
		else:
			lbl.text = NEWLINE_CH.join(trials)
		lbl.add_theme_color_override("font_color", Color(0.65, 1.0, 0.8))
	# 規定回数ためるまで選択肢は出さない(当てずっぽうで進ませない)
	if trials.size() < int(scene_data.get("trials", 3)):
		return
	if not choice_box.get_children().is_empty():
		return
	var q := Label.new()
	q.text = _kids(String(scene_data["question"]))
	q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	q.add_theme_font_size_override("font_size", 25)
	q.add_theme_color_override("font_color", HEAD)
	choice_box.add_child(q)
	for i in (scene_data["choices"] as Array).size():
		var b := Button.new()
		b.text = String(scene_data["choices"][i])
		b.custom_minimum_size = Vector2(0, 84)
		b.add_theme_font_size_override("font_size", 23)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		GameState.style_button(b, Color(0.24, 0.42, 0.72))
		b.pressed.connect(_choose.bind(i))
		choice_box.add_child(b)


func _choose(pick: int) -> void:
	if answered:
		return
	if pick != int(scene_data["answer"]):
		GameState.play_sfx("fail")
		_add_label("それは記録と合わない。表をもう一度見てみよう。", 26, Color(1.0, 0.7, 0.6))
		return
	answered = true
	GameState.play_sfx("correct")
	if guess == pick:
		_add_label("予想的中! 測る前から見抜いていた。", 27, HEAD)
	elif guess >= 0:
		_add_label("予想ははずれ。だが記録が正しい答えを教えてくれた。", 26, Color(0.85, 0.9, 1.0))
	_add_label(_kids(String(scene_data.get("after", ""))), 27, Color(0.7, 1.0, 0.8))
	for b in choice_box.get_children():
		if b is Button:
			(b as Button).disabled = true
	_add_next("つぎへ ▶")


func _on_key(k: String) -> void:
	if answered:
		return
	GameState.play_sfx("type")
	input_text = Keypad.apply(input_text, k)
	keypad.answer_lbl.text = input_text


## 式のまま「＝ 計算」を押すと、その場で 計算して 答え欄に 入れる
func _calc_in_place() -> void:
	if input_text == "" or answered:
		return
	var res: Dictionary = ExprEval.eval(input_text)
	if not bool(res["ok"]):
		GameState.play_sfx("fail")
		_add_label(String(res["err"]), 24, Color(1.0, 0.7, 0.6))
		return
	GameState.play_sfx("type")
	input_text = ExprEval.fmt(float(res["value"]))
	keypad.answer_lbl.text = input_text


func _submit_answer() -> void:
	if answered:
		return
	var v := Keypad.value_of(input_text)
	if is_nan(v):
		GameState.play_sfx("fail")
		_add_label("数を入れてね(式のままでもよい)", 24, Color(1.0, 0.7, 0.6))
		return
	_pick_answer(v, float(problem["answer"]))


func _pick_answer(v: float, ans: float) -> void:
	if answered:
		return
	if absf(v - ans) > float(problem.get("tol", 0.01)):
		GameState.play_sfx("fail")
		# 章ごとに見つけたことを言い直す(ここを決め打ちにすると別の章で嘘になる)
		_add_label(_kids("ちがう。%s ― もう一度。" % String(chapter.get("found", ""))),
			26, Color(1.0, 0.7, 0.6))
		return
	answered = true
	GameState.play_sfx("correct")
	# 依頼(story_tasks)は本編の problem とちがって解説を持たない。
	# ここで問題の辞書に無い鍵を読むと関数がそこで止まり、
	# 「つぎへ」が出ないまま進めなくなる(実際にそうなっていた)
	_add_label(_kids("答え %s%s ― %s" % [ProblemGen.fmt(ans), String(problem.get("unit", "")),
		String(chapter.get("found", ""))]), 26, Color(0.85, 0.92, 1.0))
	_add_label(String(scene_data.get("after", "")), 27, Color(0.7, 1.0, 0.8))
	keypad.visible = false
	answer_row.visible = false
	for b in choice_box.get_children():
		if b is Button:
			(b as Button).disabled = true
	_add_next("つぎへ ▶")


# =========================================================
# 部品
# =========================================================

func _add_label(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	body.add_child(l)
	return l


func _add_next(text: String) -> void:
	next_btn = Button.new()
	next_btn.text = text
	next_btn.custom_minimum_size = Vector2(0, 84)
	next_btn.add_theme_font_size_override("font_size", 28)
	GameState.style_button(next_btn, Color(0.2, 0.55, 0.35))
	next_btn.pressed.connect(_advance)
	body.add_child(next_btn)


func _advance() -> void:
	GameState.play_sfx("tap")
	idx += 1
	var scenes: Array = chapter["scenes"]
	if idx >= scenes.size():
		GameState.record_story_clear(String(chapter["id"]))
		GameState.story_scene = 0
		GameState.save_game()
		_finish()
		return
	GameState.story_scene = idx
	GameState.save_game()
	_show_scene()


func _finish() -> void:
	for c in body.get_children():
		c.queue_free()
	fig_panel.visible = false
	_add_label(_kids("%s ― 章クリア!" % String(chapter["title"])), 34, HEAD)
	_add_label(_kids("見つけたこと: " + String(chapter.get("found", ""))), 24, Color(0.7, 1.0, 0.8))
	var chapters: Array = StoryDefs.chapters_of(GameState.story_mode)
	var next_i := StoryDefs.chapter_index_in(chapters, String(chapter["id"])) + 1
	if next_i < chapters.size():
		var nb := Button.new()
		nb.text = "第%d章 %s へ" % [next_i + 1, String(chapters[next_i]["title"])]
		nb.custom_minimum_size = Vector2(0, 84)
		nb.add_theme_font_size_override("font_size", 26)
		GameState.style_button(nb, Color(0.2, 0.55, 0.35))
		nb.pressed.connect(func() -> void:
			GameState.play_sfx("tap")
			GameState.story_chapter = String(chapters[next_i]["id"])
			GameState.story_scene = 0
			GameState.save_game()
			GameState.change_scene("res://scenes/story.tscn"))
		body.add_child(nb)
	var b := Button.new()
	b.text = "章えらびへもどる"
	b.custom_minimum_size = Vector2(0, 84)
	b.add_theme_font_size_override("font_size", 28)
	GameState.style_button(b, Color(0.24, 0.42, 0.72))
	b.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		GameState.change_scene("res://scenes/story_select.tscn"))
	body.add_child(b)
