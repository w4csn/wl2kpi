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

uid=$(id -u)
INST_UID=pi
LIBAX25=libax25/
TOOLS=ax25tools/
APPS=ax25apps/
AX25REPO=https://github.com/ve7fet/linuxax25
#GET_K4GBB=false # needs to be replaced with smarter method!
UPD_CONF_FILES=false # If set to false don't replace files in /etc/ax25

# ===== Function List =====

function CreateAx25_Folders {
echo -e "\t${Blue}=== Creating file folders necessary for Ax.25 {Reset}"
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
   echo -e "\t\t Creating file folders for source files."
   mkdir /usr/local/src
   mkdir /usr/local/src/ax25
fi

echo -e "\t${Blue}=== Creating symlinks to standard directories${Reset}"
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


function DownloadAx25 {
cd /usr/local/src/ax25
echo -e "\t${Blue}=== Downloading AX25 archives${Reset}"
if [ ! -d .git ]; then
  echo -e "\t\t Cloning AX25 from $AX25REPO"
  git clone $AX25REPO .
  $UPD_CONF_FILES=true
else
  echo -e "\t\t Updating AX25 from $AX25REPO"
  git pull
fi
echo -e "\t${Green}=== Download Finished${Reset}"
echo
}

function Configure_libax25 {
echo -e "\t${Blue}=== Libax25 - Runtime Library files${Reset}"
echo -e "\t\t Creating Makefiles for Ax25lib."
cd /usr/local/src/ax25/$LIBAX25
./autogen.sh > liberror.txt 2>&1
./configure >> liberror.txt 2>&1
if [ $? -ne 0 ]; then
    echo -e "\t\t Libax25 Configuration ${Red}error${Reset} - See liberror.txt"
    exit 1
fi
echo -e "\t${Green}=== Libax25 Config Finished${Reset}"
echo
}

function CompileAx25 {
echo -e "\t${Blue}=== Compiling AX.25${Reset}"
# Clean old binaries
make clean > /dev/null

# Compile
echo -e "\t\t${Blue} === Compiling AX.25 Libraries"
make > liberror.txt 2>&1
if [ $? -ne 0 ]
    then
    echo -e "\t\t Libax25 Compile ${Red}error${Reset} - See liberror.txt"
	echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: Error Compiling AX.25 Libraries" >> $WL2KPI_INSTALL_LOGFILE
    exit 1
else   
    echo -e "\t\t${Green}AX.25 Libraries Compiled${Reset}"	
fi

# Install
echo -e "\t${Blue}=== Installing Runtime Lib files${Reset}"
make install >> liberror.txt 2>&1
if [ $? -ne 0 ]; then
    echo -e "\t\t AX.25 Libraries Install ${Red}error${Reset} - See liberror.txt"
	echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: Error Installing AX.25 Libraries" >> $WL2KPI_INSTALL_LOGFILE
    exit 1
else   
    echo -e "\t${Green} AX.25 Libraries Installed"
    rm liberror.txt
fi

# AX25 libraries declaration (into ld.so.conf)
echo "/usr/local/lib" >> /etc/ld.so.conf && /sbin/ldconfig

# Ax25-Apps
echo -e "\t${Blue}=== Compiling AX.25 Applications${Reset}"
cd /usr/local/src/ax25/$APPS
echo -e "\t Creating Makefiles for AX25apps"
./autogen.sh >  appserror.txt 2>&1
./configure >> appserror.txt 2>&1

# Clear old binaries
make clean > /dev/null

# Compile Ax25-apps
echo -e "\t\t Compiling Ax25 apps"
make > appserror.txt 2>&1
if [ $? -ne 0 ]; then
    echo -e "\t\t AX.25 Apps Compile ${Red}error${Reset} - see appserror.txt"
	echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: Error Compiling AX.25 Apps" >> $WL2KPI_INSTALL_LOGFILE
    exit 1
fi

# Install Ax25-apps
echo -e "\t\t Installing Ax25 apps"
make  install >> appserror.txt 2>&1
if [ $? -ne 0 ]; then
    echo -e "\t\t AX.25 Apps Install ${Red}error${Reset} - see appserror.txt"
	echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: Error Installing AX.25 Apps" >> $WL2KPI_INSTALL_LOGFILE
    exit 1
else
    echo -e "\t${Green} Ax25-apps Installed${Reset}"
    rm appserror.txt
fi

# Ax25-tools
echo -e "\t${Blue}=== Compiling AX.25 Tools${Reset}"
cd /usr/local/src/ax25/$TOOLS
echo -e "\t\t Creating Makefiles for AX25tools"
./autogen.sh > toolserror.txt 2>&1
./configure >> toolserror.txt 2>&1

# Clear old binaries
make clean > /dev/null

# Compile Ax.25 tools
echo -e " \t\t Compiling AX.25 tools"
make > toolserror.txt 2>&1
if [ $? -ne 0 ]; then
    echo -e " ${Red} \t\t AX.25 tools Compile ${Red}error${Reset} - See toolserror.txt ${Reset}"
	echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: Error Compiling AX.25 Tools" >> $WL2KPI_INSTALL_LOGFILE
    exit 1
fi

# Install Ax.25 tools
echo -e "\t${Blue}=== Installing AX.25 tools${Reset}"
make install >> toolserror.txt 2>&1
if [ $? -ne 0 ]; then
    echo -e "\t\t AX.25 tools Install ${Red}error${Reset} - See toolserror.txt"
	echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: Error Installing AX.25 Tools" >> $WL2KPI_INSTALL_LOGFILE
    exit 1
else
    echo -e "\t\t${Green} AX.25 tools Installed${Reset}"
    rm toolserror.txt
fi
echo -e "\t${Blue}=== Compile AX.25 ${Green}Finished${Reset}"
echo
}

function FinishAx25_Install {
# Set permissions for /usr/local/sbin/ and /usr/local/bin
cd /usr/local/sbin/
chmod 4775 *
cd /usr/local/bin/
chmod 4775 *
echo

echo -e "\t${Blue}=== Enable AX.25 Modules${Reset}"
grep ax25 /etc/modules > /dev/null 2>&1
if [ $? -ne 0 ]; then
   lsmod | grep -i ax25 > /dev/null 2>&1
   if [ $? -ne 0 ]; then
      echo -e "\t\t Enabling ax25 module"
      insmod /lib/modules/$(uname -r)/kernel/net/ax25/ax25.ko
   fi
echo "ax25" >> /etc/modules
fi
grep rose /etc/modules > /dev/null 2>&1
if [ $? -ne 0 ]; then
   lsmod | grep -i rose > /dev/null 2>&1
   if [ $? -ne 0 ]; then
      echo -e"\t\t Enabling rose module"
      insmod /lib/modules/$(uname -r)/kernel/net/rose/rose.ko
   fi
echo "rose" >> /etc/modules
fi
grep mkiss /etc/modules > /dev/null 2>&1
if [ $? -ne 0 ]; then
   echo -e "mkiss" >> /etc/modules
fi
echo -e "\t${Green}=== AX.25 Modules Finished${Reset}"
echo

# Download start up files (Possibly remove - the script depends on specific initial configuration)
#if [ "$GET_K4GBB" = "true" ]; then
#   echo -e "=== Downloading Startup Files"
#   cd $START_DIR/k4gbb
#   wget -qt3 http://k4gbb.no-ip.info/docs/scripts/ax25
#   wget -qt3 http://k4gbb.no-ip.info/docs/rpi/ax25-up.pi
#   wget -qt3 http://k4gbb.no-ip.info/docs/scripts/ax25-down
#   wget -qt3 http://k4gbb.no-ip.info/docs/rpi/axports
#   wget -qt3 http://k4gbb.no-ip.info/docs/rpi/ax25d.conf
#   wget -qt3 http://k4gbb.no.info/docs/rpi/calibrate_pi
#   wget -qt3 http://k4gbb.no.info/docs/rpi/i2ckiss
#   echo "=== Download Finished"
#   echo
#fi


# Setup ax25 SysInitV (Deprecated - Do Not USE!)
#if [ ! -f /etc/init.d/ax25 ]; then
#   cp $START_DIR/k4gbb/ax25 /etc/init.d/ax25 
#   if [ ! -L /usr/sbin/ax25 ]; then 
#		ln -s /etc/init.d/ax25 /usr/sbin/ax25
#   fi
#   echo -e "... Setting up ax25 SysInitV"
#   chmod 755 /etc/init.d/ax25
#   update-rc.d ax25 defaults
#fi

# Setup ax25 systemd service
echo -e "\t${Blue}=== Installing Startup Files${Reset}"
if [ ! -f /etc/systemd/system/ax25.service ]; then
   echo -e "\t\t Setting up ax25 systemd service"
   cp $START_DIR/systemd/ax25.service /etc/systemd/system/ax25.service
   systemctl enable ax25.service
   systemctl daemon-reload
   service ax25 start
   chk_service $service_name
fi

if [ "$UPD_CONF_FILES" = "true" ]; then
echo -e "\t${Blue}=== Installing AX.25 Configuration Files${Reset}"
cd /etc/ax25
cp $START_DIR/k4gbb/ax25-up.pi /etc/ax25/ax25-up 
cp $START_DIR/k4gbb/ax25-down /etc/ax25/ax25-down && chmod 755 ax25-*
cp $START_DIR/k4gbb/axports /etc/ax25/axports
cp $START_DIR/k4gbb/ax25d.conf /etc/ax25/ax25d.conf
touch nrports rsports
fi

echo -e "=== Install Finished"
}
# ===== End Functions list =====

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
DownloadAx25

# Configure source files
Configure_libax25

# Compile source
CompileAx25

# Clean up and install startup files
FinishAx25_Install

echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: AX.25 Installation Completed" >> $WL2KPI_INSTALL_LOGFILE
echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW} ax25_install.sh: script FINISHED ${Reset}"
echo
# ===== End Main =====