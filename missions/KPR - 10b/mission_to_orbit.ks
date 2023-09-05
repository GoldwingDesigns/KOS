parameter reboot_persist to true.// set to true to persist mission through reboot.
local inc1 to 25.3.
local lan1 to 155.5.
local apo1 to 11200955.
local per1 to 8182767.



local event_list to list(

    // MNV["change per"]@:bind(per1),
    // MNV["exec node"]@,
    MNV["change inc lan alt"]@:bind(inc1,lan1,apo1)
    //VES1["ladders on"]@
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist).
MIS1["run"]().
