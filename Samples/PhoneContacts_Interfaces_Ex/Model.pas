unit Model;

interface

uses iORM.Attributes, System.Generics.Collections, Interfaces,
  iORM.Containers.Interfaces, iORM.CommonTypes, System.Rtti;

type

//{$RTTI EXPLICIT METHODS([vcPublic, vcProtected, vcPrivate])}
{$RTTI EXPLICIT METHODS([vcPublic, vcProtected])}

  [ioEntity('Phones')]
  TPhoneNumber = class(TInterfacedObject, IPhoneNumber)
  private
    FPhoneNumber: String;
    FPhoneType: String;
    FPersonID: Integer;
    FID: Integer;
  protected
    procedure SetID(AValue:Integer);
    function GetID: Integer;
    procedure SetPersonID(AValue:Integer);
    function GetPersonID: Integer;
    procedure SetPhoneType(AValue:String);
    function GetPhoneType: String;
    procedure SetPhoneNumber(AValue:String);
    function GetPhoneNumber: String;
  public
    constructor Create(NewPhoneType, NewPhoneNumber: String; NewPersonID: Integer; NewID: Integer = 0); overload;
    destructor Destroy; override;
    [ioFTDefault(0)]
    property ID: Integer read GetID write SetID;
    property PersonID:Integer read GetPersonID write SetPersonID;
    property PhoneType:String read FPhoneType write FPhoneType;
    property PhoneNumber:String read FPhoneNumber write FPhoneNumber;
  end;

  [ioEntity('Persons', ioFields), ioTrueClass]
  [ioIndex('[.LastName], [.FirstName]')]
  TPerson = class(TInterfacedObject, IPerson)
  private
    [ioFTDefault(0)]
    FID: Integer;
    FLastName: String;
    [ioFTDefault('prova_default')]
    FFirstName: String;
    FDateOfBirth: TDate;
    [ioHasMany(IPhoneNumber, 'PersonID', ioLazyLoad)]
    FPhones: IioList<IPhoneNumber>;
  protected
    procedure SetID(AValue:Integer);
    procedure SetFirstName(AValue:String);
    procedure SetLastName(AValue:String);
    procedure SetPhones(AValue:IioList<IPhoneNumber>);
    procedure SetDateOfBirth(const Value: TDate);
    function GetID: Integer;
    function GetFirstName: String;
    function GetLastName: String;
    function GetPhones: IioList<IPhoneNumber>;
    function GetFullName: String;
    function GetClassNameProp: String;
    function GetDateOfBirth: TDate;
  public
    constructor Create; overload;
    constructor Create(NewFirstName, NewLastName: String; NewDateOfBirth:TDate; NewID: Integer = 0); overload;
    property ID:Integer read GetID write SetID;
    property FirstName:String read GetFirstName write SetFirstName;
    property LastName:String read GetLastName write SetLastName;
    property Phones:IioList<IPhoneNumber> read GetPhones write SetPhones;
    property FullName:String read GetFullName;
    property ClassNameProp:String read GetClassNameProp;
    property DateOfBirth:TDate read GetDateOfBirth write SetDateOfBirth;
  end;

  [ioEntity('Persons',  ioFields), ioTrueClass]
  TEmployee = class(TPerson, IEmployee)
  private
    FBranchOffice: String;
  protected
    procedure SetBranchOffice(AValue:String);
    function GetBranchOffice: String;
  public
    constructor Create(NewFirstName, NewLastName, NewBranchOffice: String; NewDateOfBirth:TDate; NewID: Integer = 0); overload;
    property BranchOffice:String read GetBranchOffice write SetBranchOffice;
  end;

  [ioEntity('Persons',  ioFields), ioTrueClass]
  TCustomer = class(TPerson, ICustomer)
  private
    [ioIndex]
    [ioIndex(ioDescending)]
    FFidelityCardCode: String;
  protected
    procedure SetFidelityCardCode(AValue:String);
    function GetFidelityCardCode: String;
  public
    constructor Create(NewFirstName, NewLastName, NewFidelityCardCode: String; NewDateOfBirth:TDate; NewID: Integer = 0); overload;
    property FidelityCardCode:String read GetFidelityCardCode write SetFidelityCardCode;
  end;

  [ioEntity('Persons',  ioFields), ioTrueClass]
  TVipCustomer = class(TCustomer, IVipCustomer)
  private
    FVipCardCode: String;
  protected
    procedure SetVipCardCode(AValue:String);
    function GetVipCardCode: String;
  public
    constructor Create(NewFirstName, NewLastName, NewFidelityCardCode, NewVipCardCode: String; NewDateOfBirth:TDate; NewID: Integer = 0); overload;
    property VipCardCode:String read GetVipCardCode write SetVipCardCode;
  end;

implementation

uses
  System.SysUtils, iORM.Containers.Factory, iORM;

{ TPerson }

constructor TPerson.Create(NewFirstName, NewLastName: String; NewDateOfBirth:TDate; NewID: Integer);
begin
  Self.Create;
  FID := NewID;
  FFirstName := NewFirstName;
  FLastName := NewLastName;
  FDateOfBirth := NewDateOfBirth;
end;

constructor TPerson.Create;
begin
  inherited;
  FPhones := io.di.Locate<IioList<IPhoneNumber>>.Get;
end;

function TPerson.GetClassNameProp: String;
begin
  Result := Self.ClassName;
end;

function TPerson.GetDateOfBirth: TDate;
begin
  Result := FDateOfBirth;
end;

function TPerson.GetFirstName: String;
begin
  Result := FFirstName;
end;

function TPerson.GetFullName: String;
begin
 Result := (FirstName + ' ' + LastName).Trim;
end;

function TPerson.GetID: Integer;
begin
  Result := FID;
end;

function TPerson.GetLastName: String;
begin
  Result := FLastName;
end;

function TPerson.GetPhones: IioList<IPhoneNumber>;
begin
  Result := FPhones;
end;

procedure TPerson.SetDateOfBirth(const Value: TDate);
begin
  FDateOfBirth := Value;
end;

procedure TPerson.SetFirstName(AValue: String);
begin
  FFirstName := AValue;
end;

procedure TPerson.SetID(AValue: Integer);
begin
  FID := AValue;
end;

procedure TPerson.SetLastName(AValue: String);
begin
  FLastName := AValue;
end;

procedure TPerson.SetPhones(AValue: IioList<IPhoneNumber>);
begin
  FPhones := AValue;
end;

{ TEmployee }

constructor TEmployee.Create(NewFirstName, NewLastName, NewBranchOffice: String;
  NewDateOfBirth:TDate; NewID: Integer);
begin
  inherited Create(NewFirstName, NewLastName, NewDateOfBirth);
  FBranchOffice := NewBranchOffice;
end;

function TEmployee.GetBranchOffice: String;
begin
  result := FBranchOffice;
end;

procedure TEmployee.SetBranchOffice(AValue: String);
begin
  FBranchOffice := AValue;
end;

{ TCustomer }

constructor TCustomer.Create(NewFirstName, NewLastName,
  NewFidelityCardCode: String; NewDateOfBirth:TDate; NewID: Integer);
begin
  inherited Create(NewFirstName, NewLastName, NewDateOfBirth);
  FFidelityCardCode := NewFidelityCardCode;
end;

function TCustomer.GetFidelityCardCode: String;
begin
  Result := FFidelityCardCode;
end;

procedure TCustomer.SetFidelityCardCode(AValue: String);
begin
  FFidelityCardCode := AValue;
end;

{ TVipCustomer }

constructor TVipCustomer.Create(NewFirstName, NewLastName,
  NewFidelityCardCode, NewVipCardCode: String; NewDateOfBirth:TDate; NewID: Integer);
begin
  inherited Create(NewFirstName, NewLastName, NewFidelityCardCode, NewDateOfBirth);
  FVipCardCode := NewVipCardCode;
end;

{ TPhoneNumbers }

constructor TPhoneNumber.Create(NewPhoneType, NewPhoneNumber: String;
  NewPersonID, NewID: Integer);
begin
  inherited Create;
  FPersonID := NewPersonID;
  FPhoneType := NewPhoneType;
  FPhoneNumber := NewPhoneNumber;
end;


function TVipCustomer.GetVipCardCode: String;
begin
  Result := FVipCardCode;
end;

procedure TVipCustomer.SetVipCardCode(AValue: String);
begin
  FVipCardCode := AValue;
end;

destructor TPhoneNumber.Destroy;
begin

  inherited;
end;

function TPhoneNumber.GetID: Integer;
begin
  Result := FID;
end;

function TPhoneNumber.GetPersonID: Integer;
begin
  Result := FPersonID;
end;

function TPhoneNumber.GetPhoneNumber: String;
begin
  Result := FPhoneNumber;
end;

function TPhoneNumber.GetPhoneType: String;
begin
  Result := FPhoneType;
end;

procedure TPhoneNumber.SetID(AValue: Integer);
begin
  FID := AValue;
end;

procedure TPhoneNumber.SetPersonID(AValue: Integer);
begin
  FPersonID := AValue;
end;

procedure TPhoneNumber.SetPhoneNumber(AValue: String);
begin
  FPhoneNumber := AValue;
end;

procedure TPhoneNumber.SetPhoneType(AValue: String);
begin
  FPhoneType := AValue;
end;

end.
