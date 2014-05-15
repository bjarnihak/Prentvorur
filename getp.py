#!/usr/bin/python
###############################################################################
# This script does a auto-discovery of printers on networks by using ping
# and snmpget cycling through a range of IP that is defined in a separate
# network list file and IP range.
# Calls other services and returns with cunsumable levels and pagecount.
# 
# Based on the original work of frank4dd@com in bash.
# #############################################################################

import os
import shutil
import socket
import subprocess
import ConfigParser
import sys
import fcntl
import struct
import netifaces
import netaddr
import pprint
import array
import netsnmp
import binascii
import uuid

#
#Functions
#
# Pretty print mac address.

def convertMacaddr(octet): 
    macbin = [binascii.b2a_hex(x) for x in list(octet)] 
    mac = ":".join(macbin)
    temp = mac.replace(":", "").replace("-", "").replace(".", "").upper() 
    return temp[:2] + ":" + ":".join([temp[i] + temp[i+1] for i in range(2,12,2)])  
    
# Define the range of IP used to look for printers.
# Two functions ....IP - long (add f.e. 120)  Long to IP

def ip2long(ip):
    return struct.unpack("!L", socket.inet_aton(ip))[0]
def long2ip(long):
	return socket.inet_ntoa(struct.pack('!L', long))

# Get the configfile into place and assign to variables.
# If boot/prentvakt is never than /home....prentvakt. copy pls.
src = "/boot/prentvakt.txt"
ini = "/home/vaktin/repo/prentvakt.txt"
if os.stat(src).st_mtime - os.stat(ini).st_mtime > 1:
    shutil.copy2 (src, ini)

config = ConfigParser.ConfigParser(allow_no_value=False)
config.read(ini)
#Assign values to variables.
customer = config.get('DEFAULT', 'customer')
cc = config.get('DEFAULT', 'cc')
myiface = config.get('DEFAULT', 'interface')
email = config.get('OPTIONS','email')
subnet = config.get('OPTIONS', 'subnet')
start_range = config.getint('DEFAULT', 'start_range')
end_range = config.getint('DEFAULT', 'end_range')
addrs = netifaces.ifaddresses(myiface)
# Get ipv4 stuff
ipinfo = addrs[socket.AF_INET][0]
address = ipinfo['addr']
netmask = ipinfo['netmask']
# Create ip object and get 
cidr = netaddr.IPNetwork('%s/%s' % (address, netmask))
mymac = ':'.join(['{:02x}'.format((uuid.getnode() >> i) & 0xff) for i in range(0,8*6,8)][::-1])

# Test whether subnet option was set.
if subnet == "":
  # => IPAddress('192.168.1.0')
  print 'Defining my subnet auto:'
  network = cidr.network
else:
   network = subnet



network_dec = ip2long(str(network))
scan_start=long2ip(network_dec + int(start_range))
scan_end=long2ip(network_dec + int(end_range))

sip = scan_start.split('.')
mystart = sip[3]
eip = scan_end.split('.')
myend = eip[3]
base = sip[0]+'.'+sip[1]+'.'+sip[2]+'.' 

#def main():
#Now we have constructed our ipnumbers -- ready to ping
for number in range( int(mystart) ,int(myend) ): 
    hostname = base + str(number) 
    response = os.system("fping -c 1 -q " + hostname + " > /dev/null 2>&1")
    if response == 0 : # Clean exit(0)
		modelbind = netsnmp.Varbind('hrDeviceDescr.1')
		mod=netsnmp.snmpget(modelbind, Version = 1, DestHost = hostname, Community='public') 
		model = mod[0]
		print hostname , model
		macbind = netsnmp.Varbind('.1.3.6.1.2.1.2.2.1.6') 
		if model is not None:
			print 'Now Model is not None :', model
			macres = netsnmp.snmpwalk(macbind, Version = 1, DestHost = hostname, Community='public')
			if len(macres) < 2:
				print 'Now Macres is not None :', macres
				macaddress = convertMacaddr(macres)
				print 'My conditions are met :' , macaddress
		else:				
			print "Oops!  That was not a valid mac address..."
			continue
		
		

#print 'Macaddress :' , macaddress
#print 'Model      :' , model
#print '====='		
#print 'Scan Start:', scan_start
#print '  Scan End:', scan_end
#print ' Kennitala:', customer
#print ' Start var:', start_range
#print '   End var:', end_range
#print '  Netmaski:', netmask
#print '     Email:', email
#print '  Email CC:', cc
#print 'Network info for %s:' % myiface
#print 'address:', address
#print 'netmask:', netmask
#print '   cidr:', cidr
#print 'network:', network
#
#if __name__ == '__main__':
#    main()
#
