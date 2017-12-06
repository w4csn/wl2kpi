#!/bin/bash

Rpt_Path=~/Downloads
D_Year=$(date '+%b. %d, %Y' -d "-1day")
D_Month=$(date '+%b %d' -d "-1day")

cd $Rpt_Path

# Delete and recreate file
if [ ! -e DailyRpt.txt ]; then
    touch DailyRpt.txt
else
    rm -f DailyRpt.txt
fi

# Open file descriptor (fd) 3 for read/write on a text file
exec 3<> DailyRpt.txt
    # write data to fd 3
    echo -e "RMS Gateway Daliy Report" >&3
    echo -e "   "$D_Year >&3
    echo -e >&3
    echo -e >&3
    echo -e "Successful Logins:" >&3
    grep "$D_Month" /var/log/rms | grep "Login" >&3

# Close fd 3
exec 3>&-
wl2ktelnet