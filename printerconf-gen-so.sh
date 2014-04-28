#!/bin/bash
###############################################################################
# This script does a auto-discovery of printers on networks by using ping
# and snmpget cycling through a range of IP that is defined in a separate
# network list file and IP range.
#
# 
# Based on the work of frank4dd@com
# run: printerconf-gen-so.sh ARGV > printers-so.cfg 2>/dev/null
###############################################################################

# First, we create the configuration file header and template information
cat<<'END'
###############################################################################
# HOST GROUP DEFINITIONS printers
###############################################################################
define hostgroup{
  hostgroup_name        generic-printers-so       ; The name of the hostgroup
  alias                 Generic Printers           ; Alias details of the group
}
define hostextinfo {
  hostgroup_name        generic-printers-so         ; The name of the hostgroup
  use                   basic
}
define hostgroup{
  hostgroup_name        xerox-printers-so           ; The name of the hostgroup
  alias                 Xerox Printers in SO        ; Alias details of the group
}
define hostgroup{
  hostgroup_name        kyocera-printers-so         ; The name of the hostgroup
  alias                 Kyocera Printers in SO      ; Alias details of the group
}
define hostgroup{
  hostgroup_name        HP-printers-so              ; The name of the hostgroup
  alias                 Hewlewtt Packard in SO      ; Alias details of the group
}
define hostgroup{
  hostgroup_name        epson-printers-so           ; The name of the hostgroup
  alias                 epson prointers in SO       ; Alias details of the group
}
###############################################################################
# PRINTER DEFINITION templates - These are NOT a real hosts, just a template!
###############################################################################
define host{
  name                  generic-printer-so ; The name of this host template
  use                   generic-host       ; Inherit default values from the generic-host template
  check_period          24x7               ; monitor weekdays 8-8
  check_interval        5                  ; Actively check the server every 5 minutes
  retry_interval        1                  ; Schedule host check retries at 1 minute intervals
  max_check_attempts    5                  ; Check each server 10 times (max)
  check_command         check_host_alive   ; Default command to check if servers are "alive"
  #check_command         check_hpjd         ; Default command to check if servers are "alive"
  notification_period   none               ; printers enter "sleep" mode each night - they go "down"
  notification_interval 240                ; Resend notifications every 120 minutes
  notification_options  d,u,r              ; Only send notifications for specific host states
  contact_groups        admins
  hostgroups            printers-salesoffice, 8-all-printers
  register              0                  ; DONT REGISTER THIS - ITS JUST A TEMPLATE
}
define host{
  name                  HP-printer-so      ; The name of this host template
  use                   generic-host       ; Inherit default values from the generic-host template
  check_period          24x7               ; monitor weekdays 8-8
  check_interval        5                  ; Actively check the server every 5 minutes
  retry_interval        1                  ; Schedule host check retries at 1 minute intervals
  max_check_attempts    5                  ; Check each server 10 times (max)
  #check_command         check_hpjd         ; Default command to check if servers are "alive"
  check_command         check_host_alive   ; Default command to check if servers are "alive"
  notification_period   none               ; printers enter "sleep" mode each night - they go "down"
  notification_interval 240                ; Resend notifications every 120 minutes
  notification_options  d,u,r              ; Only send notifications for specific host states
  contact_groups        admins             ;
  hostgroups            HP-printers-so     ;
  register              0                  ; DONT REGISTER THIS - ITS JUST A TEMPLATE
}
define host{
  name                  epson-printer-so   ; The name of this host template
  use                   generic-host       ; Inherit default values from the generic-host template
  check_period          24x7               ; monitor weekdays 8-8
  check_interval        5                  ; Actively check the server every 5 minutes
  retry_interval        1                  ; Schedule host check retries at 1 minute intervals
  max_check_attempts    5                  ; Check each server 10 times (max)
  check_command         check_host_alive   ; 
  notification_period   none               ; printers enter "sleep" mode each night - they go "down"
  notification_interval 240                ; Resend notifications every 120 minutes
  notification_options  d,u,r              ; Only send notifications for specific host states
  contact_groups        admins             ;
  hostgroups            epson-printers-so  ;
  register              0                  ; DONT REGISTER THIS - ITS JUST A TEMPLATE
}
define host{
  name                  xerox-printer-so   ; The name of this host template
  use                   generic-printer-so ; Inherit default values from the generic-host template
  hostgroups            xerox-printers-so, printers-salesoffice, 8-all-printers
  icon_image            xerox-logo.png     ; the default image for the device
  statusmap_image       xerox-logo.gd2     ; the default image for the statusmap display
  register              0                  ; DONT REGISTER THIS - ITS JUST A TEMPLATE
}
define host{
  name                  kyocera-printer-so ; The name of this host template
  use                   generic-printer-so ; Inherit default values from the generic-host template
  hostgroups            kyocera-printers-so; 
  icon_image            kyocera-logo.png   ; the default image for the device
  statusmap_image       kyocera-logo.gd2   ; the default image for the statusmap display
  register              0                  ; DONT REGISTER THIS - ITS JUST A TEMPLATE
}
define host{
  name                  HP-printer-so      ; The name of this host template
  use                   HP-printer-so      ; Inherit default values from the generic-host template
  hostgroups            HP-printers-so     ; HP printers
  icon_image            HP-logo.png        ; the default image for the device
  statusmap_image       HP-logo.gd2        ; the default image for the statusmap display
  register              0                  ; DONT REGISTER THIS - ITS JUST A TEMPLATE
}
define host{
  name                  epson-printer-so   ; The name of this host template
  use                   epson-printer-so   ; Inherit default values from the generic-host template
  hostgroups            epson-printers-so  ; HP printers
  icon_image            epson-logo.png     ; the default image for the device
  statusmap_image       epson-logo.gd2     ; the default image for the statusmap display
  register              0                  ; DONT REGISTER THIS - ITS JUST A TEMPLATE
}
###############################################################################
# PRINTER services and commands
###############################################################################

define service{ 
use generic-service 
service_description Toner Supply 
hostgroup_name (generic-printers-so|HP-printers-so|epson-printers-so)
check_command check_snmp_printer!public!"CONSUM ALL"!20!10 
} 

define service{ 
use generic-service 
service_description Printer Status 
hostgroup_name (generic-printers-so|epson-printers-so|HP-printers-so)
check_command check_snmp_printer!public!"STATUS" 
} 

define command{ 
command_name check_snmp_printer 
command_line $USER1$/check_snmp_printer -H $HOSTADDRESS$ -C $ARG1$ -x $ARG2$ -w $ARG3$ -c $ARG4$  
} 


###############################################################################
# PRINTER DEFINITIONS below
###############################################################################
END

  soname=$1		# Human readable network name
  soip=$2               # Printers are not on current network

  #echo $soname $soip #debugging

  if [ ! $1 ]
    then
      echo "Usage cmd [Customer Network Name] Optional: [Printer subnet]"
    exit
  fi
  if [ ! $2 ] # Printers are on same network as us ..... and I cant be bothered with subnet in argv
    then
      soip=`ifconfig eth0| awk -F ' *|:' '/inet ad*r/{split($4,a,"."); printf("%d.%d.%d\n", a[1],a[2],a[3])}'`
  fi
  if [ ! $soip ] # if eth0 is not connected lets try wifi.
    then
  	soip=`ifconfig wlan0 | awk -F ' *|:' '/inet ad*r/{split($4,a,"."); printf("%d.%d.%d\n", a[1],a[2],a[3])}'`
  fi
  
  cnt=1  # For creating unique printer name in def.

  # Change if printers are in particular IP range - quicker 
  RANGE_START=2
  RANGE_END=253

  range=`echo -e "for i in {$RANGE_START..$RANGE_END}; do echo \\${i}; done" | bash`

  for ip in $range; do
    # check if the system exists at all and ip pingeable
    #echo "IP: $soip.$ip" #Debugging
    fping -c 1 -q $soip.$ip 2> /dev/null
    # if fping received a response, the exit code will be 0
    if [ $? -eq 0 ]; then
      #snmpget -v 1 -c public 192.168.91.4 HOST-RESOURCES-MIB::hrDeviceDescr.1 -Ov
      response=`snmpget -r 1 -v 1 -c public $soip.$ip HOST-RESOURCES-MIB::hrDeviceDescr.1 -Ov 2>/dev/null`  
      # if snmpget received a response, the exit code will be 0
      if [ $? -eq 0 ]; then
        # For printers we get
        # typical response 1 (Kyocera Printer)   -> STRING: LS-C5016N
        # typical response 2 (FujiXerox Printer) -> STRING: FUJI XEROX DocuCentre-III C440 v  3.  7.  1 Multifunction System
        echo "define host{"
        # check if we got a Kyocera
        echo $response| grep -q 'STRING: LS-'
        if [ $? -eq 0 ]; then echo "  use                   kyocera-printer-so"
        else
          # check if we got a Xerox
          echo $response| grep -q 'STRING: FUJI XEROX'
          if [ $? -eq 0 ]; then echo "  use                   xerox-printer-so"
	  else
            # check if we got a Epson
            echo $response| grep -q 'STRING: EPSON'
            if [ $? -eq 0 ]; then echo "  use                   epson-printer-so"
	    else
		# check if we got a Epson
            	echo $response| grep -q 'STRING: HP\|STRING: Deskjet\|STRING: Officejet'
            	if [ $? -eq 0 ]; then echo "  use                   HP-printer-so"
            	else
              		         echo "  use                   generic-printer-so"
	    fi
           fi
          fi
        fi
        echo "  alias             $soname-printer-$cnt"
        #echo "  alias                 $soname-printer-$cnt (`echo $response| cut -d ' ' -f 2-5` $cnt)"
        echo "  host_name                 `echo $response| cut -d ' ' -f 2-5` $cnt"
        echo "  address               $soip.$ip"
        echo "}"
        cnt=`expr $cnt + 1`
      fi
    fi
done
