param(
  [ValidateSet('all', 'privacy_mosaic', 'pixel_slim', 'docu_snap', 'shift_pay')]
  [string]$App = 'all'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$allApps = @('privacy_mosaic', 'pixel_slim', 'docu_snap', 'shift_pay')
$selected = if ($App -eq 'all') { $allApps } else { @($App) }
$outputRoot = Join-Path $repoRoot 'appstudio-apks'
$symbolsRoot = Join-Path $repoRoot 'appstudio-symbols'
$oldDebugMiB = @{ privacy_mosaic = 200.02; shift_pay = 140.56; pixel_slim = 143.64; docu_snap = 175.23 }
$sizeReport = New-Object 'System.Collections.Generic.List[string]'
[void]$sizeReport.Add('App,ABI,ReleaseMiB,PreviousDebugMiB,ReductionPercent')

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'flutter not found in the runner service PATH. Configure Flutter SDK for this Windows service account and restart the AppStudio runner service only.'
}

function Invoke-Checked {
  param([string]$Executable, [string[]]$ArgList)
  & $Executable @ArgList
  if ($LASTEXITCODE -ne 0) {
    throw ("Command failed: " + $Executable + " " + ($ArgList -join ' ') + " (code " + $LASTEXITCODE + ")")
  }
}

if (Test-Path $outputRoot) {
  Remove-Item $outputRoot -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null
if (Test-Path $symbolsRoot) { Remove-Item $symbolsRoot -Recurse -Force }
New-Item -ItemType Directory -Force -Path $symbolsRoot | Out-Null

foreach ($name in $selected) {
  $started = Get-Date
  Write-Host "[START] build-app $name"
  $appPath = Join-Path $repoRoot "apps\$name"
  if (-not (Test-Path $appPath)) { throw "App directory missing: $appPath" }

  Push-Location $appPath
  try {
    Invoke-Checked -Executable 'flutter' -ArgList @(
      'create', '--platforms=android', '--org=com.uikstudio', "--project-name=$name", '--no-pub', '.'
    )
    & (Join-Path $repoRoot 'scripts\windows\patch-android.ps1') -AppPath $appPath
    Invoke-Checked -Executable 'flutter' -ArgList @('clean')
    Invoke-Checked -Executable 'flutter' -ArgList @('pub', 'get')
    if ($name -eq 'privacy_mosaic' -or $name -eq 'shift_pay') {
      Invoke-Checked -Executable 'dart' -ArgList @('run', 'tool/generate_icon.dart', $name)
    }
    Invoke-Checked -Executable 'dart' -ArgList @('run', 'flutter_launcher_icons')
    $launcher = Join-Path $appPath 'android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png'
    if (-not (Test-Path -LiteralPath $launcher)) { throw "Launcher PNG not generated: $launcher" }
    Write-Host "[ICON] generated $name launcher resources ($((Get-Item -LiteralPath $launcher).Length) bytes)"
    Invoke-Checked -Executable 'flutter' -ArgList @('analyze')
    Invoke-Checked -Executable 'flutter' -ArgList @('test')
    $symbolDir = Join-Path $symbolsRoot $name
    New-Item -ItemType Directory -Path $symbolDir -Force | Out-Null
    Invoke-Checked -Executable 'flutter' -ArgList @(
      'build', 'apk', '--release', '--target-platform=android-arm64',
      '--obfuscate', "--split-debug-info=$symbolDir", '--tree-shake-icons'
    )
    $sourceApk = Join-Path $appPath 'build\app\outputs\flutter-apk\app-release.apk'
    if (-not (Test-Path -LiteralPath $sourceApk)) { throw "Release APK missing: $sourceApk" }
    $symbols = @(Get-ChildItem -LiteralPath $symbolDir -File -Recurse -ErrorAction SilentlyContinue)
    if ($symbols.Count -eq 0) { throw "Missing AOT symbol mapping: $symbolDir" }
    $targetApk = Join-Path $outputRoot "$name-arm64-release.apk"
    Copy-Item -LiteralPath $sourceApk -Destination $targetApk -Force
    $buildTools = Join-Path $env:ANDROID_HOME 'build-tools'
    $signer = Get-ChildItem -LiteralPath $buildTools -Directory -ErrorAction Stop |
      Sort-Object Name -Descending |
      ForEach-Object { Join-Path $_.FullName 'apksigner.bat' } |
      Where-Object { Test-Path -LiteralPath $_ } |
      Select-Object -First 1
    if (-not $signer) { throw 'apksigner not found in Android SDK build-tools' }
    Invoke-Checked -Executable $signer -ArgList @('verify', '--verbose', $targetApk)
    $sizeMiB = [math]::Round((Get-Item -LiteralPath $targetApk).Length / 1MB, 2)
    $baseline = [double]$oldDebugMiB[$name]
    $reduction = [math]::Round((1 - $sizeMiB / $baseline) * 100, 1)
    [void]$sizeReport.Add(("{0},{1},{2:F2},{3:F2},{4:F1}" -f
      $name, 'arm64-v8a', $sizeMiB, $baseline, $reduction))
    $elapsed = [math]::Round(((Get-Date) - $started).TotalMilliseconds)
    Write-Host "[SIZE] $name debug $baseline MiB => arm64 release $sizeMiB MiB ($reduction% smaller)"
    Write-Host "[END] build-app $name => $targetApk ($sizeMiB MiB, $elapsed ms)"
  }
  finally {
    Pop-Location
  }
}
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllLines((Join-Path $outputRoot 'size-report.csv'), $sizeReport, $utf8)
Write-Host '[END] ARM64 release APKs, size report and external symbols generated'
