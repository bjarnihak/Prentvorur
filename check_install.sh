#!/bin/bash
#
# Fecth all that is needed and setup automatically
# 
# get all the stuff autmatically
#get shinken 
#http://www.shinken-monitoring.org/pub/shinken-1.4.1.tar.gz
# better
#git clone https://bjarnihak:presi24@github.com/bjarnihak/Prentvorur.git
#Check if we have a good repository
check=$(git status https://bjarnihak:presi24@github.com/bjarnihak/Prentvorur.git | grep up-to-date)
if test -z "$check"; then
		echo "all is good. Changing File permissions" && chmod +x *.sh
	else 
		echo "Nothing is all that good" $check
fi