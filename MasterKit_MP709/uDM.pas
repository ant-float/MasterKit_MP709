{
2014-02-09
Анатолий Дорошенко
ant.doroshenko@gmail.com
}

unit uDM;

interface

uses
  SysUtils, Classes, ImgList, Controls, JvComponentBase, JvTrayIcon,
  JvHidControllerClass, Graphics, ExtCtrls, ActnList, Menus;

const
  C_PRODUCT = 'MP709';
  C_VENDOR = 'www.masterkit.ru';

  C_ICONS: array [0..5] of string = (
    'ICO_ERROR',
    'ICO_OFF',
    'ICO_ON_BLUE',
    'ICO_ON_GREEN',
    'ICO_ON_RED',
    'ICO_ON_YELLOW'
  );

type
  TDM = class(TDataModule)
    TrayIcon: TJvTrayIcon;
    HidCtl: TJvHidDeviceController;
    StartTimer: TTimer;
    ActionList: TActionList;
    PopupMenu: TPopupMenu;
    AC_Options: TAction;
    N1: TMenuItem;
    AC_Exit: TAction;
    N3: TMenuItem;
    ImageList: TImageList;
    procedure DataModuleCreate(Sender: TObject);
    procedure HidCtlDeviceChange(Sender: TObject);
    function HidCtlEnumerate(HidDev: TJvHidDevice;
      const Idx: Integer): Boolean;
    procedure TrayIconClick(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure HidCtlDeviceUnplug(HidDev: TJvHidDevice);
    procedure StartTimerTimer(Sender: TObject);
    procedure AC_OptionsExecute(Sender: TObject);
    procedure AC_ExitExecute(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    FIcons: TStringList;
    FCurrentDev: TJvHidDevice;
    FCurrentState: integer;
    procedure SetStateIcon;
    function GetIcon(AIcon: string): TIcon;
    function GetState(HidDev: TJvHidDevice): integer;
    function SetState(HidDev: TJvHidDevice; Flag: byte): boolean;
  public
    { Public declarations }
  end;

var
  DM: TDM;

implementation

{$R *.dfm}
{$R icons.res}

uses
  Windows, Forms;

procedure TDM.DataModuleCreate(Sender: TObject);
var
  icn: TIcon;
  i: integer;
begin
  FCurrentDev := nil;
  FCurrentState := -1;

  FIcons := TStringList.Create;
  for i := 0 to High(C_ICONS) - 1 do
  begin
    icn := TIcon.Create;
    icn.Handle := LoadIcon(HInstance, PChar(C_ICONS[i]));
    FIcons.AddObject(C_ICONS[i], icn);
    DM.TrayIcon.Icon := icn;
  end;
end;

function TDM.GetState(HidDev: TJvHidDevice): integer;
var
  Buf: array [0..8] of Byte;
  r: integer;
begin
  Result := -1;
  r := 0;
  repeat
    //перед повтором дадим отдохнуть
    if r > 0 then Sleep(100);
    //пять попыток
    if r > 5 then Exit;
    FillChar(Buf, SizeOf(Buf), 0);
    Buf[1] := $7E;
    HidDev.SetFeature(buf, 9);
    HidDev.GetFeature(buf, 9);
    Inc(r);
  until Buf[1] = $7E;
  if Buf[2] <> Buf[3] then Exit;
  case Buf[2] of
    $19: Result := 0;
    else Result := 1
  end;
end;

function TDM.SetState(HidDev: TJvHidDevice; Flag: byte): boolean;
var
  Buf: array [0..8] of Byte;
  r: integer;
begin
  r := 0;
  repeat
    //перед повтором дадим отдохнуть
    if r > 0 then Sleep(100);
    //пять попыток
    if r > 5 then Exit;
    FillChar(Buf, SizeOf(Buf), 0);
    Buf[1] := $E7;
    Buf[2] := Flag;
    HidDev.SetFeature(buf, 9);
    HidDev.GetFeature(buf, 9);
    Inc(r);
  until Buf[1] = $E7;
  Result := (Buf[2] = Flag) and (Buf[2] = Buf[3]);
end;

function TDM.GetIcon(AIcon: string): TIcon;
var
  i: integer;
begin
  Result := nil;
  i := 0;
  if FIcons.Find(AIcon, i) then Result := TIcon(FIcons.Objects[i]);
end;

procedure TDM.SetStateIcon;
begin
  case FCurrentState of
    -1:
    begin
      TrayIcon.Icon := GetIcon('ICO_ERROR');
      TrayIcon.BalloonHint('Ошибка', 'Устройство не подключено', btError, 5000, True);
    end;
    0: TrayIcon.Icon := GetIcon('ICO_OFF');
    1: TrayIcon.Icon := GetIcon('ICO_ON_BLUE');
  end;
end;

procedure TDM.HidCtlDeviceChange(Sender: TObject);
begin
  HidCtl.Enumerate;
end;

function TDM.HidCtlEnumerate(HidDev: TJvHidDevice;
  const Idx: Integer): Boolean;
begin
  if
    (HidDev.ProductName = C_PRODUCT)
    and (HidDev.VendorName = C_VENDOR)
  then
  begin
    HidCtl.CheckOutByIndex(HidDev, Idx);
    if HidDev <> nil then
    begin
      FCurrentDev := HidDev;
      FCurrentState := GetState(FCurrentDev);
      SetStateIcon;
    end;
  end;
  Result := True;
end;

procedure TDM.TrayIconClick(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Flag: integer;
begin
  if Button <> mbLeft then Exit;
  if FCurrentDev = nil then Exit;
  FCurrentState := GetState(FCurrentDev);

  case FCurrentState of
    -1: Exit;
    0: Flag := 0;
    1: Flag := $19;
  end;

  if not SetState(FCurrentDev, Flag) then
    FCurrentState := -1
  else
    FCurrentState := GetState(FCurrentDev);

  SetStateIcon;
end;

procedure TDM.HidCtlDeviceUnplug(HidDev: TJvHidDevice);
begin
  if HidDev = FCurrentDev then
  begin
    FCurrentDev := nil;
    FCurrentState := -1;
    SetStateIcon;
  end;
end;

procedure TDM.StartTimerTimer(Sender: TObject);
begin
  if FCurrentDev = nil then
    FCurrentState := -1
  else
    FCurrentState := GetState(FCurrentDev);
  SetStateIcon;
  Application.Minimize;
  StartTimer.Enabled := False;
end;

procedure TDM.AC_OptionsExecute(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_RESTORE);
end;

procedure TDM.AC_ExitExecute(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TDM.TrayIconDblClick(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  AC_OptionsExecute(nil);
end;

end.
