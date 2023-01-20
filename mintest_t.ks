run koos_mnv_lib_L.
run koos_ves_lib_L.
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
SET CONFIG:TELNET TO TRUE.
GLOBAL MSGQ to QUEUE(). 
GLOBAL STARTTIME to 0.
GLOBAL COMPMODE to 0.
GLOBAL CPUINITIALIZED to 0.
GLOBAL WARNSTATE to 0.
GLOBAL INMENU to FALSE.
local reboot_persist to true. // set to true to persist mission through reboot.

local L TO LEXICON().
local jsonname to ship:name+".json".
if exists(jsonname) and reboot_persist {
    set L to readJson(jsonname).
} else {
    L:add("istep",0).
    L:add("jstep",0).
}
local init_i is L["istep"].
local init_j is L["jstep"].

local event_list to list(
    MNV["launch atmo"]@:bind(launch_alt,launch_inc,false),
    VES["stage"]@,
    ship_sep@,
    VES["panels on"]@,   
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
    MNV["change inc lan alt"]@:bind(tgt:lat,find_landing_tgt_LAN@:bind(tgt, tgt:lat, true, obt:apoapsis, final_ldg_obt_alt):call,final_ldg_obt_alt),    
	MNV["exec node"]@,
	MNV["change apo"]@:bind(final_ldg_obt_alt),
	MNV["exec node"]@,
	VES["stage"]@,
    MNV["land align"]@:bind(tgt),
    MNV["pwr land"]@:bind(rdroffset, tgt, 0),
    VES["ladders on"]@,
    wait_time@:bind(10),
    VES["ladders off"]@,
    wait_time@:bind(10),
    MNV["launch no atmo"]@:bind(moon_launch_alt,moon_launch_inc,true),
    MNV["circ"]@,
    MNV["exec node"]@,
    VES["gear off"]@,
    wait_time@:bind(10),
    MNV["moon return"]@:bind(return_tgt_alt),
    MNV["exec node"]@,
    warp_to_nextpatch@
).

local interrupt_list to list(
    VES["blank"]@
).

function ship_sep {
    VES["rcs on"]().
    wait 0.1.
    set ship:control:fore to 1.
    wait 2.
    set ship:control:neutralize to true.
    wait 10.
    VES["rcs off"]().
    return true.
}

function wait_soi_chng {
    wait until ship:body:name = tgtmoonname.
    gui_msg_add("SOI Change To "+tgtmoonname).
    return true.
}

function warp_to_nextpatch{
    warpto(TIME:SECONDS+ORBIT:NEXTPATCHETA).
    return true.
}
function wait_time {
    parameter a.
    wait a.
    return true.
}

local i is init_i.
local j is init_j.
until i = event_list:length {
    local result is event_list[i]:call.
    if result:istype("list") {
        until j = result:length {
            if result[j]:call {
                set j to j+1.
                set L["jstep"] to j.
                writeJson(L,jsonname).
            }
            check_triggers().
            wait 0.1.
        }
        set i to i+1.
        set L["istep"] to i.
        set j to 0.
        set L["jstep"] to j.
        writeJson(L,jsonname).
    } else if result:istype("boolean") {
    if result {
        set i to i+1.
        set L["istep"] to i.
        writeJson(L,jsonname).
    }
    check_triggers().
    }
    wait 0.1.
}
if exists(jsonname) {
    deletePath(jsonname).
}

function check_triggers{
    local trignum is 0.
    until trignum = interrupt_list:length {
        interrupt_list[trignum]:call.
        set trignum to trignum+1.
    }
    return true.
}