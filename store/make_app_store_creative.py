# -*- coding: utf-8 -*-
"""App Store の「ヘッダと検索結果」の画像(iOS 27 / iPadOS 27 以降で出る)。

  python store/make_app_store_creative.py          # 日本語 → store/入稿セット/app_store_creative/
  python store/make_app_store_creative.py --en     # 英語   → store/入稿セット_en/app_store_creative/

化学ゲーム(chemistry game/tools/make_app_store_creative.gd)と同じ考え方:
  ・背景はゲームの中身そのもの(ここでは角や面積の図形)を薄く敷きつめ、中央を暗くして主役を浮かせる
  ・ヘッダ 3840x1646(21:9)は「図 → 数字」の 3 枚と一文だけ。検索結果 3840x2560(3:2)は実画面と一文
  ・安全領域(Apple は数値を出していないので、テンプレートから測った値):
      ヘッダ 中央 1646x661 / 検索結果 中央 2168x1030。切れてはいけないものはこの中に置く
  ・載せないもの: 価格・割引・URL・©・検証できない受賞。透過は不可(RGB で出す)

実画面は store/raw(_en)/03_problem_angle.png(星形の角。図で出る・数字で答える、が 1 枚で伝わる)。
"""
import math
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(HERE)
FONT = os.path.join(PROJ, "assets", "fonts", "NotoSansJP.ttf")
EN = "--en" in sys.argv
RAW = os.path.join(HERE, "raw_en" if EN else "raw")
OUT = os.path.join(HERE, "入稿セット_en" if EN else "入稿セット", "app_store_creative")

BG = (17, 24, 44)              # アプリの地の色(main.gd の bg と同じ系統)
INK = (255, 255, 255)
GOLD = (255, 216, 120)
LINE = (236, 242, 255)
CARD = (28, 40, 72)
ACCENT = (255, 205, 80)
WALL_COLORS = [(255, 200, 90), (120, 190, 255), (255, 120, 140), (130, 230, 170), (200, 160, 255)]

PHRASE = "See the figure. Type the number." if EN else "図で出る。数字で答える。"
LINES = (["See the figure.", "Type the number.", "Elementary to high school."] if EN
         else ["図で出る。", "数字で答える。", "中学受験から大学受験まで。"])


def font(size, weight="Bold"):
    # 同梱の Noto Sans JP は可変フォントで、既定が Thin(100)。見出しは太字で出す
    f = ImageFont.truetype(FONT, size)
    try:
        f.set_variation_by_name(weight)
    except Exception:
        pass
    return f


# --- 背景: 図形の壁 ---------------------------------------------------------

def _shape(d, kind, cx, cy, r, col, rng):
    w = max(2, int(r * 0.07))
    if kind == "tri":
        a0 = rng.uniform(0, math.pi)
        pts = [(cx + r * math.cos(a0 + k * 2.1), cy + r * math.sin(a0 + k * 2.1)) for k in range(3)]
        d.polygon(pts, outline=col, width=w)
        # 角の印
        d.arc([pts[0][0] - r * 0.3, pts[0][1] - r * 0.3, pts[0][0] + r * 0.3, pts[0][1] + r * 0.3],
              0, 360, fill=col, width=w)
    elif kind == "circle":
        d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=col, width=w)
        a = rng.uniform(0, 360)
        d.pieslice([cx - r, cy - r, cx + r, cy + r], a, a + rng.uniform(40, 120), outline=col, width=w)
    elif kind == "square":
        d.rectangle([cx - r * 0.8, cy - r * 0.8, cx + r * 0.8, cy + r * 0.8], outline=col, width=w)
        d.line([cx - r * 0.8, cy + r * 0.8, cx + r * 0.8, cy - r * 0.8], fill=col, width=w)
    elif kind == "penta":
        pts = [(cx + r * math.cos(-math.pi / 2 + k * 2 * math.pi / 5),
                cy + r * math.sin(-math.pi / 2 + k * 2 * math.pi / 5)) for k in range(5)]
        d.polygon(pts, outline=col, width=w)
    elif kind == "star":
        pts = []
        for k in range(5):
            a = -math.pi / 2 + k * 4 * math.pi / 5
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
        d.polygon(pts, outline=col, width=w)
    else:  # net(十字の展開図)
        s = r * 0.5
        cells = [(0, -1), (-1, 0), (0, 0), (1, 0), (0, 1), (0, 2)]
        for (i, j) in cells:
            d.rectangle([cx + i * s - s * 0.5, cy + j * s - s * 1.0, cx + i * s + s * 0.5, cy + j * s],
                        outline=col, width=w)


def wall(size, seed=5):
    """図形を敷きつめた背景。中央ほど暗くして、主役を浮かせる。"""
    w, h = size
    img = Image.new("RGB", size, BG)
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rng = random.Random(seed)
    cell = int(h * 0.19)
    kinds = ["tri", "circle", "square", "penta", "star", "net"]
    n = 0
    y = -cell * 0.3
    while y < h + cell:
        x = -cell * 0.3 + (cell * 0.5 if int(y / cell) % 2 else 0)
        while x < w + cell:
            col = WALL_COLORS[n % len(WALL_COLORS)] + (120,)
            _shape(d, kinds[(n * 7 + int(y / cell)) % len(kinds)], x, y, cell * 0.33, col, rng)
            n += 1
            x += cell
        y += cell
    img.paste(layer, (0, 0), layer)
    # 中央を暗く(放射状)
    shade = Image.new("L", size, 0)
    sd = ImageDraw.Draw(shade)
    steps = 40
    for i in range(steps):
        k = i / steps
        rx = int(w * (0.08 + 0.55 * k))
        ry = int(h * (0.08 + 0.95 * k))
        sd.ellipse([w // 2 - rx, h // 2 - ry, w // 2 + rx, h // 2 + ry], fill=int(250 * (1 - k) ** 0.8))
    shade = shade.filter(ImageFilter.GaussianBlur(int(h * 0.05)))
    dark = Image.new("RGB", size, BG)
    img = Image.composite(dark, img, shade)
    # 全体も沈める(壁は脇役。主役の文字と画面が浮くくらいまで)
    return Image.blend(img, dark, 0.55)


# --- 部品 -----------------------------------------------------------------

def rounded(size, radius, fill, outline=None, width=0):
    im = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(im).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius,
                                         fill=fill, outline=outline, width=width)
    return im


def card_triangle(side):
    """三角形と 2 つの角、x の角の札(「図で出る」の図)"""
    im = rounded((side, side), int(side * 0.18), CARD + (255,), ACCENT + (255,), max(3, side // 60))
    d = ImageDraw.Draw(im)
    pad = side * 0.17
    a = (pad, side - pad)
    b = (side - pad, side - pad)
    c = (side * 0.42, pad)
    d.polygon([a, b, c], fill=(60, 95, 160, 110), outline=LINE + (255,), width=max(3, side // 70))
    r = side * 0.14
    d.arc([a[0] - r, a[1] - r, a[0] + r, a[1] + r], 300, 360, fill=(140, 200, 255, 255), width=max(3, side // 70))
    d.arc([b[0] - r, b[1] - r, b[0] + r, b[1] + r], 180, 236, fill=(140, 200, 255, 255), width=max(3, side // 70))
    d.arc([c[0] - r, c[1] - r, c[0] + r, c[1] + r], 56, 120, fill=ACCENT + (255,), width=max(3, side // 70))
    f = font(int(side * 0.11), "Medium")
    d.text((a[0] + r * 1.05, a[1] - r * 1.55), "50°", font=f, fill=(190, 225, 255))
    d.text((b[0] - r * 2.5, b[1] - r * 1.55), "60°", font=f, fill=(190, 225, 255))
    d.text((c[0] - r * 0.3, c[1] + r * 1.05), "x", font=font(int(side * 0.15)), fill=ACCENT)
    return im


def card_number(side, text):
    im = rounded((side, side), int(side * 0.18), CARD + (255,), ACCENT + (255,), max(3, side // 60))
    d = ImageDraw.Draw(im)
    f = font(int(side * 0.34))
    tw = d.textlength(text, font=f)
    d.text(((side - tw) / 2, side * 0.26), text, font=f, fill=GOLD)
    return im


def shadowed(bg, im, pos, blur):
    sh = Image.new("RGBA", (im.width + blur * 4, im.height + blur * 4), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle([blur * 2, blur * 2 + blur // 2, blur * 2 + im.width, blur * 2 + blur // 2 + im.height],
                                         radius=int(im.width * 0.1), fill=(0, 0, 0, 140))
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    bg.paste(sh, (pos[0] - blur * 2, pos[1] - blur * 2), sh)
    bg.paste(im, pos, im)


# --- ヘッダ 3840x1646 -------------------------------------------------------

def header():
    w, h = 3840, 1646
    img = wall((w, h), seed=5)
    d = ImageDraw.Draw(img)
    side = 360
    gap = 200
    total = side * 3 + gap * 2
    x = (w - total) // 2
    y = h // 2 - side // 2 - 110
    # 図 → 式 → 数字(「図で出る。数字で答える。」を 3 枚で)
    shadowed(img, card_triangle(side), (x, y), 24)
    x += side
    d.text((x + gap * 0.5 - 40, y + side * 0.22), "→", font=font(150), fill=INK)
    x += gap
    shadowed(img, card_number(side, "180" if EN else "180"), (x, y), 24)
    x += side
    d.text((x + gap * 0.5 - 40, y + side * 0.22), "→", font=font(150), fill=INK)
    x += gap
    shadowed(img, card_number(side, "70°"), (x, y), 24)
    # 一文(安全領域 1646x661 の中)
    f = font(118)
    tw = d.textlength(PHRASE, font=f)
    d.text(((w - tw) / 2, y + side + 56), PHRASE, font=f, fill=INK)
    return img


# --- 検索結果 3840x2560 -----------------------------------------------------

def search():
    w, h = 3840, 2560
    img = wall((w, h), seed=9)
    d = ImageDraw.Draw(img)
    shot = Image.open(os.path.join(RAW, "03_problem_angle.png")).convert("RGB")
    sh_h = int(h * 0.84)
    sh_w = int(sh_h * shot.width / shot.height)
    shot = shot.resize((sh_w, sh_h), Image.LANCZOS)
    # 安全領域 2168x1030 の 右端に 実画面、左に 一文
    right = w // 2 + 1084
    sx = right - sh_w
    sy = (h - sh_h) // 2
    frame = rounded((sh_w + 16, sh_h + 16), 36, ACCENT + (255,))
    shadowed(img, frame, (sx - 8, sy - 8), 40)
    mask = rounded((sh_w, sh_h), 28, (255, 255, 255, 255))
    img.paste(shot, (sx, sy), mask)
    left = w // 2 - 1084
    avail = sx - 60 - left
    size = 150
    while size > 40 and max(d.textlength(t, font=font(size)) for t in LINES) > avail:
        size -= 4
    f = font(size)
    y = h // 2 - int(size * 1.9)
    for s in LINES:
        d.text((left, y), s, font=f, fill=INK)
        y += int(size * 1.32)
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in [("AppStore_header_3840x1646.png", header), ("AppStore_search_3840x2560.png", search)]:
        im = fn().convert("RGB")
        im.save(os.path.join(OUT, name))
        print("%-32s %dx%d" % (name, im.width, im.height))
    print("→", OUT)
    return 0


if __name__ == "__main__":
    sys.exit(main())
