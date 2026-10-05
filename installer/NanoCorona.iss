#ifndef AppVersion
#define AppVersion "0.1.0"
#endif

#ifndef SourceDir
#define SourceDir "dist\\NanoCorona"
#endif

#ifndef WizardImageFile
#define WizardImageFile "{#SourceDir}\\NanoCorona-Wizard.bmp"
#endif

#ifndef WizardSmallImageFile
#define WizardSmallImageFile "{#SourceDir}\\NanoCorona-WizardSmall.bmp"
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
WizardImageFile={#WizardImageFile}
WizardSmallImageFile={#WizardSmallImageFile}
WizardResizable=no
DisableWelcomePage=no
DisableDirPage=yes
DisableProgramGroupPage=yes
ShowLanguageDialog=no
CloseApplications=no
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

[Messages]
WelcomeLabel1=Welcome to NanoCorona {#AppVersion}
WelcomeLabel2=AI-powered image editing for 3ds Max + Corona.\n\nThe installer will set up NanoCorona for your Windows user account. No administrator rights are required.\n\nBefore continuing, close 3ds Max 2026.
FinishedHeadingLabel=NanoCorona is ready
FinishedLabel=NanoCorona {#AppVersion} has been installed successfully.\n\nRestart 3ds Max 2026 to load NanoCorona.

[Run]
Filename: "{sys}\\WindowsPowerShell\\v1.0\\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\\Install-NanoCorona.ps1"" -PackageRoot ""{app}"""; Flags: runhidden waituntilterminated; StatusMsg: "Installing NanoCorona into 3ds Max..."

[UninstallRun]
Filename: "{sys}\\WindowsPowerShell\\v1.0\\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\\Uninstall-NanoCorona.ps1"""; Flags: runhidden waituntilterminated

[Code]
procedure InitializeWizard;
begin
  WizardForm.Caption := 'NanoCorona {#AppVersion} Setup';
  WizardForm.WelcomeLabel1.Font.Style := [fsBold];
  WizardForm.WelcomeLabel2.AutoSize := False;
  WizardForm.WelcomeLabel2.Height := ScaleY(150);
end;

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
