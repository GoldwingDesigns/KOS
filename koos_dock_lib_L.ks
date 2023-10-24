@lazyglobal off.
//Launch Maneuvers

// {
// 	global DOCK is lexicon(
// 		"align ports facing",			align_ports@,
//     "cancel vel", cancel_velocity@,
//     "distant approach", distant_approach@,
//     "get own port", get_ship_port@,
//     "get best tgt port", get_tgt_port@,
//     "close approach", close_approach@,
//     "final approach", final_approach@
// 	).
  function xfer_to_pos {
    parameter goal, speed to 1.
    // if goal:MAG > speed set goal to goal:normalized.
    
    local staticgoal to goal-target:position.
    local Kp to 0.9.
    local Ki to 0.01.
    local Kd to 0.02.
    local epsilon to 0.05.
    local min_output to -1.
    local max_output to 1.
    lock DTG to (staticgoal+target:position):mag.
    lock Vx to ship:facing:starvector.
    lock Vy to ship:facing:topvector.
    lock Vz to ship:facing:forevector.
    lock V0 to (staticgoal+target:position):normalized * min(DTG/10,speed). //desired Vector
    lock V0x to vdot(V0,Vx).
    lock V0y to vdot(V0,Vy).
    lock V0z to vdot(V0,Vz).
    lock V1 to ship:velocity:orbit - target:ship:velocity:orbit. //current vector
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
    clearscreen.
    local thrustx to 0.
    local thrusty to 0.
    local thrustz to 0.
    UNTIL DTG < 0.1 {
      // set ship:control:starboard TO PID_X:UPDATE(TIME:SECONDS, V1x).
      set thrustx to PID_X:UPDATE(TIME:SECONDS, V1x).
      IF abs(thrustx) < 0.015 set thrustx to 0. else if thrustx > 0 set thrustx to max(thrustx,0.5). else set thrustx to min(thrustx,-0.5).
      set ship:control:starboard TO thrustx.
      SET PID_X:SETPOINT TO V0x.
      SET PID_X:EPSILON to min(epsilon,V0X/100).
      // set ship:control:top TO PID_y:UPDATE(TIME:SECONDS, V1y).
      set thrusty to PID_y:UPDATE(TIME:SECONDS, V1y).
      IF abs(thrusty) < 0.015 set thrusty to 0. else if thrusty > 0 set thrusty to max(thrusty,0.5). else set thrusty to min(thrusty,-0.5).
      set ship:control:top TO thrusty.
      SET PID_Y:SETPOINT TO V0y.
      SET PID_Y:EPSILON to min(epsilon,V0Y/100).
      // set ship:control:fore TO PID_z:UPDATE(TIME:SECONDS, V1z).
      set thrustz to PID_z:UPDATE(TIME:SECONDS, V1z).
      IF abs(thrustz) < 0.015 set thrustz to 0. else if thrustz > 0 set thrustz to max(thrustz,0.5). else set thrustz to min(thrustz,-0.5).
      set ship:control:fore TO thrustz.
      SET PID_Z:SETPOINT TO V0z.
      SET PID_Z:EPSILON to min(epsilon,V0Z/100).

      print "Goal: "+ DTG at (0,1).
      print "V1: " + V1:MAG at (0,2).
    }
    set ship:control:starboard to 0.
    set ship:control:fore to 0.
    set ship:control:top to 0.
    // clearVecDraws().
    unlock DTG.
    unlock Vx .
    unlock Vy .
    unlock Vz .
    unlock V0 .
    unlock V0x.
    unlock V0y.
    unlock V0z.
    unlock V1 .
    unlock V1x.
    unlock V1y.
    unlock V1z.
  }
  function align_ports {
    parameter target_port.
    lock steering to -target_port:portfacing:vector.
  }
  function cancel_vel {
    parameter tgt to target.
    LOCK Vrel TO SHIP:VELOCITY:ORBIT - tgt:ship:VELOCITY:ORBIT.
    lock DTG to Vrel:mag.
    lock Vx to ship:facing:starvector.
    lock Vy to ship:facing:topvector.
    lock Vz to ship:facing:forevector.
    lock V0 to -Vrel:normalized. //desired Vector
    lock V0x to vdot(V0,Vx).
    lock V0y to vdot(V0,Vy).
    lock V0z to vdot(V0,Vz).
    until DTG < 0.02 {
       SET SHIP:CONTROL:STARBOARD  TO V0x. 
       SET SHIP:CONTROL:FORE       TO V0z. 
       SET SHIP:CONTROL:TOP        TO V0y. 
    }
    set ship:control:starboard to 0.
    set ship:control:fore to 0.
    set ship:control:top to 0.
    UNLOCK Vrel.
    UNLOCK DTG.
    UNLOCK Vx.
    UNLOCK Vy.
    UNLOCK Vz.
    UNLOCK V0.
    UNLOCK V0x.
    UNLOCK V0y.
    UNLOCK V0z.
  }
  function distant_approach {
    parameter tgt to target, speed to 1.
    xfer_to_pos(tgt:position:normalized *(tgt:position:mag-20), speed).
    xfer_to_pos(ship:position).
  }
  // cancel_vel().
  distant_approach().
  cancel_vel().
// }