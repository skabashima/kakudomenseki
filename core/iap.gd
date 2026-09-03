extends Node
## 課金マネージャ(オートロード: Iap)。
## 「各編の最初の4ステージは無料 + 買い切りで全ステージ解放」の1商品(非消費型 kakudomenseki_unlock_all)。
##
## 3層構造:
##   1) ストアプラグインが無い環境(PC/エディタ/headless、または未導入のモバイル)＝スタブ。
##      has_store()=false。ゲート/解放画面/premium永続は動くが実購入は不可。
##   2) Android: Google Play Billing プラグイン(シングルトン "GodotGooglePlayBilling")＝signal式。
##   3) iOS:     StoreKit プラグイン(シングルトン "InAppStore")＝pending event ポーリング式。
##
## いずれも「購入成功／復元成功／起動時の所有確認」で GameState.set_premium(true) を呼ぶ。
##
## 【重要・要実機検証】プラグインのメソッド名/シグナル名/戻り値の形はバージョンで差がある。
##   本ファイルは広く使われている形に合わせ、存在チェック(has_method/has_signal)で
##   ラップしてあるので API がズレても「購入失敗」に落ちるだけでクラッシュはしない。
##   実機導入時は store/課金登録情報.md の該当節でメソッド名を必ず突き合わせること。
##   (このファイルは さわる物理 で実機検証ずみの実装をそのまま移植したもの)

const PRODUCT_ID := "kakudomenseki_unlock_all"      # Google Play / App Store 共通の非消費型 商品ID
const PRICE_FALLBACK := "¥500"      # ストアから価格を取得できないときの表示
const _AND_SINGLETON := "GodotGooglePlayBilling"
const _IOS_SINGLETON := "InAppStore"

signal price_ready(text)              # ローカライズ価格が用意できた
signal purchase_done(ok, msg)         # 購入完了(ok=成功)
signal restore_done(ok)               # 復元完了(ok=1件でも所有が復元された)

var _price_text := ""
var _plugin = null                    # ストアプラグインのシングルトン(無ければ null＝スタブ)
var _platform := ""                   # "android" / "ios" / ""(スタブ)
var _connected := false               # Android/OpenIAP: 課金サービス接続済みか
var _restoring := false               # 復元操作の最中か(購入イベントを復元完了として扱う)
var _openiap := false                 # iOS で OpenIAP プラグイン(GodotIapPlugin/StoreKit2)を使うか

# ══════════ 記録(実機で 何が 起きたかを その場で 見る)══════════
## 課金は 実機でしか 動かず、落ちるときは 静かに 落ちる。
## 「SKU not found」のような ストア側の 返事を 後から 読めるように、
## 節目を ここに 残す(scenes/iap_check.tscn が 画面に 出す)。
const LOG_MAX := 60
var _log: Array = []
var last_error := {}          # 直近の 失敗(code / message)

# ══════════ 初期化 ══════════
func note(msg: String) -> void:
	_log.append("[%.1fs] %s" % [Time.get_ticks_msec() / 1000.0, msg])
	if _log.size() > LOG_MAX:
		_log.remove_at(0)
	print("[Iap] " + msg)


func log_lines() -> Array:
	return _log.duplicate()


func _ready() -> void:
	note("起動 OS=%s" % OS.get_name())
	if Engine.has_singleton(_AND_SINGLETON):
		_platform = "android"
		_plugin = Engine.get_singleton(_AND_SINGLETON)
		note("Google Play Billing を 見つけた")
		_setup_android()
	elif OS.get_name() == "iOS" and get_node_or_null("/root/GodotIapPlugin") != null:
		# iOS は OpenIAP プラグイン(GodotIapPlugin autoload・StoreKit2)を使う
		_platform = "ios"
		_openiap = true
		_plugin = get_node_or_null("/root/GodotIapPlugin")
		note("iOS の OpenIAP プラグイン(StoreKit2)を 見つけた")
		_setup_openiap()
	elif Engine.has_singleton(_IOS_SINGLETON):
		_platform = "ios"
		_plugin = Engine.get_singleton(_IOS_SINGLETON)
		note("iOS の 旧 InAppStore を 見つけた")
		_setup_ios()

func _setup_android() -> void:
	# 実プラグイン(godot-google-play-billing v3.2.0)は接続前に initPlugin() が必須。
	# (同梱の BillingClient.gd も _init で initPlugin→signal接続→startConnection の順で行う)
	_call_variant(["initPlugin", "init_plugin"], [[]])
	# シグナル名は v2/v3 の実名を第一に、旧版(3.x)の別名も併せて接続
	# (has_signal で存在するものだけ張るので余分な接続は無害)。
	_safe_connect("connected", _on_and_connected)
	_safe_connect("disconnected", _on_and_disconnected)
	_safe_connect("connect_error", _on_and_connect_error)
	_safe_connect("query_product_details_response", _on_and_products)    # 実API(v2)
	_safe_connect("product_details_query_completed", _on_and_products)   # 旧別名
	_safe_connect("sku_details_query_completed", _on_and_products)       # 旧別名
	_safe_connect("product_details_query_error", _on_and_products_error) # 旧別名
	_safe_connect("on_purchase_updated", _on_and_purchases_updated)      # 実API(v2)
	_safe_connect("purchases_updated", _on_and_purchases_updated)        # 旧別名
	_safe_connect("purchase_error", _on_and_purchase_error)             # 旧版のみ(v2は response_code で判定)
	_safe_connect("acknowledge_purchase_response", _on_and_acknowledged) # 実API(v2)
	_safe_connect("purchase_acknowledged", _on_and_acknowledged)         # 旧別名
	_safe_connect("query_purchases_response", _on_and_query_purchases)   # 実API(v2)
	_call_variant(["startConnection", "start_connection"], [[]])

func _setup_ios() -> void:
	# StoreKit は pending event を _process でポーリングする(signal を持たない実装が多い)
	set_process(_platform == "ios")

# ══════════ iOS: OpenIAP (GodotIapPlugin / StoreKit2・signal式) ══════════
func _setup_openiap() -> void:
	set_process(false)   # OpenIAPはsignal式でポーリング不要
	_safe_connect("purchase_updated", _on_oi_purchase_updated)
	_safe_connect("purchase_error", _on_oi_purchase_error)
	_safe_connect("products_fetched", _on_oi_products)
	_safe_connect("connected", _on_oi_connected)
	_oi_connect.call_deferred()

func _oi_connect() -> void:
	if _plugin != null and _plugin.has_method("init_connection"):
		var ok = await _plugin.init_connection()
		_connected = bool(ok)
	else:
		_connected = true
	note("ストアへの 接続: %s" % ("できた" if _connected else "できなかった"))
	if _connected:
		query_price()
		_oi_boot_check()   # 起動時のサイレント所有確認(再インストール等の復元)

func _oi_types():
	return load("res://addons/godot-iap/types.gd")

func _oi_dict(o) -> Dictionary:
	if o is Dictionary: return o
	if is_instance_valid(o) and o.has_method("to_dict"): return o.to_dict()
	return {}

## OpenIAPの await はネイティブ側の完了シグナルが来ないと永久に戻らないことがある
## (TestFlight実機で価格未取得＝購入ボタン無効のまま・復元フリーズの実害)。
## → 各操作に「世代番号＋タイマー」でタイムアウトを付け、遅延完了は世代番号で捨てる。
var _oi_seq := {"price": 0, "restore": 0, "buy": 0}

## seq発行。タイムアウト時は cb_timeout を呼ぶ(完了済みなら何もしない)
func _oi_guard(kind: String, secs: float, cb_timeout: Callable) -> int:
	_oi_seq[kind] = int(_oi_seq[kind]) + 1
	var seq: int = _oi_seq[kind]
	var t := get_tree().create_timer(secs)
	t.timeout.connect(func():
		if int(_oi_seq[kind]) == seq:   # まだ完了していない＝タイムアウト
			_oi_seq[kind] = seq + 1     # 遅れて届いた完了は無効化
			cb_timeout.call())
	return seq

## この操作がまだ有効(タイムアウトしていない)なら true にして世代を進める
func _oi_settle(kind: String, seq: int) -> bool:
	if int(_oi_seq[kind]) != seq:
		return false   # タイムアウト済み＝遅着は捨てる
	_oi_seq[kind] = seq + 1
	return true

func _oi_fetch_price() -> void:
	if _plugin == null or not _plugin.has_method("fetch_products"):
		price_ready.emit.call_deferred(price_text()); return
	var T = _oi_types()
	if T == null:
		price_ready.emit.call_deferred(price_text()); return
	var req = T.ProductRequest.from_dict({"skus": [PRODUCT_ID], "type": "in-app"})
	# 6秒で価格取得を打ち切り、既定価格で購入ボタンを有効化(実価格はAppleの購入シートに出る)
	note("商品を 問い合わせる: %s" % PRODUCT_ID)
	var seq := _oi_guard("price", 6.0, func():
		note("商品の 問い合わせが 6 秒で 返らなかった")
		price_ready.emit(price_text()))
	var products = await _plugin.fetch_products(req)
	if not _oi_settle("price", seq):
		return
	_apply_oi_products(products)

func _apply_oi_products(products) -> void:
	# 戻り値の形式ゆらぎに対応: Array / {"products":[...]} / 単品オブジェクト
	var arr: Array = []
	if products is Array:
		arr = products
	else:
		var pd := _oi_dict(products)
		if pd.get("products") is Array:
			arr = pd["products"]
		elif not pd.is_empty():
			arr = [pd]
	var ids: Array = []
	for p in arr:
		var d := _oi_dict(p)
		ids.append(str(d.get("id", "")))
		if str(d.get("id", "")) == PRODUCT_ID:
			var dp := str(d.get("displayPrice", d.get("display_price", "")))
			if dp != "": _price_text = dp
	if arr.is_empty():
		note("ストアから 商品が 1 つも 返ってこなかった" 			+ "(App Store Connect / Play Console の 商品の 状態を 見ること)")
	else:
		note("ストアが 返した 商品: %s" % ", ".join(PackedStringArray(ids)))
	price_ready.emit(price_text())

func _on_oi_products(result) -> void:
	_apply_oi_products(_oi_dict(result).get("products", []))

func _on_oi_connected() -> void:
	_connected = true

func _oi_purchase() -> void:
	if _plugin == null or not _plugin.has_method("request_purchase"):
		purchase_done.emit.call_deferred(false, "購入を開始できませんでした"); return
	var T = _oi_types()
	if T == null:
		purchase_done.emit.call_deferred(false, "購入を開始できませんでした"); return
	# 商品fetchはStoreKitキャッシュ温めの「ベストエフォート」(最大5秒)。
	# ★実機事実: fetch_productsが空/無応答でも request_purchase 直呼びで購入シートは出る
	#   (復元＝再購入フローで実証済み)。そのため fetch の結果では購入を中断しない。
	#   fetch無応答の場合はタイムアウト側から購入を続行する。
	if _plugin.has_method("fetch_products"):
		var req = T.ProductRequest.from_dict({"skus": [PRODUCT_ID], "type": "in-app"})
		var seq := _oi_guard("buy", 5.0, func(): _oi_request_buy())
		var products = await _plugin.fetch_products(req)
		if not _oi_settle("buy", seq):
			return   # fetch遅着＝タイムアウト側が購入続行済み
		_apply_oi_products(products)
	_oi_request_buy()

## 購入シートを実際に出す(復元と同じ・動作実証済みの request_purchase 経路)
func _oi_request_buy() -> void:
	var T = _oi_types()
	if _plugin == null or T == null or not _plugin.has_method("request_purchase"):
		purchase_done.emit.call_deferred(false, "購入を開始できませんでした"); return
	var props = T.RequestPurchaseProps.from_dict({
		"requestPurchase": {"apple": {"sku": PRODUCT_ID}},
		"type": "in-app",
	})
	# 購入シートの応答(purchase_updated/purchase_error)が一定時間来なければ画面を解放する。
	# ※ユーザーがシートを長く眺めているだけの場合もあるため長め(180秒)。遅れて購入が
	#   完了した場合も _on_oi_purchase_updated が premium を立てるので取りこぼさない。
	var bseq := _oi_guard("buy", 180.0, func():
		purchase_done.emit(false, "ストアからの応答がありませんでした。購入が完了している場合は「購入の復元」をお試しください。"))
	_oi_buy_wait_seq = bseq
	note("購入シートを 要求する: %s" % PRODUCT_ID)
	_plugin.request_purchase(props)
	# 完了/失敗は purchase_updated / purchase_error シグナルで届く

var _oi_buy_wait_seq := -1   # 購入シート待ちの世代(purchase_updated/error で解決)

## 復元のウォッチドッグ。iOS実機で get_available_purchases の完了もタイマーの
## timeoutも来ずに「復元処理中…」のまま固まる事象があったため、タイマー/ラムダに
## 一切依存しない _process 駆動の締切に変更(フレームが動く限り必ず発火する)。
var _oi_restore_round := 0
var _oi_restore_left := -1.0

func _oi_restore() -> void:
	# ★実機で getAvailablePurchases が応答せず固まるため使用しない。
	# 非消耗型の復元は Apple 標準の「再購入フロー」で行う：request_purchase を
	# 呼ぶと、所有済みの場合 StoreKit が無料で復元し purchase_updated が届く。
	# (購入と同じ・動作確認済みの経路だけを使う)
	_oi_restore_round += 1
	var rr := _oi_restore_round
	_oi_restore_left = 25.0   # シート操作の時間も見込む
	set_process(true)   # ウォッチドッグ(フレーム駆動＝必ず動く)
	_oi_restore_via_purchase(rr)

func _oi_restore_via_purchase(rr: int) -> void:
	if _plugin == null or not _plugin.has_method("request_purchase"):
		_oi_restore_finish(rr, false)
		return
	var T = _oi_types()
	if T == null:
		_oi_restore_finish(rr, false)
		return
	var props = T.RequestPurchaseProps.from_dict({
		"requestPurchase": {"apple": {"sku": PRODUCT_ID}},
		"type": "in-app",
	})
	_plugin.request_purchase(props)
	# 所有済み→purchase_updated(_on_oi_purchase_updated が復元として処理)
	# 未所有→購入シート(キャンセルすれば purchase_error → 復元失敗として処理)

func _oi_restore_finish(rr: int, ok: bool) -> void:
	if _oi_restore_round != rr:
		return
	_oi_restore_round += 1
	_oi_restore_left = -1.0
	if _openiap: set_process(false)
	if ok: GameState.set_premium(true)
	_restoring = false
	restore_done.emit(ok)

func _oi_boot_check() -> void:
	if _plugin == null or not _plugin.has_method("get_available_purchases"): return
	var purchases = await _plugin.get_available_purchases()
	if _oi_owns(purchases): GameState.set_premium(true)

func _oi_owns(purchases) -> bool:
	if purchases is Array:
		for p in purchases:
			if _oi_purchase_owns(_oi_dict(p)): return true
	return false

func _oi_purchase_owns(d: Dictionary) -> bool:
	if str(d.get("productId", "")) == PRODUCT_ID: return true
	if str(d.get("id", "")) == PRODUCT_ID: return true
	var ids = d.get("ids", [])
	if ids is Array:
		for x in ids:
			if str(x) == PRODUCT_ID: return true
	return false

func _on_oi_purchase_updated(purchase) -> void:
	var d := _oi_dict(purchase)
	if not _oi_purchase_owns(d): return
	# 復元ウォッチドッグを解除(復元は購入フロー経由で行うため、ここが完了点)
	_oi_restore_left = -1.0
	if _openiap and _platform == "ios": set_process(false)
	# 購入シート待ちのタイムアウトを解決(遅着でも premium は立てる＝取りこぼし防止)
	if _oi_buy_wait_seq >= 0:
		_oi_settle("buy", _oi_buy_wait_seq)
		_oi_buy_wait_seq = -1
	# 非消費型のトランザクション完了を通知(未完了だと毎起動でリプレイされる)
	if _plugin.has_method("finish_transaction"):
		_plugin.finish_transaction(purchase, false)
	elif _plugin.has_method("finish_transaction_dict"):
		_plugin.finish_transaction_dict(d, false)
	note("購入/復元 できた: %s" % PRODUCT_ID)
	GameState.set_premium(true)
	if _restoring:
		_restoring = false
		restore_done.emit(true)
	else:
		purchase_done.emit(true, "")

func _on_oi_purchase_error(error) -> void:
	_oi_restore_left = -1.0
	if _openiap and _platform == "ios": set_process(false)
	if _oi_buy_wait_seq >= 0:
		if not _oi_settle("buy", _oi_buy_wait_seq):
			_oi_buy_wait_seq = -1
			return   # タイムアウト通知済み＝二重通知しない
		_oi_buy_wait_seq = -1
	var d := _oi_dict(error)
	var code := str(d.get("code", ""))
	last_error = {"code": code, "message": str(d.get("message", ""))}
	note("ストアが 失敗を 返した: code=%s / %s" % [code, str(d.get("message", ""))])
	var cancelled := code in ["user-cancelled", "user_cancelled", "cancelled", "e_user_cancelled"]
	if _restoring:
		_restoring = false
		restore_done.emit(false)
	elif cancelled:
		purchase_done.emit(false, "")   # キャンセルは静かに
	else:
		purchase_done.emit(false, str(d.get("message", "購入に失敗しました")))

# ══════════ 公開API(Main から呼ぶ)══════════
func has_store() -> bool:
	if _plugin == null: return false
	if _platform == "android": return _connected
	if _openiap: return _connected   # OpenIAP: init_connection 完了で真
	return true   # 旧InAppStore は接続概念が無い

func store_platform() -> String:
	if _platform != "": return _platform
	match OS.get_name():
		"Android": return "android"
		"iOS": return "ios"
		_: return ""

func price_text() -> String:
	return _price_text if _price_text != "" else PRICE_FALLBACK

## 起動時のサイレント所有確認(再インストール・機種変更・返金の反映)
func boot_check() -> void:
	if _plugin == null: return
	if _platform == "android":
		# 接続完了後の _on_and_connected で queryPurchases する。接続済みなら即問い合わせ。
		if _connected: _and_query_owned()
	elif _platform == "ios":
		if _openiap:
			_oi_boot_check()   # OpenIAP: 所有(entitlement)をサイレント確認して復元
		# 旧InAppStore は所有の静的問い合わせが無いので明示の「復元」に委ねる

## ローカライズ価格を非同期取得。取得後 price_ready を発火。
func query_price() -> void:
	if _plugin == null:
		_price_text = PRICE_FALLBACK
		price_ready.emit.call_deferred(_price_text)
		return
	if _platform == "android":
		if not _connected:
			price_ready.emit.call_deferred(price_text())   # 未接続なら暫定表示
			return
		# v2: queryProductDetails(product_ids:Array, product_type:"inapp")。旧SKU版は候補名でフォールバック。
		_call_variant(["queryProductDetails", "query_product_details", "querySkuDetails"],
			[[PackedStringArray([PRODUCT_ID]), "inapp"], [[PRODUCT_ID], "inapp"]])
	elif _platform == "ios":
		if _openiap:
			_oi_fetch_price()
		else:
			# 旧InAppStore経路: メソッドが無い/呼べない場合も必ず price_ready を返す
			#(返さないと解放画面の購入ボタンが「価格を取得中…」の無効のままになる)
			if not _call_if("request_product_info", [{"product_ids": [PRODUCT_ID]}]):
				price_ready.emit.call_deferred(price_text())

## 購入フローを開始。完了時 purchase_done(ok, msg) を発火。
func purchase() -> void:
	note("「買う」を 押した(platform=%s / 接続=%s)" % [
		_platform if _platform != "" else "スタブ", _connected])
	if _plugin == null:
		purchase_done.emit.call_deferred(false, "この環境では ストアに接続できません")
		return
	if _platform == "android":
		if not _connected:
			purchase_done.emit.call_deferred(false, "ストアに接続できていません")
			return
		# v2: purchase(product_id, purchase_option_id, offer_id, is_offer_personalized) の4引数。
		# ★launchBillingFlow の即時結果コードを確認する。起動に失敗すると購入シートが出ず
		#   「押しても無反応」になるため、失敗コードを拾って理由を表示する。
		var res = _call_variant_ret(["purchase"], [
			[PRODUCT_ID, "", "", false],
			[PRODUCT_ID, false],
			[PRODUCT_ID],
		])
		var code := _resp_code(res)
		note("購入シートの 起動コード: %d" % code)
		# 0=購入シートの起動に成功(購入結果は on_purchase_updated で届く)。
		# それ以外(既所有7は signal で拾う)＝起動失敗なので、無反応にせず理由を出す。
		if code != 0 and code != 7:
			purchase_done.emit.call_deferred(false, _billing_msg(code))
	elif _platform == "ios":
		_restoring = false
		if _openiap:
			_oi_purchase()
		else:
			_call_if("purchase", [{"product_id": PRODUCT_ID}])

## 過去の購入を復元。完了時 restore_done(ok) を発火。
func restore() -> void:
	note("「復元」を 押した")
	if _plugin == null:
		restore_done.emit.call_deferred(false)
		return
	if _platform == "android":
		if not _connected:
			restore_done.emit.call_deferred(false)
			return
		_restoring = true
		_and_query_owned()
	elif _platform == "ios":
		_restoring = true
		if _openiap:
			_oi_restore()
		else:
			_call_if("restore_purchases", [])

# ══════════ Android ハンドラ(signal式)══════════
func _on_and_connected() -> void:
	_connected = true
	note("Google Play に 接続できた")
	query_price()      # 価格を先読み
	_and_query_owned() # 起動時の所有確認

func _on_and_disconnected() -> void:
	_connected = false
	if _has_m("startConnection"):
		_plugin.startConnection()   # 自動再接続

func _on_and_connect_error(_code = 0, _msg = "") -> void:
	_connected = false

func _and_query_owned() -> void:
	# v2: queryPurchases(product_type:"inapp", include_suspended_subs:bool)。旧版は1引数。
	_call_variant(["queryPurchases", "query_purchases"], [["inapp", false], ["inapp"]])

## 商品詳細(価格)取得完了。v2 は {response_code, product_details:[...]} の辞書で来る。
func _on_and_products(response) -> void:
	var list = _resp_list(response, ["product_details", "product_details_list", "sku_details", "result"])
	var price := _extract_price(list)
	if price != "":
		_price_text = price
	price_ready.emit(price_text())

func _on_and_products_error(_a = 0, _b = "", _c = null) -> void:
	price_ready.emit(price_text())

## 購入結果。v2 は on_purchase_updated({response_code, purchases:[...]})。
## v2 には purchase_error シグナルが無いため、キャンセル/失敗もここで response_code から判定する。
func _on_and_purchases_updated(response) -> void:
	var code := _resp_code(response)                                    # 0=OK, 1=キャンセル, 7=既所有
	var owned := _scan_owned(_resp_list(response, ["purchases", "purchases_list"]))
	if owned or code == 7:                                              # 7=ITEM_ALREADY_OWNED
		if code == 7 and not owned:
			_and_query_owned()                                          # 既所有だが応答に無い→所有確認
		GameState.set_premium(true)
		if _restoring:
			_restoring = false
			restore_done.emit(true)
		else:
			purchase_done.emit(true, "")
		return
	# ここから失敗系
	if _restoring:
		_restoring = false
		restore_done.emit(false)
	elif code != 0:                                                     # OK(0)以外＝キャンセル/エラー
		purchase_done.emit(false, _billing_msg(code))
	# code==0 だが未所有(承認待ち等)は無音。後続の queryPurchases 応答で拾う。

func _on_and_purchase_error(_code = 0, msg = "") -> void:
	if _restoring:
		_restoring = false
		restore_done.emit(false)
	else:
		purchase_done.emit(false, str(msg) if str(msg) != "" else "購入をキャンセルしました")

func _on_and_acknowledged(_a = null) -> void:
	pass   # 承認完了。premium は購入/所有確認側で確定済み

## queryPurchases の応答(所有一覧)。v2 は {response_code, purchases:[...]}。
func _on_and_query_purchases(response) -> void:
	var owned := _scan_owned(_resp_list(response, ["purchases", "purchases_list"]))
	if owned:
		GameState.set_premium(true)
		if _restoring:
			_restoring = false
			restore_done.emit(true)
	else:
		# 所有していない＝返金/未購入。復元操作なら失敗を返す。
		if _restoring:
			_restoring = false
			restore_done.emit(false)
		# 注意: 起動時確認で「非所有」だからと自動で premium を落とすと、
		# 一時的な取得失敗で解放が消える事故になる。返金の失効は慎重に扱うため、
		# ここでは premium=false への自動ダウングレードは行わない(ガイド§返金参照)。

## 所有購入の中に kakudomenseki_unlock_all があり purchased 状態か
func _scan_owned(purchases) -> bool:
	if typeof(purchases) != TYPE_ARRAY:
		return false
	for p in purchases:
		if typeof(p) != TYPE_DICTIONARY: continue
		# 商品ID一致。v2 は product_ids(配列)。旧版 products / 単一 sku / product_id にも対応。
		var ids := []
		if p.has("product_ids"): ids = p["product_ids"]
		elif p.has("products"): ids = p["products"]
		elif p.has("sku"): ids = [p["sku"]]
		elif p.has("product_id"): ids = [p["product_id"]]
		if not (PRODUCT_ID in ids): continue
		# 購入状態(1=purchased)。未指定なら所有扱い。
		var st := int(p.get("purchase_state", p.get("purchaseState", 1)))
		if st != 1: continue
		# 未承認なら承認する(Billingの要件。3日以内に承認しないと自動返金)
		var token := str(p.get("purchase_token", p.get("purchaseToken", "")))
		if token != "" and not bool(p.get("is_acknowledged", p.get("isAcknowledged", false))):
			_call_variant(["acknowledgePurchase", "acknowledge_purchase"], [[token]])
		return true
	return false

## 商品詳細リストから formatted price を取り出す(Billing v5+/旧SKU 両対応の best-effort)
func _extract_price(list) -> String:
	if typeof(list) != TYPE_ARRAY:
		return ""
	for d in list:
		if typeof(d) != TYPE_DICTIONARY: continue
		# v2: one_time_purchase_offer_details_list[0].formatted_price(リスト)
		#     ／ 旧: one_time_purchase_offer_details.formatted_price(単体)
		for k in ["one_time_purchase_offer_details_list", "one_time_purchase_offer_details"]:
			if d.has(k):
				var o = d[k]
				if typeof(o) == TYPE_ARRAY and o.size() > 0: o = o[0]
				if typeof(o) == TYPE_DICTIONARY and o.has("formatted_price"):
					return str(o["formatted_price"])
		# 旧SKU: price / formatted_price("¥1,600" 形式)
		if d.has("formatted_price"):
			return str(d["formatted_price"])
		if d.has("price"):
			return str(d["price"])
	return ""

# ══════════ iOS ハンドラ(pending event ポーリング式)══════════
func _process(dt: float) -> void:
	# 復元の締切(_oi_restore のウォッチドッグ。タイマー非依存＝必ず動く)
	if _oi_restore_left > 0.0:
		_oi_restore_left -= dt
		if _oi_restore_left <= 0.0:
			_oi_restore_left = -1.0
			_oi_restore_round += 1   # 遅着完了を無効化
			_restoring = false
			if _openiap: set_process(false)
			restore_done.emit(false)
	if _platform != "ios" or _plugin == null:
		return
	if _openiap:
		return   # OpenIAPはsignal式(上のウォッチドッグのみ使用)
	if not _plugin.has_method("get_pending_event_count"):
		return
	while int(_plugin.get_pending_event_count()) > 0:
		var e = _plugin.pop_pending_event()
		if typeof(e) != TYPE_DICTIONARY: continue
		_handle_ios_event(e)

func _handle_ios_event(e: Dictionary) -> void:
	var type := str(e.get("type", ""))
	var result := str(e.get("result", ""))
	match type:
		"product_info":
			# ids/prices(localized_prices)を含む。kakudomenseki_unlock_all の価格を拾う。
			var price := _ios_price_from(e)
			if price != "": _price_text = price
			price_ready.emit(price_text())
		"purchase":
			if result == "ok":
				GameState.set_premium(true)
				if str(e.get("product_id", "")) == PRODUCT_ID or e.get("product_id", "") == "":
					if _restoring:
						_restoring = false
						restore_done.emit(true)
					else:
						purchase_done.emit(true, "")
				# トランザクション完了通知(必要なAPIのみ)
				_call_if("finish_transaction", [PRODUCT_ID])
			else:
				if _restoring:
					_restoring = false
					restore_done.emit(false)
				else:
					purchase_done.emit(false, "購入をキャンセルしました")
		"restore":
			# 復元完了イベント。ok の restore で set_premium 済みでなければここで確定。
			if result == "ok":
				GameState.set_premium(true)
				_restoring = false
				restore_done.emit(true)
			else:
				_restoring = false
				restore_done.emit(false)

func _ios_price_from(e: Dictionary) -> String:
	# {"ids":[...], "localized_prices":[...]} 形式を想定。kakudomenseki_unlock_all のインデックスを引く。
	var ids = e.get("ids", e.get("product_ids", []))
	var prices = e.get("localized_prices", e.get("prices", []))
	if typeof(ids) == TYPE_ARRAY and typeof(prices) == TYPE_ARRAY:
		for i in range(min(ids.size(), prices.size())):
			if str(ids[i]) == PRODUCT_ID:
				return str(prices[i])
	# 単品情報の別形式
	if e.has("localized_price"): return str(e["localized_price"])
	if e.has("price"): return str(e["price"])
	return ""

# ══════════ 汎用ヘルパ(API 差異に強くする)══════════
## Android実プラグイン(GodotGooglePlayBilling v3.2.0)の確定API(AARのclassファイルから抽出)。
## Godot 4.7 は Javaメソッドを has_method()/get_method_list() に載せず、
## has_java_method() も存在しないため、GD側からは存在確認が「できない」。
## → この確定名は存在チェックなしで直接 callv する(呼べなければエラーログのみで無害)。
const _AND_KNOWN := {
	"initPlugin": 0, "startConnection": 0, "endConnection": 0,
	"queryProductDetails": 2, "queryPurchases": 2,
	"purchase": 4, "purchaseSubscription": 4,
	"acknowledgePurchase": 1, "consumePurchase": 1, "isReady": 0,
}

## プラグインがそのメソッドを持つか。Android の JNISingleton は Javaメソッドが
## has_method() に載らない(4.4は has_java_method() で判定できたが 4.7 はそれも無い)。
## ★実機で全メソッドが「無い」と誤判定され課金が完全に沈黙していた真因。
func _has_m(nm: String) -> bool:
	if _plugin == null:
		return false
	if _plugin.has_method(nm):
		return true
	if _plugin.has_method("has_java_method"):
		return _plugin.has_java_method(nm)
	# 4.7: 内省不可 → 実AARに在ると確認済みの名前だけ「在る」とみなして直接呼ぶ
	return _platform == "android" and _AND_KNOWN.has(nm)
	

func _safe_connect(sig: String, cb: Callable) -> void:
	if _plugin != null and _plugin.has_signal(sig) and not _plugin.is_connected(sig, cb):
		_plugin.connect(sig, cb)

func _call_if(method: String, args: Array) -> bool:
	if _has_m(method):
		_plugin.callv(method, args)
		return true
	return false

## 候補メソッド名のうち最初に存在するものを呼ぶ(版差の吸収)
func _call_any(methods: Array, args: Array) -> bool:
	for mth in methods:
		if _call_if(str(mth), args):
			return true
	return false

## 候補メソッド名×複数の引数列。存在するメソッドの実引数数に一致する列を選んで呼ぶ。
## (purchase の 4/2/1引数、queryPurchases の 2/1引数など、版で引数数が違う問題への対策)
func _call_variant(methods: Array, arg_variants: Array) -> bool:
	if _plugin == null:
		return false
	for mth in methods:
		var nm := str(mth)
		if not _has_m(nm):
			continue
		var argc := _method_argc(nm)
		if argc >= 0:
			for v in arg_variants:
				if (v as Array).size() == argc:
					_plugin.callv(nm, v)
					return true
		# 実引数数が不明(JNI等)＝先頭(実プラグイン想定＝最長)で呼ぶ
		_plugin.callv(nm, arg_variants[0])
		return true
	return false

## _call_variant と同じ選択ロジックで、呼んだメソッドの戻り値を返す版。
## purchase() の launchBillingFlow 即時結果コードを拾うために使う(起動失敗を「無反応」にしない)。
func _call_variant_ret(methods: Array, arg_variants: Array):
	if _plugin == null:
		return null
	for mth in methods:
		var nm := str(mth)
		if not _has_m(nm):
			continue
		var argc := _method_argc(nm)
		if argc >= 0:
			for v in arg_variants:
				if (v as Array).size() == argc:
					return _plugin.callv(nm, v)
		# 実引数数が不明(JNI等)＝先頭(実プラグイン想定＝最長)で呼ぶ
		return _plugin.callv(nm, arg_variants[0])
	return null

## プラグインのメソッドの宣言引数数(get_method_list より)。不明なら -1。
func _method_argc(nm: String) -> int:
	if _plugin == null:
		return -1
	for mi in _plugin.get_method_list():
		if str(mi.get("name", "")) == nm:
			var a = mi.get("args", [])
			return (a as Array).size() if typeof(a) == TYPE_ARRAY else -1
	return -1

## シグナル応答から配列部分を取り出す。v2 は {response_code, product_details/purchases:[...]}。
## 旧版は生の配列で来ることもあるので両対応。
func _resp_list(response, keys: Array) -> Array:
	if typeof(response) == TYPE_ARRAY:
		return response
	if typeof(response) == TYPE_DICTIONARY:
		for k in keys:
			if response.has(k) and typeof(response[k]) == TYPE_ARRAY:
				return response[k]
	return []

## シグナル応答の response_code(0=OK)。辞書でなければ 0 扱い。
func _resp_code(response) -> int:
	if typeof(response) == TYPE_DICTIONARY:
		return int(response.get("response_code", response.get("status", 0)))
	return 0

## Billing のレスポンスコードを日本語メッセージに(OK=0/キャンセル=1/既所有=7 等)。
## _toast(プレーンLabel)で出すので、他の購入メッセージと同様ふりがな記法は使わない。
func _billing_msg(code: int) -> String:
	match code:
		1: return "購入をキャンセルしました"
		2, 3: return "ストアに接続できませんでした"
		4: return "この商品は いま購入できません"
		5, 6: return "購入に失敗しました"
		7: return "すでに購入済みです"
		_: return "購入に失敗しました(コード %d)" % code

# ══════════ デバッグ(PC/エディタ検証用。ストア未接続時のみ)══════════
func debug_toggle_premium() -> bool:
	GameState.set_premium(not GameState.premium)
	return GameState.premium

## 実機での接続確認用の状態レポート。ストアプラグインの検出可否・接続状態・価格に加え、
## プラグインが実際に公開しているメソッド名/シグナル名を返す(ガイド§Cの「API突き合わせ」を
## 実機画面上で行うため)。PC/エディタでは singleton 未検出＝スタブとして返る。
func debug_report() -> Dictionary:
	var rep := {
		"os": OS.get_name(),
		"singleton_android": Engine.has_singleton(_AND_SINGLETON),
		"singleton_ios": Engine.has_singleton(_IOS_SINGLETON),
		"platform": _platform if _platform != "" else "(スタブ)",
		"connected": _connected,
		"has_store": has_store(),
		"price": price_text(),
		"price_live": _price_text != "",   # true＝ストアから実取得／false＝既定値(＝商品が未取得＝要ASC設定)
		"premium": GameState.premium,
		"product_id": PRODUCT_ID,
		"last_error": last_error,
		"log": log_lines(),
		"methods": PackedStringArray(),
		"signals": PackedStringArray(),
	}
	if _plugin != null:
		for mi in _plugin.get_method_list():
			rep["methods"].append(str(mi.get("name", "")))
		# Android の JNISingleton は Javaメソッドが get_method_list に載らない。
		# 4.4系: has_java_method で存在確認して補完。4.7系: それも無いので確定API表で補完。
		if _plugin.has_method("has_java_method"):
			for nm in debug_expected_names().get("methods", []):
				if not (str(nm) in rep["methods"]) and _plugin.has_java_method(str(nm)):
					rep["methods"].append(str(nm))
		elif _platform == "android":
			for nm in _AND_KNOWN:
				if not (str(nm) in rep["methods"]):
					rep["methods"].append(str(nm))
		for si in _plugin.get_signal_list():
			rep["signals"].append(str(si.get("name", "")))
	return rep

## debug_report のメソッド/シグナル一覧に、Iap.gd が実際に呼ぶ/受ける名前が在るか判定する補助。
## 実機で「呼んでいる名前がプラグインに存在するか」を一目で確認するため。
func debug_expected_names() -> Dictionary:
	if _openiap:
		# iOS OpenIAP(GodotIapPlugin)。Iap.gd が実際に呼ぶ/受ける名前。
		return {
			"methods": ["init_connection", "fetch_products", "request_purchase", "get_available_purchases", "finish_transaction"],
			"signals": ["connected", "disconnected", "products_fetched", "purchase_updated", "purchase_error"],
		}
	# Android GooglePlayBilling(および旧iOS InAppStore)
	return {
		"methods": ["initPlugin", "startConnection", "queryProductDetails", "queryPurchases", "purchase", "acknowledgePurchase"],
		"signals": ["connected", "disconnected", "connect_error",
			"query_product_details_response", "on_purchase_updated",
			"acknowledge_purchase_response", "query_purchases_response"],
	}
