//@lazyglobal off.
// runpath(DATAVOLUME+":/lib/koos_obtcalc_lib"). 
// runpath(DATAVOLUME+":/lib/koos_mnv_lib"). 

{
	global MNV_TMP is lexicon(
    //#region Core
		"exec node",			exec_node@,
		"unlock all",			unlock_all@,
		"hoh trans 1",			hohmann_trans1@,
		"hoh trans 2",			hohmann_trans2@,
		"change inc lan alt",	change_inc_lan_alt@,
		"change apo",			change_apo@,
		"change per",			change_per@,
		"circ",					circularize@,
		"change inc lan",		change_inc_lan@,
		"orbit sun angle", orb_sun_angle@
 		//#endregion
		).
	
  function exec_node{
		parameter laststage to VES1["&lastengine"]().
		//Execute Node Maneuvers
    //Adapted from pgoddkos Advanced Tutorial
		//warp taken from TheDapperScot on https://www.reddit.com/r/Kos/comments/5t1qx9/node_execution_script_is_causing_wild_spinning/
		local nd to nextnode.
		VES1["sas off"]().
		LOCAL th to 0.
		LOCK THROTTLE to th.
		VES1["check ign"](). //make sure active stage has a good engine
		wait 3.
		local burntime to find_burntime(nd:deltaV:mag).
		local lock max_acc to ship:maxthrust/ship:mass.
		local dv0 to nd:DELTAV:vec.
    LOCK STEERING to lookdirup(nd:deltav,SHIP:BODY:POSITION).
    local waitstart to 0.
    UI["msg add"]("Executing Node. dV: "+ round(nd:deltav:mag) + " Burntime: "+ round(burntime)).

		return list(
			{
				warpto(nd:ETA-(burntime/2)-60+time:seconds).
				return true.
			},
			{
				set dv0 to nd:deltav:vec.
				return nd:ETA <= burntime/2.
			},
			{
				//recalculate current max_acceleration, as it changes while we burn through fuel
				//throttle is 100% until there is less than 1 second of time left to burn
				//when there is less than 1 second - decrease the throttle linearly
				if max_acc <> 0 set th to min(nd:deltav:mag/max_acc, 1).
				//here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
				//this check is done via checking the dot product of those 2 vectors
				man_check_stage(laststage). 
				return nd:deltav:mag<0.1 or vdot(dv0, nd:deltav) < 0.05.
			},
			{
				lock throttle to 0.
				local sd to VES1["&solardir"]().
				if sd:contains("fore") {
						lock STEERING to lookdirup(Body("sun"):position,BODY:POSITION).
				} else if sd:contains("aft") {
						lock STEERING to lookdirup(-1 * Body("sun"):position,BODY:POSITION).
				} else if sd:contains("side") {
						lock STEERING to lookdirup(VCRS(Body("sun"):position,ship:velocity:orbit),BODY:POSITION).
				} else { 
						lock STEERING to lookdirup(Body("sun"):position,BODY:POSITION). 
				}.
				set waitstart to time:seconds.
				return true.
			},
			{
				return waitstart+15 < time:seconds.
			},
			{
				SET SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
				MNV["unlock all"]().	
				VES1["sas on"]().
				
				REMOVE nd.
				WAIT 0.1.
				UI["msg add"]("Node Execution Complete.").
				return true.
			}
		).
	}

	function unlock_all {
    UNLOCK STEERING.
    UNLOCK THROTTLE.
  }
	
	function hohmann_trans1{ 
		parameter newalt.
		if ETA:APOAPSIS < ETA:PERIAPSIS {
			change_per(newalt).
		}else{
			change_apo(newalt).
		}
		return true.
	}

	function hohmann_trans2{
		parameter newalt.
		local adiff to abs(obt:apoapsis-newalt).
		local pdiff to abs(obt:periapsis-newalt).
		if adiff < pdiff {
			change_per(newalt).
		}else{
			change_apo(newalt).
		}
		return true.
	}

	function change_inc_lan_alt {
		parameter inc_t, lan_t, alt_t.
		if lan_t:istype("UserDelegate") set lan_t to lan_t:call.
		local info to plane_change_info(inc_t,lan_t).
		local theta to info[0].
		local nd_time to info[1].
		local negind to info[2].
		local thisR to (positionAt(ship,nd_time)-body:position):mag.
		local nextA to (thisR+BODY:RADIUS+alt_t)/2.
		local vi is velocityAt(ship,nd_time):orbit:mag.
		local vf is sqrt(body:mu*((2/thisR)-(1/nextA))).
		local norm to vf * sin(theta).
		local pro to (vf * cos(theta)) - vi.
		local nd is NODE(nd_time, 0,0,0).
		set nd:normal to negind * norm.
		set nd:prograde to pro.
		Add nd.
		UI["msg add"]("Inc/LAN/Alt Node Added: "+inc_t+"/"+lan_t+"/"+alt_t).
		return true.
	}
  
  function change_apo{
		parameter newalt.
		local thisMU to BODY:MU.
		local thisR to BODY:RADIUS + SHIP:PERIAPSIS.
		local thisA to BODY:RADIUS + ((SHIP:PERIAPSIS + SHIP:APOAPSIS)/2).
		local nextA to BODY:RADIUS + ((SHIP:PERIAPSIS + newalt)/2).
		local thisDV to SQRT(thisMU * (2/thisR - 1/nextA)) - SQRT(thisMU * (2/thisR - 1/thisA)).
		local nd to NODE(TIME:SECONDS + ETA:PERIAPSIS,0,0,thisDV).
		ADD nd.
		UI["msg add"]("Change Apo Node Added.").
		return true.
	}

	function change_per{
		parameter newalt.
		local thisMU to BODY:MU.
		local thisR to BODY:RADIUS + SHIP:APOAPSIS.
		local thisA to BODY:RADIUS + ((SHIP:APOAPSIS + SHIP:PERIAPSIS)/2).
		local nextA to BODY:RADIUS + ((SHIP:APOAPSIS + newalt)/2).
		local thisDV to SQRT(thisMU * (2/thisR - 1/nextA)) - SQRT(thisMU * (2/thisR - 1/thisA)).
		local nd to NODE(TIME:SECONDS + ETA:APOAPSIS,0,0,thisDV).
		ADD nd.
    UI["msg add"]("Change Pe Node Added.").
    return true.
	}
	
	function circularize{
		local thisMU to BODY:MU.
		local apoIsSoonest to ETA:APOAPSIS<ETA:PERIAPSIS.
		local thisA to BODY:RADIUS + ((SHIP:APOAPSIS + SHIP:PERIAPSIS)/2).
		local thisR to CHOOSE BODY:RADIUS + SHIP:APOAPSIS if apoIsSoonest else BODY:RADIUS + SHIP:PERIAPSIS.
		local thisDV to SQRT(thisMU * (2/thisR - 1/thisR)) - SQRT(thisMU * (2/thisR - 1/thisA)).
		local nd to NODE(TIME:SECONDS + (CHOOSE ETA:APOAPSIS IF apoIsSoonest ELSE ETA:PERIAPSIS),0,0,thisDV).
		ADD nd.
		UI["msg add"]("Circularize Node Added At "+ (CHOOSE "Apoapsis" IF apoIsSoonest ELSE "Periapsis")).
		return true.
	}
	
	function change_inc_lan {
		//100% from https://www.reddit.com/r/Kos/comments/3r5pbj/set_inclination_from_orbit_script/  I tried to do on my own but couldn't
		parameter inc_t, lan_t to orbit:lan.
		if lan_t:istype("UserDelegate") set lan_t to lan_t:call.
		local info to plane_change_info(inc_t,lan_t).
		local theta to info[0].
		local nd_time to info[1].
		local negind to info[2].
		local vel is velocityAt(ship,nd_time):orbit:mag.
		local norm to vel * sin(theta).
		local pro to vel * cos(theta) - vel.
    local nd is NODE(nd_time, 0,0,0).
		set nd:normal to negind * norm.
		set nd:prograde to pro.
		Add nd.
		UI["msg add"]("Inc/LAN Node Added: "+inc_t+"/"+lan_t).
		return true.   
	}

	function orb_sun_angle {
		parameter inc_t, alt_t, max_t, min_t to 0.
		local lan_t is getLANForSunAngle(max_t,min_t).
		change_inc_lan_alt(inc_t,lan_t,alt_t).
		return true.
	}


}