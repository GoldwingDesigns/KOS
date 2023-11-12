parameter reboot_persist to true.// set to true to persist mission through reboot.
local inc1 to 88.
local per1 to 100000.
local launch_alt to per1.
local launch_inc to inc1.
local pitchover to 2.5. //Turn exponent for curvature. Higher is more pitchover.



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
