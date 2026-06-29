unit uagendamodel;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, fpjson, ugetdata, sql_queries, db, DateUtils;

type
  TTurno = record
    Nome:     string;
    Inicio:   string;
    Fim:      string;
  end;

type

  { TAgendaModel }

  TAgendaModel = class
    public
      function listAgendamentos(id:integer; date:string): UTF8String;
      function listResumoAgenda(id:integer; date:string): UTF8String;
      function detailAgendamento(id: integer):UTF8String;
      procedure createAgendamento(id_prof, id_client: integer;
  hora_ini, hora_fim, name_client, telefone, event_id, uuid: string; date:TDateTime;
  out status_code: integer; valor, sinal:currency);
      procedure deleteAgendamento(id: integer);
      procedure updateAgendamento(id, id_prof, id_client: integer;
  valor, sinal: currency; telefone, client, h_ini, h_fim, event_id: string;
  date:TDateTime; out status_code: integer);
      function getTurnosDisponiveis(id_prof: integer): UTF8String;
      function getDisponibilidadePublica(telefone_loja: string; id_profissional:integer): UTF8String;
      function getclientetelefone(telefone: string; out status: integer): UTF8String;
      function getprofissionaisid(id: integer): UTF8String;
      function buscadadosagendaturnos(telefone:string): UTF8String;
      class function SolicitarAgendamento(const idProfissional,
        id_cliente: Integer; const cliente, telefone, data, horaIni, horaFim, uuid: string): boolean;
      class function ListarPendentes(const idProfissional: Integer): UTF8String;
      class function notificacao_pendentes(id_loja_ex: string): integer;

  end;

implementation

{ TAgendaModel }

class function TAgendaModel.ListarPendentes(const idProfissional: Integer): UTF8String;
var
  Query: TDataSet;
  ItemJson: TJSONObject;
  jsonarray: TJSONArray;
begin
  jsonarray := TJSONArray.Create;
  try

    Query := TGetData.getData(
      sql_queries.list_solicitacoes_pendentes,
      [idProfissional],
      True
    );

    try
      with query do
      begin
        while not EOF do
        begin
          ItemJson := TJSONObject.Create;
          ItemJson.add('cod_client', FieldByName('COD_CLIENT').AsInteger);
          ItemJson.Add('id',         FieldByName('ID'        ).AsInteger);
          ItemJson.Add('cliente',    FieldByName('CLIENTE'   ).AsString);
          ItemJson.Add('telefone',   FieldByName('TELEFONE'  ).AsString);
          ItemJson.Add('hora_ini',   FieldByName('HORA_INI'  ).AsString);
          ItemJson.Add('hora_fim',   FieldByName('HORA_FIM'  ).AsString);
          ItemJson.Add('tarefa',     FieldByName('TAREFA'    ).AsString);
          ItemJson.add('valor', FormatCurr('0.00', FieldByName('valor').AsCurrency));
          ItemJson.add('sinal', FormatCurr('0.00', FieldByName('sinal').AsCurrency));
          ItemJson.Add('data', FormatDateTime('yyyy-mm-dd', FieldByName('DATA2').AsDateTime));

          jsonarray.Add(ItemJson);
          Query.Next;
        end;
      end;
      result := jsonarray.AsJSON;
    finally
      Query.Free;
      jsonarray.Free;
    end;
  except
    on E: Exception do
    begin
      raise Exception.Create('Erro ao listar solicitações pendentes: ' + E.Message);
    end;
  end;
end;

class function TAgendaModel.notificacao_pendentes(id_loja_ex: string): integer;
var
  dataset: TDataSet;
begin
  dataset := nil;
  try
    dataset := TGetData.getData(
      sql_queries.notificacao_agenda_pendente,
      [id_loja_ex],
      True
    );
    result := dataset.RecordCount;
  finally
  dataset.Free;
  end;
end;

function TAgendaModel.listAgendamentos(id: integer; date:string): UTF8String;
var
  getdata: TGetData;
  jsonIten: TJSONObject;
  jsonarray: TJSONArray;
  dataset: TDataSet;
  data: string;
  date_obj: TDateTime;
  fmt: TFormatSettings;
begin
  getdata := TGetData.Create;
  jsonarray := TJSONArray.Create;

  fmt := DefaultFormatSettings;
  fmt.DateSeparator := '-';
  fmt.ShortDateFormat := 'yyyy-mm-dd';
  date_obj := StrToDate(date, fmt);

  try
    dataset := getdata.getData(
      sql_queries.list_agendamentos_simples,
      [id, date_obj],
      true
    );
    with dataset do
    begin
      first;
      while not eof do
      begin
        jsonIten := TJSONObject.Create;

        data := FormatDateTime('dd/mm/yyyy', FieldByName('data2'     ).AsDateTime);

        jsonIten.Add('cliente',    FieldByName('cliente'   ).AsString);
        jsonIten.Add('hora_ini',   FieldByName('hora_ini'  ).AsString);
        jsonIten.Add('hora_fim',   FieldByName('hora_fim'  ).AsString);
        jsonIten.Add('tarefa',     FieldByName('tarefa'    ).AsString);
        jsonIten.Add('telefone',   FieldByName('telefone'  ).AsString);
        jsonIten.add('event_id',   FieldByName('event_id'  ).AsString);
        jsonIten.Add('cod_client', FieldByName('cod_client').AsInteger);
        jsonIten.Add('id',         FieldByName('id'        ).AsInteger);
        jsonIten.Add('data',                                      data);
        jsonIten.add('valor', FormatCurr('0.00', FieldByName('valor').AsCurrency));
        jsonIten.add('sinal', FormatCurr('0.00', FieldByName('sinal').AsCurrency));

        jsonarray.Add(jsonIten);
        next;
      end;

    end;
    Result := jsonarray.AsJSON;
  finally
    jsonarray.Free;
    dataset.Free;
    getdata.Free;
  end;
end;

function TAgendaModel.listResumoAgenda(id: integer; date: string): UTF8String;
var
  getData: TGetData;
  dataset: TDataSet;
  jsonIten: TJSONObject;
  jsonArray: TJSONArray;
  date_obj: TDateTime;
  fmt: TFormatSettings;
begin
  fmt := DefaultFormatSettings;
  fmt.DateSeparator := '-';
  fmt.ShortDateFormat := 'yyyy-mm-dd';
  date_obj := StrToDate(date, fmt);

  getData := TGetData.Create;
  jsonArray := TJSONArray.Create;
  try
    dataset := getData.getData(
      sql_queries.list_resumo_agenda,
      [id, date_obj],
      True
    );
    with dataset do
    begin
      first;
      while not eof do
      begin
        jsonIten := TJSONObject.Create;

        jsonIten.add('date', FieldByName('data2').AsString);

        jsonArray.Add(jsonIten);
        next;
      end;
    end;
    Result := jsonArray.AsJSON;
  finally
    jsonArray.Free;
    getData.Free;
    dataset.Free;
  end;
end;

function TAgendaModel.detailAgendamento(id: integer): UTF8String;
var
  getData: TGetData;
  data: TDataSet;
  jsonres: TJSONObject;
begin
  getData := TGetData.Create;
  try
    data := getData.getData(
      sql_queries.detail_agendamento_simples,
      [id],
      True
    );

    jsonres := TJSONObject.Create;

    with data do
    begin
      jsonres.Add('id_prof',   FieldByName('COD_FUNC'  ).AsInteger);
      jsonres.Add('id_client', FieldByName('COD_CLIENT').AsInteger);
      jsonres.Add('client',    FieldByName('CLIENTE'   ).AsString);
      jsonres.Add('telefone',  FieldByName('TELEFONE'  ).AsString);
      jsonres.Add('hora_ini',  FieldByName('HORA_INI'  ).AsString);
      jsonres.Add('hora_fim',  FieldByName('HORA_FIM'  ).AsString);
      jsonres.Add('data',      FieldByName('DATA2'     ).AsString);
      jsonres.add('event_id',  FieldByName('event_id'  ).AsString);
      jsonres.Add('valor', FormatCurr('0.00', FieldByName('valor').AsCurrency));
      jsonres.Add('sinal', FormatCurr('0.00', FieldByName('sinal').AsCurrency));
    end;

    Result := jsonres.AsJSON;

  finally
    getData.Free;
    jsonres.Free;
    data.Free;
  end;
end;

procedure TAgendaModel.createAgendamento(id_prof, id_client: integer;
  hora_ini, hora_fim, name_client, telefone, event_id, uuid: string; date:TDateTime;
  out status_code: integer; valor, sinal:currency);
var
  getdata:TGetData;
begin
  getdata := TGetData.Create;
  try
    try
      getdata.getData(
        sql_queries.create_agendamento_simples,
        [
          id_prof,
          id_client,
          name_client,
          telefone,
          hora_ini,
          hora_fim,
          date,
          event_id,
          valor,
          sinal,
          uuid
        ]
      );
      status_code:=200;
    except on e:Exception do
    begin
      status_code:=500;
      raise;
    end;
    end;
  finally
    getdata.Free;
  end;
end;

procedure TAgendaModel.deleteAgendamento(id: integer);
var
  getData: TGetData;
begin
  getData := TGetData.Create;
  try
    getData.getData(
      sql_queries.delete_agendamento_simples,
      [id]
    );
  finally
    getData.Free;
  end;
end;

procedure TAgendaModel.updateAgendamento(id, id_prof, id_client: integer;
  valor, sinal: currency; telefone, client, h_ini, h_fim, event_id: string;
  date:TDateTime; out status_code: integer);
var
  getdata: TGetData;
begin
  getdata := TGetData.Create;
  try
    try
    getdata.getData(
      sql_queries.update_agendamento_simples,
      [
        id_prof,
        id_client,
        client,
        telefone,
        h_ini,
        h_fim,
        date,
        event_id,
        valor,
        sinal,
        id
      ]
    );
    status_code:=200;
    except on e:Exception do
    begin
      status_code:=500;
      raise;
    end;
    end;
  finally
    getdata.Free;
  end;
end;

function TAgendaModel.getTurnosDisponiveis(id_prof: integer): UTF8String;
var
  getdata: TGetData;
  dataset: TDataSet;
  jsonDia, jsonRoot: TJSONObject;
  jsonTurnos, jsonArray: TJSONArray;
  turnos: Array[0..2] of TTurno;
  i, j: integer;
  DataAtual, DataInicio, DataFim: TDateTime;
  bloqueado: boolean;
  appini, appfim:string;
begin
  Turnos[0].Nome := 'Manhã'; Turnos[0].Inicio := '08:00'; Turnos[0].Fim := '12:00';
  Turnos[1].Nome := 'Tarde'; Turnos[1].Inicio := '13:00'; Turnos[1].Fim := '18:00';
  Turnos[2].Nome := 'Noite'; Turnos[2].Inicio := '18:00'; Turnos[2].Fim := '22:00';

  getdata := TGetData.Create;
  jsonRoot := TJSONObject.Create;
  jsonArray := TJSONArray.Create;
  try
    dataset := getdata.getData(
      sql_queries.list_ocupacao_dia,
      [id_prof, date],
      true
    );

    try
      jsonRoot.Add('data', DateToStr(date));
      jsonRoot.Add('dia_semana', FormatDateTime('dddd', date));

      for i := 0 to 2 do
      begin
        Bloqueado := False;

        if not dataset.IsEmpty then
        begin
          dataset.First;
          while not dataset.Eof do
          begin
            AppIni := dataset.FieldByName('hora_ini').AsString;
            AppFim := dataset.FieldByName('hora_fim').AsString;

            // 4. Lógica de Colisão (Intersecção de intervalos)
            // Se (AgendamentoComeca < TurnoTermina) E (AgendamentoTermina > TurnoComeca)
            if (AppIni < Turnos[i].Fim) and (AppFim > Turnos[i].Inicio) then
            begin
              Bloqueado := True;
              Break; // Se achou uma colisão, já bloqueia o turno e sai do loop
            end;

            dataset.Next;
          end;
        end;

        // Se não houve colisão, adiciona o turno na resposta JSON
        if not Bloqueado then
          jsonArray.Add(Turnos[i].Nome);
      end;

      jsonRoot.Add('turnos_disponiveis', jsonTurnos);

      Result := jsonRoot.AsJSON;
    finally
      dataset.Free;
    end;
  finally
    getdata.Free;
    jsonRoot.Free; // O Result é string, podemos liberar o objeto
  end;
end;

function TAgendaModel.getDisponibilidadePublica(telefone_loja: string; id_profissional:integer): UTF8String;
var
  getdata: TGetData;
  dsConfig, dsAgenda: TDataSet;
  jsonRoot: TJSONObject;
  jsonDias, jsonTurnos, jsonDiaDict: TJSONObject; // Auxiliares
  jsonArrayDias, jsonArrayTurnos: TJSONArray;
  jsonConfigLoja, diaConfig: TJSONObject;

  DataAtual, DataInicio, DataFim, AppData: TDateTime;
  i, j, DiaSemana: Integer;
  StrDiaSemana, LojaAbre, LojaFecha, AppIni, AppFim: String;
  Bloqueado, LojaAbertaNoTurno: Boolean;

  type TTurno = record Nome, Inicio, Fim: string; end;
  var Turnos: array[0..2] of TTurno;
begin
  // 1. Definição fixa dos seus turnos
  Turnos[0].Nome := 'Manhã'; Turnos[0].Inicio := '08:00'; Turnos[0].Fim := '12:00';
  Turnos[1].Nome := 'Tarde'; Turnos[1].Inicio := '13:00'; Turnos[1].Fim := '18:00';
  Turnos[2].Nome := 'Noite'; Turnos[2].Inicio := '18:00'; Turnos[2].Fim := '22:00';

  getdata := TGetData.Create;
  jsonRoot := TJSONObject.Create;
  jsonArrayDias := TJSONArray.Create;
  jsonConfigLoja := nil;

  try
    // A. Buscar Horários da Loja
    dsConfig := getdata.getData(sql_queries.busca_config_loja_publico, [telefone_loja], true);
    if not dsConfig.IsEmpty then
    begin
       if dsConfig.FieldByName('CONFIG_HORARIO').AsString <> '' then
       try
          jsonConfigLoja := TJSONObject(GetJSON(dsConfig.FieldByName('CONFIG_HORARIO').AsString));
       except
          jsonConfigLoja := nil;
       end;
    end;
    dsConfig.Free;

    // B. Buscar Agenda Ocupada do Profissional (Próximos 30 dias)
    DataInicio := Date;
    DataFim := IncDay(DataInicio, 30);

    dsAgenda := getdata.getData(
      sql_queries.list_ocupacao_periodo,
      [
        id_profissional,
        DataInicio,
        DataFim
      ],
      true
    );

    try
      // C. Loop dia a dia
      for i := 0 to 30 do
      begin
        DataAtual := DataInicio + i;
        DiaSemana := DayOfWeek(DataAtual); // 1=Dom, 7=Sab
        StrDiaSemana := IntToStr(DiaSemana);

        jsonDiaDict := TJSONObject.Create;
        jsonDiaDict.Add('data', DateToStr(DataAtual));
        jsonDiaDict.Add('dia_semana_str', FormatDateTime('dddd', DataAtual));
        jsonDiaDict.Add('dia_semana_int', DiaSemana);

        jsonArrayTurnos := TJSONArray.Create;

        // Verifica se a LOJA abre neste dia da semana
        LojaAbre  := '00:00';
        LojaFecha := '23:59';

        if Assigned(jsonConfigLoja) then
        begin
          if jsonConfigLoja.Find(StrDiaSemana) is TJSONObject then
          begin
            diaConfig := TJSONObject(jsonConfigLoja.Find(StrDiaSemana));
            // Se estiver marcado como fechado no JSON da loja
            if not diaConfig.Get('aberto', true) then
            begin
               jsonDiaDict.Add('turnos', jsonArrayTurnos); // Lista vazia (Fechado)
               jsonArrayDias.Add(jsonDiaDict);
               Continue;
            end;
            LojaAbre := diaConfig.Get('inicio', '08:00');
            LojaFecha := diaConfig.Get('fim', '18:00');
          end;
        end;

        // Processa Turnos
        for j := 0 to 2 do
        begin
          Bloqueado := False;
          LojaAbertaNoTurno := False;

          // Regra 1: O turno está dentro do horário da loja?
          if (LojaAbre < Turnos[j].Fim) and (LojaFecha > Turnos[j].Inicio) then
             LojaAbertaNoTurno := True;

          if not LojaAbertaNoTurno then
             Bloqueado := True
          else
          begin
            // Regra 2: Existe agendamento colidindo?
            if not dsAgenda.IsEmpty then
            begin
              dsAgenda.First;
              while not dsAgenda.Eof do
              begin
                AppData := dsAgenda.FieldByName('data_ref').AsDateTime;

                // Só verifica registros deste dia
                if Trunc(AppData) = Trunc(DataAtual) then
                begin
                  AppIni := dsAgenda.FieldByName('hora_ini').AsString;
                  AppFim := dsAgenda.FieldByName('hora_fim').AsString;

                  // Colisão: (IniA < FimB) e (FimA > IniB)
                  if (AppIni < Turnos[j].Fim) and (AppFim > Turnos[j].Inicio) then
                  begin
                     Bloqueado := True;
                     Break; // Se achou um bloqueio, não precisa ver os outros agendamentos deste dia
                  end;
                end;

                // Otimização: se passou da data, para o while interno
                if Trunc(AppData) > Trunc(DataAtual) then Break;

                dsAgenda.Next;
              end;
            end;
          end;

          if not Bloqueado then
            jsonArrayTurnos.Add(Turnos[j].Nome);
        end;

        jsonDiaDict.Add('turnos', jsonArrayTurnos);
        jsonArrayDias.Add(jsonDiaDict);
      end;

      jsonRoot.Add('calendario', jsonArrayDias);
      Result := jsonRoot.AsJSON;

    finally
      dsAgenda.Free;
    end;

  finally
    if Assigned(jsonConfigLoja) then jsonConfigLoja.Free;
    getdata.Free;
    jsonRoot.Free;
  end;

end;

function TAgendaModel.getclientetelefone(telefone: string; out status: integer): UTF8String;
var
  getdata: TGetData;
  jsonres: TJSONObject;
  dataset: TDataSet;
  id_profissional, id: integer;
  nome: string;
begin
  jsonres := nil;
  dataset := nil;
  getdata := TGetData.Create;
  try
    jsonres := TJSONObject.Create;
    dataset := getdata.getData(
      sql_queries.busca_cliente_telefone_agenda_turnos,
      [telefone],
      true
    );
    if not dataset.IsEmpty then
    begin
      id_profissional:= dataset.FieldByName('profissional').AsInteger;
      nome           := dataset.FieldByName('nome'        ).AsString;
      id             := dataset.FieldByName('id'          ).AsInteger;

      jsonres.Add('nome',                    nome);
      jsonres.Add('profissional', id_profissional);
      status:=200;
    end
    else
      status:=404;
    Result := jsonres.AsJSON;
  finally
    if Assigned(dataset) then dataset.Free;
    getdata.Free;
    jsonres.Free;
  end;
end;

function TAgendaModel.getprofissionaisid(id: integer): UTF8String;
var
  getdata: TGetData;
  jsonres: TJSONObject;
  dataset: TDataSet;
begin
  jsonres := nil;
  dataset := nil;
  getdata := TGetData.Create;
  try
    dataset := getdata.getData(
      sql_queries.busca_profissional_id_turnos,
      [id],
      True
    );

    jsonres := TJSONObject.Create;

    with dataset do
    begin
      first;

      jsonres.add('id', FieldByName('id').AsInteger);
      jsonres.add('nome', FieldByName('nome').AsString);
      jsonres.add('id_loja', FieldByName('id_loja_ex').AsString);
    end;
      Result := jsonres.AsJSON;
  finally
    jsonres.Free;
    if Assigned(dataset) then dataset.Free;
    getdata.Free;
  end;
end;

function TAgendaModel.buscadadosagendaturnos(telefone: string): UTF8String;
var
  Query: TDataSet;
  GetData: TGetData;
  RootJson, ClienteJson, ProfissionalJson, LojaJson, AgendaItem: TJSONObject;
  AgendaArray: TJSONArray;
  FirstRow: Boolean;
  clientid, profissionalid:integer;
  clientenome, profissionalnome, lojauuid:string;
begin
  RootJson    := TJSONObject.Create;
  AgendaArray := TJSONArray.Create;

  //RootJson.Add('agenda', AgendaArray);

  GetData := TGetData.Create;
  FirstRow := True;

  try
    Query := GetData.getData(
      sql_queries.busca_dados_agenda_turnos,
      [telefone],
      True
    );

    with Query do
    begin
      first;

      ClienteJson := TJSONObject.Create;

      clientenome:=FieldByName('CLIENTE_NOME').AsString;

      ClienteJson.add('cliente_id', FieldByName('CLIENTE_ID'  ).AsInteger);
      ClienteJson.Add('nome',       FieldByName('CLIENTE_NOME').AsString );

      RootJson.Add('cliente', ClienteJson);

      ProfissionalJson := TJSONObject.Create;

      ProfissionalJson.Add('id',   FieldByName('PROFISSIONAL_ID'  ).AsInteger);
      ProfissionalJson.Add('nome', FieldByName('PROFISSIONAL_NOME').AsString);

      RootJson.Add('profissional', ProfissionalJson);

      LojaJson := TJSONObject.Create;

      LojaJson.Add('uuid',           FieldByName('LOJA_UUID'     ).AsString);
      LojaJson.Add('config_horario', FieldByName('CONFIG_HORARIO').AsString);

      RootJson.Add('loja', LojaJson);

      if not Query.FieldByName('AGENDA_ID').IsNull then
      begin
        while not eof do
        begin
          AgendaItem := TJSONObject.Create;

          AgendaItem.Add('id', Query.FieldByName('AGENDA_ID').AsInteger);

          AgendaItem.Add('data',     FormatDateTime('yyyy-mm-dd', FieldByName('AGENDA_DATA').AsDateTime));
          AgendaItem.Add('hora_ini', FieldByName('AGENDA_HORA_INI').AsString);
          AgendaItem.Add('hora_fim', FieldByName('AGENDA_HORA_FIM').AsString);

          AgendaArray.Add(AgendaItem);

          next;
        end;
      end;
      RootJson.Add('agenda', AgendaArray);
    end;
    result := RootJson.AsJSON;
  finally
    GetData.Free;
    RootJson.Free;
  end;
end;

class function TAgendaModel.SolicitarAgendamento(const idProfissional, id_cliente: Integer;
  const cliente, telefone, data, horaIni, horaFim, uuid: string): boolean;
begin
  result := False;
  try
    TGetData.getData(
      sql_queries.solicitar_agendamento_app,
      [
        idProfissional,
        id_cliente,
        cliente,
        telefone,
        horaIni,
        horaFim,
        data,
        uuid
      ]
    );
    Result := True;
  except
    on E: Exception do
    begin
      raise Exception.Create('Erro ao gravar solicitação: ' + E.Message);
    end;
  end;
end;

end.

