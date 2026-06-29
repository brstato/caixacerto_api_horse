unit uanamnesecontroller;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, Horse, Horse.JWT, uanamnesemodel, uzapmodel, uJsonView,
  udata, fpjson, uPDFService, uNetService;

type

  { TAnamneseController }

  TAnamneseController = class
    public
      class procedure RegisterRoutes();
  end;

implementation

{ TAnamneseController }

procedure HandlerAnamneseCreate(req: THorseRequest; res: THorseResponse; next: TNextProc);
const prompt_anamnese: string = 'Atue como um especialista em biossegurança e gerente de estúdio de tatuagem. '+  #13#10 +
'Analise o JSON abaixo contendo os dados da ficha de anamnese de um cliente. '+ #13#10 +
'Sua tarefa é fornecer um relatório curto e direto com dois focos: '+ #13#10 +
'1. ANÁLISE DE RISCO E APTIDÃO (Saúde): '+ #13#10 +
'- Verifique campos críticos: '+ #13#10 +
'Diabético, '+ #13#10 +
'Hipertenso, ' + #13#10 +
'Hemofílico, '+ #13#10 +
'Gestante/Amamentando, '+ #13#10 +
'Problemas de Pele, '+ #13#10 +
'Doenças Transmissíveis e uso de Álcool/Drogas nas últimas 24h. ' + #13#10 +
'- Se o campo alcool_drogas for positivo, o cliente requer avaliação. '+ #13#10 +
'- Se houver condições médicas (Diabetes, Hemofilia, Problemas de pele), alerte para "REQUER AVALIAÇÃO CUIDADOSA". '+ #13#10 +
'- Veredito final: APTO, INAPTO ou REQUER AVALIAÇÃO. '+ #13#10 +
#13#10 +
'2. ANÁLISE DE PERFIL COMERCIAL (Marketing): '+ #13#10 +
'- Analise a profissão, capacidade financeira com base na profissão, estilo de tatuagem preferido e como conheceu o estúdio. '+ #13#10 +
'- Se veio por indicação, destaque como um ponto forte de fidelização. '+ #13#10 +
'- Se tem estilo definido (ex: "Delicado"), sugira se é um bom nicho para o estúdio. '+ #13#10 +
'- Classifique o perfil do cliente para o negócio como: POTENCIAL BAIXO, MÉDIO ou ALTO. '+ #13#10 +
#13#10 +
'Responda no seguinte formato: '+ #13#10 +
'--- '+ #13#10 +
'RESUMO DA ANÁLISE '+ #13#10 +
'Cliente: [Nome] '+ #13#10 +
'Status Saúde: [APTO / INAPTO / AVALIAR] '+ #13#10 +
'Alerta Médico: [Liste apenas se houver problemas, caso contrário diga "Nenhum"] '+ #13#10 +
#13#10 +
'Perfil Comercial: [A / B / C] '+ #13#10 +
'Observação: [Uma frase sobre o estilo ou origem do cliente] '+ #13#10 +
'--- ' + #13#10;
var
  jsonreq: TJSONObject;
  model: TAnamneseModel;
  date: TDateTime;
  fmt: TFormatSettings;
  dados: TAnamneseDTO;
  anamnese, anamnese64, zap_instance: string;
  legenda: UTF8String;
begin
  jsonreq := TJSONObject(GetJSON(req.Body));
  model := TAnamneseModel.Create;
  try
    try
      fmt.DateSeparator:='/';
      fmt.ShortDateFormat:='dd/mm/yyyy';

      date := StrToDate(jsonreq.get('data_nascimento', '01/01/1900'), fmt);

      dados.Profissao          := jsonreq.find('profissao'            ).AsString;
      dados.ComoConheceu       := jsonreq.find('como_conheceu'        ).AsString;
      dados.Consumo            := jsonreq.find('consumo'              ).AsString;
      dados.PraticaEsporte     := jsonreq.find('pratica_esporte'      ).AsString;
      dados.QualEsporte        := jsonreq.find('qual_esporte'         ).AsString;
      dados.Diabetico          := jsonreq.find('diabetico'            ).AsString;
      dados.Hipertenso         := jsonreq.find('hipertenso'           ).AsString;
      dados.Hemofilico         := jsonreq.find('hemofilico'           ).AsString;
      dados.ProblemaPele       := jsonreq.find('problema_de_pele'     ).AsString;
      dados.QualProblemaPele   := jsonreq.find('qual_problema_de_pele').AsString;
      dados.GestanteAmamentando:= jsonreq.find('gestante_amamentando' ).AsString;
      dados.AlcoolDrogas       := jsonreq.find('alcool_drogas'        ).AsString;
      dados.DoencaTransmissivel:= jsonreq.find('doenca_transmissivel' ).AsString;
      dados.QualDoenca         := jsonreq.find('qual_doenca'          ).AsString;
      dados.Alergia            := jsonreq.find('alergia'              ).AsString;
      dados.QualAlergia        := jsonreq.find('qual_alergia'         ).AsString;
      dados.Medicamento        := jsonreq.find('medicamento'          ).AsString;
      dados.QualMedicamento    := jsonreq.find('qual_medicamento'     ).AsString;
      dados.ConcordaTermos     := jsonreq.find('concorda_com_termos'  ).AsString;
      dados.GostoPiercing      := jsonreq.find('gosto_piercing'       ).AsString;
      dados.GostoTatuagem      := jsonreq.find('gosto_tatuagem'       ).AsString;
      dados.EstiloTatuagem     := jsonreq.find('estilo_tatuagem'      ).AsString;
      dados.Nome               := jsonreq.find('nome'                 ).AsString;
      dados.Insta              := jsonreq.find('insta'                ).AsString;
      dados.telefone_studio    := jsonreq.find('telefone_estudio'     ).AsString;
      dados.Assinatura         := jsonreq.find('assinatura'           ).AsString;
      dados.Telefone           := jsonreq.find('telefone'             ).AsString;
      dados.nome_estudio       := jsonreq.find('nome_estudio'         ).AsString;
      dados.id_profissional    := jsonreq.find('id_profissional'      ).AsInteger;

      dados.DataNascimento     := date;

      model.createAnamnese(dados);

      TJsonView.SendResponse(res, TJSONObject(GetJSON('{"status":"sucesso"}')), 200);

      anamnese:=TPDFService.GerarPDFAnamnese(dados);

      anamnese64:=TPDFService.FileToBase64(anamnese);

      legenda := TNetService.getGemini(jsonreq, prompt_anamnese);

      zap_instance := TZapModel.buscainstancezap(dados.telefone_studio );

      TNetService.EnviarArquivoWhatsapp(dados.telefone_studio, anamnese, anamnese64, legenda, zap_instance);

      TNetService.EnviarArquivoWhatsapp(dados.Telefone, anamnese, anamnese64, '', zap_instance);

      //TNetService.EnviarPushOneSignal(
      //  dados.telefone_studio,
      //  'Nova Ficha Preenchida! 📝',
      //  'O cliente ' + dados.Nome + ' acabou de assinar a anamnese. Confira a avaliação.'
      //);

    except on e:exception do
    begin
        TJsonView.SendResponse(res, TJSONObject(GetJSON(Format('{"status":"error", "message":%s}',[e.Message]))), 409)
    end;
    end;
  finally
    jsonreq.Free;
    model.Free;
  end;
end;


procedure HandlerAnamneselist_profissionais(req: THorseRequest; res: THorseResponse; next: TNextProc);
var
  jsonreq, jsonres: TJSONObject;
  telefone: string;
  model: TAnamneseModel;
begin
  model := TAnamneseModel.Create;
  try
    try
      jsonreq := TJSONObject(GetJSON(req.body));

      telefone := jsonreq.find('telefone').AsString;

      jsonres := TJSONObject(GetJSON(model.return_professional(telefone)));

      TJsonView.SendResponse(res, jsonres, 200);
    except on e:exception do
      TJsonView.SendError(res, 500, e.Message);
    end;
  finally
    model.Free;
    jsonreq.Free;
    jsonres.Free;
  end;
end;

class procedure TAnamneseController.RegisterRoutes();
begin
  THorse.Post('api/v1/anamnese/create', HandlerAnamneseCreate);
  THorse.Post('api/v1/anamnese/list_profissionais', HandlerAnamneselist_profissionais);
end;

end.

