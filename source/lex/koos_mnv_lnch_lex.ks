//@lazyglobal off. 
//runoncepath(DATAVOLUME+":/lib/lib_LAZcalc").
//runoncepath(DATAVOLUME+":/lib/koos_mnv_lib"). 

{
	global MNV_TMP is lexicon(
  	//#region Initial Launch
    "launch atmo",			launch_atmo_gravity_turn@
		//#endregion
	).
	
//#region InitialLaunch
	
	function launch_atmo_gravity_turn{
		parameter launchalt, launchinc, thrByEta is true, setpoint is 45, pitchoverDeg is 4, roll is -90.
    local waitstart to 0.
		//roll to -180 for shuttle.
		local th to 1. //Variable for locked throttle.  1.0 is the max, 0.0 is idle.
		local Steering_Lock TO HEADING(90,90,roll). //Variable for locked steering. shuttle is 0? probe is -90?
		local TurnEnd TO launchalt. //The ending altitude for the ascent turn.
		local MyPitch TO 90. //Initial setting for pitch on launch (straight up).
		local newth to 0.
		local atmoheight to SHIP:ORBIT:BODY:ATM:HEIGHT.
		local stopatstage to VES1["&launchstage"]().
		local launchazdata to LAZcalc_init(launchalt,launchinc).
		local launchaz to LAZcalc(launchazdata).
		// local launchaz to getLaunchAzimuth(launchinc).
		local THRPID to CHOOSE PIDLOOP(0.1,0.0,0.1,-0.5,0.5) if thrByEta else PIDLOOP(0.1,0,0.01,-0.5,0.5). //PID loop to set throttle to DesiredTWR.
		SET THRPID:SETPOINT to setpoint.
		VES1["sas off"]().

		//**Setup Throttle and Steering Locks.
		LOCK THROTTLE TO th. 
		LOCK STEERING TO Steering_Lock. // from now on we'll be able to change steering by just assigning a new value to Steering_Lock
		
		//**Declare Triggers.

		//**Trigger to open the Solar Panels and turn on Lights when above atmosphere. Had to split up because log file sharing conflict.
		WHEN SHIP:altitude > atmoheight - 2000 THEN {
			VES1["fairing deploy"]().
	 	}
		WHEN SHIP:altitude > atmoheight - 1000 THEN {
    	VES1["comms ext"]().
		}
		WHEN SHIP:altitude > atmoheight THEN {
    	VES1["panels on"]().
		}

		if STARTTIME = 0 {set STARTTIME to TIME. local mtime to time. UI["msg add"]("Commence Launch Program at "+mTime:year+"y "+mtime:day+"d "+mtime:hour+"h "+mtime:minute+"m "+mtime:second+"s.").}
		
		return list(
			{
				SET Steering_Lock TO HEADING(90,90,roll).
				stage.
				return true.
			},
			{
				man_check_stage(stopatstage).
				return ALT:RADAR > 300 or ship:airspeed > 50.
			},
			{
				VES1["gear up"]().
				UI["msg add"]("Commence Pitchover.").
				return true.
			},
			{
				set MyPitch to 90-pitchoverDeg.
				local CurPoint to  ETA:APOAPSIS .
				// local CurPoint to CHOOSE ETA:APOAPSIS if thrByEta else ShipTWR.
				SET Steering_Lock TO HEADING(LAZcalc(launchazdata),MyPitch,roll).
				set newth to th+THRPID:UPDATE(time:seconds, CurPoint)*min(1,(launchalt-ship:apoapsis)/1000).
				// SET th to MIN(1,MAX(newth,MinThrottle)).
				SET th to MIN(1,MAX(newth,0.05)).
				man_check_stage(stopatstage).
				return vcrs(Steering_Lock:VECTOR,SHIP:srfPrograde:VECTOR):mag < 0.01. 
			},
			{
				UI["msg add"]("Steering Unlocked. Gravity Turn Initiated.").
				return true.
			},
			{
				//set MyPitch TO 90 * (1 - ((SHIP:ALTITUDE-TurnStart) / TurnEnd) ^ TurnExponent).
				// SET Steering_Lock to LOOKDIRUP(SHIP:srfPrograde:FOREVECTOR,SHIP:FACING:TOPVECTOR).
				SET Steering_Lock to HEADING(LAZcalc(launchazdata),90-pitchangle(SHIP:srfPrograde),roll).
				
				// print dirangle(SHIP:srfPrograde:FOREVECTOR,"x").
				// print SHIP:srfprograde:pitch.
				local CurPoint to  ETA:APOAPSIS .
				// local CurPoint to CHOOSE ETA:APOAPSIS if thrByEta else ShipTWR.
				set newth to th+THRPID:UPDATE(time:seconds, CurPoint)*min(1,(launchalt-ship:apoapsis)/1000).
				SET th to MIN(1,MAX(newth,0.05)).
				// SET th to MIN(1,MAX(newth,MinThrottle)).
				man_check_stage(stopatstage).
				return SHIP:ALTITUDE > TurnEnd or SHIP:APOAPSIS > launchalt. //If still following the launch curve and desired apoapsis not reached
			},
			{
				SET Steering_Lock TO HEADING(LAZcalc(launchazdata),0,roll).
				IF SHIP:APOAPSIS < launchalt AND SHIP:ALTITUDE >=atmoheight{ //Apoapsis value has dropped due to drag.
						set newth to 1*min(1,(launchalt-ship:apoapsis)/1000).
				} ELSE { //Coasting to Apoapsis.
						set newth to 0.
				}
				SET th to MIN(1,MAX(newth,0)).
				man_check_stage(stopatstage).
				return SHIP:APOAPSIS >= launchalt AND SHIP:ALTITUDE >=atmoheight.
			},
			{
				//**At this point, our apoapsis is above the desired value and our main loop has ended. Next
				//**we'll make sure our throttle is zero and that we're pointed prograde.
				// LOCK THROTTLE TO 0.
				// WAIT 1.
				UNLOCK THROTTLE.
				SET Steering_Lock TO LOOKDIRUP(ship:prograde:forevector, SHIP:BODY:POSITION).
				set waitstart to time:seconds.
				return true.
			},
			{
				return waitstart+10 < time:seconds.
			},
			{
				UNLOCK STEERING.
				UI["msg add"]("Launch Complete.").
				return true.
			}
		).
	}

//#endregion
}