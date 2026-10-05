param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)),
    [string]$OutputDir = (Join-Path $RepoRoot "dist"),
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

# Release versions come from Git tags (for example v1.4.0 -> 1.4.0).
# This also works for local release builds. Non-tag builds use a clearly
# identifiable development version.
if ([string]::IsNullOrWhiteSpace($Version)) {
    $tag = $env:GITHUB_REF_NAME
    if ([string]::IsNullOrWhiteSpace($tag) -and (Get-Command git.exe -ErrorAction SilentlyContinue)) {
        $tag = (& git.exe -C $RepoRoot describe --tags --exact-match 2>$null)
    }

    if ($tag -match '^v([0-9]+(?:\.[0-9]+){0,3})$project = Join-Path $RepoRoot "src\NanoNetwork\NanoNetwork.csproj"
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

# Convert the vector icon to Windows ICO for Inno Setup.
$magick = Get-Command magick.exe -ErrorAction SilentlyContinue
if (!$magick) {
    throw "ImageMagick (magick.exe) was not found. Install ImageMagick to build the installer."
}
$iconSource = Join-Path $RepoRoot "installer\NanoCorona.svg"
$iconOutput = Join-Path $RepoRoot "installer\NanoCorona.ico"
& $magick.Source $iconSource -background none -define icon:auto-resize=256,128,64,48,32,16 $iconOutput
if ($LASTEXITCODE -ne 0 -or !(Test-Path $iconOutput)) { throw "Icon conversion failed." }

Copy-Item $iconOutput (Join-Path $stage "NanoCorona.ico") -Force

# Create branded bitmap panels used by the modern Inno Setup wizard.
# Inno Setup expects BMP files for WizardImageFile/WizardSmallImageFile.
$wizardImage = Join-Path $RepoRoot "installer\NanoCorona-Wizard.bmp"
$wizardSmallImage = Join-Path $RepoRoot "installer\NanoCorona-WizardSmall.bmp"
& $magick.Source $iconSource -background "#0b0f14" -gravity center -resize "140x140" -extent 164x314 -colorspace sRGB -type TrueColor $wizardImage
if ($LASTEXITCODE -ne 0 -or !(Test-Path $wizardImage)) { throw "Wizard image generation failed." }
& $magick.Source $iconSource -background "#0b0f14" -gravity center -resize "48x48" -extent 55x55 -colorspace sRGB -type TrueColor $wizardSmallImage
if ($LASTEXITCODE -ne 0 -or !(Test-Path $wizardSmallImage)) { throw "Wizard small image generation failed." }

Copy-Item $wizardImage (Join-Path $stage "NanoCorona-Wizard.bmp") -Force
Copy-Item $wizardSmallImage (Join-Path $stage "NanoCorona-WizardSmall.bmp") -Force

$zip = Join-Path $OutputDir "NanoCorona.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip -CompressionLevel Optimal

$iss = Join-Path $RepoRoot "installer\NanoCorona.iss"
& $iscc.Source /DAppVersion="$Version" /DSourceDir="$stage" /DOutputDir="$OutputDir" $iss
if ($LASTEXITCODE -ne 0) { throw "Inno Setup build failed." }

$setup = Join-Path $OutputDir "NanoCorona-Setup.exe"
if (!(Test-Path $setup)) { throw "NanoCorona-Setup.exe was not produced." }

Write-Host "Release ZIP: $zip" -ForegroundColor Green
Write-Host "Windows installer: $setup" -ForegroundColor Green
) {
        $Version = $Matches[1]
    } else {
        $Version = "0.0.0"
    }
}

if ($Version -notmatch '^[0-9]+(?:\.[0-9]+){0,3}$project = Join-Path $RepoRoot "src\NanoNetwork\NanoNetwork.csproj"
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

# Convert the vector icon to Windows ICO for Inno Setup.
$magick = Get-Command magick.exe -ErrorAction SilentlyContinue
if (!$magick) {
    throw "ImageMagick (magick.exe) was not found. Install ImageMagick to build the installer."
}
$iconSource = Join-Path $RepoRoot "installer\NanoCorona.svg"
$iconOutput = Join-Path $RepoRoot "installer\NanoCorona.ico"
& $magick.Source $iconSource -background none -define icon:auto-resize=256,128,64,48,32,16 $iconOutput
if ($LASTEXITCODE -ne 0 -or !(Test-Path $iconOutput)) { throw "Icon conversion failed." }

Copy-Item $iconOutput (Join-Path $stage "NanoCorona.ico") -Force

$iss = Join-Path $RepoRoot "installer\NanoCorona.iss"
& $iscc.Source /DAppVersion="$Version" /DSourceDir="$stage" /DOutputDir="$OutputDir" $iss
if ($LASTEXITCODE -ne 0) { throw "Inno Setup build failed." }

$setup = Join-Path $OutputDir "NanoCorona-Setup.exe"
if (!(Test-Path $setup)) { throw "NanoCorona-Setup.exe was not produced." }

Write-Host "Release ZIP: $zip" -ForegroundColor Green
Write-Host "Windows installer: $setup" -ForegroundColor Green
) {
    throw "Invalid NanoCorona version '$Version'. Expected a Git tag such as v1.2.3."
}

Write-Host "NanoCorona version: $Version" -ForegroundColor Cyan
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

# Convert the vector icon to Windows ICO for Inno Setup.
$magick = Get-Command magick.exe -ErrorAction SilentlyContinue
if (!$magick) {
    throw "ImageMagick (magick.exe) was not found. Install ImageMagick to build the installer."
}
$iconSource = Join-Path $RepoRoot "installer\NanoCorona.svg"
$iconOutput = Join-Path $RepoRoot "installer\NanoCorona.ico"
& $magick.Source $iconSource -background none -define icon:auto-resize=256,128,64,48,32,16 $iconOutput
if ($LASTEXITCODE -ne 0 -or !(Test-Path $iconOutput)) { throw "Icon conversion failed." }

Copy-Item $iconOutput (Join-Path $stage "NanoCorona.ico") -Force

$iss = Join-Path $RepoRoot "installer\NanoCorona.iss"
& $iscc.Source /DAppVersion="$Version" /DSourceDir="$stage" /DOutputDir="$OutputDir" $iss
if ($LASTEXITCODE -ne 0) { throw "Inno Setup build failed." }

$setup = Join-Path $OutputDir "NanoCorona-Setup.exe"
if (!(Test-Path $setup)) { throw "NanoCorona-Setup.exe was not produced." }

Write-Host "Release ZIP: $zip" -ForegroundColor Green
Write-Host "Windows installer: $setup" -ForegroundColor Green
