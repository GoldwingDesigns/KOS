parameter reboot_persist to true.// set to true to persist mission through reboot.
local inc1 to 2.5.
local lan1 to 219.2.
local apo1 to 3892175.
local per1 to 3885017.
local launch_alt to per1.
local pitchover to 3. //Turn exponent for curvature. Higher is more vertical.
local launch_inc to ship:geoposition:lat.
local rdroffset to 4.7.


local event_list to list(
    VES1["prelaunch checks"]@,
    MNV["launch atmo"]@:bind(launch_alt,launch_inc,true,45,pitchover),
    MNV["circ"]@,
    MNV["exec node"]@,
    MNV["change inc lan"]@:bind(inc1,lan1),
    MNV["exec node"]@,
    MNV["change apo"]@:bind(apo1),
    MNV["exec node"]@,
    MNV["change per"]@:bind(per1),
    MNV["exec node"]@
    //VES1["ladders on"]@
).

local interrupt_list to list(
    VES1["check fail"]@,
    UI["AG6 stop"]@
).

// mission specific functions


//create and run mission
global MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist).
MIS1["run"]().
