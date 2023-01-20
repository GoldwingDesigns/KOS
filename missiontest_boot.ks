SET CONFIG:TELNET TO TRUE.
GLOBAL MSGQ to QUEUE().     //these globals might be able to be deleted.
GLOBAL STARTTIME to 0.      // |
GLOBAL COMPMODE to 0.       // |
GLOBAL CPUINITIALIZED to 0. // |
GLOBAL WARNSTATE to 0.      // |
GLOBAL INMENU to FALSE.     // |

GLOBAL BOOTFILES is LIST("mintest_boot.ks").
GLOBAL LIBFILES is LIST(
    "missiontest_mission",
    "koos_mission_runner",
	"koos_mnv_lib_L",
    "koos_ves_lib_L",
    "lib_gui_dummy",
    "koos_lib_obtcalc",
    "koos_lib_hillclimb").
clearscreen.
print("Waiting for load...").
WAIT UNTIL SHIP:UNPACKED.
print("Waiting for connection...").



// IF SHIP:STATUS = "PRELAUNCH"{ //create a check here to see if there is an update
	for b in BOOTFILES {
        copypath("0:/"+b,"1:").
    }
    FOR f in LIBFILES {
		copypath("0:/"+f,"1:").
	}
    print("Files Copied").
// }

switch to 1.
run missiontest_mission.