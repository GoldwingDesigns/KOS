// #EXTERNAL_IDS lazyGlobal, MNV, MNV_TMP, VES, VES1, UTL, UI, SYS, man_check_stage, find_burntime, find_eta_to_true_anomaly, plane_change_info, find_landing_tgt_LAN,get_path_to_apprpoint,find_landing_tgt_LAN_lowalt, unlock_all, orbit_circumference, circle_distance, LAZcalc, LAZcalc_init, pitchangle, hillclimb,etatoaltitude2
SET CONFIG:TELNET TO TRUE.
GLOBAL STARTTIME to 0.
GLOBAL LOGMSGS to TRUE.
GLOBAL BOOTVOLUME to "MASTER_DISK".
GLOBAL DATAVOLUME to "SLAVE_1_DISK".
GLOBAL BOOTFILES is LIST("koos_boot").
GLOBAL BOOTLEXFILES is LIST(
    "koos_mission_runner_lex",
    "koos_sys_lex",
    "koos_ves_lex",
    "koos_utl_lex",
    "koos_ui_lex").
GLOBAL BOOTLIBFILES is LIST(
    // "placeholder_lib",
).
GLOBAL LEXFILES is BOOTLEXFILES.
GLOBAL LIBFILES is BOOTLIBFILES.
clearscreen.
print("Waiting for load...").
WAIT UNTIL SHIP:UNPACKED.
print("Waiting for connection...").
LIST PROCESSORS in ALL_PROCESSORS.
local i is 1.
local activeprocessors is 0.
local shipcapacity to 0.
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
    set shipcapacity to shipcapacity + p:volume:capacity.
}
if activeprocessors = 1 {set DATAVOLUME to BOOTVOLUME.}

IF SHIP:STATUS = "PRELAUNCH" or homeConnection:isconnected { //create a check here to see if there is an update
	for b in BOOTFILES {
        copypath("0:/boot/"+b+".ks","1:/boot/").
    }
    for f in LIBFILES {
        compile "0:/"+"lib/"+f to DATAVOLUME+":/"+"lib/"+f.
	}
    for f in LEXFILES {
        compile "0:/"+"lex/"+f to DATAVOLUME+":/"+"lex/"+f.
	}
    print("Files Copied").
}

switch to DATAVOLUME.
for f in LIBFILES {
    runPath(DATAVOLUME+":/lib/"+f).
}
for f in LEXFILES {
    runPath(DATAVOLUME+":/lex/"+f).
}

switch to BOOTVOLUME.
UTL["refresh config files"]().
global VES1 to VES["new"](ship,UTL["read config"]()).

GLOBAL MNV is lex().
// if shipcapacity > 200000 UTL["build MNV lex"](list("all")).
// else
 UTL["build MNV lex"](list("core")).

UI["run"]().