@lazyGlobal off.
local monitors to addons:kpm:getmonitorcount().
//global monindex to addons:kpm:getguid(0).
//local id to addons:kpm:getindexof(monindex).
global mybuttons to addons:kpm:buttons.
global mylabels to addons:kpm:labels.
global myflags to addons:kpm:flags.
clearscreen.

FROM {local x is 0.} UNTIL x = monitors STEP {set x to x+1.} DO {
  set mybuttons:currentmonitor to x. 
  set mylabels:currentmonitor to x.
  set myflags:currentmonitor to x. 
  FROM {local y is 0.} UNTIL y=14 STEP {set y to y+1.} DO {
    mybuttons:setdelegate(y,toggleFlag@:BIND(y)). 
    mylabels:setlabel(y," LABEL"+y:tostring+" ").
    myflags:setlabel(y,"RUN").
  }
}
function toggleFlag {
  parameter flagNum is 0.
  FROM {local x is 0.} UNTIL x = monitors STEP {set x to x+1.} DO { 
    set myflags:currentmonitor to x. 
    myflags:setstate(flagNum,not (myflags:getstate(flagNum))).
  }
}
function setFlag {
  parameter flagNum, flagState.
  FROM {local x is 0.} UNTIL x = monitors STEP {set x to x+1.} DO { 
    set myflags:currentmonitor to x. 
    myflags:setstate(flagNum,flagstate).
  }
}
UNTIL FALSE {}.