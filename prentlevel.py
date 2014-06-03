#!/usr/bin/env python
# 1. getmarkers Finds all available marker (cartridges)
#
"""
This module uses snmp to get information about toner/ink levels.
It first find the number of cartridges and then the levels plus
the max level to calculate the percentage left.
"""
import netsnmp
import socket
import time
import os

def getmarkers(ipn):
	markerbin = netsnmp.Varbind('.1.3.6.1.2.1.43.11.1.1.6.1')
	markers = netsnmp.snmpwalk(markerbin, Version=1, DestHost=ipn, Community='public', Timeout=100000, Retries=1)
	return markers

def getlevel(cnt,ipn):
		cur_capacity = netsnmp.Varbind('.1.3.6.1.2.1.43.11.1.1.9.1.%d' % cnt)
		cur_level = netsnmp.snmpget(cur_capacity, Version=1, DestHost=ipn, Community='public', Timeout=100000, Retries=1)
		color_bind = netsnmp.Varbind('.1.3.6.1.2.1.43.11.1.1.6.1.%d' % cnt)
		color_name = netsnmp.snmpget(color_bind, Version=1, DestHost=ipn, Community='public', Timeout=100000, Retries=1)
		max_capacity = netsnmp.Varbind('.1.3.6.1.2.1.43.11.1.1.8.1.%d' % cnt)
		max_level = netsnmp.snmpget(max_capacity, Version=1, DestHost=ipn, Community='public', Timeout=100000, Retries=1)
		if max_level < 0:
			max_level == 0
		levels = color_name + cur_level + max_level
		return levels
	
def main():
	start_timing = time.time()
	ipn = '192.168.1.7'
	community = 'puclic'
	marker = getmarkers(ipn)
	for i in range(len(marker)):
		cnt = i+1
		toner_level = getlevel(cnt,ipn)
		print ",".join( repr(e) for e in toner_level )
	elapsed = (time.time() - start_timing)
	print elapsed

if __name__ == '__main__':
    main()
