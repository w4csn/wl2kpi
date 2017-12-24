#!/bin/bash
# ax25_install.sh
# It will Download and Install AX25
# Parts taken from RMS-Upgrade-181 script Updated 10/30/2014
# (https://groups.yahoo.com/neo/groups/LinuxRMS/files)
# by C Schuman, K4GBB k4gbb1gmail.com
#
DEBUG=1
set -u # Exit if there are uninitialized variables.
scriptname="`basename $0`"
START_DIR=/home/pi/wl2kpi
WL2KPI_INSTALL_LOGFILE=/var/log/wl2kpi.log
source $START_DIR/core/core_functions.sh
# ===== Main =====
sleep 3
clear
echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: script START" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW} ax25-install.sh: script STARTED ${Reset}"
echo

# Be sure we're running as root
chk_root

# Set up folder structure
#CreateAx25_Folders

# Download source files
#DownloadAx25

# Configure source files
#Configure_libax25

# Compile source
#CompileAx25

# Clean up and install startup files
#FinishAx25_Install

echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: AX.25 Installation Completed" >> $WL2KPI_INSTALL_LOGFILE
echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW} ax25_install.sh: script FINISHED ${Reset}"
echo
# ===== End Main =====