parameter reboot_persist to true.// set to true to persist mission through reboot.

local launch_alt to 100000.
local pitchover to 2. //Turn exponent for curvature. Lower is more vertical.
local launch_inc to ship:geoposition:lat.


local event_list to list(
    VES1["prelaunch checks"]@,
    MNV["launch atmo"]@:bind(launch_alt,launch_inc,true,45,pitchover),
    MNV["circ"]@,
    MNV["exec node"]@
    
).

local interrupt_list to list(
    VES1["check fail"]@,
    UI["AG6 stop"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist).
MIS1["run"]().
