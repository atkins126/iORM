unit iORM.LiveBindings.CommonBSAPersistence;

interface

uses
  iORM.LiveBindings.Interfaces;

type

  TioCommonBSAPersistenceThreadExecute = reference to function: TObject;
  TioCommonBSAPersistenceThreadOnTerminate = reference to procedure(AResultValue: TObject);

  TioCommonBSAPersistence = class
  private
    class procedure SyncExecute(AExecuteFunc:TioCommonBSAPersistenceThreadExecute; AOnTerminateProc:TioCommonBSAPersistenceThreadOnTerminate); static;
    class procedure AsyncExecute(AExecuteFunc:TioCommonBSAPersistenceThreadExecute; AOnTerminateProc:TioCommonBSAPersistenceThreadOnTerminate); static;
  public
    class procedure Load(const AActiveBindSourceAdapter:IioActiveBindSourceAdapter); static;
    class procedure Delete(const AActiveBindSourceAdapter:IioActiveBindSourceAdapter; out AAbort:Boolean); static;
    class procedure Post(const AActiveBindSourceAdapter:IioActiveBindSourceAdapter; const AForce:Boolean=False); static;
    class procedure PersistCurrent(const AActiveBindSourceAdapter:IioActiveBindSourceAdapter); static;
    class procedure PersistAll(const AActiveBindSourceAdapter:IioActiveBindSourceAdapter); static;
  end;

implementation

uses
  System.Classes, System.SysUtils, iORM.Exceptions, iORM.Where.Interfaces,
  iORM, iORM.CommonTypes, iORM.LiveBindings.Factory,
  iORM.Context.Properties.Interfaces, iORM.Context.Factory,
  Data.Bind.ObjectScope;

type

  TioCommonBSAPersistenceThread = class(TThread)
  strict private
    FExceptionText: String;
    FExecuteFunc: TioCommonBSAPersistenceThreadExecute;
    FOnTerminateProc: TioCommonBSAPersistenceThreadOnTerminate;
    FResultValue: TObject;
  strict protected
    procedure Execute; override;
    procedure OnTerminateEventHandler(Sender: TObject);
  public
    constructor Create(AExecuteFunc:TioCommonBSAPersistenceThreadExecute;
      AOnTerminateProc:TioCommonBSAPersistenceThreadOnTerminate); overload;
    function ResultValue: TObject;
  end;

{ TioCommonBSAPersistence }

class procedure TioCommonBSAPersistence.AsyncExecute(
  AExecuteFunc: TioCommonBSAPersistenceThreadExecute;
  AOnTerminateProc: TioCommonBSAPersistenceThreadOnTerminate);
begin
  io.ShowWait;
  // Create and execute the thread
  TioCommonBSAPersistenceThread.Create(AExecuteFunc, AOnTerminateProc).Start;
end;

class procedure TioCommonBSAPersistence.Delete(const AActiveBindSourceAdapter: IioActiveBindSourceAdapter; out AAbort:Boolean);
var
  LExecute: TioCommonBSAPersistenceThreadExecute;
  LOnTerminate: TioCommonBSAPersistenceThreadOnTerminate;
  LResultValue: TObject;
begin
  // Init
{ TODO : Abort da eliminare??? }
//  AAbort := False;
  // ----------------------- SET ANONIMOUS METHODS -----------------------------
  // Set Execute anonimous methods
  LResultValue := nil;
  LExecute := function: TObject
  begin
    io.Delete(AActiveBindSourceAdapter.Current);
  end;
  // Set the OnTerminate anonimous method
  LOnTerminate := procedure(AResultValue: TObject)
  begin
    // DataSet synchro
    AActiveBindSourceAdapter.GetDataSetLinkContainer.Refresh;
    // Send a notification to other ActiveBindSourceAdapters & BindSource
    //  NB: Moved into "CommonBSAPersistence" (Delete, LOnTerminate)
    //       if FAutoPersist is True then the notify is performed by
    //       the "CommonBSAPersistence" else by this method
    AActiveBindSourceAdapter.Notify(
      AActiveBindSourceAdapter as TObject,
      TioLiveBindingsFactory.Notification(AActiveBindSourceAdapter as TObject, AActiveBindSourceAdapter.Current, ntAfterDelete)
      );
  end;
  // ----------------------- SET ANONIMOUS METHODS -----------------------------
  // Set the ObjectStatus
  AActiveBindSourceAdapter.SetObjStatus(osDeleted);
  // If AutoPersist or forced persist the delete from the DB else
  //  send a notification to other BSA.
  if AActiveBindSourceAdapter.ioAutoPersist then
  begin
    // Execute synchronous or asynchronous
    if AActiveBindSourceAdapter.ioAsync then
      AsyncExecute(LExecute, LOnTerminate)
    else
      SyncExecute(LExecute, LOnTerminate);
  end
  else
  begin
    LOnTerminate(LResultValue);
{ TODO : Abort da eliminare??? }
//    AAbort := True;
  end;
end;

class procedure TioCommonBSAPersistence.Load(
  const AActiveBindSourceAdapter: IioActiveBindSourceAdapter);
var
  LTypeName, LTypeAlias: String;
  LWhere: IioWhere;
  LTargetClass: TioClassRef;
  LOwnsObjects: Boolean;
  LExecute: TioCommonBSAPersistenceThreadExecute;
  LOnTerminate: TioCommonBSAPersistenceThreadOnTerminate;
  LConnectionName: string;
begin
  // If AutoLoadData is disabled then exit
  if not AActiveBindSourceAdapter.ioAutoLoadData then
    Exit;
  // Copy values into local variables
  LTypeName := AActiveBindSourceAdapter.ioTypeName;
  LTypeAlias := AActiveBindSourceAdapter.ioTypeAlias;

  if Assigned(AActiveBindSourceAdapter.DataObject) then
    LTargetClass := AActiveBindSourceAdapter.DataObject.ClassType;


  LWhere := AActiveBindSourceAdapter.ioWhere;
  LOwnsObjects := AActiveBindSourceAdapter.ioOwnsObjects;
  LConnectionName := AActiveBindSourceAdapter.ioConnectionName;
  // Set Execute anonimous methods
  case AActiveBindSourceAdapter.ioViewDataType of
    TioViewDataType.dtSingle:
      LExecute := function: TObject
      begin
        Result := io.Load(LTypeName, LTypeAlias)._Where(LWhere).ToObject;
      end;
    TioViewDataType.dtList:
      LExecute := function: TObject
      begin
        Result := io.Load(LTypeName, LTypeAlias)._Where(LWhere).ToList(LTargetClass);
      end;
  else
    raise EioException.Create('TioCommonBSAPersistence.Load: wrong ViewDataType.');
  end;
  // Set the OnTerminate anonimous method
  LOnTerminate := procedure(AResultValue: TObject)
  var
    LIntf: IInterface;
  begin
    if AActiveBindSourceAdapter.IsInterfaceBSA and Supports(AResultValue, IInterface, LIntf) then
      AActiveBindSourceAdapter.InternalSetDataObject(LIntf, LOwnsObjects)
    else
      AActiveBindSourceAdapter.InternalSetDataObject(AResultValue, LOwnsObjects);
  end;
  // Execute synchronous or asynchronous
  if AActiveBindSourceAdapter.ioAsync then
    AsyncExecute(LExecute, LOnTerminate)
  else
    SyncExecute(LExecute, LOnTerminate);
end;

class procedure TioCommonBSAPersistence.PersistAll(const AActiveBindSourceAdapter: IioActiveBindSourceAdapter);
var
  LMasterProperty: IioContextProperty;
  LRelationChildPropertyName: String;
  LMasterOID: Integer;
  LExecute: TioCommonBSAPersistenceThreadExecute;
  LOnTerminate: TioCommonBSAPersistenceThreadOnTerminate;
begin
  // If it's a single object then call the normal PersistCurrent method and exit
  if AActiveBindSourceAdapter.ioViewDataType = TioViewDataType.dtSingle then
  begin
    PersistCurrent(AActiveBindSourceAdapter);
    Exit;
  end;
  // if editing the post
  if AActiveBindSourceAdapter.State in seEditModes then
    AActiveBindSourceAdapter.Post;
  // Init
  LMasterProperty := nil;
  LRelationChildPropertyName := '';
  LMasterOID := 0;
  // If it is a detail adapter...
  if AActiveBindSourceAdapter.IsDetail then
  begin
    // Get the MasterProperty of the current object
    LMasterProperty := TioContextFactory.GetPropertyByClassRefAndName(
      AActiveBindSourceAdapter.GetMasterBindSourceAdapter.Current.ClassType,
      AActiveBindSourceAdapter.GetMasterPropertyName
      );
    // Get a local reference of some values
    LRelationChildPropertyName := LMasterProperty.GetRelationChildPropertyName;
    LMasterOID := AActiveBindSourceAdapter.GetMasterBindSourceAdapter.GetCurrentOID;
  end;
  // ----------------------- SET ANONIMOUS METHODS -----------------------------
  // Set Execute anonimous methods
  LExecute := function: TObject
  begin
    io.PersistCollection(AActiveBindSourceAdapter.DataObject,
      LRelationChildPropertyName,
      LMasterOID,
      False, // BlindInsert
      ''     // Connection name
      );
  end;
  // Set the OnTerminate anonimous method
  LOnTerminate := procedure(AResultValue: TObject)
  begin
    // Send a notification to other ActiveBindSourceAdapters & BindSource
    //  NB: Moved into "CommonBSAPersistence" (Delete, LOnTerminate)
    //       if FAutoPersist is True then the notify is performed by
    //       the "CommonBSAPersistence" else by this method
    AActiveBindSourceAdapter.Notify(
      AActiveBindSourceAdapter as TObject,
      TioLiveBindingsFactory.Notification(AActiveBindSourceAdapter as TObject, AActiveBindSourceAdapter.Current, ntAfterPost)
      );
  end;
  // ----------------------- SET ANONIMOUS METHODS -----------------------------
  // Execute synchronous or asynchronous
  if AActiveBindSourceAdapter.ioAsync then
    AsyncExecute(LExecute, LOnTerminate)
  else
    SyncExecute(LExecute, LOnTerminate);
end;

class procedure TioCommonBSAPersistence.PersistCurrent(const AActiveBindSourceAdapter: IioActiveBindSourceAdapter);
begin
  // If in editing then post
  //  NB: Se AutoPersist = True allora il Post gi� causa la persistenza dell'oggetto sul DB
  //       quindi esce subito perch� altrimenti si avrebbe una doppia persistenza
  if AActiveBindSourceAdapter.State in seEditModes then
  begin
    AActiveBindSourceAdapter.Post;
    if AActiveBindSourceAdapter.ioAutoPersist then
      Exit;
  end;
  // Persist
  Post(AActiveBindSourceAdapter, True);
end;

class procedure TioCommonBSAPersistence.Post(const AActiveBindSourceAdapter: IioActiveBindSourceAdapter; const AForce:Boolean);
var
  LMasterProperty: IioContextProperty;
  LRelationChildPropertyName: String;
  LMasterOID: Integer;
  LExecute: TioCommonBSAPersistenceThreadExecute;
  LOnTerminate: TioCommonBSAPersistenceThreadOnTerminate;
  LResultValue: TObject;
begin
  // Init
  LResultValue := nil;
  LMasterProperty := nil;
  LRelationChildPropertyName := '';
  LMasterOID := 0;
  // If it is a detail adapter...
  if AActiveBindSourceAdapter.IsDetail then
  begin
    // Get the MasterProperty of the current object
    LMasterProperty := TioContextFactory.GetPropertyByClassRefAndName(
      AActiveBindSourceAdapter.GetMasterBindSourceAdapter.Current.ClassType,
      AActiveBindSourceAdapter.GetMasterPropertyName
      );
    // Get a local reference of some values
    LRelationChildPropertyName := LMasterProperty.GetRelationChildPropertyName;
    LMasterOID := AActiveBindSourceAdapter.GetMasterBindSourceAdapter.GetCurrentOID;
  end;
  // ----------------------- SET ANONIMOUS METHODS -----------------------------
  // Set Execute anonimous methods
  LExecute := function: TObject
  begin
    io.Persist(AActiveBindSourceAdapter.Current,
      LRelationChildPropertyName,
      LMasterOID,
      False, // BlindInsert
      ''     // Connection name
      );
  end;
  // Set the OnTerminate anonimous method
  LOnTerminate := procedure(AResultValue: TObject)
  begin
    // Send a notification to other ActiveBindSourceAdapters & BindSource
    //  NB: Moved into "CommonBSAPersistence" (Delete, LOnTerminate)
    //       if FAutoPersist is True then the notify is performed by
    //       the "CommonBSAPersistence" else by this method
    AActiveBindSourceAdapter.Notify(
      AActiveBindSourceAdapter as TObject,
      TioLiveBindingsFactory.Notification(AActiveBindSourceAdapter as TObject, AActiveBindSourceAdapter.Current, ntAfterPost)
      );
  end;
  // ----------------------- SET ANONIMOUS METHODS -----------------------------
  // Set the ObjectStatus
  AActiveBindSourceAdapter.SetObjStatus(osDirty);
  // If AutoPersist or forced persist the persist to the DB else
  //  send a notification to other BSA.
  if AActiveBindSourceAdapter.ioAutoPersist or AForce then
  begin
    // Execute synchronous or asynchronous
    if AActiveBindSourceAdapter.ioAsync then
      AsyncExecute(LExecute, LOnTerminate)
    else
      SyncExecute(LExecute, LOnTerminate);
  end
  else
    LOnTerminate(LResultValue);
end;

class procedure TioCommonBSAPersistence.SyncExecute(
  AExecuteFunc: TioCommonBSAPersistenceThreadExecute;
  AOnTerminateProc: TioCommonBSAPersistenceThreadOnTerminate);
var
  LResultValue: TObject;
begin
  io.ShowWait;
  try
    // Execute core code
    LResultValue := AExecuteFunc;
    // Execute OnTerminate code
    if Assigned(AOnTerminateProc) then
      AOnTerminateProc(LResultValue);
  finally
    io.HideWait;
  end;
end;

{ TioCommonBSAPersistenceThread }

constructor TioCommonBSAPersistenceThread.Create(AExecuteFunc:TioCommonBSAPersistenceThreadExecute;
  AOnTerminateProc:TioCommonBSAPersistenceThreadOnTerminate);
begin
  inherited Create(True);
  FExecuteFunc := AExecuteFunc;
  FOnTerminateProc := AOnTerminateProc;
  FExceptionText := String.Empty;
  FResultValue := nil;
  Self.OnTerminate := OnTerminateEventHandler;
  Self.FreeOnTerminate := True;
end;

procedure TioCommonBSAPersistenceThread.Execute;
begin
  inherited;
  try
    FResultValue := FExecuteFunc;
  except
    on E:Exception do FExceptionText := E.Message;
  end;
end;

procedure TioCommonBSAPersistenceThread.OnTerminateEventHandler(
  Sender: TObject);
begin
  try
    if FExceptionText.IsEmpty and Assigned(FOnTerminateProc)then
      FOnTerminateProc(FResultValue)
    else
    begin
      io.HideWait;
      raise EioException.Create('(' + Self.ClassName + ') - ' + FExceptionText);
    end;
  finally
    io.HideWait;
  end;
end;

function TioCommonBSAPersistenceThread.ResultValue: TObject;
begin
  Result := FResultValue;
end;

end.
