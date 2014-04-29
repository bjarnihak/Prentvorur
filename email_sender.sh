#!/bin/bash
Now=$(date +"%Y-%m-%d")
SSMTP="$(which ssmtp)"


TEMPLATE="/tmp/prepare_mail.txt"

echo "To: $1" > $TEMPLATE
echo "From: $2" >> $TEMPLATE
echo "Subject: $3" >> $TEMPLATE
echo " " >> $TEMPLATE
echo  "$4" >> $TEMPLATE

$SSMTP $1 < $TEMPLATE
rm $TEMPLATE
