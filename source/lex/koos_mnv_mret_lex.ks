//@lazyglobal off.
//runoncepath(DATAVOLUME+":/lib/koos_mnv_lib"). 
//runoncepath(DATAVOLUME+":/lib/koos_hillclimb_lib"). 
//runoncepath(DATAVOLUME+":/lib/lib_LAZCalc"). 

{
	global MNV_TMP is lexicon(
		//#region Moon Return
		"moon return",			moon_return@,
    "launch no atmo",		launch_no_atmo@
		//#endregion
	).
	
//#region Moon Return
	
	function launch_no_atmo{
		parameter launchalt, launchinc to ship:geoposition:lat.
    local waitstart to 0.
		local th to 1. //Variable for locked throttle.  1.0 is the max, 0.0 is idle.
		local Steering_Lock TO HEADING(90,90). //Variable for locked steering.
		local TurnEnd TO launchalt. //The ending altitude for the ascent turn.
		local TurnExponent TO 0.1. //Turn exponent for curvature. Higher is more vertical.
		local TurnStart TO 0.  //Used to mark the altitude that the ascent turn begins.
		local MyPitch TO 90. //Initial setting for pitch on launch (straight up).
		local launchaz to LAZcalc(LAZcalc_init(launchalt,launchinc)).
		VES1["sas off"]().

		//**Setup Throttle and Steering Locks.
		LOCK THROTTLE TO th.   
		LOCK STEERING TO Steering_Lock. // from now on we'll be able to change steering by just assigning a new value to Steering_Lock		
    if STARTTIME = 0 set STARTTIME to TIME.
    return list(
      {
        SET Steering_Lock TO HEADING(90,90).
        man_check_stage(0).
        return SHIP:VELOCITY:SURFACE:MAG > 50. //Initial launch will be straight up 
      },
      {//**Trigger to mark the altitue the ascent turn begins
        VES1["gear up"]().
        SET TurnStart TO SHIP:ALTITUDE - 10.
        UI["msg add"]("Commence Pitchover.").
        return true.
      },
      {
        set MyPitch TO 90 * (1 - ((SHIP:ALTITUDE-TurnStart) / TurnEnd) ^ TurnExponent).
        SET Steering_Lock TO HEADING(launchaz,MyPitch).
        SET th to 1.
        man_check_stage(0).
        return SHIP:ALTITUDE > TurnEnd or SHIP:APOAPSIS > launchalt. //If still following the launch curve and desired apoapsis not reached
      },
      {
        SET Steering_Lock TO HEADING(launchaz,0).
        IF SHIP:APOAPSIS < launchalt { //Apoapsis value has dropped due to drag.
            set th to 1.
        } ELSE { //Coasting to Apoapsis.
            set th to 0.
        }
        man_check_stage(0).
        return SHIP:APOAPSIS >= launchalt AND SHIP:ALTITUDE >=SHIP:ORBIT:BODY:ATM:HEIGHT.
      },
      {
        //**At this point, our apoapsis is above the desired value and our main loop has ended. Next
        //**we'll make sure our throttle is zero and that we're pointed prograde.
        LOCK THROTTLE TO 0.
        WAIT 1.
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
	
	function moon_return {
		parameter p_peri.
		
    UI["msg add"]("Finding Transfer to "+BODY:OBT:BODY:NAME).
		local m_mu to SHIP:BODY:MU.
		local p_mu to SHIP:BODY:OBT:BODY:MU.
		local m_peri to SHIP:OBT:SEMIMAJORAXIS.
		local m_SOI to SHIP:BODY:SOIRADIUS.
		local p_rad to SHIP:BODY:OBT:BODY:RADIUS.
		local p_tom to SHIP:BODY:ALTITUDE + SHIP:BODY:OBT:BODY:RADIUS.
		local p_tomsoi to p_tom-m_SOI.
		local tgtname to SHIP:BODY:BODY:NAME.
		
		local Vesc to sqrt((2*m_mu)/(m_peri)).
		local vnow to SHIP:VELOCITY:OBT:MAG.

		local Vhoh to sqrt(p_mu*((2/p_tomsoi)-(2/(p_tomsoi+(p_peri+p_rad))))).
		local m_vel to sqrt(p_mu/p_tom).
		local Vinf to m_vel-Vhoh. //craft velocity relative to moon_return
		local Vbo to sqrt(Vinf^2 + Vesc^2).
		local dV to Vbo-vnow.  //have to take into acount how fast we are actually going
		local ecc to (((m_peri*Vbo^2)/m_mu)-1).
		local angburntoeject to arccos(-1/ecc).
    local transtimeUTC to calc_ejection_UTC(angburntoeject).
		// local shippos to ship:orbit:position - ship:body:position.
		// local m_vec_inv to ship:body:body:velocity:orbit. //this is retrograde of moon to parent
		// local angshiptoeject to vang(m_vec_inv,shippos).
		// local angshiptoejectcrs to vcrs(m_vec_inv,shippos).
		// if vdot(v(1,1,1), angshiptoejectcrs) <= 0 {
		// 	set angshiptoeject to -1 * angshiptoeject.
		// }
		// if angshiptoeject < 0 set angshiptoeject to angshiptoeject + 360.
		// local p_AngVel is 2*constant:radtodeg*constant:pi/ship:body:orbit:period.
		// local shipAngVel is 2*constant:radtodeg*constant:pi/ship:orbit:period.
		// local angdiff is angshiptoeject-angburntoeject.
		// if angdiff < 0 set angdiff to angdiff+360.
		// local transtimeUTC to TIME:SECONDS + (angdiff)/ABS(p_AngVel-shipAngVel).
		
		// nodetime to vang(needed position,current position) / current speed + speed of moon
		
		local nd to NODE(transtimeUTC,0,0,dV).
		local hnd is hillclimb(nd, tgtname, list("periapsis",p_peri), 100).
		ADD hnd.
    UI["msg add"]("Moon Return Node Added").
    return true.
  }
	
//#endregion

}