#!/bin/bash
#
# Configure axports & ax25d.conf files
#

DEBUG=1
set -u # Exit if there are uninitialized variables.
scriptname="`basename $0`"
source $START_DIR/core/core_functions.sh

CALLSIGN="N0ONE"
AX25PORT="0" # Leave 0 for now, needs code for configuring port on ax25-up
SSID="15"
AX25DSSID="0"
AX25_CFGDIR="/etc/ax25"


# ===== Function List =====

function get_callsign()
{ 
# Check if call sign var has already been set
echo -e "${Cyan}=== Get Call Sign${Reset}"
if [ "$CALLSIGN" == "N0ONE" ] ; then
   read -t 1 -n 10000 discard
   echo "Enter call sign, followed by [enter]:"
   read -e CALLSIGN
   sizecallstr=${#CALLSIGN}
   if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
      echo "Invalid call sign: $CALLSIGN, length = $sizecallstr"
      return 0
   fi
   # Convert callsign to upper case
   CALLSIGN=$(echo "$CALLSIGN" | tr '[a-z]' '[A-Z]')
fi
dbgecho "Using CALL SIGN: $CALLSIGN"
echo -e "${Cyan}=== Get Call Sign ${Green}Finished${Reset}"
echo
return 1
}

function get_ssid()
{
echo -e "${Cyan}=== Get SSID ${Reset}"
read -t 1 -n 10000 discard
echo "Enter ssid (0 - 15) followed by [enter]:"
read -e SSID
if [ -z "${SSID##*[!0-9]*}" ] ; then
   echo "Input: $SSID, not a positive integer"
   return 0
fi
sizessidstr=${#SSID}
if (( sizessidstr > 2 )) || ((sizessidstr < 0 )) ; then
   echo "Invalid ssid: $SSID, length = $sizessidstr, should be 1 or 2 numbers"
   return 0
fi
dbgecho "Using SSID: $SSID"
echo -e "${Cyan}=== Get SSID ${Green}Finished${Reset}"
echo
return 1
}

function prompt_read()
{
while get_callsign ; do
  echo -e "Input ${Red}error${Reset}, try again"
done
while get_ssid ; do
  echo -e "Input ${Red}error${Reset}, try again"
done
}

function chk_config_dir()
{
# check if /etc/ax25 exists as a directory or symbolic link
echo -e "Checking for /etc/ax25 symbolic link"
if [ ! -d "/etc/ax25" ] || [ ! -L "/etc/ax25" ] ; then
   if [ ! -d "/usr/local/etc/ax25" ] ; then
	  echo -e "Directory /usr/local/etc/ax25 not found..."
      echo -e "AX.25 ${Red}NOT${Reset} Properly installed, make sure that ax25_install.sh ran successfully"
      exit 1
   else
      echo -e "Creating symbolic link /etc/ax25"
      ln -s /usr/local/etc/ax25 /etc/ax25
   fi
else
   echo -e "${Green}Found${Reset} /etc/ax25 symbolic link"
   echo
fi
}

function configure_axports()
{
	sed -i -e "/k4gbb/ /k4gbb-1/$callsign/ " /etc/ax25/axports
}

function FinishAx25_Install
{
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
      echo -e " Enabling AX.25 module"
      insmod /lib/modules/$(uname -r)/kernel/net/ax25/ax25.ko
   fi
echo "ax25" >> /etc/modules
fi
grep rose /etc/modules > /dev/null 2>&1
if [ $? -ne 0 ]; then
   lsmod | grep -i rose > /dev/null 2>&1
   if [ $? -ne 0 ]; then
      echo -e " Enabling rose module"
      insmod /lib/modules/$(uname -r)/kernel/net/rose/rose.ko
   fi
echo "rose" >> /etc/modules
fi
grep mkiss /etc/modules > /dev/null 2>&1
if [ $? -ne 0 ]; then
   echo -e " Enabling mkiss module"
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
   echo -e "Setting up ax25 systemd service"
   cp $START_DIR/systemd/ax25.service /etc/systemd/system/ax25.service
   systemctl enable ax25.service
   systemctl daemon-reload
   service ax25 start
   chk_service ax25
fi
echo -e "${Cyan}=== Startup Files ${Green}Installed${Reset}"
echo
if [ -z "$(ls -A /etc/ax25)" ]; then
   UPD_CONF_FILES=true
fi
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

# =====  Main =====
sleep 3
clear
echo "$(date "+%Y %m %d %T %Z"): ax25_config.sh: script START" >>$WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW}ax25_config.sh: script STARTED${Reset}"
echo

# Be sure we're running as root
chk_root
chk_config_dir
# if there are any args on command line assume it's a callsign
if (( $# != 0 )) ; then
   CALLSIGN="$1"
fi

# Clean up and install startup files
FinishAx25_Install

# Configure axports
echo -e "${Cyan}=== Configuring axports${Reset}"
echo
grep -i "$AX25PORT" $AX25_CFGDIR/axports
if [ $? -eq 1 ] ; then
   echo
   echo -e " No AX.25 ports defined"
   echo
   mv $AX25_CFGDIR/axports $AX25_CFGDIR/axports-dist
   echo -e " Original ax25 axports saved as axports-dist"
   echo
   prompt_read
{
echo "# $AX25_CFGDIR/axports"
echo "#"
echo "# The format of this file is:"
echo "# portname	callsign	speed	paclen	window	description"
echo "$AX25PORT            $CALLSIGN-$SSID         19200    256     7       TNC-Pi port"
} > $AX25_CFGDIR/axports
else
   echo
   echo -e " AX.25 port $AX25PORT already configured"
fi
echo -e "${Cyan}=== axports Configuration ${Green}Finished${Reset}"
echo

# === Configure ax25d.conf
# Set up a listening socket, for testing
# Make it different than previous SSID
echo -e "${Cyan}=== Configuring ax25d.conf${Reset}"
if ((SSID < 15)) ; then
   AX25DSSID=$((SSID+1))
else
   AX25DSSID=$((SSID-1))
fi

grep  "n0one" /etc/ax25/ax25d.conf >/dev/null
if [ $? -eq 0 ] ; then
   echo -e " ax25d.conf not configured"
   echo
   mv $AX25_CFGDIR/ax25d.conf $AX25_CFGDIR/ax25d.conf-dist
   echo -e " Original ax25d.conf saved as ax25d.conf-dist"
   echo
   # copy first 1 line of file
   sed -n '1p' $AX25_CFGDIR/ax25d.conf-dist >> $AX25_CFGDIR/ax25d.conf
{
echo "[$CALLSIGN-$AX25DSSID VIA $AX25PORT]"
echo "NOCALL   * * * * * *  L"
echo "N0CALL   * * * * * *  L"
echo "default  * * * * * *  - root /usr/sbin/ttylinkd ttylinkd"
} > $AX25_CFGDIR/ax25d.conf
   sed -n '$p' $AX25_CFGDIR/ax25d.conf-dist >> $AX25_CFGDIR/ax25d.conf
else
   echo -e " ax25d.conf already configured"
fi
echo -e "${Cyan}=== Configuration ${Green}Finished${Reset}"
echo

# === Configure ax25-up
echo -e "${Cyan}=== Configuring ax25-up${Reset}"
echo
sed -i -e "/n0one/ s/n0one/$CALLSIGN/" $AX25_CFGDIR/ax25-up > /dev/null 2>&1
echo -e "${Cyan}=== ax25-up Configuration ${Green}Finished${Reset}"
echo

echo "$(date "+%Y %m %d %T %Z"): ax25_config.sh: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW}ax25_config.sh: script FINISHED${Reset}"
echo
# ===== END Main ====
