#!/bin/bash
#
# Install a host access point
#
# hosts, resolv.conf /etc/network/interfaces /etc/dhcpcd.conf
DEBUG=1
set -u # Exit if there are uninitialized variables.
scriptname="`basename $0`"
SERVICELIST="autohotspot hostapd dnsmasq"

SSID="NOT_SET"

# Required pacakges
PKGLIST="hostapd dnsmasq iptables iptables-persistent"
SERVICELIST="hostapd dnsmasq"




# ===== main
sleep 3
clear
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script START" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "hostap_install.sh: script STARTED"
echo
echo "=== Install hostap on an RPi 3"

# Be sure we're running as root
chk_root

is_rpi3
if [ $? -eq "0" ] ; then
   echo "Not running on an RPi 3 ... exiting"
   exit 1
fi

# check if packages are installed
dbgecho "Check packages: $PKGLIST"

# Fix for iptables-persistent broken
#  https://discourse.osmc.tv/t/failed-to-start-load-kernel-modules/3163/14
#  https://www.raspberrypi.org/forums/viewtopic.php?f=63&t=174648

sed -i -e 's/^#*/#/' /etc/modules-load.d/cups-filters.conf

for pkg_name in `echo ${PKGLIST}` ; do

   is_pkg_installed $pkg_name
   if [ $? -ne 0 ] ; then
      echo "$scriptname: Need to Install $pkg_name program"
      apt-get -qy install $pkg_name
   fi
done

echo "$(date "+%Y %m %d %T %Z"): $scriptname: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "hostap_install.sh: script FINISHED"
echo
