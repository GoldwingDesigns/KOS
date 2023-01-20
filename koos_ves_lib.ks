@lazyglobal off.

{
    global VES is lexicon(
        "sas on",           ves_sas_on@,
        "sas off",          ves_sas_off@,
        "rcs on",           ves_rcs_on@,
        "rcs off",          ves_rcs_off@,
        "ladders on",       ves_lad_on@,
        "ladders off",      ves_lad_off@,
        "gear on",          ves_gear_on@,
        "gear off",         ves_gear_off@
        ).

    function ves_sas_on {
        SAS ON.
    }
    function ves_sas_off {
        SAS OFF.
    }
    function ves_rcs_on {
        RCS ON.
    }
    function ves_rcs_off {
        RCS OFF.
    }
    function ves_lad_on {
        ladders ON.
    }
    function ves_lad_off {
        ladders OFF.
    }
    function ves_gear_on {
        gear ON.
    }
    function ves_gear_off {
        gear OFF.
    }
    function ves_stage {
        stage.
    }
}