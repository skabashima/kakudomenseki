extends Node
## 一時検証用: 問題シーンで「解き方」を指定ステップまで進めてスクショを撮る
func _ready() -> void:
	var course := "kaku"
	var index := 7
	var presses := 2
	var out := "/tmp/wt.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--course="):
			course = arg.substr(9)
		if arg.begins_with("--index="):
			index = int(arg.substr(8))
		if arg.begins_with("--presses="):
			presses = int(arg.substr(10))
		if arg.begins_with("--out="):
			out = arg.substr(6)
	await get_tree().process_frame
	GameState.current_course = course
	GameState.current_stage = index
	GameState.mode = "normal"
	var scene: Node = (load("res://scenes/problem.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	await get_tree().process_frame
	for i in presses:
		scene._on_walkthrough()
		await get_tree().create_timer(0.55).timeout
	await get_tree().create_timer(0.2).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(out)
	print("saved " + out)
	get_tree().quit(0)
