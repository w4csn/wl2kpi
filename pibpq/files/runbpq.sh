#!/bin/bash
## runbpq.sh
## This script is run from the command "pibpq test" or from the OS as an init service called by root.
LOGFILE="/home/pi/linbpq/logs/scriptrun.log";
cd /home/pi/linbpq;
echo "------"                 >> $LOGFILE;
echo "RUNBPQ: Start of runbpq script" >> $LOGFILE;

## Version
echo "----  RUNBPQ  v1"      >> $LOGFILE;
##  Version B008 -- 2020-07-21 Initial Version

######## Kill off any host session in progress. 
sudo killall -q piminicom 
sudo rm -f /home/pi/linbpq/temp*;
sudo rm -f /home/pi/linbpq/tt*.tmp
sudo rm -f /home/pi/linbpq/testfile.txt
sudo chmod 666 bpq32.cfg;
pwd >> $LOGFILE;
ls -lrat >> $LOGFILE;
sleep 1;
if [ -f bpq32.cfg ];
then
   echo "### launching linbpq"      >> $LOGFILE;
   chmod +x linbpq
   sudo setcap "CAP_NET_RAW=ep CAP_NET_BIND_SERVICE=ep" linbpq
   echo "#####"
   echo "#####  Launching G8BPQ node software.  Note, this script does not end"
   echo "#####  until the node is STOPPED/control-C etc.. "
   echo "#####"

   ###### run G8BPQ node -- this does not return until it is killed or quits
   ###### Run as user pi, even if we are called by the OS in the background
   sudo -u pi ./linbpq
   echo "##### G8BPQ LINBPQ has stopped running.  Back to runbpq.sh"
else
   echo "#### ERROR: Can't run.  See script-log"
   echo "#### ERROR: Incomplete configuration.  Is this the first run?"    >> $LOGFILE;
   echo "####        BPQ32.CFG does not exist.  It should by this time."   >> $LOGFILE; 
fi
echo -en "\n\n\n\n----- RUNBPQ: bottom of script @ "     >> $LOGFILE;
date >> $LOGFILE;
echo -e "\n\n\n\n\n\n\n"     >> $LOGFILE;