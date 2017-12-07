#!/bin/bash
#
# Run this after copying a fresh compass file system image
#
# Uncomment this statement for debug echos
DEBUG=1
set -u # Exit if there are uninitialized variables.
scriptname="`basename $0`"
WL2KPI_INSTALL_LOGFILE="/var/log/wl2kpi_install.log"
START_DIR=$(pwd)

# do upgrade, update outside of script since it can take some time
UPDATE_NOW=true

# Edit the following list with your favorite text editor and set NONESSENTIAL_PKG to true
NONESSENTIAL_PKG_LIST="mg jed whois mc"

NONESSENTIAL_PKG=true # set this to true if you even want non essential packages installed

BUILDTOOLS_PKG_LIST="rsync build-essential autoconf dh-autoreconf automake libtool git libasound2-dev libncurses5-dev"

# If the following is set to true, bluetooth will be moved to miniuart.
#Unfinished. DO NOT SET TO TRUE!
SERIAL_CONSOLE=false

# trap ctrl-c and call function ctrl_c()
trap ctrl_c INT
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== function ctrl_c trap handler

function ctrl_c() {
        echo "Exiting script from trapped CTRL-C"
	exit
}

# ===== function install build tools

function install_build_tools() {
# build tools install section

echo "=== Check Build Tools"
needs_pkg=false

for pkg_name in `echo ${BUILDTOOLS_PKG_LIST}` ; do

   is_pkg_installed $pkg_name
   if [ $? -ne 0 ] ; then
      echo "$scriptname: Will Install $pkg_name program"
      needs_pkg=true
      break
   fi
done

if [ "$needs_pkg" = "true" ] ; then
   echo -e "Installing some build tool packages"

   apt-get install -y -q $BUILDTOOLS_PKG_LIST
   if [ "$?" -ne 0 ] ; then
      echo "Build tools package install failed. Please try this command manually:"
      echo "apt-get install -y $BUILDTOOLS_PKG_LIST"
      exit 1
   fi
fi

echo "=== Build Tools packages installed."
}

# ===== function install nonessential packages

function install_nonessential_pkgs () {
# NON essential package install section

if [ "$NONESSENTIAL_PKG" = "true" ] ; then
   # Check if non essential packages have been installed
   echo "=== Check for non essential packages"
   needs_pkg=false

   for pkg_name in `echo ${NONESSENTIAL_PKG_LIST}` ; do

      is_pkg_installed $pkg_name
      if [ $? -ne 0 ] ; then
         echo "$scriptname: Will Install $pkg_name program"
         needs_pkg=true
         break
      fi
   done

   if [ "$needs_pkg" = "true" ] ; then
      echo -e "Installing some non essential packages"

      apt-get install -y -q $NONESSENTIAL_PKG_LIST
      if [ "$?" -ne 0 ] ; then
         echo "Non essential packages install failed. Please try this command manually:"
         echo "apt-get install -y $NONESSENTIAL_PKG_LIST"
      fi
   fi

   echo "Non essential packages installed."
fi
}

# ===== main

echo "$(date "+%Y %m %d %T %Z"): $scriptname: script START" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script STARTED"
echo

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "Must be root"
    exit 1
fi


if [ "$UPDATE_NOW" = "true" ] ; then
   echo "=== Check for updates"
   apt-get update -y -q
   apt-get upgrade -y -q
   echo "=== updates finished"
   echo
fi

install_build_tools

install_nonessential_pkgs


if [ ! -d /lib/modules/$(uname -r)/ ] ; then
   echo "Modules directory /lib/modules/$(uname -r)/ does NOT exist"
   echo "Probably need to reboot, type: "
   echo "shutdown -r now"
   echo "and log back in"
   exit 1
fi

echo "=== Enable Modules"
grep ax25 /etc/modules > /dev/null 2>&1
if [ $? -ne 0 ] ; then
	lsmod | grep -i ax25 > /dev/null 2>&1
if [ $? -ne 0 ] ; then
   echo "... Enable ax25 module"
   insmod /lib/modules/$(uname -r)/kernel/net/ax25/ax25.ko
fi

# Add Kernel modules
cat << EOT >> /etc/modules
i2c-dev
EOT
fi

# Modify hciattach.service to configure BT for /dev/ttyS0
echo "=== Configure BT for ttyS0"
if [ ! -e /lib/systemd/system/hciattach.service ]; then
	cp $START_DIR/rpi/hciattach.service /lib/systemd/system/hciattach.service
else
	cat << EOT >> /lib/systemd/system/hciattach.service
[Unit]
ConditionPathIsDirectory=/proc/device-tree/soc/gpio@7e200000/bt_pins
Before=bluetooth.service
After=dev-ttyS0.device

[Service]
Type=forking
ExecStart=/usr/bin/hciattach /dev/ttyS0 bcm43xx 921600 noflow -

[Install]
WantedBy=multi-user.target
EOT
fi


# Modify config.txt
echo "=== Modify /boot/config.txt"
#grep "force_turbo" /boot/config.txt > /dev/null 2>&1
cat << EOT >> /boot/config.txt
# User Mods
enable_uart=1
dtoverlay=pi-miniuart-bt
core_Frequ=250
EOT
sed -i -e "/console/ s/console=serial0,115200// " /boot/cmdline.txt
# To enable serial console disable bluetooth
#  and change console to ttyS0. Maybe? not sure how to handle yet.
if [ "$SERIAL_CONSOLE" = "true" ] ; then
   echo "=== Disabling Bluetooth & enabling serial console"
   sed -i -e "/dtoverlay/ s/dtoverlay=pi-miniuart-bt/dtoverlay=pi-disable-bt/" /boot/config.txt
   #sed -i -e "/console/ s/console=serial0/console=ttyAMA0,115200/" /boot/cmdline.txt
fi

echo "$(date "+%Y %m %d %T %Z"): $scriptname: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script FINISHED"
echo
