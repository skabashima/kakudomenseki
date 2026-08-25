extends Node
## 島取りを 最後まで 1 局 通す(--headless 可)。
##   godot --headless --path . res://tests/island_check.tscn
##
## 見るところ:
##   ・立て札 → 問題 → 正解 → なぞって取る → カラスの番、が回るか
##   ・取ったマスが かならず 自分の陣地と つながっているか
##   ・囲まれて 置けなくなっても 詰まらずに 進むか
##   ・15 ターン以内に 終わって 占有率が出るか

var failures: Array = []


func _ready() -> void:
	await get_tree().process_frame
	var inst: Node = (load("res://scenes/island.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(inst)
	for i in 8:
		await get_tree().process_frame

	var guard := 0
	while not inst.over and guard < 60:
		guard += 1
		inst._on_act()                      # 立て札の問題を開く
		await _wait(2)
		if not inst.quiz.visible:
			failures.append("%d ターンめ: 問題が開かない" % inst.turn)
			break
		inst.input_text = ProblemGen.fmt(float(inst.problem["answer"]))
		inst.keypad.answer_lbl.text = inst.input_text
		inst._submit()
		await _wait(2)
		if inst.need <= 0:
			failures.append("%d ターンめ: 正解しても 取れるマスが 決まらない" % inst.turn)
			break
		# ふちを なぞる(実際の指の道すじと同じ入口を通す)
		var before: int = inst._count(inst.MINE)
		var put := 0
		while put < inst.need:
			var cv: Vector2i = _next_cell(inst)
			if cv.x < 0:
				break
			inst._mark(cv)
			put += 1
		if put > 0 and not _all_connected(inst):
			failures.append("%d ターンめ: 陣地から はなれた マスが 取れてしまう" % inst.turn)
			break
		inst._on_act()                      # ここに決める → カラスの番
		await _wait(6)
		if inst._count(inst.MINE) <= before and not inst.over:
			failures.append("%d ターンめ: 決めても 陣地が 増えない" % inst.turn)
			break

	if not inst.over and failures.is_empty():
		failures.append("60 手 まわしても 終わらない(ターンが 進んでいない)")
	if failures.is_empty():
		print("ISLAND OK: %d ターンで 決着(じぶん %d マス / カラス %d マス)" % [
			inst.turn, inst._count(inst.MINE), inst._count(inst.CROW)])
	else:
		for f in failures:
			print("FAIL: " + str(f))
	inst.queue_free()
	await _wait(1)
	get_tree().quit(0 if failures.is_empty() else 1)


## いま なぞれる マスを 1 つ返す
func _next_cell(inst: Node) -> Vector2i:
	for y in inst.H:
		for x in inst.W:
			var cv := Vector2i(x, y)
			if inst.marked.has(cv):
				continue
			var k: int = inst.cell[y][x]
			if k != inst.EMPTY and k != inst.SPRING and k != inst.RUIN:
				continue
			if inst._touches_mine(cv):
				return cv
	return Vector2i(-1, -1)


## 選んだマスが すべて 陣地と つながっているか
func _all_connected(inst: Node) -> bool:
	for m in inst.marked:
		if not inst._touches_mine(m):
			return false
	return true


func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame
