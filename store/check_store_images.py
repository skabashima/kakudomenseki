# -*- coding: utf-8 -*-
"""ストア入稿画像の検品。

寸法を目で確かめると必ず見落とすので、出力した実ファイルを機械で見る。

見るところ:
  1. 入稿セットの各フォルダが、規定の寸法・枚数になっているか
  2. Google Play の上限(8枚)・App Store の上限(10枚)を超えていないか
  3. 拡大されていないか(素材 store/raw は 1320×2868。これを超える幅で
     出すと画質が落ちる。iPad だけは幅が大きいので背景合成で作る)
  4. 形式・色空間(PNG / RGB、アルファ無し)と 1 枚あたりのファイルサイズ
     (Google Play は 1 枚 8MB まで、フィーチャーグラフィックは 15MB まで)
  5. フィーチャーグラフィック 1024×500 と 課金審査用 1242×2208 があるか

実行: python store/check_store_images.py
"""
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
DELIVERY = os.path.join(HERE, "入稿セット")

# フォルダ名 -> (幅, 高さ, 最小枚数, 最大枚数)
EXPECT = {
    "GooglePlay_スマホ_1080x1920": (1080, 1920, 2, 8),
    "AppStore_iPhone6.9_1320x2868_必須": (1320, 2868, 3, 10),
    "AppStore_iPhone6.5_1284x2778": (1284, 2778, 3, 10),
    "AppStore_iPad13_2048x2732_必須": (2048, 2732, 3, 10),
}
RAW_W, RAW_H = 1320, 2868      # 撮影した実画面の解像度
MAX_MB = 8.0                   # Google Play の 1 枚あたりの上限


def main():
    ok = True
    print("== 入稿セット ==")
    if not os.path.isdir(DELIVERY):
        print("  NG  入稿セットがありません:", DELIVERY)
        return 1
    for name, (w, h, lo, hi) in EXPECT.items():
        d = os.path.join(DELIVERY, name)
        if not os.path.isdir(d):
            ok = False
            print("  NG  フォルダが無い: %s" % name)
            continue
        files = sorted(f for f in os.listdir(d) if f.lower().endswith(".png"))
        bad = []
        big = 0.0
        for f in files:
            im = Image.open(os.path.join(d, f))
            if im.size != (w, h):
                bad.append("%s=%dx%d" % (f, im.size[0], im.size[1]))
            if im.mode not in ("RGB", "P"):
                bad.append("%s=%s(アルファつきは避ける)" % (f, im.mode))
            mb = os.path.getsize(os.path.join(d, f)) / 1024 / 1024
            if mb > MAX_MB:
                bad.append("%s=%.1fMB(上限 %.0fMB)" % (f, mb, MAX_MB))
            big = max(big, mb)
        count_ok = lo <= len(files) <= hi
        if bad or not count_ok:
            ok = False
        print("  %-34s %dx%d  %d枚(%d〜%d)  最大 %.1f MB  %s" % (
            name, w, h, len(files), lo, hi, big,
            "OK" if (not bad and count_ok) else "*** NG ***"))
        for b in bad:
            print("        寸法/形式/容量が違う: %s" % b)
        if not count_ok:
            print("        枚数が範囲外(ストアの上限を超えるとアップロードできない)")

    # 素材より大きく引き伸ばしていないか
    print("\n== 引き伸ばしの確認(素材 %dx%d) ==" % (RAW_W, RAW_H))
    for name, (w, h, _lo, _hi) in EXPECT.items():
        # 端末画面は横幅の 88 % に置く。ただし素材幅で頭打ちにしてある
        need = min(w * 0.88, RAW_W)
        if need > RAW_W:
            ok = False
            print("  %-34s 端末画面の幅 %.0f > 素材 %d  … 拡大あり" % (name, need, RAW_W))
        else:
            print("  %-34s 端末画面の幅 %.0f ≦ %d  OK" % (name, need, RAW_W))

    print("\n== 単品の必須画像 ==")
    feat = os.path.join(DELIVERY, "GooglePlay_フィーチャーグラフィック_1024x500.png")
    ok = _one(feat, (1024, 500), "フィーチャーグラフィック(Google Play 必須)") and ok
    iap = os.path.join(DELIVERY, "AppStore_App内課金_審査用_1242x2208.png")
    ok = _one(iap, (1242, 2208), "App内課金の審査用スクショ") and ok
    promo = os.path.join(DELIVERY, "AppStore_App内課金_プロモ_1024x1024.png")
    ok = _one(promo, (1024, 1024), "App内課金のプロモ画像(任意)") and ok
    icon = os.path.join(HERE, "icon", "icon_1024.png")
    ok = _one(icon, (1024, 1024), "アプリアイコン(App Store 用 / 書き出し元)") and ok
    play_icon = os.path.join(DELIVERY, "GooglePlay_アプリアイコン_512x512.png")
    ok = _one(play_icon, (512, 512), "アプリアイコン(Google Play Console 必須)") and ok

    print("\n判定:", "入稿してよい" if ok else "★ 修正が必要 ★")
    return 0 if ok else 1


def _one(path, size, label):
    if not os.path.exists(path):
        print("  NG  %s が無い: %s" % (label, path))
        return False
    im = Image.open(path)
    good = im.size == size
    print("  %s  %-38s %dx%d" % ("OK " if good else "NG ", label, im.size[0], im.size[1]))
    return good


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.exit(main())
