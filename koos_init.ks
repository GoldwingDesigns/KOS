//@lazyglobal off.
SET CONFIG:TELNET TO TRUE.
GLOBAL MSGQ to QUEUE(). 
GLOBAL STARTTIME to 0.
GLOBAL COMPMODE to 0.
GLOBAL CPUINITIALIZED to 0.
GLOBAL WARNSTATE to 0.
GLOBAL INMENU to FALSE.
run lib_utils.


// WAIT 1.
// }
// ELSE {
	clearscreen.
	IF HOMECONNECTION:ISCONNECTED{
		local ufile to SHIP:NAME+".update.ks".
		print("Update received...").
		if utils_hasFile(ufile,0) { 
			utils_retrieveFile(ufile,0). 
			runpath(ufile).
		}
	}
// }

LIST PROCESSORS in ALL_PROCESSORS.	
//IF ALL_PROCESSORS:LENGTH < 2 { //standalone mode
//clearscreen.
//	IF NOT gui_menu_prompt_yn("Only one processor onboard. Continue in standalone mode?") {
//		clearscreen.
//		KUNIVERSE:PAUSE(). //if we decided that we wanted > 1 processor but it could not find -> pause and end program
//		PROCESSOR(VOLUME(1)):DEACTIVATE().
//	}
//}
local i is 0.
SET VOLUME(1):NAME TO "Master_Disk".
print(VOLUME(1):NAME).
for p in ALL_PROCESSORS{
	print p:bootfilename.
	if p:BOOTFILENAME:contains("koos_boot") {
		set p:TAG to "MASTER".			
	} else {
		set p:TAG to "SLAVE_"+i.
		utils_slaveInit(p,"boot/koos_slave.ks",i+2). //pass slave cpu obj, boot filename, volume number
		set i to i+2.
	}
}

run lib_gui_func.
run koos_maneuvers.


set CPUINITIALIZED to 1.

gui_scr_init().

run koos_loop.
