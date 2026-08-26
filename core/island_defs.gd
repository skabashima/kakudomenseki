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
	{"name": "はじまりの入り江", "level": "中学受験", "course": "kaku", "from": 0, "to": 3,
		"w": 9, "h": 12, "rocks": 5, "crow": 0.75, "turns": 10},
	{"name": "四角の砂洲", "level": "中学受験", "course": "men", "from": 0, "to": 4,
		"w": 9, "h": 13, "rocks": 6, "crow": 0.85, "turns": 11},
	{"name": "時計岬", "level": "中学受験", "course": "kaku", "from": 3, "to": 7,
		"w": 10, "h": 13, "rocks": 7, "crow": 1.0, "turns": 11},
	{"name": "みずうみ島", "level": "中学受験", "course": "men", "from": 5, "to": 11,
		"w": 10, "h": 14, "rocks": 7, "crow": 1.0, "turns": 12},
	{"name": "立体の丘", "level": "中学受験", "course": "men", "from": 9, "to": 14,
		"w": 10, "h": 14, "rocks": 8, "crow": 1.05, "turns": 12},
	{"name": "円のほとり", "level": "高校受験", "course": "kaku", "from": 8, "to": 12,
		"w": 11, "h": 14, "rocks": 8, "crow": 1.1, "turns": 12},
	{"name": "三平方の岬", "level": "高校受験", "course": "men", "from": 15, "to": 20,
		"w": 11, "h": 15, "rocks": 9, "crow": 1.1, "turns": 13},
	{"name": "相似の谷", "level": "高校受験", "course": "men", "from": 19, "to": 25,
		"w": 11, "h": 15, "rocks": 9, "crow": 1.15, "turns": 13},
	{"name": "作図の岩礁", "level": "高校受験", "course": "kaku", "from": 11, "to": 15,
		"w": 11, "h": 15, "rocks": 10, "crow": 1.2, "turns": 13},
	{"name": "三角比の海", "level": "大学受験", "course": "kaku", "from": 15, "to": 19,
		"w": 12, "h": 16, "rocks": 10, "crow": 1.25, "turns": 14},
	{"name": "円と方程式の島", "level": "大学受験", "course": "men", "from": 26, "to": 35,
		"w": 12, "h": 16, "rocks": 11, "crow": 1.3, "turns": 14},
	{"name": "積分の果て", "level": "大学受験", "course": "men", "from": 36, "to": 44,
		"w": 12, "h": 17, "rocks": 12, "crow": 1.4, "turns": 15},
]


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
