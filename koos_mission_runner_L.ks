@lazyGlobal OFF.

{
    function create_mission {
        parameter event_list to list(), interrupt_list to list(), reboot_persist to true.// set to true to persist mission through reboot.
        
        local L TO LEXICON().
        local jsonname to BOOTVOLUME+":/"+ship:name+".json".
        if exists(jsonname) and reboot_persist {
            set L to readJson(jsonname).
        } else {
            L:add("istep",0).
            L:add("jstep",0).
        }
        local init_i is L["istep"].
        local init_j is L["jstep"].
    

        function runmission {
            local i is init_i.
            local j is init_j.
            until i = event_list:length {
                local result is event_list[i]:call.
                if result:istype("list") {
                    until j = result:length {
                        if result[j]:call {
                            set j to j+1.
                            set L["jstep"] to j.
                            writeJson(L,jsonname).
                        }
                        check_triggers().
                        wait 0.1.
                    }
                    set i to i+1.
                    set L["istep"] to i.
                    set j to 0.
                    set L["jstep"] to j.
                    writeJson(L,jsonname).
                } else if result:istype("boolean") {
                if result {
                    set i to i+1.
                    set L["istep"] to i.
                    writeJson(L,jsonname).
                }
                check_triggers().
                }
                wait 0.1.
            }
            if exists(jsonname) {
                deletePath(jsonname).
            }
        }
        function check_triggers{
            local trignum is 0.
            until trignum = interrupt_list:length {
                interrupt_list[trignum]:call.
                set trignum to trignum+1.
            }
            return true.
        }      
        return lexicon (
            "run", runmission@
        ).
    }

    GLOBAL MIS is lexicon(
        "new", create_mission@
    ).
}