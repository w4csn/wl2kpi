#!/bin/bash
#
# Run this script after core_install.sh
#
# Uncomment this statement for debug echos
DEBUG=1
set -u # Exit if there are uninitialized variables.
scriptname="`basename $0`"
source $START_DIR/core/core_functions.sh

# trap ctrl-c and call function ctrl_c()
trap ctrl_c INT

# ===== Function List =====
function chng_passwd {
# Check for default password
echo -e "\t${Blue}=== Verify not using default password ${Reset}"
# is there even a user pi?
ls /home | grep pi > /dev/null 2>&1
if [ $? -eq 0 ] ; then
   echo "User pi found"
   echo "Determine if default password is being used"

   # get salt
   SALT=$(grep -i pi /etc/shadow | awk -F\$ '{print $3}')

   PASSGEN=$(mkpasswd --method=sha-512 --salt=$SALT raspberry)
   PASSFILE=$(grep -i pi /etc/shadow | cut -d ':' -f2)

#   dbgecho "SALT: $SALT"
#   dbgecho "pass file: $PASSFILE"
#   dbgecho "pass  gen: $PASSGEN"

   if [ "$PASSFILE" = "$PASSGEN" ] ; then
      echo "User pi is using default password"
      echo "Need to change your password for user pi NOW"
      read -t 1 -n 10000 discard
      passwd pi
      if [ $? -ne 0 ] ; then
         echo "Failed to set password, exiting"
	 exit 1
      fi
   else
      echo "User pi not using default password."
   fi

else
   echo "User pi NOT found"
fi
echo
}

function chng_hostname {
# Change hostname from default
echo " === Verify hostname"
HOSTNAME=$(cat /etc/hostname | tail -1)
dbgecho "$scriptname: Current hostname: $HOSTNAME"

if [ "$HOSTNAME" = "raspberrypi" ] || [ "$HOSTNAME" = "compass" ] ; then
   # Change hostname
   echo "Using default host name: $HOSTNAME, change it"
   echo "Enter new host name followed by [enter]:"
   read -t 1 -n 10000 discard
   read -e HOSTNAME
   echo "$HOSTNAME" > /etc/hostname
fi

}
# ===== End Function List =====

# ===== Main =====
sleep 2 
clear
echo "$(date "+%Y %m %d %T %Z"): $scriptname: script START" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW} $scriptname: script STARTED ${Reset}"
echo

# Be sure we're running as root
chk_root

# Make sure User pi isn't using the default password
chng_passwd

# Change hostname to something besides default
chng_hostname

# Get hostname again incase it was changed
HOSTNAME=$(cat /etc/hostname | tail -1)

# Set up /etc/mailname
echo "=== Set mail hostname"
echo "$HOSTNAME.localhost" > /etc/mailname

# Set  up /etc/hosts
grep "127.0.1.1" /etc/hosts
if [ $? -eq 0 ] ; then
   # Found 127.0.1.1 entry
   # Be sure hostnames match
   HOSTNAME_CHECK=$(grep "127.0.1.1" /etc/hosts | awk {'print $2'})
   if [ "$HOSTNAME" != "$HOSTNAME_CHECK" ] ; then
      echo "Make host names match between /etc/hostname & /etc/hosts"
      sed -i -e "/127.0.1.1/ s/127.0.1.1\t.*/127.0.1.1\t$HOSTNAME ${HOSTNAME}.localnet/" /etc/hosts
   else
      echo "host names match between /etc/hostname & /etc/hosts"
   fi
else
   # Add a 127.0.1.1 entry to /etc/hosts
   sed -i '1i\'"127.0.1.1\t$HOSTNAME $HOSTNAME.localnet" /etc/hosts
   if [ $? -ne 0 ] ; then
      echo "Failed to modify /etc/hosts file"
   fi
fi

# Change Time Zone
DATETZ=$(date +%Z)
dbgecho "Time zone: $DATETZ"
if [ "$DATETZ" == "UTC" ] ; then
   echo " === Set time zone"
   echo " ie. select America, then scroll down to 'Los Angeles'"
   echo " then hit tab & return ... wait for it"
   # pause to read above msg
   sleep 4
   dpkg-reconfigure tzdata
fi


echo "$(date "+%Y %m %d %T %Z"): $scriptname: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW} $scriptname: script FINISHED ${Resest}"
echo
# ===== End Main =====