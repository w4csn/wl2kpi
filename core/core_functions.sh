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
else 
	echo "scriptname: User is root"
fi
}

# function is_pkg_installed
function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# function is_rpi_valid
function is_rpi_valid {
	local CPUINFO_FILE="/proc/cpuinfo"
	local piver="$(grep "Revision" $CPUINFO_FILE)"
	local piver="$(echo -e "${piver##*:}" | tr -d '[[:space:]]')"
	local ver1B0="000d"     #### Pi  Model B Mfg by Egoman
	local ver1B1="000e"
	local ver2="000f"
	local ver3="0010"
	local ver4="0013"     ### Raspberry PI B + v2
	local ver2B1="a01040" 	### Pi 2 Model B Mfg by Sony UK
	local ver2B2="a01041"   ### Pi 2 Model B Mfg by Sony UK
	local ver2B3="a21041"   ### Pi 2 Model B Mfg by Embest
	local ver2B4="a22032"   ### Dylan's Raspberry PI 2B
	local ver2B5="a22042"	### Pi 2 Model B with BCM2837 Mfg by Embest
	local ver3B1="a02082"	### Pi 3 Model B Mfg by Sony UK
	local ver3B2="a22082"   ### Pi 3 Model B Mfg by Embest
	local ver3B3="a32082"   ### Pi 3 Model B Mfg by Sony Japan
	local ver3B4="a020d3"   ### Pi 3 Model B+ Mfg by Sony UK
	local ver7="900092"   #### Raspberry PI Zero
	local ver4B1="a03111"   #### Pi 4 Model B 1GB Mfg by Sony
	local ver4B2="b03111"   #### Pi 4 Model B 2GB Mfg by Sony
	local ver4B4="c03111"   #### Pi 4 Model B 4GB Mfg by Sony$
	local ver4B5="a03112"   #### Raspberry Pi 4 Model B Rev 1.2 1GB
	local ver4B6="b03112"   #### Raspberry Pi 4 Model B Rev 1.2 2GB
	local ver4B7="c03112"   #### Raspberry Pi 4 Model B Rev 1.2 4GB
	local version_ok=0
	if [ $piver == ver3B1 ]; then
		local version_ok=1
		echo
		echo -e "${Red} Pi 3 Model B Mfg by Sony UK${Reset}"
		echo 
	fi
	if [ $piver == ver3B2 ]; then
		local version_ok=1
		echo
		echo -e "${Red} Pi 3 Model B Mfg by Embest${Reset}"
		echo 
	fi
	if [ $piver == ver3B3 ]; then
		local version_ok=1
		echo
		echo -e "${Red} Pi 3 Model B Mfg by Sony Japan${Reset}"
		echo 
	fi
	if [ $piver == ver3B4 ]; then
		local version_ok=1
		echo
		echo -e "${Red} Pi 3 Model B+ Mfg by Sony UK${Reset}"
		echo 
	fi
}
# function is_rpi3
function is_rpi3 {

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
   pi_result='Pi 3 Model B Mfg by Sony UK'
   echo
   HAS_WIFI=1
;;
a22082)
   echo
   echo -e "${Green} Pi 3 Model B Mfg by Embest${Reset}"
   pi_result='Pi 3 Model B Mfg by Embest'
   echo
   HAS_WIFI=1
;;
a32082)
   echo
   echo -e "${Green} Pi 3 Model B Mfg by Sony Japan${Reset}"
   pi_result='Pi 3 Model B Mfg by Sony Japan'
   echo
   HAS_WIFI=1
;;
a020d3)
   echo
   echo -e "${Green) Pi 3 Model B+ Mfg by Sony UK${Reset}"
   pi_result='Pi 3 Model B+ Mfg by Sony UK'
   echo
   HAS_WIFI=1
;;
a03111)
   echo
   echo -e "${Green) Pi 4 Model B 1GB Mfg by Sony${Reset}"
   echo
   HAS_WIFI=1
;;
b03111)
   echo
   echo -e "${Green) Pi 4 Model B 2GB Mfg by Sony${Reset}"
   echo
   HAS_WIFI=1
;;
c03111)
   echo
   echo -e "${Green) Pi 4 Model B 4GB Mfg by Sony${Reset}"
   echo
   HAS_WIFI=1
;;
esac

}

# function is_rasbian
function is_raspbian {
HAS_RASPBIAN=0
DIST=$(lsb_release -si)
VER=""
read -d . VERSION < /etc/debian_version
if [ $DIST != "Raspbian" ]; then
	echo -e "${Red}INVALID OS${Reset}"
	echo "RASPBIAN JESSIE or STRETCH IS REQUIRED. PLEASE USE A FRESH IMAGE."
else
	$HAS_RASPBIAN=1
	echo -e "${Cyan}OS:${Green} $DIST${Reset}"
	if [ $VERSION -eq "8" ]; then
		VER="Jessie"
		echo -e "${Cyan}Version:${Green} $VER${Reset}"
	elif [ $VERSION -eq "9" ]; then
		VER="Stretch"
		echo -e "${Cyan}Version:${Green} $VER${Reset}"
	elif [ $VERSION -eq "10" ]; then
		VER="Buster"
		echo -e "${Cyan}Version:${Green} $VER${Reset}"
	else
		echo -e "${Red}INVALID VERSION${Reset}"		
		echo "RASPBIAN JESSIE, STRETCH OR BUSTER IS REQUIRED. PLEASE USE A FRESH IMAGE."
		$HAS_RASPBIAN=0
	fi
fi
echo -e "${Cyan}OS${Reset} is ${Yellow}$DIST $VER : ${Green}Proceeding...${Reset}"
sleep 2
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

function showContactMessage() {
	echo "***"
	echo "**** Something bad happened. "
	echo "**** Contact snewton86@gmail.com"
	echo -n
	echo "Please Send the log from /var/log/wl2kpi_install.log"
	echo "Thank you!"
	echo "***"
	return 0;
}

# function spinner -- BROKEN!!
#function spinner() {
#local -r pid="${1}"
#local -r delay='0.75'
#local spinstr='|/-\'
#local temp
#while ps a | awk '{print $1}' | grep -q "${pid}"; do
#    temp="${spinstr#?}"
#    printf " [%c]  " "${spinstr}"
#    spinstr=${temp}${spinstr%"${temp}"}
#    sleep "${delay}"
#    printf "\b\b\b\b\b\b"
#done
#printf "    \b\b\b\b"
#
#}


# ===== End Function List =====
