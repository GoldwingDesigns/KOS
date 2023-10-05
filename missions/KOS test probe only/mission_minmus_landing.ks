parameter reboot_persist to true.// set to true to persist mission through reboot.
local tgtmoonname to "minmus".
local tgtmoon to body(tgtmoonname).
local tgt to tgtmoon:geopositionLATLNG(0.51,0.51).
local rdroffset to 4.7.


local event_list to list(

    MNV["pwr land"]@:bind(rdroffset, tgt, 0)

).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist,scriptPath():name).
MIS1["run"]().
