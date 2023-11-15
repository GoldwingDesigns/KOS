@lazyglobal off.

{
	global MNV_TMP is lexicon(
    //#region Reentry
   	"aero land",			aero_ldg@
		//#endregion
	).
	
//#region Reentry
	function aero_ldg {
			parameter laststage to VES1["&lastchute"]@.
			local steervec to lookDirUp(-1*ship:velocity:orbit,-1*body:position).
			lock steering to steervec.
			local waitstart to 0.
			VES1["sas off"]().
			UI["msg add"]("Commence Aero Land Program.").
			
			return list(
				{ return ship:altitude < 200000.
				},
				{
					set steervec to lookDirUp(vcrs(body:position,ship:velocity:orbit),-1*body:position).
					return abs(vdot(vcrs(body:position,ship:velocity:orbit):normalized,ship:facing:vector:normalized)) > 0.98.
				},
				{
					wait 1.
					if stage:ready and stage:number > laststage {
						VES1["stage"]().
						return false.
					} else {
						if stage:number > laststage {return false.} else {return true.} 
					}
				},
				{ //this is same as "ship sep" in the vessel lib.  consider how to put this there.
					VES1["rcs on"](). 
					return true.
				},
				{
					set ship:control:fore to 1.
					set waitstart to time:seconds.
					return true.
				},
				{
					return waitstart+3 < time:seconds.
				},
				{
					set ship:control:neutralize to true.
					set waitstart to time:seconds.
					return true.
				},
				{
					return waitstart+10 < time:seconds.
				},
				{
					VES1["rcs off"]().
					return true.
				},
				{
					set steervec to lookDirUp(-1*ship:velocity:surface,-1*body:position).
					return true.
				},
				
				{ 
					VES1["comms ret"]().
					return true.
				},
				{
					set steervec to lookDirUp(-1*ship:velocity:surface,-1*body:position).
					return alt:radar < 20000 and ship:airspeed < 280. //to protect parachutes
				},
				{
					unlock steering.
					return true.
				},
				{
					VES1["arm chutes"]().
					// if (not chutesSafe){
					// 	chutesSafe on.
					// }
					// return chutes.
					return true.
				},
				{
					return SHIP:STATUS = "SPLASHED" or SHIP:STATUS = "LANDED".
				},
				{
					if addons:available("scansat"){
						if ship:status = "SPLASHED" {
							UI["msg add"](ship:name+" splashed down on "+ship:body:name+". L/L: "+ship:geoposition:lat+", "+ship:geoposition:lng+" Biome: "+addons:scansat:currentbiome).
						}
						if ship:status = "LANDED" {
							UI["msg add"](ship:name+" landed on "+ship:body:name+". L/L: "+ship:geoposition:lat+", "+ship:geoposition:lng+" Biome: "+addons:scansat:currentbiome).
						}
					}
					else {
						if ship:status = "SPLASHED" {
							UI["msg add"](ship:name+" splashed down on "+ship:body:name+". L/L: "+ship:geoposition:lat+", "+ship:geoposition:lng).
						}
						if ship:status = "LANDED" {
							UI["msg add"](ship:name+" landed on "+ship:body:name+". L/L: "+ship:geoposition:lat+", "+ship:geoposition:lng).
						}
					}
					return true.
				}
			).
				
		}
//#endregion
}