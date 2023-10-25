@lazyglobal off.
run koos_pathfinding_lib.

{
	global DOCK is lexicon(
		"align ports facing",			align_ports@,
    "cancel vel", cancel_vel@,
    "distant approach", distant_approach@,
    "get own port", get_ship_port@,
    "get best tgt port", get_target_port@,
    "close approach", close_approach@,
    "final approach", final_approach@,
    "dock with vessel", dock_with_vessel@
	).
  function xfer_to_pos {
    parameter goal, referenceObj to ship, speed to 1.
    // if goal:MAG > speed set goal to goal:normalized.
    local staticgoal to goal-(referenceObj:position).
    local Kp to 0.9.
    local Ki to 0.01.
    local Kd to 0.05.
    local epsilon to speed/20.
    local min_output to -1.
    local max_output to 1.
    lock DTG to (staticgoal+(referenceObj:position)):mag.
    lock Vx to ship:facing:starvector.
    lock Vy to ship:facing:topvector.
    lock Vz to ship:facing:forevector.
    lock V0 to (staticgoal+(referenceObj:position)):normalized * max(0.1,min(DTG/10,speed)). //desired Vector
    lock V0x to vdot(V0,Vx).
    lock V0y to vdot(V0,Vy).
    lock V0z to vdot(V0,Vz).
    if referenceObj:istype("Vessel") {
    lock V1 to ship:velocity:orbit - referenceObj:velocity:orbit. //current vector
    }else{
      lock V1 to ship:velocity:orbit - referenceObj:ship:velocity:orbit.
      //lock dockd to not(referenceObj:state = "Ready").
    }
    lock V1x to vdot(V1,Vx).
    lock V1y to vdot(V1,Vy).
    lock V1z to vdot(V1,Vz).
    // clearVecDraws().
    // vecdraw({return V(0,0,0).},{return staticgoal+target:position.},green,"Pos",1,true).
    // vecdraw({return V(0,0,0).},{return V0.},blue,"Desired",5,true).
    // vecdraw({return V(0,0,0).},{return V1.},yellow,"current",5,true).
    
    LOCAL PID_X TO PIDLOOP(Kp, Ki, Kd, min_output, max_output, epsilon).
    SET PID_X:SETPOINT TO V0x.
    LOCAL PID_Y TO PIDLOOP(Kp, Ki, Kd, min_output, max_output, epsilon).
    SET PID_Y:SETPOINT TO V0y.
    LOCAL PID_Z TO PIDLOOP(Kp, Ki, Kd, min_output, max_output, epsilon).
    SET PID_Z:SETPOINT TO V0z.
    // clearscreen.
    local thrustx to 0.
    local thrusty to 0.
    local thrustz to 0.
    UNTIL DTG < 0.02 {
      // set ship:control:starboard TO PID_X:UPDATE(TIME:SECONDS, V1x).
      if ship:controlpart:istype("DockingPort") and ship:controlpart:state <> "Ready" { break.}
      set thrustx to PID_X:UPDATE(TIME:SECONDS, V1x).
      IF abs(thrustx) < 0.015 set thrustx to 0. else if thrustx > 0 set thrustx to max(thrustx,0.1). else set thrustx to min(thrustx,-0.1).
      set ship:control:starboard TO thrustx.
      SET PID_X:SETPOINT TO V0x.
      SET PID_X:EPSILON to min(epsilon,V0X/100).
      // set ship:control:top TO PID_y:UPDATE(TIME:SECONDS, V1y).
      set thrusty to PID_y:UPDATE(TIME:SECONDS, V1y).
      IF abs(thrusty) < 0.015 set thrusty to 0. else if thrusty > 0 set thrusty to max(thrusty,0.1). else set thrusty to min(thrusty,-0.1).
      set ship:control:top TO thrusty.
      SET PID_Y:SETPOINT TO V0y.
      SET PID_Y:EPSILON to min(epsilon,V0Y/100).
      // set ship:control:fore TO PID_z:UPDATE(TIME:SECONDS, V1z).
      set thrustz to PID_z:UPDATE(TIME:SECONDS, V1z).
      IF abs(thrustz) < 0.015 set thrustz to 0. else if thrustz > 0 set thrustz to max(thrustz,0.1). else set thrustz to min(thrustz,-0.1).
      set ship:control:fore TO thrustz.
      SET PID_Z:SETPOINT TO V0z.
      SET PID_Z:EPSILON to min(epsilon,V0Z/100).

      // print "Goal: "+ DTG at (0,1).
      // print "V1: " + V1:MAG at (0,2).
    }
    set ship:control:starboard to 0.
    set ship:control:fore to 0.
    set ship:control:top to 0.
    // UNLOCK ALL.
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
        if shipPort:nodetype = port:nodetype and shipPort:state = "Ready" {
          UI["msg add"]("Target Port Set To "+port:name).
          return port.
        }
      }
    }}else return target.
  }
  function cancel_vel {
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
    until DTG < 0.01 {
       SET SHIP:CONTROL:STARBOARD  TO V0x. 
       SET SHIP:CONTROL:FORE       TO V0z. 
       SET SHIP:CONTROL:TOP        TO V0y. 
    }
    set ship:control:starboard to 0.
    set ship:control:fore to 0.
    set ship:control:top to 0.
    // UNLOCK ALL.
    WAIT 1.
    RETURN true.
  }
  function distant_approach {
    parameter tgtObj to target, speed to 1.
    UI["msg add"]("Distant Approach").
    xfer_to_pos(tgtObj:position:normalized *(tgtObj:position:mag-20), tgtObj, speed).
    cancel_vel(tgtObj).
    RETURN true.
  }
  function close_approach {
    parameter goal, tgtObj to target, speed to 0.5.
    UI["msg add"]("Close Approach to "+tgtObj:name).
    xfer_to_pos(goal, tgtObj, speed).
    cancel_vel(tgtObj).
    RETURN true.
  }
  function final_approach {
    parameter goal, tgtObj to target, speed to 0.3.
    UI["msg add"]("Final Approach to "+tgtObj:name).
    xfer_to_pos(goal, tgtObj, speed).
    if ship:controlpart:istype("DockingPort") and ship:controlpart:state <> "Ready" {
    UI["msg add"]("Docking Complete").}
    RETURN true.
  }
  function get_path_to_apprpoint {
    parameter tgt to target.
    LOCAL B TO "".
    if tgt:istype("Vessel"){set B to tgt:bounds.}
      else if tgt:istype("Part"){set B to tgt:ship:bounds.
      }
    local apoint to target:nodeposition+target:PORTFACING:VECTOR*B:RELMAX:MAG.
    local c to get_corners(B).
    local c_copy to c:copy.
    c_copy:add(apoint).
    return a_star(ship:position,apoint,c,getneighbors@:bind(noboxintersect@:bind(B),c_copy)).
  }
  function dock_with_vessel {
    parameter vessName, dist_speed to 1, close_speed to 0.5, final_speed to 0.3.
    SAS OFF.
    RCS ON.
    local tgtShip to vessel(vessName).
    set target to vessName. //not really used but here for some of the sub functions
    distant_approach(tgtShip, dist_speed).
    local shipPort to get_ship_port().
    shipPort:controlfrom().
    local tgtPort to get_target_port(tgtShip, shipPort).
    align_ports(tgtPort).
    local path_list is list().
    set target to tgtPort.
    set path_list to get_path_to_apprpoint(tgtPort).
    IF path_list:length > 0 {
      local cumulative_path to V(0,0,0).
    for leg in path_list {
      print leg.
      close_approach(leg-cumulative_path,tgtShip,close_speed).
      set cumulative_path to cumulative_path + leg.
    }
    final_approach(tgtPort:nodeposition, tgtShip, final_speed).
    }
    unlock steering.
    sas ON.
    RCS OFF.
    return true.
  }
}