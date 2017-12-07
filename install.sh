#!/bin/bash
#
# Install all packages & programs required for:
#  AX25, packet RMS Gateway, paclink-unix
#

set -u # Exit if there are uninitialized variables.
scriptname="`basename $0`"
WL2KPI_INSTALL_LOGFILE="/var/log/wl2kpi_install.log"
START_DIR=$(pwd)

# ===== main
clear
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script START" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script STARTED"
echo

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "$scriptname: Must be root"
   echo "Please type: "
   echo "sudo su"
   echo "and run this script again"
   exit 1
fi

echo -e "$scriptname: Configure RPI for TNC-PI"
./core/core_install.sh
./core/core_config.sh
echo

echo -e "$scriptname: Install ax25 files"
./ax25/ax25_install.sh
echo

#echo -e "$scriptname: Install RMS Gateway"
#pushd ./rmsgw
#source ./rmsgw_install.sh
#popd > /dev/null

#echo -e "$scriptname: Install paclink-unix with imap"
#pushd ./plu
#source ./pluimap_install.sh
#popd > /dev/null

echo "$(date "+%Y %m %d %T %Z"): $scriptname: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script FINISHED"
echo
exit 0