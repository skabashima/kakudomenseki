extends Node
func _ready() -> void:
	await get_tree().process_frame
	var out := "s.png"
	var sid := "e8"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.substr(6)
		if arg.begins_with("--stage="): sid = arg.substr(8)
	GameState.premium = true
	GameState.mode = "normal"
	for cid in ["kaku", "men"]:
		var stages: Array = ProblemGen.stages_of(cid)
		for i in stages.size():
			if String(stages[i]["id"]) == sid:
				GameState.current_course = cid
				GameState.current_stage = i
	var inst: Node = (load("res://scenes/problem.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(inst)
	for i in 24: await get_tree().process_frame
	inst._show_hint()
	for i in 10: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out)
	print("SHOT ", sid)
	get_tree().quit(0)
