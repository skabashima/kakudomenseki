extends Node
## 島取りを 1 局 最後まで 通す(--headless 可)。
##   godot --headless --path . res://tests/island_check.tscn
##
## 見るところ:
##   ・難しさをえらぶ → 問題 → 正解 → なぞって取る → カラスの番、が回るか
##   ・取ったマスが かならず 自分の陣地と つながっているか
##   ・えらんだ 難しさの 回数だけ まちがえたら ターンが 進むか
##     (何度でも 答えられない)
##   ・石碑を 取ると その ぶん 多く もらえるか
##   ・同じ 難しさでも 毎回 ちがう 問題が 出るか
##     (前は「むずかしい = いつも 同じステージ」だった)
##   ・むずかしい を 正解したら、その 難しさの 下限より 多く もらえるか
##     (わり算だけで 決めていた ころ、角度の 小さい 答えだと
##      むずかしい でも 3 マスしか もらえなかった)
##   ・指で なぞって 取れるか / なぞり直しても 旗が 残るか
##   ・囲まれても 詰まらず、決着して 占有率が 出るか

var failures: Array = []


func _ready() -> void:
	await get_tree().process_frame
	var keep: Dictionary = GameState.island_clear.duplicate(true)
	var keep_i := GameState.island_index
	GameState.island_clear = {}
	GameState.island_index = 0
	var inst: Node = (load("res://scenes/island.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(inst)
	for i in 8:
		await get_tree().process_frame

	await _check_variety(inst)
	await _check_reward(inst)
	await _check_drag(inst)
	await _check_miss(inst)

	var guard := 0
	var reached := 0
	while not inst.over and guard < 60:
		guard += 1
		if inst.auto_fill:
			# 決着が 見えたので 自動で 塗っている。終わるまで 待つ
			var wait_guard := 0
			while inst.auto_fill and not inst.over and wait_guard < 600:
				wait_guard += 1
				await _wait(1)
			continue
		inst._pick_level(1)
		await _wait(2)
		if not inst.quiz.visible:
			failures.append("%d ターンめ: 難しさを えらんでも 問題が 出ない" % inst.turn)
			break
		inst.input_text = ProblemGen.fmt(float(inst.problem["answer"]))
		inst.keypad.answer_lbl.text = inst.input_text
		inst._submit()
		await _wait(2)
		if inst.need <= 0:
			failures.append("%d ターンめ: 正解しても 取れるマスが 決まらない" % inst.turn)
			break
		var turn_now: int = inst.turn
		if inst.turn % 2 == 0:
			# 1 ターンおきに「おまかせ」でも 埋まるかを 見る
			# (おまかせが 取れない マスを えらび続けて 1 つも 埋まらない ことがあった)
			inst._auto_mark()
			if inst._marked_cost() < inst.need and inst._markable_left() > 0:
				failures.append("%d ターンめ: おまかせで 埋まらない(%d/%d・まだ置ける %d)" % [
					inst.turn, inst._marked_cost(), inst.need, inst._markable_left()])
				break
		# コストで 数える(カラスのマスは 2 マスぶん)
		while inst._marked_cost() < inst.need:
			var m: Vector2i = _toward(inst, _shrine_target(inst))
			if m.x < 0:
				break
			var was: int = inst.marked.size()
			inst._mark(m)
			if inst.marked.size() == was:
				break
		# 取るマスは 自陣か なぞった かたまりと となりあっていること
		if not _one_lump(inst, Vector2i(-1, -1)):
			failures.append("%d ターンめ: 旗と つながっていない マスが 取れてしまう" % inst.turn)
			break
		for sh in inst.shrines:
			if inst.marked.has(sh):
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
	# 石碑は 取り合いに なる もの。どちらかが 取れていれば しくみは 動いている
	# (どちらが 取るかは 勝負しだいなので、こちらが 取れなくても よい)
	var owned := 0
	for sh in inst.shrines:
		if inst.cell[sh.y][sh.x] != inst.SHRINE:
			owned += 1
	if owned == 0 and failures.is_empty():
		failures.append("石碑を だれも 取れない(取れる ようになっていない)")
	# 勝ったら その島が クリアとして のこり、つぎの島が 開くこと
	var mine_end: int = inst._count(inst.MINE)
	var crow_end: int = inst._count(inst.CROW)
	if mine_end > crow_end:
		if not GameState.island_clear.has(str(inst.isle)):
			failures.append("勝ったのに 島が クリアに ならない")
		elif inst.isle + 1 < IslandDefs.count() 				and not IslandDefs.is_open(inst.isle + 1, GameState.island_clear):
			failures.append("勝ったのに つぎの島が 開かない")
		if inst.result_layer == null:
			failures.append("決着しても 勝ち負けの 画面が 出ない")
	if failures.is_empty():
		print("ISLAND OK: %d ターンで 決着(じぶん %d マス / カラス %d マス・石碑 %d 回 取った・空き %d マス)" % [
			inst.turn, inst._count(inst.MINE), inst._count(inst.CROW), reached,
			inst._count(inst.EMPTY)])
		print("  おわり方: " + inst.msg.text)
	else:
		for f in failures:
			print("FAIL: " + str(f))
	inst.queue_free()
	await _wait(1)
	GameState.island_clear = keep
	GameState.island_index = keep_i
	GameState.save_game()
	get_tree().quit(0 if failures.is_empty() else 1)


## むずかしい を 1 回はずすと、そのターンは 何も 取れずに カラスの番へ
func _check_miss(inst: Node) -> void:
	var turn_before: int = inst.turn
	inst._pick_level(2)                 # むずかしい = まちがえられるのは 1 回
	await _wait(2)
	if not inst.quiz.visible:
		failures.append("むずかしい を えらんでも 問題が 出ない")
		return
	inst.input_text = "-1"
	inst._submit()
	await _wait(2)
	if inst.quiz.visible:
		failures.append("むずかしい を はずしても 問題が 閉じない(何度でも 答えられる)")
	if inst.turn <= turn_before:
		failures.append("はずしても ターンが 進まない")
	if inst.need > 0:
		failures.append("はずしたのに 土地が もらえている")


## いちばん 近い 石碑
func _shrine_target(inst: Node) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := 999
	for sh in inst.shrines:
		if inst.cell[sh.y][sh.x] == inst.MINE:
			continue
		var d: int = inst._dist_to_mine(sh.x, sh.y)
		if d < best_d:
			best_d = d
			best = sh
	if best.x < 0 and not inst.shrines.is_empty():
		best = inst.shrines[0]
	return best


## 目あて(石碑)に 近づく マスを 1 つ選ぶ
func _toward(inst: Node, target: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := 999
	for y in inst.H:
		for x in inst.W:
			var cv := Vector2i(x, y)
			if inst.marked.has(cv):
				continue
			var k: int = inst.cell[y][x]
			if k != inst.EMPTY and k != inst.SPRING and k != inst.RUIN and k != inst.SHRINE:
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


## 取るマスは すべて「自分の陣地」か「なぞった かたまり」と となりあっていること
func _one_lump(inst: Node, _flag: Vector2i) -> bool:
	for m in inst.marked:
		if not inst._touches_claim(m):
			return false
	return true


func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame


# =========================================================
# 指の 道すじ(本物の 入口を 通す)
# =========================================================

## なぞって 取れるか、なぞり直しても 詰まらないかを 見る。
## _mark() を 直に 呼ぶだけでは、
##   ・なぞり直しで 旗まで 消えて どこも なぞれなくなる
##   ・速く なぞると 通ったマスが 飛ぶ
## という 指でしか 起きない 不具合を 見つけられない(実際に 両方 起きた)。
## 難しさごとの もらえる マス数を 見る。
## えらんだ 難しさより 少ない ときは、えらぶ 意味が なくなっている
## 同じ 難しさを えらび直すと ちがう 問題が 出るか
func _check_variety(inst: Node) -> void:
	var seen := {}
	for i in 6:
		inst._pick_level(2)
		await _wait(2)
		if not inst.quiz.visible:
			failures.append("むずかしい で 問題が 出ない")
			return
		seen[String(inst.problem["q"])] = true
		inst.quiz.visible = false
		inst.need = 0
		inst.marked.clear()
		await _wait(1)
	if seen.size() < 3:
		failures.append("むずかしい を 6 回 えらんでも %d 種類しか 出ない(毎回 同じ)" % seen.size())


func _check_reward(inst: Node) -> void:
	for lv in [2, 1, 0]:
		inst._pick_level(lv)
		await _wait(2)
		if not inst.quiz.visible:
			failures.append("難しさ %d で 問題が 出ない" % lv)
			return
		var low: int = int(inst.LEVELS[lv]["low"])
		var got: int = inst._cells_for(float(inst.problem["answer"]))
		if got < low:
			failures.append("%s を 正解しても %d マス(下限 %d マス)" % [
				String(inst.LEVELS[lv]["name"]), got, low])
		# 答えずに 閉じて つぎの 難しさへ
		inst.quiz.visible = false
		inst.need = 0
		inst.marked.clear()
		await _wait(1)


func _check_drag(inst: Node) -> void:
	inst._pick_level(0)
	await _wait(2)
	if not inst.quiz.visible:
		failures.append("難しさを えらんでも 問題が 出ない")
		return
	inst.input_text = ProblemGen.fmt(float(inst.problem["answer"]))
	inst._submit()
	await _wait(2)
	if inst.need <= 0:
		failures.append("正解しても 取れるマスが 決まらない")
		return

	# 自陣の となりで、上に 空きマスが 2 つ 続く ところを えらぶ
	# (そこから 上へ すべらせて、通り道が 取れるかを 見る)
	var start := Vector2i(-1, -1)
	for y in range(inst.H - 1, 1, -1):
		for x in inst.W:
			if start.x >= 0:
				break
			var cv := Vector2i(x, y)
			if inst.cell[y][x] != inst.EMPTY or not inst._touches_claim(cv):
				continue
			if inst.cell[y - 1][x] == inst.EMPTY and inst.cell[y - 2][x] == inst.EMPTY:
				start = cv
	if start.x < 0:
		failures.append("自陣の となりに なぞれる マスが ない")
		return
	inst._mark(start)
	await _wait(1)

	# なぞり直し ― また なぞれること(詰まらないこと)
	inst._clear_marks()
	await _wait(1)
	if inst._markable_left() <= 0:
		failures.append("なぞり直したあと どこも なぞれない")
		return

	# 指を すべらせる。とちゅうの マスを 飛ばして 動かしても、
	# 通り道の マスが ぜんぶ 取れること
	var before: int = inst.marked.size()
	_press_at(inst, start)
	# 自陣は 島の 下がわなので、上へ 2 マス 分 一気に すべらせる
	var far := Vector2i(start.x, maxi(start.y - 2, 0))
	_move_at(inst, far)
	_release_at(inst, far)
	await _wait(1)
	if inst.marked.size() < before + 2:
		failures.append("指で なぞっても 通り道の マスが 取れない(%d マスしか 取れない)" % [
			inst.marked.size()])

	# 「おまかせ」で 残りが 自動で 埋まること
	inst._auto_mark()
	await _wait(1)
	if inst._marked_cost() < inst.need and inst._markable_left() > 0:
		failures.append("おまかせを 押しても 最後まで 埋まらない(%d/%d)" % [
			inst._marked_cost(), inst.need])
	# 片づけて 本編へ
	inst._on_act()
	await _wait(4)


func _cell_center(inst: Node, cv: Vector2i) -> Vector2:
	var s: float = inst._cell_size()
	return inst._origin() + (Vector2(float(cv.x), float(cv.y)) + Vector2(0.5, 0.5)) * s


func _press_at(inst: Node, cv: Vector2i) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = _cell_center(inst, cv)
	inst._on_board_input(e)


func _move_at(inst: Node, cv: Vector2i) -> void:
	var e := InputEventMouseMotion.new()
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	e.position = _cell_center(inst, cv)
	inst._on_board_input(e)


func _release_at(inst: Node, cv: Vector2i) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = false
	e.position = _cell_center(inst, cv)
	inst._on_board_input(e)
