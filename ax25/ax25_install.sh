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
LIBAX25=libax25/
TOOLS=ax25tools/
APPS=ax25apps/
AX25REPO=https://github.com/ve7fet/linuxax25
GET_K4GBB=false

function Chk_Root {
# Check for Root
if [[ $EUID != 0 ]] ; then
   echo -e "Must be root"
   exit 1
fi
}

function CreateAx25_Folders {
if [ ! -d "/usr/local/etc" ]; then
   echo -e "=== Creating file folders for Config files"
   mkdir /usr/local/etc
fi

if [ ! -d "/usr/local/etc/ax25" ]; then
   mkdir /usr/local/etc/ax25
fi

if [ ! -d "/usr/local/var/" ]; then
	echo -e "=== Creating file folders for Data files"
	mkdir /usr/local/var
fi

if [ ! -d "/usr/local/var/ax25" ]; then
   mkdir /usr/local/var/ax25
fi

if [ ! -d "/usr/etc/ax25" ]; then
   rm -rf /etc/ax25
fi

if [ ! -d /usr/local/src ]; then
   echo -e "=== Creating file folders for source files"
   mkdir /usr/local/src
   mkdir /usr/local/src/ax25
fi

echo -e "=== Creating symlinks to standard directories"
if [ ! -L /var/ax25 ]; then
   ln -s /usr/local/var/ax25/ /var/ax25
fi
if [ ! -L /etc/ax25 ]; then
   ln -s /usr/local/etc/ax25/ /etc/ax25
fi

if [ -f /usr/lib/libax25.a ]; then
	echo -e "\t Moving Old Libax25 files out of the way"
	mkdir /usr/lib/ax25lib
	mv /usr/lib/libax25* /usr/lib/ax25lib/
fi
}


function DownloadAx25 {
cd /usr/local/src/ax25
echo -e "=== Downloading AX25 archives"
if [ ! -d .git ]; then
  echo -e "\t Cloning AX25 from $AX25REPO"
  git clone $AX25REPO .
else
  echo -e "\t Updating AX25 from $AX25REPO"
  git pull
fi
echo -e "=== Download Finished"
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
echo -e "=== Libax25 Config Finished"
echo
}

function CompileAx25 {
echo -e "=== Compiling AX.25 Libraries"
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
echo -e "=== Compile AX.25 Finished"
echo
}

function FinishAx25_Install {
# Set permissions for /usr/local/sbin/ and /usr/local/bin
cd /usr/local/sbin/
chmod 4775 *
cd /usr/local/bin/
chmod 4775 *
echo -e "=== Ax.25 Libraries, Applications and Tools were successfully installed"
echo

echo -e "=== Enable AX.25 Modules"
grep ax25 /etc/modules > /dev/null 2>&1
if [ $? -ne 0 ]; then
   lsmod | grep -i ax25 > /dev/null 2>&1
   if [ $? -ne 0 ]; then
      echo -e "... Enabling ax25 module"
      insmod /lib/modules/$(uname -r)/kernel/net/ax25/ax25.ko
   fi
echo "ax25" >> /etc/modules
fi
grep rose /etc/modules > /dev/null 2>&1
if [ $? -ne 0 ]; then
   lsmod | grep -i rose > /dev/null 2>&1
   if [ $? -ne 0 ]; then
      echo -e"... Enabling rose module"
      insmod /lib/modules/$(uname -r)/kernel/net/rose/rose.ko
   fi
echo "rose" >> /etc/modules
fi
grep mkiss /etc/modules > /dev/null 2>&1
if [ $? -ne 0 ]; then
   echo -e "mkiss" >> /etc/modules
fi
echo -e "=== AX.25 Modules Finished"
echo

# download start up files
if [ "$GET_K4GBB" = "true" ]; then
   echo -e "=== Downloading Startup Files"
   cd $wd/k4gbb
   wget -qt3 http://k4gbb.no-ip.info/docs/scripts/ax25
   wget -qt3 http://k4gbb.no-ip.info/docs/rpi/ax25-up.pi
   wget -qt3 http://k4gbb.no-ip.info/docs/scripts/ax25-down
   wget -qt3 http://k4gbb.no-ip.info/docs/rpi/axports
   wget -qt3 http://k4gbb.no-ip.info/docs/rpi/ax25d.conf
   wget -qt3 http://k4gbb.no.info/docs/rpi/calibrate_pi
   wget -qt3 http://k4gbb.no.info/docs/rpi/i2ckiss
   echo "=== Download Finished"
   echo
fi

echo -e "=== Installing Startup Files"
cp $wd/k4gbb/ax25 /etc/init.d/ax25 
if [ ! -L /usr/sbin/ax25 ]; then 
   ln -s /etc/init.d/ax25 /usr/sbin/ax25
fi
chmod 755 /etc/init.d/ax25
update-rc.d ax25 defaults
# Add ax25 systemd service code here
cd /etc/ax25
cp $wd/k4gbb/ax25-up.pi /etc/ax25/ax25-up 
cp $wd/k4gbb/ax25-down /etc/ax25/ax25-down && chmod 755 ax25-*
cp $wd/k4gbb/axports /etc/ax25/axports
cp $wd/k4gbb/ax25d.conf /etc/ax25/ax25d.conf
touch nrports rsports
echo -e "=== Install Finished"
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