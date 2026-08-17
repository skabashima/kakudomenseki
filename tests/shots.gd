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
	GameState.current_course = "kaku"
	await _shot("res://scenes/stage_select.tscn", "02_stage_select_kaku")
	GameState.current_course = "men"
	await _shot("res://scenes/stage_select.tscn", "02b_stage_select_men")
	# 各編の代表ステージ(index は COURSES の並び順)
	var picks := [
		["kaku", 0, "10_problem_e1"], ["kaku", 3, "10b_problem_e11_clock"],
		["kaku", 5, "10c_problem_e17_polygon"], ["kaku", 6, "10d_problem_e12_boomerang"],
		["kaku", 7, "10e_problem_e13_fold"], ["kaku", 10, "13c_problem_j11_star"],
		["kaku", 13, "13d_problem_j12_arc"], ["kaku", 14, "16b_problem_s11_trig"],
		["kaku", 15, "16c_problem_s12_vector"],
		["men", 3, "11_problem_e8"], ["men", 4, "11b_problem_e14_road"],
		["men", 6, "11c_problem_e15_point"], ["men", 7, "11d_problem_e16_ratio"],
		["men", 8, "12_problem_e10"], ["men", 14, "15_problem_j10"],
		["men", 15, "16_problem_s1"], ["men", 22, "18_problem_s8"], ["men", 24, "19_problem_s10"]]
	for p in picks:
		GameState.current_course = p[0]
		GameState.current_stage = p[1]
		GameState.mode = "normal"
		await _shot("res://scenes/problem.tscn", p[2])
	await _shot("res://scenes/challenge_select.tscn", "03_challenge")
	await _shot("res://scenes/records.tscn", "04_records")

	# --- 同じステージを 3 回出題: 数値と図が毎回変わることの確認 ---
	GameState.current_course = "kaku"
	GameState.current_stage = 0      # e1 三角形の角
	for i in 3:
		await _shot("res://scenes/problem.tscn", "30_vary_e1_%d" % i)
	GameState.current_course = "men"
	GameState.current_stage = 9      # j5 三平方の定理
	for i in 3:
		await _shot("res://scenes/problem.tscn", "31_vary_j5_%d" % i)

	# --- iPhone のノッチ/ホームバーを再現してレイアウト検証 ---
	# (論理座標で 上 118 / 下 66 は iPhone 15 クラス相当)
	GameState.debug_safe_insets = {"top": 118.0, "bottom": 66.0}
	await _shot("res://scenes/main.tscn", "40_notch_main")
	GameState.current_course = "kaku"
	await _shot("res://scenes/stage_select.tscn", "41_notch_stage_select")
	GameState.current_stage = 0
	await _shot("res://scenes/problem.tscn", "42_notch_problem")
	GameState.debug_safe_insets = {}

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
