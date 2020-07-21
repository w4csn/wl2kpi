#!/bin/bash

######## PI SHUTDOWN BACKGROUND script -- See VERSION # below. 
###### Code written by Tadd Torborg  (callsign KA2DEW)  in February 2016 in support of the 
###### power manager project.  This runs on a Raspberry PI and establishes a dialog over a 
###### ribbon cable to a Firmware device (PWRMAN) using GPIO lines and slow speed signalling. 

## This script is called from pi_shutdown.service, which is a service control file.  
## pi_shutdown.service controls the registry of this script and specifies that
## this script should be restarted if it ever quits.  
## This script is deployed to /usr/local/sbin and is redeployed by "tarpn update". 
##
## This script toggles a GPIO output at a 1hz or so rate and drives another GPIO to high continuously.
## It also reads a GPIO.  If that GPIO is driven high, then this script calls sudo shutdown 

check_process() {
  #  echo "$ts: checking $1"
  [ "$1" = "" ]  && return 0
  [ `pgrep -n $1` ] && return 1 || return 0
}


unexport_everything()  {
     echo "8" > /sys/class/gpio/unexport
     echo "23" > /sys/class/gpio/unexport
     echo "11" > /sys/class/gpio/unexport
     echo "24" > /sys/class/gpio/unexport
     echo "9" > /sys/class/gpio/unexport
     echo "25" > /sys/class/gpio/unexport
     echo "10" > /sys/class/gpio/unexport
     echo "22" > /sys/class/gpio/unexport
}

perform_shutdown()  {
      #### tell PWRMAN that we are not staying up (GPIO10) and light the LED saying we ARE going down (GPIO25) 
      ### TARPN HOME shouldn't be running right now.  Stop it right now.  
      sudo rm -rf /usr/local/sbin/home_web_app/remove_me_to_stop_server.txt
      echo "0" > /sys/class/gpio/gpio22/value
      sudo killall piminicom
      sudo killall linbpq
      sudo touch /forcefsck

      #### Toggle Hello two more times before doing a shutdown of Linux
      echo "1" > /sys/class/gpio/gpio9/value
      
      #### Turn off the Linux-Is-Rising LED and turn on the Linux-Is-Falling LED
      #### These two writes are intended for the purchasers of the PWRMAN board, not for you cheapskates! 
      echo "1" > /sys/class/gpio/gpio25/value
      echo "0" > /sys/class/gpio/gpio9/value
      sleep 0.3
      echo "0" > /sys/class/gpio/gpio10/value
      sleep 0.3
      echo "1" > /sys/class/gpio/gpio9/value
      sleep 0.3
      echo "0" > /sys/class/gpio/gpio9/value
      sleep 0.3
      ### leave GPIO9 set high so one-button-shutdown users can see Broadcom go tristate
      echo "1" > /sys/class/gpio/gpio9/value

      sudo shutdown -h now
      sleep 900
      exit 0
}

perform_shutdown1button()  {
	#### turn off the PINLINBPQ LED immediately
      ### TARPN HOME shouldn't be running right now.  Stop it right now.  
      sudo rm -rf /usr/local/sbin/home_web_app/remove_me_to_stop_server.txt
      echo "0" > /sys/class/gpio/gpio22/value
      echo "0" > /sys/class/gpio/gpio9/value
      sleep 0.3
      echo "1" > /sys/class/gpio/gpio22/value
      echo "1" > /sys/class/gpio/gpio9/value
      echo -ne "\n1-button shutdown Button Pressed!!!  " >> $LOGFILE
      sleep 0.3
      echo "0" > /sys/class/gpio/gpio22/value
      echo "0" > /sys/class/gpio/gpio9/value
      date >> $LOGFILE
      uptime >> $LOGFILE
      sudo killall piminicom
      sudo killall linbpq
      sudo touch /forcefsck

      sudo shutdown -h now
      sleep 900
      exit 0
}

perform_reboot() {
    sudo touch /forcefsck
    ### turn off BPQ-is-running LED
    echo "0" > /sys/class/gpio/gpio22/value
    ### Turn off TARPN 0.5hz LED
    echo "0" > /sys/class/gpio/gpio9/value
    sleep 0.2
    echo "1" > /sys/class/gpio/gpio9/value
    sleep 0.2
    echo "0" > /sys/class/gpio/gpio9/value
    sleep 0.2
    echo "1" > /sys/class/gpio/gpio9/value
    sleep 0.2
    echo "0" > /sys/class/gpio/gpio9/value
    sleep 0.2
    echo "1" > /sys/class/gpio/gpio9/value
    sleep 0.2
    echo "0" > /sys/class/gpio/gpio9/value
    sleep 0.2
    echo "1" > /sys/class/gpio/gpio9/value
    sleep 0.2
    echo "0" > /sys/class/gpio/gpio9/value
    sleep 0.2
    echo "1" > /sys/class/gpio/gpio9/value
    sleep 0.2
    echo "0" > /sys/class/gpio/gpio9/value
    sleep 1
    sudo shutdown -r now;
}


LOGFILE="/var/log/tarpn_pwrman.log"
######################################################################################## VERSION INFO ####################################################################################################
####  2-13-2016 j101  Start from tarpn_background j102 
####  2-13-2016 j102  Invert the POWER-DOWN signal.  Temporarily disable the call to sudo shutdown 
####  2-13-2016 j103  put the call to sudo shutdown back.  Ready to ship? 
####  2-14-2016 j108  j104 through j107 were about moving the ribbon connector 1 step closer to USB connectors.  Move it back. 
####  2-14-2016 j109  add forcefsck
####  4-26-2016 j110  add some comments.  Get rid of waste-time-if-not-running()
####  5-27-2016 j111  Add support for GPIOs 25, 10 and 22 which will indicate BPQ status, as well as staying-up/going-down.
####  6-15-2016 j113  move the log file from /usr/local/etc to /var/log.  Change name of things from shutdown to tarpn_pwrman
####  6-24-2016 j114  Create a one-button-shutdown feature which runs if PWRMAN is not discovered. 
####  6-25-2016 j115  Debugging the one-button-shutdown feature 
####  6-26-2016 j116  One-Button-Shutdown works ok as does the PWRMAN
####  7-11-2016 j117  In PWRMAN shutdown, turn off LINBPQ LED a half second before the linux LEDs.
####  3-25-2017 j118  Fix version number so tarpn sysinfo can parse it.  
####  4-28-2018 s001  Leave GPIO-9 driven HIGH before shutdown linux so the observer can see when the Broadcom chip tristates.
####  7-01-2018 s002  Add LINUX and LINBPQ LEDs to one-button-shutdown.  Create dedicated perform-shutdown() function for 1-button
####  7-01-2018 s003  In perform_shutdown1button()  Write a line to the logfile when button is pressed, also blink the LEDs once.  
####  1-14-2019 s004  stop TARPN HOME at shutdown
####  3-18-2019 s005  in one-button-shutdown, if gpio23 is pulled high, do a shutdown -r
####  3-18-2019 s006  do shutdown at the bottom side of the loop-back test cycle as well as the top side
####  3-18-2019 s007  fix gpio23 in one-button-shutdown.  It was de-initialized after PWRMAN loopback fail. 
####  5-11-2019 s008  add code to support TARPN I2C-ASSIGN with bluetooth.
####  5-12-2019 s009  remove assign-write-completely-needed.txt  if we complete ok 
####  5-13-2019 s010  change the i2c-assign process again.  Now the process is completed manually using tarpn finish-i2c
####  5-13-2019 s011  debugging i2c-assign process
#### 10-12-2019 b001  remove i2c-assign process from pi-shutdown-background
####  5-28-2020 b002  add some fluff to the one-button-shutdown sequence
####  5-28-2020 b003  add some fluff to the one-button-shutdown sequence
####  5-28-2020 b005  add some fluff to the one-button-shutdown sequence
echo -ne "\n pi_shutdown_background.sh --VERSION-- b005 - start:" >> $LOGFILE
date >> $LOGFILE
uptime >> $LOGFILE







###### Make sure we have the GPIO export facility.  We always should, but if not, wait 15 minutes and then exit
if [ -f /sys/class/gpio/export ];
then
    echo "gpio export facility exists " >> $LOGFILE
else
	echo "ERROR0: /sys/class/gpio/export doesn't seem to exist." >> $LOGFILE
	date >> $LOGFILE
	sleep 900
	exit 1
fi

##### set up our GPIO ports to read and write the power management features

############ 
############ PWRMAN setup
############
###                 toward SDcard
### LED on PWRMAN GPIO 22     GPIO 23    <<====\
###               3V3 PWR     GPIO 24   high   |    if this is low, the rPI is not in this service, or is idle-off
### LED on PWRMAN GPIO 10     GROUND           |
###  .5hz output  GPIO  9     GPIO 25          |    LED on PWRMAN 
###  shutdown in  GPIO 11     GPIO  8    >>====/
###                toward USB
###
### If the circuit is properly connected, GPIO 8 and GPIO 23 will be tied together
### through a resistor.  If that is seen to be true, then this script will keep GPIO 9 toggling, GPIO 24 will
### be HIGH always, and GPIO 11 will be read as a SHUTDOWN pin.  
### IF GPIO 11 is read as a low, then do a shutdown command.  
####
#### GPIO  8 is output   (loopback test output to be read by gpio 23)
#### GPIO  9 is output   (toggle this at .5 hz)
#### GPIO 11 is input    (if this is high, do a shutdown)
#### GPIO 23 is input    (loopback test input) 
#### GPIO 24 is output   (high always)
#### GPIO 22 is output   (drive high if LINBPQ is running)      
#### GPIO 10 is output   (drive high if detect PWRMAN     )     
#### GPIO 25 is output   (drive high if PWRMAN says shut down)  


############ 
############ One Button Shutdown setup
############
###                            toward SDcard
###                          GPIO 22     GPIO 23  input - if high, do a reboot    
###                          3V3 PWR     GPIO 24  output high always when Linux is running   
### Shutdown when High input GPIO 10     GROUND           
###            .5hz output   GPIO  9     GPIO 25
###           /======= input GPIO 11     GPIO  8 output >>====\
###           |                 toward USB                    |
###           |                                               |
###           \===============================================/
###
### If the circuit is properly connected, GPIO 8 and GPIO 11 will be tied together
### through a jumper.  If that is seen to be true, then this script will keep GPIO 9 toggling
### GPIO 24 will be HIGH always, and GPIO 10 will be read as a SHUTDOWN pin.  
### IF GPIO 10 is read as a high, then do a shutdown command.  
####
#### GPIO  8 is output   (loopback test output to be read by gpio 11)
#### GPIO  9 is output   (toggle this at .5 hz)
#### GPIO 10 is input    (if this is high, do a shutdown)
#### GPIO 11 is input    (loopback test input) 


##### Touch FORCE-FSCK.  This tells Linux to set up for a full FSCK check the next time the Raspberry PI boots. 
sudo touch /forcefsck
   
#### __testResult will be 0 if nobody has failed. 
#### __testResult will be 1 if PWRMAN loopback has failed
__testResult=0;
__noFailures=0;

#### set-up for PWRMAN FIRST-RUN loopback test.   gpio8 drives loopback.  #23 is PWRMAN loopback input
echo "8" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio8/direction
echo "1" > /sys/class/gpio/gpio8/value
echo "23" > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio23/direction
#cat /sys/class/gpio/gpio23/value 

echo "1" > /sys/class/gpio/gpio8/value
_count=$(cat /sys/class/gpio/gpio23/value)
_value=1
if [ $_value -ne $_count ]; then
  echo "PWRMAN loopback cable fail at startup on first -1- echo test" >> $LOGFILE 
  echo "in" > /sys/class/gpio/gpio8/direction
  echo "8" > /sys/class/gpio/unexport
  echo "23" > /sys/class/gpio/unexport
  __testResult=1
fi
if [ $__testResult -eq $__noFailures ]; then
   echo "0" > /sys/class/gpio/gpio8/value
   _count=$(cat /sys/class/gpio/gpio23/value)
   _value=0
   if [ $_value -ne $_count ]; then
     echo "PWRMAN loopback cable fail at startup on 1st -0- (2nd) echo test" >> $LOGFILE 
     echo "in" > /sys/class/gpio/gpio8/direction
     echo "8" > /sys/class/gpio/unexport
     echo "23" > /sys/class/gpio/unexport
     __testResult=1
   fi
fi


if [ $__testResult -eq $__noFailures ]; then
   echo "1" > /sys/class/gpio/gpio8/value
   _count=$(cat /sys/class/gpio/gpio23/value)
   _value=1
   if [ $_value -ne $_count ]; then
     echo "PWRMAN loopback cable fail at startup on 2nd -1- (3rd) echo test" >> $LOGFILE 
     echo "in" > /sys/class/gpio/gpio8/direction
     echo "8" > /sys/class/gpio/unexport
     echo "23" > /sys/class/gpio/unexport
     __testResult=1
   fi
fi


if [ $__testResult -eq $__noFailures ]; then
echo "0" > /sys/class/gpio/gpio8/value
   _count=$(cat /sys/class/gpio/gpio23/value)
   _value=0
   if [ $_value -ne $_count ]; then
     echo "PWRMAN loopback cable fail at startup on 2nd -0- (4th) echo test" >> $LOGFILE 
     echo "in" > /sys/class/gpio/gpio8/direction
     echo "8" > /sys/class/gpio/unexport
     echo "23" > /sys/class/gpio/unexport
     __testResult=1
   fi
fi



if [ $__testResult -eq $__noFailures ]; then
   #### LOOPBACK test passes.  
   echo "####   PWRMAN loopback cable PASS at startup" >> $LOGFILE 

	#### GPIO  8 is output   (loopback test output to be read by gpio 23)
	#### GPIO  9 is output   (toggle this at .5 hz)
	#### GPIO 11 is input    (if this is high, do a shutdown)
	#### GPIO 23 is input    (loopback test input) 
	#### GPIO 24 is output   (high always)

	#### set up ports for power on toggle and power-off input

	#### port 24 is high-always to brag that we are up
	echo "24" > /sys/class/gpio/export
	echo "out" > /sys/class/gpio/gpio24/direction
	echo "1" > /sys/class/gpio/gpio24/value

	#### port 9 is toggle output
	echo "9" > /sys/class/gpio/export
	echo "out" > /sys/class/gpio/gpio9/direction
	echo "1" > /sys/class/gpio/gpio9/value

	#### port 11 is input for SHUTDOWN command
	echo "11" > /sys/class/gpio/export
	echo "in" > /sys/class/gpio/gpio11/direction
	_count=$(cat /sys/class/gpio/gpio11/value)
	_value=0
	if [ $_value -ne $_count ]; then
	   echo "Power-Off input port was at SHUTDOWN at start of the tarpn_pwrman.sh"  >> $LOGFILE
           ### TARPN HOME shouldn't be running right now.  Stop it right now.  
           sudo rm -rf /usr/local/sbin/home_web_app/remove_me_to_stop_server.txt
           sudo killall python
	   sudo touch /forcefsck
	   sleep 1
	   sudo shutdown -h now
	   sleep 900
	   exit
	fi

	################# It looks like we'll be up for a while. 
	##### Define the three LED output GPIOs to drive the LEDs on PWRMAN
	#### GPIO 22 is output   (drive high if LINBPQ is running)
	echo "22" > /sys/class/gpio/export
	echo "out" > /sys/class/gpio/gpio22/direction
	check_process "linbpq"
	if [ $? -ge 1 ]; then
	   ### BPQ node IS running
	   echo "1" > /sys/class/gpio/gpio22/value
	else
	   ### BPQ node is NOT running
	   echo "0" > /sys/class/gpio/gpio22/value
	fi

	#### GPIO 10 is output   (drive high if detect PWRMAN     )
	echo "10" > /sys/class/gpio/export
	echo "out" > /sys/class/gpio/gpio10/direction
	echo "1" > /sys/class/gpio/gpio10/value

	#### GPIO 25 is output   (drive high if PWRMAN says shut down)
	echo "25" > /sys/class/gpio/export
	echo "out" > /sys/class/gpio/gpio25/direction
	echo "0" > /sys/class/gpio/gpio25/value



	################# Firmware side is up and answering.  Enter power manager PI side mainloop here
	##### Here we flash the HELLO signal with a 1 second cycle time, and we hold the powered-up 
	##### output high.  

	################# LOOP HERE FOREVER
	#### Top of loop -- check if we should be calling linbpq or just waiting for a while. 
	while [ 1 ];
	do
	   #### HIGH portion   -- WRITE HIGH to the 1 second HELLO output
	   echo "1" > /sys/class/gpio/gpio9/value

	   #### Now make sure our loopback cable is still connected
	   echo "1" > /sys/class/gpio/gpio8/value
	   _count=$(cat /sys/class/gpio/gpio23/value)
	   _value=1
	   if [ $_value -ne $_count ]; then
		 echo "FAIL - PWRMAN loopback cable fail during runtime on -1- echo test (top)" >> $LOGFILE 
		 echo "in" > /sys/class/gpio/gpio8/direction
		 unexport_everything
		 sleep 900
		 exit 1
	   fi
   
	   ### we were able to read a high across the loopback.  now see if we can read a low
	   echo "0" > /sys/class/gpio/gpio8/value
	   _count=$(cat /sys/class/gpio/gpio23/value)
	   _value=0
	   if [ $_value -ne $_count ]; then
		 echo "FAIL - PWRMAN loopback cable fail during runtime on -0- echo test (top)" >> $LOGFILE 
		 echo "in" > /sys/class/gpio/gpio8/direction
		 unexport_everything
		 sleep 900
		 exit 1
	   fi

	   #### we were able to read a low across the output.  
	   #### Now see if the Firmware end wants us to shutdown
	   _count=$(cat /sys/class/gpio/gpio11/value)
	   _value=0
	   if [ $_value -ne $_count ]; then
		  echo "PWRMAN Power-Off input port is not low -- do SHUTDOWN (top)"  >> $LOGFILE
		  perform_shutdown
		  exit
	   fi
   
	   #### This sleep establishes the HELLO low half-wave cycle time
	   sleep 0.5
   
	   #### Light up the LINBPQ LED on GPIO22 if LINBPQ is running.  Turn it off if not. 
	   check_process "linbpq"
	   if [ $? -ge 1 ]; then
		  ### BPQ node IS running
		  echo "1" > /sys/class/gpio/gpio22/value
	   else
		  ### BPQ node is NOT running
		  echo "0" > /sys/class/gpio/gpio22/value
	   fi

	   ###  Light up the LINBPQ is up and staying up LED 
	   echo "1" > /sys/class/gpio/gpio10/value
   


	   #### LOW portion  -- Set the 1 second HELLO output to a low for half a second
	   echo "0" > /sys/class/gpio/gpio9/value


	   #### Now make sure our loopback cable is still connected
	   echo "1" > /sys/class/gpio/gpio8/value
	   _count=$(cat /sys/class/gpio/gpio23/value)
	   _value=1
	   if [ $_value -ne $_count ]; then
		 echo "FAIL - PWRMAN loopback cable fail during runtime on -1- echo test (bottom)" >> $LOGFILE 
		 echo "in" > /sys/class/gpio/gpio8/direction
		 unexport_everything
		 sleep 900
		 exit 1
	   fi

	   ### we were able to read a high across the loopback.  now see if we can read a low
	   echo "0" > /sys/class/gpio/gpio8/value
	   _count=$(cat /sys/class/gpio/gpio23/value)
	   _value=0
	   if [ $_value -ne $_count ]; then
		 echo "FAIL - PWRMAN loopback cable fail during runtime on -0- echo test (bottom)" >> $LOGFILE 
		 echo "in" > /sys/class/gpio/gpio8/direction
		 unexport_everything
		 sleep 900
		 exit 1
	   fi

	   #### we were able to read a low across the output.  
	   #### Now see if the Firmware end wants us to shutdown
	   _count=$(cat /sys/class/gpio/gpio11/value)
	   _value=0
	   if [ $_value -ne $_count ]; then
		  #### #### #### We ARE being told to shutdown.  
		  echo "PWRMAN Power-Off input port is not low -- do SHUTDOWN (bottom)"  >> $LOGFILE
		  perform_shutdown
		  exit
	   fi


	   #### This sleep establishes the HELLO high half-wave cycle time
	   sleep 0.5

	done
    exit 0
fi


echo "check to see if we're doing one-button shutdown mode"

############ 
############ One Button Shutdown setup
############
###                            toward SDcard
### output high if LINBPQ up GPIO 22     GPIO 23  input.  if high, do reboot 
###                          3V3 PWR     GPIO 24  output high if LINUX 
### Shutdown when High input GPIO 10     GROUND           
###            .5hz output   GPIO  9     GPIO 25 NC
###           /======= input GPIO 11     GPIO  8 output >>====\
###           |                 toward USB                    |
###           |                                               |
###           \===============================================/
###
### If the circuit is properly connected, GPIO 8 and GPIO 11 will be tied together
### through a jumper.  If that is seen to be true, then this script will keep GPIO 9 toggling
### GPIO24 will be HIGH always, and GPIO 10 will be read as a SHUTDOWN pin.  
### IF GPIO 10 is read as a high, then do a shutdown command.  
####
#### GPIO  8 is output   (loopback test output to be read by gpio 11)
#### GPIO  9 is output   (toggle this at .5 hz)
#### GPIO 10 is input    (if this is high, do a shutdown)
#### GPIO 11 is input    (loopback test input) 
#### GPIO 23 is input 


#### set-up for One-Button-Shutdown FIRST-RUN loopback test.
echo "8" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio8/direction
echo "1" > /sys/class/gpio/gpio8/value
echo "11" > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio11/direction



#cat /sys/class/gpio/gpio11/value 

echo "1" > /sys/class/gpio/gpio8/value
_count=$(cat /sys/class/gpio/gpio11/value)
_value=1
if [ $_value -ne $_count ]; then
  echo "FAIL - ONE-BUTTON loopback cable fail at startup on first -1- echo test" >> $LOGFILE 
  echo "in" > /sys/class/gpio/gpio8/direction
  echo "8" > /sys/class/gpio/unexport
  echo "11" > /sys/class/gpio/unexport
  sleep 900;
  exit 1
fi
echo "0" > /sys/class/gpio/gpio8/value
_count=$(cat /sys/class/gpio/gpio11/value)
_value=0
if [ $_value -ne $_count ]; then
  echo "FAIL - ONE-BUTTON loopback cable fail at startup on first -0- (2nd) echo test" >> $LOGFILE 
  echo "in" > /sys/class/gpio/gpio8/direction
  echo "8" > /sys/class/gpio/unexport
  echo "11" > /sys/class/gpio/unexport
  sleep 900;
  exit 1
fi


echo "1" > /sys/class/gpio/gpio8/value
_count=$(cat /sys/class/gpio/gpio11/value)
_value=1
if [ $_value -ne $_count ]; then
  echo "FAIL - ONE-BUTTON loopback cable fail at startup on 2nd -1- (3rd) echo test" >> $LOGFILE 
  echo "in" > /sys/class/gpio/gpio8/direction
  echo "8" > /sys/class/gpio/unexport
  echo "11" > /sys/class/gpio/unexport
  sleep 900;
  exit 1
fi


echo "0" > /sys/class/gpio/gpio8/value
_count=$(cat /sys/class/gpio/gpio11/value)
_value=0
if [ $_value -ne $_count ]; then
  echo "FAIL - ONE-BUTTON loopback cable fail at startup on 2nd -0- (4th) echo test" >> $LOGFILE 
  echo "in" > /sys/class/gpio/gpio8/direction
  echo "8" > /sys/class/gpio/unexport
  echo "11" > /sys/class/gpio/unexport
  sleep 900;
  exit 1
fi



#### LOOPBACK test passes.  
echo "####  ONE-BUTTON loopback cable PASS at startup" >> $LOGFILE 

#### port 9 is toggle output but only if we have mail??  
echo "9" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio9/direction
echo "1" > /sys/class/gpio/gpio9/value

#### port 10 is input for SHUTDOWN command
echo "10" > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio10/direction


#### port 23 is input for REBOOT command
echo "23" > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio23/direction

#### set up output 22 to say that LINBPQ is running
echo "22" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio22/direction
echo "0" > /sys/class/gpio/gpio22/value

#### set up output 24 to say that LINUX is running
echo "24" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio24/direction
echo "1" > /sys/class/gpio/gpio24/value




_count=$(cat /sys/class/gpio/gpio10/value)
_value=0
if [ $_value -ne $_count ]; then
   echo "Power-Off input port was at SHUTDOWN at start of the tarpn_pwrman.sh"  >> $LOGFILE
   sudo touch /forcefsck
   sleep 1
   sudo shutdown -h now
   sleep 900
   exit
fi


#### One Button Shutdown Loop
while [ 1 ];
do
   #### HIGH portion   -- WRITE HIGH to the 1 second HELLO output if we have mail
   echo "1" > /sys/class/gpio/gpio9/value

   #### Now make sure our loopback cable is still connected
   echo "1" > /sys/class/gpio/gpio8/value
   _count=$(cat /sys/class/gpio/gpio11/value)
   _value=1
   if [ $_value -ne $_count ]; then
	 echo "FAIL - loopback cable fail during runtime on -1- echo test (top)" >> $LOGFILE 
	 echo "in" > /sys/class/gpio/gpio8/direction
	 unexport_everything
	 sleep 900
	 exit 1
   fi

   ### we were able to read a high across the loopback.  Now see if we can read a low
   echo "0" > /sys/class/gpio/gpio8/value
   _count=$(cat /sys/class/gpio/gpio11/value)
   _value=0
   if [ $_value -ne $_count ]; then
	 echo "FAIL - loopback cable fail during runtime on -0- echo test (top)" >> $LOGFILE 
	 echo "in" > /sys/class/gpio/gpio8/direction
	 unexport_everything
	 sleep 900
	 exit 1
   fi

   #### we were able to read a low across the output.  
   #### Now see if the ONE-BUTTON end wants us to shutdown
   _count=$(cat /sys/class/gpio/gpio10/value)
   _value=0
   if [ $_value -ne $_count ]; then
	  echo "Power-Off input port is not low -- call SHUTDOWN (top)"  >> $LOGFILE
	  perform_shutdown1button
	  exit
   fi
   
   #### Now see if the REBOOT the PI input is high
   _count=$(cat /sys/class/gpio/gpio23/value)
   _value=0
   if [ $_value -ne $_count ]; then
	  echo "REBOOT input port is not low -- call REBOOT (top)"  >> $LOGFILE
          perform_reboot
	  exit
   fi
   
   ### If LINBPQ is running, turn on GPIO22 to drive an LED
   check_process "linbpq"
   if [ $? -ge 1 ]; then
      ### BPQ node IS running
      echo "1" > /sys/class/gpio/gpio22/value
   else
      ### BPQ node is NOT running
      echo "0" > /sys/class/gpio/gpio22/value
   fi





   #### This sleep establishes the HELLO low half-wave cycle time
   sleep 0.5

   #### LOW portion  -- Set the 1 second HELLO output to a low for half a second
   echo "0" > /sys/class/gpio/gpio9/value


   #### Now make sure our loopback cable is still connected
   echo "1" > /sys/class/gpio/gpio8/value
   _count=$(cat /sys/class/gpio/gpio11/value)
   _value=1
   if [ $_value -ne $_count ]; then
	 echo "FAIL - loopback cable fail during runtime on -1- echo test (bottom)" >> $LOGFILE 
	 echo "in" > /sys/class/gpio/gpio8/direction
	 unexport_everything
	 sleep 900
	 exit 1
   fi

   ### we were able to read a high across the loopback.  now see if we can read a low
   echo "0" > /sys/class/gpio/gpio8/value
   _count=$(cat /sys/class/gpio/gpio11/value)
   _value=0
   if [ $_value -ne $_count ]; then
	 echo "FAIL - loopback cable fail during runtime on -0- echo test (bottom)" >> $LOGFILE 
	 echo "in" > /sys/class/gpio/gpio8/direction
	 unexport_everything
	 sleep 900
	 exit 1
   fi

   #### we were able to read a low across the output.  
   #### Now see if the Firmware end wants us to shutdown
   _count=$(cat /sys/class/gpio/gpio10/value)
   _value=0
   if [ $_value -ne $_count ]; then
	  #### #### #### We ARE being told to shutdown.  
	  echo "Power-Off input port is not low -- do SHUTDOWN (bottom)"  >> $LOGFILE
	  perform_shutdown
	  exit
   fi

   #### Now see if the REBOOT the PI input is high
   _count=$(cat /sys/class/gpio/gpio23/value)
   _value=0
   if [ $_value -ne $_count ]; then
	  echo "REBOOT input port is not low -- call REBOOT (bottom)"  >> $LOGFILE
          perform_reboot
	  exit
   fi
   

   #### This sleep establishes the HELLO high half-wave cycle time
   sleep 0.5

done
exit 0




##### Comments from during my design work. 

# GPIO numbers should be from this list
# 0, 1, 4, 7, 8, 9, 10, 11, 14, 15, 17, 18, 21, 22, 23, 24, 25

# Note that the GPIO numbers that you program here refer to the pins
# of the BCM2835 and *not* the numbers on the pin header. 
# So, if you want to activate GPIO7 on the header you should be 
# using GPIO4 in this script. Likewise if you want to activate GPIO0
# on the header you should be using GPIO17 here.

# Set up GPIO 4 and set to output
#echo "4" > /sys/class/gpio/export
#echo "out" > /sys/class/gpio/gpio4/direction

# Set up GPIO 7 and set to input
#echo "7" > /sys/class/gpio/export
#echo "in" > /sys/class/gpio/gpio7/direction

# Write output
#echo "1" > /sys/class/gpio/gpio4/value

# Read from input
#cat /sys/class/gpio/gpio7/value 

# Clean up
#echo "4" > /sys/class/gpio/unexport
#echo "7" > /sys/class/gpio/unexport


