#!/usr/bin/env python
# This script send email from the system
# and should work on all platforms
"""
This sends email with the collected results.
"""
import smtplib, os
import zipfile
from email.MIMEMultipart import MIMEMultipart
from email.MIMEBase import MIMEBase
from email.MIMEText import MIMEText
from email.Utils import COMMASPACE, formatdate
from email import Encoders
from email.MIMEText import MIMEText

#def send_text_mail(subject, text):
	#SERVER = "monitor.prentvorur.net"
	#FROM = "fmaster@monitor.prentvorur.net"
	#TO = ["moon@monitor.prentvorur.net"] # must be a list
	#SUBJECT = subject
	#TEXT = text
	## Prepare actual message
	#msg = 'Subject: %s\n\n%s' % (SUBJECT,text)
	#msg = MIMEMultipart()
	##msg.attach(MIMEText(file("/home/bjarni/printproject/raspdev/Prentvorur/testfile").read()))
	#for f in files:
    #    part = MIMEBase('application', "octet-stream")
    #    part.set_payload( open(f,"rb").read() )
    #    Encoders.encode_base64(part)
    #    part.add_header('Content-Disposition', 'attachment; filename="%s"' % os.path.basename(f))
    #    msg.attach(part)
	#
	#server = smtplib.SMTP(SERVER, 587)
	#server.sendmail(FROM, TO, msg.as_string())
	#server.quit()
	
def send_mail(send_from, send_to, subject, server):
	filename = "/tmp/data.zip"
	target_dir = '/home/bjarni/data/'
	zip = zipfile.ZipFile('/tmp/data.zip', 'w', zipfile.ZIP_DEFLATED)   
	rootlen = len(target_dir) + 1
	for base, dirs, files in os.walk(target_dir):
		for file in files:
			fn = os.path.join(base, file)
			zip.write(fn, fn[rootlen:])

	#assert isinstance(send_to, list)
	#assert isinstance(files, list)
	msg = MIMEMultipart()
	msg['From'] = send_from
	msg['To'] = COMMASPACE.join(send_to)
	msg['Date'] = formatdate(localtime=True)
	msg['Subject'] = subject
	#msg.attach( MIMEText(text) )
	files = "/home/bjarni/data/mail_load.4"
	#for f in files:
	part = MIMEBase('application', "octet-stream")
	part.set_payload( open(files,"rb").read() )
	Encoders.encode_base64(part)
	part.add_header('Content-Disposition', 'attachment; filename="%s"' % filename )
	msg.attach(part)
	
	smtp = smtplib.SMTP(server)
	smtp.sendmail(send_from, send_to, msg.as_string())
	smtp.close()
	
	

def main():
	#text = "from the collector"
	#subject = "the collector"
	#sendthemail(subject, text)
	sendmailserver = "monitor.prentvorur.net"
	send_from="fmaster@monitor.prentvorur.net"
	send_to = "moon@monitor.prentvorur.net"
	subject = "Collector 22406613229"
	#files = filename
	
	send_mail(send_from, send_to, subject, sendmailserver ) 
	
if __name__ == "__main__":
    main()
	
	
	
	
	
import zipfile
import os,glob


def zipfunc(path, myzip):
    for path,dirs, files in os.walk(path):
            for file in files:
                if  os.path.isfile(os.path.join(path,file)):
                    myzip.write(os.path.join(os.path.basename(path), file))


if __name__ == '__main__':
    path=r'/home/ggous/new'
    myzip = zipfile.ZipFile('myzipped.zip', 'w')
    zipfunc(path,myzip)
    myzip.close()