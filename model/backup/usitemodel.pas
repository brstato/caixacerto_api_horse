unit usitemodel;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, ugetdata, sql_queries;

type

  { TSiteModel }

  TSiteModel = class
    public
      class procedure UpdateSite(var titulo, subtitulo, id_loja: string);
  end;


implementation

{ TSiteModel }

class procedure TSiteModel.UpdateSite(var titulo, subtitulo, id_loja: string);
begin
  try
    TGetData.getData(
      sql_queries.site_config,
      [
        titulo,
        subtitulo,
        id_loja
      ]
    );
  except
    on e:exception do
    begin
      raise;
    end;
  end;
end;

end.

