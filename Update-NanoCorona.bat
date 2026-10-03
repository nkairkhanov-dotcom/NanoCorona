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
set "REPO_URL=https://github.com/nkairkhanov-dotcom/NanoCorona.git"

echo [1/4] Downloading latest NanoCorona from GitHub...
if exist "%UPDATE_DIR%" rmdir /s /q "%UPDATE_DIR%"
rem Find Git even when it was installed after this terminal was opened.
if exist "%ProgramFiles%\Git\cmd\git.exe" set "PATH=%ProgramFiles%\Git\cmd;%PATH%"
if exist "%ProgramFiles(x86)%\Git\cmd\git.exe" set "PATH=%ProgramFiles(x86)%\Git\cmd;%PATH%"
if exist "%LOCALAPPDATA%\Programs\Git\cmd\git.exe" set "PATH=%LOCALAPPDATA%\Programs\Git\cmd;%PATH%"
if exist "%USERPROFILE%\scoop\apps\git\current\cmd\git.exe" set "PATH=%USERPROFILE%\scoop\apps\git\current\cmd;%PATH%"
where git.exe >nul 2>&1
if not errorlevel 1 goto :git_ready
echo Git was not found. Installing Git for Windows automatically...
where winget.exe >nul 2>&1
if errorlevel 1 goto :no_winget
winget.exe install --id Git.Git --scope user --silent --accept-package-agreements --accept-source-agreements
if errorlevel 1 goto :error
set "PATH=%LOCALAPPDATA%\Programs\Git\cmd;%ProgramFiles%\Git\cmd;%PATH%"
if exist "%ProgramFiles%\Git\cmd\git.exe" set "PATH=%ProgramFiles%\Git\cmd;%PATH%"
if exist "%LOCALAPPDATA%\Programs\Git\cmd\git.exe" set "PATH=%LOCALAPPDATA%\Programs\Git\cmd;%PATH%"
where git.exe >nul 2>&1
if errorlevel 1 goto :git_not_found
:git_ready
git.exe clone --depth 1 --branch main "%REPO_URL%" "%UPDATE_DIR%"
if errorlevel 1 goto :error
set "REPO_ROOT=%UPDATE_DIR%"
if not exist "%REPO_ROOT%\installer\Install-NanoCorona-OneClick.ps1" goto :error

echo [2/4] Update source downloaded.

echo [3/4] Building and installing...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%REPO_ROOT%\installer\Install-NanoCorona-OneClick.ps1" -RepoRoot "%REPO_ROOT%"
if errorlevel 1 goto :error

echo.
echo [4/4] Cleaning temporary files...
rmdir /s /q "%UPDATE_DIR%" >nul 2>&1

echo.
echo ==============================================
echo  NanoCorona update complete!
echo ==============================================
echo.
echo Restart 3ds Max 2026 before using the update.
echo.
pause
exit /b 0

:no_winget
echo.
echo Git and Windows Package Manager (winget) were not found.
echo Please install Git for Windows manually.
echo.
goto :error

:git_not_found
echo.
echo Git installation completed, but git.exe was not found in the expected location.
echo Please restart this updater once and try again.
echo.
goto :error

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
