//@lazyglobal off.
//runoncepath(DATAVOLUME+":/lib/koos_obtcalc_lib"). 
//runoncepath(DATAVOLUME+":/lib/koos_mnv_lib"). 

{
	global MNV_TMP is lexicon(
		//#region Lander
		"match landing lat", match_landing_lat@,
		"pwr land",				pwr_ldg@,
		"land align init",		ldg_align_burn_init@,
		"land align final", 	ldg_align_burn@
	).
	
//#region Lander

	function match_landing_lat {
		parameter tgt, finalalt is 0.
		print "hello".
		local desiredinc to abs(tgt:lat). //inclinations are expressed with positive num
		print "hi".
		if ship:obt:inclination > 90 {set desiredinc to 180-desiredinc. }  //if already retrograde, stay that way <-- dont do this.. messes up find LAN calc
		PRINT "HERE".
		if finalalt <> 0 { 
			print "loly".
			local lan to find_landing_tgt_LAN(tgt,desiredinc,finalalt).
			print lan.
			return MNV["change inc lan alt"](desiredinc,lan,finalalt). //took away the @bind delegate.
		}else{
			local lan to find_landing_tgt_LAN_lowalt(tgt, desiredinc).
			return MNV["change inc lan"](desiredinc,lan). //took away the @bind delegate.
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
				set ship:control:pilotmainthrottle to 0.
				set ship:control:neutralize to TRUE.
				MNV["unlock all"]().
				VES1["sas on"]().
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
				MNV["unlock all"]().
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
				MNV["unlock all"]().
				wait 0.1.
				return true.
			}
		).

	}
	
//#endregion

}