#!/bin/bash
#
# This script installs tools necessary for a TNC-Pi
# Configures rasberry pi for TNC-pi on /dev/ttyAMA0
# Uncomment this statement for debug echos
DEBUG=1
set -u # Exit if there are uninitialized variables.
scriptname="`basename $0`"
source $START_DIR/core/core_functions.sh