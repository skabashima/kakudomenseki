---
name: android-aab
description: Google Play にあげる Android の AAB を、この手元の Windows で書き出す手順(版の確かめ→書き出し→検品→版上げの記録)。「AAB をビルドして」「リリースして」「Play に出して」と言われたときに使う。2026-09-06 に 1.2.2(versionCode 11)を実際に通した手順だけを書いてある。
---

# Android の AAB を書き出す(図形ハンター)

**AAB のビルドは 指示が あった ときだけ 行う。** 自動では やらない。

書き出せるのは **署名鍵の ある 手元の Windows**。
鍵は リポジトリの 外(`..\keys kakudomenseki\`)に あり、
Claude Code の Linux コンテナには 無い。

---

## 1. 手順(これだけ)

```powershell
powershell -ExecutionPolicy Bypass -File "tools\build_aab.ps1"
```

- 出力: `build/android/kakudomenseki.aab`(そのまま Play Console へ)
- `-Bump` … `export_presets.cfg` の `version/code` を +1 してから 書き出す
- `-DebugSign` … デバッグ鍵で 署名(手元の 確認用。Play には 出せない)
- `-VerifyOnly` … すでに ある AAB の 検めだけ

**バックグラウンドで 走らせる。** 実測 3〜4 分だったが、
gradle の 状態に よっては 10〜15 分 かかる。途中で 止めない。
経過は `%TEMP%\kakudomenseki_export.log` と 標準出力に 出る。

スクリプトが 順に やること ―
版の 突き合わせ → SDK 探しと パス直し → 鍵と パスワードを 環境変数へ →
`--import` → `--export-release "Android"` → 検品。

## 2. 走らせる 前に 見る 3 つ

| 見るもの | 通っている 印 |
|---|---|
| ブランチ | `git checkout main && git pull --ff-only origin main` を 先に 済ませる |
| `version/code` | Play は **同じ code を 弾く**。まだ 出していない 版なら そのまま、出した 版なら `-Bump` |
| 署名鍵 | `..\keys kakudomenseki\kakudomenseki-release.keystore` と `keystorePASS.txt` |

`version/code` の いまの 値は `grep version/code export_presets.cfg`。
**どこまで 出したか**は `store/ストア掲載情報.md` の 「署名つき AAB を 書き出し」の 行に 書いてある。

## 3. 通った ときの 出力(2026-09-06 / 1.2.2)

これと 同じ 形が 出れば 成功。**ここまで 出ずに 終わったら 失敗**。

```
   o エディタもビルドテンプレートも 4.7.stable
   o SDK: C:/Users/seiic/AppData/Local/Android/Sdk
   o versionCode = 11
   o リリース鍵を環境変数で渡す(cfg には書かない) alias=kakudomenseki
   ※ 生成物が安定したので godot を終了させる(居座り対策)
   o kakudomenseki.aab  60.4 MB
判定: アップロードして良い
   o リリース鍵で署名されている
   o 日本語フォントが同梱されている
完成: ...\build\android\kakudomenseki.aab
```

検品の 中身(`store/check_aab.py`)―
`jp.snaplace.kakudomenseki` / targetSdk 36 / minSdk 24 / versionCode 11 / versionName 1.2.2 /
BILLING 権限あり / 16KB ページ OK(`libc++_shared.so`・`libgodot_android.so` とも align=16384) /
ストア用画像・テストは 同梱なし / エントリ 376・展開後 162.4 MB。

**課金が 本当に 入っているかは dex を 見る**(権限の 有無だけでは 足りない):

```bash
python -c "
import zipfile
z = zipfile.ZipFile('build/android/kakudomenseki.aab')
dex = b''.join(z.read(n) for n in z.namelist() if n.endswith('.dex'))
assert dex.find(b'com/android/billingclient') >= 0
assert dex.find(b'GodotGooglePlayBilling') >= 0
print('ok')
"
```

`addons/` に 置くだけでは AAR が 入らない。
`project.godot` の `[editor_plugins] enabled=` に
`GodotGooglePlayBilling` と `godot-iap` の `plugin.cfg` が 並んでいる ことが 前提。

## 4. 踏んだ ところ(スクリプトが 面倒を 見ている)

**直す 必要は 無い。「そう いう ものだ」と 知って おく ための 記録。**

- **終了コードを 信用しない。** Godot 4.7 の headless export は 正しい AAB が
  出ていても 0 以外を 返す ことが ある。**生成物の 有無で 判定する。**
- **書き出しが 終わっても godot が 終了せず 居座る**(実際に 40 分 待たされた)。
  スクリプトは `Start-Process` で 起こし、**生成物の 大きさが 30 秒 変わらなければ
  完了と みなして 終わらせる**。今回も この 判定で 抜けている。
- **ログの export 行が 文字化けする**(`Android逕ｨ縺ｫ...`)。コンソール版 exe の
  出力を リダイレクトした ための もので、**壊れている 印では ない**。
- **`[GodotIap] Plugin disabled` が 最後に 出る**。書き出し終わりの 後始末で、
  **課金が 落ちた 印では ない**(dex の 検査で 入っている ことを 確かめた)。
- **エディタ設定の SDK パスに `\` と `/` が 混ざると リリース書き出しだけ 落ちる**。
  スクリプトが 毎回 `/` に 揃えている。
- **パスに 空白が 入る**(「マイ ノートパソコン」)。`Start-Process -ArgumentList` は
  引用符を 付けないので 各引数を 自分で くくる。
- **パスワードを cfg に 書かない。** `export_presets.cfg` の keystore 欄は 空のままで、
  `GODOT_ANDROID_KEYSTORE_RELEASE_*` の 環境変数だけで 署名される。
  alias は 鍵の 中から 自動で 読む(思いこみで 決めると 落ちる)。

## 5. 版を 上げる ときに 直す ファイル

| ファイル | 項目 |
|---|---|
| `export_presets.cfg` | `application/short_version` / `application/version`(iOS は CI が 差し替え) |
| `export_presets.cfg` | `version/name`(Android) / `version/code` ← **毎回 +1** |
| `store/リリースノート.md` | その版の 節(貼り文と 社内用の 記録) |
| `store/APPSTORE.md` | バージョン |
| `store/ストア掲載情報.md` | versionCode / versionName と 「書き出し済み」の チェック |

直したら `python store/check_store_text.py` を 通す。

## 6. 出す前の 通し

CI(Codemagic)は **iOS の ビルドだけ**。テストは 載せていない(ビルド分が 課金される)。
push する前に 手元で 通す。

```bash
G="$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7-stable_win64_console.exe"
for t in explain_check kid_check kid_touch story_play gen_check calc_check \
         play_check smoke iap_gate review_check daily_check power_check island_check; do
  "$G" --headless --path . res://tests/$t.tscn
done
python store/check_store_text.py
```

## 7. 一行で

**main を 最新に する → `version/code` を 確かめる → `build_aab.ps1` を
バックグラウンドで 走らせる → 「判定: アップロードして良い」まで 出たら 完成。**
