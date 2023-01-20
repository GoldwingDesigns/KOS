run koos_maneuvers.
run lib_gui_dummy.
local tgt to LATLNG(-2,28).
local rdroffset to 5.5.
SET CONFIG:TELNET TO TRUE.
GLOBAL MSGQ to QUEUE(). 
GLOBAL STARTTIME to 0.
GLOBAL COMPMODE to 0.
GLOBAL CPUINITIALIZED to 0.
GLOBAL WARNSTATE to 0.
GLOBAL INMENU to FALSE.

clearVecDraws().
landing_align_burn(tgt).
pwrlanding(rdroffset, tgt, 0).
ladders on.
wait 10.
ladders off.
wait 10.
launch(20000,0,true).
exec_node().
gear off.
Wait 10.
moon_return(40000).
exec_node().