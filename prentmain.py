#!/usr/bin/env python
# This script requires tcpdump to be installed
# additionally, it requires root privs to run.
"""
The main collector of information about printers.
Calls other modules as needed.
"""
import netifaces
import netaddr
import socket
import time
import datetime
import netsnmp
import binascii
import ConfigParser
import logging
import prentarp
import prentlevel
#import prentmail

start_time = time.time()

def convertmacaddr(octet):
    macbin = [binascii.b2a_hex(x) for x in list(octet)]
    mac = ":".join(macbin)
    temp = mac.replace(":", "").replace("-", "").replace(".", "").upper()
    return temp[:2] + ":" + ":".join([temp[i] + temp[i+1] for i in range(2, 12, 2)])

def main():
	#import logging.config
	
	logger = logging.getLogger(__name__)
	#logging.config.fileConfig('/path/to/logging.conf')
	logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s %(levelname)s %(message)s',
                    filename='/tmp/prentapps.log',
                    filemode='w')
	logger.info('Starting populating standard variables')
	location = "Haberg 3"
	my_macaddress = "0d:9d:3d:02:3f:02"
	timestamp = datetime.datetime.now().isoformat()
	datadir = "/home/bjarni/data"
	postfile = "mail_load"
	customerid = "2406613229"
	sendmailserver = "monitor.prentvorur.net"
	logger.info('Network Information')
	ifaces = netifaces.interfaces()
	logger.debug('Available network interfaces are: %s', ifaces)
	# => ['lo', 'eth0', 'eth1']
	myiface = 'eth0'
	logger.debug('Hardcoded interface is: %s', myiface)
	addrs = netifaces.ifaddresses(myiface)
	# Get ipv4 stuff
	ipinfo = addrs[socket.AF_INET][0]
	address = ipinfo['addr']
	netmask = ipinfo['netmask']
	cidr = netaddr.IPNetwork('%s/%s' % (address, netmask))
	# => IPNetwork('192.168.1.150/24')
	network = cidr.network
	# => IPAddress('192.168.1.0')
	pingfod = netaddr.IPNetwork('%s/%s' % (network, netmask))
	logger.debug('Network variables are: Address = %s Netmask = %s Cidr (address/netmask) = %s Network = %s', address, netmask, cidr, network) 
	logger.debug('Values sent to arp_ping: %s', pingfod)
	values = prentarp.arp_ping(str(pingfod))
	logger.debug('Candidates received from arp_ping: %s', values)
	# Now we collect the info and call prentlevel for details. Create file to send. One for each printer.
	sent_elements = []
	config_count = 0
	logger.debug('Config count is: %s', config_count)
	logger.info('Starting Scan')
	for mac, ipn in values:
		modelbind = netsnmp.Varbind('hrDeviceDescr.1')
		mod = netsnmp.snmpget(modelbind, Version=1, DestHost=ipn, Community='public', Timeout=100000, Retries=1)
		model = mod[0]
		if model is not None:
			logger.debug('Found a printer: %s', model)
			page = netsnmp.Varbind('.1.3.6.1.2.1.43.10.2.1.4.1.1')
			pagec = netsnmp.snmpget(page, Version=1, DestHost = ipn, Community='public', Timeout=100000, Retries=1)
			pagecount = pagec[0]
			if pagecount == 0:
				logger.error('Pacecount=%s for printer: %s', pagecount, model)
			logger.debug('Got response from pacecount request: %s', pagecount)
			marker = prentlevel.getmarkers(ipn)
			logger.debug('Printer has these supplies: %s', marker)
			# We have pagecount so we config file to be sent
			filename = "%s/%s.%s" % (datadir, postfile, config_count)
			logger.debug('Opening response file: %s', filename)
			Config = ConfigParser.ConfigParser()
			cfgfile = open(filename,'w')
			Config.add_section('CUSTOMER')
			Config.set('CUSTOMER','Customer', customerid)
			Config.set('CUSTOMER','Location', location)
			Config.set('CUSTOMER','Collector', my_macaddress)
			Config.set('CUSTOMER', 'TimeStamp', timestamp)
			Config.add_section('DEVICE')
			Config.set('DEVICE','MacAddress', mac)
			Config.set('DEVICE','DeviceName', model)
			Config.set('DEVICE','IPAddress', ipn)
			Config.set('DEVICE', 'PageCount', pagecount)
			# Lets get ready for next step
			Config.add_section('MEASUREMENTS')
			item_count = 0
			for numberof in range(len(marker)):
				cnt = numberof+1
				toner_level = prentlevel.getlevel(cnt,ipn)
				logger.debug('Level found: %s', toner_level)
				my_levels = "," .join(repr(e) for e in toner_level)
				label = 'MeasuredValues.%s' % item_count
				Config.set('MEASUREMENTS', label , my_levels)
				item_count += 1
				results = ','.join([pagecount, my_levels])
				results_string = results.replace("'", "")
				sent_elements.append(toner_level)
			Config.write(cfgfile)
			logger.debug('Wrote payload file: %s', filename)
			cfgfile.close()
			logger.debug('Closed filehandle payload file: %s', filename)
		config_count +=1
	
			#prentmail.sendthemail(customerid, sent_elements)
	#put a newline after each line in the file.
	#with open('testfile', 'w') as f:
	#    f.writelines(("%s\n" % l for l in sent_elements))
		
	elapsed = (time.time() - start_time)
	print elapsed
	
if __name__ == '__main__':
    main()