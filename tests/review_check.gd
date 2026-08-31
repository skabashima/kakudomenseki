extends Node
## 復習キューの 検証(--headless 可)。
##   godot --headless --path . res://tests/review_check.tscn
##
## 見るところ:
##   ・まちがえると 覚え書きに 入るか
##   ・つぎに その単元を 開くと、その 段が 1 問めに 出るか
##   ・正解すると 覚え書きから 消えるか
##   ・同じ ものを ためこまないか / 上限を こえないか
##   ・実際の セーブを こわさないか

var failures: Array = []


func _ready() -> void:
	await get_tree().process_frame
	var keep: Array = GameState.review.duplicate(true)
	GameState.review = []

	# まちがえた ことを 覚える
	GameState.add_review("e4", 2)
	if GameState.review_count("e4") != 1:
		failures.append("まちがえても 覚え書きに 入らない")
	GameState.add_review("e4", 2)
	if GameState.review_count("e4") != 1:
		failures.append("同じ 問題を 二重に ためている")
	if GameState.peek_review("e4") != 2:
		failures.append("覚えた 段が 取り出せない")
	if GameState.peek_review("e1") != -1:
		failures.append("覚えていない 単元から 出てくる")

	# 画面を 開くと 1 問めに 出るか
	GameState.mode = "normal"
	GameState.current_course = "kaku"
	GameState.current_stage = 1                      # e4
	var inst: Node = (load("res://scenes/problem.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(inst)
	for i in 8:
		await get_tree().process_frame
	if not inst.is_review:
		failures.append("復習が あるのに 1 問めが ふつうの 問題")
	if inst.cur_tier != 2:
		failures.append("復習の 段が ちがう(%d)" % inst.cur_tier)

	# 正解すると 消える
	inst.input_text = ProblemGen.fmt(float(inst.problem["answer"]))
	inst._submit()
	for i in 4:
		await get_tree().process_frame
	if GameState.review_count("e4") != 0:
		failures.append("正解しても 覚え書きから 消えない")
	inst.queue_free()
	await get_tree().process_frame

	# 上限
	for i in 60:
		GameState.add_review("e1", i)
	if GameState.review.size() > GameState.REVIEW_MAX:
		failures.append("覚え書きが 上限を こえて たまる(%d)" % GameState.review.size())

	GameState.review = keep
	GameState.save_game()
	if failures.is_empty():
		print("REVIEW OK: まちがえた 問題が つぎに 出て、解けたら 消える")
	else:
		for f in failures:
			print("FAIL: " + str(f))
	get_tree().quit(0 if failures.is_empty() else 1)
