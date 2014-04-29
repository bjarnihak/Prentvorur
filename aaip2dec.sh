#!/bin/bash
#
# Translate IP to decimal +range where it creates START_RANGE and END_RANGE 
# for our scan.
# Get our subnet if it is not passed on.
#
#First the basics
#=========================================================================
export LOGFILE=/tmp/startup.log
touch $LOGFILE
sleep 2
echo "----------------------------------------------------------" >> ${LOGFILE} 2>&1
echo "Preparing Configuration of Prentvakt." >> ${LOGFILE} 2>&1
echo "----------------------------------------------------------" >> ${LOGFILE} 2>&1
. /home/vaktin/repo/restart "stop"  >> ${LOGFILE} 2>&1
sleep 5

# Handling parameters from SD card. We used the boot on the 

if [ -f /boot/prentvakt.txt ] ; then
	cp -u /boot/prentvakt.txt /home/vaktin/repo/prentvakt.txt
		chmod 777 /home/vaktin/repo/prentvakt.txt
fi

CMDFILE=/home/vaktin/repo/prentvakt.txt

# Use the information available.
#=========================================================================
customer=$(cat $CMDFILE | grep -w CUSTOMER | awk -F '*|=' '{print $2}') >> ${LOGFILE} 2>&1
# $soip is the subnet for example 192.168.1
soip=$(cat $CMDFILE | grep -w SUBNET | awk -F '*|=' '{print $2}') >> ${LOGFILE} 2>&1 
email1=$(cat $CMDFILE | grep -w EMAIL | awk -F '*|=' '{print $2}') >> ${LOGFILE} 2>&1
# Just for the email and URL's 
myip=$(cat $CMDFILE | grep -w MYIP | awk -F '*|=' '{print $2}') >> ${LOGFILE} 2>&1 

# Email Parameters
#=========================================================================
EMAIL_RECIPIENT="vaktin@prentvorur.net"
EMAIL_SUBJECT_CONTEXT="Initial startup email at $customer"
EMAIL_SENDER="Prentvakt"
TEMPLATE=/tmp/template
SSMTP="$(which ssmtp)"

# Various Parameters
#=========================================================================
TIMESTAMP=`date +%H.%M`
TODAYS_DATE=`date +%d-%m-%Y`
SCRIPT_PATH=/home/vaktin/repo

# Main code
#==========================================================================

if [ -n $myip ]; then
	# And we need our ip if it was not passed on to us.
	myip=$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}'); 
fi 

#If nothing was passed to us from config.txt about printers subnet then we figure it out ourselfes and use current IP (first interface).
if [ -n $soip ]; then
	# And we need the subnet as well if it is not passed on to us.
	soip=${myip%.*}
fi

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
echo "----------------------------------------------------------" >> ${LOGFILE} 2>&1
echo "Starting the run on the  $TODAYS_DATE " >> ${LOGFILE} 2>&1
echo "At $TIMESTAMP hours" >> ${LOGFILE} 2>&1
echo "----------------------------------------------------------" >> ${LOGFILE} 2>&1
echo "Customer is: "$customer >> ${LOGFILE} 2>&1
echo "Emails are to be sent email to: " $email >> ${LOGFILE} 2>&1
echo "Systems current IP number is: " $myip >> ${LOGFILE} 2>&1
echo "Printers subnet is:" $soip >> ${LOGFILE} 2>&1
echo "----------------------------------------------------------" >> ${LOGFILE} 2>&1
echo "Printer scanning start range is: "$START_RANGE  >> ${LOGFILE} 2>&1
echo "Printer scanning end range is. "$END_RANGE  >> ${LOGFILE} 2>&1
echo "----------------------------------------------------------" >> ${LOGFILE} 2>&1
echo ""
echo "Begining finding printers "  >> ${LOGFILE} 2>&1

# start search

. /home/vaktin/repo/getprinters 
sleep 5
. /home/vaktin/repo/restart "start"  >> ${LOGFILE} 2>&1
echo " " >> ${LOGFILE} 2>&1
echo "Finished. Check your email." >> ${LOGFILE} 2>&1
echo "----------------------------------------------------------" >> ${LOGFILE} 2>&1
sleep 2

BODY=$(printf "System has started and attached are the initial installation logs.\n
 Config URL is: \n
 http://$myip/cgi-bin/config.cgi if you whis to change the automatic configuration.\n
 Monitoring URL is: \n
 http://$myip:7767/all if you wish to see how your printers are doing.\n
 Soon you will get the results by email.
 \n
 Have a nice day! \n
\n
You can soon expect the results of printer scan by email. \n\n ") # | mutt  -s "$EMAIL_SUBJECT_CONTEXT" $email1 -a $LOGFILE 

# Send the email
echo "To: $EMAIL_RECIPIENT" > $TEMPLATE
echo "Cc: $email" >> $TEMPLATE
echo "From: $EMAIL_SENDER" >> $TEMPLATE
echo "Subject: $EMAIL_SUBJECT_CONTEXT" >> $TEMPLATE
echo " " >> $TEMPLATE
echo  "$BODY" >> $TEMPLATE

$SSMTP $EMAIL_RECIPIENT < $TEMPLATE
#rm $TEMPLATE
#rm $LOGFILE