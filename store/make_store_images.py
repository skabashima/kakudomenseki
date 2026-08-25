# -*- coding: utf-8 -*-
"""ストア掲載用スクリーンショットを仕上げる。

素材(store/raw/*.png = 1320×2868 の実画面)に、角度編(金)/面積編(青)の色をつかった
背景とキャッチコピーを合成し、各ストアの規定サイズで書き出す。

出力:
  store/screenshots/appstore_6.9/  1320×2868  … App Store iPhone 6.9インチ(必須)
  store/screenshots/appstore_6.5/  1284×2778  … App Store iPhone 6.5インチ(任意)
  store/screenshots/appstore_ipad/ 2048×2732  … iPad 13インチ(iPad 対応なら必須)
  store/screenshots/googleplay/    1080×1920  … Google Play スマートフォン
  store/screenshots/iap_review/    1242×2208  … App内課金の審査用(+1024×1024 プロモ用)
  store/入稿セット/                        … そのままアップロードできる形(推奨順に 01→08)
  store/入稿セット/GooglePlay_フィーチャーグラフィック_1024x500.png

素材の撮り直しは `godot --path . res://tests/shot_store.tscn`。
実行: python store/make_store_images.py
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(HERE)
FONT = os.path.join(PROJ, "assets", "fonts", "NotoSansJP.ttf")
RAW = os.path.join(HERE, "raw")
OUT = os.path.join(HERE, "screenshots")

# 出力サイズ(幅, 高さ)
SIZES = {
    "appstore_6.9": (1320, 2868),
    "appstore_6.5": (1284, 2778),
    "appstore_ipad": (2048, 2732),
    "googleplay": (1080, 1920),
}

# 入稿セットの構成。フォルダ名にサイズと必須の別を書いておく
DELIVERY = [
    ("googleplay", "GooglePlay_スマホ_1080x1920"),
    ("appstore_6.9", "AppStore_iPhone6.9_1320x2868_必須"),
    ("appstore_6.5", "AppStore_iPhone6.5_1284x2778"),
    ("appstore_ipad", "AppStore_iPad13_2048x2732_必須"),
]

# 掲載する順(Google Play は 8 枚まで)。最初の 3 枚で「何のアプリか」が伝わる並びにする
PICKS = [
    "01_title", "08_kid_tear", "03_problem_angle", "05_calc",
    "06_walkthrough", "09_story_hs", "11_stage_select_men", "12_store_iap",
]

# 画面ごとの: 素材 / 見出し / 補足 / 背景色(濃い→薄い)
NAVY = ((18, 30, 62), (44, 74, 140))
GOLD = ((62, 44, 12), (168, 122, 40))
BLUE = ((16, 44, 68), (44, 106, 160))
PLUM = ((44, 24, 52), (116, 66, 132))
TEAL = ((16, 48, 46), (40, 116, 108))

SHOTS = [
    ("01_title.png", "中学受験から\n大学受験まで",
     "角度と面積だけを集めた 65 ステージ。学年が上がっても同じアプリで", NAVY),
    ("02_stage_select.png", "一本道で\n積み上がる",
     "前をクリアすると次が開く。小学生の範囲はふりがな付き", GOLD),
    ("03_problem_angle.png", "図で出る。\n数字で答える。",
     "星形・時計の針・円周角…同じ問題でも値は毎回ちがう", NAVY),
    ("04_problem_leaf.png", "中学受験の名物問題も\nそのまま",
     "葉っぱ形・道の面積・ブーメラン形・折り返し", BLUE),
    ("05_calc.png", "式のまま答えられる。\n紙とペンいらず",
     "√ × ÷ が使える電卓つき。途中計算もその場で", TEAL),
    ("06_walkthrough.png", "わからなければ\n「解き方」をアニメで",
     "補助線がスッと引かれ、1ステップずつ進む", GOLD),
    ("07_kid_select.png", "小学生は\nストーリーから",
     "中学受験の全 23 単元に、さわって見つける回が 1 つずつ", PLUM),
    ("08_kid_tear.png", "かどを ちぎって\nならべると 180°",
     "公式を読む前に、指で動かして自分で見つける", GOLD),
    ("09_story_hs.png", "高校生は\n別の物語で",
     "惑星の基地で、方べき・余弦定理・積分を実際に使う", TEAL),
    ("10_records.png", "段位と★が\n積み上がる",
     "見習いから図形仙人まで。コンボで点が伸びる", NAVY),
    ("11_stage_select_men.png", "面積編は 45 ステージ。\n三平方から積分まで",
     "方べき・チェバ・円の方程式・空間図形・回転体もカバー", BLUE),
    ("12_store_iap.png", "買い切り。\n広告も追加課金もなし",
     "各編の最初の 4 ステージは無料でためせる", NAVY),
]

# 掲載順にリネームするときの短い名前(01_ の数字は PICKS の並び)
NICE_NAME = {
    "01_title": "title",
    "02_stage_select": "stages",
    "03_problem_angle": "angle",
    "04_problem_leaf": "area",
    "05_calc": "calc",
    "06_walkthrough": "howto",
    "07_kid_select": "story_kids",
    "08_kid_tear": "kids_tear",
    "09_story_hs": "story_hs",
    "10_records": "records",
    "11_stage_select_men": "stages_area",
    "12_store_iap": "unlock",
}


def font(size):
    return ImageFont.truetype(FONT, size)


def gradient(size, c0, c1):
    w, h = size
    img = Image.new("RGB", (w, h), c0)
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(h - 1, 1)
        # 上を濃く、下を明るく
        c = tuple(int(c0[i] + (c1[i] - c0[i]) * (t ** 0.85)) for i in range(3))
        d.line([(0, y), (w, y)], fill=c)
    return img


def watermark(bg, size):
    """うっすら図形を敷いて「図形のアプリ」だと分かるようにする。"""
    w, h = size
    wm = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(wm)
    ink = (255, 255, 255, 26)
    lw = max(2, int(w * 0.004))
    # 三角形
    r = w * 0.20
    cx, cy = w * 0.20, h * 0.30
    pts = [(cx + r * math.cos(math.radians(a)), cy + r * math.sin(math.radians(a)))
           for a in (-90, 30, 150)]
    d.polygon(pts, outline=ink, width=lw)
    # 円
    r2 = w * 0.16
    cx2, cy2 = w * 0.80, h * 0.55
    d.ellipse([cx2 - r2, cy2 - r2, cx2 + r2, cy2 + r2], outline=ink, width=lw)
    # 角の印(2 本の辺と弧)
    ax, ay = w * 0.16, h * 0.80
    d.line([(ax, ay), (ax + w * 0.30, ay)], fill=ink, width=lw)
    d.line([(ax, ay), (ax + w * 0.26, ay - h * 0.10)], fill=ink, width=lw)
    ar = w * 0.10
    d.arc([ax - ar, ay - ar, ax + ar, ay + ar], start=-21, end=0, fill=ink, width=lw)
    return Image.alpha_composite(bg.convert("RGBA"), wm).convert("RGB")


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0], img.size[1]],
                                           radius=radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def compose(raw_name, head, sub, colors, size):
    w, h = size
    bg = watermark(gradient(size, colors[0], colors[1]), size)
    d = ImageDraw.Draw(bg)

    # 見出し(枠に収まるまで自動で縮める)
    left = int(w * 0.072)
    avail = w - left * 2
    head_size = int(w * 0.088)
    lines = head.split("\n")
    while head_size > 20:
        f = font(head_size)
        if max(d.textlength(ln, font=f) for ln in lines) <= avail:
            break
        head_size -= 2
    sub_size = int(w * 0.038)
    while sub_size > 14 and d.textlength(sub, font=font(sub_size)) > avail:
        sub_size -= 1
    y = int(h * 0.050)
    for line in lines:
        d.text((left, y), line, font=font(head_size), fill=(255, 255, 255))
        y += int(head_size * 1.24)
    y += int(head_size * 0.16)
    d.text((left, y), sub, font=font(sub_size), fill=(226, 234, 250))

    # 端末画面(角丸+影)。上の文言のぶんだけ下に置く
    shot = Image.open(os.path.join(RAW, raw_name)).convert("RGB")
    top = max(int(h * 0.255), y + int(sub_size * 2.0))
    max_h = h - top - int(h * 0.035)
    # 素材より大きくしない。iPad(2048 幅)では 0.88 倍だと引き伸ばしになり、
    # ぼやけた画像を必須枠に出すことになる。背景を広くとって等倍以下に収める
    max_w = min(int(w * 0.88), shot.width)
    scale = min(max_w / shot.width, max_h / shot.height)
    sw, sh = int(shot.width * scale), int(shot.height * scale)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    card = rounded(shot, int(sw * 0.055))

    shadow = Image.new("RGBA", (sw + 80, sh + 80), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [40, 46, 40 + sw, 46 + sh], radius=int(sw * 0.055), fill=(0, 0, 0, 130))
    shadow = shadow.filter(ImageFilter.GaussianBlur(26))
    x = (w - sw) // 2
    bg.paste(shadow, (x - 40, top - 40), shadow)
    bg.paste(card, (x, top), card)
    # 縁を明るくして、背景に沈まないようにする
    ImageDraw.Draw(bg).rounded_rectangle(
        [x, top, x + sw, top + sh], radius=int(sw * 0.055),
        outline=(255, 255, 255), width=max(2, int(w * 0.0025)))
    return bg


def make_feature_graphic(path):
    """Google Play で必須のフィーチャーグラフィック(1024×500)。

    ストアのカードで上に大きく出る帯。アイコン + アプリ名 + 一行の売り文句だけにして、
    小さく表示されても読めるようにする。
    """
    w, h = 1024, 500
    img = watermark(gradient((w, h), (16, 26, 56), (46, 78, 146)), (w, h))
    d = ImageDraw.Draw(img)
    icon_path = os.path.join(HERE, "icon", "icon_1024.png")
    text_left = int(w * 0.07)
    if os.path.exists(icon_path):
        side = int(h * 0.56)
        icon = Image.open(icon_path).convert("RGB").resize((side, side), Image.LANCZOS)
        icon = rounded(icon, int(side * 0.22))
        ix, iy = int(w * 0.06), (h - side) // 2
        shadow = Image.new("RGBA", (side + 60, side + 60), (0, 0, 0, 0))
        ImageDraw.Draw(shadow).rounded_rectangle(
            [30, 34, 30 + side, 34 + side], radius=int(side * 0.22), fill=(0, 0, 0, 120))
        shadow = shadow.filter(ImageFilter.GaussianBlur(18))
        img.paste(shadow, (ix - 30, iy - 30), shadow)
        img.paste(icon, (ix, iy), icon)
        text_left = ix + side + int(w * 0.055)

    title = "図形ハンター"
    sub1 = "角度と面積を、数字で撃ち落とせ。"
    sub2 = "中学・高校・大学受験 ― 全41ステージ"
    # 右端いっぱいに文字を置かない(ストアの一覧で端が切られることがある)
    avail = w - text_left - int(w * 0.07)
    t_size = int(h * 0.19)
    while t_size > 20 and d.textlength(title, font=font(t_size)) > avail:
        t_size -= 2
    s_size = int(h * 0.072)
    while s_size > 12 and max(d.textlength(x, font=font(s_size))
                             for x in (sub1, sub2)) > avail:
        s_size -= 1
    y = int(h * 0.27)
    d.text((text_left, y), title, font=font(t_size), fill=(255, 216, 120))
    y += int(t_size * 1.22)
    d.text((text_left, y), sub1, font=font(s_size), fill=(255, 255, 255))
    y += int(s_size * 1.5)
    d.text((text_left, y), sub2, font=font(s_size), fill=(206, 220, 245))
    img.save(path)
    return True


def make_iap_images():
    """App Store の App内課金まわりの画像。2つは別物なので取り違えないこと。

      ・審査用スクリーンショット … **1242×2208**(5.5インチの掲載スクショ規格)。
        1290×2796 のような実寸縦長や 1024×1024 を出すと「寸法が違う」で弾かれる。
      ・プロモーション用画像 … 1024×1024。課金商品を宣伝する任意項目で、
        審査用スクショの代わりにはならない。

    どちらも縦長の実画面をそのまま使えないので、中身のある部分だけ切り出して
    アプリと同じ地の色で規定サイズに詰める。
    """
    iap = os.path.join(OUT, "iap_review")
    os.makedirs(iap, exist_ok=True)
    src = os.path.join(RAW, "10_store_iap.png")
    if not os.path.exists(src):
        print("  素材なし:", src)
        return
    shot = Image.open(src).convert("RGB")
    bg = shot.getpixel((8, shot.height - 8))     # 下端＝アプリの地の色
    w, h = shot.size
    px = shot.load()
    bottom = 0
    for y in range(h - 1, -1, -1):
        for x in range(0, w, 8):
            c = px[x, y]
            if abs(c[0] - bg[0]) + abs(c[1] - bg[1]) + abs(c[2] - bg[2]) > 24:
                bottom = y
                break
        if bottom:
            break
    pad = int(w * 0.04)
    content = shot.crop((0, 0, w, min(h, bottom + pad)))

    def fit(size, name):
        sw, sh = size
        scale = min(sw / content.width, sh / content.height)
        im = content.resize((max(1, int(content.width * scale)),
                             max(1, int(content.height * scale))), Image.LANCZOS)
        canvas = Image.new("RGB", size, bg)
        canvas.paste(im, ((sw - im.width) // 2, (sh - im.height) // 2))
        canvas.save(os.path.join(iap, name), dpi=(72, 72))

    fit((1242, 2208), "iap_review_1242x2208.png")     # 審査用
    fit((1024, 1024), "iap_promo_1024x1024.png")      # プロモーション用(任意)
    shot.save(os.path.join(iap, "store_screen_1320x2868.png"))   # 参考: 実寸のまま
    print("iap_review       1242x2208(審査用)と 1024x1024(プロモ用)")


def build_delivery():
    """そのままアップロードできる形にまとめる。

    ストアの枠は Google Play が 8 枚まで、App Store が 10 枚まで。全部載せると
    伝わらないので PICKS の 8 枚に絞り、掲載順どおりに 01→08 でリネームする。
    """
    root = os.path.join(HERE, "入稿セット")
    os.makedirs(root, exist_ok=True)
    for folder, dest_name in DELIVERY:
        dest = os.path.join(root, dest_name)
        os.makedirs(dest, exist_ok=True)
        for old in os.listdir(dest):
            if old.lower().endswith(".png"):
                os.remove(os.path.join(dest, old))
        for i, base in enumerate(PICKS, start=1):
            src = os.path.join(OUT, folder, base + ".png")
            if not os.path.exists(src):
                print("  入稿セット: 素材なし", src)
                continue
            Image.open(src).save(
                os.path.join(dest, "%02d_%s.png" % (i, NICE_NAME.get(base, base))))
        print("入稿セット  %-34s %d枚" % (dest_name, len(PICKS)))
    make_feature_graphic(
        os.path.join(root, "GooglePlay_フィーチャーグラフィック_1024x500.png"))
    print("入稿セット  GooglePlay_フィーチャーグラフィック_1024x500.png")
    # App内課金の画像も「アップロードするもの」なので入稿セットに置く
    iap_dir = os.path.join(OUT, "iap_review")
    for src_name, dest_name in [
            ("iap_review_1242x2208.png", "AppStore_App内課金_審査用_1242x2208.png"),
            ("iap_promo_1024x1024.png", "AppStore_App内課金_プロモ_1024x1024.png")]:
        src = os.path.join(iap_dir, src_name)
        if os.path.exists(src):
            Image.open(src).save(os.path.join(root, dest_name))
            print("入稿セット  %s" % dest_name)
    # Google Play Console の「アプリアイコン」は 512×512。アプリに埋まる
    # ランチャーアイコンとは別で、こちらは Console にアップロードする
    icon_path = os.path.join(HERE, "icon", "icon_1024.png")
    if os.path.exists(icon_path):
        Image.open(icon_path).convert("RGB").resize((512, 512), Image.LANCZOS).save(
            os.path.join(root, "GooglePlay_アプリアイコン_512x512.png"))
        print("入稿セット  GooglePlay_アプリアイコン_512x512.png")


def main():
    made = 0
    for folder, size in SIZES.items():
        outdir = os.path.join(OUT, folder)
        os.makedirs(outdir, exist_ok=True)
        # 撮り直しで名前が変わった古い画像が残ると、入稿セットに紛れ込むので消す
        for old in os.listdir(outdir):
            if old.lower().endswith(".png"):
                os.remove(os.path.join(outdir, old))
        for raw_name, head, sub, colors in SHOTS:
            if not os.path.exists(os.path.join(RAW, raw_name)):
                print("  素材なし:", raw_name)
                continue
            img = compose(raw_name, head, sub, colors, size)
            img.save(os.path.join(outdir, raw_name.replace(".png", "") + ".png"))
            made += 1
        print("%-16s %dx%d  %d枚" % (folder, size[0], size[1], len(SHOTS)))
    make_iap_images()
    print("合計 %d 枚を %s に出力" % (made, OUT))
    build_delivery()


if __name__ == "__main__":
    main()
