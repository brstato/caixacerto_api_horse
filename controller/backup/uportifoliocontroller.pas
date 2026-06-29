unit uportifoliocontroller;

{$mode delphi}{$H+}

interface

uses
  Classes,
  SysUtils,
  Horse,
  uportifolioview,
  uJsonView,
  uportifoliomodel,
  udata,
  Horse.JWT,
  fpjson,
  LazJWT,
  StrUtils;

type

  { TPortifolioController }

  TPortifolioController = class
    public
      class procedure RegisterRoutes();
  end;

implementation

{ TPortifolioController }

function verifica_slug(const slug: string): Boolean;
begin
  case IndexText(
    Slug,
    [
      'localhost',
      '127',
      'app',
      'api',
      '',
      '.env',
      '.php',
      '.json',
      '.',
      '/.'
    ]
  ) of 0..9: Result := True;
  else ;
    Result := False;
  end;
end;

procedure HandlerPortifolioGet(req: THorseRequest; res: THorseResponse);
var
  HostStr, Slug: string;
  PosPonto: Integer;
  Perfil: TArtistaPerfil;
  HTMLFinal: string;
  verifica: boolean;
begin

  HostStr := Req.Headers['Host'];
  PosPonto := Pos('.', HostStr);

  if PosPonto > 0 then
    Slug := Copy(HostStr, 1, PosPonto - 1)
  else
    Slug := HostStr;


  //verifica := verifica_slug(slug);
  if verifica_slug(slug) then
  begin
    TJsonView.SendHtml(res, 404, '<h1>Página não encontrada</h1>');
    Exit;
  end;

  try
    Perfil := TProtifolioModel.GetBySlug(Slug);
    if not Perfil.Encontrado then
    begin
      TJsonView.SendHtml(res, 404, '<h1>Artista não encontrado.</h1><p>Verifique o endereço.</p>');
      Exit;
    end;

    HTMLFinal := TPortifolioView.Render(Perfil, Slug);

    TJsonView.SendHtml(res, 200, HTMLFinal);
  except
    on E: Exception do
    begin
      TJsonView.SendHtml(
        res,
        500,
        '<h1>Erro interno do servidor</h1><p>Tente novamente mais tarde.</p>'
      );
    end;

end;

end;

procedure HandlePortifolioUpdate(req: THorseRequest; res: THorseResponse;
  next: TNextProc);
var
  jsonreq, jsonres: TJSONObject;
  id_loja, titulo, subtitulo, avatar, foto_bio, bio: string;
  id_site: integer;
  lJSONData: TJSONData;
begin
  jsonreq := nil;
  jsonres := nil;
  try
    try
      lJSONData := GetJSON(req.Body);
      if Assigned(lJSONData) and (lJSONData.JSONType = jtObject) then
        jsonreq := TJSONObject(lJSONData)
      else
      begin
        TJsonView.SendError(res, 400, 'JSON inválido.');
        if Assigned(lJSONData) then lJSONData.Free;
        Exit;
      end;

      id_loja   := jsonreq.Get('id_loja', '');
      titulo    := jsonreq.Get('titulo', '');
      subtitulo := jsonreq.Get('subtitulo', '');
      avatar    := jsonreq.Get('avatar', '');
      foto_bio  := jsonreq.Get('foto_bio', '');
      bio       := jsonreq.Get('bio', '');
      id_site   := jsonreq.Get('id_site', 0);

      if (id_loja = '') then
      begin
        TJsonView.SendError(res, 400, 'O ID da Loja é obrigatório.');
        Exit;
      end;

      TProtifolioModel.SavePortfolio(
        id_loja,
        titulo,
        subtitulo,
        avatar,
        foto_bio,
        bio
      );

      jsonres := TJSONObject.Create;

      jsonres.Add('id_portfolio', id_site);

      TJsonView.SendResponseJsonObject(res, jsonres, 200);
    except
      on e:exception do
      begin
        TJsonView.SendError(res, 500, e.Message);
        if Assigned(jsonres) then jsonres.Free;
      end;
    end;
  finally
    if Assigned(jsonreq) then jsonreq.Free;
  end;
end;

procedure HandlerPortifolioGetInfo(req: THorseRequest; res: THorseResponse;
  next: TNextProc);
var
  jsonres: TJSONObject;
  id_loja: string;
  status: Boolean;
begin
  jsonres := nil;
  try
    id_loja := req.Params['id_loja'];

    if Trim(id_loja) = '' then
    begin
      TJsonView.SendError(res, 400, 'Parâmetro id_loja é obrigatório.');
      Exit;
    end;

    jsonres := TProtifolioModel.GetPortfolio(id_loja);

    if Assigned(jsonres) = True then
      TJsonView.SendResponseJsonObject(res, jsonres, 200)
    else
      begin
        TJsonView.SendError(res, 404, 'Portfólio não encontrado!');
        if Assigned(jsonres) then jsonres.Free;
      end;
  except
    on e:exception do
    begin
      TJsonView.SendError(res, 500, e.Message);
      if Assigned(jsonres) then jsonres.Free;
    end;
  end;
end;

procedure HandleRemoveItem(req: THorseRequest; Res: THorseResponse;
  next: TNextProc);
var
  id: integer;
  str_id: string;
begin
  str_id := req.Params['id_foto'];
  id := StrToIntDef(str_id, 0);
  try
    TProtifolioModel.RemoveItem(id);
    TJsonView.SendSuccess(res);
  except on e:exception do
    TJsonView.SendError(res, 500, e.Message);
  end;
end;

procedure HandleUploadFoto(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq: TJSONObject;
  id_loja, base64_str, nome_arquivo: string;
  id_site: integer;
  lJSONData: TJSONData;
  DM: TDataModule1;
begin
  jsonreq := nil;
  try
    try
      try
        DM := TDataModule1.Create(nil);
        id_loja := DM.GetIdLoja(req.Headers['Authorization']);
      except
        on E: Exception do
        begin
          TJsonView.SendError(res, 500, 'Erro ao ler token: ' + E.Message);
          Exit;
        end;
      end;

      if id_loja = '' then
      begin
        TJsonView.SendError(res, 401, 'Token inválido ou sem id_loja.');
        Exit;
      end;

      lJSONData := GetJSON(req.Body);
      if Assigned(lJSONData) and (lJSONData.JSONType = jtObject) then
        jsonreq := TJSONObject(lJSONData)
      else
      begin
        TJsonView.SendError(res, 400, 'JSON inválido.');
        if Assigned(lJSONData) then lJSONData.Free;
        Exit;
      end;

      id_site      := jsonreq.Get('id_site', 0);
      nome_arquivo := jsonreq.Get('nome_arquivo', '');
      base64_str   := jsonreq.Get('imagem_base64', '');

      if (id_loja = '') or (base64_str = '') then
      begin
        TJsonView.SendError(res, 400, 'Dados inválidos.');
        Exit;
      end;

      TProtifolioModel.UploadFoto(id_site, nome_arquivo, base64_str, id_loja);

      TJsonView.SendSuccess(res);
    except
      on e: exception do
        TJsonView.SendError(res, 500, e.Message);
    end;
  finally
    if Assigned(jsonreq) then jsonreq.Free;
    DM.Free;
  end;
end;

procedure HandleGetGaleria(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  id_portfolio: integer;
  jsonres: TJSONObject;
begin
  jsonres := nil;
  try
    id_portfolio := StrToInt(req.Params['id_portfolio']);

    jsonres := TProtifolioModel.GetGaleria(id_portfolio);

    TJsonView.SendResponseJsonObject(res, jsonres, 200);
  except
    on EConvertError do
      TJsonView.SendError(res, 400, 'id inválido');
    on e:exception do
    begin
      TJsonView.SendError(res, 500, e.Message);
      if Assigned(jsonres) then jsonres.Free;
    end;
  end;
end;

procedure HandleUpdateAvatar(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq, jsonres: TJSONObject;
  id_loja, nome_arquivo, base64_str: string;
  id_site: integer;
  lJSONData: TJSONData;
  DM: TDataModule1;
begin
  jsonreq := nil;
  jsonres := nil;
  try
    try
      try
        DM := TDataModule1.Create(nil);
        id_loja := DM.GetIdLoja(req.Headers['Authorization']);
      except on e:exception do
      begin
        TJsonView.SendError(res, 500, 'Erro ao ler token: ' + E.Message);
        Exit;
      end;
      end;

      if id_loja = '' then
      begin
        TJsonView.SendError(res, 401, 'Token inválido ou sem id_loja.');
        Exit;
      end;

      lJSONData := GetJSON(req.Body);
      if Assigned(lJSONData) and (lJSONData.JSONType = jtObject) then
        jsonreq := TJSONObject(lJSONData)
      else
      begin
        TJsonView.SendError(res, 400, 'JSON inválido.');
        if Assigned(lJSONData) then lJSONData.Free;
        Exit;
      end;

      id_site      := jsonreq.Get('id_site', 0);
      nome_arquivo := jsonreq.Get('nome_arquivo', '');
      base64_str   := jsonreq.Get('imagem_base64', '');

      if (id_loja = '') or (base64_str = '') then
      begin
        TJsonView.SendError(res, 400, 'Dados inválidos.');
        Exit;
      end;

      id_site := TProtifolioModel.UpdateAvatar(id_site, nome_arquivo, id_loja, base64_str);

      jsonres := TJSONObject.Create;

      jsonres.Add('id_portfolio', id_site);

      TJsonView.SendResponseJsonObject(res, jsonres, 200);
    except on e:exception do
    begin
      TJsonView.SendError(res, 500, e.Message);
      if Assigned(jsonres) then jsonres.Free;
    end;
    end;
  finally
    if Assigned(jsonreq) then jsonreq.Free;
    DM.Free;
  end;
end;

procedure HandleUpdateFotoBio(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq, jsonres: TJSONObject;
  id_loja, nome_arquivo, base64_str: string;
  id_site: integer;
  lJSONData: TJSONData;
  DM: TDataModule1;
begin
  jsonreq := nil;
  jsonres := nil;
  try
    try
      try
        DM := TDataModule1.Create(nil);
        id_loja := DM.GetIdLoja(req.Headers['Authorization']);
      except on e:exception do
      begin
        TJsonView.SendError(res, 500, 'Erro ao ler token: ' + E.Message);
        Exit;
      end;
      end;

      if id_loja = '' then
      begin
        TJsonView.SendError(res, 401, 'Token inválido ou sem id_loja.');
        Exit;
      end;

      lJSONData := GetJSON(req.Body);
      if Assigned(lJSONData) and (lJSONData.JSONType = jtObject) then
        jsonreq := TJSONObject(lJSONData)
      else
      begin
        TJsonView.SendError(res, 400, 'JSON inválido.');
        if Assigned(lJSONData) then lJSONData.Free;
        Exit;
      end;

      id_site      := jsonreq.Get('id_site', 0);
      nome_arquivo := jsonreq.Get('nome_arquivo', '');
      base64_str   := jsonreq.Get('imagem_base64', '');

      if (id_loja = '') or (base64_str = '') then
      begin
        TJsonView.SendError(res, 400, 'Dados inválidos.');
        Exit;
      end;

      id_site := TProtifolioModel.UpdateFotoBio(id_site, nome_arquivo, id_loja, base64_str);

      jsonres := TJSONObject.Create;
      jsonres.Add('id_portfolio', id_site);

      TJsonView.SendResponseJsonObject(res, jsonres, 200);
    except on e:exception do
    begin
      TJsonView.SendError(res, 500, e.Message);
      if Assigned(jsonres) then jsonres.Free;
    end;
    end;
  finally
    if Assigned(jsonreq) then jsonreq.Free;
    DM.Free;
  end;
end;

procedure HandlerRobotsGet(req: THorseRequest; res: THorseResponse; next: TNextProc);
begin
  res.ContentType('text/plain')
     .Send('User-agent: *' + sLineBreak + 'Allow: /');
end;

class procedure TPortifolioController.RegisterRoutes();
begin
  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/portfolio/update', HandlePortifolioUpdate);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Get('api/v1/portfolio/info/:id_loja', HandlerPortifolioGetInfo);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Get('api/v1/portfolio/remove/:id_foto', HandleRemoveItem);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Get('api/v1/portfolio/galeria/:id_portfolio', HandleGetGaleria);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/portfolio/avatar', HandleUpdateAvatar);

  THorse.AddCallback(HorseJWT(DataModule1.token))
  .Post('api/v1/portfolio/foto-bio', HandleUpdateFotoBio);

  THorse.get('/', HandlerPortifolioGet);

  THorse.Get('/robots.txt', HandlerRobotsGet);

  THorse.AddCallback(HorseJWT(DataModule1.token))
    .Post('api/v1/portfolio/upload', HandleUploadFoto);
end;

end.

