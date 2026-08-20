# -*- coding: utf-8 -*-
"""AAB を Play にアップロードする前の検証。

設定ファイルを見るだけでは足りない(プリセットの上書きや古いテンプレの混入は
成果物にしか出ない)ので、生成された AAB の中身を直接調べる。

確認するもの:
  1. 16KB ページサイズ対応 … arm64 の .so の ELF LOAD セグメント align が 16384 以上か
                              (非対応だと Play にアップロードできない)
  2. targetSdkVersion / minSdkVersion / パッケージ名 / versionName
  3. 余計なもの(ストア用画像・テスト)が同梱されていないか

実行: python store/check_aab.py build/android/kakudomenseki.aab
"""
import struct
import sys
import zipfile


def main(path):
    z = zipfile.ZipFile(path)
    ok = True

    # --- 壊れていないか(書き出しが途中で止まると尻切れの AAB が残る) ---
    print("== ファイルの健全性 ==")
    bad = z.testzip()
    if bad is None:
        print("  OK  全エントリを展開できる")
    else:
        ok = False
        print("  NG  壊れているエントリ:", bad)

    # --- マニフェスト(protobuf なので値の周辺をそのまま出す) ---
    d = z.read("base/manifest/AndroidManifest.xml")
    print("== マニフェスト ==")
    # versionCode は毎回 +1 しないと Play が受け付けないので必ず目視する
    for key in (b"package", b"targetSdkVersion", b"minSdkVersion",
                b"versionCode", b"versionName"):
        print("  %-18s %s" % (key.decode(), _value_of(d, key)))

    # --- 課金の権限 ---
    # これが無いと Play Console で「1回限りのアイテム」を作れない
    # (「請求権限を APK に追加する必要があります」と出て商品登録に進めない)。
    print("\n== アプリ内課金 ==")
    if b"com.android.vending.BILLING" in d:
        print("  OK  BILLING 権限あり(商品を登録できる)")
    else:
        ok = False
        print("  NG  BILLING 権限が無い ― addons/GodotGooglePlayBilling が")
        print("      project.godot の [editor_plugins] で有効になっているか確認")

    # --- 16KB ページ ---
    print("\n== 16KB ページサイズ対応 ==")
    for n in sorted(z.namelist()):
        if not n.endswith(".so"):
            continue
        b = z.read(n)
        if b[:4] != b"\x7fELF" or b[4] != 2:      # 64bit だけが対象
            continue
        phoff = struct.unpack_from("<Q", b, 0x20)[0]
        phentsize = struct.unpack_from("<H", b, 0x36)[0]
        phnum = struct.unpack_from("<H", b, 0x38)[0]
        aligns = set()
        for k in range(phnum):
            off = phoff + k * phentsize
            if struct.unpack_from("<I", b, off)[0] == 1:      # PT_LOAD
                aligns.add(struct.unpack_from("<Q", b, off + 0x30)[0])
        good = all(a >= 16384 for a in aligns)
        ok = ok and good
        print("  %s %-30s align=%s" % ("OK " if good else "NG ", n.split("/")[-1],
                                        sorted(aligns)))

    # --- 余計なものが入っていないか ---
    print("\n== 同梱物 ==")
    # プロジェクト内のパスで判定する。"/raw/" のような広い条件にすると、
    # Billing ライブラリが持ち込む base/res/raw/com_android_billingclient_* を
    # 誤って弾いてしまう(Android の res/raw はライブラリの正規の資源)。
    leaked = [n for n in z.namelist()
              if "store/raw/" in n or "store/screenshots/" in n
              or "/tests/" in n or n.endswith(".py")]
    if leaked:
        ok = False
        print("  NG  除外できていない:", leaked[:5])
    else:
        print("  OK  ストア用画像・テストは入っていない")
    print("  エントリ数 %d / サイズ %.1f MB" % (
        len(z.namelist()), sum(i.file_size for i in z.infolist()) / 1024 / 1024))

    print("\n判定:", "アップロードして良い" if ok else "★ 修正が必要 ★")
    return 0 if ok else 1


def _value_of(d, key):
    """protobuf の中から key に続く文字列値を取り出す。

    aapt2 が無くても versionCode を目で確かめられるようにするため。
    形は <key><0x1a><長さ><値> なので、そこだけ読む。読めなければ生バイトを返す。
    """
    i = d.find(key)
    if i < 0:
        return "(見つからず)"
    j = i + len(key)
    if j < len(d) and d[j] == 0x1a:
        n = d[j + 1]
        try:
            return d[j + 2:j + 2 + n].decode("utf-8")
        except UnicodeDecodeError:
            pass
    return repr(d[i:i + 30])


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.exit(main(sys.argv[1]))
