#!/bin/bash
#
# Install autohotspot
# Allows for Rpi3 auto connecting wireless to an available access point on boot
# or auto starting hostapd if no AP is found.
# Will also allow for switching from AP mode to hostapd without rebooting via cron job or manually running ./autohotspot
#
DEBUG=1
set -u # Exit if there are uninitialized variables.
scriptname="`basename $0`"
WL2KPI_INSTALL_LOGFILE="/var/log/wl2kpi_install.log"
START_DIR=$(pwd)
source ./core/core_functions.sh

#===== Function List =====
function copy_files
{
cd /usr/bin
ls autohotspot 2>/dev/null
if [ $? -ne 0 ]; then
   echo -e "=== Copying autohotspot to /usr/bin"
   echo
   cp $wd/hostap/autohotspot /usr/bin/ > /dev/null 2>&1
   if [ $? -ne 0 ]; then
	  echo "Problems Copying file"
	  exit 1
	fi
else
	echo "... autohotspot already exists"
    echo 
fi
cd /etc/systemd/system
ls autohotspot.service 2>/dev/null
if [ $? -ne 0 ]; then
   echo -e "=== Copying autohotspot.service to /etc/systemd/system"
   echo
   cp $wd/systemd/autohotspot.service /etc/systemd/system > /dev/null 2>&1
   if [ $? -ne 0 ]; then
	  echo "... Problems Copying file"
	  exit 1
	fi
else
	echo "... autohotspot.service already exists"
    echo 
fi
}

#===== End Function List =====

# ===== main
clear
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script START" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script STARTED"
echo

chk_root
copy_files
service hostapd stop
service dnsmasq stop
systemctl disable hostapd
systemctl disable dnsmasq
systemctl enable autohotspot 
service autohotspot start

echo "$(date "+%Y %m %d %T %Z"): $scriptname: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script FINISHED"
echo