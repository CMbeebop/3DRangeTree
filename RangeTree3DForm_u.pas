unit RangeTree3DForm_u;

{ Constructed for the validation of T3DRangeTree and TDS2 in RangeTree3D_u.pas.

  HOW TO USE:
  1.- Select the number of Points for the analysis.
  2.- Generate Random Numbers Button -> created in the unitary cube centered at [0.5,0.5,0.5] m.
  3.- Define your 3D range in the top right edits anc click on Get points in Range button.
  4.- Clear Range and repeat 3 while necessary using the same Points
  5.- Change the points using 2 and keep the range or change it as you wish.

  NAVIGATOR:
  The purple box is the studied 3D Range, points in Red are inside the range and those
  in Black are outside. See _3D.pas for an overview on Navigator functionalities and shortcuts.

  VALIDATION MODE:
  For testing T3DRangeTree switch on CD Validation which computes also a Naive Solution
  that we compare with T3DRangeTree one. Any disagreement Point is reported and colored
  in blue in the Navigator.

  Similarly ValidationDS2 compares with a naive solution reports and colors false detections.
  All modes of DS2 can be tested by changing TForm1.DS2Mode.

  you can define a path for PointsFilename in TForm1.Create, then every time random
  points are generated their locations are saved to the file (overwriting previous content).

  Additionally a function for solving multiple problems with different random points in the
  same 3Drange is given in the procedure TForm1.TestNRandomSamples. remember to comment the
  lines that do the painting in this unit to save time. In case a False detection is found
  you can use switch HowToObtainPoints = fromfile to recover the data that produced the failure
  in the selected range for debugging (needs PointsFilename definition by the user).

  The DS were tested for some thousands of experiments, and no false detection that wasnt too
  close to the box border could be reported, you can see one of those in
  PointsFile_NumericalProblem.txt for the range [0.3,0.7]x[0.3,0.7]x[0.3,0.7] }

{.$DEFINE Validation}   // only one of this two conditional defines can be switched on
{.$DEFINE ValidationDS2}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Generics.collections, Generics.Defaults, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ActnList,
  _3D, _3DDefinitions_u, QuarterRangeSearch_u, RangeTree3D_u, System.Actions;

type THowToObtainPoints = (fromFile, randomPoints);

type
  TForm1 = class(TForm)
    GenerateRandomPointsButton,
    GetPointsInRangeButton                    : TButton;
    Label1, Label3, Label4, Label5, Label6,
    Label7, Label8, Label9, Label10, Label11  : TLabel;
    Edit1, Edit2, Edit3, Edit4, Edit5, Edit6,
    Edit7                                     : TEdit;
    Panel1                                    : TPanel;
    ActionList1                               : TActionList;
    Action1                                   : TAction;

    procedure GenerateRandomPointsButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClearData;
    procedure FormDestroy(Sender: TObject);
    procedure GetPointsInRangeButtonClick(Sender: TObject);
    procedure ClearRangeButtonClick(Sender: TObject);
    procedure OnMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure Panel1MouseEnter(Sender: TObject);
    procedure Panel1MouseLeave(Sender: TObject);
    procedure Action1Execute(Sender: TObject);
    procedure FormResize(Sender: TObject);

  private
    _3DH               : T_3D;
    isCursorInsidePanel1,
    isAnyThingPainted  : Boolean;
    HowToObtainPoints  : THowToObtainPoints;
    pointsFIleName     : String;
    ListOfKeys         : TList<TKey3D>;
    DictOfKeyToTSPt3D  : TDictionary<TKey3D,TSPt3D>;
    InvOfDomainOfPointsSize,
    DomainOfPointsSize : Single;
    {$IFDEF ValidationDS2}
    DS2Mode            : TDS2Mode;
    DS2                : TDS2;
    {$ELSE}
    RT3D               : T3DRangeTree;
    {$ENDIF}

    procedure getRandomPoints;
    procedure WritePointsFile;
    procedure readPointsFile;
    function GetNaiveSolution(const k1, k2 : TSPt3D) : TList<Boolean>;
    function GetNaiveSolutionDS2(const k1, k2 : TSPt3D; const mode : TDS2Mode) : TList<Boolean>;
    function GetTSPt3DFromTKey3D(const key : TKey3D) : TSPt3D;
    function getRangeBox(var k1,k2 : TSPt3D) : Boolean;
    procedure TestNRandomSamples(const N, NPoints : Integer);
    procedure GenerateRandomPoints(const Npoints : Integer);
    procedure GetPointsInRange(const k1,k2 : TSPt3D);

    public
    PointsNo : Integer;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

function TForm1.getRangeBox(var k1,k2 : TSPt3D) : Boolean;
var k1x, k1y, k1z, k2x, k2y, k2z   : Single;
    isk1xMinusInf, isk2xInf,
    isk1yMinusInf, isk2yInf,
    isk1zMinusInf, isk2zInf        : Boolean;
    Astring                        : string;
begin
  // xRange
  if Edit2.Text = '-Inf' then isk1xMinusInf := TRUE
  else
  begin
    try
      Astring := StringReplace(Edit2.Text,',', '.',[rfReplaceAll, rfIgnoreCase]);
      k1x := strtoFloat(Astring);
      isk1xMinusInf := FALSE;
    except
      RESULT := FALSE;
      Exit;
    end;
  end;

  if Edit3.Text = 'Inf' then isk2xInf := TRUE
  else
  begin
    try
      Astring := StringReplace(Edit3.Text,',', '.',[rfReplaceAll, rfIgnoreCase]);
      k2x := strtoFloat(Astring);
      isk2xInf := FALSE;
    except
      RESULT := FALSE;
      Exit;
    end;
  end;

  // yRange
  if Edit4.Text = '-Inf' then isk1yMinusInf := TRUE
  else
  begin
    try
      Astring := StringReplace(Edit4.Text,',', '.',[rfReplaceAll, rfIgnoreCase]);
      k1y := strtoFloat(Astring);
      isk1yMinusInf := FALSE;
    except
      RESULT := FALSE;
      Exit;
    end;
  end;

  if Edit5.Text = 'Inf' then isk2yInf := TRUE
  else
  begin
    try
      Astring := StringReplace(Edit5.Text,',', '.',[rfReplaceAll, rfIgnoreCase]);
      k2y := strtoFloat(Astring);
      isk2yInf := FALSE;
    except
      RESULT := FALSE;
      Exit;
    end;
  end;

  // zRange
  if Edit6.Text = '-Inf' then isk1zMinusInf := TRUE
  else
  begin
    try
      Astring := StringReplace(Edit6.Text,',', '.',[rfReplaceAll, rfIgnoreCase]);
      k1z := strtoFloat(Astring);
      isk1zMinusInf := FALSE;
    except
      RESULT := FALSE;
      Exit;
    end;
  end;

  if Edit7.Text = 'Inf' then isk2zInf := TRUE
  else
  begin
    try
      Astring := StringReplace(Edit7.Text,',', '.',[rfReplaceAll, rfIgnoreCase]);
      k2z := strtoFloat(Astring);
      isk2zInf := FALSE;
    except
      RESULT := FALSE;
      Exit;
    end;
  end;

  // Reached This line We have a Correct input
  if isk1xMinusInf then k1x := -100000;
  if isk2xInf      then k2x :=  100000;
  if isk1yMinusInf then k1y := -100000;
  if isk2yInf      then k2y :=  100000;
  if isk1zMinusInf then k1z := -100000;
  if isk2zInf      then k2z :=  100000;

  // get 3D points k1, k2
  if k1x < k2x then   begin  k1.x := k1x;  k2.x := k2x;  end
  else                begin  k1.x := k2x;  k2.x := k1x;  end;

  if k1y < k2y then   begin  k1.y := k1y;  k2.y := k2y;  end
  else                begin  k1.y := k2y;  k2.y := k1y;  end;

  if k1z < k2z then   begin  k1.z := k1z;  k2.z := k2z;  end
  else                begin  k1.z := k2z;  k2.z := k1z;  end;

  RESULT := TRUE;
end;

procedure TForm1.OnMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var pt : TPoint;
begin
  if isAnyThingPainted then
  begin
    if isCursorInsidePanel1 then
    begin
      Pt := _3DH.ScreenToClient(MousePos);
      if (Pt.X < _3DH.Width) and (Pt.Y <_3DH.Height) then
      begin
        if WheelDelta > 0 then _3DH.ChangeView(cvZoomIn)
        else                   _3DH.ChangeView(cvZoomOut);
        Handled := TRUE;
      end;
    end;
  end;
end;

procedure TForm1.Panel1MouseEnter(Sender: TObject);
begin
  isCursorInsidePanel1 := TRUE;
end;

// doesn't work I dont now why
procedure TForm1.Panel1MouseLeave(Sender: TObject);
begin
 // isCursorInsidePanel1 := FALSE;
end;

function TForm1.GetTSPt3DFromTKey3D(const key : TKey3D) : TSPt3D;
begin
  with RESULT do
  begin  x := key.x;  y := key.y;  z := key.z;  end;
end;

function TForm1.GetNaiveSolutionDS2(const k1, k2 : TSPt3D; const mode : TDS2Mode) : TList<Boolean>;
var i        : Integer;
    pt       : TSPt3D;
    kx1, kx2,
    ky1, ky2,
    kz1,kz2  : Single;
begin
  RESULT := TList<Boolean>.create;

  // prepare Box Range
  if k2.x < k1.x then
  begin kx1 := k2.x; kx2 := k1.x; end
  else
  begin kx1 := k1.x; kx2 := k2.x; end;

  if k2.y < k1.y then
  begin ky1 := k2.y; ky2 := k1.y; end
  else
  begin ky1 := k1.y; ky2 := k2.y; end;

  if k2.z < k1.z then
  begin kz1 := k2.z; kz2 := k1.z; end
  else
  begin kz1 := k1.z; kz2 := k2.z; end;


  case mode of

    XmYmZ :

    begin
      for i := 0 to ListOfPoints.Count-1 do
      begin
        pt := ListOfPoints[i];
        // Exclude points out of the box
        if (pt.x < kx1) OR (pt.x > kx2) OR       {out of x range}
           (pt.y > ky2) OR (pt.z > kz2) then     {not dominated by (<y2,<z2)}
             RESULT.Add(FALSE)
        else RESULT.Add(TRUE);
      end;
    end;

    XmYpZ :

    begin
      for i := 0 to ListOfPoints.Count-1 do
      begin
        pt := ListOfPoints[i];
        // Exclude points out of the box
        if (pt.x < kx1) OR (pt.x > kx2) OR       {out of x range}
           (pt.y > ky2) OR (pt.z < kz1) then     {not dominated by (<y2,>z1)}
             RESULT.Add(FALSE)
        else RESULT.Add(TRUE);
      end;
    end;

    XpYmZ :

    begin
      for i := 0 to ListOfPoints.Count-1 do
      begin
        pt := ListOfPoints[i];
        // Exclude points out of the box
        if (pt.x < kx1) OR (pt.x > kx2) OR       {out of x range}
           (pt.y < ky1) OR (pt.z > kz2) then     {not dominated by (>y1,<z2)}
             RESULT.Add(FALSE)
        else RESULT.Add(TRUE);
      end;
    end;

    XpYpZ :

    begin
      for i := 0 to ListOfPoints.Count-1 do
      begin
        pt := ListOfPoints[i];
        // Exclude points out of the box
        if (pt.x < kx1) OR (pt.x > kx2) OR       {out of x range}
           (pt.y < ky1) OR (pt.z < kz1) then     {not dominated by (>y1,>z1)}
             RESULT.Add(FALSE)
        else RESULT.Add(TRUE);
      end;
    end;

  end;
end;

function TForm1.GetNaiveSolution(const k1, k2 : TSPt3D) : TList<Boolean>;
{check validity for all points}
var i                             : Integer;
    pt                            : TSPt3D;
    kx1, kx2, ky1, ky2, kz1, kz2  : Single;
begin
  RESULT := TList<Boolean>.create;

  // prepare Box Range
  if k2.x < k1.x then
  begin kx1 := k2.x; kx2 := k1.x; end
  else
  begin kx1 := k1.x; kx2 := k2.x; end;

  if k2.y < k1.y then
  begin ky1 := k2.y; ky2 := k1.y; end
  else
  begin ky1 := k1.y; ky2 := k2.y; end;

  if k2.z < k1.z then
  begin kz1 := k2.z; kz2 := k1.z; end
  else
  begin kz1 := k1.z; kz2 := k2.z; end;


  for i := 0 to ListOfPoints.Count-1 do
  begin
    pt := ListOfPoints[i];
    // Exclude points out of the box
    if (pt.x < kx1) OR (pt.x > kx2) OR
       (pt.y < ky1) OR (pt.y > ky2) OR
       (pt.z < kz1) OR (pt.z > kz2) then RESULT.Add(FALSE)
    else                                 RESULT.Add(TRUE);
  end;
end;

procedure TForm1.GetPointsInRangeButtonClick(Sender: TObject);
var k1, k2            : TSPt3D;
    key1, key2, key   : TKey3D;
    ListOfIsActive,
    ListOfIsActive2,
    ListOfIsWrong     : TList<Boolean>;
    D                 : TDictionary<TKey3D,Boolean>;
    PtNo, WrongNo     : Integer;
begin

  if getRangeBox(k1,k2) then
  begin
    // create TKey3D key1, key2  -> Close bounds
    key1 := TKey3D.create(k1.x,k1.y,k1.z,-1);
    key2 := TKey3D.create(k2.x,k2.y,k2.z,High(Integer));

    {$IFDEF ValidationDS2}
    D := DS2.getDictOfMembersInRange(key1,key2);
    {$ELSE}
    D := RT3D.getDictOfMembersInRange(key1,key2);
    {$ENDIF}

    ListOfIsActive := TList<Boolean>.create;
    for PtNo := 0 to ListOfKeys.Count-1 do
    begin
      key := ListOfKeys[ptNo];
      if D.ContainsKey(key) then  ListOfIsActive.Add(TRUE)
      else                        ListOfIsActive.Add(FALSE);
    end;

    {$IFDEF ValidationDS2}
    ListOfIsActive2 := GetNaiveSolutionDS2(GetTSPt3DFromTKey3D(key1),
                                           GetTSPt3DFromTKey3D(key2),DS2.mode);
    ListOfIsWrong := TList<Boolean>.create;
    WrongNo       := 0;
    for PtNo := 0 to ListOfPoints.Count-1 do
    begin
      if ListOfIsActive2[PtNo] <> ListOfIsActive[ptNo] then
      begin
        ListOfIsWrong.Add(TRUE);
        Inc(WrongNo);
      end
      else  ListOfIsWrong.Add(FALSE);
    end;

    // you might want to comment this line for using TestNRandomSamples
    _3DH.SetBeingDisplayed(k1,k2,ListOfIsActive,ListOfIsWrong);

    if WrongNo = 0 then  //showmessage('DS2 Agrees Naive Solution')
    else                 showmessage('DS2 Validation Error : ' + WrongNo.ToString + ' false detections');

    ListOfIsActive2.Free;
    ListOfIsWrong.Free;
    {$ENDIF}

    {$IFDEF Validation}
    ListOfIsActive2 := GetNaiveSolution(GetTSPt3DFromTKey3D(key1),
                                        GetTSPt3DFromTKey3D(key2));
    ListOfIsWrong := TList<Boolean>.create;
    WrongNo       := 0;
    for PtNo := 0 to ListOfPoints.Count-1 do
    begin
      if ListOfIsActive2[PtNo] <> ListOfIsActive[ptNo] then
      begin
        ListOfIsWrong.Add(TRUE);
        Inc(WrongNo);
      end
      else  ListOfIsWrong.Add(FALSE);
    end;

    _3DH.SetBeingDisplayed(k1,k2,ListOfIsActive,ListOfIsWrong);

    if WrongNo = 0 then  //showmessage('3DRangeTree Agrees Naive Solution')
    else                 showmessage('3DRangeTree Validation Error : ' + WrongNo.ToString + ' false detections');

    ListOfIsActive2.Free;
    ListOfIsWrong.Free;
    {$ELSE}

    {$IFNDEF ValidationDS2D}
    _3DH.SetBeingDisplayed(k1,k2,ListOfIsActive);
    {$ENDIF}

    {$ENDIF}
    ListOfIsActive.Free;
    key1.Free;
    key2.Free;
  end
  else showmessage('Invalid Range Box Input')

end;


procedure TFOrm1.getRandomPoints;
var i    : Integer;
    pt3D : TSPt3D;
begin
  for i := 0 to PointsNo-1 do
  begin
    with pt3D do
    begin
      x := random*DomainOfPointsSize;
      y := random*DomainOfPointsSize;
      z := random*DomainOfPointsSize;
    end;
    ListOfPoints.Add(pt3D);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  ListOfPoints      := TList<TSPt3D>.create;
  ListOfKeys        := TList<TKey3D>.create;
  DictOfKeyToTSPt3D := TDictionary<TKey3D,TSPt3D>.create;

  {$IFDEF ValidationDS2}
  DS2               := TDS2.create;
  {$ELSE}
  RT3D              := T3DRangeTree.create;
  {$ENDIF}

  DomainOfPointsSize      := 1;
  InvOfDomainOfPointsSize := 1/DomainOfPointsSize;

  Panel1.Parent := Self;
  FormResize(self);

  isAnyThingPainted    := FALSE;
  isCursorInsidePanel1 := FALSE;
  HowToObtainPoints    := randomPoints; {fromFile;}
  PointsFileName       := '';
//  PointsFileName       := ' WRITE HERE A PATH \pointsFile.txt';

  {$IFDEF ValidationDS2}
  DS2Mode := XmYmZ;
  // Uncomment For Validate DS2 in a number of Experiments
  // TestNRandomSamples(1000,500);
  {$ENDIF}



end;


procedure TForm1.Action1Execute(Sender: TObject);
begin
  _3DH.changeView(cvNextView);
end;

procedure TForm1.ClearRangeButtonClick(Sender: TObject);
begin
  // clear edits
  Edit2.Text := '';   Edit3.Text := '';
  Edit4.Text := '';   Edit5.Text := '';
  Edit6.Text := '';   Edit7.Text := '';

  _3DH.UnSetBeingDisplayed;
end;

procedure TForm1.FormClearData;
var i : Integer;
begin
  ListOfPoints.Clear;
  for i := 0 to ListOfKeys.Count-1 do
    ListOfKeys[i].Free;
  ListOfKeys.Clear;
  DictOfKeyToTSPt3D.Clear;
  _3DH.Free;
  {$IFDEF ValidationDS2}
  DS2.Clear;
  {$ELSE}
  RT3D.Clear;
  {$ENDIF}
end;

procedure TForm1.FormDestroy(Sender: TObject);
var  i: Integer;
begin
  FormClearData;

  ListOfPoints.Free;
  ListOfKeys.Free;
  DictOfKeyToTSPt3D.Free;
  {$IFDEF ValidationDS2}
  DS2.free;
  {$ELSE}
  RT3D.Free;
  {$ENDIF}
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  Panel1.Left   := 0;
  Panel1.Width  := Self.Width;
  Panel1.Top    := 140;
  Panel1.height := Self.Height-Panel1.Top;
end;


procedure TForm1.GenerateRandomPointsButtonClick(Sender: TObject);
var oldSize, i : Integer;
    key        : TKey3D;
    pt3D       : TSPt3D;
begin
  FormClearData;

  if HowToObtainPoints = randomPoints then
  begin
    PointsNo := strToInt(Edit1.text);
    getRandomPoints;
    if (pointsFileName <> '') {AND ListOfPoints.Count < 1001} then
      WritePointsFile;
  end
  else
  begin
    if pointsFIleName = '' then showmessage('pointsFileName has not been specified in the code')
    else                        readPointsFile;
  end;

  // Build ListOfKeys
  for i := 0 to ListOfPoints.Count-1 do
  begin
    pt3D         := ListOfPoints[i];
    key          := TKey3D.create(pt3D.x,pt3D.y,pt3D.z,i);
    ListOfKeys.Add(key);
    DictOfKeyToTSPt3D.Add(key,pt3D);
  end;

  _3DH := T_3D.create(Self);
  with _3DH do
  begin
    Parent  := Panel1;
    Align   := alClient;
    Visible := TRUE;
    XYZ     := TRUE;
    Invalidate;
  end;

  // Build Data structure
  {$IFDEF ValidationDS2}
  DS2.BuildTree(0,ListOfKeys.Count-1,ListOfKeys,DS2Mode);
  {$ELSE}
  RT3D.BuildTree(0,ListOfKeys.Count-1,ListOfKeys);
  {$ENDIF}

  isAnyThingPainted := TRUE;
end;

procedure TForm1.writePointsFile;
var StringLine : String;
    FileString : TStringList;
    counter    : Integer;
    pt         : TSPt3D;
begin
  // write to Par File
  FileString := TStringList.Create;
  for counter := 0 to ListOfPoints.Count-1 do
  begin
    pt := ListOfPoints[counter];
    StringLine := pt.x.ToString + #9 + pt.y.ToString + #9 + pt.z.ToString;
    FileString.Add(StringLine);
  end;
  // Save to File
  FileString.SaveToFile(pointsFileName);
  // Free memory
  FileString.Free;
end;


procedure TForm1.readPointsFile;

    type CharSet = set of Char;

    function ExtractWord(N : Integer; S : string; WordDelims : CharSet) : string;
      {-Given a set of word delimiters, return the N'th word in S}
    var
      StringLength:Integer;
      NBegin,I, Count:Integer;
    begin
      Count := 0;
      I := 1;
      RESULT := '';
      StringLength := Length(S);
      while (I <= StringLength) and (Count <> N) do begin
        {skip over delimiters}
        while (I <= StringLength) and (S[I] in WordDelims) do
          Inc(I);
        {if we're not beyond end of S, we're at the start of a word}
        if I <= StringLength then
          Inc(Count);//we have found the Count word
        {find the end of the current word}

        NBegin := I;//faster because miltiple realloc is avoided
        while (I <= StringLength) and not(S[I] in WordDelims) do //reading then Count'th word
          Inc(I);
        if Count = N then	RESULT := Copy(S,NBegin,I-NBegin);
      end;
    end;

    FUNCTION ExtractSingle(N: Integer; s: string; var Code :Integer; Delims : CharSet; VAR v: Single): Boolean;
    { Evaluates the Single value of the N'th word in string s.
      Does NOT check whether s contains that many words.
      Code contains the position in s of the offending character. }
    begin
      s := ExtractWord(N, s, Delims);
      Val(s, V, Code);
      ExtractSingle := (Code = 0);
    end;

var myFile      : TextFile;
    AString     : String;
    pt          : TSPt3D;
    code        : Integer;
begin
  AssignFile(myFile,pointsFileName);
  FileMode := 0;
  reset(myFile);

  ListOfPoints.Clear;
  while (NOT EOF(MyFile)) do
  begin
    ReadLn(myFile,AString);
    ExtractSingle(1,Astring,Code,[#9],Pt.x);
    ExtractSingle(2,Astring,Code,[#9],Pt.y);
    ExtractSingle(3,Astring,Code,[#9],Pt.z);
    ListOfPoints.Add(pt);
  end;
  CloseFile(myFile);
  PointsNo := ListOfPoints.Count;
end;

procedure TForm1.TestNRandomSamples(const N, NPoints : Integer);
var  i      : Integer;
     k1, k2 : TSPt3D;
begin
  k1.x := 0.3; k1.y := 0.3; k1.z := 0.3;
  k2.x := 0.7; k2.y := 0.7; k2.z := 0.7;

  for i := 1 to N do
  begin
     outputdebugstring(pchar('TestNo = ' +  i.ToString));
     GenerateRandomPoints(Npoints);
     GetPointsInRange(k1,k2);
  end;
end;

procedure TForm1.GenerateRandomPoints(const Npoints : Integer);
var oldSize, i : Integer;
    key        : TKey3D;
    pt3D       : TSPt3D;
begin
  FormClearData;

  PointsNo := Npoints;
  getRandomPoints;

  if PointsFileName <> '' then WritePointsFile;

  // Build ListOfKeys
  for i := 0 to ListOfPoints.Count-1 do
  begin
    pt3D         := ListOfPoints[i];
    key          := TKey3D.create(pt3D.x,pt3D.y,pt3D.z,i);
    ListOfKeys.Add(key);
    DictOfKeyToTSPt3D.Add(key,pt3D);
  end;

  _3DH := T_3D.create(Self);
  with _3DH do
  begin
    Parent  := Panel1;
    Align   := alClient;
    Visible := TRUE;
    XYZ     := TRUE;
    Invalidate;
  end;

  // Build Data structure
  {$IFDEF ValidationDS2}
  DS2.BuildTree(0,ListOfKeys.Count-1,ListOfKeys,DS2Mode);
  {$ENDIF}

//  DS3.BuildTree(0,ListOfKeys.Count-1,ListOfKeys,RightWardInf);
//  RT3D.BuildTree(0,ListOfKeys.Count-1,ListOfKeys);

  isAnyThingPainted := TRUE;
end;

procedure TForm1.GetPointsInRange(const k1,k2 : TSPt3D);
var key1, key2, key   : TKey3D;
    ListOfIsActive,
    ListOfIsActive2,
    ListOfIsWrong     : TList<Boolean>;
    D                 : TDictionary<TKey3D,Boolean>;
    PtNo, WrongNo     : Integer;
begin

  // create TKey3D key1, key2  -> Close bounds
  key1 := TKey3D.create(k1.x,k1.y,k1.z,-1);
  key2 := TKey3D.create(k2.x,k2.y,k2.z,High(Integer));

 //   D := DS2.getDictOfMembersInRange(key1,key2);
 //   D := DS3.getDictOfMembersInRange(key1,key2);
 //   D := RT3D.getDictOfMembersInRange(key1,key2);

  {$IFDEF ValidationDS2}
  D := DS2.getDictOfMembersInRange(key1,key2);
  {$ENDIF}


  ListOfIsActive := TList<Boolean>.create;
  for PtNo := 0 to ListOfKeys.Count-1 do
  begin
    key := ListOfKeys[ptNo];
    if D.ContainsKey(key) then  ListOfIsActive.Add(TRUE)
    else                        ListOfIsActive.Add(FALSE);
  end;

  {$IFDEF ValidationDS2}
  ListOfIsActive2 := GetNaiveSolutionDS2(GetTSPt3DFromTKey3D(key1),
                                         GetTSPt3DFromTKey3D(key2),DS2.mode);
  ListOfIsWrong := TList<Boolean>.create;
  WrongNo       := 0;
  for PtNo := 0 to ListOfPoints.Count-1 do
  begin
    if ListOfIsActive2[PtNo] <> ListOfIsActive[ptNo] then
    begin
      ListOfIsWrong.Add(TRUE);
      Inc(WrongNo);
    end
    else  ListOfIsWrong.Add(FALSE);
  end;

  _3DH.SetBeingDisplayed(k1,k2,ListOfIsActive,ListOfIsWrong);

  if WrongNo = 0 then  //showmessage('DS2 Agrees Naive Solution')
  else                 showmessage('DS2 Validation Error : ' + WrongNo.ToString + ' false detections');

  ListOfIsActive2.Free;
  ListOfIsWrong.Free;



  {$ENDIF}



  {$IFDEF Validation}

  ListOfIsActive2 := GetNaiveSolution(GetTSPt3DFromTKey3D(key1),
                                      GetTSPt3DFromTKey3D(key2));
  ListOfIsWrong := TList<Boolean>.create;
  WrongNo       := 0;
  for PtNo := 0 to ListOfPoints.Count-1 do
  begin
    if ListOfIsActive2[PtNo] <> ListOfIsActive[ptNo] then
    begin
      ListOfIsWrong.Add(TRUE);
      Inc(WrongNo);
    end
    else  ListOfIsWrong.Add(FALSE);
  end;

//  _3DH.SetBeingDisplayed(k1,k2,ListOfIsActive,ListOfIsWrong);

  if WrongNo = 0 then  //showmessage('3DRangeTree Agrees Naive Solution')
  else                 showmessage('3DRangeTree Validation Error : ' + WrongNo.ToString + ' false detections');

  ListOfIsActive2.Free;
  ListOfIsWrong.Free;

  {$ELSE}

//   _3DH.SetBeingDisplayed(k1,k2,ListOfIsActive);

  {$ENDIF}

  // paint the box in _3D, that must be a new method overthere
  //
  // get naive solution
  ListOfIsActive.Free;

end;




end.
