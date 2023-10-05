parameter reboot_persist to true.// set to true to persist mission through reboot.
local tgtmoonname to "Mun".
local tgtmoon to body(tgtmoonname).
local tgt to tgtmoon:geopositionLATLNG(0.51,0.51).
local launch_alt to 85000.
local turn_exponent to 0.6. //Turn exponent for curvature. Higher is more vertical.
local launch_inc to ship:geoposition:lat.
local init_moon_obt_alt to (tgtmoon:soiradius - tgtmoon:radius)*0.6.
local final_ldg_obt_alt to 10000.
local rdroffset to 4.7.


local event_list to list(
    VES1["stage"]@,
    MNV["pwr land"]@:bind(rdroffset, tgt, 0)

).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist,scriptPath():name).
MIS1["run"]().
