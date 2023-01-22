SET CONFIG:TELNET TO TRUE.
GLOBAL MSGQ to QUEUE().     //these globals might be able to be deleted.
GLOBAL STARTTIME to 0.      // |
GLOBAL COMPMODE to 0.       // |
GLOBAL CPUINITIALIZED to 0. // |
GLOBAL WARNSTATE to 0.      // |
GLOBAL INMENU to FALSE.     // |
GLOBAL LOGMSGS to FALSE.

GLOBAL BOOTFILES is LIST("koos_term_boot").
GLOBAL LIBFILES is LIST(
    "koos_mission_runner_L",
    "koos_sys_lib_L",
	  "koos_mnv_small_lib_L",
    "koos_ves_lib_L",
    "koos_utils_small_lib_L",
    "koos_ui_term_L",
    "koos_obtcalc_small_lib",
    "koos_hillclimb_lib").
clearscreen.
print("Waiting for load...").
WAIT UNTIL SHIP:UNPACKED.
print("Waiting for connection...").

IF SHIP:STATUS = "PRELAUNCH" or homeConnection:isconnected { //create a check here to see if there is an update
	for b in BOOTFILES {
        compile "0:/boot/"+b to "1:/boot/"+b.
        //copypath("0:/boot/"+b+".ksm","1:/boot/").
    }
    for f in LIBFILES {
        compile "0:/"+f to "1:/"+f.
		//copypath("0:/"+f+".ksm","1:").
        
		//copypath("0:/"+f,"1:").
	}
    print("Files Copied").
}

switch to 1.
run koos_mnv_small_lib_L.
run koos_ves_lib_L.
run koos_sys_lib_L.
run koos_utils_small_lib_L.
run koos_mission_runner_L.
run koos_ui_term_L.


global VES1 to VES["new"](ship).

UI["run"]().