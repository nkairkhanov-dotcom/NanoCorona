param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)),
    [string]$OutputDir = (Join-Path $RepoRoot "dist")
)

$ErrorActionPreference = "Stop"
$project = Join-Path $RepoRoot "src\NanoNetwork\NanoNetwork.csproj"
$releaseDir = Join-Path $RepoRoot "src\NanoNetwork\bin\Release\net8.0-windows"
$dll = Join-Path $releaseDir "NanoNetwork.dll"
if (!(Test-Path $project)) { throw "Invalid repository root: $RepoRoot" }

$dotnet = Get-Command dotnet.exe -ErrorAction SilentlyContinue
if (!$dotnet) { throw "dotnet.exe was not found. Install the .NET 8 SDK first." }

& $dotnet.Source build $project -c Release
if ($LASTEXITCODE -ne 0) { throw "Build failed." }

if (!(Test-Path $dll)) { throw "Release DLL was not produced." }

$stage = Join-Path $OutputDir "NanoCorona"
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null
Copy-Item (Join-Path $releaseDir "*") $stage -Recurse -Force
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
