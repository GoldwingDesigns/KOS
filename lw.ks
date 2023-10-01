@lazyGlobal off.

local lwlist is findLaunchWindow(60,target).
print "launch time is: "+lwlist[0].
print "launch inclination is: "+lwlist[1].
warpto(lwlist[0]).

function findLaunchWindow {
    parameter leadTime is 60, myTarget is target.
    local lt is leadTime/3600.
    local launchTimeSec is 0.
    local bodyperiodinhours is body:rotationperiod/60/60.
    local rotdegperhour is 360/(bodyperiodinhours).
    print rotdegperhour.
    local alpha is myTarget:orbit:inclination.
    local raan is myTarget:orbit:lan.
    local lat is ship:latitude.
    local long is ship:longitude.
    local lst to (mod(ship:body:rotationangle + mod((360+long),360),360))/rotdegperhour.
    if abs(alpha) < abs(lat) {
      print "Unable match target inclination.".
    } else if alpha=abs(lat){
      local l is (raan+90)/rotdegperhour.
      set launchTimeSec to time:seconds+(mod(l-lst+bodyperiodinhours,bodyperiodinhours)*3600).
      return list(launchTimeSec,alpha).
    } else {
      local gamma is arcsin(cos(alpha)/cos(lat)).
      local delta is arccos(cos(gamma)/sin(alpha)).
      local lwstan is 0.
      local lwstdn is 0.
      local case is 0. //case 0 is north prograde, case 1 is south prograde or north retrograde, case 2 is south retrograde
      if lat < 0 set case to case + 1.
      if alpha > 90 or alpha < -90 set case to case + 1.
      if case = 0 {
        set lwstan to raan - delta.
        set lwstdn to raan + (180 + delta).
      } else {
        set lwstan to raan + delta.
        set lwstdn to raan + (180-delta).
      }
      local l1 is lwstan / rotdegperhour.  //60 used for kerbin, need to figure out for other bodies
      local l2 is lwstdn / rotdegperhour.
      print "l1 is: "+ l1.
      print "l2 is: "+ l2.
      print "lst is: "+ lst.

      local a is alpha.
      local ltemp is 0.
      if lst+lT > l1 and lst+lT < l2 {
        // print "choose l2".
        set a to -1 * a.
        set ltemp to l2-lst.
        until ltemp > 0  set ltemp to ltemp+bodyperiodinhours.
        set launchTimeSec to time:seconds+(mod(ltemp+bodyperiodinhours,bodyperiodinhours)*3600). // change 6 to rotation of body in hrs
      } else {
        // print "choose l1".
        set ltemp to l1-lst.
        until ltemp > 0  set ltemp to ltemp+bodyperiodinhours.
        set launchTimeSec to time:seconds+(mod(ltemp+bodyperiodinhours,bodyperiodinhours)*3600).
      }
      return list(launchTimeSec, a).
    }
}