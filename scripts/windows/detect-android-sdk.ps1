param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# This script discovers an existing Android SDK on the PC. It does not install
# software or modify system/user environment variables.
$candidates = New-Object 'System.Collections.Generic.List[string]'
function Add-SdkCandidate([string]$Path) {
    if (-not [string]::IsNullOrWhiteSpace($Path)) {
        $normalized = $Path.Trim('"').Trim()
        if (-not [string]::IsNullOrWhiteSpace($normalized) -and -not $candidates.Contains($normalized)) {
            [void]$candidates.Add($normalized)
        }
    }
}

Add-SdkCandidate $env:ANDROID_HOME
Add-SdkCandidate $env:ANDROID_SDK_ROOT

# Flutter can have an explicit Android SDK location configured.
try {
    $flutterConfig = & flutter config --list 2>&1
    foreach ($line in $flutterConfig) {
        if ("$line" -match '^\s*android-sdk:\s*(.+?)\s*$') {
            $configured = $Matches[1].Trim()
            if ($configured -notmatch '^\[') { Add-SdkCandidate $configured }
        }
    }
} catch {
    Write-Host "[WARN] Unable to query Flutter SDK configuration: $_"
}

# If adb is on PATH, its grandparent is the Android SDK root.
$adbCommand = Get-Command adb -ErrorAction SilentlyContinue
if ($null -ne $adbCommand -and $adbCommand.Source) {
    Add-SdkCandidate (Split-Path (Split-Path $adbCommand.Source -Parent) -Parent)
}

foreach ($path in @(
    'C:\Android\Sdk',
    'D:\Android\Sdk',
    'D:\Android\sdk',
    'D:\android-sdk',
    'C:\Program Files (x86)\Android\android-sdk'
)) {
    Add-SdkCandidate $path
}

if ($env:LOCALAPPDATA) { Add-SdkCandidate (Join-Path $env:LOCALAPPDATA 'Android\Sdk') }
if ($env:USERPROFILE) { Add-SdkCandidate (Join-Path $env:USERPROFILE 'AppData\Local\Android\Sdk') }

# Service accounts often use SystemProfile rather than the Android Studio
# account's profile. Inspect ordinary user-profile SDK locations as a fallback.
foreach ($profilesRoot in @('C:\Users', 'D:\Users')) {
    if (Test-Path -LiteralPath $profilesRoot) {
        foreach ($profile in @(Get-ChildItem -LiteralPath $profilesRoot -Directory -ErrorAction SilentlyContinue)) {
            Add-SdkCandidate (Join-Path $profile.FullName 'AppData\Local\Android\Sdk')
        }
    }
}

$selected = $null
$hasSdkWithoutApi36 = $false
foreach ($candidate in $candidates) {
    $platformTools = Join-Path $candidate 'platform-tools\adb.exe'
    $android36 = Join-Path $candidate 'platforms\android-36\android.jar'
    if (Test-Path -LiteralPath $android36) {
        $selected = $candidate
        break
    }
    if (Test-Path -LiteralPath $platformTools) {
        $hasSdkWithoutApi36 = $true
        if ($null -eq $selected) { $selected = $candidate }
    }
}

if ($null -eq $selected) {
    Write-Host '[ERROR] Android SDK not found in environment, Flutter config, adb PATH or standard SDK folders.'
    Write-Host 'Verify Android Studio > Settings > Languages & Frameworks > Android SDK > Android SDK Location.'
    Write-Host 'Install Android SDK Platform 36 and platform-tools if absent.'
    throw 'AppStudio SDK detection failed. Set ANDROID_HOME for the AppStudio runner service account.'
}

Write-Host "[SDK] Found Android SDK at $selected"
if (-not (Test-Path -LiteralPath (Join-Path $selected 'platforms\android-36\android.jar'))) {
    throw "Android SDK found at $selected but API 36 is missing. Install Android SDK Platform 36 with SDK Manager."
}
if (-not (Test-Path -LiteralPath (Join-Path $selected 'platform-tools\adb.exe'))) {
    throw "Android SDK found at $selected but platform-tools (adb) are missing."
}

$env:ANDROID_HOME = $selected
$env:ANDROID_SDK_ROOT = $selected

# Persist environment variables to later steps of THIS workflow job ONLY.
# Neither the global runner service nor the existing blog runner is modified.
if ($env:GITHUB_ENV) {
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::AppendAllText($env:GITHUB_ENV,
        "ANDROID_HOME=$selected" + [Environment]::NewLine +
        "ANDROID_SDK_ROOT=$selected" + [Environment]::NewLine, $encoding)
}

Write-Host '[SDK] Android SDK Platform 36 and platform-tools verified for this build job.'
