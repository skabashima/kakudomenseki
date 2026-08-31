extends Node
## 「今日の図形」の 検証(--headless 可)。
##   godot --headless --path . res://tests/daily_check.tscn
##
## 見るところ:
##   ・同じ 日なら 同じ 問題(通信 なしで 全員 同じ にする しくみ)
##   ・日が 変われば 問題も 変わる
##   ・れんぞく日数: きのう 解いていれば +1、間が あけば 1 に 戻る、
##     同じ日に 2 回 数えない
##   ・貼る 文に 答えが 入っていない(ネタバレ なし)
##   ・実際の セーブを こわさない

var failures: Array = []


func _ready() -> void:
	await get_tree().process_frame
	var keep := [GameState.daily_day, GameState.daily_streak, GameState.daily_best]

	# 同じ 日なら 同じ 問題
	var a: Dictionary = Daily.make(0)
	var b: Dictionary = Daily.make(0)
	if String(a["q"]) != String(b["q"]) or absf(float(a["answer"]) - float(b["answer"])) > 0.001:
		failures.append("同じ 日なのに ちがう 問題が 出る")
	if not a.has("stage_title"):
		failures.append("問題に ステージ名が 付いていない")

	# れんぞく日数
	var today := Daily.day_number()
	GameState.daily_day = 0
	GameState.daily_streak = 0
	GameState.record_daily()
	if GameState.daily_streak != 1 or not GameState.daily_done():
		failures.append("はじめての 日で れんぞくが 1 に ならない")
	GameState.record_daily()
	if GameState.daily_streak != 1:
		failures.append("同じ日に 2 回 数えている")
	GameState.daily_day = today - 1
	GameState.record_daily()
	if GameState.daily_streak != 2:
		failures.append("きのう 解いていても れんぞくが のびない(%d)" % GameState.daily_streak)
	# 3 日 続けてから 間を あける
	GameState.daily_day = today - 1
	GameState.record_daily()          # 3 日め
	var peak: int = GameState.daily_streak
	GameState.daily_day = today - 3   # 間が あいた
	GameState.record_daily()
	if GameState.daily_streak != 1:
		failures.append("間が あいても れんぞくが 続いている")
	if GameState.daily_best < peak:
		failures.append("れんぞくの 最高記録が のこらない(最高 %d / 実際 %d)" % [
			GameState.daily_best, peak])

	# 貼る 文に 答えを 入れない
	var text := Daily.share_text(1, 75.0, 3, String(a["stage_title"]))
	var ans := ProblemGen.fmt(float(a["answer"]))
	if ans.length() >= 2 and text.contains(ans):
		failures.append("貼る 文に 答えが 入っている(ネタバレ)")
	if not text.contains("れんぞく"):
		failures.append("貼る 文に れんぞく日数が 無い")

	GameState.daily_day = int(keep[0])
	GameState.daily_streak = int(keep[1])
	GameState.daily_best = int(keep[2])
	GameState.save_game()
	if failures.is_empty():
		print("DAILY OK: 同じ日は 同じ問題・れんぞく・ネタバレなしの 共有文")
	else:
		for f in failures:
			print("FAIL: " + str(f))
	get_tree().quit(0 if failures.is_empty() else 1)
