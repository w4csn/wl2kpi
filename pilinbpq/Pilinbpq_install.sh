#!/bin/bash
# Installs PiLinBPQ
# 
#
# Uncomment this statement for debug echos
DEBUG=1
set -u # Exit if there are uninitialized variables.
scriptname="`basename $0`"
source $START_DIR/core/core_functions.sh
# trap ctrl-c and call function ctrl_c()
trap ctrl_c INT


# ===== Function List =====

# ===== End of Functions list =====

# ===== Main
SOURCE_DIR=$START_DIR/pilinbpq/src
echo "$(date "+%Y %m %d %T %Z"): linbpq_install.sh: LinBPQInstallation Completed" >> $WL2KPI_INSTALL_LOGFILE
echo "$(date "+%Y %m %d %T %Z"): linbpq_install.sh: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW} pilinbpq_install.sh: script FINISHED ${Reset}"
echo
# ===== End Main =====