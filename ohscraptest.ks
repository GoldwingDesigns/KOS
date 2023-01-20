@lazyglobal off.

function checkFailure {
FOR P IN SHIP:PARTS {
	if P:MODULES:contains("ModuleUPFMEvents"){
		set upfmmod to P:getmodule("ModuleUPFMEvents").
		if (upfmmod:allevents:length > 1){
			for ev in upfmmod:allevents {
				if ev:contains("failure") { Print(P:TITLE + " has failed"). }
			}
		}
	}
}
}
