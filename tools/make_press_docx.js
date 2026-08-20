// store/プレスリリース案.md の本文を .docx にする。
//   npm install docx   (初回のみ)
//   node tools/make_press_docx.js store/プレスリリース案.docx
// 本文を直すときは md と この2つを揃えること。
const fs = require("fs");
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType,
  Table, TableRow, TableCell, WidthType, ShadingType, BorderStyle,
} = require("docx");

const FONT = "Yu Gothic";
const OUT = process.argv[2];

const TABLE_W = 9000;
const COLS = [2400, 6600];

function p(text, opts = {}) {
  const { size = 21, bold = false, align, space = 120, color } = opts;
  return new Paragraph({
    alignment: align,
    spacing: { after: space, line: 300 },
    children: [new TextRun({ text, font: FONT, size, bold, color })],
  });
}

function h2(text) {
  return new Paragraph({
    spacing: { before: 320, after: 140 },
    children: [new TextRun({ text, font: FONT, size: 24, bold: true, color: "1F3864" })],
  });
}

function bullet(text) {
  return new Paragraph({
    bullet: { level: 0 },
    spacing: { after: 80, line: 300 },
    children: [new TextRun({ text, font: FONT, size: 21 })],
  });
}

function cell(text, { head = false, width } = {}) {
  return new TableCell({
    width: { size: width, type: WidthType.DXA },
    shading: head ? { type: ShadingType.CLEAR, fill: "EEF1F7" } : undefined,
    margins: { top: 80, bottom: 80, left: 120, right: 120 },
    children: [new Paragraph({
      spacing: { after: 0, line: 280 },
      children: [new TextRun({ text, font: FONT, size: 20, bold: head })],
    })],
  });
}

function infoTable(rows) {
  return new Table({
    width: { size: TABLE_W, type: WidthType.DXA },
    columnWidths: COLS,
    rows: rows.map(([k, v]) => new TableRow({
      children: [cell(k, { head: true, width: COLS[0] }), cell(v, { width: COLS[1] })],
    })),
  });
}

const doc = new Document({
  styles: { default: { document: { run: { font: FONT, size: 21 } } } },
  sections: [{
    properties: { page: { margin: { top: 1134, bottom: 1134, left: 1134, right: 1134 } } },
    children: [
      p("報道関係者各位", { size: 20 }),
      p("プレスリリース　2026年■月■■日", { size: 20, align: AlignmentType.RIGHT, space: 40 }),
      p("合同会社SNAPLACE", { size: 20, align: AlignmentType.RIGHT, space: 240 }),

      new Paragraph({
        spacing: { before: 120, after: 60, line: 380 },
        children: [new TextRun({
          text: "中学受験・高校受験・大学受験の図形を、1本で",
          font: FONT, size: 32, bold: true,
        })],
      }),
      new Paragraph({
        spacing: { after: 140, line: 380 },
        border: { bottom: { style: BorderStyle.SINGLE, size: 8, color: "1F3864", space: 8 } },
        children: [new TextRun({
          text: "角度と面積の学習ゲーム『図形ハンター』を配信開始",
          font: FONT, size: 32, bold: true,
        })],
      }),
      p("平面図形の名物問題から三角比・放物線まで全41ステージ・約15,000通り"
        + "(値は毎回変わるので答えを覚えられない) ／ 各編の最初の4ステージは無料・"
        + "以降は買い切り500円 ／ 広告・ガチャ・スタミナなし",
        { size: 21, bold: true, space: 240 }),

      p("合同会社SNAPLACE(所在地：■■■■、代表：■■■■)は、図形の「角度」と「面積」の問題を"
        + "中学受験・高校受験・大学受験の3レベルで解く学習ゲーム『図形ハンター』を、"
        + "2026年■月■日より App Store(iOS)および Google Play(Android)で配信開始しました。"
        + "小学生の受験算数(平面図形)から高校の三角比・放物線までを1本に収めており、"
        + "学年が上がっても同じアプリで続けられます。",
        { space: 200 }),

      h2("■ 背景：図形の問題集は、答えを覚えた時点で終わってしまう"),
      p("図形は「解き方を知っているかどうか」で差がつく分野です。ところが紙の問題集は"
        + "一度解くと答えを覚えてしまい、同じ問題をもう一度解いても力になりません。"
        + "かといって別の問題集を買っても、載っている解法は同じ十数種類に落ち着きます。"),
      p("本作は「同じ単元を、数値を変えて何度でも解き直せること」を出発点に開発しました。"
        + "問題はすべてプログラムがその場で作るので、答えの丸暗記ができません。"),

      h2("■ ゲーム内容：図で出る。数字で答える。"),
      p("1ステージはハート3つで3問連続のミッションです。まちがえるとハートが減り、"
        + "0になるとやり直し(数値は変わります)。クリア時に残ったハートがそのまま★1〜3になります。"),
      bullet("角度編16ステージ + 面積編25ステージ = 全41ステージ。各編の中は中学受験 → 高校受験 → "
        + "大学受験の順に並び、前をクリアすると次が開きます"),
      bullet("問題文と答えの組だけ数えて15,329通り(実測)。図の数値のちがいまで含めればさらに増えます"),
      bullet("中学受験の看板問題(時計の針・ブーメラン形・折り返し・正多角形の対角線・道の面積・"
        + "長方形の中の点・葉っぱ形)から、ヒポクラテスの月・余弦定理・ヘロンの公式・6分の1公式まで収録"),
      bullet("難度ラダー(tier 0〜9)。クリアした単元に出る「挑戦 10問」では、数字だけでなく解法そのものが"
        + "1問ごとに変わります(例：平行線と角なら 錯角 → 同側内角 → 折れ線 → ジグザグ → ジグザグの逆算)。"
        + "1ステージあたり2〜6種類、全41ステージで約150種類の解法を用意しました"),

      h2("■ とちゅうでつまずかせない仕組み"),
      bullet("電卓内蔵 ― 紙とペンいらず：解答欄には数字だけでなく式が書けます"
        + "(× ÷ + − ( ) √ に対応。例 12×8÷2、三平方なら √(13×13−5×5))。"
        + "「＝計算」で途中計算もでき、こわれた式はハートを消費せずに教えます"),
      bullet("「解き方」は1ステップずつ：押すたびに解き方が一段ずつ進みます。時計の針・折り返し・"
        + "葉っぱ形・ヒポクラテスの月などの看板問題では補助線がスッと引かれ、注目する部分に色がつき、"
        + "等しい角に印がつきます。ほかの問題も図の見るべきところを色でなぞりながら、解説を一段ずつ"
        + "見せます(解き方を見た問題は学習扱いで0点)"),
      bullet("図の上に自分で補助線を引ける：端点は頂点・辺の中点・円の中心にスナップするので、"
        + "「折れ点を通る平行線」「頂点と中点を結ぶ」といった狙った線が正確に引けます"),
      bullet("段位とコンボ：総得点で 見習い → 図形たんけん隊 → 角度ハンター → 面積マイスター → "
        + "図形の達人 → 図形仙人。3分タイムアタックとサバイバルも収録しています"),

      h2("■ 料金"),
      p("角度編・面積編それぞれ最初の4ステージ(計8ステージ)は無料で、中学受験レベルの入口を"
        + "ひととおり遊べます。残り33ステージと、全ステージの「挑戦 10問」、"
        + "チャレンジ(タイムアタック全コース・サバイバル)は買い切り500円(税込)で解放されます。"),
      p("追加課金・サブスクリプション・広告・ガチャ・スタミナはありません。"
        + "個人情報の収集も行わず、通信は課金処理のときだけです。", { space: 200 }),

      h2("■ アプリ概要"),
      infoTable([
        ["名称", "図形ハンター ― 角度と面積を撃ち落とせ"],
        ["ジャンル", "学習×パズル(図形)"],
        ["対応OS", "iOS 17.0以降・iPadOS ／ Android 7.0以降"],
        ["価格", "基本無料(各編の最初の4ステージ)＋買い切り500円(税込・全41ステージ解放)"],
        ["配信", "App Store URL：■■■■　Google Play URL：■■■■"],
        ["プライバシー", "■■■■"],
      ]),

      h2("■ 会社概要"),
      infoTable([
        ["社名", "合同会社SNAPLACE"],
        ["所在地", "■■■■"],
        ["代表", "■■■■"],
        ["URL", "■■■■"],
      ]),

      h2("■ 本件に関するお問い合わせ"),
      p("合同会社SNAPLACE　広報担当", { space: 40 }),
      p("メール：info@snaplace.jp", { space: 240 }),

      p("※ ■■■■ の箇所は配信URL確定後・所在地等の確認後に埋めてください。"
        + "スクリーンショット・アイコン素材は store/入稿セット/ にあります"
        + "(App Store 6.9インチ 1320×2868 ／ Google Play 1080×1920 ほか各8枚、"
        + "フィーチャーグラフィック 1024×500)。", { size: 18, color: "666666" }),
    ],
  }],
});

Packer.toBuffer(doc).then((buf) => {
  fs.writeFileSync(OUT, buf);
  console.log("wrote " + OUT);
});
