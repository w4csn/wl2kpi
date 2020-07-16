#!/bin/bash
# Installs/Updates PiBPQ
# 
#
# Uncomment this statement for debug echos
DEBUG=1
set -u # Exit if there are uninitialized variables.
scriptname="`basename $0`"
source $START_DIR/core/core_functions.sh
# trap ctrl-c and call function ctrl_c()
trap ctrl_c INT
linbpq_source=http://www.cantab.net/users/john.wiseman/Downloads
params_source=http://www.tnc-x.com
############
###Check for these files with linbpq_source
###pilinbpq
###piBPQAPRS
###piminicom.zip
###PITNCParamsApr18.zip 
########################

# ===== Function List =====

# ===== End of Functions list =====

# ===== Main

#### Install Necessary Packages for BPQ #####
sudo apt-get install --reinstall iputils-ping
sleep1
sudo apt-get -y install ax25-tools
sleep 1
sudo apt-get -y install ax25-apps
sleep 1
sudo apt-get -y --force-yes install i2c-tools
sleep 1
sudo apt-get -y install libcap2-bin
sleep 1
sudo apt-get -y install libpcap0.8
sleep 1
sudo apt-get -y install libpcap-dev
sleep 1
sudo apt-get -y install minicom
sleep 1
sudo apt-get -y install conspy
sleep 1
sudo apt-get -y install vim
####
#### Get G8BPQ version of minicom ####
sleep 1
cd /home/pi
rm -Rf minicom
rm -f in*
mkdir minicom
cd minicom
wget -o /dev/null $linbpq_source/piminicom.zip
unzip piminicom.zip
chmod +x piminicom
wget -o /dev/null $linbpq_source/minicom.scr
cd /home/pi
####
#### GIT: install GPIO wiringPi tools
	git clone git://git.drogon.net/wiringPi
    cd wiringPi
    ./build
####
#### Get TNC-PI Files
wget -o /dev/null $_source_url/params.zip
#### wget -o /dev/null http://www.tnc-x.com/params.zip
unzip params.zip
chmod +x pitnc*
sudo mv pitnc* /usr/local/sbin
####

##Set the source folder for files needed to install BPQ
SOURCE_DIR=$START_DIR/pilinbpq/src
echo "* Reinstall IPUTILS-PING"
sudo apt install --reinstall iputils-ping

echo "$(date "+%Y %m %d %T %Z"): pibpq_install.sh: PIBPQInstallation Completed" >> $WL2KPI_INSTALL_LOGFILE
echo "$(date "+%Y %m %d %T %Z"): pipq_install.sh: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW} pibpq_install.sh: script FINISHED ${Reset}"
echo
# ===== End Main =====