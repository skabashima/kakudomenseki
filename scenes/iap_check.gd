extends Control
## 課金の しらべ 画面(解放画面の 題を 7 回 たたくと 出る)。
## 課金は 実機でしか 動かず、うまくいかないときも 静かに 失敗する。
## ストアと どこまで 話せているのかを、その場で 見えるようにする。
##   ・プラグインを 見つけたか / ストアに 接続できたか
##   ・商品を ストアが 返したか ← 「SKU not found」は ここが 空のとき
##   ・直近の 失敗コードと、起動からの 記録
## 「文を コピーする」で 全部を クリップボードに 入れられる(そのまま 送れる)。

var body: VBoxContainer
var scroll: ScrollContainer


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.1, 0.16)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var ins := GameState.safe_insets()

	var back := Button.new()
	back.text = "← もどる"
	back.position = Vector2(20, 16 + float(ins["top"]))
	back.size = Vector2(190, 68)
	back.add_theme_font_size_override("font_size", 30)
	GameState.style_button(back, Color(0.32, 0.37, 0.5))
	back.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		GameState.change_scene("res://scenes/store.tscn"))
	add_child(back)

	var title := Label.new()
	title.text = "課金の しらべ"
	title.position = Vector2(230, 24 + float(ins["top"]))
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	add_child(title)

	scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 100.0 + float(ins["top"])
	scroll.offset_left = 20.0
	scroll.offset_right = -20.0
	scroll.offset_bottom = -16.0 - float(ins["bottom"])
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	DragScroll.attach(scroll)

	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)

	if Iap.has_signal("price_ready"):
		Iap.price_ready.connect(func(_t: String) -> void: _build())
	if Iap.has_signal("purchase_done"):
		Iap.purchase_done.connect(func(_ok: bool, _msg: String) -> void: _build())
	if Iap.has_signal("restore_done"):
		Iap.restore_done.connect(func(_ok: bool) -> void: _build())
	_build()


## 画面を 組み直す(調べ直すたびに 呼ぶ)
func _build() -> void:
	if body == null or not is_instance_valid(body):
		return
	for c in body.get_children():
		c.queue_free()
	var rep: Dictionary = Iap.debug_report()
	var want: Dictionary = Iap.debug_expected_names()

	_verdict(rep)

	_head("いま どうなっているか")
	_row("OS", str(rep.get("os", "")))
	_row("つなぎ先", str(rep.get("platform", "")))
	_row("ストアと 接続", "できている" if rep.get("connected", false) else "できていない")
	_row("買える 状態か", "はい" if rep.get("has_store", false) else "いいえ")
	_row("商品ID", str(rep.get("product_id", "")))
	_row("価格", "%s(%s)" % [str(rep.get("price", "")),
		"ストアから 取れた" if rep.get("price_live", false) else "既定値。ストアから 取れていない"])
	_row("解放ずみ", "はい" if rep.get("premium", false) else "いいえ")
	var le: Dictionary = rep.get("last_error", {})
	if not le.is_empty():
		_row("直近の 失敗", "%s / %s" % [str(le.get("code", "")), str(le.get("message", ""))])

	# プラグインが 無い PC では 全部「無い」に なって 読みづらいので 出さない
	if str(rep.get("platform", "")) != "(スタブ)":
		_head("プラグインの 名前あわせ")
		var methods: Array = Array(rep.get("methods", []))
		var sigs: Array = Array(rep.get("signals", []))
		for nm in Array(want.get("methods", [])):
			_row("めそっど " + str(nm), "ある" if str(nm) in methods else "★無い")
		for nm in Array(want.get("signals", [])):
			_row("しぐなる " + str(nm), "ある" if str(nm) in sigs else "★無い")

	_head("記録(あたらしい順)")
	var lines: Array = Array(rep.get("log", []))
	lines.reverse()
	if lines.is_empty():
		_row("", "まだ 何も ありません")
	for l in lines:
		_row("", str(l))

	_buttons()


## いちばん上に、いま 何が 起きているのかの 見立てを 出す
func _verdict(rep: Dictionary) -> void:
	var msg := ""
	var col := Color(0.45, 1.0, 0.6)
	if str(rep.get("platform", "")) == "(スタブ)":
		msg = "この 端末には ストアが ありません(PC版・エディタ)。実機で 見てください。"
		col = Color(0.75, 0.8, 0.9)
	elif not rep.get("connected", false):
		msg = "ストアに つながっていません。通信を 確かめて、もう一度 調べてください。"
		col = Color(1.0, 0.6, 0.5)
	elif not rep.get("price_live", false):
		msg = "ストアが 商品を 返していません。アプリ側では なく、" \
			+ "App Store Connect / Play Console の 商品が まだ 使える 状態に " \
			+ "なっていないのが 原因です(審査待ち・未公開・国や 価格の 設定など)。"
		col = Color(1.0, 0.8, 0.4)
	elif rep.get("premium", false):
		msg = "商品も 取れていて、解放ずみです。問題ありません。"
	else:
		msg = "商品は ストアから 取れています。購入できる はずです。"
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel",
		GameState.flat_style(Color(0.16, 0.2, 0.31, 0.95), 12))
	var l := Label.new()
	l.text = msg
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", col)
	p.add_child(l)
	body.add_child(p)


func _head(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 27)
	l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	body.add_child(l)


func _row(name: String, value: String) -> void:
	var l := Label.new()
	l.text = value if name == "" else "%s: %s" % [name, value]
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	body.add_child(l)


func _buttons() -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	body.add_child(row)
	_button(row, "もう一度 調べる", Color(0.3, 0.36, 0.5), func() -> void:
		if Iap.has_method("query_price"):
			Iap.query_price()
		_build())
	_button(row, "購入を ためす", Color(0.78, 0.55, 0.15), func() -> void:
		if Iap.has_method("purchase"):
			Iap.purchase())
	_button(row, "購入を 復元する", Color(0.3, 0.36, 0.5), func() -> void:
		if Iap.has_method("restore"):
			Iap.restore())
	_button(row, "文を コピーする", Color(0.26, 0.44, 0.38), func() -> void:
		DisplayServer.clipboard_set(report_text())
		_toast("コピーしました"))


func _button(parent: Node, text: String, color: Color, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(
		minf(620.0, get_viewport_rect().size.x - 60.0), 74)
	b.add_theme_font_size_override("font_size", 25)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_NONE
	GameState.style_button(b, color)
	b.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		cb.call())
	parent.add_child(b)


## 送ってもらう ための 文(クリップボード用)
func report_text() -> String:
	var rep: Dictionary = Iap.debug_report()
	var out: Array = ["図形ハンター 課金のしらべ"]
	for k in ["os", "platform", "connected", "has_store", "product_id",
			"price", "price_live", "premium", "last_error"]:
		out.append("%s: %s" % [k, str(rep.get(k, ""))])
	out.append("--- 記録 ---")
	for l in Array(rep.get("log", [])):
		out.append(str(l))
	return "\n".join(PackedStringArray(out))


func _toast(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", Color(0.45, 1.0, 0.6))
	l.position = Vector2(get_viewport_rect().size.x * 0.5 - 110.0,
		get_viewport_rect().size.y - 130.0)
	add_child(l)
	var t := create_tween()
	t.tween_interval(1.2)
	t.tween_callback(l.queue_free)
