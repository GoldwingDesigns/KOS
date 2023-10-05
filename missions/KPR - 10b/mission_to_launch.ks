parameter reboot_persist to true.// set to true to persist mission through reboot.
local inc1 to 2.5.
local lan1 to 219.2.
local apo1 to 7900000.
local per1 to 7900000.
local launch_alt to per1.
local pitchover to 2. //Turn exponent for curvature. Higher is more pitchover.
local launch_inc to ship:geoposition:lat.
local rdroffset to 4.7.


local event_list to list(
    VES1["prelaunch checks"]@,
    MNV["launch atmo"]@:bind(launch_alt,launch_inc,true,45,pitchover),
    MNV["circ"]@,
    MNV["exec node"]@
    
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist,scriptPath():name).
MIS1["run"]().
