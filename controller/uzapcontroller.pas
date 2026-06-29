unit uzapcontroller;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, uJsonView, uzapmodel, udata, fpjson, Horse, Horse.JWT;

type

  { TZapController }

  TZapController = class
    public
      class procedure RegisterRoutes();
  end;

implementation

{ TZapController }

procedure HandlerConnectionWhatsapp(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq, jsonres: TJSONObject;
  instance, status, resposta: string;
  status_code: integer;
begin
  try
    jsonreq := TJSONObject(GetJSON(req.Body));

    instance := jsonreq.find('instance').AsString;

    jsonres := TJSONObject(GetJSON(TZapModel.conectzap(instance, status_code)));

    TJsonView.SendResponse(res, jsonres, status_code);
  finally
    jsonreq.Free;
    jsonres.Free;
  end;
end;


procedure HandlerCreateWhatsapp(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq, jsonres: TJSONObject;
  id_loja, status, number: string;
  status_code: integer;
begin
  try
    jsonreq := TJSONObject(GetJSON(req.Body));

    number := '55' + jsonreq.get('number', '99999999999');
    id_loja:= jsonreq.find('id_loja').AsString;

    jsonres := TJSONObject(GetJSON(TZapModel.createzap(number, id_loja, status_code)));

    TJsonView.SendResponse(res, jsonres, status_code);
  finally
    jsonreq.Free;
    jsonres.Free;
  end;
end;


class procedure TZapController.RegisterRoutes();
begin
  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/whatsapp/connect', HandlerConnectionWhatsapp);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/whatsapp/create', HandlerCreateWhatsapp);
end;

end.

