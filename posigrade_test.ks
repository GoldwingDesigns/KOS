clearScreen.
clearVecDraws().
local i is 0.
local dummy is false.
local vd is vecDraw(V(0,0,0),{return vcrs(SHIP:VELOCITY:orbit:normalized,ship:Body:position).},red,"mydir",10,true).
local wd is vecDraw(v(0,0,0),{return SHIP:BODY:ANGULARVEL:normalized.},blue,"bodyangular",10,true).
local xd is vecDraw(v(0,0,0),{return SHIP:prograde:vector:normalized.},yellow,"prog",10,true).
UNTIL (dummy){
  if (isPosigrade()) { print "posigrade  " + i at (0,0).} else{print "retrograde "+i at(0,0).}. set i to i+1.
}.

function isPosigrade {
  return vdot(vcrs(SHIP:VELOCITY:orbit:normalized,ship:Body:position),SHIP:BODY:ANGULARVEL:normalized)>0.
}