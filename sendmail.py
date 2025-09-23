import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.header import Header
import sys
import json
import os # Importar os para variáveis de ambiente

def send_email(sender_email: str = '', sender_password: str = '', recipient_email: str = '', subject: str = '', body: str = '', is_html:bool=False):
    """Sends a plain text or HTML email."""
    smtp_server = os.getenv("SMTP_SERVER", "smtp.gmail.com")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))

    try:
        if is_html:
            msg = MIMEText(body, 'html', 'utf-8')
        else:
            msg = MIMEText(body, 'plain', 'utf-8')

        msg['From'] = Header(sender_email, 'utf-8')
        msg['To'] = Header(recipient_email, 'utf-8')
        msg['Subject'] = Header(subject, 'utf-8')

        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            server.send_message(msg)
        return {"success": True, "message": "Email sent successfully."}
    except smtplib.SMTPAuthenticationError:
        return {"success": False, "message": "Authentication failed. Check email, app password, or 2FA."}
    except smtplib.SMTPConnectError as e:
        return {"success": False, "message": f"SMTP connection error: {e}. Check server/port."}
    except Exception as e:
        return {"success": False, "message": f"An error occurred: {e}"}

if __name__ == "__main__":
    if len(sys.argv) < 2:
        data_str = sys.stdin.read()
    try:
        data = json.loads(data_str)
        sender_email = data.get('sender_email')
        sender_password = data.get('sender_password')
        recipient_email = data.get('recipient_email')
        subject = data.get('subject')
        body = data.get('body')
        is_html = data.get('is_html', False)

        if not all([sender_email, sender_password, recipient_email, subject, body]):
            print(json.dumps({"success": False, "message": "Missing required email parameters."}))
        else:
            result = send_email(sender_email, sender_password, recipient_email, subject, body, is_html)
            print(json.dumps(result))

    except json.JSONDecodeError:
        print(json.dumps({"success": False, "message": "Invalid JSON input."}))
    except Exception as e:
        print(json.dumps({"success": False, "message": f"Unhandled script error: {e}"}))

      