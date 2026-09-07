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
## 挑戦モード(ステージクリア後に解放)の問数。高難度バリエーション中心
const GAUNTLET_QUESTIONS := 10
## stage_id -> 挑戦モードの最高正解数(GAUNTLET_QUESTIONS でクリア=王冠)
var gauntlet_best: Dictionary = {}


## 挑戦モードの記録を更新できたら true
func record_gauntlet(stage_id: String, count: int) -> bool:
	if count <= int(gauntlet_best.get(stage_id, 0)):
		return false
	gauntlet_best[stage_id] = count
	save_game()
	return true


func total_score() -> int:
	var t := 0
	for k in scores:
		t += int(scores[k])
	return t


## 1000 の位ごとにコンマを打つ(13371 -> 13,371)。得点は桁が増えるので読みやすくする
static func comma(n: int) -> String:
	var src := str(absi(n))
	var out := ""
	var c := 0
	for i in range(src.length() - 1, -1, -1):
		out = src[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if n < 0 else "") + out


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


# ---------------------------------------------------------
# 発見モード(物語)
# ---------------------------------------------------------
## クリアした章の id
var story_clear: Dictionary = {}
## いま読んでいる章と、その中の何番目のシーンか(途中でやめても続きから)
var story_chapter: String = "ch1"
## いま遊んでいるストーリーのモード("jhs" = 中学生 / "hs" = 高校生)
var story_mode: String = "jhs"
var story_scene: int = 0


## 取った島の番号(島取り)。キーは str(番号)
var island_clear: Dictionary = {}
## 島ごとの ★(1〜3)。占有率で決まる。何度でも 挑んで 上を ねらえる
var island_star: Dictionary = {}
var island_index := 0
## 島取りの 出題の はんい("elem" / "jhs" / "hs" / "all")
var island_range := "all"


## 島を取った。はじめてなら true
func record_island_clear(i: int) -> bool:
	if island_clear.has(str(i)):
		return false
	island_clear[str(i)] = true
	save_game()
	return true


## 占有率から ★ を つける。前より 良ければ 書きかえる。はじめてなら true
func record_island_star(i: int, pct: int) -> bool:
	var star := 0
	if pct >= 85:
		star = 3
	elif pct >= 70:
		star = 2
	elif pct > 50:
		star = 1
	if star <= 0:
		return false
	var before := int(island_star.get(str(i), 0))
	if star > before:
		island_star[str(i)] = star
		save_game()
		return true
	return false


## その はんいで 集めた ★
func island_stars_in(list: Array) -> int:
	var n := 0
	for i in list:
		n += int(island_star.get(str(i), 0))
	return n


## クリアした「たからの地図」の単元 id(小学生むけ)
var kid_clear: Dictionary = {}
var kid_unit: String = "k1"

## クリアした 直後だけ 入る 単元 id。地図で「つぎの ばしょまで 歩く」ために使う
## (進みぐあいそのものではないので 保存しない)
var kid_walk_from: String = ""

## ストーリー(中学生・高校生)で 章をクリアした直後だけ入る。図で歩くために使う
var story_walk_from: String = ""


## 単元をクリアした。はじめてなら true
func record_kid_clear(id: String) -> bool:
	if kid_clear.has(id):
		return false
	kid_clear[id] = true
	save_game()
	return true


## 展開図マスターで 当てた 展開図の id
var net_clear: Dictionary = {}

## 展開図マスターの「挑戦 10問」(どの 立体に なるか)の 自己ベスト 正解数
var net_quiz_best: int = 0

## 展開図マスターの「応用 10問」(数を 答える 問題)の 自己ベスト スコア
var net_challenge_best: int = 0


## 挑戦・応用の 2 つは 買った 人だけ。
## ★ 1 問ずつの 練習(はじめの 8 問)は 買わなくても できる ―
##   ここを 閉じると 何が 開くのかが 伝わらない
func net_runs_open() -> bool:
	return premium or debug_unlock_all


## 挑戦 10問(どの 立体に なるか)を 通した。自己ベストを こえたら true
func record_net_quiz(correct: int) -> bool:
	if correct <= net_quiz_best:
		save_game()
		return false
	net_quiz_best = correct
	save_game()
	return true


## 応用 10問を クリアした。自己ベストを こえたら true
func record_net_challenge(score: int) -> bool:
	if score <= net_challenge_best:
		save_game()
		return false
	net_challenge_best = score
	save_game()
	return true


## 展開図を 当てた。はじめてなら true
func record_net_clear(id: String) -> bool:
	if net_clear.has(id):
		return false
	net_clear[id] = true
	bump_stat("net")
	save_game()
	return true


## 章をクリアした。はじめてなら true
func record_story_clear(id: String) -> bool:
	if story_clear.has(id):
		return false
	story_clear[id] = true
	# 図(story_map)で「つぎの場所まで進む」ために覚えておく(保存はしない)
	story_walk_from = id
	bump_stat("story_chapter")
	save_game()
	return true


# ---------------------------------------------------------
# 課金(買い切り 1 商品・非消費型。実処理は core/iap.gd)
# ---------------------------------------------------------
## 各編の最初の何ステージまでを無料で遊べるか
const FREE_STAGES_PER_COURSE := 4
## 購入(または復元)済みなら true。全ステージとチャレンジが解放される
var premium: bool = false
## まちがえた 問題の 覚え書き [{"s": ステージ id, "t": 段}]。
## つぎに その単元を 開いたとき、1 問めに 出す
var review: Array = []

## 今日の図形: さいごに 解いた 日(1970 年から の 日数)と れんぞく日数
var daily_day := 0
var daily_streak := 0
var daily_best := 0            # れんぞくの 最高記録

## BGM を 鳴らすか(切った 状態は 保存する)
var bgm_on: bool = true


func set_premium(v: bool) -> void:
	if premium == v:
		return
	premium = v
	save_game()


## そのステージが無料範囲か(各編の先頭 FREE_STAGES_PER_COURSE ステージ)
func is_stage_free(index: int) -> bool:
	return index < FREE_STAGES_PER_COURSE


# ---------------------------------------------------------
# ストーリーと島取りの 無料範囲
#
# 「入口だけ 無料、続きは 買い切り」に そろえる。どの 学年の 人でも
# 自分の ところを 試してから 決められるように、島取りは **はんいごとに**
# 先頭 2 島を 無料に する
# ---------------------------------------------------------

const FREE_KID_UNITS := 5              # たからのちず(小学生)の 無料の 歩
const FREE_STORY_CHAPTERS := {"jhs": 3, "hs": 2}   # ストーリー(中学生/高校生)の 無料の 章
const FREE_ISLANDS_PER_RANGE := 2      # 島取り: はんいごとに 無料の 島
const FREE_NETS := 8                   # 展開図マスター: ためせる 展開図(全 101)


## たからのちず(小学生)の その歩に 購入が 必要か
func kid_unit_needs_purchase(unit_id: String) -> bool:
	if premium or debug_unlock_all:
		return false
	return KidDefs.index_of(unit_id) >= FREE_KID_UNITS


## ストーリー(中学生/高校生)の その章に 購入が 必要か
func story_chapter_needs_purchase(mode: String, chapter_id: String) -> bool:
	if premium or debug_unlock_all:
		return false
	var free_n := int(FREE_STORY_CHAPTERS.get(mode, 3))
	return StoryDefs.chapter_index_in(StoryDefs.chapters_of(mode), chapter_id) >= free_n


## 展開図マスターの その 展開図に 購入が 必要か(やさしい 順で 何番めか で 見る)
func net_needs_purchase(index: int) -> bool:
	if premium or debug_unlock_all:
		return false
	return index >= FREE_NETS


## 島取りの その島に 購入が 必要か(はんいの 中で 何番めか で 見る)
func island_needs_purchase(i: int) -> bool:
	if premium or debug_unlock_all:
		return false
	var lv := String(IslandDefs.of(i)["level"])
	var n := 0
	for k in IslandDefs.count():
		if String(IslandDefs.of(k)["level"]) != lv:
			continue
		if k == i:
			return n >= FREE_ISLANDS_PER_RANGE
		n += 1
	return true


## 買い切りで 開く もの ぜんぶの 数(訴求の 文言に 使う)
func paid_content_count() -> Dictionary:
	var isles := 0
	for i in IslandDefs.count():
		if island_needs_purchase(i):
			isles += 1
	var kid := maxi(KidDefs.UNITS.size() - FREE_KID_UNITS, 0)
	var chap := 0
	for m in ["jhs", "hs"]:
		chap += maxi(StoryDefs.chapters_of(m).size() - int(FREE_STORY_CHAPTERS[m]), 0)
	var nets := maxi(NetDefs.all().size() - FREE_NETS, 0)
	return {"stage": paid_stage_count(), "kid": kid, "chapter": chap, "island": isles,
		"net": nets}


## そのステージを遊ぶのに購入が必要か
func needs_purchase(index: int) -> bool:
	if premium or debug_unlock_all:
		return false
	return not is_stage_free(index)


## 有料ステージの数(解放画面や訴求ボタンの文言に使う)
func paid_stage_count() -> int:
	var n := 0
	for c in ProblemGen.COURSES:
		n += maxi(0, (c["stages"] as Array).size() - FREE_STAGES_PER_COURSE)
	return n


## チャレンジ(タイムアタック/サバイバル)に購入が必要か。
## 無料で遊べるのは「タイムアタック・角度編」だけ
func challenge_needs_purchase(mode_id: String, course_id: String) -> bool:
	if premium or debug_unlock_all:
		return false
	return not (mode_id == "time" and course_id == "kaku")


## チャレンジの出題を無料ステージだけに絞るときの上限(0 なら制限なし)。
## 未購入のままでも有料ステージの問題が出てしまわないようにする
func free_stage_limit() -> int:
	return 0 if (premium or debug_unlock_all) else FREE_STAGES_PER_COURSE


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
	# 一度クリアしたステージは、あとからその前に新ステージを足しても開いたまま
	# (更新でいきなり遊べなくなると、進めていた人が困る)
	if int(stars.get(String(stages[index]["id"]), 0)) > 0:
		return true
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
	_init_bgm()
	load_game()
	_low_wanted = bool(ProjectSettings.get_setting("application/run/low_processor_mode", false))
	# 起動直後の 画面の 切りかわりが いちばん あぶない。長めに 起こしておく
	wake(90)


# ---------------------------------------------------------
# 低消費モード(電池と 発熱)
#
# 画面が 変わっていないときは 描き直さない ―― これが 効くのは
# 問題を 読んでいる あいだ など、いちばん 長い 時間。
# ただし この状態の Godot は「変わった」印が 立った 回しか 描かないので、
# 画面を 差しかえる 境目で 印が 立ち損ねると **真っ暗のまま 止まって 見える**。
# そこで 画面が 変わる ときだけ、しばらく 印なしでも 描かせる。
# ---------------------------------------------------------

const WAKE_FRAMES := 12
var _wake_left := 0
var _low_wanted := true


## しばらく ふつうに 描く(画面の 差しかえ どき)
func wake(frames: int = WAKE_FRAMES) -> void:
	_wake_left = maxi(_wake_left, frames)
	OS.low_processor_usage_mode = false
	set_process(true)


func _process(_delta: float) -> void:
	if _wake_left <= 0:
		return
	_wake_left -= 1
	if _wake_left <= 0:
		OS.low_processor_usage_mode = _low_wanted
		set_process(false)


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
	wake()                          # 差しかえの 境目は 印なしでも 描く
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


## 正解の 音。コンボが のびるほど 高い 音に する(のびている 実感)
func play_correct() -> void:
	if combo >= 6:
		play_sfx("combo3")
	elif combo >= 4:
		play_sfx("combo2")
	elif combo >= 2:
		play_sfx("combo1")
	else:
		play_sfx("correct")


func _init_sfx() -> void:
	var defs := {
		"tap": _make_tone([880.0], 0.08, 25.0),
		"type": _make_tone([1320.0], 0.05, 35.0),
		"correct": _make_jingle([523.25, 659.25, 783.99], 0.09),
		"clear": _make_jingle([523.25, 659.25, 783.99, 1046.5], 0.11),
		"star": _make_tone([1318.5], 0.22, 9.0),
		"fail": _make_jingle([233.08, 207.65], 0.22),
		"hint": _make_tone([440.0, 554.37], 0.14, 14.0),
		# --- ここから 足した 音 ---
		"combo1": _make_tone([659.25], 0.10, 22.0),      # コンボ 2〜3
		"combo2": _make_tone([783.99], 0.10, 22.0),      # コンボ 4〜5
		"combo3": _make_tone([987.77], 0.11, 20.0),      # コンボ 6 以上
		"win": _make_jingle([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.10),
		"lose": _make_jingle([392.0, 349.23, 293.66], 0.20),
		"land": _make_tone([523.25, 784.0], 0.09, 26.0),  # 島取り: 土地を 取る
		"shrine": _make_jingle([659.25, 987.77], 0.13),   # 島取り: 石碑を 取る
		"open": _make_jingle([440.0, 587.33, 880.0], 0.12),  # つぎが 開く
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
		"gauntlet_best": gauntlet_best,
		"debug_unlock_all": debug_unlock_all,
		"premium": premium,
		"bgm_on": bgm_on,
		"review": review,
		"daily_day": daily_day,
		"daily_streak": daily_streak,
		"daily_best": daily_best,
		"story_clear": story_clear,
		"kid_clear": kid_clear,
		"net_clear": net_clear,
		"net_challenge_best": net_challenge_best,
		"net_quiz_best": net_quiz_best,
		"island_clear": island_clear,
		"island_star": island_star,
		"island_range": island_range,
		"kid_unit": kid_unit,
		"story_chapter": story_chapter,
		"story_scene": story_scene,
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
	gauntlet_best = data.get("gauntlet_best", {})
	debug_unlock_all = bool(data.get("debug_unlock_all", false))
	premium = bool(data.get("premium", false))
	bgm_on = bool(data.get("bgm_on", true))
	review = data.get("review", [])
	daily_day = int(data.get("daily_day", 0))
	daily_streak = int(data.get("daily_streak", 0))
	daily_best = int(data.get("daily_best", 0))
	story_clear = data.get("story_clear", {})
	kid_clear = data.get("kid_clear", {})
	net_clear = data.get("net_clear", {})
	net_challenge_best = int(data.get("net_challenge_best", 0))
	net_quiz_best = int(data.get("net_quiz_best", 0))
	island_clear = data.get("island_clear", {})
	island_star = data.get("island_star", {})
	island_range = String(data.get("island_range", "all"))
	kid_unit = String(data.get("kid_unit", "k1"))
	story_chapter = String(data.get("story_chapter", "ch1"))
	story_scene = int(data.get("story_scene", 0))


# ---------------------------------------------------------
# まちがえた 問題を 覚えておく(復習)
#
# まちがえたまま 流れていくと、同じ ところで 何度でも つまずく。
# つぎに その単元を 開いたとき、まず それを 出す。
# ---------------------------------------------------------

const REVIEW_MAX := 40


## 今日の 分を 解いたか
func daily_done() -> bool:
	return daily_day == Daily.day_number()


## 今日の 分を 解いた。きのうから 続いていれば れんぞくを のばす
func record_daily() -> void:
	var today := Daily.day_number()
	if daily_day == today:
		return
	daily_streak = daily_streak + 1 if daily_day == today - 1 else 1
	daily_day = today
	daily_best = maxi(daily_best, daily_streak)
	bump_stat("daily")
	save_game()


func add_review(stage_id: String, tier: int) -> void:
	for r in review:
		if String(r["s"]) == stage_id and int(r["t"]) == tier:
			return                      # 同じ ものは ためない
	review.append({"s": stage_id, "t": tier})
	while review.size() > REVIEW_MAX:
		review.pop_front()
	save_game()


## その単元に たまっている 復習の 数
func review_count(stage_id: String) -> int:
	var n := 0
	for r in review:
		if String(r["s"]) == stage_id:
			n += 1
	return n


## その単元の 復習を 1 つ 見る(消さない)。無ければ -1
func peek_review(stage_id: String) -> int:
	for r in review:
		if String(r["s"]) == stage_id:
			return int(r["t"])
	return -1


## 解けたので 覚え書きから 消す
func clear_review(stage_id: String, tier: int) -> void:
	for i in range(review.size() - 1, -1, -1):
		var r: Dictionary = review[i]
		if String(r["s"]) == stage_id and int(r["t"]) == tier:
			review.remove_at(i)
	save_game()


# ---------------------------------------------------------
# BGM(その場で 作る。音の ファイルは 持たない)
#
# 音は 気持ちよさの 半分。無音だと 同じ 遊びでも「作業」に 見える。
# ただし 勉強に 使うので、うるさくない ゆっくりした ループにして、
# いつでも 切れるようにする(切った 状態は 保存する)。
#
# ※ 音ごとに 専用の プレイヤーを 作り、stream は 生成時に 一度だけ 入れる。
#    鳴っている プレイヤーに stream を 入れ直すと Android で 落ちる
# ---------------------------------------------------------

const BGM_RATE := 22050

var _bgm_players: Dictionary = {}
var _bgm_now := ""


## いまの 画面に あわせて 流す。同じ 曲なら 何もしない
func play_bgm(name: String) -> void:
	if not bgm_on:
		return
	if _bgm_now == name and _bgm_players.has(name) \
			and (_bgm_players[name] as AudioStreamPlayer).playing:
		return
	stop_bgm()
	if _bgm_players.has(name):
		_bgm_now = name
		(_bgm_players[name] as AudioStreamPlayer).play()


func stop_bgm() -> void:
	for k in _bgm_players:
		var p: AudioStreamPlayer = _bgm_players[k]
		if p.playing:
			p.stop()
	_bgm_now = ""


func set_bgm_on(v: bool) -> void:
	if bgm_on == v:
		return
	bgm_on = v
	save_game()
	if not v:
		var keep := _bgm_now
		stop_bgm()
		_bgm_now = keep          # 入れ直したら 同じ 曲から 戻す
	elif _bgm_now != "":
		var again := _bgm_now
		_bgm_now = ""
		play_bgm(again)


func _init_bgm() -> void:
	# 5 度と 3 度を 積んだ ゆっくりした 分散和音。1 小節 2 秒 × 8 小節
	var defs := {
		# タイトル・地図: あたたかい 長調
		"map": _make_loop([
			[261.63, 329.63, 392.00], [293.66, 349.23, 440.00],
			[261.63, 329.63, 392.00], [246.94, 311.13, 392.00]], 2.0, 0.10),
		# 問題を 解く 画面: 静かで じゃまを しない
		"think": _make_loop([
			[220.00, 277.18, 329.63], [196.00, 246.94, 293.66],
			[174.61, 220.00, 261.63], [196.00, 246.94, 293.66]], 2.4, 0.07),
		# 島取り: 少し 張った 短調
		"battle": _make_loop([
			[196.00, 233.08, 293.66], [174.61, 220.00, 261.63],
			[196.00, 233.08, 293.66], [155.56, 196.00, 233.08]], 1.8, 0.12),
	}
	for name in defs:
		var p := AudioStreamPlayer.new()
		p.stream = defs[name]
		p.volume_db = -20.0
		add_child(p)
		_bgm_players[name] = p


## 和音を 順に ならす ループ。1 音ずつ ぽろんと 鳴らして 余韻を 重ねる
func _make_loop(chords: Array, bar: float, vol: float) -> AudioStreamWAV:
	var total := int(bar * float(chords.size()) * BGM_RATE)
	var buf := PackedFloat32Array()
	buf.resize(total)
	var bar_n := int(bar * BGM_RATE)
	for ci in chords.size():
		var chord: Array = chords[ci]
		for ni in chord.size():
			var f: float = chord[ni]
			# 1 小節を 音の数で 割って、順に 置く
			var at := ci * bar_n + int(float(ni) * float(bar_n) / float(chord.size()))
			var dur := int(1.6 * float(BGM_RATE))
			for i in dur:
				var idx := at + i
				if idx >= total:
					break
				var t := float(i) / float(BGM_RATE)
				var env := exp(-1.6 * t) * (1.0 - exp(-40.0 * t))
				# 基音 + 少しの 倍音
				var v := sin(TAU * f * t) * 0.7 + sin(TAU * f * 2.0 * t) * 0.18
				buf[idx] += v * env * vol
	var data := PackedByteArray()
	data.resize(total * 2)
	for i in total:
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
	var wav := _wav(data, BGM_RATE)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = total - 1
	return wav
