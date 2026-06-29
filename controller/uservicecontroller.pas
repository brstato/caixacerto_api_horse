unit uservicecontroller;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, uservicemodel, fpjson, Horse, uJsonView, Horse.JWT, udata;

type

  { TServiceController }

  TServiceController = class
    public
      class procedure RegisterRoutes();
  end;

implementation

{ TServiceController }

procedure HandlerServiceCreate(req: THorseRequest; res:THorseResponse; next: TNextProc);
var
  model: TServiceModel;
  jsonReq: TJSONObject;
begin
  model := TServiceModel.Create;
  try
    jsonReq := TJSONObject(GetJSON(req.Body));
    model.CreateService(jsonReq);
  finally
    model.Free;
  end;
end;


procedure HandlerServiceDelete(req: THorseRequest; res:THorseResponse; next: TNextProc);
var
  model: TServiceModel;
  jsonReq: TJSONObject;
  id: integer;
begin
  model := TServiceModel.Create;
  jsonReq := TJSONObject(GetJSON(req.Body));
  try
    id := jsonReq.Find('id').AsInteger;
    model.deleteService(id);
  finally
    model.Free;
    jsonReq.Free;
  end;
end;


procedure HandlerServiceUpdate(req: THorseRequest; res:THorseResponse; next: TNextProc);
var
   jsonReq: TJSONObject;
   model: TServiceModel;
begin
  model := TServiceModel.Create;
  jsonReq := TJSONObject(GetJSON(req.Body));
  try
    model.updateService(jsonReq);
  finally
    model.Free;
  end;
end;


procedure HandlerServiceDetail(req: THorseRequest; res:THorseResponse; next: TNextProc);
var
   jsonRes, jsonReq: TJSONObject;
   model: TServiceModel;
begin
   model := TServiceModel.Create;
   try
     jsonReq := TJSONObject(GetJSON(req.Body));
     jsonRes := TJSONObject(GetJSON(model.DetailService(jsonReq.Find('id').AsInteger)));
     TJsonView.SendResponse(res, jsonRes, 200);
   finally
     jsonReq.Free;
     jsonRes.Free;
     model.Free;
   end;
end;


procedure HandlerServiceList(req: THorseRequest; res:THorseResponse; next: TNextProc);
var
  Json, jsonResponse: TJSONObject;
  id: string;
  ServiceModel:TServiceModel;
begin
  try
    Json := TJSONObject(GetJSON(req.Body));

    id := Json.Find('id').AsString;

    ServiceModel:=TServiceModel.Create;

    jsonResponse := TJSONObject(GetJSON(ServiceModel.ListService(id)));

    TJsonView.SendResponse(res, jsonResponse, 200);
  finally
    Json.Free;
    jsonResponse.Free;
    ServiceModel.Free;
  end;
end;


class procedure TServiceController.RegisterRoutes();
begin

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/service/create', HandlerServiceCreate);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/service/delete', HandlerServiceDelete);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/service/update', HandlerServiceUpdate);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/service/detail', HandlerServiceDetail);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/service/list',   HandlerServiceList);
end;

end.

