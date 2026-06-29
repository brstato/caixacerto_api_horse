unit ustoragetokensmodel;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, base64;

type

  { TStorageTokensModel }

  TStorageTokensModel = Class
    private
      class var iniFile: TIniFile;
    public

      constructor Create;
      procedure StorageToken(const AToken, ARefreshToken: string);
      function getToken: string;
      function getRefreshToken: string;
      destructor Destroy; override;
  end;

implementation

{ TStorageTokensModel }

constructor TStorageTokensModel.Create;
begin
     iniFile := TIniFile.Create(ExtractFilePath(ParamStr(0))+'Token.ini');
end;

procedure TStorageTokensModel.StorageToken(const AToken, ARefreshToken: string);
begin
   iniFile.WriteString('Token', 'Oauth_token', EncodeStringBase64(AToken));
   iniFile.WriteString('Token', 'Refresh_token', EncodeStringBase64(ARefreshToken));
end;

function TStorageTokensModel.getToken: string;
begin
  Result := DecodeStringBase64(iniFile.ReadString('Token', 'Oauth_token', ''));
end;

function TStorageTokensModel.getRefreshToken: string;
begin
  Result := DecodeStringBase64(iniFile.ReadString('Token', 'Refresh_token', ''));
end;

destructor TStorageTokensModel.Destroy;
begin
  iniFile.Free;
  inherited Destroy;
end;

end.

