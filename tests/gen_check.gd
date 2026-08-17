extends Node
## 全ステージ × 多数シードで問題生成を検証する(--headless 可)。
##   godot --headless --path . res://tests/gen_check.tscn
## 検証内容:
##   ・answer が有限の数で、tol > 0
##   ・問題文・ヒント・解説が空でない
##   ・図形スペックの座標がすべて有限
##   ・同じステージでも数値バリエーションが複数あること(丸暗記防止)

const SEEDS_PER_STAGE := 120

var failures: Array = []


func _ready() -> void:
	var total := 0
	for course in ProblemGen.COURSES:
		for stage in course["stages"]:
			var sid := String(stage["id"])
			var answers := {}
			for i in SEEDS_PER_STAGE:
				var rng := RandomNumberGenerator.new()
				rng.seed = hash(sid) + i
				var tier := i % 3
				var p: Dictionary = ProblemGen.generate(sid, rng, tier)
				total += 1
				_check_problem(sid, i, p)
				answers[String(p["q"]) + "|" + str(p["answer"])] = true
			if answers.size() < 12:
				failures.append("%s: バリエーションが少なすぎる (%d 通り)" % [sid, answers.size()])
	if failures.is_empty():
		print("GEN CHECK OK: %d problems generated and validated" % total)
		get_tree().quit(0)
	else:
		for f in failures:
			print("FAIL: " + str(f))
		print("GEN CHECK FAILED: %d issues" % failures.size())
		get_tree().quit(1)


func _check_problem(sid: String, seed_i: int, p: Dictionary) -> void:
	var where := "%s#%d" % [sid, seed_i]
	for key in ["q", "answer", "unit", "tol", "hint1", "hint2", "expl", "fig"]:
		if not p.has(key):
			failures.append(where + ": missing key " + key)
			return
	var ans := float(p["answer"])
	if is_nan(ans) or is_inf(ans):
		failures.append(where + ": answer is not finite")
	if float(p["tol"]) <= 0.0:
		failures.append(where + ": tol <= 0")
	for key in ["q", "hint1", "hint2", "expl"]:
		if String(p[key]).strip_edges() == "":
			failures.append(where + ": empty " + key)
	# 答えの丸めが tol の中に収まるか(小数2桁で入力できること)
	var rounded := snappedf(ans, 0.01)
	if absf(rounded - ans) > float(p["tol"]):
		failures.append(where + ": answer %f not enterable with 2 decimals (tol %f)" % [ans, float(p["tol"])])
	_check_fig(where, p["fig"])


func _check_fig(where: String, fig: Dictionary) -> void:
	var shapes: Array = fig.get("shapes", [])
	if shapes.is_empty():
		failures.append(where + ": fig has no shapes")
		return
	for sh in shapes:
		if typeof(sh) != TYPE_DICTIONARY or not sh.has("t"):
			failures.append(where + ": bad shape entry")
			continue
		for k in sh:
			var v = sh[k]
			match typeof(v):
				TYPE_VECTOR2:
					if not (is_finite(v.x) and is_finite(v.y)):
						failures.append("%s: shape %s has non-finite %s" % [where, sh["t"], k])
				TYPE_FLOAT:
					if not is_finite(v):
						failures.append("%s: shape %s has non-finite %s" % [where, sh["t"], k])
				TYPE_ARRAY:
					for e in v:
						if typeof(e) == TYPE_VECTOR2 and not (is_finite(e.x) and is_finite(e.y)):
							failures.append("%s: shape %s has non-finite point in %s" % [where, sh["t"], k])
