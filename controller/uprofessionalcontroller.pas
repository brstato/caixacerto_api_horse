unit uprofessionalcontroller;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, db, fpjson, uJsonView, udata, umailmodel,
  uprofissionalmodel, Horse, Horse.JWT;

type

  { TProfessionalController }

  TProfessionalController = class
    private
    public
      class procedure RegisterRoutes;
  end;

implementation

{ TProfessionalController }

procedure HandlerDeleteAccountProfessional(Req:THorseRequest; Res:THorseResponse; next:TNextProc);
var
   json:TJSONObject;
   ProfModel: TProfissionaisModel;
   mailmodel: TmailModel;
   StringError: TStringList;
   id: integer;
begin
  try
    try
       ProfModel := TProfissionaisModel.Create;

       json := TJSONObject(GetJSON(Req.Body));

       id       :=json.Find('id').AsInteger;

       ProfModel.deleteProfessional(id);

    finally
      ProfModel.Free;
      json.Free;
    end;
  except on e:exception do
  begin
    StringError:= TStringList.Create;
    try
      TJsonView.SendResponse(res, TJSONObject(GetJSON(('{"message":"error: ' + E.Message + '"}'))), 500);

      StringError.Add(e.Message);
      mailmodel:=TmailModel.Create(
                 'brunnoribeiroangra21@gmail.com',
                 'Erro na procedure HandlerDeleteAccountProfessional',
                 StringError
               );
      mailmodel.FreeOnTerminate:=True;
      mailmodel.Start;
    finally
      StringError.Free;
    end;
  end;
  end;
end;


procedure HandlerEditAccountProfessional(Req:THorseRequest; Res:THorseResponse; next:TNextProc);
var
   json:TJSONObject;
   ProfModel: TProfissionaisModel;
   mailmodel: TmailModel;
   StringError: TStringList;
   id, comission: integer;
   name, telefone: string;
begin
  try
    try
       //DataModule1.ZConnection1.StartTransaction;

       ProfModel := TProfissionaisModel.Create;

       json := TJSONObject(GetJSON(Req.Body));

       id       :=json.Find('id'       ).AsInteger;
       name     :=json.Find('name'     ).AsString;
       telefone :=json.Find('tel'      ).AsString;
       comission:=json.Find('comission').AsInteger;

       ProfModel.EditAccountProfessional(name, telefone, id, comission);

       //DataModule1.ZConnection1.Commit;
    finally
      ProfModel.Free;
      json.Free;
    end;
  except on e:exception do
  begin
    StringError:= TStringList.Create;
    try
      TJsonView.SendResponse(res, TJSONObject(GetJSON(('{"message":"error: ' + E.Message + '"}'))), 200);

      StringError.Add(e.Message);
      mailmodel:=TmailModel.Create(
                 'brunnoribeiroangra21@gmail.com',
                 'Erro na procedure HandlerEditAccountProfessional',
                 StringError
               );
      mailmodel.FreeOnTerminate:=True;
      mailmodel.Start;
    finally
      StringError.Free;
    end;
  end;
  end;
end;


procedure HandlerListAccountProfessional(Req:THorseRequest; Res:THorseResponse; next:TNextProc);
var
  mailmodel: TmailModel;
  id:string;
  json, jsonResponse: TJSONObject;
  jsonArray: TJSONArray;
  StringError: TStringList;
  ProfModel: TProfissionaisModel;
begin
  ProfModel := TProfissionaisModel.Create;
  try
    try
       json := TJSONObject(GetJSON(Req.Body));

       id := json.Find('id').AsString;

       jsonArray := ProfModel.listProfessional(id);

       jsonResponse := TJSONObject.Create;
       jsonResponse.Add('message', jsonArray);

       TJsonView.SendResponse(Res, jsonResponse, 200);
    finally
      ProfModel.Free;
      json.Free;
      jsonResponse.Free;
    end;
  except on e:exception do
  begin
    StringError:= TStringList.Create;
    try
      TJsonView.SendResponse(res, TJSONObject(GetJSON(('{"message":"error: ' + E.Message + '"}'))), 200);

      StringError.Add(e.Message);
      mailmodel:=TmailModel.Create(
                 'brunnoribeiroangra21@gmail.com',
                 'Erro na procedure HandlerListAccountProfessional',
                 StringError
               );
      mailmodel.FreeOnTerminate:=True;
      mailmodel.Start;
    finally
      StringError.Free;
    end;
  end;
end;
end;

procedure HandlerCreateAccountProfessional(Req:THorseRequest; Res:THorseResponse; next:TNextProc);
var
  StringError: TStringList;
  ProfModel: TProfissionaisModel;
  Json: TJSONObject;
  name, tel, id_loja: string;
  comission: integer;
  mailmodel: TmailModel;
begin
  ProfModel := TProfissionaisModel.Create;
  try
    try
      Json := TJSONObject(GetJSON(Req.Body));

      name      := Json.Find('name'     ).AsString;
      tel       := Json.Find('tel'      ).AsString;
      comission := Json.Find('comission').AsInteger;
      id_loja   := Json.Find('id_loja'  ).AsString;

      ProfModel.createProfessional(name, tel, id_loja, comission);

    finally
      ProfModel.Free;
      Json.Free;
    end;
  except on e:exception do
  begin
    StringError:= TStringList.Create;
    try
      TJsonView.SendResponse(res, TJSONObject(GetJSON(('{"message":"error: ' + E.Message + '"}'))), 200);

      StringError.Add(e.Message);
      mailmodel:=TmailModel.Create(
                 'brunnoribeiroangra21@gmail.com',
                 'Erro na procedure HandlerCreateAccountProfessional',
                 StringError
               );
      mailmodel.FreeOnTerminate:=True;
      mailmodel.Start;
    finally
      StringError.Free;
    end;
  end;
end;
end;


procedure HandlerDetailAccountProfessional(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  mailmodel: TmailModel;
  id:integer;
  json, jsonResponse: TJSONObject;
  StringError: TStringList;
  ProfModel: TProfissionaisModel;
begin
  ProfModel := TProfissionaisModel.Create;
  try
    try
       json := TJSONObject(GetJSON(Req.Body));

       id := json.Find('id').AsInteger;

       jsonResponse := TJSONObject(GetJSON(ProfModel.DetailProfessional(id)));

       TJsonView.SendResponse(Res, jsonResponse, 200);
    finally
      ProfModel.Free;
      jsonResponse.Free;
      json.Free;
    end;
  except on e:exception do
  begin
    StringError:= TStringList.Create;
    try
      TJsonView.SendResponse(res, TJSONObject(GetJSON(('{"message":"error: ' + E.Message + '"}'))), 500);

      StringError.Add(e.Message);
      mailmodel:=TmailModel.Create(
                 'brunnoribeiroangra21@gmail.com',
                 'Erro na procedure HandlerListAccountProfessional',
                 StringError
               );
      mailmodel.FreeOnTerminate:=True;
      mailmodel.Start;
    finally
      StringError.Free;
    end;
  end;
end;
end;


class procedure TProfessionalController.RegisterRoutes;
begin
  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/professional/create',   HandlerCreateAccountProfessional);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/professional/list',   HandlerListAccountProfessional);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/professional/edit',   HandlerEditAccountProfessional);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/professional/delete',   HandlerDeleteAccountProfessional);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/professional/detail',   HandlerDetailAccountProfessional);
end;

end.

