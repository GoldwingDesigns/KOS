print list_ir_parts@.
for d in list_ir_parts(){
    print d.
}
    

function ir_position {
    parameter title, value.
    local plist to ship:partstitled(title).
    for p in plist {
        p:getmodule("ModuleIRServo_v3"):setfield("target position",value).
    }
}

function list_ir_parts {
    return ship:partsnamedpattern("^IR.*").
}