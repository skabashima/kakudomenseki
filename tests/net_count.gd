extends SceneTree
## 展開図に つながる 問題が 何とおり あるかを 数える(--headless 可)。
##   godot --headless --path . -s tests/net_count.gd
const SEEDS := 900
func _init() -> void:
	var groups := [
		["e23 展開図と組み立て", "e23", range(0, 10)],
		["  ├ さいころの 展開図", "e23", [0, 1]],
		["  ├ 転がして 上の面", "e23", [2, 3]],
		["  ├ 直方体の 展開図", "e23", [4, 5]],
		["  ├ 円柱の 展開図", "e23", [6]],
		["  ├ 角柱の 展開図", "e23", [7, 8]],
		["  └ 正多面体の 展開図", "e23", [9]],
		["j13 円錐の 展開図の 中心角", "j13", [6, 7]],
		["j14 円錐を ひとまわり", "j14", [8, 9]],
	]
	var total := {}
	for g in groups:
		var seen := {}
		for tier in g[2]:
			for i in SEEDS:
				var rng := RandomNumberGenerator.new()
				rng.seed = 7000 + i * 13 + int(tier)
				var p: Dictionary = ProblemGen.generate(String(g[1]), rng, int(tier))
				var key := String(p["q"]) + "|" + str(p["answer"])
				seen[key] = true
				if not String(g[0]).begins_with("  "):
					total[key] = true
		print("%-28s %5d とおり" % [String(g[0]), seen.size()])
	print("---")
	print("問題(数を 答える もの) あわせて %d とおり" % total.size())
	print("展開図マスター(どの 立体に なるか) %d とおり" % NetDefs.all().size())
	quit(0)
