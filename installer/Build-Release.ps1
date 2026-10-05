param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)),
    [string]$OutputDir = (Join-Path $RepoRoot "dist"),
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($Version)) {
    $tag = $env:GITHUB_REF_NAME
    if ([string]::IsNullOrWhiteSpace($tag) -and (Get-Command git.exe -ErrorAction SilentlyContinue)) {
        $tag = (& git.exe -C $RepoRoot describe --tags --exact-match 2>$null)
    }

    if ($tag -match '^v([0-9]+(?:\.[0-9]+){0,3})$') {
        $Version = $Matches[1]
    } else {
        $Version = "0.0.0"
    }
}

if ($Version -notmatch '^[0-9]+(?:\.[0-9]+){0,3}$') {
    throw "Invalid NanoCorona version '$Version'. Expected a Git tag such as v1.2.3."
}

Write-Host "NanoCorona version: $Version" -ForegroundColor Cyan

$project = Join-Path $RepoRoot "src\NanoNetwork\NanoNetwork.csproj"
$releaseDir = Join-Path $RepoRoot "src\NanoNetwork\bin\Release\net8.0-windows"
$dll = Join-Path $releaseDir "NanoNetwork.dll"

if (!(Test-Path -LiteralPath $project -PathType Leaf)) {
    throw "Invalid repository root: $RepoRoot"
}

$dotnet = Get-Command dotnet.exe -ErrorAction SilentlyContinue
if (!$dotnet) {
    throw "dotnet.exe was not found. Install the .NET 8 SDK first."
}

& $dotnet.Source build $project -c Release
if ($LASTEXITCODE -ne 0) {
    throw "NanoNetwork build failed."
}

if (!(Test-Path -LiteralPath $dll -PathType Leaf)) {
    throw "Release DLL was not produced: $dll"
}

$stage = Join-Path $OutputDir "NanoCorona"
if (Test-Path -LiteralPath $stage) {
    Remove-Item -LiteralPath $stage -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $stage | Out-Null

$runtimeStage = Join-Path $stage "runtime"
New-Item -ItemType Directory -Force -Path $runtimeStage | Out-Null
Copy-Item (Join-Path $releaseDir "*") $runtimeStage -Recurse -Force

$payloadFiles = @(
    "src\MaxScript\NanoCorona_VFB_Prototype.ms",
    "src\MaxScript\NanoCorona_RenderExtraction.ms",
    "src\MaxScript\NanoCorona_Toolbar.ms",
    "installer\Install-NanoCorona.ps1",
    "installer\Uninstall-NanoCorona.ps1",
    "Update-NanoCorona.bat",
    "docs\INSTALL.md",
    "docs\USER_GUIDE.md",
    "docs\COMPATIBILITY.md"
)

foreach ($relative in $payloadFiles) {
    $source = Join-Path $RepoRoot $relative
    if (!(Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Release payload is missing: $relative"
    }
    Copy-Item -LiteralPath $source -Destination $stage -Force
}

$installScript = Join-Path $stage "Install-NanoCorona.ps1"
$requiredStage = @(
    "runtime\NanoNetwork.dll",
    "NanoCorona_VFB_Prototype.ms",
    "NanoCorona_RenderExtraction.ms",
    "NanoCorona_Toolbar.ms",
    "Install-NanoCorona.ps1",
    "Uninstall-NanoCorona.ps1"
)

foreach ($relative in $requiredStage) {
    if (!(Test-Path -LiteralPath (Join-Path $stage $relative) -PathType Leaf)) {
        throw "Release staging verification failed: $relative"
    }
}

# Build a deterministic manifest for the portable package and installer payload.
$manifestPath = Join-Path $stage "NanoCorona-MANIFEST.txt"
$manifestLines = @(
    "NanoCorona $Version"
    "Generated: $(Get-Date -Format o)"
    ""
)
foreach ($relative in ($requiredStage | Sort-Object)) {
    $file = Join-Path $stage $relative
    $hash = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
    $manifestLines += "$hash  $relative"
}
Set-Content -LiteralPath $manifestPath -Value $manifestLines -Encoding UTF8

$iscc = Get-Command iscc.exe -ErrorAction SilentlyContinue
if (!$iscc) {
    $isccCandidates = @(
        "$env:ProgramFiles(x86)\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
    )
    foreach ($candidate in $isccCandidates) {
        if (Test-Path -LiteralPath $candidate) {
            $iscc = Get-Item -LiteralPath $candidate
            break
        }
    }
}
if (!$iscc) {
    throw "Inno Setup 6 (ISCC.exe) was not found."
}

$magick = Get-Command magick.exe -ErrorAction SilentlyContinue
if (!$magick) {
    throw "ImageMagick (magick.exe) was not found."
}

$iconSource = Join-Path $RepoRoot "installer\NanoCorona.svg"
$iconOutput = Join-Path $RepoRoot "installer\NanoCorona.ico"
& $magick.Source $iconSource -background none -define icon:auto-resize=256,128,64,48,32,16 $iconOutput
if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $iconOutput -PathType Leaf)) {
    throw "Icon conversion failed."
}
Copy-Item -LiteralPath $iconOutput -Destination (Join-Path $stage "NanoCorona.ico") -Force

$wizardImage = Join-Path $RepoRoot "installer\NanoCorona-Wizard.bmp"
$wizardSmallImage = Join-Path $RepoRoot "installer\NanoCorona-WizardSmall.bmp"
& $magick.Source $iconSource -background "#0b0f14" -gravity center -resize "140x140" -extent 164x314 -colorspace sRGB -type TrueColor $wizardImage
if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $wizardImage -PathType Leaf)) {
    throw "Wizard image generation failed."
}
& $magick.Source $iconSource -background "#0b0f14" -gravity center -resize "48x48" -extent 55x55 -colorspace sRGB -type TrueColor $wizardSmallImage
if ($LASTEXITCODE -ne 0 -or !(Test-Path -LiteralPath $wizardSmallImage -PathType Leaf)) {
    throw "Wizard small image generation failed."
}
Copy-Item -LiteralPath $wizardImage -Destination (Join-Path $stage "NanoCorona-Wizard.bmp") -Force
Copy-Item -LiteralPath $wizardSmallImage -Destination (Join-Path $stage "NanoCorona-WizardSmall.bmp") -Force

$zip = Join-Path $OutputDir "NanoCorona.zip"
if (Test-Path -LiteralPath $zip) {
    Remove-Item -LiteralPath $zip -Force
}
Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip -CompressionLevel Optimal

$iss = Join-Path $RepoRoot "installer\NanoCorona.iss"
& $iscc.Source /DAppVersion="$Version" /DSourceDir="$stage" /DOutputDir="$OutputDir" $iss
if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup build failed."
}

$setup = Join-Path $OutputDir "NanoCorona-Setup.exe"
if (!(Test-Path -LiteralPath $setup -PathType Leaf)) {
    throw "NanoCorona-Setup.exe was not produced."
}

Write-Host "Release ZIP: $zip" -ForegroundColor Green
Write-Host "Windows installer: $setup" -ForegroundColor Green
