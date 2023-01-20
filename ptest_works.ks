@lazyGlobal off.
local L TO LEXICON().


local jsonname to ship:name+".json".

if exists(jsonname) {
    set L to readJson(jsonname).
} else {
    L:add("istep",0).
    L:add("jstep",0).
}


local init_i is L["istep"].
local init_j is L["jstep"].


local pevent_list is list(
    print_test@,
    multi_print_test@,
    print_test@,
    print_test@,
    print_test@,
    print_test@,
    print_test@,
    print_test@,
    print_test@,
    print_test@   
).

local i is init_i.
local j is init_j.
until i = pevent_list:length {
    local result is pevent_list[i]:bind(i):call.
    if result:istype("list") {
        until j = result:length {
            if result[j]:call {
                set j to j+1.
                set L["jstep"] to j.
                writeJson(L,jsonname).
            }
            // print "trig2".
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
    // print "trig".
    }
    
    wait 0.1.
}
if exists(jsonname) {
    deletePath(jsonname).
}

function multi_print_test {
    parameter a.
    set a to a * 1000.
    local b is 10.
    return list(
    {
        
        print(a).
        
        return true.
    },
    {
        print(a+b).
        return true.
    }
    ). 
}

function print_test {
    parameter a.
    print(a).
    return true.
}