unit uloginmodel;

{$mode delphi}{$H+}

interface

uses
  Classes,
  SysUtils,
  BCrypt,
  sql_queries,
  udata,
  ZDataset,
  fpjson,
  LazJWT,
  DateUtils,
  db,
  ugetdata,
  uNetService,
  ulojamodel,
  jsonparser,
  MemDs;

type
  TLoginDados = Record
    id,
    refreshToken,
    token,
    Url,
    vencimento,
    agora: string;
    expire: integer;
    bloqueado: boolean;
    dataValidade: TDateTime;
  end;

type
  TReturn = Record
    jsonString: string;
    json: TJSONObject;
    valido: Boolean;
  end;

type
  { TLoginModel }

  TLoginModel = Class
  private
      const GoogleCheckUrl: string = 'https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=';
    public
      class function GetlojaEmailLogin(const email, senha: String): TJSONObject;

      class function updateRefreshToken(r_token, id: string):UTF8String;
      class function updateJWT(uuid: string): string;
      class function verifyRToken(r_token: string): boolean;
      class function LoginGoogle(const g_mail, g_token, g_name:
        string; out status_code: integer; r_token:string = ''): UTF8String;
  end;

implementation



function createRefreshToken: string;
var
   uuid: TGuid;
begin
  CreateGUID(uuid);
  Result := TBCrypt.GenerateHash(GUIDToString(uuid));
end;


class function TLoginModel.updateRefreshToken(r_token, id: string): UTF8String;
var
   queryData: TDataSet;
   refreshToken, token: string;
   jsonData: TJSONObject;
   recordcount, expire, agora: integer;

begin

   jsonData:=TJSONObject.Create;

   token:=updateJWT(id);
   refreshToken:=createRefreshToken;

   try
     queryData := TGetData.getData(
       sql_queries.verify_refresh_token,
       [r_token, id],
       True
     );

     recordcount:=queryData.RecordCount;

     expire:=queryData.FieldByName('expire').AsInteger;
     agora:=DateTimeToUnix(now);

     if (queryData.RecordCount = 1)  and
       (queryData.FieldByName('expire').AsInteger >= DateTimeToUnix(now)) then
     begin
      TGetData.getData(
        sql_queries.update_refresh_token,
        [
          refreshToken,
          DateTimeToUnix(IncMonth(now, 1)),
          id
        ],
        False
      );
       jsonData.Add('r_token',refreshToken);
       jsonData.Add('token', token);
       jsonData.Add('status','200');
     end
     else
     begin
       jsonData.Add('r_token','');
       jsonData.Add('token', '');
       jsonData.Add('status','401');
     end;
   finally
     queryData.Free;
     Result:=jsonData.AsJSON;
     jsonData.Free;
     //Result.jsonString:=refreshToken;
     //Result.json:=jsonData;
   end;
end;


class function TLoginModel.updateJWT(uuid: string): string;
var
   token: string;
begin
  try
    token := TLazJWT.New
           .SecretJWT(DataModule1.token)
           .Exp(DateTimeToUnix(IncMonth(now, 1)))
           .AddClaim('id', uuid)
           .AddClaim('Exp', DateTimeToUnix(IncMonth(now, 1)))
           .Token;

  finally
    Result:=token;
  end;
end;

class function TLoginModel.verifyRToken(r_token: string): boolean;
begin

end;

class function TLoginModel.LoginGoogle(const g_mail, g_token, g_name:
        string; out status_code: integer; r_token:string = ''): UTF8String;
var
   dataset: TDataSet;
   jsonObject, JsonData, GoogleResponseJson: TJSONObject;
   LoginDados: TLoginDados;
   fs: TFormatSettings;
begin

     LoginDados.bloqueado := false;

     try
       LoginDados.Url := GoogleCheckUrl + g_token;
       GoogleResponseJson := TJSONObject(GetJSON(TNetService.get(LoginDados.Url)));

       jsonObject := TJSONObject.Create;

       if (GoogleResponseJson.Find('error') <> nil) or
         (GoogleResponseJson.get('email', '') <> g_mail) then
       begin
         status_code := 401;
         jsonObject.Add('message', 'Token do Google inválido ou expirado.');
         Result := jsonObject.AsJSON;
         GoogleResponseJson.Free;
         jsonObject.Free;
         exit;
       end;
       GoogleResponseJson.Free;
     except
       on E: Exception do
       begin
         jsonObject.Add('message', 'Erro ao validar token com Google: ' + E.Message);
         Result := jsonObject.AsJSON;
         jsonObject.Free;
         exit;
       end;
     end;
    JsonData   := TJSONObject.Create;

    try
      dataset := TGetData.getData(
        'SELECT uuid, validade FROM loja WHERE email = :email',
        [g_mail],
        True
      );
        LoginDados.Bloqueado := false;
        if dataset.IsEmpty then
        begin
          LoginDados.Id := TLojaModel.createloja(g_name, g_mail);
          jsonObject.Add('status', '200');
        end
        else
        begin
          LoginDados.Id := dataset.FieldByName('uuid').AsString;
          if DateOf(dataset.FieldByName('validade').AsDateTime) < DateOf(Now) then
          begin
            jsonObject.Add('status', '403');
            status_code := 403;
            LoginDados.Bloqueado := true;
          end
          else
            jsonObject.Add('status', '200');
        end;
        // CORREÇÃO: A geração de tokens corre para utilizadores novos OU existentes (se não estiverem bloqueados)
        if not LoginDados.Bloqueado then
        begin
          JsonData.Add('id', LoginDados.Id);

          LoginDados.RefreshToken := createRefreshToken;
          LoginDados.Expire := DateTimeToUnix(IncMonth(Now, 1));

          TGetData.getData(
            'update loja set refresh_token = :token, expire = :expire, '+
            'google_refresh_token = :r_token '+
            'where uuid = :uuid;',
            [LoginDados.RefreshToken, LoginDados.Expire, r_token, LoginDados.Id]
          );

          LoginDados.Token := updateJWT(LoginDados.Id);

          jsonObject.Add('token',          LoginDados.Token);
          jsonObject.Add('r_token', LoginDados.RefreshToken);
          jsonObject.Add('message',                JsonData);

          status_code := 200;
        end;
      Result := jsonObject.AsJSON;
    finally
      jsonObject.Free;
    end;
end;


class function TLoginModel.GetlojaEmailLogin(const email, senha: String): TJSONObject;
var
  Query: TDataSet;
  jsonObject, JsonData: TJSONObject;
  password: Boolean;
  token, refreshToken, id: string;
  expire: integer;
  getdata: TGetData;
  validade, validade_of, agora: TDateTime;
begin
     password := false;

     jsonObject := TJSONObject.Create;
     JsonData   := TJSONObject.Create;
     getdata    := TGetData.Create;
     try
       try
         Query := getdata.getData(
           sql_queries.busca_loja_login,
           [
             email
           ],
           true
         );

         if Query.IsEmpty then
         begin
           JsonData.Add('id', '');

           jsonObject.Add('status', '401');
           jsonObject.Add('token',     '');
           jsonObject.Add('r_token',   '');
         end
         else
         begin
          with Query do
          begin
            if FieldByName('senha').AsString <> '' then
               password:=TBCrypt.CompareHash(senha, FieldByName('senha').AsString);

            if not password and (FieldByName('senha_temp').AsString <> '') then
               password:=TBCrypt.CompareHash(senha, FieldByName('senha_temp').AsString);

            if not password then
            begin
              JsonData.Add('id',          '');

              jsonObject.Add('status', '401');
              jsonObject.Add('token',     '');
              jsonObject.add('r_token',   '');
            end
            else
            begin

               id := FieldByName('uuid').AsString;

               JsonData.Add('id',FieldByName('uuid').AsString);

               agora := DateOf(Now);

               validade := Query.FieldByName('validade').AsDateTime;

               validade_of := DateOf(validade);

               if validade_of < agora then
               begin
                 jsonObject.Add('status', '403');
                 jsonObject.Add('token',     '');
                 jsonObject.add('r_token',   '');
               end
               else
               begin
                 refreshToken := createRefreshToken;

                 expire:=DateTimeToUnix(IncMonth(now, 1));

                 TGetData.getData(
                   sql_queries.update_refresh_token,
                   [refreshToken, expire, id]
                 );

                 token := updateJWT(id);

                 jsonObject.Add('status',         '200');
                 jsonObject.Add('token',          token);
                 jsonObject.add('r_token', refreshToken);
               end;
            end;
          end;
         end;
         jsonObject.Add('message',JsonData);
         Result:= jsonObject;
       finally
         Query.Free;
         getdata.Free;
       end;
     except
       on e:exception do
       begin
        jsonObject.Free;
        JsonData.Free;
        raise;
       end;
     end;
end;



end.

