#ifndef AppVersion
#define AppVersion "0.1.0"
#endif

#ifndef SourceDir
#define SourceDir "dist\\NanoCorona"
#endif

#define AppName "NanoCorona"
#define AppPublisher "NanoCorona"

[Setup]
AppId={{7B6D2E40-8B9B-4E9D-9D9D-5D5D5B4A0A26}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
VersionInfoVersion={#AppVersion}
VersionInfoProductVersion={#AppVersion}
VersionInfoTextVersion={#AppVersion}
VersionInfoProductName={#AppName}
VersionInfoCompany={#AppPublisher}
DefaultDirName={localappdata}\NanoCorona
SetupIconFile={#SourceDir}\NanoCorona.ico
UninstallDisplayIcon={app}\NanoCorona.ico
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir={#OutputDir}
OutputBaseFilename=NanoCorona-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
Uninstallable=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Files]
Source: "{#SourceDir}\NanoCorona.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\\runtime\\*"; DestDir: "{app}\\runtime"; Flags: recursesubdirs ignoreversion
Source: "{#SourceDir}\\NanoCorona_VFB_Prototype.ms"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\\NanoCorona_RenderExtraction.ms"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\\NanoCorona_Toolbar.ms"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\\Install-NanoCorona.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\\Uninstall-NanoCorona.ps1"; DestDir: "{app}"; Flags: ignoreversion

[Run]
Filename: "{sys}\\WindowsPowerShell\\v1.0\\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\\Install-NanoCorona.ps1"" -PackageRoot ""{app}"""; Flags: runhidden waituntilterminated; StatusMsg: "Installing NanoCorona into 3ds Max..."

[UninstallRun]
Filename: "{sys}\\WindowsPowerShell\\v1.0\\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\\Uninstall-NanoCorona.ps1"""; Flags: runhidden waituntilterminated

[Code]
function GetMax2026Root(): String;
begin
  Result := ExpandConstant('{localappdata}\\Autodesk\\3dsMax\\2026 - 64bit');
end;

function InitializeSetup(): Boolean;
begin
  Result := True;
  if not DirExists(GetMax2026Root()) then begin
    MsgBox('NanoCorona requires Autodesk 3ds Max 2026.' + #13#10 + #13#10 +
      'Install 3ds Max 2026 first, then run this installer again.', mbError, MB_OK);
    Result := False;
  end;
end;
