//@lazyglobal off.
// #EXTERNAL_IDS lazyGlobal, MNV, MNV_TMP, VES, VES1, UTL, UI, SYS, man_check_stage, find_burntime, find_eta_to_true_anomaly, plane_change_info, find_landing_tgt_LAN,get_path_to_apprpoint,find_landing_tgt_LAN_lowalt, unlock_all, orbit_circumference, circle_distance, LAZcalc, LAZcalc_init, pitchangle, hillclimb,etatoaltitude2

{
    function create_ship {
        parameter s is SHIP, shipCfg is lex().
        local solardirection to choose "side" if not shipCfg:haskey("solar") else shipCfg:solar.
        local uiType to choose "digital" if not shipCfg:haskey("ui") else shipCfg:ui.
        local launchstage to choose 0 if not shipCfg:hasKey("lastlaunchstage") else shipCfg:lastlaunchstage.
        local rcsGain to choose 1 if not shipCfg:hasKey("rcsgain") else shipCfg:rcsgain.
        local name is s:name.
        local lastchutestage is 2147483647.
        local firstchutestage is 0.
        local lastenginestage is 2147483647.
        local fairinglist is list().
        local parachuteslist is list().
        local engineslist is list().
        local commslist is list().
        local launchclamplist is list().
        local failablelist is list().
        local failedlist is list().
        local actionsavail to Career():CANDOACTIONS.
        local solardir to solardirection.

        refreshparts().

        function refreshparts {
            set parachuteslist to ship:partsdubbedpattern("^*chute*").
            list engines in engineslist.
            local flist to ship:partsnamedpattern("^fairing*").
            for f in flist {
                if f:TAG:matchespattern("^((?!NOSTAGE).)*$")  fairinglist:add(f).
            }
            if parachuteslist:length < 1 {
                set lastchutestage to 0.
            } else {
                for p in parachuteslist{
                    local stagenum is p:stage.
                    if stagenum > firstchutestage set firstchutestage to stagenum.
                    if stagenum < lastchutestage set lastchutestage to stagenum.
                }
            }
            if engineslist:length < 1 {
                set lastenginestage to 0.
            } else {
                for e in engineslist{
                    local stagenum is e:stage.
                    // if stagenum > firstenginestage set firstenginestage to stagenum.
                    if stagenum < lastenginestage set lastenginestage to stagenum.
                }
            }

            failablelist:clear().
            failedlist:clear().
            commslist:clear().
            for p in ship:parts { //add ohscrap parts to list and comms antenna parts.
		        if p:modules:contains("ModuleUPFMEvents"){ failablelist:add(p:getmodule("ModuleUPFMEvents")). }
                if p:modules:contains("Reliability"){failablelist:add(p:getmodule("Reliability")).}
                if p:modules:contains("ModuleDataTransmitter"){ commslist:add(p). } 
                if (p:name:contains("LaunchClamp") OR p:modules:contains("LaunchClamp")){ launchclamplist:add(p). }
            }

        }

        local this is lexicon(
            "&lastchute",       var_lastchute@,
            "&lastengine",      var_lastengine@,
            "&firstchute",      var_firstchute@,
            "&launchstage",     var_launchstage@,
            "&rcsGain",         var_rcsGain@,
            "&chuteslist",      var_chuteslist@,
            "&commslist",       var_commslist@,
            "&failablelist",    var_failablelist@,
            "&solardir",        var_solardir@,
            "&uitype",          var_uitype@,
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
            // "ship to sun",      meth_ship_to_sun@,
            "prelaunch checks", meth_prelaunch_checks@,
            "check ign",        meth_check_ignitions@
            ).

        function var_lastchute {
            return lastchutestage.
        }
        function var_lastengine {
            return lastenginestage.
        }
        function var_firstchute {
            return firstchutestage.
        }
        function var_launchstage {
            return launchstage.
        }
        function var_rcsGain {
            return rcsGain.
        }
        function var_chuteslist {
            return parachuteslist.
        }
        function var_commslist {
            return commslist.
        }
        function var_failablelist {
            return failablelist.
        }
        function var_name {
            return name.
        }
        function var_uitype {
            return uiType.
        }
        function var_solardir {
            return solardir.
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
                        print "oscrap_failure".
                        failedlist:add(pm:part:uid).
                        UI["msg add"](pm:part:title + " has failed").
                        local V0 TO GetVoice(0).
						V0:PLAY( NOTE( 440, 1) ). 
                        //SYS["pause"]().
                    }
                }
                }else if pm:name:tostring:contains("Reliability"){ //Kerbalism
                local fieldname is pm:allfieldnames[0]:tostring.
                // local fieldname is pm:allfieldnames[0]:tostring.
                local partstatus is pm:getfield(fieldname):tostring.
                print pm:part:name.
                print partstatus:contains("malfunction").
                if partstatus:contains("malfunction") or partstatus:contains("failure") {
                    print "kerbalism_failure". 
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
        function meth_prelaunch_checks { //engines must be set to stage first and then launchclamps
            local waitstart to 0.
            return list(
                {if launchclamplist:length > 0 { 
                    LOCK THROTTLE to 1. 
                    UI["msg add"]("Throttle Up."). 
                    WAIT 2. 
                    UI["msg add"]("Engine Ignition.").
                    stage. 
                    }. 
                return true.
                },
                {
                    set waitstart to time:seconds.
                    return true.
                },
                {
                    return waitstart+2 < time:seconds.
                },
                {
                    if failedlist:length > 0 {
                    LOCK THROTTLE to 0. 
                    UI["msg add"]("Launch Checks Failed. Discontinuing Launch."). 
                    print 1/0.} 
                    UI["msg add"]("Launch Checks Successful.").
                    // UNLOCK THROTTLE.
                    return true.}
                ).
        }
        function meth_check_ignitions {
            local myeng is list().
            LIST ENGINES in myeng. 
            local done is FALSE.
            until done{
                local e is list(). //list of eng with 0 ignitors left
                local s is list(). //list of eng in stage
                for eng in myeng { 
                    if eng:stage=stage:number { 
                        s:add(eng).
                        if eng:HASMODULE("ModuleEngineIgnitor") {
                            if eng:getmodule("ModuleEngineIgnitor"):getfield("ignitions"):split("[ ")[1]:split("/")[0] = "0" {
                                e:add(eng).
                            }
                        }
                    }
                }
                if (s:length = e:length) {//no ignitors left in stage or no eng in stage
                    if stage:number > VES1["&lastchute"]()+1 {UI["msg add"]("No ignitors or no engine. Staging."). VES1["stage"]().}
                    else {UI["msg add"]("No ignitors or no engine. Staging limit reached."). set done to TRUE.}
                } else {
                    set done to TRUE.
                }
            }
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
                if p:hasmodule("realchutemodule") p:getmodule("realchutemodule"):doaction("arm parachute",true).
                else if p:hasmodule("realchuteFAR") p:getmodule("realchuteFAR"):doaction("deploy chute",true).
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