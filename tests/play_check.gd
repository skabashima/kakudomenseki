extends Node
## 問題シーンを実際に操作してゲームの流れを検証する(--headless 可)。
##   godot --headless --path . res://tests/play_check.tscn
## 1) 正解を入力し続けてステージクリア(★3・得点・セーブ)
## 2) まちがえ続けてハート 0 → 失敗画面
## 3) 途中でまちがえてもクリアでき、★が減っていること

var failures: Array = []


func _ready() -> void:
	await get_tree().process_frame
	# クリア処理が save_game() を呼ぶので、元のセーブ内容を控えて最後に戻す
	var keep_stars: Dictionary = GameState.stars.duplicate(true)
	var keep_scores: Dictionary = GameState.scores.duplicate(true)
	var keep_best_combo := GameState.best_combo
	var keep_stats: Dictionary = GameState.stats.duplicate(true)
	var keep_gauntlet: Dictionary = GameState.gauntlet_best.duplicate(true)
	# 有料ステージも検証対象にする。未購入のまま開くと problem シーンが
	# 解放画面へ遷移してしまい、テストシーンごと差し替わって止まる。
	# (debug_unlock_all ではなく premium。進捗のロックはそのまま検証したい)
	var keep_premium := GameState.premium
	GameState.premium = true
	GameState.stars.clear()
	GameState.scores.clear()
	GameState.gauntlet_best.clear()
	GameState.combo = 0

	await _test_clear_all_correct()
	await _test_fail_out()
	await _test_clear_with_miss()
	await _test_gauntlet()
	await _test_walkthrough()
	await _test_net_challenge()

	GameState.stars = keep_stars
	GameState.scores = keep_scores
	GameState.best_combo = keep_best_combo
	GameState.stats = keep_stats
	GameState.gauntlet_best = keep_gauntlet
	GameState.combo = 0
	GameState.premium = keep_premium
	GameState.save_game()

	if failures.is_empty():
		print("PLAY CHECK OK")
		get_tree().quit(0)
	else:
		for f in failures:
			print("FAIL: " + str(f))
		print("PLAY CHECK FAILED: %d issues" % failures.size())
		get_tree().quit(1)


func _open_stage(course: String, index: int, mode := "normal") -> Node:
	GameState.current_course = course
	GameState.current_stage = index
	GameState.mode = mode
	var inst: Node = (load("res://scenes/problem.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(inst)
	await get_tree().process_frame
	return inst


func _type_answer(scene: Node, text: String) -> void:
	scene.input_text = text
	scene._submit()
	# 演出が終わって入力が再開する(または結果画面が出る)まで待つ。
	# ヘッドレスはフレームが極端に速く回るので、フレーム数ではなく状態で待つ
	var guard := 0
	while scene.locked and scene.overlay == null and guard < 100000:
		guard += 1
		await get_tree().process_frame
	if guard >= 100000:
		failures.append("timeout: 演出が終わらない")


func _answer_str(scene: Node) -> String:
	var ans := float(scene.problem["answer"])
	# 2 桁小数で入力(整数ならそのまま)
	if absf(ans - round(ans)) < 0.0005:
		return str(int(round(ans)))
	return String.num(ans, 2)


func _test_clear_all_correct() -> void:
	# 角度編の先頭 = e1
	var scene: Node = await _open_stage("kaku", 0)
	for q in GameState.QUESTIONS_PER_STAGE:
		await _type_answer(scene, _answer_str(scene))
	if scene.overlay == null:
		failures.append("clear: overlay (結果画面) が出ていない")
	if int(GameState.stars.get("e1", 0)) != 3:
		failures.append("clear: ★3 のはずが %d" % int(GameState.stars.get("e1", 0)))
	if int(GameState.scores.get("e1", 0)) <= 0:
		failures.append("clear: スコアが記録されていない")
	if GameState.combo < 3:
		failures.append("clear: コンボが伸びていない (%d)" % GameState.combo)
	scene.queue_free()
	await get_tree().process_frame


func _test_fail_out() -> void:
	# 面積編の先頭 = e2
	var scene: Node = await _open_stage("men", 0)
	for i in GameState.START_HEARTS:
		await _type_answer(scene, "999999")
	if scene.hearts != 0:
		failures.append("fail: ハートが 0 になっていない (%d)" % scene.hearts)
	if scene.overlay == null:
		failures.append("fail: 失敗画面が出ていない")
	if int(GameState.stars.get("e2", 0)) != 0:
		failures.append("fail: 失敗なのに★が付いた")
	if GameState.combo != 0:
		failures.append("fail: コンボがリセットされていない")
	scene.queue_free()
	await get_tree().process_frame


func _test_clear_with_miss() -> void:
	# 面積編の 2 番目 = e3
	var scene: Node = await _open_stage("men", 1)
	await _type_answer(scene, "999999")   # 1 ミス
	# こわれた式はハートを消費しないこと
	var hearts_before: int = scene.hearts
	await _type_answer(scene, "3++4")
	if scene.hearts != hearts_before:
		failures.append("expr: こわれた式でハートが減った")
	for q in GameState.QUESTIONS_PER_STAGE:
		# 電卓: 式のままでも答えられること(答えを (ans)+0 の式で入れる)
		await _type_answer(scene, "(%s)+0" % _answer_str(scene))
	if int(GameState.stars.get("e3", 0)) != 2:
		failures.append("miss-clear: ★2 のはずが %d" % int(GameState.stars.get("e3", 0)))
	# 角度編は e1 クリア済みなので次(e4)が解放されているはず
	if not GameState.is_stage_unlocked("kaku", 1):
		failures.append("unlock: 角度編 2 番目が解放されていない")
	if GameState.is_stage_unlocked("kaku", 5):
		failures.append("unlock: 角度編 6 番目が解放されてしまっている")
	# 面積編は e3(idx1)までクリア済み → idx2 は開き、idx5 は閉じたまま
	if not GameState.is_stage_unlocked("men", 2):
		failures.append("unlock: 面積編 3 番目が解放されていない")
	if GameState.is_stage_unlocked("men", 5):
		failures.append("unlock: 面積編 6 番目が解放されてしまっている")


func _test_gauntlet() -> void:
	# 挑戦モード: 高難度 10 問を全問正解 → 王冠(gauntlet_best = 10)
	var scene: Node = await _open_stage("kaku", 0, "gauntlet")
	for q in GameState.GAUNTLET_QUESTIONS:
		await _type_answer(scene, _answer_str(scene))
	if scene.overlay == null:
		failures.append("gauntlet: 結果画面が出ていない")
	if int(GameState.gauntlet_best.get("e1", 0)) != GameState.GAUNTLET_QUESTIONS:
		failures.append("gauntlet: 王冠記録が %d(10 のはず)" % int(GameState.gauntlet_best.get("e1", 0)))
	if int(GameState.scores.get("g:e1", 0)) <= 0:
		failures.append("gauntlet: 挑戦スコアが記録されていない")
	scene.queue_free()
	await get_tree().process_frame


## 展開図の 挑戦(10 問)。ステージを またいで 出るので、ここで 通しておく
func _test_net_challenge() -> void:
	var keep := GameState.net_challenge_best
	GameState.net_challenge_best = 0
	GameState.mode = "net"
	var inst: Node = (load("res://scenes/problem.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(inst)
	await get_tree().process_frame
	if inst._q_total() != 10:
		failures.append("net: 10 問で ないと いけない (%d 問)" % inst._q_total())
	var seen := {}
	for q in 10:
		seen[inst.stage_id] = true
		await _type_answer(inst, _answer_str(inst))
	if inst.overlay == null:
		failures.append("net: 結果画面が 出ていない")
	if GameState.net_challenge_best <= 0:
		failures.append("net: 自己ベストが 記録されていない")
	inst.queue_free()
	await get_tree().process_frame
	GameState.net_challenge_best = keep
	GameState.mode = "normal"


func _test_walkthrough() -> void:
	# 解き方アニメ: e13(折り返し)はリッチな steps 持ち(角度編 index 7)。
	# 最後まで見る → 図にアニメ図形が重なる → 正解しても得点 0 → 次の問題でリセット
	var scene: Node = await _open_stage("kaku", 7)
	scene._on_walkthrough()
	if not scene.wt_used:
		failures.append("wt: wt_used が立っていない")
	if GameState.combo != 0:
		failures.append("wt: コンボがリセットされていない")
	if scene.wt_steps.size() < 3:
		failures.append("wt: e13 の steps が少ない (%d)" % scene.wt_steps.size())
	var guard := 0
	while not scene.wt_btn.disabled and guard < 20:
		scene._on_walkthrough()
		guard += 1
	if not scene.wt_btn.disabled:
		failures.append("wt: 最後のステップでボタンが終わらない")
	if scene.figure.overlay_shapes.is_empty():
		failures.append("wt: アニメの図形が図に重なっていない")
	await _type_answer(scene, _answer_str(scene))
	if scene.stage_score != 0:
		failures.append("wt: 解き方を見たのに得点が入った (%d)" % scene.stage_score)
	if scene.overlay == null and (scene.wt_used or scene.wt_idx != -1 or scene.wt_btn.disabled):
		failures.append("wt: 次の問題で解き方がリセットされていない")
	scene.queue_free()
	await get_tree().process_frame
