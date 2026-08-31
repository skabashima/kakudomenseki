extends SceneTree
## 「解き方」アニメが どれだけ 用意できているかを 見る(--headless 可)。
##   godot --headless --path . -s tests/walkthrough_check.gd
##
## 生成器が steps を持たない 問題は、ヒントと 解説を 切って 出す 汎用の 表示に なる。
## 読めるには 読めるが、**補助線が 引かれる** 手ざわりは 出ない。
## どこが 汎用のままか 分からなくならないよう、ここで 数えて 見張る。
##
## 決まり:
##   ・中学受験(e)と 高校受験(j)の ステージは、tier 0 に かならず steps を 持つ
##   ・大学受験(s)は これから。いまの 数を 下回ったら 落とす(後戻りの 防止)

const NEED_PREFIX := ["e", "j"]     # ここは 必ず 用意する
const MIN_SENIOR := 0               # 大学受験の 今の 数(増やしたら ここも 上げる)

var missing: Array = []
var senior_have := 0


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	for c in ProblemGen.COURSES:
		for st in c["stages"]:
			var sid := String(st["id"])
			var found := false
			for seed_i in 6:
				rng.seed = 500 + seed_i
				var p: Dictionary = ProblemGen.generate(sid, rng, 0)
				if not (p.get("steps", []) as Array).is_empty():
					found = true
					break
			if sid.begins_with("s"):
				if found:
					senior_have += 1
			elif not found:
				missing.append("%s(%s)" % [sid, String(st["title"])])

	if missing.is_empty() and senior_have >= MIN_SENIOR:
		print("WALKTHROUGH OK: 中学受験と高校受験の全ステージに 解き方アニメ あり" \
			+ "(大学受験は %d ステージ)" % senior_have)
		quit(0)
	else:
		for m in missing:
			print("FAIL: 解き方アニメが 無い ― " + str(m))
		if senior_have < MIN_SENIOR:
			print("FAIL: 大学受験の 解き方アニメが 減っている(%d < %d)" % [
				senior_have, MIN_SENIOR])
		print("WALKTHROUGH FAILED: %d 件" % (missing.size() + (1 if senior_have < MIN_SENIOR else 0)))
		quit(1)
