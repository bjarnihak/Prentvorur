#!/usr/bin/env python
# This script send creates virtual filesystem
# and should work on all platforms
# -*- coding: iso-8859-1 -*-

import netifaces
import netaddr
import socket
import time
import datetime
import netsnmp
import binascii
import ConfigParser
import prentarp
import prentlevel
#import prentmail

location = "Haberg 3"
my_macaddress = "0d:9d:3d:02:3f:02"
timestamp = datetime.datetime.now().isoformat()
datadir = "/home/bjarni/data"
postfile = "mail_load"
customerid = "2406613229"

start_time = time.time()
# lets create that file for next step
config_count = 0
filename = "%s/%s.%s" % (datadir, postfile, config_count)
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
Config.add_section('MEASUREMENTS')
item_count = 0
for item in my_levels:
	label = 'MeasuredValues.%s' % item_count
	Config.set('MEASUREMENTS', label ,sent_elements[item_count])
	item_count += 1
	if item_count == items:
		break
Config.write(cfgfile)
cfgfile.close()
config_count +=1