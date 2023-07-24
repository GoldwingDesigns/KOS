@lazyGlobal off.
local termheight to terminal:height.
local termwidth to terminal:width.
local midline to termwidth/2.
local currmenutitle to "".  // have to store this here just in case of resize screen
local currmenulist to list(). // have to store this here just in case of resize screen
{
    global UI is lexicon (
        "run",          term_run@,
        "msg add",      msg_add@,
        "scr update",   scr_update@,
        "menu run",     menu_run@,
        "AG6 stop",     ag6_stop@
    ).

    function term_run {
        until false {
            local missionfile is "None".
            If homeConnection:isconnected UTL["refresh mission files"]().
            clearScreen.
            set missionfile to menu_run().
            clearscreen.
            if missionfile = "None" { msg_add("None Selected"). } else { runpath(BOOTVOLUME+":/missions/"+missionfile). }
        }
    }
    function ag6_stop{
        if AG6 {
            UTL["kill program"]().
        }
    }
    // function msg_update{
    //     local tmpstring to "".
    //     local line0 to 0.
    //     local tempQ to LOGQ:copy.
    //     local i to 0.
    //     clearscreen.
    //     until i = termheight
    //     {
    //         set tmpstring to tempQ:POP().
    //         print tmpstring:PADRIGHT(termwidth - 4) AT (2,line0+i).
    //         set i to i+1.
    //     }
    // }

    function msg_add{
        parameter msg.
        local msgstring is get_met_time() + " " + msg.
        // until LOGQ:LENGTH < termheight
        // {
        //     LOGQ:POP().
        // }
        // set msg to get_met_time() + " " + msg.
        // LOGQ:PUSH(msg).
        print(msgstring).
        if LOGMSGS {UTL["write log"](msgstring).}
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

    function scr_update {
        // msg_update().
        return.
    }

    function menu_run {
        local fnamelist is list().
        set fnamelist to UTL["list file contains"]("mission",BOOTVOLUME,"missions").
        fnamelist:add("None").
        return menu_list("Select a "+VES1["&name"]()+" mission file:",fnamelist).
    }

    function menu_list{
        parameter listtitle, list_of_names.
        
        // set INMENU to TRUE.
            
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
        // set INMENU to FALSE.
        
        set currmenutitle to "".  //clear these out for next use
        set currmenulist to list(). // clear these out for next use
        return list_of_names[result].
    }

    function menu_print{
        // menu_clr().
        local len is currmenulist:length().
        print currmenutitle:PADRIGHT(midline-3) at(2,2).
        local i is 0.

        until i=len
        {
            print i+") "+currmenulist[i] at(2,i+4).
            set i to i+1.
        }
    }

    function input_pos_int{
	local charQ to QUEUE().
	local j is 0.
	local charstring to "".
	local tempchar to "".
	until false{
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

    // function data_clr_node {
    //     return.
    // }
}