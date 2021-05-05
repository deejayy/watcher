{$O-}
unit watcher_unit;

interface

uses
	Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
	Dialogs, ExtCtrls, StdCtrls, CoolTrayIcon, Menus, Registry, PsApi;

const
	NOTIFY_FOR_ALL_SESSIONS  = 1;
	NOTIFY_FOR_THIS_SESSIONS = 0;

type
	TMainForm = class(TForm)
    timer: TTimer;
    SendToTray: TButton;
    cti: TCoolTrayIcon;
    menu: TPopupMenu;
    Quit: TMenuItem;
    stw: TCheckBox;
	procedure FormCreate(Sender: TObject);
    procedure timerTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ctiClick(Sender: TObject);
    procedure SendToTrayClick(Sender: TObject);
    procedure QuitClick(Sender: TObject);
    procedure stwClick(Sender: TObject);
	private
		{ Private declarations }
	public
		fname: string;
		currwin: string;
		procedure alog(s: string);
		procedure msg(var Msg: TMessage); message WM_WTSSESSION_CHANGE;
		function sendtowa(msg: cardinal; wparam: integer; lparam: integer): boolean;
		function pause: boolean;
		function startplay: boolean;
		{ Public declarations }
	end;

var
	MainForm: TMainForm;

function WTSRegisterSessionNotification(hWnd: HWND; dwFlags: DWORD): BOOL; stdcall;
function WTSUnRegisterSessionNotification(hWND: HWND): BOOL; stdcall;

implementation

{$R *.dfm}

uses TlHelp32;

type
	wrec = record
		exename: string;
		dispname: string;
		run: boolean;
	end;

var
  reg: tregistry;

function WTSRegisterSessionNotification; external 'wtsapi32.dll' Name 'WTSRegisterSessionNotification';
function WTSUnRegisterSessionNotification; external 'wtsapi32.dll' Name 'WTSUnRegisterSessionNotification';

function TMainForm.SendToWA(Msg: Cardinal; wParam: integer; lParam: integer): boolean;
var
	Handle: HWND;
begin
	Handle:=FindWindow('Winamp v1.x',nil);
	if Handle<>0 then begin
		SendMessage(Handle, Msg, wParam, lParam);
		Result:=true;
	end
	else Result:=false;
end;

function TMainForm.Pause: boolean;
begin
	Result:=SendToWA(WM_COMMAND,40046,0);
end;

function TMainForm.StartPlay: boolean;
begin
	Result:=SendToWA(WM_COMMAND,40045,0);
end;

procedure TMainForm.msg(var Msg: TMessage);
const
	lt : array[0..10] of string = ('0', 'Console connect', 'Console disconnect', 'Remote connect', 'Remote disconnect', 'Session logon', 'Session logoff', 'Session lock', 'Session unlock', 'Session remote control', '10');
begin
	alog(lt[msg.wparam]);
	pause;
end;

procedure TMainForm.alog(s: string);
var
	f: textfile;
	tf: TFormatSettings;
begin
	GetLocaleFormatSettings(LOCALE_SYSTEM_DEFAULT, tf);
	tf.ShortDateFormat := 'yyyy-MM-dd';
    {$I-}
	assignfile(f, fname);
	if not fileexists(fname) then rewrite(f);
	append(f);
	writeln(f, format( '%s' + #09 + '%s', [datetimetostr(now, tf), s]));
	closefile(f);
    {$I+}
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
	fname := ExtractFilePath(paramstr(0))+'\watcher.log';
	alog('Startup');

	WTSRegisterSessionNotification(Handle, NOTIFY_FOR_ALL_SESSIONS);

  reg := tregistry.Create;

  reg.RootKey := HKEY_CURRENT_USER;
  reg.OpenKey('Software\Microsoft\Windows\Currentversion\Run', false);
  if reg.ValueExists('Watcher') then
    stw.checked := (reg.ReadString('Watcher') = paramstr(0))
  else stw.checked := false;
  reg.CloseKey;

end;

function GetCurrentActiveProcessPath: String;
var
  pid     : DWORD;
  hProcess: THandle;
  path    : array[0..255] of Char;
begin
  fillchar(path, length(path), 0);
  GetWindowThreadProcessId(GetForegroundWindow, pid);

  hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, FALSE, pid);
  if hProcess <> 0 then
    try
      if GetModuleFileNameEx(hProcess, 0, @path[0], Length(path)) = 0 then
        result := '-';

      result := path;
    finally
      CloseHandle(hProcess);
    end
  else
    result := '-'
end;

procedure TMainForm.timerTimer(Sender: TObject);
var
	str, fname: string;
    fg, pid, hProcess: longint;
begin
	setlength(str, 255);
	setlength(fname, 255);
    fg := GetForegroundWindow;
    pid := GetWindowThreadProcessId(fg);
	GetWindowText(fg, pansichar(str), 255);

    hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, FALSE, pid);
    GetModuleFileNameEx(hProcess, 0, pansichar(fname), 255);
	CloseHandle(hProcess);

	str := pchar(str) + #09 + inttostr(pid);
	if (currwin <> str) then begin
		alog(pchar(str) + #09 + ExtractFileName(GetCurrentActiveProcessPath));
	end;
	currwin := str;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	alog('Shutdown');
end;

procedure TMainForm.ctiClick(Sender: TObject);
begin
	Application.Restore;
end;

procedure TMainForm.SendToTrayClick(Sender: TObject);
begin
	Application.Minimize;
end;

procedure TMainForm.QuitClick(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.stwClick(Sender: TObject);
begin
  reg.RootKey := HKEY_CURRENT_USER;
  reg.CloseKey;
  reg.OpenKey('Software\Microsoft\Windows\Currentversion\Run', false);
  if stw.checked then begin
    try begin
      reg.WriteString('Watcher', paramstr(0));
      alog('Start with windows set');
    end except on e:exception do
      showmessage('Nem beállítható!');
    end;
  end else begin
    try begin
      reg.DeleteValue('Watcher');
      alog('Start with windows unset');
    end except on e:exception do
      showmessage('Nem törölhetõ a beállítás!');
    end;
  end;
end;

end.
