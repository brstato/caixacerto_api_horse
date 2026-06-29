unit uprofissionalmodel;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, DB, fpjson, ugetdata, sql_queries;

type

  { TProfissionais }

  { TProfissionaisModel }

  TProfissionaisModel = class
  private
  public
    procedure createProfessional(const Name, Tel, id_loja: string; const Comission: integer);
    procedure deleteProfessional(const id: integer);
    function listProfessional(const id: string): TJSONArray;
    function DetailProfessional(const id: integer): UTF8String;
    procedure EditAccountProfessional(const name, telefone: string; id, comission: integer);
  end;


implementation

{ TProfissionais }

procedure TProfissionaisModel.createProfessional(const Name, Tel, id_loja: string;
  const Comission: integer);
var
  gtData: TGetData;
begin
  gtData := TGetData.Create;
  try
    try
      gtData.getData(
        sql_queries.insert_professional_simples,
        [
          name,
          tel,
          Comission,
          id_loja
        ]
      );
    finally
      gtData.Free;
    end;
  except
    raise;
  end;
end;


procedure TProfissionaisModel.deleteProfessional(const id: integer);
var
  gtData: TGetData;
begin
  gtData := TGetData.Create;
  try
    try
      gtData.getData(
        sql_queries.delete_professional_simples,
        [
         id
        ]
      );
    finally
      gtData.Free;
    end;
  except
    raise;
  end;
end;


function TProfissionaisModel.listProfessional(const id: string): TJSONArray;
var
  JsonArray: TJSONArray;
  Json:TJSONObject;
  gtData:TGetData;
  dataSet:TDataSet;
begin
  JsonArray := TJSONArray.Create;
  gtData := TGetData.Create;
  dataSet:=TDataSet.Create(nil);
  try
    dataSet:=gtData.getData(
      sql_queries.list_professional_simples,
      [id],
      True
    );

    with dataSet do
    begin
      first;
      while not eof do
      begin
        Json := TJSONObject.Create;
        Json.Add('id',FieldByName('id').AsInteger);
        Json.Add('name', FieldByName('nome').AsString);
        Json.Add('telefone',FieldByName('telefone').AsString);
        Json.Add('comissao', FieldByName('comicao').AsInteger);
        Json.Add('v_vendido', FieldByName('v_vendido').AsCurrency);

        JsonArray.Add(Json);
        next;
      end;
    end;
  finally
    gtData.Free;
    Result:=JsonArray;
    dataSet.Free;
  end;
end;

function TProfissionaisModel.DetailProfessional(const id: integer): UTF8String;
var
  gtDta: TGetData;
  dataSet: TDataSet;
  json: TJSONObject;
begin
  gtDta := TGetData.Create;
  json := TJSONObject.Create;
  try
     dataSet := gtDta.getData(
       sql_queries.detail_professional_simples,
       [id],
       True
     );
    with dataSet do
    begin
      json.Add('id',        FieldByName('id'       ).AsInteger);
      json.add('nome',      FieldByName('nome'     ).AsString );
      json.add('telefone',  FieldByName('telefone' ).AsString );
      json.add('comissao',  FieldByName('comicao'  ).AsInteger);
      json.add('v_vendido', FieldByName('v_vendido').AsFloat  );
    end;
    Result := json.AsJSON;
  finally
    gtDta.Free;
    json.Free;
    dataSet.Free;
  end;
end;

procedure TProfissionaisModel.EditAccountProfessional(const name,
  telefone: string; id, comission: integer);
var
   gtData:TGetData;
begin
  gtData:=TGetData.Create;
  try
    try
      gtData.getData(
        sql_queries.update_professional_simples,
        [
          name,
          telefone,
          comission,
          id
        ]
      );
    finally
      gtData.Free;
    end;
  except
    raise;
  end;
end;

end.
