#!/usr/bin/env python
#
"""This modules traverses the printer subnet work to identify the
targets for further processing. Returns maccaddress and ip number
of host to try.
"""
import logging
# Set Scapy logging to Error - suppress warning.
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)
import time
import netifaces
import netaddr
import socket
from scapy.all import srp, Ether, ARP, conf
		

#Network definitions to feed into arp_ping.
my_face = 'eth0'
my_addrs = netifaces.ifaddresses(my_face)
my_ipinfo = my_addrs[socket.AF_INET][0]
my_address = my_ipinfo['addr']
my_netmask = my_ipinfo['netmask']
my_cidr = netaddr.IPNetwork('%s/%s' % (my_address, my_netmask))
my_network = my_cidr.network
pingfod = netaddr.IPNetwork('%s/%s' % (my_network, my_netmask))

def arp_ping(ipn):
#Main function.
    logging.info('Starting Arp Run')
    conf.verb = 0
    ans, unans = srp(Ether(dst="ff:ff:ff:ff:ff:ff")/ARP(pdst=str(ipn)), timeout=2)
    element = []
    for snd, rcv in ans:
        res = rcv.sprintf(r"%Ether.src% %ARP.psrc%").split()
        element.append(res)
    return element

def main():
	start_timing = time.time()
	#logging.basicConfig(level=logging.DEBUG,
    #             #format='%(asctime)s %(levelname)s %(message)s',
    #             filename='/tmp/myapp.log',
    #             filemode='w')
    #When run standalone for testing purposes.
	arpi = arp_ping(pingfod)
	logging.debug('Standalone run module prentarp - results: %s', arpi)
	elapsed = (time.time() - start_timing)
	print elapsed

if __name__ == '__main__':
    main()