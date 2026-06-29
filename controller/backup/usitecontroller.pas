unit usitecontroller;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Horse, ulojamodel, uJsonView, fpjson, usitemodel,
  sql_queries, udata, Horse.JWT, jsonparser;

type

  { TSiteController }

  TSiteController = class
    class procedure RegisterRoutes();
  end;

implementation

{ TSiteController }

procedure HandlerSiteUpdate(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonclaim, jsonreq, jsonres: TJSONObject;
  id_loja, titulo, subtitulo:string;
  jsonitens: TJSONArray;
begin
  Try
    try
      //jsonclaim := req.Session<TJSONObject>;

      jsonreq := TJSONObject(GetJSON(req.Body));

      id_loja := jsonreq.Find('id_loja').AsString;

      titulo    := jsonreq.Find('titulo'   ).AsString;
      subtitulo := jsonreq.Find('subtitulo').AsString;

      jsonitens := TJSONArray(GetJSON(jsonreq.Find('itens').AsJSON));

      TSiteModel.UpdateSite(titulo, subtitulo, id_loja);

      TJsonView.SendSuccess(res);
    except
      on e:exception do
      begin
        TJsonView.SendError(res, 500, e.Message);
      end;
    end;
  finally
    //jsonclaim.Free;
    jsonreq.Free;
  end;
end;

class procedure TSiteController.RegisterRoutes();
begin
  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/site/update',   HandlerSiteUpdate);
end;

end.

