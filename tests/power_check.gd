extends Node
## 電池と 発熱の 出荷設定を 見張る(--headless 可)。
##   godot --headless --path . res://tests/power_check.tscn
##
## 見るところ:
##   ・低消費モードが 出荷設定で 入っているか
##     (「画面が真っ暗」を 直すために ここを 切るのが いちばん 危ない 近道。
##      真っ暗は wake() で 直す ― 熱対策を 消して 直さない)
##   ・画面を 差しかえたら ちゃんと 目を さますか(真っ暗の 再発を 防ぐ)
##   ・120Hz 端末で 倍の 速さで 描かないよう 上限が 入っているか
##   ・使っていない 物理を 60 回/秒 で 回していないか
##   ・起動の 待ちが 真っ暗に ならないよう 地の色が 入っているか

var failures: Array = []


func _ready() -> void:
	await get_tree().process_frame

	if not bool(ProjectSettings.get_setting("application/run/low_processor_mode", false)):
		failures.append("低消費モードが 切れている(端末が 熱くなる)")
	var fps := int(ProjectSettings.get_setting("application/run/max_fps", 0))
	if fps <= 0 or fps > 60:
		failures.append("max_fps が %d。120Hz 端末で 倍 描いてしまう" % fps)
	var ticks := int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60))
	if ticks > 30:
		failures.append("物理が %d 回/秒。この作品は 物理を 使っていない" % ticks)
	if not ProjectSettings.has_setting("application/boot_splash/bg_color"):
		failures.append("起動画面の 地の色が 無い(待ちが 真っ暗に 見える)")

	# 画面を 差しかえたら 目を さます(さまさないと 実機で 真っ暗のまま 止まる)
	GameState.set("_wake_left", 0)
	OS.low_processor_usage_mode = true
	GameState.change_scene("res://scenes/main.tscn")
	if OS.low_processor_usage_mode:
		failures.append("画面を 差しかえても 目が さめない(実機で 真っ暗のまま 止まる)")

	if failures.is_empty():
		print("POWER OK: 低消費モード・fps 上限・物理 %d 回/秒・起動画面の色" % ticks)
	else:
		for f in failures:
			print("FAIL: " + str(f))
	get_tree().quit(0 if failures.is_empty() else 1)
