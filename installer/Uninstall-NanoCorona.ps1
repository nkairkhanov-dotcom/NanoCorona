$ErrorActionPreference = "SilentlyContinue"
Set-StrictMode -Version Latest

$maxRoot = Join-Path $env:LOCALAPPDATA "Autodesk\3dsMax\2026 - 64bit"
if (Test-Path $maxRoot) {
    Get-ChildItem $maxRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $scripts = Join-Path $_.FullName "scripts\NanoCorona"
        $startup = Join-Path $_.FullName "scripts\startup\NanoCorona_Startup.ms"

        if (Test-Path $scripts) {
            Remove-Item $scripts -Recurse -Force -ErrorAction SilentlyContinue
        }

        if (Test-Path $startup) {
            Remove-Item $startup -Force -ErrorAction SilentlyContinue
        }
    }
}
