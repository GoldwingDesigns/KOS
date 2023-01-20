@lazyGlobal OFF.

local tgtbod is body.
local tgtalt is 1000000.
local myR is tgtalt + body:radius.
local mye is orbit:eccentricity.
local mya is orbit:semimajoraxis.
local myv is arcCos((mya*(1-mye^2)-myR)/(myR*mye)).
local myvz is orbit:trueanomaly.
local mybige is arcCos((mye+cos(myv))/(1+mye*cos(myv))).
local mybige2 is 360-mybige.
local mybigez is arcCos((mye+cos(myvz))/(1+mye*cos(myvz))).
local myM is (constant:degtorad*mybige) - mye*sin(mybige).
local myM2 is (constant:degtorad*mybige2) - mye*sin(mybige2).
local myMz is (constant:degtorad*mybigez) - mye*sin(mybigez).

local myN is sqrt(tgtbod:mu/(mya^3)).
local myt is (myM-myMz)/myN.
if myt<0 set myt to ((2*constant:pi)-myM-myMz)/myN.
print("myv: "+myv+" myvz: "+myvz+" myt: "+myt).
print("myM: "+mym+" myMz: "+mymz+" myn: "+myn).
print("mybige: "+mybige+" mybige2: "+mybige2+" myM2:"+mym2).

local mynode to NODE(time:seconds+myt,0,0,0).
add mynode.

set kuniverse:timewarp:mode to "Rails".
warpto(time:seconds+myt).

