//@lazyglobal off.
//runoncepath(DATAVOLUME+":/lib/koos_hillclimb_lib").  

{
	global MNV_TMP is lexicon(
		//#region Moon Transfer
		"capture",			capture_orbit@,
		"planet trans",	planet_trans@,
		"node refine",	refine_next_node@
		//#endregion
	).
	
///#region Planet Transfer
	
	// function planet_trans{
	// 	parameter tgtplanet, planet_peri.
	// 	UI["msg add"]("Finding Transfer to "+tgtplanet:name).
	// local nd to NODE(0,0,0,0).
	// 	local burns to addons:astrogator:calculateBurns(tgtplanet).
	// 	local i to 0.
	// 	for burnnode in burns {
	// 		set i to i+1.
	// 		set nd to NODE(burnnode:attime, burnnode:radial, burnnode:normal, burnnode:prograde).
	// 		if i = burns:length {set nd to hillclimb(nd, tgtplanet, list("periapsis",planet_peri), 500).}
	// 		add nd.
	// 	}
	// 	UI["msg add"]("Planet Transfer Node(s) To "+tgtplanet:name+" Added").
	// 	return true.
	// }

	function planet_trans{
		parameter tgtplanet, planet_peri, ish to 5000.
		UI["msg add"]("Finding Transfer to "+tgtplanet:name).
		local nd to NODE(0,0,0,0).
		local burns to addons:astrogator:calculateBurns(tgtplanet).
		local i to 0.
		for burnnode in burns {
			// set i to i+1.
			set nd to NODE(burnnode:attime, burnnode:radial, burnnode:normal, burnnode:prograde).
			// if i = burns:length {set nd to hillclimb(nd, tgtplanet, list("periapsis",planet_peri), ish).}
			add nd.
		}
		UI["msg add"]("Planet Transfer Node(s) To "+tgtplanet:name+" Added").
		return true.
	}
	function refine_next_node {
		parameter tgtplanet, planet_peri, ish to 5000.
		UI["msg add"]("Refining Transfer Node to "+tgtplanet:name).
		if not hasNode {
			UI["msg add"]("No Node To Refine").
		} else {
			local nd to nextNode.
			remove nextNode.
			set nd to hillclimb(nd, tgtplanet, list("periapsis",planet_peri), ish).
			add nd.
			UI["msg add"]("Planet Transfer Node To "+tgtplanet:name+" Refined").
		}
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