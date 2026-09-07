extends Control
## 展開図マスター ― この 展開図は どの 立体に なる?
##
## 中学受験で 出てくる 展開図(立方体 3 とおり・直方体・三角柱・六角柱・
## 四角錐・正四面体・正八面体・円柱・円錐)を 1 つずつ 当てる。
##
## ★ 当たっても はずれても、展開図が 立ち上がって 立体に なる ところを 見せる。
##   「どこが どの 面に なるか」は 動いて いる ところを 見ないと 分からない ―
##   まちがえた ときこそ 見せたい ので、正解のときだけ 見せる 作りには しない。
##
## 折り上がりが ほんとうに 閉じるかは tests/net_check.gd が 見張っている。

const HEAD := Color(1.0, 0.88, 0.45)
const BG := Color(0.09, 0.12, 0.21)
const CARD := Color(0.19, 0.24, 0.36)

const RUN_LENGTH := 10         # 挑戦 10問

var nets: Array = []
var idx := -1                  # -1 = 一覧
## 「挑戦 10問」の 出題ぶん。空なら 1 問ずつの 練習。
## 中みは {"i": 展開図の 番号, "rev": 逆向きか}
var run_ids: Array = []
var run_at := 0
var run_ok := 0
## いまの 問いが 逆向き(立体を 見せて 展開図を えらぶ)か
var reverse := false
## 一覧から 出す ときの むき。切りかえると 見本の 絵も 立体に かわる
var list_reverse := false
var view: NetView
var choice_box: GridContainer
var result_label: RubyLabel
var next_btn: Button
var answered := false
var root: VBoxContainer


func _ready() -> void:
	GameState.play_bgm("map")
	nets = NetDefs.all()
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build_list()


# =========================================================
# 一覧
# =========================================================

func _build_list() -> void:
	idx = -1
	_reset_root()
	_head("展開図マスター  %d / %d" % [_done_count(), nets.size()],
		func() -> void: GameState.change_scene("res://scenes/main.tscn"), "もどる")

	var lead := RubyLabel.new()
	lead.font_size = 21
	lead.ruby_size = 11
	lead.color = Color(0.80, 0.86, 1.0)
	lead.custom_minimum_size = Vector2(0, 56)
	lead.set_ruby_text(("この 立体の 展開図は どれ? えらんだら、その 展開図が "
		+ "立ち上がります。") if list_reverse else
		("この 展開図は どの 立体に なる? 当てたら、"
		+ "その場で 立ち上がって 立体に なります。"), true)
	root.add_child(lead)
	root.add_child(_flip_button())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	DragScroll.attach(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	# 一覧の 上に 2 つ。どちらも 買った 人だけ。
	# 1 問ずつの 練習は 買わなくても できるので、何が 開くのかは 伝わる
	list.add_child(_run_card(true))
	list.add_child(_run_card(false))
	for i in nets.size():
		list.add_child(_card(i))


## 一覧の むきを 切りかえる。
## ★ 逆向きの ときは 見本を 立体の 絵に する ―― 展開図の まま 出すと
##   カードを 見た だけで 答えが 分かって しまう
func _flip_button() -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 64)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	GameState.style_button(btn, Color(0.30, 0.34, 0.48))
	btn.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		list_reverse = not list_reverse
		_build_list())
	var lbl := RubyLabel.new()
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.font_size = 22
	lbl.ruby_size = 11
	lbl.center = true
	lbl.color = Color(1, 1, 1, 0.95)
	lbl.set_ruby_text(("むきを かえる ▶ いまは 立体 → 展開図") if list_reverse
		else ("むきを かえる ▶ いまは 展開図 → 立体"), true)
	btn.add_child(lbl)
	return btn


## 挑戦 10問(quiz = true)… 101 とおりから ランダムに 10 問、どの 立体に なるか
## 応用 10問(quiz = false)… 展開図に つながる 数の 問題を 10 問
func _run_card(quiz: bool) -> Button:
	var open := GameState.net_runs_open()
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 108)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	var col_on := Color(0.62, 0.42, 0.18) if quiz else Color(0.30, 0.40, 0.62)
	GameState.style_button(btn, col_on if open else col_on.darkened(0.45))
	btn.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		if not open:
			GameState.change_scene("res://scenes/store.tscn")
		elif quiz:
			_start_run()
		else:
			GameState.mode = "net"
			GameState.change_scene("res://scenes/problem.tscn"))
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16.0
	row.offset_right = -16.0
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	btn.add_child(row)
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(Icons.crown(48.0, Color(1, 1, 1, 0.95)) if quiz
		else Icons.timer(48.0, Color(1, 1, 1, 0.95)))
	row.add_child(holder)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	var t1 := RubyLabel.new()
	t1.font_size = 26
	t1.ruby_size = 12
	t1.color = Color(1, 1, 1, 0.97)
	t1.set_ruby_text("挑戦 10問" if quiz else "応用 10問", true)
	col.add_child(t1)
	var t2 := RubyLabel.new()
	t2.font_size = 19
	t2.ruby_size = 10
	t2.color = Color(1.0, 0.92, 0.78)
	var sub := ""
	if quiz:
		sub = "%d とおりから 10 問。どの 立体に なる?" % nets.size()
		if GameState.net_quiz_best > 0:
			sub += "  自己ベスト %d 問" % GameState.net_quiz_best
	else:
		sub = "展開図の 問題を 10 問 つづけて"
		if GameState.net_challenge_best > 0:
			sub += "  自己ベスト %d点" % GameState.net_challenge_best
	t2.set_ruby_text(sub, true)
	col.add_child(t2)
	if not open:
		var mark := CenterContainer.new()
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.custom_minimum_size = Vector2(56, 0)
		mark.add_child(Icons.lock(38.0, Color(1, 1, 1, 0.8)))
		row.add_child(mark)
	return btn


## 挑戦 10問を はじめる。101 とおりから かぶらないように 10 問 えらび、
## 「展開図 → 立体」と「立体 → 展開図」を かわりばんこに 出す
func _start_run() -> void:
	var pool: Array = []
	for i in nets.size():
		pool.append(i)
	pool.shuffle()
	run_ids = []
	for k in mini(RUN_LENGTH, pool.size()):
		run_ids.append({"i": int(pool[k]), "rev": k % 2 == 1})
	run_at = 0
	run_ok = 0
	_open_run_item()


func _open_run_item() -> void:
	var item: Dictionary = run_ids[run_at]
	_build_quiz(int(item["i"]), bool(item["rev"]))


func _card(i: int) -> Button:
	var net: Dictionary = nets[i]
	var locked := GameState.net_needs_purchase(i)
	var done := GameState.net_clear.has(String(net["id"]))
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 132)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	GameState.style_button(btn, CARD.darkened(0.25) if locked else
		(CARD.lightened(0.10) if done else CARD))
	btn.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		if locked:
			GameState.change_scene("res://scenes/store.tscn")
		else:
			_build_quiz(i, list_reverse))

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14.0
	row.offset_right = -14.0
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	btn.add_child(row)

	# 見本。むきに よって 展開図か 立体か を 出す(答えが 見えないように)
	var mini := NetView.new()
	mini.custom_minimum_size = Vector2(148, 104)
	mini.modulate = Color(1, 1, 1, 0.35) if locked else Color(1, 1, 1, 1)
	row.add_child(mini)
	if list_reverse:
		mini.show_solid(net, false, true)
	else:
		mini.show_net(net, true)

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	var name_lbl := RubyLabel.new()
	name_lbl.font_size = 26
	name_lbl.ruby_size = 12
	name_lbl.color = Color(1, 1, 1, 0.95)
	name_lbl.set_ruby_text("その %d" % (i + 1), true)
	col.add_child(name_lbl)
	# ★ 一覧に「長方形 3 枚と 三角形 2 枚」のような 中みを 出さない ―
	#   それだけで 答えが 分かって しまう。答えた あとに 出す
	var state := RubyLabel.new()
	state.font_size = 19
	state.ruby_size = 10
	state.color = Color(0.78, 0.85, 1.0)
	state.set_ruby_text("できた" if done else ("買うと あそべます" if locked else "まだ"),
		true)
	col.add_child(state)

	var mark := CenterContainer.new()
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.custom_minimum_size = Vector2(60, 0)
	row.add_child(mark)
	if locked:
		mark.add_child(Icons.lock(40.0, Color(1, 1, 1, 0.7)))
	elif done:
		mark.add_child(Icons.star(40.0, HEAD))
	return btn


func _done_count() -> int:
	var n := 0
	for net in nets:
		if GameState.net_clear.has(String(net["id"])):
			n += 1
	return n


# =========================================================
# クイズ
# =========================================================

## rev = false … 展開図を 見せて「どの 立体に なる?」
## rev = true  … 立体を 見せて「この 立体の 展開図は どれ?」
func _build_quiz(i: int, rev := false) -> void:
	idx = i
	reverse = rev
	answered = false
	_reset_root()
	var net: Dictionary = nets[i]
	var head_text := "その %d" % (i + 1)
	if not run_ids.is_empty():
		head_text = "挑戦 10問  %d / %d" % [run_at + 1, run_ids.size()]
	_head(head_text, func() -> void:
		run_ids = []
		_build_list(), "一覧へ")

	var q := RubyLabel.new()
	q.font_size = 25
	q.ruby_size = 12
	q.color = Color(0.92, 0.96, 1.0)
	q.custom_minimum_size = Vector2(0, 40)
	q.set_ruby_text("この 立体の 展開図は どれ?" if rev
		else "この 展開図は どの 立体に なる?", true)
	root.add_child(q)

	view = NetView.new()
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(view)
	if rev:
		view.show_solid(net)
	else:
		view.show_net(net)
	view.folded.connect(_on_folded)

	result_label = RubyLabel.new()
	result_label.font_size = 24
	result_label.ruby_size = 12
	result_label.color = HEAD
	result_label.custom_minimum_size = Vector2(0, 62)
	root.add_child(result_label)

	choice_box = GridContainer.new()
	choice_box.columns = 2
	choice_box.add_theme_constant_override("h_separation", 10)
	choice_box.add_theme_constant_override("v_separation", 10)
	root.add_child(choice_box)
	if rev:
		for cand in _net_choices(i):
			choice_box.add_child(_net_choice_button(cand as Dictionary,
				String(net["id"])))
	else:
		for name_str in _choices(net):
			choice_box.add_child(_choice_button(String(name_str), String(net["solid"])))

	next_btn = Button.new()
	next_btn.text = "つぎへ"
	next_btn.custom_minimum_size = Vector2(0, 76)
	next_btn.add_theme_font_size_override("font_size", 27)
	next_btn.focus_mode = Control.FOCUS_NONE
	next_btn.visible = false
	GameState.style_button(next_btn, Color(0.24, 0.52, 0.42))
	next_btn.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		if not run_ids.is_empty():
			run_at += 1
			if run_at < run_ids.size():
				_open_run_item()
			else:
				_build_run_result()
		elif idx + 1 < nets.size() and not GameState.net_needs_purchase(idx + 1):
			_build_quiz(idx + 1, list_reverse)
		else:
			_build_list())
	root.add_child(next_btn)


## 正しい 名まえ 1 つと、まぎらわしい 名まえ 3 つ
func _choices(net: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var correct := String(net["solid"])
	var pool: Array = NetDefs.solid_names().filter(func(n): return String(n) != correct)
	var out: Array = [correct]
	while out.size() < 4 and not pool.is_empty():
		out.append(pool.pop_at(rng.randi_range(0, pool.size() - 1)))
	# 場所で 覚えられないよう、ならびを まぜる
	for i in range(out.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out


## 逆向きの 選択肢。正しい 展開図 1 つと、**ちがう 立体の** 展開図 3 つ。
## ★ 同じ 立体の べつの 展開図を まぜては いけない ―― 立方体の 展開図は
##   11 とおり あるので、どれも 正解に なって しまう
func _net_choices(correct_i: int) -> Array:
	var correct: Dictionary = nets[correct_i]
	var by_solid := {}
	for n in nets:
		var row: Dictionary = n
		if String(row["solid"]) == String(correct["solid"]):
			continue
		var key := String(row["solid"])
		if not by_solid.has(key):
			by_solid[key] = []
		(by_solid[key] as Array).append(row)
	var names: Array = by_solid.keys()
	names.shuffle()
	var out: Array = [correct]
	for key in names:
		if out.size() >= 4:
			break
		var group: Array = by_solid[key]
		out.append(group[randi() % group.size()])
	out.shuffle()
	return out


func _net_choice_button(net: Dictionary, correct_id: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 150)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.set_meta("key", String(net["id"]))
	GameState.style_button(btn, Color(0.26, 0.36, 0.54))
	var mini := NetView.new()
	mini.set_anchors_preset(Control.PRESET_FULL_RECT)
	mini.offset_left = 8.0
	mini.offset_top = 8.0
	mini.offset_right = -8.0
	mini.offset_bottom = -8.0
	btn.add_child(mini)
	mini.show_net(net, true)
	btn.pressed.connect(func() -> void:
		_answer(btn, String(net["id"]), correct_id))
	return btn


func _choice_button(name_str: String, correct: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 82)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.set_meta("key", name_str)
	GameState.style_button(btn, Color(0.26, 0.36, 0.54))
	# ★ CenterContainer に 入れない。RubyLabel は 最小の 横はばを 出さないので、
	#   入れると はばが 0 に なり「四角錐」が「四 / 角錐」と 1 文字ずつ 折れる。
	#   ボタンいっぱいに 広げて、ラベル自身に まん中ぞろえ させる
	var lbl := RubyLabel.new()
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.font_size = 26
	lbl.ruby_size = 12
	lbl.center = true
	lbl.color = Color(1, 1, 1, 0.97)
	lbl.set_ruby_text(name_str, true)
	btn.add_child(lbl)
	btn.pressed.connect(func() -> void: _answer(btn, name_str, correct))
	return btn


func _answer(btn: Button, picked: String, correct: String) -> void:
	if answered:
		return
	answered = true
	var ok := picked == correct
	GameState.play_sfx("correct" if ok else "fail")
	# えらんだ ものと、正しい ものの 両方に 色を つける。
	# まちがえた とき、どれが 正しかったのかが 分からないと 学べない。
	# ★ disabled に しない ―― style_button は disabled の 見た目を 変えないので、
	#   ぜんぶ 灰色に なって「どれが 正しかったか」が 消えて しまう。
	#   2 回目の 答えは answered で 止めている
	for c in choice_box.get_children():
		var b := c as Button
		if _key_of(b) == correct:
			GameState.style_button(b, Color(0.24, 0.55, 0.36))
		elif b == btn:
			GameState.style_button(b, Color(0.58, 0.28, 0.32))
		else:
			GameState.style_button(b, Color(0.20, 0.24, 0.32))
	var net: Dictionary = nets[idx]
	if ok:
		run_ok += 1
		GameState.record_net_clear(String(net["id"]))
	var name_str := String(net["solid"])
	if ok:
		result_label.set_ruby_text("せいかい! %s。 立ち上がる ところを 見てみよう。"
			% name_str, true)
	else:
		# ★ まちがえても 折り上がりを 見せる。ここが いちばん 分かる ところ
		result_label.set_ruby_text("ざんねん。正しくは %s。 立ち上がる ところを 見てみよう。"
			% (name_str if not reverse else "この 中の 1 つ"), true)
	# 逆向きの ときは 立体を 見せていたので、正しい 展開図に もどしてから 立ち上げる
	if reverse:
		view.show_net(net)
	view.fold_up()


## その ボタンが あらわす もの(前向き = 立体の 名まえ / 逆向き = 展開図の id)
func _key_of(btn: Button) -> String:
	if btn.has_meta("key"):
		return String(btn.get_meta("key"))
	return _text_of(btn)


## ボタンに 出ている 名まえ(ふりがな を のぞいた ぶん)
func _text_of(btn: Button) -> String:
	for c in btn.get_children():
		if c is RubyLabel:
			return (c as RubyLabel).plain
	return ""


func _on_folded() -> void:
	next_btn.visible = true
	var net: Dictionary = nets[idx]
	if not run_ids.is_empty():
		next_btn.text = "つぎへ" if run_at + 1 < run_ids.size() else "けっかを 見る"
	elif idx + 1 < nets.size() and GameState.net_needs_purchase(idx + 1):
		next_btn.text = "一覧へ"
	result_label.set_ruby_text("%s に なった。%s" % [String(net["solid"]),
		String(net["hint"])], true)


## 挑戦 10問の けっか
func _build_run_result() -> void:
	var total := run_ids.size()
	var got := run_ok
	var best := GameState.record_net_quiz(got)
	run_ids = []
	_reset_root()
	_head("挑戦 10問の けっか", func() -> void: _build_list(), "一覧へ")
	var box := VBoxContainer.new()
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	root.add_child(box)
	var crown := CenterContainer.new()
	crown.add_child(Icons.crown(96.0, HEAD if got >= total else Color(0.55, 0.62, 0.76)))
	box.add_child(crown)
	var big := RubyLabel.new()
	big.font_size = 40
	big.ruby_size = 18
	big.center = true
	big.color = HEAD
	big.set_ruby_text("%d 問の うち %d 問 せいかい" % [total, got], true)
	box.add_child(big)
	var sub := RubyLabel.new()
	sub.font_size = 24
	sub.ruby_size = 12
	sub.center = true
	sub.color = Color(0.85, 0.9, 1.0)
	var msg := "自己ベスト %d 問" % GameState.net_quiz_best
	if best:
		msg = "自己ベスト こうしん! %d 問" % GameState.net_quiz_best
	sub.set_ruby_text(msg, true)
	box.add_child(sub)
	var again := Button.new()
	again.text = "もういちど"
	again.custom_minimum_size = Vector2(0, 76)
	again.add_theme_font_size_override("font_size", 27)
	again.focus_mode = Control.FOCUS_NONE
	GameState.style_button(again, Color(0.62, 0.42, 0.18))
	again.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		_start_run())
	root.add_child(again)
	var back := Button.new()
	back.text = "一覧へ"
	back.custom_minimum_size = Vector2(0, 70)
	back.add_theme_font_size_override("font_size", 25)
	back.focus_mode = Control.FOCUS_NONE
	GameState.style_button(back, Color(0.28, 0.32, 0.44))
	back.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		_build_list())
	root.add_child(back)


# =========================================================
# 画面づくりの 共通ぶん
# =========================================================

func _reset_root() -> void:
	if root != null and is_instance_valid(root):
		# queue_free は つぎの コマまで のこる。その 1 コマの あいだ
		# 古い ボタンが 見えたり 押せたり しないように、先に 消して 止める
		root.visible = false
		root.process_mode = Node.PROCESS_MODE_DISABLED
		root.queue_free()
	var ins := GameState.safe_insets()
	root = VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_top = 16.0 + float(ins["top"])
	root.offset_left = 20.0
	root.offset_right = -20.0
	root.offset_bottom = -14.0 - float(ins["bottom"])
	root.add_theme_constant_override("separation", 10)
	add_child(root)


func _head(title_text: String, on_back: Callable, back_text: String) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	root.add_child(head)
	var back := Button.new()
	back.text = back_text
	back.custom_minimum_size = Vector2(150, 64)
	back.add_theme_font_size_override("font_size", 25)
	back.focus_mode = Control.FOCUS_NONE
	GameState.style_button(back, Color(0.28, 0.32, 0.44))
	back.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		on_back.call())
	head.add_child(back)
	var title := RubyLabel.new()
	title.font_size = 30
	title.ruby_size = 14
	title.color = HEAD
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.set_ruby_text("  " + title_text, true)
	head.add_child(title)
