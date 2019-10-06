unit _3DDefinitions_u;

interface

uses  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
      System.Generics.collections, Generics.Defaults, Vcl.Graphics,
      Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls;

const huge      = 1e20;
const tiny      = 1e-5;
const LogOfZero = -999;

type TSPt2D = record
  x,y : Single;
end;

type TSPt3D = record
  x, y, z : Single;
end;

const Origo : TSPt3d = (x:0;y:0;z:0);

type TBOX3D = record
  min, max : TSPt3D;
end;

type TPt3D = record
  x, y, z : Double;
end;

type TMat3D = Array[1..3,1..3] of Double;//}Single;   { For coordinate transformations }

type TAlignByte3 = Array[0..2] of Byte;

type
  PViewParams = ^TViewParams;
  TViewParams = packed record
    ViewAzimuth,
    ViewElevation  : Integer; { degrees }
    Xtranslation,
    YTranslation,
    ZoomFactor     : Single;
    Projection     : Boolean;
    AlignByte3     : TAlignByte3;
end;

type TRunTimeParameters = record
    Centroid      : TSPt3D;
    Aabb          : TBOX3D;
    AabbDiagonal  : Single;
    NpointsMinus1 : Integer;
end;


type
	TViewList = class(TList)
	public
		Constructor Create(const RunTimeParameters_ : TRunTimeParameters);
		Destructor Destroy; OverRide;
		procedure Clear; OverRide;
		procedure Delete(Index : Integer);
		function GetNextView(var Index : Integer) : TViewParams;
		function GetPreviousView(var Index : Integer) : TViewParams;
		procedure Init;
	private
    RunTimeParameters : TRunTimeParameters;
		procedure AddViewParams(ViewParams : TViewParams);
		function GetView(Index:Integer) : TViewParams;
		function DefaultView : TViewParams;
end;

// begin forward declaration
function CoordTransform(const Pt : TPt3D; const TransMat: TMat3D):TPt3D;
function Pt3dToSPt3d(const pt : TPt3D) : TSPt3D;
function AzimuthElevationToXYZ(const A, E : Single): TPt3D;
function Distance(const StartPt, EndPt : TPt3D): Double; overload;
function Distance(const StartPt, EndPt : TSPt3D): Single; overload;
function VectorLength(const Vector:TSPt3D):Single; overload;
function VectorLength(const Vector:TPt3D):Single; overload;
procedure AutoRange(var IOMin, IOMax, OInc:Single; IOSteps : Integer);
// end forward declaration


// Global variables
var ListOfPoints : TList<TSPt3D>;

implementation

uses Math;

function CoordTransform(const pt : TPt3D; const TransMat: TMat3D):TPt3D;
begin
  With pt do
  begin
    RESULT.x :=  TransMat[1][1] * x
               + TransMat[1][2] * y
               + TransMat[1][3] * z;
    RESULT.y :=  TransMat[2][1] * x
               + TransMat[2][2] * y
               + TransMat[2][3] * z;
    RESULT.z :=  TransMat[3][1] * x
               + TransMat[3][2] * y
               + TransMat[3][3] * z;
  end;
end;

function Pt3dToSPt3d(const pt : TPt3D) : TSPt3D;
begin
  RESULT.x := pt.X;  RESULT.y := pt.Y;  RESULT.z := pt.Z;
end;

function AzimuthElevationToXYZ(const A, E : Single) : TPt3D;
begin
  RESULT.x := Cos(E);
	RESULT.y := RESULT.x * Sin(A);
	RESULT.x := RESULT.x * Cos(A);
	RESULT.z := Sin(E);
end;

function VectorLength(const Vector : TSPt3D) : Single;
begin
  RESULT := Sqrt( Sqr(Vector.x) + Sqr(Vector.y) + Sqr(Vector.z) );
end;

function VectorLength(const Vector : TPt3D) : Single;
begin
  RESULT := Sqrt( Sqr(Vector.x) + Sqr(Vector.y) + Sqr(Vector.z) );
end;

function Distance(const StartPt, EndPt : TPt3D): Double;
var Vector : TPt3D;
begin
  Vector.x := EndPt.x - StartPt.x;
  Vector.y := EndPt.y - StartPt.y;
  Vector.z := EndPt.z - StartPt.z;
  RESULT   := VectorLength(Vector);
end;

function Distance(const StartPt, EndPt : TSPt3D): Single;
var Vector : TPt3D;
begin
  Vector.x := EndPt.x - StartPt.x;
  Vector.y := EndPt.y - StartPt.y;
  Vector.z := EndPt.z - StartPt.z;
  RESULT   := VectorLength(Vector);
end;

function xLog10(const x : Double): Double;
begin
  if x > 0 then  RESULT := Log10(x)
  else           RESULT := LogOfZero;
end;

procedure AutoRange(var IOMin, IOMax, OInc : Single; IOSteps : Integer);
var Decades, TempIOMin, TempIOMax,
    TempOInc, StoreTempIOMin, Error,
    StoreTempIOMax, StoreTempOInc     :Single;

	procedure TrySteps(Step:Single);

  	procedure SetTempVals(const Resolution : Single);
		begin
			TempOInc  := Resolution * Decades;
			TempIOMin := Round(IOMin / TempOInc) * TempOInc;
			TempIOMax := Trunc(IOMax / TempOInc) * TempOInc;
		end;

		procedure StoreTempValues;
		begin
      StoreTempOInc  := TempOInc;
      StoreTempIOMin := TempIOMin;
      StoreTempIOMax := TempIOMax;
    end;

		procedure ErrorSteps(const resolution : Single);
    var TempError:Single;
    begin
      TempError := abs((TempIOMax - TempIOMin)/(TempOInc) - IOSteps);
      if (TempError <= Error)then
      begin
        Error := TempError;
        StoreTempValues;
      end;
    end;
  begin
    SetTempVals(Step);
    ErrorSteps(Step);
  end;

begin
	Decades := xLog10(IOMax-IOMin)+1;
	if Decades > 100 then        Decades := 100
	else if Decades >= 1 then    Decades := IntPower(10,Trunc(Decades))
	else if Decades < -100 then  Decades := -100
	else                         Decades := 1/ IntPower(10,Trunc(Decades));

	Decades := 0.1 * Decades;
	Error := huge;

  TrySteps(0.005);  TrySteps(0.01);   TrySteps(0.015);
	TrySteps(0.02);   TrySteps(0.025);  TrySteps(0.03);
  TrySteps(0.04);   TrySteps(0.05);   TrySteps(0.08);
	TrySteps(0.1);    TrySteps(0.15);   TrySteps(0.2);
	TrySteps(0.25);   TrySteps(0.3);    TrySteps(0.4);
	TrySteps(0.5);    TrySteps(0.8);    TrySteps(1);
  TrySteps(1.5);    TrySteps(2);      TrySteps(25);
  TrySteps(30);     TrySteps(40);

	OInc := StoreTempOInc;
	IOMin:= StoreTempIOMin - OInc;
	IOMax:= StoreTempIOMin + Ceil((IOMax - StoreTempIOMin)/StoreTempOInc)*StoreTempOInc;
end;


// Begin define methods of TViewList
Constructor TViewList.Create(const RunTimeParameters_ : TRunTimeParameters);
begin
  inherited Create;
  RunTimeParameters := RunTimeParameters_;
  Init;
end;

procedure TViewList.Init;
var ViewParams: TViewParams;
    AZoomFactor:Extended;
begin
  Clear;
  AZoomFactor    :=  (Screen.Width / 1024) * 280.8;
  AZoomFactor    := AZoomFactor /
                     Sqrt(Sqr(RunTimeParameters.Centroid.x) +
                          Sqr(RunTimeParameters.Centroid.y) +
                          Sqr(RunTimeParameters.Centroid.z));
  // revision for RangeRee3DForm_u
  AZoomFactor    := AZoomFactor/3;

  with ViewParams do {Default View}
  begin
    ViewAzimuth   := 30;
    ViewElevation := 30;
    Xtranslation  := 0;
    YTranslation  := 0;
    ZoomFactor    := AZoomFactor * 1.5;
    Projection    := TRUE;
  end;
  AddViewParams(ViewParams);
  with ViewParams do         {ZOX View}
	begin
		ViewAzimuth   := 90;
    ViewElevation := 0;
    Xtranslation  := 0;
    YTranslation  := 0;
    ZoomFactor    := AZoomFactor;
    Projection    := FALSE;
  end;
  AddViewParams(ViewParams);
  with ViewParams do         {YOZ View}
  begin
    ViewAzimuth   := 0;
    ViewElevation := 0;
    Xtranslation  := 0;
    YTranslation  := 0;
    ZoomFactor    := AZoomFactor;
    Projection    := FALSE;
  end;
  AddViewParams(ViewParams);
  with ViewParams do         {XOY view}
  begin
    ViewAzimuth   := 90;
    ViewElevation := 90;
    Xtranslation  := 0;
    YTranslation  := 0;
    ZoomFactor    := AZoomFactor;
    Projection    := FALSE;
  end;
  AddViewParams(ViewParams);
end;

procedure TViewList.AddViewParams(ViewParams : TViewParams);
var PtrViewParams:^TViewParams;
begin
  GetMem(PtrViewParams,SizeOf(TViewParams));
  PtrViewParams^ := ViewParams;
  Add(PtrViewParams);
end;

procedure TViewList.Delete(Index : Integer);
begin
  if (Count - 1 >= index) then
  begin
		FreeMem(Items[Index]);
		inherited Delete(Index);
  end;
end;

function TViewList.GetView(Index : Integer) : TViewParams;
begin
  if (Count - 1 >= Index) then
	begin
    RESULT := PViewParams(Items[Index])^;
  end;
end;


function TViewList.DefaultView : TViewParams;
var AZoomFactor:Extended;
begin
  AZoomFactor := (Screen.Width / 1024) * 280.8;
  AZoomFactor := AZoomFactor / VectorLength(RunTimeParameters.Centroid);

	with RESULT do
  begin
    ViewAzimuth   := 30;
    ViewElevation := 30;
    Xtranslation  := 0;
    YTranslation  := 0;
    ZoomFactor    := AZoomFactor * 1.5;
    Projection    := TRUE;
  end;
end;

function TViewList.GetNextView(var Index : Integer) : TViewParams;
begin
  if Count = 0 then RESULT := DefaultView
  else
	begin
		inc(Index);
		if Index > Count - 1 then Index := 0;
		RESULT := PViewParams(Items[Index])^;
	end;
end;

function TViewList.GetPreviousView(var Index : Integer) : TViewParams;
begin
	if Count = 0 then RESULT := DefaultView
	else
	begin
		Dec(Index);
		if (Index < 0) then Index := Count - 1;
		begin
			RESULT := PViewParams(Items[Index])^;
		end;
	end;
end;

procedure TViewList.Clear;
var Counter :Integer;
begin
	for Counter := 0  to Count - 1 do
		FreeMem(Items[Counter]);//,SizeOf(TViewParams));
	inherited Clear;
end;

Destructor TViewList.Destroy;
begin
	Clear;
	inherited Destroy;
end;
// end define mehtos of TViewList

end.
