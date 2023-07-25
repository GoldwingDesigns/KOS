@lazyglobal off.
run koos_obtcalc_tiny_lib.
run koos_hillclimb_lib.

{
	global MNV is lexicon(
		"launch atmo",			launch_atmo_gravity_turn@,
  	// "launch no atmo",		launch_no_atmo@,
		"circ",					circularize@,
		"change inc lan",		change_inc_lan@,
		"change inc lan alt",	change_inc_lan_alt@,
		// "match landing lat", match_landing_lat@,
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
		// "pwr land",				pwr_ldg@,
		// "land align init",		ldg_align_burn_init@,
		// "land align final", 	ldg_align_burn@,
		"aero land",			aero_ldg@,
		"unlock all",			unlock_all@
	).

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

		//**Trigger to open the Solar Panels and turn on Lights when above atmosphere.
		WHEN SHIP:altitude > 50000 THEN {
			VES1["fairing deploy"]().
    	VES1["panels on"]().
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
				VES1["comms ext"]().
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
	function unlock_all{UNLOCK STEERING.
            UNLOCK THROTTLE.}
	
}