//copied from reddit user 

local T2 is Mun:obt:period.
local A2 is Mun:obt:semimajoraxis.

// periapsis height of the transfer orbit is your altitude
// apoapsis height of the transfer orbit is Mun's altitude
// so we can calculate SMA of the transfer orbit
local A1 is Kerbin:radius + (ship:altitude + Mun:altitude)/2.

// 3rd Kepler's law tells us that (A1/A2)^3 = (T1/T2)^2
// where T1 is period of transfer orbit
// so T1 = T2 * (A1/A2)^1.5
local T1 is T2 * (A1/A2)^1.5.

// now we can calculate the angle between Mun's position at the start of the transfer
// and at the end of the transfer
//local aa is mod(((T1*0.5)/T2)*360, 360).
local aa is mod(360*(T1/T2), 360).

// the angle we are looking for is 180-alpha
// or 360-alpha if you are using angles in range [0..360]
local transferAngle is 360 - aa.

until false{
clearscreen.
print("transangle: " + transferAngle).

//copied from reddit user ollieshmollie
local shippos to ship:orbit:position - ship:body:position.
local munpos to mun:orbit:position - mun:body:position.
local phaseangle to vang(shippos,munpos).
local phaseanglecrs to vcrs(shippos,munpos).
  if vdot(v(1,1,1), phaseanglecrs) <= 0 {
    set phaseAngle to 360 - phaseAngle.
  }
// print("shippos: "+shippos:MAG).
// print("shipvec: "+ shippos:normalized).
// print("munpos: "+munpos:MAG).
// print("munpos: "+munpos:normalized).
// print("velocities: "+vcrs(Mun:VELOCITY:SURFACE:normalized,Ship:VELOCITY:SURFACE:normalized)).
// print("vdot: "+vdot(shippos,phaseangle)).
print("phaseang: "+phaseAngle).
// print(mun:BODY:ALTITUDEOF(SHIP:POSITION)).
local shipangvel is 2*constant:pi/ship:orbit:period.
print("calc ang vel: "+shipangvel* constant:radtodeg).
print(ship:angularvel:mag * constant:radtodeg).
print("ship T: "+ship:orbit:period).
print("mun T: "+mun:orbit:period).
print(mun:angularvel:mag * constant:radtodeg).
local angdiff is transferAngle-phaseangle.
if angdiff < 0 set angdiff to angdiff+360.
print("angdiff: "+angdiff).
local transtime to (angdiff)/(mun:angularvel:mag*constant:radtodeg-ship:angularvel:mag*constant:radtodeg).
// local transtime to (angdiff)/(shipangvel-mun:angularvel:mag*constant:radtodeg).

print(transtime).
// if transtime < 0 { set transtime to transtime * -1. }
// local nd to NODE(TIME:SECONDS + transtime,0,0,840).
	// ADD nd.
	
}