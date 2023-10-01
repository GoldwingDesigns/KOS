parameter reboot_persist to true.// set to true to persist mission through reboot.

local launch_alt to 80000.
local launch_window_lead_time to 90. //account time to launch and pitchover
local pitchover to 3. //Turn exponent for curvature. Lower is more vertical.
local launch_inc to ship:geoposition:lat.
local launchwindowlist to findLaunchWindowToTarget(launch_window_lead_time,target).
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
    VES1["check fail"]@,
    UI["AG6 stop"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist).
MIS1["run"]().
}