@LAZYGLOBAL OFF.

function seperation_at {
	parameter tgt, t.
	return (positionat(ship,t) - positionat(tgt,t)):mag.
}

function findslope {
	parameter tgt, t.
	return (seperation_at(tgt, t+1)-seperation_at(tgt, t-1))/2.
}

function cpa { //largely stolen from CheersKevin - largely
	parameter tgt,nd,returntime is false, sensitivity is 1.
        local st is TIME:SECONDS.
        local et is st + ship:ORBIT:PERIOD.
	if HASNODE {
		set st to TIME:SECONDS + nd:ETA.
        set et to st + nd:ORBIT:PERIOD.
    }
		local mt is (st+et)/2.
		local sslope is findslope(tgt,st).
		local mslope is findslope(tgt,mt).
		until (et-st<0.1) or abs(mslope) < 0.1^sensitivity {
			if (mslope * sslope) > 0
				set st to mt.
			else
				set et to mt.
			set mt to (st+et)/2.
			set mslope to findslope(tgt,mt).
		}
        if returntime {
            return mt.
        } else {
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

function plane_change_info {
    parameter inc_t, lan_t.
    local inc_i to SHIP:OBT:inclination.
    local lan_i to SHIP:OBT:LAN.
    local Va to V(sin(inc_i)*cos(lan_i+90),sin(inc_i)*sin(lan_i+90),cos(inc_i)).
    local Vb to V(sin(inc_t)*cos(lan_t+90),sin(inc_t)*sin(lan_t+90),cos(inc_t)).
    // important to use the reverse order
    local Vc to VCRS(Vb,Va).
    local theta to arccos (vdot(Vb,Va) ).
    local node_lng to mod(arctan2(Vc:Y,Vc:X)+360,360).
    local negind to 1.
    //compute burn_point and set to the range of [0,360]
    local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).
    local ship_2_node to mod((720 + node_lng - ship_ref),360).
    if ship_2_node > 180 {
        set negind to -1.
        set node_lng to mod(node_lng + 180,360).
    } 		
    local nd_eta is eta_true_anom(node_lng).
    local nd_time is nd_eta + time:seconds.
    return LIST(theta,nd_time,negind).
}

function find_landing_tgt_LAN{
    parameter tgt, inc, final_alt is 20000, init_alt is ship:obt:semimajoraxis-tgt:body:radius.
    // local initorbitperiod is orbit_period(tgt:body,init_alt,init_alt).
    local transorbitperiod is orbit_period(tgt:body,init_alt,final_alt).
    local finalorbitperiod is orbit_period(tgt:body,final_alt,final_alt).
    local bodyrotationperiod is tgt:body:rotationperiod.
    local sameside to true.
    if VDOT(tgt:position - SHIP:BODY:POSITION,ship:position - ship:body:position) < 0 set sameside to false.
    local answer to 0.
    set answer to calc_lng_from_tgt(tgt, inc)+tgt:body:rotationangle+(((transorbitperiod/bodyrotationperiod)*360)*0.5)+(((finalorbitperiod/bodyrotationperiod)*360)*0.25).
    if sameside = false set answer to answer + (((finalorbitperiod/bodyrotationperiod)*360)*0.5).
    until answer >= 0 {set answer to answer + 360.}
    until answer <=360 {set answer to answer - 360.}
    local info to plane_change_info(inc,answer).
    local ndtime to info[1].
    set answer to answer+body:angularvel:mag*constant:radtodeg*(ndtime-time:seconds).//how long till node and how far will the body rotate in that time.
    until answer >= 0 {set answer to answer + 360.}
    until answer <=360 {set answer to answer - 360.}
    return answer.
}

function eta_true_anom { 
	declare local parameter tgt_lng.
	local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).
	local node_true_anom to (mod (720+ tgt_lng - (obt:lan + obt:argumentofperiapsis),360)).
	local progr to ship:obt:inclination < 91.
	local node_eta to 0.
	local ecc to OBT:ECCENTRICITY.
	if ecc < 0.001 {
		if progr {
		set node_eta to SHIP:OBT:PERIOD * ((mod(tgt_lng - ship_ref + 720,360))) / 360.
		 } else {
		set node_eta to SHIP:OBT:PERIOD * ((mod(360-tgt_lng - ship_ref + 720,360))) / 360.
		 }
			} else {
		local eccentric_anomaly to	arccos((ecc + cos(node_true_anom)) / (1 + ecc * cos(node_true_anom))).
		local mean_anom to (eccentric_anomaly - ((180 / (constant():pi)) * (ecc * sin(eccentric_anomaly)))).
		local time_2_anom to 0.
		if progr {
		set time_2_anom to  SHIP:OBT:PERIOD * mean_anom /360.
		} else {
		set time_2_anom to  SHIP:OBT:PERIOD * (360-mean_anom) /360.
		}
		local my_time_in_orbit to ((OBT:MEANANOMALYATEPOCH)*OBT:PERIOD /360).
		set node_eta to mod(OBT:PERIOD + time_2_anom - my_time_in_orbit,OBT:PERIOD) .
	}
	return node_eta.
}

function circle_distance {
    parameter
    p1,     //...this point...
    p2,     //...to this point...
    radius. //...around a body of this radius. (note: if you are flying you may want to use ship:body:radius + altitude).
    local A is sin((p1:lat-p2:lat)/2)^2 + cos(p1:lat)*cos(p2:lat)*sin((p1:lng-p2:lng)/2)^2.
    return radius*constant():PI*arctan2(sqrt(A),sqrt(1-A))/90.
}

function calc_lng_from_tgt {
    parameter tgt, inc.
    local tlat is tgt:lat.
    local tlong is tgt:lng.
	local alpha is 0.

	if inc < 90 { //posigrade
        if abs(inc-abs(tlat))<0.001 {
            set alpha to 90.
        } else {
            set alpha to abs(arcsin(tan(tlat)/tan(inc))).
        }
        if tlat > 0 {
            return tlong - alpha.
        } else {
            return tlong - alpha + 180.
        }
    } else {
        if abs((180-inc)-abs(tlat))<0.001 {
            set alpha to 90.
        } else {
            set alpha to abs(arcsin(tan(tlat)/tan(180-inc))).
        }
        if tlat < 0 {
            return tlong - alpha.
        } else {
            return tlong - alpha + 180.
        }
    }
}
