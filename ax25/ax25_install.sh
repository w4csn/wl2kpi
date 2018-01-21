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
SRC_DIR="/usr/local/src/ax25"
#GET_K4GBB=false # needs to be replaced with smarter method!
UPD_CONF_FILES=false # If set to false don't replace files in /etc/ax25

# ===== Function List =====

function CreateAx25_Folders {
echo -e "${Cyan}=== Creating folders necessary for AX.25${Reset}"
if [ ! -d "/usr/local/etc" ]; then
   echo -e "\t Creating folders for Config files."
   mkdir /usr/local/etc
fi

if [ ! -d "/usr/local/etc/ax25" ]; then
   mkdir /usr/local/etc/ax25
fi

if [ ! -d "/usr/local/var/" ]; then
	echo -e "\t Creating file folders for Data files."
	mkdir /usr/local/var
fi

if [ ! -d "/usr/local/var/ax25" ]; then
   mkdir /usr/local/var/ax25
fi

if [ ! -d "/usr/etc/ax25" ]; then
   rm -rf /etc/ax25
fi

if [ ! -d /usr/local/src ]; then
   echo -e "\t Creating folder for AX.25 source code"
   mkdir /usr/local/src
fi
if [ ! -d /usr/local/src/ax25 ]; then
   mkdir /usr/local/src/ax25
fi
echo -e "${Cyan}=== AX.25 Folder Creation ${Green}Finished${Reset}"
echo
echo -e "${Cyan}=== Creating symlinks to standard directories${Reset}"
if [ ! -L /var/ax25 ]; then
    ln -s /usr/local/var/ax25/ /var/ax25
fi
if [ ! -L /etc/ax25 ]; then
	ln -s /usr/local/etc/ax25/ /etc/ax25
fi


if [ -f /usr/lib/libax25.a ]; then
	echo -e "${Cyan}=== Moving Old Libax25 files out of the way${Reset}"
	mkdir /usr/lib/ax25lib
	mv /usr/lib/libax25* /usr/lib/ax25lib/
fi
echo -e "${Cyan}=== AX.25 symlinks ${Green}Finished${Reset}"
echo
}


function Download_Ax25 {
echo -e "${Cyan}=== Download AX25 from Source${Reset}"
if [ ! -d $SRC_DIR ] ; then
   mkdir -p $SRC_DIR
   if [ "$?" -ne 0 ] ; then
      echo -e "\t${Red}ERROR${Reset}: Problems creating source directory: $SRC_DIR"
      exit 1
   fi
fi
cd $SRC_DIR
if [ ! -d .git ]; then
  echo -e " Cloning AX25 from $AX25REPO"
  git clone $AX25REPO .
  UPD_CONF_FILES=true
else
  echo -e " Updating AX25 from $AX25REPO"
  git pull
fi
echo -e "${Cyan}=== Download ${Green}Finished${Reset}"
echo
}

function Configure_libax25 {
echo -e "${Cyan}=== Libax25 - Runtime Library files${Reset}"
echo -e " Preparing to create makefiles for Ax25 Libraries"
cd /usr/local/src/ax25/$LIBAX25
echo -e " Creating Makefiles for AX.25 Libraries, Please Wait..."
(./autogen.sh > liberror.txt 2>&1) &
spinner $!
(./configure >> liberror.txt 2>&1) &
spinner $!
echo -e " Finished!"
if [ $? -ne 0 ]; then
	echo
    echo -e "${Cyan}=== Libax25 Configuration ${Red}error${Reset} - See liberror.txt"
    exit 1
fi
echo
echo -e "${Cyan}=== Libax25 ${Green}Finished${Reset}"
echo
}

function Compile_Ax25 {
echo -e "${Cyan}=== Compiling AX.25${Reset}"

# Remove old binaries
make clean > /dev/null

# Compile ax25 libraries
echo -e " Preparing to Compile AX.25 Libraries"
echo -e " Compiling, Please Wait..."
(make > liberror.txt 2>&1) &
spinner $!
echo -e " Finished!"
if [ $? -ne 0 ]
    then
    echo -e " Libax25 Compile ${Red}error${Reset} - See liberror.txt"
	echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: Error Compiling AX.25 Libraries" >> $WL2KPI_INSTALL_LOGFILE
    exit 1
else   
    echo -e "${Green}AX.25 Libraries Compiled${Reset}"	
fi

# Install ax25 libraries
echo -e " Preparing to install AX.25 Libraries"
echo -e " Installing, Please Wait..."
(make install >> liberror.txt 2>&1) &
spinner $!
echo -e " Finished!"
if [ $? -ne 0 ]; then
    echo -e " AX.25 Libraries Install ${Red}error${Reset} - See liberror.txt"
	echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: Error Installing AX.25 Libraries" >> $WL2KPI_INSTALL_LOGFILE
    exit 1
else   
    echo -e "${Green} AX.25 Libraries Installed${Reset}"
    rm liberror.txt
fi

# AX25 libraries declaration (into ld.so.conf)
echo "/usr/local/lib" >> /etc/ld.so.conf && /sbin/ldconfig

# Ax25-Apps
echo -e "\t Preparing to compile AX.25 Applications"
cd /usr/local/src/ax25/$APPS
echo -e "\t\t Creating Makefiles for AX.25 Applications, Please Wait..."
(./autogen.sh >  appserror.txt 2>&1) &
spinner $!
(./configure >> appserror.txt 2>&1) &
spinner $!
echo -e "\t\t Finished!"

# Remove old binaries
make clean > /dev/null

# Compile Ax25-apps
echo -e "\t\t Compiling AX.25 Applications, Please Wait..."
(make > appserror.txt 2>&1) &
spinner $!
echo -e "\t\t Finished!"
if [ $? -ne 0 ]; then
    echo -e "\t AX.25 Applications Compile ${Red}error${Reset} - see appserror.txt"
	echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: Error Compiling AX.25 Apps" >> $WL2KPI_INSTALL_LOGFILE
    exit 1
fi

# Install Ax25-apps
echo -e "\t\t Installing AX.25 Applications, Please Wait..."
(make  install >> appserror.txt 2>&1) &
spinner $!
echo -e "\t\t Finished!"
if [ $? -ne 0 ]; then
    echo -e "\t AX.25 Applications Install ${Red}error${Reset} - see appserror.txt"
	echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: Error Installing AX.25 Apps" >> $WL2KPI_INSTALL_LOGFILE
    exit 1
else
    echo -e "\t${Green} AX.25-apps Installed${Reset}"
    rm appserror.txt
fi

# Ax25-tools
echo -e "\t Preparing to Compile AX.25 Tools"
cd /usr/local/src/ax25/$TOOLS
echo -e "\t\t Creating Makefiles for AX.25 Tools, Please Wait..."
(./autogen.sh > toolserror.txt 2>&1) &
spinner $!
(./configure >> toolserror.txt 2>&1) &
spinner $!
echo -e "\t\t Finished!"

# Remove old binaries
make clean > /dev/null

# Compile Ax.25 tools
echo -e " \t\t Compiling AX.25 Tools, Please Wait..."
(make > toolserror.txt 2>&1) &
spinner $!
echo -e "\t\t Finished!"
if [ $? -ne 0 ]; then
    echo -e "\t AX.25 Tools Compile ${Red}error${Reset} - See toolserror.txt ${Reset}"
	echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: Error Compiling AX.25 Tools" >> $WL2KPI_INSTALL_LOGFILE
    exit 1
fi

# Install Ax.25 tools
echo -e "\t\t Installing AX.25 Tools. Please Wait..."
(make install >> toolserror.txt 2>&1) &
spinner $!
echo -e "\t\t Finished!"
if [ $? -ne 0 ]; then
    echo -e "\t AX.25 Tools Install ${Red}error${Reset} - See toolserror.txt"
	echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: Error Installing AX.25 Tools" >> $WL2KPI_INSTALL_LOGFILE
    exit 1
else
    echo -e "\t${Green} AX.25 tools Installed${Reset}"
    rm toolserror.txt
fi
echo -e "${Cyan}=== Compile AX.25 ${Green}Finished${Reset}"
echo
}

function FinishAx25_Install {
# Set permissions for /usr/local/sbin/ and /usr/local/bin
cd /usr/local/sbin/
chmod 4775 *
cd /usr/local/bin/
chmod 4775 *
echo

echo -e "${Cyan}=== Preparing to enable AX.25 modules${Reset}"
grep ax25 /etc/modules > /dev/null 2>&1
if [ $? -ne 0 ]; then
   lsmod | grep -i ax25 > /dev/null 2>&1
   if [ $? -ne 0 ]; then
      echo -e "\t Enabling AX.25 module"
      insmod /lib/modules/$(uname -r)/kernel/net/ax25/ax25.ko
   fi
echo "ax25" >> /etc/modules
fi
grep rose /etc/modules > /dev/null 2>&1
if [ $? -ne 0 ]; then
   lsmod | grep -i rose > /dev/null 2>&1
   if [ $? -ne 0 ]; then
      echo -e"\t Enabling rose module"
      insmod /lib/modules/$(uname -r)/kernel/net/rose/rose.ko
   fi
echo "rose" >> /etc/modules
fi
grep mkiss /etc/modules > /dev/null 2>&1
if [ $? -ne 0 ]; then
   echo -e"\t Enabling mkiss module"
   echo -e "mkiss" >> /etc/modules
fi
echo -e "${Cyan}=== AX.25 Modules ${Green}Finished${Reset}"
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
echo -e "${Cyan}=== Installing Startup Files${Reset}"
if [ ! -f /etc/systemd/system/ax25.service ]; then
   echo -e "\t Setting up ax25 systemd service"
   cp $START_DIR/systemd/ax25.service /etc/systemd/system/ax25.service
   systemctl enable ax25.service
   systemctl daemon-reload
   service ax25 start
   chk_service ax25
fi
echo -e "${Cyan}=== Startup Files ${Green}Installed${Reset}"
echo
if [ "$UPD_CONF_FILES" = "true" ]; then
echo -e "${Cyan}=== Installing AX.25 Configuration Files${Reset}"
cd /etc/ax25
cp $START_DIR/k4gbb/ax25-up.pi /etc/ax25/ax25-up 
cp $START_DIR/k4gbb/ax25-down /etc/ax25/ax25-down && chmod 755 ax25-*
cp $START_DIR/k4gbb/axports /etc/ax25/axports
cp $START_DIR/k4gbb/ax25d.conf /etc/ax25/ax25d.conf
touch nrports rsports
fi
echo -e "${Cyan}=== Configuration Files ${Green}Installed${Reset}"
echo
echo -e "${Green}=== AX.25 Installation Finished${Reset}"
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
Download_Ax25

# Configure source files
Configure_libax25

# Compile source
Compile_Ax25

# Clean up and install startup files
FinishAx25_Install

cd $START_DIR/ax25
echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: AX.25 Installation Completed" >> $WL2KPI_INSTALL_LOGFILE
echo "$(date "+%Y %m %d %T %Z"): ax25_install.sh: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW} ax25_install.sh: script FINISHED ${Reset}"
echo
# ===== End Main =====