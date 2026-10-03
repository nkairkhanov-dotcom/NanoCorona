param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)),
    [switch]$SkipDotNetInstall
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$project = Join-Path $RepoRoot "src\NanoNetwork\NanoNetwork.csproj"
$releaseDir = Join-Path $RepoRoot "src\NanoNetwork\bin\Release\net8.0-windows"
$maxScript = Join-Path $RepoRoot "src\MaxScript\NanoCorona_VFB_Prototype.ms"
$extractScript = Join-Path $RepoRoot "src\MaxScript\NanoCorona_RenderExtraction.ms"
$toolbarScript = Join-Path $RepoRoot "src\MaxScript\NanoCorona_Toolbar.ms"

if (!(Test-Path $project)) { throw "NanoCorona repository root is invalid: $RepoRoot" }

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " NanoCorona One-Click Installer" -ForegroundColor Cyan
Write-Host " 3ds Max 2026 + Corona 15" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

function Find-DotNet {
    $programFilesX86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
    $candidates = @(
        (Join-Path $env:ProgramFiles "dotnet\dotnet.exe"),
        (Join-Path $programFilesX86 "dotnet\dotnet.exe"),
        (Join-Path $env:LOCALAPPDATA "Microsoft\dotnet\dotnet.exe")
    )

    $cmd = Get-Command dotnet.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) { return $candidate }
    }

    return $null
}

function Install-DotNet8Sdk {
    $installDir = Join-Path $env:LOCALAPPDATA "Microsoft\dotnet"
    $bootstrap = Join-Path $env:TEMP "dotnet-install-nanocorona.ps1"

    Write-Host ".NET 8 SDK was not found." -ForegroundColor Yellow
    Write-Host "Downloading Microsoft's official dotnet-install script..." -ForegroundColor Yellow

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri "https://dot.net/v1/dotnet-install.ps1" -OutFile $bootstrap -UseBasicParsing

    Write-Host "Installing .NET 8 SDK (x64) to $installDir" -ForegroundColor Yellow

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $bootstrap -Channel 8.0 -Architecture x64 -InstallDir $installDir

    if ($LASTEXITCODE -ne 0) { throw ".NET 8 SDK installation failed." }

    $dotnet = Join-Path $installDir "dotnet.exe"
    if (!(Test-Path $dotnet)) { throw ".NET 8 SDK installation completed without dotnet.exe at $dotnet" }

    return $dotnet
}

$dotnet = Find-DotNet

if (!$dotnet -and !$SkipDotNetInstall) {
    $dotnet = Install-DotNet8Sdk
}

if (!$dotnet) {
    throw "dotnet.exe was not found. Install the .NET 8 SDK."
}

Write-Host "Using dotnet:" -ForegroundColor Green
& $dotnet --version
if ($LASTEXITCODE -ne 0) { throw "dotnet.exe could not be executed." }

Write-Host ""
Write-Host "Restoring NanoNetwork dependencies..." -ForegroundColor Cyan
& $dotnet restore $project
if ($LASTEXITCODE -ne 0) { throw "NanoNetwork dependency restore failed." }

Write-Host ""
Write-Host "Building NanoNetwork for net8.0-windows..." -ForegroundColor Cyan
& $dotnet build $project -c Release --no-restore
if ($LASTEXITCODE -ne 0) { throw "NanoNetwork build failed." }

$dll = Join-Path $releaseDir "NanoNetwork.dll"
if (!(Test-Path $dll)) { throw "NanoNetwork.dll was not produced at $releaseDir" }
if (!(Test-Path $maxScript)) { throw "Missing MAXScript: $maxScript" }
if (!(Test-Path $extractScript)) { throw "Missing render extraction script: $extractScript" }
if (!(Test-Path $toolbarScript)) { throw "Missing NanoCorona toolbar script: $toolbarScript" }

$maxRoot = Join-Path $env:LOCALAPPDATA "Autodesk\3dsMax\2026 - 64bit"
if (!(Test-Path $maxRoot)) { throw "3ds Max 2026 user-data folder was not found: $maxRoot" }

$languageDirs = Get-ChildItem $maxRoot -Directory -ErrorAction SilentlyContinue
if (!$languageDirs) { throw "No 3ds Max 2026 language folders were found under $maxRoot" }

foreach ($lang in $languageDirs) {
    $scripts = Join-Path $lang.FullName "scripts\NanoCorona"
    $startup = Join-Path $lang.FullName "scripts\startup"

    New-Item -ItemType Directory -Force -Path $scripts,$startup | Out-Null

    Write-Host ""
    Write-Host "Installing NanoCorona for $($lang.Name)..." -ForegroundColor Cyan

    Copy-Item (Join-Path $releaseDir "*") $scripts -Recurse -Force
    Copy-Item $maxScript $scripts -Force
    Copy-Item $extractScript $scripts -Force
    Copy-Item $toolbarScript $scripts -Force

    $loader = Join-Path $startup "NanoCorona_Startup.ms"
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

    Set-Content -Path $loader -Value $loaderText -Encoding UTF8
    Write-Host "Installed: $scripts" -ForegroundColor Green
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host " NanoCorona installation complete." -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host " 1. Restart 3ds Max 2026."
Write-Host " 2. Make sure Corona 15 is the active renderer."
Write-Host " 3. Open Corona VFB."
Write-Host " 4. Use the NanoCorona bar at the top of 3ds Max: OPEN/HIDE NANOCORONA."
Write-Host ""
