@lazyglobal off.

//Launch Maneuvers

function ShipTWR {
	local englist to list().
    list engines in englist.
	local mth to englist[englist:LENGTH - 1]:THRUST.
	//set mth to SHIP:MAXTHRUST. // (depends on fixed kOS issue 940)
    local r to SHIP:ALTITUDE+SHIP:BODY:RADIUS.
    local w to SHIP:MASS * SHIP:BODY:MU / r / r.
    return mth/w.
}

function launch{
	parameter launchalt, launchinc, launchcirc.
	SET COMPMODE to 9.
	gui_menu_run().
	local th to 1. //Variable for locked throttle.  1.0 is the max, 0.0 is idle.
	local Steering_Lock TO HEADING(90,90). //Variable for locked steering.
	local TurnEnd TO 60000. //The ending altitude for the ascent turn.
	local TurnExponent TO 0.5. //Turn exponent for curvature.
	local TurnStart TO 0.  //Used to mark the altitude that the ascent turn begins.
	local MyPitch TO 90. //Initial setting for pitch on launch (straight up).
	local DesiredTWR TO 2. //DesiredTWR throughout launch
	local newth to 0.
	local launchaz to LAZcalc(LAZcalc_init(launchalt,launchinc)).
	local TWRPID is PIDLOOP(0.1,0,0.01,-0.5,0.5). //PID loop to set throttle to DesiredTWR.
	SET TWRPID:SETPOINT to DesiredTWR.



	//**Setup Throttle and Steering Locks.
	LOCK THROTTLE TO th.   
	LOCK STEERING TO Steering_Lock. // from now on we'll be able to change steering by just assigning a new value to Steering_Lock

	//**Declare Triggers.

	//**Trigger to open the Solar Panels and turn on Lights when above atmosphere.
	WHEN SHIP:ALTITUDE > SHIP:ORBIT:BODY:ATM:HEIGHT THEN {
	PANELS ON.
	LIGHTS ON.
	gui_msg_add("Panels Extended.").
	}
	//**Trigger to mark the altitue the ascent turn begins
	WHEN SHIP:VELOCITY:SURFACE:MAG >= 50 THEN{
	SET TurnStart TO SHIP:ALTITUDE - 10.
	gui_msg_add("Commence Roll.").
	}

	//**Uncomment to draw vectors
	//set vd to vecdraw(V(0,0,0),ship:srfprograde:forevector,green,"srfprograde",20,TRUE). 
	//set vd:vecupdater to {
	//	return ship:srfprograde:forevector.
	//	}.
	// vecdraw(V(0,0,0),UP:VECTOR,red,"kerbinup",20,TRUE). 

	//**Uncomment below to log throttle PID info**
	//SET start_time to TIME:SECONDS.
	//LOG "# Throttle PID Tuning" to throttle_log.
	//LOG "# Kp: " + TWRPID:KP TO throttle_log.
	//LOG "t,P,ShipTWR,Th" TO throttle_log.
	//LOCK logline TO (TIME:SECONDS - start_time) + "," + TWRPID:ERROR + "," + CurTWR + "," + th.

	GLOBAL STARTTIME to TIME.

	UNTIL SHIP:APOAPSIS >= launchalt AND SHIP:ALTITUDE >=70000 { //Until the desired Apoapsis is reached and we are out of the atmospere
		LOCK MyPitch TO 90 * (1 - ((SHIP:ALTITUDE-TurnStart) / TurnEnd) ^ TurnExponent).

		IF SHIP:VELOCITY:SURFACE:MAG < 50 {//Initial launch will be straight up 
			SET Steering_Lock TO HEADING(90,90).
		} 
		ELSE IF SHIP:ALTITUDE < TurnEnd AND SHIP:APOAPSIS < launchalt { //If still following the launch curve and desired apoapsis not reached 
			local CurTWR to ShipTWR.
			SET Steering_Lock TO HEADING(launchaz,MyPitch).
			set newth to th+TWRPID:UPDATE(time:seconds, CurTWR).
			SET th to MIN(1,MAX(newth,0)).
		} 
		ELSE { //If launch curve has ended or desired apoapsis value is reached.
			local CurTWR to ShipTWR.
			SET Steering_Lock TO HEADING(launchaz,0).
			IF SHIP:APOAPSIS < launchalt { //Apoapsis value has dropped due to drag.
			set newth to th+TWRPID:UPDATE(time:seconds, CurTWR).
			} 
			ELSE { //Coasting to Apoapsis.
				set newth to 0.
			}
			SET th to MIN(1,MAX(newth,0)).
		}
		
		man_check_stage(0).

		WAIT 0.1.
		gui_scr_update().
		
		
	}

	gui_msg_add("Cutting throttle.").

	//**Uncomment below to log throttle PID info**
	//COPYPATH("throttle_log", "0:/throttletest.xls").

	//**At this point, our apoapsis is above the desired value and our main loop has ended. Next
	//**we'll make sure our throttle is zero and that we're pointed prograde.
	LOCK THROTTLE TO 0.
	UNLOCK THROTTLE.
	SET Steering_Lock TO LOOKDIRUP(ship:prograde:forevector, SHIP:BODY:POSITION).
	WAIT 10.
	UNLOCK STEERING.
	if launchcirc {
		circularize().
	}
	else {
		IF SHIP:ORBIT:PERIAPSIS > SHIP:ORBIT:BODY:ATM:HEIGHT SET COMPMODE TO 2.
		ELSE IF SHIP:ORBIT:APOAPSIS > SHIP:ORBIT:BODY:ATM:HEIGHT SET COMPMODE TO 1.
	}
}

function man_check_stage{
	parameter laststage.
	if stage:number >= laststage {
		if maxthrust = 0 {
			stage.
			gui_msg_add("Stage.").
			return.
		}
		local numOut to 0.
		local myengines to list().
		LIST ENGINES IN myengines. 
		FOR eng IN myengines {
			IF eng:FLAMEOUT 	{
				SET numOut TO numOut + 1.
			}
		}
		if numOut > 0 { stage.  gui_msg_add("Stage."). }.
	}
}
//Circularization Maneuvers

function circularize{
	SET COMPMODE to 9.
	gui_menu_run().
	local Mi to SHIP:MASS.
	local thisMU to BODY:MU.
	local thisR to BODY:RADIUS + SHIP:APOAPSIS.
	local thisA to BODY:RADIUS + ((SHIP:APOAPSIS + SHIP:PERIAPSIS)/2).
	local thisDV to SQRT(thisMU * (2/thisR - 1/thisR)) - SQRT(thisMU * (2/thisR - 1/thisA)).
	local Go to 9.80665.
	local englist is list().
	list engines in englist.
	local engISP to englist[englist:LENGTH - 1]:VISP.
	local engT to englist[englist:LENGTH - 1]:AVAILABLETHRUST.
	local burnTime to thisDV/(engT * (((Mi + (Mi * (constant:e ^ (-1 * (thisDV / (engISP * Go) )))))/2) ^ (-1))).
	local nd to NODE(TIME:SECONDS + ETA:APOAPSIS,0,0,thisDV).
	ADD nd.
	exec_node().
}

//Inclination Maneuvers
//taken from G_Space on https://www.reddit.com/r/Kos/comments/3r5pbj/set_inclination_from_orbit_script/

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

function set_inc_lan {
    DECLARE PARAMETER incl_t.
    DECLARE PARAMETER lan_t.
    local incl_i to SHIP:OBT:INCLINATION.
    local lan_i to SHIP:OBT:LAN.

// setup the vectors to highest latitude; Transform spherical to cubic coordinates.
    local Va to V(sin(incl_i)*cos(lan_i+90),sin(incl_i)*sin(lan_i+90),cos(incl_i)).
    local Vb to V(sin(incl_t)*cos(lan_t+90),sin(incl_t)*sin(lan_t+90),cos(incl_t)).
// important to use the reverse order
    local Vc to VCRS(Vb,Va).

    local dv_factor to 1.
    //compute burn_point and set to the range of [0,360]
    local node_lng to mod(arctan2(Vc:Y,Vc:X)+360,360).
    local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).

    local ship_2_node to mod((720 + node_lng - ship_ref),360).
    if ship_2_node > 180 {
        //print "Switching to DN".
        set dv_factor to -1.
        set node_lng to mod(node_lng + 180,360).
    }       

    local node_true_anom to 360- mod(720 + (obt:lan + obt:argumentofperiapsis) - node_lng , 360 ).
    local ecc to OBT:ECCENTRICITY.
    local my_radius to OBT:SEMIMAJORAXIS * (( 1 - ecc^2)/ (1 + ecc*cos(node_true_anom)) ).
    local my_speed1 to sqrt(SHIP:BODY:MU * ((2/my_radius) - (1/OBT:SEMIMAJORAXIS)) ).   
    local node_eta to eta_true_anom(node_lng).
    local my_speed to VELOCITYAT(SHIP, time+node_eta):ORBIT:MAG.
    local d_inc to arccos (vdot(Vb,Va) ).
    local dvtgt to dv_factor* (2 * (my_speed) * SIN(d_inc/2)).

    // Create a blank node
    local inc_node to NODE(node_eta, 0, 0, 0).
 // we need to split our dV to normal and prograde
    set inc_node:NORMAL to dvtgt * cos(d_inc/2).
    // always burn retrograde
    set inc_node:PROGRADE to 0 - abs(dvtgt * sin(d_inc/2)).
    set inc_node:ETA to node_eta.

    ADD inc_node.
	exec_node().
}

//Execute Node Maneuvers
//warp taken from TheDapperScot on https://www.reddit.com/r/Kos/comments/5t1qx9/node_execution_script_is_causing_wild_spinning/

function exec_node{
	SET COMPMODE TO 9.
	gui_menu_run().
	local nd to nextnode.
	sas off.
	local np to lookdirup(nd:deltav,SHIP:BODY:POSITION).
	LOCK np to lookdirup(nd:deltav,SHIP:BODY:POSITION).
	LOCAL th to 0.
	LOCK THROTTLE to th.
	//LOCK STEERING to np.
	lock max_acc to ship:maxthrust/ship:mass.
	lock burn_duration to nd:deltav:mag/max_acc.
	
	
	//UNTIL ABS(np:PITCH - FACING:PITCH) < 0.5 AND ABS(np:YAW - FACING:YAW) < 0.5 {
	//	gui_scr_update().
	//	WAIT 0.1.
	//}
	SET WARP to 4.
	UNTIL nd:ETA < (burn_duration/2+60)	{
		gui_scr_update().
		WAIT 0.1.
	}
	SET WARP to 0.
	LOCK STEERING to np.
	UNTIL nd:ETA <= (burn_duration/2)	{
		gui_scr_update().
		WAIT 0.1.
	}

	local done to FALSE.
	local dv0 to nd:DELTAV.

	UNTIL done{
		gui_scr_update().
		//recalculate current max_acceleration, as it changes while we burn through fuel
		//SET np to lookdirup(nd:deltav,SHIP:BODY:POSITION).
		//throttle is 100% until there is less than 1 second of time left to burn
		//when there is less than 1 second - decrease the throttle linearly
		if max_acc <> 0 set th to min(nd:deltav:mag/max_acc, 1).
		//here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
		//this check is done via checking the dot product of those 2 vectors
		
		if vdot(dv0, nd:deltav) < 0 {
			gui_msg_add("End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1)).
			lock throttle to 0.
			break.
		}

		//we have very little left to burn, less then 0.1m/s
		if nd:deltav:mag < 0.1 {
			gui_msg_add("Finalizing burn, remain dv " + round(nd:deltav:mag,1) + "m/s").
			//we burn slowly until our node vector starts to drift significantly from initial vector
			//this usually means we are on point
			wait until vdot(dv0, nd:deltav) < 0.5.

			lock throttle to 0.
			gui_msg_add("End burn, remain dv " + round(nd:deltav:mag,1) + "m/s").
			set done to True.
		}
		man_check_stage(0).
		wait 0.001.
	}

	LOCK STEERING TO LOOKDIRUP(ship:prograde:forevector, SHIP:BODY:POSITION).
	gui_msg_add("Stabilizing steering").
	gui_scr_update().
	WAIT 10.
	UNLOCK STEERING.
	SAS ON.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
	UNLOCK THROTTLE.
	WAIT 1.
	IF SHIP:ORBIT:PERIAPSIS > SHIP:ORBIT:BODY:ATM:HEIGHT SET COMPMODE TO 2.
	ELSE IF SHIP:ORBIT:APOAPSIS > SHIP:ORBIT:BODY:ATM:HEIGHT SET COMPMODE TO 1.
	UNLOCK np.
	REMOVE nd.
	gui_data_clr_node().
	SET COMPMODE to 2.
}

function exec_node_raw{
	parameter utimeVar,radialVar,normalVar,progradeVar.
	local burnvec TO V(radialVar,normalVar,progradeVar).
	SET COMPMODE TO 9.
	gui_menu_run().
	//local nd to nextnode.
	sas off.
	local np to lookdirup(burnvec,SHIP:BODY:POSITION).
	LOCK np to lookdirup(burnvec,SHIP:BODY:POSITION).
	LOCAL th to 0.
	LOCK THROTTLE to th.
	//LOCK STEERING to np.
	lock max_acc to ship:maxthrust/ship:mass.
	lock burn_duration to burnvec:mag/max_acc.
	
	
	//UNTIL ABS(np:PITCH - FACING:PITCH) < 0.5 AND ABS(np:YAW - FACING:YAW) < 0.5 {
	//	gui_scr_update().
	//	WAIT 0.1.
	//}
	SET WARP to 4.
	UNTIL (utimeVar-TIME) < (burn_duration/2+60)	{
		gui_scr_update().
		WAIT 0.1.
	}
	SET WARP to 0.
	LOCK STEERING to np.
	UNTIL (utimeVar-TIME) <= (burn_duration/2)	{
		gui_scr_update().
		WAIT 0.1.
	}

	local done to FALSE.
	local dv0 to burnvec.

	UNTIL done{
		gui_scr_update().
		//recalculate current max_acceleration, as it changes while we burn through fuel
		//SET np to lookdirup(nd:deltav,SHIP:BODY:POSITION).
		//throttle is 100% until there is less than 1 second of time left to burn
		//when there is less than 1 second - decrease the throttle linearly
		if max_acc <> 0 set th to min(burnvec:mag/max_acc, 1).
		//here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
		//this check is done via checking the dot product of those 2 vectors
		
		if vdot(dv0, burnvec) < 0 {
			gui_msg_add("End burn, remain dv " + round(burnvec:mag,1) + "m/s, vdot: " + round(vdot(dv0, burnvec),1)).
			lock throttle to 0.
			break.
		}

		//we have very little left to burn, less then 0.1m/s
		if burnvec:mag < 0.1 {
			gui_msg_add("Finalizing burn, remain dv " + round(burnvec:mag,1) + "m/s").
			//we burn slowly until our node vector starts to drift significantly from initial vector
			//this usually means we are on point
			wait until vdot(dv0, burnvec) < 0.5.

			lock throttle to 0.
			gui_msg_add("End burn, remain dv " + round(burnvec:mag,1) + "m/s").
			set done to True.
		}
		man_check_stage(0).
		wait 0.001.
	}

	LOCK STEERING TO LOOKDIRUP(ship:prograde:forevector, SHIP:BODY:POSITION).
	gui_msg_add("Stabilizing steering").
	gui_scr_update().
	WAIT 10.
	UNLOCK STEERING.
	SAS ON.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
	UNLOCK THROTTLE.
	WAIT 1.
	IF SHIP:ORBIT:PERIAPSIS > SHIP:ORBIT:BODY:ATM:HEIGHT SET COMPMODE TO 2.
	ELSE IF SHIP:ORBIT:APOAPSIS > SHIP:ORBIT:BODY:ATM:HEIGHT SET COMPMODE TO 1.
	UNLOCK np.
	//REMOVE nd.
	gui_data_clr_node().
	SET COMPMODE to 2.
}
	
function change_apo{
	parameter newalt.
	SET COMPMODE to 9.
	gui_menu_run().
	local Mi to SHIP:MASS.
	local thisMU to BODY:MU.
	local thisR to BODY:RADIUS + SHIP:PERIAPSIS.
	local thisA to BODY:RADIUS + ((SHIP:PERIAPSIS + SHIP:APOAPSIS)/2).
	local nextA to BODY:RADIUS + ((SHIP:PERIAPSIS + newalt)/2).
	local thisDV to SQRT(thisMU * (2/thisR - 1/nextA)) - SQRT(thisMU * (2/thisR - 1/thisA)).
	local Go to 9.80665.
	local englist is list().
	list engines in englist.
	local engISP to englist[englist:LENGTH - 1]:VISP.
	local engT to englist[englist:LENGTH - 1]:AVAILABLETHRUST.
	local burnTime to thisDV/(engT * (((Mi + (Mi * (constant:e ^ (-1 * (thisDV / (engISP * Go) )))))/2) ^ (-1))).
	//local nd to NODE(TIME:SECONDS + ETA:PERIAPSIS,0,0,thisDV).
	//ADD nd.
	exec_node_raw(TIME:SECONDS + ETA:PERIAPSIS,0,0,thisDV).
}

function change_per{
	parameter newalt.
	SET COMPMODE to 9.
	gui_menu_run().
	local Mi to SHIP:MASS.
	local thisMU to BODY:MU.
	local thisR to BODY:RADIUS + SHIP:APOAPSIS.
	local thisA to BODY:RADIUS + ((SHIP:APOAPSIS + SHIP:PERIAPSIS)/2).
	local nextA to BODY:RADIUS + ((SHIP:APOAPSIS + newalt)/2).
	local thisDV to SQRT(thisMU * (2/thisR - 1/nextA)) - SQRT(thisMU * (2/thisR - 1/thisA)).
	local Go to 9.80665.
	local englist is list().
	list engines in englist.
	local engISP to englist[englist:LENGTH - 1]:VISP.
	local engT to englist[englist:LENGTH - 1]:AVAILABLETHRUST.
	local burnTime to thisDV/(engT * (((Mi + (Mi * (constant:e ^ (-1 * (thisDV / (engISP * Go) )))))/2) ^ (-1))).
	local nd to NODE(TIME:SECONDS + ETA:APOAPSIS,0,0,thisDV).
	ADD nd.
	exec_node().
}

function hohmann_trans{
	parameter newalt.
	local oldalt to SHIP:PERIAPSIS.
	if ETA:APOAPSIS < ETA:PERIAPSIS {
		change_per(newalt).
		if newalt > oldalt change_per(newalt).
		else change_apo(newalt).
	}
	else {
		change_apo(newalt).
		if newalt < oldalt change_apo(newalt).
		else change_per(newalt).
	}
}

function moon_trans{
	parameter moonname.
	parameter moon_peri.
	

	

	local planetMU to BODY:MU.
	local oldSMA to (SHIP:PERIAPSIS+(BODY:RADIUS*2)+SHIP:APOAPSIS)/2.
	local moonMU to tgtmoon:MU.
	local moonSOI to tgtmoon:SOIRADIUS-20000.
	local moonSOIdistfromplanet to tgtMoon:obt:semimajoraxis - moonSOI.
	local newSMA to (moonSOIdistfromplanet+SHIP:PERIAPSIS+BODY:RADIUS)/2.
	local curplanetPEV to sqrt(planetMU*(2/(ship:periapsis+body:radius)-1/oldSMA)).
	local newplanetPEV to sqrt(planetMU*(2/(ship:periapsis+body:radius)-1/newSMA)).
	local thisDV to newplanetPEV - curplanetPEV.
	local transferAPV to sqrt(planetMU*(2/moonSOIdistfromplanet-1/newSMA)).
	local moonSMA to (moon_peri+tgtmoon:RADIUS+moonSOI)/2.
	local requiredAPV to sqrt(moonMU*(2/moonSOI-1/moonSMA)).
	local thisnextDV to requiredAPV-transferAPV.
	
		
	//copied from reddit user 
	
	local T2 is tgtMoon:obt:period.
	local A2 is tgtMoon:obt:semimajoraxis.

	// periapsis height of the transfer orbit is your altitude
	// apoapsis height of the transfer orbit is tgtMoon's altitude
	// so we can calculate SMA of the transfer orbit
	local A1 is newSMA.

	// 3rd Kepler's law tells us that (A1/A2)^3 = (T1/T2)^2
	// where T1 is period of transfer orbit
	// so T1 = T2 * (A1/A2)^1.5
	local T1 is T2 * (A1/A2)^1.5.

	// now we can calculate the angle between tgtMoon's position at the start of the transfer
	// and at the end of the transfer
	local aa is mod(((T1*0.5)/T2)*360, 360).
	//local aa is mod(360*(T1/T2), 360).

	// the angle we are looking for is 180-alpha
	// or 360-alpha if you are using angles in range [0..360]
	local transferAngle is 180 - aa.

	//copied from reddit user ollieshmollie and toukiedatak

	local shippos to ship:orbit:position - ship:body:position.
	local tgtMoonpos to tgtMoon:orbit:position - tgtMoon:body:position.
	local phaseangle to vang(tgtMoonpos,shippos).
	local phaseanglecrs to vcrs(tgtMoonpos,shippos).
	  if vdot(v(1,1,1), phaseanglecrs) <= 0 {
		set phaseangle to -1 * phaseangle.
	  }

	
	//local tgtAngVel is tgtMoon:angularvel:mag * constant:radtodeg.
	local tgtAngVel is 2*constant:radtodeg*constant:pi/tgtMoon:orbit:period.
	
	//local shipAngVel is (SQRT(BODY:MU / ((ship:altitude + BODY:radius)^3)))* constant:radtodeg.
	local shipAngVel is 2*constant:radtodeg*constant:pi/ship:orbit:period.
	
	local angdiff is phaseangle-transferAngle.
	if angdiff < 0 set angdiff to angdiff+360.
	
	local transtime to (angdiff)/ABS(tgtAngVel-shipAngVel).
	
	local trans2time to Constant:PI*sqrt(newSMA^3/planetMU).
	
	

	local nd to NODE(TIME:SECONDS + transtime,0,0,thisDV).
	ADD nd.
	local nd2 to NODE(TIME:SECONDS + transtime+trans2time,0,0,thisnextDV).
	ADD nd2.
	//exec_node().	
	wait until false.
}

function moon_trans{
	parameter moonname.
	parameter moon_peri.
	

	

	local planetMU to BODY:MU.
	local oldSMA to (SHIP:PERIAPSIS+(BODY:RADIUS*2)+SHIP:APOAPSIS)/2.
	local moonMU to tgtmoon:MU.
	local moonSOI to tgtmoon:SOIRADIUS-20000.
	local moonSOIdistfromplanet to tgtMoon:obt:semimajoraxis - moonSOI.
	local newSMA to (moonSOIdistfromplanet+SHIP:PERIAPSIS+BODY:RADIUS)/2.
	local curplanetPEV to sqrt(planetMU*(2/(ship:periapsis+body:radius)-1/oldSMA)).
	local newplanetPEV to sqrt(planetMU*(2/(ship:periapsis+body:radius)-1/newSMA)).
	local thisDV to newplanetPEV - curplanetPEV.
	local transferAPV to sqrt(planetMU*(2/moonSOIdistfromplanet-1/newSMA)).
	local moonSMA to (moon_peri+tgtmoon:RADIUS+moonSOI)/2.
	local requiredAPV to sqrt(moonMU*(2/moonSOI-1/moonSMA)).
	local thisnextDV to requiredAPV-transferAPV.
	
		
	//copied from reddit user 
	
	local T2 is tgtMoon:obt:period.
	local A2 is tgtMoon:obt:semimajoraxis.

	// periapsis height of the transfer orbit is your altitude
	// apoapsis height of the transfer orbit is tgtMoon's altitude
	// so we can calculate SMA of the transfer orbit
	local A1 is newSMA.

	// 3rd Kepler's law tells us that (A1/A2)^3 = (T1/T2)^2
	// where T1 is period of transfer orbit
	// so T1 = T2 * (A1/A2)^1.5
	local T1 is T2 * (A1/A2)^1.5.

	// now we can calculate the angle between tgtMoon's position at the start of the transfer
	// and at the end of the transfer
	local aa is mod(((T1*0.5)/T2)*360, 360).
	//local aa is mod(360*(T1/T2), 360).

	// the angle we are looking for is 180-alpha
	// or 360-alpha if you are using angles in range [0..360]
	local transferAngle is 180 - aa.

	//copied from reddit user ollieshmollie and toukiedatak

	local shippos to ship:orbit:position - ship:body:position.
	local tgtMoonpos to tgtMoon:orbit:position - tgtMoon:body:position.
	local phaseangle to vang(tgtMoonpos,shippos).
	local phaseanglecrs to vcrs(tgtMoonpos,shippos).
	  if vdot(v(1,1,1), phaseanglecrs) <= 0 {
		set phaseangle to -1 * phaseangle.
	  }

	
	//local tgtAngVel is tgtMoon:angularvel:mag * constant:radtodeg.
	local tgtAngVel is 2*constant:radtodeg*constant:pi/tgtMoon:orbit:period.
	
	//local shipAngVel is (SQRT(BODY:MU / ((ship:altitude + BODY:radius)^3)))* constant:radtodeg.
	local shipAngVel is 2*constant:radtodeg*constant:pi/ship:orbit:period.
	
	local angdiff is phaseangle-transferAngle.
	if angdiff < 0 set angdiff to angdiff+360.
	
	local transtime to (angdiff)/ABS(tgtAngVel-shipAngVel).
	
	local trans2time to Constant:PI*sqrt(newSMA^3/planetMU).
	
	

	local nd to NODE(TIME:SECONDS + transtime,0,0,thisDV).
	ADD nd.
	local nd2 to NODE(TIME:SECONDS + transtime+trans2time,0,0,thisnextDV).
	ADD nd2.
	//exec_node().	
	wait until false.
}

function ship_trans{
	parameter shipname.
	parameter moon_peri.
	//copied from reddit user 

	local tgtShip to SHIP(shipname).
	//local transfer_apo to find_moon_transfer(moonname,moon_peri).
	//local tgtOffset to tgtMoon:radius + 40000.
	//local tgtOffset to tgtMoon:soiradius/5.
	local T2 is tgtShip:obt:period.
	local A2 is tgtShip:obt:semimajoraxis.

	// periapsis height of the transfer orbit is your altitude
	// apoapsis height of the transfer orbit is tgtMoon's altitude
	// so we can calculate SMA of the transfer orbit
	local A1 is (SHIP:obt:semimajoraxis + (tgtShip:obt:semimajoraxis))/2.

	// 3rd Kepler's law tells us that (A1/A2)^3 = (T1/T2)^2
	// where T1 is period of transfer orbit
	// so T1 = T2 * (A1/A2)^1.5
	local T1 is T2 * (A1/A2)^1.5.

	// now we can calculate the angle between tgtMoon's position at the start of the transfer
	// and at the end of the transfer
	local aa is mod(((T1*0.5)/T2)*360, 360).
	//local aa is mod(360*(T1/T2), 360).

	// the angle we are looking for is 180-alpha
	// or 360-alpha if you are using angles in range [0..360]
	local transferAngle is 180 - aa.


	
	

	//copied from reddit user ollieshmollie and toukiedatak

	local shippos to ship:orbit:position - ship:body:position.
	local tgtShippos to tgtShip:orbit:position - tgtShip:body:position.
	local phaseangle to vang(tgtShippos,shippos).
	local phaseanglecrs to vcrs(tgtShippos,shippos).
	  if vdot(v(1,1,1), phaseanglecrs) <= 0 {
		set phaseangle to -1 * phaseangle.
	  }

	
	//local tgtAngVel is tgtMoon:angularvel:mag * constant:radtodeg.
	local tgtAngVel is 2*constant:radtodeg*constant:pi/tgtMoon:orbit:period.
	
	//local shipAngVel is (SQRT(BODY:MU / ((ship:altitude + BODY:radius)^3)))* constant:radtodeg.
	local shipAngVel is 2*constant:radtodeg*constant:pi/ship:orbit:period.
	
	local angdiff is phaseangle-transferAngle.
	if angdiff < 0 set angdiff to angdiff+360.
	
	local transtime to (angdiff)/ABS(tgtAngVel-shipAngVel).
	

    local thisDV to 0. //need to put in 
	

	local nd to NODE(TIME:SECONDS + transtime,0,0,thisDV).
	ADD nd.
	//exec_node().	
	wait until false.
}

function reentry {
	parameter r_target.
	SAS OFF.
	lock Altsq to SHIP:ALTITUDE^2.
	local targetll to LATLNG(-1.5409,-71.9099).
	local desdist to (2*BODY:RADIUS)^2.
	local aimvector to ship:retrograde:forevector.
	
	local midatm is SHIP:ORBIT:BODY:ATM:HEIGHT/2.
	if ADDONS:TR:AVAILABLE {
		if r_target ADDONS:TR:SETTARGET(targetll).
		SET WARP TO 4.
		local this is targetll:distance^2.
		local that is desdist + SHIP:ALTITUDE^2.
		UNTIL this < that AND this > (3*that/4) AND targetll:heading < 180 {
			gui_scr_update().
			set this to targetll:distance^2.
			set that to desdist + SHIP:ALTITUDE^2.
			WAIT 0.1.
		}
		SET WARP TO 0.
		LOCK aimvector to ship:retrograde:forevector.
		LOCK STEERING to aimvector.
		UNTIL ABS(ship:retrograde:yaw - FACING:YAW < 0.1) AND ABS(ship:retrograde:pitch - FACING:PITCH < 0.1) {
			gui_scr_update().
			WAIT 0.1.
		}
		SET THROTTLE to 1.
		WAIT UNTIL ADDONS:TR:HASIMPACT.
		SET THROTTLE to 0.2.
		UNLOCK aimvector.
		Local dist is circle_distance(targetll,ADDONS:TR:IMPACTPOS,BODY:RADIUS).
		LOCAL LATPID TO PIDLOOP(.06, 0, 0.25, -1, 1).
		LOCAL LONGPID TO PIDLOOP(.001, 0, 0.006, -1, 1).
		// kerbalX
		// LOCAL LATPID TO PIDLOOP(.06, 0, 0.25, -1, 1).
		// LOCAL LONGPID TO PIDLOOP(.001, 0, 0.006, -1, 1).
		//Save for my sanity
		//LOCAL LATPID TO PIDLOOP(.04, 0, 0.005, -1, 1).
		//LOCAL LONGPID TO PIDLOOP(.001, 0, 0.001, -1, 1).
		//
		LOCAL THPID	TO PIDLOOP(.5, 0, 0, -1, 1).
		LOCAL myheading to ship:retrograde:forevector:direction:yaw.
		UNTIL dist < 300 {
			LOCAL costheta to COS(SHIP:ORBIT:INCLINATION).
			Set aimvector to aimvector:normalized + ((-LONGPID:UPDATE(TIME:SECONDS,((targetll:LNG - ADDONS:TR:IMPACTPOS:LNG)/costheta))*SHIP:PROGRADE:FOREVECTOR:NORMALIZED) - (LATPID:UPDATE(TIME:SECONDS,((targetll:LAT - ADDONS:TR:IMPACTPOS:LAT)/costheta))*((vcrs(ship:prograde:forevector,-body:position)):NORMALIZED))).
			//Set aimvector to HEADING(myheading,0).
			//Local aimvector to (-LONGPID:UPDATE(TIME:SECONDS,((targetll:LNG - ADDONS:TR:IMPACTPOS:LNG)/COS(SHIP:ORBIT:INCLINATION)))*SHIP:PROGRADE:FOREVECTOR:NORMALIZED).
			SET THROTTLE TO MIN(dist/300000,.2).
			print dist:tostring:PADRIGHT(10) AT (2,5).
			set dist to circle_distance(targetll,ADDONS:TR:IMPACTPOS,BODY:RADIUS).
			gui_scr_update().
			WAIT 0.01.
		}
		SET THROTTLE TO 0.
	}
	else {
		set THROTTLE to 1.
		until SHIP:PERIAPSIS < midatm {
			gui_scr_update().
			WAIT 0.1.
		}
	}
	SET THROTTLE to 0.
	UNLOCK THROTTLE.
	UNLOCK STEERING.
	SAS ON.
	WAIT 1.
	SET SASMODE TO "RETROGRADE".
	WAIT 1.
	UNTIL STAGE:NUMBER < 2 {
		STAGE.
		WAIT 0.1.
	}
	UNTIL SHIP:ALTITUDE < 8000 {
		gui_scr_update().
		WAIT 0.1.
	}
	UNTIL SHIP:STATUS = "SPLASHED" OR SHIP:STATUS = "LANDED" {
		IF (NOT CHUTESSAFE)  CHUTESSAFE ON.
		WAIT 0.1.
	}
		
}

function circle_distance {
 parameter
  p1,     //...this point...
  p2,     //...to this point...
  radius. //...around a body of this radius. (note: if you are flying you may want to use ship:body:radius + altitude).
 local A is sin((p1:lat-p2:lat)/2)^2 + cos(p1:lat)*cos(p2:lat)*sin((p1:lng-p2:lng)/2)^2.
 
 return radius*constant():PI*arctan2(sqrt(A),sqrt(1-A))/90.
}.

function find_moon_transfer {
parameter moonname, moonalt.
local aa is BODY("kerbin"):MU.
local bb is ship:orbit:periapsis.
local cc is 12000000.
local dd is BODY(moonname):MU.
local ee is moonalt.
local transfer_apo is 0.
//set transfer_apo to ((1/(2*(aa*bb-dd*ee)))*((-1*(sqrt(bb)))*(sqrt(ee))*(sqrt(aa^2*bb*ee+4*aa*bb*dd*ee+4*aa*cc^2*dd+4*aa*cc*dd*ee+bb*dd^2*ee+2*aa*bb*cc+aa*bb*ee+bb*dd*ee)))).
//print ABS(transfer_apo).
return ABS(transfer_apo).
}