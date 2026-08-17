class_name ExprEval
## 解答欄に入力した式を計算する小さな電卓。
## 対応: 数(小数可) + − × ÷ ( ) √、単項マイナス。
## 紙とペンなしで「12×8÷2」「√(64+225)」のように立式して解けるようにする。
##
## 使い方: ExprEval.eval("3+4×5") -> {"ok": true, "value": 23.0}
##         失敗時は {"ok": false, "err": "…"}

## 式に演算子が含まれるか(ただの数値入力かどうかの判定に使う)
static func is_expression(s: String) -> bool:
	for op in ["+", "×", "÷", "√", "(", ")", "*", "/"]:
		if s.contains(op):
			return true
	# 先頭以外のマイナスは演算子
	return s.substr(1).contains("−") or s.substr(1).contains("-")


static func eval(s: String) -> Dictionary:
	var tokens := _tokenize(s)
	if tokens.is_empty():
		return {"ok": false, "err": "式が空です"}
	var st := {"t": tokens, "i": 0}
	var v := _expr(st)
	if is_nan(v):
		return {"ok": false, "err": "式のかたちがおかしいよ"}
	if int(st["i"]) < tokens.size():
		return {"ok": false, "err": "式のかたちがおかしいよ"}
	if is_inf(v):
		return {"ok": false, "err": "0 でわることはできないよ"}
	return {"ok": true, "value": v}


## 数値を答え欄向けの文字列にする(整数はそのまま、小数は末尾の 0 を落とす)
static func fmt(v: float) -> String:
	if absf(v - round(v)) < 0.0000001 and absf(v) < 1e12:
		return str(int(round(v)))
	var s := String.num(v, 4)
	while s.ends_with("0"):
		s = s.substr(0, s.length() - 1)
	if s.ends_with("."):
		s = s.substr(0, s.length() - 1)
	return s


static func _tokenize(s: String) -> Array:
	# 表記ゆれを吸収(全角・ASCII どちらでも)
	s = s.replace("*", "×").replace("/", "÷").replace("-", "−").replace(" ", "")
	var out: Array = []
	var i := 0
	while i < s.length():
		var c := s[i]
		if c == "." or (c >= "0" and c <= "9"):
			var j := i
			var dots := 0
			while j < s.length() and (s[j] == "." or (s[j] >= "0" and s[j] <= "9")):
				if s[j] == ".":
					dots += 1
				j += 1
			var num := s.substr(i, j - i)
			if dots > 1 or num == ".":
				return []
			out.append(num.to_float())
			i = j
		elif c in ["+", "−", "×", "÷", "(", ")", "√"]:
			out.append(c)
			i += 1
		else:
			return []
	return out


## expr := term (('+'|'−') term)*
static func _expr(st: Dictionary) -> float:
	var v := _term(st)
	if is_nan(v):
		return NAN
	while _peek(st) == "+" or _peek(st) == "−":
		var op: String = st["t"][st["i"]]
		st["i"] += 1
		var rhs := _term(st)
		if is_nan(rhs):
			return NAN
		v = v + rhs if op == "+" else v - rhs
	return v


## term := factor (('×'|'÷') factor)*
static func _term(st: Dictionary) -> float:
	var v := _factor(st)
	if is_nan(v):
		return NAN
	while _peek(st) == "×" or _peek(st) == "÷":
		var op: String = st["t"][st["i"]]
		st["i"] += 1
		var rhs := _factor(st)
		if is_nan(rhs):
			return NAN
		if op == "×":
			v = v * rhs
		else:
			if rhs == 0.0:
				return INF
			v = v / rhs
	return v


## factor := '−' factor | '√' factor | number | '(' expr ')'
static func _factor(st: Dictionary) -> float:
	var p = _peek(st)
	if p == null:
		return NAN
	if p is String and p == "−":
		st["i"] += 1
		var v := _factor(st)
		return NAN if is_nan(v) else -v
	if p is String and p == "√":
		st["i"] += 1
		var v2 := _factor(st)
		if is_nan(v2) or v2 < 0.0:
			return NAN
		return sqrt(v2)
	if p is String and p == "(":
		st["i"] += 1
		var v3 := _expr(st)
		if is_nan(v3):
			return NAN
		if _peek(st) != ")":
			return NAN
		st["i"] += 1
		return v3
	if p is float:
		st["i"] += 1
		return p
	return NAN


static func _peek(st: Dictionary):
	var i := int(st["i"])
	var t: Array = st["t"]
	return t[i] if i < t.size() else null
