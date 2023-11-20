// #EXTERNAL_IDS lazyGlobal, MNV, MNV_TMP, VES, VES1, UTL, UI, SYS, man_check_stage, find_burntime, find_eta_to_true_anomaly, plane_change_info, find_landing_tgt_LAN,get_path_to_apprpoint,find_landing_tgt_LAN_lowalt, unlock_all, orbit_circumference, circle_distance, LAZcalc, LAZcalc_init, pitchangle, hillclimb,etatoaltitude2
//@lazyglobal off.
local INFINITY is 2^64.
local BQ is QUEUE().
local STEPSIZE is 0.
local LASTSCORE is INFINITY.
local answer is NODE(0,0,0,0).

function hillclimb {
	parameter nd, tgt, tgtvalue, ish.
	if evaluate(nd, tgt, tgtvalue, ish)[1] = 0 return nd.
	BQ:CLEAR().
	BQ:PUSH(nd).
	set STEPSIZE to 0.
	// if tgtvalue:CONTAINS("inclination"){
		// Set li to tgtvalue:ITERATOR.
		// UNTIL NOT li:NEXT{
		  // if li:VALUE = "inclination" {
			// set ind to li:INDEX.
			// UNTIL findneighbors(tgt, list("inclination",tgtvalue[ind+1]), ish) {}	
			// tgtvalue:REMOVE(ind).
			// tgtvalue:REMOVE(ind). //have to do it twice to remove key and value
			// BQ:CLEAR().
			// BQ:PUSH(answer).
			// set STEPSIZE to 0.
			// BREAK.
			// }
		// }
	// }
	UNTIL findneighbors(tgt, tgtvalue, ish) {}
	return answer.
}

function findneighbors{
	parameter tgt, tgtvalue, ish.
	local nd is BQ:POP().
	local rlist to list().
	rlist:CLEAR.
	FROM {local i is 0.} UNTIL i = 8 STEP {set i to i+1.} DO {
		rlist:ADD(evaluate(stepnode(nd,i),tgt,tgtvalue,ish)).
	}
	local sortlist is arrsort(rlist).
	local bestscore is sortlist[0][1].
	if bestscore = 0 {set answer to sortlist[0][0]. return TRUE.}
	if bestscore > LASTSCORE {BQ:PUSH(nd). if stepsize < 4 {set STEPSIZE to STEPSIZE + 1.} else {set STEPSIZE to 0.}}
	// if bestscore > LASTSCORE {set answer to nd. return TRUE.}
	else {BQ:PUSH(sortlist[0][0]). set LASTSCORE to bestscore.}
	// print STEPSIZE.
	return FALSE.
}

function findscoremean {
	parameter meanarr.
	local sum is 0.
	for arr in meanarr {
		set sum to sum + arr[1].
	}
	local mean is sum / meanarr:LENGTH.
	return mean.
}

function arrsort{
	parameter arr.
	local n to arr:LENGTH.
	FROM {local i is 1.} UNTIL i >= n STEP {set i to i+1.} DO { 
		set key to arr[i]. 
		set j to i - 1.
		// Move elements of arr[0..i-1], that are 
		// greater than key, to one position ahead 
		// of their current position 
		UNTIL j < 0 OR arr[j][1] <= key[1] { 
			set arr[j + 1] to arr[j]. 
			set j to j - 1.
		} 
		set arr[j + 1] to key. 
	}
	return arr.
}		
		
function evaluate{
	parameter nd, tgt, tgtvalue, ish.
	ADD nd.
	WAIT 0.1.
	local score is scorenode(tgt,tgtvalue, nd).
	REMOVE nd.
	if score < ish { return list(nd,0). }
	return list(nd,score).
}

function scorenode{
	parameter tgt, tgtvalue, nd.
	local score is 1.
	FROM {local i is 0.} UNTIL i = tgtvalue:LENGTH STEP {set i to i+2.} DO {
	if tgtvalue[i] = "periapsis" { 
		if nd:ORBIT:HASNEXTPATCH 
			set score to score + abs(nd:ORBIT:NEXTPATCH:PERIAPSIS - tgtvalue[i+1]).
		else
			set score to score + abs(cpa(tgt,nd)-tgtvalue[i+1]).
	}
	// if tgtvalue[i] = "apoapsis" { set score to score + abs(nd:ORBIT:NEXTPATCH:APOAPSIS - tgtvalue[i+1]). }
	if tgtvalue[i] = "inclination" { set score to score + (abs(nd:ORBIT:NEXTPATCH:INCLINATION - tgtvalue[i+1])*100). }
	if tgtvalue[i] = "eccentricity" { set score to score + abs(nd:ORBIT:NEXTPATCH:ECCENTRICITY - tgtvalue[i+1]). }
	if tgtvalue[i] = "shiptoship" { 
			set score to score + abs(cpa(tgt,nd)-tgtvalue[i+1]).
	}
	}
	// print score.
	return score.
}

function stepnode {
	parameter nd, i.
	local j is 1/10^STEPSIZE.
	local mult is 10.
	set d to list(
	list ( j*mult, 0, 0, 0),
	list ( -j*mult, 0, 0, 0),
	list ( 0, 0, 0, j),
	list ( 0, 0, 0, -j),
	list ( 0, 0, j*mult, 0),
	list ( 0, 0, -j*mult, 0),
	list ( 0, j*mult, 0, 0),
	list ( 0, -j*mult, 0, 0)).
	
	RETURN NODE(TIME:SECONDS+nd:ETA+d[i][0], nd:RADIALOUT+d[i][1], nd:NORMAL+d[i][2], nd:PROGRADE+d[i][3]).
}
