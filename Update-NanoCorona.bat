@echo off
setlocal EnableExtensions

title NanoCorona Updater

set "UPDATE_DIR=%TEMP%\NanoCorona-update"
set "SETUP_URL=https://github.com/nkairkhanov-dotcom/NanoCorona/releases/latest/download/NanoCorona-Setup.exe"
set "SETUP_PATH=%UPDATE_DIR%\NanoCorona-Setup.exe"

echo.
echo ==============================================
echo  NanoCorona Updater
echo  Downloading the latest Windows installer
echo ==============================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference = 'Stop'; " ^
  "$updateDir = '%UPDATE_DIR%'; " ^
  "$setupPath = '%SETUP_PATH%'; " ^
  "if (Test-Path $updateDir) { Remove-Item -LiteralPath $updateDir -Recurse -Force }; " ^
  "New-Item -ItemType Directory -Path $updateDir | Out-Null; " ^
  "Invoke-WebRequest -Uri '%SETUP_URL%' -OutFile $setupPath; " ^
  "if (!(Test-Path $setupPath)) { throw 'NanoCorona installer download failed.' }; " ^
  "Start-Process -FilePath $setupPath -Wait"

if errorlevel 1 goto :error

echo.
echo NanoCorona update installer finished.
exit /b 0

:error
echo.
echo NanoCorona update failed. Check your internet connection and release availability.
pause
exit /b 1
