[Setup]
AppId=LEMATZIUM-Desktop
AppName=LEMATZIUM
AppVersion=1.3.3
AppPublisher=LEMATZIUM
DefaultDirName={localappdata}\Programs\LEMATZIUM
DefaultGroupName=LEMATZIUM
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir=..\release
OutputBaseFilename=LEMATZIUM_Setup_1.3.3
SetupIconFile=..\release\app\build_assets\icons\lematzium_default.ico
UninstallDisplayIcon={app}\LEMATZIUM.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes
CloseApplications=yes

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el escritorio"; GroupDescription: "Accesos directos:"

[Files]
Source: "..\release\app\*"; DestDir: "{app}"; Excludes: "config\*,launcher\lematzium_suite_launcher_prefs.json"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\release\app\config\*"; DestDir: "{app}\config"; Flags: onlyifdoesntexist uninsneveruninstall recursesubdirs createallsubdirs
Source: "..\release\app\launcher\lematzium_suite_launcher_prefs.json"; DestDir: "{app}\launcher"; Flags: onlyifdoesntexist uninsneveruninstall skipifsourcedoesntexist

[Icons]
Name: "{group}\LEMATZIUM"; Filename: "{app}\LEMATZIUM.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\LEMATZIUM"; Filename: "{app}\LEMATZIUM.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\LEMATZIUM.exe"; Description: "Abrir LEMATZIUM"; Flags: nowait postinstall skipifsilent
