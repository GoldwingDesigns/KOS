@LAZYGLOBAL OFF.

//=====LAUNCH AZIMUTH CALCULATOR=====
//~~LIB_LAZcalc.ks~~
//~~Version 2.1~~
//~~Created by space-is-hard~~
//~~Updated by TDW89~~

//To use: RUN LAZcalc.ks. SET data TO LAZcalc_init([desired circular orbit altitude in meters],[desired orbital inclination; negative if launching from descending node, positive otherwise]). Then loop SET myAzimuth TO LAZcalc(data).
function seperation_at {
	parameter tgt, t.
	return (positionat(ship,t) - positionat(tgt,t)):mag.
}

function findslope {
	parameter tgt, t.
	return (seperation_at(tgt, t+1)-seperation_at(tgt, t-1))/2.
}

function cpa { //largely stolen from CheersKevin - largely
	parameter tgt,nd.
	
	if HASNODE {
		local st is TIME:SECONDS + nd:ETA.
        local et is st + nd:ORBIT:PERIOD.
		local mt is (st+et)/2.
		local sslope is findslope(tgt,st).
		local mslope is findslope(tgt,mt).
		until (et-st<0.1) or mslope < 0.1 {
			if (mslope * sslope) > 0
				set st to mt.
			else
				set et to mt.
			set mt to (st+et)/2.
			set mslope to findslope(tgt,mt).
		}
		return seperation_at(tgt,mt).
		
	}
}

function LAZcalc_init {
    PARAMETER
        desiredAlt, //Altitude of desired target orbit (in *meters*)
        desiredInc. //Inclination of desired target orbit
    
    //We'll pull the latitude now so we aren't sampling it multiple times
    LOCAL launchLatitude IS SHIP:LATITUDE.
    
    LOCAL data IS LIST().   // A list is used to store information used by LAZcalc
    
    //Orbital altitude can't be less than sea level
    IF desiredAlt <= 0 {
        PRINT "Target altitude cannot be below sea level".
        SET launchAzimuth TO 1/0.		//Throws error
    }.
    
    //Determines whether we're trying to launch from the ascending or descending node
    LOCAL launchNode TO "Ascending".
    IF desiredInc < 0 {
        SET launchNode TO "Descending".
        
        //We'll make it positive for now and convert to southerly heading later
        SET desiredInc TO ABS(desiredInc).
    }.
    
    //Orbital inclination can't be less than launch latitude or greater than 180 - launch latitude
    IF ABS(launchLatitude) > desiredInc {
        SET desiredInc TO ABS(launchLatitude).
        // HUDTEXT("Inclination impossible from current latitude, setting for lowest possible inclination.", 10, 2, 30, RED, FALSE).
    }.
    
    IF 180 - ABS(launchLatitude) < desiredInc {
        SET desiredInc TO 180 - ABS(launchLatitude).
        // HUDTEXT("Inclination impossible from current latitude, setting for highest possible inclination.", 10, 2, 30, RED, FALSE).
    }.
    
    //Does all the one time calculations and stores them in a list to help reduce the overhead or continuously updating
    LOCAL equatorialVel IS (2 * CONSTANT():Pi * BODY:RADIUS) / BODY:ROTATIONPERIOD.
    LOCAL targetOrbVel IS SQRT(BODY:MU/ (BODY:RADIUS + desiredAlt)).
    data:ADD(desiredInc).       //[0]
    data:ADD(launchLatitude).   //[1]
    data:ADD(equatorialVel).    //[2]
    data:ADD(targetOrbVel).     //[3]
    data:ADD(launchNode).       //[4]
    RETURN data.
}

function LAZcalc {
    PARAMETER
        data. //pointer to the list created by LAZcalc_init
    LOCAL inertialAzimuth IS ARCSIN(MAX(MIN(COS(data[0]) / COS(SHIP:LATITUDE), 1), -1)).
    LOCAL VXRot IS data[3] * SIN(inertialAzimuth) - data[2] * COS(data[1]).
    LOCAL VYRot IS data[3] * COS(inertialAzimuth).
    
    // This clamps the result to values between 0 and 360.
    LOCAL Azimuth IS MOD(ARCTAN2(VXRot, VYRot) + 360, 360).
    
    //Returns northerly azimuth if launching from the ascending node
    IF data[4] = "Ascending" {
        RETURN Azimuth.
        
    //Returns southerly azimuth if launching from the descending node
    } ELSE IF data[4] = "Descending" {
        IF Azimuth <= 90 {
            RETURN 180 - Azimuth.
            
        } ELSE IF Azimuth >= 270 {
            RETURN 540 - Azimuth.
            
        }.
    }.
}

function orbit_circumference {
    local a is ship:orbit:semimajoraxis.
	local b is ship:orbit:semiminoraxis.
	local h is (a - b)^2 / (a + b)^2.
	local circ is constant:pi * (a + b) *( 1 + 3 * h / (10 + sqrt(4 - 3 * h) )).
    return circ.
}

function orbit_period {
    parameter tgtbody is BODY, p is ship:obt:periapsis, a is ship:obt:apoapsis.
    set p to p + body:radius.
    set a to a + body:radius.
    return sqrt((4*(constant:pi^2)*((p+a)/2)^3)/tgtbody:mu).
}

function etatoaltitude2 {
    parameter tgtalt to 1000000.
    local altateta is ((positionat(ship,time:seconds+eta:periapsis)-body:position):mag-body:radius).
    local etaper is eta:periapsis.
    until altateta >= tgtalt { //work our way backwards from when the periapsis is to find the eta for the altitude above the body
        set etaper to etaper-1.
        set altateta to ((positionat(ship,time:seconds+etaper)-body:position):mag-body:radius). //vector math subtracting position of the body from the position where the ship will be
    }
    return etaper.
}

function eta_true_anom { 
    //100% from https://www.reddit.com/r/Kos/comments/3r5pbj/set_inclination_from_orbit_script/  I tried to do on my own but couldn't
	declare local parameter tgt_lng.
	// convert the positon from reference to deg from PE (which is the true anomaly)
	local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).
	// s_ref = lan + arg + referenc

	local node_true_anom to (mod (720+ tgt_lng - (obt:lan + obt:argumentofperiapsis),360)).

	// print "Node anomaly   : " + round(node_true_anom,2).	
	local node_eta to 0.
	local ecc to OBT:ECCENTRICITY.
	if ecc < 0.001 {
		set node_eta to SHIP:OBT:PERIOD * ((mod(tgt_lng - ship_ref + 360,360))) / 360.
	
	} else {
		local eccentric_anomaly to	arccos((ecc + cos(node_true_anom)) / (1 + ecc * cos(node_true_anom))).
		local mean_anom to (eccentric_anomaly - ((180 / (constant():pi)) * (ecc * sin(eccentric_anomaly)))).
	
		// time from periapsis to point
		local time_2_anom to  SHIP:OBT:PERIOD * mean_anom /360.

		local my_time_in_orbit to ((OBT:MEANANOMALYATEPOCH)*OBT:PERIOD /360).
		set node_eta to mod(OBT:PERIOD + time_2_anom - my_time_in_orbit,OBT:PERIOD) .

	}
	
	return node_eta.
}

function pitchangle { //https://www.youtube.com/watch?v=0g3CQEEjbH8
    local parameter direction.
    local upvec to SHIP:UP:FOREVECTOR.
    local dirvec to direction:FOREVECTOR.
	local result to arccos((vdot(dirvec,upvec)/(dirvec:MAG))).
    return result.
}

function findLaunchWindowToTarget {
    parameter leadTime is 60, myTarget is target.
    return findLaunchWindow(leadTime,myTarget:orbit:inclination,myTarget:orbit:lan).
}
function findLaunchWindow {
    parameter leadTime is 60, alpha is 0, raan is 0.
    local lt is leadTime/3600.
    local launchTimeSec is 0.
    // local bodyperiodinhours is body:rotationperiod/60/60.
    local bodyperiodinhours is 6.
    local rotdegperhour is 360/(bodyperiodinhours).
    local lat is ship:latitude.
    local long is ship:longitude.
    local lst to (mod(ship:body:rotationangle + mod((360+long),360),360))/rotdegperhour.
    if abs(alpha) < abs(lat) {
      UI["msg add"]("Unable to match target inclination").
      return list(-1,-1).
    } else if alpha=abs(lat){
      local l is (raan+90)/rotdegperhour.
      set launchTimeSec to time:seconds+(mod(l-lst+bodyperiodinhours,bodyperiodinhours)*3600).
      return list(launchTimeSec,alpha).
    } else {
      local gamma is arcsin(cos(alpha)/cos(lat)).
      local delta is arccos(cos(gamma)/sin(alpha)).
      local lwstan is 0.
      local lwstdn is 0.
      local case is 0. //case 0 is north prograde, case 1 is south prograde or north retrograde, case 2 is south retrograde
      if lat < 0 set case to case + 1.
      if alpha > 90 or alpha < -90 set case to case + 1.
      if case = 0 {
        set lwstan to raan - delta.
        set lwstdn to raan + (180 + delta).
      } else {
        set lwstan to raan + delta.
        set lwstdn to raan + (180-delta).
      }
      local l1 is lwstan / rotdegperhour.  
      local l2 is lwstdn / rotdegperhour.
      local a is alpha.
      local ltemp is 0.
      if lst+lT > l1 and lst+lT < l2 {
        // print "choose l2".
        set a to -1 * a.
        set ltemp to l2-lst.
        until ltemp > 0  set ltemp to ltemp+bodyperiodinhours.
        set launchTimeSec to time:seconds+(mod(ltemp+bodyperiodinhours,bodyperiodinhours)*3600). // change 6 to rotation of body in hrs
      } else {
        // print "choose l1".
        set ltemp to l1-lst.
        until ltemp > 0  set ltemp to ltemp+bodyperiodinhours.
        set launchTimeSec to time:seconds+(mod(ltemp+bodyperiodinhours,bodyperiodinhours)*3600).
      }
      return list(launchTimeSec, a).
    }
}
// function getLaunchAzimuth {
//     parameter a.
//     local lat is ship:latitude.
//     if a < lat {
//         return 1/0.
//     } else {
//       local gamma is arcsin(cos(a)/cos(lat)). 
//       if a<0 return 180-gamma.
//       return gamma.
//     }
// }
// function isPosigrade {
//   return vdot(vcrs(SHIP:VELOCITY:orbit:normalized,ship:Body:position),SHIP:BODY:ANGULARVEL:normalized)>0.
// }
//here to next comment completely copied from u/yagoki134 https://gist.github.com/benjft/05d9966300ea216167ee32b7dbb4d3cc

    /// <summary>Finds the greatest common denominator of A and B using the Euclidean Algorithm
    /// </summary>

//end copy from https://gist.github.com/benjft/05d9966300ea216167ee32b7dbb4d3cc