//@lazyglobal off.
// #EXTERNAL_IDS lazyGlobal, MNV, MNV_TMP, VES, VES1, UTL, UI, SYS, man_check_stage, find_burntime, find_eta_to_true_anomaly, plane_change_info, find_landing_tgt_LAN,get_path_to_apprpoint,find_landing_tgt_LAN_lowalt, unlock_all, orbit_circumference, circle_distance, LAZcalc, LAZcalc_init, pitchangle, hillclimb
//runoncepath(DATAVOLUME+":/lib/koos_obtcalc_lib"). 

{
	global MNV_TMP is lexicon(
		//#region Adv Orbital
		"match inc lan",    	match_inc_lan@,
		"change per",			change_per@,
		"change arg per",		change_AoPer@
		//#endregion
	).
	
//#region Adv Orbital
	
	function match_inc_lan {
      parameter tgtbody.
      RETURN MNV["change inc lan"]@:bind(tgtbody:obt:inclination, tgtbody:obt:lan).
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

	function change_AoPer{ //should only be accomplished from circular orbit
		parameter aop, newalt.
		local thisMU to BODY:MU.
		local thisR to SHIP:ORBIT:semimajoraxis.
		local thisA to SHIP:ORBIT:semimajoraxis.
		local nextA to (BODY:RADIUS + SHIP:ORBIT:semimajoraxis + newalt)/2.
		local thisDV to SQRT(thisMU * (2/thisR - 1/nextA)) - SQRT(thisMU * (2/thisR - 1/thisA)).
		local aopdiff to aop-SHIP:ORBIT:argumentofperiapsis.
		if aopdiff < 0 set aopdiff to aopdiff+360.
		local maneuvertrueanom is 0.
		if thisR >= newalt+body:radius { set maneuvertrueanom to find_eta_to_true_anomaly(mod(aopdiff+180,360)). } else { set maneuvertrueanom to find_eta_to_true_anomaly(mod(aopdiff,360)). } //just in case changing apoapsis instead of periapsis
		local nd to NODE(TIME:SECONDS + maneuvertrueanom,0,0,thisDV).
		ADD nd.
    UI["msg add"]("Change Pe Node Added.").
    return true.
	}

//#endregion
}