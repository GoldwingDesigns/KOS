declare function ShipTWR
{
    list engines in englist.
	SET mth to englist[englist:LENGTH - 1]:THRUST.
	//set mth to SHIP:MAXTHRUST. // (depends on fixed kOS issue 940)
    set r to SHIP:ALTITUDE+SHIP:BODY:RADIUS.
    set w to SHIP:MASS * SHIP:BODY:MU / r / r.
    return mth/w.
}

function launch{
parameter launchalt, launchinc, launchcirc.
SET COMPMODE to 9.
gui_menu_run().
SET th to 1. //Variable for locked throttle.  1.0 is the max, 0.0 is idle.
SET Steering_Lock TO HEADING(90,90). //Variable for locked steering.
SET TurnEnd TO 60000. //The ending altitude for the ascent turn.
SET TurnExponent TO 0.5. //Turn exponent for curvature.
SET TurnStart TO 0.  //Used to mark the altitude that the ascent turn begins.
SET MyPitch TO 90. //Initial setting for pitch on launch (straight up).
SET DesiredTWR TO 2. //DesiredTWR throughout launch
LOCAL TWRPID is PIDLOOP(0.1,0,0.01,-0.5,0.5). //PID loop to set throttle to DesiredTWR.
SET TWRPID:SETPOINT to DesiredTWR.



//**Setup Throttle and Steering Locks.
LOCK THROTTLE TO th.   
LOCK STEERING TO Steering_Lock. // from now on we'll be able to change steering by just assigning a new value to Steering_Lock

//**Declare Triggers.

//**This is a trigger that constantly checks to see if our thrust is zero.
//**If it is, it will attempt to stage and then return to where the script
//**left off. 
//WHEN MAXTHRUST = 0 THEN {
//  PRINT "Staging".
//    STAGE.
//    PRESERVE.
//}.

//**Trigger to open the Solar Panels and turn on Lights when above atmosphere.
WHEN SHIP:ALTITUDE > 70000 THEN {
PANELS ON.
LIGHTS ON.
gui_msg_add("Panels Extended.").
}
//**Trigger to mark the altitue the ascent turn begins
WHEN SHIP:VELOCITY:SURFACE:MAG >= 50 THEN{
SET TurnStart TO SHIP:ALTITUDE - 10.
gui_msg_add("Commence Roll.").
}

//**Uncomment to draw vectors
//set vd to vecdraw(V(0,0,0),ship:srfprograde:forevector,green,"srfprograde",20,TRUE). 
//set vd:vecupdater to {
//	return ship:srfprograde:forevector.
//	}.
// vecdraw(V(0,0,0),UP:VECTOR,red,"kerbinup",20,TRUE). 

//**Uncomment below to log throttle PID info**
//SET start_time to TIME:SECONDS.
//LOG "# Throttle PID Tuning" to throttle_log.
//LOG "# Kp: " + TWRPID:KP TO throttle_log.
//LOG "t,P,ShipTWR,Th" TO throttle_log.
//LOCK logline TO (TIME:SECONDS - start_time) + "," + TWRPID:ERROR + "," + CurTWR + "," + th.

SET STARTTIME to TIME.

UNTIL SHIP:APOAPSIS >= launchalt AND SHIP:ALTITUDE >=70000 { //Until the desired Apoapsis is reached and we are out of the atmospere
	LOCK MyPitch TO 90 * (1 - ((SHIP:ALTITUDE-TurnStart) / TurnEnd) ^ TurnExponent).

    IF SHIP:VELOCITY:SURFACE:MAG < 50 //Initial launch will be straight up 
	{
        SET Steering_Lock TO HEADING(90,90).
		//PRINT "Apoapsis:  " + ROUND(SHIP:APOAPSIS,0) AT (0,16).
		//PRINT "TWR:       " + ROUND(ShipTWR,2) AT (0,17).
		//PRINT "MyPitch:   " + MyPitch AT (0,20).
    } ELSE IF SHIP:ALTITUDE < TurnEnd AND SHIP:APOAPSIS < launchalt { //If still following the launch curve and desired apoapsis not reached 
		SET CurTWR to ShipTWR.
		SET Steering_Lock TO HEADING(90,MyPitch).
		SET newth to th+TWRPID:UPDATE(time:seconds, CurTWR).
		SET th to MIN(1,MAX(newth,0)).
		//PRINT "Pitching to " + ROUND(MyPitch,1) + " degrees" AT(0,15).
        //PRINT "Apoapsis:  " + ROUND(SHIP:APOAPSIS,0) AT (0,16).
		//PRINT "TWR:       " + ROUND(CurTWR,2) AT (0,17).
		//PRINT "TIME:      " + TIME:SECONDS AT (0,18).
		//PRINT "NewTH:     " + ROUND(newth,3) AT (0,19).
		//PRINT "MyPitch:   " + MyPitch AT (0,20).
		//LOG logline TO throttle_log. //Uncomment to log throttle PID data
	} ELSE { //If launch curve has ended or desired apoapsis value is reached.
		SET CurTWR to ShipTWR.
		SET Steering_Lock TO HEADING(90,0).
		IF SHIP:APOAPSIS < launchalt { //Apoapsis value has dropped due to drag.
		SET newth to th+TWRPID:UPDATE(time:seconds, CurTWR).
		} ELSE { //Coasting to Apoapsis.
		SET newth to 0.
		}
		SET th to MIN(1,MAX(newth,0)).
		//SET th TO 0.
		//PRINT "Pitching to prograde               " AT(0,15).
        //PRINT "Apoapsis:  " + ROUND(SHIP:APOAPSIS,0) AT (0,16).
		//PRINT "TWR:       " + ROUND(CurTWR,2) AT (0,17).
		//PRINT "TIME:      " + TIME:SECONDS AT (0,18).
		//PRINT "NewTH:     " + ROUND(newth,3) AT (0,19).
	}
	
	if stage:number > 0 {
    if maxthrust = 0 {
        stage.
		gui_msg_add("Stage.").
    }
    SET numOut to 0.
    LIST ENGINES IN engines. 
    FOR eng IN engines 
    {
        IF eng:FLAMEOUT 
        {
            SET numOut TO numOut + 1.
        }
    }
    if numOut > 0 { stage.  gui_msg_add("Stage."). }.
	}

	WAIT 0.1.
	gui_scr_update().
	
	
}
gui_msg_add("Cutting throttle.").

//**Uncomment below to log throttle PID info**
//COPYPATH("throttle_log", "0:/throttletest.xls").

//**At this point, our apoapsis is above the desired value and our main loop has ended. Next
//**we'll make sure our throttle is zero and that we're pointed prograde.
LOCK THROTTLE TO 0.
UNLOCK THROTTLE.
SET Steering_Lock TO ship:prograde:forevector.
WAIT 10.
UNLOCK STEERING.
if launchcirc circularize().
}