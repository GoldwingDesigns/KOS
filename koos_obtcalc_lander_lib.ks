@LAZYGLOBAL OFF.

function orbit_circumference {
    local a is ship:orbit:semimajoraxis.
	local b is ship:orbit:semiminoraxis.
	local h is (a - b)^2 / (a + b)^2.
	local circ is constant:pi * (a + b) *( 1 + 3 * h / (10 + sqrt(4 - 3 * h) )).
    return circ.
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
	}.
function orbit_period {
    parameter tgtbody is BODY, p is ship:obt:periapsis, a is ship:obt:apoapsis.
    set p to p + body:radius.
    set a to a + body:radius.
    return sqrt((4*(constant:pi^2)*((p+a)/2)^3)/tgtbody:mu).
}
function calc_lng_from_tgt {
    parameter tgt, inc.
    local tlat is tgt:lat.
    local tlong is tgt:lng.
		// if tlong < 0 set tlong to tlong + 360.
	local alpha is 0.

	if inc < 90 { //posigrade
	if abs(inc-abs(tlat))<0.001 set alpha to 90.
		else {
			set alpha to abs(arcsin(tan(tlat)/tan(inc))).
		}
		if tlat > 0 {
			return tlong - alpha.
		} else {
			return tlong - alpha + 180.
		}
	} else {
		if abs((180-inc)-abs(tlat))<0.001 set alpha to 90.
		else {
		set alpha to abs(arcsin(tan(tlat)/tan(180-inc))).
		}
		if tlat < 0 {
			return tlong - alpha.
		} else {
			return tlong - alpha + 180.
		}
		
	}
}
