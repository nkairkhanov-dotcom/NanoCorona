param(
    [string]$PackageRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path),
    [string]$MaxUserDataRoot = (Join-Path $env:LOCALAPPDATA "Autodesk\3dsMax\2026 - 64bit")
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$logPath = Join-Path $PackageRoot "NanoCorona-install.log"
Start-Transcript -Path $logPath -Force | Out-Null
try {

# A release package contains ready-to-copy files. No compiler, SDK, Git, or
# network access is required on the target workstation.
$runtimeDir = Join-Path $PackageRoot "runtime"
$maxScript = Join-Path $PackageRoot "NanoCorona_VFB_Prototype.ms"
$extractScript = Join-Path $PackageRoot "NanoCorona_RenderExtraction.ms"
$toolbarScript = Join-Path $PackageRoot "NanoCorona_Toolbar.ms"
$dll = Join-Path $runtimeDir "NanoNetwork.dll"

if (!(Test-Path $dll)) {
    throw "Release runtime is incomplete: $dll was not found. Use the official NanoCorona release ZIP, not the source repository."
}
if (!(Test-Path $maxScript) -or !(Test-Path $extractScript) -or !(Test-Path $toolbarScript)) {
    throw "Release package is incomplete: required MAXScript files are missing."
}
if (!(Test-Path $MaxUserDataRoot)) {
    # 3ds Max may not have been launched by this Windows user yet.
    # Autodesk documents this as the default local user-data location.
    New-Item -ItemType Directory -Force -Path $MaxUserDataRoot | Out-Null
}

$languageDirs = Get-ChildItem $MaxUserDataRoot -Directory -ErrorAction Stop
if (!$languageDirs) {
    # ENU is the standard English profile and 3ds Max will initialize it
    # normally on first launch if the profile does not exist yet.
    $languageDirs = @(
        (New-Item -ItemType Directory -Force -Path (Join-Path $MaxUserDataRoot "ENU"))
    )
}

Write-Host "NanoCorona one-click installation" -ForegroundColor Cyan
Write-Host "Target: 3ds Max 2026 + Corona 15" -ForegroundColor Cyan

$loaderText = @'
global NanoCoronaStartupFile
NanoCoronaStartupFile = (getDir #userScripts) + "\NanoCorona\NanoCorona_VFB_Prototype.ms"
if (doesFileExist NanoCoronaStartupFile) then
(
    try (fileIn NanoCoronaStartupFile) catch()
)

global NanoCoronaStartupToolbar
NanoCoronaStartupToolbar = (getDir #userScripts) + "\NanoCorona\NanoCorona_Toolbar.ms"
if (doesFileExist NanoCoronaStartupToolbar) then
(
    try (fileIn NanoCoronaStartupToolbar) catch()
)
'@

foreach ($lang in $languageDirs) {
    $scripts = Join-Path $lang.FullName "scripts\NanoCorona"
    $startup = Join-Path $lang.FullName "scripts\startup"
    $loader = Join-Path $startup "NanoCorona_Startup.ms"

    New-Item -ItemType Directory -Force -Path $scripts, $startup | Out-Null
    Copy-Item (Join-Path $runtimeDir "*") $scripts -Recurse -Force
    Copy-Item $maxScript, $extractScript, $toolbarScript -Destination $scripts -Force
    Set-Content -LiteralPath $loader -Value $loaderText -Encoding UTF8

    Write-Host "Installed: $scripts" -ForegroundColor Green
}

function Test-NanoCoronaInstallation {
    param([string]$Root)

    $errors = @()
    $required = @(
        "NanoNetwork.dll",
        "NanoCorona_VFB_Prototype.ms",
        "NanoCorona_RenderExtraction.ms",
        "NanoCorona_Toolbar.ms"
    )

    foreach ($relative in $required) {
        $path = Join-Path $Root $relative
        if (!(Test-Path -LiteralPath $path -PathType Leaf)) {
            $errors += "Missing: $relative"
        }
    }

    if ($errors.Count -gt 0) {
        throw ("NanoCorona installation verification failed: " + ($errors -join " | "))
    }

    Write-Host "Installation verification: OK" -ForegroundColor Green
}

foreach ($lang in $languageDirs) {
    $scripts = Join-Path $lang.FullName "scripts\NanoCorona"
    $startup = Join-Path $lang.FullName "scripts\startup"
    $loader = Join-Path $startup "NanoCorona_Startup.ms"

    Test-NanoCoronaInstallation -Root $scripts

    if (!(Test-Path -LiteralPath $loader -PathType Leaf)) {
        throw "Installation verification failed: startup loader was not created for $($lang.Name)."
    }

    $loaderText = Get-Content -LiteralPath $loader -Raw
    if ($loaderText -notmatch 'NanoCorona_VFB_Prototype\.ms' -or
        $loaderText -notmatch 'NanoCorona_Toolbar\.ms') {
        throw "Installation verification failed: startup loader is incomplete for $($lang.Name)."
    }

    Write-Host "Verified: $($lang.Name)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Installation verification: ALL CHECKS PASSED" -ForegroundColor Green
Write-Host "Restart 3ds Max 2026 before using NanoCorona." -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "NanoCorona installation error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Log: $logPath" -ForegroundColor Yellow
    exit 1
}
finally {
    Stop-Transcript | Out-Null
}
