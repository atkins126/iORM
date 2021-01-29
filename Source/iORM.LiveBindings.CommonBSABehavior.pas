{ *************************************************************************** }
{ }
{ iORM - (interfaced ORM) }
{ }
{ Copyright (C) 2015-2016 Maurizio Del Magno }
{ }
{ mauriziodm@levantesw.it }
{ mauriziodelmagno@gmail.com }
{ https://github.com/mauriziodm/iORM.git }
{ }
{ }
{ *************************************************************************** }
{ }
{ This file is part of iORM (Interfaced Object Relational Mapper). }
{ }
{ Licensed under the GNU Lesser General Public License, Version 3; }
{ you may not use this file except in compliance with the License. }
{ }
{ iORM is free software: you can redistribute it and/or modify }
{ it under the terms of the GNU Lesser General Public License as published }
{ by the Free Software Foundation, either version 3 of the License, or }
{ (at your option) any later version. }
{ }
{ iORM is distributed in the hope that it will be useful, }
{ but WITHOUT ANY WARRANTY; without even the implied warranty of }
{ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the }
{ GNU Lesser General Public License for more details. }
{ }
{ You should have received a copy of the GNU Lesser General Public License }
{ along with iORM.  If not, see <http://www.gnu.org/licenses/>. }
{ }
{ *************************************************************************** }

unit iORM.LiveBindings.CommonBSABehavior;

interface

uses
  iORM.LiveBindings.Interfaces, Rtti, Data.Bind.ObjectScope, System.Generics.Collections, Data.Bind.Components,
  iORM.Context.Properties.Interfaces;

type

  // This class helper is a hack because I absolutely needed to be able to access the private "FIndex" field
  //  of the "TBindSourceAdapterField" class.
  TioBindSourceAdapterFieldHelper = class helper for TBindSourceAdapterField
  private
    class var FIndexOffset: Integer;
  public
    class constructor Create; // Executed automatically at program start
    procedure SetIndex(const Value: Integer);
  end;

  // Implementation of IGetMemberObject to get the child object
  //  In the architecture of the BindSourceAdapters, the classes that implement the "IGetMemberObject" interface have
  //  the task of returning the instance of the object on which to carry out the read / write operations (GetValue / SetValue).
  //  This specific implementation is used to make it possible to obtain the object even if the field is related to a property
  //  of a child object of the current master object (master-detail of a BelongsTo, HasOne or EmbeddedHasOne relation)
  //  Ex: Customer.Payment.Description in a TOrder class.
  //  In practice, various implementations are created in cascade for how many are the relationship levels that must be crossed
  //  to reach the target object on which to perform the GetValue / SetValue operations.
  TioBindSourceAdapterGetChildMemberObject = class(TInterfacedObject, IGetMemberObject)
  private
    FMasterMemberObject: IGetMemberObject;
    FMasterProperty: IioContextProperty;
  public
    constructor Create(const AMasterGetMemberObject: IGetMemberObject; const AMasterProperty: IioContextProperty);
    function GetMemberObject: TObject;
  end;

  // Use RTTI to read the value of a property
  //  The ValueReader classes are used to read the value of a property relating to a field of a BindSourceAdapter
  //  from the current object of the adapter itself. This particular implementation in iORM is used to access the
  //  properties of also child objects of the current master object (the current object of the BindSourceAdapter);
  //  eg: "Customer.Address" field name.
  TioPropertyValueReader<T> = class(TPropertyValueReader<T>)
  public
    function GetValue: T; override;
  end;

  // Use RTTI to write the value into a property
  //  The ValueReader classes are used to write a value into a property relating to a field of a BindSourceAdapter
  //  in the current object of the adapter itself. This particular implementation in iORM is used to access the
  //  properties of also child objects of the current master object (the current object of the BindSourceAdapter);
  //  eg: "Customer.Address" field name.
  TioPropertyValueWriter<T> = class(TPropertyValueWriter<T>)
  public
    procedure SetValue(const AValue: T); override;
  end;

  // Methods and functionalities common to all ActiveBindSouceAdapters
  TioCommonBSABehavior = class
  public
    // NB: Generic type for this methods must be only TObject or IInterface
    class procedure InternalSetDataObjectAsDetail<T>(const AActiveBindSourceAdapter: IioActiveBindSourceAdapter;
      const ADataObject: T); overload;
    // ==========================================================================================================================
    // Changes to the BindSourceAdapters to make it possible to create fields that access nested properties/fields
    //  (eg: "Customer.Payment.Description")
    // --------------------------------------------------------------------------------------------------------------------------
    class procedure AddFields(AType: TRttiType; ABindSourceAdapter: TBindSourceAdapter; const AGetMemberObject: IGetMemberObject;
      const APath: String);
    class procedure AddPropertiesToList(AType: TRttiType; ABindSourceAdapter: TBindSourceAdapter;
      AFieldsList: TList<TBindSourceAdapterField>; const AGetMemberObject: IGetMemberObject; const APath: String);
    class procedure AddChildPropertiesToList(AType: TRttiType; ABindSourceAdapter: TBindSourceAdapter;
      AFieldsList: TList<TBindSourceAdapterField>; const AMasterGetMemberObject: IGetMemberObject; const AMasterPath: String);
    class function CreateRttiPropertyField<T>(AProperty: TRttiProperty; ABindSourceAdapter: TBindSourceAdapter;
      const AGetMemberObject: IGetMemberObject; AMemberType: TScopeMemberType; const APath: String): TBindSourceAdapterField;
    class function CreateRttiObjectPropertyField<T: class>(AProperty: TRttiProperty; ABindSourceAdapter: TBindSourceAdapter;
      const AGetMemberObject: IGetMemberObject; AMemberType: TScopeMemberType; const APath: String): TBindSourceAdapterField;
    // ==========================================================================================================================
  end;

implementation

uses iORM.Context.Map.Interfaces, iORM.Context.Factory, iORM.Attributes,
  System.TypInfo, System.SysUtils, iORM.Utilities, iORM.Exceptions;

{ TioCommonBSABehavior }

class procedure TioCommonBSABehavior.InternalSetDataObjectAsDetail<T>(const AActiveBindSourceAdapter: IioActiveBindSourceAdapter;
  const ADataObject: T);
var
  LMasterObj: TObject;
  LMasterProperty: IioContextProperty;
  LValue: TValue;
begin
  LMasterObj := AActiveBindSourceAdapter.GetMasterBindSourceAdapter.Current;
  LMasterProperty := TioContextFactory.GetPropertyByClassRefAndName(LMasterObj.ClassType,
    AActiveBindSourceAdapter.GetMasterPropertyName);
  TValue.Make(@ADataObject, LMasterProperty.GetTypeInfo, LValue);
  LMasterProperty.SetValue(LMasterObj, LValue);
  AActiveBindSourceAdapter.GetMasterBindSourceAdapter.DetailAdaptersContainer.SetMasterObject(LMasterObj);
end;

class procedure TioCommonBSABehavior.AddFields(AType: TRttiType; ABindSourceAdapter: TBindSourceAdapter;
  const AGetMemberObject: IGetMemberObject; const APath: String);
begin
  // AddFieldsToList(LType, Self, Self.Fields, LIntf); // Per ora ho deciso di non considerare gli eventuali public fields ma solo propriet� (sempre pubbliche)
  AddPropertiesToList(AType, ABindSourceAdapter, ABindSourceAdapter.Fields, AGetMemberObject, APath);
  AddChildPropertiesToList(AType, ABindSourceAdapter, ABindSourceAdapter.Fields, AGetMemberObject, APath);
end;

class procedure TioCommonBSABehavior.AddPropertiesToList(AType: TRttiType; ABindSourceAdapter: TBindSourceAdapter;
  AFieldsList: TList<TBindSourceAdapterField>; const AGetMemberObject: IGetMemberObject; const APath: String);
const
  sTStrings = 'TStrings';
  sTPersistent = 'TPersistent';
var
  LType: TRttiType;
  LProperties: TArray<TRttiProperty>;
  LProperty: TRttiProperty;
  LCollectionEditorField: TBindSourceAdapterField;
  LTypeInfo: PTypeInfo;
  LTypeName: string;
  LTypeData: PTypeData;
  LInstance: TRttiInstanceType;
  LAncestor: string;
begin
  //LType := AType; // Original code
  LType := TioUtilities.ResolveRttiTypeToRttiType(AType);
  LProperties := LType.GetProperties;
  for LProperty in LProperties do
  begin
    LCollectionEditorField := nil;
    LTypeInfo := LProperty.PropertyType.Handle;
    if LTypeInfo = nil then
      continue;
    LTypeName := LProperty.PropertyType.Name;
    LTypeData := System.TypInfo.GetTypeData(LTypeInfo);
    case LProperty.Visibility of
      TMemberVisibility.mvPublic, TMemberVisibility.mvPublished:
        begin
{$IFDEF NEXTGEN}
          if (LProperty.Name = 'Disposed') or (LProperty.Name = 'RefCount') then
            continue;
{$ENDIF}
          case LProperty.PropertyType.TypeKind of
            tkEnumeration:
              if SameText(LTypeName, 'boolean') or SameText(LTypeName, 'bool') then // 'bool' for C++
                LCollectionEditorField := CreateRttiPropertyField<Boolean>(LProperty, ABindSourceAdapter, AGetMemberObject,
                  mtBoolean, APath);
            tkInteger:
              begin
                case LTypeData.OrdType of
                  otSByte: // Int8
                    LCollectionEditorField := CreateRttiPropertyField<Int8>(LProperty, ABindSourceAdapter, AGetMemberObject,
                      mtInteger, APath);
                  otSWord: // Int16
                    LCollectionEditorField := CreateRttiPropertyField<Int16>(LProperty, ABindSourceAdapter, AGetMemberObject,
                      mtInteger, APath);
                  otSLong: // Int32
                    LCollectionEditorField := CreateRttiPropertyField<Int32>(LProperty, ABindSourceAdapter, AGetMemberObject,
                      mtInteger, APath);
                  otUByte: // UInt8
                    LCollectionEditorField := CreateRttiPropertyField<UInt8>(LProperty, ABindSourceAdapter, AGetMemberObject,
                      mtUInteger, APath);
                  otUWord: // UInt16
                    LCollectionEditorField := CreateRttiPropertyField<UInt16>(LProperty, ABindSourceAdapter, AGetMemberObject,
                      mtUInteger, APath);
                  otULong: // UInt32
                    LCollectionEditorField := CreateRttiPropertyField<UInt32>(LProperty, ABindSourceAdapter, AGetMemberObject,
                      mtUInteger, APath);
                else
                  LCollectionEditorField := CreateRttiPropertyField<Integer>(LProperty, ABindSourceAdapter, AGetMemberObject,
                    mtInteger, APath);
                end
              end;
            tkWChar:
              LCollectionEditorField := CreateRttiPropertyField<Char>(LProperty, ABindSourceAdapter, AGetMemberObject, mtChar, APath);
            tkUString:
              LCollectionEditorField := CreateRttiPropertyField<string>(LProperty, ABindSourceAdapter, AGetMemberObject, mtText, APath);
{$IFNDEF NEXTGEN}
            tkChar:
              LCollectionEditorField := CreateRttiPropertyField<AnsiChar>(LProperty, ABindSourceAdapter, AGetMemberObject,
                mtChar, APath);
            tkString:
              LCollectionEditorField := CreateRttiPropertyField<ShortString>(LProperty, ABindSourceAdapter, AGetMemberObject,
                mtText, APath);
            tkLString:
              LCollectionEditorField := CreateRttiPropertyField<AnsiString>(LProperty, ABindSourceAdapter, AGetMemberObject,
                mtText, APath);
{$ENDIF}
            tkFloat:
              case LTypeData^.FloatType of
                System.TypInfo.ftSingle:
                  LCollectionEditorField := CreateRttiPropertyField<single>(LProperty, ABindSourceAdapter, AGetMemberObject,
                    mtFloat, APath);
                System.TypInfo.ftDouble:
                  begin
                    if LTypeInfo = System.TypeInfo(TDate) then
                      LCollectionEditorField := CreateRttiPropertyField<TDate>(LProperty, ABindSourceAdapter, AGetMemberObject,
                        mtDate, APath)
                    else if LTypeInfo = System.TypeInfo(TTime) then
                      LCollectionEditorField := CreateRttiPropertyField<TTime>(LProperty, ABindSourceAdapter, AGetMemberObject,
                        mtTime, APath)
                    else if LTypeInfo = System.TypeInfo(TDateTime) then
                      LCollectionEditorField := CreateRttiPropertyField<TDateTime>(LProperty, ABindSourceAdapter, AGetMemberObject,
                        mtDateTime, APath)
                    else
                      LCollectionEditorField := CreateRttiPropertyField<double>(LProperty, ABindSourceAdapter, AGetMemberObject,
                        mtFloat, APath);
                  end;
                ftExtended:
                  LCollectionEditorField := CreateRttiPropertyField<Extended>(LProperty, ABindSourceAdapter, AGetMemberObject,
                    mtFloat, APath);
                ftCurr:
                  LCollectionEditorField := CreateRttiPropertyField<currency>(LProperty, ABindSourceAdapter, AGetMemberObject,
                    mtCurrency, APath);
                // ftComp:  // Not supported
              else
                Assert(False);
                LCollectionEditorField := CreateRttiPropertyField<Extended>(LProperty, ABindSourceAdapter, AGetMemberObject,
                  mtFloat, APath);
              end;
            tkInt64:
              if LTypeData.MinInt64Value > LTypeData.MaxInt64Value then
                LCollectionEditorField := CreateRttiPropertyField<UInt64>(LProperty, ABindSourceAdapter, AGetMemberObject,
                  mtUInteger, APath)
              else
                LCollectionEditorField := CreateRttiPropertyField<Int64>(LProperty, ABindSourceAdapter, AGetMemberObject,
                  mtInteger, APath);
            tkClass:
              begin
                if LProperty.PropertyType.IsInstance then
                begin
                  LInstance := LProperty.PropertyType.AsInstance;
                  while LInstance <> nil do
                  begin
                    LAncestor := LInstance.Name;
                    if LAncestor = sTStrings then
                      break;
                    if LAncestor = sTPersistent then
                      break;
                    LInstance := LInstance.BaseType;
                  end;
                end;
                if LAncestor = sTStrings then
                  LCollectionEditorField := CreateRttiObjectPropertyField<TObject>(LProperty, ABindSourceAdapter, AGetMemberObject,
                    mtMemo, APath)
                else if LAncestor = sTPersistent then
                  LCollectionEditorField := CreateRttiObjectPropertyField<TObject>(LProperty, ABindSourceAdapter, AGetMemberObject,
                    mtBitmap, APath)
                else
                  LCollectionEditorField := CreateRttiObjectPropertyField<TObject>(LProperty, ABindSourceAdapter, AGetMemberObject,
                    mtObject, APath)
              end;
          end;
          if LCollectionEditorField <> nil then
          begin
            // LCollectionEditorField.FGetMemberObject := AGetMemberObject; // Original
            LCollectionEditorField.GetMemberObjectIntf := AGetMemberObject;
            // LCollectionEditorField.FIndex := AFieldsList.Add(LCollectionEditorField);  // Original
            LCollectionEditorField.SetIndex(AFieldsList.Add(LCollectionEditorField));
            // Using class helper hack to access FIndex private field in the original class
          end;
        end;

    end;

  end;
end;

class procedure TioCommonBSABehavior.AddChildPropertiesToList(AType: TRttiType; ABindSourceAdapter: TBindSourceAdapter;
  AFieldsList: TList<TBindSourceAdapterField>; const AMasterGetMemberObject: IGetMemberObject; const AMasterPath: String);
var
  LMap: IioMap;
  LProperty: IioContextProperty;
  LChildPath: String;
  LChildGetMemberObject: IGetMemberObject;
begin
  LMap := TioContextFactory.Map(TioUtilities.ResolveRttiTypeToClassRef(AType));
  for LProperty in LMap.GetProperties do
  begin
    if LProperty.GetRelationType in [ioRtBelongsTo, ioRTHasOne, ioRTEmbeddedHasOne] then
    begin
      LChildPath := AMasterPath + LProperty.GetName + '.';
      LChildGetMemberObject := TioBindSourceAdapterGetChildMemberObject.Create(AMasterGetMemberObject, LProperty);
      AddFields(LProperty.GetRttiType, ABindSourceAdapter, LChildGetMemberObject, LChildPath);
    end;
  end;
end;

class function TioCommonBSABehavior.CreateRttiPropertyField<T>(AProperty: TRttiProperty; ABindSourceAdapter: TBindSourceAdapter;
  const AGetMemberObject: IGetMemberObject; AMemberType: TScopeMemberType; const APath: String): TBindSourceAdapterField;
begin
  Result := nil;
  if AProperty.IsReadable then
    if AProperty.IsWritable then
      Result := TBindSourceAdapterReadWriteField<T>.Create(ABindSourceAdapter, APath + AProperty.Name,
        TBindSourceAdapterFieldType.Create(AProperty.PropertyType.Name, AProperty.PropertyType.TypeKind), AGetMemberObject,
        TioPropertyValueReader<T>.Create, TioPropertyValueWriter<T>.Create, AMemberType)
    else
      Result := TBindSourceAdapterReadField<T>.Create(ABindSourceAdapter, APath + AProperty.Name,
        TBindSourceAdapterFieldType.Create(AProperty.PropertyType.Name, AProperty.PropertyType.TypeKind), AGetMemberObject,
        TioPropertyValueReader<T>.Create, AMemberType);
end;

class function TioCommonBSABehavior.CreateRttiObjectPropertyField<T>(AProperty: TRttiProperty; ABindSourceAdapter: TBindSourceAdapter;
  const AGetMemberObject: IGetMemberObject; AMemberType: TScopeMemberType; const APath: String): TBindSourceAdapterField;
begin
  Result := nil;
  if AProperty.IsReadable then
    if AProperty.IsWritable then
      Result := TBindSourceAdapterReadWriteObjectField<T>.Create(ABindSourceAdapter, AProperty.Name,
        TBindSourceAdapterFieldType.Create(AProperty.PropertyType.Name, AProperty.PropertyType.TypeKind), AGetMemberObject,
        TPropertyValueReader<T>.Create, TPropertyValueWriter<T>.Create, AMemberType)
    else
      Result := TBindSourceAdapterReadObjectField<T>.Create(ABindSourceAdapter, AProperty.Name,
        TBindSourceAdapterFieldType.Create(AProperty.PropertyType.Name, AProperty.PropertyType.TypeKind), AGetMemberObject,
        TPropertyValueReader<T>.Create, AMemberType);
end;

{ TBindSourceAdapterFieldHelper }

class constructor TioBindSourceAdapterFieldHelper.Create;
var
  Ctx: TRTTIContext;
begin
  // Obtain the offset of the private field "FIndex"
  FIndexOffset := Ctx.GetType(TBindSourceAdapterField).GetField('FIndex').Offset;
end;

procedure TioBindSourceAdapterFieldHelper.SetIndex(const Value: Integer);
begin
  // Use the offset obtained above to access the value of the private field "FIndex"
  PInteger(Pointer(NativeInt(Self) + FIndexOffset))^ := Value;
end;

{ TBindSourceAdapterGetChildMemberObject }

constructor TioBindSourceAdapterGetChildMemberObject.Create(const AMasterGetMemberObject: IGetMemberObject;
  const AMasterProperty: IioContextProperty);
begin
  FMasterMemberObject := AMasterGetMemberObject;
  FMasterProperty := AMasterProperty;
end;

function TioBindSourceAdapterGetChildMemberObject.GetMemberObject: TObject;
var
  LMasterObj: TObject;
begin
  LMasterObj := FMasterMemberObject.GetMemberObject;
  Result := FMasterProperty.GetRelationChildObject(LMasterObj);
end;

{ TioPropertyValueReader<T> }

function TioPropertyValueReader<T>.GetValue: T;
var
  LObject: TObject;
  LCtxt: TRTTIContext;
  LRttiType: TRttiType;
  LRttiField: TRttiProperty;

begin
  // Do not inherit
  // LObject := FField.GetMemberObject; // original code
  LObject := FField.GetMemberObjectIntf.GetMemberObject;
  if LObject <> nil then
  begin
    LRttiType := LCtxt.GetType(LObject.ClassType);
    LRttiField := LRttiType.GetProperty(TioUtilities.ExtractPropertyName(FField.MemberName));
    if LRttiField <> nil then
    begin
      Result := LRttiField.GetValue(LObject).AsType<T>;
    end
    else
      Result := TValue.Empty.AsType<T>;
  end
  else
    Result := TValue.Empty.AsType<T>;
end;

{ TioPropertyValueWriter<T> }

procedure TioPropertyValueWriter<T>.SetValue(const AValue: T);
var
  LObject: TObject;
  LCtxt: TRTTIContext;
  LRttiType: TRttiType;
  LRttiField: TRttiProperty;
begin
  // Do not inherit
  LObject := FField.GetMemberObjectIntf.GetMemberObject;
  if LObject <> nil then
  begin
    LRttiType := LCtxt.GetType(LObject.ClassType);
    LRttiField := LRttiType.GetProperty(TioUtilities.ExtractPropertyName(FField.MemberName));
    if LRttiField <> nil then
    begin
      LRttiField.SetValue(LObject, TValue.From<T>(AValue));
      // RecordChanged;
    end;
  end
  else
    raise EioException.Create(Self.ClassName, 'SetValue',
      Format('I am unable to resolve the property path "%s".'#13#13'It could be that one of the objects along the way is nil.',
      [FField.MemberName]));
end;

end.
