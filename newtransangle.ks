//copied from reddit user 
local tgtMoon to BODY("mun").
local tgtOffset to 0.
//local tgtOffset to tgtMoon:radius + 40000.
//local tgtOffset to tgtMoon:soiradius/5.
local T2 is tgtMoon:obt:period.
local A2 is tgtMoon:obt:semimajoraxis.

// periapsis height of the transfer orbit is your altitude
// apoapsis height of the transfer orbit is tgtMoon's altitude
// so we can calculate SMA of the transfer orbit
local A1 is (SHIP:obt:semimajoraxis + (tgtMoon:obt:semimajoraxis - tgtOffset))/2.

// 3rd Kepler's law tells us that (A1/A2)^3 = (T1/T2)^2
// where T1 is period of transfer orbit
// so T1 = T2 * (A1/A2)^1.5
local T1 is T2 * (A1/A2)^1.5.

// now we can calculate the angle between tgtMoon's position at the start of the transfer
// and at the end of the transfer
local aa is mod(((T1*0.5)/T2)*360, 360).
//local aa is mod(360*(T1/T2), 360).

// the angle we are looking for is 180-alpha
// or 360-alpha if you are using angles in range [0..360]
local transferAngle is 180 - aa.

//until false{
clearscreen.
LIST targets in ALL_VESSELS.	
for vess in ALL_VESSELS{
		print vess:name.
	}
print("tgtOffset: "+tgtOffset).
print("transangle: " + transferAngle).

//copied from reddit user ollieshmollie and toukiedatak
print("sma: "+tgtMoon:obt:semimajoraxis).
print("alt: "+tgtMoon:altitude+BODY:radius).
local shippos to ship:orbit:position - ship:body:position.
local tgtMoonpos to tgtMoon:orbit:position - tgtMoon:body:position.
local phaseangle to vang(tgtMoonpos,shippos).
local phaseanglecrs to vcrs(tgtMoonpos,shippos).
  if vdot(v(1,1,1), phaseanglecrs) <= 0 {
    set phaseangle to -1 * phaseangle.
  }

print("phaseang: "+phaseangle).
print("ship T: "+ship:orbit:period).
print("tgtMoon T: "+tgtMoon:orbit:period).
//local tgtAngVel is tgtMoon:angularvel:mag * constant:radtodeg.
local tgtAngVel is 2*constant:radtodeg*constant:pi/tgtMoon:orbit:period.
print("tgtMoon ang vel: "+tgtAngVel).
//local shipAngVel is (SQRT(BODY:MU / ((ship:altitude + BODY:radius)^3)))* constant:radtodeg.
local shipAngVel is 2*constant:radtodeg*constant:pi/ship:orbit:period.
print("ship ang vel: "+shipAngVel).
local angdiff is phaseangle-transferAngle.
if angdiff < 0 set angdiff to angdiff+360.
print("angdiff: "+angdiff).
local transtime to (angdiff)/ABS(tgtAngVel-shipAngVel).
print("transtime: "+transtime).

//find DeltaV
local thisMU to BODY:MU.
local thisR to SHIP:obt:semimajoraxis.
//local nextA to BODY:RADIUS + ((SHIP:APOAPSIS + A2)/2).
local nextA to (SHIP:obt:semimajoraxis + (tgtMoon:obt:semimajoraxis - tgtOffset))/2.
local thisDV to SQRT(thisMU * (2/thisR - 1/nextA)) - SQRT(thisMU/thisR).
//local tgtMoonOrbVel is SQRT(tgtMoon:MU/tgtOffset).
print ("DV required: "+thisDV).
//print ("Mun mu: "+Mun:MU).
//print("Minmus mu: "+Minmus:MU).
//print ("tgtMoon Orbit Vel:"+tgtMoonOrbVel).

local nd to NODE(TIME:SECONDS + transtime,0,0,thisDV).
ADD nd.
	
//}