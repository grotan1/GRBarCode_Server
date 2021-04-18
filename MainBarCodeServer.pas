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
    Button1: TButton;
    Label1: TLabel;
    Edit1: TEdit;
    Label5: TLabel;
    TrayIcon1: TTrayIcon;
    ApplicationEvents1: TApplicationEvents;
    Label2: TLabel;
    PopupMenu1: TPopupMenu;
    Show1: TMenuItem;
    Exit1: TMenuItem;
    procedure Button1Click(Sender: TObject);
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

  private
    hw: HWND;
    key: String;
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
  key := '';
  for x := 0 to 9 do
  begin
    y := Chr(ord('0') + Random(10));
    key.Insert(0, y);
  end;
  grg.WriteINIstr('Server', 'Key', key);
  Edit1.text := key;

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

procedure TMainForm.Button1Click(Sender: TObject);

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
    key := grg.ReadINIstr('Server', 'key');
    if key.Length < 8 then
      CreateKey();

  end
  else
  begin
    CreateKey();
  end;
  Edit1.text := key;
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

begin
  // Check if client has correct key
  if AHeaders.Values['X-API-KEY'] = key then
  begin
    auth := True;
  end
  else
    auth := False;
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
