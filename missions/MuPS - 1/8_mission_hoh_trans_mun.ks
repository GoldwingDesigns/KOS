parameter reboot_persist to true.// set to true to persist mission through reboot.
local tgtmoonname to "Mun".
local tgtmoon to body(tgtmoonname).
local scanalt to 200000.

local event_list to list(
        MNV["hoh trans 1"]@:bind(scanalt),
        MNV["exec node"]@,
        MNV["hoh trans 2"]@:bind(scanalt),
        MNV["exec node"]@
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist,scriptPath():name).
MIS1["run"]().
