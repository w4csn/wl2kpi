#!/bin/bash
# Installs/Updates PiBPQ
# 
#
# Uncomment this statement for debug echos
DEBUG=1
set -u # Exit if there are uninitialized variables.
scriptname="`basename $0`"
source $START_DIR/core/core_functions.sh
linbpq_source=http://www.cantab.net/users/john.wiseman/Downloads
# trap ctrl-c and call function ctrl_c()
trap ctrl_c INT


# ===== Function List =====

# ===== End of Functions list =====

# ===== Main
##Set the source folder for files needed to install BPQ
SOURCE_DIR=$START_DIR/pilinbpq/src
echo "* Reinstall IPUTILS-PING"
sudo apt install --reinstall iputils-ping

echo "$(date "+%Y %m %d %T %Z"): linbpq_install.sh: LinBPQInstallation Completed" >> $WL2KPI_INSTALL_LOGFILE
echo "$(date "+%Y %m %d %T %Z"): linbpq_install.sh: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW} pilinbpq_install.sh: script FINISHED ${Reset}"
echo
# ===== End Main =====