#!/bin/bash 
#
# Translate IP to decimal +range where it creates my_start_range and my_end_range 
# for our scan.
# Get our subnet if it is not passed on.
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games
SHELL=/bin/bash
#
#First the basics
#=========================================================================
log_file=/tmp/startup.log
touch $log_file
get_logfile=/tmp/get_logfile
touch $get_logfile
timestamp=`date +%H:%M:%S`
todays_date=`date +%d/%m/%Y`

# Empty the previous log with > on first occasion of redirect
echo "$timestamp: ----------------------------------------------------------------------------------" > ${log_file} 
echo "$timestamp: Preparing Configuration of Prentvakt." >> ${log_file} 
echo "$timestamp: ----------------------------------------------------------------------------------" >> ${log_file} 

# Handling parameters from SD card. We used the boot on the 

if [ -f /boot/prentvakt.txt ] ; then
	cp -u /boot/prentvakt.txt /home/vaktin/repo/prentvakt.txt
		chmod 777 /home/vaktin/repo/prentvakt.txt
fi

cmd_file=/home/vaktin/repo/prentvakt.txt
# Lots of problems from Windows and others making config files = fix it.
for file in /home/vaktin/repo/*.txt ; do
    dos2unix "$file" >> /dev/null 2>&1
done

# Use the information from SD card if available.
#=========================================================================

# Load file into array. Save I/O's on Rasp
declare -a my_parameter
let i=0
while IFS=$'"="' read -r line_data; do
    my_parameter[i]="${line_data}"
    ((++i))
done < $cmd_file
 
customer=$(printf ${my_parameter[0]} | awk -F '*|=' '{print $2}')
subnet=$(printf ${my_parameter[1]} | awk -F '*|=' '{print $2}')
myip=$(printf ${my_parameter[2]} | awk -F '*|=' '{print $2}')
email=$(printf ${my_parameter[3]} | awk -F '*|=' '{print $2}')
my_start_range=$(printf ${my_parameter[4]} | awk -F '*|=' '{print $2}')
my_end_range=$(printf ${my_parameter[5]} | awk -F '*|=' '{print $2}')

# Debug
#echo "--->" $customer
#echo "--->" $subnet
#echo "--->" $myip
#echo "--->" $emailcc
#echo "--->" $my_start_range
#echo "--->" $my_end_range

# Email Parameters -
#=========================================================================
if [[ -z $email ]]; then 
		email_recipient="vaktin@prentvorur.is"
	else
		email_recipient="$email"
fi

email_subject_context="Startup email at $customer DATE: $todays_date at $timestamp"
email_from="prentvakt@prentvorur.is" # Actually rewritten on send by ssmt
template=/tmp/template
#email_prog="$(which email_sender)"
email_prog=/usr/loca/bin/email_sender

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

# Prepare range and ip calc
if [[ -n $soip ]]; then
	decimal=$(ip2dec $soip)
fi

if [[ -n $my_start_range ]] ; then
	my_start_range=$(dec2ip $decimal + $my_start_range )
	#echo "$timestamp: Got my_start_range :"
else
	my_start_range=$(dec2ip $decimal + 2 ) 
	#echo "$timestamp: Assinging Standard start"
fi

if [[ -n $my_end_range ]] ; then
	my_end_range=$(dec2ip $decimal + $my_end_range )
	#echo "$timestamp: Got my_end_range :"
else
	my_end_range=$(dec2ip $decimal + 253 ) 
	#echo "$timestamp: Assinging Standard end" 
fi



# Preparing the log_file soon to turn into email
body=$(printf "
You can use the following URL's after the system has configured.\n
Config URL is: http://$myip/cgi-bin/config.cgi  \n
Monitoring URL is: http://$myip:7767/all \n
Please find below the logs generated during the install.\n
Have a nice day! \n

Please give the system few minutes to initialize. \n\n ") 


echo "$body" >> ${log_file}
echo "$timestamp: ----------------------------------------------------------------------------------" >> ${log_file} 
echo "$timestamp: Starting the run on the  $todays_date " >> ${log_file} 
echo "$timestamp: At $timestamp hours" >> ${log_file} 
echo "$timestamp: ----------------------------------------------------------------------------------" >> ${log_file} 
echo "$timestamp: Customer is: "$customer >> ${log_file} 
echo "$timestamp: Emails are to be sent email to: " $email  >> ${log_file}
echo "$timestamp: ----------------------------------------------------------------------------------" >> ${log_file}
echo "$timestamp: Systems current IP number is: " $myip  >> ${log_file}
echo "$timestamp: Printers subnet is:" $soip >> ${log_file}
echo "$timestamp: Printer scanning start range is: " $my_start_range  >> ${log_file}
echo "$timestamp: Printer scanning end range is: " $my_end_range  >> ${log_file}
echo "$timestamp: ----------------------------------------------------------------------------------" >> ${log_file} 
#echo "$timestamp: " >> ${log_file}
echo "$timestamp: Finding printers -> getprinters "  >> ${log_file} 

# starting search

. /home/vaktin/repo/getprinters >> ${log_file} 2>&1
wait


echo "---------------------------------------------------------------------------------------------" >> ${log_file} 
cat $get_logfile >> ${log_file}
#rm $get_logfile

/bin/sh "$email_prog" "$email_recipient" "$email_from" "$email_subject_context" "$(cat ${log_file})"  

#debug
#/usr/sbin/ssmtp $email <<EOF > /tmp/mailERR 2>&1
#To: $email
#From: contact-us@somedomain.co.uk 
#Subject: mailtest
#
#---> $customer
#---> $subnet
#---> $myip
#---> $email
#---> $my_start_range
#---> $my_end_range
#
#think about that!
#
#EOF
#