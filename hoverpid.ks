SET hoveralt to 500.


SET Kp TO 0.0006.
SET Ki TO 0.00001.
SET Kd TO 0.008.
SET PID TO PIDLOOP(Kp, Ki, Kd, 0, 1).
SET PID:SETPOINT TO hoveralt.

lock hoverthrot to ((ship:mass * BODY:MU)/(Body:rADIUS ^ 2))/Ship:availablethrust.
lock steering TO HEADING(90,90,90).
SET thrott TO 0.
LOCK THROTTLE TO thrott.
STAGE.

clearscreen.

UNTIL STAGE:Liquidfuel < 35 {
    SET thrott TO hoverthrot + PID:UPDATE(TIME:SECONDS, SHIP:altitude).
    set PID:maxoutput to 1-hoverthrot.
    set PID:minoutput to hoverthrot * -1.
    printat("Kp: " + PID:pterm + " ki: " + PID:iterm + " kd: " + PID:dterm + " hthrot " + hoverthrot,1,1).
    WAIT 0.001.
}

Set PID:setpoint to 500.

UNTIL STAGE:Liquidfuel < 5 {
    SET thrott TO hoverthrot + PID:UPDATE(TIME:SECONDS, SHIP:altitude).
    set PID:maxoutput to 1-hoverthrot.
    set PID:minoutput to hoverthrot * -1.
    printat("Kp: " + PID:pterm + " ki: " + PID:iterm + " kd: " + PID:dterm + " hthrot " + hoverthrot,1,1).
    WAIT 0.001.
}

LOCK THROTTLE TO 0.
unlock Throttle.
STAGE.