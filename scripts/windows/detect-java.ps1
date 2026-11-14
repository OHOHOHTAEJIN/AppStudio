param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Prefer the user's dedicated JDK 17 installation and then any verified
# JDK/Android Studio runtime. Changes apply to this job only.
$candidates = New-Object 'System.Collections.Generic.List[string]'
function Add-Candidate([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    $clean = $Path.Trim('"').Trim()
    if (-not $candidates.Contains($clean)) { [void]$candidates.Add($clean) }
}

Add-Candidate 'D:\Java\jdk-17'
Add-Candidate $env:JAVA_HOME
Add-Candidate 'C:\Program Files\Android\Android Studio\jbr'
Add-Candidate 'D:\Android\Android Studio\jbr'
Add-Candidate 'C:\Program Files\Java\jdk-17'

foreach ($dir in @('C:\Program Files\Eclipse Adoptium', 'D:\Java', 'C:\Program Files\Java')) {
    if (Test-Path -LiteralPath $dir) {
        foreach ($item in @(Get-ChildItem -LiteralPath $dir -Directory -ErrorAction SilentlyContinue)) {
            if ($item.Name -match '^(jdk[-_]?17|jdk[-_]?21|temurin[-_]?17|temurin[-_]?21)') {
                Add-Candidate $item.FullName
            }
        }
    }
}

$javac = Get-Command javac.exe -ErrorAction SilentlyContinue
if ($null -ne $javac -and $javac.Source) {
    Add-Candidate (Split-Path (Split-Path $javac.Source -Parent) -Parent)
}

$selected = $null
foreach ($root in $candidates) {
    if ((Test-Path -LiteralPath (Join-Path $root 'bin\java.exe')) -and
        (Test-Path -LiteralPath (Join-Path $root 'bin\javac.exe'))) {
        $selected = $root
        break
    }
}

if ($null -eq $selected) {
    Write-Host "[ERROR] JAVA_HOME is currently '$env:JAVA_HOME'. That directory has no usable JDK."
    throw 'No JDK 17/21 detected. Install Java 17 or set AppStudio service JAVA_HOME to a verified JDK root containing bin\java.exe.'
}

$env:JAVA_HOME = $selected
$env:PATH = (Join-Path $selected 'bin') + ';' + $env:PATH
if ($env:GITHUB_ENV) {
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::AppendAllText($env:GITHUB_ENV,
        "JAVA_HOME=$selected" + [Environment]::NewLine, $encoding)
}

Write-Host "[JAVA] Selected JDK: $selected"
& (Join-Path $selected 'bin\java.exe') '-version'
if ($LASTEXITCODE -ne 0) { throw 'Detected JDK failed to start' }
Write-Host '[JAVA] JDK verified for this workflow job only.'
