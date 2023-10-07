parameter reboot_persist to true.// set to true to persist mission through reboot.
local tgtmoonname to "Mun".
local tgtmoon to body(tgtmoonname).
set ldgtgtname to "Mul - 3".
local tgt to waypoint(ldgtgtname):geoposition.
local final_ldg_obt_alt to 10000.
local rdroffset to 0.5.
set LOGMSGS to false. //save disk space

local event_list to list(
    VES1["panels on"]@,
    VES1["comms ext"]@,
    MNV["match landing lat"]@:bind(tgt,final_ldg_obt_alt),
	MNV["exec node"]@,
    MNV["change apo"]@:bind(final_ldg_obt_alt),
	MNV["exec node"]@,
    MNV["land align init"]@:bind(tgt),
    MNV["land align final"]@:bind(tgt),
    MNV["pwr land"]@:bind(rdroffset, tgt, 1)
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist,scriptPath():name).
MIS1["run"]().
