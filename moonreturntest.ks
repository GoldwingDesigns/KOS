run koos_mnv_lib.
run koos_ves_lib.
run lib_gui_dummy.
local tgtmoon to "mun".
local tgt to body(tgtmoon):geopositionLATLNG(-9.83,25.92).
local launch_alt to 100000.
local launch_inc to ship:geoposition:lat.
local init_moon_obt_alt to (body(tgtmoon):soiradius - body(tgtmoon):radius)*0.5.
local final_ldg_obt_alt to 20000.
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

local event_list to queue(
    MNV["launch atmo"]@:bind(launch_alt,launch_inc,false),
    stage@,
    VES["rcs on"]@,
    ship_sep@,    
    MNV["circ"]@,
    MNV["exec node"]@,
    MNV["moon trans"]@:bind(tgtmoon,init_moon_obt_alt),
    MNV["exec node"]@,
    warp_to_nextpatch@,
    wait_soi_chng@,
    MNV["capture"]@,
    MNV["exec node"]@,
    MNV["land obt adj"]@:bind(tgt,final_ldg_obt_alt),
    clearVecDraws@,
    MNV["land align"]@:bind(tgt),
    MNV["pwr land"]@:bind(rdroffset, tgt, 0),
    VES["ladders on"]@,
    wait_time@:bind(10),
    VES["ladders off"]@,
    wait_time@:bind(10),
    MNV["launch no atmo"]@:bind(moon_launch_alt,moon_launch_inc,true),
    MNV["exec node"]@,
    VES["gear off"]@,
    wait_time@:bind(10),
    MNV["moon return"]@:bind(return_tgt_alt),
    MNV["exec node"]@,
    warp_to_nextpatch@
).

function ship_sep {
    wait 0.1.
    set ship:control:fore to 1.
    wait 2.
    set ship:control:neutralize to true.
    wait 10.
}

function wait_soi_chng {
    wait until ship:body:name = tgtmoon.
}

function warp_to_nextpatch{
    warpto(TIME:SECONDS+ORBIT:NEXTPATCHETA).
}
function wait_time {
    parameter a.
    wait a.
}

until event_list:empty {
    event_list:pop:call.
    wait 0.1.
}