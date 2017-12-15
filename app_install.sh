#!/bin/bash
#
# Expects an argument for which app to install
# Arg can be one of the following:
#	core, rmsgw, plu, pluimap
#
# Uncomment this statement for debug echos
DEBUG=1
set -u # Exit if there are uninitialized variables.
scriptname="`basename $0`"
WL2KPI_INSTALL_LOGFILE="/var/log/wl2kpi_install.log"
START_DIR=$(pwd)
source $START_DIR/core/core_functions.sh
CALLSIGN="N0ONE"
APP_CHOICES="core, rmsgw, plu, pluimap, hostapd"
#APP_SELECT="hostapd"
trap ctrl_c INT


# ===== main
clear
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script START" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script STARTED"
echo

# Be sure we're running as root
chk_root

# OS Check
DIST=$(lsb_release -si)
read -d . VERSION < /etc/debian_version
if [ $DIST -ne "Rasbian" ]; then
	echo "INVALID OS"
	echo "RASPBIAN JESSIE or STRETCH IS REQUIRED. PLEASE USE A FRESH IMAGE."
	exit 1
else
	echo "OS: $DIST"
	if [ $VERSION -eq "8" ]; then
		$VER="Jessie"
		echo "Version: Jessie"
		
	elif [ $VERSION -eq "9" ]; then
		$VER="Stretch"
		echo "Version: Stretch"
	else
		echo "INVALID VERSION"	
		echo "RASPBIAN JESSIE or STRETCH IS REQUIRED. PLEASE USE A FRESH IMAGE."
		exit 1
fi
echo "OS is $DIST $VER : Proceeding..."
sleep 3
# move OS Check to core_functions, simplifies code
# is_raspbian
#if [ $? -eq "0" ] ; then
#   echo "Not running on an RPi 3 ... exiting"
#   exit 1
#fi


# Check if there are any args on command line
if (( $# != 0 )) ; then
   APP_SELECT=$1
else
   echo "No app chosen from command... Loading menu"
fi

while true
do
	clear
	echo ""
	echo "Please select option."
	echo "wait for each process to finish."
	echo "" 
	echo "core)    Install CORE (Do this first!)"
	echo "ax25)    Install AX.25"
	echo "rmsgw)   Install RMS Gateway - Linux"
	echo "plu)     Install paclink-unix  basic "
	echo "pluimap) Install paclink-unix with imap "
	echo "hostap)  Install WiFi Hotspot Rpi3 Only!"
	echo "autohs)  Install Autohotspot Rpi3 Only!"
	echo ""
	echo "bye)  EXIT PROGRAM"
	echo ""
	echo -n "Please select option.  " 
	read APP_SELECT
	echo
	
   # check argument passed to this script
	case $APP_SELECT in
		core)
			echo "$scriptname: Install core"
			# install core files
			pushd ../core
			source ./core_install.sh
			source ./core_config.sh
			popd > /dev/null
			echo "$scriptname: core installation FINISHED"
		;;
		ax25)
			echo "$scriptname: Install AX.25"
			# install ax25 files
			pushd ../ax25
			source ./ax25_install.sh
			source ./ax25_config.sh
			popd > /dev/null
		;;
		rmsgw)
			echo "$scriptname: Install RMS Gateway"
			# install rmsgw
			pushd ../rmsgw
			source ./rmsgw_install.sh
			source ./rmsgw_config.sh
			popd > /dev/null
		;;
		plu)
			echo "$scriptname: Install paclink-unix basic"
			# install paclink-unix basic
			pushd ../plu
			source ./plu_install.sh
			popd > /dev/null
		;;
		pluimap)
			echo "$scriptname: Install paclink-unix with imap"
			# install paclink-unix with imap
			pushd ../plu
			source ./pluimap_install.sh
			popd > /dev/null
		;;
		hostapd)
			echo "$scriptname: Install hostapd"
			# install hostapd
			pushd ../hostap
			source ./hostap_install.sh
			source ./hostap_config.sh
			popd > /dev/null
		;;
		autohs)
			echo "$scriptname: Install autohotspot"
			# install autohotspot
			pushd ../autohotspot
			source ./autohotspot_config.sh
			popd > /dev/null
		;;
		uronode)
			echo "$scriptname: Install uronode"
			pushd ../uronode
			source ./uro_install.sh
			popd > /dev/null
		;;
		messanger)
			# Install pluimap & nixtracker
			echo "$scriptname: Install messanger appliance"
			pushd ../plu
			# Command line arg prevents installation of pluweb.service
			source ./pluimap_install.sh -
			popd > /dev/null
			pushd ../tracker
			echo "Change to normal login user & cd to ~/n7nix/tracker"
			echo "Now run tracker_install.sh"
			## source ./tracker_install.sh
			popd > /dev/null
		;;
		bye)
			echo ""
			echo ""
			echo "73!"
			echo "Scott Newton - W4CSN"
			echo ""
			echo ""
			clear
			exit
		;;
		*)
			echo "Undefined app, must be one of $APP_CHOICES"
			echo "$(date "+%Y %m %d %T %Z"): $scriptname: ($APP_SELECT) script ERROR, undefined app" >> $WL2KPI_INSTALL_LOGFILE
		;;
	esac
done

echo "$(date "+%Y %m %d %T %Z"): $scriptname: ($APP_SELECT) script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: ($APP_SELECT) script FINISHED"
echo