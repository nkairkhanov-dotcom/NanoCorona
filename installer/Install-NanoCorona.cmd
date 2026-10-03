@echo off
setlocal EnableExtensions

title NanoCorona Installer
set "INSTALLER=%~dp0Install-NanoCorona.ps1"

if not exist "%INSTALLER%" (
    echo NanoCorona installer files are incomplete.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%INSTALLER%"
set "INSTALL_RESULT=%ERRORLEVEL%"

echo.
if not "%INSTALL_RESULT%"=="0" (
    echo NanoCorona installation failed. See the message above.
    pause
    exit /b %INSTALL_RESULT%
)

echo NanoCorona installation completed. Restart 3ds Max 2026.
pause
exit /b 0
