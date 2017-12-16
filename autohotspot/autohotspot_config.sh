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
SERVICELIST="autohotspot hostapd dnsmasq"

#===== Function List =====
function copy_files
{
cd /usr/bin
ls autohotspot 2>/dev/null
if [ $? -ne 0 ]; then
   echo -e "=== Copying autohotspot to /usr/bin"
   echo
   cp $START_DIR/autohotspot/autohotspot /usr/bin/   
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
   cp $START_DIR/systemd/autohotspot.service /etc/systemd/system > /dev/null 2>&1
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

# ===== Main =====
sleep 2
clear
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script START" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW}autohotspot_config.sh: script STARTED${Reset}"
echo

# Be sure we're running as root
chk_root

# Make sure we're running a Raspberry Pi 3
is_rpi3
if [ $? -eq "0" ] ; then
   echo -e "Not running on an RPi 3 ... ${Yellow}exiting${Reset}"
   echo
   exit 1
fi

# Copy autohotspot files
copy_files

# Configure services
service hostapd stop
service dnsmasq stop
systemctl disable hostapd
systemctl disable dnsmasq
systemctl enable autohotspot
systemctl daemon-reload
service autohotspot start

echo
echo -e "Test if ${Yellow}$SERVICELIST{$Reset} services have been modified."
echo -e "For reference hostapd and dnsmasq should be disabled and autohotspot enabled"
for service_name in `echo ${SERVICELIST}` ; do

   systemctl is-active $service_name >/dev/null
   if [ "$?" = "0" ] ; then
      echo -e "$service_name is running"
   else
      echo -e "$service_name is NOT running"
   fi
done
# Setup crontab
grep "autohotspot"  /etc/crontab  > /dev/null 2>&1
if [ $? -eq 0 ] ; then
	echo "autohotspot has already been added to crontab"
else
	echo "Adding autohotspot to crontab"
fi

echo "$(date "+%Y %m %d %T %Z"): $scriptname: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "autohotspot_config.sh: script FINISHED"
echo
# ===== End Main =====