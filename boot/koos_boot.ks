CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
GLOBAL BOOTFILES is LIST("koos_boot.ks").
GLOBAL LIBFILES is LIST(
	"koos_loop.ks",
	"koos_init.ks",
	"lib_utils.ks",
	"koos_maneuvers.ks",
	"lib_gui_box.ks",
	"lib_hillclimb.ks",
	"lib_gui_func.ks",
	"lib_lazcalc.ks").
clearscreen.
print("Waiting for load...").
WAIT UNTIL SHIP:UNPACKED.
print("Waiting for connection...").



IF SHIP:STATUS = "PRELAUNCH"{
	FOR f in LIBFILES {
		copypath("0:/"+f,"1:").
	}
}

switch to 1.
run koos_init.





