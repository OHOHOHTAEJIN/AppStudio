param(
  [ValidateSet('all', 'pulse_puzzle', 'pixel_slim', 'docu_snap', 'daily_quiz')]
  [string]$App = 'all'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$allApps = @('pulse_puzzle', 'pixel_slim', 'docu_snap', 'daily_quiz')
$selected = if ($App -eq 'all') { $allApps } else { @($App) }
$outputRoot = Join-Path $repoRoot 'appstudio-apks'

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
    Invoke-Checked -Executable 'flutter' -ArgList @('analyze')
    Invoke-Checked -Executable 'flutter' -ArgList @('test')
    Invoke-Checked -Executable 'flutter' -ArgList @('build', 'apk', '--debug')

    $sourceApk = Join-Path $appPath 'build\app\outputs\flutter-apk\app-debug.apk'
    if (-not (Test-Path $sourceApk)) {
      throw "Expected APK missing: $sourceApk"
    }
    $targetApk = Join-Path $outputRoot "$name-debug.apk"
    Copy-Item $sourceApk $targetApk -Force
    $sizeMb = [math]::Round((Get-Item $targetApk).Length / 1MB, 2)
    $elapsed = [math]::Round(((Get-Date) - $started).TotalMilliseconds)
    Write-Host "[END] build-app $name => $targetApk ($sizeMb MB, $elapsed ms)"
  }
  finally {
    Pop-Location
  }
}
Write-Host '[END] all requested AppStudio Android debug APKs built and staged for upload'
