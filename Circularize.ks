function circularize{
SET COMPMODE to 9.
gui_menu_run().
SET Mi to SHIP:MASS.
SET thisMU to BODY:MU.
SET thisR to BODY:RADIUS + SHIP:APOAPSIS.
SET thisA to BODY:RADIUS + ((SHIP:APOAPSIS + SHIP:PERIAPSIS)/2).
SET thisDV to SQRT(thisMU * (2/thisR - 1/thisR)) - SQRT(thisMU * (2/thisR - 1/thisA)).
SET Go to 9.80665.
list engines in englist.
SET engISP to englist[englist:LENGTH - 1]:VISP.
SET engT to englist[englist:LENGTH - 1]:AVAILABLETHRUST.
SET burnTime to thisDV/(engT * (((Mi + (Mi * (constant:e ^ (-1 * (thisDV / (engISP * Go) )))))/2) ^ (-1))).
//SET burnTime to Mi * (constant:e ^ (-1 * thisDV / engISP / Go ) ) * engISP * Go / engT.
SET nd to NODE(TIME:SECONDS + ETA:APOAPSIS,0,0,thisDV).
ADD nd.



SET COUNTDWN TO ROUND(ETA:APOAPSIS - burnTime/2,1).
//PRINT "deltaV:   " + thisDV AT (0,5).
//PRINT "Burn Time:   " + burnTime AT (0,6).
//PRINT "Prograde:    " + nd:PROGRADE AT (0,7). // prints 100.
//PRINT "ETA:         " + nd:ETA AT (0,8).      // prints seconds till maneuver
//PRINT "Delta V:     " + nd:DELTAV.    // prints delta-v vector
//PRINT "New Orbit Ap:" + nd:ORBIT:APOAPSIS AT (0,9).  // apoapsis after maneuver
//PRINT "New Orbit Pe:" + nd:ORBIT:PERIAPSIS AT (0,10). // periapsis after maneuver
//PRINT "Burn in:     " + COUNTDWN AT (0,11).
//SET CircSteer to Heading(90,0).
//SET CircThrot TO 0.
//LOCK THROTTLE TO CircThrot.
//LOCK STEERING TO CircSteer.


SET np to nd:DELTAV:DIRECTION.
SET th to 0.
LOCK THROTTLE to th.
LOCK STEERING to np.
WAIT UNTIL ABS(np:PITCH - FACING:PITCH) < 0.15 AND ABS(np:YAW - FACING:YAW) < 0.15.
UNTIL nd:ETA <= (burnTime/2)
{
SET COUNTDWN TO ROUND(ETA:APOAPSIS - burnTime/2,1).
//PRINT "Burn in:     " + COUNTDWN AT (0,11).
gui_scr_update().
WAIT 0.1.
}


SET done to FALSE.
SET dv0 to nd:DELTAV.
//LOCAL CIRCPID IS PIDLOOP(0.05,0.01,0.01,0,1).
//SET CIRCPID:SETPOINT to 0.
UNTIL done
{
	gui_scr_update().
    //recalculate current max_acceleration, as it changes while we burn through fuel
    set max_acc to ship:maxthrust/ship:mass.
	SET np to nd:DELTAV:DIRECTION.
    //throttle is 100% until there is less than 1 second of time left to burn
    //when there is less than 1 second - decrease the throttle linearly
    set th to min(nd:deltav:mag/max_acc, 1).
    //here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
    //this check is done via checking the dot product of those 2 vectors
    
	if vdot(dv0, nd:deltav) < 0
    {
        gui_msg_add("End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1)).
        lock throttle to 0.
        break.
    }

    //we have very little left to burn, less then 0.1m/s
    if nd:deltav:mag < 0.1
    {
        gui_msg_add("Finalizing burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1)).
        //we burn slowly until our node vector starts to drift significantly from initial vector
        //this usually means we are on point
        wait until vdot(dv0, nd:deltav) < 0.5.

        lock throttle to 0.
        gui_msg_add("End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1)).
        set done to True.
    }
	wait 0.001.
}

//UNTIL SHIP:ORBIT:ECCENTRICITY <= 0.01
//{
 //SET CircThrot TO 1.0.
 //SET CircSteer to ship:prograde:forevector.
 //WAIT 0.001.
//}
 LOCK STEERING TO HEADING(90,0).
 WAIT 3.
 UNLOCK STEERING.
 SET SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
 UNLOCK THROTTLE.
 WAIT 1.
 SET COMPMODE to 2.
 REMOVE nd.
}