unit uclientsmodel;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, db, fpjson, ugetdata, sql_queries, DateUtils;

type

  { TClientModel }

  TClientModel = class
    public
      procedure deleteClient(id: integer);
      procedure updateClient(nome, telefone, aniversario: string; id:integer; out status_code: integer);
      procedure createClient(nome, telefone, aniversario, id_loja: string);
      function detailCliente(id: integer): UTF8String;
      function listClient(id: string): UTF8String;
      class function listClientA(var id: string; out status_code: integer): UTF8String;
      class function listClientB(var id: string; out status_code: integer): UTF8String;
      class function listClientC(var id: string; out status_code: integer): UTF8String;
      class function listClientMaior(var id: string; out status_code: integer): UTF8String;
      class function listClientMenor(var id: string; out status_code: integer): UTF8String;

  end;


implementation

{ TClientModel }

procedure TClientModel.deleteClient(id: integer);
var
  getDta: TGetData;
begin
  getDta := TGetData.Create;
  try
    getDta.getData(
      sql_queries.delete_cliente_simples,
      [id]
    );
  finally
    getDta.Free;
  end;
end;

procedure TClientModel.updateClient(nome, telefone, aniversario: string;
  id: integer; out status_code: integer);
var
  getDta: TGetData;
begin
  getDta := TGetData.Create;
  try
    try
      getDta.getData(
        sql_queries.update_client_simples,
        [
          nome,
          telefone,
          aniversario,
          id
        ]
      );
      status_code:=200;
    except
    begin
      status_code:=500;
      raise;
    end;
    end;
  finally
    getDta.Free;
  end;
end;

procedure TClientModel.createClient(nome, telefone, aniversario, id_loja: string);
var
  getData: TGetData;
begin
  getData := TGetData.Create;
  try
    try
      getData.getData(
        sql_queries.create_client_simples,
        [
          nome, aniversario, telefone, id_loja
        ]
      );
    except on e:exception do
    begin
      if (Pos('violation of PRIMARY or UNIQUE KEY', E.Message) > 0) or
                 (Pos('duplicate value', LowerCase(E.Message)) > 0) then
        raise Exception.Create('DUPLICIDADE_TELEFONE')
      else
        raise;
    end;
    end;
  finally
    getData.Free;
  end;
end;

function TClientModel.detailCliente(id: integer): UTF8String;
var
  getDta: TGetData;
  dataSet: tdataset;
  jsonRes: TJSONObject;
begin
  getDta := TGetData.Create;
  jsonRes:= TJSONObject.Create;
  try
    dataSet := getDta.getData(
      sql_queries.detail_client_simples,
      [id],
      True
    );
    with dataSet do
    begin
      jsonRes.Add('nome',            FieldByName('nome'           ).AsString);
      jsonRes.Add('telefone',        FieldByName('telefone'       ).AsString);
      jsonRes.Add('data_nascimento', FieldByName('data_nascimento').AsString);
    end;
    Result := jsonRes.AsJSON;
  finally
    getDta.Free;
    jsonRes.Free;
    if Assigned(dataSet) then dataSet.Free;
  end;
end;

function TClientModel.listClient(id: string): UTF8String;
var
  getData: TGetData;
  dataSet: TDataSet;
  jsonRes, json: TJSONObject;
  JsonArray: TJSONArray;
begin
  getData := TGetData.Create;
  try
    dataSet := getData.getData(
      sql_queries.list_client_simples,
      [id],
      True
    );

    JsonArray := TJSONArray.Create;
    with dataSet do
    begin
      first;
      while not eof do
      begin
        json := TJSONObject.Create;

        json.add('id',                FieldByName('id'         ).AsInteger);
        json.Add('nome',              FieldByName('nome'       ).AsString);
        json.add('categoria',         FieldByName('categoria'  ).AsString);
        json.add('telefone',          FieldByName('telefone'   ).AsString);
        json.add('v_gasto',           FieldByName('v_gasto'    ).AsCurrency);
        json.add('data_nascimento',   StringReplace(FieldByName('data_nascimento').AsString, '-', '/', [rfReplaceAll]));
        json.add('data_ultima_compra',StringReplace(FormatDateTime('dd/mm/yyyy',FieldByName('data_ultima_compra').AsDateTime), '-', '/', [rfReplaceAll]));

        JsonArray.Add(json);
        next;
      end;
      jsonRes := TJSONObject.Create;
      jsonRes.Add('message', JsonArray);
      jsonRes.add('count', RecordCount);
    end;
    Result := jsonRes.AsJSON;
  finally
    jsonRes.Free;
    getData.Free;
    dataSet.Free;
  end;
end;

class function TClientModel.listClientA(var id: string; out status_code: integer): UTF8String;
var
  getdata: TGetData;
  dataset: TDataSet;
  jsonitem, jsonres: TJSONObject;
  arraylista: TJSONArray;
begin
  getdata := TGetData.Create;
  arraylista := TJSONArray.Create;
  try
    try
      dataset := getdata.getData(
        sql_queries.list_client_simples_a,
        [id],
        True
      );

      with dataset do
      begin
        first;
        while not eof do
        begin
          jsonitem := TJSONObject.Create;

          jsonitem.add('id',                FieldByName('id'         ).AsInteger);
          jsonitem.Add('nome',              FieldByName('nome'       ).AsString);
          jsonitem.add('categoria',         FieldByName('categoria'  ).AsString);
          jsonitem.add('telefone',          FieldByName('telefone'   ).AsString);
          jsonitem.add('v_gasto',           FieldByName('v_gasto'    ).AsCurrency);
          jsonitem.add('data_nascimento',   StringReplace(FieldByName('data_nascimento').AsString, '-', '/', [rfReplaceAll]));
          jsonitem.add('data_ultima_compra',StringReplace(FormatDateTime('dd/mm/yyyy',FieldByName('data_ultima_compra').AsDateTime), '-', '/', [rfReplaceAll]));

          arraylista.Add(jsonitem);
          next;
        end;
      end;
      jsonres := TJSONObject.Create;
      jsonres.Add('message', arraylista);
      jsonres.Add('count', dataset.RecordCount);

      status_code:=200;
      result := jsonres.AsJSON;

    except on e:exception do
    begin
      status_code:=500;
      jsonitem.add('message', e.Message);

      end;
    end;

  finally
    getdata.Free;
    jsonres.Free;
  end;
end;

class function TClientModel.listClientB(var id: string; out status_code: integer
  ): UTF8String;
var
  getdata: TGetData;
  dataset: TDataSet;
  jsonitem, jsonres: TJSONObject;
  arraylista: TJSONArray;
begin
  getdata := TGetData.Create;
  arraylista := TJSONArray.Create;
  try
    try
      dataset := getdata.getData(
        sql_queries.list_client_simples_b,
        [id],
        True
      );

      with dataset do
      begin
        first;
        while not eof do
        begin
          jsonitem := TJSONObject.Create;

          jsonitem.add('id',                FieldByName('id'         ).AsInteger);
          jsonitem.Add('nome',              FieldByName('nome'       ).AsString);
          jsonitem.add('categoria',         FieldByName('categoria'  ).AsString);
          jsonitem.add('telefone',          FieldByName('telefone'   ).AsString);
          jsonitem.add('v_gasto',           FieldByName('v_gasto'    ).AsCurrency);
          jsonitem.add('data_nascimento',   StringReplace(FieldByName('data_nascimento').AsString, '-', '/', [rfReplaceAll]));
          jsonitem.add('data_ultima_compra',StringReplace(FormatDateTime('dd/mm/yyyy',FieldByName('data_ultima_compra').AsDateTime), '-', '/', [rfReplaceAll]));

          arraylista.Add(jsonitem);
          next;
        end;
      end;
      jsonres := TJSONObject.Create;
      jsonres.Add('message', arraylista);
      jsonres.Add('count', dataset.RecordCount);

      status_code:=200;
      result := jsonres.AsJSON;

    except on e:exception do
    begin
      status_code:=500;
      jsonitem.add('message', e.Message);

      end;
    end;

  finally
    getdata.Free;
    jsonres.Free;
  end;
end;

class function TClientModel.listClientC(var id: string; out status_code: integer
  ): UTF8String;
var
  getdata: TGetData;
  dataset: TDataSet;
  jsonitem, jsonres: TJSONObject;
  arraylista: TJSONArray;
begin
  getdata := TGetData.Create;
  arraylista := TJSONArray.Create;
  try
    try
      dataset := getdata.getData(
        sql_queries.list_client_simples_c,
        [id],
        True
      );

      with dataset do
      begin
        first;
        while not eof do
        begin
          jsonitem := TJSONObject.Create;

          jsonitem.add('id',                FieldByName('id'         ).AsInteger);
          jsonitem.Add('nome',              FieldByName('nome'       ).AsString);
          jsonitem.add('categoria',         FieldByName('categoria'  ).AsString);
          jsonitem.add('telefone',          FieldByName('telefone'   ).AsString);
          jsonitem.add('v_gasto',           FieldByName('v_gasto'    ).AsCurrency);
          jsonitem.add('data_nascimento',   StringReplace(FieldByName('data_nascimento').AsString, '-', '/', [rfReplaceAll]));
          jsonitem.add('data_ultima_compra',StringReplace(FormatDateTime('dd/mm/yyyy',FieldByName('data_ultima_compra').AsDateTime), '-', '/', [rfReplaceAll]));

          arraylista.Add(jsonitem);
          next;
        end;
      end;
      jsonres := TJSONObject.Create;
      jsonres.Add('message', arraylista);
      jsonres.Add('count', dataset.RecordCount);

      status_code:=200;
      result := jsonres.AsJSON;

    except on e:exception do
    begin
      status_code:=500;
      jsonitem.add('message', e.Message);

      end;
    end;

  finally
    getdata.Free;
    jsonres.Free;
  end;
end;

class function TClientModel.listClientMaior(var id: string; out
  status_code: integer): UTF8String;
var
  getdata: TGetData;
  dataset: TDataSet;
  jsonitem, jsonres: TJSONObject;
  arraylista: TJSONArray;
begin
  getdata := TGetData.Create;
  arraylista := TJSONArray.Create;
  try
    try
      dataset := getdata.getData(
        sql_queries.list_client_simples_order_maior_v_gasto,
        [id],
        True
      );

      with dataset do
      begin
        first;
        while not eof do
        begin
          jsonitem := TJSONObject.Create;

          jsonitem.add('id',                FieldByName('id'         ).AsInteger);
          jsonitem.Add('nome',              FieldByName('nome'       ).AsString);
          jsonitem.add('categoria',         FieldByName('categoria'  ).AsString);
          jsonitem.add('telefone',          FieldByName('telefone'   ).AsString);
          jsonitem.add('v_gasto',           FieldByName('v_gasto'    ).AsCurrency);
          jsonitem.add('data_nascimento',   StringReplace(FieldByName('data_nascimento').AsString, '-', '/', [rfReplaceAll]));
          jsonitem.add('data_ultima_compra',StringReplace(FormatDateTime('dd/mm/yyyy',FieldByName('data_ultima_compra').AsDateTime), '-', '/', [rfReplaceAll]));

          arraylista.Add(jsonitem);
          next;
        end;
      end;
      jsonres := TJSONObject.Create;
      jsonres.Add('message', arraylista);
      jsonres.Add('count', dataset.RecordCount);

      status_code:=200;
      result := jsonres.AsJSON;

    except on e:exception do
    begin
      status_code:=500;
      jsonitem.add('message', e.Message);

      end;
    end;

  finally
    getdata.Free;
    jsonres.Free;
  end;

end;

class function TClientModel.listClientMenor(var id: string; out
  status_code: integer): UTF8String;
var
  getdata: TGetData;
  dataset: TDataSet;
  jsonitem, jsonres: TJSONObject;
  arraylista: TJSONArray;
begin
  getdata := TGetData.Create;
  arraylista := TJSONArray.Create;
  try
    try
      dataset := getdata.getData(
        sql_queries.list_client_simples_order_menor_v_gasto,
        [id],
        True
      );

      with dataset do
      begin
        first;
        while not eof do
        begin
          jsonitem := TJSONObject.Create;

          jsonitem.add('id',                FieldByName('id'         ).AsInteger);
          jsonitem.Add('nome',              FieldByName('nome'       ).AsString);
          jsonitem.add('categoria',         FieldByName('categoria'  ).AsString);
          jsonitem.add('telefone',          FieldByName('telefone'   ).AsString);
          jsonitem.add('v_gasto',           FieldByName('v_gasto'    ).AsCurrency);
          jsonitem.add('data_nascimento',   StringReplace(FieldByName('data_nascimento').AsString, '-', '/', [rfReplaceAll]));
          jsonitem.add('data_ultima_compra',StringReplace(FormatDateTime('dd/mm/yyyy',FieldByName('data_ultima_compra').AsDateTime), '-', '/', [rfReplaceAll]));

          arraylista.Add(jsonitem);
          next;
        end;
      end;
      jsonres := TJSONObject.Create;
      jsonres.Add('message', arraylista);
      jsonres.Add('count', dataset.RecordCount);

      status_code:=200;
      result := jsonres.AsJSON;

    except on e:exception do
    begin
      status_code:=500;
      jsonitem.add('message', e.Message);

      end;
    end;

  finally
    getdata.Free;
    jsonres.Free;
  end;

end;


end.

