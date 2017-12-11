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