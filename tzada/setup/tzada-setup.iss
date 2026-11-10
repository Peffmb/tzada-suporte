; Instalador Tzada Suporte (Inno Setup 6).
; Não instala arquivos por conta própria: extrai o app para uma pasta temporária e chama
; "Tzada.exe --silent-install", que faz a instalação completa do próprio app
; (serviço do Windows, atalhos, registro e desinstalador em Program Files\Tzada).
; Compilar: iscc /DAppVersion=1.5.3 /DSourceDir=<pasta do build> tzada-setup.iss

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\rustdesk"
#endif

[Setup]
AppId={{6E2B1F0C-3A7D-4C55-9C3E-5A1D2F7B9E41}
AppName=Tzada Suporte
AppVersion={#AppVersion}
AppVerName=Tzada Suporte {#AppVersion}
AppPublisher=Tzada
AppPublisherURL=https://desk.tzada.org
AppSupportURL=https://desk.tzada.org
VersionInfoCompany=Tzada
VersionInfoDescription=Instalador do Tzada Suporte
VersionInfoProductName=Tzada Suporte
VersionInfoVersion={#AppVersion}
CreateAppDir=no
Uninstallable=no
DisableProgramGroupPage=yes
DisableReadyPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
WizardStyle=modern
WizardImageFile=wizard-164.bmp,wizard-410.bmp
WizardSmallImageFile=wizard-small-55.bmp,wizard-small-138.bmp
SetupIconFile=..\..\res\icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
OutputDir=..\..\SignOutput
OutputBaseFilename=Tzada-Suporte-Setup
CloseApplications=no
RestartApplications=no

[Languages]
Name: "pt"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Messages]
pt.WelcomeLabel1=Bem-vindo ao Tzada Suporte
pt.WelcomeLabel2=Este assistente vai instalar o Tzada Suporte no seu computador.%n%nDepois de instalado, é só abrir o Tzada e passar o ID e a senha para o atendente da Tzada.
pt.FinishedHeadingLabel=Tudo pronto!
pt.FinishedLabelNoIcons=O Tzada Suporte foi instalado. Abra o programa e passe o ID e a senha que aparecem na tela para o atendente.
pt.FinishedLabel=O Tzada Suporte foi instalado. Abra o programa e passe o ID e a senha que aparecem na tela para o atendente.

[Files]
Source: "{#SourceDir}\*"; DestDir: "{tmp}\tzada-payload"; Flags: recursesubdirs createallsubdirs ignoreversion deleteafterinstall

[Run]
Filename: "{tmp}\tzada-payload\Tzada.exe"; Parameters: "--silent-install"; StatusMsg: "Instalando o Tzada Suporte..."; Flags: runhidden waituntilterminated
Filename: "{autopf}\Tzada\Tzada.exe"; Description: "Abrir o Tzada agora"; Flags: postinstall nowait skipifsilent runasoriginaluser

[Code]
procedure KillTzada();
var
  Code: Integer;
begin
  { para o serviço e fecha qualquer Tzada aberto (instalado ou sem instalar) antes de instalar }
  Exec(ExpandConstant('{sys}\sc.exe'), 'stop Tzada', '', SW_HIDE, ewWaitUntilTerminated, Code);
  Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /IM Tzada.exe', '', SW_HIDE, ewWaitUntilTerminated, Code);
  Sleep(1500);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  KillTzada();
  Result := '';
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if not FileExists(ExpandConstant('{autopf}\Tzada\Tzada.exe')) then
      MsgBox('Não foi possível concluir a instalação do Tzada. Tente executar o instalador novamente ou fale com o atendente.', mbError, MB_OK);
  end;
end;
