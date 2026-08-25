extends Node
## ストーリー(小学生)の全単元を、実際に最後まで通す(--headless 可)。
##   godot --headless --path . res://tests/kid_check.tscn
##
## 見るところ:
##   ・おはなし → さわる場面 に入れるか
##   ・3 回できたあと、しるし(その単元の問題)に進めるか
##   ・正しい数を入れたら クリアに なるか
## さわり方(act)を足したのに つなぎ忘れると、ここで止まる
var failures: Array = []

func _ready() -> void:
	await get_tree().process_frame
	# 通しプレイの途中でクリアが保存されるので、終わったら元に戻して書き戻す
	# (そうしないと、遊んでいない単元がクリア済みとして残る)
	var keep: Dictionary = GameState.kid_clear.duplicate(true)
	var keep_unit := GameState.kid_unit
	GameState.kid_clear = {}
	for u in KidDefs.UNITS:
		await _play(u)
	GameState.kid_clear = keep
	GameState.kid_unit = keep_unit
	GameState.save_game()
	if failures.is_empty():
		print("KID OK: %d 単元 すべて 進めた" % KidDefs.UNITS.size())
	else:
		for f in failures:
			print("FAIL: " + String(f))
	get_tree().quit(0 if failures.is_empty() else 1)

func _play(u: Dictionary) -> void:
	GameState.kid_unit = String(u["id"])
	var inst: Node = (load("res://scenes/kid_unit.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(inst)
	for i in 8: await get_tree().process_frame
	for i in (u["intro"] as Array).size():
		inst._advance()
		await get_tree().process_frame
	if inst.phase != 1:
		failures.append("%s: さわる場面に入らない" % u["id"])
		inst.queue_free()
		return
	for round in 3:
		inst._act_done()
		await get_tree().process_frame
		if round < 2:
			inst._advance()
			await get_tree().process_frame
	inst._advance()
	for i in 6: await get_tree().process_frame
	if inst.phase != 2:
		failures.append("%s: しるし(クイズ)に進めない" % u["id"])
	elif inst.problem.is_empty() or not inst.problem.has("answer"):
		failures.append("%s: 問題が作れない" % u["id"])
	else:
		inst.input_text = ProblemGen.fmt(float(inst.problem["answer"]))
		inst._submit()
		await get_tree().process_frame
		if inst.phase != 3:
			failures.append("%s: 正解しても おわりに ならない(%s)" % [u["id"], inst.big.text])
	inst.queue_free()
	await get_tree().process_frame
