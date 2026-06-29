unit URelatoriosController;

{$mode Delphi}

interface

uses
  Classes, SysUtils, udata, fpjson, Horse, uJsonView, URelatoriosModel,
  Horse.JWT;

type

  { TRelatoriosController }

  TRelatoriosController = class
    public
      class procedure RegisterRoutes();
  end;

implementation

{ TRelatoriosController }


procedure HandlerRelatorioEntradas(req: THorseRequest; res: THorseResponse;
  next: TNextProc);
var
  id_loja: string;
  dm: TDataModule1;
  mes, ano: Integer;
  jsonReq, jsonRes: TJSONObject;
  Response: TJSONArray;
begin
  dm := TDataModule1.Create(nil);
  jsonRes := TJSONObject.Create;
  jsonReq := nil;
  try
    try
     id_loja := dm.GetIdLoja(req.Headers['Authorization']);

     jsonReq := TJSONObject(GetJSON(req.Body));

     mes := jsonReq.Find('mes').AsInteger;
     ano := jsonReq.Find('ano').AsInteger;

     Response := TRelatoriosModel.relatorio_entradas(id_loja, mes, ano);

     jsonRes.Add('response', Response);

     TJsonView.SendResponseJsonObject(res, jsonRes, 200);
    except on e:exception do
    begin
      WriteLn('Erro na rota relatorios/entradas: ' + e.Message);
      TJsonView.SendError(res, 500, e.Message);
      if Assigned(jsonRes) then jsonRes.Free;
    end;
    end;
  finally
    dm.Free;
    jsonReq.Free;
  end;
end;


procedure HandlerRelatorioEntradasGraficos(req: THorseRequest; res: THorseResponse;
  next: TNextProc);
var
  id_loja: string;
  dm: TDataModule1;
  jsonRes: TJSONObject;
  Response: TJSONArray;
begin
  dm := TDataModule1.Create(nil);
  jsonRes := TJSONObject.Create;
  try
    try
      id_loja := dm.GetIdLoja(req.Headers['Authorization']);

      Response := TRelatoriosModel.entradas_grafico(id_loja);

      jsonRes.Add('response', Response);

      TJsonView.SendResponseJsonObject(res, jsonRes, 200);
    except on e:exception do
    begin
      WriteLn('Erro na rota relatorios/graficos: ' + e.Message);
      TJsonView.SendError(res, 500, e.Message);
      if Assigned(jsonRes) then jsonRes.Free;
    end;
    end;
  finally
    dm.Free;
  end;
end;

procedure HandlerRelatorioEntradasDetalhes(req: THorseRequest; res: THorseResponse;
  next: TNextProc);
var
  dm: TDataModule1;
  id_venda: integer;
  jsonReq, jsonRes: TJSONObject;
  Response: TJSONArray;
begin
  dm := TDataModule1.Create(nil);

  jsonReq := nil;
  jsonReq := nil;
  try
    try
      jsonReq := TJSONObject(GetJSON(req.Body));

      if not Assigned(jsonReq.Find('id_venda')) then
              raise Exception.Create('Parâmetro id_venda não informado.');

      id_venda := jsonReq.find('id_venda').AsInteger;

      Response := TRelatoriosModel.entrada_detalhes(id_venda);

      jsonRes := TJSONObject.Create;
      jsonRes.Add('response', Response);

      TJsonView.SendResponseJsonObject(res, jsonRes, 200);

    except on e:exception do
    begin
      WriteLn('Erro na rota relatorios/detalhes: ' + e.Message);
      TJsonView.SendError(res, 500, e.Message);
      if Assigned(jsonRes) then jsonRes.Free;
    end;
    end;
  finally
    if Assigned(dm) then dm.Free;
    if Assigned(jsonReq) then jsonReq.Free;
  end;
end;

class procedure TRelatoriosController.RegisterRoutes();
begin
  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/relatorio/entradas', HandlerRelatorioEntradas);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Get('api/v1/relatorio/entradas_grafico', HandlerRelatorioEntradasGraficos);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/relatorio/entrada_detalhes', HandlerRelatorioEntradasDetalhes);
end;

end.

