extends SceneTree
## アイコン候補の比較シートを作るツール(一時利用)。
##   godot --headless --path . -s tools/icon_preview.gd -- --dir=<svgのあるフォルダ> --out=<出力png>
## 各候補を 1024 で描き、iOS の角丸マスクを模した 256/120/60 を横に並べる。

const BG := Color(0.80, 0.82, 0.85)

func _init() -> void:
	var dir_path := ""
	var out := "/tmp/icon_sheet.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--dir="):
			dir_path = arg.substr(6)
		if arg.begins_with("--out="):
			out = arg.substr(6)
	var names: Array = []
	var d := DirAccess.open(dir_path)
	for f in d.get_files():
		if f.ends_with(".svg"):
			names.append(f)
	names.sort()
	var sizes := [256, 120, 60]
	var pad := 24
	var row_h := 256 + pad
	var sheet := Image.create(pad + 256 + pad + 120 + pad + 60 + pad, row_h * names.size() + pad, false, Image.FORMAT_RGBA8)
	sheet.fill(BG)
	for i in names.size():
		var svg := FileAccess.get_file_as_string(dir_path.path_join(names[i]))
		var big := Image.new()
		if big.load_svg_from_string(svg, 1.0) != OK:
			push_error("SVG 失敗: " + names[i])
			quit(1)
			return
		big.save_png(dir_path.path_join(names[i].get_basename() + "_1024.png"))
		var x := pad
		for s in sizes:
			var im := big.duplicate()
			im.resize(s, s, Image.INTERPOLATE_LANCZOS)
			_round_mask(im)
			sheet.blend_rect(im, Rect2i(0, 0, s, s), Vector2i(x, pad + row_h * i))
			x += s + pad
	sheet.save_png(out)
	print("wrote " + out)
	quit(0)


## iOS の角丸(一辺の約 22.4%)を模して外側を透明にする
func _round_mask(im: Image) -> void:
	var n := im.get_width()
	var r := n * 0.2237
	for y in n:
		for x in n:
			var dx := maxf(r - (x + 0.5), (x + 0.5) - (n - r))
			var dy := maxf(r - (y + 0.5), (y + 0.5) - (n - r))
			if dx > 0.0 and dy > 0.0 and Vector2(dx, dy).length() > r:
				im.set_pixel(x, y, Color(0, 0, 0, 0))
