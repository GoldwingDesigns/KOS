parameter reboot_persist to true.// set to true to persist mission through reboot.
local return_tgt_alt to 35000.
local event_list to list(
    MNV["change per"]@:bind(return_tgt_alt),
    MNV["exec node"]@,
    MNV["aero land"]@:bind(VES1["&lastchute"]())
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist,scriptPath():name).
MIS1["run"]().
