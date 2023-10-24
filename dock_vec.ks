set tgt_ship to vessel("Station - 1").

clearVecDraws().
SET B TO tgt_ship:BOUNDS. 
set vd to vecdraw({return tgt_ship:position.},{return b:absmin.},green,"absmin",1,true). 
set vs to vecdraw({return tgt_ship:position.},{return b:absmax.},red,"absmax",1,true).  
set vp to vecdraw({return tgt_ship:position.},{return ship:position-tgt_ship:position.},blue,"shippos",1,true).
set vf to vecdraw({return tgt_ship:position.},{return b:furthestcorner(ship:position-tgt_ship:position).},white,"furthest",1,true).

//
//
local top is B:furthestcorner(up:vector).
local bottom is B:furthestcorner(-up:vector).
set vt to vecdraw({return tgt_ship:position.},{return top.},red,"top",1,true). 
set vb to vecdraw({return tgt_ship:position.},{return bottom.},red,"bottom",1,true). 
local from_other_to_me is ship:position - tgt_ship:position.
local nearest is B:furthestcorner(from_other_to_me).
print "The closest point on the other vessel's bounds box is this far away:".
print nearest:mag.

// A more complex example showing how you might use bounds boxes
// when trying to figure out how big a target vessel is so you
// know how to go around it:
//
local my_left is -ship:facing:starvector.
local leftmost is B:furthestcorner(my_left).
print "In order to go around the other vessel, to the left, ".
print "I would need to shift myself this far to my left:".
print vdot(-ship:facing:starvector, leftmost).


until false{}.