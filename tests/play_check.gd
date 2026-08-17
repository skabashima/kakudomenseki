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
	GameState.stars.clear()
	GameState.scores.clear()
	GameState.combo = 0

	await _test_clear_all_correct()
	await _test_fail_out()
	await _test_clear_with_miss()

	GameState.stars = keep_stars
	GameState.scores = keep_scores
	GameState.best_combo = keep_best_combo
	GameState.stats = keep_stats
	GameState.combo = 0
	GameState.save_game()

	if failures.is_empty():
		print("PLAY CHECK OK")
		get_tree().quit(0)
	else:
		for f in failures:
			print("FAIL: " + str(f))
		print("PLAY CHECK FAILED: %d issues" % failures.size())
		get_tree().quit(1)


func _open_stage(course: String, index: int) -> Node:
	GameState.current_course = course
	GameState.current_stage = index
	GameState.mode = "normal"
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
	var scene: Node = await _open_stage("e", 0)
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
	var scene: Node = await _open_stage("e", 1)
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
	var scene: Node = await _open_stage("e", 2)
	await _type_answer(scene, "999999")   # 1 ミス
	for q in GameState.QUESTIONS_PER_STAGE:
		await _type_answer(scene, _answer_str(scene))
	if int(GameState.stars.get("e3", 0)) != 2:
		failures.append("miss-clear: ★2 のはずが %d" % int(GameState.stars.get("e3", 0)))
	# 1 問目クリア済みなので次のステージが解放されているはず
	if not GameState.is_stage_unlocked("e", 1):
		failures.append("unlock: e2 が解放されていない")
	if GameState.is_stage_unlocked("e", 5):
		failures.append("unlock: e6 が解放されてしまっている")
	scene.queue_free()
	await get_tree().process_frame
