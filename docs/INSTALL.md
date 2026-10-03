# NanoCorona installation: 3ds Max 2026 + Corona 15

## Requirements

- Windows 10 or 11, x64.
- Autodesk 3ds Max 2026 and Corona 15 for 3ds Max.
- A Gemini API key with access to the selected image model.
- .NET 8 SDK when building from this repository.

NanoCorona currently targets this exact 3ds Max/Corona combination. Other Max versions are not claimed compatible by this build.

## Install from the repository

From a PowerShell window at the repository root, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\installer\Install-NanoCorona.ps1
```

The script runs `dotnet build` for `net8.0-windows`, then copies the MAXScript files and the complete NanoNetwork runtime output to each detected 3ds Max 2026 language folder under:

```text
%LOCALAPPDATA%\Autodesk\3dsMax\2026 - 64bit\<language>\scripts\NanoCorona
```

It also creates `NanoCorona_Startup.ms` in the matching `scripts\startup` folder. Restart 3ds Max after installation.

If the .NET 8 SDK is unavailable, install it or build on another machine and provide the complete contents of:

```text
src\NanoNetwork\bin\Release\net8.0-windows\
```

## First use

1. Start 3ds Max 2026 with Corona 15 as the active renderer.
2. Select the building objects that must be protected.
3. Open NanoCorona, run **Setup Depth / Normals / Architecture Mask**, then render again.
4. Choose **Extract Passes + Scene.json**.
5. Open **Settings** and save the Gemini API key. It is encrypted with Windows DPAPI for the current Windows user.
6. Select the edit options and choose **Generate AI**.

The working package and results are written to `%TEMP%\NanoCorona\Current`. The source Corona render is not overwritten.

## Update and removal

Run the installer again after updating the repository, or use `Update-NanoCorona.bat`. The updater installs .NET 8 automatically when needed.

To remove NanoCorona, delete the `scripts\NanoCorona` directory and `NanoCorona_Startup.ms` from every installed 3ds Max 2026 language folder. Credentials are stored separately at `%LOCALAPPDATA%\NanoCorona\credentials.bin` and are not removed by the installer.
