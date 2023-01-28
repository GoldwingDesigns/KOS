@lazyGlobal OFF.

{
    Global SYS is lexicon (
        "wait soi chng", wait_soi_chng@,
        "warp next patch", warp_to_nextpatch@,
        "wait time", wait_time@,
        "warp to alt", warp_to_alt@,
        "pause", pause@
    ).

    function wait_soi_chng {
        parameter tgtmoonname.
        return list(
            {
                if ship:body:name = tgtmoonname {
                    UI["msg add"]("SOI Change To "+tgtmoonname).
                    return true.
                } else {
                    return false.
                }
            }
        ).
    }

    function pause{
        KUniverse:pause().
        return true.
    }

    function warp_to_nextpatch{
        warpto(TIME:SECONDS+ORBIT:NEXTPATCHETA).
        return true.
    }

    function warp_to_alt{
        parameter a.
        return list(
			{
				warpto(etatoaltitude2(a)+time:seconds).
				return true.
			},
			{
				return ship:altitude < a.
			}
        ).
    }

    function wait_time {
        parameter a.
        local waitend to time:seconds + a.
        return list ( 
            { 
            if time:seconds > waitend { return true. } else { return false. }
            }
        ).
    }
}