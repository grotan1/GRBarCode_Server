program BarCode_Server;

uses
  Vcl.Forms,
  MainBarCodeServer in 'MainBarCodeServer.pas' {MainForm} ,
  grg in 'grg.pas';

{$R *.res}

begin
  Application.Initialize;
  // Application.ShowMainForm := False;
  Application.MainFormOnTaskbar := true;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;

end.
