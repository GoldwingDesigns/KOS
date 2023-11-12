parameter reboot_persist to true.// set to true to persist mission through reboot.

local targetname to ("Station - 1").


local event_list to list(
    DOCK["undock from vessel"]@
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist,scriptPath():name).
MIS1["run"]().
