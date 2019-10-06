object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 545
  ClientWidth = 531
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnMouseWheel = OnMouseWheel
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 24
    Top = 8
    Width = 163
    Height = 25
    Caption = 'Number of Points'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label3: TLabel
    Left = 296
    Top = 8
    Width = 85
    Height = 19
    Caption = 'Range X :  ['
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label4: TLabel
    Left = 442
    Top = 12
    Width = 6
    Height = 23
    Caption = ','
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label5: TLabel
    Left = 506
    Top = 8
    Width = 6
    Height = 19
    Caption = ']'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label6: TLabel
    Left = 296
    Top = 34
    Width = 86
    Height = 19
    Caption = 'Range Y :  ['
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label7: TLabel
    Left = 442
    Top = 38
    Width = 6
    Height = 23
    Caption = ','
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label8: TLabel
    Left = 506
    Top = 34
    Width = 6
    Height = 19
    Caption = ']'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label9: TLabel
    Left = 296
    Top = 60
    Width = 85
    Height = 19
    Caption = 'Range Z :  ['
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label10: TLabel
    Left = 442
    Top = 63
    Width = 6
    Height = 23
    Caption = ','
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object Label11: TLabel
    Left = 506
    Top = 59
    Width = 6
    Height = 19
    Caption = ']'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object GenerateRandomPointsButton: TButton
    Left = 24
    Top = 39
    Width = 121
    Height = 33
    Caption = 'Random Points'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnClick = GenerateRandomPointsButtonClick
  end
  object Edit1: TEdit
    Left = 206
    Top = 11
    Width = 64
    Height = 21
    TabOrder = 1
  end
  object Edit2: TEdit
    Left = 387
    Top = 8
    Width = 49
    Height = 21
    TabOrder = 2
  end
  object Edit3: TEdit
    Left = 451
    Top = 8
    Width = 49
    Height = 21
    TabOrder = 3
  end
  object Edit4: TEdit
    Left = 387
    Top = 34
    Width = 49
    Height = 21
    TabOrder = 4
  end
  object Edit5: TEdit
    Left = 451
    Top = 36
    Width = 49
    Height = 21
    TabOrder = 5
  end
  object Edit6: TEdit
    Left = 387
    Top = 61
    Width = 49
    Height = 21
    TabOrder = 6
  end
  object Edit7: TEdit
    Left = 451
    Top = 63
    Width = 49
    Height = 21
    TabOrder = 7
  end
  object GetPointsInRangeButton: TButton
    Left = 160
    Top = 38
    Width = 121
    Height = 25
    Caption = 'Get Points In Range'
    TabOrder = 8
    OnClick = GetPointsInRangeButtonClick
  end
  object ClearRangeButton: TButton
    Left = 184
    Top = 72
    Width = 75
    Height = 25
    Caption = 'Clear Range'
    TabOrder = 9
    OnClick = ClearRangeButtonClick
  end
  object Panel1: TPanel
    Left = 32
    Top = 103
    Width = 468
    Height = 434
    TabOrder = 10
    OnMouseEnter = Panel1MouseEnter
    OnMouseLeave = Panel1MouseLeave
  end
  object ActionList1: TActionList
    Left = 456
    Top = 111
    object Action1: TAction
      Caption = 'Action1'
      ShortCut = 49238
      OnExecute = Action1Execute
    end
  end
end
