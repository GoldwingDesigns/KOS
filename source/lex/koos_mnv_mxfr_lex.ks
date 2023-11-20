//@lazyglobal off.
// #EXTERNAL_IDS lazyGlobal, MNV, MNV_TMP, VES, VES1, UTL, UI, SYS, man_check_stage, find_burntime, find_eta_to_true_anomaly, plane_change_info, find_landing_tgt_LAN,get_path_to_apprpoint,find_landing_tgt_LAN_lowalt, unlock_all, orbit_circumference, circle_distance, LAZcalc, LAZcalc_init, pitchangle, hillclimb
//runoncepath(DATAVOLUME+":/lib/koos_hillclimb_lib").  

{
	global MNV_TMP is lexicon(
		//#region Moon Transfer
		"capture",				capture_orbit@,
		"moon trans",			moon_trans@
		//#endregion
	).
	
///#region Moon Transfer
	
	function moon_trans{
		parameter tgtmoon, moon_peri.
		UI["msg add"]("Finding Transfer to "+tgtmoon:name).
		local planetMU to SHIP:ORBIT:BODY:MU.
		local oldSMA to SHIP:ORBIT:SEMIMAJORAXIS.
		local moonPEdistfromplanet to tgtmoon:obt:semimajoraxis - (moon_peri+tgtmoon:RADIUS).
		local newSMA to (moonPEdistfromplanet+oldSMA)/2.
		//copied from reddit user 
		
		local T2 is tgtmoon:obt:period.
		local A2 is tgtmoon:obt:semimajoraxis.

		// periapsis height of the transfer orbit is your altitude
		// apoapsis height of the transfer orbit is tgtmoon's altitude
		// so we can calculate SMA of the transfer orbit
		local A1 is newSMA.

		// 3rd Kepler's law tells us that (A1/A2)^3 = (T1/T2)^2
		// where T1 is period of transfer orbit
		// so T1 = T2 * (A1/A2)^1.5
		local T1 is T2 * (A1/A2)^1.5.

		// now we can calculate the angle between tgtmoon's position at the start of the transfer
		// and at the end of the transfer
		local aa is mod(((T1*0.5)/T2)*360, 360).
		//local aa is mod(360*(T1/T2), 360).

		// the angle we are looking for is 180-alpha
		// or 360-alpha if you are using angles in range [0..360]
		local transferAngle is 180 - aa.

		//copied from reddit user ollieshmollie and toukiedatak

		local shippos to ship:orbit:position - ship:body:position.
		local tgtmoonpos to tgtmoon:orbit:position - tgtmoon:body:position.
		local phaseangle to vang(tgtmoonpos,shippos).
		local phaseanglecrs to vcrs(tgtmoonpos,shippos).
		if vdot(v(1,1,1), phaseanglecrs) <= 0 {
			set phaseangle to -1 * phaseangle.
		}
		
		local tgtAngVel is 2*constant:radtodeg*constant:pi/tgtmoon:orbit:period.
		local shipAngVel is 2*constant:radtodeg*constant:pi/ship:orbit:period.
		local angdiff is phaseangle-transferAngle.
		if angdiff < 0 set angdiff to angdiff+360.
		
		local transtimeUTC to TIME:SECONDS + (angdiff)/ABS(tgtAngVel-shipAngVel).
		local initialV to sqrt(planetMU/oldSMA).
		local finalV to sqrt(planetMU*(2/oldSMA-1/newSMA)).
		local thisDV to finalV - initialV.
		
		local nd to NODE(transtimeUTC,0,0,thisDV).

		local hnd is hillclimb(nd, tgtmoon, list("periapsis",moon_peri), 500).
		ADD hnd.
		UI["msg add"]("Moon Transfer Node To "+tgtmoon:name+" Added").
		return true.
	}
	
	function capture_orbit{ //thanks to u/bdlarkin for example guidance
		parameter capture_altitude is SHIP:ORBIT:PERIAPSIS.
		local thistime to TIME:SECONDS.
		local etaper to ETA:PERIAPSIS.
		local bodyMU to BODY:MU.
		local bodyr to BODY:RADIUS.
		local vinf to sqrt(-1*(bodyMU/SHIP:OBT:SEMIMAJORAXIS)).
		local vesc to sqrt(2*bodyMU/(bodyr+SHIP:OBT:PERIAPSIS)).
		local perV to sqrt(vesc^2+vinf^2).
		local newSMA to (SHIP:OBT:PERIAPSIS + (bodyr*2) + capture_altitude)/2.
		local transV to sqrt(bodymu*((2/(SHIP:OBT:PERIAPSIS+bodyr))-(1/newSMA))).
		local thisDV to transV-perV.
		local nd to NODE(thistime+etaper,0,0,thisDV).
		ADD nd.
        UI["msg add"]("Orbit Capture Node Added").
        return true.
	}

//#endregion

}