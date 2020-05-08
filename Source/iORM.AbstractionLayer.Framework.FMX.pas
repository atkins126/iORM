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





unit iORM.AbstractionLayer.Framework.FMX;

interface

uses
  FireDAC.FMXUI.Wait, // For FireDAC compatibility without insert the original component
  iORM.AbstractionLayer.Framework, FMX.Types, System.Classes, FMX.ActnList,
  System.Rtti;

type

  TioFMX = class(TComponent)
  end;

  TioApplicationFMX = class(TioApplication)
  protected
    class procedure _HandleException(const Sender: TObject); override;
    class function _Terminate: Boolean; override;
  end;

  TioControlFMX = class(TioControl)
  protected
    class procedure _SetParent(const AControl, AParent: TObject); override;
    class procedure _SetVisible(const AControl: TObject; const AVisible: Boolean); override;
  end;

  TioTimerFMX = class(TioTimer)
  private
    FInternalTimer: TTimer;
  protected
    function GetEnabled: Boolean; override;
    function GetInterval: Cardinal; override;
    function GetOnTimer: TNotifyEvent; override;
    function GetTag: Integer; override;
    procedure SetEnabled(const Value: Boolean); override;
    procedure SetInterval(const Value: Cardinal); override;
    procedure SetOnTimer(const Value: TNotifyEvent); override;
    procedure SetTag(const Value: Integer); override;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

  TioActionFMX = class(TioAction)
  private
    FInternalAction: TAction;
  protected
    class function _CreateNewAction(const AOwner:TComponent): TioAction; override;
    class function _CreateNewAction(const AOwner:TComponent; const AAction: TObject): TioAction; override;
    class function _IsValid(const AField: TRttiField): Boolean; override;
    function GetCaption: string; override;
    function GetChecked: boolean; override;
    function GetEnabled: boolean; override;
    function GetGroupIndex: integer; override;
    function GetHint: string; override;
    function GetImageIndex: integer; override;
    function GetName: TComponentName; override;
    function GetVisible: boolean; override;
    function GetOnExecute: TNotifyEvent; override;
    function GetOnHint: THintEvent; override;
    function GetOnUpdate: TNotifyEvent; override;
    procedure SetCaption(const Value: string); override;
    procedure SetChecked(const Value: boolean); override;
    procedure SetEnabled(const Value: boolean); override;
    procedure SetGroupIndex(const Value: integer); override;
    procedure SetHint(const Value: string); override;
    procedure SetImageIndex(const Value: integer); override;
    procedure SetName(const Value: TComponentName); override;
    procedure SetVisible(const Value: boolean); override;
    procedure SetOnExecute(const Value: TNotifyEvent); override;
    procedure SetOnHint(const Value: THintEvent); override;
    procedure SetOnUpdate(const Value: TNotifyEvent); override;
  public
    constructor Create(AOwner: TComponent); reintroduce; overload;
    constructor Create(AOwner: TComponent; const AAction: TObject); reintroduce; overload;
    function Execute: Boolean; override;
    function AsTValue: TValue; override;
  end;

implementation

uses
  FMX.Forms, iORM.Exceptions, FMX.Controls;

{ TioTimerFMX }

constructor TioTimerFMX.Create;
begin
  inherited;
  FInternalTimer := TTimer.Create(nil);
end;

destructor TioTimerFMX.Destroy;
begin
  FInternalTimer.Free;
  inherited;
end;

function TioTimerFMX.GetEnabled: Boolean;
begin
  Result := FInternalTimer.Enabled;
end;

function TioTimerFMX.GetInterval: Cardinal;
begin
  Result := FInternalTimer.Interval;
end;

function TioTimerFMX.GetOnTimer: TNotifyEvent;
begin
  Result := FInternalTimer.OnTimer;
end;

function TioTimerFMX.GetTag: Integer;
begin
  Result := FInternalTimer.Tag;
end;

procedure TioTimerFMX.SetEnabled(const Value: Boolean);
begin
  FInternalTimer.Enabled := Value;
end;

procedure TioTimerFMX.SetInterval(const Value: Cardinal);
begin
  FInternalTimer.Interval := Value;
end;

procedure TioTimerFMX.SetOnTimer(const Value: TNotifyEvent);
begin
  FInternalTimer.OnTimer := Value;
end;

procedure TioTimerFMX.SetTag(const Value: Integer);
begin
  FInternalTimer.Tag := Value;
end;

{ TioApplicationFMX }

class procedure TioApplicationFMX._HandleException(const Sender: TObject);
begin
  Application.HandleException(Sender);
end;

class function TioApplicationFMX._Terminate: Boolean;
begin
  Result := Application.Terminate;
end;

{ TioActionFMX }

function TioActionFMX.AsTValue: TValue;
begin
  Result := TValue.From<TAction>(FInternalAction);
end;

constructor TioActionFMX.Create(AOwner: TComponent);
begin
  inherited;
  FInternalAction := TAction.Create(AOwner);
end;


constructor TioActionFMX.Create(AOwner: TComponent; const AAction: TObject);
begin
  inherited Create(AOwner);
  FInternalAction := AAction as TAction;
end;

function TioActionFMX.Execute: Boolean;
begin
  Result := FInternalAction.Execute;
end;

function TioActionFMX.GetCaption: string;
begin
  Result := FInternalAction.Caption;
end;

function TioActionFMX.GetChecked: boolean;
begin
  Result := FInternalAction.Checked;
end;

function TioActionFMX.GetEnabled: boolean;
begin
  Result := FInternalAction.Enabled;
end;

function TioActionFMX.GetGroupIndex: integer;
begin
  Result := FInternalAction.GroupIndex;
end;

function TioActionFMX.GetHint: string;
begin
  Result := FInternalAction.Hint;
end;

function TioActionFMX.GetImageIndex: integer;
begin
  Result := FInternalAction.ImageIndex;
end;

function TioActionFMX.GetName: TComponentName;
begin
  Result := FInternalAction.Name;
end;

function TioActionFMX.GetOnExecute: TNotifyEvent;
begin
  Result := FInternalAction.OnExecute;
end;

function TioActionFMX.GetOnHint: THintEvent;
begin
  Result := FInternalAction.OnHint;
end;

function TioActionFMX.GetOnUpdate: TNotifyEvent;
begin
  Result := FInternalAction.OnUpdate;
end;

function TioActionFMX.GetVisible: boolean;
begin
  Result := FInternalAction.Visible;
end;

procedure TioActionFMX.SetCaption(const Value: string);
begin
  FInternalAction.Caption := Value;
end;

procedure TioActionFMX.SetChecked(const Value: boolean);
begin
  FInternalAction.Checked := Value;
end;

procedure TioActionFMX.SetEnabled(const Value: boolean);
begin
  FInternalAction.Enabled := Value;
end;

procedure TioActionFMX.SetGroupIndex(const Value: integer);
begin
  FInternalAction.GroupIndex := Value;
end;

procedure TioActionFMX.SetHint(const Value: string);
begin
  FInternalAction.Hint := Value;
end;

procedure TioActionFMX.SetImageIndex(const Value: integer);
begin
  FInternalAction.ImageIndex := Value;
end;

procedure TioActionFMX.SetName(const Value: TComponentName);
begin
  FInternalAction.Name := Value;
end;

procedure TioActionFMX.SetOnExecute(const Value: TNotifyEvent);
begin
  FInternalAction.OnExecute := Value;
end;

procedure TioActionFMX.SetOnHint(const Value: THintEvent);
begin
  FInternalAction.OnHint := Value;
end;

procedure TioActionFMX.SetOnUpdate(const Value: TNotifyEvent);
begin
  FInternalAction.OnUpdate := Value;
end;

procedure TioActionFMX.SetVisible(const Value: boolean);
begin
  FInternalAction.Visible := Value;
end;

class function TioActionFMX._CreateNewAction(const AOwner: TComponent): TioAction;
begin
  Result := Self.Create(AOwner);
end;

class function TioActionFMX._CreateNewAction(const AOwner: TComponent; const AAction: TObject): TioAction;
begin
  Result := Self.Create(AOwner, AAction);
end;

class function TioActionFMX._IsValid(const AField: TRttiField): Boolean;
begin
  // A Valid Field is a Field of TAction type (or derived)
  Result := AField.FieldType.IsInstance and AField.FieldType.AsInstance.MetaclassType.InheritsFrom(TAction);
end;

{ TioControlFMX }

class procedure TioControlFMX._SetParent(const AControl, AParent: TObject);
begin
  inherited;
  if not (AControl is TFmxObject) then
    raise EioException.Create(Self.ClassName, '_SetParent', 'AControl must descend from TFmxObject.');
  if not (AParent is TFmxObject) then
    raise EioException.Create(Self.ClassName, '_SetParent', 'AParent must descend from TFmxObject.');
  TFmxObject(AControl).Parent := TFmxObject(AParent);
end;

class procedure TioControlFMX._SetVisible(const AControl: TObject; const AVisible: Boolean);
begin
  inherited;
  if not (AControl is TControl) then
    raise EioException.Create(Self.ClassName, '_SetParent', 'AControl must descend from TControl.');
  TControl(AControl).Visible := AVisible;
end;

initialization

  TioApplicationFMX.SetConcreteClass(TioApplicationFMX);
  TioControlFMX.SetConcreteClass(TioControlFMX);
  TioTimerFMX.SetConcreteClass(TioTimerFMX);
  TioActionFMX.SetConcreteClass(TioActionFMX);
end.
