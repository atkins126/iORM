{***************************************************************************}
{                                                                           }
{           iORM - (interfaced ORM)                                         }
{                                                                           }
{           Copyright (C) 2015-2016 Maurizio Del Magno                      }
{                                                                           }
{           mauriziodm@levantesw.it                                         }
{           mauriziodelmagno@gmail.com                                      }
{           https://github.com/mauriziodm/iORM.git                          }
{                                                                           }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  This file is part of iORM (Interfaced Object Relational Mapper).         }
{                                                                           }
{  Licensed under the GNU Lesser General Public License, Version 3;         }
{  you may not use this file except in compliance with the License.         }
{                                                                           }
{  iORM is free software: you can redistribute it and/or modify             }
{  it under the terms of the GNU Lesser General Public License as published }
{  by the Free Software Foundation, either version 3 of the License, or     }
{  (at your option) any later version.                                      }
{                                                                           }
{  iORM is distributed in the hope that it will be useful,                  }
{  but WITHOUT ANY WARRANTY; without even the implied warranty of           }
{  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            }
{  GNU Lesser General Public License for more details.                      }
{                                                                           }
{  You should have received a copy of the GNU Lesser General Public License }
{  along with iORM.  If not, see <http://www.gnu.org/licenses/>.            }
{                                                                           }
{***************************************************************************}





unit iORM.Utilities;

interface

uses
  iORM.CommonTypes, System.Rtti, System.Classes, iORM.Exceptions,
  System.TypInfo, iORM.MVVM.Interfaces, System.Types;

type

  TioUtilities = class
  public
    class function ObjectAsIInterface(const AObj:Tobject): IInterface; static;
    class function ObjectAsIioViewModel(const AObj:Tobject): IioViewModel; static;
    class function IsAnInterface<T>: Boolean; static;
    class function CastObjectToGeneric<T>(const AObj:TObject): T; overload; static;
    class function CastObjectToGeneric<T>(const AObj:TObject; IID:TGUID): T; overload; static;
    class function GenericToString<T>(const AQualified:Boolean=False): String; static;
    class function ClassRefToRttiType(const AClassRef:TioClassRef): TRttiInstanceType; static;
    class function IsAnInterfaceTypeName(const ATypeName:String): Boolean; static;
    class function ResolveChildPropertyPath(const ARootObj:TObject; const AChildPropertyPath:TStrings): TObject; static;
    class function TypeInfoToTypeName(const ATypeInfo:PTypeInfo; const AQualified:Boolean=False): String; static;
    class function SameObject(const AObj1, AObj2: TObject): boolean;
    class function GetImplementedInterfaceName(const AClassType:TRttiInstanceType; const IID:TGUID): String; static;
    class function TValueToObject(const AValue: TValue; const ASilentException:Boolean=True): TObject; static;
    class function TObjectFrom<T>(const AInstancePointer:Pointer): TObject;
    class function TypeInfoToGUID(const ATypeInfo:PTypeInfo):TGUID; static;
    class function GUIDtoTypeInfo(const IID:TGUID): PTypeInfo; static;
    class function GUIDtoInterfaceName(const IID:TGUID): String; static;
    class function GetQualifiedTypeName(const ATypeInfo: Pointer): String; static;
    class function ExtractPropertyName(const AFullPathPropertyName: String): String;
    class function ResolveRttiTypeToClassRef(const ARttiType: TRttiType): TClass;
    class function ResolveRttiTypeToRttiType(const ARttiType: TRttiType): TRttiType;
  end;

implementation

uses
  System.SysUtils, iORM.RttiContext.Factory, System.StrUtils, iORM, iORM.DependencyInjection.Implementers;

{ TioRttiUtilities }


class function TioUtilities.CastObjectToGeneric<T>(const AObj: TObject; IID:TGUID): T;
begin
  if not Assigned(AObj) then
    Exit(TValue.Empty.AsType<T>);
  if IsAnInterface<T> then
  begin
    if IID = GUID_NULL then
    begin
      IID := TypeInfoToGUID(TypeInfo(T));
      if IID = GUID_NULL then
        raise EioException.Create('TioRttiUtilities.CastObjectToGeneric: The interface does not have the GUID.');
    end;
    if not Supports(AObj, IID, Result) then
      raise EioException.Create('TioRttiUtilities.CastObjectToGeneric: Interface not supported.');
  end
  else
    Result := TValue.From<TObject>(AObj).AsType<T>;
end;

class function TioUtilities.CastObjectToGeneric<T>(const AObj: TObject): T;
begin
  Result := CastObjectToGeneric<T>(AObj, GUID_NULL);
end;

class function TioUtilities.ClassRefToRttiType(const AClassRef: TioClassRef): TRttiInstanceType;
begin
  Result := TioRttiContextFactory.RttiContext.GetType(AClassref).AsInstance;
end;

class function TioUtilities.ExtractPropertyName(const AFullPathPropertyName: String): String;
var
  LDotPos: Integer;
begin
  Result := AFullPathPropertyName;
  LDotPos := Pos('.', Result);
  while LDotPos > 0 do
  begin
    Result := Result.Remove(0, LDotPos);
    LDotPos := Pos('.', Result);
  end;
end;

class function TioUtilities.GenericToString<T>(const AQualified:Boolean=False): String;
begin
  Result := TypeInfoToTypeName(TypeInfo(T), AQualified);
end;

class function TioUtilities.GetImplementedInterfaceName(
  const AClassType: TRttiInstanceType; const IID: TGUID): String;
var
  LRttiInterfaceType: TRttiInterfaceType;
begin
  for LRttiInterfaceType in AClassType.GetImplementedInterfaces do
    if LRttiInterfaceType.GUID = IID then
      Exit(LRttiInterfaceType.Name);
  raise EioException.Create('TioRttiUtilities.GetImplementedInterfaceName: Interface non implemented by the class.');
end;

class function TioUtilities.GetQualifiedTypeName(const ATypeInfo: Pointer): String;
begin
  Result := TioRttiContextFactory.RttiContext.GetType(ATypeInfo).QualifiedName;
end;

class function TioUtilities.GUIDtoInterfaceName(const IID: TGUID): String;
var
  LType : TRttiType;
begin
  for LType in TioRttiContextFactory.RttiContext.GetTypes do
   if LType is TRTTIInterfaceType and (TRTTIInterfaceType(LType).GUID = IID) then
     exit(TRTTIInterfaceType(LType).Name);
  raise EioException.Create('TioRttiUtilities.GUIDtoInterfaceName: IID is not an interface.');
end;

class function TioUtilities.GUIDtoTypeInfo(const IID: TGUID): PTypeInfo;
var
  LType : TRttiType;
begin
  for LType in TioRttiContextFactory.RttiContext.GetTypes do
   if LType is TRTTIInterfaceType and (TRTTIInterfaceType(LType).GUID = IID) then
     exit(TRTTIInterfaceType(LType).Handle);
  raise EioException.Create('TioRttiUtilities.GUIDtoTypeInfo: IID is not an interface.');
end;

class function TioUtilities.IsAnInterfaceTypeName(const ATypeName: String): Boolean;
begin
  Result := ATypeName.StartsWith('I');
end;

class function TioUtilities.ObjectAsIInterface(
  const AObj: Tobject): IInterface;
begin
  if not Supports(AObj, IInterface, Result) then
    raise EioException.Create('TioRttiUtilities: IInterface not implemented by the object (' + AObj.ClassName + ').');
end;

class function TioUtilities.ObjectAsIioViewModel(
  const AObj: Tobject): IioViewModel;
begin
  if not Supports(AObj, IioViewModel, Result) then
    raise EioException.Create('TioRttiUtilities: IioViewModel not implemented by the object (' + AObj.ClassName + ').');
end;

// Questa funzione, a partire dal RootObject, restituisce l'oggetto a relativo al ChildPropertyPath navigando le propriet�
//  dei vari livelli di oggetti.
class function TioUtilities.ResolveChildPropertyPath(const ARootObj: TObject; const AChildPropertyPath: TStrings): TObject;
var
  Ctx: TRttiContext;
  ACurrPropName: String;
  function GetChildObject(const AMasterObj:TObject; const AMasterPropertyName:String): TObject;
  var
    Typ: TRttiType;
    Prop: TRttiProperty;
    AValue: TValue;
  begin
    // Get the object RttiType
    Typ := Ctx.GetType(AMasterObj.ClassType);
    // Get the RttiProperty
    Prop := Typ.GetProperty(AMasterPropertyName);
    // Extract the object/interface (it must be an object or an interface)
    AValue := Prop.GetValue(AMasterObj);
    // Return the resolved child object
    Result := TValueToObject(AValue, True);
  end;
begin
  // Init
  Result := ARootObj;
  // If the AChildPropertyPath is not assigned then Exit
  if not Assigned(AChildPropertyPath) then
    Exit;
  // Get the RttiContext
  Ctx := TioRttiContextFactory.RttiContext;
  // Loop for properties on the path
  for ACurrPropName in AChildPropertyPath do
  begin
    if not Assigned(Result) then
      Exit;
    Result := GetChildObject(Result, ACurrPropName);
  end;
end;

class function TioUtilities.ResolveRttiTypeToClassRef(const ARttiType: TRttiType): TClass;
var
  LResolvedRttiType: TRttiType;
begin
  LResolvedRttiType := ResolveRttiTypeToRttiType(ARttiType);
  Result := LResolvedRttiType.AsInstance.MetaclassType; // Note: the resolved type is always a TRttiInstamceType
end;

class function TioUtilities.ResolveRttiTypeToRttiType(const ARttiType: TRttiType): TRttiType;
var
  LContainerImplementersItem: TioDIContainerImplementersItem;
begin
  if ARttiType.IsInstance then
    Exit(ARttiType)
  else
  if ARttiType is TRttiInterfaceType then
  begin
    LContainerImplementersItem := io.di.Locate(ARttiType.Name).GetItem;
    Exit(LContainerImplementersItem.RttiType);
  end
  else
    raise eioException.Create(Self.ClassName, 'RttiTypeToClassRef', '"ARttiType" parameter must be a TRttiInstanceType or TRttiInterfaceType.');
end;

class function TioUtilities.SameObject(const AObj1,
  AObj2: TObject): boolean;
begin
  Result := (@AObj1 = @AObj2);
end;

class function TioUtilities.TObjectFrom<T>(const AInstancePointer: Pointer): TObject;
var
  LValue: TValue;
begin
  TValue.Make(@AInstancePointer, TypeInfo(T), LValue);
  Result := Self.TValueToObject(LValue, False);
end;

class function TioUtilities.TValueToObject(const AValue: TValue; const ASilentException:Boolean): TObject;
begin
  Result := nil;
  case AValue.TypeInfo.Kind of
    tkInterface: Result := AValue.AsInterface As TObject;
    tkClass: Result := AValue.AsObject;
  else if not ASilentException then
    raise EioException.Create('TioRttiUtilities.TValueToObject: The TValue does not contain an object or interfaced object.');
  end;
end;

class function TioUtilities.TypeInfoToGUID(
  const ATypeInfo: PTypeInfo): TGUID;
var
  LTyp: TRttiType;
begin
  if ATypeInfo.Kind <> tkInterface then
    raise EioException.Create('TioRttiUtilities.TypeInfoToGUID: ATypeInfo is not relative to an interface.');
  LTyp := TioRttiContextFactory.RttiContext.GetType(ATypeInfo);
  if not Assigned(LTyp) then
    raise EioException.Create('TioRttiUtilities.TypeInfoToGUID: RTTI type info not found, derive it from IInvokable or insert the {M+} directive before its declaration to solve the problem.');
  Result := TRttiInterfaceType(LTyp).GUID;
end;

class function TioUtilities.TypeInfoToTypeName(
  const ATypeInfo: PTypeInfo; const AQualified:Boolean=False): String;
begin
// From XE7
{$IFDEF NEXTGEN}
  // Get the type name
  Result := ATypeInfo.NameFld.ToString;
  // If a qualifiedname is required...
  if AQualified then
  begin
    // If it is an interface then link the Interface unit to the TypeName
    if  ATypeInfo.Kind = tkInterface then
      Result := ATypeInfo.TypeData.IntfUnitFld.ToString + '.' + Result
    // else (class) link the class unit to the TypeName
    else
      Result := ATypeInfo.TypeData.UnitNameFld.ToString + '.' + Result;
  end;
// Before XE7
{$ELSE  NEXTGEN}
  Result := String(ATypeInfo.Name);
{$ENDIF NEXTGEN}
end;

class function TioUtilities.IsAnInterface<T>: Boolean;
begin
  // Result is True if T si an interface
//  Result := (   TioRttiContextFactory.RttiContext.GetType(TypeInfo(T)) is TRttiInterfaceType   );
  Result := PTypeInfo(TypeInfo(T)).Kind = tkInterface;
end;

end.



