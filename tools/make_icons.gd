extends SceneTree
## ストア用アイコン PNG を SVG から生成するツール。
##   godot --headless --path . -s tools/make_icons.gd
## App Store の 1024×1024 は透過禁止なので、不透明のフルブリード版
## (store/icon/icon_full.svg)から書き出して RGB に落とす。

func _init() -> void:
	var svg := FileAccess.get_file_as_string("res://store/icon/icon_full.svg")
	if svg == "":
		push_error("store/icon/icon_full.svg が読めません")
		quit(1)
		return
	var img := Image.new()
	# SVG は 128px 基準 → 8 倍で 1024px
	var err := img.load_svg_from_string(svg, 8.0)
	if err != OK or img.get_width() != 1024:
		push_error("SVG のラスタライズに失敗: err=%d size=%d" % [err, img.get_width()])
		quit(1)
		return
	img.convert(Image.FORMAT_RGB8)   # アルファを外す(App Store 要件)
	img.save_png("res://store/icon/icon_1024.png")
	print("wrote store/icon/icon_1024.png (%dx%d)" % [img.get_width(), img.get_height()])
	quit(0)
