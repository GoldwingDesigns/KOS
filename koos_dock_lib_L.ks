@lazyglobal off.
run koos_pathfinding_lib.

{
	global DOCK is lexicon(
		"align ports facing",			align_ports@,
    "cancel vel RCS", cancel_rel_vel_RCS@,
    "cancel vel", cancel_rel_vel@,
    "cancel vel cpa", cancel_rel_vel_at_cpa@,
    "distant approach", distant_approach@,
    "get own port", get_ship_port@,
    "get best tgt port", get_target_port@,
    "close approach", close_approach@,
    "final approach", final_approach@,
    "dock with vessel", dock_with_vessel@,
    "undock from vessel", undock_from_vessel@,
    "ship transfer", ship_trans@
	).
  function xfer_to_pos {
    parameter goal, referenceObj to ship, speed to 1, epsilon to speed/100, onfinalappr is false.
    rcs on.
    local staticgoal to goal-(referenceObj:position).
    local twn to 2. local tzeta to 0.2. local Kp to twn^2. local Ki to 0. local Kd to 2*tzeta*twn.
    local currobjpos to V(0,0,0).
    local min_output to -1.
    local max_output to 1.
    if not onfinalappr {lock currobjpos to (staticgoal+(referenceObj:position))-ship:controlpart:position.} else { lock currobjpos to referenceObj:nodeposition-ship:controlpart:position.}. //final docking using nodeposition is more accurate
    lock DTG to currobjpos:mag.
    lock Vx to ship:facing:starvector.
    lock Vy to ship:facing:topvector.
    lock Vz to ship:facing:forevector.
    lock V0 to currobjpos:normalized * max(0.1,min(DTG/10,speed)). //desired Vector
    if not onfinalappr { //this change is for final docking.  We want x and y offset to be exactly 0.
      lock V0x to vdot(V0,Vx).
      lock V0y to vdot(V0,Vy).
    }else{
      lock V0x to 0.
      lock V0y to 0.
    }
    lock V0z to vdot(V0,Vz).
    if referenceObj:istype("Vessel") {
    lock V1 to ship:velocity:orbit - referenceObj:velocity:orbit. //current vector
    }else{
      lock V1 to ship:velocity:orbit - referenceObj:ship:velocity:orbit.
    }
    if not onfinalappr { //this change is for final docking.  We want x and y setpoint to based off position, not speed.
      lock V1x to vdot(V1,Vx).
      lock V1y to vdot(V1,Vy).
    }else{
      lock V1x to vdot(currobjpos,-Vx).
      lock V1y to vdot(currobjpos,-Vy).
    }
    lock V1z to vdot(V1,Vz).    
    LOCAL PID_X TO PIDLOOP(Kp, Ki, Kd, min_output, max_output, epsilon).
    SET PID_X:SETPOINT TO V0x.
    LOCAL PID_Y TO PIDLOOP(Kp, Ki, Kd, min_output, max_output, epsilon).
    SET PID_Y:SETPOINT TO V0y.
    LOCAL PID_Z TO PIDLOOP(Kp, Ki, Kd, min_output, max_output, epsilon).
    SET PID_Z:SETPOINT TO V0z.
    local thrustx to 0.
    local thrusty to 0.
    local thrustz to 0.
    UNTIL DTG < 0.02 {
      if ship:controlpart:istype("DockingPort") and ship:controlpart:state <> "Ready" { break.}
      set thrustx to PID_X:UPDATE(TIME:SECONDS, V1x).
      set ship:control:starboard TO thrustx.
      if not onfinalappr{SET PID_X:SETPOINT TO V0x.}
      SET PID_X:EPSILON to min(epsilon,V0X/10).
      set thrusty to PID_y:UPDATE(TIME:SECONDS, V1y).
      set ship:control:top TO thrusty.
      if not onfinalappr{SET PID_Y:SETPOINT TO V0y.}
      SET PID_Y:EPSILON to min(epsilon,V0Y/10).
      set thrustz to PID_z:UPDATE(TIME:SECONDS, V1z).
      set ship:control:fore TO thrustz.
      SET PID_Z:SETPOINT TO V0z.
      SET PID_Z:EPSILON to min(epsilon,V0Z/10).
    }
    set ship:control:starboard to 0.
    set ship:control:fore to 0.
    set ship:control:top to 0.
    UNLOCK currobjpos.
    rcs off.
    RETURN true.
  }
  function align_ports {
    parameter target_port.
    lock steering to -target_port:portfacing:vector.
    UI["msg add"]("Aligning Reference and Target Ports").
    wait 5.
    RETURN true.
  }
  function get_ship_port {
    if ship:dockingports:length > 0 {
      UI["msg add"]("Reference Port Set To "+ship:DOCKINGPORTS[0]:name).
      return ship:DOCKINGPORTS[0].
    }
  }
  function get_target_port {
    parameter tgtObj, shipPort is 0.
    if tgtObj:istype("vessel"){
    if shipPort = 0 {
      set shipPort to get_ship_port().
    }
    IF tgtObj:DOCKINGPORTS:LENGTH <> 0 {
      for port in tgtObj:DOCKINGPORTS {
        if shipPort:nodetype = port:nodetype and port:state = "Ready" {
          UI["msg add"]("Target Port Set To "+port:name).
          return port.
        }
      }
    }}else {UI["msg add"]("Target Port Not Found"). return target.}
  }
  function cancel_rel_vel_RCS {
    parameter tgtObj.
    if not tgtObj:istype("Vessel") {set tgtObj to tgtObj:ship.}
    LOCK Vrel TO SHIP:VELOCITY:ORBIT - tgtObj:VELOCITY:ORBIT.
    lock DTG to Vrel:mag.
    lock Vx to ship:facing:starvector.
    lock Vy to ship:facing:topvector.
    lock Vz to ship:facing:forevector.
    lock V0 to -Vrel:normalized. //desired Vector
    lock V0x to vdot(V0,Vx).
    lock V0y to vdot(V0,Vy).
    lock V0z to vdot(V0,Vz).
    rcs on.
    until DTG < 0.01 {
       SET SHIP:CONTROL:STARBOARD  TO V0x. 
       SET SHIP:CONTROL:FORE       TO V0z. 
       SET SHIP:CONTROL:TOP        TO V0y. 
    }
    set ship:control:starboard to 0.
    set ship:control:fore to 0.
    set ship:control:top to 0.
    UNLOCK DTG.
    Unlock Vx.
    Unlock Vy.
    Unlock Vz.
    Unlock V0.
    Unlock V0x.
    Unlock V0y.
    unlock V0z.
    rcs off.
    WAIT 1.
    RETURN true.
  }
  function cancel_rel_vel {
    parameter tgtObj.
    if not tgtObj:istype("Vessel") {set tgtObj to tgtObj:ship.}
    LOCK Vrel TO SHIP:VELOCITY:ORBIT - tgtObj:VELOCITY:ORBIT.
    sas off.
    lock STEERING to -Vrel.
    wait until vcrs(ship:facing:forevector,Vrel):mag<0.1.
    local th to 0.
    lock THROTTLE to th.
    until Vrel:mag < 0.1 {
       SET TH TO MIN(1,Vrel:mag/20).
    }
    set th to 0.
    UNLOCK Vrel.
    Unlock Steering.
    Unlock throttle.
    sas on.
    WAIT 1.
    RETURN true.
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
  function cancel_rel_vel_at_cpa{
    parameter tgt.
    local cpat is cpa(tgt,node(0,0,0,0),true,10).
    add node(cpat,0,0,0).
    local shipvel is velocityAt(ship,cpat):orbit.
    local tgtvel is velocityAt(tgt,cpat):orbit.
    local veldiffV is (shipvel-tgtvel).
    local burnt is find_burntime(abs(veldiffV:mag)).
    local startburn is cpat-burnt.
    local th to 0.
    local relspeed to 0.
    lock THROTTLE to th.
    return list(
      {
				warpto(startburn-30).
				return true.
			},

      {
        if not tgt:istype("Vessel") {set tgt to tgt:ship.}
        LOCK Vrel TO SHIP:VELOCITY:ORBIT - tgt:VELOCITY:ORBIT.
        sas off.
        lock STEERING to -Vrel.
        return true.
      },
      {
        return vcrs(ship:facing:forevector,Vrel):mag<0.1.
      },
      {
				return time:seconds > startburn-1.
			},
      {
          set relspeed to Vrel:mag.
          SET TH TO MIN(1,relspeed/20).
          return relspeed<0.1.
      },
      {
        set th to 0.
        UNLOCK Vrel.
        Unlock Throttle.
        Unlock Steering.
        sas on.
        if hasnode remove nextnode.
        WAIT 1.
        RETURN true.
      }).
  }
  function distant_approach {
    parameter tgtObj to target, speed to 1.
    UI["msg add"]("Distant Approach To "+tgtObj:name).
    xfer_to_pos(tgtObj:position:normalized *(tgtObj:position:mag-50), tgtObj, speed).
    cancel_rel_vel_RCS(tgtObj).
    RETURN true.
  }
  function close_approach {
    parameter goal, tgtObj to target, speed to 0.5.
    UI["msg add"]("Close Approach to "+tgtObj:name).
    xfer_to_pos(goal, tgtObj, speed).
    cancel_rel_vel_RCS(tgtObj).
    RETURN true.
  }
  function final_approach {
    parameter goal, tgtObj to target, speed to 0.1.
    UI["msg add"]("Final Approach To "+tgtObj:name).
    xfer_to_pos(goal, tgtObj, speed, 0, true).
    if ship:controlpart:istype("DockingPort") and ship:controlpart:state <> "Ready" {
    UI["msg add"]("Docking Complete").}
    RETURN true.
  }
  function get_path_to_apprpoint {
    parameter tgt to target.
    LOCAL B TO "".
    local tshooting to true.
    local buffer to ship:bounds:relmax:mag * 2.
    if tgt:istype("Vessel"){set B to tgt:bounds.}
      else if tgt:istype("Part"){set B to tgt:ship:bounds.
      }
    local apoint to tgt:nodeposition+tgt:PORTFACING:VECTOR*(B:RELMAX:MAG+(ship:bounds:relmax:mag * 2)).
    local c to get_corners(B,buffer).
    if tshooting {
      runPath("0:/koos_tgt_bounds_tshoot.ks").
    }
     
    local c_copy to c:copy.
    c_copy:add(apoint).
    return a_star(ship:position,apoint,c,getneighbors@:bind(noboxintersect@:bind(B),c_copy)).
  }
  function ship_trans{
		parameter tgt, distance is 500.
    set target to tgt.
    local planetMU to SHIP:ORBIT:BODY:MU.
		local oldSMA to SHIP:ORBIT:SEMIMAJORAXIS.
		local newSMA to tgt:ORBIT:SEMIMAJORAXIS.
    local atx is (oldSMA+newSMA)/2.
    local e is 1-(oldSMA/atx).
    local trueanom is 0.
    set trueanom to arccos(round(((((atx * (1-e^2))/newSMA)-1)/e),6)).
    local eccanom is arcCos((e+cos(trueanom))/(1+(e*cos(trueanom)))).
    local tof is ((eccanom*constant:degtorad-e*sin(eccanom))*sqrt((atx^3)/planetMU)).
		local tgtdistancecovered is (tof/orbit_period(BODY,tgt:orbit:periapsis,tgt:orbit:apoapsis))*360.
		local transferAngle is 180 - tgtdistancecovered.
		//copied from reddit user ollieshmollie and toukiedatak
    local shippos to ship:orbit:position - ship:body:position.
		local tgtshippos to tgt:orbit:position - tgt:body:position.
		local phaseangle to vang(tgtshippos,shippos).
		local phaseanglecrs to vcrs(tgtshippos,shippos).
		if vdot(v(1,1,1), phaseanglecrs) <= 0 {
			set phaseangle to -1 * phaseangle.
		}
		
		local tgtAngVel is 2*constant:radtodeg*constant:pi/tgt:orbit:period.
		local shipAngVel is 2*constant:radtodeg*constant:pi/ship:orbit:period.
    if newSMA>oldSMA and phaseangle < 0 set phaseangle to phaseangle+360.
    if oldSMA>newSMA and phaseangle > 0 set phaseangle to phaseangle-360.
		local angdiff is abs(phaseangle-transferAngle).
		
		UI["msg add"]("phase: "+phaseangle+" xfer: "+transferAngle).
		local transtimeUTC to TIME:SECONDS + (angdiff)/ABS(tgtAngVel-shipAngVel).
		local initialV to sqrt(planetMU/oldSMA).
		local finalV to sqrt(planetMU*(2/oldSMA-1/atx)).
		local thisDV to finalV - initialV.
		local nd to NODE(transtimeUTC,0,0,thisDV).
		local hnd is hillclimb(nd, tgt, list("shiptoship",distance), 20).
		ADD hnd.
		return true.
	}
  function undock_from_vessel {
    //works with first docking port nearest kos core.
    function findchildport{
      parameter prt.
      for pchild in prt:children{
        if pchild:istype("DockingPort") return pchild.
        if findchildport(pchild):istype("DockingPort") return pchild.
        return prt.
      }
    }
    local final_speed to 0.2.
    local p is core:part:parent. 
    local tgtPort is "".
    until not p:hasparent or p:istype("DockingPort") 
    {set p to p:parent.} 
    if p:istype("DockingPort") {set tgtPort to p:partner. p:undock.}else{
      set p to findchildport(core:part:parent).
      if p:istype("DockingPort") {set tgtPort to p:partner. p:undock.}

    }
    set kuniverse:activevessel to core:vessel.
    rcs on.
    p:controlfrom().
    align_ports(tgtPort).
    close_approach(tgtPort:facing:vector * tgtPort:ship:bounds:relmax:mag*2, tgtPort, final_speed).
    p:ship:controlfrom().
    secure_port(p).
    secure_port(tgtPort).
    rcs off.
    unlock steering.
    sas on.
    wait 1.
    unlock all.

  }
  function prepare_port{
    parameter p.
    if p:hasmodule("ModuleAnimateGeneric") { 
      if p:getmodule("ModuleAnimateGeneric"):hasevent("open") {
        p:getmodule("ModuleAnimateGeneric"):doevent("open"). 
      }
      if p:getmodule("ModuleAnimateGeneric"):hasevent("open shield") {
        p:getmodule("ModuleAnimateGeneric"):doevent("open shield"). 
      }
      if p:getmodule("ModuleAnimateGeneric"):hasevent("deploy") {
        p:getmodule("ModuleAnimateGeneric"):doevent("deploy"). 
      }
    }
    return true.
  }
  function secure_port {
    parameter p.
    if p:hasmodule("ModuleAnimateGeneric") { 
      if p:getmodule("ModuleAnimateGeneric"):hasevent("close") {
        p:getmodule("ModuleAnimateGeneric"):doevent("close"). 
      }
      if p:getmodule("ModuleAnimateGeneric"):hasevent("close shield") {
        p:getmodule("ModuleAnimateGeneric"):doevent("close shield"). 
      }
      if p:getmodule("ModuleAnimateGeneric"):hasevent("retract") {
        p:getmodule("ModuleAnimateGeneric"):doevent("retract"). 
      }
    }.
    return true.
}
  function dock_with_vessel {
    parameter vessName, dist_speed to 2, close_speed to 1, final_speed to 0.1.
    SAS OFF.
    // RCS ON.
    local tgtShip to vessel(vessName).
    set target to vessName. //not really used but here for some of the sub functions
    local shipPort to get_ship_port().
    prepare_port(shipPort).
    shipPort:controlfrom().
    local tgtPort to get_target_port(tgtShip, shipPort).
    if tgtPort = tgtShip return true.  //tgtport not found
    prepare_port(tgtPort).
    align_ports(tgtPort).
    distant_approach(tgtShip, dist_speed).
    local path_list is list().
    set target to tgtPort.
    set path_list to get_path_to_apprpoint(tgtPort).
    IF path_list:length > 0 {
      local cumulative_path to V(0,0,0).
    for leg in path_list {
      if leg <> V(0,0,0){
      close_approach(leg-cumulative_path,tgtShip,close_speed).
      set cumulative_path to cumulative_path + leg.
      }
      
    }
    final_approach(tgtPort:nodeposition, tgtPort, final_speed).
    }
    unlock all.
    sas ON.
    RCS OFF.
    return true.
  }
}