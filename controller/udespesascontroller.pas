unit udespesascontroller;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Horse, Horse.JWT, uagendamodel, udespesasmodel, uJsonView,
  udata, uNetService, fpjson, jsonparser;

type

  { TDespesasController }

  TDespesasController = class
  public
     class procedure RegisterRoutes();
  end;

implementation

{ TDespesasController }

procedure HandleResume(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq, jsonres: TJSONObject;
  model: TDespesasModel;
  id_loja: string;
begin
  jsonres := nil;

  jsonreq := TJSONObject(GetJSON(req.Body));
  model := TDespesasModel.Create;
  try
    try
      id_loja := jsonreq.Get('id_loja','');

      jsonres := TJSONObject(GetJSON(model.list_resume(id_loja)));

      TJsonView.SendResponse(res, jsonres, 200);
    except on e:Exception do
    begin
      TJsonView.SendError(res, 500, e.Message);
    end;
    end;
  finally
    jsonreq.Free;
    model.Free;
    jsonres.Free;
  end;
end;

procedure HandlerCreate(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq: TJSONObject;
  model: TDespesasModel;
  date: TDateTime;
  fmt: TFormatSettings;
begin
  jsonreq := TJSONObject(GetJSON(req.Body));
  model := TDespesasModel.Create;
  try
    try
      fmt.DateSeparator:='/';
      fmt.ShortDateFormat:='dd/mm/yyyy';

      date := StrToDate(jsonreq.get('date', '01/01/1900'), fmt);

      model.criar_depesa(
        jsonreq.Get('descricao',  ''),
        jsonreq.Get('status',     ''),
        jsonreq.Get('f_pagamento',''),
        jsonreq.Get('id_loja',    ''),
        jsonreq.Get('valor',     0.0),
        jsonreq.Get('qtd',         1),
        date
      );
      TJsonView.SendSuccess(res);
    except on e:exception do
    begin
      TJsonView.SendError(res, 500, e.Message);
    end;
    end;
  finally
    jsonreq.Free;
    model.free;
  end;
end;


procedure handlelistdespesasmes(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq, jsonres: TJSONObject;
  id_loja: string;
  date: TDateTime;
  fmt: TFormatSettings;
  model: TDespesasModel;
begin
  jsonreq := nil;
  jsonres := nil;

  fmt.DateSeparator:='/';
  fmt.ShortDateFormat:='dd/mm/yyyy';

  model := TDespesasModel.Create;
  try
    try
      jsonreq := TJSONObject(GetJSON(req.Body));

      date := StrToDate(jsonreq.get('date', '01/01/1900'), fmt);

      id_loja := jsonreq.Get('id_loja', '');

      jsonres := TJSONObject(GetJSON(model.list_despesas_mes(id_loja, date)));

      TJsonView.SendResponse(res, jsonres, 200);

    except on e:exception do
      TJsonView.SendError(res, 500, e.Message);
    end;
  finally
    jsonreq.Free;
    model.Free;
    jsonres.Free;
  end;
end;


procedure handledeletepesasmes(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq: TJSONObject;
  model: TDespesasModel;
  id: integer;
begin
  model := TDespesasModel.Create;
  try
    try
      jsonreq := TJSONObject(GetJSON(req.Body));

      id := jsonreq.find('id_despesa').AsInteger;

      model.delete_despesa(id);

      TJsonView.SendSuccess(res);
    except on e:exception do
      TJsonView.SendError(res, 500, e.Message);
    end;
  finally
    model.Free;
    jsonreq.Free;
  end;
end;


procedure handleupdatepesasmes(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq: TJSONObject;
  descricao, f_pagamento, status: string;
  date, j_data: TDateTime;
  valor: Currency;
  id_despesa: integer;
  fmt: TFormatSettings;
  model: TDespesasModel;
begin
  model := TDespesasModel.Create;
  try
    try
      fmt.DateSeparator:='/';
      fmt.ShortDateFormat:='dd/mm/yyyy';

      jsonreq := TJSONObject(GetJSON(req.Body));

      j_data := StrToDate(jsonreq.find('date').AsString, fmt);

      descricao   := jsonreq.Find('descricao'  ).AsString;
      f_pagamento := jsonreq.Find('f_pagamento').AsString;
      status      := jsonreq.Find('status'     ).AsString;
      valor       := jsonreq.Find('valor'      ).AsFloat;
      id_despesa  := jsonreq.Find('id_despesa' ).AsInteger;
      date        := j_data;

      model.update_despesa(
        descricao,
        f_pagamento,
        status,
        date,
        valor,
        id_despesa
      );

      TJsonView.SendSuccess(res);
    except on e:exception do
      TJsonView.SendError(res, 500, e.Message);
    end;
  finally
    jsonreq.Free;
    model.Free;
  end;
end;


procedure handleupdatepesabaixa(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq: TJSONObject;
  model: TDespesasModel;
begin
  jsonreq := nil;

  model := TDespesasModel.Create;
  try
    try
      jsonreq := TJSONObject(GetJSON(req.Body));

      model.baixa_despesa(
        jsonreq.Find('id_despesa').AsInteger
      );

      TJsonView.SendSuccess(res);
    except on e:exception do
      TJsonView.SendError(res, 500, e.Message);
    end;
  finally
  end;
end;

class procedure TDespesasController.RegisterRoutes();
begin
  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/despesas/create', HandlerCreate);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/despesas/resume', HandleResume);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/despesas/list_mes', handlelistdespesasmes);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/despesas/delete', handledeletepesasmes);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/despesas/update', handleupdatepesasmes);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/despesas/baixa', handleupdatepesabaixa);
end;

end.

