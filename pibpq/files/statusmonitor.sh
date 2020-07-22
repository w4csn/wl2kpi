#!/bin/bash
## statusmoniotor.sh
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


LOGFILE="/var/log/statusmonitor.log"
BAD_LINK_WAV="/home/pi/badlinksound.wav"
######################################################################################## VERSION INFO ####################################################################################################
#### 11-22-2018 s101  Create to keep the check-bbs app running once in a while
#### 12-08-2018 s102  Improve error output.  Add output of the version number from the application. 
#### 12-09-2018 s103  If node is enabled as a service, but not found running, wait 90 seconds and check again. 
#### 12-14-2018 s104  Get version of sendroutestocq and output it to the log before entering while 
#### 12-15-2018 s105  Speed up the sendroutestocq calls to get it closer to 15 minutes.  Add killall for bbs_checker
####  2-26-2018 s106  Fewer check-bbs-calls between sendroutestocq, to get it closer to 15 minutes. 
echo -ne "\n =statusmonitor_background s106= \n start:" >> $LOGFILE
date >> $LOGFILE
uptime >> $LOGFILE



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

######## Make sure somebody else isn't running bbs_checker app.  If there is, then dump out of this script. 

check_process "bbs_checker"
if [ $? -ge 1 ]; then
    echo -n "ERROR4: BPQ-checker was already running!  wait 60 seconds starting @" >> $LOGFILE
    date >> $LOGFILE
    sleep 60
    echo -n "ERROR4: exit script @ " >> $LOGFILE
    date >> $LOGFILE
    exit 1
fi

echo "Get version of BBS checker application"  >> $LOGFILE
/usr/local/sbin/bbs_checker version >> $LOGFILE
echo "Get version of sendroutestocq application"  >> $LOGFILE
/usr/local/sbin/sendroutestocq version >> $LOGFILE
echo -n "Starting WHILE(1) loop to run bbschecker every 30 seconds or so @ " >> $LOGFILE
date >> $LOGFILE


################# LOOP HERE FOREVER
#### Top of loop -- check if we should be calling check_bbs or just waiting for a while. 
while [ 1 ];
do
   #### Now get a local R R table, share it via CQ, and generate a log of the link-status for our node
   check_process "sendroutestocq"
   if [ $? -ge 1 ]; then
       echo -n "ERROR7: in while loop, sendroutestocq redundantly running!  wait 60 seconds starting @" >> $LOGFILE
       date >> $LOGFILE
       sleep 60
       echo -n "ERROR7: exit script @ " >> $LOGFILE
       date >> $LOGFILE
       exit 1
   fi

   ### Generate the CQs and add to the log file
   /usr/local/sbin/sendroutestocq

   ### See if the operator wants a WAV file played if the log file has a bad link
   if [ -f $BAD_LINK_WAV ];
      then
      if tail -1 /var/log/pibpq_linkstatus.log | grep -q "BAD"; then
         aplay $BAD_LINK_WAV
      fi
   fi

   # Now loop for the BBS checker, every 30+ seconds, for 15 minutes
   x=1
   while [ $x -le 22 ]
   do
      x=$(( $x + 1 ))


      ########### 30 second loop
      check_process "linbpq"
      if [ $? -ge 1 ]; then
          echo  
      else
          echo -n "ERROR5: in while loop, BPQ node is not running!  wait 1200 seconds starting @" >> $LOGFILE
          date >> $LOGFILE
          sleep 1200
          echo -n "ERROR5: exit script @ " >> $LOGFILE
          date >> $LOGFILE
          exit 1
      fi
      
      check_process "bbs_checker"
      if [ $? -ge 1 ]; then
          echo -n "ERROR6: in while loop, bbs_checker redundantly running!  @" >> $LOGFILE
          date >> $LOGFILE
          echo -n "ERROR6: do killall and wait 60secs @" >> $LOGFILE
          date >> $LOGFILE
          sudo killall bbs_checker
          sleep 60
          echo -n "ERROR6: did killall bbs_checker - exit script @ " >> $LOGFILE
          date >> $LOGFILE
          exit 1
      fi
      
      /usr/local/sbin/bbs_checker
      if grep -q "BBS_HAS_MAIL" /usr/local/etc/bbshasmail.txt; then
         aplay /usr/local/sbin/ring.wav
      fi
      sleep 30
   
   done


done

exit 0;