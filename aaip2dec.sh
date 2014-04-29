#!/bin/bash
#
# Translate IP to decimal +range where it creates START_RANGE and END_RANGE 
# for our scan.
# Get our subnet if it is not passed on.
#
#First we need the logfile 
#===========================================================================
LOGFILE=/tmp/startup.log
touch $LOGFILE
# Parameters from SD card.
CMDFILE=/boot/prentvakt.txt
customer=$(cat $CMDFILE | grep -w customer | awk -F '*|=' '{print $2}') >> ${LOGFILE} 2>&1
soip=$(cat $CMDFILE | grep -w  subnet | awk -F '*|=' '{print $2}') >> ${LOGFILE} 2>&1 # $soip is the subnet for example 192.168.1
email=$(cat $CMDFILE | grep -w  email | awk -F '*|=' '{print $2}') >> ${LOGFILE} 2>&1
myip=$(cat $CMDFILE | grep -w  myip | awk -F '*|=' '{print $2}') >> ${LOGFILE} 2>&1 # Just for the email and URL's 

# Email Parameters
#=========================================================================
EMAIL_SUBJECT_CONTEXT="Initial startup email at $customer"
EMAIL_RECIPIENT="bh@islaw.is"
EMAIL_SENDER="Prentvakt"

# Various Parameters
#=========================================================================
TIMESTAMP=`date +%F-%H.%M.%S`
TODAYS_DATE=`date +%Y-%m-%d`
SCRIPT_PATH=/home/vaktin/repo

# Main code
#==========================================================================

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

 printf "System has started and attached are the initial installation logs.\n
 Config URL is: \n
 http://$myip/config.html if you whis to change the automatic configuration.\n
 Monitoring URL is: \n
 http://$myip:7767/ if you wish to see how your printers are doing.\n
 Soon you will get the results by email.
 \n
 Have a nice day! \n
\n
You can soon expect the results of printer scan by email. \n\n " | mutt  -s "$EMAIL_SUBJECT_CONTEXT" $email -a $LOGFILE 

#sleep 20 
#echo "begin getprinters.sh " 
#echo "begining finding printers getprinters.sh" >> ${LOGFILE} 
#/home/vaktin/repo/getprinters  

#echo "Results of initial setup " >> $LOGFILE
#/bin/sh "$SCRIPT_PATH/email_sender.sh" "$EMAIL_RECIPIENT" "$EMAIL_SENDER" "$EMAIL_SUBJECT_CONTEXT" "$(cat $LOGFILE)"
rm $LOGFILE
