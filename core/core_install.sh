#!/bin/bash
#
# This script installs tools necessary for preparing a fresh rasberry pi2 or 3
# Configures rasberry pi for TNC-pi on /dev/ttyAMA0
# Uncomment this statement for debug echos
DEBUG=1
set -u # Exit if there are uninitialized variables.
scriptname="`basename $0`"
source $START_DIR/core/core_functions.sh

# trap ctrl-c and call function ctrl_c()
trap ctrl_c INT

# do upgrade, update outside of script since it can take some time
UPDATE_NOW="true"

# Edit the following list with your favorite text editor and set NONESSENTIAL_PKG to true
NONESSENTIAL_PKG_LIST="mg jed whois mc telnet tmux screen minmicom conspy vin"
NONESSENTIAL_PKG=true # set this to true if you even want non essential packages installed
BUILDTOOLS_PKG_LIST="rsync build-essential autoconf dh-autoreconf automake libtool git libasound2-dev libncurses5-dev i2c-tools libccap2-bin libpcap0.8 libpcap-dev "
REMOVE_PKG_LIST="triggeryhappy libreoffice minecraft-pi wolfram-engine scratch nuscratch"

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
   apt install -y -q --force-yes $BUILDTOOLS_PKG_LIST
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
      apt install -y -q $NONESSENTIAL_PKG_LIST
      if [ "$?" -ne 0 ] ; then
         echo -e "${Red}Non essential packages install failed. ${Reset}Please try this command manually:"
         echo "apt-get install -y $NONESSENTIAL_PKG_LIST"
      fi
   fi
   echo -e "${Cyan}=== Non essential packages installed. ${Reset}"
   echo
fi
}

function remove_pkgs()
{
# Remove unecessary packages
echo -e "${Cyan}=== Removing Unecessary Raspbian Packages ${Reset}"
needs_pkg=false
for pkg_name in `echo ${REMOVE_PKG_LIST}` ; do
   is_pkg_installed $pkg_name
   if [ $? -ne 0 ] ; then
      echo -e "\t ${Blue} core_install.sh: Will Remove $pkg_name program ${Reset}"
      needs_pkg=true
      break
   fi
done
if [ "$needs_pkg" = "true" ] ; then
   echo -e "\t ${Blue} Removing some Unecessary packages ${Reset}"
   apt remove -y -q --purge $REMOVE_PKG_LIST
   if [ "$?" -ne 0 ] ; then
      echo -e "\t ${Red} Removal of "$REMOVE_PKG_LIST" package failed. ${Reset}Please try this command manually:"
      echo -e "\t apt-get remove -y --purge $REMOVE_PKG_LIST"
      exit 1
   fi
   apt clean
   apt autoremove -y
fi
echo -e "${Cyan}=== Unecessary Raspbian packages Removed. ${Reset}"
echo
}
# ===== End Function List =====

# ===== Main =====
clear
sleep 2
echo "$(date "+%x %T"): $scriptname: script START" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW}core_install.sh: script STARTED ${Reset}"
echo

# Be sure we're running as root
chk_root

# Remove Unecessary PI Packages
Remove_pkgs

# Reinstall IPUTILS-PING"
sudo apt-get install --reinstall iputils-ping

# Update OS
if [ "$UPDATE_NOW" = "true" ] ; then
   echo -e "${Cyan} === Check for Rasobuan updates ${Reset}"
   echo -e "${Cyan} === Be Patient... This can take some time ${Reset}"
   apt update -y -q
   apt upgrade -y -q
   apt dist-upgrade -y -q
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
if [ $HAS_BT -eq 0 ]; then
   echo -e "$HARDWARE... Skipping BT Configuration"
else
	echo -e "$HARDWARE... Configuring BT"
	# Modify hciattach.service to configure BT for /dev/ttyS0
	if [ ! -e /lib/systemd/system/hciattach.service ]; then
		cp $START_DIR/systemd/hciattach.service /lib/systemd/system/hciattach.service
		systemctl enable hciattach.service
		systemctl daemon-reload
	else
		echo -e "\t ... hciattach.service already exists."
	fi
	echo -e "${Cyan}=== Configure BT for ttyS0 ${Green}Finished ${Reset}"
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
echo "$(date "+%x %T"): core_install: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW}core_install.sh: script FINISHED ${Reset}"
echo
# ===== End Main =====