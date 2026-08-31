class_name Zukan
## 「見つけた 決まり」の 図鑑。
##
## ストーリーと たからのちずで 見つけた こと(found)を カードとして 集める。
## 数字が 増えるだけでは 集めている 気が しないので、**何を 手に入れたか**が
## 一覧で 見えるようにする。
##
## 元は それぞれの データに ある 文なので、ここでは 集める・数える だけを 持つ。

## 図鑑の 中身 [{"id","name","found","from"}]
static func cards() -> Array:
	var out: Array = []
	for u in KidDefs.UNITS:
		out.append({
			"id": "kid:" + String(u["id"]),
			"name": String(u["title"]),
			"found": String(u["found"]),
			"from": "たからのちず",
		})
	for mode in ["jhs", "hs"]:
		for ch in StoryDefs.chapters_of(mode):
			out.append({
				"id": "story:%s:%s" % [mode, String(ch["id"])],
				"name": String(ch["title"]),
				"found": String(ch.get("found", "")),
				"from": "はかる旅" if mode == "jhs" else "軌道計算室",
			})
	return out


## そのカードを もう 手に入れたか(その回を クリアしていれば 手に入る)
static func has(card: Dictionary, kid_clear: Dictionary, story_clear: Dictionary) -> bool:
	var id := String(card["id"])
	if id.begins_with("kid:"):
		return kid_clear.has(id.substr(4))
	var parts := id.split(":")
	return story_clear.has(parts[2]) if parts.size() >= 3 else false


## 集めた 数 [集めた, ぜんぶ]
static func progress(kid_clear: Dictionary, story_clear: Dictionary) -> Array:
	var all := cards()
	var got := 0
	for c in all:
		if has(c, kid_clear, story_clear):
			got += 1
	return [got, all.size()]
