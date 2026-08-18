extends Node
## ステージごとに「何通りの問題が出るか」を実測するレポート(--headless 可)。
##   godot --headless --path . res://tests/variation_report.tscn
## 問題文+答えの組が何種類あるかを大量サンプルで数える。

const SAMPLES := 4000


func _ready() -> void:
	var grand := 0
	for course in ProblemGen.COURSES:
		var course_total := 0
		print("== %s ==" % course["name"])
		for stage in course["stages"]:
			var sid := String(stage["id"])
			var uniq := {}
			for i in SAMPLES:
				var rng := RandomNumberGenerator.new()
				rng.seed = hash(sid) * 31 + i
				var p: Dictionary = ProblemGen.generate(sid, rng, i % 10)
				uniq[String(p["q"]) + "|" + str(snappedf(float(p["answer"]), 0.001))] = true
			print("  %-4s %-12s %5d 通り" % [sid, String(stage["title"]).substr(0, 6), uniq.size()])
			course_total += uniq.size()
		print("  小計 %d 通り" % course_total)
		grand += course_total
	print("TOTAL DISTINCT PROBLEMS: %d" % grand)
	get_tree().quit(0)
