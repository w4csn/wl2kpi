#!/bin/bash
#
# Install all packages & programs required for:
#  AX25, packet RMS Gateway, paclink-unix
#

set -u # Exit if there are uninitialized variables.
scriptname="`basename $0`"
WL2KPI_INSTALL_LOGFILE="/var/log/wl2kpi_install.log"
START_DIR=$(pwd)
source $START_DIR/core/core_functions.sh

# ===== main
clear
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script START" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script STARTED"
echo


# Be sure we're running as root
chk_root

echo -e "$scriptname: Configure RPI for TNC-PI"
pushd ../core
#source ./core_install.sh
#source ./core_config.sh
popd > /dev/null
echo

echo -e "$scriptname: Install ax25 files"
pushd ../ax25
#source ./ax25_install.sh
#source ./ax25_config.sh
popd > /dev/null
echo

echo -e "$scriptname: Install RMS Gateway"
pushd ../rmsgw
#source ./rmsgw_install.sh
source ./rmsgw_config.sh
popd > /dev/null
echo

#echo -e "$scriptname: Install paclink-unix with imap"
#pushd ./plu
#source ./pluimap_install.sh
#popd > /dev/null

echo "$(date "+%Y %m %d %T %Z"): $scriptname: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script FINISHED"
echo
exit 0