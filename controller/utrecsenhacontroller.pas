unit utrecsenhacontroller;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Horse, urecsenhamodel, fpjson, uJsonView, process, logger,
  umailmodel, uoauthtokenmodel, ustoragetokensmodel, uNetService;

type

  { TRecSenhaController }

  TRecSenhaController = class

    public
      class procedure RegisterRoutes();

  end;

implementation

{ TRecSenhaController }


procedure HandleRecuperarSenha(Req: THorseRequest; Res: THorseResponse; next: TNextProc);
var
  recSenhaModel: TRecSenhaModel;
  mailMode: TmailModel;
  Email, tempPass, resposta: string;
  passData, RequestJson, JsonMessage, jsonresposta: TJSONObject;
  StringList, StringPass: TStringList;
begin
  try
     RequestJson := TJSONObject(GetJSON(Req.Body));

     if not Assigned(RequestJson) then
     begin
       TJsonView.SendError(res, 400, 'Json invalido!');
       exit;
     end;

     email := RequestJson.Find('email').AsString;

     if email = '' then
     begin
       TJsonView.SendError(res, 400, 'Email é obrigatório!');
       exit;
     end;

     recSenhaModel := TRecSenhaModel.Create;

     try
        tempPass:=recSenhaModel.GeneratePassword(Email);

        if tempPass = '0' then
        begin
          JsonMessage := TJSONObject.Create;
          try
             JsonMessage.Add('message', 'Email não encontrado!');
             TJsonView.SendResponse(res, JsonMessage, 404);
          finally
            JsonMessage.Free;
          end;
            exit;
        end
        else
        begin

          //StringList := TStringList.Create;
          //
          //StringList.LoadFromFile(ExtractFilePath(ParamStr(0))+'resources/senha_temp.html');
          //
          //StringPass := TStringList.Create;
          //
          //StringPass.Add(StringReplace(StringList.Text, '{{SENHA_TEMPORARIA}}', tempPass, [rfReplaceAll]));

          try
             jsonresposta := TJSONObject(GetJSON(TNetService.rec_senha(Email, tempPass)));

             resposta:=jsonresposta.find('status_code').AsString;
             if resposta = '200' then
             begin
               passData := TJSONObject.Create;
               passData.Add('success', True);
               passData.Add('message', 'Um email com uma senha temporaria foi enviado para ' + Email);
               TJsonView.SendResponse(res, passData, 200);
             end
             else
             begin
               passData := TJSONObject.Create;
               passData.Add('success', False);
               passData.Add('message', 'Houve um erro interno no envio do email!');
               TJsonView.SendResponse(res, passData, 500);
             end;
          finally
            jsonresposta.Free;
            passData.Free;
            //StringList.Free;
            //StringPass.Free;
          end;
        end;

     finally
       recSenhaModel.Free;
       RequestJson.Free;
     end;

  except on e: Exception do
  begin
         Log.LogError('Erro na procedure HandleRecuperarSenha: '+
         e.Message, 'HandleRecuperarSenha');

         TJsonView.SendError(res, 500,
         'Erro interno do servidor ao processar sua solicitação: ' + E.Message);
  end;
end;

end;

class procedure TRecSenhaController.RegisterRoutes();
begin
   THorse.post('/api/v1/resenha', HandleRecuperarSenha);
end;

end.

