#!/bin/bash
# Installs/Updates the Linux RMS Gateway
# Based on RMS-Install7-181.bash by C Schuman, K4GBB k4gbb1gmail.com
# ReWrite by Scott Newton, W4CSN	Nov 2017

# Error Checking
set -u # Exit if there are uninitialized variables
set -e # Exit if any statement returns a non-true value

# Color Codes
Reset='\e[0m'
Red='\e[31m'
Green='\e[32m'
Yellow='\e[33m'
Blue='\e[34m'
White='\e[37m'
BluW='\e[37;44m'

# Constants
wd=$(pwd)
uid=$(id -u)
UDATE="NO"
GWOWNER="rmsgw"
RMSGW=https://github.com/nwdigitalradio/rmsgw

function Chk_Root
{
# Check for Root
if [ ! uid=0 ]; then
 echo "You must be root User to perform installation!"
 echo "Attempting to change user to root..."
 sudo su ||{echo "SU to root Failed! Exiting..."; exit 1}
fi
}


function Install_Tools
{
echo -e "${Green} Updating the Package List               ${Reset}"
echo -e "\t${YelRed} This may take a while ${Reset}"
apt-get update > /dev/null
echo "  *"
echo -e "${BluW}\t Installing Support libraries \t${Reset}"
apt-get install build-essential autoconf automake libtool -y -q
apt-get install xutils-dev libxml2 libxml2-dev python-requests -y -q
apt-get install libax25-dev libx11-dev zlib1g-dev libncurses5-dev -y -q
echo "  *"
}

function Create_Users
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

function Download_rmsgw #Pull rmsgw from github
{
echo -e "${BluW}\t Downloading RMS Source file \t${Reset}"
cd /usr/local/src
if [ ! -d /usr/local/src/rmsgw ]; then
  echo -e "${Green} Downloading rmsgw source ${Reset}"
  git clone $RMSGW
else
  echo -e "${Green} Updating local rmsgw source ${Reset}"
  git pull $RMSGW
fi
}

function CopyFromInst_rmsgw # Copy rmsgw from install folder
{
echo -e "${BluW}\t Downloading RMS Source file \t${Reset}"
cd /usr/local/src
cp rmsgw-2.4.0-182 rmsgw
if [ $? -ne 0 ]
   then
 echo -e "${BluW}${Red}\t RMS File not available \t${Reset}"
 exit 1
fi
}

function Compile_rmsgw
{
# rmsgw 
echo -e "${BluW}\t Compiling RMS Source file \t${Reset}"
cd /usr/local/src/rmsgw
make > RMS.txt
if [ $? -ne 0 ]
 then
 echo -e "${BluW}$Red} \tCompile error${White} - check RMS.txt File \t${Reset}"
 exit 1
else 
 rm RMS.txt
fi
make install
echo -e "${BluW}RMS Gateway Installed \t${Reset}"
}

function Finishrmsgw_Install
{
# Add RMS_ACI to Crontab
cat /etc/crontab|grep rmsgw || echo "6,36 *  * * *   rmsgw    /usr/local/bin/rmsgw_aci > /dev/null 2>&1
# (End) " >> /etc/crontab

# Install Logging
if [ ! -f "/etc/rsyslog.d/60-rmsgw.conf" ]; then
echo "# RMS Gate" > /etc/rsyslog.d/60-rms.conf 
echo "        local0.info                     /var/log/rms" >> /etc/rsyslog.d/60-rms.conf 
echo "        local0.debug                    /var/log/rms.debug" >> /etc/rsyslog.d/60-rms.conf
echo "        #local0.debug                   /dev/null" >> /etc/rsyslog.d/60-rms.conf 
echo "
# (End)" >> /etc/rsyslog.d/60-rms.conf 

service restart rsyslog
fi

# Use old rmschanstat file.
if [ -f /usr/local/bin/rmschanstat.~1~ ] ; then
    cp /usr/local/bin/rmschanstat.~1~ /usr/local/bin/rmschanstat
fi

date >> /root/Changes
echo "        RMS Gate Installed - rmsgw-2.4.0-181" >> /root/Changes
echo -e "${BluW} Be Sure to Update/Edit the channels.xml and gateway.config file${Reset}"
exit 0
}

# Main
echo -e "${BluW}\t\n\t  Install/Update Linux RMS Gateway \n${Yellow}\t     version 1.0.0  \t\n\t \n${White}   by Scott Newton ( W4CSN )  \n${Red}               snewton86@gmail.com \n${Reset}"
Chk_Root
Install_Tools
Create_Users
Download_rmsgw
Compile_rmsgw
Finishrmsgw_Install
exit 0
# (End of Script)