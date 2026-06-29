unit uoauthtokencontroller;

{$mode delphi}{$H+}

interface

uses
   Classes, SysUtils, Horse, uOAuthTokenModel, fpjson, uJsonView,
   ustoragetokensmodel, logger;

type

  { TOauthTokenController }

  TOauthTokenController = class
    public
      class procedure RegisterRoutes;
  end;

implementation

{ TOauthTokenController }

procedure HandleGetAuthorizationURL(Req: THorseRequest; Res: THorseResponse);
var
  OAuthModel: TOAuthTokenModel;
  AuthURL: string;
  ResponseJson: TJSONObject;
begin
  OAuthModel := TOAuthTokenModel.Create(
    '669477241496-195ertksh03gapc81jh5is1bl5rq3kr0.apps.googleusercontent.com',
    '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',
    'https://www.googleapis.com/auth/gmail.send'
  );
  try
    AuthURL := OAuthModel.GetAuthorizationURL;
    ResponseJson := TJSONObject.Create;
    ResponseJson.Add('authorization_url', AuthURL);
    TJsonView.SendResponse(Res, ResponseJson, 200);
  finally
    OAuthModel.Free;
  end;
end;


procedure HandleExchangeCode(Req: THorseRequest; Res: THorseResponse);
var
  OAuthModel: TOAuthTokenModel;
  RequestJson: TJSONObject;
  AuthCode: string;
  AccessToken, RefreshToken: string;
  ResponseJson: TJSONObject;
  StorageToken: TStorageTokensModel;
begin
  RequestJson := TJSONObject(GetJSON(Req.Body));
  try
    if not Assigned(RequestJson) then
    begin
      TJsonView.SendError(Res, 400, 'JSON inválido');
      Exit;
    end;

    AuthCode := RequestJson.Get('code', '');
    if AuthCode = '' then
    begin
      TJsonView.SendError(Res, 400, 'Código de autorização ausente');
      Exit;
    end;

    OAuthModel := TOAuthTokenModel.Create(
      '669477241496-195ertksh03gapc81jh5is1bl5rq3kr0.apps.googleusercontent.com',
      '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',
      'https://www.googleapis.com/auth/gmail.send'
    );
    try
      if OAuthModel.GetTokens(AuthCode, AccessToken, RefreshToken) then
      begin
        try
          StorageToken := TStorageTokensModel.Create;
          StorageToken.StorageToken(AccessToken,RefreshToken);
        finally
          StorageToken.Free;
        end;

        ResponseJson := TJSONObject.Create;
        ResponseJson.Add('access_token', AccessToken);
        ResponseJson.Add('refresh_token', RefreshToken);
        TJsonView.SendResponse(Res, ResponseJson, 200);
      end
      else
      begin
        TJsonView.SendError(Res, 400, 'Falha ao obter tokens');
      end;
    finally
      OAuthModel.Free;
    end;
  finally
    RequestJson.Free;
  end;
end;


procedure HandleOAuthCallback(Req: THorseRequest; Res: THorseResponse);
var
  AuthCode, AccessToken, RefreshToken: string;
  StorageToken: TStorageTokensModel;
  OAuthModel: TOauthTokenModel;
begin

  AuthCode := Req.Query['code'];

  OAuthModel := TOauthTokenModel.Create(
    '593692690842d3t4lbahbhdesv2fhh62896qoct1q6jq.apps.googleusercontent.com',
    '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',
    'https://www.googleapis.com/auth/gmail.send'
  );
    try
    if OAuthModel.GetTokens(AuthCode, AccessToken, RefreshToken) then
    begin
      try
        StorageToken := TStorageTokensModel.Create;
        StorageToken.StorageToken(AccessToken, RefreshToken);
        Res.Send('Tokens armazenados com sucesso!');

      finally
        StorageToken.Free;
      end;
    end
    else
    begin
      Res.Status(500).Send('Falha ao obter tokens');
    end;
  finally
    OAuthModel.Free;
  end;

  if AuthCode = '' then
  begin
    Res.Status(400).Send('Código ausente');
    Exit;
  end;

  Res.Send('Autenticação concluída! Você pode fechar esta janela.');
end;


class procedure TOauthTokenController.RegisterRoutes();
begin
  THorse.Get('api/v1/oauth/authorize', HandleGetAuthorizationURL);
  THorse.Get('api/v1/oauth/callback', HandleOAuthCallback);
  THorse.Post('api/v1/oauth/token', HandleExchangeCode);
end;

end.

