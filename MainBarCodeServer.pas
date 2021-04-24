unit MainBarCodeServer;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IdBaseComponent,
  IdComponent, IdCustomTCPServer, IdCustomHTTPServer, IdHTTPServer, IdContext,
  IdHeaderList, IdGlobal, Vcl.Clipbrd, IdServerIOHandler, IdSSL, IdSSLOpenSSL,
  Vcl.ExtCtrls, Vcl.AppEvnts, Vcl.Menus;

type
  TMainForm = class(TForm)
    IdHTTPServer1: TIdHTTPServer;
    Memo1: TMemo;
    IdServerIOHandlerSSLOpenSSL1: TIdServerIOHandlerSSLOpenSSL;
    Panel1: TPanel;
    ServerKeyGenerateBtn1: TButton;
    Label1: TLabel;
    ServerKeyEdit1: TEdit;
    Label5: TLabel;
    TrayIcon1: TTrayIcon;
    ApplicationEvents1: TApplicationEvents;
    Label2: TLabel;
    PopupMenu1: TPopupMenu;
    Show1: TMenuItem;
    Exit1: TMenuItem;
    Label3: TLabel;
    PortEdit1: TEdit;
    PortBtn1: TButton;
    procedure ServerKeyGenerateBtn1Click(Sender: TObject);
    procedure IdHTTPServer1HeadersAvailable(AContext: TIdContext;
      const AUri: string; AHeaders: TIdHeaderList;
      var VContinueProcessing: Boolean);
    procedure IdHTTPServer1DoneWithPostStream(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; var VCanFree: Boolean);
    Procedure PostVKey();
    procedure FormCreate(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
    procedure ApplicationEvents1Minimize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CreateKey();
    procedure Show1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure ShowApp();
    procedure PortBtn1Click(Sender: TObject);

  private
    hw: HWND;
    key_ini: String;
    port_ini: String;
    auth: Boolean;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses grg;

procedure TMainForm.CreateKey();

var
  x: Integer;
  y: char;

begin
  // Generate auth key
  key_ini := '';
  for x := 0 to 9 do
  begin
    y := Chr(ord('0') + Random(10));
    key_ini.Insert(0, y);
  end;
  grg.WriteINIstr('Server', 'Key', key_ini);
  ServerKeyEdit1.text := key_ini;

end;

procedure TMainForm.Exit1Click(Sender: TObject);
begin
  close;
end;

procedure TMainForm.ApplicationEvents1Minimize(Sender: TObject);
begin
  // Hide the window and set its state variable to wsMinimized.
  Hide();
  WindowState := wsMinimized;

  // Show the animated tray icon and also a hint balloon.
  TrayIcon1.Visible := True;
  TrayIcon1.ShowBalloonHint;
end;

procedure TMainForm.ServerKeyGenerateBtn1Click(Sender: TObject);

begin
  CreateKey();
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  auth := False;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  if grg.INIstrExists('Server', 'key') = True then
  begin
    key_ini := grg.ReadINIstr('Server', 'key');
    if key_ini.Length < 8 then
      CreateKey();
  end
  else
  begin
    CreateKey();
  end;

  if grg.INIstrExists('Server', 'port') = True then
  begin
    port_ini := grg.ReadINIstr('Server', 'port');
  end
  else
    port_ini := '6942';

  PortEdit1.text := port_ini;
  ServerKeyEdit1.text := key_ini;
  IdHTTPServer1.Bindings.Items[0].port := strtoint(port_ini);
  IdHTTPServer1.Active := True;
end;

procedure TMainForm.IdHTTPServer1DoneWithPostStream(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; var VCanFree: Boolean);

var
  todayStr: string;

begin
  todayStr := DateTimeToStr(now);
  // If client has wrong auth key no Copy/Paste will occur.
  if auth = False then
  begin
    Memo1.Lines.Insert(0, todayStr + ': Auth failed from ' +
      ARequestInfo.RemoteIP);
    exit;
  end;

  // debug delay
  // sleep(2000);

  // Set stream at position 0
  ARequestInfo.PostStream.Position := 0;

  // Write log
  Memo1.Lines.Insert(0, todayStr + ': ' + ReadStringFromStream
    (ARequestInfo.PostStream));

  // Set stream at position 0
  ARequestInfo.PostStream.Position := 0;

  // Copy string from client to Clipboard
  Clipboard.AsText := ReadStringFromStream(ARequestInfo.PostStream);

  // Paste clipboard to window with focus
  PostVKey();
end;

procedure TMainForm.IdHTTPServer1HeadersAvailable(AContext: TIdContext;
  const AUri: string; AHeaders: TIdHeaderList;
  var VContinueProcessing: Boolean);

var
  todayStr: string;
begin
  todayStr := DateTimeToStr(now);
  // Check if client has correct key
  if AHeaders.Values['X-API-KEY'] = key_ini then
  begin
    auth := True;
  end
  else
  begin
    auth := False;
    VContinueProcessing := False;
    Memo1.Lines.Insert(0, todayStr + ': Auth failed from ' +
      AContext.Binding.PeerIP);

  end;

end;

procedure TMainForm.PortBtn1Click(Sender: TObject);

var
  port: Integer;

begin
  port_ini := PortEdit1.text;
  grg.WriteINIstr('Server', 'port', port_ini);
  IdHTTPServer1.Active := False;
  try
    port := strtoint(PortEdit1.text);
  except
    port := 6942;
  end;
  IdHTTPServer1.Bindings.Items[0].port := port;
  IdHTTPServer1.Active := True;
  Memo1.Lines.Add(inttostr(IdHTTPServer1.Bindings.Items[0].port));

end;

Procedure TMainForm.PostVKey();
Begin
  // Simulate Copy/Paste keyboard event.
  keybd_event(VK_CONTROL, MapVirtualkey(VK_CONTROL, 0), 0, 0);
  keybd_event(ord('V'), MapVirtualkey(ord('V'), 0), 0, 0);
  keybd_event(ord('V'), MapVirtualkey(ord('V'), 0), KEYEVENTF_KEYUP, 0);
  keybd_event(VK_CONTROL, MapVirtualkey(VK_CONTROL, 0), KEYEVENTF_KEYUP, 0);
End;

procedure TMainForm.ShowApp();
begin
  // Bring app to forground
  Show();
  WindowState := wsNormal;
  Application.BringToFront();
end;

procedure TMainForm.Show1Click(Sender: TObject);
begin
  ShowApp();
end;

procedure TMainForm.TrayIcon1Click(Sender: TObject);
begin
  ShowApp();
end;

end.
