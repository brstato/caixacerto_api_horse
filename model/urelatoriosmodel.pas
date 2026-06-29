unit URelatoriosModel;

{$mode Delphi}

interface

uses
  Classes, SysUtils, ugetdata, udata, fpjson, db;

type

  { TRelatoriosModel }

  TRelatoriosModel = class
    public
      class function relatorio_entradas(id_loja: string; mes, ano: integer): TJSONArray;
      class function entradas_grafico(id_loja: string): TJSONArray;
      class function entrada_detalhes(id_venda: integer): TJSONArray;
  end;

implementation

class function TRelatoriosModel.relatorio_entradas(id_loja: string; mes, ano: integer
  ): TJSONArray;
var
  dataSet: TDataSet;
  jsonItem: TJSONObject;
  comissoes, liquido: Currency;
begin
  dataSet := nil;
  Result := TJSONArray.Create;

  try
    try
      dataSet := TGetData.getData(
        'SELECT ID, DATA_VENDA, VALOR, DIN, PIX, DEB, CRED, COMISSAO, ' +
        'SUM(VALOR) OVER() AS TOTAL_MES, ' +
        'SUM(COMISSAO) OVER() AS COMISSOES, ' +
        '(SUM(VALOR) OVER() - SUM(COMISSAO) OVER()) AS LIQUIDO ' +
        'FROM VENDA WHERE ID_LOJA_EX = :IdLoja ' +
        'AND EXTRACT(MONTH FROM DATA_VENDA) = :Mes ' +
        'AND EXTRACT(YEAR FROM DATA_VENDA) = :Ano ' +
        'AND STATUS = ''F'';',
        [id_loja, mes, ano],
        True
      );

      with dataSet do
      begin
        if not IsEmpty then
        begin
          First;
          while not eof do
          begin
            jsonItem := TJSONObject.Create;

            jsonItem.Add('id_venda',   FieldByName('id'        ).AsInteger );
            jsonItem.Add('valor',      FieldByName('valor'     ).AsCurrency);
            jsonItem.add('total',      FieldByName('total_mes' ).AsCurrency);
            jsonItem.add('comissoes',  FieldByName('comissoes' ).AsCurrency);
            jsonItem.Add('liquido',    FieldByName('liquido'   ).AsCurrency);
            jsonItem.Add('data_venda', FormatDateTime(
                                       'dd/mm/yyyy',
                                       FieldByName('data_venda').AsDateTime)
                                       );

            Result.Add(jsonItem);
            next;
          end;
        end;
      end;
    except
      begin
        Result.Free;
        raise;
      end;
    end;
  finally
    dataSet.Free;
  end;
end;

class function TRelatoriosModel.entradas_grafico(id_loja: string): TJSONArray;
var
  dataSet: TDataSet;
  jsonItem: TJSONObject;
begin
  dataSet := nil;
  Result := TJSONArray.Create;

  try
    try
      dataSet := TGetData.getData(
        'SELECT EXTRACT(YEAR FROM DATA_VENDA) AS ANO, ' +
        'EXTRACT(MONTH FROM DATA_VENDA) AS MES, ' +
        'SUM(VALOR) AS TOTAL ' +
        'FROM VENDA WHERE ID_LOJA_EX = :IdLoja AND STATUS = ''F'' ' +
        'GROUP BY 1, 2 ORDER BY 1 DESC, 2 DESC;',
        [id_loja],
        True
      );
      with dataSet do
      begin
        if not IsEmpty then
        begin
          First;
          while not eof do
          begin
            jsonItem := TJSONObject.Create;
            jsonItem.Add('ano',   FieldByName('ANO').AsInteger);
            jsonItem.Add('mes',   FieldByName('MES').AsInteger);
            jsonItem.Add('total', FieldByName('TOTAL').AsCurrency);

            Result.Add(jsonItem);
            next;
          end;
        end;
      end;
    except
      begin
        Result.Free;
        raise;
      end;
    end;
  finally
    dataSet.Free;
  end;
end;

class function TRelatoriosModel.entrada_detalhes(id_venda: integer): TJSONArray;
var
  dataSet: TDataSet;
  jsonItem: TJSONObject;
begin
  dataSet := nil;
  Result := TJSONArray.Create;
  try
    try
      dataSet := TGetData.getData(
        'SELECT '+
        'v.DIN, v.PIX, v.DEB, v.CRED, v.TROCO, vd.QUANTIDADE, '+
        'vd.VALOR, vd.TOTAL, vd.COMISSAO, p.NOME AS NOME_PRODUTO, '+
        'prof.NOME AS NOME_ARTISTA, c.NOME AS NOME_CLIENTE, v.COMISSAO '+
        'FROM VENDA v '+
        'INNER JOIN VENDA_DETALHADA vd ON v.ID = vd.COD_VENDA '+
        'INNER JOIN PRODUTOS p ON vd.COD_PRODUTO = p.ID '+
        'INNER JOIN PROFISSIONAIS prof ON v.ID_PROFISSIONAL = prof.ID ' +
        'LEFT JOIN CLIENTES c ON v.ID_CLIENTE = c.ID ' +
        'WHERE v.ID = :ID;',
        [id_venda],
        True
      );
      with dataSet do
      begin
        if not IsEmpty then
        begin
          first;
          while not eof do
          begin
            jsonItem := TJSONObject.Create;

            jsonItem.Add('dinheiro',     FieldByName('din'         ).AsCurrency);
            jsonItem.add('pix',          FieldByName('pix'         ).AsCurrency);
            jsonItem.Add('debito',       FieldByName('deb'         ).AsCurrency);
            jsonItem.Add('credito',      FieldByName('cred'        ).AsCurrency);
            jsonItem.Add('troco',        FieldByName('troco'       ).AsCurrency);
            jsonItem.Add('valor',        FieldByName('valor'       ).AsCurrency);
            jsonItem.Add('total',        FieldByName('total'       ).AsCurrency);
            jsonItem.Add('comissao',     FieldByName('comissao'    ).AsCurrency);
            jsonItem.Add('quantidade',   FieldByName('quantidade'  ).AsInteger );
            jsonItem.Add('nome_produto', FieldByName('nome_produto').AsString  );
            jsonItem.Add('nome_artista', FieldByName('nome_artista').AsString  );
            jsonItem.Add('nome_cliente', FieldByName('nome_cliente').AsString  );

            Result.Add(jsonItem);
            next;
          end;
        end;
      end;
    except
      begin
        Result.Free;
        raise;
      end;
    end;
  finally
    if Assigned(dataSet) then dataSet.Free;
  end;
end;

end.

