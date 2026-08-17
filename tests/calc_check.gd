extends Node
## 解答欄の電卓(ExprEval)の検証(--headless 可)。
##   godot --headless --path . res://tests/calc_check.tscn

var failures: Array = []


func _ready() -> void:
	# [式, 期待値]
	var ok_cases := [
		["48", 48.0],
		["3+4×5", 23.0],
		["(3+4)×5", 35.0],
		["12×8÷2", 48.0],
		["10÷4", 2.5],
		["−3+5", 2.0],
		["6×(5+3)−14", 34.0],
		["√9", 3.0],
		["√(64+225)", 17.0],
		["√(13×13−5×5)", 12.0],
		["3.14×4×4", 50.24],
		["2×3.14×6×120÷360", 12.56],
		["(3+5)×4÷2", 16.0],
		["√2×√2", 2.0000000001],   # 誤差込みで 2
		["−(3+4)", -7.0],
		["5−−3", 8.0],              # 5 − (−3)
		["1/2+1/2", 1.0],           # ASCII の / も受け付ける
		["3*4", 12.0],
	]
	for c in ok_cases:
		var res: Dictionary = ExprEval.eval(c[0])
		if not res["ok"]:
			failures.append("%s -> エラー扱い (%s)" % [c[0], res.get("err", "")])
		elif absf(float(res["value"]) - float(c[1])) > 0.001:
			failures.append("%s -> %f (期待 %f)" % [c[0], float(res["value"]), float(c[1])])

	var bad_cases := ["", "3++4", "(3+4", "3+4)", "√", "12×", "÷5", "1.2.3", "√(−9)", "5÷0", "abc", "。"]
	for b in bad_cases:
		var res: Dictionary = ExprEval.eval(b)
		if res["ok"]:
			failures.append("%s -> 成功扱い (%f)" % [b, float(res.get("value", 0.0))])

	# fmt: 整数はそのまま、小数は末尾ゼロなし
	var fmt_cases := [[48.0, "48"], [2.5, "2.5"], [50.24, "50.24"], [-7.0, "-7"], [1.0 / 3.0, "0.3333"]]
	for f in fmt_cases:
		if ExprEval.fmt(float(f[0])) != String(f[1]):
			failures.append("fmt(%f) -> %s (期待 %s)" % [float(f[0]), ExprEval.fmt(float(f[0])), String(f[1])])

	if failures.is_empty():
		print("CALC CHECK OK: %d cases" % (ok_cases.size() + bad_cases.size() + fmt_cases.size()))
		get_tree().quit(0)
	else:
		for f in failures:
			print("FAIL: " + str(f))
		print("CALC CHECK FAILED: %d issues" % failures.size())
		get_tree().quit(1)
