unit _3D;

{ Delphi Implementation of 3DNavigator -> T_3D

  The navigator is prepared to display a ListOfPoints, global variable defined in
  _3DDefinitions_u.pas. SetBeingDisplayed can be used to define Active points (also
  wrong points if desired) so the ListOfPoints is divided in subsets that are displayed
  in a different color.

  Basic functionalities for navegation:

  pad    : right mouse button hold, then move the mouse
  rotate : left mouse button hold, then move the mouse
  zoom   : either use MouseWheel or Alt + left mouse button hold, then move mouse
  views  : Ctrl + Alt + v to change the view, viewList (DefaultView, ZOX, YOZ, XOY)    }

{$DEFINE DEBUG}

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, ExtCtrls, Math, System.Generics.collections,
  Generics.Defaults, mswheel,_3DDefinitions_u;

type
  TViewOperation = (cvMoveLeft,    cvMoveRight,    cvMoveUp,      cvMoveDown,
                    cvRotateLeft,  cvRotateRight,  cvRotateDown,  cvRotateUp,
                    cvZoomIn,      cvZoomOut,
                    cvNextView,    cvPreviousView);

type T_3DBeingDisplayed = (AllPoints, ActiveSetInRed, WrongSetInGreen);

type
  T_3D = class(TPaintBox)
    procedure MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer); virtual;
    procedure MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer); virtual;
  private
    ScreenZoomFac                : Single;
    WidthWas, HeightWas,
    AngleStep                    : Integer;
    StartViewMouseViewoperation  : TViewParams;
    StartShift                   : TShiftState;
    ProjectionMatrix             : TMat3D;
    ViewDistance, TranslateStep,
    ZoomStep, MaxTransLate,
    MinZoom, MaxZoom             : Double;
    EyePoint                     : TPt3D;
    FSmallSteps                  : Boolean;
    BeingDisplayed               : T_3DBeingDisplayed;
    ListOfActivePointNo,
    ListOfInactivePointNo,
    ListOfWrongPointNo,
    ListOfPointNos               : TList<Integer>;
    BoxPoints                    : Array[1..8] of TSPt3D;

    procedure getRunTimeParameters;
    procedure getBoxPoints(const k1, k2 : TSPt3D);
    Procedure CalculateProjectionMatrix;
    Procedure SetSmallViewSteps(NewValueSmallSteps: Boolean);
    function GetProjection: Boolean;
    Procedure SetProjection(NewValue: Boolean);
    Procedure SetXYZ(NewValue: Boolean);
    procedure DrawMeasures(ACanvas: TCanvas);
    procedure DrawPoints(ACanvas: TCanvas);
    procedure DrawActivePoints(ACanvas: TCanvas);
    procedure DrawInActivePoints(ACanvas: TCanvas);
    procedure DrawWrongPoints(ACanvas: TCanvas);
    procedure DrawBox(ACanvas: TCanvas; const APenStyle : TPenStyle; const Acolor : TColor; const APenWidth : Integer);
    Procedure DrawCoordinatesystem(ACanvas: TCanvas);
    Procedure MSWheel1WheelEvent(zdelta, xpos, ypos, ScrollLines: Integer);
    Procedure FreeMemory;
    Procedure ClearMemory;
    function RealToStrLeft1(const R : Double; const Dec : Integer) : string;
    function GetXYZString(const X,Y,Z:Double; const Dec : Integer) : String;
  protected
    StartX, StartY, CurrViewNo : Integer;
    CanvasCenter,
    CenterToStartCursorPos     : TPoint;
    FXYZ                       : Boolean;
    ViewNormal                 : TPt3D;
    RunTimeParameters          : TRuntimeParameters;
    ViewList                   : TViewList;
    CurrViewParams             : TViewParams;
    procedure Resize; OverRide;
    procedure SetDefaultView;
    Procedure SetViewAngles(const DegAzimuth, DegElevation : Integer);
    Function TransFormPoint3DTo3DViewCoords(const pt : TSPt3D) : TSPt3D;
    Function TransFormPoint3DViewCoordsTo2D(const pt : TSPt3D) : TSPt2D;
    Function TransFormPoint3DTo2D(const pt : TSPt3D) : TSPt2D;
    Function ToDeviceCoords(const Pt: TSPt2D) : TPoint;
    Function ToScaledDeviceCoords(const Pt: TSPt2D; const scaleFactor: Single) : TPoint;
    procedure TransForm; Virtual;
    procedure Paint; OverRide;
  public
    MiddleOfDeviceBoxX, MiddleOfDeviceBoxY,
    DeviceScaleFactorX, DeviceScaleFactorY : Single;
    OneCMInPixelsX, OneCMInPixelsY         : Integer;

    function FindClosestPointOneNorm(X, Y: Integer): Integer;
    function FindClosestPointString(X, Y: Integer): String;

    Constructor Create(AOwner: TComponent); OverRide;
    Destructor Destroy; OverRide;
    Procedure SetDeviceAsScreen; virtual;
    procedure Draw(ACanvas: TCanvas); Virtual;
    procedure ChangeView(ViewOperation: TViewOperation);
    Procedure SetBeingDisplayed(const k1, k2 : TSPt3D; const ListOfIsActive : TList<Boolean>); overload;
    procedure SetBeingDisplayed(const k1, k2 : TSPt3D; const ListOfIsActive, ListOfIsWrong : TList<Boolean>); overload;
    procedure UnSetBeingDisplayed;
  published
    Property SmallSteps: Boolean Read FSmallSteps Write SetSmallViewSteps;
    Property Projection: Boolean read GetProjection Write SetProjection;
    property XYZ: Boolean read FXYZ Write SetXYZ;
  end;

implementation

Uses Types;

Procedure T_3D.MSWheel1WheelEvent(zdelta, xpos, ypos, ScrollLines: Integer);
begin
  if zdelta > 0 then
    ChangeView(cvZoomIn)
  else
    ChangeView(cvZoomOut)
end;

function T_3D.FindClosestPointOneNorm(X, Y: Integer): Integer;
var
  Distance, TempDistance: Int64; // Single;
  Counter: Integer;
  Point2: TPoint;
begin
  Distance := High(Int64); // Huge;
  RESULT := 1;
  for Counter := 0 to ListOfPoints.Count-1 do
  begin
    Point2 := ToDeviceCoords(TransFormPoint3DTo2D(ListOfPoints[Counter]));
      TempDistance := abs(X - Point2.X) + abs(Y - Point2.Y);
      if TempDistance < Distance then
      begin
        RESULT := Counter;
        Distance := TempDistance;
      end;
  end;
end;

function T_3D.FindClosestPointString(X, Y: Integer): String;
var
  AStr: String;
  PointNo: Integer;
  pt : TSPt3D;
begin

  // PointNo := FindClosestPoint(X, Y);
  PointNo := FindClosestPointOneNorm(X, Y);
  pt := ListOfPoints[PointNo];
  // RESULT := 'Corner closest to mouse pointer: ' +
  // IntToStr(UserCornerNumbDoubleDict.GetNumber(PointNo)) + '  ' +
  // GetXYZString(CornerList[PointNo].X + PtrRunTimeParameters^.CubenetLower.X,
  // CornerList[PointNo].Y + PtrRunTimeParameters^.CubenetLower.Y,
  // CornerList[PointNo].Z + PtrRunTimeParameters^.CubenetLower.Z, 3);
  AStr := IntToStr(PointNo) + '  ';
  RESULT := 'Corner closest to mouse pointer (' + 'CurrentLongUnitString' +
    '): ' + AStr +
  // IntToStr(UserCornerNumbDoubleDict.GetNumber(PointNo)) + '  ' +
  GetXYZString(pt.X {+ PtrRunTimeParameters^.CubenetLower.X)},
                 pt.Y {+ PtrRunTimeParameters^.CubenetLower.Y)},
                 pt.Z {+ PtrRunTimeParameters^.CubenetLower.Z)},
                 3{CurrentUnitNDec});
end;

procedure T_3D.SetXYZ(NewValue: Boolean);
begin
  FXYZ := NewValue; // NOT(FXYZ);
  Invalidate;
end;

procedure T_3D.getBoxPoints(const k1,k2 : TSPt3D);
var dx, dy, dz : Single;
begin
  dx := k2.x-k1.x; dy := k2.y-k1.y; dz := k2.z-k1.z;
  BoxPoints[1] := k1;
  BoxPoints[2] := k1;                  BoxPoints[2].x := BoxPoints[2].x+dx;
  BoxPoints[3] := BoxPoints[2];        BoxPoints[3].y := BoxPoints[3].y+dy;
  BoxPoints[4] := k1;                  BoxPoints[4].y := BoxPoints[3].y;
  BoxPoints[5] := k1;                  BoxPoints[5].z := BoxPoints[5].z+dz;
  BoxPoints[6] := BoxPoints[5];        BoxPoints[6].x := BoxPoints[2].x;
  BoxPoints[7] := BoxPoints[6];        BoxPoints[7].y := BoxPoints[3].y;
  BoxPoints[8] := BoxPoints[5];        BoxPoints[8].y := BoxPoints[3].y;
end;


procedure T_3D.SetBeingDisplayed(const k1, k2 : TSPt3D; const ListOfIsActive, ListOfIsWrong : TList<Boolean>);
var i : Integer;
begin
  ClearMemory;
  for i := 0 to ListOfIsActive.Count-1 do
  begin
    if ListOfIsWrong[i] then  ListOfWrongPointNo.Add(i)
    else
    begin
      if ListOfIsActive[i] then  ListOfActivePointNo.Add(i)
      else                       ListOfInactivePointNo.Add(i);
    end;
  end;

  getBoxPoints(k1,k2);

  BeingDisplayed := WrongSetInGreen;
  Invalidate;
end;


procedure T_3D.SetBeingDisplayed(const k1, k2 : TSPt3D; const ListOfIsActive : TList<Boolean>);
var  i: Integer;
begin
  ClearMemory;
  for i := 0 to ListOfIsActive.Count-1 do
  begin
    if ListOfIsActive[i] then  ListOfActivePointNo.Add(i)
    else                       ListOfInactivePointNo.Add(i);
  end;

  getBoxPoints(k1,k2);

  BeingDisplayed := ActiveSetInRed;
  Invalidate;
end;

procedure T_3D.UnSetBeingDisplayed;
var  i: Integer;
begin
  BeingDisplayed := AllPoints;
  Invalidate;
end;


procedure T_3D.MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  StartX                      := X;
  StartY                      := Y;
  StartViewMouseViewoperation := CurrViewParams;
  StartShift                  := Shift;
  CenterToStartCursorPos.X    := StartX - CanvasCenter.X;
  CenterToStartCursorPos.Y    := StartY - CanvasCenter.Y;
end;

procedure T_3D.MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var DotProd: Single;
begin

  if StartShift <> Shift then
  // reset our starting point if shiftstate has changed
  begin
    StartViewMouseViewoperation := CurrViewParams;
    StartShift                  := Shift;
    StartX                      := X;
    StartY                      := Y;
    CenterToStartCursorPos.X    := StartX - CanvasCenter.X;
    CenterToStartCursorPos.Y    := StartY - CanvasCenter.Y;
  end;

  if (Y <> StartY) or (X <> StartX) then
  begin
    with CurrViewParams do
    begin
      if ssLeft in Shift then
      begin
        if (ssAlt in Shift) then
        begin  {Zoom no MouseWheel}

          // translate (StartX,StartY) To CanvasCenter
          Xtranslation := StartViewMouseViewoperation.Xtranslation - (CenterToStartCursorPos.X / (StartViewMouseViewoperation.ZoomFactor * ScreenZoomFac));
          Ytranslation := StartViewMouseViewoperation.Ytranslation - (CenterToStartCursorPos.Y / (StartViewMouseViewoperation.ZoomFactor * ScreenZoomFac));

          TransForm;

          // Compute ZoomFactor And Apply Zoom
          // dot prod with vector (1,-1)
          DotProd := (X - StartX) / Screen.Width - (Y - StartY) / Screen.Height;

          if DotProd > tiny then             ZoomFactor := StartViewMouseViewoperation.ZoomFactor * (1 + DotProd * 9)
          else if DotProd < -tiny then       ZoomFactor := StartViewMouseViewoperation.ZoomFactor / (1 - DotProd * 9);

          if ZoomFactor > MaxZoom then       ZoomFactor := MaxZoom
          else if ZoomFactor < MinZoom then  ZoomFactor := MinZoom;

          TransForm;

          // translate CanvasCenter to (StartX,StartY)
          Xtranslation := Xtranslation + (CenterToStartCursorPos.X / (ZoomFactor * ScreenZoomFac));
          Ytranslation := Ytranslation + (CenterToStartCursorPos.Y / (ZoomFactor * ScreenZoomFac));
        end
        else
        begin {rotation}
          ViewAzimuth := StartViewMouseViewoperation.ViewAzimuth - Round(2 * (X - StartX) / (Screen.Width) * 360);
          ViewElevation := StartViewMouseViewoperation.ViewElevation + Round(2 * (Y - StartY) / (Screen.Height) * 90);

          if ViewAzimuth > 180 then         ViewAzimuth := ViewAzimuth - 360
          else if ViewAzimuth < -180 then   ViewAzimuth := ViewAzimuth + 360;

          if ViewElevation > 90 then        ViewElevation := 90
          else if ViewElevation < -90 then  ViewElevation := -90;
        end;
        TransForm;
        Invalidate;
      end
      else if ssRight in Shift then {padding}
      begin
        Xtranslation := StartViewMouseViewoperation.Xtranslation + (X - StartX) / (CurrViewParams.ZoomFactor * ScreenZoomFac);
        if Xtranslation < -MaxTransLate then       Xtranslation := -MaxTransLate
        else if Xtranslation > MaxTransLate then   Xtranslation :=  MaxTransLate;

        Ytranslation := StartViewMouseViewoperation.Ytranslation + (Y - StartY) / (CurrViewParams.ZoomFactor * ScreenZoomFac);
        if Ytranslation < -MaxTransLate then      Ytranslation := -MaxTransLate
        else if Ytranslation > MaxTransLate then  Ytranslation :=  MaxTransLate;
        TransForm;
        Invalidate;
      end;
    end;
  end;
end;


procedure T_3D.Resize;
begin
  if (WidthWas > 1) and (HeightWas > 1) then
  begin
    // zoom to the smallest change ratio
    if ClientWidth / WidthWas < ClientHeight / HeightWas then
      // biggest change in Width
      ScreenZoomFac := ClientWidth / WidthWas
    else
      ScreenZoomFac := ClientHeight / HeightWas
  end;

  inherited Resize;
  if (WidthWas = 1) and (HeightWas = 1) then
    if (ClientWidth > 200) and (ClientHeight > 200) then
    // consder this original reference size
    begin
      WidthWas := ClientWidth;
      HeightWas := ClientHeight;
    end;
end;

Constructor T_3D.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  getRunTimeParameters;

  WidthWas              := 1;
  HeightWas             := 1;
  ScreenZoomFac         := 1;

  BeingDisplayed        := AllPoints;
  ListOfActivePointNo   := TList<Integer>.create;
  ListOfInactivePointNo := TList<Integer>.create;
  ListOfWrongPointNo    := TList<Integer>.create;

  Cursor                := crHandPoint;
  ParentShowHint        := FALSE;
  OnMouseMove           := MouseMove;
  OnMouseDown           := MouseDown;

  Canvas.Brush.Color    := clBtnFace;
  ParentFont            := FALSE;
  Font.Name             := 'MS Sans Serif';

  ViewList              := TViewList.Create(RunTimeParameters);

  SetDefaultView;
  SetSmallViewSteps(FALSE);
  FXYZ := FALSE;

  TransForm;
end;

Procedure T_3D.FreeMemory;
begin
  ListOfActivePointNo.Free;
  ListOfInactivePointNo.Free;
  ListOfWrongPointNo.Free;
end;

Procedure T_3D.ClearMemory;
begin
  ListOfActivePointNo.Clear;
  ListOfInactivePointNo.Clear;
  ListOfWrongPointNo.Clear;
end;

Destructor T_3D.Destroy;
begin
  FreeMemory;
  ViewList.Free;
  inherited Destroy;
end;

procedure T_3D.SetDefaultView;
var CentroidDist: Double;
    OSVERSIONINFO: TOSVERSIONINFO;
begin
  OSVERSIONINFO.dwOSVersionInfoSize := sizeof(OSVERSIONINFO);
  GetVersionEx(OSVERSIONINFO);

  CentroidDist := VectorLength(RunTimeParameters.Centroid);
  MaxTransLate := CentroidDist * 4;

  if OSVERSIONINFO.dwPlatformId = VER_PLATFORM_WIN32_NT then // allow large zoom
  begin
    MaxZoom := {$IFDEF DEBUG}100*{$ENDIF}3200000 / (4 * MaxTransLate);
    MinZoom := {$IFDEF DEBUG}0.01*{$ENDIF}MaxZoom / 5000;
  end
  else
  begin
    MaxZoom := {$IFDEF DEBUG}100*{$ENDIF}32000 / (4 * MaxTransLate);
    MinZoom := {$IFDEF DEBUG}0.01*{$ENDIF}MaxZoom / 200;
	end;

  CurrViewNo     := -1;
  CurrViewParams := ViewList.GetNextView(CurrViewNo);
end;

Function T_3D.TransFormPoint3DTo3DViewCoords(const Pt : TSPt3D) : TSPt3D;
Var ShPt : TPt3D;
    Alfa : Double;
begin
  with RunTimeParameters do
  begin
    ShPt.X := pt.X - Centroid.X;
    ShPt.Y := pt.Y - Centroid.Y;
    ShPt.Z := pt.Z - Centroid.Z;

    if CurrViewParams.Projection then
    begin
      Alfa   := ViewDistance / ( ViewNormal.X * (ShPt.X - EyePoint.X) +
                                 ViewNormal.Y * (ShPt.Y - EyePoint.Y) +
                                 ViewNormal.Z * (ShPt.Z - EyePoint.Z));

      ShPt.X := Alfa * (ShPt.X - EyePoint.X) + EyePoint.X;
      ShPt.Y := Alfa * (ShPt.Y - EyePoint.Y) + EyePoint.Y;
      ShPt.Z := Alfa * (ShPt.Z - EyePoint.Z) + EyePoint.Z;
    end;
    RESULT := Pt3dToSPt3d(CoordTransform(ShPt, ProjectionMatrix));
  end;
end;

Function T_3D.TransFormPoint3DTo2D(const pt : TSPt3D): TSPt2D;
var transPt : TSPt3D;
    prod    : Single;
begin
  transPt  := TransFormPoint3DTo3DViewCoords(pt);
  prod     := CurrViewParams.ZoomFactor * ScreenZoomFac;
  RESULT.X := (transPt.Y + CurrViewParams.Xtranslation) * prod;
  RESULT.Y := (transPt.Z + CurrViewParams.Ytranslation) * prod;
end;

Function T_3D.TransFormPoint3DViewCoordsTo2D(const pt : TSPt3D): TSPt2D;
var prod : Single;
begin
  prod     := CurrViewParams.ZoomFactor * ScreenZoomFac;
  RESULT.X := (pt.Y + CurrViewParams.Xtranslation) * prod;
  RESULT.Y := (pt.Z + CurrViewParams.Ytranslation) * prod;
end;

Function T_3D.ToDeviceCoords(const pt: TSPt2D): TPoint;
begin
  RESULT.X := Round(Pt.X * DeviceScaleFactorX + MiddleOfDeviceBoxX);
  RESULT.Y := Round(Pt.Y * DeviceScaleFactorY + MiddleOfDeviceBoxY);
end;

Function T_3D.ToScaledDeviceCoords(const Pt: TSPt2D;
  const scaleFactor: Single): TPoint;
begin
  RESULT.X := Round( scaleFactor * (Pt.X * DeviceScaleFactorX + MiddleOfDeviceBoxX) );
  RESULT.Y := Round( scaleFactor * (Pt.Y * DeviceScaleFactorY + MiddleOfDeviceBoxY) );
end;

Procedure T_3D.DrawCoordinatesystem(ACanvas: TCanvas);

  function TransformPoint(const Pt : TSPt3D): TPoint;
  begin
    RESULT := ToDeviceCoords(TransFormPoint3DTo2D(pt));
  end;

var _2DOrigoPt, _2DVectorEndPt : TPoint;
    _3DVectorEndPt             : TSPt3D;
    VectorSize                 : Single;
    KeepPenWidth               : Integer;
    KeepFontStyle              : TFontStyles;
begin
  if FXYZ then
  begin
    VectorSize := (2 * 45 / (CurrViewParams.ZoomFactor * ScreenZoomFac));
    if VectorSize <= 0 then
      VectorSize := 1
    else if VectorSize > RunTimeParameters.AabbDiagonal * 0.5 then
      VectorSize := RunTimeParameters.AabbDiagonal * 0.5;

    with ACanvas do
    begin
      with Pen do
      begin
        Color        := clBlue;
        Style        := psSolid;
        KeepPenWidth := Width;
        Width        := 2;
        Mode         := pmCopy;
      end;
      Font.Color     := clBlue;
    end;

    _2DOrigoPt          := TransformPoint(Origo);
    ACanvas.Brush.Style := bsClear;
    KeepFontStyle       := ACanvas.Font.Style;
    ACanvas.Font.Style  := [fsItalic] + [fsBold];
    ACanvas.TextOut(_2DOrigoPt.X, _2DOrigoPt.Y, 'O');
    ACanvas.Font.Style  := KeepFontStyle;

    if ( (CurrViewParams.ViewAzimuth <> 0) AND (CurrViewParams.ViewAzimuth <> 180) ) OR Projection then
    begin
      _3DVectorEndPt.X := VectorSize;
      _3DVectorEndPt.Y := 0;
      _3DVectorEndPt.Z := 0;
      _2DVectorEndPt   := TransformPoint(_3DVectorEndPt);

      With ACanvas do
      begin
        MoveTo(_2DOrigoPt.X, _2DOrigoPt.Y);
        LineTo(_2DVectorEndPt.X, _2DVectorEndPt.Y);
        TextOut(_2DVectorEndPt.X, _2DVectorEndPt.Y, 'X');
      end;
    end;

    if ( (abs(CurrViewParams.ViewAzimuth) <> 90) OR (CurrViewParams.ViewElevation <> 0) ) OR Projection then
    begin
      _3DVectorEndPt.X := 0;
      _3DVectorEndPt.Y := VectorSize;
      _3DVectorEndPt.Z := 0;
      _2DVectorEndPt   := TransformPoint(_3DVectorEndPt);

      With ACanvas do
      begin
        MoveTo(_2DOrigoPt.X, _2DOrigoPt.Y);
        LineTo(_2DVectorEndPt.X, _2DVectorEndPt.Y);
        TextOut(_2DVectorEndPt.X, _2DVectorEndPt.Y, 'Y');
      end;
    end;

    if (abs(CurrViewParams.ViewElevation) <> 90) OR Projection then
    begin
      _3DVectorEndPt.X := 0;
      _3DVectorEndPt.Y := 0;
      _3DVectorEndPt.Z := VectorSize;
      _2DVectorEndPt   := TransformPoint(_3DVectorEndPt);

      With ACanvas do
      begin
        MoveTo(_2DOrigoPt.X, _2DOrigoPt.Y);
        LineTo(_2DVectorEndPt.X, _2DVectorEndPt.Y);
        TextOut(_2DVectorEndPt.X, _2DVectorEndPt.Y + Font.Height, 'Z');
      end;
    end;
    ACanvas.Pen.Width := KeepPenWidth;
  end;
end;

procedure T_3D.getRunTimeParameters;
var i          : Integer;
    InvNpoints : Single;
    pt, Sum    : TSPt3D;
begin
  if ListOfPoints.Count > 0 then
  begin
    with RunTimeParameters do
    begin
      NpointsMinus1 := ListOfPoints.Count-1;

      Aabb.min.x := huge; Aabb.max.x := -huge;
      Aabb.min.y := huge; Aabb.max.y := -huge;
      Aabb.min.z := huge; Aabb.max.z := -huge;
      Sum.x := 0;  Sum.y := 0;  Sum.z := 0;

      for i := 0 to NpointsMinus1 do
      begin
        pt := ListOfPoints[i];

        Sum.x := Sum.x + pt.x;
        Sum.y := Sum.y + pt.y;
        Sum.z := Sum.z + pt.z;

        if pt.x < Aabb.min.x then Aabb.min.x := pt.x;
        if pt.x > Aabb.max.x then Aabb.max.x := pt.x;
        if pt.y < Aabb.min.y then Aabb.min.y := pt.y;
        if pt.y > Aabb.max.y then Aabb.max.y := pt.y;
        if pt.z < Aabb.min.z then Aabb.min.z := pt.z;
        if pt.z > Aabb.max.z then Aabb.max.z := pt.z;
      end;

      InvNpoints := 1/ListOfPoints.Count;
      Centroid.x := sum.x * InvNpoints;
      Centroid.y := sum.y * InvNpoints;
      Centroid.z := sum.z * InvNpoints;

      with Aabb do
        AabbDiagonal := Sqrt(Sqr(Max.X - min.X) + Sqr(Max.Y - min.Y) + Sqr(Max.Z - min.Z));
    end;
  end;
end;

Procedure T_3D.CalculateProjectionMatrix;
var
  CosA, SinA, CosE, SinE, CosR, SinR: Double;
  CutLength: Double;
  Length, TempLength: Single;
  CNum, ClosestCorner: Integer;
  pt : TSPt3D;
begin
  CosA := Cos(DegToRad(CurrViewParams.ViewAzimuth));
  SinA := Sin(DegToRad(CurrViewParams.ViewAzimuth));
  CosE := Cos((DegToRad(CurrViewParams.ViewElevation + 180)));
  SinE := Sin((DegToRad(CurrViewParams.ViewElevation + 180)));
  CosR := 1; { no Rotation }
  SinR := 0;

  ProjectionMatrix[1][1] := CosE * CosA;
  ProjectionMatrix[1][2] := CosE * SinA;
  ProjectionMatrix[1][3] := SinE;
  ProjectionMatrix[2][1] := -(CosR * SinA) - (SinR * SinE * CosA);
  ProjectionMatrix[2][2] := (CosR * CosA) - (SinR * SinE * SinA);
  ProjectionMatrix[2][3] := CosE * SinR;
  ProjectionMatrix[3][1] := (SinR * SinA) - (CosR * SinE * CosA);
  ProjectionMatrix[3][2] := -(SinR * CosA) - (CosR * SinE * SinA);
  ProjectionMatrix[3][3] := CosR * CosE;

  ViewNormal := AzimuthElevationToXYZ(DegToRad(CurrViewParams.ViewAzimuth), DegToRad(CurrViewParams.ViewElevation));
  with ViewNormal do
  begin  X := -X;  Y := -Y;  Z := -Z;  end;

  if CurrViewParams.Projection then
  begin
    with RunTimeParameters do
    begin
      ViewDistance := 1.4 * VectorLength(Centroid);

      Length       := 10000000;
      for CNum := 0 to NpointsMinus1 do
      begin
        pt := ListOfPoints[CNum];
        TempLength := abs(Sqrt(Sqr(pt.X - ViewNormal.X * 1000000) +
                               Sqr(pt.Y - ViewNormal.Y * 1000000) +
                               Sqr(pt.Z - ViewNormal.Z * 1000000)));
        if Length > TempLength then
        begin
          Length        := TempLength;
          ClosestCorner := CNum;
        end;
      end;
      CutLength := Distance(Centroid, ListOfPoints[ClosestCorner]);
    end;
    With EyePoint do
    begin
      X := -ViewNormal.X * (ViewDistance + CutLength);
      Y := -ViewNormal.Y * (ViewDistance + CutLength);
      Z := -ViewNormal.Z * (ViewDistance + CutLength);
    end;
  end;
end;

procedure T_3D.TransForm;
begin
  CalculateProjectionMatrix;
end;

Procedure T_3D.SetDeviceAsScreen;
Begin
  MiddleOfDeviceBoxX := Round(0.5 * Width);
  MiddleOfDeviceBoxY := Round(0.5 * Height);
  with Canvas do
  begin
    Font.Size      := 10;
    Brush.Color    := clBtnFace;
    OneCMInPixelsX := Round(GetDeviceCaps(Canvas.Handle, LOGPIXELSX) / 2.54);
    OneCMInPixelsY := Round(GetDeviceCaps(Canvas.Handle, LOGPIXELSY) / 2.54);
  end;

  DeviceScaleFactorX := 1;
  DeviceScaleFactorY := 1;
  CanvasCenter.X     := Round(MiddleOfDeviceBoxX);
  CanvasCenter.Y     := Round(MiddleOfDeviceBoxY);
end;

procedure T_3D.Draw(ACanvas: TCanvas);
var ASPt3D        : TSPt3D;
    Counter       : Integer;
    APoint, Point : TPoint;
begin
  DrawCoordinatesystem(ACanvas);
  DrawMeasures(ACanvas);

  case BeingDisplayed of
     AllPoints       :  DrawPoints(ACanvas);
     ActiveSetInRed  :
     begin
       DrawInactivePoints(ACanvas);
       DrawActivePoints(ACanvas);
       DrawBox(ACanvas,psSolid,clFuchsia,3);
     end;
     WrongSetInGreen :
     begin
       DrawInactivePoints(ACanvas);
       DrawActivePoints(ACanvas);
       DrawWrongPoints(ACanvas);
       DrawBox(ACanvas,psSolid,clFuchsia,3);
     end;
  end;
end;

procedure T_3D.Paint;
begin
  SetDeviceAsScreen;
  Draw(Canvas);
end;


procedure T_3D.DrawPoints(ACanvas: TCanvas);
var CornerCounter: Integer;
    SPt          : TSPt2D;
    Pt           : TPoint;
Const Size = 3;
begin
  Canvas.Pen.Color   := clBlack;
  Canvas.Brush.Color := clblack;
  for CornerCounter := 0 to ListOfPoints.Count-1 do
  begin
    SPt := TransFormPoint3DTo2D(ListOfPoints[CornerCounter]);
    Pt  := ToDeviceCoords(SPt);
    Canvas.Ellipse(Pt.X-Size,Pt.Y-Size,Pt.X+Size,Pt.Y+Size);
  end;
end;

procedure T_3D.DrawActivePoints(ACanvas: TCanvas);
var CornerCounter, CornerNo : Integer;
    SPt                     : TSPt2D;
    Pt                      : TPoint;
Const Size = {1.7}3;
begin
  Canvas.Pen.Color   := clred;
  Canvas.Brush.Color := clred;
  for CornerCounter := 0 to ListOfActivePointNo.Count-1 do
  begin
    CornerNo := ListOfActivePointNo[CornerCOunter];
    SPt      := TransFormPoint3DTo2D(ListOfPoints[CornerNo]);
    Pt       := ToDeviceCoords(SPt);
    Canvas.Ellipse(Pt.X-Size,Pt.Y-Size,Pt.X+Size,Pt.Y+Size);
  end;
end;

procedure T_3D.DrawInactivePoints(ACanvas: TCanvas);
var CornerCounter, CornerNo : Integer;
    SPt                     : TSPt2D;
    Pt                      : TPoint;
Const Size = 3;
begin
  Canvas.Pen.Color := clBlack;
  Canvas.Brush.Color := clBlack;
  for CornerCounter := 0 to ListOfInActivePointNo.Count-1 do
  begin
    CornerNo := ListOfInActivePointNo[CornerCOunter];
    SPt := TransFormPoint3DTo2D(ListOfPoints[CornerNo]);
    Pt  := ToDeviceCoords(SPt);
    Canvas.Ellipse(Pt.X-Size,Pt.Y-Size,Pt.X+Size,Pt.Y+Size);
  end;
end;

procedure T_3D.DrawWrongPoints(ACanvas: TCanvas);
var CornerCounter, CornerNo : Integer;
    SPt                     : TSPt2D;
    pt3D                    : TSPt3D;
    Pt                      : TPoint;
Const Size = 3;
begin
  Canvas.Pen.Color   := claqua;
  Canvas.Brush.Color := claqua;
  for CornerCounter  := 0 to ListOfWrongPointNo.Count-1 do
  begin
    CornerNo := ListOfWrongPointNo[CornerCOunter];
    pt3D     := ListOfPoints[CornerNo];
    SPt      := TransFormPoint3DTo2D(pt3D);
    Pt       := ToDeviceCoords(SPt);
    Canvas.Ellipse(Pt.X-Size,Pt.Y-Size,Pt.X+Size,Pt.Y+Size);
  end;
end;


procedure T_3D.DrawBox(ACanvas: TCanvas; const APenStyle : TPenStyle; const Acolor : TColor; const APenWidth : Integer);
var Pt1, pt2, pt3, pt4,
    pt5, pt6, pt7, pt8 : TPoint;
    InitPenStyle       : TPenStyle;
    Initcolor          : TColor;
    InitPenWidth       : Integer;
begin
  // Transform Points
  Pt1 := ToDeviceCoords(TransFormPoint3DTo2D(BoxPoints[1]));
  Pt2 := ToDeviceCoords(TransFormPoint3DTo2D(BoxPoints[2]));
  Pt3 := ToDeviceCoords(TransFormPoint3DTo2D(BoxPoints[3]));
  Pt4 := ToDeviceCoords(TransFormPoint3DTo2D(BoxPoints[4]));
  Pt5 := ToDeviceCoords(TransFormPoint3DTo2D(BoxPoints[5]));
  Pt6 := ToDeviceCoords(TransFormPoint3DTo2D(BoxPoints[6]));
  Pt7 := ToDeviceCoords(TransFormPoint3DTo2D(BoxPoints[7]));
  Pt8 := ToDeviceCoords(TransFormPoint3DTo2D(BoxPoints[8]));
  // Paint Edges
  with Canvas do
  begin
    InitPenStyle := Pen.Style;  InitColor := Pen.Color;    InitPenWidth := Pen.Width;
    Pen.Style    := APenStyle;  Pen.Color := AColor;       Pen.Width    := APenWidth;

    // lower 4 edges on XY plane
    Canvas.MoveTo(Pt1.X, Pt1.Y);
    Canvas.LineTo(Pt2.X, Pt2.Y);
    Canvas.LineTo(Pt3.X, Pt3.Y);
    Canvas.LineTo(Pt4.X, Pt4.Y);
    Canvas.LineTo(Pt1.X, Pt1.Y);

    // upper 4 edges on XY plane
    Canvas.MoveTo(Pt5.X, Pt5.Y);
    Canvas.LineTo(Pt6.X, Pt6.Y);
    Canvas.LineTo(Pt7.X, Pt7.Y);
    Canvas.LineTo(Pt8.X, Pt8.Y);
    Canvas.LineTo(Pt5.X, Pt5.Y);

    // upper 4 vertical edges along Z axis
    Canvas.MoveTo(Pt1.X, Pt1.Y);
    Canvas.LineTo(Pt5.X, Pt5.Y);
    Canvas.MoveTo(Pt2.X, Pt2.Y);
    Canvas.LineTo(Pt6.X, Pt6.Y);
    Canvas.MoveTo(Pt3.X, Pt3.Y);
    Canvas.LineTo(Pt7.X, Pt7.Y);
    Canvas.MoveTo(Pt4.X, Pt4.Y);
    Canvas.LineTo(Pt8.X, Pt8.Y);

    Pen.Style := InitPenStyle;  Pen.Color := InitColor;    Pen.Width := InitPenWidth;
  end;


end;

procedure T_3D.DrawMeasures(ACanvas: TCanvas);
var
  NumberOfTics, NumDec, Y_DownAdjustment,
  ActualNumTics, X, Y, I, CurrentHeight  : Integer;
  Value                                  : Double;
  Min, High, inc, FactorX, FactorY       : Single;
begin
  // Horizontal ruler
  if NOT(Projection) then
  begin
    CurrentHeight := Round(MiddleOfDeviceBoxY * 2);
    NumberOfTics  := Round(7 * 5 / 4 * Width / 800 );
    if NumberOfTics < 3 then NumberOfTics := 3;

    With ACanvas do
    begin
      Pen.Color   := clNavy;
      Font.Color  := clNavy;
      Brush.Style := bsClear;
      Min         := 0;
      High        :=  5 / 6 * Width / (CurrViewParams.ZoomFactor * ScreenZoomFac);

      AutoRange(Min, High, inc, NumberOfTics);

      FactorX := CurrViewParams.ZoomFactor * ScreenZoomFac * DeviceScaleFactorX;
      FactorY := CurrViewParams.ZoomFactor * ScreenZoomFac * DeviceScaleFactorY;

      if (inc >= 1) then         NumDec := 0
      else if inc >= 0.1 then    NumDec := 1
      else                       NumDec := 2;

      if Frac(inc * Power(10, NumDec)) > tiny then
        NumDec := NumDec + 1;

      ActualNumTics := Round((High - Min) / inc);
      MoveTo(Round(0.25 * OneCMInPixelsX), Round(0.1 * OneCMInPixelsY));
      LineTo(Round(0.25 * OneCMInPixelsX + (ActualNumTics - 1) * inc * FactorX),
        Round(0.1 * OneCMInPixelsY));

      SetTextAlign(Handle, Ta_Left);
      for I := 0 to ActualNumTics - 1 do
      begin
        Value := I * inc;
        X     := Round(0.25 * OneCMInPixelsX + Value * FactorX);
        Y     := Round(0.1 * OneCMInPixelsY);
        MoveTo(X, Y);
        LineTo(X, Y + Round(0.25 * OneCMInPixelsY));
        TextOut(X + Round(0.1 * OneCMInPixelsX),
          Y + Round(0.1 * OneCMInPixelsY), RealToStrLeft1(Value, NumDec));
      end;
      TextOut(X + Round(0.1 * OneCMInPixelsX) + TextWidth(RealToStrLeft1(Value,
        NumDec) + ' '), Y + Round(0.1 * OneCMInPixelsY),  '[m]');
    end;
    // vertical ruler
    With ACanvas do
    begin
      Min  := 0;
      High := (CurrentHeight - 4 * OneCMInPixelsY) / (CurrViewParams.ZoomFactor * ScreenZoomFac);

      ActualNumTics := Round((High - Min) / inc);
      NumberOfTics  := Round(NumberOfTics * Height / Width);
      if NumberOfTics > 10 then      NumberOfTics := 10
      else if NumberOfTics < 3 then  NumberOfTics := 3;

      AutoRange(Min, High, inc, NumberOfTics);

      if (inc >= 1) then        NumDec := 0
      else if inc >= 0.1 then   NumDec := 1
      else                      NumDec := 2;

      if Frac(inc * Power(10, NumDec)) > tiny then
        NumDec := NumDec + 1;

      if TextHeight('X') * 1.3 < inc * FactorY then
      // only draw scale if there is decent space for it
      begin
        Y_DownAdjustment := -Round(1.3 * OneCMInPixelsY);
        ActualNumTics := Round((High - Min) / inc);
        MoveTo(Round(0.1 * OneCMInPixelsX), Round(CurrentHeight + Y_DownAdjustment));
        LineTo(Round(0.1 * OneCMInPixelsX), Round(CurrentHeight + Y_DownAdjustment - (ActualNumTics - 1) * inc * FactorY));

        for I := 0 to ActualNumTics - 1 do
        begin
          Value := I * inc;
          X     := Round(0.1 * OneCMInPixelsX);
          Y      := Round(Round(CurrentHeight + Y_DownAdjustment) - Value * FactorY);

          MoveTo(X, Y);
          LineTo(X + Round(0.1 * OneCMInPixelsX), Y);
          TextOut(X + Round(0.1 * OneCMInPixelsX), Y + Round(0.1 * OneCMInPixelsY), RealToStrLeft1(Value, NumDec));
        end;
        TextOut(X + Round(0.1 * OneCMInPixelsX) + TextWidth(RealToStrLeft1(Value, NumDec) + ' '), Y + Round(0.1 * OneCMInPixelsY), '[m]');
      end;
    end;
  end;
end;

procedure T_3D.ChangeView(ViewOperation: TViewOperation);
var CursorPos, CenterToCursorPos: TPoint;
begin
  SetSmallViewSteps(SmallSteps);
  with CurrViewParams do
  begin
    case ViewOperation of

      cvMoveLeft:
      begin
        if ( (Xtranslation - TranslateStep / (CurrViewParams.ZoomFactor * ScreenZoomFac) ) > -MaxTransLate) then
          Xtranslation := Xtranslation - TranslateStep / CurrViewParams.ZoomFactor;
//        else showmessage('Move limit')
      end;
      cvMoveRight:
      begin
        if ((Xtranslation + TranslateStep / (CurrViewParams.ZoomFactor * ScreenZoomFac)) < MaxTransLate) then
          Xtranslation := Xtranslation + TranslateStep / CurrViewParams.ZoomFactor;
//        else  showmessage('Move limit')
      end;
      cvMoveUp:
      begin
        if ((Ytranslation - TranslateStep / (CurrViewParams.ZoomFactor * ScreenZoomFac)) > -MaxTransLate) then
          Ytranslation := Ytranslation - TranslateStep / CurrViewParams.ZoomFactor;
//        else  showmessage('Move limit')
      end;
      cvMoveDown:
      begin
        if ((Ytranslation + TranslateStep / (CurrViewParams.ZoomFactor * ScreenZoomFac)) < MaxTransLate) then
          Ytranslation := Ytranslation + TranslateStep / CurrViewParams.ZoomFactor;
//        else  showmessage('Move limit')
      end;
      cvRotateLeft:
      begin
        ViewAzimuth := (ViewAzimuth + AngleStep);
        if ViewAzimuth > 180 then ViewAzimuth := ViewAzimuth - 360;
      end;
      cvRotateRight:
      begin
        ViewAzimuth := (ViewAzimuth - AngleStep);
        if ViewAzimuth < -180 then ViewAzimuth := ViewAzimuth + 360;
      end;
      cvRotateDown:
      begin
        ViewElevation := (ViewElevation - AngleStep);
        if ViewElevation < -90 then
        begin
  //        showmessage('Min. elevation');
          ViewElevation := -90;
        end;
      end;
      cvRotateUp:
      begin
        ViewElevation := (ViewElevation + AngleStep);
        if ViewElevation > 90 then
        begin
//          showmessage('Max. elevation');
          ViewElevation := 90;
        end;
      end;
      cvZoomIn:
      begin
        CursorPos := ScreenToClient(Mouse.CursorPos);
        CenterToCursorPos := CursorPos - CanvasCenter;

        // translate ClosestCorner To CanvasCenter
        CurrViewParams.Xtranslation := CurrViewParams.Xtranslation - (CenterToCursorPos.X / (CurrViewParams.ZoomFactor * ScreenZoomFac));
        CurrViewParams.Ytranslation := CurrViewParams.Ytranslation - (CenterToCursorPos.Y / (CurrViewParams.ZoomFactor * ScreenZoomFac));

        TransForm;

        if ZoomFactor * ScreenZoomFac < MaxZoom then
          ZoomFactor := ZoomFactor * ZoomStep;
        // else showmessage('Zoom limit');

        // apply Zoom
        TransForm;
        // Translate Closer Node To Original Position
        CurrViewParams.Xtranslation := CurrViewParams.Xtranslation + (CenterToCursorPos.X / (CurrViewParams.ZoomFactor * ScreenZoomFac));
        CurrViewParams.Ytranslation := CurrViewParams.Ytranslation + (CenterToCursorPos.Y / (CurrViewParams.ZoomFactor * ScreenZoomFac));
      end;
      cvZoomOut       :
      begin
        CursorPos := ScreenToClient(Mouse.CursorPos);
        CenterToCursorPos := CursorPos - CanvasCenter;

        // translate ClosestCorner To CanvasCenter
        CurrViewParams.Xtranslation := CurrViewParams.Xtranslation - (CenterToCursorPos.X / (CurrViewParams.ZoomFactor * ScreenZoomFac));
        CurrViewParams.Ytranslation := CurrViewParams.Ytranslation - (CenterToCursorPos.Y / (CurrViewParams.ZoomFactor * ScreenZoomFac));
        TransForm;

        if (ZoomFactor * ScreenZoomFac > MinZoom) then
          ZoomFactor := ZoomFactor / ZoomStep;
//        else   showmessage('Zoom limit');

        // apply Zoom
        TransForm;

        // Translate Closer Node To Original Position
        CurrViewParams.Xtranslation := CurrViewParams.Xtranslation + (CenterToCursorPos.X / (CurrViewParams.ZoomFactor * ScreenZoomFac));
        CurrViewParams.Ytranslation := CurrViewParams.Ytranslation + (CenterToCursorPos.Y / (CurrViewParams.ZoomFactor * ScreenZoomFac));
      end;
      cvNextView:     CurrViewParams := ViewList.GetNextView(CurrViewNo);
      cvPreviousView: CurrViewParams := ViewList.GetPreviousView(CurrViewNo);
    end;
  end;

  TransForm;
  Invalidate;
end;

Procedure T_3D.SetSmallViewSteps(NewValueSmallSteps: Boolean);
begin
  FSmallSteps := NewValueSmallSteps;
  if FSmallSteps Then
  begin
    AngleStep := 1;
    TranslateStep := 5;
    ZoomStep := 1.05;
  end
  else
  begin
    AngleStep := 10;
    TranslateStep := 50;
    ZoomStep := 1.5;
  end;
end;

function T_3D.GetProjection: Boolean;
begin
  RESULT := CurrViewParams.Projection;
end;

Procedure T_3D.SetProjection(NewValue: Boolean);
begin
  if NewValue <> CurrViewParams.Projection then
  begin
    CurrViewParams.Projection := NewValue;
    if NewValue then
      CurrViewParams.ZoomFactor := 1.5 * CurrViewParams.ZoomFactor
    else
      CurrViewParams.ZoomFactor := 2 / 3 * CurrViewParams.ZoomFactor;
    TransForm;
    Invalidate;
  end;
end;

Procedure T_3D.SetViewAngles(const DegAzimuth, DegElevation : Integer);
begin
  CurrViewParams.ViewAzimuth := DegAzimuth;
  CurrViewParams.ViewElevation := DegElevation;
  TransForm;
end;

function T_3D.RealToStrLeft1(const R : Double; const Dec : Integer) : string;
begin
  RESULT := FloatToStrF(R, ffFixed, 15, Dec);
end;

function T_3D.GetXYZString(const X,Y,Z : Double; const Dec : Integer) : String;
var SepStr:String;
begin
  SepStr := ',';
  RESULT := '(x,y,z) = (' + RealToStrLeft1(X,Dec)+SepStr+
                            RealToStrLeft1(Y,Dec)+SepStr+
                            RealToStrLeft1(Z,Dec)+')';
end;

end.
