run koos_mnv_lib_L.
run koos_ves_lib_L.
run koos_mission_runner.
run lib_gui_dummy.

local tgtmoonname to "Minmus".
local tgtmoon to body(tgtmoonname).
local tgt to tgtmoon:geopositionLATLNG(-7.5,-17.5).
local launch_alt to 100000.
local launch_inc to ship:geoposition:lat.
local init_moon_obt_alt to (tgtmoon:soiradius - tgtmoon:radius)*0.3.
local final_ldg_obt_alt to 10000.
local rdroffset to 5.5.
local moon_launch_alt to 20000.
local moon_launch_inc to abs(tgt:lat).
local return_tgt_alt to 30000.
local reboot_persist to true.// set to true to persist mission through reboot.

local VES1 to VES["new"](ship).

local event_list to list(
    MNV["launch atmo"]@:bind(launch_alt,launch_inc,false),
    VES1["stage"]@,
    VES1["extract stage"]@,
    VES1["panels on"]@,   
    MNV["circ"]@,
    MNV["exec node"]@,
    MNV["match inc lan"]@:bind(tgtmoon),
    MNV["exec node"]@,
    MNV["moon trans"]@:bind(tgtmoon,init_moon_obt_alt),
    MNV["exec node"]@,
    warp_to_nextpatch@,
    wait_soi_chng@,
    MNV["capture"]@,
    MNV["exec node"]@,
    MNV["hoh trans 1"]@:bind(final_ldg_obt_alt),
    // MNV["change inc lan alt"]@:bind(tgt:lat,find_landing_tgt_LAN@:bind(tgt, tgt:lat, true, obt:apoapsis, final_ldg_obt_alt):call,final_ldg_obt_alt),    
	MNV["exec node"]@,
	MNV["hoh trans 2"]@:bind(final_ldg_obt_alt),
    MNV["exec node"]@,
    MNV["change inc lan"]@:bind(tgt:lat,find_landing_tgt_LAN_lowalt@:bind(tgt, tgt:lat, vdot(ship:angularvel,tgtmoon:angularvel)>=0):call),
	MNV["exec node"]@,
	VES1["stage"]@,
    MNV["land align"]@:bind(tgt),
    MNV["pwr land"]@:bind(rdroffset, tgt, 0),
    VES1["ladders on"]@,
    wait_time@:bind(10),
    VES1["ladders off"]@,
    wait_time@:bind(10),
    MNV["launch no atmo"]@:bind(moon_launch_alt,moon_launch_inc,true),
    MNV["circ"]@,
    MNV["exec node"]@,
    VES1["gear off"]@,
    wait_time@:bind(10),
    MNV["moon return"]@:bind(return_tgt_alt),
    MNV["exec node"]@,
    warp_to_nextpatch@,
    MNV["aero land"]@:bind(VES1["&lastchute"])
).

local interrupt_list to list(
    VES1["blank"]@
).

// mission specific functions



function wait_soi_chng {
    return list(
        {
            if ship:body:name = tgtmoonname {
                gui_msg_add("SOI Change To "+tgtmoonname).
                return true.
            } else {
                return false.
            }
        }
    ).
}

function warp_to_nextpatch{
    warpto(TIME:SECONDS+ORBIT:NEXTPATCHETA).
    return true.
}

function wait_time {
    parameter a.
    local waitend to time:seconds + a.
    return list ( 
        { 
        if time:seconds > waitend { return true. } else { return false. }
        }
    ).
}

//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist).
MIS1["run"]().
