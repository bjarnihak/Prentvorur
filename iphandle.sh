#!/bin/bash
#
# This scrift figures out which subnet it is on. 
# tries eth0 and if not ....wifi.
#Translate that to decimal where it creates START_RANGE and END_RANGE for our scan.
# get our subnet.

soip=`ifconfig eth0| awk -F ' *|:' '/inet ad*r/{split($4,a,"."); printf("%d.%d.%d\n", a[1],a[2],a[3])}'`

if [ ! $soip ] # if eth0 is not connected lets try wifi.
   then
  	soip=`ifconfig wlan0 | awk -F ' *|:' '/inet ad*r/{split($4,a,"."); printf("%d.%d.%d\n", a[1],a[2],a[3])}'`
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
        ((octet = dec / (256 ** e) ))
        ((dec -= octet * 256 ** e))
        ip+=$delim$octet
        delim=.
    done
    printf '%s\n' "$ip"
}

decimal=$(ip2dec $soip)

START_RANGE=$(dec2ip $decimal +2) # we will not want to 0 or one as printer address.
END_RANGE=$(dec2ip $decimal +253)

echo $START_RANGE
echo $END_RANGE