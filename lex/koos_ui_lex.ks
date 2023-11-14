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
       // "scr update",   scr_update@,
        "AG6 stop",     ag6_stop@
    ).

    function term_run {
        parameter is_analog to false.
        if is_analog {            
            local fnamelist to get_mission_list().
            local cList to create_command_list().
            local verbLex to clist[0].
            local nounLex to clist[1].
            until false {
            if AG7 {
                AG7 off.
                if fnamelist:length > 0 {
                runpath(BOOTVOLUME+":/missions/"+fnamelist[0]).
                }
            }
            if AG8 {
                AG8 off.
                if fnamelist:length > 1 {
                runpath(BOOTVOLUME+":/missions/"+fnamelist[1]).
                }
            }
            if AG9 {
                AG9 off.
                if fnamelist:length > 2 {
                runpath(BOOTVOLUME+":/missions/"+fnamelist[2]).
                }
            }
        }
        } else {
            until false {
                local result to "".
                local functionlist to list("Missions","Maneuvers","Vessel","Reboot"). 
                clearscreen.
                set result to menu_list("Choose a function:",functionlist).
                if functionlist[result]="Missions"{
                    mission_menu_run().
                } else if functionlist[result] = "Maneuvers"{
                    lexicon_menu_run(MNV).
                } else if functionlist[result] = "Vessel" {
                    lexicon_menu_run(VES1).
                } else if functionlist[result] = "Reboot" {
                    reboot.
                }
            }
        }
    }
    function create_command_list{
        local verbs to list("Run","Show Status","Stop","Reboot").
        local verbLex to lexicon().
        local nounLex to lexicon().
        local missionIndex to -1.
        local maneuverIndex to -1.
        local vesselActionIndex to -1.
        local vesselVarIndex to -1.
        local verbKey to 0.
        local nounKey to 0.
        local missionList to get_mission_list().
        for v in verbs {
            verbLex:add(verbKey,v).
            set verbKey to verbKey +1.
        }
        set missionIndex to nounKey.
        for n in missionList {
            nounLex:add(nounKey,n).
            set nounKey to nounKey +1.
        } 
        set maneuverIndex to nounKey.
        for n in MNV:keys {
            nounLex:add(nounKey,n).
            set nounKey to nounKey +1.
        }
        set vesselActionIndex to nounKey.
        for n in VES1:keys {
            nounLex:add(nounKey,n).
            set nounKey to nounKey +1.
        }
        UTL["write commands"](verbLex ,nounLex , missionIndex , maneuverIndex , vesselActionIndex , vesselVarIndex).
        return list(verbLex,nounLex).
    }

    function get_mission_list{
        if homeConnection:isconnected UTL["refresh mission files"]().
        local missionList to UTL["list file contains"]("mission",BOOTVOLUME,"missions").
        return missionList.
    }
    function mission_menu_run{
        until false {
            local missionfile is "None".
            clearScreen.
            local fnamelist is get_mission_list().
            local fprintlist is list().
            for name in fnamelist {
                local strarr to name:SPLIT("mission_").
                // fprintlist:add(strarr[strarr:length-1]:toupper).
                fprintlist:add(strarr[strarr:length-1]:split(".ks")[0]:replace("_"," "):toupper).
            }
            fprintlist:add("Prev Menu").
            set missionfile to menu_list("Select a "+CORE:ELEMENT:NAME+" mission file:",fprintlist).
            clearscreen.
            if missionfile = -1 { return false. } else { runpath(BOOTVOLUME+":/missions/"+fnamelist[missionfile]). }
        }
    }
    function lexicon_menu_run{
        parameter my_lex.
        until false {
            local key_list to my_lex:keys.
            key_list:add("Prev Menu").
            local result to "".
            set result to menu_list("Select an operation:",key_list).
            clearscreen.
            if result = "Prev Menu" {return false.} else {my_lex[result]().}
        }
    }
    function ag6_stop{
        if AG6 {
            AG6 off.
            MIS1["stop"]().
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

    // function scr_update {
    //     // msg_update().
    //     return.
    // }

    function menu_list{
        parameter listtitle, list_of_names.
        
        // set INMENU to TRUE.
        local pagenum to 0.
        local result_value to "".
        if list_of_names:empty{
            print "error: list_of_names should not be empty". print 1/0.
        }
        set currmenutitle to listtitle.
        local list_len is list_of_names:length().
        local maxlength is termheight/3.
        until false {
            if list_len > maxlength {
                set currmenulist to list_of_names:sublist(pagenum*maxlength,maxlength).
                if pagenum <> 0 { currmenulist:insert(0,"PREV PAGE").}
                if (pagenum+1)*maxlength < list_len { currmenulist:add("NEXT PAGE").} 
            } else {
                set currmenulist to list_of_names.
            }
            local currlist_len to currmenulist:length().
            
            //keep going until actual result acheived
            clearscreen.
            menu_print().
            local result is input_pos_int().
            // print(result).
            until result < currlist_len {
                PRINT "ERROR: INPUT OUT OF RANGE" AT (4,termheight-3).
                WAIT 1.
                set result to input_pos_int().
            }
            set result_value to currmenulist[result].
            if  result_value = "PREV PAGE" { 
                set pagenum to pagenum-1. 
            } else if result_value = "NEXT PAGE" {
                set pagenum to pagenum+1. 
            } else {
                break.
            }
        // set INMENU to FALSE.
        }
        set currmenutitle to "".  //clear these out for next use
        set currmenulist to list(). // clear these out for next use
        if result_value = "PREV MENU" {return -1.}
        return list_of_names:indexof(result_value).
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