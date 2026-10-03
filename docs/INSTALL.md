# NanoCorona: one-click installation

## What the user needs

- Windows 10/11 x64;
- Autodesk 3ds Max 2026 and Corona 15;
- a NanoCorona release ZIP;
- a Gemini API key for generation.

The user does **not** need Git, the .NET SDK, Visual Studio, or the source repository.

## Install

1. Download and unpack `NanoCorona.zip` from the project release page.
2. Close 3ds Max if it is running.
3. Double-click `Install-NanoCorona.cmd`.
4. Restart 3ds Max 2026.

The installer copies the ready-built .NET runtime and both MAXScript modules into every discovered 3ds Max 2026 language directory under:

```text
%LOCALAPPDATA%\Autodesk\3dsMax\2026 - 64bit\<language>\scripts\NanoCorona
```

It also writes the startup loader into the matching `scripts\startup` directory. On the next launch it adds the native dockable **NanoCorona** command bar at the top of 3ds Max. Its **OPEN NANOCORONA** / **HIDE NANOCORONA** button opens or hides the right-docked NanoCorona panel. Existing plugin files are replaced; the encrypted Gemini API key is retained.

## Update

Close 3ds Max and double-click `Update-NanoCorona.bat`. It downloads the latest release ZIP, installs it, and removes the temporary package. It does not clone GitHub, install software, or build C# code.

## Build a distributable package

This is only for the developer/release maintainer. With the .NET 8 SDK installed, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\installer\Build-Release.ps1
```

The command produces `dist\NanoCorona.zip`. That ZIP contains a `runtime` directory with `NanoNetwork.dll` and all required managed dependencies, the MAXScript files, the one-click installer, and the updater.

To publish that ZIP for automatic updates, push a version tag such as `v0.1.0`. GitHub Actions builds the package and attaches `NanoCorona.zip` to the matching GitHub Release.

## First use

After starting 3ds Max, use the **OPEN NANOCORONA** button in the NanoCorona command bar with Corona 15 as the active renderer. Enter the Gemini API key in **Settings**; NanoCorona saves it for the current Windows user with Windows DPAPI.
