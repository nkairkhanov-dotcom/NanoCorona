# NanoCorona

**AI image editing inside 3ds Max + Corona.**

NanoCorona sends a Corona render and technical passes to Nano Banana / Gemini and returns an AI-edited result without leaving 3ds Max.

## 👤 For users

**Requirements**

- Windows 10/11 x64
- 3ds Max 2026
- Corona 15
- Gemini API key
- Internet connection

### Install

1. Open **Releases**.
2. Download **NanoCorona-Setup.exe**.
3. Double-click it.
4. Click **Install**.
5. Restart 3ds Max 2026.

That's it.

You do **not** need:

- Git
- Visual Studio
- .NET SDK
- manual copying of MAXScript files
- administrator rights

### Update

Download the newest **NanoCorona-Setup.exe** from Releases and run it again.

The installer automatically repairs/updates the existing installation. Your Gemini API key is kept separately.

### Uninstall

Use **Windows Settings → Apps → Installed apps → NanoCorona → Uninstall**.

## 📦 Downloads

- **NanoCorona-Setup.exe** — recommended for normal users.
- **NanoCorona.zip** — portable/manual package for developers and troubleshooting.

[Open NanoCorona Releases](https://github.com/nkairkhanov-dotcom/NanoCorona/releases)

## 🧑‍💻 Development

The project is currently targeting **3ds Max 2026 + Corona 15**.

Core pipeline:

    Corona
       ↓
    Beauty + Z-Depth + Normals + Architecture Mask
       ↓
    Scene.json
       ↓
    NanoNetwork (.NET 8)
       ↓
    Gemini / Nano Banana
       ↓
    AI result + QA

### Documentation

- [Installation](docs/INSTALL.md)
- [User Guide](docs/USER_GUIDE.md)
- [Compatibility](docs/COMPATIBILITY.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Technical Specification](docs/TECHNICAL_SPEC.md)
- [Development Plan](docs/DEVELOPMENT_PLAN.md)

The repository remains the source of truth for technical specifications, schemas and implementation details.

## 🚀 Creating a release

For the maintainer, releases are intentionally simple:

1. Open **Actions**.
2. Select **Build NanoCorona release**.
3. Click **Run workflow**.
4. Enter a version such as **1.0.0**.
5. Click **Run workflow**.

GitHub builds and validates the installer, then creates the Release with:

- `NanoCorona-Setup.exe`
- `NanoCorona.zip`

No manual packaging is required.

## Current status

The installer and packaging pipeline are ready. Final production acceptance still requires live testing on a machine with **3ds Max 2026 + Corona 15**.
