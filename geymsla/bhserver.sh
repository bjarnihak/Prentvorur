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
# Based on the work of frank4dd@com
# run: printerconf-gen-so.sh ARGV > printers-so.cfg 2>/dev/null
###############################################################################

# No external redirect - redirect all output to cotrrect place directly
PRINTCONF=/usr/local/shinken/etc/hosts/printers.cfg

# Log file handling
get_logfile=/tmp/get_logfile
echo "" > $get_logfile

# Lots of problems from Windows and others making config files = fix it.
for file in /home/vaktin/repo/*.txt ; do
    dos2unix "$file" > /dev/null 2>&1
done

# Load file into array. Save I/O's on Rasp
# Parameters kept in:
cmd_file=/home/vaktin/repo/prentvakt.txt

declare -a my_parameter
let i=0
while IFS=$'"="' read -r line_data; do
    my_parameter[i]="${line_data}"
    ((++i))
done < $cmd_file

# We only call awk = little I/O 
customer=$(printf ${my_parameter[0]} | awk -F '*|=' '{print $2}')
soip=$(printf ${my_parameter[1]} | awk -F '*|=' '{print $2}')
myip=$(printf ${my_parameter[2]} | awk -F '*|=' '{print $2}')
email=$(printf ${my_parameter[3]} | awk -F '*|=' '{print $2}')
my_start_range=$(printf ${my_parameter[4]} | awk -F '*|=' '{print $2}')
my_end_range=$(printf ${my_parameter[5]} | awk -F '*|=' '{print $2}')
location=Home

# Debug
#echo $customer
#echo $soip
#echo $myip
#echo $email
#echo $my_start_range
#echo $my_end_range

# Database Parameters
#=========================================================================
dbname=my_monitor
dbuser=mon
dbpw=mon
dbtable=montable
dbtimestamp=`date +'%Y-%m-%d %H:%M:%S'`


# Email Parameters
#=========================================================================
if [[ -z $email ]]; then 
		email_recipient="vaktin@prentvorur.is"
	else
		email_recipient="$email"
fi
email_subject_context="Reconfiguring at $customer"
email_sender="prentvakt@prentvorur.is" # Actually rewritten on send by ssmt
template=/tmp/template
email_prog="$(which email_sender)"

# Various Parameters
#=========================================================================
timestamp=`date +%H:%M:%S`
todays_date=`date +%d/%m/%Y`

# Main code
#=========================================================================
# Start with functions
#=========================================================================

debug() { echo "DEBUG: $*" >&2; }

ip2dec () {
    local a b c d ip=$@
    IFS=. read -r a b c d <<< "$ip"
    printf '%d\n' "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
}

dec2ip () {
    local ip dec=$@
    for e in {3..0}
    do
        ((octet = dec / (256 ** e) )) 
        ((dec -= octet * 256 ** e)) 
        ip+=$delim$octet
        delim=.
    done
    printf '%s\n' "$ip"
}

# Other code
#=========================================================================
# And we need our ip if it was not passed on to us.
if [[ -z $myip ]]; then
	#echo "myip is null or space"
	  myip=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}') 
fi 

# If nothing was passed to us from config.txt about printers subnet then we figure it out 
# and use current IP (first interface).
if [[ -z $soip ]]; then
	#echo "soip is null or space"
	getsub=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}') 
	soip=${getsub%.*}
fi

#echo $soip #debug
# Prepare range and ip calc
if [[ -n $soip ]]; then
	decimal=$(ip2dec $soip)
fi

if [[ -n $my_start_range ]] ; then
	my_start_range=$(dec2ip $decimal + $my_start_range )
	#echo "Got my_start_range :"
else
	my_start_range=$(dec2ip $decimal + 2 ) 
	#echo "Assinging Standard start"
fi

if [[ -n $my_end_range ]] ; then
	my_end_range=$(dec2ip $decimal + $my_end_range )
	#echo "Got my_end_range :"
else
	my_end_range=$(dec2ip $decimal + 253 ) 
	#echo "Assinging Standard end" 
fi

#prepare to feed this to snmp
start_range=$(echo $my_start_range | awk -F"." '{print $4}') #We only want the last digit
end_range=$(echo $my_end_range | awk -F"." '{print $4}') #We only want the last digit

cnt=1  # For creating unique printer name in def.

range=`echo -e "for i in {$start_range..$end_range}; do echo \\${i}; done" | bash`

#echo "ECHOING RANGE: " $range  #>> $get_logfile #debug


for ip in $range; do
    # check if the system exists at all and ip pingeable
    #echo "SOIP: $soip.$ip" #Debugging
    fping -c 1 -q $soip.$ip 2>/dev/null
    # if fping received a response, the exit code will be 0
    if [ $? -eq 0 ]; then
    #`snmpget -v 1 -c public 192.168.91.4 HOST-RESOURCES-MIB::hrDeviceDescr.1 -Ov`
      response=`snmpget -r 1 -v 1 -c public $soip.$ip HOST-RESOURCES-MIB::hrDeviceDescr.1 -Ov 2>/dev/null | awk -F 'STRING: ' '{print $2}'` 
    # if snmpget received a response, the exit code will be 0
		if [ $? -eq 0 ]; then 
			#bablefish=$(/home/vaktin/repo/check_snmp_printer -H $soip.$ip -C public -x "CONSUM ALL" | grep '%' | awk -F ' ' '{print "," $6}')
			bablefish=$(/home/vaktin/repo/check_snmp_printer -H $soip.$ip -C public -x "CONSUM ALL" ) #| grep '%' | awk -F ' ' '{print "," $6}')
			#readarray consum < <(/home/vaktin/repo/check_snmp_printer -H $soip.$ip -C public -x "CONSUM ALL" #| grep '%' | awk -F ' ' '{print  "'"$dbtimestamp"', '$customer', '$location' ,'"$response"'," $1  "," $6""}')
			#readarray consum < <(/home/vaktin/repo/check_snmp_printer -H $soip.$ip -C public -x "CONSUM ALL" )
			#| grep '%' | awk -F ' ' '{print  '$customer', '$location' ,'"$response"'," $1  "," $6""}')
			#readarray bablefish < <(/home/vaktin/repo/check_snmp_printer -H $soip.$ip -C public -x "CONSUM ALL" | grep '%' | awk -F ' ' '{print "\"INSERT INTO '$dbtable' ( runtime, cid, customer , location, printer, consum, status ) VALUES ( '"$dbtimestamp"', '$customer', '$location' ,'"$response"'," $1  "," $6")"";\""}')
		fi 
		echo $bablefish
	fi
done 


#for i in "${consum[*]}" ; do 
#	echo $i
#done




#        echo "}"
#        cnt=`expr $cnt + 1`
#		fi
#    fi
#done

#echo "---------------------------------------------------------------------------------------------">> $get_logfile
#echo "$timestamp: Finished creating definition: " >> $get_logfile
#echo "$timestamp: I found " `expr $cnt - 1` "printers during scan" >> $get_logfile
#
#echo "$timestamp: Preparing Email" >> $get_logfile
#echo "$timestamp: Restarting shinken" >> $get_logfile
#echo "---------------------------------------------------------------------------------------------">> $get_logfile
#echo "                                    Shinken startup log                                        ">> $get_logfile
#echo ""
#. /usr/local/bin/shmotor "restart"  >> $get_logfile
#

