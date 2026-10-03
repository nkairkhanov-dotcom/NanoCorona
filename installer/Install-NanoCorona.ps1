param(
    [string]$PackageRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path),
    [string]$MaxUserDataRoot = (Join-Path $env:LOCALAPPDATA "Autodesk\3dsMax\2026 - 64bit")
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

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
    throw "3ds Max 2026 user-data folder was not found: $MaxUserDataRoot"
}

$languageDirs = Get-ChildItem $MaxUserDataRoot -Directory -ErrorAction Stop
if (!$languageDirs) {
    throw "No 3ds Max 2026 language folders were found under $MaxUserDataRoot"
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

Write-Host ""
Write-Host "Installation complete. Restart 3ds Max 2026 before using NanoCorona." -ForegroundColor Green
