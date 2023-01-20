@lazyGlobal off.
local init_i is 1.
local init_j is 1.

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
            }
            print "trig2".
        }
        set i to i+1.
    } else if result:istype("boolean") {
    if result {
         set i to i+1.
    }
    print "trig".
    }
    
    wait 0.1.
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