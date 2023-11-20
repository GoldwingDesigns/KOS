parameter reboot_persist to false.// set to true to persist mission through reboot.

local targetname to "Station - 1".
local tgt to vessel(targetname).
local rdvzdist to 100.

UTL["build MNV lex"](list("core","rdvz")).

local event_list to list(
    MNV["ship transfer"]@:bind(tgt,rdvzdist),
    MNV["exec node"]@,
    MNV["cancel vel cpa"]@:bind(tgt)
).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist,scriptPath():name).
MIS1["run"]().
