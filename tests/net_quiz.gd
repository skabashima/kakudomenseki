extends Node
## 展開図マスターの すじみちを 見る(--headless 可)。
##   godot --headless --path . res://tests/net_quiz.tscn
##
## 見るところ:
##   1. 一覧に 展開図が ぜんぶ 出る
##   2. 選択肢は 4 つで、正しい 名まえが ちょうど 1 つ 入っている
##   3. ★ まちがえても 折り上がりが 始まる。
##      この 機能の かなめは「立ち上がる ところを 見る」ことなので、
##      正解の ときだけ 動かす 作りに なっていないかを ここで 止める
##   4. 当てたら 記録される / まちがえたら 記録されない
##   5. 無料で ためせる 数だけ 開いていて、その先は 買うまで 閉じている

var fails: Array = []


func _ready() -> void:
	GameState.premium = false
	GameState.debug_unlock_all = false
	GameState.net_clear = {}

	var scene: Node = load("res://scenes/net_master.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame

	var nets: Array = NetDefs.all()
	if nets.size() < 8:
		fails.append("展開図が %d こしか ない" % nets.size())

	# 5. 無料の 数
	if GameState.net_needs_purchase(GameState.FREE_NETS - 1):
		fails.append("無料の はずの %d 番めが 閉じている" % GameState.FREE_NETS)
	if not GameState.net_needs_purchase(GameState.FREE_NETS):
		fails.append("%d 番めから 先は 買うまで 閉じているはず" % (GameState.FREE_NETS + 1))

	# まちがえる 回
	scene._build_quiz(0)
	await get_tree().process_frame
	var correct := String(nets[0]["solid"])
	var buttons: Array = scene.choice_box.get_children()
	if buttons.size() != 4:
		fails.append("選択肢が %d こ(4 こでないと いけない)" % buttons.size())
	var hit := 0
	var wrong_name := ""
	for b in buttons:
		var txt := _text_of(b as Button)
		if txt == correct:
			hit += 1
		elif wrong_name == "":
			wrong_name = txt
	if hit != 1:
		fails.append("正しい 名まえが %d こ 入っている(1 こだけの はず)" % hit)
	if wrong_name != "":
		scene._answer(buttons[0] as Button, wrong_name, correct)
		await get_tree().process_frame
		if not scene.view.is_processing():
			fails.append("まちがえた ときに 折り上がりが 始まっていない")
		if GameState.net_clear.has(String(nets[0]["id"])):
			fails.append("まちがえたのに 記録されている")

	# 当てる 回
	scene._build_quiz(1)
	await get_tree().process_frame
	var correct2 := String(nets[1]["solid"])
	var btns2: Array = scene.choice_box.get_children()
	scene._answer(btns2[0] as Button, correct2, correct2)
	await get_tree().process_frame
	if not scene.view.is_processing():
		fails.append("当てた ときに 折り上がりが 始まっていない")
	if not GameState.net_clear.has(String(nets[1]["id"])):
		fails.append("当てたのに 記録されていない")

	# 展開図の 挑戦(3 問)― 出どころの 組み合わせが ぜんぶ 問題に なるか
	var ladder: Array = load("res://scenes/problem.gd").NET_LADDER
	if ladder.size() != 10:
		fails.append("挑戦は 10 問の はず(いまは %d 問)" % ladder.size())
	for step in ladder:
		for pick in step:
			var sid := String((pick as Array)[0])
			var tier := int((pick as Array)[1])
			for k in 8:
				var rng := RandomNumberGenerator.new()
				rng.seed = 900 + k
				var q: Dictionary = ProblemGen.generate(sid, rng, tier)
				var a := float(q["answer"])
				if is_nan(a) or is_inf(a):
					fails.append("挑戦の %s tier %d が 数に ならない" % [sid, tier])
				if String(q["q"]).strip_edges() == "":
					fails.append("挑戦の %s tier %d の 問題文が 空" % [sid, tier])

	if fails.is_empty():
		print("NET QUIZ OK: 当たっても はずれても 立ち上がる / 挑戦 10 問も 出る")
		get_tree().quit(0)
	else:
		for f in fails:
			print("FAIL: " + str(f))
		print("NET QUIZ FAILED: %d 件" % fails.size())
		get_tree().quit(1)


func _text_of(btn: Button) -> String:
	for c in btn.get_children():
		if c is RubyLabel:
			return (c as RubyLabel).plain
	return ""
