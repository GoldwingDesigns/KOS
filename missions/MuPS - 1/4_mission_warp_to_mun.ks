parameter reboot_persist to true.// set to true to persist mission through reboot.
local tgtmoonname to "Mun".
local tgtmoon to body(tgtmoonname).


local event_list to list(
    SYS["warp next patch"]@,
    SYS["wait soi chng"]@:bind(tgtmoonname)

    
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist,scriptPath():name).
MIS1["run"]().
