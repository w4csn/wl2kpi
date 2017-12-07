#!/bin/bash
# ax25_install.sh
# It will Download and Install AX25
set -u # Exit if there are uninitialized variables.
scriptname="`basename $0`"
WL2KPI_INSTALL_LOGFILE="/var/log/wl2kpi_install.log"
START_DIR=$(pwd)

#Constants
wd=$(pwd)
uid=$(id -u)
INST_UID=pi
#LIBAX25=linuxax25-master/libax25/
#TOOLS=linuxax25-master/ax25tools/
#APPS=linuxax25-master/ax25apps/
LIBAX25=linuxax25/libax25/
TOOLS=linuxax25/ax25tools/
APPS=linuxax25/ax25apps/
AX25REPO=https://github.com/ve7fet/linuxax25
	

function Chk_Root {
# Check for Root
if [[ $EUID != 0 ]] ; then
   echo "Must be root"
   exit 1
fi
}

function CreateAx25_Folders {
if [ ! -d /usr/local/etc ]; then
	echo "=== Creating file folders for Config files"
	mkdir /usr/local/etc
fi

mkdir /usr/local/etc/ax25

if [ ! -d /usr/local/var/ ]; then
	echo "=== Creating file folders for Data files"
	mkdir /usr/local/var
fi

mkdir /usr/local/var/ax25

if [ ! -d /usr/etc/ax25 ]; then
	rm -rf /etc/ax25
fi

if [ ! -d /usr/local/src ]; then
	echo "=== Creating file folders for source files"
	mkdir /usr/local/src
	mkdir /usr/local/src/ax25
else
  mkdir /usr/local/src/ax25
fi

echo "=== Creating symlinks to standard directories"
ln -s /usr/local/var/ax25/ /var/ax25
ln -s /usr/local/etc/ax25/ /etc/ax25

if [ -f /usr/lib/libax25.a ]; then
	echo -e "\t Moving Old Libax25 files out of the way"
	mkdir /usr/lib/ax25lib
	mv /usr/lib/libax25* /usr/lib/ax25lib/
fi
}


function DownloadAx25 {
cd /usr/local/src/ax25
echo "=== Downloading AX25 archives"
if [ ! -d linuxax25 ]; then
  echo -e "\t Downloading AX25 source"
  git clone $AX25REPO .
else
  echo -e "\t Updating local AX25 source"
  git pull $AX25REPO .
fi
echo "=== Download Finished"
echo
}

function Configure_libax25 {
echo -e "=== Libax25 - Runtime Library files"
echo -e "\t Creating Makefiles for Ax25lib."
cd /usr/local/src/ax25/$LIBAX25
./autogen.sh > liberror.txt 2>&1
./configure >> liberror.txt 2>&1
if [ $? -ne 0 ]; then
    echo -e "\t Libax25 Configuration error - See liberror.txt"
    exit 1
fi
echo "=== Libax25 Config Finished"
echo
}

function CompileAx25 {
echo "=== Compiling AX.25 Libraries"
# Clean old binaries
make clean > /dev/null

# Compile
echo -e "\t Compiling Runtime Lib files"
make > liberror.txt 2>&1
if [ $? -ne 0 ]
    then
    echo -e "\t Libax25 Compile error - See liberror.txt"
    exit 1
else   
    echo -e "\t Libax25 Compiled"	
fi

# Install
echo -e "\t Installing Runtime Lib files"
make install >> liberror.txt 2>&1
if [ $? -ne 0 ]; then
    echo -e "Libax25 Install error - See liberror.txt"
    exit 1
else   
    echo -e "\t Libax25 Installed"
    rm liberror.txt
fi

# AX25 libraries declaration (into ld.so.conf)
echo "/usr/local/lib" >> /etc/ld.so.conf && /sbin/ldconfig

# Ax25-Apps
echo -e "=== Compiling AX.25 Applications"
cd /usr/local/src/ax25/$APPS
echo -e "\t Creating Makefiles for AX25apps"
./autogen.sh >  appserror.txt 2>&1
./configure >> appserror.txt 2>&1

# Clear old binaries
make clean > /dev/null

# Compile Ax25-apps
echo -e "\t Compiling Ax25 apps"
make > appserror.txt 2>&1
if [ $? -ne 0 ]; then
    echo -e "\t Ax25-Apps Compile Error - see appserror.txt"
    exit 1
fi

# Install Ax25-apps
echo -e "\t Installing Ax25 apps"
make  install >> appserror.txt 2>&1
if [ $? -ne 0 ]; then
    echo -e "Ax25-Apps Install Error - see appserror.txt"
    exit 1
else
    echo -e "\t Ax25-apps Installed"
    rm appserror.txt
fi

# Ax25-tools
echo -e "=== Compiling AX.25 Tools"
cd /usr/local/src/ax25/$TOOLS
echo -e "\t Creating Makefiles for AX25tools"
./autogen.sh > toolserror.txt 2>&1
./configure >> toolserror.txt 2>&1

# Clear old binaries
make clean > /dev/null

# Compile Ax.25 tools
echo -e " \t Compiling AX.25 tools"
make > toolserror.txt 2>&1
if [ $? -ne 0 ]; then
    echo -e " ${Red} \t AX.25 tools Compile error - See toolserror.txt ${Reset}"
    exit 1
fi

# Install Ax.25 tools
echo -e "\t Installing AX.25 tools"
make install >> toolserror.txt 2>&1
if [ $? -ne 0 ]; then
    echo -e "\t AX.25 tools Install error - See toolserror.txt"
    exit 1
else
    echo -e "\t AX.25 tools Installed"
    rm toolserror.txt
fi
echo "=== Compile AX.25 Finished"
echo
}

function FinishAx25_Install {
# Set permissions for /usr/local/sbin/ and /usr/local/bin
cd /usr/local/sbin/
chmod 4775 *
cd /usr/local/bin/
chmod 4775 *
echo -e "=== Ax.25 Libraries, Applications and Tools were successfully installed"

echo "=== Enable AX.25 Modules"
grep ax25 /etc/modules > /dev/null 2>&1
if [ $? -ne 0 ]; then
   lsmod | grep -i ax25 > /dev/null 2>&1
   if [ $? -ne 0 ]; then
      echo "... Enabling ax25 module"
      insmod /lib/modules/$(uname -r)/kernel/net/ax25/ax25.ko
   fi
echo "ax25" >> /etc/modules
fi
grep rose /etc/modules > /dev/null 2>&1
if [ $? -ne 0 ]; then
   lsmod | grep -i rose > /dev/null 2>&1
   if [ $? -ne 0 ]; then
      echo "... Enabling rose module"
      insmod /lib/modules/$(uname -r)/kernel/net/rose/rose.ko
   fi
echo "rose" >> /etc/modules
fi
grep mkiss /etc/modules > /dev/null 2>&1
if [ $? -ne 0 ]; then
   lsmod | grep -i mkiss > /dev/null 2>&1
   if [ $? -ne 0 ]; then
      echo "... Enabling mkiss module"
      insmod /lib/modules/$(uname -r)/kernel/net/mkiss/mkiss.ko
   fi
echo "mkiss" >> /etc/modules
fi
echo "=== AX.25 Modules Finished"

# download start up files
cd $wd/k4gbb
wget -qt3 http://k4gbb.no-ip.info/docs/scripts/ax25
wget -qt3 http://k4gbb.no-ip.info/docs/rpi/ax25-up.pi
wget -qt3 http://k4gbb.no-ip.info/docs/scripts/ax25-down
wget -qt3 http://k4gbb.no-ip.info/docs/rpi/axports
wget -qt3 http://k4gbb.no-ip.info/docs/rpi/ax25d.conf
wget -qt3 http://k4gbb.no.info/docs/rpi/calibrate_pi
wget -qt3 http://k4gbb.no.info/docs/rpi/i2ckiss

  
cp $wd/k4gbb/ax25 /etc/init.d/ax25 && ln -s /etc/init.d/ax25 /usr/sbin/ax25
chmod 755 /etc/init.d/ax25
update-rc.d ax25 defaults
# Add ax25 systemd service code here
cd /etc/ax25
cp $wd/k4gbb/ax25-up.pi /etc/ax25/ax25-up 
cp $wd/k4gbb/ax25-down /etc/ax25/ax25-down && chmod 755 ax25-*
cp $wd/k4gbb/axports /etc/ax25/axports
cp $wd/k4gbb/ax25d.conf /etc/ax25/ax25d.conf
touch nrports rsports
}

# Main
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script START" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script STARTED"
echo

Chk_Root
CreateAx25_Folders
DownloadAx25
Configure_libax25
CompileAx25
FinishAx25_Install

echo "$(date "+%Y %m %d %T %Z"): $scriptname: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script FINISHED"
echo
# (End of Script)