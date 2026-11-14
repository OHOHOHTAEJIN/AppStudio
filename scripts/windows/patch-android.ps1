param(
  [Parameter(Mandatory = $true)]
  [string]$AppPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Pure ASCII source for Windows PowerShell 5.1. Decode Korean labels at runtime.
$labelCodepoints = @{
  pulse_puzzle = @(0xD384, 0xC2A4, 0x20, 0xD37C, 0xC990)
  pixel_slim = @(0xD53D, 0xC140, 0x20, 0xC2AC, 0xB9BC)
  docu_snap = @(0xB3C4, 0xD050, 0x20, 0xC2A4, 0xB0C5)
  daily_quiz = @(0xB370, 0xC77C, 0xB9AC, 0x20, 0xD034, 0xC988)
}

$root = (Resolve-Path $AppPath).Path
$appName = Split-Path $root -Leaf
if (-not $labelCodepoints.ContainsKey($appName)) {
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
$label = -join ($labelCodepoints[$appName] | ForEach-Object { [char]$_ })
$valuesDir = Join-Path $root 'android\app\src\main\res\values'
if (-not (Test-Path $valuesDir)) { New-Item -ItemType Directory -Path $valuesDir -Force | Out-Null }
$xmlLabel = [System.Security.SecurityElement]::Escape($label)
$stringsXml = '<?xml version="1.0" encoding="utf-8"?>' +
    '<resources><string name="app_name">' + $xmlLabel + '</string></resources>'
[System.IO.File]::WriteAllText((Join-Path $valuesDir 'strings.xml'), $stringsXml, $utf8)

if (Test-Path $manifest) {
  $content = [System.IO.File]::ReadAllText($manifest)
  $content = [regex]::Replace($content, 'android:label="[^"]+"', 'android:label="@string/app_name"', 1)
  [System.IO.File]::WriteAllText($manifest, $content, $utf8)
}

# Prevent invalid incremental state when Kotlin dependency sources are reused.
$gradleProperties = Join-Path $root 'android\gradle.properties'
if (Test-Path $gradleProperties) {
  $propertiesContent = [System.IO.File]::ReadAllText($gradleProperties)
  if ($propertiesContent -notmatch '(?m)^kotlin\.incremental=') {
    $propertiesContent += [Environment]::NewLine + 'kotlin.incremental=false' + [Environment]::NewLine
    [System.IO.File]::WriteAllText($gradleProperties, $propertiesContent, $utf8)
  }
}

$generatedTest = Join-Path $root 'test\widget_test.dart'
if (Test-Path $generatedTest) {
  $content = [System.IO.File]::ReadAllText($generatedTest)
  if ($content.Contains('await tester.pumpWidget(const MyApp());')) {
    Remove-Item $generatedTest -Force
  }
}

Write-Host "[END] patch-android $appName (API 36; PowerShell; no Python dependency)"
