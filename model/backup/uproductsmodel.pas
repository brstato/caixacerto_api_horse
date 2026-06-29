unit uproductsmodel;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, sql_queries, ugetdata, udata, fpjson, db;

type

  { TProductModel }

  TProductModel = class
    private
    public
      function ListProduct(const id: string):TJSONObject;
      function ListService(const id: string):UTF8String;
      function DetailProduct(const id: string): UTF8String;
      procedure CreateProduct(json: string);
      procedure deleteProduct(json: string);
      procedure updateProduct(json: string);

  end;

implementation

{ TProductModel }

function TProductModel.ListProduct(const id: string): TJSONObject;
var
   gtData: TGetData;
   dataSet: TDataSet;
   jsonArray: TJSONArray;
   jsonObj, jsonResponse: TJSONObject;
begin
   //Result:=nil;
   gtData := TGetData.Create;
   jsonArray := TJSONArray.Create;
   jsonResponse := TJSONObject.Create;
   try
     dataSet:=gtData.getData(
       sql_queries.list_products_simples,
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
           jsonObj.Add('inf_valor',   FieldByName('inf_valor').AsString);
           jsonObj.Add('margem',      FieldByName('margem'   ).AsString);
           jsonObj.Add('insumo',      FieldByName('insumo'   ).AsString);

           jsonObj.Add('vendas',      FieldByName('vendas'     ).AsCurrency);
           jsonObj.Add('valor_custo', FieldByName('valor_custo').AsCurrency);
           jsonObj.Add('valor_venda', FieldByName('valor_venda').AsCurrency);

           jsonObj.Add('id',          FieldByName('id'                ).AsInteger);
           jsonObj.Add('comissao',    FieldByName('comicao'           ).AsInteger);
           jsonObj.Add('min_estoque', FieldByName('min_estoque'       ).AsInteger);
           jsonObj.Add('qt_estoque',  FieldByName('quantidade_estoque').AsInteger);

           jsonArray.Add(jsonObj);

           next;
         end;
         jsonResponse.Add('message', jsonArray);
       end;
     end
     else
     begin
         jsonObj := TJSONObject.Create;

         jsonObj.Add('id',          '');
         jsonObj.Add('nome',        '');
         jsonObj.Add('valor_custo', '');
         jsonObj.Add('valor_venda', '');
         jsonObj.Add('inf_valor',   '');
         jsonObj.Add('margem',      '');
         jsonObj.Add('comicao',     '');
         jsonObj.Add('vendas',      '');
         jsonObj.add('qt_estoque',  '');
         jsonObj.add('min_estoque', '');

         jsonArray.Add(jsonObj);

         jsonResponse.Add('message', jsonArray);
     end;
   finally
     gtData.Free;
     dataSet.Free;
     Result:=jsonResponse;
   end;
end;


function TProductModel.ListService(const id: string): UTF8String;

begin

end;

function TProductModel.DetailProduct(const id: string): UTF8String;
var
   getdata: TGetData;
   dataSet: TDataSet;
   jsonObj: TJSONObject;
begin
   getdata := TGetData.Create;
   jsonObj := TJSONObject.Create;
   try
      dataSet := getdata.getData(
        sql_queries.detail_product_simples,
        [id],
        True
      );
      with dataSet do
      begin
         jsonObj.add('valor_custo', FieldByName('valor_custo' ).AsFloat        );
         jsonObj.add('valor_venda', FieldByName('valor_venda' ).AsFloat        );
         jsonObj.Add('inf_valor',   FieldByName('inf_valor'   ).AsString       );
         jsonObj.add('margem',      FieldByName('margem'      ).AsString       );
         jsonObj.add('nome',        FieldByName('nome'        ).AsString       );
         jsonObj.Add('insumo',      FieldByName('insumo'      ).AsString       );
         jsonObj.add('comissionado',FieldByName('comissionado').AsString       );
         jsonObj.Add('id',          FieldByName('id'          ).AsInteger      );
         jsonObj.add('comissao',    FieldByName('comicao'     ).AsInteger      );
         jsonObj.add('min_estoque', FieldByName('MIN_ESTOQUE' ).AsInteger      );
         jsonObj.add('estoque',     FieldByName('QUANTIDADE_ESTOQUE').AsInteger);
      end;
      Result := jsonObj.AsJSON;
   finally
     getdata.Free;
     jsonObj.Free;
     dataSet.Free;
   end;
end;


function calcMargem(custo, venda: currency): integer;
begin
   if custo = 0 then
      Result := 0
    else
      Result := round(((venda - custo) / custo) * 100);
end;


procedure TProductModel.CreateProduct(json: string);
var
   gtData: TGetData;
   jsonObject: TJSONObject;
   nome, inf_valor, insumo, ident_serv, id_loja, comissionado: string;
   valor_custo, valor_venda: Currency;
   margem, comissao, quantidade_estoque, min_estoque: integer;
begin
   gtData := TGetData.Create;
   try
     jsonObject := TJSONObject(GetJSON(json));

     nome               := jsonObject.Find('nome'              ).AsString;
     inf_valor          := jsonObject.Find('inf_valor'         ).AsString;
     insumo             := jsonObject.Find('insumo'            ).AsString;
     id_loja            := jsonObject.Find('id_loja'           ).AsString;
     comissionado       := jsonObject.Find('comissionado'      ).AsString;
     valor_custo        := StrToFloatDef(StringReplace(jsonObject.Find('valor_custo').AsString, ',', '.', []),0);
     valor_venda        := StrToFloatDef(StringReplace(jsonObject.Find('valor_venda').AsString, ',', '.', []),0);
     quantidade_estoque := StrToIntDef(jsonObject.Find('quantidade_estoque').Asstring,0);
     min_estoque        := StrToIntDef(jsonObject.Find('min_estoque').Asstring,0);
     margem             := calcMargem(valor_custo, valor_venda);

     gtData.getData(
       sql_queries.insert_product_simples,
       [
         nome,
         valor_custo,
         valor_venda,
         inf_valor,
         margem,
         quantidade_estoque,
         min_estoque,
         insumo,
         id_loja,
         comissionado
       ]
     );
   finally
     jsonObject.Free;
     gtData.Free;
   end;
end;

procedure TProductModel.deleteProduct(json: string);
var
   gtData: TGetData;
   jsonObject: TJSONObject;
   id: integer;
begin
   gtData := TGetData.Create;
   try
     jsonObject := TJSONObject(GetJSON(json));
      id := jsonObject.Find('id').AsInteger;

      gtData.getData(
        sql_queries.delete_product_simples,
        [id]
      );

   finally
     gtData.Free;
     jsonObject.Free;
   end;
end;

procedure TProductModel.updateProduct(json: string);
var
   gtDta: TGetData;
   jsonObject: TJSONObject;
   nome, inf_falor, insumo, comissionado: string;
   valor_custo, valor_venda:Currency;
   margem, comissao, quantidade_estoque, min_estoque, id: integer;
begin
   gtDta := TGetData.Create;
   try
     jsonObject := TJSONObject(GetJSON(json));

     valor_custo := StrToFloat(StringReplace(
       jsonObject.Find('valor_custo').AsString,
       ',','.',[]));

     valor_venda := StrToFloat(StringReplace(
       jsonObject.Find('valor_venda').AsString,
        ',','.',[]));

     nome               := jsonObject.Find('nome'              ).AsString;
     inf_falor          := jsonObject.Find('inf_valor'         ).AsString;
     insumo             := jsonObject.Find('insumo'            ).AsString;
     comissionado       := jsonObject.Find('comissionado'      ).AsString;
     quantidade_estoque := jsonObject.Find('quantidade_estoque').AsInteger;
     min_estoque        := jsonObject.Find('min_estoque'       ).AsInteger;
     id                 := jsonObject.Find('id'                ).AsInteger;
     margem             := calcMargem(valor_custo, valor_venda);

     gtDta.getData(
       sql_queries.update_product_simples,
       [
         nome,
         valor_custo,
         valor_venda,
         inf_falor,
         margem,
         quantidade_estoque,
         min_estoque,
         insumo,
         comissionado,
         id
       ]
     );
   finally
     gtDta.Free;
     jsonObject.Free;
   end;
end;

end.

