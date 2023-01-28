parameter reboot_persist to false.// set to true to persist mission through reboot.
local tgtmoonname to "Minmus".
local tgtmoon to body(tgtmoonname).
local tgt to tgtmoon:geopositionLATLNG(10,30.5).
local launch_alt to 100000.
local launch_inc to ship:geoposition:lat.
local pitchover to 3.
local init_moon_obt_alt to (tgtmoon:soiradius - tgtmoon:radius)*0.3.
local final_ldg_obt_alt to 10000.
local rdroffset to 4.7.

local event_list to list(
    // MNV["launch atmo"]@:bind(launch_alt,launch_inc,true,45,pitchover),
    // // VES1["stage"]@,
    // // VES1["extract stage"]@,
    // // VES1["panels on"]@,
    // // VES1["comms ext"]@,   
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
    // MNV["hoh trans 1"]@:bind(final_ldg_obt_alt),  
	// MNV["exec node"]@,
	// MNV["hoh trans 2"]@:bind(final_ldg_obt_alt),
    // MNV["exec node"]@,
    // MNV["change per"]@:bind(final_ldg_obt_alt),
    // MNV["exec node"]@,
    // SYS["pause"]@,
    MNV["match landing lat"]@:bind(tgt),
    SYS["pause"]@,

    // MNV["exec node"]@,
    // MNV["land align init"]@:bind(tgt),
    // MNV["land align final"]@:bind(tgt),
    // MNV["pwr land"]@:bind(rdroffset, tgt, 0),
    VES1["ladders on"]@
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist).
MIS1["run"]().
