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
  privacy_mosaic = @(0xBAA8, 0xC790, 0xC774, 0xD06C, 0x20, 0xAC00, 0xB4DC)
  shift_pay = @(0xADFC, 0xBB34, 0xD398, 0xC774)
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
# The Korean OCR model is required in addition to the Flutter ML Kit wrapper.
if ($appName -eq 'docu_snap' -or $appName -eq 'privacy_mosaic') {
  $ocr = 'com.google.mlkit:text-recognition-korean:16.0.1'
  if (-not $gradleText.Contains($ocr)) {
    if ($gradle.EndsWith('.kts')) {
      $gradleText += [Environment]::NewLine + 'dependencies {' +
          [Environment]::NewLine + '    implementation("' + $ocr + '")' +
          [Environment]::NewLine + '}' + [Environment]::NewLine
    } else {
      $gradleText += [Environment]::NewLine + 'dependencies {' +
          [Environment]::NewLine + "    implementation '" + $ocr + "'" +
          [Environment]::NewLine + '}' + [Environment]::NewLine
    }
  }
}
# Explicit Android shrinker settings; the release build also enables Flutter's R8.
if ($gradle.EndsWith('.kts')) {
  $signing = 'signingConfig = signingConfigs.getByName("debug")'
  if ($gradleText.Contains($signing) -and -not $gradleText.Contains('isShrinkResources = true')) {
    $gradleText = $gradleText.Replace($signing,
      'isMinifyEnabled = true' + [Environment]::NewLine +
      '            isShrinkResources = true' + [Environment]::NewLine +
      '            ' + $signing)
  }
} else {
  $signing = 'signingConfig signingConfigs.debug'
  if ($gradleText.Contains($signing) -and -not $gradleText.Contains('shrinkResources true')) {
    $gradleText = $gradleText.Replace($signing,
      'minifyEnabled true' + [Environment]::NewLine +
      '            shrinkResources true' + [Environment]::NewLine +
      '            ' + $signing)
  }
}
# google_mlkit_text_recognition exposes optional script APIs, but our apps
# package Latin and Korean models only. Do not add huge unused OCR models.
# Tell R8 that references to unused optional language implementations are safe
# to ignore, while retaining full shrinking for actual packaged classes.
if ($appName -eq 'privacy_mosaic' -or $appName -eq 'docu_snap') {
  $rulesPath = Join-Path $root 'android\app\proguard-rules.pro'
  $rulesContent = @'
# Optional ML Kit language implementations are not packaged.
# The applications only request Latin or Korean text recognition.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
'@
  [System.IO.File]::WriteAllText($rulesPath, $rulesContent, $utf8)
  if ($gradle.EndsWith('.kts')) {
    $shrinkToken = 'isShrinkResources = true'
    $rulesToken = 'proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")'
    if (-not $gradleText.Contains($rulesToken)) {
      if (-not $gradleText.Contains($shrinkToken)) { throw "R8 shrink option missing for $appName" }
      $gradleText = $gradleText.Replace($shrinkToken,
        $shrinkToken + [Environment]::NewLine + '            ' + $rulesToken)
    }
  } else {
    $shrinkToken = 'shrinkResources true'
    $rulesToken = "proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'"
    if (-not $gradleText.Contains($rulesToken)) {
      if (-not $gradleText.Contains($shrinkToken)) { throw "R8 shrink option missing for $appName" }
      $gradleText = $gradleText.Replace($shrinkToken,
        $shrinkToken + [Environment]::NewLine + '            ' + $rulesToken)
    }
  }
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

# Limit this generated AppStudio project's Gradle memory/parallelism.
# Do not edit JVM, Gradle or service settings shared with UikChanggo.
$gradleProperties = Join-Path $root 'android\gradle.properties'
if (Test-Path -LiteralPath $gradleProperties) {
  $settings = [System.IO.File]::ReadAllText($gradleProperties)
  $memoryLine = 'org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1024m -Dfile.encoding=UTF-8'
  if ($settings -match '(?m)^org\.gradle\.jvmargs=.*
if (Test-Path $generatedTest) {
  $content = [System.IO.File]::ReadAllText($generatedTest)
  if ($content.Contains('await tester.pumpWidget(const MyApp());')) {
    Remove-Item $generatedTest -Force
  }
}

Write-Host "[END] patch-android $appName (API 36; PowerShell; no Python dependency)"
) {
    $settings = [regex]::Replace($settings, '(?m)^org\.gradle\.jvmargs=.*
if (Test-Path $generatedTest) {
  $content = [System.IO.File]::ReadAllText($generatedTest)
  if ($content.Contains('await tester.pumpWidget(const MyApp());')) {
    Remove-Item $generatedTest -Force
  }
}

Write-Host "[END] patch-android $appName (API 36; PowerShell; no Python dependency)"
, $memoryLine)
  } else {
    $settings += [Environment]::NewLine + $memoryLine
  }
  foreach ($item in @(
    'org.gradle.workers.max=2',
    'org.gradle.parallel=false'
  )) {
    $key = $item.Split('=')[0]
    if ($settings -match ('(?m)^' + [regex]::Escape($key) + '=')) {
      $settings = [regex]::Replace($settings,
        '(?m)^' + [regex]::Escape($key) + '=.*
if (Test-Path $generatedTest) {
  $content = [System.IO.File]::ReadAllText($generatedTest)
  if ($content.Contains('await tester.pumpWidget(const MyApp());')) {
    Remove-Item $generatedTest -Force
  }
}

Write-Host "[END] patch-android $appName (API 36; PowerShell; no Python dependency)"
, $item)
    } else {
      $settings += [Environment]::NewLine + $item
    }
  }
  [System.IO.File]::WriteAllText($gradleProperties, $settings, $utf8)
  Write-Host '[GRADLE] AppStudio limits: Xmx4g, metaspace1g, 2 workers, no parallel projects'
}

$generatedTest = Join-Path $root 'test\widget_test.dart'
if (Test-Path $generatedTest) {
  $content = [System.IO.File]::ReadAllText($generatedTest)
  if ($content.Contains('await tester.pumpWidget(const MyApp());')) {
    Remove-Item $generatedTest -Force
  }
}

Write-Host "[END] patch-android $appName (API 36; PowerShell; no Python dependency)"
