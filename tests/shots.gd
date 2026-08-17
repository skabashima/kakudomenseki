extends Node
## 各画面のスクリーンショットを撮ってレイアウトを目視検証する(要描画環境)。
##   godot --path . res://tests/shots.tscn -- --shots-dir=<出力先>
## ヘッドレスでは動かない(描画が必要)。

var out_dir := "user://shots"


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots-dir="):
			out_dir = arg.substr("--shots-dir=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)
	await _run()


func _run() -> void:
	await get_tree().process_frame
	GameState.debug_unlock_all = true
	await _shot("res://scenes/main.tscn", "01_main")
	GameState.current_course = "e"
	await _shot("res://scenes/stage_select.tscn", "02_stage_select_e")
	# 各コースの代表ステージ
	var picks := [["e", 0, "10_problem_e1"], ["e", 7, "11_problem_e8"], ["e", 9, "12_problem_e10"],
		["j", 2, "13_problem_j3"], ["j", 8, "14_problem_j9"], ["j", 9, "15_problem_j10"],
		["s", 0, "16_problem_s1"], ["s", 5, "17_problem_s6"], ["s", 7, "18_problem_s8"], ["s", 9, "19_problem_s10"]]
	for p in picks:
		GameState.current_course = p[0]
		GameState.current_stage = p[1]
		GameState.mode = "normal"
		await _shot("res://scenes/problem.tscn", p[2])
	await _shot("res://scenes/challenge_select.tscn", "03_challenge")
	await _shot("res://scenes/records.tscn", "04_records")
	print("SHOTS DONE -> " + out_dir)
	get_tree().quit(0)


func _shot(path: String, shot_name: String) -> void:
	var packed: PackedScene = load(path)
	var inst := packed.instantiate()
	get_tree().root.add_child(inst)
	for i in 8:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(shot_name + ".png"))
	inst.queue_free()
	await get_tree().process_frame
