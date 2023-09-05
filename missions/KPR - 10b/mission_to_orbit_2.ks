parameter reboot_persist to true.// set to true to persist mission through reboot.
local inc1 to 34.4.
local lan1 to 39.6.
local apo1 to 11742856.
local per1 to 3885017.
local launch_alt to per1.
local pitchover to 3. //Turn exponent for curvature. Higher is more vertical.
local launch_inc to ship:geoposition:lat.
local rdroffset to 4.7.


local event_list to list(
    
    MNV["change inc lan alt"]@:bind(inc1, lan1, apo1)
    
    //VES1["ladders on"]@
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist).
MIS1["run"]().
