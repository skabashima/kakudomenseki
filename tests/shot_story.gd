extends Node
## 一時検証用: ストーリーの依頼場面で正解を選んだ直後を撮る(要描画環境)
##   godot --path . res://tests/shot_story.tscn -- --ch=ch2 --scene=3 --out=a.png
## 正解のあとに「つぎへ」がちゃんと出ているかを目で見るため。
## GameState の読み込みが 1 フレーム遅れて入るので、章の指定はそのあとに行う。
func _ready() -> void:
	await get_tree().process_frame
	var ch := 'ch2'
	var idx := 3
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with('--ch='): ch = arg.substr(5)
		if arg.begins_with('--scene='): idx = int(arg.substr(8))
	GameState.story_chapter = ch
	GameState.story_scene = idx
	var inst: Node = (load('res://scenes/story.tscn') as PackedScene).instantiate()
	get_tree().root.add_child(inst)
	for i in 20: await get_tree().process_frame
	var ans := float(inst.problem['answer'])
	inst._pick_answer(ans, ans)
	for i in 30: await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var out := 'shot_story.png'
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with('--out='): out = arg.substr(6)
	img.save_png(out)
	print('SHOT ', out, ' next_btn=', inst.next_btn != null)
	get_tree().quit(0)
