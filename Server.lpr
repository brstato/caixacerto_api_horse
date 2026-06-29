program Server;

{$mode delphi}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, zcomponent, CustApp, Horse, urouter, uTlogincontroller,
  uloginmodel, sql_queries, uconfig, ugetdata, utokenmanager,
  uPDFService, ucacheservice, uAssistenteIaDAO, uNetService, udata,
  utlojacontroller, ulojamodel, uprofessionalcontroller, uprofissionalmodel,
  uzapmodel, ustoragetokensmodel, usitemodel, uservicemodel, urecsenhamodel,
  uagendamodel, uanamnesemodel, uAssistenteIaModel, ucaixamodel, uclientsmodel,
  umailmodel, uoauthtokenmodel, uportifoliomodel, uproductsmodel,
  udespesasmodel, uproductscontroller, uportifoliocontroller,
  uoauthtokencontroller, uservicecontroller, usitecontroller,
  utrecsenhacontroller, uzapcontroller, udespesascontroller, uclientscontroller,
  ucaixacontroller, uassistenteiacontroller, uassistenteia, uanamnesecontroller,
  uagendacontroller, uportifolioview, uJsonView, URelatoriosController, URelatoriosModel;


type

  { TMyApplication }

  TMyApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TMyApplication }

procedure TMyApplication.DoRun;
var
  ErrorMsg: String;
begin
  // quick check parameters
  ErrorMsg:=CheckOptions('h', 'help');
  if ErrorMsg<>'' then begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h', 'help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;
  try
     tAppRouter.load_routes();
     WriteLn('Rotas carregadas');
  except on e:exception do
     WriteLn('Erro ao carregar rotas: ' + e.Message);
  end;
  try
     THorse.Listen(8082);
  except on e:exception do
     WriteLn('Erro ao iniciar server: ' + e.Message);
  end;
  // stop program loop
  Terminate;
end;

constructor TMyApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TMyApplication.Destroy;
begin
  inherited Destroy;
end;

procedure TMyApplication.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ', ExeName, ' -h');
end;

var
  Application: TMyApplication;
begin
  Application:=TMyApplication.Create(nil);
  Application.Title:='Server Inkers';
  Application.Run;
  Application.Free;
end.

