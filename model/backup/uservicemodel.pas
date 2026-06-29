unit uservicemodel;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, ugetdata, fpjson, db, sql_queries;

type
  TServicesData = record
    nome,
    comissionado,
    inf_valor,
    id:string;
    valor_custo,
    valor_venda: currency;
    comissao,
    margem: integer;
  end;

type

  { TServiceModel }

  TServiceModel = class
    public
      function ListService(const id: string):UTF8String;
      function DetailService(const id: integer): UTF8String;
      procedure CreateService(json: TJSONObject);
      procedure deleteService(id: integer);
      procedure updateService(json: TJSONObject);
  end;

implementation

{ TServiceModel }

function calcMargem(custo, venda: currency): integer;
begin
   if custo = 0 then
      Result := 0
    else
      Result := round(((venda - custo) / custo) * 100);
end;

function TServiceModel.ListService(const id: string): UTF8String;
var
   gtData: TGetData;
   dataSet: TDataSet;
   jsonArray: TJSONArray;
   jsonObj, jsonResponse: TJSONObject;
begin
  gtData := TGetData.Create;
  jsonArray := TJSONArray.Create;
  jsonResponse := TJSONObject.Create;
  try
    dataSet:=gtData.getData(
      sql_queries.list_services_simples,
      [id],
      true
    );
    if dataSet.RecordCount > 0 then
    begin
      with dataSet do
      begin
        First;
        while not eof do
        begin
          jsonObj := TJSONObject.Create;

          jsonObj.Add('nome',        FieldByName('nome'     ).AsString);
          jsonObj.Add('margem',      FieldByName('margem'   ).AsString);

          jsonObj.Add('vendas',      FieldByName('vendas'     ).AsCurrency);
          jsonObj.Add('valor_custo', FieldByName('valor_custo').AsCurrency);
          jsonObj.Add('valor_venda', FieldByName('valor_venda').AsCurrency);

          jsonObj.Add('id',          FieldByName('id'     ).AsInteger);
          jsonObj.Add('comissao',    FieldByName('comicao').AsInteger);

          jsonArray.Add(jsonObj);

          next;
        end;
        jsonResponse.Add('message', jsonArray);
      end;
    end
    else
    begin
        jsonObj := TJSONObject.Create;

        jsonObj.Add('nome',       '');
        jsonObj.Add('valor_custo','');
        jsonObj.Add('valor_venda','');
        jsonObj.Add('inf_valor',  '');
        jsonObj.Add('margem',     '');
        jsonObj.Add('comicao',    '');
        jsonObj.Add('vendas',     '');
        jsonObj.Add('id',         '');
        jsonObj.Add('comissao',   '');

        jsonArray.Add(jsonObj);

        jsonResponse.Add('message', jsonArray);
    end;
  finally
    gtData.Free;
    dataSet.Free;
    Result:=jsonResponse.AsJSON;
    jsonResponse.Free;
  end;
end;

function TServiceModel.DetailService(const id: integer): UTF8String;
var
   getDta: TGetData;
   dataSet: TDataSet;
   jsonObj: TJSONObject;
begin
   getDta := TGetData.Create;
   jsonObj := TJSONObject.Create;
   try
     dataSet := getDta.getData(
       sql_queries.detail_service_simples,
       [id],
       True
     );

     with dataSet do
     begin
       jsonObj.Add('id',          FieldByName('id'          ).AsInteger);
       jsonObj.add('nome',        FieldByName('nome'        ).AsString );
       jsonObj.add('valor_custo', FieldByName('valor_custo' ).AsFloat  );
       jsonObj.add('valor_venda', FieldByName('valor_venda' ).AsFloat  );
       jsonObj.Add('inf_valor',   FieldByName('inf_valor'   ).AsString );
       jsonObj.add('comissao',    FieldByName('comicao'     ).AsInteger);
       jsonObj.add('comissionado',FieldByName('comissionado').AsString );
     end;
     Result := jsonObj.AsJSON;
   finally
     getDta.Free;
     jsonObj.Free;
     dataSet.Free;
   end;
end;

procedure TServiceModel.CreateService(json: TJSONObject);
var
   data: TServicesData;
begin
   try
     with data do
     begin
       nome        :=json.Find('nome'        ).AsString;
       comissionado:=json.Find('comissionado').AsString;
       inf_valor   :=json.Find('inf_valor'   ).AsString;
       id          :=json.Find('id_loja'     ).AsString;
       valor_custo :=StrToCurr(StringReplace(json.Find('valor_custo').AsString, ',', '.',[]));
       valor_venda :=StrToCurr(StringReplace(json.Find('valor_venda').AsString, ',', '.',[]));

       margem:=calcMargem(valor_custo,valor_venda);

       TGetData.getData(
         'insert into produtos (nome, valor_custo, valor_venda, '+
         'inf_valor, margem, comissionado, id_loja_ex, ident_serv, flag, insumo) '+
         'values (:nome, :valor_custo, :valor_venda, :inf_valor, :margem, '+
         ':comissionado, :id_loja, ''1'', ''A'', ''False'');',
         [
           nome,
           valor_custo,
           valor_venda,
           inf_valor,
           margem,
           comissionado,
           id
         ]
       );
     end;
   finally
     json.Free;
   end;
end;

procedure TServiceModel.deleteService(id: Integer);
var
   getData: TGetData;
begin
   getData := TGetData.Create;
   try
     getData.getData(
       sql_queries.delete_product_simples,
       [id]
     );
   finally
     getData.Free;
   end;
end;

procedure TServiceModel.updateService(json: TJSONObject);
var
   data: TServicesData;
begin
   try
     with data do
     begin
       nome        :=json.Find('nome'        ).AsString;
       comissionado:=json.Find('comissionado').AsString;
       inf_valor   :=json.Find('inf_valor'   ).AsString;
       id          :=json.Find('id'          ).AsString;
       valor_custo :=StrToCurr(StringReplace(json.Find('valor_custo').AsString, ',', '.',[]));
       valor_venda :=StrToCurr(StringReplace(json.Find('valor_venda').AsString, ',', '.',[]));

       margem:=calcMargem(valor_custo, valor_venda);

       TGetData.getData(
         'update produtos set nome = :nome, valor_custo = :custo, '+
         'valor_venda = :venda, inf_valor = :inf, margem = :margem, '+
         'comissionado = :comissionado where id = :id;',
         [
           nome,
           valor_custo,
           valor_venda,
           inf_valor,
           margem,
           comissionado,
           id
         ]
       );
     end;
   finally
     json.Free;
   end;
end;

end.

