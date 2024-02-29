parameter reboot_persist to true.// set to true to persist mission through reboot.
local tgtmoonname to "minmus".
local tgtmoon to body(tgtmoonname).
local init_moon_obt_alt to (tgtmoon:soiradius-tgtmoon:radius)*0.9.

UTL["build MNV lex"](list("core","mxfr")).


local event_list to list(
    MNV["moon trans"]@:bind(tgtmoon,init_moon_obt_alt),
    MNV["exec node"]@,
    SYS["warp next patch"]@,
    SYS["wait soi chng"]@:bind(tgtmoonname),
    MNV["capture"]@,
    MNV["exec node"]@
    ).

local interrupt_list to list(
    VES1["check fail"]@,
    UI["abort stop"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist,scriptPath():name).
MIS1["run"]().
