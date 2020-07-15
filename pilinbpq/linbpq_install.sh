#!/bin/bash
# Installs/Updates LinBPQ
# 
#
# Uncomment this statement for debug echos
DEBUG=1
set -u # Exit if there are uninitialized variables.
source $START_DIR/core/core_functions.sh


# ===== Function List =====

# ===== End of Functions list =====

# ===== Main

echo "$(date "+%Y %m %d %T %Z"): linbpq_install.sh: LinBPQInstallation Completed" >> $WL2KPI_INSTALL_LOGFILE
echo "$(date "+%Y %m %d %T %Z"): linbpq_install.sh: script FINISHED" >> $WL2KPI_INSTALL_LOGFILE
echo
echo -e "${BluW} linbpq_install.sh: script FINISHED ${Reset}"
echo
# ===== End Main =====