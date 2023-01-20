{
    global test is lexicon("sas",print@).

    function ves_sas {
        if SAS {
            SAS OFF.
            print "turn off".
        } else {
            SAS ON.
            print "turn on".
        }
    }
}

local tlist is list().
tlist:add(clearscreen@).
tlist:add(print@:bind("hello1")).
tlist:add({wait 10.}).
tlist:add(printat("hello",1,10)@).
tlist[0]:call.
tlist[1]:call.
tlist[2]().
tlist[3]:call.
// test["sas"]().