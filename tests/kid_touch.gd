extends Node
## ストーリー(小学生)の さわる場面を、**ゆびの 動きで** 通す(--headless 可)。
##   godot --headless --path . res://tests/kid_touch.tscn
##
## kid_check.gd は _act_done() を直に呼ぶので、指で操作できるかは見ていない。
## 実際に「ドラッグしても線が引けない」「タップしても何も起きない」が出たので、
## ここでは press → motion → release を本物の入口(_on_map_input)に流し、
## 3 回とも自力でクリアできるかを見る。
##
## 目標の場所は、絵を描くのに使っている関数から取る。
## 絵と当たり判定がずれたら(押しても反応しない状態)、ここで落ちる。

var failures: Array = []


func _ready() -> void:
	await get_tree().process_frame
	var keep: Dictionary = GameState.kid_clear.duplicate(true)
	var keep_unit := GameState.kid_unit
	GameState.kid_clear = {}
	for u in KidDefs.UNITS:
		await _play(u)
	GameState.kid_clear = keep
	GameState.kid_unit = keep_unit
	GameState.save_game()
	if failures.is_empty():
		print("KID TOUCH OK: %d 単元 すべて ゆびで 通せた" % KidDefs.UNITS.size())
	else:
		for f in failures:
			print("FAIL: " + str(f))
		print("KID TOUCH FAILED: %d 件" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)


func _play(u: Dictionary) -> void:
	GameState.kid_unit = String(u["id"])
	var inst: Node = (load("res://scenes/kid_unit.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(inst)
	await _wait(8)
	for i in (u["intro"] as Array).size():
		inst._advance()
		await _wait(1)
	if inst.phase != 1:
		failures.append("%s: さわる場面に入らない" % u["id"])
		inst.queue_free()
		await _wait(1)
		return
	for round_i in 3:
		var before: int = inst.tries
		await _do_act(inst, String(u["act"]))
		if inst.tries <= before:
			failures.append("%s(%s): %d 回め ― ゆびで動かしても できたことに ならない" % [
				u["id"], String(u["act"]), round_i + 1])
			break
		if round_i < 2:
			inst._advance()
			await _wait(2)
	inst.queue_free()
	await _wait(1)


func _wait(n: int) -> void:
	for i in n:
		await get_tree().process_frame


# =========================================================
# さわり方ごとの ゆびの 動き
# =========================================================

## 目標の 場所は、絵を 描くのに 使っている 関数から とる。
## 絵と 当たり判定が ずれたら(押しても 反応しない)ここで 落ちる
func _do_act(inst: Node, act: String) -> void:
	var s: float = inst._cell()
	var o: Vector2 = inst._grid_origin()
	match act:
		"tear":
			var tri: Array = inst.st["tri"]
			for i in 3:
				var from: Vector2 = inst._to_screen(tri[i])
				var to := Vector2(120.0 + 140.0 * float(i), inst._line_y() - 60.0)
				await _drag(inst, from, to)
		"slide":
			await _drag(inst, inst._slide_points()[0], inst._slide_target()[0])
		"fold":
			if bool(inst.st.get("tape", false)):
				# 紙テープの ななめ折り(k8)。右はしを 折り返し先まで 運ぶ
				var h: Vector2 = inst._tape_screen(inst._tape_handle())
				var m: Vector2 = inst._tape_screen(inst._tape_fold_pt(inst._tape_handle(), 1.0))
				await _drag(inst, h, m)
			else:
				var br: Vector2 = inst._to_screen(Vector2(5.0, -3.5))
				var bl: Vector2 = inst._to_screen(Vector2(-5.0, -3.5))
				await _drag(inst, br, bl - Vector2(30.0, 0))
		"diag":
			var pts: Array = inst._diag_points()
			var n: int = inst.st["n"]
			for i in range(2, n - 1):
				await _drag(inst, pts[0], pts[i])
		"clock":
			await _turn_clock(inst)
		"grid":
			await _drag(inst, o + Vector2(s * 2.0, -s * 2.0),
				o + Vector2(s * float(inst.st["tw"]), -s * float(inst.st["th"])))
		"cut":
			var parts: Array = inst._cut_shapes()
			var piece: PackedVector2Array = parts[1]
			var mid := Vector2.ZERO
			for q in piece:
				mid += q
			mid /= float(piece.size())
			var to_v: Vector2 = parts[2]
			await _drag(inst, mid, mid + to_v * 1.05)
		"roll":
			var rr := minf((inst.map.size.x - 90.0) / (TAU + 2.0), inst.map.size.y * 0.16)
			await _drag(inst, Vector2(50.0 + rr, inst.map.size.y * 0.5),
				Vector2(50.0 + rr + TAU * rr + 6.0, inst.map.size.y * 0.5))
		"shift":
			var from_v := float(inst.st["from"])
			await _drag(inst, o + Vector2(s * 0.5, -s), 
				o + Vector2(s * (from_v + 3.5), -s))
		"stack":
			var total: int = int(inst.st["bw"]) * int(inst.st["bd"]) * int(inst.st["bh"])
			for i in total:
				await _tap(inst, Vector2(inst.map.size.x * 0.5, inst.map.size.y * 0.5))
		"open":
			await _drag(inst, Vector2(inst.map.size.x * 0.5, inst.map.size.y * 0.45),
				Vector2(inst.map.size.x * 0.5 + s * 3.2, inst.map.size.y * 0.45))
		"pour":
			await _drag(inst, Vector2(o.x + s * 7.0, o.y - s),
				Vector2(o.x + s * 4.0 + s * (float(inst.st["from"]) + 2.0), o.y - s))
		_:
			await _drag(inst, Vector2(o.x + s * 2.0, o.y - s * 2.0),
				Vector2(o.x + s * 2.0, o.y - s * 5.0))


## 針を まわす。指を 円の ふちに そって 少しずつ 動かす
func _turn_clock(inst: Node) -> void:
	var center: Vector2 = inst._clock_center()
	var rr: float = inst._clock_radius() - 30.0
	var goal := float(inst.st["goal"])
	await _press(inst, center + Vector2(0, -rr))
	var a := 0.0
	while a < goal:
		a = minf(a + 15.0, goal)
		var t := deg_to_rad(a)
		await _move(inst, center + Vector2(sin(t), -cos(t)) * rr)
	await _up(inst, center + Vector2(sin(deg_to_rad(goal)), -cos(deg_to_rad(goal))) * rr)


# =========================================================
# ゆびの 出来事(本物の 入口に 流す)
# =========================================================

func _drag(inst: Node, from: Vector2, to: Vector2) -> void:
	await _press(inst, from)
	for i in range(1, 6):
		await _move(inst, from.lerp(to, float(i) / 5.0))
	await _up(inst, to)


func _tap(inst: Node, at: Vector2) -> void:
	await _press(inst, at)
	await _up(inst, at)


func _press(inst: Node, at: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	inst._on_map_input(e)
	await _wait(1)


func _up(inst: Node, at: Vector2) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = false
	e.position = at
	inst._on_map_input(e)
	await _wait(1)


func _move(inst: Node, at: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = at
	inst._on_map_input(e)
	await _wait(1)
