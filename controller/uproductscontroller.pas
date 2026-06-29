unit uproductscontroller;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, fpjson, uJsonView, Horse, Horse.JWT, uproductsmodel, udata;

type

  { TServiceController }

  TProductController = class
    private
    public
      class procedure RegisterRoutes();
  end;

implementation

{ TServiceController }

procedure HandlerProductList(req: THorseRequest; res: THorseResponse;
  next: TNextProc);
var
  Json, jsonResponse: TJSONObject;
  id: string;
  ProductModel:TProductModel;
begin
  try
    Json := TJSONObject(GetJSON(req.Body));

    id := Json.Find('id').AsString;

    ProductModel:=TProductModel.Create;

    jsonResponse := ProductModel.ListProduct(id);

    TJsonView.SendResponse(res, jsonResponse, 200);
  finally
    jsonResponse.Free;
    Json.Free;
    ProductModel.Free;
  end;
end;


procedure HandlerProductCreate(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  productModel: TProductModel;
begin
  productModel := TProductModel.Create;
  try
    productModel.CreateProduct(req.Body);
  finally
    productModel.Free;
  end;
end;


procedure HandlerProductDelete(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  productModel: TProductModel;
begin
  productModel := TProductModel.Create;
  try
    productModel.deleteProduct(req.Body);
  finally
    productModel.Free;
  end;
end;


procedure HandlerProductUpdate(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  productModel: TProductModel;
begin
  productModel := TProductModel.Create;
  try
    productModel.updateProduct(req.Body);
  finally
    productModel.Free;
  end;
end;


procedure HandlerServiceList(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  Json, jsonResponse: TJSONObject;
  id: string;
  ProductModel:TProductModel;
begin
  try
    Json := TJSONObject(GetJSON(req.Body));

    id := Json.Find('id').AsString;

    ProductModel:=TProductModel.Create;

    jsonResponse := TJSONObject(GetJSON(ProductModel.ListService(id)));

    TJsonView.SendResponse(res, jsonResponse, 200);
  finally
    Json.Free;
    jsonResponse.Free;
    ProductModel.Free;
  end;

end;


procedure HandlerProductDetail(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  model: TProductModel;
  jsonRes, jsonReq: TJSONObject;
  id: string;
begin
  model   := TProductModel.Create;
  try
    jsonReq := TJSONObject(GetJSON(req.Body));
    id      := jsonReq.Find('id').AsString;
    jsonRes := TJSONObject(GetJSON(model.DetailProduct(id)));

    TJsonView.SendResponse(res, jsonRes, 200);
  finally
    model.Free;
    jsonReq.Free;
    jsonRes.Free;
  end;
end;


class procedure TProductController.RegisterRoutes();
begin
  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/product/list',   HandlerProductList);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/product/create',   HandlerProductCreate);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/product/delete',   HandlerProductDelete);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/product/update',   HandlerProductUpdate);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/product/detail',   HandlerProductDetail);
end;

end.

