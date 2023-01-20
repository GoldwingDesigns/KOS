@lazyGlobal off.

run koos_utils_lib_L.
// print "missions/"+ship:name.
// local p to path("0:/missions/"+ship:name).
// print exists(p).
// print UTL["has file"]("missions/"+ship:name,0).

print UTL["retrieve file list"](list("dummyfile.ks","muntest_t.ks"),0,"",1,"testy").
UTL["refresh mission files"]().