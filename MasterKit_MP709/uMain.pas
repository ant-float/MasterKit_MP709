{
2014-02-09
Анатолий Дорошенко
ant.doroshenko@gmail.com
}

unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, JvComponentBase, JvHidControllerClass, ComCtrls,
  ExtCtrls, XPMan, AppEvnts, dxGDIPlusClasses;

const
  c_reg_autostart_key = 'ANT MP709';

type
  TfmMain = class(TForm)
    pnButtons: TPanel;
    lbInfo: TLabel;
    btMinimize: TButton;
    btExit: TButton;
    PageControl: TPageControl;
    tsShare: TTabSheet;
    cbAutostart: TCheckBox;
    ApplicationEvents: TApplicationEvents;
    XPManifest: TXPManifest;
    Label1: TLabel;
    Image1: TImage;
    procedure btExitClick(Sender: TObject);
    procedure btMinimizeClick(Sender: TObject);
    procedure ApplicationEventsMinimize(Sender: TObject);
    procedure ApplicationEventsRestore(Sender: TObject);
    procedure cbAutostartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure CheckAutoStart;
  public
  end;

var
  fmMain: TfmMain;

implementation

uses
  uDM, Registry;

{$R *.dfm}

procedure TfmMain.btExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfmMain.btMinimizeClick(Sender: TObject);
begin
  Application.Minimize;
end;

procedure TfmMain.ApplicationEventsMinimize(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_HIDE);
end;

procedure TfmMain.ApplicationEventsRestore(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_RESTORE);
end;

procedure TfmMain.CheckAutoStart;
var
  reg: TRegistry;
  OldSetAutostart: Boolean;
  str, ExeName: string;
  FLoadOnStartup: Boolean;
begin
  try
    reg := TRegistry.Create;
    try
      FLoadOnStartup := cbAutostart.Checked;

      reg.RootKey := HKEY_CURRENT_USER;
      reg.LazyWrite := False;
      reg.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Run', False);

      ExeName := '"' + ParamStr(0) + '"';
      str := reg.ReadString(c_reg_autostart_key);
      OldSetAutostart := (str = ExeName);

      //Все в норме
      if FLoadOnStartup and OldSetAutostart then
      begin
        reg.CloseKey;
        Exit;
      end;

      //Убрать из автозагрузки
      if not FLoadOnStartup then
      begin
        reg.DeleteValue(c_reg_autostart_key);
        reg.CloseKey;
        Exit;
      end;

      if FLoadOnStartup then
        reg.WriteString(c_reg_autostart_key, ExeName);

      reg.CloseKey;
    finally
      Reg.Free;
    end;
  except
  end;end;

procedure TfmMain.cbAutostartClick(Sender: TObject);
begin
  CheckAutoStart;
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
  CheckAutoStart;
end;

end.
