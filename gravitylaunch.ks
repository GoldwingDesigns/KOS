//hellolaunch
declare function ShipTWR
{
    set mth to SHIP:MAXTHRUST. // (depends on fixed kOS issue 940)
    set r to SHIP:ALTITUDE+SHIP:BODY:RADIUS.
    set w to SHIP:MASS * SHIP:BODY:MU / r / r.
    return mth/w.
}
//First, we'll clear the terminal screen to make it look nice
CLEARSCREEN.
SET thekerbin TO Body("Kerbin").
//Next, we'll lock our throttle to 100%.
set th TO 1.0.
LOCK THROTTLE TO th.   // 1.0 is the max, 0.0 is idle.

//This is our countdown loop, which cycles from 10 to 0
PRINT "Counting down:".
FROM {local countdown is 1.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
    WAIT 1. // pauses the script here for 1 second.
}

//This is a trigger that constantly checks to see if our thrust is zero.
//If it is, it will attempt to stage and then return to where the script
//left off. The PRESERVE keyword keeps the trigger active even after it
//has been triggered.
WHEN MAXTHRUST = 0 THEN {
    PRINT "Staging".
    STAGE.
    PRESERVE.
}.
//set vd to vecdraw(V(0,0,0),ship:srfprograde:forevector,green,"srfprograde",20,TRUE). 
//set vd:vecupdater to {
//	return ship:srfprograde:forevector.
//	}.
// vecdraw(V(0,0,0),UP:VECTOR,red,"kerbinup",20,TRUE). 
//This will be our main control loop for the ascent. It will
//cycle through continuously until our apoapsis is greater
//than 100km. Each cycle, it will check each of the IF
//statements inside and perform them if their conditions
//are met
SET PITCHDONE TO FALSE.
SET PITCHKICK TO 5.
SET MYSTEER TO HEADING(90,90).
LOCK STEERING TO MYSTEER. // from now on we'll be able to change steering by just assigning a new value to MYSTEER
UNTIL PITCHDONE { 
	IF SHIP:VELOCITY:SURFACE:MAG <= 50 {
		SET MYSTEER TO HEADING(90,90).
		PRINT "Pitching to 90 degrees" AT(0,15).
		PRINT "Apoapsis: " + ROUND(SHIP:APOAPSIS,0) AT (0,16).
		PRINT "TWR:      " + ShipTWR AT (0,17).
	//	PRINT abs(10 - VANG(UP:vector,ship:srfprograde:forevector)) AT (0,18).	
	} ELSE IF abs(PITCHKICK - VANG(UP:vector,ship:srfprograde:forevector)) > 0.1 {
		SET MYSTEER TO HEADING(90,90-PITCHKICK).
		PRINT "Pitching to 80 degrees" AT (0,15).
		PRINT "Apoapsis: " + ROUND(SHIP:APOAPSIS,0) AT (0,16).
		PRINT "TWR:      " + ShipTWR AT (0,17).
	//	PRINT abs(10 - VANG(UP:vector,ship:srfprograde:forevector)) AT (0,18).
	} ELSE {
	SET PITCHDONE TO TRUE.
	}
}
UNTIL SHIP:APOAPSIS > 100000 {  
	IF NAVMODE = "SURFACE" {	
		SET MYSTEER TO ship:srfprograde:forevector.
		PRINT "Pitching to SRFPROGRADE           " AT (0,15).
		PRINT "Apoapsis: " + ROUND(SHIP:APOAPSIS,0) AT (0,16).
		PRINT "TWR:      " + ShipTWR AT (0,17).
	} ELSE IF NAVMODE = "ORBIT" {	
		SET MYSTEER TO ship:prograde:forevector.
		PRINT "Pitching to SRFPROGRADE           " AT (0,15).
		PRINT "Apoapsis: " + ROUND(SHIP:APOAPSIS,0) AT (0,16).
		PRINT "TWR:      " + ShipTWR AT (0,17).
	}
}
UNTIL SHIP:APOAPSIS > 100000 AND SHIP:ALTITUDE > 50000 {  
		SET MYSTEER TO HEADING(90,0).
		SET th TO 0.7.
		PRINT "Pitching to horizon               " AT(0,15).
		PRINT "Apoapsis: " + ROUND(SHIP:APOAPSIS,0) AT (0,16).
		PRINT "TWR:      " + ShipTWR AT (0,17).
}
PRINT "Cutting throttle                   " AT (0,15).

//At this point, our apoapsis is above 100km and our main loop has ended. Next
//we'll make sure our throttle is zero and that we're pointed prograde
LOCK THROTTLE TO 0.
CLEARSCREEN.
print missiontime.
print " Arming upper stage".
stage.
print " Cruise to apoapsis".
wait until eta:apoapsis < 10.
CLEARSCREEN.
print missiontime.
print " Circularization".
set mysteering to up + R(0,-90,0).
lock steering to mysteering.
lock throttle to 1.
set lastapoapsis to alt:apoapsis.
set lastaltitude to altitude.
until alt:periapsis > 99000
{
  if alt:periapsis > 95000
  {
    lock throttle to 0.1.
  }
  ELSE if altitude > 100005
  {
    set mysteering to up + R(0,-135,0).
  }
  ELSE if altitude < 99995
  {
    set mysteering to up + R(0,-40,0).
  }
  ELSE 
  {
      set mysteering to up + R(0,-90,0).
  }
}
//This sets the user's throttle setting to zero to prevent the throttle
//from returning to the position it was at before the script was run.
LOCK THROTTLE TO 0.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
UNLOCK THROTTLE.
UNLOCK STEERING.
