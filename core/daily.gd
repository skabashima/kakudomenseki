class_name Daily
## 「今日の図形」― その日は 世界じゅうで 同じ 1 問。
##
## 日付から たねを 作るので、通信 なしで 全部の 端末が 同じ 問題に なる。
## 1 日 1 回、答えを 出すまでの 時間と まちがえた 数を 記録し、
## ネタバレ なしの 文を 作って 貼れるようにする(毎日 開く 理由)。

## 1970 年から 何日め か(その日の たね)
static func day_number() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)


static func date_label() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%d/%d" % [int(d["month"]), int(d["day"])]


## その日の 問題。無料の 人には 無料の 範囲から 出す
static func make(free_limit: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = day_number() * 7919 + 13
	var courses: Array = ProblemGen.COURSES
	var c: Dictionary = courses[rng.randi_range(0, courses.size() - 1)]
	var stages: Array = c["stages"]
	var top := stages.size() if free_limit <= 0 else mini(free_limit, stages.size())
	var idx := rng.randi_range(0, top - 1)
	var tier := rng.randi_range(0, 4)
	var p: Dictionary = ProblemGen.generate(String(stages[idx]["id"]), rng, tier)
	p["stage_id"] = String(stages[idx]["id"])
	p["stage_title"] = String(stages[idx]["title"])
	return p


## 貼れる 文。答えは 書かない(ネタバレ なし)
static func share_text(miss: int, seconds: float, streak: int, title: String) -> String:
	var marks := ""
	for i in 3:
		marks += "■" if i < 3 - mini(miss, 3) else "□"
	return "図形ハンター 今日の図形 %s\n%s  %d分%02d秒  %d日れんぞく\nきょうの図形: %s" % [
		date_label(), marks, int(seconds) / 60, int(seconds) % 60, streak, title]
