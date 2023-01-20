@lazyglobal off.
run lib_gui_box.

local termheight to terminal:height.
local termwidth to terminal:width.
local midline to termwidth/2.
local currmenutitle to "".  // have to store this here just in case of resize screen
local currmenulist to list(). // have to store this here just in case of resize screen

function menu_run{

	if COMPMODE = 0 { // On Surface
		return menu_list("Program:",list("Launch","Utilities")).
	}
	else if COMPMODE = 1 {// Suborbital
		return menu_list("Program:",list("Inclination","Exec Nxt Node","Utilities")).
	} 
	else if COMPMODE = 2 {// Orbital
		if SHIP:ORBIT:ECCENTRICITY < .002 {
			return menu_list("Program:",list("Circularize","Inclination","Change Ap","Change Pe","Hohmann Transfer","Target Transfer","Exec Nxt Node","Reentry","Utilities")).
		}
		else return menu_list("Program:",list("Circularize","Inclination","Change Ap","Change Pe","Exec Nxt Node","Reentry","Utilities")).
	} 
	else if COMPMODE = 3 {// Has next patch
		return menu_list("Program:",list("Capture","Inclination","Change Pe","Exec Nxt Node","Reentry","Utilities")).
	} 
	else if COMPMODE = 4 {//fly-by
		return menu_list("Program:",list("Capture","Inclination","Change Pe","Exec Nxt Node","Reentry","Utilities")).
	} 
	else if COMPMODE = 9 {// In Maneuver
		print ("Maneuver Mode"):PADRIGHT(midline-3) AT (2,2).
		menu_clr().
		// local result is input_pos_int().
		// print(result).
		// if result = 99 {
			// PRINT "OKAY" AT (4,termheight-3).
		// }
		
		return.
	}
	else if COMPMODE = 99 {// Abort Maneuver
		print ("!ABORTING MANEUVER!"):PADRIGHT(midline-3) AT (2,2).
		menu_clr().
		return.
	}
}

function menu_clr{
	local i is 0.
	local str is "".
		until i=9
		{
			print str:PADRIGHT(midline-3) at(2,i+4).
			set i to i+1.
		}
}

function menu_list{
	parameter listtitle.
	parameter list_of_names.
	
	set INMENU to TRUE.
		
	if list_of_names:empty{
		print "error: list_of_names should not be empty". print 1/0.
	}
	set currmenutitle to listtitle.
	set currmenulist to list_of_names.
	local len is list_of_names:length().
	
	menu_print().
	
	local result is input_pos_int().
	// print(result).
	until result <= len {
		PRINT "ERROR: INPUT OUT OF RANGE" AT (4,termheight-3).
		WAIT 1.
		set result to input_pos_int().
	}
	set INMENU to FALSE.
	
	set currmenutitle to "".  //clear these out for next use
	set currmenulist to list(). // clear these out for next use
	return list_of_names[result].
}

function menu_print{
	menu_clr().
	local len is currmenulist:length().


	print currmenutitle:PADRIGHT(midline-3) at(2,2).
	local i is 0.

	until i=len
	{
		print i+") "+currmenulist[i] at(2,i+4).
		set i to i+1.
	}
}

function menu_prompt_pos_int{
	parameter prompt.
	menu_clr().
	print prompt:PADRIGHT(midline-3) at(2,2).
	return input_pos_int().
}

function menu_prompt_float{
	parameter prompt.
	menu_clr().
	print prompt:PADRIGHT(midline-3) at(2,2).
	return input_pos_float().
}

function menu_prompt_yn{
	// prompt for yes or no question args strthequestion
	parameter prompt.
	menu_clr().
	print (prompt+" (Y/N)"):PADRIGHT(midline-3) at(2,2).
	return input_yn().
}

function splashscreen {
	clearscreen.
	local startrow is termheight/2-5.
	local startcol is termwidth/2-29.
	print("         _              _            _            _       ") AT (startcol,startrow).
	print("        /\_\           /\ \         /\ \         / /\     ") AT (startcol,startrow+1).
	print("       / / /  _       /  \ \       /  \ \       / /  \    ") AT (startcol,startrow+2).
	print("      / / /  /\_\    / /\ \ \     / /\ \ \     / / /\ \__ ") AT (startcol,startrow+3).
	print("     / / /__/ / /   / / /\ \ \   / / /\ \ \   / / /\ \___\") AT (startcol,startrow+4).
	print("    / /\_____/ /   / / /  \ \_\ / / /  \ \_\  \ \ \ \/___/") AT (startcol,startrow+5).
	print("   / /\_______/   / / /   / / // / /   / / /   \ \ \      ") AT (startcol,startrow+6).
	print("  / / /\ \ \     / / /   / / // / /   / / /_    \ \ \     ") AT (startcol,startrow+7).
	print(" / / /  \ \ \   / / /___/ / // / /___/ / //_/\__/ / /     ") AT (startcol,startrow+8).
	print("/ / /    \ \ \ / / /____\/ // / /____\/ / \ \/___/ /      ") AT (startcol,startrow+9).
	print("\/_/      \_\_\\/_________/ \/_________/   \_____\/       ") AT (startcol,startrow+10).
	wait 0.1.
	clearscreen.                                                   
}
	
function data_update{
	local data_alt to ROUND(SHIP:ALTITUDE,1):TOSTRING.
	local data_vel to ROUND(SHIP:VELOCITY:SURFACE:MAG,1):TOSTRING.
	local data_apo to ROUND(SHIP:ORBIT:APOAPSIS/1000,1):TOSTRING.
	local data_per to ROUND(SHIP:ORBIT:PERIAPSIS/1000,1):TOSTRING.
	local data_inc to ROUND(SHIP:ORBIT:INCLINATION,1):TOSTRING.
	local data_ecc to ROUND(SHIP:ORBIT:ECCENTRICITY,3):TOSTRING.
	local data_bod to SHIP:ORBIT:BODY:NAME:TOSTRING.
	print "Alt:  " AT (midline+1, 3). print data_alt:PADLEFT(midline - 10) AT (midline+7,3).
	print "Vel:  " AT (midline+1, 4). print data_vel:PADLEFT(midline - 10) AT (midline+7,4).
	print "Body: " AT (midline+1, 5). print data_bod:PADLEFT(midline - 10) AT (midline+7,5).
	print "Ap:   " AT (midline+1, 6). print data_apo:PADLEFT(midline - 10) AT (midline+7,6).
	print "Pe:   " AT (midline+1, 7). print data_per:PADLEFT(midline - 10) AT (midline+7,7).
	print "Inc:  " AT (midline+1, 8). print data_inc:PADLEFT(midline - 10) AT (midline+7,8).
	print "Ecc:  " AT (midline+1, 9). print data_ecc:PADLEFT(midline - 10) AT (midline+7,9).
	if HASNODE {
	local data_node to NEXTNODE.
	local data_node_eta to ROUND(data_node:ETA,0):TOSTRING.
	local data_node_dv to ROUND(data_node:DELTAV:MAG,1):TOSTRING.
	local data_node_apo to ROUND(data_node:ORBIT:APOAPSIS/1000,1):TOSTRING.
	local data_node_per to ROUND(data_node:ORBIT:PERIAPSIS/1000,1):TOSTRING.
	local data_node_inc to ROUND(data_node:ORBIT:INCLINATION,1):TOSTRING.
	local data_node_ecc to ROUND(SHIP:ORBIT:ECCENTRICITY,3):TOSTRING.
	print ("--Next Node--"):PADRIGHT(midline-3) AT (midline+1,13).
	print "ETA:  " AT (midline+1, 14). print data_node_eta:PADLEFT(midline - 10) AT (midline+7,14).
	print "dV:   " AT (midline+1, 15). print data_node_dv:PADLEFT(midline - 10) AT (midline+7,15).
	print "Ap:   " AT (midline+1, 16). print data_node_apo:PADLEFT(midline - 10) AT (midline+7,16).
	print "Pe:   " AT (midline+1, 17). print data_node_per:PADLEFT(midline - 10) AT (midline+7,17).
	print "Inc:  " AT (midline+1, 18). print data_node_inc:PADLEFT(midline - 10) AT (midline+7,18).
	print "Ecc:  " AT (midline+1, 19). print data_node_ecc:PADLEFT(midline - 10) AT (midline+7,19).
	}	
}

function data_clr_node {
	local i is 0.
	until i > 6 {
		print (""):PADRIGHT(midline-3) AT (midline+1,i+13).
		set i to i+1.
	}
} 

function msg_update{
	local tmpstring to "".
	local line0 to termheight-5.
	local line1 to termheight-4.

	local i to 0.
	until i = MSGQ:LENGTH
	{
		set tmpstring to MSGQ:POP().
		print tmpstring:PADRIGHT(termwidth - 4) AT (2,line0+i).
		MSGQ:PUSH(tmpstring).
		set i to i+1.
	}
}

function msg_add{
	parameter msg.
	until MSGQ:LENGTH < 2
	{
		MSGQ:POP().
	}
	set msg to get_met_time() + " " + msg.
	MSGQ:PUSH(msg).
}

function get_met_time{ //time calc borrowed from u/ElWanderer_KSP
	LOCAL ts IS TIME + MISSIONTIME - TIME:SECONDS.
	RETURN "T+" 
    + pad_time(ts:YEAR - 1) + "-" // subtracts 1 to get years elapsed, not game year
    + pad_time(ts:DAY - 1,3) + " " // subtracts 1 to get days elapsed, not day of year
    + pad_time(ts:HOUR) + ":"
    + pad_time(ts:MINUTE) + ":"
    + pad_time(ROUND(ts:SECOND)).
}	  

FUNCTION pad_time { //borrowed from u/farsyte
	PARAMETER t, l is 2.
    RETURN (""+t):PADLEFT(l):REPLACE(" ","0").
}

function scr_init{
	clearscreen.
	//check to make sure term is not impossibly small
	if terminal:width < 60
	{
		set terminal:width to 60.
	}
	if terminal:height < 30
	{
		set terminal:height to 30.
	}
	splashscreen().
	set termheight to terminal:height.
	set termwidth to terminal:width.
	set midline to termwidth/2.
	draw_gui_box(0, 0, midline, termheight-5).
	draw_gui_box(midline-1, 0, midline, termheight-5).
	draw_gui_box(0, termheight-6, midline*2-1, 5).
	print ">" AT (2,termheight-3).
	data_update().
	msg_update().
	msg_add("Boot complete.").
}

function scr_update{
	if (termheight <> terminal:height) or (termwidth <> terminal:width) { scr_resized(). }
	data_update().
	msg_update().
	//fail_msg().
	
}

function scr_resized{
	clearscreen.
	//check to make sure term is not impossibly small
	if terminal:width < 30
	{
		set terminal:width to 30.
	}
	if terminal:height < 20
	{
		set terminal:height to 20.
	}
	set termheight to terminal:height.
	set termwidth to terminal:width.
	set midline to termwidth/2.
	draw_gui_box(0, 0, midline, termheight-5).
	draw_gui_box(midline-1, 0, midline, termheight-5).
	draw_gui_box(0, termheight-6, midline*2-1, 5).
	print ">" AT (2,termheight-3).
	if INMENU { menu_print(). }
}

function input_pos_int{
	local charQ to QUEUE().
	local j is 0.
	local charstring to "".
	local tempchar to "".
	local termheight to termheight.
	local termwidth to termwidth.
	until false{
		if CPUINITIALIZED {scr_update().}
		if Terminal:INPUT:HASCHAR(){
			local ch to Terminal:Input:Getchar().
			// print unchar(ch).
				if ch = Terminal:Input:BACKSPACE {
					if charQ:LENGTH > 0 {
						set j to 0.
						set charstring to "".
						until j=charQ:LENGTH-1{
							set tempchar to charQ:POP.
							set charstring to charstring+tempchar.
							charQ:PUSH(tempchar).
							set j to j+1.
						}
						charQ:POP.
						print charstring + " " AT (4,termheight-3).
					}
				} 
				else if ch = Terminal:Input:RETURN {
					IF charstring = "" {print "FAIL" AT (30,30).} //if empty dont do anything
					else {	break. } //else submit the charstring
				} 
				else if unchar(ch) >= 48 AND unchar(ch) <= 57 { 
				charQ:PUSH(ch).
				set charstring to charstring+ch.
				print charstring AT (4,termheight-3).
			}	
		}
		wait 0.1.
	}
	set tempchar to "".
	print tempchar:PADRIGHT(termwidth-6) AT (4,termheight-3).
	return charstring:TOSCALAR.
}	

function input_pos_float{
	local charQ to QUEUE().
	local j is 0.
	local charstring to "".
	local tempchar to "".
	local termheight to termheight.
	local termwidth to termwidth.
	local decimalset is 0.
	until false{
		if CPUINITIALIZED {scr_update().}
		if Terminal:INPUT:HASCHAR(){
			local ch to Terminal:Input:Getchar().
			//print unchar(ch).
			if ch = Terminal:Input:BACKSPACE {
				if charQ:LENGTH > 0 {
					set j to 0.
					set charstring to "".
					until j=charQ:LENGTH-1{ //rewrite charstring to one less character than before
						set tempchar to charQ:POP.
						set charstring to charstring+tempchar.
						charQ:PUSH(tempchar).
						set j to j+1.
					}
					charQ:POP. //take the deleted character off the stack
					if charQ:LENGTH < decimalset set decimalset to 0. //deleted decimal point
					print charstring + " " AT (4,termheight-3).
				}
			}
			else if unchar(ch) = 45 { //negative sign
				if charQ:LENGTH < 1 {
					charQ:PUSH(ch).
					set charstring to charstring+ch.
					print charstring AT (4,termheight-3).
				}
			} 
			else if unchar(ch) = 46 { //decimal point
				if charQ:LENGTH > 0 and decimalset = 0 {
					charQ:PUSH(ch).
					set decimalset to charQ:LENGTH.
					set charstring to charstring+ch.
					print charstring AT (4,termheight-3).
				}
			}
			else if ch = Terminal:Input:RETURN {
				break.
			} 
			else if unchar(ch) >= 48 AND unchar(ch) <= 57 { //numbers 0-9
				charQ:PUSH(ch).
				set charstring to charstring+ch.
				print charstring AT (4,termheight-3).
			}	
		}
		wait 0.1.
	}
	set tempchar to "".
	print tempchar:PADRIGHT(termwidth-6) AT (4,termheight-3).
	IF charstring = "" {print "FAIL" AT (30,30).} else {	return charstring:TOSCALAR. }
}	

function input_yn{ //returns bool of TRUE for Y and FALSE for N
	local charQ to QUEUE().
	local j is 0.
	local bool to FALSE.
	local charstring to "".
	local tempchar to "".
	local termheight to termheight.
	local termwidth to termwidth.
	until false{
		if CPUINITIALIZED {scr_update().}
		if Terminal:INPUT:HASCHAR(){
			local ch to Terminal:Input:Getchar().
			//print unchar(ch).
			if ch = Terminal:Input:BACKSPACE {
					if charstring:LENGTH > 0 {
						set charstring to "".
						set bool to FALSE.
						print charstring + " " AT (4,termheight-3).
					}
				} 
			else if ch = Terminal:Input:RETURN {
					break.
				} 
			else if unchar(ch) = 121 OR unchar(ch) = 89 { 
					set charstring to ch.
					print charstring AT (4,termheight-3).
					set bool to TRUE.
				} 
			else if unchar(ch) = 78 OR unchar(ch) = 110 {
				set charstring to ch.
				print charstring AT (4,termheight-3).
				set bool to FALSE.
				}
		}	
		wait 0.1.
	}
	print tempchar:PADRIGHT(termwidth-6) AT (4,termheight-3).
	return bool.
}	

function fail_msg{
	if WARNSTATE = 1 {return.}
	FOR P IN SHIP:PARTS {
		if P:MODULES:contains("ModuleUPFMEvents"){
			local upfmmod to P:getmodule("ModuleUPFMEvents").
			if (upfmmod:allevents:length > 1){
				for ev in upfmmod:allevents {
					if ev:contains("failure") { 
						// msg_add(P:TITLE + " has failed"). 
						set WARNSTATE to 1.
						print(P:TITLE + " has failed") at (1,0).
						local V0 TO GetVoice(0).
						V0:PLAY( NOTE( 440, 1) ). 
						print CHAR(7).
						
					}
				}
			}
		}
	}
}