unit uagendacontroller;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Horse, Horse.JWT, uagendamodel, uJsonView, udata,
  uNetService, fpjson, jsonparser;

type

  { TAgendaController }

  TAgendaController = class
    public
       class procedure RegisterRoutes();
  end;

implementation

{ TAgendaController }

procedure HandlerAgendaList(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonres, jsonReq: TJSONObject;
  model: TAgendaModel;
  id: integer;
  date:string;
begin
  jsonres := nil;

  model := TAgendaModel.Create;
  try
    jsonReq := TJSONObject(GetJSON(req.Body));

    id   := jsonReq.find('id'  ).AsInteger;
    date := jsonReq.Find('data').AsString;

    jsonres := TJSONObject(GetJSON(model.listAgendamentos(id, date)));

    TJsonView.SendResponse(res, jsonres, 200);
  finally
    jsonres.Free;
    jsonReq.Free;
    model.Free;
  end;
end;

procedure HandlerAgendaResumo(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  model: TAgendaModel;
  jsonreq, jsonres: TJSONObject;
  jsonitens: TJSONArray;
  id: integer;
  date:string;
begin
  model := TAgendaModel.Create;
  try
    jsonreq := TJSONObject(GetJSON(req.Body));

    id   := jsonreq.Find('id'  ).AsInteger;
    date := jsonreq.find('data').AsString;

    jsonitens := TJSONArray(GetJSON(model.listResumoAgenda(id, date)));

    jsonres := TJSONObject.Create;

    jsonres.Add('message', jsonitens);

    TJsonView.SendResponse(res, jsonres, 200);
  finally
    jsonitens.Free;
    jsonreq.Free;
    model.Free;
  end;
end;

procedure HandlerAgendaCreate(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq: TJSONObject;
  model: TAgendaModel;
  date_obj: TDateTime;
  fmt: TFormatSettings;
  status_code: integer;
  sinal, valor: currency;
  sinal_str, valor_str: string;
begin
  model := TAgendaModel.Create;
  try
    try
      jsonreq := TJSONObject(GetJSON(req.Body));

      fmt.DateSeparator:='/';
      fmt.ShortDateFormat:='dd/mm/yyyy';

      date_obj:= StrToDate(jsonreq.Find('date').AsString, fmt);

      sinal_str := jsonreq.find('sinal').AsString;
      valor_str := jsonreq.find('valor').AsString;

      sinal := StrToCurrDef(sinal_str, 0);
      valor := StrToCurrDef(valor_str, 0);

      model.createAgendamento(
        jsonreq.find('id_prof'    ).AsInteger,
        jsonreq.find('id_client'  ).AsInteger,
        jsonreq.find('hora_ini'   ).AsString,
        jsonreq.find('hora_fim'   ).AsString,
        jsonreq.find('client_name').AsString,
        jsonreq.find('telefone'   ).AsString,
        jsonreq.find('event_id'   ).AsString,
        jsonreq.find('id_loja'    ).AsString,
        date_obj,
        status_code,
        valor,
        sinal
      );
      TJsonView.SendSuccess(res);
    except on e:Exception do
      TJsonView.SendError(res, status_code, e.Message);
    end;
  finally
    jsonreq.Free;
    model.Free;
  end;
end;

procedure HandlerAgendaDelete(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  model: TAgendaModel;
  jsonreq: TJSONObject;
  id: integer;
begin
  model := TAgendaModel.Create;
  try
    jsonreq := TJSONObject(GetJSON(req.Body));
    id := jsonreq.Find('id').AsInteger;
    model.deleteAgendamento(id);
  finally
    model.Free;
    jsonreq.Free;
  end;
end;

procedure HandlerAgendaDetail(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  model: TAgendaModel;
  jsonreq, jsonres: TJSONObject;
begin
  jsonreq := TJSONObject(GetJSON(req.Body));
  model := TAgendaModel.Create;
  try
    jsonres := TJSONObject(GetJSON(model.detailAgendamento(jsonreq.Find('id').AsInteger)));

    TJsonView.SendResponse(res, jsonres, 200);
  finally
    model.Free;
    jsonreq.Free;
    jsonres.Free;
  end;
end;

procedure HandlerAgendaUpdate(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  model: TAgendaModel;
  jsonreq: TJSONObject;
  date_obj: TDateTime;
  fmt: TFormatSettings;
  status_code:integer;
begin
  model := TAgendaModel.Create;
  try
    try
      jsonreq := TJSONObject(GetJSON(req.Body));

      fmt.DateSeparator:='/';
      fmt.ShortDateFormat:='dd/mm/yyyy';

      date_obj:= StrToDate(jsonreq.Find('date').AsString, fmt);

      model.updateAgendamento(
        jsonreq.find('id'       ).AsInteger,
        jsonreq.find('id_prof'  ).AsInteger,
        jsonreq.find('id_client').AsInteger,
        StrToCurrDef(jsonreq.find('valor').AsString, 0),
        StrToCurrDef(jsonreq.find('sinal').AsString, 0),
        jsonreq.find('telefone').AsString,
        jsonreq.find('client'  ).AsString,
        jsonreq.find('hora_ini').AsString,
        jsonreq.find('hora_fim').AsString,
        jsonreq.find('event_id').AsString,

        date_obj,
        status_code
    );
    TJsonView.SendSuccess(res);
    except on e:Exception do
      TJsonView.SendError(res, status_code, e.Message);
    end;
  finally
    model.Free;
    jsonreq.Free;
  end;
end;

procedure HandlerSendConfirmation(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq, message, instance: TJSONObject;
  status_code: integer;
  instance_str, message_str: string;
begin
  jsonreq := TJSONObject(GetJSON(req.Body));
  try
    try
      instance_str := jsonreq.find('instance').AsJSON;
      instance := TJSONObject(GetJSON(instance_str));
      instance_str := instance.AsJSON;
      instance_str := instance.Find('zap_instance').AsString;

      message_str  := jsonreq.find('message').AsJSON;
      message := TJSONObject(GetJSON(message_str));

      TNetService.post(
        'http://100.72.176.93:8080/message/sendText/'+instance_str,
        'apikey',
        'B8394857-B21runo89',
        message.AsJSON,
        status_code
      );
      TJsonView.SendSuccess(res);
    except on e:Exception do
      TJsonView.SendError(res, status_code, e.Message);
    end;
  finally
    jsonreq.Free;
    message.Free;
    instance.Free;
  end;
end;

procedure HandlerCheckAvailability(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  model: TAgendaModel;
  jsonReq, jsonRes: TJSONObject;
  telefone_loja: string;
  id_profissional: integer;
begin
  model := TAgendaModel.Create;
  try
    try
      jsonReq := TJSONObject(GetJSON(req.Body));

      telefone_loja   := jsonReq.Find('telefone_loja'  ).AsString;
      id_profissional := jsonReq.Find('id_profissional').AsInteger;

      jsonRes := TJSONObject(GetJSON(model.getDisponibilidadePublica(telefone_loja, id_profissional)));

      TJsonView.SendResponse(res, jsonRes, 200);
    except on E: Exception do
      TJsonView.SendError(res, 500, 'Erro: ' + E.Message);
    end;
  finally
    if Assigned(jsonReq) then jsonReq.Free;
    model.Free;
    jsonRes.Free;
  end;
end;

procedure HandlerListClientTel(req: THorseRequest; res: THorseResponse);
var
  jsonreq, jsonres: TJSONObject;
  model: TAgendaModel;
  telefone: string;
  status: integer;
begin
  model := TAgendaModel.Create;
  try
    try
      jsonreq := TJSONObject(GetJSON(req.Body));

      telefone := jsonreq.Find('telefone').AsString;

      jsonres := TJSONObject(GetJSON(model.getclientetelefone(telefone, status)));

      if status = 200 then
        TJsonView.SendResponse(res, jsonres, status)
      else if status = 404 then
        TJsonView.SendError(res, status, 'Não encontrado!');
    except on e:exception do
      TJsonView.SendError(res, 500, e.Message);
    end;
  finally
    model.Free;
    jsonreq.Free;
    jsonres.Free;
  end;
end;

procedure HandlerListProfissionalId(req: THorseRequest; res: THorseResponse);
var
  jsonreq, jsonres: TJSONObject;
  model: TAgendaModel;
  id: integer;
begin
  model := TAgendaModel.Create;
  jsonres := nil;
  jsonreq := nil;
  try
    try
      jsonreq := TJSONObject(GetJSON(req.Body));

      id := jsonreq.Find('id').AsInteger;

      jsonres := TJSONObject(GetJSON(model.getprofissionaisid(id)));

      TJsonView.SendResponse(res, jsonres, 200);
    except on e:exception do
      TJsonView.SendError(res, 500, e.Message);
    end;
  finally
    model.Free;
    jsonreq.Free;
    jsonres.Free;
  end;
end;

procedure HandlerTurnos(req: THorseRequest; res: THorseResponse);
var
  jsonreq, jsonres: TJSONObject;
  model: TAgendaModel;
  telefone:string;
begin
  model := TAgendaModel.Create;
  try
    try
      jsonreq := TJSONObject(GetJSON(req.Body));

      telefone := jsonreq.Find('telefone').AsString;

      jsonres := TJSONObject(GetJSON(model.buscadadosagendaturnos(telefone)));

      TJsonView.SendResponse(res, jsonres, 200);
    except on e:exception do
      TJsonView.SendError(res, 500, e.Message);
    end;
  finally
    model.Free;
    jsonreq.Free;
    jsonres.Free;
  end;
end;

procedure HandleSolicitarAgendamento(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  RequestJson, ResponseJson: TJSONObject;
  idProfissional, id_cliente: Integer;
  cliente, telefone, data, horaIni, horaFim, uuid: string;
begin
  RequestJson := nil;
  ResponseJson := TJSONObject.Create;

  try
    try
      // Lê o Body da requisição
      RequestJson := TJSONObject(GetJSON(Req.Body));

      // Extrai os campos (com fallback para vazio/zero caso falte algo)
      id_cliente     := RequestJson.Find('cliente_id'     ).AsInteger;
      idProfissional := RequestJson.find('id_profissional').AsInteger;
      uuid           := RequestJson.Find('uuid'           ).AsString;
      cliente        := RequestJson.find('cliente'        ).AsString;
      telefone       := RequestJson.find('telefone'       ).AsString;
      data           := RequestJson.find('data'           ).AsString;
      horaIni        := RequestJson.find('hora_ini'       ).AsString;
      horaFim        := RequestJson.find('hora_fim'       ).AsString;

      // Validação básica
      if (idProfissional = 0) or (telefone = '') or (data = '') then
      begin
        ResponseJson.Add('message', 'Dados incompletos para agendamento.');
        TJsonView.SendResponse(Res, ResponseJson, 400);
        Exit;
      end;

      // Chama o Model para gravar no banco
      if TAgendaModel.SolicitarAgendamento(
        idProfissional,
        id_cliente,
        cliente,
        telefone,
        data,
        horaIni,
        horaFim,
        uuid
      ) then
      begin
        ResponseJson.Add('message', 'Agendamento solicitado com sucesso.');
        TJsonView.SendResponse(Res, ResponseJson, 201); // 201 = Created
      end;

    except
      on E: Exception do
      begin
        ResponseJson.Add('message', 'Erro interno do servidor: ' + E.Message);
        TJsonView.SendResponse(Res, ResponseJson, 500);
      end;
    end;
  finally
    if Assigned(RequestJson) then RequestJson.Free;
    if Assigned(ResponseJson) then ResponseJson.Free;
  end;
end;

procedure HandleListarPendentes(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  idProfissional: Integer;
  JsonArray: TJSONArray;
  ResponseJson, jsonreq: TJSONObject;
begin
  try
    try
      jsonreq := TJSONObject(GetJSON(Req.Body));
      idProfissional := jsonreq.Find('id_profissional').AsInteger;
    except
      TJsonView.SendError(Res, 400, 'ID do profissional inválido ou não fornecido.');
      Exit;
    end;

    try
      // Chama o Model
      JsonArray := TJSONArray(GetJSON(TAgendaModel.ListarPendentes(idProfissional)));
      ResponseJson := TJSONObject.Create;
      // Anexa o array ao objeto de resposta
      ResponseJson.Add('pendentes', JsonArray);

      TJsonView.SendResponse(Res, ResponseJson, 200); // 200 OK

    except
      on E: Exception do
      begin
        ResponseJson.Add('message', 'Erro interno: ' + E.Message);
        TJsonView.SendResponse(Res, ResponseJson, 500); // Erro de Servidor
      end;
    end;

  finally
    jsonreq.Free;
    ResponseJson.Free;

    // Não precisamos libertar o JsonArray manualmente aqui porque, ao fazer
    // ResponseJson.Add('pendentes', JsonArray), o ResponseJson passa a ser
    // o "dono" do array e destrói-o automaticamente no Free acima.
  end;
end;

procedure HandleNotificaPendentes(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq, jsonres: TJSONObject;
  id_loja: string;
  count: integer;
begin
  try
    try
      jsonreq := TJSONObject(GetJSON(req.Body));

      id_loja := jsonreq.Find('id_loja').AsString;

      count := TAgendaModel.notificacao_pendentes(id_loja);

      jsonres := TJSONObject.Create;

      jsonres.Add('count', count);

      TJsonView.SendResponse(res, jsonres, 200);
    except on e:exception do
      TJsonView.SendError(res, 500, e.Message);
    end;
  finally
    jsonreq.Free;
    jsonres.Free;
  end;
end;

class procedure TAgendaController.RegisterRoutes();
begin
  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/agenda/notifica', HandleNotificaPendentes);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/agenda/pendentes', HandleListarPendentes);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/agenda/list', HandlerAgendaList);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/agenda/resume', HandlerAgendaResumo);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/agenda/create', HandlerAgendaCreate);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/agenda/delete', HandlerAgendaDelete);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/agenda/detail', HandlerAgendaDetail);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/agenda/update', HandlerAgendaUpdate);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/agenda/send_confirmation', HandlerSendConfirmation);

  THorse.Post('api/v1/public/agenda/check', HandlerCheckAvailability);

  THorse.Post('api/v1/public/agenda/list_client_tel', HandlerListClientTel);

  THorse.Post('api/v1/public/agenda/list_profissional_id', HandlerListProfissionalId);

  THorse.Post('api/v1/public/agenda/turnos', HandlerTurnos);

  THorse.Post('/api/v1/public/agenda/solicitar', HandleSolicitarAgendamento);
end;

end.

