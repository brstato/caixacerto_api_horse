unit uclientscontroller;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, fpjson, uclientsmodel, Horse, uJsonView, Horse.JWT, udata;

type

  { TClientController }

  TClientController = class
    public
      class procedure RegisterRoutes();
  end;

implementation

{ TClientController }


procedure HandlerclientCreate(req: THorseRequest; res: THorseResponse;
  next: TNextProc);
var
  jsonReq: TJSONObject;
  model: TClientModel;
begin
  model := TClientModel.Create;
  try
    try
      jsonReq := TJSONObject(GetJSON(req.Body));
      model.createClient(
        jsonReq.Find('nome'       ).AsString,
        jsonReq.Find('telefone'   ).AsString,
        jsonReq.Find('aniversario').AsString,
        jsonReq.Find('id_loja'    ).AsString
      );
    except on e:exception do
    begin
      if E.Message = 'DUPLICIDADE_TELEFONE' then
        TJsonView.SendResponse(res, TJSONObject(GetJSON('{"status":"error", "message":"Este telefone já está cadastrado.", "code":"PHONE_EXISTS"}')), 409)
      else
        TJsonView.SendResponse(res, TJSONObject(GetJSON('{"status":"error", "message":"' + E.Message )), 500)
    end;
    end;
  finally
    jsonReq.Free;
    model.Free;
  end;
end;


procedure HandlerclientDelete(req: THorseRequest; res: THorseResponse;
  next: TNextProc);
var
  jsonReq: TJSONObject;
  model: TClientModel;
begin
  model := TClientModel.Create;
  try
    jsonReq := TJSONObject(GetJSON(req.Body));
    model.deleteClient(strtointdef(jsonReq.Find('id').AsString, 0));
  finally
    model.Free;
    jsonReq.Free;
  end;
end;


procedure HandlerclientUpdate(req: THorseRequest; res: THorseResponse;
  next: TNextProc);
var
  model: TClientModel;
  jsonReq: TJSONObject;
  status_code: integer;
begin
  model := TClientModel.Create;
  try
    try
      jsonReq := TJSONObject(GetJSON(req.Body));

      model.updateClient(
        jsonReq.Find('nome'       ).AsString,
        jsonReq.Find('telefone'   ).AsString,
        jsonReq.Find('aniversario').AsString,
        jsonReq.Find('id'         ).AsInteger,
        status_code
      );

      if status_code = 200 then
         TJsonView.SendSuccess(res);
    except on e:Exception do
      TJsonView.SendError(res, status_code, e.Message);
    end;
  finally
    model.Free;
    jsonReq.Free;
  end;
end;


procedure HandlerclientDetail(req: THorseRequest; res: THorseResponse;
  next: TNextProc);
var
  model: TClientModel;
  jsonReq, jsonRes: TJSONObject;
begin
  model := TClientModel.Create;
  try
    jsonReq := TJSONObject(GetJSON(req.Body));
    jsonRes := TJSONObject(GetJSON(model.detailCliente(strtointdef(jsonReq.Find('id').AsString,0))));
    TJsonView.SendResponse(res, jsonRes, 200);
  finally
    model.Free;
    jsonRes.Free;
    jsonReq.Free;
  end;
end;


procedure HandlerclientList(req: THorseRequest; res: THorseResponse;
  next: TNextProc);
var
  model: TClientModel;
  id, categoria: string;
  order_maior, order_menor, ultima_compra: boolean;
  jsonReq, jsonRes: TJSONObject;
  row, row_to:integer;
begin
  model := TClientModel.Create;
  try

    jsonReq := TJSONObject(GetJSON(req.Body));

    jsonRes := TJSONObject(
      GetJSON(
        model.listClient(
          jsonReq.Find('id').AsString
        )
      )
    );

    TJsonView.SendResponse(res, jsonRes, 200);

  finally
    jsonRes.Free;
    jsonReq.Free;
    model.Free;
  end;
end;



procedure HandlerclientListA(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq, jsonRes: TJSONObject;
  status_code: integer;
  id: string;
begin
  try
    jsonreq := TJSONObject(GetJSON(req.Body));

    id := jsonreq.Find('id').AsString;

    jsonRes := TJSONObject(GetJSON(TClientModel.listClientA(id, status_code)));

    TJsonView.SendResponse(res, jsonRes, status_code);
  finally
    jsonreq.Free;
    jsonRes.Free;
  end;
end;


procedure HandlerclientListB(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq, jsonRes: TJSONObject;
  status_code: integer;
  id: string;
begin
  try
    jsonreq := TJSONObject(GetJSON(req.Body));

    id := jsonreq.Find('id').AsString;

    jsonRes := TJSONObject(GetJSON(TClientModel.listClientB(id, status_code)));

    TJsonView.SendResponse(res, jsonRes, status_code);
  finally
    jsonreq.Free;
    jsonRes.Free;
  end;
end;


procedure HandlerclientListC(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq, jsonRes: TJSONObject;
  status_code: integer;
  id: string;
begin
  try
    jsonreq := TJSONObject(GetJSON(req.Body));

    id := jsonreq.Find('id').AsString;

    jsonRes := TJSONObject(GetJSON(TClientModel.listClientC(id, status_code)));

    TJsonView.SendResponse(res, jsonRes, status_code);
  finally
    jsonreq.Free;
    jsonRes.Free;
  end;
end;


procedure HandlerclientListMaior(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq, jsonRes: TJSONObject;
  status_code: integer;
  id: string;
begin
  try
    jsonreq := TJSONObject(GetJSON(req.Body));

    id := jsonreq.Find('id').AsString;

    jsonRes := TJSONObject(GetJSON(TClientModel.listClientMaior(id, status_code)));

    TJsonView.SendResponse(res, jsonRes, status_code);
  finally
    jsonreq.Free;
    jsonRes.Free;
  end;

end;


procedure HandlerclientListMenor(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq, jsonRes: TJSONObject;
  status_code: integer;
  id: string;
begin
  try
    jsonreq := TJSONObject(GetJSON(req.Body));

    id := jsonreq.Find('id').AsString;

    jsonRes := TJSONObject(GetJSON(TClientModel.listClientMenor(id, status_code)));

    TJsonView.SendResponse(res, jsonRes, status_code);
  finally
    jsonreq.Free;
    jsonRes.Free;
  end;
end;


class procedure TClientController.RegisterRoutes();
begin
    THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/client/create', HandlerclientCreate);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/client/delete', HandlerclientDelete);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/client/update', HandlerclientUpdate);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/client/detail', HandlerclientDetail);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/client/list',   HandlerclientList);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/client/list_A', HandlerclientListA);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/client/list_B', HandlerclientListB);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/client/list_C', HandlerclientListC);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/client/list_maior', HandlerclientListMaior);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/client/list_menor', HandlerclientListMenor);
end;

end.

