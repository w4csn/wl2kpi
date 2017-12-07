#!/bin/bash
#
# This script configures various ax25 file for use.
#
DEBUG=1
set -u # Exit if there are unitialized variables.
scriptname="`basename $0`"
WL2KPI_INSTALL_LOGFILE="/var/log/wl2kpi_install.log"
wd=$(pwd)

# trap ctrl-c and call function ctrl_c()
trap ctrl_c INT
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== Function List

# function ctrl_c trap handler

function ctrl_c() {
        echo "Exiting script from trapped CTRL-C"
        exit
}

function determin_callsign() {
	echo -n "Please enter your CALLSIGN and press [ENTER]: "
	read callsign1; echo $callsign1 > $callsign
}

function configure_axports() {
	sed -i -e "/k4gbb/ /k4gbb-1/$callsign/ " /etc/ax25/axports
}
#function configure_ax25d() {
#}
#function configure_ax25up() {
#}
# ===== End of Functions list

# =====  Main
sleep 5
clear
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script START" >>$WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script STARTED"

echo
echo -n "Please enter your CALLSIGN and press [ENTER]: "
read callsign; echo $callsign

echo "$(date "+%Y %m %d %T %Z"): $scriptname: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script FINISHED"
echo

