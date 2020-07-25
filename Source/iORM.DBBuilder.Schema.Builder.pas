unit iORM.DBBuilder.Schema.Builder;

interface

uses
  iORM.DBBuilder.Interfaces, iORM.COntext.Map.Interfaces;

type

  TioDBBuilderSchemaBuilder = class
  private
    class procedure BuildIndexList(const ASchemaTable: IioDBBuilderSchemaTable; const AMap: IioMap);
    class procedure BuildSchemaFK(const ASchema: IioDBBuilderSchema; const AMap: IioMap);
    class procedure BuildSchemaTable(const ASchema: IioDBBuilderSchema; const AMap: IioMap);
  public
    class procedure BuildSchema(const ASchema: IioDBBuilderSchema);
  end;

implementation

uses
  iORM.COntext.Container, iORM.COntext.Properties.Interfaces, iORM.Attributes, iORM.DBBuilder.Factory, iORM.Containers.Interfaces,
  iORM.Resolver.Factory, iORM.Resolver.Interfaces;

{ TioDBBuilderSchemaBuilder }

class procedure TioDBBuilderSchemaBuilder.BuildSchema(const ASchema: IioDBBuilderSchema);
var
  AContextSlot: TioMapSlot;
begin
  // Loop for all entities and build table list
  for AContextSlot in TioMapContainer.GetContainer.Values do
    BuildSchemaTable(ASchema, AContextSlot.GetMap);
  // Loop for all entities and build FK list
  for AContextSlot in TioMapContainer.GetContainer.Values do
    BuildSchemaFK(ASchema, AContextSlot.GetMap);
end;

class procedure TioDBBuilderSchemaBuilder.BuildSchemaFK(const ASchema: IioDBBuilderSchema; const AMap: IioMap);
var
  // LSchemaTable: IioDBBuilderSchemaTable;
  LProperty: IioContextProperty;
  LDependentProperty: IioContextProperty;
  LResolvedTypeList: IioList<string>;
  LResolvedTypeName: String;
  LResolvedTypeMap: IioMap;
begin
  for LProperty in AMap.GetProperties do
  begin
    if (LProperty.GetRelationType in [ioRTNone, ioRTEmbeddedHasOne, ioRTEmbeddedHasMany]) or
      (LProperty.GetMetadata_FKCreate = fkDoNotCreate) then
      Continue;
    // Resolve the type and alias for the relation child type
    LResolvedTypeList := TioResolverFactory.GetResolver(rsByDependencyInjection).Resolve(LProperty.GetRelationChildTypeName,
      LProperty.GetRelationChildTypeAlias, rmAll);
    // Loop for all classes in the resolved type list
    for LResolvedTypeName in LResolvedTypeList do
    begin
      // Get the map for the current ResolverTypeName (Child)
      LResolvedTypeMap := TioMapContainer.GetMap(LResolvedTypeName);
      // If FK is between two classes mapped to two different ConnectionDefNames then skip it
      if AMap.GetTable.GetConnectionDefName <> LResolvedTypeMap.GetTable.GetConnectionDefName then
        Continue;
      if LProperty.GetRelationType in [ioRTBelongsTo] then
      begin
        LDependentProperty := LProperty;
        ASchema.FindTable(AMap.GetTable.TableName).AddForeignKey(LResolvedTypeMap, AMap, LProperty,
          LDependentProperty.GetMetadata_FKOnDeleteAction, LDependentProperty.GetMetadata_FKOnUpdateAction)
      end
      else
      begin
        LDependentProperty := LResolvedTypeMap.GetProperties.GetPropertyByName(LProperty.GetRelationChildPropertyName);
        ASchema.FindTable(LResolvedTypeMap.GetTable.TableName).AddForeignKey(AMap, LResolvedTypeMap, LDependentProperty,
          LDependentProperty.GetMetadata_FKOnDeleteAction, LDependentProperty.GetMetadata_FKOnUpdateAction);
      end;
    end;
  end;
end;

class procedure TioDBBuilderSchemaBuilder.BuildSchemaTable(const ASchema: IioDBBuilderSchema; const AMap: IioMap);
var
  LSchemaTable: IioDBBuilderSchemaTable;
  LProperty: IioContextProperty;
begin
  if not(AMap.GetTable.GetAutoCreateDB and AMap.GetTable.IsForThisConnection(ASchema.ConnectionDefName)) then
    Exit;
  LSchemaTable := ASchema.FindOrCreateTable(AMap);
  for LProperty in AMap.GetProperties do
    if not(LProperty.IsSkipped and (LProperty.GetRelationType = ioRTHasMany) and (LProperty.GetRelationType = ioRTHasOne)) then
      LSchemaTable.AddField(TioDBBuilderFactory.NewSchemaField(LProperty));
  BuildIndexList(LSchemaTable, AMap);
end;

class procedure TioDBBuilderSchemaBuilder.BuildIndexList(const ASchemaTable: IioDBBuilderSchemaTable; const AMap: IioMap);
var
  LIndexAttr: ioIndex;
begin
  // If some explicit index is present then add it to the list
  if AMap.GetTable.IndexListExists then
    for LIndexAttr in AMap.GetTable.GetIndexList(False) do
      ASchemaTable.AddIndex(LIndexAttr);
end;

end.