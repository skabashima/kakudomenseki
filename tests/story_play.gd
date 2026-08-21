extends Node
## ストーリーを全10章、実際に最後まで進めてみる(--headless 可)。
##   godot --headless --path . res://tests/story_play.tscn
##
## 見るところ:
##   ・各場面で「つぎへ」が必ず出るか(出ないと進めなくなる = フリーズに見える)
##   ・measure で 3 回記録すると選択肢が開き、正解を選ぶと先へ進めるか
##   ・solve で正解を選んでも止まらないか
##     (依頼は本編の problem と鍵の中身が違う。無い鍵を読むと関数がそこで
##      止まり、ボタンが出ないまま進めなくなる ― 実際に起きた)
##   ・最後まで行くと章クリアが記録されるか

var failures: Array = []


func _ready() -> void:
	await get_tree().process_frame
	var keep_clear: Dictionary = GameState.story_clear.duplicate(true)
	var keep_chapter := GameState.story_chapter
	var keep_scene := GameState.story_scene
	GameState.story_clear = {}

	for ch in StoryDefs.CHAPTERS:
		await _play(ch)

	GameState.story_clear = keep_clear
	GameState.story_chapter = keep_chapter
	GameState.story_scene = keep_scene

	if failures.is_empty():
		print("STORY PLAY OK: %d 章を最後まで通した" % StoryDefs.CHAPTERS.size())
		get_tree().quit(0)
	else:
		for f in failures:
			print("FAIL: " + String(f))
		print("STORY PLAY FAILED: %d 件" % failures.size())
		get_tree().quit(1)


func _play(ch: Dictionary) -> void:
	var cid := String(ch["id"])
	GameState.story_chapter = cid
	GameState.story_scene = 0
	var inst: Node = (load("res://scenes/story.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(inst)
	await _wait(6)
	var scenes: Array = ch["scenes"]
	for i in scenes.size():
		var sc: Dictionary = scenes[i]
		var where := "%s の場面 %d(%s)" % [cid, i + 1, String(sc["type"])]
		match String(sc["type"]):
			"talk":
				pass
			"measure":
				await _do_measure(inst, sc, where)
			"solve":
				await _do_solve(inst, sc, where)
		if not _has_next(inst):
			failures.append(where + ": 「つぎへ」が出ないので先へ進めない")
			inst.queue_free()
			await _wait(2)
			return
		inst._advance()
		await _wait(6)
	if not GameState.story_clear.has(cid):
		failures.append(cid + ": 最後まで進めたのにクリアが記録されない")
	inst.queue_free()
	await _wait(2)


func _do_measure(inst: Node, sc: Dictionary, where: String) -> void:
	# 予想 → 記録 → 判定
	inst._do_guess(0)
	await _wait(4)
	var kind := String(sc["fig"])
	var need := int(sc.get("trials", 3))
	for t in need:
		var start: Vector2 = StoryDefs.start_of(kind)
		inst._on_dragged(0, StoryDefs.clamp_of(kind, start * (1.0 + 0.2 * float(t))
			+ Vector2(0.5 * float(t), -0.3 * float(t))))
		await _wait(2)
		inst._record()
		await _wait(2)
	if inst.choice_box.get_child_count() == 0:
		failures.append(where + ": %d 回記録しても選択肢が出ない" % need)
		return
	inst._choose(int(sc["answer"]))
	await _wait(4)
	if not inst.answered:
		failures.append(where + ": 正解を選んでも先へ進める状態にならない")


func _do_solve(inst: Node, sc: Dictionary, where: String) -> void:
	var ans := float(inst.problem["answer"])
	inst._pick_answer(ans, ans)
	await _wait(4)
	if not inst.answered:
		failures.append(where + ": 正解を選んでも先へ進める状態にならない")


func _has_next(inst: Node) -> bool:
	return inst.next_btn != null and is_instance_valid(inst.next_btn)


func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame
