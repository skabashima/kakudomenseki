extends Node
## 課金ゲート(無料範囲 / 有料範囲 / チャレンジ)の検証(--headless 可)。
##   godot --headless --path . res://tests/iap_gate.tscn
## 検証内容:
##   ・各編の先頭 FREE_STAGES_PER_COURSE ステージだけが無料
##   ・購入(premium)またはデバッグ解放で全ステージが開く
##   ・有料ステージ数が「全ステージ - 無料ステージ」に一致する
##   ・未購入のチャレンジは タイムアタック(角度編)だけ遊べる
##   ・未購入のチャレンジ出題が無料ステージからしか出ない
##   ・Iap(オートロード)がスタブとして安全に動く(PC では購入不可)

var failures: Array = []


func _ready() -> void:
	# 実際のセーブを書き換えないよう、状態を退避してから検証する
	var saved_premium: bool = GameState.premium
	var saved_debug: bool = GameState.debug_unlock_all
	GameState.premium = false
	GameState.debug_unlock_all = false

	_check_free_range()
	_check_paid_count()
	_check_challenge_gate()
	_check_challenge_pool()
	_check_premium_opens_all()
	_check_iap_stub()

	GameState.premium = saved_premium
	GameState.debug_unlock_all = saved_debug

	if failures.is_empty():
		print("IAP GATE OK")
		get_tree().quit(0)
	else:
		for f in failures:
			print("FAIL: " + String(f))
		print("IAP GATE FAILED: %d issues" % failures.size())
		get_tree().quit(1)


func _ok(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


## 各編の先頭 4 ステージだけが無料
func _check_free_range() -> void:
	var free_n: int = GameState.FREE_STAGES_PER_COURSE
	for c in ProblemGen.COURSES:
		var stages: Array = c["stages"]
		for i in stages.size():
			var paid: bool = GameState.needs_purchase(i)
			_ok(paid == (i >= free_n),
				"%s の %d 番目: needs_purchase=%s (無料は先頭 %d)" % [
					String(c["name"]), i + 1, str(paid), free_n])


## 解放画面の訴求に使う有料ステージ数
func _check_paid_count() -> void:
	var total := 0
	for c in ProblemGen.COURSES:
		total += (c["stages"] as Array).size()
	var expected := total - GameState.FREE_STAGES_PER_COURSE * ProblemGen.COURSES.size()
	_ok(GameState.paid_stage_count() == expected,
		"paid_stage_count=%d (期待 %d)" % [GameState.paid_stage_count(), expected])


## 未購入で遊べるチャレンジは タイムアタック(角度編)だけ
func _check_challenge_gate() -> void:
	_ok(not GameState.challenge_needs_purchase("time", "kaku"),
		"タイムアタック(角度編)は無料のはず")
	_ok(GameState.challenge_needs_purchase("time", "men"),
		"タイムアタック(面積編)は有料のはず")
	_ok(GameState.challenge_needs_purchase("time", "all"),
		"タイムアタック(全コース)は有料のはず")
	_ok(GameState.challenge_needs_purchase("survival", "all"),
		"サバイバルは有料のはず")


## 未購入のチャレンジ出題が有料ステージに届かない
func _check_challenge_pool() -> void:
	var free_ids := {}
	for c in ProblemGen.COURSES:
		var stages: Array = c["stages"]
		for i in mini(GameState.FREE_STAGES_PER_COURSE, stages.size()):
			free_ids[String(stages[i]["id"])] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for course_id in ["kaku", "all"]:
		for i in 400:
			var ramp := float(i) / 400.0
			var sid := ProblemGen.random_stage(String(course_id), rng, ramp,
				GameState.free_stage_limit())
			_ok(free_ids.has(sid),
				"未購入のチャレンジ(%s)で有料ステージ %s が出題された" % [String(course_id), sid])
			if not free_ids.has(sid):
				return


## 購入 / デバッグ解放で全ステージが開く
func _check_premium_opens_all() -> void:
	GameState.premium = true
	_ok(GameState.free_stage_limit() == 0, "購入後は出題の制限が外れるはず")
	for c in ProblemGen.COURSES:
		for i in (c["stages"] as Array).size():
			_ok(not GameState.needs_purchase(i),
				"購入後に %s の %d 番目がロックされている" % [String(c["name"]), i + 1])
	_ok(not GameState.challenge_needs_purchase("survival", "all"),
		"購入後はサバイバルも遊べるはず")
	GameState.premium = false
	GameState.debug_unlock_all = true
	_ok(not GameState.needs_purchase(999), "デバッグ解放中はロックしないはず")
	GameState.debug_unlock_all = false


## PC(ストアプラグイン無し)では Iap はスタブとして安全に動く
func _check_iap_stub() -> void:
	var iap := get_node_or_null("/root/Iap")
	if iap == null:
		failures.append("オートロード Iap が見つからない(project.godot を確認)")
		return
	_ok(not bool(iap.has_store()), "PC ではストア未接続のはず")
	_ok(String(iap.price_text()) != "", "価格の既定表示が空")
	# スタブでも購入/復元の呼び出しでクラッシュしないこと(失敗が返るだけ)
	iap.purchase()
	iap.restore()
	iap.query_price()
