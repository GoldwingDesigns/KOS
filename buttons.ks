@lazyGlobal off.
local monitors to addons:kpm:getmonitorcount().
global monindex to addons:kpm:getguid(0).
local id to addons:kpm:getindexof(monindex).
global mybuttons to addons:kpm:buttons.
global mylabels to addons:kpm:labels.
global myflags to addons:kpm:flags.
mybuttons:setdelegate(10,hello@).
function hello {
parameter x is 9.
print x.
}
mybuttons:setdelegate(0,hello@).
print monitors.
print monindex.
print id.
FROM {local x is 0.} UNTIL x = monitors STEP {set x to x+1.} DO {print x. set mybuttons:currentmonitor to x. set mylabels:currentmonitor to x.
set myflags:currentmonitor to x. mybuttons:setdelegate(0,hello@:BIND(x)). mylabels:setlabel(0,x:tostring).
myflags:setlabel(0,"RUN").
myflags:setstate(0,false). }.
