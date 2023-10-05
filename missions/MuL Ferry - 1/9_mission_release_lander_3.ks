parameter reboot_persist to true.// set to true to persist mission through reboot.
// local tgtmoonname to "Mun".
// local tgtmoon to body(tgtmoonname).
// local init_moon_obt_alt to (tgtmoon:soiradius - tgtmoon:radius)*0.9.



local event_list to list(

   {
    local landernumber to 3.
    local landersep to ship:partstagged("LANDER"+landernumber+"_SEP")[0].
    local landercpu to ship:partstagged("LANDER"+landernumber+"_CPU")[0].
    landercpu:getmodule("KOSProcessor"):activate().
    landersep:getmodule("ModuleDecouple"):doevent("decouple").
    
    return true.
   }
    ).

local interrupt_list to list(
    VES1["check fail"]@
).

// mission specific functions


//create and run mission
local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist,scriptPath():name).
MIS1["run"]().
