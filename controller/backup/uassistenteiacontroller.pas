unit uassistenteiacontroller;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Horse, fpjson, db,
  uCacheService, uQueueService, uAssistenteIaModel, uAssistenteIaDAO;

type
  TAssistenteIa = class
  public
    class procedure RegisterRoutes();
  end;

implementation

// Função para evitar que nomes como "~.___.~" ou apenas emojis passem
function ExtrairNomeValido(const ANomeBruto: string): string;
var
  i: Integer;
  TemLetra: Boolean;
begin
  TemLetra := False;

  // Verifica se existe pelo menos uma letra comum no nome
  for i := 1 to Length(ANomeBruto) do
  begin
    if ANomeBruto[i] in ['A'..'Z', 'a'..'z'] then
    begin
      TemLetra := True;
      Break;
    end;
  end;

  // Só retorna o nome se detectou letra e não é só 1 caractere perdido
  if TemLetra and (Length(Trim(ANomeBruto)) > 1) then
    Result := Trim(ANomeBruto)
  else
    Result := '';
end;

// Extrai o conteúdo da mensagem conforme seu tipo
function ExtrairConteudoMensagem(jsonMsg, jsonData: TJSONObject; out vMimeType, vBase64: string): string;
begin
  Result := '';
  vMimeType := '';
  vBase64 := '';

  // -- TEXTO SIMPLES --
  if jsonMsg.IndexOfName('conversation') > -1 then
    Result := jsonMsg.Get('conversation', '')

  // -- TEXTO COM LINK OU CITAÇÃO --
  else if jsonMsg.IndexOfName('extendedTextMessage') > -1 then
    Result := jsonMsg.FindPath('extendedTextMessage.text').AsString

  // -- IMAGEM --
  else if jsonMsg.IndexOfName('imageMessage') > -1 then
  begin
    Result := jsonMsg.Get('imageMessage.caption', '');
    if Result = '' then
      Result := 'O cliente enviou uma imagem de referência para a tatuagem. Analise a imagem e responda o que acha e como seria o orçamento.';

    if Assigned(jsonMsg.FindPath('imageMessage.mimetype')) then
      vMimeType := jsonMsg.FindPath('imageMessage.mimetype').AsString;
    if Assigned(jsonData.FindPath('message.base64')) then
      vBase64 := jsonData.FindPath('message.base64').AsString;
  end

  // -- ÁUDIO (MENSAGEM DE VOZ) --
  else if jsonMsg.IndexOfName('audioMessage') > -1 then
  begin
    Result := 'O cliente enviou uma mensagem de voz. Ouça o áudio com atenção, entenda o que ele quer e responda seguindo as suas regras financeiras e de estilo.';

    if Assigned(jsonMsg.FindPath('audioMessage.mimetype')) then
      vMimeType := jsonMsg.FindPath('audioMessage.mimetype').AsString;
    if Assigned(jsonData.FindPath('message.base64')) then
      vBase64 := jsonData.FindPath('message.base64').AsString;
  end;
end;

// Configura as propriedades do objeto de mensagem
procedure ConfigurarMensagem(objMsg: TAssistantMessage; const instanceUUID, remoteJid, conteudo, pushName: string;
                              const config: TConfigLoja; const vMimeType, vBase64: string);
begin
  objMsg.InstanciaId     := instanceUUID;
  objMsg.WhatsAppId      := remoteJid;
  objMsg.Content         := conteudo;
  objMsg.Role            := 'user';
  objMsg.ExemploMensagem := config.ExemploMensagem;
  objMsg.NomeAssistente  := config.NomeAssistente;
  objMsg.NomeCliente     := pushName;
  objMsg.DuracaoSessao   := config.tempo_sessao;
  objMsg.ValorMinimo     := config.ValorMinimo;
  objMsg.ValorHora       := config.ValorHora;
  objMsg.ValorSessao     := config.ValorSessao;
  objMsg.MimeType        := vMimeType;
  objMsg.Base64Data      := vBase64;
end;

// Recupera e formata o histórico de mensagens
procedure CarregarHistorico(objMsg: TAssistantMessage; const instanceUUID, remoteJid: string);
var
  dsHistorico: TDataSet;
  listaHistorico: TStringList;
  lRole, lContent: string;
begin
  dsHistorico := TMensagemDAO.ObterContexto(instanceUUID, remoteJid, 30);
  try
    listaHistorico := TStringList.Create;
    try
      dsHistorico.First;
      while not dsHistorico.EOF do
      begin
        lRole := dsHistorico.FieldByName('ROLE').AsString;
        lContent := dsHistorico.FieldByName('CONTENT').AsString;

        if lRole = 'user' then
          listaHistorico.Insert(0, 'Cliente: ' + lContent)
        else
          listaHistorico.Insert(0, 'Assistente: ' + lContent);

        dsHistorico.Next;
      end;
      objMsg.ContextoHistorico := listaHistorico.Text;
    finally
      listaHistorico.Free;
    end;
  finally
    dsHistorico.Free;
  end;
end;

// Processa e enfileira a mensagem
procedure ProcessarMensagem(objMsg: TAssistantMessage; const config: TConfigLoja; const remoteJid, vBase64: string);
begin
  TMensagemDAO.Inserir(objMsg);
  CarregarHistorico(objMsg, objMsg.InstanciaId, remoteJid);
  TQueueService.Instance.AdicionarAFila(objMsg);

  WriteLn('Mensagem enfileirada: ' + config.NomeAssistente + ' -> ' + remoteJid);
  if vBase64 <> '' then
    WriteLn(' > Mídia recebida e anexada ao contexto.');
end;

// Extrai dados essenciais do JSON da requisição
function ExtrairDadosRequisicao(jsonReq: TJSONObject; out instanceUUID: string; out config: TConfigLoja): Boolean;
begin
  instanceUUID := jsonReq.Get('instance', '');
  Result := TCacheService.GetConfig(instanceUUID, config);
end;

// Extrai dados da mensagem do JSON
function ExtrairDadosMensagem(jsonData, jsonKey, jsonMsg: TJSONObject; out fromMe: Boolean;
                              out remoteJid, pushName: string): Boolean;
begin
  fromMe := jsonKey.Get('fromMe', False);
  remoteJid := jsonKey.Get('remoteJid', '');
  pushName := ExtrairNomeValido(jsonData.Get('pushName', ''));
  Result := (remoteJid <> '');
end;

// Valida a estrutura JSON recebida
function ValidarJSON(jsonReq: TJSONObject; out jsonData, jsonKey, jsonMsg: TJSONObject): Boolean;
begin
  jsonData := jsonReq.FindPath('data') as TJSONObject;
  if not Assigned(jsonData) then
    Exit(False);

  jsonKey := jsonData.FindPath('key') as TJSONObject;
  jsonMsg := jsonData.FindPath('message') as TJSONObject;
  Result := Assigned(jsonKey) and Assigned(jsonMsg);
end;

procedure HandleAssistenteIaWebhook(req: THorseRequest; res: THorseResponse);
var
  jsonReq, jsonData, jsonMsg, jsonKey: TJSONObject;
  instanceUUID, remoteJid, textoFinal, pushName, vMimeType, vBase64, evento: string;
  fromMe: Boolean;
  config: TConfigLoja;
  objMsg: TAssistantMessage;
begin
  jsonReq := nil;
  try
    jsonReq := TJSONObject(GetJSON(req.Body));
    if not Assigned(jsonReq) then Exit;

    // Valida evento (só processa 'messages.upsert')
    evento := jsonReq.FindPath('event').AsString;
    if evento <> 'messages.upsert' then
    begin
      res.Status(200).Send('Evento ignorado: ' + jsonReq.Get('event', ''));
      Exit;
    end;

    // Valida instância e configuração
    if not ExtrairDadosRequisicao(jsonReq, instanceUUID, config) then
    begin
      res.Status(200).Send('Instância não localizada no Cache do Inkers');
      Exit;
    end;

    // Verifica se assistente está ativo
    if not config.AssistenteAtivo then
    begin
      res.Status(200).Send('Assistente desativado para esta loja');
      Exit;
    end;

    // Valida estrutura JSON
    if not ValidarJSON(jsonReq, jsonData, jsonKey, jsonMsg) then Exit;

    // Extrai dados da mensagem
    if not ExtrairDadosMensagem(jsonData, jsonKey, jsonMsg, fromMe, remoteJid, pushName) then Exit;

    // Ignora mensagens do próprio proprietário
    if fromMe then
    begin
      TMensagemDAO.DesativarBotParaContato(instanceUUID, remoteJid);
      res.Status(200).Send('Ignorado: Mensagem enviada pelo dono');
      Exit;
    end;

    if not TMensagemDAO.BotEstaAtivo(instanceUUID, remoteJid) then
    begin
      res.Status(200).Send('Bot pausado para este contato. Aguardando atendimento humano.');
      Exit;
    end;

    // Extrai conteúdo conforme o tipo
    textoFinal := ExtrairConteudoMensagem(jsonMsg, jsonData, vMimeType, vBase64);

    // Processa e enfileira a mensagem
    if (textoFinal <> '') then
    begin
      objMsg := TAssistantMessage.Create;

      ConfigurarMensagem(objMsg, instanceUUID, remoteJid, textoFinal, pushName, config, vMimeType, vBase64);
      ProcessarMensagem(objMsg, config, remoteJid, vBase64);

    end;

    res.Status(200).Send('OK');

  except
    on E: Exception do
      res.Status(500).Send('Erro Interno: ' + E.Message);
  end;

  if Assigned(jsonReq) then jsonReq.Free;
end;

class procedure TAssistenteIa.RegisterRoutes();
begin
  THorse.Post('api/v1/public/assistente/webhook', HandleAssistenteIaWebhook);
end;

end.
