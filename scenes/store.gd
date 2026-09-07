extends Control
## 解放画面(買い切り 1 商品)。すべての課金導線はここに合流する。
## ストアプラグインが無い環境(PC/エディタ)では Iap がスタブになり、購入はできない。

var status: Label
var buy_btn: Button
var restore_btn: Button


func _ready() -> void:
	GameState.play_bgm("map")
	var bg := ColorRect.new()
	bg.color = Color(0.11, 0.13, 0.22)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var ins := GameState.safe_insets()
	var portrait := get_viewport_rect().size.x < 1400.0

	var back := Button.new()
	back.text = "← もどる"
	back.position = Vector2(20, 16 + float(ins["top"]))
	back.size = Vector2(190, 68)
	back.add_theme_font_size_override("font_size", 30)
	GameState.style_button(back, Color(0.32, 0.37, 0.5))
	back.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		GameState.change_scene("res://scenes/main.tscn"))
	add_child(back)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 100.0 + float(ins["top"])
	scroll.offset_left = 24.0
	scroll.offset_right = -24.0
	scroll.offset_bottom = -16.0 - float(ins["bottom"])
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	DragScroll.attach(scroll)   # 実機で指でなぞってスクロールできるように

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)

	# 題は ボタン。7 回 つづけて たたくと「課金の しらべ」が 開く。
	# (実機で 買えないと 言われたとき、その場で 中を 見るため。見た目は 文字のまま)
	var title := Button.new()
	title.text = "全ステージを解放"
	title.flat = true
	title.focus_mode = Control.FOCUS_NONE
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	title.add_theme_color_override("font_hover_color", Color(1.0, 0.85, 0.35))
	title.add_theme_color_override("font_pressed_color", Color(1.0, 0.85, 0.35))
	title.pressed.connect(_on_title_tap)
	v.add_child(title)

	var paid := GameState.paid_stage_count()
	var lead := Label.new()
	lead.text = "残り %d ステージが すべて 遊べるようになります" % paid
	lead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lead.add_theme_font_size_override("font_size", 24)
	lead.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	v.add_child(lead)

	# 買うと何が増えるか
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",
		GameState.flat_style(Color(0.16, 0.2, 0.31, 0.95), 14))
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 8)
	panel.add_child(pv)
	for line in [
		"・角度編 %d + 面積編 %d ステージ(中学・高校・大学受験)" % [
			(ProblemGen.COURSES[0]["stages"] as Array).size(),
			(ProblemGen.COURSES[1]["stages"] as Array).size()],
		"・全ステージの「挑戦 10問」(1 問ごとに解法が変わる難度ラダー)と王冠",
		"・チャレンジの全コースタイムアタック / サバイバル",
		"・展開図マスター全 %d 問(展開図が立ち上がって立体になるアニメつき)" % 			NetDefs.all().size(),
		"・買い切り。追加の課金や広告はありません",
	]:
		var l := Label.new()
		l.text = String(line)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 23)
		l.add_theme_color_override("font_color", Color(0.88, 0.93, 1.0))
		pv.add_child(l)
	v.add_child(panel)

	var free_note := Label.new()
	free_note.text = "※ 各編の最初の %d ステージと、電卓・解き方アニメ・補助線・" % \
		GameState.FREE_STAGES_PER_COURSE + "ヒント・段位・記録は無料のままです。"
	free_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	free_note.add_theme_font_size_override("font_size", 20)
	free_note.add_theme_color_override("font_color", Color(0.68, 0.75, 0.88))
	v.add_child(free_note)

	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 22)
	status.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	v.add_child(status)

	buy_btn = Button.new()
	buy_btn.custom_minimum_size = Vector2(
		minf(620.0, get_viewport_rect().size.x - 60.0), 96)
	buy_btn.add_theme_font_size_override("font_size", 30 if portrait else 34)
	buy_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameState.style_button(buy_btn, Color(0.78, 0.55, 0.15))
	buy_btn.pressed.connect(_on_buy)
	v.add_child(buy_btn)

	restore_btn = Button.new()
	restore_btn.text = "購入を復元する"
	restore_btn.custom_minimum_size = Vector2(
		minf(620.0, get_viewport_rect().size.x - 60.0), 76)
	restore_btn.add_theme_font_size_override("font_size", 26)
	restore_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameState.style_button(restore_btn, Color(0.3, 0.36, 0.5))
	restore_btn.pressed.connect(_on_restore)
	v.add_child(restore_btn)

	var later := Button.new()
	later.text = "あとで"
	later.custom_minimum_size = Vector2(
		minf(620.0, get_viewport_rect().size.x - 60.0), 70)
	later.add_theme_font_size_override("font_size", 24)
	later.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	GameState.style_button(later, Color(0.26, 0.29, 0.38))
	later.pressed.connect(func() -> void:
		GameState.play_sfx("tap")
		GameState.change_scene("res://scenes/main.tscn"))
	v.add_child(later)

	# ストアからの通知を受ける
	if Iap.has_signal("price_ready"):
		Iap.price_ready.connect(func(_t: String) -> void: _refresh())
	if Iap.has_signal("purchase_done"):
		Iap.purchase_done.connect(_on_purchase_done)
	if Iap.has_signal("restore_done"):
		Iap.restore_done.connect(_on_restore_done)
	if Iap.has_method("query_price"):
		Iap.query_price()
	_refresh()


func _refresh() -> void:
	if GameState.premium:
		buy_btn.text = "解放ずみ"
		buy_btn.disabled = true
		restore_btn.visible = false
		status.text = "ありがとうございます。全ステージが遊べます。"
		return
	buy_btn.disabled = false
	buy_btn.text = "全ステージを解放する  %s" % _price()
	if not _store_ready():
		status.text = "この端末ではストアに接続できません(PC版では購入できません)。"


func _price() -> String:
	if Iap.has_method("price_text"):
		return String(Iap.price_text())
	return "¥500"


func _store_ready() -> bool:
	return Iap.has_method("has_store") and bool(Iap.has_store())


func _on_buy() -> void:
	GameState.play_sfx("tap")
	if not _store_ready():
		status.text = "この端末ではストアに接続できません(PC版では購入できません)。"
		return
	status.text = "ストアに接続しています…"
	Iap.purchase()


func _on_restore() -> void:
	GameState.play_sfx("tap")
	if not _store_ready():
		status.text = "この端末ではストアに接続できません(PC版では購入できません)。"
		return
	status.text = "購入を確認しています…"
	Iap.restore()


func _on_purchase_done(ok: bool, msg: String) -> void:
	if ok:
		GameState.play_sfx("clear")
		status.text = "解放しました。ありがとうございます!"
	else:
		status.text = "購入できませんでした: %s" % msg
	_refresh()


func _on_restore_done(ok: bool) -> void:
	status.text = "購入を復元しました。" if ok else "復元できる購入が見つかりませんでした。"
	_refresh()


# ══════════ かくしコマンド: 題を 7 回 たたく ══════════
const CHECK_TAPS := 7          # 何回で 開くか
const TAP_GAP := 1.5           # つづけて とみなす 間(秒)

var _taps := 0
var _last_tap := -100.0


func _on_title_tap() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_taps = (_taps + 1) if now - _last_tap <= TAP_GAP else 1
	_last_tap = now
	if _taps >= CHECK_TAPS:
		_taps = 0
		GameState.play_sfx("clear")
		GameState.change_scene("res://scenes/iap_check.tscn")
		return
	if _taps >= 4 and status != null:
		status.text = "課金の しらべ まで あと %d 回" % (CHECK_TAPS - _taps)
