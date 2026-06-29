unit utokenmanager;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, uoauthtokenmodel;

type

  { TTokenManager }

  TTokenManager = class
    private
      class var FAccessToken: string;
      class var FRefreshToken: string;
      class var FInitialized: Boolean;
      class procedure InitializeTokens;
    public
      class function GetTokens(out AccessToken, RefreshToken: string): Boolean;
      class procedure UpdateTokens(const NewAccessToken, NewRefreshToken: string);
      class procedure RefreshTokens;
  end;

implementation

{ TTokenManager }

class procedure TTokenManager.InitializeTokens;
begin
  FAccessToken := 'access_token_inicial';
  FRefreshToken := 'refresh_token_inicial';
  FInitialized := True;
end;

class function TTokenManager.GetTokens(out AccessToken, RefreshToken: string
  ): Boolean;
begin
  if not FInitialized then
    InitializeTokens;

  AccessToken := FAccessToken;
  RefreshToken := FRefreshToken;
  Result := (AccessToken <> '') and (RefreshToken <> '');
end;

class procedure TTokenManager.UpdateTokens(const NewAccessToken,
  NewRefreshToken: string);
begin
  FAccessToken := NewAccessToken;
  if NewRefreshToken <> '' then
    FRefreshToken := NewRefreshToken;
end;

class procedure TTokenManager.RefreshTokens;
var
  OAuthModel: TOAuthTokenModel;
  NewAccessToken: string;
begin
  if not FInitialized then
    InitializeTokens;

  OAuthModel := TOAuthTokenModel.Create(
    '669477241496-195ertksh03gapc81jh5is1bl5rq3kr0.apps.googleusercontent.com',
    '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',
    'https://www.googleapis.com/auth/gmail.send'
  );
  try
    if OAuthModel.RefreshAccessToken(FRefreshToken, NewAccessToken) then
      UpdateTokens(NewAccessToken, '');
  finally
    OAuthModel.Free;
  end;
end;

end.

