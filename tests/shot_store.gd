extends Node
## ストア掲載用の素材を、App Store が必須とする 6.9インチの解像度(1320×2868)で撮る。
## ここが最大サイズなので、他のサイズは縮小だけで作れる(引き伸ばしを起こさない)。
##   godot --path . res://tests/shot_store.tscn
## 出力: res://store/raw/*.png(この後 store/make_store_images.py で仕上げる)
##
## PC の画面より高い解像度はウィンドウでは撮れないので、SubViewport に描く。
## size = 実解像度 / size_2d_override = 端末と同じ論理解像度 にすると、
## レイアウトは実機と同じまま、くっきりした実寸の画像が得られる。
## 論理解像度は 基準幅 1080 ÷ content_scale_factor 1.2 = 900(GameState._update_ui_scale)。

const DIR := "res://store/raw"
const SHOT := Vector2i(1320, 2868)
const LOGICAL_W := 900

var sub: SubViewport


func _ready() -> void:
	sub = SubViewport.new()
	sub.size = SHOT
	sub.size_2d_override = Vector2i(LOGICAL_W, int(round(float(LOGICAL_W) * SHOT.y / SHOT.x)))
	sub.size_2d_override_stretch = true
	sub.transparent_bg = false
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sub)
	await _run()
	get_tree().quit()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	# 撮影用の状態。セーブはしない(実際の進捗を壊さないため)
	GameState.debug_unlock_all = true
	GameState.premium = true
	_fill_progress()

	# 1) タイトル(段位と進捗が入った状態)
	await _scene("res://scenes/main.tscn", "01_title.png")
	# 2) ステージ一覧(角度編。★と王冠が並ぶ)
	GameState.current_course = "kaku"
	await _scene("res://scenes/stage_select.tscn", "02_stage_select.png")
	# 3) 角度の問題(星形の角。とがった角が 4 つ示された難しい変化)
	await _problem("kaku", 10, "03_problem_angle.png", 5, 7001)
	# 4) 面積の問題(葉っぱ形 ― 中学受験の名物。2 つの四分円が重なる変化)
	await _problem("men", 8, "04_problem_leaf.png", 2, 7002)
	# 5) 電卓(道の面積。式のまま入れて答えられることを見せる)
	await _calc("men", 4, "(8−1)×(11−1)", "05_calc.png", 2, 7003)
	# 6) 「解き方」アニメ(ヒポクラテスの月。補助線と色ぬりが出たところ)
	await _walkthrough("men", 14, 3, "06_walkthrough.png", 2, 7004)
	# 7) チャレンジ選択(自己ベストつき)
	await _scene("res://scenes/challenge_select.tscn", "07_challenge.png")
	# 8) 記録(段位・コース別・自己ベスト)
	await _scene("res://scenes/records.tscn", "08_records.png")
	# 9) ステージ一覧(面積編。大学受験まで並ぶ)
	GameState.current_course = "men"
	await _scene("res://scenes/stage_select.tscn", "09_stage_select_men.png")
	# 10) 解放画面(App Store の課金審査用スクショにも使う)
	GameState.premium = false
	GameState.debug_unlock_all = false
	await _store_shot("10_store_iap.png")

	_clear_progress()
	print("SHOT STORE DONE")


## それらしい進捗を入れて撮る(空の画面より魅力が伝わる)
func _fill_progress() -> void:
	var cleared := {
		"e1": 3, "e4": 3, "e6": 2, "e11": 3, "e7": 3, "e17": 2, "e12": 3,
		"e2": 3, "e3": 3, "e5": 3, "e8": 3, "e14": 2, "e9": 3, "e15": 2,
		"j1": 3, "j5": 2,
	}
	GameState.stars = cleared.duplicate()
	GameState.scores = {}
	for id in cleared:
		GameState.scores[id] = 380 + 40 * int(cleared[id])
	GameState.gauntlet_best = {"e1": 10, "e4": 10, "e11": 7, "e2": 10, "e3": 6}
	GameState.challenge_best = {"time:kaku": 12, "time:men": 9, "time:all": 11, "survival": 14}
	GameState.best_combo = 9
	GameState.stats = {"correct": 326, "clear": 16, "gauntlet_clear": 3}
	GameState.combo = 0


func _clear_progress() -> void:
	GameState.stars = {}
	GameState.scores = {}
	GameState.gauntlet_best = {}
	GameState.challenge_best = {}
	GameState.stats = {}
	GameState.best_combo = 0
	GameState.debug_unlock_all = false
	GameState.premium = false


func _scene(path: String, out_name: String) -> void:
	var inst: Node = (load(path) as PackedScene).instantiate()
	sub.add_child(inst)
	for f in 14:
		await get_tree().process_frame
	# デバッグビルドで出る「デバッグ: 全ステージ解放」はストア画像に写さない
	if "debug_btn" in inst and inst.debug_btn != null:
		inst.debug_btn.visible = false
		await get_tree().process_frame
	_save(out_name)
	inst.queue_free()
	await get_tree().process_frame


## 問題シーンを開いて撮る。
## tier は難度ラダーの段(0〜2 は通常の 1〜3 問目、3 以上は挑戦モードの後半)。
## 図が単純すぎる tier 0 ではなく、見ごたえのある変化を選んで撮るために使う。
## rng_seed を与えると同じ数値の問題が出る(式を入れた状態の撮影で必要)。
func _open_problem(course_id: String, index: int, tier := 0, rng_seed := 0) -> Node:
	GameState.current_course = course_id
	GameState.current_stage = index
	GameState.mode = "normal" if tier <= 2 else "gauntlet"
	var inst: Node = (load("res://scenes/problem.tscn") as PackedScene).instantiate()
	sub.add_child(inst)
	for f in 12:
		await get_tree().process_frame
	if tier > 0 or rng_seed != 0:
		# 指定の tier(と数値)で出しなおす。通常モードは tier = 何問目
		if rng_seed != 0:
			inst.rng.seed = rng_seed
		inst.q_index = tier
		inst._next_question(true)
		for f in 8:
			await get_tree().process_frame
	return inst


func _problem(course_id: String, index: int, out_name: String, tier := 0,
		rng_seed := 0) -> void:
	var inst := await _open_problem(course_id, index, tier, rng_seed)
	_save(out_name)
	inst.queue_free()
	await get_tree().process_frame


## 解答欄に式を入れた状態(電卓が売りなので、式のまま見せる)。
## 式は問題の数値に合わせて書くので、生成が変わっていないかをその場で確かめる
func _calc(course_id: String, index: int, expr: String, out_name: String, tier := 0,
		rng_seed := 0) -> void:
	var inst := await _open_problem(course_id, index, tier, rng_seed)
	print("  calc: " + String(inst.problem["q"]))
	var res: Dictionary = ExprEval.eval(expr)
	var ok := bool(res["ok"])
	var diff := 1e9
	if ok:
		diff = absf(float(res["value"]) - float(inst.problem["answer"]))
	if not ok or diff > float(inst.problem["tol"]):
		push_warning("式 %s が問題の答え %s と合わない(生成が変わった可能性)" % [
			expr, str(inst.problem["answer"])])
		print("  ★ 式が答えと合っていない: " + expr)
	inst.input_text = expr
	inst._update_answer()
	for f in 4:
		await get_tree().process_frame
	_save(out_name)
	inst.queue_free()
	await get_tree().process_frame


## 「解き方」を presses 回すすめた状態(補助線・色ぬり・角の印が出る)
func _walkthrough(course_id: String, index: int, presses: int, out_name: String,
		tier := 0, rng_seed := 0) -> void:
	var inst := await _open_problem(course_id, index, tier, rng_seed)
	for i in presses:
		inst._on_walkthrough()
		# 補助線が引かれるアニメが終わってから次へ
		await get_tree().create_timer(0.75).timeout
	await get_tree().create_timer(0.35).timeout
	_save(out_name)
	inst.queue_free()
	await get_tree().process_frame


## 解放画面。PC でしか出ない「ストアに接続できません」は審査担当が混乱するので消す
func _store_shot(out_name: String) -> void:
	var inst: Node = (load("res://scenes/store.tscn") as PackedScene).instantiate()
	sub.add_child(inst)
	for f in 14:
		await get_tree().process_frame
	if inst.status:
		inst.status.text = ""
	for f in 3:
		await get_tree().process_frame
	_save(out_name)
	inst.queue_free()
	await get_tree().process_frame


func _save(out_name: String) -> void:
	var img: Image = sub.get_texture().get_image()
	img.save_png(DIR + "/" + out_name)
	print("saved " + out_name)
