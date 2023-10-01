parameter reboot_persist to true.// set to true to persist mission through reboot.
local inc1 to 4.6.
local lan1 to 150.8.
local apo1 to 3734626.


local event_list to list(
    
    MNV["change apo"]@:bind(apo1)
    
    //VES1["ladders on"]@
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist).
MIS1["run"]().
