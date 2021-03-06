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
   echo "$scriptname: -- User Must be Root... Exiting!"
   echo "$(date "+%x %T"): $scriptname: # User Must be Root... Exiting!" >> $WL2KPI_INSTALL_LOGFILE
   exit 1
else 
	echo "$scriptname: User is Root... Proceeding!"
	echo "$(date "+%x %T"): $scriptname: # User is Root... Proceeding!" >> $WL2KPI_INSTALL_LOGFILE
fi
}

# function is_pkg_installed
function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# function chk_rpi_hardware
function chk_rpi_hardware {
	CPUINFO_FILE="/proc/cpuinfo"
	piver="$(grep "Revision" $CPUINFO_FILE)"
	piver="$(echo -e "${piver##*:}" | tr -d '[[:space:]]')"
	ver1B0="000d"     #### Pi  Model B Mfg by Egoman
	ver1B1="000e"
	ver2="000f"
	ver3="0010"
	ver4="0013"     ### Raspberry PI B + v2
	ver2B1="a01040" 	### Pi 2 Model B Mfg by Sony UK
	ver2B2="a01041"   ### Pi 2 Model B Mfg by Sony UK
	ver2B3="a21041"   ### Pi 2 Model B Mfg by Embest
	ver2B4="a22032"   ### Dylan's Raspberry PI 2B
	ver2B5="a22042"	### Pi 2 Model B with BCM2837 Mfg by Embest
	ver3B1="a02082"	### Pi 3 Model B Mfg by Sony UK
	ver3B2="a22082"   ### Pi 3 Model B Mfg by Embest
	ver3B3="a32082"   ### Pi 3 Model B Mfg by Sony Japan
	ver3B4="a020d3"   ### Pi 3 Model B+ Mfg by Sony UK
	ver7="900092"   #### Raspberry PI Zero
	ver4B1="a03111"   #### Pi 4 Model B 1GB Mfg by Sony
	ver4B2="b03111"   #### Pi 4 Model B 2GB Mfg by Sony
	ver4B3="c03111"   #### Pi 4 Model B 4GB Mfg by Sony
	ver4B4="a03112"   #### Raspberry Pi 4 Model B Rev 1.2 1GB
	ver4B5="b03112"   #### Raspberry Pi 4 Model B Rev 1.2 2GB
	ver4B6="c03112"   #### Raspberry Pi 4 Model B Rev 1.2 4GB
	IS_RPI_VALID=0
	HAS_WIFI=0
	HAS_BT=0
	if [ $piver == $ver3B1 ]; then
		IS_RPI_VALID=1
		HAS_WIFI=1
		HAS_BT=1
		echo
		echo -e "${Cyan}Hardware:${Green}RPi 3 Model B Mfg by Sony UK${Reset}"
		HARDWARE="RPi 3 Model B Mfg by Sony UK"
	fi
	if [ $piver == $ver3B2 ]; then
		IS_RPI_VALID=1
		HAS_WIFI=1
		HAS_BT=0
		echo
		echo -e "${Cyan}Hardware:${Green}  RPi 3 Model B Mfg by Embest${Reset}"
		HARDWARE="RPi 3 Model B Mfg by Embest"
	fi
	if [ $piver == $ver3B3 ]; then
		IS_RPI_VALID=1
		HAS_WIFI=1
		HAS_BT=1
		echo
		echo -e "${Cyan}Hardware:${Green}  RPi 3 Model B Mfg by Sony Japan${Reset}"
		HARDWARE="RPi 3 Model B Mfg by Sony Japan"
	fi
	if [ $piver == $ver3B4 ]; then
		IS_RPI_VALID=1
		HAS_WIFI=1
		HAS_BT=1
		echo
		echo -e "${Cyan}Hardware:${Green}  RPi 3 Model B+ Mfg by Sony UK${Reset}"
		HARDWARE="RPi 3 Model B+ Mfg by Sony UK"
	fi
	if [ $piver == $ver4B1 ]; then
		IS_RPI_VALID=1
		HAS_WIFI=1
		HAS_BT=1
		echo
		echo -e "${Cyan}Hardware:${Green}  RPi 4 Model B 1GB Mfg by Sony${Reset}"
		HARDWARE="RPi 4 Model B 1GB Mfg by Sony"
	fi
	if [ $piver == $ver4B2 ]; then
		IS_RPI_VALID=1
		HAS_WIFI=1
		HAS_BT=1
		echo
		echo -e "${Cyan}Hardware:${Green}  RPi 4 Model B 2GB Mfg by Sony${Reset}"
		HARDWARE="RPi 4 Model B 2GB Mfg by Sony"
	fi
	if [ $piver == $ver4B3 ]; then
		IS_RPI_VALID=1
		HAS_WIFI=1
		HAS_BT=1
		echo
		echo -e "${Cyan}Hardware:${Green}  RPi 4 Model B 4GB Mfg by Sony${Reset}"
		HARDWARE="RPi 4 Model B 4GB Mfg by Sony"
	fi
}
function chk_rpi_os {
	DIST=$(lsb_release -si)
	VER=""
	IS_OS_VALID=0
	read -d . VERSION < /etc/debian_version
	if [ $DIST != "Raspbian" ]; then
		echo -e "${Red}INVALID OS${Reset}"
		echo "A RASPBIAN OS IS REQUIRED. PLEASE USE A FRESH IMAGE."
		exit 1
	else
		echo -e "${Cyan}OS:${Green} $DIST${Reset}"
		if [ $VERSION -eq "8" ]; then
			VER="Jessie"
			IS_OS_VALID=1
			echo -e "${Cyan}Version:${Green} $VER${Reset}"
		elif [ $VERSION -eq "9" ]; then
			VER="Stretch"
			IS_OS_VALID=1
			echo -e "${Cyan}Version:${Green} $VER${Reset}"
		elif [ $VERSION -eq "10" ]; then
			VER="Buster"
			IS_OS_VALID=1
			echo -e "${Cyan}Version:${Green} $VER${Reset}"
		else
			echo "Not running Raspbian Jessie, Stretch or Buster ... exiting!"
			echo -e "${Cyan}OS${Reset} is ${Yellow}$DIST $VER : ${Red}Exiting!...${Reset}"
			exit 1
		fi
	fi
	echo -e "${Cyan}OS${Reset} is ${Yellow}$DIST $VER : ${Green}Proceeding...${Reset}"
	sleep 2
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
