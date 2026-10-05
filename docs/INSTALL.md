# NanoCorona: one-click installation

## For a normal user

The recommended installation is now a normal Windows installer:

1. Download **NanoCorona-Setup.exe** from the GitHub Release.
2. Close 3ds Max.
3. Double-click **NanoCorona-Setup.exe**.
4. Click **Install**.
5. Start 3ds Max 2026 again.

That's it. You do **not** need Git, Visual Studio, the .NET SDK, PowerShell commands, or the NanoCorona source repository.

The installer is **per-user** and does not require administrator rights. It detects the 3ds Max 2026 user-data directory and installs the complete NanoCorona runtime and MAXScript files into every language profile it finds.

It also creates the startup loader automatically, so NanoCorona appears after the next 3ds Max launch.

## Requirements

- Windows 10/11 x64;
- Autodesk 3ds Max 2026;
- Corona 15;
- internet access for Gemini generation;
- a Gemini API key.

The installer does not install Autodesk 3ds Max or Corona.

## Update

The installed project keeps the existing **Update-NanoCorona.bat** workflow for convenience. It downloads the latest **NanoCorona-Setup.exe** and launches the normal installer, so updating uses exactly the same installation path as a fresh install.

You can also simply download the newest setup file from GitHub Releases and run it over the existing installation.

The installer does not remove the encrypted Gemini API key stored for the current Windows user.

## Uninstall

Use Windows **Installed apps / Apps & features → NanoCorona → Uninstall**.

The uninstaller removes NanoCorona files from the 3ds Max 2026 user-data profiles and removes the NanoCorona startup loader. It does not remove 3ds Max, Corona, or unrelated user scripts.

## Developer / release maintainer

Developers still build the distributable package with:

```powershell
powershell -ExecutionPolicy Bypass -File .\installer\Build-Release.ps1 -Version 0.1.0
```

The build produces:

- `dist\NanoCorona-Setup.exe` — the recommended end-user installer;
- `dist\NanoCorona.zip` — portable/manual fallback package.

The Windows installer is built with Inno Setup 6. The GitHub Actions release workflow installs the required installer compiler automatically.

## First use

After starting 3ds Max 2026, make sure Corona is the active renderer. The NanoCorona command bar is loaded automatically; use **OPEN NANOCORONA** to open the dockable panel.

On first generation, enter the Gemini API key in **Settings**. NanoCorona stores it encrypted for the current Windows user with Windows DPAPI.
