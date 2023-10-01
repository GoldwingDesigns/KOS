SET CONFIG:TELNET TO TRUE.
GLOBAL MSGQ to QUEUE().     //these globals might be able to be deleted.
GLOBAL STARTTIME to 0.      // |
GLOBAL COMPMODE to 0.       // |
GLOBAL CPUINITIALIZED to 0. // |
GLOBAL WARNSTATE to 0.      // |
GLOBAL INMENU to FALSE.     // |
GLOBAL LOGMSGS to TRUE.
GLOBAL BOOTVOLUME to "MASTER_DISK".
GLOBAL DATAVOLUME to "SLAVE_1_DISK".
GLOBAL BOOTFILES is LIST("koos_term_lander_boot_FORE").
GLOBAL LIBFILES is LIST(
    "koos_mission_runner_L",
    "koos_sys_lib_L",
	"koos_mnv_lander_lib_L",
    "koos_ves_lib_L",
    "koos_utils_lib_L",
    "koos_ui_term_L",
    "koos_obtcalc_lander_lib").
clearscreen.
print("Waiting for load...").
WAIT UNTIL SHIP:UNPACKED.
print("Waiting for connection...").
LIST PROCESSORS in ALL_PROCESSORS.
local i is 1.
local activeprocessors is 0.
for p in ALL_PROCESSORS{
    if p:TAG:contains("lander") {
        if p:BOOTFILENAME:contains("boot") {
            set p:TAG to "MASTER".
            set p:volume:name to BOOTVOLUME.			
        } else {
            set p:TAG to "SLAVE_"+i.
            SET p:VOLUME:NAME TO p:TAG+"_DISK".
            print(p:VOLUME:NAME+" found."). //pass slave cpu obj, boot filename, volume number
            if(i=1){set DATAVOLUME to p:VOLUME:NAME. print (p:VOLUME:NAME+" set to data volume.").}
            set i to i+1.
        }
        set activeprocessors to activeprocessors+1.
	} else {
        p:deactivate().
    }
}
if activeprocessors = 1 {set DATAVOLUME to BOOTVOLUME.}
IF SHIP:STATUS = "PRELAUNCH" or homeConnection:isconnected { //create a check here to see if there is an update
	for b in BOOTFILES {
        compile "0:/boot/"+b to BOOTVOLUME+":/boot/"+b.
        // copypath("0:/boot/"+b+".ks",BOOTVOLUME+":/boot/"+b).
    }
    for f in LIBFILES {
        compile "0:/"+f to DATAVOLUME+":/"+f.
		// copypath("0:/"+f+".ks",DATAVOLUME+":/"+f).
        
		//copypath("0:/"+f,"1:").
	}
    print("Files Copied").
}

switch to DATAVOLUME.
run koos_mnv_lander_lib_L.
run koos_ves_lib_L.
run koos_sys_lib_L.
run koos_utils_lib_L.
run koos_mission_runner_L.
run koos_ui_term_L.

switch to BOOTVOLUME.

global VES1 to VES["new"](ship,"fore").
local is_analog to false.
UI["run"](is_analog).