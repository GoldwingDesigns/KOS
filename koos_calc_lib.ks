@LAZYGLOBAL OFF.

//=====LAUNCH AZIMUTH CALCULATOR=====
//~~LIB_LAZcalc.ks~~
//~~Version 2.1~~
//~~Created by space-is-hard~~
//~~Updated by TDW89~~

//To use: RUN LAZcalc.ks. SET data TO LAZcalc_init([desired circular orbit altitude in meters],[desired orbital inclination; negative if launching from descending node, positive otherwise]). Then loop SET myAzimuth TO LAZcalc(data).
print find_landing_tgt_LAN(latlng(20,27),25,200000,20000).

FUNCTION LAZcalc_init {
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
        HUDTEXT("Inclination impossible from current latitude, setting for lowest possible inclination.", 10, 2, 30, RED, FALSE).
    }.
    
    IF 180 - ABS(launchLatitude) < desiredInc {
        SET desiredInc TO 180 - ABS(launchLatitude).
        HUDTEXT("Inclination impossible from current latitude, setting for highest possible inclination.", 10, 2, 30, RED, FALSE).
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

FUNCTION LAZcalc {
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

function calc_lng_from_tgt {
	//taken from https://ntrs.nasa.gov/archive/nasa/casi.ntrs.nasa.gov/20070025021.pdf
    parameter tgt, inc, posigrade is true.
	local alpha is 0.
	if posigrade {
    	set alpha to abs(arcsin(tan(tgt:lat)/tan(inc))).
		if tgt:lat > 0 {
			return tgt:lng - alpha.
		} else {
			return tgt:lng - alpha + 180.
		}
	} else {
		set alpha to abs(arcsin(tan(tgt:lat)/tan(180-inc))).
		if tgt:lat < 0 {
			return tgt:lng - alpha.
		} else {
			return tgt:lng - alpha + 180.
		}
	}

}

function find_landing_tgt_LAN{
    parameter tgt, inc, posigrade is true, init_alt is ship:obt:semimajoraxis-tgt:body:radius, final_alt is 20000.
    local initorbitperiod is orbit_period(tgt:body,init_alt,final_alt).
    local finalorbitperiod is orbit_period(tgt:body,final_alt,final_alt).
    local bodyrotationperiod is tgt:body:rotationperiod.
    local answer is calc_lng_from_tgt(tgt, inc, posigrade)-tgt:body:rotationangle-(((initorbitperiod/bodyrotationperiod)*360)*0.5)-(((finalorbitperiod/bodyrotationperiod)*360)*0.75).
    //above is longitudinal dist from tgt minus current rotation angle from nodal line minus long dist covered by half transfer orbit minus dist covered during half final orbit and one quarter final orbit
    until answer <= 180 and answer >= -180 {set answer to answer+360.}
    return answer.
}
function orbit_period {
    parameter tgtbody is BODY, p is ship:obt:periapsis+body:radius, a is ship:obt:apoapsis+body:radius.
    return sqrt((4*(constant:pi^2)*((p+a)/2)^3)/tgtbody:mu).
}
