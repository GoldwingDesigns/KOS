local moon_launch_alt to 20000.
local moon_launch_inc to ship:geoposition:lat.
local return_tgt_alt to 35000.
local reboot_persist to true.// set to true to persist mission through reboot.

local event_list to list(
    VES1["ladders off"]@,
    SYS["wait time"]@:bind(10),
    MNV["launch no atmo"]@:bind(moon_launch_alt,moon_launch_inc,true),
    MNV["circ"]@,
    MNV["exec node"]@,
    VES1["gear up"]@,
    SYS["wait time"]@:bind(10),
    MNV["moon return"]@:bind(return_tgt_alt),
    MNV["exec node"]@,
    SYS["warp next patch"]@,
    SYS["wait soi chng"]@:bind("Kerbin"),
    SYS["warp to alt"]@:bind(Body("kerbin"):atm:height * 2),
    VES1["comms ret"]@,
    MNV["aero land"]@:bind(VES1["&lastchute"]())
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist).
MIS1["run"]().
