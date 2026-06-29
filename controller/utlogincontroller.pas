unit uTlogincontroller;

{$mode delphi}{$H+}

interface

uses
  Classes,
  SysUtils,
  Horse,
  uloginmodel, umailmodel,
  uJsonView, udata,
  fpjson,
  jsonscanner,
  Horse.JWT
  ;

type
  TLoginController = class
  private

  public
    class procedure RegisterRoutes();
  end;

implementation

procedure HandleRefreshToken(Req: THorseRequest; Res: THorseResponse; next: TNextProc);
var
  TokenData, RequestJson: TJSONObject;
  mailMode:TmailModel;
  uuid, refreshToken: string;
  StringError: TStringList;
  status: integer;
begin
  status:=401;
  try
    try
      RequestJson := TJSONObject(GetJSON(req.Body));

      refreshToken := RequestJson.get('r_token', '');
      uuid         := RequestJson.get('uuid', ''   );

      if (refreshToken = '') or (uuid = '') then
         exit;

      TokenData := TJSONObject(GetJSON(TLoginModel.updateRefreshToken(refreshToken, uuid)));

      status:=TokenData.Find('status').AsInteger;

      TJsonView.SendResponse(Res, TokenData, status);

    except on e:Exception do
      begin
        StringError:= TStringList.Create;
        try
          StringError.Add(e.Message);
        finally
          StringError.Free;
        end;
      end;
    end;
  finally
    if Assigned(RequestJson) then RequestJson.Free;
    if Assigned(TokenData  ) then TokenData.Free;
  end;
end;


procedure HandleLogin(Req: THorseRequest; Res: THorseResponse; next: TNextProc);
var
  Email, Senha: string;
  LoginModel: TLoginModel;
  LoginData, RequestJson: TJSONObject;
  status: integer;
begin
  RequestJson := nil; // Boa prática: inicializar com nil
  LoginData := nil;
  try
  try
    try
      // 1. Bloco protegido para a leitura do JSON
      RequestJson := TJSONObject(GetJSON(req.Body));
    except
      on E: EScannerError do
      begin
        // Retorna um erro 400 (Bad Request) específico e claro
        TJsonView.SendResponse(Res, TJSONObject(GetJSON('{"message":"Corpo da requisição inválido. JSON malformado."}')), 400);
        Exit; // Encerra a execução
      end;
    end;

    // Se chegou aqui, o JSON é válido. O resto do código pode continuar.
    // Opcional: Acesso seguro aos campos para evitar outras exceções
    if Assigned(RequestJson.Find('email')) and Assigned(RequestJson.Find('senha')) then
    begin
      email := RequestJson.Find('email').AsString;
      senha := RequestJson.Find('senha').AsString;
    end
    else
    begin
       TJsonView.SendResponse(Res, TJSONObject(GetJSON('{"message":"Campos ''email'' e ''senha'' são obrigatórios."}')), 400);
       Exit;
    end;

    LoginModel := TLoginModel.Create;
    try
      LoginData := TLoginModel.GetlojaEmailLogin(Email, Senha);

      if Assigned(LoginData) then
      begin
        status := LoginData.Find('status').AsInteger;
        TJsonView.SendResponse(Res, LoginData, status);
        // LoginData será liberado no 'finally' externo
      end
      else
        TJsonView.SendResponse(Res, TJSONObject(GetJSON('{"message":"Usuário não encontrado."}')), 404);
    finally
      LoginModel.Free;
    end;
  except
    on E: Exception do
      TJsonView.SendResponse(Res, TJSONObject(GetJSON('{"message":"Erro interno do servidor: ' + E.Message + '"}')), 500);
  end;
  finally
    // Libera os objetos JSON aqui para garantir que sempre sejam liberados
    if Assigned(RequestJson) then RequestJson.Free;
    if Assigned(LoginData) then LoginData.Free;
  end;

end;


procedure HandleLogin_Google(req: THorseRequest; res: THorseResponse);
var
  RequestJson, LoginData: TJSONObject;
  Email, GoogleToken, nome, ads_id, r_token: string;
  status: integer;
begin
  try
    try
      RequestJson := TJSONObject(GetJSON(Req.Body));

      nome        := RequestJson.Find('g_name' ).AsString;
      Email       := RequestJson.Find('g_email').AsString;
      GoogleToken := RequestJson.Find('g_token').AsString;
      //ads_id      := RequestJson.find('ads_id' ).AsString;
      r_token     := RequestJson.Get('r_token', '');

      LoginData := TJSONObject(
        GetJSON(
          TLoginModel.LoginGoogle(
            Email,
            GoogleToken,
            nome,
            //ads_id,
            status,
            r_token
          )
        )
      );

      TJsonView.SendResponse(Res, LoginData, status);

    except
      on E: Exception do
        TJsonView.SendError(Res, 500, e.Message);
    end;
  finally
    if Assigned(RequestJson) then RequestJson.Free;
    if Assigned(LoginData) then LoginData.Free;
  end;

end;

class procedure TLoginController.RegisterRoutes();
begin
  //THorse.AddCallback(HorseJWT(DataModule1.token))
  //  .post('/api/v1/login', HandleLogin);
  THorse.Post('/api/v1/token/refresh', HandleRefreshToken);
  THorse.post('/api/v1/login', HandleLogin);
  THorse.post('/api/v1/login_google', HandleLogin_Google);
end;

end.
