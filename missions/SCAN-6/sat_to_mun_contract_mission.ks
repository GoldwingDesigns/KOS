parameter reboot_persist to true.// set to true to persist mission through reboot.
local tgtmoonname to "Mun".
local tgtmoon to body(tgtmoonname).
local launch_alt to 100000.
local launch_inc to ship:geoposition:lat.
local init_moon_obt_alt to 718148.

local event_list to list(
    MNV["launch atmo"]@:bind(launch_alt,launch_inc,false),
    VES1["stage"]@,
    VES1["panels on"]@,
    VES1["comms ext"]@,   
    MNV["circ"]@,
    MNV["exec node"]@,
    MNV["match inc lan"]@:bind(tgtmoon),
    MNV["exec node"]@,
    MNV["moon trans"]@:bind(tgtmoon,init_moon_obt_alt),
    MNV["exec node"]@,
    SYS["warp next patch"]@,
    SYS["wait soi chng"]@:bind(tgtmoonname),
    MNV["capture"]@,
    MNV["exec node"]@,
    MNV["change inc lan"]@:bind(6,107.8),  
	MNV["exec node"]@,
    MNV["change arg per"]@:bind(16.6,329584),  
	MNV["exec node"]@
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist).
MIS1["run"]().
