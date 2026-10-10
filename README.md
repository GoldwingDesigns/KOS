# KOOS

**Version 0.0.1**

> [!WARNING]
> **Experimental, for personal use only.** KOOS is a work in progress. It is not complete, and neither the code nor this documentation should be considered accurate. Use it at your own risk.

KOOS is a mission-automation framework for Kerbal Space Program, written for the [kOS](https://ksp-kos.github.io/KOS/) mod. A ship boots into a menu on its kOS terminal, and from there you can run a whole mission (launch, rendezvous, dock, fly to a moon, land, return, reenter) or any single maneuver or vessel action.

Missions are short scripts that list steps in order. KOOS runs the steps, saves progress so a mission picks up where it left off after a reboot, watches for part failures, and writes a timestamped mission log back to the archive.

## Contents

- [Repository layout](#repository-layout)
- [How it works](#how-it-works)
- [Setting up a ship](#setting-up-a-ship)
- [Writing a mission](#writing-a-mission)
- [Function reference](#function-reference)
- [Optional mods](#optional-mods)
- [Tools](#tools)
- [Known issues](#known-issues)
- [Credits](#credits)

## Repository layout

```
source/          Readable source code. Edit these files.
  boot/            Boot file that starts everything
  lex/             Modules (MIS, SYS, UTL, UI, VES and the maneuver modules)
  lib/             Shared math and helper libraries
boot/ lex/ lib/  Minified copies of source/, built by minify.sh. These are what ships load.
template/        Example mission files and ship config
missions/        Your own mission files, one folder per ship (not tracked by git)
minify.sh        Rebuilds the minified copies from source/
minifier.py      The kerboscript minifier used by minify.sh
scan_solver_3.py Standalone tool for planning SCANsat mapping orbits
sunang.ks        Debug script that draws sun and orbit vectors on screen
```

The repo is laid out to sit in the kOS archive folder (`Ships/Script/` in your KSP install), which kOS calls volume `0:`.

Code on ships is stored on small in-game disks, so ships load the minified copies to save space. After editing anything in `source/`, run `./minify.sh` to rebuild them.

## How it works

### Booting

`koos_boot.ks` runs when the ship loads. It:

1. Names the kOS processors on the vessel. The one running the boot file becomes `MASTER` (volume `MASTER_DISK`). Any others, if untagged or tagged `SLAVE`, become `SLAVE_1`, `SLAVE_2` and so on. `SLAVE_1_DISK` is used for data, or `MASTER_DISK` if it's the only processor.
2. Before launch, shuts down processors tagged `payload` or `lander`, so they can take over once separated.
3. If the ship is on the pad or has a connection home, copies the latest files from the archive. Libraries go to the boot disk and modules go to the data disk.
4. Loads the core modules (`MIS`, `SYS`, `VES`, `UTL`, `UI`), reads `ship.cfg`, creates the vessel object `VES1`, and loads the core maneuvers into `MNV`.
5. Opens the terminal menu.

### Modules

Each module is a kOS lexicon (a key → value table) of functions, stored in a global variable. You call a function by its key, e.g. `MNV["circ"]()` or `VES1["gear up"]()`.

Maneuvers are loaded on demand to save disk space. `UTL["build MNV lex"](list("core","lnch"))` copies only the maneuver modules a mission needs, plus the libraries they depend on, then loads them into `MNV`.

### Steps

Every mission step follows one rule, which lets the runner check for failures and save progress between steps:

- A step that **returns `true`** is done. If it returns `false`, it's called again on the next cycle, every 0.1 seconds.
- A step that **returns a list of functions** is a sequence of sub-steps, each following the same rule.

Most long maneuvers, like a launch or a node burn, return a list of sub-steps. One-shot actions, like adding a maneuver node, just return `true`.

### Terminal menu

The menu has four entries:

- **Missions:** Lists the mission files for this ship and runs the one you choose.
- **Maneuvers:** Runs any loaded `MNV` function.
- **Vessel:** Runs any `VES1` action, or shows a vessel value (the keys starting with `&`).
- **Reboot**

If a mission's saved progress file exists, a **Delete Persist File** entry also appears, so you can start that mission over from the beginning.

You choose an entry by typing its number and pressing Enter. Long lists are split into pages.

### Mission log

Every status message is printed with mission elapsed time (`T+YY-DDD HH:MM:SS`) and added to `<ship>_log.txt`. While the ship has a connection, the log is sent to `0:/missions/<ship>/`. If not, it's kept on the ship and sent once a connection returns. To turn logging off, set `logmsg:false` in `ship.cfg`.

## Setting up a ship

1. Put this repo's contents in `Ships/Script/`.
2. On the ship's main kOS processor, set the boot file to `koos_boot.ks`.
3. Optional: tag any extra kOS processors (`SLAVE`, `payload` or `lander`) as described in [Booting](#booting).
4. Make a folder named after the ship: `Ships/Script/missions/<ship name>/`.
5. Copy the mission files you want from `template/missions/` into that folder. Any file with `mission` in its name shows up in the Missions menu.
6. Optional: add a `ship.cfg` to the same folder (see below).

### ship.cfg

Each line is `key:value`.

| Key | Values | Default | What it does |
|---|---|---|---|
| `solar` | `fore`, `aft`, `side` | `side` | Which way the solar panels face. After a burn, the ship turns that side toward the sun. |
| `lastlaunchstage` | stage number | `0` | Auto-staging during launch stops at this stage. |
| `rcsgain` | number | `1` | Scales RCS thrust during docking. Lower it for small or light craft. |
| `rtryRCS` | `true`, `false` | `true` | Whether to use RCS to push away from the spent stage before reentry. |
| `logmsg` | `true`, `false` | `true` | Whether to write the mission log. |
| `ui` | `digital`, `analog` | `digital` | Read but not currently used (see [Known issues](#known-issues)). |

## Writing a mission

A mission file loads the maneuvers it needs, lists the steps, lists the interrupt checks, and runs. This is a trimmed copy of `template/missions/0_mission_launch.ks`:

```
parameter reboot_persist to true.

local launch_alt to 80000.
local pitchover to 4.
local launch_inc to ship:geoposition:lat.

UTL["build MNV lex"](list("core","lnch")).

local event_list to list(
    VES1["prelaunch checks"]@,
    MNV["launch atmo"]@:bind(launch_alt,launch_inc,true,45,pitchover),
    MNV["circ"]@,
    MNV["exec node"]@
).

local interrupt_list to list(
    VES1["check fail"]@
).

local MIS1 is MIS["new"](event_list,interrupt_list,reboot_persist,scriptPath():name).
MIS1["run"]().
```

The `@` turns a function into a delegate (a reference to call later), and `:bind(...)` fills in its inputs ahead of time. See the kOS docs on [delegates](https://ksp-kos.github.io/KOS/language/delegates.html).

### Included templates

| File | What it does |
|---|---|
| `0_mission_launch.ks` | Launch to an 80 km orbit, circularize |
| `1_mission_rdvz_STATION-1.ks` | Plan and fly a rendezvous to within 100 m of "Station - 1", then match speed |
| `2_mission_dock_STATION-1.ks` | Dock with "Station - 1" |
| `3_mission_undock.ks` | Undock and back away |
| `4_mission_kerbin_to_moon.ks` | Transfer to Minmus and capture into orbit |
| `5_mission_mun_landing.ks` | Line up the orbit over a target on the Mun, lower orbit, and make a powered landing |
| `7_mission_reentry.ks` | Lower periapsis to 35 km, warp to the upper atmosphere, and reenter with parachutes |
| `9_mission_exec_node.ks` | Fly the next maneuver node |

## Function reference

Inputs in *italics* are optional.

### MIS: mission runner

| Key | Inputs | What it does |
|---|---|---|
| `new` | step list, *interrupt list*, *keep progress through reboot* (default true), *mission name*, *Abort key stops mission* (default false) | Creates a mission. Returns `run` and `stop`. |

The interrupt list is checked on every cycle. If progress is kept, it's saved as `<ship name>.json` on the boot disk and deleted when the mission finishes.

### SYS: time and warp

| Key | Inputs | What it does |
|---|---|---|
| `wait time` | seconds | Waits that long |
| `warp to time` | time | Time-warps to that moment |
| `warp to alt` | altitude, *descending* (default true) | Time-warps until the ship reaches that altitude. Needs the orbit library, loaded with `aobt`, `core` or `land`. |
| `warp next patch` | none | Warps to 5 seconds before the next sphere-of-influence change |
| `wait soi chng` | body name | Waits until the ship is orbiting that body |
| `pause` | none | Pauses the game |

### VES: vessel

`VES["new"](ship, config)` builds a vessel object, stored as `VES1` at boot. It finds the ship's engines, parachutes, fairings, antennas, launch clamps, and parts that can fail.

**Values** (show these from the Vessel menu):

| Key | Value |
|---|---|
| `&name` | Ship name |
| `&lastengine` | Lowest stage that has an engine |
| `&firstchute`, `&lastchute` | Highest and lowest stage that has a parachute |
| `&launchstage`, `&rcsGain`, `&rtryRCS`, `&solardir`, `&uitype` | Settings from `ship.cfg` |
| `&chuteslist`, `&commslist`, `&failablelist` | Lists of the matching parts |

**Actions:**

| Key | What it does |
|---|---|
| `sas on/off`, `rcs on/off`, `gear down/up`, `ladders on/off`, `panels on/off` | Toggles that system and logs it |
| `comms ext`, `comms ret` | Extends or retracts deployable antennas |
| `fairing deploy` | Jettisons fairings (except parts tagged `NOSTAGE`) |
| `arm chutes` | Arms RealChute parachutes |
| `stage` | Stages when ready, then rescans the ship's parts |
| `extract stage` | Pushes forward on RCS for 2 seconds to clear a spent stage |
| `extract stage lite` | A gentler version, at 25% RCS for 1 second |
| `extract stage stbd` | *seconds* (default 2). Pushes sideways one way, then the other. |
| `prelaunch checks` | If the ship has launch clamps, sets 10% throttle, ignites, waits 1 second, and stops the launch if a part has failed |
| `check ign` | Stages past engines that are out of ignitions (needs an ignition-limit mod) |
| `check fail` | Logs and beeps when a part fails (OhScrap or Kerbalism). Meant for the interrupt list. |
| `refresh parts` | Rescans the ship's parts |

### MNV: maneuvers

Each group is a module you load with `UTL["build MNV lex"]`.

**`core`: orbit changes and node execution**

| Key | Inputs | What it does |
|---|---|---|
| `exec node` | *last stage* | Warps to the next maneuver node and flies the burn. It throttles down near the end, stages as needed, then turns the solar panels to the sun. |
| `circ` | none | Adds a node to circularize at whichever comes first, apoapsis or periapsis |
| `change apo` | altitude | Adds a node at periapsis to set a new apoapsis |
| `change per` | altitude | Adds a node at apoapsis to set a new periapsis |
| `hoh trans 1` | altitude | First burn of a Hohmann transfer |
| `hoh trans 2` | altitude | Second (circularizing) burn of a Hohmann transfer |
| `change inc lan` | inclination, *LAN* | Adds a plane-change node |
| `change inc lan alt` | inclination, LAN, altitude | Plane change and altitude change in one burn |
| `orbit sun angle` | inclination, altitude, max angle, *min angle* | Picks an orbital plane with a set angle to the sun, e.g. to keep solar panels lit |
| `unlock all` | none | Releases steering and throttle control |

**`lnch`: launch from a body with atmosphere**

| Key | Inputs | What it does |
|---|---|---|
| `launch atmo` | altitude, inclination, *PID tuning switch* (default true), *target seconds to apoapsis* (default 45), *pitchover degrees* (default 4), *roll* (default −90) | Launches straight up, pitches over at 300 m or 50 m/s, then follows prograde in a gravity turn. Holds about 45 seconds to apoapsis with a PID throttle, stages automatically, and coasts to the target apoapsis. Deploys fairings, antennas and solar panels near the edge of the atmosphere. |

**`aobt`: more orbit changes**

| Key | Inputs | What it does |
|---|---|---|
| `match inc lan` | body | Returns a plane change that matches the body's orbital plane |
| `change arg per` | argument of periapsis, altitude | Moves periapsis to a chosen point in the orbit (start from a circular orbit). See [Known issues](#known-issues). |
| `change per` | altitude | Same as in `core` |

**`rdvz`: rendezvous**

| Key | Inputs | What it does |
|---|---|---|
| `ship transfer` | target vessel, *distance* (default 500 m) | Plans a Hohmann transfer to another ship orbiting the same body, then fine-tunes the node until the closest approach is about that distance |
| `cancel vel cpa` | target | Warps to the closest approach and burns to match the target's speed |

**`dock`: docking with RCS**

| Key | Inputs | What it does |
|---|---|---|
| `dock with vessel` | *target vessel* | Full docking sequence: approach, choose ports, open them, line up, plan a path around the target, and dock |
| `undock from vessel` | none | Undocks the nearest port, backs away, and closes the ports' shields |
| `distant approach` | *target*, *speed* | Moves on RCS to 50 m from the target, then stops |
| `close approach` | *target*, *speed* | Follows a path around the target's bounding box (A* search) to a point in front of its port |
| `final approach` | *port position*, *target*, *speed* | Flies straight in to dock, keeping sideways drift at zero |
| `align ports facing` | *target port* | Points the ship opposite the target port |
| `get own port`, `get best tgt port` | | Picks this ship's port, and a free, matching port on the target |
| `prepare port` | port | Opens a port's shield or doors |
| `cancel vel RCS` | *target* | Matches the target's speed using RCS |
| `cancel vel` | *target* | Matches the target's speed using the main engine |

**`mxfr`: moon transfer**

| Key | Inputs | What it does |
|---|---|---|
| `moon trans` | moon, periapsis | Plans the transfer burn from the moon's phase angle, then fine-tunes it to hit the periapsis you want at the moon |
| `capture` | *orbit altitude* | Adds a braking node at periapsis to capture into orbit |

**`pxfr`: planet transfer** (needs Astrogator)

| Key | Inputs | What it does |
|---|---|---|
| `planet trans` | planet, periapsis, *tolerance* | Adds the transfer node or nodes calculated by Astrogator |
| `node refine` | planet, periapsis, *tolerance* | Fine-tunes the next node toward the periapsis you want at the planet |
| `capture` | *orbit altitude* | Same as in `mxfr` |

**`mret`: moon return**

| Key | Inputs | What it does |
|---|---|---|
| `moon return` | periapsis at the planet | Plans the escape burn from a moon back to its planet, then fine-tunes it to that periapsis |
| `launch no atmo` | altitude, *inclination* | Launches from an airless body using a curved ascent profile |

**`land`: powered landing on airless bodies**

| Key | Inputs | What it does |
|---|---|---|
| `match landing lat` | target position, *final orbit altitude* | Plane change so the orbit passes over the target. See [Known issues](#known-issues). |
| `land align init` | target position | Warps until the target is ahead, then makes a rough correction to line up the ground track |
| `land align final` | target position | Fine alignment using RCS, then a braking burn to cancel horizontal speed over the target |
| `pwr land` | *radar offset*, *target*, *altitude offset* | Suicide-burn ("hoverslam") landing. It steers toward the target using the impact point from Trajectories, then reports where it landed. |

**`rtry`: reentry**

| Key | Inputs | What it does |
|---|---|---|
| `aero land` | *last stage*, *use RCS* | Below 200 km, drops spent stages, pushes away on RCS, points retrograde, and retracts antennas. Arms parachutes once below 20 km and slower than 280 m/s, then reports the landing site (with biome, if SCANsat is installed). |

### UTL: files and setup

| Key | What it does |
|---|---|
| `build MNV lex` | Loads the listed maneuver modules and their libraries into `MNV` (`"all"` loads every one) |
| `has file`, `has file contains`, `list file contains` | Finds files on a volume by exact name or partial name |
| `delete file`, `delete files`, `retrieve file`, `retrieve file list` | File management between volumes |
| `refresh mission files`, `refresh config files` | Copies this ship's missions and `.cfg` files from the archive |
| `update lexfiles`, `update libfiles`, `update bootfiles` | Copies the latest code from the archive, if the ship has a connection |
| `read config` | Reads `ship.cfg` into a lexicon |
| `write log` | Adds a line to the mission log |
| `write commands` | Writes a verb/noun command list to the archive, for the analog interface |
| `reboot`, `kill program` | Reboots, or stops the running program |

### UI: terminal

| Key | What it does |
|---|---|
| `run` | Starts the menu. `run(true)` starts the analog mode instead, where action groups 7, 8 and 9 run the first three missions. |
| `msg add` | Prints a message with mission time, and logs it |
| `abort stop`, `AG6 stop` | Return true when Abort or action group 6 is pressed |

### Libraries (`lib/`)

| File | Functions |
|---|---|
| `koos_mnv_lib` | `man_check_stage` (stages on flameout or no thrust) and `find_burntime` (burn duration from the rocket equation, across several stages) |
| `koos_obtcalc_lib` | Orbital math: `cpa` (closest approach to a target, found by bisection), `orbit_period`, `orbit_circumference`, `etatoaltitude2`, `pitchangle`, `findLaunchWindow` and `findLaunchWindowToTarget`, `plane_change_info`, `getLANForSunAngle`, `find_landing_tgt_LAN`, `eta_true_anom`, `circle_distance` (great-circle distance), `calc_lng_from_tgt`, `calc_ejection_UTC` |
| `koos_hillclimb_lib` | `hillclimb`, which nudges a maneuver node's time and burn direction until the result hits a target periapsis, closest approach, inclination or eccentricity within a tolerance |
| `koos_pathfinding_lib` | `get_path_to_apprpoint`, which finds a path around the target ship's bounding box to a point in front of its docking port (A* search) |
| `lib_LAZcalc` | `LAZcalc_init` and `LAZcalc`: launch heading for a target inclination, corrected for the body's rotation |
| `lib_enum` | `ENUM`: list helpers (`map`, `select`, `reduce`, `sort` and more), from KSLib |

## Optional mods

KOOS runs in plain kOS, but some functions use other mods when they're installed:

| Mod | Used for |
|---|---|
| Trajectories | Predicted impact point, for landing on target (`pwr land`, `land align final`) |
| Astrogator | Planet transfer burns (`pxfr`). Required for that module. |
| RealChute | Arming parachutes (`arm chutes`) |
| OhScrap! or Kerbalism | Detecting part failures (`check fail`, `prelaunch checks`) |
| An engine ignition-limit mod | `check ign` |
| SCANsat | Biome name in the landing report |

## Tools

- **`minify.sh` / `minifier.py`:** Rebuild the compact copies in `boot/`, `lex/` and `lib/` from `source/`. `minify.sh` passes a list of global names so the minifier won't rename them. Run `python minifier.py --help` for its options.
- **`scan_solver_3.py`:** A standalone Python tool by Benedict Thompson (MIT license). It finds the fastest orbit for a complete SCANsat surface scan, and isn't used by the kOS code.
- **`sunang.ks`:** A debug script that draws the sun, body and orbit vectors on screen and shows the angles used by `orbit sun angle`.

## Known issues

These turned up while reading through the code:

- **`change arg per`** calls `find_eta_to_true_anomaly`, which doesn't exist. The orbit library has `eta_true_anom` instead.
- **`match landing lat`**, when called without a final altitude, calls `find_landing_tgt_LAN_lowalt`, which doesn't exist. The Mun landing template passes an altitude, so it isn't affected.
- **`update bootfiles`** loops over the library files and uses an undefined variable `b`. It should loop over `BOOTFILES`.
- **The docking template** passes the target as a name (text), but `dock with vessel` expects a vessel. Changing the template to `vessel(targetname)` should fix it.
- **The Abort key** stops a mission only if `MIS["new"]` gets `true` as its 5th input. The templates instead list `UI["abort stop"]` as an interrupt, which only returns true or false and doesn't stop anything.
- **`ui:analog`** in `ship.cfg` is read but never used. The boot file always starts the digital menu.
- **`findLaunchWindow`** assumes a 6-hour day (Kerbin's) instead of using the body's actual rotation period.
- **`change per` and `capture`** are each defined in two modules. Whichever loads first is used. The copies are identical.
- **`lex/padtime.ks`** is a leftover test file and isn't used.

## Credits

Parts of the code are adapted from others, as noted in the source comments:

- Node execution: adapted from the kOS advanced tutorial and u/TheDapperScot
- Closest approach: adapted from CheersKevin
- Plane change: from a r/Kos post
- Phase angles: u/ollieshmollie and u/toukiedatak
- Capture burn: guidance from u/bdlarkin
- File helpers: u/DeOriginale69
- Mission time format: u/ElWanderer_KSP and u/farsyte
- `lib_enum`: KSLib team, MIT license
- `scan_solver_3.py`: Benedict Thompson, MIT license
