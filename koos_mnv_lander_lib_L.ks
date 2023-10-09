@lazyglobal off.
run koos_obtcalc_lander_lib.

{
	global MNV is lexicon(
		"match landing lat", match_landing_lat@,
		"exec node",			exec_node@,
		"change apo",			change_apo@,
		"pwr land",				pwr_ldg@,
		"land align init",		ldg_align_burn_init@,
		"land align final", 	ldg_align_burn@,
		"change inc lan alt", change_inc_lan_alt@,
		"unlock all",			unlock_all@
	).
	
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
	
	function man_check_stage{
		parameter laststage.
		//local press to MAX(0,MIN(1,ship:body:atm:altitudepressure(ship:altitude))).
		if stage:number >= laststage {
			if ship:maxthrust = 0 {
				WAIT 1.
				if ship:maxthrust = 0 {
					UI["msg add"]("Stage: "+stage:number+" no thrust.").
					VES1["stage"]().
				}
			} else {
			local numOut to 0.
			local myengines to list().
			LIST ENGINES IN myengines. 
			FOR eng IN myengines {
				IF eng:FLAMEOUT {
					UI["msg add"]("Stage: "+stage:number+" eng: "+eng:title+" flameout.").
					SET numOut TO numOut + 1.
				}
			}
			if numOut > 0 { VES1["stage"](). }. //designed for if an assymetric booster engine goes out, but just causes problems with symmetric redundant ones.
		}}
	}
  
	function exec_node{
		parameter laststage to 0.
		//Execute Node Maneuvers
        //Adapted from pgoddkos Advanced Tutorial
		//warp taken from TheDapperScot on https://www.reddit.com/r/Kos/comments/5t1qx9/node_execution_script_is_causing_wild_spinning/
		local nd to nextnode.
		VES1["sas off"]().
		LOCAL th to 0.
		LOCK THROTTLE to th.
		VES1["check ign"](). //make sure active stage has a good engine
		wait 3.
		local burntime to find_burntime(nd:deltaV:mag).
		local lock max_acc to ship:maxthrust/ship:mass.
		local dv0 to nd:DELTAV:vec.
    LOCK STEERING to lookdirup(nd:deltav,SHIP:BODY:POSITION).
    local waitstart to 0.
    UI["msg add"]("Executing node: "+nd + "Burntime: "+burntime).

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
					man_check_stage(laststage). 
					// return nd:deltav:mag<0.1 and vdot(dv0, nd:deltav) < 0.1.
					return nd:deltav:mag<0.1 or vdot(dv0, nd:deltav) < 0.1.
			},
			{
					lock throttle to 0.
					local sd to VES1["&solardir"]().
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

	function match_landing_lat {
		parameter tgt, finalalt is 0.
		local desiredinc to abs(tgt:lat). //inclinations are expressed with positive num
		if ship:obt:inclination > 90 {set desiredinc to 180-desiredinc. }  //if already retrograde, stay that way <-- dont do this.. messes up find LAN calc

		if finalalt <> 0 { 
			local lan to find_landing_tgt_LAN(tgt,desiredinc,finalalt).
			change_inc_lan_alt(desiredinc,lan,finalalt).
		}else{
			local lan to find_landing_tgt_LAN_lowalt(tgt, desiredinc).
			change_inc_lan(desiredinc,lan).
		}
		return true.
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
	function find_burntime {
		parameter inputDV, stagenum to STAGE:NUMBER.
		local Mi to SHIP:MASS.
		local stageDV to ship:STAGEDELTAV(stagenum):CURRENT.
		UI["msg add"]("Calculated STAGEDV for stage "+stagenum+" is: "+stageDV).
		local Go to 9.80665.
		local englist is list().
		list engines in englist.
		local engISP to 0.1.
		local engT to 0.1.
		local troubleshooting is 0.
		//local press to MAX(0,MIN(1,ship:body:atm:altitudepressure(ship:altitude))).
		for e in englist {
			if e:stage = stagenum {
				set engISP to engISP + e:VISP.
				set engT to engT + e:possibleThrust.
			}
		}
		if stageDV > inputDV {
			return inputDV/(engT * (((Mi + (Mi * (constant:e ^ (-1 * (inputDV / (engISP * Go) )))))/2) ^ (-1))).
		} else {
			if (stagenum = 0) {
				UI["msg add"]("Not enough DV. ").
				print 0/1.
			}
			else {
				return stageDV/(engT * (((Mi + (Mi * (constant:e ^ (-1 * (stageDV / (engISP * Go) )))))/2) ^ (-1))) + find_burntime(inputDV-stageDV, max(stagenum-1,0)).
			}
			
		}
	}
	function unlock_all{UNLOCK STEERING.
            UNLOCK THROTTLE.}
	
}