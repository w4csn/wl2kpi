#!/bin/bash
# ===== Function List =====

# function dbecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function ctrl_c trap handler
function ctrl_c() {
        echo "Exiting script from trapped CTRL-C"
	exit
}

# function chk_root
function chk_root {
# Check for Root
if [[ $EUID != 0 ]] ; then
   echo "$scriptname: Must be root"
   exit 1
fi
}

# function is_pkg_installed
function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# function is_rpi3
function is_rpi3() {

CPUINFO_FILE="/proc/cpuinfo"
HAS_WIFI=0

piver="$(grep "Revision" $CPUINFO_FILE)"
piver="$(echo -e "${piver##*:}" | tr -d '[[:space:]]')"

case $piver in
000d)
	echo
	echo -e "${Red} Pi  Model B Mfg by Egoman${Reset}"
	echo
;;
a01040)
   echo
   echo -e "${Red} Pi 2 Model B Mfg by Sony UK${Reset}"
   echo
;;
a01041)
   echo
   echo -e "${Red} Pi 2 Model B Mfg by Sony UK${Reset}"
   echo
;;
a21041)
   echo 
   echo -e "${Red} Pi 2 Model B Mfg by Embest${Reset}"
   echo
;;
a22042)
   echo
   echo -e "${Red} Pi 2 Model B with BCM2837 Mfg by Embest${Reset}"
   echo
;;
a02082)
   echo
   echo -e "${Green} Pi 3 Model B Mfg by Sony UK${Reset}"
   echo
   HAS_WIFI=1
;;
a22082)
   echo
   echo -e "${Green} Pi 3 Model B Mfg by Embest${Reset}"
   echo
   HAS_WIFI=1
;;
a32082)
   echo
   echo -e "${Green} Pi 3 Model B Mfg by Sony Japan${Reset}"
   echo
   HAS_WIFI=1
;;
esac

return $HAS_WIFI
}

# function is_rasbian
function is_rasbian() {
HAS_RASBIAN=0
DIST=$(lsb_release -si)
VER=""
read -d . VERSION < /etc/debian_version
if [ $DIST != "Raspbian" ]; then
	echo "INVALID OS"
	echo "RASPBIAN JESSIE or STRETCH IS REQUIRED. PLEASE USE A FRESH IMAGE."
else
	$HAS_RASBIAN=1
	echo "OS: $DIST"
	if [ $VERSION -eq "8" ]; then
		$VER="Jessie"
		echo "Version: Jessie"
		
	elif [ $VERSION -eq "9" ]; then
		$VER="Stretch"
		echo "Version: Stretch"
	else
		echo "INVALID VERSION"	
		echo "RASPBIAN JESSIE or STRETCH IS REQUIRED. PLEASE USE A FRESH IMAGE."
		$HAS_RASBIAN=0
	fi
fi
echo "OS is $DIST $VER : Proceeding..."
sleep 3
return $HAS_RASBIAN
}

# function chk_service
function chk_service() {
systemctl is-active $service_name >/dev/null
	if [ $? -eq 0 ]; then
		echo "$service_name is running"
	else
		echo "$service_name is NOT running"
   fi
}

# function to draw progress bar
function progressBar() {
  # Calculate number of fill/empty slots in the bar
  progress=$(echo "$progressBarWidth/$taskCount*$tasksDone" | bc -l)  
  fill=$(printf "%.0f\n" $progress)
  if [ $fill -gt $progressBarWidth ]; then
    fill=$progressBarWidth
  fi
  empty=$(($fill-$progressBarWidth))

  # Percentage Calculation
  percent=$(echo "100/$taskCount*$tasksDone" | bc -l)
  percent=$(printf "%0.2f\n" $percent)
  if [ $(echo "$percent>100" | bc) -gt 0 ]; then
    percent="100.00"
  fi

  # Output to screen
  printf "\r["
  printf "%${fill}s" '' | tr ' ' ▉
  printf "%${empty}s" '' | tr ' ' ░
  printf "] $percent%% - $text "
}


# ===== End Function List =====
