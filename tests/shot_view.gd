extends Node
## 一時検証用: 好きな画面を 1 枚だけ撮る(要描画環境)。
##   godot --path . res://tests/shot_view.tscn -- --scene=kid_map --out=a.png
##
## 使える指定:
##   --scene=<scenes/ の名前>   撮る画面
##   --unit=k5                  ストーリー(小学生)の単元
##   --ch=ch4 --idx=3           ストーリー(中学生・高校生)の章と場面
##   --mode=jhs|hs              ストーリーのモード
##   --cleared=9                たからのちずを 9 歩 進んだ ことにする
##   --sclear=21                ストーリーの 章を 21 まで クリアした ことにする
##   --act --try=1              小学生の単元の さわる場面(何回めか)
##   --deg=210                  時計の 針を そこまで まわした ところ
##   --quiz                     小学生の単元を しるし(問題)まで 進める
##   --island-quiz              島取りの 問題画面
##   --island-claim             島取りで 正解して なぞっている ところ
##   --wait=40                  撮るまでに 待つ フレーム数
func _ready() -> void:
	await get_tree().process_frame
	var scene := "main"
	var out := "shot_view.png"
	var cleared := 0
	var sclear := 0
	var wait := 30
	var quiz := false
	var island := 0
	var turns := 0
	var act := false
	var deg := -1.0
	var tri := 0
	var netq := -1                 # 展開図マスターの 何番めの クイズか
	var hold := false              # できた ところで 止める(つぎへ 進めない)
	var netfold := false           # 答えて 立ち上がった ところまで 進めるか
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="): scene = arg.substr(8)
		if arg.begins_with("--netq="): netq = int(arg.substr(7))
		if arg == "--netfold": netfold = true
		if arg == "--hold": hold = true
		if arg.begins_with("--out="): out = arg.substr(6)
		if arg.begins_with("--unit="): GameState.kid_unit = arg.substr(7)
		if arg.begins_with("--ch="): GameState.story_chapter = arg.substr(5)
		if arg.begins_with("--idx="): GameState.story_scene = int(arg.substr(6))
		if arg.begins_with("--mode="): GameState.story_mode = arg.substr(7)
		if arg.begins_with("--cleared="): cleared = int(arg.substr(10))
		if arg.begins_with("--sclear="): sclear = int(arg.substr(9))
		if arg.begins_with("--wait="): wait = int(arg.substr(7))
		if arg == "--quiz": quiz = true
		if arg == "--island-quiz": island = 1
		if arg == "--island-claim": island = 2
		if arg == "--island-crow": island = 3
		if arg.begins_with("--turns="): turns = int(arg.substr(8))
		if arg == "--act": act = true
		if arg.begins_with("--deg="): deg = float(arg.substr(6))
		if arg.begins_with("--try="): tri = int(arg.substr(6))
	for i in cleared:
		GameState.kid_clear[String(KidDefs.UNITS[i]["id"])] = true
	for i in sclear:
		var list: Array = StoryDefs.chapters_of(GameState.story_mode)
		if i < list.size():
			GameState.story_clear[String(list[i]["id"])] = true
	var inst: Node = (load("res://scenes/%s.tscn" % scene) as PackedScene).instantiate()
	get_tree().root.add_child(inst)
	for i in 10:
		await get_tree().process_frame
	if netq >= 0:
		# 展開図マスターの クイズ。--netfold で 立ち上がった ところまで 進める
		inst._build_quiz(netq)
		await get_tree().process_frame
		if netfold:
			var net: Dictionary = inst.nets[netq]
			inst._answer(inst.choice_box.get_child(0) as Button,
				String(net["solid"]), String(net["solid"]))
			for i in 300:
				await get_tree().process_frame
				if inst.view.t >= 1.0:
					break
	if act:
		# おはなしを とばして さわる場面へ。--try= で 何回めかを えらぶ
		for i in 8:
			if inst.phase == 1:
				break
			inst._advance()
			await get_tree().process_frame
		for r in tri:
			inst._act_done()
			await get_tree().process_frame
			if hold and r == tri - 1:
				break              # できた ところで 止める(立ち上がりを 見る)
			inst._advance()
			await get_tree().process_frame
	for tn in turns:
		if inst.over or inst.auto_fill:
			break
		inst._pick_level(1)
		await get_tree().process_frame
		inst.input_text = ProblemGen.fmt(float(inst.problem["answer"]))
		inst._submit()
		await get_tree().process_frame
		inst._auto_mark()
		inst._on_act()
		for i in 2:
			await get_tree().process_frame
	if island > 0:
		# 島取り: 立て札の問題を開く(2 なら 正解して なぞる 途中まで)
		inst._pick_level(1)
		for i in 4:
			await get_tree().process_frame
		if island == 3:
			# カラスのターンの カットイン(問題は 閉じて 盤面の 上に 出す)
			inst.quiz.visible = false
			inst._cut_in("laugh", "その計算、500円で売ってやろうか?")
			for i in 8:
				await get_tree().process_frame
		if island == 2:
			inst.input_text = ProblemGen.fmt(float(inst.problem["answer"]))
			inst.keypad.answer_lbl.text = inst.input_text
			inst._submit()
			for i in 4:
				await get_tree().process_frame
			for t in 4:
				for y in inst.H:
					for x in inst.W:
						var cv := Vector2i(x, y)
						if not inst.marked.has(cv) and inst._touches_claim(cv) 								and inst.cell[y][x] == inst.EMPTY:
							inst._mark(cv)
							break
					if inst.marked.size() > t:
						break
			for i in 2:
				await get_tree().process_frame
	if act and deg >= 0.0:
		# 時計を まわした とちゅうを 見る
		inst.st["deg"] = deg
		inst.map.queue_redraw()
	if quiz:
		# おはなし → さわる(3 回)→ しるし まで 進める
		for i in 8:
			inst._advance()
			await get_tree().process_frame
			if inst.phase == 1:
				break
		for r in 3:
			inst._act_done()
			await get_tree().process_frame
			if r < 2:
				inst._advance()
				await get_tree().process_frame
		inst._advance()
	for i in wait:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out)
	print("SHOT ", scene)
	get_tree().quit(0)
