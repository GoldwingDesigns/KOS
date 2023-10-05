parameter reboot_persist to true.// set to true to persist mission through reboot.
local tgtmoonname to "Mun".
local tgtmoon to body(tgtmoonname).
local tgt to tgtmoon:geopositionLATLNG(4.4,-54.51).
local init_moon_obt_alt to (tgtmoon:soiradius - tgtmoon:radius)*0.6.
local final_ldg_obt_alt to 10000.
local rdroffset to 4.7.


local event_list to list(
    MNV["moon trans"]@:bind(tgtmoon,init_moon_obt_alt),
    MNV["exec node"]@,
    SYS["warp next patch"]@,
    SYS["wait soi chng"]@:bind(tgtmoonname),
    MNV["capture"]@,
    MNV["exec node"]@,
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
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist,scriptPath():name).
MIS1["run"]().
