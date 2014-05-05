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
			#bablefish=$(/home/vaktin/repo/check_snmp_printer -H $soip.$ip -C public -x "CONSUM ALL" | grep '%' | awk -F ' ' '{print "," $6}')
			readarray consum < <(/home/vaktin/repo/check_snmp_printer -H $soip.$ip -C public -x "CONSUM ALL" | grep '%' | awk -F ' ' '{print  "'"$dbtimestamp"', '$customer', '$location' ,'"$response"'," $1  "," $6""}')
			readarray pagecount < <(/home/vaktin/repo/check_snmp_printer -H $soip.$ip -C public -x "DEVICE" | grep '%' | awk -F ' ' '{print  "'"$dbtimestamp"', '$customer', '$location' ,'"$response"'," $1  "," $6""}')
			#readarray bablefish < <(/home/vaktin/repo/check_snmp_printer -H $soip.$ip -C public -x "CONSUM ALL" | grep '%' | awk -F ' ' '{print "\"INSERT INTO '$dbtable' ( runtime, cid, customer , location, printer, consum, status ) VALUES ( '"$dbtimestamp"', '$customer', '$location' ,'"$response"'," $1  "," $6")"";\""}')
		fi 
	  fi
done 

for i in "${consum[@]}" ; do 
	echo $i
done
for i in "${pagecount[@]}" ; do 
	echo $i
done





# OK PRINTER_STATUS=$(snmpget -v1 -Ovq -c $COMMUNITY $HOST_NAME 1.3.6.1.2.1.25.3.5.1.1.1 2>/dev/null)










	#insrt=`printf $i ` 
#	/usr/bin/mysql -u$dbuser -p$dbpw $dbname -e "INSERT INTO $dbtable ( runtime, cid, customer , location, printer, consum, status ) VALUES( now(), $customer, $location , "EPSON Epson Stylus Office BX320FW", Black2 ,88);"

#INSERT INTO my_table ( runtime, cid, customer , location, printer, consum, status ) VALUES (NOW(), LOAD_FILE('/tmp/my_file.txt'));

#INSERT INTO my_table (stamp, what) VALUES (NOW(), LOAD_FILE('/tmp/my_file.txt'));
#LOAD DATA LOCAL INFILE "myfile.csv" INTO TABLE tablename 
#FIELDS TERMINATED BY ','
#LINES TERMINATED BY '\n'
#column name, column name);

#for record in ${bablefish[@]}; do
#mysql $dbname -u$dbuser -p$dbpw $record
#echo "Done: "$record
#done


#cnt=${#bablefish[@]}
#echo $cnt

#mysql $dbname -u$dbuser -p$dbpw -e 

#(datetime, cid, customer , location, printer, consum, status )
#
#INSERT INTO TABLE X VALUES(2406613229,EPSON Epson Stylus Office BX320FW,Black,100%)
#INSERT INTO TABLE X VALUES(2406613229,EPSON Epson Stylus Office BX320FW,Black#2,88%)
#INSERT INTO TABLE X VALUES(2406613229,EPSON Epson Stylus Office BX320FW,Magenta,55%)
#INSERT INTO TABLE X VALUES(2406613229,EPSON Epson Stylus Office BX320FW,Cyan,22%)
#INSERT INTO TABLE X VALUES(2406613229,EPSON Epson Stylus Office BX320FW,Yellow,57%)
#

#		  #echo "Found a got response" 
#		    bablefish=$(/home/vaktin/repo/check_snmp_printer -H $soip.$ip -C public -x "CONSUM ALL" | grep '%' | awk -F ' ' '{print $response "," $6}')
#		fi
#		printf $response","$bablefish
#	fi
#done

 #echo ${bablefish[*]}\n




	# For printers we get
    # typical response 1 (Kyocera Printer)   -> STRING: LS-C5016N
    # typical response 2 (FujiXerox Printer) -> STRING: FUJI XEROX DocuCentre-III C440 v  3.  7.  1 Multifunction System
	
#	echo $response | grep -q 'EPSON\|Epson'
#		if [ $? -eq 0 ]; then 
#		  echo "Found Epson Printer" 
#		  bablefish=$(/home/vaktin/repo/check_snmp_printer -H $soip.$ip -C public -x "CONSUM ALL" | grep '%' | awk -F ' ' '{print "," $6}')
#		else
#		#Look for Kyocera Printer
#		echo $response | grep -q 'LS-'
#		  if [ $? -eq 0 ]; then
#		  echo "Found Kyocera Printer"
#		  bablefish=$(/home/vaktin/repo/check_snmp_printer -H $soip.$ip -C public -x "CONSUM ALL" | grep '%' | awk -F ' ' '{print "," $6}')
#		else
#		# Look for FujiXerox Printer
#		  echo $response | grep -q 'FUJI XEROX'
#		  if [ $? -eq 0 ]; then	
#		  echo "Xerox Printer"
#		  bablefish=$(/home/vaktin/repo/check_snmp_printer -H $soip.$ip -C public -x "CONSUM ALL" | grep '%' | awk -F ' ' '{print "," $6}')
#		# Look for HP printer
#		else
#		  echo $response | grep -q 'HP\|Deskjet\|Officejet'
#		  if [ $? -eq 0 ]; then
#		  echo "HP Printer"
#		  bablefish=$(/home/vaktin/repo/check_snmp_printer -H $soip.$ip -C public -x "CONSUM ALL" | grep '%' | awk -F ' ' '{print "," $6}')
#		# Nothing special found call it generic
#		else
#		  echo "generic-printer"
#		  bablefish=$(/home/vaktin/repo/check_snmp_printer -H $soip.$ip -C public -x "CONSUM ALL" | grep '%' | awk -F ' ' '{print "," $6}')
#		  fi
#		fi
#	  fi
#	fi
#fi
#done

#echo "Done"
#echo '"'$response'"' $bablefish


#	  if [[ -n $response ]]; then
#		readarray table_insert <  <(/home/vaktin/repo/check_snmp_printer -H $soip.$ip -C public -x "CONSUM ALL" | grep '%' | awk -F ' ' '{print "INSERT INTO TABLE X VALUES('$customer','"$response"'," $1 "," $6")"}')
#	  fi 
#	fi
#done
#echo ${table_insert[4]}
#
#echo $response

#        # For printers we get
#        # typical response 1 (Kyocera Printer)   -> STRING: LS-C5016N
#        # typical response 2 (FujiXerox Printer) -> STRING: FUJI XEROX DocuCentre-III C440 v  3.  7.  1 Multifunction System
#		# No redirects in loop stout to config file
#		exec >> $PRINTCONF
#        echo "define host{"
#        # check if we got a Kyocera
#        echo $response| grep -q 'STRING: LS-'
#        if [ $? -eq 0 ]; then echo "  use                   kyocera-printer-so"
#        else
#          # check if we got a Xerox
#          echo $response| grep -q 'STRING: FUJI XEROX'
#          if [ $? -eq 0 ]; then echo "  use                   xerox-printer-so"
#	  else
#            # check if we got a Epson
#            echo $response| grep -q 'STRING: EPSON'
#            if [ $? -eq 0 ]; then echo "  use                   epson-printer-so"
#	    else
#		# check if we got a Epson
#            	echo $response| grep -q 'STRING: HP\|STRING: Deskjet\|STRING: Officejet'
#            	if [ $? -eq 0 ]; then echo "  use                   HP-printer-so"
#            	else
#              		         echo "  use                   generic-printer-so"
#	    fi
#           fi
#          fi
#        fi
#        echo "  alias             $customer-printer-$cnt"
#        #echo "  alias            $customer-printer-$cnt (`echo $response| cut -d ' ' -f 2-5` $cnt)"
#        echo "  host_name                `echo $response| cut -d ' ' -f 2-5` $cnt"
#        echo "  address              $soip.$ip"
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

