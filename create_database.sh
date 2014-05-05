#!/bin/bash
# 
# Create database and tables. 
# Check if db and table exists and if not create them.
#

rootpw=root
dbname=my_monitor
dbuser=mon
dbpw=mon
dbtable=montable 
timestamp=`date +%H:%M:%S`

db="CREATE DATABASE $dbname;GRANT ALL PRIVILEGES ON $dbname.* TO $dbuser@localhost IDENTIFIED BY '$dbpw';FLUSH PRIVILEGES;"
tableadd="CREATE TABLE $dbtable (runtime datetime, cid VARCHAR(25), customer VARCHAR(25), location VARCHAR(25), printer VARCHAR(25), consum VARCHAR(25), status VARCHAR(25));"
dbcheck=`mysqlshow --user=$dbuser --password=$dbpw $dbname | grep -v Wildcard | grep -o $dbname  2> /dev/null` 
tablexists=`mysql -N -s -uroot -proot -e "select count(*) from information_schema.tables where table_schema='$dbname' and table_name='$dbtable';"` 2>/dev/null

 
if [[ $1 == "drop" ]] ; then
	my_check=$( echo $dbcheck | grep "$dbname" 2>/dev/null)
 		if [ -z $my_check ]; then
		 echo "------------------------------------------"
		 echo "Database name <$dbname> does not exitsts."
		 echo "------------------------------------------"
	exit
else
	while true; do
    read -p "Do you wish to drop the database?(y/n):" yn
		case $yn in
			[Yy]* ) `mysql  -uroot -proot -e "drop database $dbname;"` ; break;;
			[Nn]* ) exit;;
			* ) echo "Please answer yes or no.";;
		esac
	done
	fi
fi

if [ "$dbcheck" == "$dbname" ]; then
	echo "------------------------------------------"
	echo "Database name <$dbname> exitsts."
	echo "------------------------------------------"
else
	mysql -u root -p$rootpw -e "$db"
		if [ $? != "0" ]; then
		echo "[Error]: Database creation failed"
	exit 1
	else
	echo "------------------------------------------"
	echo " Database has been created successfully "
	echo "------------------------------------------"
	echo " DB Info: "
	echo ""
	echo " DB Name: $dbname"
	echo " DB User: $dbuser"
	echo " DB Pass: $dbpw"
	echo ""
	echo "------------------------------------------"
	echo "Adding a table"
 	fi
fi


if [ "$tablexists" == 1 ]; then
	echo "------------------------------------------"
	echo "Table name <$dbtable> exists."
	echo "------------------------------------------"
else
	echo "------------------------------------------"
    echo "Table <$dbtable> does not exist - creating"
	echo "------------------------------------------"
	mysql $dbname -u$dbuser -p$dbpw -e  "$tableadd"
	mysql $dbname -u$dbuser -p$dbpw -e  "$insert"
		if [ $? != "0" ]; then
			echo "[Error]: Table creation failed"
	exit 1
	echo "------------------------------------------"
	echo " Database table has been created "
	echo "------------------------------------------"
	echo " DB Info: "
	echo ""
	echo " DB Name: $dbname"
	echo " DB User: $dbtable"
	echo ""
	echo "------------------------------------------"
  fi
fi
