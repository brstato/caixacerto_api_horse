unit uzapmodel;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, uNetService, sql_queries, ugetdata, fpjson, db, uconfig;

type

  { TZapModel }

  TZapModel = class
    public
       class function conectzap(var instance: string; out AStatus_code: integer): UTF8String;
       class function createzap(var number, id_loja: string; out AStatus_code: integer): UTF8String;
       class function buscainstancezap(var telefone: string): UTF8String;
    private
       //const base_url: string = 'http://127.0.0.1:8080/';
       const base_url: string = 'http://100.72.176.93:8080/';
       const conect_zap: string = '/instance/connect/';
       const create_zap: string = '/instance/create';
  end;

implementation

{ TZapModel }

class function TZapModel.conectzap(var instance: string; out AStatus_code: integer): UTF8String;
var
  jsonresponse: TJSONObject;
  url: string;
begin
  url := '';
  url := ConfigValue('services', 'url', '') + conect_zap + instance;
  try
    jsonresponse := TJSONObject(GetJSON(TNetService.get(
      url,
      'apikey',
      ConfigValue('services', 'internal_apikey', ''),
      AStatus_code
    )));
    result := jsonresponse.AsJSON;
  finally
    jsonresponse.Free;
  end;
end;


class function TZapModel.createzap(var number, id_loja: string; out AStatus_code: integer): UTF8String;
var
  url, uuidString, _url: string;
  jsonres, jsonreq: TJSONObject;
  uuid: TGuid;
  getdata: TGetData;
begin
  url := '';
  url := ConfigValue('services', 'url', '') + create_zap;
  try
    getdata := TGetData.Create;

    jsonreq := TJSONObject.Create;

    CreateGUID(uuid);

    uuidString:=stringreplace(GUIDToString(uuid), '{','',[rfReplaceAll]);
    uuidString:=stringreplace(uuidString, '}','',[rfReplaceAll]);

    getdata.getData(
      sql_queries.criar_instacia_zap,
      [
         uuidString,
         id_loja
      ]
    );

    jsonreq.Add('instanceName', uuidString);
    jsonreq.add('number', number);
    jsonreq.add('qrcode',TJSONBoolean.Create(True));
    jsonreq.add('integration', 'WHATSAPP-BAILEYS');

    jsonres := TJSONObject(GetJSON(TNetService.post(
            url,
            'apikey',
            ConfigValue('services', 'internal_apikey', ''),
            jsonreq.AsJSON,
            AStatus_code
    )));

    Result := jsonres.AsJSON;
  finally
    getdata.Free;
    jsonres.Free;
    jsonreq.Free;
  end;

end;

class function TZapModel.buscainstancezap(var telefone: string): UTF8String;
var
  getdata: TGetData;
  dataset: TDataSet;
begin
  getdata := TGetData.Create;
  try
    dataset := getdata.getData(
      sql_queries.busca_loja_telefone,
      [telefone],
      True
    );

    result := dataset.FieldByName('zap_instance').AsString;
  finally
    getdata.Free;
    dataset.Free;
  end;
end;

end.

