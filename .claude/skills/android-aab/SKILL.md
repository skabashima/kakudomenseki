---
name: android-aab
description: Google Play にあげる Android の AAB を書き出す手順と、リリース版を出すまでの流れ(版上げ→テスト→マージ→書き出し→検品)。「AAB をビルドして」「リリースして」「Play に出して」「バージョンを上げて」と言われたとき、また Android の書き出しが失敗したときに使う。Windows の手元でも、Claude Code の Linux コンテナでも書き出せる ― コンテナ側の手順は毎回わすれるので、ここに全部書いてある。
---

# Android の AAB を書き出す(図形ハンター)

**AAB のビルドは指示があったときだけ行う。** 自動でやらない。

## ★ まず この 2 つを 読む(調べ直さない)

セッションの コンテナは 毎回 まっさらで、前の 回の 記憶は 何も 残らない。
だが **答えは ぜんぶ リポジトリの 中に 書いてある**。手を 動かす 前に 読む。

| ファイル | 書いてあること |
|---|---|
| `store/署名鍵の作り方.md` | **署名鍵の 置き場所・alias・パスワードの 場所** |
| `tools/README_BUILD.md` | 普段の 手順・踏んだ 落とし穴 |

ほかの アプリの 同じ ファイルも 役に立つ:
`skabashima/umeshiwa` の `README_BUILD.md` に、**エディタ無しで
android/build を 用意する やり方**(下の ★)が ある。
`skabashima/chemigame` も 同じ 構成。

書き出せる場所は 2 つある。**どちらでも作れる。**
コンテナでは作れないと早合点しないこと ― 下の「用意するもの」を
1 つずつ確かめれば通る。

| | Windows(手元) | Claude Code の Linux コンテナ |
|---|---|---|
| 手順 | `tools/build_aab.ps1` 一発 | このファイルの「コンテナで書き出す」 |
| 署名 | リポジトリ外の リリース鍵 | 鍵を渡してもらう必要がある |
| 落とし穴 | SDK パスの 区切り文字 | android/build の 用意と egress |

---

## 1. 先に確かめる 3 つ(コンテナのとき)

**この 3 つが 揃っていないと どこかで 必ず 止まる。書き出す前に 全部 見る。**

### (a) `dl.google.com` に 出られるか

```bash
curl -s -o /dev/null -w "%{http_code}\n" --max-time 20 https://dl.google.com/
```

`000` や 403 なら **組織の egress ポリシーで 止められている**。
gradle は Android Gradle Plugin を `google()`(= dl.google.com)から取り、
Android SDK も 同じ ところ からしか 取れないので、**ここが 通らないと 書き出せない**。

- 迂回しない。`/root/.ccr/README.md` に「403/407 は 報告する。回り道しない」と ある。
- 環境ごとに ポリシーが ちがう。前の セッションで 通ったのに 今回 通らない ことは ふつうに ある。
  そのときは **環境の ネットワーク設定で `dl.google.com` を 許可してもらう**。
  ユーザに そう 伝える(「できません」で 終わらせない)。
- `maven.google.com` も 中身は dl.google.com へ 飛ぶので 代わりに ならない。
- 通る ことが 分かっている 先: `github.com` / `repo1.maven.org` / `services.gradle.org`。

**しらべた 結果(2026-09 時点)― 迂回は できない:**

| ほしい もの | どこから | 通るか |
|---|---|---|
| Godot 本体・書き出しテンプレート | github.com | ○ |
| Android Gradle Plugin | repo1.maven.org(Maven Central にも ある) | ○ |
| gradle 本体 | services.gradle.org | ○ |
| **Android SDK(android.jar API 36・aapt2・d8・build-tools)** | **dl.google.com だけ** | **×** |

Ubuntu の apt にも Android の パッケージは あるが、
`android-sdk-platform-23`(API 23)止まりで、`aapt2` と `d8` は 候補すら 無い。
このプロジェクトは compileSdk 36 なので **足りない**。
→ **`dl.google.com` を 開けてもらう しか ない。**

### (b) 書き出しコマンドの 実行を 許可されているか

`--export-release` と `--install-android-build-template` は
auto モードの 分類器に 止められる ことが ある。止められたら
**ユーザに 許可を もらう**(settings の Bash permission rule)。
黙って 別の やり方を 探さない。

### (c) 署名鍵 ― 場所は 決まっている

**さがし回らない。`store/署名鍵の作り方.md` に 書いてある。**

| | |
|---|---|
| 置き場所 | `G:\その他のパソコン\マイ ノートパソコン\Others\snaplace\game\keys kakudomenseki\kakudomenseki-release.keystore` |
| alias | `kakudomenseki` |
| 形式 | PKCS12(keystore と 鍵の パスワードは 同じ) |
| パスワード | 同じ フォルダの `keystorePASS.txt`(無ければ `pass.txt`) |

**ユーザの Windows の G: ドライブに ある。** リポジトリの 中にも、
コンテナの 中にも 無い(`store/署名鍵の作り方.md` に
「リポジトリの外なのでコミットされません」と 明記)。
探しても 出てこないので、**コンテナで 署名するなら
ファイルと パスワードを 渡してもらう**。それだけ 頼めば よい。

Godot は 環境変数から 読むので `export_presets.cfg` に 書かない:

```bash
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=<.keystore の場所>
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=<alias>
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=<パスワード>
```

`alias` は 鍵の 中に ある。`keytool -list -v -keystore <鍵>` で 読める
(名前を 思いこみで 決めない ― 実際に 落ちた)。

手元の 確認だけなら デバッグ鍵でも よいが、**Play には 出せない**。

---

## 2. コンテナで 書き出す

### 用意するもの

```bash
SP=<作業用の場所>
# Godot 本体(プロジェクトと 同じ 版。project.godot の config/features を見る)
curl -fsSL -o "$SP/godot.zip" \
  https://github.com/godotengine/godot/releases/download/4.7.1-stable/Godot_v4.7.1-stable_linux.x86_64.zip
unzip -q -o "$SP/godot.zip" -d "$SP" && chmod +x "$SP"/Godot_v4.7.1-stable_linux.x86_64

# 書き出しテンプレート(約 1.2GB)
curl -fsSL -o "$SP/tpz.tpz" \
  https://github.com/godotengine/godot/releases/download/4.7.1-stable/Godot_v4.7.1-stable_export_templates.tpz
mkdir -p "$SP/tpl" && (cd "$SP/tpl" && unzip -q -o ../tpz.tpz)
TD=~/.local/share/godot/export_templates/4.7.1.stable
mkdir -p "$TD" && cp -r "$SP/tpl/templates/." "$TD/"
```

### ★ android/build を 手で 用意する(いちばん 忘れる ところ)

`--install-android-build-template` が 使えない ときは 手で 展開する。
**うめしわ(`skabashima/umeshiwa`)の README_BUILD.md に 書いてある やり方。**

```bash
mkdir -p android/build
python3 -c "import zipfile;zipfile.ZipFile('$TD/android_source.zip').extractall('android/build')"
touch android/build/.gdignore          # ★これが 最重要
cp "$TD/version.txt" android/.build_version
```

- **`.gdignore` が 無いと 詰む。** Godot が `android/build` を プロジェクトの 一部として
  走査し、書き出すたびに アセットを コピー → 次回 それも 走査 … と 入れ子に 増える。
  パスが 二重三重に 伸びた エラーで 出る。
- `android/.build_version` は テンプレの 版。エンジンと 食いちがうと 拒まれる。
- `/android/` と `build/` は `.gitignore` 済み(`libs/` だけで 200MB 超)。

### Android SDK

`compileSdk` / `targetSdk` は `android/build/config.gradle` に ある(いまは 36)。
cmdline-tools を 入れて、`platforms;android-36` と `build-tools` と `platform-tools` を 入れる。
入れたら Godot の エディタ設定に SDK の 場所を 書く
(`export/android/android_sdk_path`)。区切りは `/` に 揃える ―
`\` と `/` が 混ざると **リリース書き出しだけ** が 落ちる(デバッグは 通るので 気づきにくい)。

### 書き出し

```bash
"$SP/Godot_v4.7.1-stable_linux.x86_64" --headless --path . --import
"$SP/Godot_v4.7.1-stable_linux.x86_64" --headless --path . \
  --export-release "Android" "$PWD/build/android/kakudomenseki.aab"
```

- **終了コードを 信用しない。** Godot 4.7 の headless export は、正しい AAB が
  出ていても 0 以外(255 など)を 返す。**生成物の 有無で 判定する。**
- gradle が 走るので 10〜15 分 かかる。途中で 止めない(尻切れの AAB が のこる)。

---

## 3. Windows(手元)で 書き出す

```powershell
powershell -ExecutionPolicy Bypass -File "tools\build_aab.ps1"
```

出力: `build/android/kakudomenseki.aab`(そのまま Play Console へ)

- `-DebugSign` … デバッグ鍵で 署名(Play には 出せない)
- `-VerifyOnly` … すでに ある AAB を 検めるだけ
- `-Bump` … `version/code` を +1 してから 書き出す

スクリプトが やること: 版の 突き合わせ → SDK 探し と パス直し →
鍵と パスワードを 環境変数へ → `--import` → `--export-release` → 検品。

---

## 4. 版を 上げる(書き出す 前に)

| ファイル | 項目 | 備考 |
|---|---|---|
| `export_presets.cfg` | `application/short_version` | App Store の 版と そろえる |
| `export_presets.cfg` | `application/version` | iOS は CI が 差し替える |
| `export_presets.cfg` | `version/name` (Android) | 上と 同じ 番号に |
| `export_presets.cfg` | `version/code` (Android) | **上げるたび +1** |
| `store/リリースノート.md` | その版の 節 | 貼り文と 社内用の 記録 |
| `store/APPSTORE.md` | バージョン | |
| `store/ストア掲載情報.md` | versionCode / versionName | まだ 書き出していない なら チェックを 外す |

**`version/code` は 毎回 +1。** 同じ code は Play に 弾かれる
(「バージョンコード 1 はすでに使用されています」で 実際に 弾かれた)。

版を 上げたら `python store/check_store_text.py` を 通す。

---

## 5. 書き出したら 必ず 検品する

設定ファイルを 見るだけでは 足りない。プリセットの 上書きや 古い テンプレの
混入は **成果物にしか 出ない**。

```bash
python store/check_aab.py build/android/kakudomenseki.aab
```

見るところ: 壊れていないか / パッケージ名・versionCode / **課金の BILLING 権限** /
**16KB ページ対応**(align) / 余計な 同梱物 / 大きさ。

課金プラグインが 本当に 入っているかは dex を 見る のが 確実:

```python
import zipfile
z = zipfile.ZipFile("build/android/kakudomenseki.aab")
dex = b"".join(z.read(n) for n in z.namelist() if n.endswith(".dex"))
assert dex.find(b"com/android/billingclient") >= 0
```

**リリース鍵で 署名されているか** も 見る(指紋を keystore と 突き合わせる)。
`build_aab.ps1` は そこまで やる。

---

## 6. 出す前の 通し(手元で 全部 通してから)

CI(Codemagic)は **iOS の ビルドだけ**。テストは 載せていない(ビルド分が 課金される)。
push する前に 手元で 通す。

```bash
G=<godot>
for t in explain_check kid_check kid_touch story_play gen_check calc_check \
         play_check smoke iap_gate review_check daily_check power_check island_check; do
  "$G" --headless --path . res://tests/$t.tscn
done
for t in consistency_check story_check ruby_check walkthrough_check font_check; do
  "$G" --headless --path . -s tests/$t.gd
done
python store/check_store_text.py
```

---

## 7. 忘れやすい ことの まとめ

0. **`store/署名鍵の作り方.md` と `tools/README_BUILD.md` を 先に 読む。**
   鍵の 場所も 手順も そこに 書いてある。ファイルシステムを 探し回って
   「見つかりません」と 言うのは 時間の むだ。実際に それを やって 叱られた。
1. **コンテナでも 書き出せる。**「鍵が 無いから 無理」で 止めない ―
   足りないのは 鍵・egress・実行許可の どれかで、どれも ユーザに 頼めば 済む。
   頼む ときは **何が どれだけ 要るかを 1 回で 言う**(小出しに しない)。
2. `android/build/.gdignore` を 置く。
3. 終了コードでは 判定しない。生成物を 見る。
4. `version/code` を +1。
5. 書き出したら `check_aab.py` を 通す。
6. `dl.google.com` が 403 なら 迂回しない。**許可を 頼む。**
