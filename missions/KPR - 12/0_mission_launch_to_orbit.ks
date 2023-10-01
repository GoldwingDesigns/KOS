parameter reboot_persist to true.// set to true to persist mission through reboot.
local inc1 to 4.6.
local lan1 to 150.8.
local per1 to 100000.
local launch_alt to per1.
local pitchover to 2. //Turn exponent for curvature. Higher is more pitchover.
local launch_window_lead_time to 90. //account time to launch and pitchover
local launch_inc to ship:geoposition:lat.
local launchwindowlist to findLaunchWindow(launch_window_lead_time,inc1,lan1).
if launchwindowlist[0] <> -1 {
    set launch_inc to launchwindowlist[1].
    local launch_time to launchwindowlist[0]-launch_window_lead_time.


local event_list to list(
    SYS["warp to time"]@:bind(launch_time),
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
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist).
MIS1["run"]().
}