function prepare_port{
list dockingports in dp.
    for p in dp {
    if p:hasmodule("ModuleAnimateGeneric") { 
      if p:getmodule("ModuleAnimateGeneric"):hasevent("open") {
        p:getmodule("ModuleAnimateGeneric"):doevent("open"). 
      }
      if p:getmodule("ModuleAnimateGeneric"):hasevent("open shield") {
        p:getmodule("ModuleAnimateGeneric"):doevent("open shield"). 
      }
      if p:getmodule("ModuleAnimateGeneric"):hasevent("deploy") {
        p:getmodule("ModuleAnimateGeneric"):doevent("deploy"). 
      }
    }
    }
    return true.
}
function secure_port {
    list dockingports in dp.    for p in dp {
    if p:hasmodule("ModuleAnimateGeneric") { 
      if p:getmodule("ModuleAnimateGeneric"):hasevent("close") {
        p:getmodule("ModuleAnimateGeneric"):doevent("close"). 
      }
      if p:getmodule("ModuleAnimateGeneric"):hasevent("close shield") {
        p:getmodule("ModuleAnimateGeneric"):doevent("close shield"). 
      }
      if p:getmodule("ModuleAnimateGeneric"):hasevent("retract") {
        p:getmodule("ModuleAnimateGeneric"):doevent("retract"). 
      }
    }
    }
    return true.
}
prepare_port().
Wait 5.
secure_port().