@LAZYGLOBAL OFF.

//=====LAUNCH AZIMUTH CALCULATOR=====
//~~LIB_LAZcalc.ks~~
//~~Version 2.1~~
//~~Created by space-is-hard~~
//~~Updated by TDW89~~

//To use: RUN LAZcalc.ks. SET data TO LAZcalc_init([desired circular orbit altitude in meters],[desired orbital inclination; negative if launching from descending node, positive otherwise]). Then loop SET myAzimuth TO LAZcalc(data).


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
    local tlat is tgt:lat.
    local tlong is tgt:lng.
    // if tlong < 0 { set tlong to tlong + 360. }
	local alpha is 0.
	if posigrade {
    	set alpha to abs(arcsin(tan(tgt:lat)/tan(inc))).
		if tlat > 0 {
			return tlong - alpha.
		} else {
			return tlong - alpha + 180.
		}
	} else {
		set alpha to abs(arcsin(tan(tlat)/tan(180-inc))).
		if tlat < 0 {
			return tlong - alpha.
		} else {
			return tlong - alpha + 180.
		}
	}
}

function orbit_circumference {
    local a is ship:orbit:semimajoraxis.
	local b is ship:orbit:semiminoraxis.
	local h is (a - b)^2 / (a + b)^2.
	local circ is constant:pi * (a + b) *( 1 + 3 * h / (10 + sqrt(4 - 3 * h) )).
    return circ.
}

function find_landing_tgt_LAN{
    parameter tgt, inc, posigrade is true, init_alt is ship:obt:semimajoraxis-tgt:body:radius, final_alt is 20000.
    local initorbitperiod is orbit_period(tgt:body,init_alt,init_alt).
    local transorbitperiod is orbit_period(tgt:body,init_alt,final_alt).
    local finalorbitperiod is orbit_period(tgt:body,final_alt,final_alt).
    local bodyrotationperiod is tgt:body:rotationperiod.
    local answer is calc_lng_from_tgt(tgt, inc, posigrade)+tgt:body:rotationangle+(((initorbitperiod/bodyrotationperiod)*360)*0.5)+(((transorbitperiod/bodyrotationperiod)*360)*0.5)+(((finalorbitperiod/bodyrotationperiod)*360)*0.5).
    //above is longitudinal dist from tgt minus current rotation angle from nodal line minus long dist covered by half transfer orbit minus dist covered during half final orbit and one quarter final orbit
    until answer >= 0 {set answer to answer + 360.}
    until answer <=360 {set answer to answer - 360.}
    return answer.
}

function find_landing_tgt_LAN_lowalt{
    parameter tgt, inc, posigrade is true.
    local finalorbitperiod is orbit_period(tgt:body).
    local bodyrotationperiod is tgt:body:rotationperiod.
    local answer is calc_lng_from_tgt(tgt, inc, posigrade)+tgt:body:rotationangle+(((finalorbitperiod/bodyrotationperiod)*360)*0.25).
    until answer >= 0 {set answer to answer + 360.}
    until answer <=360 {set answer to answer - 360.}
    return answer.
}

function orbit_period {
    parameter tgtbody is BODY, p is ship:obt:periapsis, a is ship:obt:apoapsis.
    set p to p + body:radius.
    set a to a + body:radius.
    return sqrt((4*(constant:pi^2)*((p+a)/2)^3)/tgtbody:mu).
}

function circle_distance {
		parameter
		p1,     //...this point...
		p2,     //...to this point...
		radius. //...around a body of this radius. (note: if you are flying you may want to use ship:body:radius + altitude).
		local A is sin((p1:lat-p2:lat)/2)^2 + cos(p1:lat)*cos(p2:lat)*sin((p1:lng-p2:lng)/2)^2.
		
		return radius*constant():PI*arctan2(sqrt(A),sqrt(1-A))/90.
	}.

function cpa { //largely stolen from CheersKevin - largely
	parameter tgt,nd.
	
	if HASNODE {
		local st is TIME:SECONDS + nd:ETA.
        local et is st + nd:ORBIT:PERIOD.
		local mt is (st+et)/2.
		local sslope is findslope(tgt,st).
		local eslope is findslope(tgt,et).
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

function findslope {
	parameter tgt, t.
	return (seperation_at(tgt, t+1)-seperation_at(tgt, t-1))/2.
}

function seperation_at {
	parameter tgt, t.
	return (positionat(ship,t) - positionat(tgt,t)):mag.
}

function etatoaltitude { //eta until ship reaches altitude above body. Param: altitude (not good for very highly eliptical)
    parameter tgtalt is 1000000.
    local myR is tgtalt + body:radius.
    local mye is orbit:eccentricity.
    local mya is orbit:semimajoraxis.
    local myv is arcCos((mya*(1-mye^2)-myR)/(myR*mye)).
    local myvz is orbit:trueanomaly.
    local mybige is arcCos((mye+cos(myv))/(1+mye*cos(myv))).
    local mybigez is arcCos((mye+cos(myvz))/(1+mye*cos(myvz))).
    local myM is (constant:degtorad*mybige) - mye*sin(mybige).
    local myMz is (constant:degtorad*mybigez) - mye*sin(mybigez).
    local myN is sqrt(body:mu/(mya^3)).
    local myt is (myM-myMz)/myN.
    if myt<0 set myt to ((2*constant:pi)-myM-myMz)/myN. //there are 2 myt's. This resolves ambiguity if the first is behind you
    return myt.
}

function etatoaltitude2 {
    parameter tgtalt to 1000000.
    local altateta is ((positionat(ship,time:seconds+eta:periapsis)-body:position):mag-body:radius).
    local eta is eta:periapsis.
    until altateta >= tgtalt { //work our way backwards from when the periapsis is to find the eta for the altitude above the body
        set eta to eta-1.
        set altateta to ((positionat(ship,time:seconds+eta)-body:position):mag-body:radius). //vector math subtracting position of the body from the position where the ship will be
    }
    return eta.
}

function eta_true_anom {
		declare local parameter tgt_lng.
		// convert the positon from reference to deg from PE (which is the true anomaly)
		local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).
		// s_ref = lan + arg + referenc

		local node_true_anom to (mod (720+ tgt_lng - (obt:lan + obt:argumentofperiapsis),360)).

		//print "Node anomaly   : " + round(node_true_anom,2).    
		local node_eta to 0.
		local ecc to OBT:ECCENTRICITY.
		if ecc < 0.001 {
			set node_eta to SHIP:OBT:PERIOD * ((mod(tgt_lng - ship_ref + 360,360))) / 360.

		} else {
			local eccentric_anomaly to  arccos((ecc + cos(node_true_anom)) / (1 + ecc * cos(node_true_anom))).
			local mean_anom to (eccentric_anomaly - ((180 / (constant():pi)) * (ecc * sin(eccentric_anomaly)))).

			// time from periapsis to point
			local time_2_anom to  SHIP:OBT:PERIOD * mean_anom /360.

			local my_time_in_orbit to ((OBT:MEANANOMALYATEPOCH)*OBT:PERIOD /360).
			set node_eta to mod(OBT:PERIOD + time_2_anom - my_time_in_orbit,OBT:PERIOD) .

		}

		return node_eta.
	}