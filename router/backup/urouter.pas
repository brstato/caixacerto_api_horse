unit urouter;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Horse, utlojacontroller, fpjson, utrecsenhacontroller,
  uprofessionalcontroller, uproductscontroller, uservicecontroller,
  uclientscontroller, ucaixacontroller, uagendacontroller, uanamnesecontroller,
  uzapcontroller, udespesascontroller, usitecontroller, uassistenteiacontroller,
  uportifoliocontroller;

type

  { tAppRouter }

  tAppRouter = class
  private
      public
      class procedure load_routes();
  end;

implementation

uses
  uTlogincontroller;

{ tAppRouter }


procedure onStatus(Req: THorseRequest; Res: THorseResponse; next: TNextProc);
begin
     Res.ContentType('text/html').Send(Format('<h1>Server on-line, horse version: %s</h1>', [THorse.Version]));
end;

class procedure tAppRouter.load_routes();
begin
    THorse.Get('/', onStatus);
    TLoginController.RegisterRoutes;
    TLojaController.RegisterRoutes;
    TRecSenhaController.RegisterRoutes;
    TProfessionalController.RegisterRoutes;
    TProductController.RegisterRoutes;
    TServiceController.RegisterRoutes;
    TClientController.RegisterRoutes;
    TCaixaController.RegisterRoutes;
    TAgendaController.RegisterRoutes;
    TAnamneseController.RegisterRoutes;
    TZapController.RegisterRoutes;
    TDespesasController.RegisterRoutes;
    TSiteController.RegisterRoutes;
    TAssistenteIa.RegisterRoutes;
    TPortifolioController.RegisterRoutes;
    //TOauthTokenController.RegisterRoutes;
end;


end.

