param(
  [Parameter(Mandatory = $true)]
  [string]$AppPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$labels = @{
  pulse_puzzle = '펄스 퍼즐'
  pixel_slim = '픽셀 슬림'
  docu_snap = '도큐 스냅'
  daily_quiz = '데일리 퀴즈'
}

$root = (Resolve-Path $AppPath).Path
$appName = Split-Path $root -Leaf
if (-not $labels.ContainsKey($appName)) {
  throw "Unknown AppStudio application: $appName"
}

$gradle = Join-Path $root 'android\app\build.gradle.kts'
if (-not (Test-Path $gradle)) {
  $gradle = Join-Path $root 'android\app\build.gradle'
}
if (-not (Test-Path $gradle)) {
  throw "Android project is not generated yet for $appName"
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
$gradleText = [System.IO.File]::ReadAllText($gradle)
$replacements = @(
  @('compileSdk = flutter.compileSdkVersion', 'compileSdk = 36'),
  @('targetSdk = flutter.targetSdkVersion', 'targetSdk = 36'),
  @('minSdk = flutter.minSdkVersion', 'minSdk = 24'),
  @('compileSdkVersion flutter.compileSdkVersion', 'compileSdkVersion 36'),
  @('targetSdkVersion flutter.targetSdkVersion', 'targetSdkVersion 36'),
  @('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 24')
)
foreach ($pair in $replacements) {
  $gradleText = $gradleText.Replace($pair[0], $pair[1])
}
[System.IO.File]::WriteAllText($gradle, $gradleText, $utf8)

$manifest = Join-Path $root 'android\app\src\main\AndroidManifest.xml'
if (Test-Path $manifest) {
  $content = [System.IO.File]::ReadAllText($manifest)
  $content = $content.Replace('android:label="' + $appName + '"', 'android:label="' + $labels[$appName] + '"')
  [System.IO.File]::WriteAllText($manifest, $content, $utf8)
}

$generatedTest = Join-Path $root 'test\widget_test.dart'
if (Test-Path $generatedTest) {
  $content = [System.IO.File]::ReadAllText($generatedTest)
  if ($content.Contains('await tester.pumpWidget(const MyApp());')) {
    Remove-Item $generatedTest -Force
  }
}

Write-Host "[END] patch-android $appName (API 36; PowerShell; no Python dependency)"
