#!/bin/bash
# ===== Function List =====

# ===== function dbecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function ctrl_c trap handler
function ctrl_c() {
        echo "Exiting script from trapped CTRL-C"
	exit
}

# ===== function chk_root
function chk_root {
# Check for Root
if [[ $EUID != 0 ]] ; then
   echo "$scriptname: Must be root"
   exit 1
fi
}

# ===== function is_pkg_installed
function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== End Function List =====
