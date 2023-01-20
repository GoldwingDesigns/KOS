clearscreen.
set radarOffset to 4.1.	 				// The value of alt:radar when landed (on gear)
lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear

lock totvec to ship:velocity:surface.


// SET totarrow TO VECDRAW(
//       V(0,0,0),
//       { return ship:velocity:surface. },
//       yellow,
//       "surf vel",
//       1.0,
//       TRUE,
//       0.2,
//       TRUE,
//       TRUE
//     ).

// Set xarrow To VECDRAW(
//       V(0,0,0),
//       { return V(totvec:x,0,0). },
//       red,
//       "x",
//       1.0,
//       TRUE,
//       0.2,
//       TRUE,
//       TRUE
//     ).

// Set yarrow To VECDRAW(
//       V(0,0,0),
//       { return V(0,totvec:y,0). },
//       green,
//       "y",
//       1.0,
//       TRUE,
//       0.2,
//       TRUE,
//       TRUE
//     ).
// Set zarrow To VECDRAW(
//       V(0,0,0),
//       { return V(0,0,totvec:z). },
//       blue,
//       "z",
//       1.0,
//       TRUE,
//       0.2,
//       TRUE,
//       TRUE
//     ).
	
// lock throttle to 1.
// // lock steering TO HEADING(180,80).
// lock steering to srfretrograde.
// // lock steering to lookdirup(ship:srfretrograde,vcrs(body:position,ship:srfRetrograde)).
// stage.

// Wait until ship:orbit:apoapsis > 2000.
// 	lock throttle to 0.
// 	lock steering TO UP.
// 	unlock throttle.
	
WAIT UNTIL ship:verticalspeed < -1.
	print "Preparing for hoverslam...".
  sas off.
	rcs on.
	brakes on.
	lock steering to srfretrograde.
	when impactTime < 3 then {gear on.}

WAIT UNTIL trueRadar < stopDist.
	print "Performing hoverslam".
	lock throttle to idealThrottle.

WAIT UNTIL ship:verticalspeed > -0.01.
	print "Hoverslam completed".
	unlock throttle.
	unlock steering.
	clearvecdraws().
	set ship:control:pilotmainthrottle to 0.
	rcs off.