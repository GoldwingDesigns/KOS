parameter reboot_persist to true.// set to true to persist mission through reboot.
local tgtmoonname to "Mun".
local tgtmoon to body(tgtmoonname).
set ldgtgtname to "Mul - 3".
local tgt to waypoint(ldgtgtname):geoposition.
local final_ldg_obt_alt to 10000.
local rdroffset to 2.3.
set LOGMSGS to false. //save disk space

local event_list to list(
    // VES1["prelaunch checks"]@,
    // MNV["launch atmo"]@:bind(launch_alt,launch_inc,true,45,pitchover),
    // MNV["circ"]@,
    // MNV["exec node"]@,
    // MNV["match inc lan"]@:bind(tgtmoon),
    // MNV["exec node"]@,
    // MNV["moon trans"]@:bind(tgtmoon,init_moon_obt_alt),
    // MNV["exec node"]@,
    // SYS["warp next patch"]@,
    // SYS["wait soi chng"]@:bind(tgtmoonname),
    // MNV["capture"]@,
    // MNV["exec node"]@,
    VES1["panels on"]@,
    VES1["comms ext"]@,
    MNV["match landing lat"]@:bind(tgt,final_ldg_obt_alt),  
	MNV["exec node"]@,
    MNV["change apo"]@:bind(final_ldg_obt_alt),
	MNV["exec node"]@,
    MNV["land align init"]@:bind(tgt),
    MNV["land align final"]@:bind(tgt),
    MNV["pwr land"]@:bind(rdroffset, tgt, 1)
    //VES1["ladders on"]@
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist).
MIS1["run"]().
