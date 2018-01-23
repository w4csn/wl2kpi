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
function chng_passwd
{
# Check for default password
echo -e "${Cyan}=== Verify pi not using default password ${Reset}"
# is there even a user pi?
ls /home | grep pi > /dev/null 2>&1
if [ $? -eq 0 ] ; then
   echo -e "User ${Yellow}pi${Reset} found"
   echo -e "Determine if default password is being used"

   # get salt
   SALT=$(grep -i pi /etc/shadow | awk -F\$ '{print $3}')

   PASSGEN=$(mkpasswd --method=sha-512 --salt=$SALT raspberry)
   PASSFILE=$(grep -i pi /etc/shadow | cut -d ':' -f2)

#   dbgecho "SALT: $SALT"
#   dbgecho "pass file: $PASSFILE"
#   dbgecho "pass  gen: $PASSGEN"

   if [ "$PASSFILE" = "$PASSGEN" ] ; then
      echo -e "User ${Yellow}pi${Reset} is using default password"
      echo -e "Need to change your password for user pi NOW"
      read -t 1 -n 10000 discard
      passwd pi
      if [ $? -ne 0 ] ; then
         echo -e "Failed to set password, exiting"
	 exit 1
      fi
   else
      echo -e "User ${Yellow}pi${Reset} not using default password."
   fi

else
   echo -e "User ${Yellow}pi${Reset} ${Red}NOT${Reset} found"
fi
echo -e "${Cyan}=== Verify Password ${Green}Complete${Reset}"
echo
}

function chng_hostname {
# Change hostname from default
echo -e "${Cyan}=== Verify hostname${Reset}"
echo
HOSTNAME=$(cat /etc/hostname | tail -1)
echo -e "Current hostname: ${Yellow}$HOSTNAME${Reset}"
echo
if [ "$HOSTNAME" = "raspberrypi" ] || [ "$HOSTNAME" = "compass" ] ; then
   # Change hostname
   echo -e "Using default host name: ${Red}$HOSTNAME${Reset}, change it"
   echo "Enter new host name followed by [enter]:"
   read -t 1 -n 10000 discard
   read -e HOSTNAME
   echo "$HOSTNAME" > /etc/hostname
fi
echo -e "${Cyan}=== Verify hostname ${Green}Finished${Reset}"
echo
}
# ===== End Function List =====

# ===== Main =====
sleep 2 
clear
echo "$(date "+%Y %m %d %T %Z"): core_config.sh: script START" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW}core_config.sh: script STARTED ${Reset}"
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
echo -e "${Cyan}=== Configure /etc/mailname with  ${Yellow}$HOSTNAME${Reset}"
echo
echo "$HOSTNAME.localhost" > /etc/mailname
echo -e "${Cyan}=== Configure mailname ${Green}Finished${Reset}"
echo

# Set  up /etc/hosts
echo -e "${Cyan}=== Configure /etc/hosts${Reset}"
echo
grep "127.0.1.1" /etc/hosts
if [ $? -eq 0 ] ; then
   # Found 127.0.1.1 entry
   # Be sure hostnames match
   HOSTNAME_CHECK=$(grep "127.0.1.1" /etc/hosts | awk {'print $2'})
   echo
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
echo -e "${Cyan}=== Configure /etc/hosts ${Green}Finished${Reset}"
echo

# Change Time Zone
DATETZ=$(date +%Z)
echo
dbgecho "Time zone: $DATETZ"
if [ "$DATETZ" == "UTC" ] ; then
   echo -e "\t${Blue} === Set time zone ${Reset}"
   echo " ie. select America, then scroll down to 'Los Angeles'"
   echo " then hit tab & return ... wait for it"
   # pause to read above msg
   sleep 4
   dpkg-reconfigure tzdata
fi


echo "$(date "+%Y %m %d %T %Z"): $scriptname: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW}core_config.sh: script FINISHED ${Reset}"
echo
# ===== End Main =====