@lazyglobal off.
runOncePath(DATAVOLUME+":/lib/koos_pathfinding_lib"). 

{
	global MNV_TMP is lexicon(
		//#region Dock
		"align ports facing",			align_ports@,
    "cancel vel RCS", cancel_rel_vel_RCS@,
    "cancel vel", cancel_rel_vel@,
    "distant approach", distant_approach@,
    "get own port", get_ship_port@,
    "get best tgt port", get_target_port@,
    "close approach", close_approach@,
    "final approach", final_approach@,
    "dock with vessel", dock_with_vessel@,
    "undock from vessel", undock_from_vessel@
		//#endregion
 	).
	
//#region Dock

  function xfer_to_pos {
    parameter goal, referenceObj to ship, speed to 1, epsilon to speed/100, onfinalappr is false.
    rcs on.
    local staticgoal to goal-(referenceObj:position).
		local gain is VES1["&RCSgain"]().
    local twn to gain*2. local tzeta to gain*0.2. local Kp to twn^2. local Ki to 0. local Kd to 2*tzeta*twn.
    local currobjpos to V(0,0,0).
    local min_output to -1.
    local max_output to 1.
    if not onfinalappr {lock currobjpos to (staticgoal+(referenceObj:position))-ship:controlpart:position.} else { lock currobjpos to referenceObj:nodeposition-ship:controlpart:position.}. //final docking using nodeposition is more accurate
    // if not onfinalappr {lock currobjpos to (staticgoal+(referenceObj:position))-ship:controlpart:position.} else { lock currobjpos to referenceObj:nodeposition-ship:controlpart:position.}. //final docking using nodeposition is more accurate
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
    UNTIL DTG < 0.01 {
      if onfinalappr and ship:controlpart:istype("DockingPort") and ship:controlpart:state <> "Ready" { break.}
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
    }}else {UI["msg add"]("Target Port Not Found"). return 0.}
  }
  
	function cancel_rel_vel_RCS {
    parameter tgtObj.
    if not tgtObj:istype("Vessel") {set tgtObj to tgtObj:ship.}
		local gain is VES1["&RCSgain"]().
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
       SET SHIP:CONTROL:STARBOARD  TO gain*V0x. 
       SET SHIP:CONTROL:FORE       TO gain*V0z. 
       SET SHIP:CONTROL:TOP        TO gain*V0y. 
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
    parameter goal, tgtObj to target, speed to 0.2.
    UI["msg add"]("Final Approach To "+tgtObj:name).
    xfer_to_pos(goal, tgtObj, speed, 0, true).
    if ship:controlpart:istype("DockingPort") and ship:controlpart:state <> "Ready" {
    UI["msg add"]("Docking Complete").}
    RETURN true.
  }
  
	function get_path_to_apprpoint {
    parameter tgt to target.
    LOCAL B TO "".
    // local tshooting to true.
    local buffer to ship:bounds:relmax:mag * 2.
    if tgt:istype("Vessel"){set B to tgt:bounds.}
      else if tgt:istype("Part"){set B to tgt:ship:bounds.
      }
    local apoint to tgt:nodeposition+tgt:PORTFACING:VECTOR*(B:RELMAX:MAG+(ship:bounds:relmax:mag * 2)).
    local c to get_corners(B,buffer).
    // if tshooting {
    //   runPath("0:/koos_tgt_bounds_tshoot.ks").
    // }
     
    local c_copy to c:copy.
    c_copy:add(apoint).
    return a_star(ship:position,apoint,c,getneighbors@:bind(noboxintersect@:bind(B),c_copy)).
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
    local p is core:part. 
    local tgtPort is "".
    until (not p:hasparent) or p:istype("DockingPort") 
    {set p to p:parent. } 
    if p:istype("DockingPort") {set tgtPort to p:partner. wait 0. p:undock.}else{
      set p to findchildport(p).
      if p:istype("DockingPort") {set tgtPort to p:partner. wait 0. p:undock.}

    }
    set kuniverse:activevessel to core:vessel.
		WAIT 0.1.
    rcs on.
		local newport is get_ship_port().
    newport:controlfrom().
    align_ports(tgtPort).
	  close_approach(tgtport:facing:vector*tgtPort:ship:bounds:relmax:mag*2, tgtPort, 0.5).
    rcs off.
    // unlock steering.
    sas on.
    wait 1.
		unlock_all().	
    secure_port(newport).
    secure_port(tgtPort).
		ship:rootpart:controlfrom().
    
		return true.
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
    parameter vessName, dist_speed to 2, close_speed to 1, final_speed to 0.2.
    SAS OFF.
    // RCS ON.
    local tgtShip to vessel(vessName).
    set target to vessName. //not really used but here for some of the sub functions
    local shipPort to get_ship_port().
    prepare_port(shipPort).
    shipPort:controlfrom().
    local tgtPort to get_target_port(tgtShip, shipPort).
    if tgtPort = 0 return true.  //tgtport not found
    prepare_port(tgtPort).
    align_ports(tgtPort).
    // distant_approach(tgtShip, dist_speed).
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
    unlock_ALL().
    sas ON.
    RCS OFF.
    return true.
  }

//#endregion
}