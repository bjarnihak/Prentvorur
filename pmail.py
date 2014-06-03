#!/usr/bin/env python
# This script send email from the system
# and should work on all platforms
# -*- coding: iso-8859-1 -*-

from email.mime.text import MIMEText
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
import smtplib 
 
msg = MIMEMultipart()
msg['Subject'] = 'collector'
msg['From'] = 'fmster@monitor.prentvorur.net'
msg['Reply-to'] = 'fmster@monitor.prentvorur.net'
msg['To'] = 'moon@monitor.prentvorur.net'
 
# That is what u see if dont have an email reader:
msg.preamble = 'Multipart massage.\n'
 
# This is the textual part:
part = MIMEText("coming from sdfsfd")
msg.attach(part)
 
# This is the binary part(The Attachment):
part = MIMEApplication(open("/home/bjarni/printproject/raspdev/Prentvorur/testfile","rb").read())
part.add_header('Content-Disposition', 'attachment', filename="testfile")
msg.attach(part)
 
# Create an instance in SMTP server
SERVER = 'monitor.prentvorur.net'
server = smtplib.SMTP(SERVER, 587)
server.sendmail(msg['From'], msg['To'], msg.as_string())
server.quit()
 
# Send the email
#smtp.sendmail(msg['From'], msg['To'], msg.as_string())

