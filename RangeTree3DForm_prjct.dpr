program RangeTree3DForm_prjct;

uses
  Vcl.Forms,
  RangeTree3DForm_u in 'RangeTree3DForm_u.pas' {Form1},
  _3D in '_3D.pas',
  _3DDefinitions_u in '_3DDefinitions_u.pas',
  RangeTree3D_u in 'RangeTree3D_u.pas',
  QuarterRangeSearch_u in 'QuarterRangeSearch_u.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
