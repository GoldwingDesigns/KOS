parameter reboot_persist to true.// set to true to persist mission through reboot.

local reentry_tgt_alt to 45000.
local laststage to 1.



local event_list to list(
    
    MNV["change per"]@:bind(reentry_tgt_alt),
    MNV["exec node"]@,
    MNV["aero land"]@:bind(laststage)
    
    //VES1["ladders on"]@
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist,scriptPath():name).
MIS1["run"]().
