extends Node
class_name DragScroll
## ScrollContainer を「指でなぞって」スクロールできるようにする補助ノード。
##
## Godot 標準の ScrollContainer のタッチスクロールは、
##   ・ボタンなど子コントロールが先にタッチを取ってしまうと始まらない
##   ・環境によってはタッチスクリーン判定に依存する
## ため、カードやボタンで埋まった一覧では実機で動かないことがある。
## ここでは _input(GUI より前)でドラッグを見て、自前でスクロールする。
##
## 使い方: DragScroll.attach(scroll_container)

## この距離(px)を超えて動いたら「スクロール操作」とみなし、ボタンの反応を止める
const DEAD_ZONE := 12.0
## 指を離したあとの慣性(0 で慣性なし)
const FRICTION := 0.88
const MIN_FLICK := 40.0

var scroll: ScrollContainer
var _dragging := false
var _scrolled := false
var _last_pos := Vector2.ZERO
var _velocity := 0.0
var _synth := false            # 自分で流した入力を自分で拾わないための目印


static func attach(sc: ScrollContainer) -> DragScroll:
	var d := DragScroll.new()
	d.scroll = sc
	sc.add_child(d)
	return d


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	# 指を離したあとの慣性スクロール
	if _dragging or absf(_velocity) < 1.0:
		return
	if not is_instance_valid(scroll):
		return
	scroll.scroll_vertical = int(round(scroll.scroll_vertical - _velocity * delta))
	_velocity *= FRICTION


func _input(event: InputEvent) -> void:
	if _synth:
		return
	if not is_instance_valid(scroll) or not scroll.is_visible_in_tree():
		return
	var rect := Rect2(scroll.global_position, scroll.size)

	# --- 指を置く / 離す ---
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_begin(t.position, rect)
		else:
			_end()
			if _scrolled:
				# なぞった後の指離しでボタンが反応しないようにする
				get_viewport().set_input_as_handled()
			_scrolled = false
		return
	if event is InputEventMouseButton:
		var m := event as InputEventMouseButton
		if m.button_index == MOUSE_BUTTON_LEFT:
			if m.pressed:
				_begin(m.position, rect)
			else:
				_end()
				if _scrolled:
					get_viewport().set_input_as_handled()
				_scrolled = false
		return

	# --- なぞる ---
	var pos := Vector2.ZERO
	if event is InputEventScreenDrag:
		pos = (event as InputEventScreenDrag).position
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if not (mm.button_mask & MOUSE_BUTTON_MASK_LEFT):
			return
		pos = mm.position
	else:
		return
	if not _dragging:
		return
	var dy := pos.y - _last_pos.y
	_last_pos = pos
	if not _scrolled and absf(pos.y - _start_y) < DEAD_ZONE:
		return   # 小さな揺れはタップとして扱う(ボタンを押せるようにする)
	if not _scrolled:
		_cancel_press()   # なぞり始めた時点で、押されかけの見た目を解く
	_scrolled = true
	scroll.scroll_vertical = int(round(scroll.scroll_vertical - dy))
	_velocity = dy * 12.0
	get_viewport().set_input_as_handled()


var _start_y := 0.0


func _begin(pos: Vector2, rect: Rect2) -> void:
	if not rect.has_point(pos):
		return
	_dragging = true
	_scrolled = false
	_last_pos = pos
	_start_y = pos.y
	_velocity = 0.0


func _end() -> void:
	_dragging = false
	if absf(_velocity) < MIN_FLICK:
		_velocity = 0.0


func _cancel_press() -> void:
	## 指を置いた時点でボタンは「押下中」になる。なぞりに移ったら指離しを
	## 握りつぶす(＝ボタンを誤作動させない)ので、そのままだと押された表示のまま
	## 固まり、選んでいないのに選ばれて見える。
	##
	## ★ 離すだけでは足りない。ボタンは「押してから指が外へ出たか」を
	##   マウス移動で判断していて、なぞりはこちらが握りつぶすため外へ出たことを
	##   知らない。そのまま離すと**押されたと判定して反応してしまう**。
	##   画面外への移動 → 離す の順で流して、確実に取り消す。
	var vp := get_viewport()
	if vp == null:
		return
	const FAR := Vector2(-10000, -10000)
	_synth = true
	var mm := InputEventMouseMotion.new()
	mm.position = FAR
	mm.global_position = FAR
	mm.button_mask = MOUSE_BUTTON_MASK_LEFT
	vp.push_input(mm)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = false
	ev.position = FAR
	ev.global_position = FAR
	vp.push_input(ev)
	_synth = false
	GameState.clear_touch_highlight()   # ホバーとフォーカスの残りも消す
