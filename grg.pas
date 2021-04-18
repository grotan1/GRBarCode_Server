unit grg;

interface

uses System.Inifiles, Winapi.Windows, Winapi.Messages, System.SysUtils,
  System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs;

function WriteINIstr(Section, key, Value: string): boolean;
function ReadINIstr(Section, key: string): string;
function INIstrExists(Section, key: string): boolean;

implementation

function WriteINIstr(Section, key, Value: string): boolean;

var
  IniFile: TIniFile;

begin
  IniFile := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  try
    IniFile.WriteString(Section, key, Value);
  except
    showmessage('Error writing to inifile');
  end;
end;

function ReadINIstr(Section, key: string): string;

var
  IniFile: TIniFile;

begin
  IniFile := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  result := IniFile.ReadString(Section, key, '');

end;

function INIstrExists(Section, key: string): boolean;

var
  IniFile: TIniFile;

begin
  IniFile := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  if IniFile.ValueExists(Section, key) = true then
    result := true
  else
    result := false;

end;

end.
