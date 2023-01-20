local INFINITY is 2^64.
local BQ is QUEUE().
local LASTMEAN is 0.
local STEPSIZE is 0.
local LASTSCORE is INFINITY.
local MEANQ is QUEUE().
local answer is NODE(0,0,0,0).

function beamsearch {
	parameter nd, moonname, tgtvalue, ish.
	if evaluate(nd, moonname, tgtvalue, ish)[1] = 0 return nd.
	BQ:CLEAR().
	BQ:PUSH(nd).
	set STEPSIZE to 0.
	UNTIL findneighbors(moonname, tgtvalue, ish) {}
	return answer.
}

function findneighbors{
	parameter moonname, tgtvalue, ish.
	local nd is BQ:POP().
	local rlist to list().
	rlist:CLEAR.
	FROM {local i is 0.} UNTIL i = 4 STEP {set i to i+1.} DO {
		rlist:ADD(evaluate(stepnode(nd,i),moonname,tgtvalue,ish)).
	}
	local sortlist is arrsort(rlist).
	local bestscore is sortlist[0][1].
	if bestscore = 0 {set answer to sortlist[0][0]. return TRUE.}
	if bestscore > LASTSCORE {BQ:PUSH(nd). set STEPSIZE to STEPSIZE + 1.}
	else {BQ:PUSH(sortlist[0][0]). set LASTSCORE to bestscore.}
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
	parameter nd, moonname, tgtvalue, ish.
	ADD nd.
	WAIT 0.1.
	local score is scorenode(tgtvalue).
	REMOVE nd.
	if score < ish { return list(nd,0). }
	return list(nd,score).
}

function scorenode{
	parameter tgtvalue.
	local score is 0.
	for p in tgtvalue {
	if p:KEY = "periapsis" { set score to score + abs(nd:ORBIT:NEXTPATCH:PERIAPSIS - p:VALUE). }
	if p:KEY = "apoapsis" { set score to score + abs(nd:ORBIT:NEXTPATCH:APOAPSIS - p:VALUE). }
	if p:KEY = "inclination" { set score to score + abs(nd:ORBIT:NEXTPATCH:INCLINATION - p:VALUE)*100. }
	if p:KEY = "eccentricity" { set score to score * abs(nd:ORBIT:NEXTPATCH:ECCENTRICITY - p:VALUE). }
	}
	return score.
}

function stepnode {
	parameter nd, i.
	local j is 1/10^STEPSIZE.
	local mult is 1.
	set d to list(
	list ( j, 0, 0, 0),
	list ( -j, 0, 0, 0),
	list ( 0, 0, 0, j*mult),
	list ( 0, 0, 0, -j*mult),
	list ( 0, 0, j*mult, 0),
	list ( 0, 0, -j*mult, 0),
	list ( 0, j*mult, 0, 0),
	list ( 0, -j*mult, 0, 0)).
	
	RETURN NODE(TIME:SECONDS+nd:ETA+d[i][0], nd:RADIALOUT+d[i][1], nd:NORMAL+d[i][2], nd:PROGRADE+d[i][3]).
}
