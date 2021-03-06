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
RPI_PKG_LIST="python-dev python-serial python3-serial python-configparser pyserial tornado python-tornado multiprocessing  "
############
###Check for these files with linbpq_source
###pilinbpq
###piBPQAPRS
###piminicom.zip
###PITNCParamsApr18.zip 
########################

# ===== Function List =====
function install_rasbpian_Packages()
{
# Install Apps
echo -e "${Cyan}=== Check Build Tools ${Reset}"
needs_pkg=false
for pkg_name in `echo ${RPI_PKG_LIST}` ; do
   is_pkg_installed $pkg_name
   if [ $? -ne 0 ] ; then
      echo -e "\t ${Blue} pibpq_install.sh: Will Install $pkg_name program ${Reset}"
      needs_pkg=true
      break
   fi
done
if [ "$needs_pkg" = "true" ] ; then
   echo -e "\t ${Blue} Installing some Rasbpian packages ${Reset}"
   apt install -y -q --force=yes $RPI_PKG_LIST
   if [ "$?" -ne 0 ] ; then
      echo -e "\t ${Red} Rasbpian package install failed. ${Reset}Please try this command manually:"
      echo -e "\t apt-get install -y $PIBPQ_PKG_LIST"
      exit 1
   fi
fi
echo -e "${Cyan}=== Raspbian packages installed. ${Reset}"
echo
}
# ===== End of Functions list =====

# ===== Main
clear
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script START" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW}$scriptname: script STARTED ${Reset}"
echo
#### Install Necessary Packages for BPQ #####

install_rasbpian_Packages

####
#### Set user to pi
sudo su pi
#### Get G8BPQ version of minicom ####
sleep 1
cd ~
rm -Rf minicom
rm -f in*
mkdir minicom
cd minicom
wget -o /dev/null $linbpq_source/piminicom.zip
unzip piminicom.zip
chmod +x piminicom
wget -o /dev/null $linbpq_source/minicom.scr
cd ~
####
#### GIT: install GPIO wiringPi tools
	git clone git://git.drogon.net/wiringPi
    cd wiringPi
    ./build
####
exit

#### Unpack TNC-PI Files and move to /usr/local/sbin
cd $START_DIR/pibpq/src/params.zip
#### wget -o /dev/null http://www.tnc-x.com/params.zip
unzip params.zip
chmod +x pitnc*
sudo mv pitnc* /usr/local/sbin
####

#### Create a BPQ directory below /home/pi
echo "##### create bpq folder below /home/pi"
sudo su pi
cd ~
rm -rf linbpq
mkdir linbpq
chmod 755 linbpq
cd linbpq
exit

##### Get RUNBPQ.SH
echo "##### get RUNBPQ"
cd $START_DIR/pibpq/src
if [ -f runbpq.sh ]; then
   chown pi:pi runpbq.sh
   chmod +x runbpq.sh
   sudo cp runbpq.sh /usr/local/sbin/runbpq.sh;
   echo "copy runpq.sh to /usr/local/bin"
   echo "#####"
else
   echo "ERROR: Failure retrieving runbpq.sh.  Something is wrong"
   echo "ERROR: Aborting"
   exit 1;
fi

#### Get bpq32.cfg
echo "##### get bpq32.cfg"
cd $START_DIR/pibpq/src
if [ -f bpq32.cfg ];
then
	cp bpq32 /home/pi/linbpq
	cd home/pi/linbpq
	chmod 0644 bpq32
	chown pi:pi bpq32
	echo "##### bpq32.cfg found successfully"
   echo "#####"
else
   echo "ERROR: Failure retrieving bpq32.cfg.  Something is wrong"
   echo "ERROR: Aborting"
   exit 1;
fi

echo "$(date "+%Y %m %d %T %Z"): $scriptname: PIBPQInstallation Completed" >> $WL2KPI_INSTALL_LOGFILE
echo "$(date "+%Y %m %d %T %Z"):$scriptname: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW} pibpq_install.sh: script FINISHED ${Reset}"
echo
# ===== End Main =====