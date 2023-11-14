@lazyglobal off.

function man_check_stage{
  parameter laststage to VES1["&lastengine"]().
  //local press to MAX(0,MIN(1,ship:body:atm:altitudepressure(ship:altitude))).
  if stage:number > laststage {
    if ship:maxthrust = 0 {
      WAIT 1.
      if ship:maxthrust = 0 {
        UI["msg add"]("Stage: "+stage:number+" no thrust.").
        VES1["stage"]().
      }
    } else {
			local numEngOut to 0.
			local numEngOn to 0.
			local numEngOther to 0.
			// local engName to "".
			local myengines to list().
			LIST ENGINES IN myengines. 
			local stagenum is STAGE:NUMBER.
			FOR eng IN myengines {
				if eng:stage = stagenum{
				IF eng:FLAMEOUT {
					SET numEngOut TO numEngOut + 1.
					// set engName to eng:title.
				}
				IF eng:maxThrust>0 and eng:allowshutdown set numEngOn to numEngOn + 1. //rules out SRBs
				}
			}
			if numEngOut > 0 { 
				// UI["msg add"]("Stage: "+stagenum+" eng: "+engName+" flameout. "+numEngOn+" engines remain."). 
				if numEngOn<1 and numEngOther>1 VES1["stage"](). 
			}
  	}
	}
}
function find_burntime {
		parameter inputDV, stagenum to STAGE:NUMBER.
		local Mi to SHIP:MASS.
		local stageDV to ship:STAGEDELTAV(stagenum):CURRENT.
		UI["msg add"]("Calculated STAGEDV for stage "+stagenum+" is: "+stageDV).
		local Go to 9.80665.
		local englist is list().
		list engines in englist.
		local engISP to 0.1.
		local engT to 0.1.
		for e in englist {
			if e:stage = stagenum {
				set engISP to engISP + e:VISP.
				set engT to engT + e:possibleThrust.
			}
		}
		if stageDV > inputDV {
			return inputDV/(engT * (((Mi + (Mi * (constant:e ^ (-1 * (inputDV / (engISP * Go) )))))/2) ^ (-1))).
		} else {
			if (stagenum = 0) {
				UI["msg add"]("Not enough DV. ").
				print 0/1.
			}
			else {
				return stageDV/(engT * (((Mi + (Mi * (constant:e ^ (-1 * (stageDV / (engISP * Go) )))))/2) ^ (-1))) + find_burntime(inputDV-stageDV, max(stagenum-1,0)).
			}
			
		}
	}
	
