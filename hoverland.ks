// Name: hoverland.ks
// Author: Trey Del Bonis
// License: MIT
//
// See doHoverLand function.

// Tuning parameters, see calcDescentThrottle for details.  The amount these
// need to vary may depent on engine type.
SET overspeedThresh TO 3.
SET throttleRespDecel TO 1.2.
SET throttleRespAccel TO 0.8.
SET throttleWiggleRoom TO 0.1.

function calcDescentThrottle {
	PARAMETER maxSpeed.

	IF ship:availablethrust = 0 {
		RETURN 0.
	}

	LOCAL maxAcc IS ship:availablethrust / ship:mass.
	LOCAL curGrav IS body:mu / (body:radius + altitude) ^ 2.
	LOCAL eqThrust IS curGrav / maxAcc.

	LOCAL throt IS eqThrust.
	LOCAL speedDiff IS (ship:verticalspeed * -1) - maxSpeed.

	// If we're about to start going up, then don't.
	IF abs(speedDiff) > overspeedThresh {
		SET throt TO eqThrust * 3. // don't overkill it
	}

	// Now here we check to see if we need to increase or decrease.
	IF abs(speedDiff) > throttleWiggleRoom {

		IF speedDiff > 0 {
			SET throt TO eqThrust * throttleRespDecel.
		}

		IF speedDiff < 0 {
			SET throt TO eqThrust * throttleRespAccel.
		}
		
		// Shouldn't normally get here.
	}

	// Clamp max.
	IF throt > 1 {
		RETURN 1.
	}

	// Clamp min.
	IF throt < 0 {
		RETURN 0.
	}

	RETURN throt.
}

SET landedSpeedThresh TO 0.2.

// Does a 2-phase hovering land.  First lets you fall down keeping one max fall
// velocity, then at a certain height lowers to a safer velocity.
//
// Assumes that you already have near-0 surface velocity and that you're
// already moving downwards.  Also assumes you have enough control to stay
// upright.
function doHoverLand {

	PARAMETER fastDropMaxSpeed.
	PARAMETER slowDropMaxSpeed.
	PARAMETER slowDropHeight.
	PARAMETER endHeight.

	LOCK STEERING TO up.
	LOCK THROTTLE TO calcDescentThrottle(fastDropMaxSpeed).

	WAIT UNTIL alt:radar < slowDropHeight.
	PRINT "Switching to slow drop speed.".
	LOCK THROTTLE TO calcDescentThrottle(slowDropMaxSpeed).

	WAIT UNTIL alt:radar < endHeight.
	LOCK THROTTLE TO 0.
	
	WAIT UNTIL abs(ship:verticalspeed) < landedSpeedThresh.
	UNLOCK STEERING.
	UNLOCK THROTTLE.

}

// I with these settings on a 25 kton vessel with 2 nuclear engines on Minmus.
//doHoverLand(5, 1, 30, 12).

