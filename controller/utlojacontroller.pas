unit utlojacontroller;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Horse, ulojamodel, umailmodel, uJsonView, fpjson,
  sql_queries, udata, ucacheservice, Horse.JWT;

type

  { TlojaController }

  TlojaController = class
    private
    public
      class procedure RegisterRoutes();
  end;

implementation

{ TlojaController }

procedure handlerGetDataAccount(Req: THorseRequest; Res: THorseResponse; next: TNextProc);
var
   RequestJson, JsonResponse: TJSONObject;
   LModel: TLojaModel;
   id: string;
begin
   JsonResponse:=TJSONObject.Create;
   RequestJson := TJSONObject(GetJSON(Req.Body));
   LModel := TLojaModel.Create;
   try
     id := RequestJson.Find('id').AsString;
     JsonResponse :=  LModel.getDataAccount(id);
   finally
     TJsonView.SendResponse(Res, JsonResponse, 200);
     RequestJson.Free;
     JsonResponse.Free;
   end;
end;

procedure HandlerUpdateAccounPass(Req: THorseRequest; Res: THorseResponse; next: TNextProc);
var
   RequestJson, horario: TJSONObject;
   LojaDados: TLojaReturn;
   lojaModel: TLojaModel;
begin
  try
     try
       RequestJson := TJSONObject(GetJSON(req.Body));

       LojaDados.nome           := RequestJson.Find('nome'           ).AsString;
       LojaDados.telefone       := RequestJson.Find('telefone'       ).AsString;
       LojaDados.email          := RequestJson.Find('email'          ).AsString;
       LojaDados.id             := RequestJson.Find('id'             ).AsString;
       LojaDados.logradouro     := RequestJson.Find('endereco'       ).AsString;
       LojaDados.uf             := RequestJson.Find('estado'         ).AsString;
       LojaDados.cidade         := RequestJson.find('cidade'         ).AsString;
       LojaDados.cep            := RequestJson.Find('cep'            ).AsString;
       LojaDados.bairro         := RequestJson.Find('bairro'         ).AsString;
       LojaDados.complemento    := RequestJson.Find('complemento'    ).AsString;
       LojaDados.numero         := RequestJson.Find('numero'         ).AsString;
       LojaDados.meta_pixel     := RequestJson.Find('meta_pixel'     ).AsString;
       LojaDados.g_tag          := RequestJson.Find('g_analytics_id' ).AsString;
       LojaDados.insta_str      := RequestJson.find('insta'          ).AsString;
       LojaDados.google_ads_nome:= RequestJson.Find('google_ads_nome').AsString;
       LojaDados.google_ads_id  := RequestJson.Find('google_ads_id'  ).AsString;
       LojaDados.latitude       := RequestJson.Find('latitude'       ).AsFloat;
       LojaDados.longitude      := RequestJson.Find('longitude'      ).AsFloat;
       LojaDados.slug           := LowerCase(RequestJson.Find('slug' ).AsString);
       LojaDados.horario_str    := RequestJson.Find('horario' ).AsJSON;

       lojaModel := TLojaModel.Create;

       lojaModel.updateAccount(LojaDados);

     finally
       lojaModel.Free;
       TJsonView.SendResponse(res, TJSONObject(GetJSON(('{"message":"Success"}'))), 200);
       RequestJson.Free;
     end;

  except on e:exception do
  begin
      TJsonView.SendError(res, 500, e.Message);
   end;
  end;
end;

procedure HandleRegisterRoute(Req: THorseRequest; Res: THorseResponse; next: TNextProc);
var
   RequestJson, horario: TJSONObject;
   nome, email, telefone, senha, MsgErro, slug: UTF8String;

   lojaModel: TLojaModel;
   NewlojaId: integer;
begin
  try
    try
        RequestJson := TJSONObject(GetJSON(req.Body));

        nome     := RequestJson.Find('nome'    ).AsString;
        telefone := RequestJson.Find('telefone').AsString;
        email    := RequestJson.Find('email'   ).AsString;
        slug     := LowerCase(RequestJson.Find('slug').AsString);

        horario  := TJSONObject(GetJSON(RequestJson.Find('horario').AsJSON));

        if (nome = '') or (telefone = '') or (email = '') then
        begin
           TJsonView.SendError(res, 400, 'Preencha todos os campos corretamente');
           exit;
        end;

        lojaModel := TLojaModel.Create;

        try
           NewlojaId := LojaModel.createloja(nome, telefone, email, horario.AsJSON, slug);
           if NewlojaId > 0 then
               TJsonView.SendResponse(res, TJSONObject(GetJSON(('{"message":"Registro criado com sucesso."}'))), 200)
           else
               TJsonView.SendError(res, 500, 'Erro ao criar conta: ID inválido retornado.');
        finally
          lojaModel.Free;
          horario.Free;
        end;
    except on e:Exception do
    begin
      MsgErro := E.Message;
      if (Pos('unique', LowerCase(MsgErro)) > 0) or (Pos('duplicate', LowerCase(MsgErro)) > 0) then
      begin
         TJsonView.SendError(Res, 409, 'Já existe uma conta registrada com este Nome, Telefone ou Email.');
      end
      else
      begin
         TJsonView.SendError(Res, 500, 'Erro interno: ' + MsgErro);
      end;
    end;
    end;
  finally
    RequestJson.Free;
  end;
end;

procedure handlerGetSlug(Req: THorseRequest; Res: THorseResponse; next: TNextProc);
var
   jsonreq, jsonres: TJSONObject;
   slug: string;
   slug_bool: Boolean;
begin
   try
     try
       jsonreq := TJSONObject(GetJSON(Req.Body));

       slug := jsonreq.find('slug').AsString;

       jsonres := TLojaModel.get_slug(slug);

       TJsonView.SendResponse(res, jsonres, 200);
     except on e:exception do
       TJsonView.SendError(res, 500, e.Message);
     end;
   finally
     jsonreq.Free;
     jsonres.Free;
   end;
end;

procedure HandleStudio(Req: THorseRequest; Res: THorseResponse);
var
   jsonRes, jsonreq: TJSONObject;

   slug: string;
begin
  try
    try
       jsonreq := TJSONObject(GetJSON(req.Body));

       slug := jsonreq.Find('slug').AsString;

       jsonRes := TLojaModel.GetInfoStudio(slug);

       if Assigned(jsonRes) then
         TJsonView.SendResponseJsonObject(res, jsonRes, 200)
       else
         TJsonView.SendError(res, 404, '{"erro": "Estúdio não encontrado"}');
    except
      on e:exception do
      begin
        TJsonView.SendError(res, 500, e.message);
      end;
    end;
  finally
    jsonreq.Free;
  end;
end;

procedure HandleEndereco(Req: THorseRequest; Res: THorseResponse);
var
   jsonRes, jsonreq: TJSONObject;
   endereco: string;
begin
  try
     jsonreq := TJSONObject(GetJSON(req.Body));

     jsonRes := TLojaModel.get_endereco(jsonreq);

     if Assigned(jsonRes) then
       TJsonView.SendResponseJsonObject(res, jsonRes, 200)
     else
       TJsonView.SendError(res, 400, '{"erro": "CEP não informado"}');
  except
    on e:exception do
    begin
      TJsonView.SendError(res, 500, e.message);
    end;
  end;
end;

procedure HandleSincronizarCache(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  instanceUUID: string;
begin
  // Captura o UUID da instância que veio na URL da requisição
  instanceUUID := req.Params['instance'];

  if instanceUUID = '' then
  begin
    TJsonView.SendError(res, 400, 'O parâmetro instance é obrigatório na URL.');
    Exit;
  end;

  try
    // Atualiza apenas a instância específica na memória, sem travar o servidor
    TCacheService.AtualizarInstancia(instanceUUID);

    // Retorna sucesso mantendo o padrão do seu TJsonView
    TJsonView.SendResponse(res, TJSONObject(GetJSON('{"message":"Cache da instância ' + instanceUUID + ' atualizado com sucesso."}')), 200);
  except
    on E: Exception do
      TJsonView.SendError(res, 500, 'Erro ao atualizar cache: ' + E.Message);
  end;
end;

procedure HandlerUpdateMetaLongToken(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq: TJSONObject;
  id_loja, meta_long_token: string;
  DM: TDataModule1;
begin
  try
    try
      DM := TDataModule1.Create(nil);
      id_loja := DM.GetIdLoja(req.Headers['Authorization']);

      jsonreq := TJSONObject(GetJSON(req.Body));

      meta_long_token := jsonreq.Find('meta_long_token').AsString;

      TLojaModel.UpdateMetaLongToken(id_loja, meta_long_token);

      TJsonView.SendSuccess(res);
    except on e:exception do
      TJsonView.SendError(res, 500, e.Message);
    end;
  finally
    jsonreq.Free;
    DM.Free;
  end;
end;


procedure HandlerUpdateMetaAdsId(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq: TJSONObject;
  IdLoja, MetaAdsId: string;
  DM: TDataModule1;
begin
  try
    try
      DM := TDataModule1.Create(nil);
      IdLoja := DM.GetIdLoja(req.Headers['Authorization']);

      jsonreq := TJSONObject(GetJSON(req.Body));

      MetaAdsId := jsonreq.Find('MetaAdsId').AsString;

      TLojaModel.UpdateMetaAdsId(IdLoja, MetaAdsId);

      TJsonView.SendSuccess(res);
    except on e:exception do
      TJsonView.SendError(res, 500, e.Message);
    end;
  finally
    jsonreq.Free;
    DM.Free;
  end;
end;


procedure HandlerUpdateMetaPixelId(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  DM: TDataModule1;
  JsonReq: TJSONObject;
  IdLoja, MetaPixelId: string;
begin
  try
    try
      DM := TDataModule1.Create(nil);
      IdLoja := DM.GetIdLoja(req.Headers['Authorization']);

      JsonReq := TJSONObject(GetJSON(req.Body));

      MetaPixelId := JsonReq.Find('MetaPixelId').AsString;

      TLojaModel.UpdateMetaPixelId(IdLoja, MetaPixelId);

      TJsonView.SendSuccess(res);
    except on e:exception do
      TJsonView.SendError(res, 500, e.Message);
    end;
  finally
    JsonReq.Free;
    DM.Free;
  end;
end;


procedure HandlerUpdateGoogleAnalyticsId(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  JsonReq: TJSONObject;
  IdLoja, GoogleAnalyticsId: string;
  DM: TDataModule1;
begin
  try
    try
      DM := TDataModule1.Create(nil);

      IdLoja := DM.GetIdLoja(req.Headers['Authorization']);

      JsonReq := TJSONObject(GetJSON(req.Body));

      GoogleAnalyticsId := JsonReq.Find('GoogleAnalyticsId').AsString;

      TLojaModel.UpdateGoogleAnalyticsId(IdLoja, GoogleAnalyticsId);

      TJsonView.SendSuccess(res);
    except on e:exception do
      TJsonView.SendError(res, 500, e.Message);
    end;
  finally
    JsonReq.Free;
    DM.Free;
  end;
end;


procedure HandlerUpdateStatusCampanhaMeta(req: THorseRequest; res: THorseResponse;
  next: TNextProc);
var
  IdLoja, StatusCampanhaMeta: String;
  StatusCampanhaMetaBool: Boolean;
  JsonReq: TJSONObject;
  DM: TDataModule1;
begin
  try
    try
      DM := TDataModule1.Create(nil);

      IdLoja := DM.GetIdLoja(req.Headers['Authorization']);

      JsonReq := TJSONObject(GetJSON(req.Body));

      StatusCampanhaMetaBool := JsonReq.Find('StatusCampanhaMeta').AsBoolean;

      TLojaModel.UpdateStatusCampanhaMeta(IdLoja, StatusCampanhaMetaBool);

      TJsonView.SendSuccess(res);
    except on e:exception do
      TJsonView.SendError(res, 500, e.Message);
    end;
  finally
    JsonReq.Free;
    DM.Free;
  end;
end;


class procedure TlojaController.RegisterRoutes;
begin
     THorse.AddCallback(HorseJWT(DataModule1.token))
     .Post('api/v1/account/update',   HandlerUpdateAccounPass);

     THorse.AddCallback(HorseJWT(DataModule1.token))
     .Post('api/v1/account/get_data', handlerGetDataAccount);

     THorse.Post('api/v1/account/get_slug', handlerGetSlug);

     THorse.Post('api/v1/account/register', HandleRegisterRoute);

     THorse.Post('api/v1/public/studio', HandleStudio);

     thorse.post('api/v1/public/endereco', HandleEndereco);

     THorse.AddCallback(HorseJWT(DataModule1.token))
     .Post('api/v1/account/sincronizar-cache/:instance', HandleSincronizarCache);

     THorse.AddCallback(HorseJWT(DataModule1.token))
     .Post('api/v1/account/metatoken',   HandlerUpdateMetaLongToken);

     THorse.AddCallback(HorseJWT(DataModule1.token))
     .Post('api/v1/account/meta_ads_id',   HandlerUpdateMetaAdsId);

     THorse.AddCallback(HorseJWT(DataModule1.token))
     .Post('api/v1/account/meta_pixel_id',   HandlerUpdateMetaPixelId);

     THorse.AddCallback(HorseJWT(DataModule1.token))
     .Post('api/v1/account/google_analytics_id',   HandlerUpdateGoogleAnalyticsId);

     THorse.AddCallback(HorseJWT(DataModule1.token))
     .Post('api/v1/account/status_campanha_meta',   HandlerUpdateStatusCampanhaMeta);
end;



end.

