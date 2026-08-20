extends SceneTree
## ストア用/Android 用アイコン PNG を SVG から生成するツール。
##   godot --headless --path . -s tools/make_icons.gd
##
## 出力:
##   store/icon/icon_1024.png       … App Store 用(1024×1024・透過禁止なので RGB)
##   store/icon/launcher_192.png    … Android の旧来のランチャーアイコン(角丸つき)
##   store/icon/adaptive_bg_432.png … アダプティブアイコンの背景(432×432)
##   store/icon/adaptive_fg_432.png … アダプティブアイコンの前景(432×432・透過)
##   store/icon/adaptive_mono_432.png … テーマ付きアイコンの単色版(432×432・透過)
##
## アダプティブアイコンは 432×432 のうち **中央 66%(288px)しか必ず見える保証がない**
## (端末ごとに円・角丸・しずくなど任意の形でくり抜かれる)。
## そのため前景は絵柄を 276px に収めて中央に置き、背景は地のグラデーションだけにする。

const FULL_SVG := "res://store/icon/icon_full.svg"
const ROUND_SVG := "res://icon.svg"
const OUT_DIR := "res://store/icon"

## 絵柄(狙いを定める枠)の外周。icon_full.svg の 1024 座標系での位置
const ART_MIN := 140.0
const ART_MAX := 884.0
## アダプティブアイコンの一辺と、そこに収める絵柄の大きさ
const ADAPTIVE := 432.0
const ART_TARGET := 276.0


func _init() -> void:
	var full := FileAccess.get_file_as_string(FULL_SVG)
	if full == "":
		_die("%s が読めません" % FULL_SVG)
		return

	# 1) App Store 用 1024×1024(透過なし)
	var img := _rasterize(full, 1.0)
	if img == null:
		return
	img.convert(Image.FORMAT_RGB8)   # アルファを外す(App Store 要件)
	_save(img, "icon_1024.png")

	# 2) Android の旧来のランチャーアイコン(角丸つきの版から)
	var round_svg := FileAccess.get_file_as_string(ROUND_SVG)
	if round_svg == "":
		_die("%s が読めません" % ROUND_SVG)
		return
	# icon.svg は width=128 で書いてあるので、192px にするには 1.5 倍
	var launcher := _rasterize(round_svg, 192.0 / 128.0)
	if launcher == null:
		return
	_save(launcher, "launcher_192.png")

	# 3) アダプティブアイコンの背景(地のグラデーションだけ)
	var bg := _rasterize(_background_svg(full), 1.0)
	if bg == null:
		return
	_save(bg, "adaptive_bg_432.png")

	# 4) アダプティブアイコンの前景(絵柄だけ・透過)
	var fg := _rasterize(_foreground_svg(full), 1.0)
	if fg == null:
		return
	_save(fg, "adaptive_fg_432.png")

	# 5) テーマ付きアイコン(Android 13+)の単色版。
	#    指定しないと Godot 既定の「ロボットのロゴ」が入ってしまう
	var mono := _rasterize(_monochrome_svg(full), 1.0)
	if mono == null:
		return
	_save(mono, "adaptive_mono_432.png")

	print("done")
	quit(0)


## 地の色だけの SVG(432×432)。<rect> までを残し、絵柄は落とす
func _background_svg(full: String) -> String:
	var defs := _between(full, "<defs>", "</defs>")
	var rect := ""
	var i := full.find("<rect")
	if i >= 0:
		rect = full.substr(i, full.find("/>", i) + 2 - i)
	return ('<svg xmlns="http://www.w3.org/2000/svg" width="432" height="432" '
		+ 'viewBox="0 0 1024 1024"><defs>' + defs + "</defs>" + rect + "</svg>")


## 絵柄だけの SVG(432×432・透過)。マスクで欠けないよう中央 276px に収める
func _foreground_svg(full: String) -> String:
	var i := full.find("<rect")
	var art := full.substr(full.find("/>", i) + 2)
	art = art.replace("</svg>", "")
	var s := ART_TARGET / (ART_MAX - ART_MIN)
	var t := ADAPTIVE * 0.5 - 512.0 * s
	return ('<svg xmlns="http://www.w3.org/2000/svg" width="432" height="432" '
		+ 'viewBox="0 0 432 432"><g transform="translate(%f,%f) scale(%f)">' % [t, t, s]
		+ art + "</g></svg>")


## テーマ付きアイコン用の単色 SVG。絵柄を白一色にする(OS 側で好きな色に染められる)
func _monochrome_svg(full: String) -> String:
	var svg := _foreground_svg(full)
	for color in ["#7ea6e0", "#2f5aa8", "#ffd94d", "#ebf2ff"]:
		svg = svg.replace('fill="%s"' % color, 'fill="#ffffff"')
		svg = svg.replace('stroke="%s"' % color, 'stroke="#ffffff"')
	return svg.replace('opacity="0.85"', 'opacity="1"')


func _between(s: String, head: String, tail: String) -> String:
	var a := s.find(head)
	var b := s.find(tail)
	if a < 0 or b < 0:
		return ""
	return s.substr(a + head.length(), b - a - head.length())


func _rasterize(svg: String, scale: float) -> Image:
	var img := Image.new()
	var err := img.load_svg_from_string(svg, scale)
	if err != OK:
		_die("SVG のラスタライズに失敗: err=%d" % err)
		return null
	return img


func _save(img: Image, file_name: String) -> void:
	var err := img.save_png(OUT_DIR.path_join(file_name))
	if err != OK:
		_die("PNG の書き出しに失敗(%s): err=%d" % [file_name, err])
		return
	print("wrote %s/%s (%dx%d)" % [OUT_DIR, file_name, img.get_width(), img.get_height()])


func _die(msg: String) -> void:
	push_error(msg)
	quit(1)
