param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)),
    [string]$OutputDir = (Join-Path $RepoRoot "dist"),
    [string]$Version = "0.1.0"
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

$runtimeStage = Join-Path $stage "runtime"
New-Item -ItemType Directory -Force -Path $runtimeStage | Out-Null
Copy-Item (Join-Path $releaseDir "*") $runtimeStage -Recurse -Force
Copy-Item (Join-Path $RepoRoot "src\MaxScript\NanoCorona_VFB_Prototype.ms") $stage -Force
Copy-Item (Join-Path $RepoRoot "src\MaxScript\NanoCorona_RenderExtraction.ms") $stage -Force
Copy-Item (Join-Path $RepoRoot "src\MaxScript\NanoCorona_Toolbar.ms") $stage -Force
Copy-Item (Join-Path $RepoRoot "installer\Install-NanoCorona.ps1") $stage -Force
Copy-Item (Join-Path $RepoRoot "installer\Install-NanoCorona.cmd") $stage -Force
Copy-Item (Join-Path $RepoRoot "installer\Uninstall-NanoCorona.ps1") $stage -Force
Copy-Item (Join-Path $RepoRoot "Update-NanoCorona.bat") $stage -Force
Copy-Item (Join-Path $RepoRoot "docs\INSTALL.md") $stage -Force
Copy-Item (Join-Path $RepoRoot "docs\USER_GUIDE.md") $stage -Force
Copy-Item (Join-Path $RepoRoot "docs\COMPATIBILITY.md") $stage -Force

$zip = Join-Path $OutputDir "NanoCorona.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip -CompressionLevel Optimal

$iscc = Get-Command iscc.exe -ErrorAction SilentlyContinue
if (!$iscc) {
    $isccCandidates = @(
        "$env:ProgramFiles(x86)\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
    )
    foreach ($candidate in $isccCandidates) {
        if (Test-Path $candidate) { $iscc = Get-Item $candidate; break }
    }
}
if (!$iscc) {
    throw "Inno Setup 6 (ISCC.exe) was not found. Install Inno Setup 6 to build NanoCorona-Setup.exe."
}

$iss = Join-Path $RepoRoot "installer\NanoCorona.iss"
& $iscc.Source /DAppVersion="$Version" /DSourceDir="$stage" /DOutputDir="$OutputDir" $iss
if ($LASTEXITCODE -ne 0) { throw "Inno Setup build failed." }

$setup = Join-Path $OutputDir "NanoCorona-Setup.exe"
if (!(Test-Path $setup)) { throw "NanoCorona-Setup.exe was not produced." }

Write-Host "Release ZIP: $zip" -ForegroundColor Green
Write-Host "Windows installer: $setup" -ForegroundColor Green
