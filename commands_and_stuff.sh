Memo for Prentvakt. ekki endilega � r�ttri r�� en til minnis.

sudo curl -L http://install.shinken-monitoring.org | /bin/bash 2>/dev/null # get shinken ig install (not addons we dont want them)

get mongodb -linux direct (shinken breaks on mongodb install) #if we want.

#get our repos directly
git clone https://bjarnihak:presi24@github.com/bjarnihak/Prentvorur.git

cp /home/vaktin/check_snmp_printer /usr/local/shinken/libexec/ #get check_printer in correct place

sudo chown shinken:shinken  /usr/local/shinken/libexec/check_snmp_printer

sudo chmod 777 /usr/local/shinken/etc/hosts/

#NO: sudo apt-get install dosutils

# Postgres if we want
# Create /etc/apt/sources.list.d/pgdg.list file with the following command ( Raspbian is a Debian wheezy system): 
deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main
# Import the repository key, update the package lists, and start installing packages:
wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install postgresql-9.3
sudo apt-get install wput


#manual way to get official shinken if we dont like our own.
wget http://www.shinken-monitoring.org/pub/shinken-1.4.1.tar.gz

tar xvf shinken-1.4.1.tar.gz

cd shinken-1.4.1
#Remove previous installations.
sudo ./install -u

sudo ./install -i &&\
sudo ./install -p nagios-plugins &&\
sudo ./install -p check_mem &&\
sudo ./install -p manubulon &&\
#sudo ./install -a multisite &&\
sudo ./install -a pnp4nagios &&\
sudo ./install -a nagvis &&\
sudo ./install -a mongodb


#Sm� leibeiningar um github stuff sem ��eg er a� l�tra �.
# �tti a� geta gengi� � Makka. Sem er me� prumpu ...so e�a github sty�ur makka vel

#Get all the stuff �samt shinken-1.4.1.tar.gz
git clone https://bjarnihak:presi24@github.com/bjarnihak/Prentvorur.git

#add to git from cmdline. Spyr mig samt um user/pass � vher skipti?

# �g ger�i �etta en held a� �a� �urfi ekki.
git config --global user.name "bjarnihak" 

# �g ger�i �etta en held a� �a� �urfi ekki.
git config --global user.email "bh@islaw.is" 

mkdir somedir
cd somedir

# creates .git folder 
git init 

#List the files in somedir
git status 

# Add files to local repos
git add somefile anotherfile andthehirdfile 

#Commit for sync
git commit -m �Add some text�

#Connect Your Local Repository To Your GitHub (online) Repository

# Connect the two repos together
git remote add origin https://github.com/bjarnihak/Prentvorur.git

#check if it's ok
git remote -v 

#Setja okkur � sync. Annars kvartar github �egar vi� "git push"
git pull https://github.com/bjarnihak/Prentvorur.git 

# push my stuff to online repo
git push 

bjarnihak/presi24 #fyi







sudo apt-get install pyro