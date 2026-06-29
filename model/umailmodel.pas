unit umailmodel;

{$mode delphi}{$H+}

interface

uses
  {$IfDef Unix}
   cthreads, cmem,
  {$endif}
   Classes, SysUtils, Process, SMTPSend, MIMEMess, mimepart, synautil,
   ssl_openssl, synachar, synacode, httpsend;

type

  { TmailModel }

  TmailModel = class(TThread)
    private
      FMailTo:      string;
      FMailSubject: string;
      FMailBody:    Tstrings;
      FERRorMessage:string;
      FOnterminate: TNotifyEvent;
      FSuccess:     Boolean;
      FAccessToken: string;
      FRefreshToken: string;

      

    protected
      procedure Execute; override;
      procedure doTerminate; override;
      function RefreshAccessToken:Boolean;
      function SendOAuth(SMTP: TSMTPSend): Boolean;
    public
      //constructor Create(const AMailTo, ASubject: string; ABody: TStrings;
      //  const AAccessToken, ARefreshToken: string);
      constructor Create(const AMailTo, ASubject: string; ABody: TStrings);
      destructor Destroy; override;
      property Success: Boolean read FSuccess;
      property ErrorMessage: string read FErrorMessage;
      property OnTerminate: TNotifyEvent read FOnTerminate write FOnTerminate;
  end;


implementation


uses
  logger, uconfig;

{ TmailModel }

procedure TmailModel.Execute;
var
  SMTP: TSMTPSend;
  MimeMess: TMimeMess;
  MimePart: TMimePart;
  sl: TStringList;
begin

  //if (FAccessToken = '') or (FRefreshToken = '') then
  //begin
    //FErrorMessage := 'Tokens não disponíveis';
    //Exit;
  //end;
  //
  //if not RefreshAccessToken then
  //begin
  //  FErrorMessage := 'Falha ao atualizar token de acesso';
  //  Exit;
  //end;

  MimeMess := TMimeMess.Create;
  MimeMess.Header.CharsetCode:= UTF_8;
  MimeMess.Header.ToList.Text:=FMailTo;
  MimeMess.Header.Subject:=FMailSubject;
  MimeMess.Header.from:= ConfigValue('mail', 'mail_from', 'inkers.suporte@gmail.com');

  sl := TStringList.Create;
  sl.Assign(FMailBody);

  MimePart := MimeMess.AddPartMultipart('mixed', nil);

  MimeMess.AddPartHTML(sl, MimePart);

  MimeMess.EncodeMessage;

  SMTP := TSMTPSend.Create;
  try

    SMTP.UserName  := ConfigValue('mail', 'smtp_user', ConfigValue('mail', 'mail_from', 'inkers.suporte@gmail.com'));
    SMTP.Password  := ConfigValue('mail', 'smtp_password', ''); // or use OAuth
    SMTP.TargetHost:= ConfigValue('mail', 'smtp_host', 'smtp.gmail.com');
    SMTP.TargetPort:= ConfigValue('mail', 'smtp_port', '465');
    SMTP.AutoTLS   := False;
    SMTP.FullSSL   := True;

    if SMTP.Login then
    begin
         //if not SendOAuth(SMTP) then
         //begin
         //  MimeMess.Free;
         //  sl.Free;
         //  SMTP.Free;
         //  Exit;
         //end;

      SMTP.MailFrom(ConfigValue('mail', 'mail_from', 'inkers.suporte@gmail.com'), Length(MimeMess.Lines.Text));
      if SMTP.MailTo(FMailTo) then
      begin
        if SMTP.MailData(MimeMess.Lines) then
          FSuccess := True
        else
          FErrorMessage := 'Erro no envio dos dados!';
      end
      else
          FErrorMessage := 'Erro no comando RCPT TO!';

      SMTP.Logout;
    end;
        FErrorMessage := 'Falha de autenticação!';
  finally
    SMTP.Free;
    sl.Free;
    MimeMess.Free;
  end;
end;


procedure TmailModel.doTerminate;
begin
  inherited doTerminate;
  if Assigned(FOnterminate) then
  begin
       FOnterminate(self);
  end;
end;

function TmailModel.RefreshAccessToken: Boolean;
var
  http: THTTPSend;
  params: tstringList;
  Response: TStringStream;
  ResponseSTR: string;
begin

  http := THTTPSend.Create;
  params := TStringList.Create;
  Response := TStringStream.Create('');

  try
    Params.Add('client_id=' + ConfigValue('google', 'client_id', ''));
    Params.Add('client_secret=' + ConfigValue('google', 'client_secret', ''));
    Params.Add('refresh_token=' + FRefreshToken);
    Params.Add('grant_type=refresh_token');

    http.MimeType:='application/x-www-form-urlencoded';
    WriteStrToStream(http.Document, params.Text);


    if http.HTTPMethod('POST', 'https://oauth2.googleapis.com/token') then
    begin
         Response.LoadFromStream(http.Document);
         ResponseSTR:=Response.DataString;

         if Pos('"access_token"', ResponseSTR) > 0 then
         begin
              FAccessToken := Copy(ResponseStr,
                           Pos('"access_token":"', ResponseStr) + 16,
                           Length(ResponseStr));

              FAccessToken := Copy(FAccessToken, 1, Pos('"', FAccessToken) - 1);
              Result := True;
         end;
    end;
  finally
    HTTP.Free;
    Params.Free;
    Response.Free;
  end;
end;

function TmailModel.SendOAuth(SMTP: TSMTPSend): Boolean;
var
  XOAuthStr: string;
  EncodedAuth: string;
  Response: string;
begin
      XOAuthStr := Format('user=%s'#1'auth=Bearer %s'#1#1, [ConfigValue('mail', 'mail_from', 'inkers.suporte@gmail.com'), FAccessToken]);
      EncodedAuth:=EncodeBase64(XOAuthStr);
      SMTP.Sock.SendString('AUTH XOAUTH2 ' + EncodedAuth + #13#10);
      Response := SMTP.Sock.RecvTerminated(5000, #13#10);


      if Copy(Response, 1, 3) = '235' then
        Result := True
      else
        FErrorMessage := 'Falha na autenticação OAuth2: ' + Response;
end;


//constructor TmailModel.Create(const AMailTo, ASubject: string; ABody: TStrings;
//  const AAccessToken, ARefreshToken: string);
constructor TmailModel.Create(const AMailTo, ASubject: string; ABody: TStrings);
begin
  inherited Create(True);
  FreeOnTerminate:=True;

  FMailTo := AMailTo;
  FMailSubject := ASubject;
  FMailBody := TStringList.Create;
  FMailBody.Assign(ABody);

  //FAccessToken := AAccessToken;
  //FRefreshToken := ARefreshToken;

  FSuccess := False;
end;


destructor TmailModel.Destroy;
begin
  FMailBody.Free;
  inherited Destroy;
end;

end.

