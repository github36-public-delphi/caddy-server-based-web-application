unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.OleCtrls, SHDocVw, acWebBrowser, EwbCore, EmbeddedWB,
  SHDocVw_EWB, System.StrUtils, System.Math, ComObj, ActiveX ,Clipbrd, ShellApi,
  sSkinManager, Vcl.ExtCtrls, sPanel, Vcl.ComCtrls, acHeaderControl,
  Vcl.StdCtrls, sButton, Tlhelp32, acArcControls;


type
  TForm1 = class(TForm)
    Browser: TEmbeddedWB;
    sSkinManager1: TsSkinManager;
    Timer1: TTimer;
    Preloader: TsArcPreloader;
 procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Timer1Timer(Sender: TObject);
    procedure sButton2Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;



var
  Form1: TForm1;
//����� ����������
full_path_to_folder:string;
vbs_file_path,caddy_file_path:string;
output_string_list:TStringlist; //������ ��� ������ � ����
output_file_path:string; //���� ��� �����
timer_seconds_count:integer;

implementation

{$R *.dfm}


//������� �������� ��������� ��������� (�������) � ������
function CountPos(const subtext: string; Text: string): Integer;
begin
if (Length(subtext)=0) or (Length(Text)=0) or (Pos(subtext, Text)=0) then
Result:=0
else
Result:=(Length(Text)-Length(StringReplace(Text, subtext, '', [rfReplaceAll]))) div
Length(subtext);
end;

//������� ��������� ����������� ����� ������  (��� Delphi 10)
function get_stext(First, Second, Where: string): string;
var
Pos1, Pos2: Integer;
WhereLower: string;
begin
First:=LowerCase(First);
Second:=LowerCase(Second);
WhereLower:=LowerCase(Where);
Assert(Length(WhereLower) = Length(Where));
Pos1:=PosEx(First, WhereLower, 1);
Pos2:=PosEx(Second, WhereLower, Pos1);
Result:=Copy(Where, Pos1 + Length(First), Pos2 - Pos1 - Length(First));
end;


function FindTask(ExeFileName: string): integer;
 var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
 begin
  result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := Sizeof(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
  while integer(ContinueLoop) <> 0 do
   begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(ExeFileName))
     or (UpperCase(FProcessEntry32.szExeFile) = UpperCase(ExeFileName)))
      then Result := 1;
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
   end;
  CloseHandle(FSnapshotHandle);
 end;

//��������� ���� �������� � ���������� �������� �����
procedure set_preloader_position();
begin
if (form1.Preloader <> nil) then
begin
form1.Preloader.Left:=(form1.Width div 2)-90;
form1.Preloader.Top:=(form1.Height div 2)-90;
end;
end;

//��������� ���� �������� � ���������� �������� �����
procedure set_form_settings();
var
settings_file:TextFile;
path_to_file,current_string:string;
FORM_CAPTION, FORM_WIDTH, FORM_HEIGHT, FORM_BORDER_STYLE, FORM_WINDOW_STATE, FORM_SHOW_MINIMIZE_ICON, FORM_SHOW_MAXIMIZE_ICON:string;
begin
//���� � ����� ��������
try
path_to_file:=ExtractFileDir(ParamStr(0))+'\settings.xml';
AssignFile (settings_file, path_to_file);
Reset (settings_file);
while not EOF(settings_file) do
begin
//������ ������
readln(settings_file, current_string);
//�������� ���������
if (CountPos('<FORM_CAPTION>',current_string)>0) then FORM_CAPTION:=get_stext('<FORM_CAPTION>','</FORM_CAPTION>',current_string);
if (CountPos('<FORM_WIDTH>',current_string)>0) then FORM_WIDTH:=get_stext('<FORM_WIDTH>','</FORM_WIDTH>',current_string);
if (CountPos('<FORM_HEIGHT>',current_string)>0) then FORM_HEIGHT:=get_stext('<FORM_HEIGHT>','</FORM_HEIGHT>',current_string);
if (CountPos('<FORM_BORDER_STYLE>',current_string)>0) then FORM_BORDER_STYLE:=get_stext('<FORM_BORDER_STYLE>','</FORM_BORDER_STYLE>',current_string);
if (CountPos('<FORM_WINDOW_STATE>',current_string)>0) then FORM_WINDOW_STATE:=get_stext('<FORM_WINDOW_STATE>','</FORM_WINDOW_STATE>',current_string);
if (CountPos('<FORM_SHOW_MINIMIZE_ICON>',current_string)>0) then FORM_SHOW_MINIMIZE_ICON:=get_stext('<FORM_SHOW_MINIMIZE_ICON>','</FORM_SHOW_MINIMIZE_ICON>',current_string);
if (CountPos('<FORM_SHOW_MAXIMIZE_ICON>',current_string)>0) then FORM_SHOW_MAXIMIZE_ICON:=get_stext('<FORM_SHOW_MAXIMIZE_ICON>','</FORM_SHOW_MAXIMIZE_ICON>',current_string);
end;
CloseFile (settings_file);
except
MessageBox(0, PChar('������. ���� �������� (settings.xml) �� ������.'),PChar('���������'),MB_OK);
end;
//������������� �������� �����
form1.Width:=strtoint(FORM_WIDTH);
form1.Height:=strtoint(FORM_HEIGHT);
form1.Caption:=FORM_CAPTION;
if (FORM_BORDER_STYLE='Sizeable') then form1.BorderStyle:=bsSizeable;
if (FORM_BORDER_STYLE='Single') then form1.BorderStyle:=bsSingle;
if (FORM_WINDOW_STATE='Normal') then form1.WindowState:=wsNormal;
if (FORM_WINDOW_STATE='Maximized') then form1.WindowState:=wsMaximized;

if (FORM_SHOW_MINIMIZE_ICON='1') then
Form1.BorderIcons := Form1.BorderIcons + [biMinimize]
else
Form1.BorderIcons := Form1.BorderIcons - [biMinimize];

if (FORM_SHOW_MAXIMIZE_ICON='1') then
Form1.BorderIcons := Form1.BorderIcons + [biMaximize]
else
Form1.BorderIcons := Form1.BorderIcons - [biMaximize];



end;




procedure TForm1.FormCreate(Sender: TObject);
begin
timer_seconds_count:=0; //������� ������
set_form_settings();
set_preloader_position();
vbs_file_path:=ExtractFileDir(ParamStr(0))+'\start_caddy.vbs';
//��������� ������
ShellExecute(Handle, 'open',PWideChar(vbs_file_path), 'wscript //nologo' , nil, SW_SHOWNORMAL);
end;




procedure TForm1.FormResize(Sender: TObject);
begin
set_preloader_position();
end;



procedure TForm1.sButton2Click(Sender: TObject);
begin
ShellExecute(Self.Handle,'open',pchar(ExtractFilePath(Application.ExeName)+'web_app\'),nil,nil,SW_SHOWNORMAL);
end;



procedure TForm1.Timer1Timer(Sender: TObject);
begin
//����� ������ �������
timer_seconds_count:=timer_seconds_count+1;

//���� �������� �������� - ���������� �������� � ��������
if (FindTask('caddy.exe')=1) and (FindTask('php-cgi.exe')=1) then
begin
Browser.Visible:=true;
Browser.Navigate('127.0.0.1');
form1.Preloader.Destroy;
Timer1.Enabled:=false;
end;

//�������� ������ ���������� ����� ��� �� 15 ������ (������ �����������)����� ������� ���������
if (timer_seconds_count>15) then
begin
Preloader.Visible:=false;
form1.Preloader.Destroy;
Timer1.Enabled:=false;
MessageBox(0, PChar('������ ������� ���������. ��������� �� ������ ��������� �������� caddy.exe �/��� php-cgi.exe. ���������� ��������� �� ������� �� ����� ��������� � ������ ������� ������. ��������, ������� ��������� ����������������� ������ Visual C++ (vc_redist.x64)'),PChar('������'),MB_OK);
end;




end;




procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
//������������� ������ (������� ��� �������� ��������� � �������� � ��� ��������)
WinExec('taskkill /f /im caddy.exe',SW_HIDE);
WinExec('taskkill /f /im php-cgi.exe',SW_HIDE);
end;













end.
