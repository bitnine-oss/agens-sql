create schema pgsmtp;


CREATE TABLE pgsmtp.user_smtp_data
 (smtp_user character varying, smtp_server character varying, smtp_port integer, smtp_pass character varying );

CREATE OR REPLACE FUNCTION pgsmtp.pg_smtp_mail(
    sender character varying,
    receiver character varying,
    cc text[],
    topic character varying,
    content text)
  RETURNS text AS
$BODY$
 
import smtplib
from email.MIMEText import MIMEText


# find data about sender
query = "SELECT smtp_server,smtp_port,smtp_pass FROM pgsmtp.user_smtp_data where smtp_user='" +sender + "' LIMIT 1"
result = plpy.execute(query)
if result:
    ccs = cc
    # Create mens
    mens = MIMEText(content)
    ccs = cc

    # Conex con el server
    mens['Subject'] = topic
    mens['From'] = sender
    mens['To'] = receiver
    recipients = [receiver] + ccs

    try:
        # Authenticate
        serversmtp = smtplib.SMTP(result[0]['smtp_server'],result[0]['smtp_port'])
        serversmtp.ehlo_or_helo_if_needed()
        serversmtp.starttls()
        serversmtp.ehlo_or_helo_if_needed()
        serversmtp.login(sender,result[0]['smtp_pass'])

        # Sending
        serversmtp.sendmail(sender, recipients, mens.as_string())

        # close conex
        serversmtp.close()
        return 'Send'

    except Exception, e:
        return 'Error , check parameters ', str(e)
else:
    return 'Error , no data for sender user, check in table pgsmtp.user_smtp_data'
 

 
$BODY$
  LANGUAGE plpythonu VOLATILE;

CREATE OR REPLACE FUNCTION pgsmtp.pg_smtp_mail_attach(
    sender character varying,
    receiver character varying,
    cc text[],
    topic character varying,
    content text,
    attach text[])
  RETURNS text AS
$BODY$
 
import smtplib
from email.MIMEText import MIMEText
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart


# find data about sender
query = "SELECT smtp_server,smtp_port,smtp_pass FROM pgsmtp.user_smtp_data where smtp_user='" +sender + "' LIMIT 1"
result = plpy.execute(query)
if result:
    ccs = cc
    # Create mens
    mens = MIMEMultipart()
    ccs = cc

    # Conex con el server
    mens['Subject'] = topic
    mens['From'] = sender
    mens['To'] = receiver
    recipients = [receiver] + ccs

    try:
        # Authenticate
        serversmtp = smtplib.SMTP(result[0]['smtp_server'],result[0]['smtp_port'])
        serversmtp.ehlo_or_helo_if_needed()
        serversmtp.starttls()
        serversmtp.ehlo_or_helo_if_needed()
        serversmtp.login(sender,result[0]['smtp_pass'])

        # Sending
        # text
        mens.attach(MIMEText(str(content)))
        #attaching
        if attach[0]!=None:
            for att in attach:
                print str(att)
                bin = MIMEApplication(open(str(att),"rb").read())
                bin.add_header('Content-Disposition', 'attachment', filename=att)
                mens.attach(bin)
        serversmtp.sendmail(sender, recipients, mens.as_string())
       

        # close conex
        serversmtp.close()
        return 'Send'

    except Exception, e:
        return 'Error , check parameters ', str(e)
else:
    return 'Error , no data for sender user, check in table pgsmtp.user_smtp_data'
 

 
$BODY$
  LANGUAGE plpythonu VOLATILE;

