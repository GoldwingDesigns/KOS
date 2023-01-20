run koos_maneuvers.ks.

// local nd to NODE(TIME:SECONDS + 60000,0,0,1000).
local tgt to BODY("Minmus").
// ADD nd.
	// WAIT 0.1.
// print cpa(tgt,nd).
// REMOVE nd.

print seperation_at(tgt,TIME:SECONDS+NEXTNODE:ETA+1).