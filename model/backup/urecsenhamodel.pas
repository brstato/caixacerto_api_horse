unit urecsenhamodel;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, BCrypt, sql_queries, udata, ZDataset;

type

  { TRecSenhaModel }

  TRecSenhaModel = class
    public
      function GeneratePassword(const email: string): string;
  end;

implementation

{ TRecSenhaModel }

function EncRandompass(const randompass:string):string;
begin
   Result := TBCrypt.GenerateHash(randompass);
end;

function GenerateRandomPassw(
  ALength: Integer;
  AIncludeLowercase: Boolean;
  AIncludeUppercase: Boolean;
  AIncludeDigits: Boolean;
  AIncludeSpecialChars: Boolean):String;
var
   encPass: string;
   randomPass: string;
   CharPool: string;
   i: Integer;
begin
   Randomize;
   Result := '';
   CharPool := '';

   // Constrói o conjunto de caracteres disponíveis
   if AIncludeLowercase then
     CharPool := CharPool + 'abcdefghijklmnopqrstuvwxyz';
   if AIncludeUppercase then
     CharPool := CharPool + 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
   if AIncludeDigits then
     CharPool := CharPool + '0123456789';
   if AIncludeSpecialChars then
     CharPool := CharPool + '!@#$%^&*()_-+=[]{};:,.<>?/~`'; // Adicione/remova caracteres especiais conforme necessário

   // Gera a string aleatória
   for i := 1 to ALength do
   begin
     // Random(N) gera um número de 0 a N-1.
     // Índices de string em Pascal são 1-baseados, então adicionamos +1.
     Result := Result + CharPool[Random(Length(CharPool)) + 1];
   end;
end;

function TRecSenhaModel.GeneratePassword(const email: string): string;
var
   Query: TZQuery;
   randomPass: string;
   randomPassDB: string;
begin
     with Query do
     begin
          try
             try
                Query := TZQuery.Create(nil);

                Connection := DataModule1.ZConnection1;

                sql.Clear;
                sql.Add(sql_queries.busca_loja_login);
                ParamByName('email').AsString:=email;
                Open;

                if RecordCount > 0 then
                begin
                     randomPass:= GenerateRandomPassw(6, False, False, True, False);
                     randomPassDB := EncRandompass(randomPass);

                     SQL.Clear;
                     sql.Add(sql_queries.rec_senha);

                     ParamByName('email'     ).AsString:=     email;
                     ParamByName('senha_temp').AsString:=randomPassDB;

                     ExecSQL;
                end
                else
                    randomPass:='0';

                Result := randomPass;
             except
               raise;
             end;
          finally;
                  Query.Free;
                  //DataModule1.ZConnection1.Disconnect;

          end;
     end;
end;



end.

