param(
  [ValidateSet('all','privacy_mosaic','pixel_slim','docu_snap','shift_pay')]
  [string]$App = 'all'
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$apps = if ($App -eq 'all') { @('privacy_mosaic','pixel_slim','docu_snap','shift_pay') } else { @($App) }
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
    if ($name -eq 'privacy_mosaic' -or $name -eq 'shift_pay') {
      dart run tool/generate_icon.dart $name
      if ($LASTEXITCODE -ne 0) { throw "icon generation failed: $name" }
    }
    dart run flutter_launcher_icons
    if ($LASTEXITCODE -ne 0) { throw "launcher creation failed: $name" }
    flutter analyze
    if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed: $name" }
    flutter test
    if ($LASTEXITCODE -ne 0) { throw "flutter test failed: $name" }
    Write-Host "[END] $name passed"
  } finally {
    Pop-Location
  }
}
