program ant_mp709;

uses
  Forms,
  uMain in 'uMain.pas' {fmMain},
  uDM in 'uDM.pas' {DM: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Управление нагрузками';
  Application.CreateForm(TDM, DM);

  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
