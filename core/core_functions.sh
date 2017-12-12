#!/bin/bash
# ===== Function List =====

# ===== function dbecho
function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function chk_root
function chk_root {
# Check for Root
if [[ $EUID != 0 ]] ; then
   echo -e "Must be root"
   exit 1
fi
}
# ===== End Function List =====
