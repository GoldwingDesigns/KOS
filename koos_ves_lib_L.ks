@lazyglobal off.

{
    function create_ship {
        parameter s is SHIP, solardirection is "side".
        local name is s:name.
        local lastchutestage is 2147483647.
        local firstchutestage is 0.
        local launchstage is 0.
        // local roboticslist is list().
        local fairinglist is list().
        local parachuteslist is list().
        local commslist is list().
        local launchclamplist is list().
        local failablelist is list().
        local failedlist is list().
        local actionsavail to Career():CANDOACTIONS.

        refreshparts().

        function refreshparts {
            // set roboticslist to ship:partsnamedpattern("^IR.*").
            set parachuteslist to ship:partsdubbedpattern("^*chute*").
            set fairinglist to ship:partsnamedpattern("^fairing*").
                        
            if parachuteslist:length < 1 {
                set lastchutestage to 0.
            } else {
                for p in parachuteslist{
                    local stagenum is p:stage.
                    if stagenum > firstchutestage set firstchutestage to stagenum.
                    if stagenum < lastchutestage set lastchutestage to stagenum.
                }
            }

            failablelist:clear().
            failedlist:clear().
            commslist:clear().
            for p in ship:parts { //add ohscrap parts to list and comms antenna parts.
		        if p:modules:contains("ModuleUPFMEvents"){ failablelist:add(p:getmodule("ModuleUPFMEvents")). }
                if p:modules:contains("Reliability"){failablelist:add(p:getmodule("Reliability")).}
                if p:modules:contains("ModuleDataTransmitter"){ commslist:add(p). } 
                if p:name:contains("LaunchClamp"){ launchclamplist:add(p). }
            }

        }

        local this is lexicon(
            "&lastchute",       var_lastchute@,
            "&firstchute",      var_firstchute@,
            "&launchstage",     var_launchstage@,
            "&chuteslist",      var_chuteslist@,
            // "&IRlist",          var_roboticslist@,
            "&commslist",       var_commslist@,
            "&failablelist",    var_failablelist@,
            "&name",            var_name@,
            "comms ext",        meth_comms_ext@,
            "comms ret",        meth_comms_ret@,
            "sas on",           meth_sas_on@,
            "sas off",          meth_sas_off@,
            "rcs on",           meth_rcs_on@,
            "rcs off",          meth_rcs_off@,
            "ladders on",       meth_lad_on@,
            "ladders off",      meth_lad_off@,
            "panels on",        meth_pan_on@,
            "panels off",       meth_pan_off@,
            "gear down",        meth_gear_on@,
            "gear up",          meth_gear_off@,
            "stage",            meth_stage@,
            "extract stage",    meth_sep_stage@,
            "arm chutes",       meth_arm_chutes@,
            "check fail",       meth_check_fail@,
            "fairing deploy",   meth_deploy_fairing@,
            "ship to sun",      meth_ship_to_sun@,
            "prelaunch checks", meth_prelaunch_checks@,
            "blank",            meth_blank@
            ).

        function var_lastchute {
            return lastchutestage.
        }
        function var_firstchute {
            return firstchutestage.
        }
        function var_launchstage {
            return launchstage.
        }
        function var_chuteslist {
            return parachuteslist.
        }
        // function var_roboticslist {
        //     return roboticslist.
        // }
        function var_commslist {
            return commslist.
        }
        function var_failablelist {
            return failablelist.
        }
        function var_name {
            return name.
        }
        function meth_deploy_fairing {
            if actionsavail {
            for p in fairinglist{
                p:getmodule("ModuleProceduralFairing"):doaction("deploy",true).
            }
            UI["msg add"]("Fairings deployed.").
            return true.
            } else {
                UI["msg add"]("Actions Unavailable. Deploy Fairings Manually.").
                return true.
            }
        }
        function meth_comms_ext {
            if actionsavail {
            for p in commslist {
                if p:hasmodule("ModuleDeployableAntenna") { p:getmodule("ModuleDeployableAntenna"):doaction("extend antenna",true).}
            }
            UI["msg add"]("Radio Antennas Extended.").
            return true.
            } else {
                UI["msg add"]("Actions Unavailable. Extend Radio Antennas Manually.").
                return true.
            }
        }
        function meth_comms_ret {
            if actionsavail {
            for p in commslist {
                if p:hasmodule("ModuleDeployableAntenna") { p:getmodule("ModuleDeployableAntenna"):doaction("retract antenna",true).}
            }
            UI["msg add"]("Radio Antennas Retracted.").
            return true.
            } else {
                UI["msg add"]("Actions Unavailable. Retract Radio Antennas Manually.").
                return true.
            }
        }
        function meth_check_fail {
            for pm in failablelist {
                if pm:name:tostring:contains("ModuleUPFMEvents"){ //OhScrap
                if pm:allevents:tostring:contains("failure") { 
                    if not failedlist:contains(pm:part:uid) {
                        failedlist:add(pm:part:uid).
                        UI["msg add"](pm:part:title + " has failed").
                        local V0 TO GetVoice(0).
						V0:PLAY( NOTE( 440, 1) ). 
                        //SYS["pause"]().
                    }
                }
                }else if pm:name:tostring:contains("Reliability"){ //Kerbalism
                local fieldname is pm:allfieldnames[0]:tostring.
                local partstatus is pm:getfield(fieldname):tostring.
                if partstatus:contains("malfunction") or partstatus:contains("failure") { 
                    if not failedlist:contains(pm:part:uid) {
                        failedlist:add(pm:part:uid).
                        UI["msg add"](pm:part:title + " has failed").
                        local V0 TO GetVoice(0).
						V0:PLAY( NOTE( 440, 1) ). 
                        //SYS["pause"]().
                    }
                }
                }
            }
            return true.         
        }
        function meth_prelaunch_checks {
            //engines must be set to stage first and then launchclamps
            return list(
                {if launchclamplist:length > 0 { 
                    set SHIP:CONTROL:MAINTHROTTLE to 1. 
                    stage. 
                    }. 
                WAIT 1. 
                return true.
                },
                {
                    if failedlist:length > 0 {
                    set SHIP:CONTROL:MAINTHROTTLE to 0. 
                    //UI["msg add"]("Launch Checks Failed. Discontinuing Launch."). 
                    print 1/0.} 
                    //UI["msg add"]("Launch Checks Successful.").
                    return true.}
                ).
        }
        function meth_ship_to_sun { 
            VES1["sas off"]().
            if solardirection:contains("fore"){
                lock STEERING to Body("sun"):position.
            } else if solardirection:contains("aft"){
                lock STEERING to 1 * Body("sun"):position.
            } else if solardirection:contains("side"){
                lock STEERING to VCRS(body("sun"):position,ship:velocity:orbit).
            }.
	    }
        function meth_sas_on {
            SAS ON.
            UI["msg add"]("SAS On.").
            return true.
        }
        function meth_sas_off {
            SAS OFF.
            UI["msg add"]("SAS Off.").
            return true.
        }
        function meth_rcs_on {
            RCS ON.
            UI["msg add"]("RCS On.").
            return true.
        }
        function meth_rcs_off {
            RCS OFF.
            UI["msg add"]("RCS Off.").
            return true.
        }
        function meth_lad_on {
            ladders ON.
            UI["msg add"]("Ladders Extended.").
            return true.
        }
        function meth_lad_off {
            ladders OFF.
            UI["msg add"]("Ladders Retracted.").
            return true.
        }
        function meth_pan_on {
            panels ON.
            UI["msg add"]("Solar Panels Extended.").
            return true.
        }
        function meth_pan_off {
            panels OFF.            
            UI["msg add"]("Solar Panels Retracted.").
            return true.
        }
        function meth_gear_on {
            gear ON.
            UI["msg add"]("Landing Gear Extended.").
            return true.
        }
        function meth_gear_off {
            gear OFF.
            UI["msg add"]("Landing Gear Retracted.").
            return true.
        }
        function meth_stage {
            if stage:ready {
                stage.
                UI["msg add"]("Stage. Current stage: " + stage:number + ".").
                refreshparts().
                return true.
            }
            else return false.
        }
        function meth_blank {
            return true.
        }
        function meth_sep_stage {
            local waitstart to 0.
            UI["msg add"]("Commence stage "+stage:number+" extraction.").
            return list (
                {
                    RCS ON.
                    return true.
                },
                {
                    set ship:control:fore to 1.
                    set waitstart to time:seconds.
                    return true.
                },
                {
                    return waitstart+2 < time:seconds.
                },
                {
                    set ship:control:neutralize to true.
                    set waitstart to time:seconds.
                    return true.
                },
                {
                    return waitstart+10 < time:seconds.
                },
                {
                    RCS OFF.
                    UI["msg add"]("Stage "+stage:number+" extraction complete.").
                    return true.
                }
            ).
        }
        function meth_arm_chutes {
            if actionsavail {
            for p in parachuteslist{
                p:getmodule("realchutemodule"):doaction("arm parachute",true).
            }
            UI["msg add"]("Parachutes armed. Radalt: "+alt:radar).
            return true.
            } else {
                UI["msg add"]("Actions Unavailable. Arm Chutes NOW.").
                return true.
            }
        }

        return this.
    }

    global VES is lexicon(
        "new", create_ship@
    ).
}