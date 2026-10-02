param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
)

$ErrorActionPreference = "Stop"

$project = Join-Path $RepoRoot "src\NanoNetwork\NanoNetwork.csproj"
$releaseDir = Join-Path $RepoRoot "src\NanoNetwork\bin\Release\net8.0-windows"
$maxScript = Join-Path $RepoRoot "src\MaxScript\NanoCorona_VFB_Prototype.ms"
$extractScript = Join-Path $RepoRoot "src\MaxScript\NanoCorona_RenderExtraction.ms"

if (!(Test-Path $project)) { throw "NanoCorona repository root is invalid: $RepoRoot" }

Write-Host "NanoCorona - 3ds Max 2026 + Corona 15 installer" -ForegroundColor Cyan

$dotnet = Get-Command dotnet.exe -ErrorAction SilentlyContinue
if (!$dotnet) { throw "dotnet.exe was not found. Install the .NET 8 SDK first." }

Write-Host "Building NanoNetwork for net8.0-windows..."
& $dotnet.Source build $project -c Release
if ($LASTEXITCODE -ne 0) { throw "NanoNetwork build failed." }

if (!(Test-Path (Join-Path $releaseDir "NanoNetwork.dll"))) {
    throw "NanoNetwork.dll was not produced at $releaseDir."
}

$maxRoot = Join-Path $env:LOCALAPPDATA "Autodesk\3dsMax\2026 - 64bit"
$languageDirs = Get-ChildItem $maxRoot -Directory -ErrorAction SilentlyContinue
if (!$languageDirs) { throw "3ds Max 2026 user-data folder was not found: $maxRoot" }

foreach ($lang in $languageDirs) {
    $scripts = Join-Path $lang.FullName "scripts\NanoCorona"
    $startup = Join-Path $lang.FullName "scripts\startup"
    New-Item -ItemType Directory -Force -Path $scripts,$startup | Out-Null

    Copy-Item (Join-Path $releaseDir "*") $scripts -Recurse -Force
    Copy-Item $maxScript $scripts -Force
    Copy-Item $extractScript $scripts -Force

    $loader = Join-Path $startup "NanoCorona_Startup.ms"
    $loaderText = @'
global NanoCoronaStartupFile
NanoCoronaStartupFile = (getDir #userScripts) + "\NanoCorona\NanoCorona_VFB_Prototype.ms"
if (doesFileExist NanoCoronaStartupFile) then
(
    try (fileIn NanoCoronaStartupFile) catch()
)
'@
    Set-Content -Path $loader -Value $loaderText -Encoding UTF8

    Write-Host "Installed for 3ds Max 2026 ($($lang.Name)): $scripts" -ForegroundColor Green
}

Write-Host ""
Write-Host "Installation complete. Restart 3ds Max 2026." -ForegroundColor Green
Write-Host "Use Corona 15 as the active renderer and open Corona VFB."
