# RMS Gateway installation

#### Notes on compiling if downloading from source
rmsgw-2.4.0-181 and 182 will not compile on Raspbian Jessie or stretch
due to a strict interpretation of boolean library. Must use <stdbool.h>
instead of manually defining boolean flags. 

````bash
include/rmslib.h  
           add
                 #include <stdbool.h>
           remove        
                  #ifndef TRUE
                  typedef	int	bool;	/* boolean flag */
                  #define TRUE	1
                  #define	FALSE	0
                  #endif

          librms/cmslogin.c
            replace all "TRUE" or "FALSE" with "true" or "false repsectively.

          librms/file_exists.c
            replace all "TRUE" or "FALSE" with "true" or "false repsectively.
````



#### Notes on rmschanstat
rmschanstat is the script that determines if your rms gateway is functioning. It's called by rms_aci via a cron job. 
If all checks are ok, then the results are posted to the winlink web site. 
This keeps your station alive on the winlink map. otherwise after four hours your station will drop off the map.
There is an issue with rmschanstat that prevents it from returning an available status on a RPI3 with Raspbian Stretch.
It exist in the check_ax25_netstat functions, which simply greps the netstat command for the ax25 protocol, the interface (which would usually be ax0 from ifconfig), and the callsign.
everything is returned true exept the interface, so i can be reasonably assured the interface is actually working.

I simply edited the following line (200) in the check_ax25_netstat function on /usr/local/sbin/rmschanstat.
 
from:
````bash
	STATUS=($netstat --protocol=ax25 -l | grep "${INTERFACE[0]})" | grep -i "${CALL}" | grep -i "LISTENING"))
````
to:
````bash
	STATUS=($netstat --protocol=ax25 -l | grep -i "${CALL}" | grep -i "LISTENING"))
````