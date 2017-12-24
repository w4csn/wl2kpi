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
source $START_DIR/core/core_functions.sh

# ===== Function List =====

function CreateAx25_Folders {
echo -e "\t${Cyan)=== Creating file folders necessary for Ax.25${Reset}"
if [ ! -d "/usr/local/etc" ]; then
   echo -e "\t\t Creating file folders for Config files."
   mkdir /usr/local/etc
fi

if [ ! -d "/usr/local/etc/ax25" ]; then
   mkdir /usr/local/etc/ax25
fi

if [ ! -d "/usr/local/var/" ]; then
	echo -e "\t\t Creating file folders for Data files."
	mkdir /usr/local/var
fi

if [ ! -d "/usr/local/var/ax25" ]; then
   mkdir /usr/local/var/ax25
fi

if [ ! -d "/usr/etc/ax25" ]; then
   rm -rf /etc/ax25
fi

if [ ! -d /usr/local/src ]; then
   echo -e "\t\t Creating /usr/local/src"
   mkdir /usr/local/src
fi
if [ ! -d /usr/local/src ]; then
   echo -e "\t\t Creating /usr/local/src/ax25"
   mkdir /usr/local/src/ax25
fi
mkdir /usr/local/src/ax25
echo -e "\t=== Creating symlinks to standard directories"
if [ ! -L /var/ax25 ]; then
   ln -s /usr/local/var/ax25/ /var/ax25
fi
if [ ! -L /etc/ax25 ]; then
   ln -s /usr/local/etc/ax25/ /etc/ax25
fi

if [ -f /usr/lib/libax25.a ]; then
	echo -e "\t\t Moving Old Libax25 files out of the way"
	mkdir /usr/lib/ax25lib
	mv /usr/lib/libax25* /usr/lib/ax25lib/
fi
}

# ===== End Function List

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
CreateAx25_Folders

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