@lazyGlobal off.

parameter __RUN__ is false.

/// <summary>Finds the greatest common denominator of A and B using the Euclidean Algorithm
/// </summary>
function gcd {
    parameter A, B.

    if A = 0 {
        return B.
    }
    if B = 0 {
        return A.
    }

    return gcd(B, mod(A, B)).
}

/// <summary>Returns true if A is co-prime with B</summary>
function isCoprime {
    parameter A, B.

    return gcd(A, B) = 1.
}

/// <summary>Finds and returns the best altitude to complete a ScanSat scan of the body, given the 
/// passed scan parameters</summary>
/// <parameter name="fov">The field of view of the ScanSat Scanner as listed in the VAB</parameter>
/// <parameter name="minAlt">The lowest altitude to consider. Should be either the listed minAlt
/// for the scanner, or the minimum safe/desired altitude; whichever is greatest</parameter>
/// <parameter name="bestAlt">The listed best altitude for the scanner</parameter>
/// <parameter name="maxAlt">The maximum altitude the scan can be completed from</parameter>
/// <parameter name="targetBody">The body the scan will be performed at. Defaults to the current
/// body</parameter>
/// <returns>a Lexicon containing T, the expected time required to complete the scan in seconds,
/// R, the radius of the orbit from the centre of the body, and A, the radius of the orbit minus 
/// the body's radius to sea level</returns>
function findBestOrbit {
    parameter fov.
    parameter minAlt.
    parameter bestAlt.
    parameter maxAlt.
    parameter targetBody is body.


    local srfRatio is kerbin:radius/targetBody:radius.
    set srfRatio to max(1, srfRatio).
    set srfRatio to sqrt(srfRatio).
    
    // the fov scaled by the radius of the planet as ScanSat does it.
    local scaledFOV is fov * srfRatio.
    set scaledFOV to min(scaledFOV, 20).

    // the minimum number of sweeps required for 100% coverage
    local minNSweeps is ceiling(180/scaledFOV).

    local minT is -1.
    local sma is -1.
    for nSweeps in range(minNSweeps, 2*minNSweeps) {
        // the effective FOV required with the current number of passes
        local sweepFOV is 180/nSweeps.
        // the minimum altitude at which this FOV can be achieved with the scanner as fov is
        // reduced linearly below bestAlt
        local fovAlt is (sweepFOV/fov)*bestAlt/srfRatio.
        set fovAlt to max(fovAlt, minAlt).

        // n controls the amount of rotation of the body between passes, i.e. the distance between
        // ground tracks.
        for n in range(1, 2*nSweeps) {
            // n must be coprime with nSweeps, otherwise we will repeat tracks without completing
            // coverage
            if isCoprime(nSweeps, n) {
                // calculate orbital period and radius required.
                local orbitPeriod is n * targetBody:rotationPeriod / nSweeps.
                local orbitSMA is (targetBody:mu * orbitPeriod^2 / (4 * constant:pi^2))^(1/3).

                // check orbit is within constraints
                if orbitSMA > maxAlt + targetBody:radius {
                    break.
                }

                if orbitSMA > fovAlt + targetBody:radius {
                    local scanTime is n * targetBody:rotationPeriod.
                    // update best if orbit is better
                    if minT = -1 or minT > scanTime or (scanTime = minT and orbitSMA < sma) {
                        set minT to scanTime.
                        set sma to orbitSMA.
                    }
                }
            }
        }
    }

    return lexicon("T", minT, "R", sma, "A", sma-targetBody:radius).
}

function input {
    parameter col, row, decal is ">>".
    local ti is terminal:input.
    local value is "".
    until false {
        local dispStr is decal + value.
        print dispStr:padRight(terminal:width) at (col,row).
        local c is ti:getChar.
        if c = ti:backspace {
            set value to value:subString(0, max(0, value:length-1)).
        } else if c = ti:enter {
            return value.
        } else if unChar(c) > 32 and unChar(c) < 127 {
            set value to value + c.
        }
    }
}

function doUserInput {
    set terminal:width to 40.
    set terminal:height to 30.

    clearScreen.

    print "Input Target Body:" at (0, 0).
    local targetBody is input(0,1).
    until bodyExists(targetBody) {
        print ("cannot find " + targetBody + ". check spelling"):padRight(terminal:width) at (0, 1).
        wait until terminal:input:hasChar.
        set targetBody to input(0, 1).
    }

    print "Input FOV:" at (0, 3).
    local fov is input(0, 4).
    until fov:matchesPattern("^\d+(\.\d+)?$") {
        print "Float input expected":padRight(terminal:width) at (0, 4).
        wait until terminal:input:hasChar.
        set fov to input(0, 4).
    }

    print "Input minimum altitude:" at (0, 6).
    local minAlt is input(0, 7).
    until minAlt:matchesPattern("^\d+$") {
        print "Integer input expected":padRight(terminal:width) at (0, 7).
        wait until terminal:input:hasChar.
        set minAlt to input(0, 7).
    }

    print "Input best altitude:" at (0, 9).
    local bestAlt is input(0, 10).
    until bestAlt:matchesPattern("^\d+$") {
        print "Integer input expected":padRight(terminal:width) at (0, 10).
        wait until terminal:input:hasChar.
        set bestAlt to input(0, 10).
    }

    print "Input maximum altitude:" at (0, 12).
    local maxAlt is input(0, 13).
    until maxAlt:matchesPattern("^\d+$") {
        print "Integer input expected":padRight(terminal:width) at (0, 13).
        wait until terminal:input:hasChar.
        set maxAlt to input(0, 13).
    }

    local res is findBestOrbit(fov:toNumber, minAlt:toNumber, bestAlt:toNumber, maxAlt:toNumber,
                               body(targetBody)).

    print "T=" + res["T"] + "s" at (0, 15).
    print "R=" + res["R"] + "m" at (0, 16).
    print "A=" + res["A"] + "m" at (0, 17).
}

if __RUN__ {
    doUserInput().
    print "Run again? y/n" at (0, 19).
    until input(0, 20) = "n" {
        doUserInput().
        print "Run again? y/n" at (0, 19).
    }
}