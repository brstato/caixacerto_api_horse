unit ucaixacontroller;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, fpjson, ucaixamodel, uzapmodel, Horse, uJsonView,
  Horse.JWT, udata, uNetService, Variants, db;

type

  { TCaixaController }

  TCaixaController = class
    public
      class procedure RegisterRoutes();
  end;

implementation

{ TCaixaController }


procedure HandlerItensList(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  model: TCaixaModel;
  jsonReq, jsonRes: TJSONObject;
  id_loja: string;
begin
  model := TCaixaModel.Create;
  try
    jsonReq := TJSONObject(GetJSON(req.Body));
    id_loja := jsonReq.Find('id_loja').AsString;
    jsonRes := TJSONObject(GetJSON(model.listItens(id_loja)));
    TJsonView.SendResponse(res, jsonRes, 200);
  finally
    jsonRes.Free;
    jsonReq.Free;
    model.Free;
  end;
end;


procedure HandlerclientList(req: THorseRequest; res: THorseResponse;
  next: TNextProc);
var
  model: TCaixaModel;
  id: string;
  jsonReq, jsonRes: TJSONObject;
begin
  model := TCaixaModel.Create;
  try
    jsonReq := TJSONObject(GetJSON(req.Body));

    id := jsonReq.Find('id_loja').AsString;

    jsonRes := TJSONObject(
      GetJSON(
        model.listClient(id)
      )
    );

    TJsonView.SendResponse(res, jsonRes, 200);

  finally
    jsonRes.Free;
    jsonReq.Free;
    model.Free;
  end;
end;


procedure HandlerAbrirCaixa(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonReq: TJSONObject;
  model: TCaixaModel;
  id_loja:string;
  troco:currency;
  id_func:integer;
  id_caixa:integer;
  jsonRes: TJSONObject;
begin
  model := TCaixaModel.Create;
  jsonReq := TJSONObject(GetJSON(req.Body));
  try
    id_func := jsonReq.Find('pr_abriu').AsInteger;
    troco   := StrToCurr(jsonReq.Find('troco_abertura').AsString);
    id_loja := jsonReq.Find('id_loja').AsString;

    id_caixa := model.abrirCaixa(
      id_loja,
      troco,
      id_func
    );
    jsonRes := TJSONObject.Create;

    jsonRes.Add('id_caixa', id_caixa);
    TJsonView.SendResponse(res, jsonRes, 200);
  finally
    jsonReq.Free;
    jsonRes.Free;
    model.Free;
  end;
end;


procedure HandlerFecharCaixa(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonReq: TJSONObject;
  model: TCaixaModel;
  troco, dinheiro, pix, debito, credito:currency;
  id_func, id, id_caixa:integer;
begin
  model := TCaixaModel.Create;
  jsonReq := TJSONObject(GetJSON(req.Body));
  try
    id_func  := jsonReq.Find('id_func').AsInteger;
    id_caixa := jsonReq.Find('id_caixa').AsInteger;

    troco    := StrToCurr(jsonReq.Find('troco'   ).AsString);
    dinheiro := StrToCurr(jsonReq.Find('dinheiro').AsString);
    pix      := StrToCurr(jsonReq.Find('pix'     ).AsString);
    debito   := StrToCurr(jsonReq.Find('debito'  ).AsString);
    credito  := StrToCurr(jsonReq.Find('credito' ).AsString);

    model.fecharcaixa(
      id_caixa,
      id_func,
      troco,
      dinheiro,
      pix,
      debito,
      credito
    );
  finally
    jsonReq.Free;
    model.Free;
  end;
end;


procedure HandlerIDCaixa(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  model: TCaixaModel;
  id: integer;
  jsonRes, jsonReq: TJSONObject;
  id_loja: string;
  dataset:TDataSet;
begin
  model := TCaixaModel.Create;
  try
    jsonReq := TJSONObject(GetJSON(req.Body));

    id_loja := jsonReq.Find('id_loja').AsString;

    jsonRes := TJSONObject(GetJSON(model.status_caixa(id_loja)));

    TJsonView.SendResponse(res, jsonRes, 200);
  finally
    model.Free;
    jsonReq.Free;
    jsonRes.Free;
  end;
end;


procedure HandlerVendas(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  model: TCaixaModel;
  jsonreq: TJSONObject;
  Dados: TVendaDados;
begin
  try
    model := TCaixaModel.Create;
    try
       jsonreq := TJSONObject(GetJSON(req.Body));

       Dados.id_loja        :=jsonreq.find('id_loja'  ).AsString;
       Dados.id_cliente     :=jsonreq.find('id_client').AsInteger;
       Dados.id_caixa       :=jsonreq.find('id_caixa' ).AsInteger;
       Dados.id_profissional:=jsonreq.find('id_prof'  ).AsInteger;
       Dados.comissao       :=jsonreq.find('comission').AsInteger;
       Dados.valor          :=jsonreq.find('total'    ).AsFloat;
       Dados.din            :=jsonreq.find('din'      ).AsFloat;
       Dados.pix            :=jsonreq.find('pix'      ).AsFloat;
       Dados.deb            :=jsonreq.find('deb'      ).AsFloat;
       Dados.cred           :=jsonreq.find('cred'     ).AsFloat;
       Dados.troco          :=jsonreq.find('troco'    ).AsFloat;
       Dados.itens          :=jsonreq.find('itens'    ).AsString;

       model.venda(Dados);

       TJsonView.SendSuccess(res);

    except on e:exception do
       TJsonView.SendError(res, 500, e.Message);
    end;
  finally
    jsonreq.Free;
    model.Free;
  end;
end;


procedure HandlerInsumos(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  model: TCaixaModel;
  id_loja: string;
  jsonreq, jsonres: TJSONObject;
begin
  model := TCaixaModel.create;
  try
    jsonreq := TJSONObject(GetJSON(req.Body));

    id_loja := jsonreq.Find('id_loja').AsString;

    jsonres := TJSONObject(GetJSON(model.list_insumo(id_loja)));

    TJsonView.SendResponse(res, jsonres, 200);
  finally
    model.Free;
    jsonreq.Free;
    jsonres.Free;
  end;
end;

procedure HandlerUpdateInsumos(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  model: TCaixaModel;
  jsonreq, jsoniten: TJSONObject;
  jsonarray: TJSONArray;
  i, id, quantidade: integer;
begin
  model := TCaixaModel.create;
  try
    try
      jsonreq := TJSONObject(GetJSON(req.Body));

      jsonarray := jsonreq.Find('itens') as TJSONArray;

      for i := 0 to jsonarray.Count -1 do
      begin
        jsoniten := jsonarray.Items[i] as TJSONObject;

        id := jsoniten.Find('id').AsInteger;
        quantidade:=jsoniten.Find('quantidade').AsInteger;

        model.update_insumos(
          id,
          quantidade
        );
      end;

      TJsonView.SendSuccess(res);
    except on e:exception do
      TJsonView.SendError(res, 500, e.Message);
    end;
  finally
    jsonreq.Free;
    model.Free;
  end;
end;


procedure HandlerUpdateNotaCliente(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq: TJSONObject;
  model: TCaixaModel;
  id: integer;
  nota: string;
begin
  model := TCaixaModel.create;
  try
    jsonreq := TJSONObject(GetJSON(req.Body));

    id   := jsonreq.Find('id').AsInteger;
    nota := jsonreq.find('nota').AsString;

    model.update_nota_cliente(id, nota);
  finally
    model.Free;
    jsonreq.Free;
  end;
end;



class procedure TCaixaController.RegisterRoutes();
begin
  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/caixa/itens/list', HandlerItensList);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/caixa/client/list', HandlerclientList);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/caixa/abrir_caixa', HandlerAbrirCaixa);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/caixa/fechar_caixa', HandlerFecharCaixa);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/caixa/status', HandlerIDCaixa);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/caixa/venda', HandlerVendas);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/caixa/insumo', HandlerInsumos);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/caixa/insumo/update', HandlerUpdateInsumos);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/caixa/cliente/update_nota', HandlerUpdateNotaCliente);
end;

end.

