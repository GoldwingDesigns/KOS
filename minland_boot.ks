GLOBAL BOOTFILES is LIST("mintest_boot.ks").
GLOBAL LIBFILES is LIST(
    "minland",
	"koos_mnv_lib_L",
    "koos_ves_lib_L",
    "lib_gui_dummy",
    "koos_lib_obtcalc",
    "koos_lib_hillclimb").
clearscreen.
print("Waiting for load...").
WAIT UNTIL SHIP:UNPACKED.
print("Waiting for connection...").



// IF SHIP:STATUS = "PRELAUNCH"{
	for b in BOOTFILES {
        copypath("0:/"+b,"1:").
    }
    FOR f in LIBFILES {
		copypath("0:/"+f,"1:").
	}
    print("Files Copied").
// }

switch to 1.
run minland.