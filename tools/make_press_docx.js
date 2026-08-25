// store/プレスリリース案.md を そのまま読んで .docx にする。
//   npm install docx   (初回のみ)
//   node tools/make_press_docx.js store/プレスリリース案.docx [store/プレスリリース案.md]
//
// 以前は本文をこのファイルに直書きしていて、md を直しても docx が古いままだった
// (41 ステージ・15,329 通りのまま残っていた)。いまは md 一本を読むので ずれない。
// 読むのは「## 見出しの候補」の手前まで(そこから先は社内メモ)。
const fs = require("docx") && require("fs");
const {
  Document, Packer, Paragraph, TextRun, AlignmentType,
  Table, TableRow, TableCell, WidthType, ShadingType,
} = require("docx");

const FONT = "Yu Gothic";
const OUT = process.argv[2];
const SRC = process.argv[3] || "store/プレスリリース案.md";
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

function h1(text) {
  return new Paragraph({
    spacing: { before: 200, after: 200, line: 340 },
    children: [new TextRun({
      text, font: FONT, size: 30, bold: true, color: "1F3864" })],
  });
}

function h2(text) {
  return new Paragraph({
    spacing: { before: 320, after: 140 },
    children: [new TextRun({ text, font: FONT, size: 24, bold: true, color: "1F3864" })],
  });
}

function bullet(text, level) {
  return new Paragraph({
    bullet: { level },
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

function clean(t) {
  return t.replace(/\*\*/g, "").replace(/<br>/g, " ").replace(/`/g, "").trim();
}

// md を 段落・箇条書き・表 に分ける(この文書に出てくる書き方だけを見る)
function build(md) {
  const cut = md.indexOf("## 見出しの候補");
  const src = cut >= 0 ? md.slice(0, cut) : md;
  const out = [];
  let table = null;
  const flush = () => {
    if (table && table.length) out.push(infoTable(table));
    table = null;
  };
  for (const raw of src.split(/\r?\n/)) {
    const line = raw.trimEnd();
    if (/^\s*$/.test(line) || line.startsWith("> ") || line === "---") { flush(); continue; }
    if (line.startsWith("# ")) { flush(); continue; }      // ファイル名の見出しは出さない
    if (line.startsWith("## ")) { flush(); out.push(h1(clean(line.slice(3)))); continue; }
    if (line.startsWith("### ")) { flush(); out.push(h2(clean(line.slice(4)))); continue; }
    if (/^\s*-\s/.test(line)) {
      flush();
      out.push(bullet(clean(line.replace(/^\s*-\s/, "")),
        /^\s{2,}-/.test(line) ? 1 : 0));
      continue;
    }
    if (line.startsWith("|")) {
      const cells = line.split("|").slice(1, -1).map((c) => clean(c));
      if (cells.every((c) => /^-*$/.test(c.replace(/\s/g, "")))) continue;  // 罫線
      if (!table) table = [];
      table.push([cells[0] || "", cells.slice(1).join(" ")]);
      continue;
    }
    flush();
    out.push(p(clean(line)));
  }
  flush();
  out.push(p("※ ■■■■ の箇所は配信URL確定後・所在地等の確認後に埋めてください。"
    + "スクリーンショット・アイコン素材は store/入稿セット/ にあります。",
    { size: 18, color: "666666" }));
  return out;
}

const doc = new Document({
  styles: { default: { document: { run: { font: FONT, size: 21 } } } },
  sections: [{
    properties: { page: { margin: { top: 1134, bottom: 1134, left: 1134, right: 1134 } } },
    children: build(fs.readFileSync(SRC, "utf8")),
  }],
});

Packer.toBuffer(doc).then((buf) => {
  fs.writeFileSync(OUT, buf);
  console.log("wrote " + OUT);
});
