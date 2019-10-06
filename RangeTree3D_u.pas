unit RangeTree3D_u;

{ Delphi implementation of static 3D Range tree -> T3DRangeTree.
  Based on the ideas given in the course 6.851 MIT OpenWare

  https://ocw.mit.edu/courses/electrical-engineering-and-computer-science/6-851-advanced-data-structures-spring-2012/lecture-videos/session-4-geometric-structures-ii/

  The DS is Build with a List of T3DKeys, points (x,y,z) in R^3,
  the keys are stored in multiple Data structures for a fast query :

  get all (x,y,z) in the List inside the range [a1,b1]x[a2,b2]x[a3,b3]

  The outPut is a Dictionary with all keys inside the box. Do not free this output Dictionary
  since it should be freed in T3DRangeTree.Free;  See how to use it in RAngeTree3DForm_u.pas

  Some other DS are implemented here that can solve other 3D range queries with some of the
  bounds being infinity (see TDS2 and TDS3). }

interface

uses Math, System.SysUtils,DIalogs, System.Variants, System.Classes, System.Generics.collections,
     Generics.Defaults, QuarterRangeSearch_u;

                           //   Queries -> report members in 3D ranges  //
                           //      X           Y            Z           //
type TDS2Mode = (XmYmZ,    //   [a1,b1]   x [-Inf,b2] x [-Inf,b3]       //
                 XmYpZ,    //   [a1,b1]   x [-Inf,b2] x [a3,Inf]        //
                 XpYmZ,    //   [a1,b1]   x [a2,Inf]  x [-Inf,b3]       //
                 XpYpZ);   //   [a1,b1]   x [a2,Inf]  x [a3,Inf]        //
//                 YmZmX,    //   [-Inf,b1] x [a2,b2]   x [-Inf,b3]       //
//                 YmZpX,    //   [a1,Inf]  x [a2,b2]   x [-Inf,b3]       //
//                 YpZmX,    //   [-Inf,b1] x [a2,b2]   x [a3,Inf]        //
//                 YpZpX,    //   [a1,Inf]  x [a2,b2]   x [a3,Inf]        //
//                 ZmXmY,    //   [-Inf,b1] x [-Inf,b2] x [a3,b3]         //
//                 ZmXpY,    //   [-Inf,b1] x [a2,Inf]  x [a3,b3]         //
//                 ZpXmY,    //   [a1,Inf]  x [-Inf,b2] x [a3,b3]         //
//                 ZpXpY);   //   [a1,Inf]  x [a2,Inf]  x [a3,b3]         //

type TDS2Node = class

    parent, left, right : TDS2Node;
    isLeftChild         : Boolean;
    key                 : TKey3D;
    compare             : TComparison<TKey3D>;
    QRSTree             : TQuarterRangeSearch;

    public
    constructor create(const compare_ : TComparison<TKey3D>);
    procedure free;
    procedure initNode(const key_: TKey3D; const parent_: TDS2Node);
    procedure buildQRSTree(const InitIdx, LastIdx : Integer; const sortedList : TList<TKey3D>; const quadrant_ : TQuadrant);

    protected


    private
    size, size_left, size_right : Integer;
    isLeaf                      : Boolean;
    quadrant                    : TQuadrant;
    procedure DeleteSubTreeAndGetSortedObjects(var List : TList<TDS2Node>);
    procedure SplitNode(const idxStart, idxEnd : Integer; const SortedList : TList<TKey3D>);

end;


type TDS2 = class
 { 1D Range Tree on x + any quadrant Range Search Tree on YZ, See TDS2Mode defined }

 root                   : TDS2Node;
 OutputDictOfKeys       : TDictionary<TKey3D,Boolean>;

 private
 Fmode               : TDS2mode;
 Quadrant            : TQuadrant;
 FCount              : Integer;    // number of objects in the tree
 compare             : TComparison<TKey3D>;
 WorkingListOfKeys   : TList<TKey3D>;
 function getBifurcationNode(const k1,k2 : TKey3D) : TDS2Node;
 procedure GetWorkingListOfKeys(const idxStart, idxEnd : Integer; const ListOfKeys : TList<TKey3D>);
 procedure GetQuadrant;

 public
 constructor create;
 procedure BuildTree(const idxStart, idxEnd : Integer; const ListOfKeys : TList<TKey3D>; const Amode : TDS2Mode);
 procedure free;
 procedure Clear;
 property Count : integer read FCount;
 property mode : TDS2mode read Fmode;
 function getDictOfMembersInRange(const key1, key2 : TKey3D) : TDictionary<TKey3D,Boolean>;

end;
                                 //   For Solving 3D queries (x,y,z) in :   //
type TDS3Mode = (LeftWardInf,    //   [a1,b1]   x [b1,b2] x [-Inf,b3]       //
                 RightWardInf);  //   [a1,b1]   x [b1,b2] x [a3,Inf]        //

type TDS3Node = class

  parent, left, right : TDS3Node;
  isLeftChild         : Boolean;
  key                 : TKey3D;
  compareY            : TComparison<TKey3D>;
  DS2Left, DS2Right   : TDS2;

  constructor create(const compareY_ : TComparison<TKey3D>);
  procedure free;
  procedure initNode(const key_: TKey3D; const parent_: TDS3Node);

  private
  isLeaf                      : Boolean;
  procedure SplitNode(const idxStart, idxEnd : Integer; const SortedList : TList<TKey3D>; const mode : TDS3Mode);
  procedure SplitNodeLeftWardInf(const idxStart, idxEnd : Integer; const SortedList : TList<TKey3D>); overload;
  procedure SplitNodeRightWardInf(const idxStart, idxEnd : Integer; const SortedList : TList<TKey3D>); overload;
  procedure DeleteSubTreeAndGetSortedObjects(var List : TList<TDS3Node>);

end;

type TDS3 = class

 root                   : TDS3Node;
 OutputDictOfKeys       : TDictionary<TKey3D,Boolean>;
 compareY               : TComparison<TKey3D>;

 private
 mode                : TDS3Mode;
 FCount              : Integer;
 WorkingListOfKeys   : TList<TKey3D>;
 procedure GetWorkingListOfKeys(const idxStart, idxEnd : Integer; const ListOfKeys : TList<TKey3D>);

 public
 constructor create;
 procedure BuildTree(const idxStart, idxEnd : Integer; const ListOfKeys : TList<TKey3D>; const mode_ : TDS3Mode);
 procedure free;
 procedure Clear;
 property Count : integer read FCount;
 function getDictOfMembersInRange(const key1, key2 : TKey3D) : TDictionary<TKey3D,Boolean>;

end;


type T3DRangeTreeNode = class

  parent, left, right : T3DRangeTreeNode;
  isLeftChild         : Boolean;
  key                 : TKey3D;
  compareZ            : TComparison<TKey3D>;
  DS3Left, DS3Right   : TDS3;

  constructor create(const compareZ_ : TComparison<TKey3D>);
  procedure free;
  procedure initNode(const key_: TKey3D; const parent_: T3DRangeTreeNode);
  private
  isLeaf                      : Boolean;
  procedure SplitNode(const idxStart, idxEnd : Integer; const SortedList : TList<TKey3D>);
  procedure DeleteSubTreeAndGetSortedObjects(var List : TList<T3DRangeTreeNode>);

end;


type T3DRangeTree = class

 OutputDictOfKeys       : TDictionary<TKey3D,Boolean>;

 private
 FCount            : Integer;
 WorkingListOfKeys : TList<TKey3D>;
 root              : T3DRangeTreeNode;
 compareZ          : TComparison<TKey3D>;

 procedure GetWorkingListOfKeys(const idxStart, idxEnd : Integer; const ListOfKeys : TList<TKey3D>);

 public
 constructor create;
 procedure BuildTree(const idxStart, idxEnd : Integer; const ListOfKeys : TList<TKey3D>);
 procedure free;
 procedure Clear;
 property Count : integer read FCount;
 function getDictOfMembersInRange(const key1, key2 : TKey3D) : TDictionary<TKey3D,Boolean>;

end;



implementation

// begin define methods of TDS2Node
constructor TDS2Node.create(const compare_ : TComparison<TKey3D>);
begin
  inherited create;
  compare := compare_;
  QRSTree := TQuarterRangeSearch.create;
 end;

procedure TDS2Node.free;
begin
  QRSTree.free;
  inherited free;
end;

procedure TDS2Node.initNode(const key_: TKey3D; const parent_: TDS2Node);
begin
  key        := key_;
  right      := nil;
  left       := nil;
  parent     := parent_;
  isLeaf     := TRUE;
  size       := 1;
  size_left  := 0;
  size_right := 0;
end;

procedure TDS2Node.buildQRSTree(const InitIdx, LastIdx : Integer; const sortedList : TList<TKey3D>; const quadrant_ : TQuadrant);
begin
  quadrant := quadrant_;
  QRSTree.Build(InitIdx, LastIdx, sortedList, quadrant_);
end;

procedure TDS2Node.DeleteSubTreeAndGetSortedObjects(var List : TList<TDS2Node>);
begin
  if isLeaf then
    List.Add(Self)
  else
  begin
    Self.left.DeleteSubTreeAndGetSortedObjects(List);
    Self.right.DeleteSubTreeAndGetSortedObjects(List);
    Self.Free;
  end;
end;

procedure TDS2Node.SplitNode(const idxStart, idxEnd : Integer; const SortedList : TList<TKey3D>);
var idxEndLeft, n, no2 : Integer;
    leafKey            : TKey3D;
begin
  n := idxEnd-idxStart;
  if n = 0 then
  begin
    leafkey    := SortedList[idxStart];
    key        := leafkey;
    size       := 1;
    size_left  := 0;
    size_right := 0;
    isLeaf     := TRUE;
  end
  else
  begin
    no2 := Trunc(0.5*n);
    idxEndLeft := idxStart + no2;
    // revise CurrentNode
    key        := SortedList[idxEndLeft];
    size       := n+1;
    size_left  := idxEndLeft-idxStart+1;
    size_right := size-size_left;
    isLeaf     := FALSE;
    // Create New Left Node
    left             := TDS2Node.create(compare);
    left.BuildQRSTree(idxStart,idxEndLeft,SortedList,quadrant);
    left.parent      := self;
    left.isLeftChild := TRUE;
    left.SplitNode(idxStart,idxEndLeft,SortedList);
    // Create New Left Node
    right := TDS2Node.create(compare);
    right.BuildQRSTree(idxEndLeft+1,idxEnd,SortedList,quadrant);
    right.parent := self;
    right.isLeftChild := FALSE;
    right.SplitNode(idxEndLeft+1,idxEnd,SortedList);
  end;
end;
// end define methods of TDS2Node


// begin define methods of TDS2
constructor TDS2.create;
var compareXYZ : TComparison<TKey3D>;
begin
  inherited create;
  root                   := nil;
  OutputDictOfKeys       := TDictionary<TKey3D,Boolean>.create;
  WorkingListOfKeys      := TList<TKey3D>.create;

  compareXYZ :=
  function(const left, right: TKey3D): Integer
  begin
    RESULT := TComparer<Single>.Default.Compare(left.x,right.x);
    if RESULT = 0 then
    begin
      RESULT := TComparer<Single>.Default.Compare(left.y,right.y);
      if RESULT = 0 then
      begin
        RESULT := TComparer<Single>.Default.Compare(left.z,right.z);
        if RESULT =0 then
          RESULT := TComparer<Integer>.Default.Compare(left.entityNo,right.entityNo);
      end;
    end;
  end;
  compare := compareXYZ;
end;

procedure TDS2.Clear;
var ListOfNodes : TList<TDS2Node>;
    node        : TDS2Node;
    i           : Integer;
begin
  OutputDictOfKeys.Clear;
  WorkingListOfKeys.Clear;
  if Assigned(root) then
  begin
    ListOfNodes := TList<TDS2Node>.create;
    root.DeleteSubTreeAndGetSortedObjects(ListOfNodes);
    for i := 0 to ListOfNodes.Count-1 do
    begin
      node := ListOfNodes[i];
      node.free;
    end;
    root := nil;
    ListOfNodes.Free;
  end;
end;

procedure TDS2.free;
begin
  Clear;
  OutputDictOfKeys.free;
  WorkingListOfKeys.Free;
  inherited free;
end;

procedure TDS2.GetQuadrant;
begin
  case FMode of
    XmYmZ{, YmZmX, ZmXmY} : quadrant := Third;
    XmYpZ{, YmZpX, ZmXpY} : quadrant := Second;
    XpYmZ{, YpZmX, ZpXmY} : quadrant := Fourth;
    XpYpZ{, YpZpX, ZpXpY} : quadrant := First;
  end;
end;

procedure TDS2.GetWorkingListOfKeys(const idxStart, idxEnd : Integer; const ListOfKeys : TList<TKey3D>);
var i   : Integer;
    key : TKey3D;
begin
  for i := idxStart to idxEnd do
  begin
    key        := ListOfKeys[i];
    WorkingListOfKeys.Add(Key);   // untouched Inputkeys
  end;
end;

procedure TDS2.BuildTree(const idxStart, idxEnd : Integer; const ListOfKeys : TList<TKey3D>; const Amode : TDS2Mode);
var compareFun : IComparer<TKey3D>;
    key        : TKey3D;
    i          : Integer;
begin
  Clear;

  Fmode := AMode;
  GetWorkingListOfKeys(idxStart,idxEnd,ListOfKeys);
  GetQuadrant;

  compareFun := TComparer<TKey3D>.Construct(compare);
  WorkingListOfKeys.Sort(compareFun);

  // inspectSortedList
  for i := 0 to WorkingListOfKeys.Count-1 do
    key := WorkingListOfKeys[i];

  FCount := WorkingListOfKeys.Count;
  root   := TDS2Node.Create(compare);
  root.BuildQRSTree(0,FCount-1,WorkingListOfKeys,quadrant);
  root.splitNode(0,FCount-1,WorkingListOfKeys);
end;

function TDS2.getBifurcationNode(const k1,k2 : TKey3D) : TDS2Node;
{assumed k1<k2}
var node       : TDS2Node;
    int1, int2 : Integer;
begin
  // Find BifurcationNode
  node   := root;
  RESULT := nil;
  while Assigned(node) do
  begin
    int1 := node.compare(k1,node.key);
    if int1 <> 1 then
    begin
      int2 := node.compare(k2,node.key);

      if int2 = 1 then
      begin  RESULT := node;  Exit;  end
      else
        node := node.left;
    end
    else node := node.right;
  end;
end;

function TDS2.getDictOfMembersInRange(const key1, key2 : TKey3D) : TDictionary<TKey3D,Boolean>;
{ outputs a dictionary with the set K=(k_i) i=1,..,|K|. keys of the tree satisfying
   k1 < k < k2 : Note input is sorted to satisfy k1<k2 }
var node, BifurcationNode  : TDS2Node;
    int1, int2, i          : Integer;
    k1, k2, DomkeyYZCheck,
    k2ForYZCheck, tmpKey   : TKey3D;
    L                      : TList<TKey3D>;
begin
  // Saveguard k1 >= k2
  if root.compare(key1,key2) > 0 then
  begin  k1 := key2;  k2 := key1;  end
  else
  begin  k1 := key1;  k2 := key2;  end;

  // prepare keys for YZ RangeSearch On a Quadrant
  case quadrant of
    First  : DomkeyYZCheck := TKey3D.create(100000,-k1.y,-k1.z,High(Integer));
    Second : DomkeyYZCheck := TKey3D.create(100000,k2.y,-k1.z,High(Integer));
    Third  : DomkeyYZCheck := TKey3D.create(100000,k2.y,k2.z,High(Integer));
    Fourth : DomkeyYZCheck := TKey3D.create(100000,-k1.y,k2.z,High(Integer));
  end;

  OutputDictOfKeys.Clear;
  RESULT := OutputDictOfKeys;

  BifurcationNode := getBifurcationNode(k1,k2);

  if Assigned(BifurcationNode) then
  begin
    if BifurcationNode.isleaf then
    begin
      if BifurcationNode.QRSTree.isKey1DominatedByKey2(BifurcationNode.key,DomkeyYZCheck) then
        RESULT.Add(BifurcationNode.Key,TRUE);
    end
    else
    begin
      // Track k1 to a leaf count nodes at right subtree when move left
      node := bifurcationNode.left;
      while NOT node.isLeaf do
      begin
        int1 := node.compare(k1,node.key);

        if int1 = 1 then
          node := node.right
        else
        begin
          //CollectSubTreeLeafsToDictionary(node.right);
          L := node.right.QRSTree.getSortedListOfMembersDominatedBykey(DOmKeyYZCheck);
          for i := 0 to L.Count-1 do
          begin
            tmpKey := L[i];
            RESULT.Add(tmpKey,TRUE);
          end;


          node := node.left;
        end
      end;
      // node at the leaf
      int1 := node.compare(k1,node.key);
      if (int1 <> 1) AND node.QRSTree.isKey1DominatedByKey2(node.key,DomkeyYZCheck) then
        RESULT.Add(node.key,TRUE);
      // Track k2 to a leaf count nodes at left subtree when move right
      node := bifurcationNode.right;
      while NOT node.isLeaf do
      begin
        int2 := node.compare(k2,node.key);

        if int2 = 1 then
        begin
          // CollectSubTreeLeafsToDictionary(node.left);
          L := node.left.QRSTree.getSortedListOfMembersDominatedBykey(DOmKeyYZCheck);
          for i := 0 to L.Count-1 do
          begin
            tmpKey := L[i];
            RESULT.Add(tmpKey,TRUE);
          end;

          node   := node.right;
        end
        else
          node   := node.left
      end;
      // node at the leaf
      int2 := node.compare(k2,node.key);
      if (int2 <> -1) AND node.QRSTree.isKey1DominatedByKey2(node.key,DomkeyYZCheck) then
        RESULT.Add(node.Key,TRUE);
    end;
  end;
  // Free memory
  DomkeyYZCheck.Free;
end;
// end define methods of TDS2


// Begin define methods of TDS3Node
constructor TDS3Node.create(const compareY_ : TComparison<TKey3D>);
begin
  inherited create;
  compareY := compareY_;
  DS2Left  := TDS2.create;
  DS2Right := TDS2.create;
end;

procedure TDS3Node.free;
begin
  DS2Left.free;
  DS2Right.free;
  inherited free;
end;

procedure TDS3Node.initNode(const key_: TKey3D; const parent_: TDS3Node);
begin
  key        := key_;
  right      := nil;
  left       := nil;
  parent     := parent_;
  isLeaf     := TRUE;
end;

procedure TDS3Node.SplitNode(const idxStart, idxEnd : Integer; const SortedList : TList<TKey3D>; const mode : TDS3Mode);
begin
  case mode of
    LeftWardInf  : SplitNodeLeftWardInf(idxStart, idxEnd, SortedList);
    RightWardInf : SplitNodeRightWardInf(idxStart, idxEnd, SortedList);
  end;
end;

procedure TDS3Node.SplitNodeLeftWardInf(const idxStart, idxEnd : Integer; const SortedList : TList<TKey3D>);
var idxEndLeft, n, no2 : Integer;
    leafKey            : TKey3D;
begin
  n := idxEnd-idxStart;
  if n = 0 then
  begin
    leafkey    := SortedList[idxStart];
    key        := leafkey;
    isLeaf     := TRUE;
    // Leaves Have empty DS2 structures
  end
  else
  begin
    no2 := Trunc(0.5*n);
    idxEndLeft := idxStart + no2;
    // revise CurrentNode
    key        := SortedList[idxEndLeft];
    isLeaf     := FALSE;
    // Build CurrentNode DS2 structures
    DS2Left.BuildTree(idxStart,idxEndLeft,SortedList,XpYmZ);
    DS2Right.BuildTree(idxEndLeft+1,idxEnd,SortedList,XmYmZ);
    // Create New Left Node
    left             := TDS3Node.create(compareY);
    left.parent      := self;
    left.isLeftChild := TRUE;
    left.SplitNodeLeftWardInf(idxStart,idxEndLeft,SortedList);
    // Create New Left Node
    right := TDS3Node.create(compareY);
    right.parent := self;
    right.isLeftChild := FALSE;
    right.SplitNodeLeftWardInf(idxEndLeft+1,idxEnd,SortedList);
  end;
end;

procedure TDS3Node.SplitNodeRightWardInf(const idxStart, idxEnd : Integer; const SortedList : TList<TKey3D>);
var idxEndLeft, n, no2 : Integer;
    leafKey            : TKey3D;
begin
  n := idxEnd-idxStart;
  if n = 0 then
  begin
    leafkey    := SortedList[idxStart];
    key        := leafkey;
    isLeaf     := TRUE;
    // Leaves Have empty DS2 structures
  end
  else
  begin
    no2 := Trunc(0.5*n);
    idxEndLeft := idxStart + no2;
    // revise CurrentNode
    key        := SortedList[idxEndLeft];
    isLeaf     := FALSE;
    // Build CurrentNode DS2 structures
    DS2Left.BuildTree(idxStart,idxEndLeft,SortedList,XpYpZ);
    DS2Right.BuildTree(idxEndLeft+1,idxEnd,SortedList,XmYpZ);
    // Create New Left Node
    left             := TDS3Node.create(compareY);
    left.parent      := self;
    left.isLeftChild := TRUE;
    left.SplitNodeRightWardInf(idxStart,idxEndLeft,SortedList);
    // Create New Left Node
    right := TDS3Node.create(compareY);
    right.parent := self;
    right.isLeftChild := FALSE;
    right.SplitNodeRightWardInf(idxEndLeft+1,idxEnd,SortedList);
  end;
end;

procedure TDS3Node.DeleteSubTreeAndGetSortedObjects(var List : TList<TDS3Node>);
begin
  if isLeaf then
    List.Add(Self)
  else
  begin
    Self.left.DeleteSubTreeAndGetSortedObjects(List);
    Self.right.DeleteSubTreeAndGetSortedObjects(List);
    Self.Free;
  end;
end;
// End define methods of TDS3Node

// begin define methods of TDS3
constructor TDS3.create;
var compareYZX : TComparison<TKey3D>;
begin
  inherited create;
  root                   := nil;
  OutputDictOfKeys       := TDictionary<TKey3D,Boolean>.create;
  WorkingListOfKeys      := TList<TKey3D>.create;

  compareYZX :=
  function(const left, right: TKey3D): Integer
  begin
    RESULT := TComparer<Single>.Default.Compare(left.y,right.y);
    if RESULT = 0 then
    begin
      RESULT := TComparer<Single>.Default.Compare(left.z,right.z);
      if RESULT = 0 then
      begin
        RESULT := TComparer<Single>.Default.Compare(left.x,right.x);
        if RESULT =0 then
          RESULT := TComparer<Integer>.Default.Compare(left.entityNo,right.entityNo);
      end;
    end;
  end;
  compareY := compareYZX;
end;

procedure TDS3.Clear;
var ListOfNodes : TList<TDS3Node>;
    node        : TDS3Node;
    i           : Integer;
begin
  OutputDictOfKeys.Clear;
  WorkingListOfKeys.Clear;
  if Assigned(root) then
  begin
    ListOfNodes := TList<TDS3Node>.create;
    root.DeleteSubTreeAndGetSortedObjects(ListOfNodes);
    for i := 0 to ListOfNodes.Count-1 do
    begin
      node := ListOfNodes[i];
      node.free;
    end;
    root := nil;
    ListOfNodes.Free;
  end;
end;

procedure TDS3.free;
begin
  Clear;
  OutputDictOfKeys.free;
  WorkingListOfKeys.Free;
  inherited free;
end;

procedure TDS3.GetWorkingListOfKeys(const idxStart, idxEnd : Integer; const ListOfKeys : TList<TKey3D>);
var i                : Integer;
    key, workingKey  : TKey3D;
begin
  for i := idxStart to idxEnd do
  begin
    key := ListOfKeys[i];
    WorkingListOfKeys.Add(key); // Input key remains untouched
  end;
end;

procedure TDS3.BuildTree(const idxStart, idxEnd : Integer; const ListOfKeys : TList<TKey3D>; const mode_ : TDS3Mode);
var compareFun : IComparer<TKey3D>;
begin
  Clear;

  mode := mode_;
  GetWorkingListOfKeys(idxStart,idxEnd,ListOfKeys);

  compareFun := TComparer<TKey3D>.Construct(compareY);
  WorkingListOfKeys.Sort(compareFun);

  FCount := WorkingListOfKeys.Count;
  root   := TDS3Node.Create(compareY);
  root.splitNode(0,FCount-1,WorkingListOfKeys,mode);
end;

function TDS3.getDictOfMembersInRange(const key1, key2 : TKey3D) : TDictionary<TKey3D,Boolean>;
var k1, k2, key,
    InputKey    : TKey3D;
    node        : TDS3Node;
    DL, DR      : TDictionary<TKey3D,Boolean>;
begin
  // Saveguard k1 >= k2
  if compareY(key1,key2) > 0 then
  begin  k1 := key2;  k2 := key1;  end
  else
  begin  k1 := key1;  k2 := key2;  end;

  OutputDictOfKeys.Clear;
  RESULT := OutputDictOfKeys;
  // walk down the tree up to bifurcation
  node := root;

  while (NOT node.isLeaf) do
  begin
    if (compareY(node.key,k1) = -1) then  node := node.right
    else
    begin
      if (compareY(node.key,k2) = 1) then  node := node.left
      else // bifurcation
      begin
        // take points in  (k1.y,inf) x (-inf,k2.z)
        DL := node.DS2Left.getDictOfMembersInRange(k1,k2);
        for key in DL.Keys do
          RESULT.Add(Key,TRUE);
        // take points in  (-inf,k2.y) x (-inf,k2.z)
        DR := node.DS2Right.getDictOfMembersInRange(k1,k2);
        for key in DR.Keys do
          RESULT.Add(Key,TRUE);

        EXIT;

      end;
    end;
  end;
end;
// end define methods of TDS3

// begin define methods of T3DRangeTreeNode
constructor T3DRangeTreeNode.create(const compareZ_ : TComparison<TKey3D>);
begin
  inherited create;
  compareZ := compareZ_;
  DS3Left  := TDS3.create;
  DS3Right := TDS3.create;
end;

procedure T3DRangeTreeNode.free;
begin
  DS3Left.free;
  DS3Right.free;
  inherited free;
end;

procedure T3DRangeTreeNode.initNode(const key_: TKey3D; const parent_: T3DRangeTreeNode);
begin
  key        := key_;
  right      := nil;
  left       := nil;
  parent     := parent_;
  isLeaf     := TRUE;
end;

procedure T3DRangeTreeNode.SplitNode(const idxStart, idxEnd : Integer; const SortedList : TList<TKey3D>);
var idxEndLeft, n, no2 : Integer;
    leafKey            : TKey3D;
begin
  n := idxEnd-idxStart;
  if n = 0 then
  begin
    leafkey    := SortedList[idxStart];
    key        := leafkey;
    isLeaf     := TRUE;
    // Leaves Have empty DS3 structures
  end
  else
  begin
    no2 := Trunc(0.5*n);
    idxEndLeft := idxStart + no2;
    // revise CurrentNode
    key        := SortedList[idxEndLeft];
    isLeaf     := FALSE;
    // Build CurrentNode DS2 structures
    DS3Left.BuildTree(idxStart,idxEndLeft,SortedList,RightWardInf);
    DS3Right.BuildTree(idxEndLeft+1,idxEnd,SortedList,LeftWardInf);
    // Create New Left Node
    left              := T3DRangeTreeNode.create(compareZ);
    left.parent       := self;
    left.isLeftChild  := TRUE;
    left.SplitNode(idxStart,idxEndLeft,SortedList);
    // Create New Left Node
    right             := T3DRangeTreeNode.create(compareZ);
    right.parent      := self;
    right.isLeftChild := FALSE;
    right.SplitNode(idxEndLeft+1,idxEnd,SortedList);
  end;
end;

procedure T3DRangeTreeNode.DeleteSubTreeAndGetSortedObjects(var List : TList<T3DRangeTreeNode>);
begin
  if isLeaf then
    List.Add(Self)
  else
  begin
    Self.left.DeleteSubTreeAndGetSortedObjects(List);
    Self.right.DeleteSubTreeAndGetSortedObjects(List);
    Self.Free;
  end;
end;
// end define methods of T3DRangeTreeNode

// begin define methods of T3DRangeTree
constructor T3DRangeTree.create;
var compareZXY : TComparison<TKey3D>;
begin
  inherited create;
  root                   := nil;
  OutputDictOfKeys       := TDictionary<TKey3D,Boolean>.create;
  WorkingListOfKeys      := TList<TKey3D>.create;

  compareZXY :=
  function(const left, right: TKey3D): Integer
  begin
    RESULT := TComparer<Single>.Default.Compare(left.z,right.z);
    if RESULT = 0 then
    begin
      RESULT := TComparer<Single>.Default.Compare(left.x,right.x);
      if RESULT = 0 then
      begin
        RESULT := TComparer<Single>.Default.Compare(left.y,right.y);
        if RESULT =0 then
          RESULT := TComparer<Integer>.Default.Compare(left.entityNo,right.entityNo);
      end;
    end;
  end;
  compareZ := compareZXY;
end;

procedure T3DRangeTree.Clear;
var ListOfNodes : TList<T3DRangeTreeNode>;
    node        : T3DRangeTreeNode;
    i           : Integer;
begin
  OutputDictOfKeys.Clear;
  WorkingListOfKeys.Clear;
  if Assigned(root) then
  begin
    ListOfNodes := TList<T3DRangeTreeNode>.create;
    root.DeleteSubTreeAndGetSortedObjects(ListOfNodes);
    for i := 0 to ListOfNodes.Count-1 do
    begin
      node := ListOfNodes[i];
      node.free;
    end;
    root := nil;
    ListOfNodes.Free;
  end;
end;

procedure T3DRangeTree.free;
begin
  Clear;
  OutputDictOfKeys.free;
  WorkingListOfKeys.Free;
  inherited free;
end;

procedure T3DRangeTree.GetWorkingListOfKeys(const idxStart, idxEnd : Integer; const ListOfKeys : TList<TKey3D>);
var i    : Integer;
    key  : TKey3D;
begin
  for i := idxStart to idxEnd do
  begin
    key        := ListOfKeys[i];
    WorkingListOfKeys.Add(key);  // list to be sorted leaving input untouched
  end;
end;

procedure T3DRangeTree.BuildTree(const idxStart, idxEnd : Integer; const ListOfKeys : TList<TKey3D>);
var compareFun : IComparer<TKey3D>;
begin
  Clear;

  GetWorkingListOfKeys(idxStart,idxEnd,ListOfKeys);

  compareFun := TComparer<TKey3D>.Construct(compareZ);
  WorkingListOfKeys.Sort(compareFun);

  FCount := WorkingListOfKeys.Count;
  root   := T3DRangeTreeNode.Create(compareZ);
  root.splitNode(0,FCount-1,WorkingListOfKeys);
end;

function T3DRangeTree.getDictOfMembersInRange(const key1, key2 : TKey3D) : TDictionary<TKey3D,Boolean>;
{Outputs a DIctionary with all keys leaving in the Range given by key1, key2.
 key1, key2 are vertices of the the box so
 key1.x = a1     key1.y = a2    key1.z = a3
 key2.x = b1     key2.y = b2    key2.z = b3  }

var k1, k2, key : TKey3D;
    node        : T3DRangeTreeNode;
    DL, DR      : TDictionary<TKey3D,Boolean>;
begin
  // Saveguard k1 >= k2
  if compareZ(key1,key2) > 0 then
  begin  k1 := key2;  k2 := key1;  end
  else
  begin  k1 := key1;  k2 := key2;  end;

  OutputDictOfKeys.Clear;
  RESULT := OutputDictOfKeys;
  // walk down the tree up to bifurcation
  node := root;

  while (NOT node.isLeaf) do
  begin
    if (compareZ(node.key,k1) = -1) then  node := node.right
    else
    begin
      if (compareZ(node.key,k2) = 1) then  node := node.left
      else // bifurcation
      begin
        // take points in  (k1.y,inf) x (-inf,k2.z)
        DL := node.DS3Left.getDictOfMembersInRange(k1,k2);
        for key in DL.Keys do
         RESULT.Add(key,TRUE);
        // take points in  (-inf,k2.y) x (-inf,k2.z)
        DR := node.DS3Right.getDictOfMembersInRange(k1,k2);
        for key in DR.Keys do
         RESULT.Add(key,TRUE);

        EXIT;

      end;
    end;
  end;
end;
// end define methods of T3DRangeTree

end.
