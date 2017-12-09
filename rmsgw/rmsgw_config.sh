#!/bin/bash
#
# Configure an RMS Gateway installation
#

DEBUG=1 # Uncomment this statement for debug echos
set -u # Exit if there are unitialized variables.
scriptname="`basename $0`"
WL2KPI_INSTALL_LOGFILE="/var/log/wl2kpi_install.log"
wd=$(pwd)
CALLSIGN="N0ONE"
GRIDSQUARE="AA00aa"
AX25PORT="0"
SSID="10"
AX25_CFGDIR="/etc/ax25"
RMSGW_CFGDIR="/etc/rmsgw"
RMSGW_CFG_FILES="gateway.conf channels.xml banner"
REQUIRED_PRGMS="rmschanstat python rmsgw rmsgw_aci"

# ===== Function List =====

# ===== function dbecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function chk_root 
function chk_root {
# Check for Root
if [[ $EUID != 0 ]] ; then
   echo -e "Must be root"
   exit 1
fi
}

# ===== function get_callsign
function get_callsign() {
# Check if call sign var has already been set
if [ "$CALLSIGN" == "N0ONE" ] ; then
   echo "Enter call sign, followed by [enter]:"
   read -e CALLSIGN

   sizecallstr=${#CALLSIGN}

   if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
      echo "Invalid call sign: $CALLSIGN, length = $sizecallstr"
      exit 1
   fi

   # Convert callsign to upper case
   CALLSIGN=$(echo "$CALLSIGN" | tr '[a-z]' '[A-Z]')
fi

dbgecho "Using CALL SIGN: $CALLSIGN"
}

# ===== function get_gridsquaree
function get_gridsquare() {

# Check if gridsquare var has already been set
if [ "$GRIDSQUARE" == "AA00aa" ] ; then
   echo "Enter grid square in the form AA00aa, follwed by [enter]:"
   read -e GRIDSQUARE

   sizegridsqstr=${#GRIDSQUARE}

   if (( sizegridsqstr != 6 )) ; then
      echo
      echo "INVALID grid square: $GRIDSQUARE, length = $sizegridsqstr"
      echo "NEED TO manually edit channels file"
      echo
   fi
fi

dbgecho "Using Grid Square: $GRIDSQUARE"
}

# ===== function prompt_read_gwcfg

function prompt_read_gwcfg() {

# Use default SSID 10
#echo "Enter ssid, followed by [enter]:"
#read SSID

sizessidstr=${#SSID}

if (( sizessidstr > 2 )) || ((sizessidstr < 0 )) ; then
   echo "Invalid ssid: $SSID, length = $sizessidstr"
   exit 1
fi

dbgecho "Using SSID: $SSID"

echo "Enter city name where gateway resides, follwed by [enter]:"
read -e CITY

echo "Enter state or province name where gateway resides, follwed by [enter]:"
read -e STATE

get_gridsquare

echo "You can change any of the above by manually editing these files"
for filename in `echo ${RMSGW_CFG_FILES}` ; do
   echo -n "$RMSGW_CFGDIR/$filename "
done
echo
}

# ===== function prompt_read_chanxml

function prompt_read_chanxml() {

echo "Enter Winlink Gateway password, followed by [enter]:"
read -e PASSWD

get_gridsquare

echo "Enter radio Frequency in Hz (ie. 144000000, followed by [enter]:"
read -e FREQUENCY

   sizefreqstr=${#FREQUENCY}

   if (( sizefreqstr != 9 )) ; then
      echo
      echo "INVALID frequency: $FREQUENCY, length = $sizefreqstr"
      echo "NEED TO manually edit channels file"
      echo
   fi
   if ! [[ $FREQUENCY =~ ^[0-9]+$ ]] ; then
      echo
      echo "INVALID frequency: $FREQUENCY, needs to be a number"
      echo "NEED TO manually edit channels file"
      echo
   fi

echo "You can change any of the above by manually editing $RMSGW_CHANFILE"
echo
}

# ===== function cfg_ax25d

function cfg_ax25d() {
{
echo "#"
echo "[$CALLSIGN-$SSID VIA $AX25PORT]"
echo "NOCALL   * * * * * *  L"
echo "N0CALL   * * * * * *  L"
#echo "default  * * * * * *  - rmsgw /usr/local/bin/rmsgw rmsgw -l debug -P %d %U"
echo "default  * * * * * *  - rmsgw /usr/local/bin/rmsgw rmsgw -P 0 %U"
} >> $AX25_CFGDIR/ax25d.conf

}

# ===== function cfg_chan_xml
# Configure the following:
# channel name, basecall, callsign, password,
#  gridsquare, frequency
# sed -i  save result to input file

function cfg_chan_xml() {

RMSGW_CHANFILE=$RMSGW_CFGDIR/channels.xml
prompt_read_chanxml

CHECK_CALL="N0CALL"
sed -i -e "/$CHECK_CALL/ s/$CHECK_CALL/$CALLSIGN/g" $RMSGW_CHANFILE
sed -i -e "/channel name=/ s/radio/$AX25PORT/" $RMSGW_CHANFILE
# Replace the second occurance of "password"
sed -i -e "/password/ s/password/$PASSWD/2" $RMSGW_CHANFILE
sed -i -e "/AA00AA/ s/AA00AA/$GRIDSQUARE/" $RMSGW_CHANFILE
sed -i -e "/144000000/ s/144000000/$FREQUENCY/" $RMSGW_CHANFILE
}
# ===== End of Functions list =====

# ===== main
sleep 5
clear
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script START" >>$WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script STARTED"
echo
# Make sure user is root
chk_root

echo "Check for required files ..."
EXITFLAG=false
for prog_name in `echo ${REQUIRED_PRGMS}` ; do
   type -P $prog_name &>/dev/null
   if [ $? -ne 0 ] ; then
      echo "$scriptname: RMS Gateway not installed properly"
      echo "$scriptname: Need to Install $prog_name program"
      EXITFLAG=true
   fi
done
if [ "$EXITFLAG" = "true" ] ; then
  exit 1
fi

# if there are any args on command line assume it's a callsign
if (( $# != 0 )) ; then
   CALLSIGN="$1"
fi

# Check for a valid callsign
get_callsign

# Create a /etc/ax25d.conf entry
echo -e "=== Configuring ax25d.conf for rmsgw"
CHECK_CALL="k4gbb"
grep $CHECK_CALL  /etc/ax25/ax25d.conf  > /dev/null 2>&1
if [ $? -eq 0 ] ; then
   echo "ax25d never configured"
   mv $AX25_CFGDIR/ax25d.conf $AX25_CFGDIR/ax25d.conf-dist
   echo "Original ax25d.conf saved as ax25d.conf-dist"
   # copy first 1 line of original file
   sed -n '1p' $AX25_CFGDIR/ax25d.conf-dist >> $AX25_CFGDIR/ax25d.conf
{
echo "[$CALLSIGN-$AX25DSSID VIA $AX25PORT]"
echo "NOCALL   * * * * * *  L"
echo "N0CALL   * * * * * *  L"
echo "default  * * * * * *  - root /usr/sbin/ttylinkd ttylinkd"
} >> $AX25_CFGDIR/ax25d.conf
	sed -n '$p' $AX25_CFGDIR/ax25d.conf-dist >> $AX25_CFGDIR/ax25d.conf
else
   echo "ax25d is configured, checking for RMS Gateway entry"
   grep  "\-10" /etc/ax25/ax25d.conf  > /dev/null 2>&1
   if [ $? -eq 0 ] ; then
      echo "ax25d.conf already configured"
   else
      echo "ax25d NOT configured for Gateway"
      get_callsign
	  sed '$d' $AX25GFGDIR/ax25d.conf
      cfg_ax25d
	  sed -n '$p' $AX25CFGDIR/ax25d.conf-dist >> $AX25CFGDIR/ax25d.conf
  fi
fi
echo -e "=== Configuration Finished"
echo

# RMSGW user created in rmsgw_install.sh
# Does the RMSGW user exist?
#getent passwd rmsgw > /dev/null 2>&1
#if [ $? -ne 0 ] ; then
#   echo "user rmsgw does NOT exist, creating"
#   adduser --no-create-home --system rmsgw
#else
#   echo "user rmsgw exists"
#fi

# Edit gateway.conf
# Need to set:
# GWCALL, GRIDSQUARE, LOGFACILITY (should match syslog entry)
echo -e "=== Configure gateway.conf"
RMSGW_GWCFGFILE=$RMSGW_CFGDIR/gateway.conf
CHECK_CALL="N0CALL"

grep -i "$CHECK_CALL" $RMSGW_GWCFGFILE > /dev/null 2>&1
if [ $? -eq 0 ] ; then
   echo "gateway.conf not configured, will set"
   mv $RMSGW_GWCFGFILE $RMSGW_CFGDIR/gateway.conf-dist
   echo "Original gateway.conf saved as gateway.conf-dist"
   prompt_read_gwcfg
   {
   echo "GWCALL=$CALLSIGN-$SSID"
   echo "GRIDSQUARE=$GRIDSQUARE"
   echo "CHANNELFILE=/etc/rmsgw/channels.xml"
   echo "BANNERFILE=/etc/rmsgw/banner"
   echo "LOGFACILITY=LOCAL0"
   echo "LOGMASK=INFO"
   echo "PYTHON=/usr/bin/python"
   } > $RMSGW_GWCFGFILE
else
   echo "$RMSGW_GWCFGFILE already configured."
fi
echo -e "=== Configuration Finished"
echo

# Edit channels.xml
# Need to set:
# channel name, basecall, callsign, password, gridsquare,
# frequency
echo -e "=== Configure channels.xml"
CHECK_CALL="N0CALL"
grep -i "$CHECK_CALL" $RMSGW_CFGDIR/channels.xml  > /dev/null 2>&1
if [ $? -eq 0 ] ; then
   echo "channels.xml not configured, will set"
   cfg_chan_xml
else
   echo "$RMSGW_CFGDIR/channels.xml already configured"
fi
echo -e " Configuration Finished"
echo

# Edit banner
echo -e "=== Configure banner"
CHECK_CALL="N0CALL"
grep -i "$CHECK_CALL" $RMSGW_CFGDIR/banner  > /dev/null 2>&1
if [ $? -eq 0 ] ; then
   echo "banner not configured, will set"
   echo "$CALLSIGN-$SSID Linux RMS Gateway 2.4, $CITY, $STATE" > $RMSGW_CFGDIR/banner
else
   echo "$RMSGW_CFGDIR/banner already configured, looks like this:"
   cat $RMSGW_CFGDIR/banner
   echo
fi
echo -e "=== Configuration Finished"
echo

# Install Logging
echo -e "=== Configuring log files"
# Install Logging
filename="/etc/rsyslog.d/60-rms.conf"
if [ ! -f $filename ]; then
	{
	echo "# RMS Gate" 
	echo "local0.info                    /var/log/rms"
	echo "local0.debug                   /var/log/rms.debug"
	echo "#local0.debug                  /dev/null" 
	echo "# (End)"
	} >> $filename
	sysctl restart rsyslog
else
	echo "file $filename already configured"
fi

filename="/etc/logrotate.d/rms"
# Check if file exists.
if [  -f "$filename" ] ; then
   echo "logrotate file is already configured."
else
   echo "Creating $filename"
cat > $filename <<EOT
/var/log/rms {
	weekly
	missingok
	rotate 7
	compress
	delaycompress
	notifempty
	create 640 root adm
}
/var/log/rms.debug {
	weekly
	missingok
	rotate 7
	compress
	delaycompress
	notifempty
	create 640 root adm
}
EOT
fi
echo -e "=== Configuration Finished"
echo

# create a sysop record
# run mksysop.py
# Check /etc/rmsgw/new-sysop.xml

echo -e "=== Setting up cron"
# Add RMS_ACI to Crontab
# Is there already a entry for user rmsgw?
grep rmsgw  /etc/crontab  > /dev/null 2>&1
if [ $? -eq 1 ] ; then
	echo "Creating crontab entry for user: rmsgw"
	{
	echo "6,36 * * * *   rmsgw    /usr/local/bin/rmsgw_aci > /dev/null 2>&1"
	echo "# (End) " 
	} >> /etc/crontab
else
	echo "Crontab entry already exist"
fi
echo
echo -e "=== Finished"
echo


	
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo "$scriptname: script FINISHED"
echo