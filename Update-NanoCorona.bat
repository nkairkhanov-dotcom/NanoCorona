@echo off
setlocal EnableExtensions

title NanoCorona Updater

set "UPDATE_DIR=%TEMP%\NanoCorona-update"
set "RELEASE_URL=https://github.com/nkairkhanov-dotcom/NanoCorona/releases/latest/download/NanoCorona.zip"

echo.
echo ==============================================
echo  NanoCorona Updater
echo  Downloading ready-to-install release package
echo ==============================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop'; " ^
  "$updateDir = '%UPDATE_DIR%'; " ^
  "$zipPath = Join-Path $updateDir 'NanoCorona.zip'; " ^
  "if (Test-Path $updateDir) { Remove-Item -LiteralPath $updateDir -Recurse -Force }; " ^
  "New-Item -ItemType Directory -Path $updateDir | Out-Null; " ^
  "Invoke-WebRequest -Uri '%RELEASE_URL%' -OutFile $zipPath; " ^
  "Expand-Archive -LiteralPath $zipPath -DestinationPath $updateDir -Force; " ^
  "$installer = Join-Path $updateDir 'Install-NanoCorona.ps1'; " ^
  "if (!(Test-Path $installer)) { throw 'The downloaded release package is incomplete.' }; " ^
  "& $installer -PackageRoot $updateDir; " ^
  "Remove-Item -LiteralPath $updateDir -Recurse -Force"

if errorlevel 1 goto :error

echo.
echo NanoCorona update complete. Restart 3ds Max 2026.
pause
exit /b 0

:error
echo.
echo NanoCorona update failed. Check your internet connection and release availability.
pause
exit /b 1
