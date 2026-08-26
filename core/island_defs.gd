class_name IslandDefs
## 島取りの 島(ステージ)データ。
##
## 島を 1 つ 取るごとに つぎの 島が 開く。島が 進むほど 出る問題が 上の
## 範囲に なり(中学受験 → 高校受験 → 大学受験)、島も 大きく、カラスも
## 強くなる。全 65 ステージを 12 の 島で 通す。
##
##   course … その島で 出る コース(kaku / men)
##   from,to … そのコースの ステージ番号の はば(この中から 出る)
##   w,h    … 島の 大きさ
##   rocks  … 岩の 数(通れない)
##   crow   … カラスの 強さ(1 ターンに 広げる マス数の 倍率)
##   turns  … 何ターンで 決着か

const ISLANDS := [
	# ---- 中学受験(小学生) 8 島 ----
	{"name": "はじまりの はまべ", "level": "中学受験", "course": "kaku", "from": 0, "to": 1,
		"w": 9, "h": 12, "rocks": 5, "crow": 0.75, "turns": 10},
	{"name": "四角の すなはま", "level": "中学受験", "course": "men", "from": 0, "to": 2,
		"w": 9, "h": 12, "rocks": 5, "crow": 0.8, "turns": 11},
	{"name": "かどの いわば", "level": "中学受験", "course": "kaku", "from": 2, "to": 3,
		"w": 9, "h": 13, "rocks": 6, "crow": 0.85, "turns": 12},
	{"name": "ますめの おか", "level": "中学受験", "course": "men", "from": 3, "to": 5,
		"w": 9, "h": 13, "rocks": 6, "crow": 0.85, "turns": 12},
	{"name": "時計の みさき", "level": "中学受験", "course": "kaku", "from": 4, "to": 5,
		"w": 10, "h": 13, "rocks": 7, "crow": 0.9, "turns": 12},
	{"name": "みずうみの 島", "level": "中学受験", "course": "men", "from": 6, "to": 9,
		"w": 10, "h": 14, "rocks": 7, "crow": 0.9, "turns": 13},
	{"name": "おりがみの 谷", "level": "中学受験", "course": "kaku", "from": 6, "to": 7,
		"w": 10, "h": 14, "rocks": 7, "crow": 0.95, "turns": 13},
	{"name": "立体の おか", "level": "中学受験", "course": "men", "from": 10, "to": 14,
		"w": 10, "h": 14, "rocks": 8, "crow": 1.0, "turns": 14},
	# ---- 高校受験(中学生) 8 島 ----
	{"name": "円の ほとり", "level": "高校受験", "course": "kaku", "from": 8, "to": 9,
		"w": 10, "h": 14, "rocks": 8, "crow": 1.0, "turns": 13},
	{"name": "三平方の みさき", "level": "高校受験", "course": "men", "from": 15, "to": 17,
		"w": 11, "h": 14, "rocks": 8, "crow": 1.0, "turns": 13},
	{"name": "まわりの 角", "level": "高校受験", "course": "kaku", "from": 10, "to": 11,
		"w": 11, "h": 15, "rocks": 9, "crow": 1.05, "turns": 14},
	{"name": "相似の たに", "level": "高校受験", "course": "men", "from": 18, "to": 20,
		"w": 11, "h": 15, "rocks": 9, "crow": 1.05, "turns": 14},
	{"name": "作図の いわば", "level": "高校受験", "course": "kaku", "from": 12, "to": 13,
		"w": 11, "h": 15, "rocks": 9, "crow": 1.1, "turns": 14},
	{"name": "くみあわせの 島", "level": "高校受験", "course": "men", "from": 21, "to": 23,
		"w": 11, "h": 15, "rocks": 10, "crow": 1.1, "turns": 15},
	{"name": "かたちの 森", "level": "高校受験", "course": "kaku", "from": 14, "to": 15,
		"w": 11, "h": 16, "rocks": 10, "crow": 1.15, "turns": 15},
	{"name": "広さの 島", "level": "高校受験", "course": "men", "from": 24, "to": 25,
		"w": 11, "h": 16, "rocks": 10, "crow": 1.15, "turns": 15},
	# ---- 大学受験(高校生) 8 島 ----
	{"name": "三角比の 海", "level": "大学受験", "course": "kaku", "from": 16, "to": 17,
		"w": 12, "h": 16, "rocks": 10, "crow": 1.2, "turns": 15},
	{"name": "方べきの みなと", "level": "大学受験", "course": "men", "from": 26, "to": 29,
		"w": 12, "h": 16, "rocks": 11, "crow": 1.2, "turns": 15},
	{"name": "ベクトルの 空", "level": "大学受験", "course": "kaku", "from": 18, "to": 19,
		"w": 12, "h": 16, "rocks": 11, "crow": 1.25, "turns": 16},
	{"name": "円と 方程式の 島", "level": "大学受験", "course": "men", "from": 30, "to": 33,
		"w": 12, "h": 17, "rocks": 11, "crow": 1.25, "turns": 16},
	{"name": "かくどの 谷", "level": "大学受験", "course": "men", "from": 34, "to": 37,
		"w": 12, "h": 17, "rocks": 12, "crow": 1.3, "turns": 16},
	{"name": "空の みさき", "level": "大学受験", "course": "men", "from": 38, "to": 40,
		"w": 12, "h": 17, "rocks": 12, "crow": 1.35, "turns": 16},
	{"name": "積分の 果て", "level": "大学受験", "course": "men", "from": 41, "to": 43,
		"w": 12, "h": 17, "rocks": 12, "crow": 1.4, "turns": 16},
	{"name": "さいごの 島", "level": "大学受験", "course": "men", "from": 42, "to": 44,
		"w": 12, "h": 18, "rocks": 13, "crow": 1.5, "turns": 17},
]


## 出題の はんい。えらんだ はんいの 島だけを 通す
const RANGES := [
	{"id": "elem", "name": "小学生", "read": "しょうがくせい", "level": "中学受験",
		"color": Color(0.52, 0.30, 0.34)},
	{"id": "jhs", "name": "中学生", "read": "ちゅうがくせい", "level": "高校受験",
		"color": Color(0.45, 0.35, 0.62)},
	{"id": "hs", "name": "高校生", "read": "こうこうせい", "level": "大学受験",
		"color": Color(0.24, 0.42, 0.58)},
	{"id": "all", "name": "ぜんぶ", "read": "", "level": "",
		"color": Color(0.24, 0.46, 0.40)},
]


static func range_of(id: String) -> Dictionary:
	for r in RANGES:
		if String(r["id"]) == id:
			return r
	return RANGES[RANGES.size() - 1]


## その はんいに 入る 島の 番号
static func islands_in(id: String) -> Array:
	var out: Array = []
	var want := String(range_of(id)["level"])
	for i in ISLANDS.size():
		if want == "" or String(ISLANDS[i]["level"]) == want:
			out.append(i)
	return out


## その はんいで つぎに 挑む 島
static func first_open_in(id: String, cleared: Dictionary) -> int:
	var list := islands_in(id)
	for i in list:
		if not cleared.has(str(i)):
			return int(i)
	return int(list[list.size() - 1]) if not list.is_empty() else 0


## その はんいの つぎの 島(無ければ -1)
static func next_in(id: String, i: int) -> int:
	var list := islands_in(id)
	for k in list.size():
		if int(list[k]) == i and k + 1 < list.size():
			return int(list[k + 1])
	return -1


## その はんいで いくつ 取ったか [取った数, ぜんぶの数]
static func progress_in(id: String, cleared: Dictionary) -> Array:
	var list := islands_in(id)
	var done := 0
	for i in list:
		if cleared.has(str(i)):
			done += 1
	return [done, list.size()]


static func count() -> int:
	return ISLANDS.size()


static func of(i: int) -> Dictionary:
	return ISLANDS[clampi(i, 0, ISLANDS.size() - 1)]


## その島が 開いているか(前の島を 取れば 開く)
static func is_open(i: int, cleared: Dictionary) -> bool:
	if i <= 0:
		return true
	return cleared.has(str(i - 1))


## いま 挑む 島(取っていない いちばん 手前)
static func current(cleared: Dictionary) -> int:
	for i in ISLANDS.size():
		if not cleared.has(str(i)):
			return i
	return ISLANDS.size() - 1


## その島で 出る ステージ(難しさ 0..2 で はばの 中の どこを 使うか 変える)
static func stage_range(i: int, level: int) -> Array:
	var d := of(i)
	var lo := int(d["from"])
	var hi := int(d["to"])
	var span := maxi(hi - lo, 1)
	match level:
		0:
			return [lo, lo + int(ceil(float(span) * 0.4))]
		1:
			return [lo + int(float(span) * 0.3), lo + int(ceil(float(span) * 0.8))]
		_:
			return [lo + int(float(span) * 0.55), hi]
