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





unit iORM;

interface

uses
  iORM.DependencyInjection,
  iORM.Context.Properties.Interfaces,
  iORM.context.interfaces,
  iORM.Context.Factory,
  iORM.CommonTypes,
  iORM.DB.Interfaces,
  iORM.LiveBindings.Interfaces,
  iORM.Global.Factory,
  iORM.DB.ConnectionContainer, iORM.Where.Interfaces, iORM.Where.Factory,
  System.TypInfo, System.Classes, Data.Bind.ObjectScope, ObjMapper,
  System.SysUtils, iORM.DependencyInjection.Interfaces,
  iORM.MVVM.Components.ViewContextProvider, iORM.MVVM.Interfaces,
  iORM.MVVM.Components.ModelPresenter;

type

  // iORM
  io = class
  public
    class function di: TioDependencyInjectionRef;
    class function GlobalFactory: TioGlobalFactoryRef;
    class function RefTo(const ATypeName:String; const ATypeAlias:String=''): IioWhere; overload;
    class function RefTo(const AClassRef:TioClassRef; const ATypeAlias:String=''): IioWhere; overload;
    class function RefTo<T>(const ATypeAlias:String=''): IioWhere<T>; overload;
    class function RefTo(const AWhere:IioWhere): IioWhere; overload;
    class function Load(const ATypeName:String; const ATypeAlias:String=''): IioWhere; overload;
    class function Load(const ATypeInfo:PTypeInfo; const ATypeAlias:String=''): IioWhere; overload;
    class function Load(const AClassRef:TioClassRef; const ATypeAlias:String=''): IioWhere; overload;
    class function Load(const AIID:TGUID; const ATypeAlias:String=''): IioWhere; overload;
    class function Load<T>(const ATypeAlias:String=''): IioWhere<T>; overload;
    class function Load(const AWhere:IioWhere): IioWhere; overload;
    class procedure Delete(const AObj: TObject; const AConnectionName:String=''); overload;
    class procedure Delete(const AIntfObj: IInterface; const AConnectionName:String=''); overload;
    class procedure Persist(const AObj: TObject; const ARelationPropertyName:String; const ARelationOID:Integer; const ABlindInsert:Boolean; const AConnectionName:String); overload;
    class procedure Persist(const AObj: TObject; const ABlindInsert:Boolean=False); overload;
    class procedure Persist(const AObj: TObject; const AConnectionName:String; const ABlindInsert:Boolean=False); overload;
    class procedure Persist(const AIntfObj: IInterface; const ABlindInsert:Boolean=False); overload;
    class procedure Persist(const AIntfObj: IInterface; const AConnectionName:String; const ABlindInsert:Boolean=False); overload;
    class procedure PersistCollection(const ACollection: TObject; const ARelationPropertyName:String; const ARelationOID:Integer; const ABlindInsert:Boolean; const AConnectionName:String); overload;
    class procedure PersistCollection(const ACollection: TObject; const ABlindInsert:Boolean=False); overload;
    class procedure PersistCollection(const ACollection: TObject; const AConnectionName:String; const ABlindInsert:Boolean=False); overload;
    class procedure PersistCollection(const AIntfCollection: IInterface; const ABlindInsert:Boolean=False); overload;
    class procedure PersistCollection(const AIntfCollection: IInterface; const AConnectionName:String; const ABlindInsert:Boolean=False); overload;
    class procedure StartTransaction(const AConnectionName:String='');
    class procedure CommitTransaction(const AConnectionName:String='');
    class procedure RollbackTransaction(const AConnectionName:String='');
    class procedure AutoCreateDatabase(const AConnectionName:String=''; const RaiseExceptionIfNotAvailable:Boolean=True); overload;
    class procedure AutoCreateDatabase(const RaiseExceptionIfNotAvailable:Boolean); overload;   // Default connection only
    class function Connections: TioConnectionManagerRef;
    class function Where: IioWhere; overload;
    class function Where<T>: IioWhere<T>; overload;
    class function Where(const ATextCondition:String): IioWhere; overload;
    class function Where<T>(const ATextCondition:String): IioWhere<T>; overload;
    class function SQL(const ASQL:String): IioSQLDestination; overload;
    class function SQL(const ASQLDestination:IioSQLDestination): IioSQLDestination; overload;
    class function Mapper:omRef;
    class procedure SetWaitProc(const AShowWaitProc:TProc=nil; const AHideWaitProc:TProc=nil);
    class procedure ShowWait;
    class procedure HideWait;
    class function TerminateApplication: Boolean;
    class procedure HandleException(Sender: TObject);

    // Create instance
    class function Create<T:IInterface>(const ATypeAlias:String=''; const AParams: TioConstructorParams=nil): T; overload;
    class function Create<T:IInterface>(const AParams: TioConstructorParams): T; overload;

    // Create View instance
    class function CreateView<T:IInterface>(const ATypeAlias:String=''; const AParams: TioConstructorParams=nil): T; overload;
    class function CreateView<T:IInterface>(const AParams:TioConstructorParams): T; overload;
    // Create View instance passing a ViewContextProvider
    class function CreateView<T:IInterface>(const ATypeAlias:String; const AVCProvider:TioViewContextProvider; const AParams: TioConstructorParams=nil): T; overload;
    class function CreateView<T:IInterface>(const AVCProvider:TioViewContextProvider; const AParams: TioConstructorParams=nil): T; overload;
    // Create View instance passing an already created ViewContext
    class function CreateView<T:IInterface>(const ATypeAlias:String; const AViewContext:TComponent; const AParams: TioConstructorParams=nil): T; overload;
    class function CreateView<T:IInterface>(const AViewContext:TComponent; const AParams: TioConstructorParams=nil): T; overload;
    // Create View instance passing a ViewModel
    class function CreateView<T:IInterface>(const ATypeAlias:String; const AViewModel:IioViewModel; const AParams:TioConstructorParams=nil): T; overload;
    class function CreateView<T:IInterface>(const AViewModel:IioViewModel; const AParams:TioConstructorParams=nil): T; overload;
    // Create View instance passing a ViewModel and a VCProvider)
    class function CreateView<T:IInterface>(const ATypeAlias:String; const AVCProvider:TioViewContextProvider; const AViewModel:IioViewModel; const AParams:TioConstructorParams=nil): T; overload;
    class function CreateView<T:IInterface>(const AVCProvider:TioViewContextProvider; const AViewModel:IioViewModel; const AParams:TioConstructorParams=nil): T; overload;
    // Create View instance passing a ViewModel and an already created ViewContext
    class function CreateView<T:IInterface>(const ATypeAlias:String; const AViewContext:TComponent; const AViewModel:IioViewModel; const AParams:TioConstructorParams=nil): T; overload;
    class function CreateView<T:IInterface>(const AViewContext:TComponent; const AViewModel:IioViewModel; const AParams:TioConstructorParams=nil): T; overload;

    // Create View instance for a specified type of instances
    class function CreateViewFor<T>(const AVVMAlias:String=''; const AParams: TioConstructorParams=nil): TComponent; overload;
    class function CreateViewFor<T>(const AParams:TioConstructorParams): TComponent; overload;
    // Create View instance for a specified type of instances passing a ViewContextProvider
    class function CreateViewFor<T>(const AVVMAlias:String; const AVCProvider:TioViewContextProvider; const AParams: TioConstructorParams=nil): TComponent; overload;
    class function CreateViewFor<T>(const AVCProvider:TioViewContextProvider; const AParams: TioConstructorParams=nil): TComponent; overload;
    // Create View instance for a specified type of instances passing an already created ViewContext
    class function CreateViewFor<T>(const AVVMAlias:String; const AViewContext:TComponent; const AParams: TioConstructorParams=nil): TComponent; overload;
    class function CreateViewFor<T>(const AViewContext:TComponent; const AParams: TioConstructorParams=nil): TComponent; overload;
    // Create View instance for a specified type of instances passing a ViewModel
    class function CreateViewFor<T>(const AVVMAlias:String; const AViewModel:IioViewModel; const AParams:TioConstructorParams=nil): TComponent; overload;
    class function CreateViewFor<T>(const AViewModel:IioViewModel; const AParams:TioConstructorParams=nil): TComponent; overload;
    // Create View instance for a specified type of instances passing a ViewModel and a VCProvider)
    class function CreateViewFor<T>(const AVVMAlias:String; const AVCProvider:TioViewContextProvider; const AViewModel:IioViewModel; const AParams:TioConstructorParams=nil): TComponent; overload;
    class function CreateViewFor<T>(const AVCProvider:TioViewContextProvider; const AViewModel:IioViewModel; const AParams:TioConstructorParams=nil): TComponent; overload;
    // Create View instance for a specified type of instances passing a ViewModel and an already created ViewContext
    class function CreateViewFor<T>(const AVVMAlias:String; const AViewContext:TComponent; const AViewModel:IioViewModel; const AParams:TioConstructorParams=nil): TComponent; overload;
    class function CreateViewFor<T>(const AViewContext:TComponent; const AViewModel:IioViewModel; const AParams:TioConstructorParams=nil): TComponent; overload;

    // Create ViewModel instance
    class function CreateViewModel<T:IioViewModel>(const AAlias:String=''; const AParams: TioConstructorParams=nil): T; overload;
    class function CreateViewModel<T:IioViewModel>(const AParams:TioConstructorParams): T; overload;
    // Create ViewModel instance for a specified type of instances
    class function CreateViewModelFor<T>(const AAlias:String=''; const AParams: TioConstructorParams=nil): IioViewModel; overload;
    class function CreateViewModelFor<T>(const AParams: TioConstructorParams): IioViewModel; overload;

    // Create View & ViewModel coupled instances
    class procedure CreateViewViewModel<TView:IInterface; TViewModel:IioViewModel>(const AAlias:String=''; const AVCProviderName:String=''); overload;
    // Create View & ViewModel coupled instances passing a ViewContextProvider
    class procedure CreateViewViewModel<TView:IInterface; TViewModel:IioViewModel>(const AVCProvider:TioViewContextProvider); overload;
    class procedure CreateViewViewModel<TView:IInterface; TViewModel:IioViewModel>(const AAlias:String; const AVCProvider:TioViewContextProvider); overload;
    // Create View & ViewModel coupled instances passing an already created ViewContext
    class procedure CreateViewViewModel<TView:IInterface; TViewModel:IioViewModel>(const AViewContext:TComponent); overload;
    class procedure CreateViewViewModel<TView:IInterface; TViewModel:IioViewModel>(const AAlias:String; const AViewContext:TComponent); overload;

    // Create View & ViewModel instance for a specified type of instances
    class procedure CreateViewViewModelFor<T>(const AVVMAlias:String=''; const AVCProviderName:String=''); overload;
    class procedure CreateViewViewModelFor<T>(const AVCProvider:TioViewContextProvider; const AVVMAlias:String=''); overload;
    class procedure CreateViewViewModelFor<T>(const AViewContext:TComponent; const AVVMAlias:String=''); overload;

    // Show instance as TObject (even passing ViewContextProvider or an already created ViewContext)
    class procedure Show(const ATargetObj:TObject; const AVVMAlias:String=''; const AVCProviderName:String=''); overload;
    class procedure Show(const ATargetObj:TObject; const AVCProvider:TioViewContextProvider; const AVVMAlias:String=''); overload;
    class procedure Show(const ATargetObj:TObject; const AViewContext:TComponent; const AVVMAlias:String=''); overload;
    // Show instance as IInterface (even passing ViewContextProvider or an already created ViewContext)
    class procedure Show(const ATargetIntf:IInterface; const AVVMAlias:String=''; const AVCProviderName:String=''); overload;
    class procedure Show(const ATargetIntf:IInterface; const AVCProvider:TioViewContextProvider; const AVVMAlias:String=''); overload;
    class procedure Show(const ATargetIntf:IInterface; const AViewContext:TComponent; const AVVMAlias:String=''); overload;
    // Show instance of generic type <T> (even passing ViewContextProvider or an already created ViewContext)
    class procedure Show<T>(const AVVMAlias:String=''; const AVCProviderName:String=''); overload;
    class procedure Show<T>(const AVCProvider:TioViewContextProvider; const AVVMAlias:String=''); overload;
    class procedure Show<T>(const AViewContext:TComponent; const AVVMAlias:String=''); overload;

    // Show current record/instance of a ModelPresenter (even passing ViewContextProvider or an already created ViewContext)
    class procedure ShowCurrent(const AModelPresenter:TioModelPresenter; const AVVMAlias:String=''; const AVCProviderName:String=''); overload;
    class procedure ShowCurrent(const AModelPresenter:TioModelPresenter; const AVCProvider:TioViewContextProvider; const AVVMAlias:String=''); overload;
    class procedure ShowCurrent(const AModelPresenter:TioModelPresenter; const AViewContext:TComponent; const AVVMAlias:String=''); overload;

    // Show each record/instance of a ModelPresenter (even passing ViewContextProvider or an already created ViewContext)
    class procedure ShowEach(const AModelPresenter:TioModelPresenter; const AVVMAlias:String=''; const AVCProviderName:String=''); overload;
    class procedure ShowEach(const AModelPresenter:TioModelPresenter; const AVCProvider:TioViewContextProvider; const AVVMAlias:String=''); overload;
    class procedure ShowEach(const AModelPresenter:TioModelPresenter; const AViewContext:TComponent; const AVVMAlias:String=''); overload;

    // Show selector
    class procedure ShowAsSelector(const ATargetMP:TioModelPresenter; const AVVMAlias:String=''; const AVCProviderName:String=''); overload;
    class procedure ShowAsSelector(const ATargetMP:TioModelPresenter; const AVCProvider:TioViewContextProvider; const AVVMAlias:String=''); overload;
    class procedure ShowAsSelector(const ATargetMP:TioModelPresenter; const AViewContext:TComponent; const AVVMAlias:String=''); overload;
    // Show selector (Generic version)
    class procedure ShowAsSelector<T>(const ATargetMP:TioModelPresenter; const AVVMAlias:String=''; const AVCProviderName:String=''); overload;
    class procedure ShowAsSelector<T>(const ATargetMP:TioModelPresenter; const AVCProvider:TioViewContextProvider; const AVVMAlias:String=''); overload;
    class procedure ShowAsSelector<T>(const ATargetMP:TioModelPresenter; const AViewContext:TComponent; const AVVMAlias:String=''); overload;
  end;

implementation

uses
  iORM.DuckTyped.Interfaces,
  iORM.DuckTyped.Factory,
  iORM.DuckTyped.StreamObject,
  iORM.Attributes,
  iORM.Exceptions,
  iORM.DB.Factory,
  iORM.DB.DBCreator.Factory, iORM.Rtti.Utilities, iORM.Strategy.Factory,
  iORM.Context.Container, iORM.AbstractionLayer.Framework;


{ io }

class function io.Load(const ATypeName, ATypeAlias: String): IioWhere;
begin
  Result := TioWhereFactory.NewWhere;
  Result.TypeName := ATypeName;
  Result.TypeAlias := ATypeAlias;
  Result.TypeInfo := nil;
end;

class function io.Load(const AWhere: IioWhere): IioWhere;
begin
  Result := AWhere;
end;

class function io.Load(const AIID: TGUID; const ATypeAlias: String): IioWhere;
begin
  Result := Self.Load(TioRttiUtilities.GUIDtoTypeInfo(AIID), ATypeAlias);
end;

class function io.Load<T>(const ATypeAlias:String): IioWhere<T>;
begin
  Result := TioWhereFactory.NewWhere<T>;
  Result.TypeName := TioRttiUtilities.GenericToString<T>;
  Result.TypeAlias := ATypeAlias;
  Result.TypeInfo := TypeInfo(T);
end;

class function io.Where: IioWhere;
begin
  Result := TioWhereFactory.NewWhere;
end;

class function io.Where(const ATextCondition: String): IioWhere;
begin
  Result := Self.Where.Add(ATextCondition);
end;

class function io.Where<T>(const ATextCondition: String): IioWhere<T>;
begin
  Result := Self.Where<T>.Add(ATextCondition);
end;

class function io.Where<T>: IioWhere<T>;
begin
  Result := TioWhereFactory.NewWhere<T>;
end;

class function io.Mapper: omRef;
begin
  Result := ObjMapper.om;
end;

class procedure io.Persist(const AObj: TObject; const ARelationPropertyName:String; const ARelationOID:Integer; const ABlindInsert:Boolean; const AConnectionName:String);
begin
  // Get the strategy and call the proper funtionality
  TioStrategyFactory.GetStrategy(AConnectionName).PersistObject(AObj, ARelationPropertyName, ARelationOID, ABlindInsert, AConnectionName);
end;

class procedure io.Persist(const AIntfObj: IInterface; const ABlindInsert:Boolean);
begin
  Self.Persist(AIntfObj as TObject, ABlindInsert);
end;

class procedure io.PersistCollection(const ACollection: TObject; const ABlindInsert:Boolean);
begin
  // Redirect to the internal PersistCollection_Internal (same of PersistRelationChildList)
  TioStrategyFactory.GetStrategy('').PersistCollection(ACollection, '', 0, ABlindInsert, '');
end;

class procedure io.Persist(const AObj: TObject;
  const ABlindInsert: Boolean);
begin
  Self.Persist(AObj, '', 0, ABlindInsert, '');
end;

class procedure io.Persist(const AObj: TObject; const AConnectionName: String;
  const ABlindInsert: Boolean);
begin
  Self.Persist(AObj, '', 0, ABlindInsert, AConnectionName);
end;

class procedure io.Persist(const AIntfObj: IInterface;
  const AConnectionName: String; const ABlindInsert: Boolean);
begin
  Self.Persist(AIntfObj as TObject, AConnectionName, ABlindInsert);
end;

class procedure io.PersistCollection(const AIntfCollection: IInterface; const ABlindInsert:Boolean);
begin
  Self.PersistCollection(AIntfCollection as TObject, ABlindInsert);
end;

class procedure io.PersistCollection(const ACollection: TObject;
  const AConnectionName: String; const ABlindInsert: Boolean);
begin
  // Redirect to the internal PersistCollection_Internal (same of PersistRelationChildList)
  TioStrategyFactory.GetStrategy('').PersistCollection(ACollection, '', 0, ABlindInsert, AConnectionName);
end;

class function io.RefTo(const AClassRef: TioClassRef; const ATypeAlias:String=''): IioWhere;
begin
  Result := Self.Load(AClassRef, ATypeAlias);
end;

class function io.RefTo(const ATypeName, ATypeAlias: String): IioWhere;
begin
  Result := Self.Load(ATypeName, ATypeAlias);
end;

class function io.RefTo<T>(const ATypeAlias:String=''): IioWhere<T>;
begin
  Result := Self.Load<T>(ATypeAlias);
end;

class procedure io.RollbackTransaction(const AConnectionName:String);
begin
  TioStrategyFactory.GetStrategy(AConnectionName).RollbackTransaction(AConnectionName);
end;

class function io.SQL(const ASQL: String): IioSQLDestination;
begin
  Result := TioDBFactory.SQLDestination(ASQL);
end;

class procedure io.SetWaitProc(const AShowWaitProc: TProc;
  const AHideWaitProc: TProc);
begin
  TioConnectionManager.SetShowHideWaitProc(AShowWaitProc, AHideWaitProc);
end;

class procedure io.Show(const ATargetObj: TObject; const AViewContext: TComponent; const AVVMAlias: String);
begin
  di.LocateViewVMfor(ATargetObj, AVVMAlias).SetViewContext(AViewContext).Show;
end;

class procedure io.Show(const ATargetObj: TObject; const AVCProvider: TioViewContextProvider; const AVVMAlias: String);
begin
  di.LocateViewVMfor(ATargetObj, AVVMAlias).VCProvider(AVCProvider).Show;
end;

class procedure io.Show(const ATargetObj: TObject; const AVVMAlias: String; const AVCProviderName:String);
begin
  di.LocateViewVMfor(ATargetObj, AVVMAlias).VCProvider(AVCProviderName).Show;
end;

class procedure io.Show(const ATargetIntf: IInterface; const AViewContext: TComponent; const AVVMAlias: String);
begin
  di.LocateViewVMfor(ATargetIntf, AVVMAlias).SetViewContext(AViewContext).Show;
end;

class procedure io.Show<T>(const AVVMAlias: String; const AVCProviderName:String);
begin
  di.LocateViewVMfor<T>(AVVMAlias).VCProvider(AVCProviderName).Show;
end;

class procedure io.Show<T>(const AVCProvider: TioViewContextProvider; const AVVMAlias: String);
begin
  di.LocateViewVMfor<T>(AVVMAlias).VCProvider(AVCProvider).Show;
end;

class procedure io.Show<T>(const AViewContext: TComponent; const AVVMAlias: String);
begin
  di.LocateViewVMfor<T>(AVVMAlias).SetViewContext(AViewContext).Show;
end;

class procedure io.Show(const ATargetIntf: IInterface; const AVCProvider: TioViewContextProvider; const AVVMAlias: String);
begin
  di.LocateViewVMfor(ATargetIntf, AVVMAlias).VCProvider(AVCProvider).Show;
end;

class procedure io.Show(const ATargetIntf: IInterface; const AVVMAlias: String; const AVCProviderName:String);
begin
  di.LocateViewVMfor(ATargetIntf, AVVMAlias).VCProvider(AVCProviderName).Show;
end;

class procedure io.ShowCurrent(const AModelPresenter: TioModelPresenter; const AViewContext: TComponent; const AVVMAlias: String);
begin
  if TioModelPresenter.IsValidForDependencyInjectionLocator(AModelPresenter, True, False) then
    TioDependencyInjectionFactory.GetViewVMLocatorFor(AModelPresenter, AVVMAlias, False).SetViewContext(AViewContext).ShowCurrent;
end;

class procedure io.ShowCurrent(const AModelPresenter: TioModelPresenter; const AVCProvider: TioViewContextProvider;
  const AVVMAlias: String);
begin
  if TioModelPresenter.IsValidForDependencyInjectionLocator(AModelPresenter, True, False) then
    TioDependencyInjectionFactory.GetViewVMLocatorFor(AModelPresenter, AVVMAlias, False).VCProvider(AVCProvider).ShowCurrent;
end;

class procedure io.ShowCurrent(const AModelPresenter: TioModelPresenter; const AVVMAlias: String; const AVCProviderName:String);
begin
  if TioModelPresenter.IsValidForDependencyInjectionLocator(AModelPresenter, True, False) then
    TioDependencyInjectionFactory.GetViewVMLocatorFor(AModelPresenter, AVVMAlias, False).VCProvider(AVCProviderName).ShowCurrent;
end;

class procedure io.ShowEach(const AModelPresenter: TioModelPresenter; const AViewContext: TComponent; const AVVMAlias: String);
begin
  if TioModelPresenter.IsValidForDependencyInjectionLocator(AModelPresenter, True, False) then
    TioDependencyInjectionFactory.GetViewVMLocatorFor(AModelPresenter, AVVMAlias, False).SetViewContext(AViewContext).ShowEach;
end;

class procedure io.ShowAsSelector(const ATargetMP: TioModelPresenter; const AVVMAlias, AVCProviderName: String);
begin
  if TioModelPresenter.IsValidForDependencyInjectionLocator(ATargetMP, False, False) then
    io.di.LocateViewVMfor(ATargetMP.TypeName, AVVMAlias).VCProvider(AVCProviderName).SetPresenterAsSelectorFor(ATargetMP).Get;
end;

class procedure io.ShowAsSelector(const ATargetMP: TioModelPresenter; const AVCProvider: TioViewContextProvider;
  const AVVMAlias: String);
begin
  if TioModelPresenter.IsValidForDependencyInjectionLocator(ATargetMP, False, False) then
    io.di.LocateViewVMfor(ATargetMP.TypeName, AVVMAlias).VCProvider(AVCProvider).SetPresenterAsSelectorFor(ATargetMP).Get;
end;

class procedure io.ShowAsSelector(const ATargetMP: TioModelPresenter; const AViewContext: TComponent; const AVVMAlias: String);
begin
  if TioModelPresenter.IsValidForDependencyInjectionLocator(ATargetMP, False, False) then
    io.di.LocateViewVMfor(ATargetMP.TypeName, AVVMAlias).SetViewContext(AViewContext).SetPresenterAsSelectorFor(ATargetMP).Get;
end;

class procedure io.ShowAsSelector<T>(const ATargetMP: TioModelPresenter; const AViewContext: TComponent; const AVVMAlias: String);
begin
  if TioModelPresenter.IsValidForDependencyInjectionLocator(ATargetMP, False, False) then
    io.di.LocateViewVMfor<T>(AVVMAlias).SetViewContext(AViewContext).SetPresenterAsSelectorFor(ATargetMP).Get;
end;

class procedure io.ShowAsSelector<T>(const ATargetMP: TioModelPresenter; const AVCProvider: TioViewContextProvider;
  const AVVMAlias: String);
begin
  if TioModelPresenter.IsValidForDependencyInjectionLocator(ATargetMP, False, False) then
    io.di.LocateViewVMfor<T>(AVVMAlias).VCProvider(AVCProvider).SetPresenterAsSelectorFor(ATargetMP).Get;
end;

class procedure io.ShowAsSelector<T>(const ATargetMP: TioModelPresenter; const AVVMAlias, AVCProviderName: String);
begin
  if TioModelPresenter.IsValidForDependencyInjectionLocator(ATargetMP, False, False) then
    io.di.LocateViewVMfor<T>(AVVMAlias).VCProvider(AVCProviderName).SetPresenterAsSelectorFor(ATargetMP).Get;
end;

class procedure io.ShowEach(const AModelPresenter: TioModelPresenter; const AVCProvider: TioViewContextProvider; const AVVMAlias: String);
begin
  if TioModelPresenter.IsValidForDependencyInjectionLocator(AModelPresenter, True, False) then
    TioDependencyInjectionFactory.GetViewVMLocatorFor(AModelPresenter, AVVMAlias, False).VCProvider(AVCProvider).ShowEach;
end;

class procedure io.ShowEach(const AModelPresenter: TioModelPresenter; const AVVMAlias: String; const AVCProviderName:String);
begin
  if TioModelPresenter.IsValidForDependencyInjectionLocator(AModelPresenter, True, False) then
    TioDependencyInjectionFactory.GetViewVMLocatorFor(AModelPresenter, AVVMAlias, False).VCProvider(AVCProviderName).ShowEach;
end;

class procedure io.ShowWait;
begin
  TioConnectionManager.ShowWaitProc;
end;

class function io.SQL(
  const ASQLDestination: IioSQLDestination): IioSQLDestination;
begin
  Result := ASQLDestination;
end;

class procedure io.StartTransaction(const AConnectionName:String);
begin
  TioStrategyFactory.GetStrategy(AConnectionName).StartTransaction(AConnectionName);
end;

class procedure io.AutoCreateDatabase(const AConnectionName:String; const RaiseExceptionIfNotAvailable:Boolean);
begin
  // The AutoCreateDatabase feature is available only for SQLite database
  if TioConnectionManager.GetConnectionInfo(AConnectionName).ConnectionType = cdtSQLite then
    TioDBCreatorFactory.GetDBCreator.AutoCreateDatabase
  else if RaiseExceptionIfNotAvailable then
    raise EioException.Create(ClassName + ':  "AutoCreateDatabase" feature is available for SQLite RDBMS only.');
end;

class procedure io.AutoCreateDatabase(
  const RaiseExceptionIfNotAvailable: Boolean);
begin
  AutoCreateDatabase('', RaiseExceptionIfNotAvailable);
end;

class procedure io.CommitTransaction(const AConnectionName:String);
begin
  TioStrategyFactory.GetStrategy(AConnectionName).CommitTransaction(AConnectionName);
end;

class function io.Connections: TioConnectionManagerRef;
begin
  Result := Self.GlobalFactory.DBFactory.ConnectionManager;
end;

class function io.Create<T>(const ATypeAlias: String; const AParams: TioConstructorParams): T;
begin
  Result := di.Locate<T>(ATypeAlias).ConstructorParams(AParams).Get;
end;

class function io.CreateView<T>(const AViewContext: TComponent; const AParams: TioConstructorParams): T;
begin
  Result := di.LocateView<T>.SetViewContext(AViewContext).ConstructorParams(AParams).Get;
end;

class function io.CreateView<T>(const ATypeAlias: String; const AViewContext: TComponent; const AParams: TioConstructorParams): T;
begin
  Result := di.LocateView<T>(ATypeAlias).SetViewContext(AViewContext).ConstructorParams(AParams).Get;
end;

class function io.CreateView<T>(const AViewModel: IioViewModel; const AParams: TioConstructorParams): T;
begin
  Result := di.LocateView<T>.SetViewModel(AViewModel).ConstructorParams(AParams).Get;
end;

class function io.CreateView<T>(const ATypeAlias: String; const AVCProvider: TioViewContextProvider;
  const AParams: TioConstructorParams): T;
begin
  Result := di.LocateView<T>(ATypeAlias).VCProvider(AVCProvider).ConstructorParams(AParams).Get;
end;

class function io.CreateView<T>(const ATypeAlias: String; const AParams: TioConstructorParams): T;
begin
  Result := di.LocateView<T>(ATypeAlias).ConstructorParams(AParams).Get;
end;

class function io.CreateView<T>(const AParams: TioConstructorParams): T;
begin
  Result := di.LocateView<T>.ConstructorParams(AParams).Get;
end;

class function io.CreateView<T>(const AVCProvider: TioViewContextProvider; const AParams: TioConstructorParams): T;
begin
  Result := di.LocateView<T>.VCProvider(AVCProvider).ConstructorParams(AParams).Get;
end;

class function io.CreateView<T>(const AViewContext: TComponent; const AViewModel: IioViewModel; const AParams: TioConstructorParams): T;
begin
  Result := di.LocateView<T>.SetViewContext(AViewContext).SetViewModel(AViewModel).ConstructorParams(AParams).Get;
end;

class function io.CreateView<T>(const ATypeAlias: String; const AViewContext: TComponent; const AViewModel: IioViewModel;
  const AParams: TioConstructorParams): T;
begin
  Result := di.LocateView<T>(ATypeAlias).SetViewContext(AViewContext).SetViewModel(AViewModel).ConstructorParams(AParams).Get;
end;

class function io.CreateViewFor<T>(const AVVMAlias: String; const AVCProvider: TioViewContextProvider;
  const AParams: TioConstructorParams): TComponent;
begin
  Result := io.di.LocateViewFor<T>(AVVMAlias).ConstructorParams(AParams).VCProvider(AVCProvider).GetAsGeneric.OfType<TComponent>;
end;

class function io.CreateViewFor<T>(const AViewContext: TComponent; const AParams: TioConstructorParams): TComponent;
begin
  Result := io.di.LocateViewFor<T>.ConstructorParams(AParams).SetViewContext(AViewContext).GetAsGeneric.OfType<TComponent>;
end;

class function io.CreateViewFor<T>(const AVVMAlias: String; const AViewContext: TComponent;
  const AParams: TioConstructorParams): TComponent;
begin
  Result := io.di.LocateViewFor<T>(AVVMAlias).ConstructorParams(AParams).SetViewContext(AViewContext).GetAsGeneric.OfType<TComponent>;
end;

class function io.CreateViewFor<T>(const AVVMAlias: String; const AParams: TioConstructorParams): TComponent;
begin
  Result := io.di.LocateViewFor<T>(AVVMAlias).ConstructorParams(AParams).GetAsGeneric.OfType<TComponent>;
end;

class function io.CreateViewFor<T>(const AParams: TioConstructorParams): TComponent;
begin
  Result := io.di.LocateViewFor<T>.ConstructorParams(AParams).GetAsGeneric.OfType<TComponent>;
end;

class function io.CreateViewFor<T>(const AVCProvider: TioViewContextProvider; const AParams: TioConstructorParams): TComponent;
begin
  Result := io.di.LocateViewFor<T>.ConstructorParams(AParams).VCProvider(AVCProvider).GetAsGeneric.OfType<TComponent>;
end;

class function io.CreateViewFor<T>(const AVVMAlias: String; const AVCProvider: TioViewContextProvider; const AViewModel: IioViewModel;
  const AParams: TioConstructorParams): TComponent;
begin
  Result := io.di.LocateViewFor<T>(AVVMAlias).ConstructorParams(AParams).VCProvider(AVCProvider).SetViewModel(AViewModel).GetAsGeneric.OfType<TComponent>;
end;

class function io.CreateViewFor<T>(const AViewContext: TComponent; const AViewModel: IioViewModel;
  const AParams: TioConstructorParams): TComponent;
begin
  Result := io.di.LocateViewFor<T>.ConstructorParams(AParams).SetViewContext(AViewContext).SetViewModel(AViewModel).GetAsGeneric.OfType<TComponent>;
end;

class function io.CreateViewFor<T>(const AVVMAlias: String; const AViewContext: TComponent; const AViewModel: IioViewModel;
  const AParams: TioConstructorParams): TComponent;
begin
  Result := io.di.LocateViewFor<T>(AVVMAlias).ConstructorParams(AParams).SetViewContext(AViewContext).SetViewModel(AViewModel).GetAsGeneric.OfType<TComponent>;
end;

class function io.CreateViewFor<T>(const AViewModel: IioViewModel; const AParams: TioConstructorParams): TComponent;
begin
  Result := io.di.LocateViewFor<T>.ConstructorParams(AParams).SetViewModel(AViewModel).GetAsGeneric.OfType<TComponent>;
end;

class function io.CreateViewFor<T>(const AVVMAlias: String; const AViewModel: IioViewModel;
  const AParams: TioConstructorParams): TComponent;
begin
  Result := io.di.LocateViewFor<T>(AVVMAlias).ConstructorParams(AParams).SetViewModel(AViewModel).GetAsGeneric.OfType<TComponent>;
end;

class function io.CreateViewFor<T>(const AVCProvider: TioViewContextProvider; const AViewModel: IioViewModel;
  const AParams: TioConstructorParams): TComponent;
begin
  Result := io.di.LocateViewFor<T>.ConstructorParams(AParams).VCProvider(AVCProvider).SetViewModel(AViewModel).GetAsGeneric.OfType<TComponent>;
end;

class function io.CreateViewModelFor<T>(const AAlias: String; const AParams: TioConstructorParams): IioViewModel;
begin
  Result := io.di.LocateVMfor<T>(AAlias).ConstructorParams(AParams).GetAsGeneric.OfType<IioViewModel>;
end;

class function io.CreateViewModelFor<T>(const AParams: TioConstructorParams): IioViewModel;
begin
  Result := io.di.LocateVMfor<T>.ConstructorParams(AParams).GetAsGeneric.OfType<IioViewModel>;
end;

class function io.CreateView<T>(const ATypeAlias: String; const AVCProvider: TioViewContextProvider; const AViewModel: IioViewModel;
  const AParams: TioConstructorParams): T;
begin
  Result := di.LocateView<T>(ATypeAlias).VCProvider(AVCProvider).SetViewModel(AViewModel).ConstructorParams(AParams).Get;
end;

class function io.CreateView<T>(const ATypeAlias: String; const AViewModel: IioViewModel; const AParams: TioConstructorParams): T;
begin
  Result := di.LocateView<T>(ATypeAlias).SetViewModel(AViewModel).ConstructorParams(AParams).Get;
end;

class function io.CreateView<T>(const AVCProvider: TioViewContextProvider; const AViewModel: IioViewModel;
  const AParams: TioConstructorParams): T;
begin
  Result := di.LocateView<T>.VCProvider(AVCProvider).SetViewModel(AViewModel).ConstructorParams(AParams).Get;
end;

class procedure io.CreateViewViewModel<TView, TViewModel>(const AAlias: String; const AVCProvider: TioViewContextProvider);
begin
  di.LocateViewVM<TView,TViewModel>(AAlias, AAlias).VCProvider(AVCProvider).Show;
end;

class procedure io.CreateViewViewModel<TView, TViewModel>(const AAlias: String; const AVCProviderName:String);
begin
  di.LocateViewVM<TView,TViewModel>(AAlias, AAlias).VCProvider(AVCProviderName).Show;
end;

class procedure io.CreateViewViewModel<TView, TViewModel>(const AVCProvider: TioViewContextProvider);
begin
  di.LocateViewVM<TView,TViewModel>.VCProvider(AVCProvider).Show;
end;

class procedure io.CreateViewViewModel<TView, TViewModel>(const AViewContext: TComponent);
begin
  di.LocateViewVM<TView,TViewModel>.SetViewContext(AViewContext).Show;
end;

class procedure io.CreateViewViewModel<TView, TViewModel>(const AAlias: String; const AViewContext: TComponent);
begin
  di.LocateViewVM<TView,TViewModel>(AAlias, AAlias).SetViewContext(AViewContext).Show;
end;

class procedure io.CreateViewViewModelFor<T>(const AVVMAlias: String; const AVCProviderName:String);
begin
  Self.Show<T>(AVVMAlias, AVCProviderName);
end;

class procedure io.CreateViewViewModelFor<T>(const AVCProvider: TioViewContextProvider; const AVVMAlias: String);
begin
  Self.Show<T>(AVCProvider, AVVMAlias);
end;

class procedure io.CreateViewViewModelFor<T>(const AViewContext: TComponent; const AVVMAlias: String);
begin
  Self.Show<T>(AViewContext, AVVMAlias);
end;

class function io.CreateViewModel<T>(const AParams: TioConstructorParams): T;
begin
  Result := di.LocateVM<T>.ConstructorParams(AParams).Get;
end;

class function io.CreateViewModel<T>(const AAlias: String; const AParams: TioConstructorParams): T;
begin
  Result := di.LocateVM<T>(AAlias).ConstructorParams(AParams).Get;
end;

class function io.Create<T>(const AParams: TioConstructorParams): T;
begin
  Result := di.Locate<T>.ConstructorParams(AParams).Get;
end;

class procedure io.Delete(const AObj: TObject; const AConnectionName:String='');
begin
  TioStrategyFactory.GetStrategy(AConnectionName).DeleteObject(AObj, AConnectionName);
end;

class procedure io.Delete(const AIntfObj: IInterface; const AConnectionName:String='');
begin
  Self.Delete(AIntfObj as TObject, AConnectionName);
end;

class function io.di: TioDependencyInjectionRef;
begin
  Result := TioDependencyInjection;
end;

class function io.GlobalFactory: TioGlobalFactoryRef;
begin
  Result := TioGlobalFactory;
end;

class procedure io.HandleException(Sender: TObject);
begin
  TioApplication.HandleException(Sender);
end;

class procedure io.HideWait;
begin
  TioConnectionManager.HideWaitProc;
end;

class function io.Load(const AClassRef:TioClassRef; const ATypeAlias:String): IioWhere;
begin
  Result := Self.Load(AClassref.ClassInfo, ATypeAlias);
end;

class function io.Load(const ATypeInfo: PTypeInfo;
  const ATypeAlias: String): IioWhere;
begin
  Result := TioWhereFactory.NewWhere;
  Result.TypeName := TioRttiUtilities.TypeInfoToTypeName(ATypeInfo);
  Result.TypeAlias := ATypeAlias;
  Result.TypeInfo := ATypeInfo;
end;

class procedure io.PersistCollection(const AIntfCollection: IInterface;
  const AConnectionName: String; const ABlindInsert: Boolean);
begin
  Self.PersistCollection(AIntfCollection as TObject, AConnectionName, ABlindInsert);
end;

class procedure io.PersistCollection(const ACollection: TObject; const ARelationPropertyName: String; const ARelationOID: Integer;
  const ABlindInsert: Boolean; const AConnectionName: String);
begin
  // Redirect to the internal PersistCollection_Internal (same of PersistRelationChildList)
  TioStrategyFactory.GetStrategy(AConnectionName).PersistCollection(ACollection, ARelationPropertyName, ARelationOID, ABlindInsert, AConnectionName);
end;

class function io.TerminateApplication: Boolean;
begin
  Result := TioApplication.Terminate;
end;

class function io.RefTo(const AWhere: IioWhere): IioWhere;
begin
  Result := Self.Load(AWhere);
end;


initialization

  // Initialize the dependency injection container
  TioDependencyInjectionContainer.Build;

  // Register as default DuckTypedStreamObject invoker
  //  NB: L'ho messo qui perch� altrimenti nella unit dove � dichiarata la classe non
  //       venive eseguito
  io.di.RegisterClass<TioDuckTypedStreamObject>
                        .Implements<IioDuckTypedStreamObject>
                        .DisableMapImplemetersRef  // Evita un AV error probabilmente causato dal fatto che i vari containers della parte ORM non sono ancora a posto
                        .Execute;

  // Create the ContextContainer Instance and Init it by loading
  //  all entities declarated in the application
  TioMapContainer.Build;

end.


















