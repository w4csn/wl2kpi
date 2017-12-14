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
source ./core/core_functions.sh
CALLSIGN="N0ONE"
APP_CHOICES="core, rmsgw, plu, pluimap, hostapd"
APP_SELECT="hostapd"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== main
clear
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script START" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script STARTED"
echo

# Be sure we're running as root
chk_root

# Check if there are any args on command line
if (( $# != 0 )) ; then
   APP_SELECT=$1
else
   echo "No app chosen from command arg, so installing Hostapd"
fi

   # check argument passed to this script
case $APP_SELECT in
   core)
      echo "$scriptname: Install core"

      # install systemd files
      pushd ../systemd
      /bin/bash ./install.sh
      popd > /dev/null

      echo "core installation FINISHED"
   ;;
   rmsgw)
      echo "$scriptname: Install RMS Gateway"
      # install rmsgw
      pushd ../rmsgw
      source ./install.sh
      popd > /dev/null
   ;;
   plu)
      # install paclink-unix basic
      echo "$scriptname: Install paclink-unix"
      pushd ../plu
      source ./plu_install.sh
      popd > /dev/null

   ;;
   pluimap)
      echo "$scriptname: Install paclink-unix with imap"
      pushd ../plu
      source ./pluimap_install.sh
      popd > /dev/null
   ;;
   uronode)
      echo "$scriptname: Install uronode"
      pushd ../uronode
      source ./uro_install.sh
      popd > /dev/null
   ;;
   hostapd)
      echo "$scriptname: Install hostapd"
      pushd ../hostap
      source ./hostap_install.sh
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

##      source ./tracker_install.sh
      popd > /dev/null
   ;;

   *)
      echo "Undefined app, must be one of $APP_CHOICES"
      echo "$(date "+%Y %m %d %T %Z"): app install ($APP_SELECT) script ERROR, undefined app" >> $WL2KPI_INSTALL_LOGFILE
      exit 1
   ;;
esac

echo "$(date "+%Y %m %d %T %Z"): app install ($APP_SELECT) script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "app install ($APP_SELECT) script FINISHED"
echo