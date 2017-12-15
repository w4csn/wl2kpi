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

# ===== function get_callsign
function get_callsign() { 

# Check if call sign var has already been set
if [ "$CALLSIGN" == "N0ONE" ] ; then

   read -t 1 -n 10000 discard
   echo "Enter call sign, followed by [enter]:"
   read CALLSIGN

   sizecallstr=${#CALLSIGN}

   if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
      echo "Invalid call sign: $CALLSIGN, length = $sizecallstr"
      return 0
   fi

   # Convert callsign to upper case
   CALLSIGN=$(echo "$CALLSIGN" | tr '[a-z]' '[A-Z]')
fi

dbgecho "Using CALL SIGN: $CALLSIGN"
return 1
}

# ===== function get_ssid
function get_ssid() {

read -t 1 -n 10000 discard
echo "Enter ssid (0 - 15) for direwolf APRS, followed by [enter]:"
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
return 1
}

# ===== function prompt_read
function prompt_read() {
while get_callsign ; do
  echo "Input error, try again"
done

while get_ssid ; do
  echo "Input error, try again"
done
}

function configure_axports() {
	sed -i -e "/k4gbb/ /k4gbb-1/$callsign/ " /etc/ax25/axports
}

# ===== End Functions list =====

# =====  Main =====
sleep 3
clear
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script START" >>$WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script STARTED"
echo
# Make sure user is root
chk_root

if [ ! -f "/etc/ax25/axports" ]; then
   echo "Need to install libax25, tools & apps"
   exit 1
fi

# check if /etc/ax25 exists as a directory or symbolic link
if [ ! -d "/etc/ax25" ] || [ ! -L "/etc/ax25" ] ; then
   if [ ! -d "/usr/local/etc/ax25" ] ; then
      echo "ax25 directory /usr/local/etc/ax25 DOES NOT exist, install ax25 first"
      exit
   else
      echo "Making symbolic link to /etc/ax25"
      ln -s /usr/local/etc/ax25 /etc/ax25
   fi
else
   echo " Found ax.25 link or directory"
fi

# if there are any args on command line assume it's a callsign
if (( $# != 0 )) ; then
   CALLSIGN="$1"
fi

# Check for a valid callsign
get_callsign

# === Configure axports
echo -e "=== Configuring axports"
echo
grep -i "$AX25PORT" $AX25_CFGDIR/axports
if [ $? -eq 1 ] ; then
   echo
   echo "No ax25 ports defined"
   echo
   mv $AX25_CFGDIR/axports $AX25_CFGDIR/axports-dist
   echo "Original ax25 axports saved as axports-dist"
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
   echo "AX.25 port $AX25PORT already configured"
   echo
fi
echo -e "=== Configuration Finished"
echo

# === Configure ax25d.conf
# Set up a listening socket, for testing
# Make it different than previous SSID
echo -e "=== Configuring ax25d.conf"
echo
if ((SSID < 15)) ; then
   AX25DSSID=$((SSID+1))
else
   AX25DSSID=$((SSID-1))
fi

grep  "n0one" /etc/ax25/ax25d.conf >/dev/null
if [ $? -eq 0 ] ; then
   echo "ax25d not configured"
   echo
   mv $AX25_CFGDIR/ax25d.conf $AX25_CFGDIR/ax25d.conf-dist
   echo "Original ax25d.conf saved as ax25d.conf-dist"
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
   echo "ax25d.conf already configured"
   echo
fi
echo -e "=== Configuration Finished"
echo

# === Configure ax25-up
echo -e "=== Configuring ax25-up"
echo
sed -i -e "/n0one/ s/n0one/$CALLSIGN/" $AX25_CFGDIR/ax25-up > /dev/null 2>&1

echo -e "=== Configuration Finished"
echo
===== END Main ====
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script FINISHED"
echo

