#!/bin/bash
# Installs/Updates the Linux RMS Gateway
# Parts taken from RMS-Upgrade-181 script Updated 10/30/2014
# (https://k4gbb.no-ip.org/docs/scripts)
# by C Schuman, K4GBB k4gbb1gmail.com
#
DEBUG=1 # Uncomment this statement for debug echos
set -u # Exit if there are unitialized variables.
scriptname="`basename $0`"
WL2KPI_INSTALL_LOGFILE="/var/log/wl2kpi_install.log"
wd=$(pwd)
uid=$(id -u)

# Color Codes
Reset='\e[0m'
Red='\e[31m'
Green='\e[32m'
Yellow='\e[33m'
Blue='\e[34m'
White='\e[37m'
BluW='\e[37;44m'

UDATE="NO"
GWOWNER="rmsgw"
RMSGW=https://github.com/nwdigitalradio/rmsgw
PKG_REQUIRE="xutils-dev libxml2 libxml2-dev python-requests"
SRC_DIR="/usr/local/src/rmsgw"
SRC_FILE="rmsgw-2.4.0-182.zip"
ROOTFILE_NAME="rmsgw-"
RMS_BUILD_FILE="rmsbuild.txt"

# ===== Function List =====

# ===== function dbecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function chk_root 
function chk_root {
# Check for Root
if [[ $EUID != 0 ]] ; then
   echo -e "Must be root"
   exit 1
fi
}

# ===== function is_pkg_installed
function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}


function install_tools
{
# check if packages are installed
echo -e "=== Installing Required Packages"
dbgecho "Check packages: $PKG_REQUIRE"
needs_pkg=false

for pkg_name in `echo ${PKG_REQUIRE}` ; do

   is_pkg_installed $pkg_name
   if [ $? -ne 0 ] ; then
      echo "$scriptname: Will Install $pkg_name program"
      needs_pkg=true
      break
   fi
done

if [ "$needs_pkg" = "true" ] ; then
   echo -e "${BluW}\t Installing Support libraries \t${Reset}"

   apt-get install -y -q $PKG_REQUIRE
   if [ "$?" -ne 0 ] ; then
      echo "Support library install failed. Please try this command manually:"
      echo "apt-get install -y $PKG_REQUIRE"
      exit 1
   fi
fi

echo -e "=== All required packages installed."
echo
}

function create_users
{
#  create the group for the gateway if it doesn't exist
grep "rmsgw:" /etc/group >/dev/null 2>&1
if [ $? -ne 0 ]; then
 echo "Creating group rmsgw..."
 groupadd rmsgw
fi
#  create the gateway user if it doesn't exist
grep "rmsgw:" /etc/passwd >/dev/null 2>&1
if [ $? -ne 0 ]; then
 echo "Creating user rmsgw..."
 useradd -s /bin/false -g rmsgw rmsgw
fi
# lock the account to prevent a potential hole, unless the owner is root
if [ "$GWOWNER" != root ]; then
 echo "Locking user account $GWOWNER..."
 passwd -l $GWOWNER >/dev/null
 # while the account is locked, make the password to
 # never expire so that cron will be happy
 chage -E-1 $GWOWNER >/dev/null
fi
}

function download_rmsgw #Pull rmsgw from github
{
echo -e "${BluW}\t Downloading RMS Source file \t${Reset}"
cd /usr/local/src
if [ ! -d $SRC_DIR ]; then
  echo -e "${Green} Downloading rmsgw source ${Reset}"
  git clone $RMSGW
else
  echo -e "${Green} Updating local rmsgw source ${Reset}"
  git pull $RMSGW
fi
}

function copy_rmsgw # Copy rmsgw from install folder
{
echo -e "${BluW}\t Downloading RMS Source file \t${Reset}"
if [ ! -d $SRC_DIR ]; then
	mkdir $SRC_DIR
fi
cd $SRC_DIR
cp $wd/src/$SRC_FILE . > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "...Copy complete"
else
	echo "... Copy failed"
	exit 1
fi
unzip $SRC_FILE > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "...Unzip complete"
else
	echo "...Unzip failed"
	exit 1
fi	

}

function compile_rmsgw
{
# rmsgw 
echo -e "${BluW}\t Compiling RMS Source file \t${Reset}"
num_cores=$(nproc --all)
cd $SRC_DIR
make clean
make -j$num_cores > $RMS_BUILD_FILE 2>&1
if [ $? -ne 0 ]
 then
 echo -e "${BluW}$Red}\t Compile error${White} - check RMS.txt File \t${Reset}"
 exit 1
else 
 rm $RMS_BUILD_FILE
fi
make install
echo -e "${BluW}RMS Gateway Installed \t${Reset}"
}

function finish_rmsgw
{
# Copy rmschanstat to /usr/local/bin
if [ ! -f /usr/local/bin/rmschanstat~1~ ]; then
	cp -f $wd/rmsgw/rmschanstat /usr/local/bin/rmschanstat
else
	# Use old rmschanstat file.
    cp /usr/local/bin/rmschanstat.~1~ /usr/local/bin/rmschanstat
fi

date >> /root/Changes
echo "        RMS Gate Installed - rmsgw-2.4.0-181" >> /root/Changes
echo -e "${BluW} Be Sure to Update/Edit the channels.xml and gateway.config file${Reset}"
}

# ===== End of Functions list =====

# ===== Main
sleep 3
clear
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script START" >>$WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script STARTED"
echo

chk_root
install_tools
create_users
copy_rmsgw
compile_rmsgw
finish_rmsgw

echo "$(date "+%Y %m %d %T %Z"): $scriptname: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script FINISHED"
echo