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
        "menu run",     menu_run@
    ).

    function term_run {
        until false {
            local missionfile is "none".
            clearScreen.
            set missionfile to menu_run().
            clearscreen.
            runpath(missionfile).
        }
    }

    function msg_add {
        parameter msg.
        print msg.
    }

    function scr_update {
        return.
    }

    function menu_run {
        local choice is "none".
        local fnamelist is list().
        if UTL["has File Contains"](VES1["&name"]()+"_mission",1) {
            set fnamelist to UTL["list File Contains"](VES1["&name"]()+"_mission",1).
            fnamelist:add("None").
            set choice to menu_list("Pick a mission file:",fnamelist).
        }
        return choice.
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

    function data_clr_node {
        return.
    }
}