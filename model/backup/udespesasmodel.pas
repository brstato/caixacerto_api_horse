unit udespesasmodel;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, db, fpjson, ugetdata, sql_queries, DateUtils;

type

  { TDespesasModel }

  TDespesasModel = class
     procedure criar_depesa(descricao, status, f_pagamento, id_loja: string;
       valor: Currency; qtd: integer; date: TDateTime);
     function list_resume(id_loja:string): UTF8String;
     function list_despesas_mes(id_loja: string; date: TDateTime): UTF8String;
     procedure delete_despesa(id: integer);
     procedure update_despesa(descricao, f_pagamento, status: string; date: TDateTime; valor: Currency; id: integer);
     procedure baixa_despesa(id: integer);
  end;



implementation

{ TDespesasModel }

procedure TDespesasModel.criar_depesa(descricao, status, f_pagamento,
  id_loja: string; valor: Currency; qtd: integer; date: TDateTime);
var
  getdata: TGetData;
begin
  getdata := TGetData.Create;
  try
    try
      getdata.getData(
        sql_queries.criar_despesa,
        [
          descricao,
          status,
          valor,
          qtd,
          f_pagamento,
          date,
          id_loja
        ]
      );
    except on e:exception do
        raise
    end;
  finally
    getdata.Free;
  end;
end;


function TDespesasModel.list_resume(id_loja: string): UTF8String;
var
  getdata: TGetData;
  dataset: TDataSet;
  jsonres, jsoniten: TJSONObject;
  jsonarray: TJSONArray;
begin
  jsonres := nil;
  dataset := nil;

  getdata := TGetData.Create;
  try
    dataset := getdata.getData(
      sql_queries.list_resume_despesas,
      [id_loja],
      True
    );
    if Assigned(dataset) then
    begin
      with dataset do
      begin
        first;
        jsonres := TJSONObject.Create;
        jsonarray := TJSONArray.Create;
        while not eof do
        begin
          jsoniten := TJSONObject.Create;

          jsoniten.Add('ano',           FieldByName('r_ano'          ).AsInteger );
          jsoniten.Add('mes',           FieldByName('r_mes'          ).AsInteger );
          jsoniten.Add('total_pago',    FieldByName('r_total_pago'   ).AsCurrency);
          jsoniten.Add('total_a_pagar', FieldByName('r_total_a_pagar').AsCurrency);
          jsoniten.Add('total_geral',   FieldByName('r_total_geral'  ).AsCurrency);

          jsonarray.Add(jsoniten);
          next;
        end;
      end;
      jsonres.Add('message', jsonarray);
      Result := jsonres.AsJSON;
    end;
  finally
    getdata.Free;
    if Assigned(dataset) then
       dataset.Free;
    if Assigned(jsonres) then
       jsonres.Free;
  end;
end;


function TDespesasModel.list_despesas_mes(id_loja: string; date: TDateTime): UTF8String;
var
  getdata: TGetData;
  dataset: TDataSet;
  jsonres, jsoniten: TJSONObject;
  JSONArray: TJSONArray;

  // Variáveis auxiliares de data
  DataIni, DataFim: TDateTime;
  SDataIni, SDataFim: String;

  TotalGeral: Currency;
begin
  dataset    := nil;
  JSONArray  := nil;
  jsonres    := nil;
  TotalGeral := 0;

  // 1. Lógica de Datas (Delphi calcula, Banco recebe pronto)
  DataIni  := StartOfTheMonth(date); // Ex: 01/02/2026
  DataFim  := IncMonth(DataIni);     // Ex: 01/03/2026

  SDataIni := FormatDateTime('yyyy-mm-dd', DataIni);
  SDataFim := FormatDateTime('yyyy-mm-dd', DataFim);

  getdata := TGetData.Create;
  try
    dataset := getdata.getData(
      sql_queries.list_despesas_por_mes_e_residuo,
      // 2. Passagem de parâmetros na ordem da Procedure (ID, INI, FIM)
      [id_loja, SDataIni, SDataFim],
      True
    );

    JSONArray := TJSONArray.Create;

    if Assigned(dataset) then
    begin
      with dataset do
      begin
        First;
        // Captura o total geral da primeira linha (se houver dados)
        if not Eof then
           TotalGeral := FieldByName('R_TOTAL_GERAL').AsCurrency;

        while not eof do
        begin
          jsoniten := TJSONObject.Create; // CRÍTICO: Criação do objeto

          // Note o prefixo "R_" que definimos na procedure
          jsoniten.Add('id',              FieldByName('R_ID'             ).AsInteger );
          jsoniten.Add('descricao',       FieldByName('R_DESCRICAO'      ).AsString  );
          jsoniten.Add('valor',           FieldByName('R_VALOR'          ).AsCurrency);
          jsoniten.Add('status',          FieldByName('R_STATUS'         ).AsString  );
          jsoniten.Add('parcela',         FieldByName('R_PARCELA'        ).AsString  );
          jsoniten.Add('tipo_registro',   FieldByName('R_ORIGEM'         ).AsString  );

          jsoniten.Add('data_vencimento', FormatDateTime('dd/mm/yyyy', FieldByName('R_DATA_VENCIMENTO').AsDateTime));

          JSONArray.Add(jsoniten);
          next;
        end;
      end;
    end;

    jsonres := TJSONObject.Create;
    jsonres.Add('total_periodo', TotalGeral);
    jsonres.Add('message', JSONArray);

    Result := jsonres.AsJSON;
  finally
    getdata.Free;
    if Assigned(dataset) then dataset.Free;
    if Assigned(jsonres) then jsonres.Free;
  end;
end;

procedure TDespesasModel.delete_despesa(id: integer);
var
  getdata: TGetData;
begin
  getdata := TGetData.Create;
  try
    getdata.getData(
      sql_queries.delete_despesa,
      [id]
    );
  finally
    getdata.Free;
  end;
end;

procedure TDespesasModel.update_despesa(descricao, f_pagamento, status: string;
  date: TDateTime; valor: Currency; id: integer);
var
  getdata: TGetData;
  data_formatada: string;
begin
  getdata := TGetData.Create;
  data_formatada := FormatDateTime('yyyy-mm-dd',date);
  try
    getdata.getData(
      sql_queries.update_despesa,
      [
        descricao,
        f_pagamento,
        status,
        data_formatada,
        valor,
        id
      ]
    );
  finally
    getdata.Free;
  end;
end;

procedure TDespesasModel.baixa_despesa(id: integer);
var
  getdata: TGetData;
begin
  getdata := TGetData.Create;
  try
    getdata.getData(
      sql_queries.update_baixa_despesa,
      [id]
    );
  finally
    getdata.Free;
  end;
end;

end.

