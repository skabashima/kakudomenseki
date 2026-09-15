extends Node
## 一覧を 流した ときの 重さを 1 コマずつ 測る(要描画環境。--headless 不可)。
##   godot --path . res://tests/perf_scroll.tscn
##
## ★ 前は 「1 コマに かかった 時間」だけを PC の ソフト描画で 測って、
##   速く なった と 判断した。Android の 実機では 直って いなかった。
##   実機の 重さに 効く ものを いっしょに 測る:
##     描画コール … GPU への 命令の 回数。スマホの GPU は ここに 弱い
##     頂点     … 描いた 形の 細かさ
##     間隔 ms   … コマと コマの 実時間。低消費モードで 休む 時間も 入る
##
## 低消費モードを 切った とき(仕事の 重さ)と、出荷と 同じ 入れた ときの
## 両方を 測る。くらべる 相手は ふつうの ステージ一覧。

const FRAMES := 120


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	# 起動の 境目で GameState が 低消費モードを しばらく 切っている。
	# それが もどりきってから 測る(途中で 設定が 書きかわらないように)
	for i in 110:
		await get_tree().process_frame
	GameState.debug_unlock_all = true
	GameState.current_course = "men"

	var lines: Array = []
	for low in [false, true]:
		lines.append(await _run("展開図マスター 展開図→立体", "res://scenes/net_master.tscn", false, low))
		lines.append(await _run("展開図マスター 立体→展開図", "res://scenes/net_master.tscn", true, low))
		lines.append(await _run("ステージ一覧(くらべる相手)", "res://scenes/stage_select.tscn", false, low))
	print("")
	print("PERF 低消費 | 画面                         | 開く ms | 描画コール 平均/最大 | 頂点 平均 | 間隔 ms 平均/最大")
	# ★ Performance.TIME_PROCESS は コマごとに 更新されない(平均と 最大が
	#   同じ 値に なる)ので 使わない。仕事の 重さは 低消費「切」の 間隔で 見る
	for l in lines:
		print(l)
	get_tree().quit(0)


func _run(label: String, path: String, rev: bool, low: bool) -> String:
	OS.low_processor_usage_mode = low
	Engine.max_fps = 60 if low else 0

	var t0 := Time.get_ticks_usec()
	var inst: Node = (load(path) as PackedScene).instantiate()
	add_child(inst)
	await get_tree().process_frame
	if rev and "list_reverse" in inst:
		inst.list_reverse = true
		inst._build_list()
		await get_tree().process_frame
	var open_ms := float(Time.get_ticks_usec() - t0) / 1000.0
	for i in 6:
		await get_tree().process_frame

	var sc: ScrollContainer = _find_scroll(inst)
	if sc == null:
		inst.queue_free()
		return "PERF %s | %s | スクロールが 見つからない" % [_on(low), label]
	var span := maxf(0.0, sc.get_v_scroll_bar().max_value - sc.size.y)

	var calls: Array = []
	var prims: Array = []
	var gaps: Array = []
	var last := Time.get_ticks_usec()
	for k in FRAMES:
		# 下へ 流す(ゆびで なぞる のと 同じく、毎コマ 位置が かわる)
		sc.scroll_vertical = int(span * float(k + 1) / float(FRAMES))
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		gaps.append(float(now - last) / 1000.0)
		last = now
		calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		prims.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))

	inst.queue_free()
	for i in 3:
		await get_tree().process_frame
	return "PERF %s | %-26s | %7.1f | %6.0f / %6.0f | %8.0f | %6.2f / %6.2f" % [
		_on(low), label, open_ms, _avg(calls), _max(calls),
		_avg(prims), _avg(gaps), _max(gaps)]


func _on(low: bool) -> String:
	return "入" if low else "切"


func _find_scroll(n: Node) -> ScrollContainer:
	if "_scroll" in n and n._scroll is ScrollContainer and is_instance_valid(n._scroll):
		return n._scroll
	if n is ScrollContainer:
		return n
	for c in n.get_children():
		var s := _find_scroll(c)
		if s != null:
			return s
	return null


func _avg(a: Array) -> float:
	if a.is_empty():
		return 0.0
	var s := 0.0
	for v in a:
		s += float(v)
	return s / float(a.size())


func _max(a: Array) -> float:
	var m := 0.0
	for v in a:
		m = maxf(m, float(v))
	return m
