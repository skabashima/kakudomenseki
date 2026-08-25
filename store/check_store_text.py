# ストアに貼りつける文の検品。
#
#   python store/check_store_text.py
#
# App Store Connect は絵文字などを受けつけず、貼りつけると
# 「このフィールドには1つ以上の無効な文字が含まれています」で弾かれる。
# 実際に 👑 で弾かれたので、機械で見張る。
#
# 見るところ:
#   ・使えない字(絵文字・装飾記号・異体字セレクタ・制御文字)が混じっていないか
#   ・字数が上限を超えていないか(見出しの「(80字以内)」から読み取る)
import io
import os
import re
import sys
import unicodedata

HERE = os.path.dirname(os.path.abspath(__file__))
DOCS = ["ストア掲載情報.md", "APPSTORE.md"]

# 弾かれる字の範囲(絵文字とその仲間)。ここに入る字は書かない
NG_RANGES = [
    (0x1F000, 0x1FAFF),   # 絵文字ぜんぶ(🀄 麻雀牌〜)
    (0x2600, 0x27BF),     # ☀ ★ ✓ ✔ ✅ などの装飾記号・Dingbats
    (0xFE00, 0xFE0F),     # 異体字セレクタ(絵文字の見た目切り替え)
    (0x2B00, 0x2BFF),     # ⬅ ⬛ など
    (0x1F1E6, 0x1F1FF),   # 国旗
]
# 使ってよい記号(日本語の文章でふつうに出るもの)
OK_MARKS = set("、。ー・「」『』()【】〜ー―※＝｜×÷−√¥°々…！？：・■□◆〈〉《》")


def is_ng(ch):
    o = ord(ch)
    if ch in "\n\r\t":
        return False
    if o < 0x20:
        return True
    for lo, hi in NG_RANGES:
        if lo <= o <= hi:
            return True
    return False


def fields(path):
    """### 見出し と、その直後の ``` ブロック の組を返す"""
    s = io.open(path, encoding="utf-8").read()
    out = []
    head = ""
    for m in re.finditer(r"^###[ \t]+([^\n]+)$|^```[^\n]*\n(.*?)\n```$", s, re.M | re.S):
        if m.group(1) is not None:
            head = m.group(1).strip()
        else:
            out.append((head, m.group(2)))
    return out


def limit_of(head):
    m = re.search(r"(\d+)\s*字", head)
    return int(m.group(1)) if m else 0


def main():
    bad = 0
    for name in DOCS:
        path = os.path.join(HERE, name)
        if not os.path.exists(path):
            continue
        print("== %s ==" % name)
        for head, body in fields(path):
            text = body.strip()
            n = len(text.replace("\n", ""))
            lim = limit_of(head)
            ng = sorted({c for c in text if is_ng(c)})
            mark = "OK "
            note = "%d字" % n
            if lim and n > lim:
                mark = "NG "
                note = "%d字 > 上限 %d字" % (n, lim)
                bad += 1
            if ng:
                mark = "NG "
                names = ", ".join(
                    "U+%04X %s" % (ord(c), unicodedata.name(c, "?")) for c in ng)
                note += " / 使えない字: " + names
                bad += 1
            print("  %s %-34s %s" % (mark, head[:34], note))
    print("")
    print("判定: 貼りつけてよい" if bad == 0 else "判定: %d 件なおすこと" % bad)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
