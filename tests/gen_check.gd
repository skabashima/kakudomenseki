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


## 「40°」のような数値ラベルの角の印について、描画される角
## (reflex 指定がなければ 180° 以下の側)がラベルと一致するか確かめる
func _check_angle_mark(where: String, sh: Dictionary) -> void:
	var label := String(sh["label"])
	if not label.ends_with("°"):
		return
	var num_str := label.trim_suffix("°")
	if not num_str.is_valid_int():
		return
	var expected := float(num_str.to_int())
	var at: Vector2 = sh["at"]
	var d1: Vector2 = (sh["p1"] as Vector2) - at
	var d2: Vector2 = (sh["p2"] as Vector2) - at
	var sweep := fposmod(d2.angle() - d1.angle(), TAU)
	var drawn := rad_to_deg(sweep if sh.get("reflex", false) else minf(sweep, TAU - sweep))
	if absf(drawn - expected) > 1.5:
		failures.append("%s: 角ラベル %s に対して描画角 %.1f°" % [where, label, drawn])


func _check_fig(where: String, fig: Dictionary) -> void:
	var shapes: Array = fig.get("shapes", [])
	if shapes.is_empty():
		failures.append(where + ": fig has no shapes")
		return
	for sh in shapes:
		if typeof(sh) != TYPE_DICTIONARY or not sh.has("t"):
			failures.append(where + ": bad shape entry")
			continue
		# 数値ラベルつきの角の印は、実際に描かれる角度と一致していること
		# (図が出題値どおりに描けているかの検証。図は常に正確、が本作の原則)
		if String(sh["t"]) == "angle":
			_check_angle_mark(where, sh)
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
