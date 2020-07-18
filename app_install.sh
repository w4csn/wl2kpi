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
WL2KPI_INSTALL_LOGFILE="/home/pi/Scripts/Temp/wl2kpi_install.log"
START_DIR=$(pwd)
source $START_DIR/core/core_functions.sh
CALLSIGN="N0ONE"
APP_CHOICES="core, rmsgw, plu, pluimap, hostapd autohs"
#APP_SELECT="hostapd"
trap ctrl_c INT

# Color Codes
Reset='\e[0m'
Red='\e[31m'
Green='\e[32m'
Yellow='\e[33m'
Blue='\e[34m'
Cyan='\e[36m'
White='\e[37m'
BluW='\e[37;44m'

# ===== Main =====
clear
# Create Temp dir for logs and flags if it doesn't exist.
if [ -d /home/pi/Scripts/Temp ];
then
	echo \n
else
	mkdir /home/pi/Scripts/Temp
fi

echo "$(date "+%Y %m %d %T %Z"): $scriptname: script START" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW} $scriptname: script STARTED \t${Reset}"
echo
sleep 2

# Be sure we're running as root
chk_root

# OS Check

DIST=$(lsb_release -si)
read -d . VERSION < /etc/debian_version
VER=""
if [ $DIST != "Raspbian" ]; then
	echo -e "${Red}INVALID OS${Reset}"
	echo "RASPBIAN JESSIE, STRETCH or BUSTER IS REQUIRED. PLEASE USE A FRESH IMAGE."
	exit 1
else
	echo -e "${Cyan}OS:${Green} $DIST${Reset}"
	if [ $VERSION -eq "8" ]; then
		VER="Jessie"
		echo -e "${Cyan}Version:${Green} $VER${Reset}"
		
	elif [ $VERSION -eq "9" ]; then
		VER="Stretch"
		echo -e "${Cyan}Version:${Green} $VER${Reset}"
	elif [ $VERSION -eq "10" ]; then
		VER="Buster"
		echo -e "${Cyan}Version:${Green} $VER${Reset}"
	else
		echo -e "${Red}INVALID VERSION${Reset}"	
		echo "RASPBIAN JESSIE, STRETCH or BUSTER IS REQUIRED. PLEASE USE A FRESH IMAGE."
		exit 1
	fi
fi
echo -e "${Cyan}OS${Reset} is ${Yellow}$DIST $VER: ${Green}Proceeding...${Reset}"
sleep 2

# FUTURE -- move OS Check to core_functions.sh, simplifies code
# is_raspbian
#if [ $? -ne "0" ] ; then
#   echo "Not running Raspbian Jessie or Stretch ... exiting"
#   exit 1
#fi


# Check if there are any args on command line
if (( $# != 0 )) ; then
   APP_SELECT=$1
else
   echo -e "${Red}No app chosen from command line${White}... Loading menu ${Reset}"
   sleep 2
fi

while true
do
	clear
	echo -e "${Cyan}OS${Reset} is ${Green}$DIST $VER${Reset}"
	echo ""
	echo -e "\t${Cyan}wl2kpi Install Menu${Reset}"
	echo ""
	echo "" 
	echo -e "${Green}core${Reset}        Install CORE (Do this first!)"
	echo -e "${Green}ax25${Reset}        Install AX.25"
	echo -e "${Green}ax25c${Reset}        Configure AX.25 (Don't do this if installing PiBPQ)"
	echo -e "${Red}Direwolf${Reset}    Install Direwolf"
	echo -e "${Green}pibpq${Reset}      Install PiBPQ"
	echo -e "${Green}rmsgw${Reset}       Install RMS Gateway"
	echo -e "${Red}plu${Reset}         Install paclink-unix  basic "
	echo -e "${Red}pluimap${Reset}     Install paclink-unix with imap "
	echo -e "${Green}hostap${Reset}      Install WiFi Hotspot, Rpi3 or later!"
	echo -e "${Green}autohs${Reset}      Install Autohotspot, Rpi3 or later!"
	echo ""
	echo -e "${Green}bye${Reset}  EXIT PROGRAM"
	echo ""
	echo "wait for each process to finish."
	echo -n "Please enter option:  " 
	
	read APP_SELECT
	echo
	
   # check argument passed to this script
	case $APP_SELECT in
		core)
			echo -e "${BluW}$scriptname: Install core${Reset}"
			# install core files
			pushd $START_DIR/core > /dev/null
			source ./core_install.sh
			source ./core_config.sh
			popd > /dev/null
			echo -e "${BluW}$scriptname: core installation FINISHED${Reset}"
			echo
			read -n 1 -s -r -p "Press any key to continue"
		;;
		ax25)
			echo -e "${BluW}$scriptname: Install AX.25${Reset}"
			# install ax25 files
			pushd $START_DIR/ax25 > /dev/null
			source ./ax25_install.sh
			
			popd > /dev/null
			echo -e "${BluW}$scriptname: AX.25 installation FINISHED${Reset}"
			echo
			read -n 1 -s -r -p "Press any key to continue"
		;;
		ax25c)
			echo -e "${BluW}$scriptname: Configure AX.25${Reset}"
			# Configure ax25 files
			pushd $START_DIR/ax25 > /dev/null
			source ./ax25_config.sh
			popd > /dev/null
			echo -e "${BluW}$scriptname: AX.25 installation FINISHED${Reset}"
			echo
			read -n 1 -s -r -p "Press any key to continue"	
		
		;;
		linbpq)
			echo -e "${BluW}$scriptname: Install PiBPQ${Reset}"
			# install pibpq
			pushd $START_DIR/pibpq > /dev/null
			scriptname="pibpq_install"
			source ./pibpq_install.sh
			scriptname="pibpq_config"
			source ./pibpq_config.sh
			popd > /dev/null
			scriptname="`basename $0`"
			echo -e "${BluW}$scriptname: PiBPQ installation FINISHED${Reset}"
			echo
			read -n 1 -s -r -p "Press any key to continue"
		;;
		rmsgw)
			echo -e "${BluW}$scriptname: Install RMS Gateway${Reset}"
			# install rmsgw
			pushd $START_DIR/rmsgw > /dev/null
			scriptname="rmsgw_install"
			source ./rmsgw_install.sh
			scriptname="rmsgw_config"
			source ./rmsgw_config.sh
			popd > /dev/null
			scriptname="`basename $0`"
			echo -e "${BluW}$scriptname: RMS Gateway installation FINISHED${Reset}"
			echo
			read -n 1 -s -r -p "Press any key to continue"
		;;
		plu)
			echo "$scriptname: Install paclink-unix basic"
			# install paclink-unix basic
			pushd $START_DIR/plu > /dev/null
			source ./plu_install.sh
			popd > /dev/null
			echo "$scriptname: paclink-unix installation FINISHED"
			echo
			read -n 1 -s -r -p "Press any key to continue"
		;;
		pluimap)
			echo "$scriptname: Install paclink-unix with imap"
			# install paclink-unix with imap
			pushd $START_DIR/plu > /dev/null
			source ./pluimap_install.sh
			popd > /dev/null
			echo "$scriptname: paclink-unix with imap installation FINISHED"
			echo
			read -n 1 -s -r -p "Press any key to continue"
		;;
		hostap)
			echo -e "${BluW}$scriptname: Install hostapd${Reset}"
			# install hostapd
			pushd $START_DIR/hostap > /dev/null
			source ./hostap_install.shcore
			source ./hostap_config.sh
			popd > /dev/null
			echo -e "${BluW}$scriptname: hostapd installation FINISHED${Reset}"
			echo
			read -n 1 -s -r -p "Press any key to continue"
		;;
		autohs)
			echo -e "${BluW}$scriptname: Install autohotspot${Reset}"
			# install autohotspot
			pushd $START_DIR/autohs > /dev/null
			source ./autohs_config.sh
			popd > /dev/null
			echo -e "${BluW}$scriptname: autohotspot installation FINISHED${Reset}"
			echo
			read -n 1 -s -r -p "Press any key to continue"
		;;
		uronode)
			echo "$scriptname: Install uronode"
			pushd ../uronode
			source ./uro_install.sh
			popd > /dev/null
			echo "$scriptname: urnode installation FINISHED"
			echo
			read -n 1 -s -r -p "Press any key to continue"
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
			echo "$scriptname: messanger installation FINISHED"
			echo
			read -n 1 -s -r -p "Press any key to continue"
		;;
		bye)
			echo "$(date "+%Y %m %d %T %Z"): $scriptname: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
			echo
			echo -e "${BluW} $scriptname: script FINISHED \t${Reset}"
			echo
			exit 0
		;;
		*)
			echo "Undefined app, must be one of $APP_CHOICES"
			echo "$(date "+%Y %m %d %T %Z"): $scriptname: ($APP_SELECT) script ERROR, undefined app" >> $WL2KPI_INSTALL_LOGFILE
		;;
	esac
done
# ===== End Main =====