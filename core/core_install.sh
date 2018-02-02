#!/bin/bash
#
# This script installs tools necessary for preparing a fresh rasberry pi2 or 3
# Configures rasberry pi for TNC-pi on /dev/ttyAMA0
# Uncomment this statement for debug echos
DEBUG=1
set -u # Exit if there are uninitialized variables.
scriptname="`basename $0`"
source $START_DIR/core/core_functions.sh

# do upgrade, update outside of script since it can take some time
UPDATE_NOW=false

# Edit the following list with your favorite text editor and set NONESSENTIAL_PKG to true
NONESSENTIAL_PKG_LIST="mg jed whois mc telnet tmux"

NONESSENTIAL_PKG=true # set this to true if you even want non essential packages installed

BUILDTOOLS_PKG_LIST="rsync build-essential autoconf dh-autoreconf automake libtool git libasound2-dev libncurses5-dev"


# trap ctrl-c and call function ctrl_c()
trap ctrl_c INT

# ===== Function List =====

function install_build_tools()
{
# build tools install section
echo -e "${Cyan}=== Check Build Tools ${Reset}"
needs_pkg=false
for pkg_name in `echo ${BUILDTOOLS_PKG_LIST}` ; do
   is_pkg_installed $pkg_name
   if [ $? -ne 0 ] ; then
      echo -e "\t ${Blue} core_install.sh: Will Install $pkg_name program ${Reset}"
      needs_pkg=true
      break
   fi
done
if [ "$needs_pkg" = "true" ] ; then
   echo -e "\t ${Blue} Installing some build tool packages ${Reset}"
   apt-get install -y -q $BUILDTOOLS_PKG_LIST
   if [ "$?" -ne 0 ] ; then
      echo -e "\t ${Red} Build tools package install failed. ${Reset}Please try this command manually:"
      echo -e "\t apt-get install -y $BUILDTOOLS_PKG_LIST"
      exit 1
   fi
fi
echo -e "${Cyan}=== Build Tools packages installed. ${Reset}"
echo
}

function install_nonessential_pkgs ()
{
# NON essential package install section
if [ "$NONESSENTIAL_PKG" = "true" ] ; then
   # Check if non essential packages have been installed
   echo -e "${Cyan}=== Check for non essential packages"
   needs_pkg=false
   for pkg_name in `echo ${NONESSENTIAL_PKG_LIST}` ; do
      is_pkg_installed $pkg_name
      if [ $? -ne 0 ] ; then
         echo -e "${Blue} core_install.sh: Will Install $pkg_name program${Reset}"
         needs_pkg=true
         break
      fi
   done
   if [ "$needs_pkg" = "true" ] ; then
      echo -e "Installing some non essential packages"
      apt-get install -y -q $NONESSENTIAL_PKG_LIST
      if [ "$?" -ne 0 ] ; then
         echo -e "${Red}Non essential packages install failed. ${Reset}Please try this command manually:"
         echo "apt-get install -y $NONESSENTIAL_PKG_LIST"
      fi
   fi
   echo -e "${Cyan}=== Non essential packages installed. ${Reset}"
   echo
fi
}
# ===== End Function List =====

# ===== Main =====
clear
sleep 2
echo "$(date "+%Y %m %d %T %Z"): core_install.sh: script START" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW}core_install.sh: script STARTED ${Reset}"
echo

# Be sure we're running as root
chk_root

# Update OS
if [ "$UPDATE_NOW" = "true" ] ; then
   echo -e "${Cyan} === Check for updates ${Reset}"
   apt-get update -y -q
   apt-get upgrade -y -q
   echo -e "${Cyan}=== updates ${Green}finished ${Reset}"
   echo
fi

# Check for Kernel Update
if [ ! -d /lib/modules/$(uname -r)/ ]; then
   echo "Modules directory /lib/modules/$(uname -r)/ does NOT exist"
   echo "Probably need to reboot, type: "
   echo "shutdown -r now"
   echo "and log back in"
   exit 1
fi

install_build_tools
install_nonessential_pkgs

# Add Kernel modules
echo -e "${Cyan}=== Enable Kernel Modules ${Reset}"
grep i2c-dev /etc/modules > /dev/null 2>&1
if [ $? -ne 0 ]; then
   echo "i2c-dev" >> /etc/modules
fi
echo -e "${Cyan}=== Enable Kernel Modules ${Green}Finished. ${Reset}"
echo

# If Using RPi3 reconfigure BT
echo -e "${Cyan}=== Configure BT for ttyS0 ${Reset}"
is_rpi3 > /dev/null 2>&1
if [ $? -eq "0" ]; then
   echo -e "Not running on an RPi 3... Skipping BT Configuration"
else
	# Modify hciattach.service to configure BT for /dev/ttyS0
	if [ ! -e /lib/systemd/system/hciattach.service ]; then
		cp $START_DIR/systemd/hciattach.service /lib/systemd/system/hciattach.service
		systemctl enable hciattach.service
		systemctl daemon-reload
	else
		echo -e "\t ... hciattach.service already exists."
	fi
	echo -e "${cyan}=== Configure BT for ttyS0 ${Green}Finished ${Reset}"
	echo
fi

# Modify config.txt to enable uart and if using rpi3 move BT to miniuart
echo -e "${Cyan}=== Modify /boot/config.txt ${Reset}"
CONFIGDIR=/boot/config.txt
grep "# User Mods" $CONFIGDIR > /dev/null 2>&1
if [ $? -ne 0 ]; then
   echo "# User Mods" >> $CONFIGDIR
fi
grep "enable_uart=1" $CONFIGDIR > /dev/null 2>&1
if [ $? -ne 0 ]; then
   echo "enable_uart=1" >> $CONFIGDIR
fi
is_rpi3 > /dev/null 2>&1
if [ $? -ne "0" ]; then
	grep "dtoverlay=pi3-miniuart-bt" $CONFIGDIR >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "dtoverlay=pi3-miniuart-bt" >> $CONFIGDIR
	fi
	grep "core_freq=250" $CONFIGDIR > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "core_freq=250" >> $CONFIGDIR
	fi
fi
echo -e "${Cyan}=== Modify /boot/config.txt ${Green}Finished. ${Reset}"
echo

# Disable Serial Console
echo -e "${Cyan}=== Remove Serial Console from /boot/cmdline.txt ${Reset}"
sed -i -e "/console/ s/console=serial0,115200// " /boot/cmdline.txt
echo -e "${Cyan}=== Remove Serial Console ${Green}Finished. ${Reset}"
echo

cd $START_DIR/core
echo "$(date "+%Y %m %d %T %Z"): core_install: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW}core_install.sh: script FINISHED ${Reset}"
echo
# ===== End Main =====