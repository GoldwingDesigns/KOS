GLOBAL BOOTFILES is LIST("muntest_boot.ks").
GLOBAL LIBFILES is LIST(
    "muntest_t",
	"koos_mnv_lib_L",
    "koos_ves_lib_L",
    "lib_gui_dummy",
    "koos_lib_obtcalc",
    "koos_lib_hillclimb").
clearscreen.
print("Waiting for load...").
WAIT UNTIL SHIP:UNPACKED.
print("Waiting for connection...").



IF SHIP:STATUS = "PRELAUNCH"{
	for b in BOOTFILES {
        copypath("0:/"+b,"1:").
    }
    FOR f in LIBFILES {
		copypath("0:/"+f,"1:").
	}
}

switch to 1.
run muntest_t.