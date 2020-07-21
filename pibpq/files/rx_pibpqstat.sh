#!/bin/bash

######## STATUSMONITOR script -- See VERSION # below. 
## This script is called from statusmonitor.service, which is a service control file.  
## statusmonitor.service controls the registry of this script and specifies that
## this script should be restarted if it ever quits.  
## This script is deployed to /usr/local/sbin and is redeployed by "tarpn update". 
##
## This script checks /usr/local/etc/background.ini for a token.  
## The token can either be BACKGROUND:OFF  or  BACKGROUND:ON
## If off, wait a while, then repeat the test.
## If on, then goes through a sequence of launching apps and checking apps to make sure they are running unless it is already running.  If running, log an error and repeat the token test. 

check_process() {
  #  echo "$ts: checking $1"
  [ "$1" = "" ]  && return 0
  [ `pgrep -n $1` ] && return 1 || return 0
}


LOGFILE="/var/log/rx_tarpnstat_service.log"
SOURCE_URL="/usr/local/sbin/source_url.txt"
NODE_INIT="/home/pi/node.ini"
######################################################################################## VERSION INFO ####################################################################################################
####  2-26-2019 s101  Create for RX-TARPNSTAT from Statusmonitor service. 
####  2-26-2019 s102  rename rx-tarpnstat to rx-tarpnstatapp.
####  2-28-2019 s103  set the permissions of tarpn_home_linkquality.dat to RWRWRW just before launching rx_tarpnstatapp 
echo -ne "\n =rx_tarpnstat shellscript s103= \n start:" >> $LOGFILE
date >> $LOGFILE
uptime >> $LOGFILE


###### Make sure we have a listed URL on the Internet for getting updates and configuration.  If not, wait 3 minutes and then exit
if [ -f $SOURCE_URL ];
then
    echo -n "source URL is " >> $LOGFILE
    cat $SOURCE_URL >> $LOGFILE
else
    echo -n "ERROR0: source URL file not found.  wait 1200 seconds starting @" >> $LOGFILE
    date >> $LOGFILE
    sleep 1200
    echo -n "ERROR0: exit script @ " >> $LOGFILE
    date >> $LOGFILE
    exit 1
fi

###### Make sure we have a node.ini config file.  If not, wait 3 minutes and then exit
if [ -f $NODE_INIT ];
then
    echo "got NODE_INIT" >> $LOGFILE
else
    echo -n "ERROR1: NODE INIT file not found.  wait 1200 seconds starting @" >> $LOGFILE
    date >> $LOGFILE
    sleep 1200
    echo -n "ERROR1: exit script @ " >> $LOGFILE
    date >> $LOGFILE
    exit 1
fi

####### Check Node background service.  If not enabled, don't do the statusmonitoring. 
if grep -q "BACKGROUND:ON" /usr/local/etc/background.ini; then
    echo "BPQ node is enabled to be run as a service" >> $LOGFILE
else
    echo -n "ERROR2: BPQ node is NOT enabled to be run as a service.  wait 1200 seconds starting @" >> $LOGFILE
    date >> $LOGFILE
    sleep 1200
    echo -n "ERROR2: exit script @ " >> $LOGFILE
    date >> $LOGFILE
    exit 1
fi


###### Check to see that the node is actually running. 
check_process "linbpq"
if [ $? -ge 1 ]; then
    echo "BPQ node is running"  >> $LOGFILE
else
    echo -n "ERROR3: BPQ node is not running.  wait 90 seconds starting @" >> $LOGFILE
    date >> $LOGFILE
    sleep 90
    echo -n "Re-check BPQ node @" >> $LOGFILE
    date >> $LOGFILE
    check_process "linbpq"
    if [ $? -ge 1 ]; then
        echo "BPQ node is running on second check"  >> $LOGFILE
    else
        echo -n "ERROR3: BPQ node is still not running.  wait 1200 seconds starting @" >> $LOGFILE
        date >> $LOGFILE
        sleep 1200
        echo -n "ERROR3: exit script @ " >> $LOGFILE
        date >> $LOGFILE
        exit 1
    fi
fi

######## Make sure somebody else isn't running rx_tarpnstatapp application.  If there is, then dump out of this script. 

check_process "rx_tarpnstatapp"
if [ $? -ge 1 ]; then
    echo -n "ERROR4: RX_TARPNSTATAPP was already running!  wait 60 seconds starting @" >> $LOGFILE
    date >> $LOGFILE
    sleep 60
    echo -n "ERROR4: exit script @ " >> $LOGFILE
    date >> $LOGFILE
    exit 1
fi

echo "Get version of RX_TARPNSTAT application"  >> $LOGFILE
/usr/local/sbin/rx_tarpnstatapp version >> $LOGFILE
echo -n "Starting RX_TARPNSTAT @ " >> $LOGFILE
date >> $LOGFILE


#### make sure we can write to the linkquality data file. 
sudo chmod 666 /usr/local/etc/tarpn_home_linkquality.dat

/usr/local/sbin/rx_tarpnstatapp
echo -n "RX_TARPNSTATAPP must have quit.  Log @ " >> $LOGFILE
date >> $LOGFILE


exit 0;



