unit uoauthtokenmodel;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, httpsend, ssl_openssl, synautil, synacode, blcksock,
  sockets, synsock, fpjson, StrUtils;

type

  { TOauthTokenModel }

  TOauthTokenModel = class
    private
      FClientID: string;
      FClientSecret: string;
      FRedirectURI: string;
      FScope: string;
    public
      constructor Create(const AClientID, AClientSecret, AScope: string);
      function GetAuthorizationURL: string;
      function GetTokens(const AAuthCode: string; out AccessToken, RefreshToken: string): Boolean;
      function RefreshAccessToken(const ARefreshToken: string; out AccessToken: string): Boolean;
  end;


implementation

{ TOauthTokenModel }

constructor TOauthTokenModel.Create(const AClientID, AClientSecret,
  AScope: string);
begin
  FClientID     := AClientID;
  FClientSecret := AClientSecret;
  FRedirectURI := 'http://localhost:8082/oauth/callback';
  FScope        := AScope;
end;

function TOauthTokenModel.GetAuthorizationURL: string;
const
  AUTH_URL = 'https://accounts.google.com/o/oauth2/v2/auth';
begin
  Result := AUTH_URL +
    '?response_type=code' +
    '&client_id=' + EncodeURLElement(FClientID) +
    '&redirect_uri=' + EncodeURLElement(FRedirectURI) +
    '&scope=openid%20email%20profile' +
    //'&scope=' + EncodeURLElement(FScope) +
    '&access_type=offline' +
    '&prompt=consent';
end;

function TOauthTokenModel.GetTokens(const AAuthCode: string; out AccessToken,
  RefreshToken: string): Boolean;
const
  TOKEN_URL = 'https://oauth2.googleapis.com/token';
var
  HTTP: THTTPSend;
  Params: TStringList;
  Response: TStringStream;
  ResponseStr: string;
  StartPos, EndPos: integer;
begin
  Result := False;
  AccessToken := '';
  RefreshToken := '';

  HTTP := THTTPSend.Create;
  Params := TStringList.Create;
  Response := TStringStream.Create('');
  try
    Params.Add('code=' + AAuthCode);
    Params.Add('client_id=' + FClientID);
    Params.Add('client_secret=' + FClientSecret);
    Params.Add('redirect_uri=' + FRedirectURI);
    Params.Add('grant_type=authorization_code');

    HTTP.MimeType := 'application/x-www-form-urlencoded';
    WriteStrToStream(HTTP.Document, Params.Text);

    if HTTP.HTTPMethod('POST', TOKEN_URL) then
    begin
      Response.LoadFromStream(HTTP.Document);
      ResponseStr := Response.DataString;

      // Extrair access_token
      if Pos('"access_token"', ResponseStr) > 0 then
      begin
        StartPos := Pos('"access_token":"', ResponseStr) + 16;
        EndPos := PosEx('"', ResponseStr, StartPos);
        AccessToken := Copy(ResponseStr, StartPos, EndPos - StartPos);
      end;

      // Extrair refresh_token
      if Pos('"refresh_token"', ResponseStr) > 0 then
      begin
        StartPos := Pos('"refresh_token":"', ResponseStr) + 17;
        EndPos := PosEx('"', ResponseStr, StartPos);
        RefreshToken := Copy(ResponseStr, StartPos, EndPos - StartPos);
        Result := (AccessToken <> '') and (RefreshToken <> '');
      end;
    end;
  finally
    HTTP.Free;
    Params.Free;
    Response.Free;
  end;
end;

function TOauthTokenModel.RefreshAccessToken(const ARefreshToken: string; out
  AccessToken: string): Boolean;
const
  TOKEN_URL = 'https://oauth2.googleapis.com/token';
var
  HTTP: THTTPSend;
  Params: TStringList;
  Response: TStringStream;
  ResponseStr: string;
  StartPos, EndPos: integer;
begin
  Result := False;
  AccessToken := '';

  HTTP := THTTPSend.Create;
  Params := TStringList.Create;
  Response := TStringStream.Create('');
  try
    Params.Add('client_id=' + FClientID);
    Params.Add('client_secret=' + FClientSecret);
    Params.Add('refresh_token=' + ARefreshToken);
    Params.Add('grant_type=refresh_token');

    HTTP.MimeType := 'application/x-www-form-urlencoded';
    WriteStrToStream(HTTP.Document, Params.Text);

    if HTTP.HTTPMethod('POST', TOKEN_URL) then
    begin
      Response.LoadFromStream(HTTP.Document);
      ResponseStr := Response.DataString;

      if Pos('"access_token"', ResponseStr) > 0 then
      begin
        StartPos := Pos('"access_token":"', ResponseStr) + 16;
        EndPos := PosEx('"', ResponseStr, StartPos);
        AccessToken := Copy(ResponseStr, StartPos, EndPos - StartPos);
        Result := AccessToken <> '';
      end;
    end;
  finally
    HTTP.Free;
    Params.Free;
    Response.Free;
  end;
end;

end.

