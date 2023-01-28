parameter reboot_persist to true.// set to true to persist mission through reboot.

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
    // MNV["change inc lan"]@:bind(mod(tgt:lat+180,180),find_landing_tgt_LAN_lowalt@:bind(tgt, tgt:lat, isPosigrade())),
    // MNV["exec node"]@,
    // MNV["land align init"]@:bind(tgt),
    // MNV["land align final"]@:bind(tgt),
    // MNV["pwr land"]@:bind(rdroffset, tgt, 0),
    // VES1["ladders on"]@
    MNV["change inc lan alt"]@:bind(34,120,20000),
    SYS["pause"]@,
    MNV["exec node"]@
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist).
MIS1["run"]().
