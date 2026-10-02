@echo off
setlocal EnableExtensions

title NanoCorona Updater

echo.
echo ==============================================
echo  NanoCorona Updater
echo  3ds Max 2026 + Corona 15
echo ==============================================
echo.

set "UPDATE_DIR=%TEMP%\NanoCorona-update"
set "ZIP_FILE=%TEMP%\NanoCorona-main.zip"
set "REPO_URL=https://github.com/nkairkhanov-dotcom/NanoCorona/archive/refs/heads/main.zip"

echo [1/4] Downloading latest NanoCorona from GitHub...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "if (Test-Path '%ZIP_FILE%') { Remove-Item '%ZIP_FILE%' -Force }; Invoke-WebRequest -Uri '%REPO_URL%' -OutFile '%ZIP_FILE%'"
if errorlevel 1 goto :error

echo [2/4] Extracting update...
if exist "%UPDATE_DIR%" rmdir /s /q "%UPDATE_DIR%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%UPDATE_DIR%' -Force"
if errorlevel 1 goto :error

set "REPO_ROOT=%UPDATE_DIR%\NanoCorona-main"
if not exist "%REPO_ROOT%\installer\Install-NanoCorona-OneClick.ps1" goto :error

echo [3/4] Building and installing...
echo .NET 8 SDK version check is intentionally skipped.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%REPO_ROOT%\installer\Install-NanoCorona-OneClick.ps1" -RepoRoot "%REPO_ROOT%" -SkipDotNetInstall
if errorlevel 1 goto :error

echo.
echo [4/4] Cleaning temporary files...
rmdir /s /q "%UPDATE_DIR%" >nul 2>&1
del /q "%ZIP_FILE%" >nul 2>&1

echo.
echo ==============================================
echo  NanoCorona update complete!
echo ==============================================
echo.
echo Restart 3ds Max 2026 before using the update.
echo.
pause
exit /b 0

:error
echo.
echo ==============================================
echo  NanoCorona update FAILED
echo ==============================================
echo.
echo Check the error above.
echo.
pause
exit /b 1
