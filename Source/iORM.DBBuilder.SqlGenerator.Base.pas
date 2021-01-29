unit iORM.DBBuilder.SqlGenerator.Base;

interface

uses
  System.Classes, iORM.DBBuilder.Interfaces, iORM.DB.Interfaces, iORM.Attributes, System.Rtti;

const
  SCRIPT_SEPARATOR_LENGTH = 79; // Per allineamento con i warnings
  SCRIPT_INDENTATION_WIDTH = 4;
  MSG_METHOD_NOT_IMPLEMENTED = 'Method not implemented by this class.';

type

  TioDBBuilderSqlGenBase = class(TInterfacedObject)
  private
    FFSchema: IioDBBuilderSchema;
    FIndentationLevel: Byte;
  protected
    function FSchema: IioDBBuilderSchema;
    function TValueToSql(const AValue: TValue): string;
    function ExtractFieldDefaultValue(const AField: IioDBBuilderSchemaField): string;

    function NewQuery(AConnectionName: String = ''): IioQuery;
    function OpenQuery(AConnectionName: String; const ASQL: String): IioQuery; overload;
    function OpenQuery(const ASQL: String): IioQuery; overload;
    procedure ExecuteQuery(AConnectionName: String; const ASQL: String); overload;
    procedure ExecuteQuery(const ASQL: String); overload;

    procedure DecIndentationLevel;
    procedure IncIndentationLevel;
    function GetIndentation: String;

    procedure ScriptAdd(const AText: String); virtual;
    procedure ScriptAddComment(const AText: String); virtual;
    procedure ScriptAddEmpty; virtual;
    procedure ScriptAddSeparator; virtual;
    procedure ScriptAddTitle(const AText: String); virtual;
    procedure ScriptAddWarning(const AText: String); virtual;
    procedure ScriptAddAllWarnings; virtual;

    procedure AddWarning(const AText: String); virtual;

    function IsFieldTypeChanged(const AOldFieldType, ANewFieldType: String; const AField: IioDBBuilderSchemaField;
      const ATable: IioDBBuilderSchemaTable; const AInvalidTypeConversions: string): Boolean; virtual;
    function IsFieldLengthChanged(const AOldFieldLength, ANewFieldLength: Smallint; const AField: IioDBBuilderSchemaField;
      const ATable: IioDBBuilderSchemaTable): Boolean; virtual;
    function IsFieldPrecisionChanged(const AOldFieldPrecision, ANewFieldPrecision: Smallint; const AField: IioDBBuilderSchemaField;
      const ATable: IioDBBuilderSchemaTable): Boolean; virtual;
    function IsFieldDecimalsChanged(const AOldFieldDecimals, ANewFieldDecimals: Smallint; const AField: IioDBBuilderSchemaField;
      const ATable: IioDBBuilderSchemaTable): Boolean; virtual;
    function IsFieldNotNullChanged(const AOldFieldNotNull, ANewFieldNotNull: Boolean; const AField: IioDBBuilderSchemaField;
      const ATable: IioDBBuilderSchemaTable; const AIsPermitted: Boolean): Boolean; virtual;
    function IsBlobSubTypeChanged(const AOldBlobSubType, ANewBlobSubType: String; const AField: IioDBBuilderSchemaField;
      const ATable: IioDBBuilderSchemaTable; const AIsPermitted: Boolean): Boolean; virtual;

    procedure WarningTypeAffinity(const AOldFieldType, ANewFieldType: String; const AField: IioDBBuilderSchemaField;
      const ATable: IioDBBuilderSchemaTable; const AInvalidTypeConversions: string); virtual;
    procedure WarningNotNullCannotBeChanged(const AOldFieldNotNull: Boolean; const AField: IioDBBuilderSchemaField;
      const ATable: IioDBBuilderSchemaTable); virtual;
    procedure WarningNullBecomesNotNull(const AOldFieldNotNull: Boolean; const AField: IioDBBuilderSchemaField;
      const ATable: IioDBBuilderSchemaTable); virtual;
    procedure WarningNewValueLessThanTheOldOne(const AValueName: String; const AOldValue, ANewValue: Integer;
      const AField: IioDBBuilderSchemaField; const ATable: IioDBBuilderSchemaTable); virtual;
    procedure WarningValueChanged(const AValueName, AOldValue, ANewValue: String; const AField: IioDBBuilderSchemaField;
      const ATable: IioDBBuilderSchemaTable); virtual;

    function BuildIndexName(const ATable: IioDBBuilderSchemaTable; const AIndex: ioIndex): String; virtual;
    function BuildIndexUnique(const AIndex: ioIndex): String; virtual;
    function BuildIndexOrientation(const ATable: IioDBBuilderSchemaTable; const AIndex: ioIndex; const AIndexName: String)
      : String; virtual;
    function BuildIndexFieldList(const ATable: IioDBBuilderSchemaTable; const AIndex: ioIndex; const AIndexName: String;
      const AWithIndexOrientation: Boolean): String; virtual;
    function TranslateFKAction(const AForeignKey: IioDBBuilderSchemaFK; const AFKAction: TioFKAction): String;
  public
    constructor Create(const ASchema: IioDBBuilderSchema); virtual;
    procedure ScriptBegin; virtual;
    procedure ScriptEnd; virtual;
  end;

implementation

uses
  iORM.DB.Factory, iORM.DB.ConnectionContainer, System.SysUtils, System.StrUtils, iORM.CommonTypes, iORM.SqlTranslator, iORM.Exceptions;

{ TioDBBuilderSqlGenBase }

procedure TioDBBuilderSqlGenBase.ScriptAddComment(const AText: String);
begin
  FSchema.Script.Add('-- ' + AText);
end;

procedure TioDBBuilderSqlGenBase.ScriptAddEmpty;
begin
  FSchema.Script.Add('');
end;

procedure TioDBBuilderSqlGenBase.ScriptAddSeparator;
begin
  FSchema.Script.Add(StringOfChar('-', SCRIPT_SEPARATOR_LENGTH));
end;

procedure TioDBBuilderSqlGenBase.ScriptAddTitle(const AText: String);
begin
  ScriptAddEmpty;
  ScriptAddSeparator;
  ScriptAddComment(AText);
  ScriptAddSeparator;
  ScriptAddEmpty;
end;

procedure TioDBBuilderSqlGenBase.ScriptAddWarning(const AText: String);
begin
  FSchema.Script.Add('-- WARNING:  ' + AText);
end;

function TioDBBuilderSqlGenBase.TranslateFKAction(const AForeignKey: IioDBBuilderSchemaFK; const AFKAction: TioFKAction): String;
begin
  case AFKAction of
    fkNoAction:
      Exit('NO ACTION');
    fkSetNull:
      Exit('SET NULL');
    fkSetDefault:
      Exit('SET DEFAULT');
    fkCascade:
      Exit('CASCADE');
  else
    AddWarning(Format('Table ''%s'' constraint ''%s'' --> Invalid foreign key action (field %s reference to %s.%s)',
      [AForeignKey.DependentTableName, AForeignKey.Name, AForeignKey.DependentFieldName, AForeignKey.ReferenceTableName,
      AForeignKey.ReferenceFieldName]));
  end;
end;

function TioDBBuilderSqlGenBase.TValueToSql(const AValue: TValue): string;
begin
  Result := TioDBFactory.SqlDataConverter(FSchema.ConnectionDefName).TValueToSql(AValue);
end;

procedure TioDBBuilderSqlGenBase.AddWarning(const AText: String);
begin
  FSchema.Warnings.Add(GetIndentation + AText);
end;

function TioDBBuilderSqlGenBase.BuildIndexFieldList(const ATable: IioDBBuilderSchemaTable; const AIndex: ioIndex;
  const AIndexName: String; const AWithIndexOrientation: Boolean): String;
var
  LFieldList: TStrings;
  LField: String;
  LComma: String;
  LIndexOrientation: String;
begin
  if AWithIndexOrientation then
    LIndexOrientation := BuildIndexOrientation(ATable, AIndex, AIndexName)
  else
    LIndexOrientation := '';
  LFieldList := TStringList.Create;
  try
    LComma := '';
    LFieldList.Delimiter := ',';
    LFieldList.DelimitedText := AIndex.CommaSepFieldList;
    for LField in LFieldList do
    begin
      Result := Format('%s%s %s %s', [Result, LComma, LField, LIndexOrientation]).Trim;
      LComma := ', ';
    end;
  finally
    LFieldList.Free;
  end;
end;

function TioDBBuilderSqlGenBase.BuildIndexName(const ATable: IioDBBuilderSchemaTable; const AIndex: ioIndex): String;
var
  LFieldList: TStrings;
  LField: String;
begin
  // If the index name is already specified then use it and exit
  if not AIndex.IndexName.IsEmpty then
    Exit(TioSqlTranslator.Translate(AIndex.IndexName, ATable.GetContextTable.GetClassName, False));
  // Build the indexname
  Result := 'IDX_' + ATable.TableName;
  // Field list
  LFieldList := TStringList.Create;
  try
    LFieldList.Delimiter := ',';
    LFieldList.DelimitedText := AIndex.CommaSepFieldList;
    for LField in LFieldList do
      Result := Result + '_' + LField;
  finally
    LFieldList.Free;
  end;
  // Index orientation
  case AIndex.IndexOrientation of
    ioAscending:
      Result := Result + '_A';
    ioDescending:
      Result := Result + '_D';
  end;
  // Unique
  if AIndex.Unique then
    Result := Result + '_U';
  // Translate
  Result := TioSqlTranslator.Translate(Result, ATable.GetContextTable.GetClassName, False);
end;

function TioDBBuilderSqlGenBase.BuildIndexOrientation(const ATable: IioDBBuilderSchemaTable; const AIndex: ioIndex;
  const AIndexName: String): String;
begin
  case AIndex.IndexOrientation of
    ioAscending:
      Exit('ASC');
    ioDescending:
      Exit('DESC');
  else
    AddWarning(Format('Table ''%s'' index ''%s'' --> Invalid index orientation', [ATable.TableName, AIndexName]));
  end;
end;

function TioDBBuilderSqlGenBase.BuildIndexUnique(const AIndex: ioIndex): String;
begin
  if AIndex.Unique then
    Exit('UNIQUE')
  else
    Exit('');
end;

procedure TioDBBuilderSqlGenBase.WarningNewValueLessThanTheOldOne(const AValueName: String; const AOldValue, ANewValue: Integer;
  const AField: IioDBBuilderSchemaField; const ATable: IioDBBuilderSchemaTable);
begin
  if ANewValue < AOldValue then
    AddWarning(Format('Table ''%s'' field ''%s'' --> The new %s cannot be less than the old one (old = %d, new = %d)',
      [ATable.TableName, AField.FieldName, AValueName, AOldValue, ANewValue]));
end;

procedure TioDBBuilderSqlGenBase.WarningNotNullCannotBeChanged(const AOldFieldNotNull: Boolean; const AField: IioDBBuilderSchemaField;
  const ATable: IioDBBuilderSchemaTable);
begin
  if AField.FieldNotNull <> AOldFieldNotNull then
    AddWarning(Format('Table ''%s'' field ''%s'' --> The not null setting cannot be changed automatically',
      [ATable.TableName, AField.FieldName]));
end;

procedure TioDBBuilderSqlGenBase.WarningNullBecomesNotNull(const AOldFieldNotNull: Boolean; const AField: IioDBBuilderSchemaField;
  const ATable: IioDBBuilderSchemaTable);
begin
  if AField.FieldNotNull and (not AOldFieldNotNull) and (not AField.FieldDefaultExists) then
    AddWarning
      (Format('Table ''%s'' field ''%s'' --> The not null setting is changed from false to true and a default value has not been specified',
      [ATable.TableName, AField.FieldName]));
end;

procedure TioDBBuilderSqlGenBase.WarningTypeAffinity(const AOldFieldType, ANewFieldType: String; const AField: IioDBBuilderSchemaField;
  const ATable: IioDBBuilderSchemaTable; const AInvalidTypeConversions: string);
var
  LRequiredConversion: String;
begin
  LRequiredConversion := Format('[%s->%s]', [AOldFieldType, ANewFieldType]);
  if ContainsText(AInvalidTypeConversions, LRequiredConversion) then
    AddWarning(Format('Table ''%s'' field ''%s'' --> Invalid conversion from ''%s'' to ''%s''', [ATable.TableName, AField.FieldName,
      AOldFieldType, ANewFieldType]));
end;

procedure TioDBBuilderSqlGenBase.WarningValueChanged(const AValueName, AOldValue, ANewValue: String;
  const AField: IioDBBuilderSchemaField; const ATable: IioDBBuilderSchemaTable);
begin
  if ANewValue <> AOldValue then
    AddWarning(Format('Table ''%s'' field ''%s'' --> Changing the %s is not allowed (old = ''%s'', new = ''%s'')',
      [ATable.TableName, AField.FieldName, AValueName, AOldValue, ANewValue]));
end;

constructor TioDBBuilderSqlGenBase.Create(const ASchema: IioDBBuilderSchema);
begin
  FFSchema := ASchema;
  FIndentationLevel := 0;
end;

function TioDBBuilderSqlGenBase.NewQuery(AConnectionName: String = ''): IioQuery;
begin
  AConnectionName := IfThen(AConnectionName.IsEmpty, FSchema.ConnectionDefName, AConnectionName);
  Result := TioDBFactory.Query(AConnectionName);
end;

function TioDBBuilderSqlGenBase.OpenQuery(const ASQL: String): IioQuery;
begin
  Result := OpenQuery(string.empty, ASQL);
end;

function TioDBBuilderSqlGenBase.OpenQuery(AConnectionName: String; const ASQL: String): IioQuery;
begin
  Result := NewQuery(AConnectionName);
  Result.SQL.Text := ASQL;
  Result.Open;
end;

procedure TioDBBuilderSqlGenBase.ScriptAdd(const AText: String);
begin
  FSchema.Script.Add(GetIndentation + AText);
end;

procedure TioDBBuilderSqlGenBase.ScriptAddAllWarnings;
var
  LWarning: String;
begin
  ScriptAddTitle('W A R N I N G S !!!        W A R N I N G S !!!        W A R N I N G S !!! --');
  for LWarning in FSchema.Warnings do
    ScriptAddWarning(LWarning);
end;

procedure TioDBBuilderSqlGenBase.DecIndentationLevel;
begin
  Dec(FIndentationLevel);
end;

procedure TioDBBuilderSqlGenBase.ExecuteQuery(AConnectionName: String; const ASQL: String);
var
  LQuery: IioQuery;
begin
  LQuery := NewQuery(AConnectionName);
  LQuery.SQL.Text := ASQL;
  LQuery.ExecSQL;
end;

procedure TioDBBuilderSqlGenBase.ExecuteQuery(const ASQL: String);
begin
  ExecuteQuery(string.empty, ASQL);
end;

function TioDBBuilderSqlGenBase.ExtractFieldDefaultValue(const AField: IioDBBuilderSchemaField): string;
var
  LFieldDefaultValue: TValue;
begin
  LFieldDefaultValue := AField.FieldDefault;
  if LFieldDefaultValue.IsEmpty then
    Result := ''
  else
    Result := 'DEFAULT ' + TioDBFactory.SqlDataConverter(FSchema.ConnectionDefName).TValueToSql(LFieldDefaultValue);
end;

procedure TioDBBuilderSqlGenBase.ScriptEnd;
begin
  ScriptAddSeparator;
  ScriptAddComment('End of the script generated by iORM');
  ScriptAddSeparator;
end;

function TioDBBuilderSqlGenBase.FSchema: IioDBBuilderSchema;
begin
  Result := FFSchema;
end;

function TioDBBuilderSqlGenBase.GetIndentation: String;
begin
  Result := StringOfChar(' ', FIndentationLevel * SCRIPT_INDENTATION_WIDTH);
end;

procedure TioDBBuilderSqlGenBase.IncIndentationLevel;
begin
  Inc(FIndentationLevel);
end;

procedure TioDBBuilderSqlGenBase.ScriptBegin;
begin
  ScriptAddSeparator;
  ScriptAddComment('Start of the script generated by iORM');
  ScriptAddSeparator;
  ScriptAddComment('Date - time....: ' + FormatDateTime('d mmm yyyy - hh:nn:ss', Now));
  ScriptAddComment('Connection name: ' + FSchema.ConnectionDefName);
  ScriptAddComment('Database file..: ' + FSchema.DatabaseFileName);
  ScriptAddComment('DBMS...........: ' + TioConnectionManager.GetConnectionDefByName(FSchema.ConnectionDefName).Params.DriverID);
  ScriptAddSeparator;
  if FSchema.WarningExists then
    ScriptAddAllWarnings;
end;

function TioDBBuilderSqlGenBase.IsBlobSubTypeChanged(const AOldBlobSubType, ANewBlobSubType: String;
  const AField: IioDBBuilderSchemaField; const ATable: IioDBBuilderSchemaTable; const AIsPermitted: Boolean): Boolean;
begin
  Result := AOldBlobSubType <> ANewBlobSubType;
  if Result then
  begin
    AField.AddAltered(alFieldType);
    if not AIsPermitted then
      WarningValueChanged('blob sub-type', AOldBlobSubType, ANewBlobSubType, AField, ATable);
  end;
end;

function TioDBBuilderSqlGenBase.IsFieldDecimalsChanged(const AOldFieldDecimals, ANewFieldDecimals: Smallint;
  const AField: IioDBBuilderSchemaField; const ATable: IioDBBuilderSchemaTable): Boolean;
begin
  Result := AOldFieldDecimals <> ANewFieldDecimals;
  if Result then
  begin
    AField.AddAltered(alFieldType);
    WarningNewValueLessThanTheOldOne('field decimals', AOldFieldDecimals, ANewFieldDecimals, AField, ATable);
  end;
end;

function TioDBBuilderSqlGenBase.IsFieldLengthChanged(const AOldFieldLength, ANewFieldLength: Smallint;
  const AField: IioDBBuilderSchemaField; const ATable: IioDBBuilderSchemaTable): Boolean;
begin
  Result := ANewFieldLength <> AOldFieldLength;
  if Result then
  begin
    AField.AddAltered(alFieldType);
    WarningNewValueLessThanTheOldOne('field length', AOldFieldLength, ANewFieldLength, AField, ATable);
  end;
end;

function TioDBBuilderSqlGenBase.IsFieldNotNullChanged(const AOldFieldNotNull, ANewFieldNotNull: Boolean;
  const AField: IioDBBuilderSchemaField; const ATable: IioDBBuilderSchemaTable; const AIsPermitted: Boolean): Boolean;
begin
  Result := AOldFieldNotNull <> ANewFieldNotNull;
  if Result then
  begin
    AField.AddAltered(alFieldNotNull);
    if AIsPermitted then
      WarningNullBecomesNotNull(AOldFieldNotNull, AField, ATable)
    else
      WarningNotNullCannotBeChanged(AOldFieldNotNull, AField, ATable);
  end;
end;

function TioDBBuilderSqlGenBase.IsFieldPrecisionChanged(const AOldFieldPrecision, ANewFieldPrecision: Smallint;
  const AField: IioDBBuilderSchemaField; const ATable: IioDBBuilderSchemaTable): Boolean;
begin
  Result := AOldFieldPrecision <> ANewFieldPrecision;
  if Result then
  begin
    AField.AddAltered(alFieldType);
    WarningNewValueLessThanTheOldOne('field precision', AOldFieldPrecision, ANewFieldPrecision, AField, ATable);
  end;
end;

function TioDBBuilderSqlGenBase.IsFieldTypeChanged(const AOldFieldType, ANewFieldType: String; const AField: IioDBBuilderSchemaField;
  const ATable: IioDBBuilderSchemaTable; const AInvalidTypeConversions: string): Boolean;
begin
  Result := not SameText(AOldFieldType, ANewFieldType);
  if Result then
  begin
    AField.AddAltered(alFieldType);
    WarningTypeAffinity(AOldFieldType, ANewFieldType, AField, ATable, AInvalidTypeConversions);
  end;
end;

end.
