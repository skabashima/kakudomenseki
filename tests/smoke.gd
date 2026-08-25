extends Node
## 全シーンをロードして起動確認するスモークテスト(--headless 可)。
##   godot --headless --path . res://tests/smoke.tscn
## 各シーンを順にインスタンス化し、数フレーム回してエラーが出ないことを確かめる。
## problem シーンは 3 コース × 通常/チャレンジで試す。

var checks: Array = []


func _ready() -> void:
	await _run()


func _run() -> void:
	# root がシーンツリーを組み立て中に add_child しないよう 1 フレーム待つ
	await get_tree().process_frame
	# 全ステージを開いた状態で確認する。未購入のまま有料ステージを開くと
	# problem シーンが解放画面へ遷移し、テストシーンごと差し替わって止まる
	var saved_premium: bool = GameState.premium
	GameState.premium = true
	# 通常画面
	await _open("res://scenes/main.tscn")
	await _open("res://scenes/challenge_select.tscn")
	await _open("res://scenes/records.tscn")
	await _open("res://scenes/store.tscn")
	await _open("res://scenes/story_select.tscn")
	await _open("res://scenes/story.tscn")
	await _open("res://scenes/kid_select.tscn")
	await _open("res://scenes/kid_unit.tscn")
	# コースごとのステージ一覧と問題シーン(各コースの最初と最後のステージ)
	for course in ProblemGen.COURSES:
		var cid := String(course["id"])
		GameState.current_course = cid
		await _open("res://scenes/stage_select.tscn")
		for idx in [0, course["stages"].size() - 1]:
			GameState.mode = "normal"
			GameState.current_stage = idx
			await _open("res://scenes/problem.tscn")
	# チャレンジ 2 モード
	GameState.mode = "time"
	GameState.challenge_course = "all"
	await _open("res://scenes/problem.tscn")
	GameState.mode = "survival"
	await _open("res://scenes/problem.tscn")

	GameState.premium = saved_premium

	var bad := 0
	for c in checks:
		if not c[1]:
			bad += 1
			print("FAIL: " + c[0])
	if bad == 0:
		print("SMOKE OK: %d scene loads" % checks.size())
		get_tree().quit(0)
	else:
		print("SMOKE FAILED: %d issues" % bad)
		get_tree().quit(1)


func _open(path: String) -> void:
	var packed: PackedScene = load(path)
	if packed == null:
		checks.append([path + " (load)", false])
		return
	var inst := packed.instantiate()
	get_tree().root.add_child(inst)
	# _ready と数フレームの _process を回す
	for i in 5:
		await get_tree().process_frame
	checks.append([path, true])
	inst.queue_free()
	await get_tree().process_frame
