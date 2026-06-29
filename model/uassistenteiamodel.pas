unit uAssistenteIaModel;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils;

type
  { Representa uma mensagem individual no fluxo do Inkers }
  TAssistantMessage = class
  private
    FBase64Data     : string;
    FMimeType       : string;
    FInstanciaId    : string;
    FWhatsAppId     : string;
    FRole           : string;
    FContent        : string;
    FExemploMensagem: string;
    FNomeAssistente : string;
    FNomeCliente    : string;
    FValorMinimo    : Double;
    FValorHora      : Double;
    FValorSessao    : double;
    FDataRegistro   : TDateTime;
    FDuracaoSessao  : integer;
    FContextoHistorico: string;
  public
    constructor Create;

    { Identificador UUID da Evolution API para isolamento multi-tenant }
    property InstanciaId: string read FInstanciaId write FInstanciaId;

    { JID do cliente no WhatsApp (ex: 5524999...) }
    property WhatsAppId: string read FWhatsAppId write FWhatsAppId;

    { Identifica se a mensagem é do 'user' ou do 'assistant' }
    property Role: string read FRole write FRole;

    { O texto, link ou descrição da imagem enviada }
    property Content        : string read FContent         write FContent;
    property ExemploMensagem: string read FExemploMensagem write FExemploMensagem;
    property NomeAssistente : string read FNomeAssistente  write FNomeAssistente;
    property NomeCliente    : string read FNomeCliente     write FNomeCliente;
    property Base64Data     : string read FBase64Data      write FBase64Data;
    property MimeType       : string read FMimeType        write FMimeType;

    { Parâmetros financeiros capturados do Cache/Loja }
    property ValorMinimo   : Double read FValorMinimo    write FValorMinimo;
    property ValorHora     : Double read FValorHora      write FValorHora;
    property ValorSessao   : Double read FValorSessao    write FValorSessao;

    { Timestamp da mensagem para ordenação no histórico }
    property DataRegistro: TDateTime read FDataRegistro write FDataRegistro;

    property DuracaoSessao: integer read FDuracaoSessao write FDuracaoSessao;
    property ContextoHistorico: string read FContextoHistorico write FContextoHistorico;
  end;

implementation

{ TAssistantMessage }

constructor TAssistantMessage.Create;
begin
  inherited Create;
  FDataRegistro := Now; // Define a hora exata da criação do objeto
end;

end.
