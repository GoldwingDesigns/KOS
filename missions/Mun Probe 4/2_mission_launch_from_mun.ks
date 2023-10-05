local moon_launch_alt to 20000.
local moon_launch_inc to ship:geoposition:lat.
local reboot_persist to true.// set to true to persist mission through reboot.

local event_list to list(
    MNV["launch no atmo"]@:bind(moon_launch_alt,moon_launch_inc),
    MNV["circ"]@,
    MNV["exec node"]@,
    VES1["gear up"]@
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist,scriptPath():name).
MIS1["run"]().
