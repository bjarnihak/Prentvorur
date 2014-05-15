#!/usr/bin/python
#
import netsnmp
import binascii
import uuid

response = '192.168.1.142'

def convertMacaddr(octet): 
    macbin = [binascii.b2a_hex(x) for x in list(octet)] 
    mac = ":".join(macbin)
    temp = mac.replace(":", "").replace("-", "").replace(".", "").upper() 
    return temp[:2] + ":" + ":".join([temp[i] + temp[i+1] for i in range(2,12,2)]) 


modelbind = netsnmp.Varbind('hrDeviceDescr.1')
mod = netsnmp.snmpget(modelbind, Version = 1, DestHost = response, Community='public') 
model = mod[0]
pacebind = netsnmp.Varbind('.1.3.6.1.2.1.43.10.2.1.4.1.1') 
pageres = netsnmp.snmpwalk(pacebind, Version = 1, DestHost = response, Community='public') 

#pagecount = pageres[0]

#macaddress = convertMacaddr(macres)

print pageres
print model
#print macaddress
#print 'my macaddress :', mymac


#Pagecount= snmpwalk -v1 -Ovq -c public 192.168.1.142 1.3.6.1.2.1.43.10.2.1.4.1.1
#MESSAGES=$(snmpwalk -v1 -Ovq -c $COMMUNITY $HOST_NAME 1.3.6.1.2.1.43.18.1.1.8 
#SERIAL=$(snmpwalk -v1 -Ovq -c $COMMUNITY $HOST_NAME 1.3.6.1.2.1.43.5.1.1.17
# macaddress .1.3.6.1.2.1.2.2.1.6

#def bintohexMac(octet): 
#    mac = [binascii.b2a_hex(x) for x in list(octet)] 
#    return ":".join(mac)
#
#def prettyMac(mac): 
#    temp = mac.replace(":", "").replace("-", "").replace(".", "").upper() 
#    return temp[:2] + ":" + ":".join([temp[i] + temp[i+1] for i in range(2,12,2)]) 
#
#
