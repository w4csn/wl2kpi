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
a01040)
   echo " Pi 2 Model B Mfg by Unknown"
;;
a01041)
   echo " Pi 2 Model B Mfg by Sony"
;;
a21041)
   echo " Pi 2 Model B Mfg by Embest"
;;
a22042)
   echo " Pi 2 Model B with BCM2837 Mfg by Embest"
;;
a02082)
   echo " Pi 3 Model B Mfg by Sony"
   HAS_WIFI=1
;;
a22082)
   echo " Pi 3 Model B Mfg by Embest"
   HAS_WIFI=1
;;
esac

return $HAS_WIFI
}

# function is_rasbian
function is_rasbian() {
HAS_RASBIAN=0
DIST=$(lsb_release -si)
read -d . VERSION < /etc/debian_version
if [ $DIST -ne "Rasbian" ]; then
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
echo "OS is $DIST $VER : Proceeding..."
sleep 3
return $HAS_RASBIAN
}
# ===== End Function List =====
