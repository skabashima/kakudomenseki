# Android の AAB(Play にあげる形)を書き出す。fumi / Structura と同じ運用。
#
#   powershell -ExecutionPolicy Bypass -File tools/build_aab.ps1              ← 署名済みリリース版
#   powershell -ExecutionPolicy Bypass -File tools/build_aab.ps1 -DebugSign   ← デバッグ鍵(手元の確認用)
#   powershell -ExecutionPolicy Bypass -File tools/build_aab.ps1 -Bump        ← versionCode を +1 してから書き出す
#
# 署名鍵はリポジトリの外に置いてある。ここには置かないこと。
#   ..\keys kakudomenseki\kakudomenseki-release.keystore
#   ..\keys kakudomenseki\keystorePASS.txt   (無ければ pass.txt)
# Godot は環境変数から鍵を読める(export_presets.cfg にパスワードを書かずに済む)。
#
# 注意(PowerShell 5.1): このファイルは UTF-8 BOM 付きで保存すること。

# -VerifyOnly … 書き出しを飛ばして、すでにある AAB の検めだけを行う
param([switch]$DebugSign, [switch]$VerifyOnly, [switch]$Bump)

$proj  = Split-Path -Parent $PSScriptRoot
$games = Split-Path -Parent $proj
$out   = Join-Path $proj "build\android"
$godot = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"

if (-not (Test-Path $godot)) { Write-Host "Godot 4.7 が見つかりません"; exit 1 }

Write-Host "-- 版 --"
$bv = Join-Path $proj "android\.build_version"
if (-not (Test-Path $bv)) {
    Write-Host "x android/build/ がありません。"
    Write-Host "  エディタの プロジェクト → ツール → Android ビルドテンプレートをインストール"
    Write-Host "  または: godot --headless --path <proj> --install-android-build-template --export-debug ""Android"" <出力>.aab"
    exit 1
}
$tv = (Get-Content $bv -Raw).Trim()
$ev = ((& $godot --version) -replace '\.official.*$', '').Trim()
if ($tv -ne $ev) {
    Write-Host "x ビルドテンプレートが $tv、エディタが $ev。食い違っています。"
    exit 1
}
Write-Host "   o エディタもビルドテンプレートも $ev"

# -- Android SDK --
# エディタ設定のパスに区切り文字が混在していると platform-tools / build-tools を
# 見失い、リリース書き出しだけが落ちる(デバッグは通るので気づきにくい)。毎回直す。
Write-Host "-- Android SDK --"
$settings = Join-Path $env:APPDATA "Godot\editor_settings-4.7.tres"
$sdk = ""
foreach ($cand in @((Join-Path $env:LOCALAPPDATA "Android\Sdk"), $env:ANDROID_SDK_ROOT, $env:ANDROID_HOME, "C:\Android\Sdk")) {
    if ($cand -and (Test-Path (Join-Path $cand "platform-tools")) -and (Test-Path (Join-Path $cand "build-tools"))) {
        $sdk = $cand.Replace("\", "/")
        break
    }
}
if ($sdk -eq "") {
    Write-Host "x Android SDK が見つかりません。探した場所:"
    foreach ($cand in @((Join-Path $env:LOCALAPPDATA "Android\Sdk"), $env:ANDROID_SDK_ROOT, $env:ANDROID_HOME, "C:\Android\Sdk")) {
        if ($cand) { Write-Host ("   " + $cand + "  -> " + (Test-Path $cand)) }
    }
    Write-Host "  Android Studio の SDK Manager で platform-tools と build-tools を入れてください。"
    exit 1
}
Write-Host "   o SDK: $sdk"
if (Test-Path $settings) {
    # 読み書きは UTF-8(BOM 無し)。PowerShell 5.1 の Get-Content/Set-Content は既定が
    # ANSI で、設定内の日本語が壊れて Godot が設定を読めなくなる。
    $utf8 = New-Object Text.UTF8Encoding $false
    $lines = @([IO.File]::ReadAllLines($settings, $utf8))
    $cur = ($lines | Where-Object { $_ -like "export/android/android_sdk_path*" })
    $want = 'export/android/android_sdk_path = "' + $sdk + '"'
    if ($cur -ne $want) {
        Copy-Item $settings "$settings.bak" -Force
        $new = foreach ($l in $lines) {
            if ($l -like "export/android/android_sdk_path*") { $want }
            elseif ($l -eq "[resource]" -and -not $cur) { $l; $want }
            else { $l }
        }
        [IO.File]::WriteAllLines($settings, [string[]]$new, $utf8)
        Write-Host "   o エディタ設定の SDK パスを直しました(元は .bak)"
    }
}

# -- versionCode --
# Play は同じ versionCode を受け付けない
# (「バージョンコード 1 はすでに使用されています」で弾かれる)。
Write-Host "-- versionCode --"
$presets = Join-Path $proj "export_presets.cfg"
$u8 = New-Object Text.UTF8Encoding $false
$plines = @([IO.File]::ReadAllLines($presets, $u8))
$cur = ($plines | Where-Object { $_ -like "version/code=*" } | Select-Object -First 1)
$code = 0
if ($cur) { $code = [int]($cur -replace "version/code=", "") }
if ($Bump -and -not $VerifyOnly) {
    $code = $code + 1
    $new = foreach ($l in $plines) {
        if ($l -like "version/code=*") { "version/code=$code" } else { $l }
    }
    [IO.File]::WriteAllLines($presets, [string[]]$new, $u8)
    Write-Host "   o versionCode を $code に上げた(export_presets.cfg を書き換え)"
} else {
    Write-Host "   o versionCode = $code  ※上げるには -Bump を付ける"
}

# -- 署名鍵 --
$ks = Join-Path $games "keys kakudomenseki\kakudomenseki-release.keystore"
$alias = ""
if (-not $DebugSign) {
    Write-Host "-- 署名鍵 --"
    $pf = ""
    foreach ($n in @("keystorePASS.txt", "pass.txt")) {
        $p = Join-Path $games ("keys kakudomenseki\" + $n)
        if (Test-Path $p) { $pf = $p; break }
    }
    if (-not (Test-Path $ks) -or $pf -eq "") {
        Write-Host "x 署名鍵かパスワードのファイルがありません:"
        Write-Host "   $ks"
        Write-Host "   ..\keys kakudomenseki\keystorePASS.txt (または pass.txt)"
        Write-Host "  手元の確認だけなら -DebugSign を付けてください。"
        exit 1
    }
    # BOM は ReadAllText が落としてくれる(Get-Content -Raw だと残って照合に失敗する)
    $raw = [IO.File]::ReadAllText($pf)
    # 「パスワード: xxx」のような書き方でも拾えるように候補をいくつか試す
    $cands = @($raw.Trim())
    foreach ($l in ($raw -split "`r?`n")) {
        $t = $l.Trim()
        if ($t -eq "") { continue }
        $cands += $t
        if ($t -match "[:：]\s*(\S.*)$") { $cands += $Matches[1].Trim() }
    }
    $keytool = Join-Path $env:ProgramFiles "Eclipse Adoptium\jdk-17.0.19.10-hotspot\bin\keytool.exe"
    if (-not (Test-Path $keytool) -and $env:JAVA_HOME) { $keytool = Join-Path $env:JAVA_HOME "bin\keytool.exe" }
    # 鍵の中の alias を自動で読む(名前を間違えて落ちるのを防ぐ)
    $pw = ""
    $list = ""
    foreach ($c in ($cands | Select-Object -Unique)) {
        $list = (& $keytool -list -keystore $ks -storepass $c 2>&1) -join "`n"
        if ($list -match "(?m)^([^,\r\n]+),[^,]*,\s*PrivateKeyEntry") {
            $alias = $Matches[1].Trim()
            $pw = $c
            break
        }
    }
    if ($alias -eq "") {
        Write-Host "x 鍵を開けませんでした($pf のパスワードが合いません)"
        Write-Host $list
        exit 1
    }
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = $ks
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = $alias
    $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $pw
    Write-Host "   o リリース鍵を環境変数で渡す(cfg には書かない) alias=$alias"
}

New-Item -ItemType Directory -Force -Path $out | Out-Null
$name = "kakudomenseki.aab"
if ($DebugSign) { $name = "kakudomenseki-debug.aab" }
$aab = Join-Path $out $name

if (-not $VerifyOnly) {
    # 前回の生成物を「成功」と誤認しないよう、先に消す
    Remove-Item $aab -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "-- 書き出し(gradle が走るので10〜15分かかる) --"
    $log = Join-Path $env:TEMP "kakudomenseki_export.log"
    Remove-Item $log -Force -ErrorAction SilentlyContinue

    # ★ 書き出しが終わっても godot のコンソールプロセスが終了せず、居座ることがある
    #   (4.7-stable で実際に40分待たされた)。& で呼ぶと永久に返らないので、
    #   別プロセスで起こして「生成物が増えなくなったら完了」と判定して終わらせる。
    # ★ パスに空白が入る(「マイ ノートパソコン」)。Start-Process の -ArgumentList は
    #   配列を空白で連結するだけで引用符を付けないため、そのまま渡すと途中で切れて
    #   「Invalid project path specified」で落ちる。各引数を自分でくくる。
    $mode = if ($DebugSign) { "--export-debug" } else { "--export-release" }
    $pargs = @("--headless", "--path", ('"' + $proj + '"'), $mode, "Android", ('"' + $aab + '"'))
    $p = Start-Process -FilePath $godot -ArgumentList $pargs -PassThru -NoNewWindow `
         -RedirectStandardOutput $log -RedirectStandardError "$log.err"

    $waited = 0
    $stable = 0
    $last = -1
    while ($waited -lt 2400) {           # 上限40分
        Start-Sleep -Seconds 5
        $waited += 5
        if ($p.HasExited) { break }
        if (Test-Path $aab) {
            $sz = (Get-Item $aab).Length
            if ($sz -gt 0 -and $sz -eq $last) { $stable += 5 } else { $stable = 0 }
            $last = $sz
            if ($stable -ge 30) {        # 30秒変化なし＝書き終わっている
                Write-Host "   ※ 生成物が安定したので godot を終了させる(居座り対策)"
                Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
                break
            }
        }
        if ($waited % 60 -eq 0) { Write-Host ("   ... {0}分経過" -f ($waited / 60)) }
    }
    if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }

    if (Test-Path $log) { Get-Content $log -Tail 12 -ErrorAction SilentlyContinue }
    # ★ Godot の headless export は、成果物が正しく出ていても 0 以外を返すことがある
    #   (4.7-stable で確認)。終了コードではなく生成物の有無で判定する。
    if (-not (Test-Path $aab)) {
        Write-Host "x AAB が生成されませんでした。$log を確認してください。"
        if (Test-Path "$log.err") { Get-Content "$log.err" -Tail 20 }
        exit 1
    }
} else {
    if (-not (Test-Path $aab)) { Write-Host "x $aab がありません"; exit 1 }
    Write-Host ""
    Write-Host "-- 書き出しは飛ばす(-VerifyOnly) --"
}
$f = Get-Item $aab
Write-Host ("   o {0}  {1:N1} MB  {2}" -f $f.Name, ($f.Length / 1MB), $f.LastWriteTime)

Write-Host ""
Write-Host "-- 中身の検め --"
python (Join-Path $proj "store\check_aab.py") $aab
$ng = 0
if ($LASTEXITCODE -ne 0) { $ng++ }

# 署名。デバッグ鍵のまま出していないかを指紋で突き合わせる
$keytool = Join-Path $env:ProgramFiles "Eclipse Adoptium\jdk-17.0.19.10-hotspot\bin\keytool.exe"
if (-not (Test-Path $keytool) -and $env:JAVA_HOME) { $keytool = Join-Path $env:JAVA_HOME "bin\keytool.exe" }
$cert = (& $keytool -printcert -jarfile $aab 2>&1) -join "`n"
if ($cert -match "SHA256:\s*([0-9A-Fa-f:]+)") {
    $fp = $Matches[1]
    if (-not $DebugSign) {
        $want = ((& $keytool -list -v -keystore $ks -storepass $env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD) -join "`n")
        if ($want -match "SHA256:\s*([0-9A-Fa-f:]+)" -and $Matches[1] -eq $fp) {
            Write-Host "   o リリース鍵で署名されている"
        } else {
            Write-Host "   x 署名が別の鍵になっている(デバッグ鍵のまま出ていないか)"
            $ng++
        }
    } else {
        Write-Host "   o 署名あり(デバッグ鍵)"
    }
} else {
    Write-Host "   x 署名されていない"
    $ng++
}

# フォントが同梱されているか(抜けると端末で書体が化ける)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [System.IO.Compression.ZipFile]::OpenRead($aab)
$names = $z.Entries.FullName
$z.Dispose()
if ($names -match "NotoSansJP") {
    Write-Host "   o 日本語フォントが同梱されている"
} else {
    Write-Host "   x 日本語フォントが入っていない"
    $ng++
}

$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = $null
Write-Host ""
if ($ng -eq 0) {
    Write-Host "完成: $aab"
    Write-Host "Play Console にアップロードできます(version/code は毎回 +1 すること)。"
} else {
    Write-Host "★ $ng 件の問題があります。上を確認してください。"
    exit 1
}
