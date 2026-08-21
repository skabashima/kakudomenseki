class_name StoryDefs
## ストーリー。図形の「動かしても変わらないもの」を自分で見つけていく筋書き。
##
## ■ 本編と何が違うか
## 本編(problem.tscn)は「図が出る → 公式を使って値を答える」。
## ここは逆で、**公式を知らないところから、図を動かして、変わらないものを見つける**。
## 動詞が違うので、同じ単元でも遊びが重ならない。
##
## 判定は選択肢だが、**自分で何度か動かして記録するまで選択肢が開かない**。
## 数値は図の座標から計算しているので、当てずっぽうでは進めない。
##
## シーンの種類:
##   talk    … 会話。art があれば挿絵、fig があれば図を上に出す
##   measure … 図の点を指で動かして記録し、「何が一定か」を選ぶ
##   solve   … 見つけたことを使って、本編と同じ生成器の問題を 1 問解く(3択)
##
## 章は 中学受験 → 高校受験 → 大学受験 の順。前の章をクリアすると次が開く。
##
## 章を足すときは CHAPTERS に足し、動かす図が新しければ
## start_of / clamp_of / spec_of / readout_of の 4 つに種類を足す。

const CHAPTERS := [
	# ============ 中学受験レベル ============
	{
		"id": "ch1", "title": "三角形の秘密", "level": "中学受験",
		"place": "ギリシャ、紀元前300年ごろ",
		"found": "三角形の内角の和は、形を変えても 180°",
		"scenes": [
			{"type": "talk", "title": "測量師の見習い", "art": "field", "lines": [
				"あなたは土地を測る仕事の見習いだ。畑の形はどれも三角形をしている。",
				"親方が言う。「三角形の 3 つの角を全部たすと、いつも同じ数になる」",
				"「どんな三角形でもですか」と聞くと、親方は笑って砂に三角形を描いた。",
				"「自分で確かめてみろ。それが測量師の仕事だ」",
			]},
			{"type": "measure", "title": "頂点を動かしてみる", "fig": "triangle", "trials": 3,
				"lead": "三角形の上の頂点(金色の点)を指で動かすと、3 つの角が変わる。"
					+ "形をいくつか作って、そのたびに「この形を記録する」を押そう。",
				"question": "頂点を動かすと、3 つの角の和はどうなった?",
				"choices": [
					"とがった三角形ほど、和は小さくなった",
					"どんな形にしても、和は 180° のままだった",
					"大きい三角形ほど、和は大きくなった",
				], "answer": 1, "invariant": {"value": 180.0, "tol": 0.6},
				"after": "どう動かしても和は 180°。これが三角形の決まりごとだ。"},
			{"type": "talk", "title": "なぜ 180° なのか", "fig": "parallel_proof", "lines": [
				"親方が、頂点 A を通って底辺と平行な線を引いた。",
				"「錯角は等しい。だから左の角は ∠B と同じ、右の角は ∠C と同じだ」",
				"平行線の上で、3 つの角がぴったり一直線に並んだ。",
				"一直線は 180°。だから三角形の内角の和は 180° になる。",
			]},
			{"type": "solve", "title": "畑の角を求める", "stage": "e1", "tier": 1,
				"lead": "見つけたことを使ってみよう。", "after": "測量師として一歩前へ。"},
			{"type": "talk", "title": "次の謎へ", "art": "dusk", "lines": [
				"「では四角形は?」あなたは砂に四角形を描いてみる。",
				"対角線を 1 本引くと、三角形が 2 つ。ということは 180° が 2 つぶん ―",
				"数えてみたくなる。だが日は暮れかけている。確かめるのは次の機会に。",
				"変わらないものを見つける。それが図形をあばく第一歩だ。",
			]},
		],
	},
	{
		"id": "ch2", "title": "平行線のいたずら", "level": "中学受験",
		"place": "エジプト、ナイルの岸辺",
		"found": "平行線に 1 本の線が交わるとき、錯角はいつも等しい",
		"scenes": [
			{"type": "talk", "title": "二本の道", "art": "field", "lines": [
				"ナイルの岸に、まっすぐな道が二本、どこまでも平行に走っている。",
				"その二本を斜めに横切る細い道が一本。旅人がその道を行く。",
				"親方が言う。「斜めの道の傾きを変えても、変わらない角がある」",
				"どの角のことだろう。斜めの道を動かして確かめよう。",
			]},
			{"type": "measure", "title": "斜めの道を動かす", "fig": "parallel_lines", "trials": 3,
				"lead": "上の道の上にある金色の点を動かすと、斜めの道の傾きが変わる。"
					+ "斜めに交わってできる「はす向かいの角」を記録しよう。",
				"question": "傾きを変えると、2 つの角(錯角)はどうなった?",
				"choices": [
					"いつも同じ大きさだった",
					"上の角のほうがいつも大きかった",
					"傾けるほど差が広がった",
				], "answer": 0, "invariant": {"value": 0.0, "tol": 0.6},
				"after": "はす向かいの角 ― 錯角は、どんな傾きでも等しい。"},
			{"type": "talk", "title": "同位角と錯角", "fig": "parallel_proof", "lines": [
				"平行線と交わる線がつくる角には名前がついている。",
				"同じ向きにできる角が同位角、はす向かいの角が錯角。どちらも等しい。",
				"これが分かると、離れた場所の角を「移してくる」ことができる。",
				"第1章で内角の和が 180° になったのも、この錯角のおかげだった。",
			]},
			{"type": "solve", "title": "折れ線の角", "stage": "e4", "tier": 1,
				"lead": "錯角を使って角を移してみよう。", "after": "角は移せる。覚えておこう。"},
			{"type": "talk", "title": "岸を離れて", "art": "dusk", "lines": [
				"川の対岸までの距離も、この理屈で測れるという。",
				"直接は測れないものを、測れるものから割り出す ―",
				"それが測量という仕事の正体らしい。",
			]},
		],
	},
	{
		"id": "ch3", "title": "円のふしぎ", "level": "中学受験",
		"place": "バビロニア、車輪の工房",
		"found": "円周 ÷ 直径 は、どんな大きさの円でも 3.14…(円周率)",
		"scenes": [
			{"type": "talk", "title": "車輪をつくる", "art": "wheel", "lines": [
				"車輪の工房に来た。大小さまざまな車輪が転がっている。",
				"職人が言う。「車輪のふちの長さは、さしわたしの 3 倍と少しだ」",
				"「大きい車輪でも小さい車輪でも、同じ 3 倍と少しですか」",
				"「そうだ。ずっと昔からそうだ」― 本当だろうか。測ってみよう。",
			]},
			{"type": "measure", "title": "大きさを変えて測る", "fig": "circle", "trials": 3,
				"lead": "金色の点を左右に動かすと、円の大きさが変わる。"
					+ "直径と、巻き尺で測った円周を記録しよう。",
				"question": "円の大きさを変えると、円周 ÷ 直径 はどうなった?",
				"choices": [
					"大きい円ほど大きくなった",
					"どんな大きさでも 3.14 くらいで変わらなかった",
					"小さい円ほど大きくなった",
				], "answer": 1, "invariant": {"value": 3.1416, "tol": 0.01},
				"after": "円周 ÷ 直径 はいつも 3.14…。これを円周率(π)と呼ぶ。"},
			{"type": "talk", "title": "3.14 の正体", "fig": "circle_proof", "lines": [
				"円の中に正六角形を描くと、ふちの長さは直径のちょうど 3 倍。",
				"角の数を増やして正十二角形、正二十四角形…と近づけていくと、",
				"3 倍より少しだけ長い ― 3.14… に近づいていく。",
				"円周率は「円のふちが直径の何倍か」を表す数だった。",
			]},
			{"type": "solve", "title": "おうぎ形の計算", "stage": "e8", "tier": 1,
				"lead": "円周率を使って計算してみよう。", "after": "3.14 の計算にも慣れてきた。"},
			{"type": "talk", "title": "丸いものたち", "art": "wheel", "lines": [
				"車輪、皿、井戸のふち。丸いものはすべて同じ数にしたがっている。",
				"形が違っても、比が同じ ― 図形の世界では、それがよく起きるらしい。",
			]},
		],
	},
	{
		"id": "ch4", "title": "高さが同じなら", "level": "中学受験",
		"place": "麦畑のふち",
		"found": "底辺と高さが同じ三角形は、形がちがっても面積は同じ",
		"scenes": [
			{"type": "talk", "title": "分けられた畑", "art": "field", "lines": [
				"兄弟が三角形の畑を分けあうことになった。どちらも「大きいほうが欲しい」と言う。",
				"親方は畑の形を書き換えて、二人に見せた。まったく違う形の三角形だ。",
				"「どちらも同じ広さだ」と親方は言う。形が違うのに、同じ?",
				"頂点を動かしても広さが変わらないか、自分で確かめよう。",
			]},
			{"type": "measure", "title": "頂点を横に滑らせる", "fig": "equal_area", "trials": 3,
				"lead": "金色の点は左右にしか動かない(高さは変わらない)。"
					+ "形が変わるたびに、底辺・高さ・面積を記録しよう。",
				"question": "頂点を横に動かすと、面積はどうなった?",
				"choices": [
					"とがるほど面積は小さくなった",
					"横に長いほど面積は大きくなった",
					"形は変わったが、面積は変わらなかった",
				], "answer": 2, "invariant": {"value": 30.0, "tol": 0.3},
				"after": "底辺と高さが同じなら、面積は同じ。これを等積変形という。"},
			{"type": "talk", "title": "長方形の半分", "fig": "equal_area_proof", "lines": [
				"三角形を、同じ底辺と高さの長方形の中に入れてみる。",
				"頂点をどこへ動かしても、三角形は長方形のちょうど半分になっている。",
				"だから面積 = 底辺 × 高さ ÷ 2。頂点の位置は関係ない。",
				"「形を変えても面積は同じ」― この技は、複雑な図形を崩すときに効く。",
			]},
			{"type": "solve", "title": "三角形の面積", "stage": "e3", "tier": 1,
				"lead": "底辺と高さを見つけて計算しよう。", "after": "畑の分配は無事に終わった。"},
			{"type": "talk", "title": "中学受験の範囲を越えて", "art": "dusk", "lines": [
				"角の和、錯角、円周率、等積変形 ― 道具が 4 つそろった。",
				"親方が言う。「ここから先は、お前の代の仕事だ」",
				"まだ名前をつけていない決まりが、この先に待っている。",
			]},
		],
	},
	# ============ 高校受験レベル ============
	{
		"id": "ch5", "title": "直角の宝", "level": "高校受験",
		"place": "大工の作業場",
		"found": "直角三角形では a² + b² = c²(三平方の定理)",
		"scenes": [
			{"type": "talk", "title": "棟梁の縄", "art": "roof", "lines": [
				"大工の棟梁は、3・4・5 の長さに結び目をつけた縄で直角を作る。",
				"「なぜ 3・4・5 なんですか」と聞くと、棟梁は板に正方形を三つ描いた。",
				"辺の長さを一辺とする正方形。小さい二つと、大きい一つ。",
				"「この二つの面積をたすと、大きいほうになる。自分で測ってみろ」",
			]},
			{"type": "measure", "title": "二辺を変えてみる", "fig": "pythagoras", "trials": 3,
				"lead": "金色の点を動かすと、直角をはさむ 2 辺の長さが変わる。"
					+ "a²・b²・c² を記録しよう。",
				"question": "2 辺を変えると、a² + b² と c² の関係はどうなった?",
				"choices": [
					"いつも a² + b² = c² だった",
					"c² のほうがいつも大きかった",
					"辺が長いほど差が開いた",
				], "answer": 0, "invariant": {"value": 0.0, "tol": 0.05},
				"after": "a² + b² = c²。直角三角形にひそむ、いちばん有名な決まりだ。"},
			{"type": "talk", "title": "正方形で見る", "fig": "pythagoras_proof", "lines": [
				"斜辺を一辺とする正方形の中に、同じ直角三角形を 4 つ並べてみる。",
				"真ん中に残るのは、2 辺の差を一辺とする小さな正方形。",
				"面積を数えると、c² = a² + b² がそのまま出てくる。",
				"縄の 3・4・5 は、9 + 16 = 25 だったのだ。",
			]},
			{"type": "solve", "title": "斜辺の長さ", "stage": "j5", "tier": 1,
				"lead": "a² + b² = c² を使ってみよう。", "after": "直角は、計算で作れるようになった。"},
			{"type": "talk", "title": "道具が増えた", "art": "roof", "lines": [
				"長さが 2 つ分かれば、残りの 1 つが分かる。",
				"高さの分からない塔も、影と縄があれば測れそうだ。",
			]},
		],
	},
	{
		"id": "ch6", "title": "円周角のふしぎ", "level": "高校受験",
		"place": "円形の劇場",
		"found": "同じ弧を見る円周角は等しく、中心角のちょうど半分",
		"scenes": [
			{"type": "talk", "title": "どこから見ても", "art": "wheel", "lines": [
				"円形の劇場に来た。舞台の左右の端を、客席のどこからでも見わたせる。",
				"「どの席から見ても、舞台は同じ広さに見える」と案内人が言う。",
				"そんなことがあるだろうか。席を移して確かめてみよう。",
			]},
			{"type": "measure", "title": "席を移してみる", "fig": "inscribed", "trials": 3,
				"lead": "円の上の金色の点(あなたの席)を動かして、"
					+ "舞台の端を見こむ角と、中心から見た角を記録しよう。",
				"question": "席を動かすと、見こむ角(円周角)はどうなった?",
				"choices": [
					"中心に近い席ほど大きかった",
					"どこから見ても同じで、中心から見た角の半分だった",
					"端の席ほど小さくなった",
				], "answer": 1, "invariant": {"value": 0.0, "tol": 0.8},
				"after": "円周角はどこから見ても等しく、中心角の半分。"},
			{"type": "talk", "title": "半分になるわけ", "fig": "inscribed_proof", "lines": [
				"中心 O と自分の席 A を結ぶと、二等辺三角形ができる(どちらも半径だから)。",
				"二等辺三角形の底角は等しく、外角はその 2 つ分。",
				"だから中心角は円周角の 2 倍 ― 円周角は中心角の半分になる。",
				"直径を見こむ角なら、中心角 180° の半分で、いつでも 90° だ。",
			]},
			{"type": "solve", "title": "円周角を求める", "stage": "j3", "tier": 1,
				"lead": "中心角の半分を使ってみよう。", "after": "円の中の角が読めるようになった。"},
			{"type": "talk", "title": "円は角を運ぶ", "art": "wheel", "lines": [
				"円周上の点は、どこにあっても同じ角を保っている。",
				"位置が変わっても変わらないもの ― また一つ見つけた。",
			]},
		],
	},
	{
		"id": "ch7", "title": "大きくすると", "level": "高校受験",
		"place": "設計図の部屋",
		"found": "長さを k 倍に拡大すると、面積は k × k 倍になる",
		"scenes": [
			{"type": "talk", "title": "図面と実物", "art": "master", "lines": [
				"設計図の部屋。同じ形の図面が、大きさ違いで何枚も並んでいる。",
				"「長さを 2 倍にした図面は、布も 2 倍あれば足りますか」と聞いてみる。",
				"棟梁は首を振った。「それでは足りん。ずっと多く要る」",
				"どれだけ要るのか。拡大しながら面積を測ってみよう。",
			]},
			{"type": "measure", "title": "拡大してみる", "fig": "similar", "trials": 3,
				"lead": "金色の点を動かすと、相似比(何倍に拡大したか)が変わる。"
					+ "相似比と面積比を記録しよう。",
				"question": "長さを k 倍にすると、面積は何倍になった?",
				"choices": [
					"同じ k 倍",
					"k × k 倍(2 倍なら 4 倍)",
					"k の半分",
				], "answer": 1, "invariant": {"value": 1.0, "tol": 0.02},
				"after": "面積比は相似比の 2 乗。2 倍に拡大したら、布は 4 倍要る。"},
			{"type": "talk", "title": "たてもよこも", "fig": "similar_proof", "lines": [
				"長方形で考えると分かりやすい。たてを 2 倍、よこも 2 倍にする。",
				"面積は たて × よこ だから、2 × 2 = 4 倍。",
				"どんな形でも同じで、長さが k 倍なら面積は k × k 倍になる。",
				"(ついでに、体積なら k × k × k 倍だ)",
			]},
			{"type": "solve", "title": "相似と面積比", "stage": "j8", "tier": 1,
				"lead": "相似比の 2 乗を使ってみよう。", "after": "図面から必要な材料が読めるようになった。"},
			{"type": "talk", "title": "比でものを見る", "art": "master", "lines": [
				"長さの比、面積の比 ― 比で考えると、大きさに振り回されない。",
				"高校受験の範囲は、ここまでで一通り手に入った。",
			]},
		],
	},
	# ============ 大学受験レベル ============
	{
		"id": "ch8", "title": "外接円のひみつ", "level": "大学受験",
		"place": "天文台の観測室",
		"found": "三角形では a ÷ sin A が、外接円の直径 2R に等しい(正弦定理)",
		"scenes": [
			{"type": "talk", "title": "星の位置", "art": "night", "lines": [
				"天文台に来た。三つの星を結ぶと、いつも同じ円の上に乗るという。",
				"観測者が言う。「星を移しても、辺 ÷ sin(向かいの角) は変わらない」",
				"sin という新しい道具が出てきた。まずは、その値がどう動くか見てみよう。",
			]},
			{"type": "measure", "title": "頂点を円の上で動かす", "fig": "sine_law", "trials": 3,
				"lead": "円周上の金色の点を動かすと、∠A が変わる。"
					+ "a ÷ sin A と、円の直径 2R を記録しよう。",
				"question": "頂点を動かすと、a ÷ sin A はどうなった?",
				"choices": [
					"角が大きいほど大きくなった",
					"いつも外接円の直径 2R と同じだった",
					"ばらばらだった",
				], "answer": 1, "invariant": {"value": 0.0, "tol": 0.08},
				"after": "a ÷ sin A = 2R。これが正弦定理だ。"},
			{"type": "talk", "title": "直径で考える", "fig": "sine_law_proof", "lines": [
				"辺 BC の一端から直径を引くと、直径を見こむ角は 90°(第6章の結果)。",
				"その直角三角形で sin を考えると、a = 2R sin A がすぐに出る。",
				"円周角がどこでも等しいから、頂点をどこに置いても同じ式になる。",
			]},
			{"type": "solve", "title": "外接円の半径", "stage": "s2", "tier": 1,
				"lead": "正弦定理を使ってみよう。", "after": "円と三角形がつながった。"},
			{"type": "talk", "title": "角と長さの橋", "art": "night", "lines": [
				"sin は、角と長さをつなぐ橋だった。",
				"この橋を渡れば、面積にも手が届くかもしれない。",
			]},
		],
	},
	{
		"id": "ch9", "title": "はさむ角と面積", "level": "大学受験",
		"place": "測量の仕事場",
		"found": "2 辺とそのはさむ角で、面積 = ½ × a × b × sin C",
		"scenes": [
			{"type": "talk", "title": "三角形の土地", "art": "field", "lines": [
				"依頼が来た。「二辺の長さと、その間の角だけ分かっている土地の広さを出せ」",
				"高さは測れていない。底辺 × 高さ ÷ 2 が使えない。",
				"だが sin という橋がある。角を動かしながら、面積の変わり方を見てみよう。",
			]},
			{"type": "measure", "title": "はさむ角を変える", "fig": "area_sin", "trials": 3,
				"lead": "金色の点を動かすと、2 辺のはさむ角 C が変わる(辺の長さは変わらない)。"
					+ "角・sin C・面積を記録しよう。",
				"question": "面積 ÷ sin C はどうなった?",
				"choices": [
					"角が大きいほど大きくなった",
					"いつも同じ数(= ½ × a × b)だった",
					"90° のときだけ特別な値になった",
				], "answer": 1, "invariant": {"value": 24.0, "tol": 0.2},
				"after": "面積 = ½ × a × b × sin C。高さを測らなくても面積が出る。"},
			{"type": "talk", "title": "高さの正体", "fig": "area_sin_proof", "lines": [
				"辺 b の先から底辺へ垂線を下ろすと、その高さは b × sin C。",
				"だから 面積 = 底辺 × 高さ ÷ 2 = a × b × sin C ÷ 2。",
				"sin は「高さの割合」を教えてくれる数だった。",
			]},
			{"type": "solve", "title": "三角比の面積公式", "stage": "s3", "tier": 1,
				"lead": "½ × a × b × sin C を使ってみよう。", "after": "測れない土地も、計算で測れた。"},
			{"type": "talk", "title": "曲がった線へ", "art": "night", "lines": [
				"まっすぐな辺で囲まれた図形は、これでほぼ手中に入った。",
				"残るは曲線。円は分かった。では、放物線が囲む面積は?",
			]},
		],
	},
	{
		"id": "ch10", "title": "放物線が囲む", "level": "大学受験",
		"place": "近代、噴水のほとり",
		"found": "放物線と直線が囲む面積は (交点の差)³ ÷ 6(6分の1公式)",
		"scenes": [
			{"type": "talk", "title": "噴水の水", "art": "dusk", "lines": [
				"噴水の水が描く曲線は放物線。水面で切り取られた部分の面積を出したい。",
				"曲線で囲まれた形に、底辺 × 高さ ÷ 2 は使えない。",
				"だが交点の間隔を変えていくと、面積の変わり方に規則があるという。",
			]},
			{"type": "measure", "title": "水面の高さを変える", "fig": "parabola", "trials": 3,
				"lead": "金色の点を上下に動かすと、水面(直線)の高さが変わる。"
					+ "交点の差と、囲まれた面積を記録しよう。",
				"question": "面積 ÷ (交点の差 × 3 回かけたもの) はどうなった?",
				"choices": [
					"高いほど大きくなった",
					"いつも 0.167(= 6 分の 1)くらいだった",
					"高さと関係なくばらばらだった",
				], "answer": 1, "invariant": {"value": 0.16667, "tol": 0.004},
				"after": "面積 = (交点の差)³ ÷ 6。放物線と直線なら、いつでもこれで出る。"},
			{"type": "talk", "title": "6 分の 1 公式", "fig": "parabola_proof", "lines": [
				"放物線 y = ax² と直線が α と β で交わるとき、囲む面積は",
				"|a| × (β − α)³ ÷ 6 になる。積分すればそのまま出てくる形だ。",
				"入試ではこの形がくり返し出る。覚えておくと計算が一気に短くなる。",
			]},
			{"type": "solve", "title": "放物線と直線", "stage": "s8", "tier": 1,
				"lead": "6 分の 1 公式を使ってみよう。", "after": "曲線の面積にも手が届いた。"},
			{"type": "talk", "title": "図形をあばく者", "art": "night", "lines": [
				"角の和、錯角、円周率、等積変形、三平方、円周角、相似比、正弦定理、",
				"sin の面積、6 分の 1 公式 ― 10 の決まりが手の中にある。",
				"どれも「動かしても変わらないもの」だった。",
				"図形ハンターの旅は、ここから本編へ続く。",
			]},
		],
	},
]


static func chapter_by_id(id: String) -> Dictionary:
	for c in CHAPTERS:
		if String(c["id"]) == id:
			return c
	return CHAPTERS[0]


static func chapter_index(id: String) -> int:
	for i in CHAPTERS.size():
		if String(CHAPTERS[i]["id"]) == id:
			return i
	return 0


## その章を開いてよいか(前の章をクリアしていれば開く)
static func is_unlocked(id: String, cleared: Dictionary) -> bool:
	var i := chapter_index(id)
	if i <= 0:
		return true
	return cleared.has(String(CHAPTERS[i - 1]["id"]))


# =========================================================
# 動かす図。種類ごとに 初期位置 / 動ける範囲 / 読み取り を持つ
# (図そのものは story_figs.gd)
# =========================================================

const TRI_B := Vector2(0.0, 0.0)     # 三角形の左下
const TRI_C := Vector2(10.0, 0.0)    # 三角形の右下
const R_CIRCLE := 6.0                # 円周角・正弦定理で使う円の半径
const SIDE_A := 8.0                  # ch9 の辺 a
const SIDE_B := 6.0                  # ch9 の辺 b


static func start_of(kind: String) -> Vector2:
	match kind:
		"triangle":
			return Vector2(4.0, 6.0)
		"parallel_lines":
			return Vector2(8.0, 6.0)
		"circle":
			return Vector2(5.0, 0.0)
		"equal_area":
			return Vector2(4.0, 6.0)
		"pythagoras":
			return Vector2(6.0, 4.5)
		"inscribed", "sine_law":
			return Vector2(0.0, R_CIRCLE)
		"similar":
			return Vector2(1.6, 0.0)
		"area_sin":
			return Vector2(0.0, SIDE_B)
		"parabola":
			return Vector2(0.0, 4.0)
	return Vector2.ZERO


## 動かせる範囲に収める(つぶれた図やはみ出しを作らない)
static func clamp_of(kind: String, p: Vector2) -> Vector2:
	match kind:
		"triangle":
			return Vector2(clampf(p.x, -4.0, 14.0), clampf(p.y, 2.0, 9.0))
		"parallel_lines":
			return Vector2(clampf(p.x, 4.0, 12.0), 6.0)
		"circle":
			return Vector2(clampf(p.x, 2.0, 8.0), 0.0)
		"equal_area":
			return Vector2(clampf(p.x, -4.0, 14.0), 6.0)
		"pythagoras":
			return Vector2(clampf(p.x, 3.0, 9.0), clampf(p.y, 3.0, 8.0))
		"inscribed", "sine_law":
			# 円の上だけを動く(舞台のある下側の弧には行かせない)
			var a := clampf(atan2(p.y, p.x), deg_to_rad(25.0), deg_to_rad(155.0))
			return Vector2(cos(a), sin(a)) * R_CIRCLE
		"similar":
			return Vector2(clampf(p.x, 1.2, 2.6), 0.0)
		"area_sin":
			# 中心から距離 b の円の上(はさむ角だけが変わる)
			var t := clampf(atan2(p.y, p.x), deg_to_rad(20.0), deg_to_rad(160.0))
			return Vector2(cos(t), sin(t)) * SIDE_B
		"parabola":
			return Vector2(0.0, clampf(p.y, 1.0, 9.0))
	return p


## 記録する値。row = 表に出す 1 行 / value = 一定かどうかを見る量
static func readout_of(kind: String, p: Vector2) -> Dictionary:
	match kind:
		"triangle":
			var d: Array = rounded_angles(angles_of(p, TRI_B, TRI_C))
			var sum := int(d[0]) + int(d[1]) + int(d[2])
			return {"row": "∠A %d°  ∠B %d°  ∠C %d°  → 合計 %d°" % [
				int(d[0]), int(d[1]), int(d[2]), sum], "value": float(sum)}
		"parallel_lines":
			var th := roundi(rad_to_deg(atan2(6.0, p.x - 2.0)))
			return {"row": "下の角 %d°  上の角 %d°  → 差 0°" % [th, th], "value": 0.0}
		"circle":
			var r: float = p.x
			return {"row": "直径 %.1f  円周 %.2f  → 円周÷直径 %.3f" % [
				2.0 * r, TAU * r, (TAU * r) / (2.0 * r)], "value": (TAU * r) / (2.0 * r)}
		"equal_area":
			var area := 10.0 * 6.0 * 0.5
			return {"row": "底辺 10  高さ 6  → 面積 %.1f" % area, "value": area}
		"pythagoras":
			var a2: float = p.x * p.x
			var b2: float = p.y * p.y
			return {"row": "a² %.1f ＋ b² %.1f ＝ %.1f   c² %.1f" % [
				a2, b2, a2 + b2, a2 + b2], "value": 0.0}
		"inscribed":
			var deg := inscribed_angles(p)
			return {"row": "円周角 %d°  中心角 %d°  → 中心角 − 円周角×2 = %d°" % [
				roundi(deg[0]), roundi(deg[1]), roundi(deg[1] - 2.0 * deg[0])],
				"value": deg[1] - 2.0 * deg[0]}
		"sine_law":
			var deg2 := inscribed_angles(p)
			var a_side := chord_len()
			var s := a_side / maxf(sin(deg_to_rad(deg2[0])), 0.0001)
			return {"row": "∠A %d°  a %.2f  → a÷sin A %.2f   2R %.2f" % [
				roundi(deg2[0]), a_side, s, 2.0 * R_CIRCLE], "value": s - 2.0 * R_CIRCLE}
		"similar":
			var k: float = p.x
			return {"row": "相似比 %.2f  面積比 %.2f  → 面積比÷(相似比×相似比) %.2f" % [
				k, k * k, 1.0], "value": 1.0}
		"area_sin":
			var t := atan2(p.y, p.x)
			var area2 := 0.5 * SIDE_A * SIDE_B * sin(t)
			return {"row": "∠C %d°  sin C %.3f  面積 %.2f  → 面積÷sin C %.2f" % [
				roundi(rad_to_deg(t)), sin(t), area2, area2 / maxf(sin(t), 0.0001)],
				"value": area2 / maxf(sin(t), 0.0001)}
		"parabola":
			var k2: float = p.y
			var w := 2.0 * sqrt(k2)
			var s2 := w * w * w / 6.0
			return {"row": "交点の差 %.2f  面積 %.2f  → 面積÷(差×差×差) %.3f" % [
				w, s2, s2 / pow(w, 3.0)], "value": s2 / pow(w, 3.0)}
	return {"row": "", "value": 0.0}


# =========================================================
# 角度と長さの計算
# =========================================================

## 三角形の 3 つの角(度)を座標から計算する [∠A, ∠B, ∠C]
static func angles_of(a: Vector2, b: Vector2, c: Vector2) -> Array:
	var f := func(at: Vector2, p: Vector2, q: Vector2) -> float:
		var d1 := (p - at).normalized()
		var d2 := (q - at).normalized()
		return rad_to_deg(acos(clampf(d1.dot(d2), -1.0, 1.0)))
	return [f.call(a, b, c), f.call(b, a, c), f.call(c, a, b)]


## 3 つの角を整数に丸める。**丸めても和が 180 になるように**誤差を分配する。
## そのまま四捨五入すると 40 + 12 + 129 = 181 のように見えて、
## 「和は 180」という発見そのものが濁ってしまうため
static func rounded_angles(deg: Array) -> Array:
	var base: Array = []
	var rest: Array = []
	var total := 0
	for i in 3:
		var f := floori(float(deg[i]))
		base.append(f)
		rest.append([float(deg[i]) - float(f), i])
		total += f
	rest.sort_custom(func(x, y): return float(x[0]) > float(y[0]))
	var lack := clampi(180 - total, 0, 3)
	for k in lack:
		base[int(rest[k][1])] += 1
	return base


## 円周角の図で使う、舞台の両端(弦の端)
static func chord_ends() -> Array:
	return [Vector2(cos(deg_to_rad(200.0)), sin(deg_to_rad(200.0))) * R_CIRCLE,
		Vector2(cos(deg_to_rad(340.0)), sin(deg_to_rad(340.0))) * R_CIRCLE]


static func chord_len() -> float:
	var e := chord_ends()
	return (e[0] as Vector2).distance_to(e[1])


## [円周角, 中心角] を返す。中心角は舞台のある側(下側)の角
static func inscribed_angles(a: Vector2) -> Array:
	var e := chord_ends()
	var p: Vector2 = e[0]
	var q: Vector2 = e[1]
	var insc := rad_to_deg(acos(clampf(
		(p - a).normalized().dot((q - a).normalized()), -1.0, 1.0)))
	var cen := rad_to_deg(acos(clampf(
		p.normalized().dot(q.normalized()), -1.0, 1.0)))
	return [insc, cen]
