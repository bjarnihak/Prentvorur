#!/usr/bin/python
# arpv.py
import os
import sys
import netifaces
import netaddr
import socket
import time
import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)
from scapy.all import *
import pprint
import array
import netsnmp
import binascii
import uuid
import socket
from subprocess import call
from multiprocessing import Pool
from IPy import IP
from IPy import IPint

def arp2(ip):

    # An ARP scanner for the network.
    ips = []

    #global ans, unans
    ans, unans = srp(Ether(dst="ff:ff:ff:ff:ff:ff")/ARP(pdst=ip), timeout=2, verbose=0)

    for snd, rcv in ans:
    #Assign MAC address and IP address to variables mac and ipaddr

        mac = rcv.sprintf(r"%Ether.src%")
        ipaddr = rcv.sprintf(r"%ARP.psrc%")

        #Get NIC vendor code from MAC address
        niccode = mac[:8]
        niccode = niccode.upper()

        print ips
        ips.append("end")

        #ARPips file amendments
        with open( '/home/vaktin/repo/Prentvorur/ARPips.prn', 'w+') as f:
            f.write("\n".join(map(lambda x: str(x), ips)) + "\n")

        #String lookup for NIC vendors. DO NOT CHANGE 'r' TO ANY OTHER VALUE.
        with open('/usr/share/nmap/nmap-mac-prefixes', 'r') as file:
            for line in file:
                if niccode in line:
                    return mac, ipaddr, line[8:]


def main():

	print "Discovering..."
	print ""
	print "MAC Address \t \t  IP Address \t  NIC Vendor"

pool = Pool(processes=12)
Subnetlist = '192.168.1.0'
ARPresults = pool.map(arp2, Subnetlist)
pool.close()
pool.join()

print "\n".join(ARPresults)
	


if __name__ == '__main__':
    main()