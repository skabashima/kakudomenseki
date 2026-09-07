extends Control
## 展開図が 立ち上がる ところを 1 枚の 絵に して 目で 見る。
##   godot --path . res://tests/shot_net.tscn -- --out=<png>
##
## 折り上がりが 閉じるかは tests/net_check.gd が 数えて 見るが、
## 「見た目が 展開図に 見えるか」「途中が おかしくないか」は 目でしか 分からない。

const STEPS := 5


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.12, 0.21)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.substr(7)
	var nets: Array = NetDefs.all()
	if only != "":
		nets = nets.filter(func(n): return only.split(",").has(String(n["id"])))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(grid)
	for net in nets:
		for k in STEPS:
			var v := NetView.new()
			v.custom_minimum_size = Vector2(232, 232)
			grid.add_child(v)
			v.show_net(net)
			v.t = float(k) / float(STEPS - 1)
			v.queue_redraw()
	for i in 8:
		await get_tree().process_frame
	var out := "user://shot_net.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.substr(6)
	get_viewport().get_texture().get_image().save_png(out)
	print("saved: " + out)
	get_tree().quit(0)
