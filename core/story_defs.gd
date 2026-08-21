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
##   solve   … 見つけたことを使う「依頼」を 1 つ解く(3択)。
##             本編の問題をそのまま出すと同じ画面になってしまうので、
##             章の文脈で書き直したものを core/story_tasks.gd に持つ
##
## 章は 中学受験 → 高校受験 → 大学受験 の順。前の章をクリアすると次が開く。
##
## 章を足すときは CHAPTERS に足し、動かす図が新しければ
## start_of / clamp_of / spec_of / readout_of の 4 つに種類を足す。

## ■ 通しの筋
## 主人公は測量師トトの見習い。行く先々に「渡りの学者」カラスが先回りしていて、
## 公式を高く売りつけている。カラスの言うことは**正しいこともあれば、嘘もある**。
## トトは答えを教えない。「測れ」としか言わない。
## プレイヤーは自分で図を動かし、カラスの主張が本当かどうかを確かめていく。
## (丸暗記できない ― という本編の思想を、そのまま物語の対立にしている)
##
## 各章のかたち: 困っている依頼人 → カラスの断言 → 自分で測って確かめる →
## トトが補助線を一本引いて理由を見せる → 依頼が片づく → 次の町への引き

const CHAPTERS := [
	# ============ 中学受験レベル ============
	{
		"id": "ch1", "title": "三角形の秘密", "level": "中学受験",
		"place": "ギリシャ、麦の畑",
		"found": "三角形の内角の和は、形を変えても 180°",
		"scenes": [
			{"type": "talk", "title": "読めない石碑", "art": "field", "lines": [
				"三角形の畑の境で、農夫が困っていた。角の目印の石碑が倒れ、数字が欠けている。",
				"「二つの角は読める。50 度と 60 度。残りひとつが分からん」",
				"そこへ黒い外套の男が割り込んだ。渡りの学者を名乗る、カラス。",
				"「角の和は形で変わる。とがった畑なら小さい。教えてやろう ― 銀貨一枚で」",
				"親方のトトは何も言わず、砂に三角形を描いて棒を渡してきた。測れ、ということだ。",
			]},
			{"type": "measure", "title": "頂点を動かしてみる", "fig": "triangle", "trials": 3,
				"lead": "三角形の上の頂点(金色の点)を指で動かすと、3 つの角が変わる。"
					+ "とがった形、平べったい形 ― いくつか作って記録し、カラスの言い分を確かめよう。",
				"question": "頂点を動かすと、3 つの角の和はどうなった?",
				"choices": [
					"カラスの言うとおり、とがった形ほど和は小さかった",
					"どんな形にしても、和は 180° のままだった",
					"大きい三角形ほど和は大きかった",
				], "answer": 1, "invariant": {"value": 180.0, "tol": 0.6},
				"after": "カラスは嘘をついていた。和はいつも 180°。残りの角は 180 − 50 − 60 = 70 度だ。"},
			{"type": "talk", "title": "トトの一本", "fig": "parallel_proof", "lines": [
				"「なぜ 180 なんですか」― 初めて聞いた問いに、トトは砂へ棒を下ろした。",
				"頂点を通って、底辺と平行な線を一本。それだけ。",
				"左の角が ∠B と重なり、右の角が ∠C と重なる。三つの角が一直線に並んだ。",
				"一直線は 180°。トトは棒を置いて、また黙って歩き出した。",
			]},
			{"type": "solve", "title": "石碑の角を埋める", "fig": "triangle",
				"lead": "農夫の畑の角を出してやろう。", "after": "農夫は境の杭を打ち直した。"},
			{"type": "talk", "title": "銀貨は渡らない", "art": "dusk", "lines": [
				"カラスは銀貨を受け取れなかった。去りぎわ、こちらを振り返って笑う。",
				"「今のは外れだ。だが次の町では、俺の言うことが正しいぞ」",
				"どれが本当でどれが嘘か ― 自分で測るしか、見分ける方法はない。",
				"トトが北を指した。次の仕事は、二本の壁にはさまれた倉庫街だ。",
			]},
		],
	},
	{
		"id": "ch2", "title": "壁ぎわの曲がり角", "level": "中学受験",
		"place": "エジプト、倉庫街の細道",
		"found": "平行な壁の間で折れた角は、上の角と下の角の和になる",
		"scenes": [
			{"type": "talk", "title": "梁が入らない", "art": "field", "lines": [
				"倉庫街。平行な壁のあいだの細道は、柱があって真っすぐには通れない。",
				"荷を担いで一度だけ折れて進む ― その折れ角に合わせて梁を切る必要がある。",
				"大工が言う。「上と下の角なら測れる。だが折れるところは足場が無くて登れん」",
				"先回りしていたカラスが胸を張った。「折れ角は 180 から上下を引いた値だ。常識だな」",
				"トトは壁を指でなぞって、ここで曲がってみろ、という顔をした。",
			]},
			{"type": "measure", "title": "曲がる場所を変える", "fig": "zigzag", "trials": 3,
				"lead": "金色の点(曲がり角)を動かすと、上の角・下の角・折れ角の 3 つとも変わる。"
					+ "場所をいくつか変えて記録し、3 つの数を見くらべよう。",
				"question": "折れ角は、上の角と下の角とどんな関係だった?",
				"choices": [
					"いつも 上の角 + 下の角 になっていた",
					"カラスの言うとおり 180° から 2 つを引いた値だった",
					"どれとも関係がなかった",
				], "answer": 0, "invariant": {"value": 0.0, "tol": 0.8},
				"after": "折れ角 = 上の角 + 下の角。カラスの「常識」はまた外れだ。"},
			{"type": "talk", "title": "無い線を引く", "fig": "zigzag_proof", "lines": [
				"トトが曲がり角を通って、壁と平行な線を引いた。図には無かった線だ。",
				"折れ角が上下に分かれる。上側は上の角と、下側は下の角と、はす向かいで等しい。",
				"だから 折れ角 = 上 + 下。梁の角度は、登らなくても出せる。",
				"「図に無い線を、引いてよかったんですね」― トトは初めて、少しだけ笑った。",
			]},
			{"type": "solve", "title": "梁の角を伝える", "fig": "zigzag",
				"lead": "折れ線の角を出そう。", "after": "梁はぴたりと収まった。"},
			{"type": "talk", "title": "二勝", "art": "dusk", "lines": [
				"カラスは二度外した。それでも去るとき、なぜか機嫌がよかった。",
				"「よく測る見習いだ。だが次の町のものは、巻いてみないと分からんぞ」",
				"次の町は車輪の工房。丸いものばかりだという。",
			]},
		],
	},
	{
		"id": "ch3", "title": "円のふしぎ", "level": "中学受験",
		"place": "バビロニア、車輪の工房",
		"found": "円周 ÷ 直径 は、どんな大きさの円でも 3.14…(円周率)",
		"scenes": [
			{"type": "talk", "title": "縄を先に切りたい", "art": "wheel", "lines": [
				"車輪の工房。親方が大小の車輪にはめる鉄の輪を、先に切っておきたいという。",
				"「車輪のさしわたし(直径)なら測れる。だが、ふちの長さは巻いてみないと分からん」",
				"カラスが割り込む。「大きい車輪ほど、ふちは直径の何倍にもなる。倍率の表を売ろう」",
				"トトが巻き尺を投げてよこした。大きさを変えて、自分で巻いてみろということらしい。",
			]},
			{"type": "measure", "title": "大きさを変えて測る", "fig": "circle", "trials": 3,
				"lead": "金色の点を左右に動かすと、円の大きさが変わる。"
					+ "直径と、巻き尺で測った円周を記録しよう。",
				"question": "円の大きさを変えると、円周 ÷ 直径 はどうなった?",
				"choices": [
					"カラスの言うとおり、大きい円ほど倍率も大きかった",
					"どんな大きさでも 3.14 くらいで変わらなかった",
					"小さい円ほど大きかった",
				], "answer": 1, "invariant": {"value": 3.1416, "tol": 0.01},
				"after": "いつも 3.14…。この数があれば、直径だけで鉄の輪を切れる。"},
			{"type": "talk", "title": "六角形から", "fig": "circle_proof", "lines": [
				"円の中に正六角形を描くと、ふちの長さは直径のちょうど 3 倍。",
				"角を増やして十二角、二十四角 ― 円に近づくほど 3.14… に寄っていく。",
				"「3 倍と、ほんの少し」。その少しに、人が千年かけて名前をつけた。円周率だ。",
			]},
			{"type": "solve", "title": "鉄の輪を切る", "fig": "circle",
				"lead": "円周率を使って計算しよう。", "after": "輪は一発で車輪にはまった。"},
			{"type": "talk", "title": "売り物が減る", "art": "wheel", "lines": [
				"表を売れなくなったカラスは、それでも上機嫌で言った。",
				"「一つ覚えれば全部の円に効く ― そういう数は高く売れるんだ。覚えておけ」",
				"言われてみれば、こちらも同じものを手に入れている。売り物ではなく、道具として。",
			]},
		],
	},
	{
		"id": "ch4", "title": "高さが同じなら", "level": "中学受験",
		"place": "麦畑のふち",
		"found": "底辺と高さが同じ三角形は、形がちがっても面積は同じ",
		"scenes": [
			{"type": "talk", "title": "兄弟げんか", "art": "field", "lines": [
				"三角形の畑を、兄弟で分けることになった。どちらも「細長いほうが損だ」と譲らない。",
				"カラスが即座に値をつけた。「とがった土地は狭い。差額を払わせればいい」",
				"トトは杭を一本抜いて、頂点だけを横へずらした。形はまるで変わる。",
				"だが広さは? ― 二人が見ている前で、確かめることになった。",
			]},
			{"type": "measure", "title": "頂点を横に滑らせる", "fig": "equal_area", "trials": 3,
				"lead": "金色の点は左右にしか動かない(高さは変わらない)。"
					+ "形が変わるたびに、辺の長さと面積を記録しよう。",
				"question": "頂点を横に動かすと、面積はどうなった?",
				"choices": [
					"カラスの言うとおり、とがるほど狭くなった",
					"横に長いほど広かった",
					"形は変わったが、面積は変わらなかった",
				], "answer": 2, "invariant": {"value": 30.0, "tol": 0.3},
				"after": "辺の長さは変わるのに、面積は動かない。差額を払う理由は無い。"},
			{"type": "talk", "title": "長方形の半分", "fig": "equal_area_proof", "lines": [
				"同じ底辺と高さの長方形の中に、三角形を入れてみる。",
				"頂点をどこへ滑らせても、三角形は長方形のちょうど半分のまま。",
				"面積 = 底辺 × 高さ ÷ 2。頂点の位置は、はじめから関係なかった。",
				"トトが言った。この日ふたつ目の言葉だ。「形は、崩していい」",
			]},
			{"type": "solve", "title": "畑の広さを出す", "fig": "equal_area",
				"lead": "底辺と高さを見つけて計算しよう。", "after": "兄弟は納得して握手した。"},
			{"type": "talk", "title": "四つの道具", "art": "dusk", "lines": [
				"角の和、折れ角、円周率、そして崩してよい形 ― 四つ手に入れた。",
				"カラスが手をひらひらさせて背を向ける。「子どもの町はここまでだ」",
				"「次からは大人の現場だぞ。柱が立ち、船が出る」",
			]},
		],
	},
	# ============ 高校受験レベル ============
	{
		"id": "ch5", "title": "直角の宝", "level": "高校受験",
		"place": "大工の作業場",
		"found": "直角三角形では a² + b² = c²(三平方の定理)",
		"scenes": [
			{"type": "talk", "title": "直角の出し方", "art": "roof", "lines": [
				"新しい家の土台。直角が出せないと、柱も屋根も歪む。",
				"棟梁の道具は、結び目のついた縄が一本きり。3・4・5 のところに印がある。",
				"カラスが横から言う。「その縄が特別なのさ。ほかの長さでは直角にならん」",
				"棟梁は答えず、板に正方形を三つ描いた。二辺の正方形と、斜辺の正方形。",
			]},
			{"type": "measure", "title": "二辺を変えてみる", "fig": "pythagoras", "trials": 3,
				"lead": "金色の点を動かすと、直角をはさむ 2 辺の長さが変わる。"
					+ "a²・b² と、斜辺を測って出した c² を記録しよう。",
				"question": "2 辺を変えると、a² + b² と c² の関係はどうなった?",
				"choices": [
					"いつも a² + b² = c² だった",
					"カラスの言うとおり 3・4・5 のときだけ合った",
					"辺が長いほど差が開いた",
				], "answer": 0, "invariant": {"value": 0.0, "tol": 0.05},
				"after": "どの長さでも成り立つ。3・4・5 は 9 + 16 = 25 の一例にすぎない。"},
			{"type": "talk", "title": "正方形を数える", "fig": "pythagoras_proof", "lines": [
				"斜辺の正方形の中に、同じ直角三角形を四つ並べる。真ん中に小さな正方形が残る。",
				"面積を数えると、c² = a² + b² がそのまま出てくる。",
				"棟梁が縄を巻きながら言った。「印の無い縄でも、これで直角は出せるな」",
			]},
			{"type": "solve", "title": "斜辺を出す", "fig": "pythagoras",
				"lead": "a² + b² = c² を使おう。", "after": "土台に墨が引かれた。"},
			{"type": "talk", "title": "測れない高さ", "art": "roof", "lines": [
				"二辺が分かれば残りが出る ― 塔の高さも、影と縄で届きそうだ。",
				"カラスはこの町では何も売らず、ただ図面を覗き込んでいた。",
				"「次は劇場だ。あそこの席売りは、俺の得意分野でな」",
			]},
		],
	},
	{
		"id": "ch6", "title": "円周角のふしぎ", "level": "高校受験",
		"place": "円形の劇場",
		"found": "同じ弧を見る円周角は等しく、中心角のちょうど半分",
		"scenes": [
			{"type": "talk", "title": "特等席の値段", "art": "theater", "lines": [
				"円形の劇場。開場前の客席に、カラスが立っていた。今日は興行主の側らしい。",
				"「舞台がいちばん広く見えるのは中央の席だ。ここだけ倍の値で売る」",
				"券を買った客が「端の席は損だ」と騒いでいる。本当に損なのか。",
				"トトは分度器を渡してよこした。席を移りながら、舞台の端から端を見こむ角を測れ。",
			]},
			{"type": "measure", "title": "席を移してみる", "fig": "inscribed", "trials": 3,
				"lead": "円の上の金色の点(あなたの席)を動かして、"
					+ "席の位置・見こむ角(円周角)・中心から見た角を記録しよう。",
				"question": "席を動かすと、見こむ角はどうなった?",
				"choices": [
					"カラスの言うとおり、中央の席ほど大きかった",
					"どこから見ても同じで、中心から見た角の半分だった",
					"端の席ほど小さかった",
				], "answer": 1, "invariant": {"value": 0.0, "tol": 0.8},
				"after": "席の位置は変わっても、見こむ角は変わらない。特等席の根拠は消えた。"},
			{"type": "talk", "title": "半分になるわけ", "fig": "inscribed_proof", "lines": [
				"中心と自分の席を結ぶと、半径が二本 ― 二等辺三角形が二つできる。",
				"二等辺三角形の外角は、底角二つ分。だから中心角は円周角の二倍になる。",
				"直径を見こむ席なら、中心角 180° の半分でいつでも 90°。",
				"「端の客に、差額を返してやってくれ」と言うと、カラスは肩をすくめた。",
			]},
			{"type": "solve", "title": "円の中の角", "fig": "inscribed",
				"lead": "中心角の半分を使おう。", "after": "券は同じ値段になった。"},
			{"type": "talk", "title": "カラスの言い分", "art": "theater", "lines": [
				"「なぜ嘘を売る」と聞くと、カラスは初めて真顔になった。",
				"「嘘じゃない。誰も確かめないから、値がつくんだ」",
				"確かめる者がいる限り、その商売は成り立たない ― そういうことらしい。",
			]},
		],
	},
	{
		"id": "ch7", "title": "大きくすると", "level": "高校受験",
		"place": "船の帆をつくる仕事場",
		"found": "長さを k 倍に拡大すると、面積は k × k 倍になる",
		"scenes": [
			{"type": "talk", "title": "布が足りない", "art": "master", "lines": [
				"船主が帆を大きくしたいと言う。「長さを二倍にしてくれ。布も二倍あればいいな」",
				"仕立て屋がうなずきかけたところで、トトが手を止めさせた。",
				"カラスは涼しい顔だ。「二倍は二倍だろう。俺なら二倍で請ける ― 追加は別料金でな」",
				"帆を拡大しながら、必要な布を自分で測ってみよう。",
			]},
			{"type": "measure", "title": "拡大してみる", "fig": "similar", "trials": 3,
				"lead": "金色の点を動かすと、相似比(何倍に拡大したか)が変わる。"
					+ "小さい帆と大きい帆の面積を記録しよう。",
				"question": "長さを k 倍にすると、面積は何倍になった?",
				"choices": [
					"カラスの言うとおり、同じ k 倍",
					"k × k 倍(2 倍なら 4 倍)",
					"k の半分",
				], "answer": 1, "invariant": {"value": 1.0, "tol": 0.02},
				"after": "二倍の帆には、四倍の布が要る。二倍で請けたら大損だった。"},
			{"type": "talk", "title": "たてもよこも", "fig": "similar_proof", "lines": [
				"長方形で考えれば早い。たてが二倍、よこも二倍。面積は 2 × 2 = 4 倍。",
				"どんな形でも同じで、長さが k 倍なら面積は k × k 倍。",
				"「体積なら k × k × k だ」とトト。三つ目の言葉だった。",
			]},
			{"type": "solve", "title": "布の見積り", "fig": "similar",
				"lead": "相似比の 2 乗を使おう。", "after": "帆はぴたりと張られ、船は出た。"},
			{"type": "talk", "title": "海の向こうへ", "art": "master", "lines": [
				"出港を見送りながら、カラスがぽつりと言った。",
				"「俺が売っていた表は、あの船の行き先じゃ通じない。星の見え方が違うんだ」",
				"星の位置で船が向きを知る、という話をあなたは初めて聞いた。",
			]},
		],
	},
	# ============ 大学受験レベル ============
	{
		"id": "ch8", "title": "外接円のひみつ", "level": "大学受験",
		"place": "天文台の観測室",
		"found": "三角形では a ÷ sin A が、外接円の直径 2R に等しい(正弦定理)",
		"scenes": [
			{"type": "talk", "title": "星をつなぐ円", "art": "night", "lines": [
				"天文台。三つの星を結んだ三角形から、その外側を通る円の大きさを出したいという。",
				"観測官が言う。「辺の長さと、向かいの角なら測れる。だが円は空に描けない」",
				"カラスは今度は買う側だった。「その手の式なら、俺も高く買うぞ」",
				"sin という新しい道具を渡された。まず、その値がどう動くか見てみよう。",
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
				"after": "a ÷ sin A = 2R。空に描けない円の大きさが、地上の測定から出た。"},
			{"type": "talk", "title": "直径で考える", "fig": "sine_law_proof", "lines": [
				"辺の端から直径を引くと、直径を見こむ角は 90°(劇場で確かめたとおりだ)。",
				"その直角三角形で sin を使えば、a = 2R sin A がすぐ出る。",
				"円周角はどこでも等しいから、頂点を動かしても同じ式のまま。",
			]},
			{"type": "solve", "title": "外接円の半径", "fig": "sine_law",
				"lead": "正弦定理を使おう。", "after": "星図に、正しい縮尺が入った。"},
			{"type": "talk", "title": "橋がかかる", "art": "night", "lines": [
				"sin は、角と長さをつなぐ橋だった。",
				"カラスが観測台の手すりに寄りかかって言う。「面積にも橋は架かるぞ」",
				"また売りつける気だ ― と思ったが、その顔は少し違って見えた。",
			]},
		],
	},
	{
		"id": "ch9", "title": "はさむ角と面積", "level": "大学受験",
		"place": "崖の上の測量",
		"found": "2 辺とそのはさむ角で、面積 = ½ × a × b × sin C",
		"scenes": [
			{"type": "talk", "title": "高さが測れない", "art": "field", "lines": [
				"崖の上の三角形の土地。二辺の長さと、そのはさむ角までは測れた。",
				"だが高さを測ろうにも、垂線を下ろす先が崖の外だ。底辺 × 高さ ÷ 2 が使えない。",
				"カラスが言った。「無理だ。高さの無い土地は測れん ― 誰にもな」",
				"はさむ角を変えながら、面積がどう動くかを見てみよう。",
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
				"after": "面積 = ½ × a × b × sin C。高さを測らずに、面積が出た。"},
			{"type": "talk", "title": "高さの正体", "fig": "area_sin_proof", "lines": [
				"辺の先から垂線を下ろすと、その高さは b × sin C。測れなくても、計算で出せる。",
				"だから 面積 = a × b × sin C ÷ 2。sin は「高さの割合」だった。",
				"カラスは黙って崖の下を見ていた。「測れんと言ったのは、俺の負けだ」",
			]},
			{"type": "solve", "title": "崖の上の土地", "fig": "area_sin",
				"lead": "½ × a × b × sin C を使おう。", "after": "土地の登記が通った。"},
			{"type": "talk", "title": "最後の依頼", "art": "night", "lines": [
				"まっすぐな辺で囲まれた形は、これでほぼ手中にある。",
				"残るは曲線。カラスが一枚の図面を差し出した。噴水の設計図だ。",
				"「これは俺にも解けなかった。おまえがやってみろ」― 初めての、売りつけでない話。",
			]},
		],
	},
	{
		"id": "ch10", "title": "放物線が囲む", "level": "大学受験",
		"place": "近代、噴水のほとり",
		"found": "放物線と直線が囲む面積は (交点の差)³ ÷ 6(6分の1公式)",
		"scenes": [
			{"type": "talk", "title": "水が描く線", "art": "fountain", "lines": [
				"噴水の水が描くのは放物線。水面で切り取られた部分に、石を敷きつめたい。",
				"曲線で囲まれた形に、底辺 × 高さ ÷ 2 は使えない。石の数が読めない。",
				"カラスが図面の端を指した。「水面の高さを変えると、面積の増え方が妙なんだ」",
				"妙、で終わらせない方法をあなたはもう知っている。動かして、記録する。",
			]},
			{"type": "measure", "title": "水面の高さを変える", "fig": "parabola", "trials": 3,
				"lead": "金色の点を上下に動かすと、水面(直線)の高さが変わる。"
					+ "交点の差と、囲まれた面積を記録しよう。",
				"question": "面積 ÷ (交点の差 を 3 回かけたもの) はどうなった?",
				"choices": [
					"高いほど大きくなった",
					"いつも 0.167(= 6 分の 1)くらいだった",
					"高さと関係なくばらばらだった",
				], "answer": 1, "invariant": {"value": 0.16667, "tol": 0.004},
				"after": "面積 = (交点の差)³ ÷ 6。曲線で囲まれた形が、掛け算だけで出た。"},
			{"type": "talk", "title": "6 分の 1 公式", "fig": "parabola_proof", "lines": [
				"放物線と直線が α と β で交わるとき、囲む面積は (β − α)³ ÷ 6。",
				"カラスが図面を丸めながら言った。「この式なら、俺も売らずに使う」",
				"「なぜです」と聞くと、答えはこうだった。",
				"「確かめた者にしか、この式は効かんからだ。おまえは確かめただろう」",
			]},
			{"type": "solve", "title": "石を敷く", "fig": "parabola",
				"lead": "6 分の 1 公式を使おう。", "after": "噴水のまわりに、石が過不足なく並んだ。"},
			{"type": "talk", "title": "図形ハンター", "art": "fountain", "lines": [
				"角の和、折れ角、円周率、崩してよい形、三平方、円周角、相似比、",
				"正弦定理、sin の面積、6 分の 1 公式 ― 十の決まりが手の中にある。",
				"どれも人から買ったものではない。全部、自分で動かして見つけた。",
				"トトが初めて、まとまった言葉をくれた。「これで、お前も測れる者だ」",
				"カラスの姿はもう無い。旅はここから、本編の 41 ステージへ続く。",
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
		"zigzag":
			return Vector2(1.0, 4.0)
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
		"zigzag":
			return Vector2(clampf(p.x, -5.0, 6.0), clampf(p.y, 1.5, 6.5))
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
		"zigzag":
			var z := zigzag_angles(p)
			return {"row": "上の角 %d°  下の角 %d°  折れ角 %d°  → 上+下 %d°" % [
				roundi(z[0]), roundi(z[1]), roundi(z[2]), roundi(z[0] + z[1])],
				"value": z[2] - (z[0] + z[1])}
		"circle":
			var r: float = p.x
			return {"row": "直径 %.1f  円周 %.2f  → 円周÷直径 %.3f" % [
				2.0 * r, TAU * r, (TAU * r) / (2.0 * r)], "value": (TAU * r) / (2.0 * r)}
		"equal_area":
			# 面積だけが動かない。辺の長さは動くので、そこを見せて「変わらなさ」を出す
			var ab: float = p.distance_to(TRI_B)
			var ac: float = p.distance_to(TRI_C)
			return {"row": "辺 AB %.2f  辺 AC %.2f  高さ 6  → 面積 %.1f" % [
				ab, ac, 30.0], "value": 30.0}
		"pythagoras":
			# c は「斜辺を測った長さ」から出す(a²+b² を 2 回書くと出来レースに見える)
			var a2: float = p.x * p.x
			var b2: float = p.y * p.y
			var c_side: float = Vector2(p.x, 0.0).distance_to(Vector2(0.0, p.y))
			return {"row": "a² %.1f ＋ b² %.1f ＝ %.1f   斜辺 %.2f → c² %.1f" % [
				a2, b2, a2 + b2, c_side, c_side * c_side],
				"value": c_side * c_side - (a2 + b2)}
		"inscribed":
			# 席の位置は変わるのに角が変わらない、という形にする
			var deg := inscribed_angles(p)
			return {"row": "席の位置 %d°  円周角 %d°  中心角 %d°  → 中心角 − 円周角×2 = %d°" % [
				roundi(rad_to_deg(atan2(p.y, p.x))), roundi(deg[0]), roundi(deg[1]),
				roundi(deg[1] - 2.0 * deg[0])],
				"value": deg[1] - 2.0 * deg[0]}
		"sine_law":
			var deg2 := inscribed_angles(p)
			var a_side := chord_len()
			var s := a_side / maxf(sin(deg_to_rad(deg2[0])), 0.0001)
			return {"row": "∠A %d°  a %.2f  → a÷sin A %.2f   2R %.2f" % [
				roundi(deg2[0]), a_side, s, 2.0 * R_CIRCLE], "value": s - 2.0 * R_CIRCLE}
		"similar":
			# 面積は実際に頂点から計算する(k×k と書くだけでは確かめたことにならない)
			var k: float = p.x
			var s1 := polygon_area(tri_shape(1.0))
			var s2 := polygon_area(tri_shape(k))
			return {"row": "相似比 %.2f  小 %.2f  大 %.2f  → 面積比 %.2f ÷ (%.2f×%.2f) = %.2f" % [
				k, s1, s2, s2 / s1, k, k, (s2 / s1) / (k * k)],
				"value": (s2 / s1) / (k * k)}
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


## 折れ線の 3 つの角 [上の角, 下の角, 折れ角]。
## 平行な壁(y=0 と y=8)の右側に端があり、曲がり角 p は左側にある
const ZIG_LOW := Vector2(9.0, 0.0)
const ZIG_HIGH := Vector2(11.0, 8.0)


static func zigzag_angles(p: Vector2) -> Array:
	var left := Vector2(-1.0, 0.0)
	var up_ang := rad_to_deg(acos(clampf(
		(p - ZIG_HIGH).normalized().dot(left), -1.0, 1.0)))
	var low_ang := rad_to_deg(acos(clampf(
		(p - ZIG_LOW).normalized().dot(left), -1.0, 1.0)))
	var bend := rad_to_deg(acos(clampf(
		(ZIG_HIGH - p).normalized().dot((ZIG_LOW - p).normalized()), -1.0, 1.0)))
	return [up_ang, low_ang, bend]


## 多角形の面積(靴ひもの公式)
static func polygon_area(pts: Array) -> float:
	var s := 0.0
	for i in pts.size():
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		s += a.x * b.y - b.x * a.y
	return absf(s) * 0.5


## 相似の章で使う三角形(k 倍したもの)
static func tri_shape(k: float) -> Array:
	return [Vector2(0.0, 0.0) * k, Vector2(4.0, 0.0) * k, Vector2(1.2, 3.0) * k]


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
