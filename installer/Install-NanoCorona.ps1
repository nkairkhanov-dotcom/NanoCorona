param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
)

$ErrorActionPreference = "Stop"

$project = Join-Path $RepoRoot "src\NanoNetwork\NanoNetwork.csproj"
$dll = Join-Path $RepoRoot "src\NanoNetwork\bin\Release\NanoNetwork.dll"
$maxScript = Join-Path $RepoRoot "src\MaxScript\NanoCorona_VFB_Prototype.ms"
$extractScript = Join-Path $RepoRoot "src\MaxScript\NanoCorona_RenderExtraction.ms"

if (!(Test-Path $project)) { throw "NanoCorona repository root is invalid: $RepoRoot" }

Write-Host "NanoCorona Phase 6 installer" -ForegroundColor Cyan

if (!(Test-Path $dll)) {
    $msbuild = Get-Command msbuild.exe -ErrorAction SilentlyContinue
    if ($msbuild) {
        Write-Host "Building NanoNetwork Release..."
        & $msbuild.Source $project /p:Configuration=Release /m
        if ($LASTEXITCODE -ne 0) { throw "NanoNetwork build failed." }
    }
}

if (!(Test-Path $dll)) {
    throw "NanoNetwork.dll not found. Build src/NanoNetwork/NanoNetwork.csproj in Release first."
}

$maxRoot = Join-Path $env:APPDATA "Autodesk\3dsMax"
$targets = Get-ChildItem $maxRoot -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match "^20\d\d" }

if (!$targets) {
    throw "No per-user 3ds Max folders were found under $maxRoot."
}

foreach ($max in $targets) {
    $scripts = Join-Path $max.FullName "ENU\scripts\NanoCorona"
    $startup = Join-Path $max.FullName "ENU\scripts\Startup"
    New-Item -ItemType Directory -Force -Path $scripts,$startup | Out-Null

    Copy-Item $dll $scripts -Force
    Copy-Item $maxScript $scripts -Force
    Copy-Item $extractScript $scripts -Force

    $loader = Join-Path $startup "NanoCorona_Startup.ms"
    $loaderText = @'
local p = (getDir #userScripts) + "\NanoCorona\NanoCorona_VFB_Prototype.ms"
if (doesFileExist p) then
(
    try (fileIn p) catch()
)
'@
    Set-Content -Path $loader -Value $loaderText -Encoding UTF8

    Write-Host "Installed for $($max.Name): $scripts" -ForegroundColor Green
}

Write-Host ""
Write-Host "Installation complete. Restart 3ds Max." -ForegroundColor Green
Write-Host "Open Corona VFB, then use NanoCorona from the docked right-side panel."
