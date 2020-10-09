unit FormStart;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.TabControl, System.Actions, FMX.ActnList,
  iORM.MVVM.Components.ViewContextProvider, iORM.DB.Components.ConnectionDef, iORM.AbstractionLayer.Framework.FMX;

type
  TForm1 = class(TForm)
    MainTabControl: TTabControl;
    SQLiteConn: TioSQLiteConnectionDef;
    TabsVCProvider: TioViewContextProvider;
    ActionList1: TActionList;
    NextTabAction1: TNextTabAction;
    PreviousTabAction1: TPreviousTabAction;
    ioFMX1: TioFMX;
    procedure TabsVCProviderioOnAfterRequest(const Sender: TObject; const AView,
      AViewContext: TComponent);
    procedure TabsVCProviderioOnRelease(const Sender: TObject; const AView,
      AViewContext: TComponent);
    procedure SQLiteConnAfterRegister(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TabsVCProviderioOnRequest(const Sender: TObject;
      out ResultViewContext: TComponent);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  SampleData, iORM, FMX.Styles, M.Interfaces;

{$R *.fmx}

procedure TForm1.FormCreate(Sender: TObject);
begin
  // Get the main view
  io.Show<IPerson>('List');
end;

procedure TForm1.SQLiteConnAfterRegister(Sender: TObject);
begin
  // Check for sample data creation
  if (Sender as TioCustomConnectionDef).DefaultConnection then
    TSampleData.CheckForSampleDataCreation;
end;

procedure TForm1.TabsVCProviderioOnAfterRequest(const Sender: TObject;
  const AView, AViewContext: TComponent);
begin
  Application.ProcessMessages;
  NextTabAction1.Execute;
end;

procedure TForm1.TabsVCProviderioOnRelease(const Sender: TObject; const AView,
  AViewContext: TComponent);
begin
  PreviousTabAction1.Execute;
  MainTabControl.Delete((AViewContext as TTabItem).Index);
end;

procedure TForm1.TabsVCProviderioOnRequest(const Sender: TObject;
  out ResultViewContext: TComponent);
begin
  ResultViewContext := MainTabControl.Add;
end;

end.
