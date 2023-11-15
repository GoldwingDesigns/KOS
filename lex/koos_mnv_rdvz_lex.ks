@lazyglobal off.
runOncePath(DATAVOLUME+":/lib/koos_mnv_lib"). 
runOncePath(DATAVOLUME+":/lib/koos_hillclimb_lib"). 

{
	global MNV_TMP is lexicon(
    //#region Rdvz
    "cancel vel cpa", cancel_rel_vel_at_cpa@,
    "ship transfer", ship_trans@
		//#endregion
    ).
	
	//#region Rdvz

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
		local transtimeUTC to TIME:SECONDS + (angdiff)/ABS(tgtAngVel-shipAngVel).
		local initialV to sqrt(planetMU/oldSMA).
		local finalV to sqrt(planetMU*(2/oldSMA-1/atx)).
		local thisDV to finalV - initialV.
		local nd to NODE(transtimeUTC,0,0,thisDV).
		local hnd is hillclimb(nd, tgt, list("shiptoship",distance), 20).
		ADD hnd.
		return true.
	}
  
//#endregion
}