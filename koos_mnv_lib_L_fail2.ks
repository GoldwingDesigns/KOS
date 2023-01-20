@lazyglobal off.
run koos_lib_obtcalc.
run koos_lib_hillclimb.
//Launch Maneuvers

{
	global MNV is lexicon(
		"launch atmo",			launch_atmo@,
        "launch no atmo",		launch_no_atmo@,
		"circ",					circularize@,
		"change inc lan",		change_inc_lan@,
		"change inc lan alt",	change_inc_lan_alt@,
        "match inc lan",        match_inc_lan@,
		"exec node",			exec_node@,
		"change apo",			change_apo@,
		"change per",			change_per@,
		"capture",				capture_orbit@,
		"hoh trans",			hohmann_trans@,
		"moon trans",			moon_trans@,
		"moon return",			moon_return@,
		"aero land",			aero_ldg@,
		"pwr land",				pwr_ldg@,
		"land align",			ldg_align_burn@
		// "land obt adj",			ldg_orbit_adjust@
	).

	function ShipTWR {
		local thst is 0.
		local englist to list().
		list engines in englist.
		// local mth to englist[englist:LENGTH - 1]:THRUST.
		//set mth to SHIP:MAXTHRUST. // (depends on fixed kOS issue 940)
		for e in englist {
			set thst to e:thrust + thst.
		}
		local r to SHIP:ALTITUDE+SHIP:BODY:RADIUS.
		local w to SHIP:MASS * SHIP:BODY:MU / r / r.
		return thst/w.
	}

	function launch_atmo{
		parameter launchalt, launchinc, launchcirc.
		SET COMPMODE to 9.
		gui_menu_run().
        local waitstart to 0.
		local th to 1. //Variable for locked throttle.  1.0 is the max, 0.0 is idle.
		local Steering_Lock TO HEADING(90,90). //Variable for locked steering.
		local TurnEnd TO launchalt. //The ending altitude for the ascent turn.
		local TurnExponent TO 0.3. //Turn exponent for curvature. Higher is more vertical.
		local TurnStart TO 0.  //Used to mark the altitude that the ascent turn begins.
		local MyPitch TO 90. //Initial setting for pitch on launch (straight up).
		local DesiredTWR TO 2. //DesiredTWR throughout launch
		local newth to 0.
		local launchaz to LAZcalc(LAZcalc_init(launchalt,launchinc)).
		local TWRPID is PIDLOOP(0.1,0,0.01,-0.5,0.5). //PID loop to set throttle to DesiredTWR.
		SET TWRPID:SETPOINT to DesiredTWR.
		SAS off.

		//**Setup Throttle and Steering Locks.
		LOCK THROTTLE TO th.   
		LOCK STEERING TO Steering_Lock. // from now on we'll be able to change steering by just assigning a new value to Steering_Lock
		
		//**Declare Triggers.

		//**Trigger to open the Solar Panels and turn on Lights when above atmosphere.
		// WHEN SHIP:ALTITUDE > SHIP:ORBIT:BODY:ATM:HEIGHT THEN {
		// 	PANELS ON.
		// 	LIGHTS ON.
		// 	gui_msg_add("Panels Extended.").
		// }
		// //**Trigger to mark the altitue the ascent turn begins

		if STARTTIME = 0 set STARTTIME to TIME.
		
        return list(
            {
                SET Steering_Lock TO HEADING(90,90).
                man_check_stage(0).
                return SHIP:VELOCITY:SURFACE:MAG > 50. //Initial launch will be straight up 
            },
            {
                gear off.
			    SET TurnStart TO SHIP:ALTITUDE - 10.
			    gui_msg_add("Commence Pitchover.").
                return true.
            },
            {
                set MyPitch TO 90 * (1 - ((SHIP:ALTITUDE-TurnStart) / TurnEnd) ^ TurnExponent).
                local CurTWR to ShipTWR.
                SET Steering_Lock TO HEADING(launchaz,MyPitch).
                set newth to th+TWRPID:UPDATE(time:seconds, CurTWR).
                SET th to MIN(1,MAX(newth,0)).
                man_check_stage(0).
                return SHIP:ALTITUDE > TurnEnd or SHIP:APOAPSIS > launchalt. //If still following the launch curve and desired apoapsis not reached
            },
            {
                local CurTWR to ShipTWR.
                SET Steering_Lock TO HEADING(launchaz,0).
                IF SHIP:APOAPSIS < launchalt { //Apoapsis value has dropped due to drag.
                    set newth to th+TWRPID:UPDATE(time:seconds, CurTWR).
                } ELSE { //Coasting to Apoapsis.
                    set newth to 0.
                }
                SET th to MIN(1,MAX(newth,0)).
                man_check_stage(0).
                return SHIP:APOAPSIS >= launchalt AND SHIP:ALTITUDE >=SHIP:ORBIT:BODY:ATM:HEIGHT.
            },
            {
                //**At this point, our apoapsis is above the desired value and our main loop has ended. Next
                //**we'll make sure our throttle is zero and that we're pointed prograde.
                LOCK THROTTLE TO 0.
                WAIT 1.
                UNLOCK THROTTLE.
                SET Steering_Lock TO LOOKDIRUP(ship:prograde:forevector, SHIP:BODY:POSITION).
                set waitstart to time:seconds.
                return true.
            },
            {
                return waitstart+10 < time:seconds.
            },
            {
                UNLOCK STEERING.
                gui_msg_add("Launch Complete").
                return true.
            }
        ).
	}

    function launch_no_atmo{
		parameter launchalt, launchinc, launchcirc.
		SET COMPMODE to 9.
		gui_menu_run().
        local waitstart to 0.
		local th to 1. //Variable for locked throttle.  1.0 is the max, 0.0 is idle.
		local Steering_Lock TO HEADING(90,90). //Variable for locked steering.
		local TurnEnd TO launchalt. //The ending altitude for the ascent turn.
		local TurnExponent TO 0.1. //Turn exponent for curvature. Higher is more vertical.
		local TurnStart TO 0.  //Used to mark the altitude that the ascent turn begins.
		local MyPitch TO 90. //Initial setting for pitch on launch (straight up).
		local launchaz to LAZcalc(LAZcalc_init(launchalt,launchinc)).
		SAS off.

		//**Setup Throttle and Steering Locks.
		LOCK THROTTLE TO th.   
		LOCK STEERING TO Steering_Lock. // from now on we'll be able to change steering by just assigning a new value to Steering_Lock
		
		//**Declare Triggers.

		//**Trigger to open the Solar Panels and turn on Lights when above atmosphere.
		// WHEN SHIP:ALTITUDE > SHIP:ORBIT:BODY:ATM:HEIGHT THEN {
		// 	PANELS ON.
		// 	LIGHTS ON.
		// 	gui_msg_add("Panels Extended.").
		// }
		
		if STARTTIME = 0 set STARTTIME to TIME.
		
        return list(
            {
                SET Steering_Lock TO HEADING(90,90).
                man_check_stage(0).
                return SHIP:VELOCITY:SURFACE:MAG > 50. //Initial launch will be straight up 
            },
            {//**Trigger to mark the altitue the ascent turn begins
                gear off.
			    SET TurnStart TO SHIP:ALTITUDE - 10.
			    gui_msg_add("Commence Pitchover.").
                return true.
            },
            {
                set MyPitch TO 90 * (1 - ((SHIP:ALTITUDE-TurnStart) / TurnEnd) ^ TurnExponent).
                SET Steering_Lock TO HEADING(launchaz,MyPitch).
                SET th to 1.
                man_check_stage(0).
                return SHIP:ALTITUDE > TurnEnd or SHIP:APOAPSIS > launchalt. //If still following the launch curve and desired apoapsis not reached
            },
            {
                SET Steering_Lock TO HEADING(launchaz,0).
                IF SHIP:APOAPSIS < launchalt { //Apoapsis value has dropped due to drag.
                    set th to 1.
                } ELSE { //Coasting to Apoapsis.
                    set th to 0.
                }
                man_check_stage(0).
                return SHIP:APOAPSIS >= launchalt AND SHIP:ALTITUDE >=SHIP:ORBIT:BODY:ATM:HEIGHT.
            },
            {
                //**At this point, our apoapsis is above the desired value and our main loop has ended. Next
                //**we'll make sure our throttle is zero and that we're pointed prograde.
                LOCK THROTTLE TO 0.
                WAIT 1.
                UNLOCK THROTTLE.
                SET Steering_Lock TO LOOKDIRUP(ship:prograde:forevector, SHIP:BODY:POSITION).
                set waitstart to time:seconds.
                return true.
            },
            {
                return waitstart+10 < time:seconds.
            },
            {
                UNLOCK STEERING.
                gui_msg_add("Launch Complete").
                return true.
            }
        ).
	}

	function man_check_stage{
		parameter laststage.
		if stage:number >= laststage {
			if ship:availablethrust = 0 {
				stage.
				gui_msg_add("Stage.").
				return.
			}
			local numOut to 0.
			local myengines to list().
			LIST ENGINES IN myengines. 
			FOR eng IN myengines {
				IF eng:FLAMEOUT {
					SET numOut TO numOut + 1.
				}
			}
			if numOut > 0 { stage.  gui_msg_add("Stage."). }.
		}
	}

	function circularize{
		SET COMPMODE to 9.
		gui_menu_run().
		local Mi to SHIP:MASS.
		local thisMU to BODY:MU.
		local thisR to BODY:RADIUS + SHIP:APOAPSIS.
		local thisA to BODY:RADIUS + ((SHIP:APOAPSIS + SHIP:PERIAPSIS)/2).
		local thisDV to SQRT(thisMU * (2/thisR - 1/thisR)) - SQRT(thisMU * (2/thisR - 1/thisA)).
		local nd to NODE(TIME:SECONDS + ETA:APOAPSIS,0,0,thisDV).
		ADD nd.
        gui_msg_add("Circularize Node Added At Apoapsis").
        return true.
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

	function change_inc_lan {
		//taken from G_Space on https://www.reddit.com/r/Kos/comments/3r5pbj/set_inclination_from_orbit_script/
		DECLARE PARAMETER incl_t.
		DECLARE PARAMETER lan_t.
		local incl_i to SHIP:OBT:INCLINATION.
		local lan_i to SHIP:OBT:LAN.
		
		if lan_t = -1 set lan_t to SHIP:OBT:LAN.

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
        gui_msg_add("Inc/LAN Node Added: "+incl_t+"/"+lan_t).
        return true.
		// exec_node().
	}

	function change_inc_lan_alt {
		parameter inc_a, lan_t, alt_t.
		local inc_i to SHIP:OBT:inclination.
		local lan_i to SHIP:OBT:LAN.
		local inc_t to abs(inc_a).
		local a1 is sin(inc_i)*cos(lan_i).
		local a2 is sin(inc_i)*sin(lan_i).
		local a3 is cos(inc_i).
		local b1 is sin(inc_t)*cos(lan_t).
		local b2 is sin(inc_t)*sin(lan_t).
		local b3 is cos(inc_t).

		local theta is arccos(a1*b1 + a2*b2 + a3*b3).

		local c1 is a2*b3 - a3*b2.
		local c2 is a3*b1 - a1*b3.
		local c3 is a1*b2 - a2*b1.

		local long1 is 0.
		// local lat1 is arctan(c3/sqrt(c1^2 + c2^2)).
		if c1 < 0 { set long1 to arctan(c2/c1)+90. }
		else { set long1 to arctan(c2/c1)+270. }

		// local lat2 is -lat1.
		local long2 is long1 + 180.
		if long2 > 360 { set long2 to long2 - 360. }
		local negind is 1.
		local nd_eta is 0.
		local nd_eta1 is eta_true_anom(long1).
		local nd_eta2 is eta_true_anom(long2).
		if nd_eta1 < nd_eta2 {
			set nd_eta to nd_eta1.
		} else {
			set nd_eta to nd_eta2.
					set negind to -1.
		}
			
		local nd_time is nd_eta + time:seconds.
		local thisR to (positionAt(ship,nd_time)-body:position):mag.
		local nextA to (thisR+BODY:RADIUS+alt_t)/2.
		local vi is sqrt(body:mu/thisR).
		local vf is sqrt(body:mu*((2/thisR)-(1/nextA))).
		local norm to vf * sin(theta).
		local pro to vf * cos(theta) - vi.
		local nd is NODE(nd_time, 0,0,0).
		set nd:normal to negind * norm.
		set nd:prograde to pro.
       
		Add nd.
        gui_msg_add("Inc/LAN/Alt Node Added: "+inc_a+"/"+lan_t+"/"+alt_t).
        return true.

	}

    function match_inc_lan {
        parameter tgtbody.
        RETURN change_inc_lan(tgtbody:obt:inclination, tgtbody:obt:lan).
    }

	function exec_node{
		//Execute Node Maneuvers
        //Adapted from pgoddkos Advanced Tutorial
		//warp taken from TheDapperScot on https://www.reddit.com/r/Kos/comments/5t1qx9/node_execution_script_is_causing_wild_spinning/
		local nd to nextnode.
		sas off.
		LOCAL th to 0.
		LOCK THROTTLE to th.
		local burntime to find_burntime(nd:deltaV:mag).
		local lock max_acc to ship:maxthrust/ship:mass.
		local dv0 to nd:DELTAV:vec.
        LOCK STEERING to lookdirup(nd:deltav,SHIP:BODY:POSITION).
        local waitstart to 0.
        gui_msg_add("Executing node: "+nd).

        return list(
            {
                if warp <> 5 and nd:ETA > (burntime/2+6000) set warp to 5.
                return nd:ETA < (burntime/2+6000).
            },
            {
                if warp <> 4 and nd:ETA > (burntime/2+120) set warp to 4.
                return nd:ETA < (burntime/2+120).
            },
            {
                if warp <> 0 set warp to 0.
                return nd:ETA < (burntime/2).
            },
            {
            //recalculate current max_acceleration, as it changes while we burn through fuel
                //throttle is 100% until there is less than 1 second of time left to burn
                //when there is less than 1 second - decrease the throttle linearly
                if max_acc <> 0 set th to min(nd:deltav:mag/max_acc, 1).
                //here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
                //this check is done via checking the dot product of those 2 vectors
                man_check_stage(0). 
                return nd:deltav:mag<0.1 and vdot(dv0, nd:deltav) < 0.1.
            },
            {
                lock throttle to 0.
                lock steering TO LOOKDIRUP(-SHIP:velocity:ORBIT,SHIP:BODY:POSITION).
                set waitstart to time:seconds.
                return true.
            },
            {
                return waitstart+10 < time:seconds.
            },
            {
                UNLOCK STEERING.
                SAS ON.
                SET SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
                UNLOCK THROTTLE.
                WAIT 0.1.
                REMOVE nd.
                gui_msg_add("Node Execution Complete").
                return true.
            }
        ).
	}
		
	function change_apo{
		parameter newalt.
		SET COMPMODE to 9.
		gui_menu_run().
		local thisMU to BODY:MU.
		local thisR to BODY:RADIUS + SHIP:PERIAPSIS.
		local thisA to BODY:RADIUS + ((SHIP:PERIAPSIS + SHIP:APOAPSIS)/2).
		local nextA to BODY:RADIUS + ((SHIP:PERIAPSIS + newalt)/2).
		local thisDV to SQRT(thisMU * (2/thisR - 1/nextA)) - SQRT(thisMU * (2/thisR - 1/thisA)).
		local nd to NODE(TIME:SECONDS + ETA:PERIAPSIS,0,0,thisDV).
		ADD nd.
        gui_msg_add("Change Apo Node Added").
        return true.
	}

	function change_per{
		parameter newalt.
		SET COMPMODE to 9.
		gui_menu_run().
		local thisMU to BODY:MU.
		local thisR to BODY:RADIUS + SHIP:APOAPSIS.
		local thisA to BODY:RADIUS + ((SHIP:APOAPSIS + SHIP:PERIAPSIS)/2).
		local nextA to BODY:RADIUS + ((SHIP:APOAPSIS + newalt)/2).
		local thisDV to SQRT(thisMU * (2/thisR - 1/nextA)) - SQRT(thisMU * (2/thisR - 1/thisA)).
		local nd to NODE(TIME:SECONDS + ETA:APOAPSIS,0,0,thisDV).
		ADD nd.
        gui_msg_add("Change Pe Node Added").
        return true.
	}

	function capture_orbit{ //thanks to u/bdlarkin for example guidance
		parameter capture_altitude is SHIP:OBT:PERIAPSIS.
		local thistime to TIME:SECONDS.
		local etaper to ETA:PERIAPSIS.
		local bodyMU to BODY:MU.
		local bodyr to BODY:RADIUS.
		local vinf to sqrt(-1*(bodyMU/SHIP:OBT:SEMIMAJORAXIS)).
		local vesc to sqrt(2*bodyMU/(bodyr+SHIP:OBT:PERIAPSIS)).
		local perV to sqrt(vesc^2+vinf^2).
		local circV to vesc/sqrt(2).
		local newSMA to (SHIP:OBT:PERIAPSIS + (bodyr*2) + capture_altitude)/2.
		local transV to sqrt(bodymu*((2/(SHIP:OBT:PERIAPSIS+bodyr))-(1/newSMA))).
		local thisDV to transV-perV.
		local nd to NODE(thistime+etaper,0,0,thisDV).
		ADD nd.
        gui_msg_add("Orbit Capture Node Added").
        return true.
	}
		
	function hohmann_trans{ //hmmmm... how to solve this in the mission runner?
		parameter newalt.
		local oldalt to SHIP:PERIAPSIS.
		if ETA:APOAPSIS < ETA:PERIAPSIS {
			change_per(newalt). exec_node().
			if newalt > oldalt {change_per(newalt). exec_node().}
			else {change_apo(newalt). exec_node(). }
		}
		else {
			change_apo(newalt). exec_node().
			if newalt < oldalt {change_apo(newalt). exec_node().}
			else {change_per(newalt). exec_node().}
		}
	}

	function moon_trans{
		parameter tgtmoon, moon_peri, moon_inc is 80.

        gui_msg_add("Finding Transfer to "+tgtmoon:name).
		local planetMU to SHIP:ORBIT:BODY:MU.
		local oldSMA to SHIP:ORBIT:SEMIMAJORAXIS.
		
		local moonMU to tgtmoon:MU.

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

		local hnd is hillclimb(nd, tgtmoon, list("periapsis",moon_peri), 40).
		ADD hnd.
        gui_msg_add("Moon Transfer Node To "+tgtmoon:name+" Added").
        return true.
	}

	function moon_return {
		parameter p_peri.
		
        gui_msg_add("Finding Transfer to "+BODY:OBT:BODY:NAME).
		local this_m to SHIP:BODY.
		local m_mu to SHIP:BODY:MU.
		local p_mu to SHIP:BODY:OBT:BODY:MU.
		local m_peri to SHIP:OBT:SEMIMAJORAXIS.
		local m_SOI to SHIP:BODY:SOIRADIUS.
		local p_rad to SHIP:BODY:OBT:BODY:RADIUS.
		local p_tom to SHIP:BODY:ALTITUDE + SHIP:BODY:OBT:BODY:RADIUS.
		local p_tomsoi to p_tom-m_SOI.
		local tgtname to SHIP:BODY:BODY:NAME.
		
		local Vesc to sqrt((2*m_mu)/(m_peri)).
		local vnow to SHIP:VELOCITY:OBT:MAG.

		local Vhoh to sqrt(p_mu*((2/p_tomsoi)-(2/(p_tomsoi+(p_peri+p_rad))))).
		local m_vel to sqrt(p_mu/p_tom).
		local Vinf to m_vel-Vhoh. //craft velocity relative to moon_return
		local Vbo to sqrt(Vinf^2 + Vesc^2).
		local dV to Vbo-vnow.  //have to take into acount how fast we are actually going
		local ecc to (((m_peri*Vbo^2)/m_mu)-1).
		local angburntoeject to arccos(-1/ecc).

		local shippos to ship:orbit:position - ship:body:position.
		local m_vec_inv to ship:body:body:velocity:orbit. //this is retrograde of moon to parent
		local angshiptoeject to vang(m_vec_inv,shippos).
		local angshiptoejectcrs to vcrs(m_vec_inv,shippos).
		if vdot(v(1,1,1), angshiptoejectcrs) <= 0 {
			set angshiptoeject to -1 * angshiptoeject.
		}
		if angshiptoeject < 0 set angshiptoeject to angshiptoeject + 360.

		
		local p_AngVel is 2*constant:radtodeg*constant:pi/ship:body:orbit:period.
		local shipAngVel is 2*constant:radtodeg*constant:pi/ship:orbit:period.
		local angdiff is angshiptoeject-angburntoeject.
		if angdiff < 0 set angdiff to angdiff+360.
		local transtimeUTC to TIME:SECONDS + (angdiff)/ABS(p_AngVel-shipAngVel).
		
		// nodetime to vang(needed position,current position) / current speed + speed of moon
		
		local nd to NODE(transtimeUTC,0,0,dV).
		
		local hnd is hillclimb(nd, tgtname, list("periapsis",p_peri), 100).
		ADD hnd.
        gui_msg_add("Moon Return Node Added").
        return true.
		// exec_node().
	}

	function ship_trans{
		parameter shipname.
		parameter moon_peri.
		//copied from reddit user 

		local tgtShip to SHIP(shipname).
		//local transfer_apo to find_moon_transfer(moonname,moon_peri).
		//local tgtOffset to tgtmoon:radius + 40000.
		//local tgtOffset to tgtmoon:soiradius/5.
		local T2 is tgtShip:obt:period.
		local A2 is tgtShip:obt:semimajoraxis.

		// periapsis height of the transfer orbit is your altitude
		// apoapsis height of the transfer orbit is tgtmoon's altitude
		// so we can calculate SMA of the transfer orbit
		local A1 is (SHIP:obt:semimajoraxis + (tgtShip:obt:semimajoraxis))/2.

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
		local tgtShippos to tgtShip:orbit:position - tgtShip:body:position.
		local phaseangle to vang(tgtShippos,shippos).
		local phaseanglecrs to vcrs(tgtShippos,shippos).
		if vdot(v(1,1,1), phaseanglecrs) <= 0 {
			set phaseangle to -1 * phaseangle.
		}

		
		//local tgtAngVel is tgtmoon:angularvel:mag * constant:radtodeg.
		local tgtAngVel is 2*constant:radtodeg*constant:pi/tgtmoon:orbit:period.
		
		//local shipAngVel is (SQRT(BODY:MU / ((ship:altitude + BODY:radius)^3)))* constant:radtodeg.
		local shipAngVel is 2*constant:radtodeg*constant:pi/ship:orbit:period.
		
		local angdiff is phaseangle-transferAngle.
		if angdiff < 0 set angdiff to angdiff+360.
		
		local transtime to (angdiff)/ABS(tgtAngVel-shipAngVel).
		

		local thisDV to 0. //need to put in 
		

		local nd to NODE(TIME:SECONDS + transtime,0,0,thisDV).
		ADD nd.

		wait until false.
	}

	function aero_ldg {
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
			LOCAL THPID	TO PIDLOOP(.5, 0, 0, -1, 1).
			LOCAL myheading to ship:retrograde:forevector:direction:yaw.
			UNTIL dist < 300 {
				LOCAL costheta to COS(SHIP:ORBIT:INCLINATION).
				Set aimvector to aimvector:normalized + ((-LONGPID:UPDATE(TIME:SECONDS,((targetll:LNG - ADDONS:TR:IMPACTPOS:LNG)/costheta))*SHIP:PROGRADE:FOREVECTOR:NORMALIZED) - (LATPID:UPDATE(TIME:SECONDS,((targetll:LAT - ADDONS:TR:IMPACTPOS:LAT)/costheta))*((vcrs(ship:prograde:forevector,-body:position)):NORMALIZED))).
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

	function find_burntime {
		parameter thisDV.
		local Mi to SHIP:MASS.
		local Go to 9.80665.
		local englist is list().
		list engines in englist.
		local engISP to englist[englist:LENGTH - 1]:VISP.
		local engT to englist[englist:LENGTH - 1]:AVAILABLETHRUST.
		return thisDV/(engT * (((Mi + (Mi * (constant:e ^ (-1 * (thisDV / (engISP * Go) )))))/2) ^ (-1))).
	}

	function pwr_ldg { 
		parameter radaroffset is 4.1, tgt is latlng(0,27), altoffset is 0.
							// The value of alt:radar when landed (on gear)
		local lock trueRadar to alt:radar - radarOffset-altoffset.			// Offset radar to get distance from gear to ground
		local lock Fg to ship:mass * body:mu /((ship:altitude + body:radius)^2).
		local lock am to vang(up:vector, ship:facing:vector).		// Gravity (m/s^2)
		local lock maxDecel to (ship:availablethrust*cos(am) - Fg)/ship:mass.	// Maximum deceleration possible (m/s^2)
		local lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
		local lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
				// Time until impact, used for landing gear
		local VD TO VECDRAW(
				{ return tgt:ALTITUDEPOSITION(tgt:TERRAINHEIGHT+100). },
				{ return tgt:POSITION-tgt:ALTITUDEPOSITION(tgt:TERRAINHEIGHT+100). },
				red, "THIS IS THE SPOT", 1, true, 0.2, true, true).
		local alterr to (Body:position:mag - ship:altitude-body:radius).
		local lock totvec to ship:velocity:surface.
		local lock survec to vxcl(cos(VANG(totvec,BODY:POSITION))*Body:position:normalized,totvec).
		local lock tgtvec to tgt:altitudeposition(ship:altitude+alterr).
		local errorvec to V(0,0,0).
		local lock nsvec to ship:north:vector.
		local lock ewvec to -1 * vcrs(ship:north:vector,ship:up:vector).
        local twn to 1. local tzeta to 0.9. local tKp to twn^2. local tKi to 0. local tKd to 2*tzeta*twn.
		local NSPID TO PIDLOOP (tKp, tKi, tKd, -1, 1).
		SET NSPID:SETPOINT TO 0.
		local dwn to 1.	local dzeta to 0.9. local dKp to dwn^2. local dKi to 0. local dKd to 2*dzeta*dwn.
		local EWPID TO PIDLOOP (dKp, dKi, dKd, -1, 1).
		SET EWPID:SETPOINT TO 0.
        local mytime to 0.
        local waitstart to 0.
        gui_msg_add("Commence Powered Landing").
        
        return list (
            {
                return ship:verticalSpeed < -1.
            },
            {
                sas off.
                rcs on.
                lock steering TO lookDirUp(-1*ship:velocity:surface,ewvec).
                set mytime to TIME:seconds.
                lock throttle to 0.	
                return true.
            },
			{
                return trueRadar < stopDist + 1000. 
            },
            { //1000 meters before suicide burn start final alignments.
				if addons:tr:hasimpact {set errorvec to tgtvec-addons:tr:impactpos:altitudeposition(ship:altitude+alterr).}
                set ship:control:starboard to -1 * NSPID:UPDATE(mytime,vdot(errorvec,nsvec:normalized)).
                set ship:control:top to -1 * EWPID:UPDATE(mytime,vdot(errorvec,ewvec:normalized)).
                return trueRadar < stopDist + 50.
            },
            {
                set ship:control:neutralize to TRUE.
                gui_msg_add("Performing Final Burn").
                gear on.
                lock throttle to idealThrottle.
                return true.
            },
            {
                if addons:tr:hasimpact {set errorvec to tgtvec-addons:tr:impactpos:altitudeposition(ship:altitude+alterr).}
                set ship:control:starboard to -1 * NSPID:UPDATE(mytime,vdot(errorvec,nsvec:normalized)).
                set ship:control:top to -1 * EWPID:UPDATE(mytime,vdot(errorvec,ewvec:normalized)).
                return ship:verticalSpeed > -0.5.
            },
            {
                lock throttle to 0.
                wait 1.
                unlock steering.
                sas on.
                gui_msg_add("Landing Completed").
                set ship:control:pilotmainthrottle to 0.
                set ship:control:neutralize to TRUE.
                unlock throttle.
                set waitstart to time:seconds.
                return true.
            },
            {
                return waitstart+10 < time:seconds.
            },
            {
                rcs off.
                clearVecDraws().
                return true.
            }
        ).
	}

	function ldg_align_burn {
		parameter tgt.
		local lock hvel to ship:groundspeed.
		local thrt to 0.
		lock throttle to thrt.
		local alterr to (Body:position:mag - ship:altitude-body:radius).
		local hburnt to find_burntime(hvel).
		local hburnd to (hburnt*hvel/2)+1000.
		local lock totvec to ship:velocity:surface.
		local lock survec to vxcl(cos(VANG(totvec,BODY:POSITION))*Body:position:normalized,totvec).
		local lock tgtvec to vxcl((tgt:position:mag*cos(VANG(tgt:position,BODY:POSITION)))*body:position:normalized,tgt:position).
        local errorvec to V(0,0,0).
		local errorvechoriz to V(0,0,0).
        local waitstart to 0.
		// local VD TO VECDRAW(
		// 			{ return tgt:ALTITUDEPOSITION(tgt:TERRAINHEIGHT+1000). },
		// 			{ return vxcl(tgt:POSITION,tgt:ALTITUDEPOSITION(tgt:TERRAINHEIGHT+1000)). },
		// 			red, "THIS IS THE SPOT", 1, true, 0.2, true, true).
        local dwn to 1. local dzeta to 0. local dKp to dwn^2. local dKi to 0. local dKd to 2*dzeta*dwn.
		local hdgPID TO PIDLOOP (dKp, dKi, dKd, -0.5, 0.5). //helps with .05 deadzone in RCS
		SET hdgPID:SETPOINT TO 0.
		local hdgpitch to 0.
		local negind to 0.
		local angdiff to 0.
		local mindist to 2147483647.
		local steervec to lookDirUp(-1*ship:velocity:orbit,-1*body:position).
		lock steering to steervec.
        gui_msg_add("Commence Landing Angular Alignment").

        return list(
            {
                SET WARP to 4.
                return vdot(tgtvec,survec) > 0 and tgtvec:mag < (hburnd*5) and tgtvec:mag > (hburnd*4) and tgt:position:mag < body:radius*2.
            },
            {
                SET WARP to 0.
                set waitstart to time:seconds.
                return true.
            },
            {
                return waitstart+3 < time:seconds.
            },
            {
                rcs on.
                sas off.
				local totarrow TO VECDRAW(
					V(0,0,0),
					{ return survec. },
					blue,
					"surf vel",
					1.0,
					TRUE,
					0.2,
					TRUE,
					TRUE
					).
				// local tgtvect To VECDRAW(
				// 	V(0,0,0),
				// 	{ return tgtvec. },
				// 	purple,
				// 	"tgt",
				// 	1.0,
				// 	TRUE,
				// 	0.2,
				// 	TRUE,
				// 	TRUE
				// ).    
				local errvect To VECDRAW(
					V(0,0,0),
					{ return errorvechoriz. },
					green,
					"err",
					1.0,
					TRUE,
					0.2,
					TRUE,
					TRUE
				).    
				local angarrow TO VECDRAW(
					V(0,0,0),
					V(0,0,0),
					yellow,
					{return angdiff:tostring.},
					1.0,
					TRUE,
					0.2,
					TRUE,
					TRUE
					).
				return true.
            },
            {
                set negind to vdot(vcrs(tgtvec:normalized,survec:normalized),body:position:normalized).
                set angdiff to vang(tgtvec,survec).
                if angdiff > 0.05 {
                    set ship:control:neutralize to TRUE.
                    set steervec to lookDirUp(-1 * negind*vcrs(body:position,survec),-1*body:position).
                    if abs(vdot(vcrs(body:position,survec):normalized,ship:facing:vector:normalized)) > 0.98 { set thrt to angdiff. }
                    set hburnt to find_burntime(hvel).
                    set hburnd to (hburnt*hvel/2)+1000.
                }else{
                    set thrt to 0.
                    set steervec to lookDirUp(-1*survec,-1*body:position).
                    if  negind < 0  {
                        set hdgpitch to hdgPID:update(TIME:SECONDS, angdiff).
                    } else {
                        set hdgpitch to hdgPID:update(TIME:SECONDS, angdiff*-1).
                    }
                    if abs(vdot(-1*survec,ship:facing:vector:normalized)) > 0.98 {set ship:control:starboard to -2 * hdgpitch.}
                }
                return tgtvec:mag < (hburnd).	
		    },
            {
                set ship:control:neutralize to TRUE.
                return true.
            },
            {
                if ADDONS:TR:AVAILABLE {
                    ADDONS:TR:SETTARGET(tgt).
                    set ADDONS:TR:RETROGRADE to TRUE.
                }
				gui_msg_add("Cancelling Horiz Velocity").
                return true.
            },
            {
                if ADDONS:TR:AVAILABLE {
                    set thrt to min(1,(hvel)/10).
                    set negind to vdot(vcrs(tgtvec:normalized,survec:normalized),body:position:normalized).
					if  negind < 0  {
						set hdgpitch to hdgPID:update(TIME:SECONDS, vang(tgtvec,survec)).
					} else {
						set hdgpitch to hdgPID:update(TIME:SECONDS, vang(tgtvec,survec)*-1).
					}
					set ship:control:starboard to -2*hdgpitch.
                    return ADDONS:TR:HASIMPACT.
                } else {
                    return true.
                }
            },
            {
                if ADDONS:TR:AVAILABLE {
                    set errorvec to addons:tr:impactpos:altitudeposition(ship:altitude+alterr)-tgt:altitudeposition(ship:altitude+alterr).
					set errorvechoriz to vxcl(cos(VANG(errorvec,BODY:POSITION))*Body:position:normalized,errorvec).
                    set thrt to min(1,errorvec:mag/2000).
					set negind to vdot(vcrs(errorvechoriz:normalized,survec:normalized),body:position:normalized).
					if  negind < 0  {
						set angdiff to vang(errorvechoriz,survec)*-1.
						set hdgpitch to hdgPID:update(TIME:SECONDS, angdiff).
					} else {
						set angdiff to vang(errorvechoriz,survec).
						set hdgpitch to hdgPID:update(TIME:SECONDS, angdiff).
					}
					set ship:control:starboard to -2*hdgpitch.
					printat(angdiff,18,17).
					printat(errorvechoriz:mag,18,18).
					if errorvechoriz:mag < mindist set mindist to errorvechoriz:mag.
					return errorvechoriz:mag<30.
				} else {
					set thrt to min(1,(hvel-10)/10).
                    return hvel<20.
                }
            },
            {
				printat("CPA was "+mindist,18,19).
                set steervec to lookDirUp(-1*ship:velocity:orbit,-1*body:position).
				set thrt to 0.
                SET SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
                set ship:control:neutralize to TRUE.
                unlock throttle.
                unlock steering.
                clearVecDraws().
                wait 0.1.
                return true.
            }
        ).
	}

	function ldg_orbit_adjust { //dont call this just do this manually
		parameter tgt, final_alt.
		if abs(tgt:lat - obt:inclination) > 5 Or abs(obt:lan - mod((tgt:lng - 90 - tgt:body:rotationangle),360)) > 5 {
    		change_inc_lan_alt(tgt:lat,find_landing_tgt_LAN(tgt, tgt:lat, true, obt:apoapsis, final_alt),final_alt).    
			exec_node().
			change_apo(final_alt).
			exec_node().
			stage.
		}
	}

// 	function setcompmode{
// 	IF ALT:RADAR < 1 OR SHIP:STATUS = "PRELAUNCH" {SET COMPMODE to 0.}
// 	IF SHIP:ALTITUDE > 70000 SET COMPMODE to 1.
// 	IF SHIP:PERIAPSIS > SHIP:ORBIT:BODY:ATM:HEIGHT SET COMPMODE to 2.
// 	IF SHIP:OBT:HASNEXTPATCH SET COMPMODE TO 3.
// 	IF SHIP:OBT:ECCENTRICITY > 1 SET COMPMODE TO 4.
// }

}