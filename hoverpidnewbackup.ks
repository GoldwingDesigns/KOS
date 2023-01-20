SET hoveralt to 280.
SET tgtlat to -0.096789186370403402.
set	tgtlong to 285.38258125436499.
set alterr to (Body:position:mag - ship:altitude-body:radius).
set raderr to alt:radar.
set tgt to LATLNG(tgtlat,tgtlong).
lock totvec to ship:velocity:surface.
lock survec to vxcl(cos(VANG(totvec,BODY:POSITION))*Body:position:normalized,totvec).
lock tgtvec to tgt:altitudeposition(ship:altitude+alterr).
set corvec to V(0,0,0).
set distvec to V(0,0,0).

// SET totarrow TO VECDRAW(
//       V(0,0,0),
//       { return survec. },
//       blue,
//       "surf vel",
//       1.0,
//       TRUE,
//       0.2,
//       TRUE,
//       TRUE
//     ).


// SET corarrow TO VECDRAW(
//       V(0,0,0),
//       { return corvec. },
//       yellow,
//       "corvec",
//       1.0,
//       TRUE,
//       0.2,
//       TRUE,
//       TRUE
//     ).

// Set surfarrow To VECDRAW(
//       V(0,0,0),
//       { return distvec. },
//       yellow,
//       "distvec",
//       1.0,
//       TRUE,
//       0.2,
//       TRUE,
//       TRUE
//     ).

// Set tgtvect To VECDRAW(
//       V(0,0,0),
//       { return tgtvec. },
//       purple,
//       "tgt",
//       1.0,
//       TRUE,
//       0.2,
//       TRUE,
//       TRUE
//     ).

// Set tgtsarrow To VECDRAW(
//       V(0,0,0),
//       { return V(tgt:position:x,tgt:position:y,0). },
//       white,
//       "tgtsurf",
//       1.0,
//       TRUE,
//       0.2,
//       TRUE,
//       TRUE
//     ).




stage.
wait 0.1.

// hover against gravity:
lock alt_ship to ship:altitude+alterr.
lock Fg to ship:mass * body:mu /((alt_ship + body:radius)^2).
lock am to vang(up:vector, ship:facing:vector).

lock alt_radar to alt:radar-raderr.
set T_star to 0.
lock throttle to max(0.05,T_star / ship:availablethrust).

// calculate initial hover PID gains
set hwn to 0.8.
set hzeta to 1.05.
set hKp to hwn^2 * ship:mass.
set hKd to 2 * ship:mass * hzeta * hwn.
set hKi to 0.
SET hoverPID TO PIDLOOP(hKp, hKi, hKd, -Fg, Fg).
SET hoverPID:SETPOINT TO hoveralt.

set twn to 1.
set tzeta to 7.
set tKp to twn^2.
set tKi to 0.01.
set tKd to 2*tzeta*twn.
SET tgtPID TO PIDLOOP (tKp, tKi, tKd, -10, 10).
SET tgtPID:SETPOINT TO 0.
set dwn to .8.
set dzeta to 1.2.
set dKp to dwn^2.
set dKi to 0.
set dKd to 2*dzeta*dwn.
SET hdgPID TO PIDLOOP (dKp, dKi, dKd, -10, 10).
SET hdgPID:SETPOINT TO 0.
SET shippitch to 0.
set hdgpitch to 0.
set tgtsteering to lookDirUp(-1 * BODY:position:normalized,tgtvec).

lock steering TO tgtsteering.

clearscreen.
UNTIL abs(alt_ship-hoveralt) < 2 { //within 2 meters of hover setpoint go to next part
    //hover:
    set hKp to hwn^2 * ship:mass.
    set hKd to 2 * ship:mass * hzeta * hwn.
    set hoverPID:maxoutput to Fg.
    set hoverPID:minoutput to -Fg.
    set T_star to (hoverPID:UPDATE(TIME:SECONDS, alt_ship) + Fg)/ cos(am).

    printat("Kp: " + hoverPID:pterm + " ki: " + hoverPID:iterm + " kd: " + hoverPID:dterm,1,1).
    
    WAIT 0.001.
}
UNTIL tgtvec:mag<5 { //steer to target until 5 meters laterally from target
    //hover:
    set hKp to hwn^2 * ship:mass.
    set hKd to 2 * ship:mass * hzeta * hwn.
    set hoverPID:maxoutput to Fg.
    set hoverPID:minoutput to -Fg.
    set T_star to (hoverPID:UPDATE(TIME:SECONDS, alt_ship) + Fg)/ cos(am).
     //to/from
    set shippitch to -1 * tgtPID:update(TIME:SECONDS, tgtvec:mag).
    set distvec to (shippitch * tgtvec:normalized).
    //hdg:
    set negind to vcrs(tgtvec:normalized,survec:normalized):z.
    if  negind > 0  {
    set hdgpitch to hdgPID:update(TIME:SECONDS, vang(tgtvec,survec)).
    } else {
      set hdgpitch to hdgPID:update(TIME:SECONDS, vang(tgtvec,survec)*-1).
    }
    set corvec to hdgpitch*vcrs(tgtvec:normalized,BODY:POSITION:normalized).
    //total vector steer:
    set tgtsteering to lookDirUp((-100 * BODY:position:normalized)+distvec+corvec,tgtvec).
    printat("Kp: " + hoverPID:pterm + " ki: " + hoverPID:iterm + " kd: " + hoverPID:dterm,1,1).
    printat("Kp: " + tgtPID:pterm + " ki: " + tgtPID:iterm + " kd: " + tgtPID:dterm,1,2).
    printat(" to/from: "+ shippitch+" L/R: " +hdgpitch + " vang: "+vang(tgtvec,survec),1,3).
    printat("negind: "+negind,1,4).
    WAIT 0.001.
}
set hoverPID:setpoint to 2. //reset hover to 2 meters above ground
UNTIL tgtvec:mag < 0.5 and alt_radar < 2.5 { //reduce hover to 2 meters on radalt and once close enough cut throttle
    //hover:
    set hKp to hwn^2 * ship:mass.
    set hKd to 2 * ship:mass * hzeta * hwn.
    set hoverPID:maxoutput to Fg.
    set hoverPID:minoutput to -Fg.
    set T_star to (hoverPID:UPDATE(TIME:SECONDS, alt_radar) + Fg)/ cos(am).
    //to/from:
    set shippitch to -1 * tgtPID:update(TIME:SECONDS, tgtvec:mag).
    set distvec to (shippitch * tgtvec:normalized).
    //hdg:
    set negind to vcrs(tgtvec:normalized,survec:normalized):z.
    if  negind > 0  {
    set hdgpitch to hdgPID:update(TIME:SECONDS, vang(tgtvec,survec)).
    } else {
      set hdgpitch to hdgPID:update(TIME:SECONDS, vang(tgtvec,survec)*-1).
    }
    set corvec to hdgpitch*vcrs(tgtvec:normalized,BODY:POSITION:normalized).
    //total vector steer:
    set tgtsteering to lookDirUp((-100 * BODY:position:normalized)+distvec+corvec,tgtvec).
    printat("Kp: " + hoverPID:pterm + " ki: " + hoverPID:iterm + " kd: " + hoverPID:dterm,1,1).
    printat("Kp: " + tgtPID:pterm + " ki: " + tgtPID:iterm + " kd: " + tgtPID:dterm,1,2).
    printat(" to/from: "+ shippitch+" L/R: " +hdgpitch + " vang: "+vang(tgtvec,survec),1,3).
    printat("negind: "+negind,1,4).
    WAIT 0.001.
}
LOCK STEERING to UP.
LOCK THROTTLE TO 0.
unlock Throttle.
unlock steering.
panels on.