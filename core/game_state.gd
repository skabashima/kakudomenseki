extends Node
## 進捗・セーブ・得点・共通テーマを管理するオートロード。

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

## stage_id -> 獲得スター数 (1-3)。クリア済みの判定にも使う。
var stars: Dictionary = {}
## stage_id -> そのステージの自己ベスト得点
var scores: Dictionary = {}
## 連続正解数(セーブしない。アプリを閉じるとリセット)
var combo: int = 0
## 連続正解の自己ベスト
var best_combo: int = 0
## 累計カウンタ("clear" "perfect" "no_hint" など)
var stats: Dictionary = {}
## チャレンジの自己ベスト: "time:e" -> 正解数 / "survival" -> 連続数
var challenge_best: Dictionary = {}
## デバッグ: すべてのステージを解放する
var debug_unlock_all: bool = false

## いま遊ぶコースID("e" / "j" / "s")とステージ index
var current_course: String = "e"
var current_stage: int = 0
## 問題画面のモード: "normal"(ステージ攻略) / "time"(タイムアタック) / "survival"
var mode: String = "normal"
## チャレンジで出題するコース("all" なら全コース)
var challenge_course: String = "all"

## 段位(総得点のしきい値の低い順)
const RANKS := [
	{"score": 0, "name": "見習い"},
	{"score": 2000, "name": "図形たんけん隊"},
	{"score": 6000, "name": "角度ハンター"},
	{"score": 14000, "name": "面積マイスター"},
	{"score": 30000, "name": "図形の達人"},
	{"score": 60000, "name": "図形仙人"},
]

## 1 ステージはこの問数の連続正解ミッション
const QUESTIONS_PER_STAGE := 3
## ステージ開始時のハート(まちがえると 1 つ減る。残った数がそのまま★になる)
const START_HEARTS := 3


func total_score() -> int:
	var t := 0
	for k in scores:
		t += int(scores[k])
	return t


func rank_name() -> String:
	var t := total_score()
	var rname := String(RANKS[0]["name"])
	for r in RANKS:
		if t >= int(r["score"]):
			rname = String(r["name"])
	return rname


## 次の段位まであと何点か([次の段位名, 残り点]。最高位なら ["", 0])
func next_rank_gap() -> Array:
	var t := total_score()
	for r in RANKS:
		if t < int(r["score"]):
			return [String(r["name"]), int(r["score"]) - t]
	return ["", 0]


## 1 問の得点。基礎点 100 × 挑戦回数 × ヒント × 速さ × コンボ倍率
func question_score(tries: int, hints: int, seconds: float, combo_at: int) -> int:
	var try_mult := 2.0 if tries == 1 else (1.4 if tries == 2 else 1.0)
	var hint_mult := pow(0.7, hints)
	var speed_mult := 1.3 if seconds <= 15.0 else (1.15 if seconds <= 30.0 else 1.0)
	var combo_mult := minf(1.0 + 0.1 * float(combo_at), 2.0)
	return int(round(100.0 * try_mult * hint_mult * speed_mult * combo_mult))


## そのステージを遊べるか。コース内で前のステージをクリアしていれば次へ進める。
## (学年によるロックはしない。実力で進む)
func is_stage_unlocked(course_id: String, index: int) -> bool:
	if debug_unlock_all:
		return true
	if index <= 0:
		return true
	var stages: Array = ProblemGen.stages_of(course_id)
	if index >= stages.size():
		return false
	return int(stars.get(String(stages[index - 1]["id"]), 0)) > 0


## クリアを記録する。★が自己ベストを更新したら true
func record_clear(stage_id: String, earned_stars: int, score: int) -> bool:
	var improved := earned_stars > int(stars.get(stage_id, 0))
	stars[stage_id] = maxi(earned_stars, int(stars.get(stage_id, 0)))
	if score > int(scores.get(stage_id, 0)):
		scores[stage_id] = score
	save_game()
	return improved


func bump_stat(key: String, by: int = 1) -> void:
	stats[key] = int(stats.get(key, 0)) + by


## チャレンジの自己ベストを更新できたら true
func record_challenge(key: String, value: int) -> bool:
	if value <= int(challenge_best.get(key, 0)):
		return false
	challenge_best[key] = value
	save_game()
	return true


## 効果音プレイヤー (name -> AudioStreamPlayer)。音は起動時にプログラム生成する
var _sfx_players: Dictionary = {}
var _transitioning := false


func _ready() -> void:
	_apply_theme()
	_update_ui_scale()
	get_window().size_changed.connect(_update_ui_scale)
	_init_sfx()
	load_game()


func _input(event: InputEvent) -> void:
	# 指を離したら、触っていた場所に残る「選択されたような見た目」を消す。
	if event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed:
		clear_touch_highlight.call_deferred()


func clear_touch_highlight() -> void:
	## タッチはマウスとして扱われるが、指を離してもカーソルはその場に残るため、
	## 下にあるボタンがホバー表示のまま固まる。押した拍子に付くフォーカス枠も残る。
	## 画面外へマウスを動かした扱いにして解除する。
	var vp := get_viewport()
	if vp == null:
		return
	vp.gui_release_focus()
	var mm := InputEventMouseMotion.new()
	mm.position = Vector2(-10000, -10000)
	mm.global_position = mm.position
	vp.push_input(mm)


func _update_ui_scale() -> void:
	## 縦持ちでは全 UI を 1.2 倍で描く(スマホで文字が大きく読める)。
	## 横画面(デスクトップ検証)は等倍のまま
	var w := get_window()
	var f := 1.2 if w.size.y > w.size.x else 1.0
	if not is_equal_approx(w.content_scale_factor, f):
		w.content_scale_factor = f


## 検証用のセーフエリア上書き({"top": 120.0, "bottom": 80.0} など)。空なら実機の値を使う
var debug_safe_insets: Dictionary = {}


## iPhone のノッチ/ホームバー等に UI が隠れないための内側マージン(論理座標)。
## デスクトップ/Android の通常画面は全面が安全域=すべて 0
func safe_insets() -> Dictionary:
	if not debug_safe_insets.is_empty():
		return debug_safe_insets
	var d := {"top": 0.0, "bottom": 0.0}
	var win := DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return d
	var vis := get_viewport().get_visible_rect().size
	var safe := DisplayServer.get_display_safe_area()
	var sy := vis.y / float(win.y)
	d["top"] = maxf(0.0, float(safe.position.y) * sy)
	d["bottom"] = maxf(0.0, float(win.y - (safe.position.y + safe.size.y)) * sy)
	# 保険: 一部 iOS で安全域がほぼ 0 で返ることがある。縦長端末では既定値を使う
	if OS.get_name() == "iOS" and vis.y / maxf(vis.x, 1.0) > 1.9:
		if d["top"] < 20.0:
			d["top"] = vis.x * 0.15
		if d["bottom"] < 15.0:
			d["bottom"] = vis.x * 0.10
	return d


# =========================================================
# 画面遷移(フェード付き)
# =========================================================

func change_scene(path: String) -> void:
	if _transitioning:
		return
	_transitioning = true
	var layer := CanvasLayer.new()
	layer.layer = 100
	var overlay := ColorRect.new()
	overlay.color = Color(0.05, 0.07, 0.13, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(overlay)
	get_tree().root.add_child(layer)
	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 1.0, 0.09)
	await tw.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(overlay, "color:a", 0.0, 0.12)
	await tw2.finished
	layer.queue_free()
	_transitioning = false


# =========================================================
# 効果音(外部アセットなしで波形を合成)
# =========================================================

func play_sfx(sfx_name: String) -> void:
	if _sfx_players.has(sfx_name):
		_sfx_players[sfx_name].play()


func _init_sfx() -> void:
	var defs := {
		"tap": _make_tone([880.0], 0.08, 25.0),
		"type": _make_tone([1320.0], 0.05, 35.0),
		"correct": _make_jingle([523.25, 659.25, 783.99], 0.09),
		"clear": _make_jingle([523.25, 659.25, 783.99, 1046.5], 0.11),
		"star": _make_tone([1318.5], 0.22, 9.0),
		"fail": _make_jingle([233.08, 207.65], 0.22),
		"hint": _make_tone([440.0, 554.37], 0.14, 14.0),
	}
	for sfx_name in defs:
		var p := AudioStreamPlayer.new()
		# stream は生成時に一度だけ設定し、以後は play()/stop() のみ。
		# 再生中の stream 代入はオーディオスレッドと競合し Android で SIGSEGV する
		p.stream = defs[sfx_name]
		p.max_polyphony = 3
		p.volume_db = -8.0
		add_child(p)
		_sfx_players[sfx_name] = p


func _make_tone(freqs: Array, dur: float, decay: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := i / float(rate)
		var v := 0.0
		for f in freqs:
			v += sin(TAU * f * t)
		v = v / freqs.size() * exp(-decay * t) * 0.5
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	return _wav(data, rate)


func _make_jingle(freqs: Array, seg_dur: float) -> AudioStreamWAV:
	var rate := 22050
	var seg_n := int(seg_dur * rate)
	var tail := int(0.25 * rate)
	var total := seg_n * freqs.size() + tail
	var data := PackedByteArray()
	data.resize(total * 2)
	for si in freqs.size():
		var f: float = freqs[si]
		var length := seg_n + (tail if si == freqs.size() - 1 else 0)
		for i in length:
			var t := i / float(rate)
			var v := sin(TAU * f * t) * exp(-7.0 * t) * 0.45
			var idx := (si * seg_n + i) * 2
			data.encode_s16(idx, int(clampf(v, -1.0, 1.0) * 32767.0))
	return _wav(data, rate)


func _wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	return wav


func _apply_theme() -> void:
	# 同梱の Noto Sans JP を既定フォントにする。Android の OS フォントには日本語補完が
	# 効かず豆腐(□)になるため、フォント同梱が必須。少し太らせて視認性を上げる。
	# ※embolden フォントはヘッドレス描画でクラッシュするため、テストでは OS フォントを使う
	var font: Font
	if DisplayServer.get_name() != "headless":
		var fv := FontVariation.new()
		fv.base_font = load("res://assets/fonts/NotoSansJP.ttf")
		var wtag: int = TextServerManager.get_primary_interface().name_to_tag("weight")
		fv.variation_opentype = {wtag: 700}
		fv.variation_embolden = 0.3
		ThemeDB.fallback_font = fv
		var dt := ThemeDB.get_default_theme()
		if dt:
			dt.set_default_font(fv)
		font = fv
	else:
		var sysf := SystemFont.new()
		sysf.font_names = PackedStringArray([
			"Meiryo", "Yu Gothic UI", "BIZ UDGothic",
			"Noto Sans CJK JP", "Noto Sans JP", "sans-serif",
		])
		font = sysf
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 30

	# ボタン: 角丸+立体感(下辺の濃い縁+影)。押すと沈む
	theme.set_stylebox("normal", "Button", button_style(Color(0.24, 0.42, 0.72)))
	theme.set_stylebox("hover", "Button", button_style(Color(0.31, 0.51, 0.84)))
	theme.set_stylebox("pressed", "Button", pressed_style(Color(0.24, 0.42, 0.72)))
	theme.set_stylebox("disabled", "Button", flat_style(Color(0.32, 0.35, 0.43, 0.55), 16))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", Color(0.97, 0.98, 1.0))
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color(0.85, 0.9, 1.0))
	theme.set_color("font_disabled_color", "Button", Color(0.78, 0.8, 0.88, 0.6))

	# パネル: 角丸の濃紺
	var panel := flat_style(Color(0.08, 0.11, 0.19, 0.94), 20)
	panel.set_content_margin_all(20)
	theme.set_stylebox("panel", "PanelContainer", panel)

	get_window().theme = theme


func flat_style(color: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(12)
	return sb


## ボタンらしく見せるスタイル: 下辺の濃い縁(厚み)+ドロップシャドウ
func button_style(color: Color, radius := 16) -> StyleBoxFlat:
	var sb := flat_style(color, radius)
	sb.border_width_bottom = 5
	sb.border_color = color.darkened(0.4)
	sb.shadow_color = Color(0, 0, 0, 0.28)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(0, 3)
	return sb


## 押し込まれた状態: 厚みと影をなくし、少し暗く・下にずれる
func pressed_style(color: Color, radius := 16) -> StyleBoxFlat:
	var sb := flat_style(color.darkened(0.22), radius)
	sb.content_margin_top = 16
	sb.content_margin_bottom = 8
	return sb


## シーン側から特別な色のボタンを作るためのヘルパー
func style_button(btn: Button, color: Color) -> void:
	btn.add_theme_stylebox_override("normal", button_style(color))
	btn.add_theme_stylebox_override("hover", button_style(color.lightened(0.12)))
	btn.add_theme_stylebox_override("pressed", pressed_style(color))
	# 指で操作するアプリではフォーカス枠は「選ばれたまま」に見えるだけなので持たせない
	btn.focus_mode = Control.FOCUS_NONE


func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"stars": stars,
		"scores": scores,
		"best_combo": best_combo,
		"stats": stats,
		"challenge_best": challenge_best,
		"debug_unlock_all": debug_unlock_all,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	stars = data.get("stars", {})
	scores = data.get("scores", {})
	best_combo = int(data.get("best_combo", 0))
	stats = data.get("stats", {})
	challenge_best = data.get("challenge_best", {})
	debug_unlock_all = bool(data.get("debug_unlock_all", false))
