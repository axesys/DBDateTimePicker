unit DBDateTimePicker;

interface

uses
  Winapi.Messages, System.SysUtils, System.Classes, Vcl.Controls, Vcl.ComCtrls,
  Data.DB, Vcl.DBCtrls;

type
  TDBDateTimePicker = class(TDateTimePicker)
  private
    { Private declarations }
    FDataLink: TFieldDataLink;
    FReadOnly: Boolean;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);published
    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
    function GetField: TField;
    procedure SetDateTimeJumpMinMax(const AValue: TDateTime);
    procedure SetReadOnly(const AValue: Boolean);
  protected
    { Protected declarations }
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure WndProc(var Message: TMessage); override;
    procedure CMEnter(var Message: TCMEnter); message CM_ENTER;
    procedure Change; override;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
  public
    { Public declarations }
    function DateIsNull: Boolean;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    { Published declarations }
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property ReadOnly : boolean read FReadOnly write SetReadOnly default False;
  end;

procedure Register;

implementation

uses
  System.Math;

const
  NullDate = 0;

constructor TDBDateTimePicker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle:=ControlStyle - [csReplicatable];  // El control no se permite en un DBCtrlGrid
  FReadOnly:= False;
  FDataLink:= TFieldDataLink.Create;
  FDataLink.Control:= Self;
  Self.DateTime:= NullDate;
  FDataLink.OnDataChange:= DataChange;
  FDataLink.OnUpdateData:= UpdateData;
end;

destructor TDBDateTimePicker.Destroy;
begin
  FDataLink.OnDataChange:= nil;
  FDataLink.OnUpdateData:= nil;
  FreeAndNil(FDataLink);
  inherited Destroy;
end;

procedure TDBDateTimePicker.SetReadOnly(const AValue: Boolean);
begin
  if FReadOnly <> AValue then
  begin
    FReadOnly:= AValue;
    Self.TabStop:= not AValue;
  end;
end;

function TDBDateTimePicker.GetDataSource: TDataSource;
begin
  Result:= FDataLink.DataSource;
end;

procedure TDBDateTimePicker.SetDataSource(const AValue: TDataSource);
begin
  if FDataLink.DataSource<>AValue then
  begin
    FDataLink.DataSource:= AValue;
    if Assigned(AValue) then AValue.FreeNotification(Self);
  end;
end;

function TDBDateTimePicker.GetDataField: string;
begin
  Result:= FDataLink.FieldName;
end;

procedure TDBDateTimePicker.SetDataField(const AValue: string);
begin
  FDataLink.FieldName:= AValue;
end;

procedure TDBDateTimePicker.SetDateTimeJumpMinMax(const AValue: TDateTime);
var
  TempMinDate: TDateTime;
  TempMaxDate: TDateTime;
begin
  TempMinDate:= Trunc(Self.MinDate);
  TempMaxDate:= Self.MaxDate;
  Self.MinDate:= NullDate;
  Self.MaxDate:= StrToDate('31/12/9999');
  try
    Self.DateTime:= AValue;
  finally
    Self.MinDate:= TempMinDate;
    Self.MaxDate:= TempMaxDate;
  end;
end;

function TDBDateTimePicker.GetField: TField;
begin
  Result:= FDataLink.Field;
end;

procedure TDBDateTimePicker.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and Assigned(FDataLink) and
    (AComponent = Self.DataSource) then
    Self.DataSource:= nil;
end;

procedure TDBDateTimePicker.DataChange(Sender: TObject);
begin
  if Assigned(FDataLink.Field) and not FDataLink.Field.IsNull then
    SetDateTimeJumpMinMax(FDataLink.Field.AsDateTime)
  else
    Self.DateTime:= NullDate;
end;

procedure TDBDateTimePicker.CMEnter(var Message: TCMEnter);
begin
  inherited;
  FDataLink.CanModify;
end;

procedure TDBDateTimePicker.Change;
begin
  if FDataLink.Edit then
  begin
    FDataLink.Modified;
    inherited Change;
  end
  else
    FDataLink.Reset
end;

function TDBDateTimePicker.DateIsNull: Boolean;
begin
  Result:= Self.DateTime = NullDate;
end;

procedure TDBDateTimePicker.UpdateData(Sender: TObject);
begin
  if Assigned(FDataLink.Field) then
    if DateIsNull then
      FDataLink.Field.Clear
    else
      FDataLink.Field.AsDateTime:= Self.DateTime;
end;

procedure TDBDateTimePicker.CMExit(var Message: TCMExit);
begin
  try
    FDataLink.UpdateRecord;
  except
    SetFocus;
    raise;
  end;
  inherited;
end;

procedure TDBDateTimePicker.WndProc(var Message: TMessage);
begin
  if not (csDesigning in ComponentState) then
    if FReadOnly OR (not FReadOnly and Assigned(FDatalink) and not FDataLink.Edit) then
      if ((Message.Msg >= WM_MOUSEFIRST) and (Message.Msg <= WM_MOUSELAST))
        or (Message.Msg = WM_KEYDOWN) or (Message.Msg = WM_KEYUP) then
        Exit;
  inherited WndProc(Message);
end;

procedure Register;
begin
  RegisterComponents('Data Controls', [TDBDateTimePicker]);
end;

end.
