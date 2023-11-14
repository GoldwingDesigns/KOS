SET CONFIG:TELNET TO TRUE.
// GLOBAL MSGQ to QUEUE().     //these globals might be able to be deleted.
GLOBAL STARTTIME to 0.      // |
// GLOBAL CPUINITIALIZED to 0. // |
// GLOBAL WARNSTATE to 0.      // |
// GLOBAL INMENU to FALSE.     // |
GLOBAL LOGMSGS to TRUE.
GLOBAL BOOTVOLUME to "MASTER_DISK".
GLOBAL DATAVOLUME to "SLAVE_1_DISK".
GLOBAL BOOTFILES is LIST("koos_boot").
GLOBAL LEXFILES is LIST(
    "koos_mission_runner_lex",
    "koos_sys_lex",
	"koos_mnv_lex",
    "koos_ves_lex",
    "koos_utl_lex",
    "koos_ui_lex").
GLOBAL LIBFILES is LIST(
    "koos_pathfinding_lib",
    "lib_enum",
    "koos_mnv_lib",
    "koos_obtcalc_lib",
    "koos_hillclimb_lib").
clearscreen.
print("Waiting for load...").
WAIT UNTIL SHIP:UNPACKED.
print("Waiting for connection...").
LIST PROCESSORS in ALL_PROCESSORS.
local i is 1.
local activeprocessors is 0.
local elementParts to core:element:parts.
for p in ALL_PROCESSORS{
    if elementParts:contains(p:part){
        // if p:TAG = ""{
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
        // } else {
        //     p:deactivate().
        // }
    }
}
if activeprocessors = 1 {set DATAVOLUME to BOOTVOLUME.}
IF SHIP:STATUS = "PRELAUNCH" or homeConnection:isconnected { //create a check here to see if there is an update
	for b in BOOTFILES {
        compile "0:/boot/"+b to BOOTVOLUME+":/boot/"+b.
        //copypath("0:/boot/"+b+".ksm","1:/boot/").
    }
    for f in LIBFILES {
        compile "0:/"+"lib/"+f to DATAVOLUME+":/"+"lib/"+f.
		//copypath("0:/"+f+".ksm","1:").
        
		//copypath("0:/"+f,"1:").
	}
    for f in LEXFILES {
        compile "0:/"+"lex/"+f to DATAVOLUME+":/"+"lex/"+f.
		//copypath("0:/"+f+".ksm","1:").
        
		//copypath("0:/"+f,"1:").
	}
    print("Files Copied").
}

switch to DATAVOLUME.
runpath(DATAVOLUME+":/lex/koos_mnv_lex").
runpath(DATAVOLUME+":/lex/koos_ves_lex").
runpath(DATAVOLUME+":/lex/koos_sys_lex").
runpath(DATAVOLUME+":/lex/koos_utl_lex").
runpath(DATAVOLUME+":/lex/koos_mission_runner_lex").
runpath(DATAVOLUME+":/lex/koos_ui_lex").

switch to BOOTVOLUME.
UTL["refresh config files"]().
global VES1 to VES["new"](ship,UTL["read config"]()).

UI["run"]().