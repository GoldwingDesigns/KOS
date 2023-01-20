run koos_ves_lib_L.

local VES1 to VES["new"](ship).

print VES1["&name"]().
print VES1["&commslist"]().
print VES1["&chuteslist"]().
// print VES1["&failablelist"]().

VES1["comms ext"]().
wait 10.
VES1["comms ret"]().