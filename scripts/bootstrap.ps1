param(
  [ValidateSet('all','pulse_puzzle','pixel_slim','docu_snap','daily_quiz')]
  [string]$App = 'all'
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$apps = if ($App -eq 'all') { @('pulse_puzzle','pixel_slim','docu_snap','daily_quiz') } else { @($App) }
foreach ($name in $apps) {
  Push-Location (Join-Path $root "apps/$name")
  try {
    Write-Host "[START] $name"
    flutter create --platforms=android --org=com.uikstudio --project-name=$name --no-pub .
    if ($LASTEXITCODE -ne 0) { throw "flutter create failed: $name" }
    python (Join-Path $root 'scripts/patch_android.py') (Get-Location).Path
    if ($LASTEXITCODE -ne 0) { throw "Android patch failed: $name" }
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "pub get failed: $name" }
    flutter analyze
    if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed: $name" }
    flutter test
    if ($LASTEXITCODE -ne 0) { throw "flutter test failed: $name" }
    Write-Host "[END] $name passed"
  } finally {
    Pop-Location
  }
}
