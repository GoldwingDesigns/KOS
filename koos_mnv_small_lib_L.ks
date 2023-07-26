@lazyglobal off.
run koos_obtcalc_small_lib.
run koos_hillclimb_lib.

{
	global MNV is lexicon(
		"launch atmo",			launch_atmo_gravity_turn@,
  	"launch no atmo",		launch_no_atmo@,
		"circ",					circularize@,
		"change inc lan",		change_inc_lan@,
		"change inc lan alt",	change_inc_lan_alt@,
		"match landing lat", match_landing_lat@,
    "match inc lan",    	match_inc_lan@,
		"exec node",			exec_node@,
		"change apo",			change_apo@,
		"change per",			change_per@,
		"change arg per",		change_AoPer@,
		"capture",				capture_orbit@,
		"hoh trans 1",			hohmann_trans1@,
		"hoh trans 2",			hohmann_trans2@,
		"moon trans",			moon_trans@,
		"moon return",			moon_return@,
		"pwr land",				pwr_ldg@,
		"land align init",		ldg_align_burn_init@,
		"land align final", 	ldg_align_burn@,
		"aero land",			aero_ldg@
	).

	// function ShipTWR {
	// 	local thst is 0.
	// 	local englist to list().
	// 	list engines in englist.
	// 	// local mth to englist[englist:LENGTH - 1]:THRUST.
	// 	//set mth to SHIP:MAXTHRUST. // (depends on fixed kOS issue 940)
	// 	for e in englist {
	// 		set thst to e:availablethrust + thst.
	// 	}
	// 	local rd to SHIP:ALTITUDE+SHIP:BODY:RADIUS.
	// 	local w to SHIP:MASS * SHIP:BODY:MU / rd / rd.
	// 	return thst/w.
	// }

	function MinThrottle {
		local thst is 0.
		local englist to list().
		list engines in englist.
		// local mth to englist[englist:LENGTH - 1]:THRUST.
		//set mth to SHIP:MAXTHRUST. // (depends on fixed kOS issue 940)
		for e in englist {
			set thst to e:availablethrust + thst.
		}
		if thst >0{
			local rd to SHIP:ALTITUDE+SHIP:BODY:RADIUS.
			local w to SHIP:MASS * SHIP:BODY:MU / rd / rd.
			local answer to max(w/thst,0.05).
			return answer.
		}
		else return 1.
	}

	function launch_atmo_gravity_turn{
		parameter launchalt, launchinc, thrByEta is true, setpoint is 45, pitchoverDeg is 4, roll is -90.
    local waitstart to 0.
		//roll to -180 for shuttle.
		local th to 1. //Variable for locked throttle.  1.0 is the max, 0.0 is idle.
		local Steering_Lock TO HEADING(90,90,roll). //Variable for locked steering. shuttle is 0? probe is -90?
		local TurnEnd TO launchalt. //The ending altitude for the ascent turn.
		local MyPitch TO 90. //Initial setting for pitch on launch (straight up).
		local newth to 0.
		local stopatstage to VES1["&launchstage"]().
		local launchaz to LAZcalc(LAZcalc_init(launchalt,launchinc)).
		local THRPID to CHOOSE PIDLOOP(0.1,0.0,0.1,-0.5,0.5) if thrByEta else PIDLOOP(0.1,0,0.01,-0.5,0.5). //PID loop to set throttle to DesiredTWR.
		SET THRPID:SETPOINT to setpoint.
		VES1["sas off"]().

		//**Setup Throttle and Steering Locks.
		LOCK THROTTLE TO th.   
		LOCK STEERING TO Steering_Lock. // from now on we'll be able to change steering by just assigning a new value to Steering_Lock
		
		//**Declare Triggers.

		//**Trigger to open the Solar Panels and turn on Lights when above atmosphere. Had to split up because log file sharing conflict.
		WHEN SHIP:altitude > 50000 THEN {
			VES1["fairing deploy"]().
	 	}
		WHEN SHIP:altitude > 52000 THEN {
    	VES1["panels on"]().
		}
		WHEN SHIP:altitude > 55000 THEN {
    	VES1["comms ext"]().
		}

		if STARTTIME = 0 {set STARTTIME to TIME. local mtime to time. UI["msg add"]("Commence Launch Program at "+mTime:year+"y "+mtime:day+"d "+mtime:hour+"h "+mtime:minute+"m "+mtime:second+"s.").}
		
		return list(
			{
				SET Steering_Lock TO HEADING(90,90,roll).
				stage.
				return true.
			},
			{
				man_check_stage(stopatstage).
				return ALT:RADAR > 100.
			},
			{
				VES1["gear up"]().
				UI["msg add"]("Commence Pitchover.").
				return true.
			},
			{
				set MyPitch to 90-pitchoverDeg.
				local CurPoint to  ETA:APOAPSIS .
				// local CurPoint to CHOOSE ETA:APOAPSIS if thrByEta else ShipTWR.
				SET Steering_Lock TO HEADING(launchaz,MyPitch,roll).
				set newth to th+THRPID:UPDATE(time:seconds, CurPoint)*min(1,(launchalt-ship:apoapsis)/1000).
				SET th to MIN(1,MAX(newth,MinThrottle)).
				man_check_stage(stopatstage).
				return vcrs(Steering_Lock:VECTOR,SHIP:srfPrograde:VECTOR):mag < 0.01. 
			},
			{
				UI["msg add"]("Steering Unlocked. Gravity Turn Initiated.").
				return true.
			},
			{
				//set MyPitch TO 90 * (1 - ((SHIP:ALTITUDE-TurnStart) / TurnEnd) ^ TurnExponent).
				SET Steering_Lock to LOOKDIRUP(SHIP:srfPrograde:FOREVECTOR,SHIP:FACING:TOPVECTOR).
				local CurPoint to  ETA:APOAPSIS .
				// local CurPoint to CHOOSE ETA:APOAPSIS if thrByEta else ShipTWR.
				set newth to th+THRPID:UPDATE(time:seconds, CurPoint)*min(1,(launchalt-ship:apoapsis)/1000).
				SET th to MIN(1,MAX(newth,MinThrottle)).
				man_check_stage(stopatstage).
				return SHIP:ALTITUDE > TurnEnd or SHIP:APOAPSIS > launchalt. //If still following the launch curve and desired apoapsis not reached
			},
			{
				SET Steering_Lock TO HEADING(launchaz,0,roll).
				IF SHIP:APOAPSIS < launchalt AND SHIP:ALTITUDE >=SHIP:ORBIT:BODY:ATM:HEIGHT{ //Apoapsis value has dropped due to drag.
						set newth to 1*min(1,(launchalt-ship:apoapsis)/1000).
				} ELSE { //Coasting to Apoapsis.
						set newth to 0.
				}
				SET th to MIN(1,MAX(newth,0)).
				man_check_stage(stopatstage).
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
				UI["msg add"]("Launch Complete.").
				return true.
			}
		).
	}

  function launch_no_atmo{
		parameter launchalt, launchinc.
        local waitstart to 0.
		local th to 1. //Variable for locked throttle.  1.0 is the max, 0.0 is idle.
		local Steering_Lock TO HEADING(90,90). //Variable for locked steering.
		local TurnEnd TO launchalt. //The ending altitude for the ascent turn.
		local TurnExponent TO 0.1. //Turn exponent for curvature. Higher is more vertical.
		local TurnStart TO 0.  //Used to mark the altitude that the ascent turn begins.
		local MyPitch TO 90. //Initial setting for pitch on launch (straight up).
		local launchaz to LAZcalc(LAZcalc_init(launchalt,launchinc)).
		VES1["sas off"]().

		//**Setup Throttle and Steering Locks.
		LOCK THROTTLE TO th.   
		LOCK STEERING TO Steering_Lock. // from now on we'll be able to change steering by just assigning a new value to Steering_Lock
		
		//**Declare Triggers.

		//**Trigger to open the Solar Panels and turn on Lights when above atmosphere.
		// WHEN SHIP:ALTITUDE > SHIP:ORBIT:BODY:ATM:HEIGHT THEN {
		// 	PANELS ON.
		// 	LIGHTS ON.
		// 	UI["msg add"]("Panels Extended.").
		// }
		
				if STARTTIME = 0 set STARTTIME to TIME.

        return list(
            {
                SET Steering_Lock TO HEADING(90,90).
                man_check_stage(0).
                return SHIP:VELOCITY:SURFACE:MAG > 50. //Initial launch will be straight up 
            },
            {//**Trigger to mark the altitue the ascent turn begins
                VES1["gear up"]().
			    SET TurnStart TO SHIP:ALTITUDE - 10.
			    UI["msg add"]("Commence Pitchover.").
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
                UI["msg add"]("Launch Complete.").
                return true.
            }
        ).
	}

	function man_check_stage{
		parameter laststage.
		if stage:number >= laststage {
			if ship:availablethrust = 0 {
				UI["msg add"]("Stage: "+stage:number+" no thrust.").
				VES1["stage"]().
				return.
			}
			local numOut to 0.
			local myengines to list().
			LIST ENGINES IN myengines. 
			FOR eng IN myengines {
				IF eng:FLAMEOUT {
					UI["msg add"]("Stage: "+stage:number+" eng: "+eng:title+" flameout.").
					SET numOut TO numOut + 1.
				}
			}
			if numOut > 0 { VES1["stage"](). }.
		}
	}

	function circularize{
		local thisMU to BODY:MU.
		local thisR to BODY:RADIUS + SHIP:APOAPSIS.
		local thisA to BODY:RADIUS + ((SHIP:APOAPSIS + SHIP:PERIAPSIS)/2).
		local thisDV to SQRT(thisMU * (2/thisR - 1/thisR)) - SQRT(thisMU * (2/thisR - 1/thisA)).
		local nd to NODE(TIME:SECONDS + ETA:APOAPSIS,0,0,thisDV).
		ADD nd.
		UI["msg add"]("Circularize Node Added At Apoapsis.").
		return true.
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

	function change_inc_lan {
		//100% from https://www.reddit.com/r/Kos/comments/3r5pbj/set_inclination_from_orbit_script/  I tried to do on my own but couldn't
		parameter inc_t, lan_t to orbit:lan.
		if lan_t:istype("UserDelegate") set lan_t to lan_t:call.
		local info to plane_change_info(inc_t,lan_t).
		local theta to info[0].
		local nd_time to info[1].
		local negind to info[2].
		local vel is velocityAt(ship,nd_time):orbit:mag.
		local norm to vel * sin(theta).
		local pro to vel * cos(theta) - vel.
    local nd is NODE(nd_time, 0,0,0).
		set nd:normal to negind * norm.
		set nd:prograde to pro.
		Add nd.
		UI["msg add"]("Inc/LAN Node Added: "+inc_t+"/"+lan_t).
		return true.   
	}

	function change_inc_lan_alt {
		parameter inc_t, lan_t, alt_t.
		if lan_t:istype("UserDelegate") set lan_t to lan_t:call.
		local info to plane_change_info(inc_t,lan_t).
		local theta to info[0].
		local nd_time to info[1].
		local negind to info[2].
		local thisR to (positionAt(ship,nd_time)-body:position):mag.
		local nextA to (thisR+BODY:RADIUS+alt_t)/2.
		local vi is velocityAt(ship,nd_time):orbit:mag.
		local vf is sqrt(body:mu*((2/thisR)-(1/nextA))).
		local norm to vf * sin(theta).
		local pro to (vf * cos(theta)) - vi.
		local nd is NODE(nd_time, 0,0,0).
		set nd:normal to negind * norm.
		set nd:prograde to pro.
		Add nd.
		UI["msg add"]("Inc/LAN/Alt Node Added: "+inc_t+"/"+lan_t+"/"+alt_t).
		return true.
	}

  function match_inc_lan {
      parameter tgtbody.
      RETURN change_inc_lan(tgtbody:obt:inclination, tgtbody:obt:lan).
  }
  
	function match_landing_lat {
		parameter tgt, finalalt is 0.
		local desiredinc to abs(tgt:lat). //inclinations are expressed with positive num
		if ship:obt:inclination > 90 {set desiredinc to 180-desiredinc. }  //if already retrograde, stay that way
		if finalalt <> 0 { 
			local lan to find_landing_tgt_LAN(tgt,desiredinc,finalalt).
			change_inc_lan_alt(desiredinc,lan,finalalt).
		}else{
			local lan to find_landing_tgt_LAN_lowalt(tgt, desiredinc).
			change_inc_lan(desiredinc,lan).
		}
		return true.
	}

	function exec_node{
		//Execute Node Maneuvers
        //Adapted from pgoddkos Advanced Tutorial
		//warp taken from TheDapperScot on https://www.reddit.com/r/Kos/comments/5t1qx9/node_execution_script_is_causing_wild_spinning/
		local nd to nextnode.
		VES1["sas off"]().
		LOCAL th to 0.
		LOCK THROTTLE to th.
		local burntime to find_burntime(nd:deltaV:mag).
		local lock max_acc to ship:maxthrust/ship:mass.
		local dv0 to nd:DELTAV:vec.
    LOCK STEERING to lookdirup(nd:deltav,SHIP:BODY:POSITION).
    local waitstart to 0.
    UI["msg add"]("Executing node: "+nd).

		return list(
			{
				warpto(nd:ETA-(burntime/2)-60+time:seconds).
				return true.
			},
			{
				return nd:ETA < burntime/2.
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
					local sd to VES1["&solardir"]().
					print sd.
					if sd:contains("fore") {
							lock STEERING to Body("sun"):position.
					} else if sd:contains("aft") {
							lock STEERING to 1 * Body("sun"):position.
					} else if sd:contains("side") {
							lock STEERING to VCRS(Body("sun"):position,ship:velocity:orbit).
					} else { 
							lock STEERING to Body("sun"):position. 
					}.
					set waitstart to time:seconds.
					return true.
			},
			{
					return waitstart+15 < time:seconds.
			},
			{
					UNLOCK STEERING.
					VES1["sas on"]().
					SET SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
					UNLOCK THROTTLE.
					WAIT 0.1.
					REMOVE nd.
					UI["msg add"]("Node Execution Complete.").
					return true.
			}
		).
	}
		
	function change_apo{
		parameter newalt.
		local thisMU to BODY:MU.
		local thisR to BODY:RADIUS + SHIP:PERIAPSIS.
		local thisA to BODY:RADIUS + ((SHIP:PERIAPSIS + SHIP:APOAPSIS)/2).
		local nextA to BODY:RADIUS + ((SHIP:PERIAPSIS + newalt)/2).
		local thisDV to SQRT(thisMU * (2/thisR - 1/nextA)) - SQRT(thisMU * (2/thisR - 1/thisA)).
		local nd to NODE(TIME:SECONDS + ETA:PERIAPSIS,0,0,thisDV).
		ADD nd.
        UI["msg add"]("Change Apo Node Added.").
        return true.
	}

	function change_per{
		parameter newalt.
		local thisMU to BODY:MU.
		local thisR to BODY:RADIUS + SHIP:APOAPSIS.
		local thisA to BODY:RADIUS + ((SHIP:APOAPSIS + SHIP:PERIAPSIS)/2).
		local nextA to BODY:RADIUS + ((SHIP:APOAPSIS + newalt)/2).
		local thisDV to SQRT(thisMU * (2/thisR - 1/nextA)) - SQRT(thisMU * (2/thisR - 1/thisA)).
		local nd to NODE(TIME:SECONDS + ETA:APOAPSIS,0,0,thisDV).
		ADD nd.
        UI["msg add"]("Change Pe Node Added.").
        return true.
	}

	function change_AoPer{ //should only be accomplished from circular orbit
		parameter aop, newalt.
		local thisMU to BODY:MU.
		local thisR to OBT:semimajoraxis.
		local thisA to OBT:semimajoraxis.
		local nextA to (BODY:RADIUS + OBT:semimajoraxis + newalt)/2.
		local thisDV to SQRT(thisMU * (2/thisR - 1/nextA)) - SQRT(thisMU * (2/thisR - 1/thisA)).
		local aopdiff to aop-obt:argumentofperiapsis.
		if aopdiff < 0 set aopdiff to aopdiff+360.
		local maneuvertrueanom is 0.
		if thisR >= newalt+body:radius { set maneuvertrueanom to find_eta_to_true_anomaly(mod(aopdiff+180,360)). } else { set maneuvertrueanom to find_eta_to_true_anomaly(mod(aopdiff,360)). } //just in case changing apoapsis instead of periapsis
		local nd to NODE(TIME:SECONDS + maneuvertrueanom,0,0,thisDV).
		ADD nd.
        UI["msg add"]("Change Pe Node Added.").
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
		local newSMA to (SHIP:OBT:PERIAPSIS + (bodyr*2) + capture_altitude)/2.
		local transV to sqrt(bodymu*((2/(SHIP:OBT:PERIAPSIS+bodyr))-(1/newSMA))).
		local thisDV to transV-perV.
		local nd to NODE(thistime+etaper,0,0,thisDV).
		ADD nd.
        UI["msg add"]("Orbit Capture Node Added").
        return true.
	}

	function hohmann_trans1{ 
		parameter newalt.
		if ETA:APOAPSIS < ETA:PERIAPSIS {
			change_per(newalt).
		}else{
			change_apo(newalt).
		}
		return true.
	}

	function hohmann_trans2{
		parameter newalt.
		local adiff to abs(obt:apoapsis-newalt).
		local pdiff to abs(obt:periapsis-newalt).
		if adiff < pdiff {
			change_per(newalt).
		}else{
			change_apo(newalt).
		}
		return true.
	}

	function moon_trans{
		parameter tgtmoon, moon_peri.
		UI["msg add"]("Finding Transfer to "+tgtmoon:name).
		local planetMU to SHIP:ORBIT:BODY:MU.
		local oldSMA to SHIP:ORBIT:SEMIMAJORAXIS.
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
        UI["msg add"]("Moon Transfer Node To "+tgtmoon:name+" Added").
        return true.
	}

	function moon_return {
		parameter p_peri.
		
    UI["msg add"]("Finding Transfer to "+BODY:OBT:BODY:NAME).
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
        UI["msg add"]("Moon Return Node Added").
        return true.
		// exec_node().
	}
	
	function aero_ldg {
			parameter laststage to 0.
			local steervec to lookDirUp(-1*ship:velocity:orbit,-1*body:position).
			lock steering to steervec.
			local waitstart to 0.
			VES1["sas off"]().
			UI["msg add"]("Commence Aero Land Program.").
			
			return list(
				// { //moved to warp_to_alt in sys_lib
				// 	warpto(etatoaltitude2(initalt)+time:seconds).
				// 	return true.
				// },
				// {
				// 	return ship:altitude < initalt.
				// },
				{
					set steervec to lookDirUp(vcrs(body:position,ship:velocity:orbit),-1*body:position).
					return abs(vdot(vcrs(body:position,ship:velocity:orbit):normalized,ship:facing:vector:normalized)) > 0.98.
				},
				{
					if stage:ready and stage:number > laststage {
						VES1["stage"]().
						return false.
					} else {
						if stage:number > laststage {return false.} else {return true.} 
					}
				},
				{ //this is same as "ship sep" in the vessel lib.  consider how to put this there.
					VES1["rcs on"](). 
					return true.
				},
				{
					set ship:control:fore to 1.
					set waitstart to time:seconds.
					return true.
				},
				{
					return waitstart+3 < time:seconds.
				},
				{
					set ship:control:neutralize to true.
					set waitstart to time:seconds.
					return true.
				},
				{
					return waitstart+10 < time:seconds.
				},
				{
					VES1["rcs off"]().
					return true.
				},
				{
					set steervec to lookDirUp(-1*ship:velocity:surface,-1*body:position).
					return true.
				},
				{ return ship:alt < 200000.
				},
				{ 
					VES1["comms ret"]().
					return true.
				},
				{
					set steervec to lookDirUp(-1*ship:velocity:surface,-1*body:position).
					return alt:radar < 10000.
				},
				{
					unlock steering.
					return true.
				},
				{
					VES1["arm chutes"]().
					if (not chutesSafe){
						chutesSafe on.
					}
					return chutes.
				},
				{
					return SHIP:STATUS = "SPLASHED" or SHIP:STATUS = "LANDED".
				},
				{
					if addons:available("scansat"){
						if ship:status = "SPLASHED" {
							UI["msg add"](ship:name+" splashed down on "+ship:body+". L/L: "+ship:geoposition:lat+", "+ship:geoposition:lng+" Biome: "+addons:scansat:currentbiome).
						}
						if ship:status = "LANDED" {
							UI["msg add"](ship:name+" landed on "+ship:body+". L/L: "+ship:geoposition:lat+", "+ship:geoposition:lng+" Biome: "+addons:scansat:currentbiome).
						}
					else {
						if ship:status = "SPLASHED" {
							UI["msg add"](ship:name+" splashed down on "+ship:body+". L/L: "+ship:geoposition:lat+", "+ship:geoposition:lng).
						}
						if ship:status = "LANDED" {
							UI["msg add"](ship:name+" landed on "+ship:body+". L/L: "+ship:geoposition:lat+", "+ship:geoposition:lng).
						}
					}
					}
				}
			).
				
		}

	function find_burntime {
		parameter inputDV, stagenum to STAGE:NUMBER.
		local Mi to SHIP:MASS.
		local stageDV to ship:STAGEDELTAV(stagenum):CURRENT.
		local Go to 9.80665.
		local englist is list().
		list engines in englist.
		local engISP to 0.1.
		local engT to 0.1.
		for e in englist {
			if e:stage = stagenum {
				set engISP to engISP + e:VISP.
				set engT to engT + e:availableThrust.
			}
		}
		if stageDV > inputDV {
			return inputDV/(engT * (((Mi + (Mi * (constant:e ^ (-1 * (inputDV / (engISP * Go) )))))/2) ^ (-1))).
		} else {
			return stageDV/(engT * (((Mi + (Mi * (constant:e ^ (-1 * (stageDV / (engISP * Go) )))))/2) ^ (-1))) + find_burntime(inputDV-stageDV, max(stagenum-1,0)).
		}
	}


	function pwr_ldg { 
		parameter radaroffset is 4.1, tgt is latlng(0,27), altoffset is 0.
							// The value of alt:radar when landed (on gear)
		local offsets to radarOffset+altoffset.
		
		local lock trueRadar to alt:radar - offsets.			// Offset radar to get distance from gear to ground
		local g to body:mu /((body:radius)^2).
		//local lock Fg to ship:mass * g.
		//local lock Fg to ship:mass * body:mu /((ship:altitude + body:radius)^2).
		local lock am to vang(up:vector, ship:facing:vector).		// Gravity (m/s^2)
		// local lock maxDecel to (ship:availablethrust*cos(am) - Fg)/ship:mass.	// Maximum deceleration possible (m/s^2)
		local lock maxDecel to (ship:availablethrust/ship:mass)*cos(am) - g.	// Maximum deceleration possible (m/s^2)
		local lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
		local idealThrottle to 1.			// Throttle required for perfect hoverslam
		
		local alterr to (Body:position:mag - ship:altitude-body:radius).
		local lock tgtvec to tgt:altitudeposition(ship:altitude+alterr).
		local errorvec to V(0,0,0).
		local lock nsvec to ship:north:vector.
		local lock ewvec to -1 * vcrs(ship:north:vector,ship:up:vector).
    local twn to 1. local tzeta to 0.9. local tKp to twn^2. local tKi to 0. local tKd to 2*tzeta*twn.
		local NSPID TO PIDLOOP (tKp, tKi, tKd, -0.5, 0.5).
		SET NSPID:SETPOINT TO 0.
		local dwn to 1.	local dzeta to 0.9. local dKp to dwn^2. local dKi to 0. local dKd to 2*dzeta*dwn.
		local EWPID TO PIDLOOP (dKp, dKi, dKd, -0.5, 0.5).
		SET EWPID:SETPOINT TO 0.
       
		local mytime to 0.
    local waitstart to 0.
    UI["msg add"]("Commence Powered Landing.").
        
    return list (
    	{
				return ship:verticalSpeed < -1.
			},
			{
				VES1["sas off"]().
				VES1["rcs on"]().
				lock steering TO lookDirUp(-1*ship:velocity:surface,ewvec).
				set mytime to TIME:seconds.
				lock throttle to 0.	
				return true.
			},
			{
				if addons:tr:hasimpact {
					set errorvec to tgtvec-addons:tr:impactpos:altitudeposition(ship:altitude+alterr).
				}
				if errorvec:mag > 20 { //keeps aimpoint within 20 meters
					set ship:control:starboard to -1 * NSPID:UPDATE(mytime,vdot(errorvec,nsvec:normalized)).
					set ship:control:top to -1 * EWPID:UPDATE(mytime,vdot(errorvec,ewvec:normalized)).
				}else{
					set ship:control:neutralize to TRUE.
				}
				return trueRadar < stopDist + 1000. 
			},
			{ //1000 meters before suicide burn start final alignments.
				if addons:tr:hasimpact {
					set errorvec to tgtvec-addons:tr:impactpos:altitudeposition(ship:altitude+alterr).
				}
        set ship:control:starboard to -1 * NSPID:UPDATE(mytime,vdot(errorvec,nsvec:normalized)).
        set ship:control:top to -1 * EWPID:UPDATE(mytime,vdot(errorvec,ewvec:normalized)).
				// 				print "TrueRadar: "+trueRadar at(0,0).
				return trueRadar < stopDist + 100.
			},
			{
				set idealThrottle to stopDist / trueRadar.
				set ship:control:neutralize to TRUE.
				lock throttle to idealThrottle.
				UI["msg add"]("Performing Final Burn.").
				VES1["gear down"]().
				return true.
			},
			{
				set idealThrottle to stopDist / trueRadar.
				if addons:tr:hasimpact {set errorvec to tgtvec-addons:tr:impactpos:altitudeposition(ship:altitude+alterr).}
				set ship:control:starboard to -1 * NSPID:UPDATE(mytime,vdot(errorvec,nsvec:normalized)).
				set ship:control:top to -1 * EWPID:UPDATE(mytime,vdot(errorvec,ewvec:normalized)).
				return trueRadar <= 0.5 or ship:verticalSpeed > -1.
			},				
			// { 
			// 	// if (softlanding){
			// 		local result to THRPID:UPDATE(time:seconds, ship:verticalSpeed).
			// 		set newth to idealThrottle+result.
      //     SET idealThrottle to MIN(1,MAX(newth,0)).
			// 		print "IdealThr: "+idealThrottle+" ship:verticalSpeed: "+ship:verticalspeed+" result: "+result.
			// 		return SHIP:STATUS = "SPLASHED" or SHIP:STATUS = "LANDED".
			// 	// } else {
			// 	// 	set idealThrottle to stopDist / trueRadar.
			// 	// 	return ship:verticalSpeed > -0.5.
			// 	// }
			// },
			{
				set ship:control:neutralize to TRUE.
				set ship:control:fore to -1.
				lock steering to up.
				lock throttle to 0.
				wait 3.
				unlock steering.
				VES1["sas on"]().
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
				VES1["rcs off"]().
				return true.
			},
			{
				return SHIP:STATUS = "SPLASHED" or SHIP:STATUS = "LANDED".
			},
			{
				if addons:available("scansat"){
					if ship:status = "SPLASHED" {
						UI["msg add"](ship:name+" splashed down on "+ship:body+". L/L: "+ship:geoposition:lat+", "+ship:geoposition:lng+" Biome: "+addons:scansat:currentbiome).
					}
					if ship:status = "LANDED" {
						UI["msg add"](ship:name+" landed on "+ship:body+". L/L: "+ship:geoposition:lat+", "+ship:geoposition:lng+" Biome: "+addons:scansat:currentbiome).
					} else {
						if ship:status = "SPLASHED" {
							UI["msg add"](ship:name+" splashed down on "+ship:body+". L/L: "+ship:geoposition:lat+", "+ship:geoposition:lng).
						}
						if ship:status = "LANDED" {
							UI["msg add"](ship:name+" landed on "+ship:body+". L/L: "+ship:geoposition:lat+", "+ship:geoposition:lng).
						}
					}
				}
				return true.
			}
		).
	}

	function ldg_align_burn_init{
		parameter tgt.
		local circ is orbit_circumference().
		local qcirc is circ/4.
		local lock totvec to ship:velocity:surface.
		local lock survec to vxcl(cos(VANG(totvec,BODY:POSITION))*Body:position:normalized,totvec).
		local lock tgtvec to vxcl((tgt:position:mag*cos(VANG(tgt:position,BODY:POSITION)))*body:position:normalized,tgt:position).
		local lock dist to circle_distance(ship:geoposition,tgt,((obt:semimajoraxis+obt:semiminoraxis)/2)).
		local thrt to 0.
		lock throttle to thrt.
		local negind to 0.
		local angdiff to 0.
		local steervec to lookDirUp(-1*ship:velocity:orbit,-1*body:position).
		local waitstart to 0.
		UI["msg add"]("Commence Initial Landing Angular Correction.").
		return list(
			{
				if not (vdot(tgtvec,survec) > 0 and dist < qcirc){SET WARP to 4.}
				
				WAIT 0.1.
				return true.
			},
			{
				return vdot(tgtvec,survec) > 0 and dist < qcirc .
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
				VES1["sas off"]().
				lock steering to steervec.
				return true.
			},
			{
				set negind to vdot(vcrs(tgtvec:normalized,survec:normalized),body:position:normalized).
				set angdiff to vang(tgtvec,survec).
				if angdiff > 2 {
					set ship:control:neutralize to TRUE.
					set steervec to lookDirUp(-1 * negind*vcrs(body:position,survec),-1*body:position).
					if abs(vdot(vcrs(body:position,survec):normalized,ship:facing:vector:normalized)) > 0.98 
					{ 
						set thrt to angdiff. 
					}
					return false.
				} else {
					set thrt to 0.
					set steervec to lookDirUp(-1*survec,-1*body:position).
					if abs(vdot(-1*survec,ship:facing:vector:normalized)) > 0.98 
					{return true.}else{return false.} //done once angle < 0.02 and facing retrograde.
					}
			},
			{
				set thrt to 0.
				SET SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
				unlock throttle.
				unlock steering.
				wait 0.1.
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
		local dwn to 1. local dzeta to 0. local dKp to dwn^2. local dKi to 0. local dKd to 2*dzeta*dwn.
		local hdgPID TO PIDLOOP (dKp, dKi, dKd, -0.5, 0.5). //helps with .05 deadzone in RCS
		SET hdgPID:SETPOINT TO 0.
		local hdgpitch to 0.
		local negind to 0.
		local angdiff to 0.
		local deadband to 0.2.
		local mindist to 2147483647.
		local steervec to lookDirUp(-1*ship:velocity:orbit,-1*body:position).
		lock steering to steervec.
		local hystate to 0.
		UI["msg add"]("Commence Landing Angular Alignment.").
		return list(
			{
				if not(vdot(tgtvec,survec) > 0 and tgtvec:mag < (hburnd*5) and tgtvec:mag > (hburnd*4) and tgt:position:mag < body:radius*2) 
				{
					SET WARP to 2.
					WAIT 0.1.
				}
				return true.
			},
			{
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
				VES1["rcs on"]().
				wait 1.
				VES1["sas off"]().
				return true.
			},
			{
				set negind to vdot(vcrs(tgtvec:normalized,survec:normalized),body:position:normalized).
				set angdiff to vang(tgtvec,survec).
				if angdiff > 1 set hystate to 1. //use hysteresis to keep it from flipflopping at high inclinations
				if angdiff < 0.5 set hystate to 0.
				// if angdiff > deadband {
					if  negind < 0  {
								set hdgpitch to hdgPID:update(TIME:SECONDS, angdiff).
					} else {
							set hdgpitch to hdgPID:update(TIME:SECONDS, angdiff*-1).
					}
				// } else {
				// 	set ship:control:neutralize to TRUE.

				// }
				if hystate = 1 {
					set ship:control:neutralize to TRUE.
					set steervec to lookDirUp(-1 * negind*vcrs(body:position,survec),-1*body:position).
					if abs(vdot(vcrs(body:position,survec):normalized,ship:facing:vector:normalized)) > 0.98 { set thrt to angdiff. }
					set hburnt to find_burntime(hvel).
					set hburnd to (hburnt*hvel/2)+1000.
				}
				if hystate = 0 {
					set thrt to 0.
					set steervec to lookDirUp(-1*survec,-1*body:position).
					if abs(vdot(-1*survec,ship:facing:vector:normalized)) > 0.98 {
						set ship:control:starboard to -2 * hdgpitch. // put the negative sign back if this is messed up
					}
				}
				return tgtvec:mag < (hburnd).	
			},
			{
	set steervec to lookDirUp(-1*survec,-1*body:position).
					set ship:control:neutralize to TRUE.
					return true.
			},
			{
				if ADDONS:TR:AVAILABLE {
					ADDONS:TR:SETTARGET(tgt).
					set ADDONS:TR:RETROGRADE to TRUE.
				}
				UI["msg add"]("Cancelling Horiz Velocity.").
				return true.
			},
			{
				set steervec to lookDirUp(-1*survec,-1*body:position).
				if ADDONS:TR:AVAILABLE {
					set angdiff to vang(tgtvec,survec).
					if angdiff > deadband {
					if  negind < 0  {
								set hdgpitch to hdgPID:update(TIME:SECONDS, angdiff).
						} else {
								set hdgpitch to hdgPID:update(TIME:SECONDS, angdiff*-1).
						}
					}
					set thrt to min(1,(hvel)/10).
					set negind to vdot(vcrs(tgtvec:normalized,survec:normalized),body:position:normalized).
					set ship:control:starboard to -2*hdgpitch.
					return ADDONS:TR:HASIMPACT.
				} else {
					return true.
				}
			},
			{
				set steervec to lookDirUp(-1*survec,-1*body:position).
				if ADDONS:TR:AVAILABLE {
					set errorvec to addons:tr:impactpos:altitudeposition(ship:altitude+alterr)-tgt:altitudeposition(ship:altitude+alterr).
					set errorvechoriz to vxcl(cos(VANG(errorvec,BODY:POSITION))*Body:position:normalized,errorvec).
					set thrt to min(1,errorvec:mag/2000).
					set negind to vdot(vcrs(tgtvec:normalized,survec:normalized),body:position:normalized).
					if  negind < 0  {
						set angdiff to vang(tgtvec,survec).
						set hdgpitch to hdgPID:update(TIME:SECONDS, angdiff).
					} else {
						set angdiff to vang(tgtvec,survec)*-1.
						set hdgpitch to hdgPID:update(TIME:SECONDS, angdiff).
					}
					set ship:control:starboard to -1*hdgpitch.
					if errorvechoriz:mag < mindist set mindist to errorvechoriz:mag.
					return errorvechoriz:mag<200 and mindist<errorvechoriz:mag.
				} else {
					set thrt to min(1,(hvel-10)/10).
					return hvel<20.
				}
			},
			{
				UI["msg add"]("Landing alignment CPA: "+mindist).
				set steervec to lookDirUp(-1*ship:velocity:orbit,-1*body:position).
				set thrt to 0.
				SET SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
				set ship:control:neutralize to TRUE.
				unlock throttle.
				unlock steering.
				wait 0.1.
				return true.
			}
		).

	}

	
}