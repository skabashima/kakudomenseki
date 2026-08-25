extends Node
## 島取りを 1 局 最後まで 通す(--headless 可)。
##   godot --headless --path . res://tests/island_check.tscn
##
## 見るところ:
##   ・立て札をタップ → 問題 → 正解 → なぞって取る → カラスの番、が回るか
##   ・取ったマスが かならず 自分の陣地と つながっているか
##   ・3 回まちがえると 立て札を失って ターンが 進むか(何度でも 答えられない)
##   ・立て札まで とどくと 次のターンの ぶんが 増えるか
##   ・囲まれても 詰まらず、決着して 占有率が 出るか

var failures: Array = []


func _ready() -> void:
	await get_tree().process_frame
	var inst: Node = (load("res://scenes/island.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(inst)
	for i in 8:
		await get_tree().process_frame

	await _check_miss(inst)

	var guard := 0
	var reached := 0
	while not inst.over and guard < 60:
		guard += 1
		var cv: Vector2i = _near_post(inst)
		if cv.x < 0:
			break
		inst._tap_post(cv)
		await _wait(2)
		if not inst.quiz.visible:
			failures.append("%d ターンめ: 立て札をタップしても 問題が 出ない" % inst.turn)
			break
		inst.input_text = ProblemGen.fmt(float(inst.problem["answer"]))
		inst.keypad.answer_lbl.text = inst.input_text
		inst._submit()
		await _wait(2)
		if inst.need <= 0:
			failures.append("%d ターンめ: 正解しても 取れるマスが 決まらない" % inst.turn)
			break
		var turn_now: int = inst.turn
		# コストで 数える(カラスのマスは 2 マスぶん)
		while inst._marked_cost() < inst.need:
			var m: Vector2i = _toward(inst, cv)
			if m.x < 0:
				break
			var was: int = inst.marked.size()
			inst._mark(m)
			if inst.marked.size() == was:
				break
		# 取る土地は「旗を ふくむ ひとつながり」で なければ ならない
		if not _one_lump(inst, cv):
			failures.append("%d ターンめ: 旗と つながっていない マスが 取れてしまう" % inst.turn)
			break
		if inst.marked.has(cv):
			reached += 1
		inst._on_act()
		await _wait(4)
		# カラスに 切り返されて 減ることも あるので、マス数ではなく
		# 「ターンが 進んだか」を 見る
		if inst.turn <= turn_now and not inst.over:
			failures.append("%d ターンめ: 決めても ターンが 進まない(need %d / なぞった %d / まだ置ける %d)" % [inst.turn, inst.need, inst.marked.size(), inst._markable_left()])
			break

	if not inst.over and failures.is_empty():
		failures.append("60 手 まわしても 終わらない(ターンが 進んでいない)")
	if reached == 0 and failures.is_empty():
		failures.append("一度も 立て札に とどかない(近い立て札でも 届かないなら 数が おかしい)")
	if failures.is_empty():
		print("ISLAND OK: %d ターンで 決着(じぶん %d マス / カラス %d マス・立て札 %d 本 占領・空き %d マス)" % [
			inst.turn, inst._count(inst.MINE), inst._count(inst.CROW), reached,
			inst._count(inst.EMPTY)])
		print("  おわり方: " + inst.msg.text)
	else:
		for f in failures:
			print("FAIL: " + str(f))
	inst.queue_free()
	await _wait(1)
	get_tree().quit(0 if failures.is_empty() else 1)


## 3 回まちがえたら 立て札を失って ターンが 進む(何度でも 答えられない)
func _check_miss(inst: Node) -> void:
	var cv: Vector2i = _near_post(inst)
	if cv.x < 0:
		failures.append("立て札が 1 本も 立っていない")
		return
	var turn_before: int = inst.turn
	inst._tap_post(cv)
	await _wait(2)
	for i in 3:
		inst.input_text = "-1"
		inst._submit()
		await _wait(2)
	if inst.quiz.visible:
		failures.append("3 回まちがえても 問題が 閉じない(何度でも 答えられる)")
	var still := false
	for p in inst.posts:
		if int(p["x"]) == cv.x and int(p["y"]) == cv.y:
			still = true
	if still:
		failures.append("3 回まちがえても その立て札が 残っている")
	if inst.turn <= turn_before:
		failures.append("3 回まちがえても ターンが 進まない")
	if inst.need > 0:
		failures.append("3 回まちがえたのに 土地が もらえている")


func _near_post(inst: Node) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := 999
	for p in inst.posts:
		var d: int = inst._dist_to_mine(int(p["x"]), int(p["y"]))
		if d < best_d:
			best_d = d
			best = Vector2i(int(p["x"]), int(p["y"]))
	return best


## 立て札に 近づく マスを 1 つ選ぶ
func _toward(inst: Node, target: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := 999
	for y in inst.H:
		for x in inst.W:
			var cv := Vector2i(x, y)
			if inst.marked.has(cv):
				continue
			var k: int = inst.cell[y][x]
			if k != inst.EMPTY and k != inst.SPRING and k != inst.RUIN and k != inst.CROW:
				continue
			if not inst._touches_claim(cv):
				continue
			# のこりの マスぶんで 取れる ものだけ(カラスのマスは 2 つぶん)
			if inst._cost_of(cv) > inst.need - inst._marked_cost():
				continue
			var d := absi(x - target.x) + absi(y - target.y)
			if d < best_d:
				best_d = d
				best = cv
	return best


## 取る土地は「旗から、なぞったマスと 自分の陣地を たどって」つながること
func _one_lump(inst: Node, flag: Vector2i) -> bool:
	if inst.marked.is_empty():
		return true
	if not inst.marked.has(flag):
		return false
	var seen := {}
	var stack: Array[Vector2i] = [flag]
	while not stack.is_empty():
		var cur: Vector2i = stack.pop_back()
		if seen.has(cur):
			continue
		seen[cur] = true
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = cur + d
			if n.x < 0 or n.x >= inst.W or n.y < 0 or n.y >= inst.H:
				continue
			if seen.has(n):
				continue
			if inst.marked.has(n) or inst.cell[n.y][n.x] == inst.MINE:
				stack.append(n)
	for m in inst.marked:
		if not seen.has(m):
			return false
	return true


func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame
