#!/bin/bash
#
# Translate IP to decimal +range where it creates START_RANGE and END_RANGE for our scan.
# Get our subnet if it is not passed on.

LOGFILE=/tmp/startup.log
touch $LOGFILE
CMDFILE=/boot/prentvakt.txt

customer=$(cat $CMDFILE | grep -w customer | awk -F '*|=' '{print $2}') >> ${LOGFILE} 2>&1
soip=$(cat $CMDFILE | grep -w  subnet | awk -F '*|=' '{print $2}') >> ${LOGFILE} 2>&1 # $soip is the subnet for example 192.168.1
email=$(cat $CMDFILE | grep -w  email | awk -F '*|=' '{print $2}') >> ${LOGFILE} 2>&1
myip=$(cat $CMDFILE | grep -w  myip | awk -F '*|=' '{print $2}') >> ${LOGFILE} 2>&1 # I have a fixed IP number 

if [ ! $soip ] #If nothing was passed to us from config.txt about printers subnet then we figure it out ourselfes and use current IP (first interface).
	then
	myip=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}') 
	# And we need the subnet as well iqf it is not passed on to us.
	soip=${myip%.*}
fi

#Let us log what we have before we go any further
echo "Customer is: "$customer >> ${LOGFILE} 2>&1
echo "Emails are to be sent email to: " $email >> ${LOGFILE} 2>&1
echo "Systems current IP number is" $myip >> ${LOGFILE} 2>&1
echo "Printers subnet is" $soip >> ${LOGFILE} 2>&1


ip2dec () {
    local a b c d ip=$@
    IFS=. read -r a b c d <<< "$ip"
    printf '%d\n' "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
}

dec2ip () {
    local ip dec=$@
    for e in {3..0}
    do
        ((octet = dec / (256 ** e) )) >> ${LOGFILE} 2>&1
        ((dec -= octet * 256 ** e)) >> ${LOGFILE} 2>&1
        ip+=$delim$octet
        delim=.
    done
    printf '%s\n' "$ip"
}

decimal=$(ip2dec $soip)

START_RANGE=$(dec2ip $decimal +2) # we will not want to 0 or one as printer IP address.
END_RANGE=$(dec2ip $decimal +253) # we dont want 254 or 255 as printer IP address

# Log scanning range for debug
echo "Printer scanning start range is: "$START_RANGE  >> ${LOGFILE} 2>&1
echo "Printer scanning end range is. "$END_RANGE  >> ${LOGFILE} 2>&1
echo "----------------------------------------------------------" >> ${LOGFILE} 2>&1

 #cat /boot/config.txt | grep "customer\|subnet" | mail -s "here is your config logs" bh@islaw.is < /tmp/prentv.log >> ${LOGFILE} 2>&1
 printf "I am up and running and attached are my initial installation logs. \n
 Config address: http://$myip/config.html if you whis to change the automatic configuration.\n
 Monitoring address: http://$myip:7767/ if you wish to see how your printers are doing.\n
 \n
 Have a nice day!" | mutt  -s "Startup notification-at boot" $email  -a $LOGFILE 2>/dev/null #No sence in logging this one - is there?
sleep 20 
echo "begin getprinters.sh " 
echo "begin getprinters.sh" >> ${LOGFILE} 
/home/vaktin/getprinters.sh > /usr/local/shinken/etc/hosts/printers.cfg 

#rm $LOGFILE
