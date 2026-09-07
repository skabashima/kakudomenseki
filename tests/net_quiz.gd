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

	# 挑戦 10問 / 応用 10問 は 買った 人だけ
	if GameState.net_runs_open():
		fails.append("買っていないのに 挑戦・応用が 開いている")
	GameState.premium = true
	if not GameState.net_runs_open():
		fails.append("買ったのに 挑戦・応用が 開かない")
	GameState.premium = false

	# 挑戦 10問: 101 とおりから かぶらずに 10 問 えらべるか
	scene._start_run()
	await get_tree().process_frame
	if scene.run_ids.size() != 10:
		fails.append("挑戦は 10 問の はず(いまは %d 問)" % scene.run_ids.size())
	var seen_ids := {}
	var rev_n := 0
	for v in scene.run_ids:
		var item: Dictionary = v
		seen_ids[int(item["i"])] = true
		if bool(item["rev"]):
			rev_n += 1
	if seen_ids.size() != scene.run_ids.size():
		fails.append("挑戦の 出題が かぶっている")
	# 「展開図 → 立体」と「立体 → 展開図」を かわりばんこに 出す
	if rev_n != 5:
		fails.append("逆向きの 問いが %d 問(5 問の はず)" % rev_n)

	# ★ 誤答の 判定に つかう「ほんものの 展開図」は、クイズの 一覧では なく
	#   その 立体を 数えつくした ものを つかう こと。
	#   一覧は 立体ごとに 打ち切っている ので、四角柱なら 29 とおり あるのに
	#   8 とおりしか 入っていない ―― 残りを「まちがい」として 出して しまう
	var listed := 0
	for n in NetDefs.all():
		if String(n["id"]).begins_with("prism4_"):
			listed += 1
	var whole: int = NetDefs._valid_signatures("prism4_0").size()
	if whole <= listed:
		fails.append("四角柱の 展開図が 全数 %d / 一覧 %d ― 数えつくせていない" % [
			whole, listed])

	# 逆向きの 選択肢: 正しい 展開図 1 つと、それを くずした 3 つ。
	# ★ 見た だけで 分かる ちがう 立体を ならべない。
	# ★ くずした ものが たまたま 正しい 展開図に なっていない こと。
	#    立方体の 展開図は 11 とおり あるので、これを 見ないと
	#    「正解が 2 つ ある」問いが できて しまう
	var all_nets: Array = NetDefs.all()
	for k in 14:
		var at := (k * 7) % all_nets.size()
		var picks: Array = scene._net_choices(at)
		if picks.size() != 4:
			fails.append("逆向きの 選択肢が %d こ" % picks.size())
			break
		var real_n := 0
		var solids := {}
		var sigs := {}
		for q in picks:
			var row: Dictionary = q
			if not bool(row.get("fake", false)):
				real_n += 1
			solids[String(row["solid"])] = true
			sigs[NetDefs._signature(row["faces"])] = true
		# 円柱・円錐は 面を 24 に 分けているので くずしても 見た目が 変わらない。
		# その ときだけ ちがう 立体を ならべる(正解は やはり 1 つ)
		if bool((all_nets[at] as Dictionary).get("round", false)):
			if solids.size() != 4:
				fails.append("まるい 立体の 選択肢に 同じ 立体が まざっている")
				break
		elif real_n != 1:
			fails.append("組み立てられる 展開図が %d こ(1 こだけの はず)" % real_n)
			break
		if sigs.size() != 4:
			fails.append("同じ 形の 選択肢が まざっている")
			break
		# くずした ものが その 立体の ほんとうの 展開図に なっていないか
		var real_sigs: Dictionary = NetDefs._valid_signatures(
			String((all_nets[at] as Dictionary)["id"]))
		for q in picks:
			var row2: Dictionary = q
			if not bool(row2.get("fake", false)):
				continue
			if real_sigs.has(NetDefs._signature(row2["faces"])):
				fails.append("くずした はずが 正しい 展開図に なっている")
				break
	scene.run_ids = []

	# 展開図の 応用(10 問)― 出どころの 組み合わせが ぜんぶ 問題に なるか
	var ladder: Array = load("res://scenes/problem.gd").NET_LADDER
	if ladder.size() != 10:
		fails.append("応用は 10 問の はず(いまは %d 問)" % ladder.size())
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
		print("NET QUIZ OK: 当たっても はずれても 立ち上がる / 挑戦・応用の 10 問も 出る")
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
