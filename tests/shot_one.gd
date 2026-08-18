extends Control
## 一時検証用: 指定ステージ・tier の図形と問題文だけ描画する
var stage := "e4"
var tier := 3
func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--stage="):
			stage = arg.substr(8)
		if arg.begins_with("--tier="):
			tier = int(arg.substr(7))
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.13, 0.24)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var p: Dictionary = ProblemGen.generate(stage, rng, tier)
	var fv := FigureView.new()
	fv.set_anchors_preset(Control.PRESET_FULL_RECT)
	fv.offset_bottom = -320
	fv.set_spec(p["fig"])
	add_child(fv)
	var lbl := Label.new()
	lbl.text = String(p["q"]) + "\n答え: " + str(p["answer"])
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	lbl.offset_top = -300
	lbl.offset_left = 20
	lbl.offset_right = -20
	lbl.add_theme_font_size_override("font_size", 30)
	add_child(lbl)
	for i in 8:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var out := "/tmp/shot_one.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.substr(6)
	img.save_png(out)
	get_tree().quit(0)
