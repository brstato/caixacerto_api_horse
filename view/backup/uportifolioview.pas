unit uportifolioview;

{$mode delphi}{$H+}

interface

uses
  Classes, 
  SysUtils, 
  uportifoliomodel, 
  udata, 
  httpprotocol;

type

  { TPortifolioView }

  TPortifolioView = class
    public
      class function Render(const APerfil: TArtistaPerfil; const ASlug: string): string;
  end;

implementation

{ TPortifolioView }

class function TPortifolioView.Render(const APerfil: TArtistaPerfil;
  const ASlug: string): string;
var
  HtmlCarrossel, UrlFoto, WpMsg, endereco: string;
begin
    endereco := Format(
      '%s, N°%s - %s - %s, %s - %s, %s',
      [
        APerfil.Logradouro,
        APerfil.Numero,
        APerfil.Complemento,
        APerfil.Bairro,
        APerfil.Cidade,
        APerfil.Uf,
        APerfil.CEP
      ]
    );

  // Utiliza o HTML carregado no udata.pas
    Result := udata.index_html;

    // 1. Montagem do Bloco Dinâmico do Carrossel
    HtmlCarrossel := '';
    for UrlFoto in APerfil.FotosGaleria do
    begin
      HtmlCarrossel := HtmlCarrossel +
        '<div class="carousel-item">' +
        '  <a href="' + UrlFoto + '" data-pswp-width="1200" data-pswp-height="1500" target="_blank">' +
        '    <img src="' + UrlFoto + '" alt="Trabalho de ' + APerfil.Titulo + '">' +
        '  </a>' +
        '</div>';
    end;

    // 3. Injeção de Variáveis (Substituição)
    Result := Result.Replace('{{PAGE_TITLE}}',    APerfil.Titulo + ' | Inkers', [rfReplaceAll]);
    Result := Result.Replace('{{META_AUTHOR}}',   APerfil.Titulo, [rfReplaceAll]);
    Result := Result.Replace('{{CANONICAL_URL}}', 'https://' + ASlug + '.inkers.com.br', [rfReplaceAll]);

    Result := Result.Replace('{{OG_DESCRIPTION}}',       APerfil.Subtitulo,   [rfReplaceAll]);
    Result := Result.Replace('{{SCHEMA_DIAS}}',          APerfil.SchemaDias,  [rfReplaceAll]);
    Result := Result.Replace('{{SCHEMA_ABRE}}',          APerfil.SchemaAbre,  [rfReplaceAll]);
    Result := Result.Replace('{{SCHEMA_FECHA}}',         APerfil.SchemaFecha, [rfReplaceAll]);
    Result := Result.Replace('{{SCHEMA_INSTAGRAM_URL}}', APerfil.Insta,       [rfReplaceAll]);
    Result := Result.Replace('{{SCHEMA_NOME}}',          APerfil.Titulo,      [rfReplaceAll]);
    Result := Result.Replace('{{SCHEMA_TELEFONE}}',      APerfil.Telefone,    [rfReplaceAll]);
    Result := Result.Replace('{{SCHEMA_LOGRADOURO}}',    APerfil.Logradouro,  [rfReplaceAll]);
    Result := Result.Replace('{{SCHEMA_CIDADE}}',        APerfil.Cidade,      [rfReplaceAll]);
    Result := Result.Replace('{{SCHEMA_UF}}',            APerfil.Uf,          [rfReplaceAll]);
    Result := Result.Replace('{{SCHEMA_CEP}}',           APerfil.CEP,         [rfReplaceAll]);
    Result := Result.Replace('{{SCHEMA_LATITUDE}}',      APerfil.Latitude,    [rfReplaceAll]);
    Result := Result.Replace('{{SCHEMA_LONGITUDE}}',     APerfil.Longitude,   [rfReplaceAll]);
    Result := Result.Replace('{{META_PIXEL_ID}}',        APerfil.meta_pixel,  [rfReplaceAll]);
    Result := Result.Replace('{{GOOGLE_TAG_ID}}',        APerfil.google_id,   [rfReplaceAll]);

    Result := Result.Replace('{{MAPS_COORDENADAS}}', APerfil.Latitude + ',' + APerfil.Longitude, [rfReplaceAll]);
    Result := Result.Replace('{{MAPS_EMBED_URL}}',  'https://maps.google.com/maps?q=' + HTTPEncode(endereco) + '&t=&z=15&ie=UTF8&iwloc=&output=embed', [rfReplaceAll]);

    // Perfil e Bio
    Result := Result.Replace('{{ARTISTA_NOME}}',              APerfil.Titulo,    [rfReplaceAll]);
    Result := Result.Replace('{{ARTISTA_BIO}}',               APerfil.Subtitulo, [rfReplaceAll]);
    Result := Result.Replace('{{ARTISTA_BIO_LONGA}}',         APerfil.Bio,       [rfReplaceAll]);
    Result := Result.Replace('{{ARTISTA_FOTO_URL}}',          APerfil.Avatar,    [rfReplaceAll]);
    Result := Result.Replace('{{ARTISTA_FOTO_FULL_URL}}',     APerfil.Avatar,    [rfReplaceAll]);
    Result := Result.Replace('{{ARTISTA_FOTO_BIO_URL}}',      APerfil.FotoBio,   [rfReplaceAll]);
    Result := Result.Replace('{{ARTISTA_FOTO_FULL_BIO_URL}}', APerfil.FotoBio,   [rfReplaceAll]);

    // Contato e Localização
    Result := Result.Replace('{{WHATSAPP_NUMERO}}',   APerfil.WhatsApp,   [rfReplaceAll]);
    Result := Result.Replace('{{ARTISTA_CIDADE}}',    APerfil.Logradouro, [rfReplaceAll]);

    Result := Result.Replace('{{ENDERECO_COMPLETO}}', endereco,   [rfReplaceAll]);

    //Result := Result.Replace('{{WHATSAPP_MENSAGEM}}', WpMsg, [rfReplaceAll]);

    // SEO e Metatags
    Result := Result.Replace('{{META_DESCRIPTION}}', APerfil.Subtitulo, [rfReplaceAll]);
    Result := Result.Replace('{{OG_IMAGE_URL}}',     APerfil.Avatar,    [rfReplaceAll]);

    // Injeção dos Blocos Gerados
    Result := Result.Replace('{{CARROSSEL_ITENS}}', HtmlCarrossel, [rfReplaceAll]);

    // Caso não tenha depoimentos ainda, removemos a tag
    Result := Result.Replace('{{DEPOIMENTOS}}', '', [rfReplaceAll]);
end;

end.

