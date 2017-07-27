unit DBDateTimePicker;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.ComCtrls, Data.DB, Vcl.DBCtrls;

type
  TDBDateTimePicker = class(TDateTimePicker)
  private
    { Private declarations }
    FDataLink: TFieldDataLink;
    function GetDataField: string;
    function GetDataSource: TDataSource;
    procedure SetDataField(const AValue: string);
    procedure SetDataSource(const AValue: TDataSource);published
    procedure DataChange(Sender: TObject);
    procedure UpdateData(Sender: TObject);
  protected
    { Protected declarations }
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure CMEnter(var Message: TCMEnter); message CM_ENTER;
    procedure Change; override;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    { Published declarations }
    property DataField: string read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
  end;

procedure Register;

implementation

const
  NullDate = 0;

constructor TDBDateTimePicker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDataLink := TFieldDataLink.Create;
  FDataLink.Control := Self;
  Self.DateTime := NullDate;
  FDataLink.OnDataChange := DataChange;
  FDataLink.OnUpdateData := UpdateData;
end;

destructor TDBDateTimePicker.Destroy;
begin
  FreeAndNil(FDataLink);
  inherited Destroy;
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

procedure TDBDateTimePicker.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and Assigned(FDataLink) and
    (AComponent = DataSource) then
    DataSource:= nil;
end;

procedure TDBDateTimePicker.DataChange(Sender: TObject);
begin
  if Assigned(FDataLink.Field) and not FDataLink.Field.IsNull then
    Self.DateTime:= FDataLink.Field.AsDateTime
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

procedure TDBDateTimePicker.UpdateData(Sender: TObject);
begin
  if Assigned(FDataLink.Field) then
    if Self.DateTime = NullDate then
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

procedure Register;
begin
  RegisterComponents('Data Controls', [TDBDateTimePicker]);
end;

end.
