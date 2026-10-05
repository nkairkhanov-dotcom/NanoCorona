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
UsePreviousAppDir=no
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
Source: "{#SourceDir}\\NanoCorona-MANIFEST.txt"; DestDir: "{app}"; Flags: ignoreversion

[Messages]
WelcomeLabel1=Welcome to NanoCorona {#AppVersion}
WelcomeLabel2=AI-powered image editing for 3ds Max + Corona.\n\nThe installer will set up NanoCorona for your Windows user account. No administrator rights are required.\n\nBefore continuing, close 3ds Max 2026.
FinishedHeadingLabel=NanoCorona is ready
FinishedLabel=NanoCorona {#AppVersion} has been installed or repaired successfully.\n\nRestart 3ds Max 2026 to load NanoCorona.

; Installation is executed from CurStepChanged so a non-zero exit code
; from the post-install verification can abort the installer cleanly.

[Code]
function RunNanoCoronaInstallerScript(): Boolean;
var
  ResultCode: Integer;
  Params: String;
begin
  Params := '-NoProfile -ExecutionPolicy Bypass -File "' + ExpandConstant('{app}\\Install-NanoCorona.ps1') + '" -PackageRoot "' + ExpandConstant('{app}') + '"';
  Result := Exec(ExpandConstant('{sys}\\WindowsPowerShell\\v1.0\\powershell.exe'), Params, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  if not Result then begin
    MsgBox('NanoCorona could not start its installation verification script.', mbError, MB_OK);
    Result := False;
    exit;
  end;

  if ResultCode <> 0 then begin
    MsgBox(
      'NanoCorona installation verification failed.' + #13#10 + #13#10 +
      'The installer will stop because the plugin was not verified successfully.' + #13#10 +
      'Please review the error above and run the installer again.',
      mbError, MB_OK);
    Result := False;
    exit;
  end;

  Result := True;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then begin
    if not RunNanoCoronaInstallerScript() then
      Abort;
  end;
end;

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

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = wpWelcome then begin
    if DirExists(ExpandConstant('{localappdata}\\NanoCorona')) then begin
      WizardForm.WelcomeLabel1.Caption := 'Repair or update NanoCorona {#AppVersion}';
      WizardForm.WelcomeLabel2.Caption :=
        'A previous NanoCorona installation was found.' + #13#10 + #13#10 +
        'Click Next to repair or update the existing installation.' + #13#10 +
        'Your Gemini API key is stored separately and will not be removed.';
    end;
  end;
end;

function GetMax2026Root(): String;
begin
  Result := ExpandConstant('{localappdata}\\Autodesk\\3dsMax\\2026 - 64bit');
end;

function GetMax2026Exe(): String;
var
  EnvPath: String;
  RegPath: String;
begin
  Result := '';

  // Autodesk creates this environment variable for the installed 3ds Max.
  EnvPath := GetEnv('ADSK_3DSMAX_x64_2026');
  if (EnvPath <> '') and FileExists(AddBackslash(EnvPath) + '3dsmax.exe') then
    Result := AddBackslash(EnvPath) + '3dsmax.exe';

  // Standard Autodesk installation location.
  if (Result = '') then begin
    RegPath := ExpandConstant('{autopf}\\Autodesk\\3ds Max 2026\\3dsmax.exe');
    if FileExists(RegPath) then
      Result := RegPath;
  end;

  // Autodesk registry location. 28.0 is the internal major version for Max 2026.
  if (Result = '') then begin
    if RegQueryStringValue(HKLM, 'SOFTWARE\\Autodesk\\3dsMax\\28.0\\MAX-1:409', 'InstallDir', RegPath) then begin
      RegPath := AddBackslash(RegPath) + '3dsmax.exe';
      if FileExists(RegPath) then
        Result := RegPath;
    end;
  end;
end;

function GetCorona2026Root(): String;
var
  EnvPath: String;
begin
  Result := '';

  // Chaos supports selecting a specific Corona build for a Max version
  // through this multiloaders environment variable.
  EnvPath := GetEnv('CORONA_3DSMAX_2026_LOAD_PATH');
  if (EnvPath <> '') and
     FileExists(AddBackslash(EnvPath) + 'Corona_Release.dll') and
     FileExists(AddBackslash(EnvPath) + 'CoronaMax_Release-2026.dll') then
    Result := EnvPath;

  // Current standard Chaos installation path.
  if (Result = '') then begin
    Result := ExpandConstant('{autopf}\Chaos\Corona\Corona Renderer for 3ds Max\2026');
    if (not FileExists(AddBackslash(Result) + 'Corona_Release.dll')) or
       (not FileExists(AddBackslash(Result) + 'CoronaMax_Release-2026.dll')) then
      Result := '';
  end;

  // Legacy Corona installation path, retained as a fallback for older
  // installations. It is still checked for compatibility, but version 15
  // is required below.
  if (Result = '') then begin
    Result := ExpandConstant('{autopf}\Corona\Corona Renderer for 3ds Max\2026');
    if (not FileExists(AddBackslash(Result) + 'Corona_Release.dll')) or
       (not FileExists(AddBackslash(Result) + 'CoronaMax_Release-2026.dll')) then
      Result := '';
  end;
end;

function GetCoronaMajorVersion(const CoronaDll: String): Integer;
var
  MS, LS: Cardinal;
begin
  Result := 0;
  if GetVersionNumbers(CoronaDll, MS, LS) then
    Result := MS shr 16;
end;

function InitializeSetup(): Boolean;
var
  MaxExe: String;
  CoronaRoot: String;
  CoronaDll: String;
  CoronaVersion: Integer;
begin
  Result := True;

  MaxExe := GetMax2026Exe();
  if MaxExe = '' then begin
    MsgBox(
      'NanoCorona requires Autodesk 3ds Max 2026.' + #13#10 + #13#10 +
      '3ds Max 2026 was not found on this computer.' + #13#10 +
      'Please install 3ds Max 2026 and run this installer again.',
      mbError, MB_OK);
    Result := False;
    exit;
  end;

  CoronaRoot := GetCorona2026Root();
  if CoronaRoot = '' then begin
    MsgBox(
      'NanoCorona requires Corona 15 for 3ds Max 2026.' + #13#10 + #13#10 +
      'Corona for 3ds Max 2026 was not found.' + #13#10 +
      'Please install Corona 15 for 3ds Max 2026 and run this installer again.',
      mbError, MB_OK);
    Result := False;
    exit;
  end;

  CoronaDll := AddBackslash(CoronaRoot) + 'Corona_Release.dll';
  CoronaVersion := GetCoronaMajorVersion(CoronaDll);

  if CoronaVersion <> 15 then begin
    MsgBox(
      'NanoCorona requires Corona 15 for 3ds Max 2026.' + #13#10 + #13#10 +
      'An older Corona version was detected (' + IntToStr(CoronaVersion) + ').' + #13#10 +
      'Please update Corona to version 15 and run this installer again.',
      mbError, MB_OK);
    Result := False;
    exit;
  end;
end;
