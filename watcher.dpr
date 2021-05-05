program watcher;

uses
  Forms,
  watcher_unit in 'watcher_unit.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Watcher';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
