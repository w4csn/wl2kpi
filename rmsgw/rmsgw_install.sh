#!/bin/bash
# Installs/Updates the Linux RMS Gateway
# Parts taken from RMS-Upgrade-181 script Updated 10/30/2014
# (https://k4gbb.no-ip.org/docs/scripts)
# by C Schuman, K4GBB k4gbb1gmail.com
#
# Uncomment this statement for debug echos
DEBUG=1
set -u # Exit if there are uninitialized variables.
source $START_DIR/core/core_functions.sh

uid=$(id -u)

UDATE="NO"
GWOWNER="rmsgw"
RMSGWREPO=https://github.com/nwdigitalradio/rmsgw
PKG_REQUIRE="xutils-dev libxml2 libxml2-dev python-requests"
SRC_DIR="/usr/local/src/rmsgw"
SRC_FILE="rmsgw-2.4.0-182.zip"
ROOTFILE_NAME="rmsgw-"
RMS_BUILD_FILE="rmsgwbuild.txt"

# ===== Function List =====

function install_tools
{
# check if packages are installed
echo -e "${Cyan}=== Installing Required Packages${Reset}"
dbgecho "Check packages: $PKG_REQUIRE"
needs_pkg=false

for pkg_name in `echo ${PKG_REQUIRE}` ; do

   is_pkg_installed $pkg_name
   if [ $? -ne 0 ] ; then
      echo "$scriptname: Will Install $pkg_name program"
      needs_pkg=true
      break
   fi
done

if [ "$needs_pkg" = "true" ] ; then
   echo -e "\t Installing Support libraries "

   apt-get install -y -q $PKG_REQUIRE
   if [ "$?" -ne 0 ] ; then
      echo "Support library install failed. Please try this command manually:"
      echo "apt-get install -y $PKG_REQUIRE"
      exit 1
   fi
fi

echo -e "${Cyan}=== All required packages ${Green}installed.${Reset}"
echo
}

function create_users
{
#  create the group for the gateway if it doesn't exist
grep "rmsgw:" /etc/group >/dev/null 2>&1
if [ $? -ne 0 ]; then
 echo "Creating group rmsgw..."
 groupadd rmsgw
fi
#  create the gateway user if it doesn't exist
grep "rmsgw:" /etc/passwd >/dev/null 2>&1
if [ $? -ne 0 ]; then
 echo "Creating user rmsgw..."
 useradd -s /bin/false -g rmsgw rmsgw
fi
# lock the account to prevent a potential hole, unless the owner is root
if [ "$GWOWNER" != root ]; then
 echo "Locking user account $GWOWNER..."
 passwd -l $GWOWNER >/dev/null
 # while the account is locked, make the password to
 # never expire so that cron will be happy
 chage -E-1 $GWOWNER >/dev/null
 echo
fi
}

function download_rmsgw #Pull rmsgw from github
{
echo -e "${Cyan}=== Download RMSGW-Linux from Source${Reset}"
if [ ! -d $SRC_DIR ] ; then
   mkdir -p $SRC_DIR
   if [ "$?" -ne 0 ] ; then
      echo -e "\t${Red}ERROR${Reset}: Problems creating source directory: $SRC_DIR"
      exit 1
   fi
fi
cd $SRC_DIR
if [ ! -d .git ]; then
  echo -e " Cloning rmsgw-linux from $RMSGWREPO"
  git clone $RMSGWREPO .
else
  echo -e " Updating rmsgw-linux from $RMSGWREPO"
  git pull $RMSGWREPO
fi
echo -e "${Cyan}=== Download ${Green}Finished${Reset}"
echo
}

function copy_rmsgw # DEPRECATED... USE DOWNLOAD_RMSGW function Copy rmsgw from install folder
{
echo -e "${Cyan}=== Copy RMSGW-Linux from Source Folder${Reset}"
# Does source directory exist?
if [ ! -d $SRC_DIR ] ; then
   mkdir -p $SRC_DIR
   if [ "$?" -ne 0 ] ; then
      echo -e "\t${Red}ERROR${Reset}: Problems creating source directory: $SRC_DIR"
      exit 1
   fi
fi
cd $SRC_DIR
# Determine if any rmsgw zip files have been copied to $SRC_DIR"
ls rmsgw-*.zip 2>/dev/null
if [ $? -ne 0 ]; then
   echo -e "\t Copying RMS Gateway Source file"
   cp $START_DIR/src/$SRC_FILE $SRC_DIR > /dev/null 2>&1
   if [ $? -ne 0 ]; then
	  echo -e "\t${Red}ERROR${Reset}: Problems creating source directory: $SRC_DIR"
	  exit 1
	fi
else
	# Get here if some zip files were found
    ZIP_FILELIST="$(ls rmsgw-*.zip |tr '\n' ' ')"
    echo "Already have rmsgw install file(s): $ZIP_FILELIST"
    echo "To check for a new version move .zip file(s) out of this directory"
fi
# Lists all .tgz files in directory
# Last file listed should have lastest version number
for filename in *.zip ; do
   rms_ver="$(echo ${filename#r*-} | cut -d '.' -f1,2,3)"
   echo "$filename version: $rms_ver"
done
dbgecho "Unzipping this installation file: $filename, version: $rms_ver"

#tar xf $filename
echo -e "\t Unzipping $filename"
unzip -o $filename
if [ $? -ne 0 ] ; then
 echo -e "\t${Red}ERROR${Reset}: $filename File not available"
 exit 1
fi
echo -e "${Cyan}=== Copy ${Green}Finished${Reset}"
echo
}

function compile_rmsgw
{
# rmsgw 
echo -e "${Cyan}=== Compile RMSGW-Linux from Source${Reset}"
#chown root:root -R $SRC_DIR/$ROOTFILE_NAME$rms_ver
#chmod 755 -R $SRC_DIR/$ROOTFILE_NAME$rms_ver
cd $SRC_DIR
num_cores=$(nproc --all)
# Clean old binaries
make clean
echo -e " Compiling, Please Wait..."
(make -j$num_cores > $RMS_BUILD_FILE 2>&1) &
spinner $!
echo " Finished!"
if [ $? -ne 0 ]
 then
 echo -e "\t${Red}ERROR${Reset}: Compile error - check RMS.txt File"
 exit 1
else 
 rm $RMS_BUILD_FILE
fi
echo -e " Compiling, Please Wait..."
(make install) &
spinner $!
echo -e " Finished!"
if [ $? -ne 0 ] ; then
  echo -e "\t${Red}ERROR${Reset}: Error during install."
  exit 1
fi
echo -e "${Cyan}=== RMSGW-Linux ${Green}installed.${Reset}"
}

function finish_rmsgw
{
# Copy rmschanstat to /usr/local/bin
if [ -f /usr/local/bin/rmschanstat ]; then
	mv /usr/local/bin/rmschanstat /usr/local/bin/rmschanstat-dist
	cp -f $START_DIR/rmsgw/rmschanstat /usr/local/bin/rmschanstat
else
	# Use old rmschanstat file.
    cp -f $START_DIR/rmsgw/rmschanstat /usr/local/bin/rmschanstat
fi
# remove all duplicate files due to recompile
rm -f /usr/local/bin/rmschanstat.*
echo -e "${BluW}Be Sure to Update/Edit the channels.xml and gateway.config file${Reset}"
# Chown /etc/rmsgw/stat folder
chown -Rf rmsgw:rmsgw /etc/rmsgw/stat
}

# ===== End of Functions list =====

# ===== Main
sleep 2
clear
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script START" >>$WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW}$scriptname: script STARTED${Reset}"
echo

chk_root
install_tools
create_users
download_rmsgw
compile_rmsgw
finish_rmsgw

echo "$(date "+%Y %m %d %T %Z"): $scriptname: RMS Gateway Installed - $ROOTFILE_NAME$rms_ver" >> $WL2KPI_INSTALL_LOGFILE
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW}$scriptname: script FINISHED${Reset}"
echo