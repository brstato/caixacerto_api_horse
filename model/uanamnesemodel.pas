unit uanamnesemodel;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, fpjson, ugetdata, udata, sql_queries, db;

type
  EClienteDuplicado = class(Exception);

  TAnamneseDTO = record
    Profissao: string;
    ComoConheceu: string;
    Consumo: string;
    PraticaEsporte: string;
    QualEsporte: string;
    Diabetico: string;
    Hipertenso: string;
    Hemofilico: string;
    ProblemaPele: string;
    QualProblemaPele: string;
    GestanteAmamentando: string;
    AlcoolDrogas: string;
    DoencaTransmissivel: string;
    QualDoenca: string;
    Alergia: string;
    QualAlergia: string;
    Medicamento: string;
    QualMedicamento: string;
    ConcordaTermos: string;
    GostoPiercing: string;
    GostoTatuagem: string;
    EstiloTatuagem: string;
    Nome: string;
    Insta: string;
    IdLojaEx: string;
    Assinatura: string;
    Telefone: string;
    DataNascimento: TDateTime;
    telefone_studio: string;
    nome_estudio: string;
    id_profissional: integer;
  end;

type

  { TAnamneseModel }

  TAnamneseModel = class
    public
      procedure createAnamnese(const ADados: TAnamneseDTO);
      function return_professional(tel: string): UTF8String;

    private
      function createCliente(const ADados: TAnamneseDTO): integer;
  end;

implementation

{ TAnamneseModel }

procedure TAnamneseModel.createAnamnese(const ADados: TAnamneseDTO);
var
  getdata: TGetData;
  id_client: integer;
begin
  getdata := TGetData.Create;
  try
    try
    getdata.getData(
      sql_queries.registrar_anamnese,
      [
       ADados.Nome,
       ADados.Telefone,
       FormatDateTime('dd/mm/yyyy',ADados.DataNascimento),
       ADados.Insta,
       ADados.telefone_studio,
       ADados.profissao,
       ADados.ComoConheceu,
       ADados.consumo,
       ADados.PraticaEsporte,
       ADados.QualEsporte,
       ADados.diabetico,
       ADados.hipertenso,
       ADados.hemofilico,
       ADados.ProblemaPele,
       ADados.QualProblemaPele,
       ADados.GestanteAmamentando,
       ADados.AlcoolDrogas,
       ADados.DoencaTransmissivel,
       ADados.QualDoenca,
       ADados.Alergia,
       ADados.QualAlergia,
       ADados.Medicamento,
       ADados.QualMedicamento,
       ADados.ConcordaTermos,
       ADados.GostoPiercing,
       ADados.GostoTatuagem,
       ADados.EstiloTatuagem,
       ADados.Assinatura,
       ADados.id_profissional
      ]
    );

    except on e:exception do
    begin
      raise Exception.Create('Erro ao gravar Anamnese: ' + e.Message);
    end;
    end;
  finally
    getdata.Free;
  end;
end;

function TAnamneseModel.return_professional(tel: string): UTF8String;
var
  getdata: TGetData;
  dataset: TDataSet;
  jsonarray: TJSONArray;
  jsonobject: TJSONObject;
begin
  getdata := TGetData.Create;
  jsonarray := TJSONArray.Create;
  try
    dataset := getdata.getData(
      sql_queries.list_profissionais_publico_por_tel,
      [tel],
      True
    );

    with dataset do
    begin
      first;
      while not eof do
      begin
        jsonobject := TJSONObject.Create;

        jsonobject.add('id',   FieldByName('id'  ).AsInteger);
        jsonobject.add('nome', FieldByName('nome').AsString );

        jsonarray.Add(jsonobject);
        next;
      end;
    end;
    Result := jsonarray.AsJSON;
  finally
    getdata.Free;
    jsonarray.Free;
  end;
end;

function TAnamneseModel.createCliente(const ADados: TAnamneseDTO): integer;
var
  getdata:TGetData;
  id: integer;
  dataset, dataset_aux: TDataSet;

  id_loja: string;
begin
  getdata := TGetData.Create;
  try
    try
      dataset_aux := getdata.getData(
        sql_queries.busca_loja_telefone,
        [ADados.telefone_studio],
        true
      );

      id_loja := dataset_aux.FieldByName('uuid').AsString;

      dataset := getdata.getData(
        sql_queries.create_client_anamnese,
        [
          ADados.Nome,
          ADados.DataNascimento,
          ADados.Telefone,
          ADados.Insta,
          id_loja
        ],
        True
      );
      id := dataset.Fields[0].AsInteger;

      Result := id;
      dataset.Free;
      dataset_aux.Free;
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
    getdata.Free;
  end;
end;

end.

