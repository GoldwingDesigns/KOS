// @lazyglobal off.

local tgt to LATLNG(10.3633909,19.2129650).

lock surfvec to SHIP:VELOCITY:SURFACE.
lock tgtvec to tgt:ALTITUDEPOSITION(SHIP:ALTITUDE) -SHIP:POSITION.

Set varw To VECDRAW(
      V(0,0,0),
      { return surfvec. },
      red,
      "v",
      1.0,
      TRUE,
      0.2,
      TRUE,
      TRUE
    ).
	
Set tarw To VECDRAW(
      V(0,0,0),
      { return tgtvec. },
      green,
      "t",
      1.0,
      TRUE,
      0.2,
      TRUE,
      TRUE
    ).
	
WAIT UNTIL FALSE.