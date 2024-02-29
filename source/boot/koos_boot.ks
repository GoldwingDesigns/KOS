SET CONFIG:TELNET TO TRUE.
SET Config:SUPPRESSAUTOPILOT TO FALSE.
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
// local processorList is list().
LIST PROCESSORS in processorList.
local i is 1.
local activeprocessors is 0.
local shipcapacity to 0.
local elementParts to core:element:parts.
for p in processorList{
    if elementParts:contains(p:part){
        if ship:status="PRELAUNCH" and (p:TAG:contains("payload") or p:TAG:contains("lander")){ //shutdown uneeded processors before launch
            p:deactivate().
        } else if p:part:UID = core:part:UID{ //this processor is the one running the bootfile
            // if p:BOOTFILENAME:contains("boot") {
            set p:TAG to "MASTER".
            set p:volume:name to BOOTVOLUME.	
            set activeprocessors to activeprocessors+1.		
        } else if p:TAG:contains("SLAVE") or p:TAG = "" {
            set p:TAG to "SLAVE_"+i.
            SET p:VOLUME:NAME TO p:TAG+"_DISK".
            print(p:VOLUME:NAME+" found."). //pass slave cpu obj, boot filename, volume number
            if(i=1){set DATAVOLUME to p:VOLUME:NAME. print (p:VOLUME:NAME+" set to data volume.").}
            set i to i+1.
            set activeprocessors to activeprocessors+1.
        }
    }
    set shipcapacity to shipcapacity + p:volume:capacity.
}
if activeprocessors = 1 {set DATAVOLUME to BOOTVOLUME.}

IF SHIP:STATUS = "PRELAUNCH" or homeConnection:isconnected { //create a check here to see if there is an update
	for b in BOOTFILES {
        copypath("0:/boot/"+b+".ks",BOOTVOLUME+":/boot/"+b+".ks").
    }
    // createDir(DATAVOLUME+":/lib/").
    for f in LIBFILES {
        copypath("0:/lib/"+f+".ks",BOOTVOLUME+":/lib/"+f+".ks").
        // compile "0:/"+"lib/"+f to DATAVOLUME+":/"+"lib/"+f.
	    }
    // createDir(DATAVOLUME+":/lex/").
    for f in LEXFILES {
        copypath("0:/lex/"+f+".ks",DATAVOLUME+":/lex/"+f+".ks").
        // compile "0:/"+"lex/"+f to DATAVOLUME+":/"+"lex/"+f.
	}
    print("Files Copied").
}

// switch to DATAVOLUME.
for f in LIBFILES {
    runPath(BOOTVOLUME+":/lib/"+f).
}
for f in LEXFILES {
    runPath(DATAVOLUME+":/lex/"+f).
}

// switch to BOOTVOLUME.
UTL["refresh config files"]().
local shipCfg to UTL["read config"]().
if shipCfg:hasKey("logmsg") {if shipCfg:logmsg = "false" set LOGMSGS to false.}
global VES1 to VES["new"](ship,shipCfg).

GLOBAL MNV is lex().
// if shipcapacity > 200000 UTL["build MNV lex"](list("all")).
// else
UTL["build MNV lex"](list("core")).

UI["run"]().