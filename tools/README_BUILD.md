# Android の書き出し(図形ハンター)

fumi(kobungame)と同じ運用にしてある。踏んだ落とし穴もそこと同じなので、ここに残す。

## 普段の手順

```powershell
powershell -ExecutionPolicy Bypass -File "tools\build_aab.ps1"
```

出力: `build/android/kakudomenseki.aab`(このまま Play Console にアップロードできる)

- 手元の確認だけなら `-DebugSign`(デバッグ鍵で署名。Play には出せない)
- すでにある AAB を検めるだけなら `-VerifyOnly`

**gradle が走るので 10〜15 分かかる。** 途中で止めないこと(尻切れの AAB が残る)。

## スクリプトがやること

1. `android/.build_version` とエディタの版が一致するか確認(食い違ったら中止)
2. Android SDK を見つけ、エディタ設定の `android_sdk_path` の区切り文字を `/` に揃える
3. `..\keys kakudomenseki\keystorePASS.txt` を読み、keystore の alias を自動で判別して
   `GODOT_ANDROID_KEYSTORE_RELEASE_*` に渡す
4. `--import` → `--export-release "Android"`
5. 検め ― 破損 / 16KB ページ / targetSdk / パッケージ名 / 余計な同梱物 /
   **リリース鍵で署名されているか(指紋を keystore と突き合わせる)** / 日本語フォントの同梱

## 引っかかった点

- **終了コードを信用しない。** Godot 4.7 の headless export は、正しい AAB が出ていても
  0 以外(255 など)を返す。**生成物の有無で判定する。**
- **パスワードを cfg に書かない。** `export_presets.cfg` に keystore 欄は空のままでよく、
  環境変数だけで署名される。鍵とパスワードはリポジトリの外(`game\keys kakudomenseki\`)。
- **エディタ設定の SDK パスに `\` と `/` が混ざると、リリース書き出しだけが落ちる**
  (「platform-tools がありません」)。デバッグは通るので気づきにくい。毎回直している。
- **エディタ設定を PowerShell で書き換えるときは UTF-8(BOM 無し)で。**
  `Get-Content` / `Set-Content` の既定は ANSI なので、設定内の日本語パスが壊れて
  Godot が「設定を読み込めません」になる。`[IO.File]::ReadAllLines/WriteAllLines` を使う。
- **`--install-android-build-template` は単独では効かない。** export と併用するか、
  `%APPDATA%\Godot\export_templates\4.7.stable\android_source.zip` を `android\build` へ
  手で展開して `android\.build_version` に版を書く。
- **このスクリプトは UTF-8 BOM 付きで保存する**(PowerShell 5.1 は BOM が無いと日本語が化ける)。

## アップロード前に

- **versionCode を毎回 +1** する(同じ code は Play に弾かれる。実際に
  「バージョンコード 1 はすでに使用されています」で弾かれた)。
  `tools/build_aab.ps1 -Bump` を付けると `export_presets.cfg` の
  `version/code` を +1 してから書き出す。付けないときは現在値を表示するだけ。
  書き出した AAB の実際の値は `python store/check_aab.py <aab>` が出す。
- 確認済みの値(2026-08-20 / **リリース鍵で署名した AAB**・versionCode 2):
  `build/android/kakudomenseki.aab` 59.9 MB /
  パッケージ `jp.snaplace.kakudomenseki` / targetSdk 36 / minSdk 24 / versionCode 2 /
  16KB ページ OK(arm64・armeabi-v7a とも align=16384) / **BILLING 権限あり** /
  **リリース鍵で署名済み**(AAB の証明書 SHA256 が keystore と一致) /
  日本語フォント同梱 / ストア用画像・テスト・iOS のフレームワークは同梱なし。
  デバッグ鍵版(`kakudomenseki-debug.aab` 65.3 MB)も同じ検品を通っている。

## 書き出しが終わっても godot が終了しないことがある

4.7-stable で、export 自体は完了して AAB も正しく出ているのに、
`Godot_v4.7-stable_win64_console.exe` のプロセスが終了せず居座ることがある
(実際に40分待たされた)。`& $godot ...` で呼ぶと永久に返らない。

そのため書き出しは `Start-Process` で起こし、**生成物のサイズが30秒変化しなければ
完了と見なして終了させる**ようにしてある。ログは `%TEMP%\kakudomenseki_export.log`。

手で叩いていて止まったときは、生成物が出来ていれば残っている godot プロセスを
終わらせてよい。判定は `-VerifyOnly` で改めて行える。
