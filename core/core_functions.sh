
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
