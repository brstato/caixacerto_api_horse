unit ucaixamodel;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, ugetdata, udata, fpjson, db, sql_queries;

type
  TVendaDados = record
     id_loja: string;
     id_profissional,
     comissao,
     id_cliente,
     id_caixa: integer;
     valor,
     din,
     pix,
     deb,
     cred,
     troco,
     total: currency;
     itens: UTF8String
  end;

type

  { TCaixaModel }

  TCaixaModel = class
    private
      //getData: TGetData;
    public
      function listItens(id_loja: string): UTF8String;
      function listClient(id: string): UTF8String;
      function abrirCaixa(id_loja: string; troco_abertura: currency;
        pr_abriu: integer): integer;
      procedure fecharcaixa(id, id_prof:integer; troco, dinheiro, pix, debito,
        credito:currency);
      function status_caixa(id_loja:string): UTF8String;
      procedure venda(Dados: TVendaDados);
      constructor create;
      destructor destroy; override;
      function list_insumo(id_loja: string): utf8string;
      procedure update_insumos(id, quantidade: integer);
      procedure update_nota_cliente(id: integer; nota:string);
      class function relatorio_entradas(id_loja: string; mes: integer): TJSONObject;

  end;

implementation

{ TCaixaModel }

function TCaixaModel.listItens(id_loja: string): UTF8String;
var
  dataset: TDataSet;
  getdata: TGetData;
  jsonitens, jsonRes: TJSONObject;
  jsonArray: TJSONArray;
begin
  getdata := TGetData.Create;
  jsonArray := TJSONArray.Create;
  try
    dataset := getdata.getData(
      sql_queries.list_itens_simples,
      [id_loja],
      true
    );

    with dataset do
    begin
      first;
      while not eof do
      begin
        jsonitens := TJSONObject.Create;

        jsonitens.add('nome',               FieldByName('nome'              ).AsString);
        jsonitens.add('inf_valor',          FieldByName('inf_valor'         ).AsString);
        jsonitens.add('comissionado',       FieldByName('comissionado'      ).AsString);
        jsonitens.Add('id',                 FieldByName('id'                ).AsInteger);
        jsonitens.Add('comissao',           FieldByName('comicao'           ).AsInteger);
        jsonitens.add('quantidade_estoque', FieldByName('quantidade_estoque').AsInteger);
        jsonitens.add('ident_serv',         FieldByName('ident_serv'        ).AsInteger);
        jsonitens.add('valor_venda',        FieldByName('valor_venda'       ).AsCurrency);

        jsonArray.Add(jsonitens);
        next;
      end;
      jsonRes := TJSONObject.Create;
      jsonRes.Add('message', jsonArray);
    end;
    Result := jsonRes.AsJSON;
  finally
    getdata.Free;
    jsonRes.Free;
    dataset.Free;
  end;
end;


function TCaixaModel.listClient(id: string): UTF8String;
var
  getData: TGetData;
  dataSet: TDataSet;
  jsonRes, json: TJSONObject;
  JsonArray: TJSONArray;
begin
  getData := TGetData.Create;
  try
    dataSet := getData.getData(
      sql_queries.list_client_simples_caixa,
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
    dataset.Free;
  end;
end;


function TCaixaModel.abrirCaixa(id_loja: string;
  troco_abertura: currency; pr_abriu: integer): integer;
var
  getData: TGetData;
  dataset: TDataSet;
  id_caixa: integer;
begin
  getData := TGetData.Create;
  try
    getData.getData(
      sql_queries.create_caixa_simples,
      [
        id_loja,
        Now,
        troco_abertura,
        pr_abriu
      ]
    );

    dataset := getData.getData(
      sql_queries.retornar_id_caixa,
      [id_loja],
      true
    );

    id_caixa := dataset.Fields[0].AsInteger;

    Result := id_caixa;
  finally
    getData.Free;
    dataset.Free;
  end;
end;


procedure TCaixaModel.fecharcaixa(id, id_prof: integer; troco, dinheiro, pix,
  debito, credito: currency);
var
  getData: TGetData;
begin
  getData := TGetData.Create;
  try
    getData.getData(
      sql_queries.fechar_caixa_simples,
      [
        troco,
        id_prof,
        dinheiro,
        pix,
        debito,
        credito,
        Now,
        id
      ]
    );
  finally
    getData.Free;
  end;
end;


function TCaixaModel.status_caixa(id_loja: string): UTF8String;
var
  getData: TGetData;
  id: integer;
  dataSet: TDataSet;
  status: string;
  jsonres: TJSONObject;
begin
  getData := TGetData.Create;
  try
    try
      dataSet := getData.getData(
        sql_queries.retornar_id_caixa,
        [id_loja],
        True
      );
      jsonres := TJSONObject.Create;

      id := dataSet.Fields[0].AsInteger;
      status := dataSet.Fields[1].AsString;

      jsonres.Add('id_caixa', id);
      jsonres.add('status', status);

      Result := jsonres.AsJSON;
    finally
      dataSet.Free;
      getData.Free;
      jsonres.Free;
    end;
  except
    raise
  end;
end;


procedure TCaixaModel.venda(Dados: TVendaDados);
var
  getData: TGetData;
  jsonres: TJSONObject;
  itens_array: TJSONArray;
  jsonItem: TJSONObject;
  i: integer;
  ListaItens: TStringBuilder;
  fs: TFormatSettings;
  DataModule1: TDataModule1;
begin
  getData := nil;
  jsonres := nil;
  ListaItens := TStringBuilder.Create;

  fs := DefaultFormatSettings;
  fs.DecimalSeparator := '.';

  try
    getData := TGetData.Create;

    if Dados.itens <> '' then
       jsonres := TJSONObject(GetJSON(Dados.itens))
    else
       Exit;

    if (jsonres.Find('itens') <> nil) then
    begin
        itens_array := jsonres.Find('itens') as TJSONArray;

        for i := 0 to itens_array.Count - 1 do
        begin
          jsonItem := itens_array.Items[i] as TJSONObject;


          ListaItens.Append(IntToStr(jsonItem.Find('id_produto').AsInteger));
          ListaItens.Append(';');
          ListaItens.Append(IntToStr(jsonItem.Find('quantidade').AsInteger));
          ListaItens.Append(';');
          ListaItens.Append(FloatToStr(jsonItem.Find('valor_unitario').AsFloat, fs));
          ListaItens.Append(';');
          ListaItens.Append(FloatToStr(jsonItem.Find('valor_total').AsFloat, fs));
          ListaItens.Append(';');
          ListaItens.Append(jsonItem.Find('comissionado').AsString);
          ListaItens.Append(';');
          ListaItens.Append(IntToStr(jsonItem.Find('ident_serv').AsInteger));
          ListaItens.Append('|');
        end;
    end;

    TGetData.getData(
      'execute procedure REGISTRAR_VENDA_LOTE(' +
      ':id_prof, :valor, :id_caixa, :id_cliente, '+
      ':din, :pix, :deb, :cred, :troco, ' +
      ':id_loja, :perc_comissao, :lista_itens);',
      [
        Dados.id_profissional,
        Dados.valor,
        Dados.id_caixa,
        Dados.id_cliente,
        Dados.din,
        Dados.pix,
        Dados.deb,
        Dados.cred,
        Dados.troco,
        Dados.id_loja,
        Dados.comissao,
        ListaItens.ToString
      ]
    );

  finally
    ListaItens.Free;
    if Assigned(jsonres) then jsonres.Free;
  end;
end;

constructor TCaixaModel.create;
begin
  //getData := TGetData.Create;
end;

destructor TCaixaModel.destroy;
begin
  //getData.free;
  inherited destroy;
end;

function TCaixaModel.list_insumo(id_loja: string): utf8string;
var
  getdata: TGetData;
  DataSet: TDataSet;
  jsonres, jsoniten: TJSONObject;
  jsonarray: TJSONArray;
begin
  try
    getdata := TGetData.Create;
      jsonarray := TJSONArray.Create;

      DataSet := getdata.getData(
        sql_queries.list_insumos_simples,
        [id_loja],
        True
      );

      with DataSet do
      begin
        first;
        while not eof do
        begin
          jsoniten := TJSONObject.Create;

          jsoniten.add('id',      FieldByName('id'                ).AsInteger);
          jsoniten.add('estoque', FieldByName('quantidade_estoque').AsInteger);
          jsoniten.add('nome',    FieldByName('nome'              ).AsString );
          jsoniten.add('valor',   FieldByName('VALOR_VENDA'       ).AsFloat  );

          jsonarray.Add(jsoniten);

          next;
        end;
        jsonres := TJSONObject.Create;

        jsonres.Add('message',jsonarray);
        Result := jsonarray.AsJSON;
      end;
  finally
    getdata.Free;
    DataSet.Free;
    jsonres.Free;
  end;
end;

procedure TCaixaModel.update_insumos(id, quantidade: integer);
var
  getdata: TGetData;
begin
  getdata := TGetData.Create;
  try
    getdata.getData(
      sql_queries.update_insumos_simples,
      [
        quantidade,
        id
      ]
    );
  finally
    getdata.Free;
  end;
end;

procedure TCaixaModel.update_nota_cliente(id: integer; nota: string);
var
  getdata: TGetData;
begin
  getdata := TGetData.Create;
  try
    getdata.getData(
      sql_queries.update_nota_cliente_simples,
      [
        nota,
        id
      ]
    );
  finally
    getdata.Free;
  end;
end;

class function TCaixaModel.relatorio_entradas(id_loja: string; mes: integer
  ): TJSONObject;
var
  dataSet: TDataSet;
begin
  dataSet := nil;
  Result := nil;
  try
    try
      dataSet := TGetData.getData(
        '',
        [id_loja, mes],
        True
      );
    except
      raise;
    end;
  finally
    dataSet.Free;
  end;
end;

end.

