parameter reboot_persist to true.// set to true to persist mission through reboot.
local inc1 to 2.5.
local lan1 to 219.2.
local apo1 to 3892175.
local per1 to 3885017.



local event_list to list(
    
    
    MNV["change apo"]@:bind(apo1),
    MNV["exec node"]@,
    MNV["change per"]@:bind(per1),
    MNV["exec node"]@,
    MNV["change inc lan"]@:bind(inc1,lan1),
    MNV["exec node"]@
    //VES1["ladders on"]@
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist).
MIS1["run"]().
