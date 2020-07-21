#!/bin/bash

######## PIBPQ BACKGROUND script -- See VERSION # below. 
## This script is called from tarpn.service, which is a service control file.  
## tarpn.service controls the registry of this script and specifies that
## this script should be restarted if it ever quits.  
## This script is deployed to /usr/local/sbin and is redeployed by "tarpn update". 
##
## This script checks /usr/local/etc/background.ini for a token.  
## The token can either be BACKGROUND:OFF  or  BACKGROUND:ON
## If off, wait a while, then repeat the test.
## If on, then launch linbpq unless it is already running.  If running, log an error and repeat the token test. 

check_process() {
  #  echo "$ts: checking $1"
  [ "$1" = "" ]  && return 0
  [ `pgrep -n $1` ] && return 1 || return 0
}

waste_time_if_not_running() {
   if grep -q "BACKGROUND:OFF" /usr/local/etc/background.ini; 
   then
      sleep 5
      check_process "python"
      if [ $? -ge 1 ]; then
          echo "not running but PYTHON seems to still be running.  Remove the remove-me file" >> $LOGFILE
          sudo rm -rf /usr/local/sbin/home_web_app/remove_me_to_stop_server.txt
	  date >> $LOGFILE
          sleep 5
      fi
      check_process "python"
      if [ $? -ge 1 ]; then
          echo "but PYTHON is yet again still running.  killall python" >> $LOGFILE
          sudo killall python
	  date >> $LOGFILE
      fi
   fi
}

LOGFILE="/var/log/pibpq.log"

echo -ne "\n =tarpn_background s003= \n start:" >> $LOGFILE
date >> $LOGFILE
uptime >> $LOGFILE


################# LOOP HERE FOREVER
#### Top of loop -- check if we should be calling linbpq or just waiting for a while. 
while [ 1 ];
do
   if grep -q "BACKGROUND:ON" /usr/local/etc/background.ini; then
      echo "BPQ node is enabled to be run as a service" >> $LOGFILE
      check_process "linbpq"
      if [ $? -ge 1 ]; then
         echo -n "ERROR!! BPQ node is already running.  " >> $LOGFILE
	     date >> $LOGFILE
         sleep 100
         exit 0;
      else
         echo -ne "BPQ node is not already running-- call runbpq @" >> $LOGFILE
         date >> $LOGFILE
         tarpn i2c >> $LOGFILE
         grep -e port01 -e port02 -e port03 -e port04 -e port05 -e port06 -e port07 -e port08 -e port09 -e port10 -e port11 -e port12  /home/pi/node.ini >> $LOGFILE
         /usr/local/sbin/runbpq.sh
         echo -ne "back from runbpq @" >> $LOGFILE
         date >> $LOGFILE
      fi
   else
      echo -n "BPQ node is NOT enabled to be run as a service@" >> $LOGFILE
      date >> $LOGFILE
      check_process "linbpq"
      if [ $? -ge 1 ]; then
         echo "Not enabled as a service, but is running" >> $LOGFILE
      else
         check_process "python"
         if [ $? -ge 1 ]; then
             echo "Not enabled and not running. Python seems to be running.  oops" >> $LOGFILE
             echo "PYTHON seems to still be running.  Remove the remove-me file" >> $LOGFILE
             sudo rm -rf /usr/local/sbin/home_web_app/remove_me_to_stop_server.txt
             date >> $LOGFILE
             sleep 5
         fi
         check_process "python"
         if [ $? -ge 1 ]; then
             echo "Not enabled and not running. Python seems to be running." >> $LOGFILE
             echo "PYTHON is yet again still running.  killall python" >> $LOGFILE
             sudo killall python
             date >> $LOGFILE
         fi
      fi
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
   fi
done


ste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
      waste_time_if_not_running 0  
   fi
done


