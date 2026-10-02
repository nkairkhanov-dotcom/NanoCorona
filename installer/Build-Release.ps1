param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)),
    [string]$OutputDir = (Join-Path $RepoRoot "dist")
)

$ErrorActionPreference = "Stop"
$project = Join-Path $RepoRoot "src\NanoNetwork\NanoNetwork.csproj"
$dll = Join-Path $RepoRoot "src\NanoNetwork\bin\Release\NanoNetwork.dll"
if (!(Test-Path $project)) { throw "Invalid repository root: $RepoRoot" }

$msbuild = Get-Command msbuild.exe -ErrorAction SilentlyContinue
if (!$msbuild) { throw "msbuild.exe was not found. Install Visual Studio Build Tools or build NanoNetwork manually." }

& $msbuild.Source $project /p:Configuration=Release /m
if ($LASTEXITCODE -ne 0) { throw "Build failed." }

if (!(Test-Path $dll)) { throw "Release DLL was not produced." }

$stage = Join-Path $OutputDir "NanoCorona"
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null
Copy-Item $dll $stage -Force
Copy-Item (Join-Path $RepoRoot "src\MaxScript\NanoCorona_VFB_Prototype.ms") $stage -Force
Copy-Item (Join-Path $RepoRoot "src\MaxScript\NanoCorona_RenderExtraction.ms") $stage -Force
Copy-Item (Join-Path $RepoRoot "installer\Install-NanoCorona.ps1") $stage -Force
Copy-Item (Join-Path $RepoRoot "docs\INSTALL.md") $stage -Force
Copy-Item (Join-Path $RepoRoot "docs\USER_GUIDE.md") $stage -Force
Copy-Item (Join-Path $RepoRoot "docs\COMPATIBILITY.md") $stage -Force

$zip = Join-Path $OutputDir "NanoCorona.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip -CompressionLevel Optimal
Write-Host "Release package: $zip" -ForegroundColor Green
