@lazyglobal off.
run lib_enum.ks.
//
//  display_bounds.ks
//  -----------------
//
// A small example program that will show you how to
// read the BOUNDS information of Vessels and Parts,
// and will display the box as a set of Vecdraws.
// You may iterate over the parts with the N and P
// keys. (The "-1 th" part is to show the whole
// vessel's box).
//

// Because this example uses lots of delegates
// in its VECDRAWs, it needs the time to keep running
// those delegates each update, or else it really
// bogs down:
// if CONFIG:IPU < 500 {
//   set CONFIG:IPU to 500.
//   HUDTEXT("NOTICE: EXAMPLE SCRIPT INCREASED CONFIG:IPU TO " + CONFIG:IPU,
//     20, 2, 22, magenta, true).
// }

// =======================================
// These are some utility functions for this
// example program to help display things:
// =======================================

function vector_tostring_rounded {
  // Same thing that vector:tostring() normally
  // does, but with more rounding so the display
  // doesn't get so big:
  parameter vec.

  return "V(" +
    round(vec:x,2) + ", " +
    round(vec:y,2) + ", " +
    round(vec:z,2) + ")".
}

local arrows is LIST().
function draw_abs_to_box {
  // Draws the vectors from origin TO the 2 opposite corners of the box:

  parameter B.

  // Wipe any old arrow draws off the screen.
  for arrow in arrows { set arrow:show to false. }
  wait 0.

  arrows:CLEAR().
  if target:istype("Part"){
  arrows:ADD(Vecdraw(
    {return target:ship:PARTS[0]:POSITION.}, {return B:FACING * B:RELMIN.}, RGB(1,0,0.75), "ABSMIN", 1, true)).
  arrows:ADD(Vecdraw(
    {return target:ship:PARTS[0]:POSITION.}, {return B:FACING *B:RELMAX.}, RGB(1,0,0.75), "ABSMAX", 1, true)).
  }
}
local vectors is LIST().
function draw_app_point {
  parameter B.
  for v in vectors { set v:show to false. }
  wait 0.
  local distance to B:RELMAX:MAG.
  lock approachpoint TO target:PORTFACING:VECTOR * distance.
  lock shiptoapprvec to target:nodeposition+approachpoint.
  vectors:clear().
  vectors:add(Vecdraw({return target:NODEPOSITION.}, {return approachpoint.}, RGB(0.5,0.5,0.75), "apprpoint", 1, true)).
  // vectors:add(Vecdraw({return V(0,0,0).}, {return shiptoapprvec.}, RGB(0.5,0.5,0.75), "shiptoappr", 1, true)).
  // vectors:add(Vecdraw({return V(0,0,0).}, {return B:absmax.}, RGB(0.5,0.5,0.75), "absmaxfromship", 1, true)).

    // vectors:add(
    //   Vecdraw(
    // {return target:ship:position.}, {return target:ship:facing:topvector*5.}, green, "Y", 1, true)).
    // vectors:add(
    //   Vecdraw(
    // {return target:ship:position.}, {return target:ship:facing:starvector*5.}, red, "X", 1, true)).
    // vectors:add(Vecdraw(
    // {return target:ship:position.}, {return target:ship:facing:forevector*5.}, blue, "Z", 1, true)).
}
local pV is List().
function path_vectors{
  parameter pL.
  local newL to list().
  for p in PL {
    newL:add(p-target:position).
  }
for v in pV { set v:show to false. }
  wait 0.
  local wtf to newL[1].
  pV:clear().
  pV:add(
  Vecdraw(
    {return v(0,0,0).}, {return newL[1]+target:position.}, yellow, "path0", 1, true)).
  local i is 1.
  UNTIL i > newL:length-2 {
  local p1 to newL[i].
  local p2 to newL[i+1].
  pV:add(
      Vecdraw(
    {return p1+target:position.}, {return p2-p1.}, yellow, "path"+i, 1, true)).
  // Vecdraw(
  //   {return p1+target:position.}, {return p2+target:position.}, yellow, "path"+i, 1, true)).
  set i to i+1.
  }
}
function lineboxintersects{
  parameter B, v0 to ship:position, v1 to target:nodeposition+target:PORTFACING:VECTOR *B:RELMAX:MAG.
  local a_corr to target:ship:facing:inverse. //axis corection
  // print ("testing: "+vector_tostring_rounded(v0)+" to "+vector_tostring_rounded(v1)).
  set v0 to v0 * a_corr.
  set v1 to v1 * a_corr.
  // print "v0: " + vector_tostring_rounded(v0).
  // print "v1: " + vector_tostring_rounded(v1).
  // local distance to B:RELMAX:MAG.
  // local approachpoint TO target:PORTFACING:VECTOR * distance.
  // local shiptoapprvec to (target:nodeposition+approachpoint).
  // print b:absorigin:x.
  // print b:absorigin:y.
  // print b:absorigin:z.
  // PRINT "absmin"+(a_corr*(b:absmin)):x.
  // PRINT "absmax"+(a_corr*(b:absmAX)):x.
  // PRINT "v0x"+v0:x.
  // PRINT "v1x"+v1:x.
  // print "issame?" + (abs(v0:x-v1:x) < 0.1 or abs(v1:x-v0:x)< 0.1).
  // PRINT (target:ship:facing:inverse*ship:position):X.
  // PRINT (target:ship:facing:inverse*shiptoapprvec):x.
    // local tx1 to ((target:ship:facing:inverse*(b:absmin)):x - (target:ship:facing:inverse*ship:position):x)/(target:ship:facing:inverse*shiptoapprvec):x.
    // local tx2 to ((target:ship:facing:inverse*(b:absmax)):x - (target:ship:facing:inverse*ship:position):x)/(target:ship:facing:inverse*shiptoapprvec):x.

    // local tmin to min(tx1, tx2).
    // local tmax to max(tx1, tx2).

    // local ty1 to ((target:ship:facing:inverse*(b:absmin)):y - (target:ship:facing:inverse*ship:position):y)/(target:ship:facing:inverse*shiptoapprvec):y.
    // local ty2 to ((target:ship:facing:inverse*(b:absmax)):y - (target:ship:facing:inverse*ship:position):y)/(target:ship:facing:inverse*shiptoapprvec):y.

    // set tmin to max(tmin, min(ty1, ty2)).
    // set tmax to min(tmax, max(ty1, ty2)).

    // local tz1 to ((target:ship:facing:inverse*(b:absmin)):z - (target:ship:facing:inverse*ship:position):z)/(target:ship:facing:inverse*shiptoapprvec):z.
    // local tz2 to ((target:ship:facing:inverse*(b:absmax)):z - (target:ship:facing:inverse*ship:position):z)/(target:ship:facing:inverse*shiptoapprvec):z.

    // set tmin to max(tmin, min(tz1, tz2)).
    // set tmax to min(tmax, max(tz1, tz2)).
    // print tmax.
    // print tmin.
    local infinity is 1.7976931348623157E+308.
    // return tmax >= tmin and (abs(tmax)<1 or abs(tmin)<1).
    local tmin to -infinity.
    local tmax to infinity.
    local vmin to a_corr*(b:absmin).
    local vmax to a_corr*(b:absmax).
    if v1:x<>0{
    local tx1 to (vmin:x - v0:x)/v1:x.
    local tx2 to (vmax:x - v0:x)/v1:x.
    set tmin to max(tmin, min(tx1, tx2)).
    set tmax to min(tmax, max(tx1, tx2)).
    } 
    // else if (v0:x <= vmin:x or v0:x >= vmax:x) {
    //   return false.
    // }

    if v1:y<>0{
    local ty1 to (vmin:y - v0:y)/v1:y.
    local ty2 to (vmax:y - v0:y)/v1:y.
    set tmin to max(tmin, min(ty1, ty2)).
    set tmax to min(tmax, max(ty1, ty2)).
    } 
    // else if (v0:y <= vmin:y or v0:y >= vmax:y) {
    //   return false.
    // }
//got rid of z.  I htink it was messing everything up... maybe bc of left hand coord sys?
    // if v1:z<>0{
    // local tz1 to (vmin:z - v0:z)/v1:z.
    // local tz2 to (vmax:z - v0:z)/v1:z.
    // set tmin to max(tmin, min(tz1, tz2)).
    // set tmax to min(tmax, max(tz1, tz2)).
    // } 
    // else if (v0:z <= vmin:z or v0:z >= vmax:z) {
    //   return false.
    // }
    // print tmax.
    // print tmin.
    // if tmax > tmin { print("intersects"). return true.}
    return tmax>tmin.
    // return round(tmax,2) >= round(tmin,2) and (abs(tmax)<1 or abs(tmin)<1).
    // return  abs(tmax-tmin)>0.1 and (abs(tmax)>0.01 and abs(tmin)>0.01).
    // return  tmax >= tmin and (abs(tmax)<1 or abs(tmin)<1) and ((tmax>0 and tmin>0)or(tmax<0 and tmin<0)).
    // return (tmax < 1 and tmin > 0.004) or (-tmax > -1 and -tmin < -0.004) or tmax-tmin >0.1.

}
function get_corners {
  parameter B, buffer to ship:bounds:relmax:mag.
  local rn to B:relmin:normalized * (B:relmin:mag + buffer).
  local rx to B:relmax:normalized * (B:relmax:mag + buffer).
  local ao to B:ABSORIGIN.
  local f to B:FACING.
  // until false {
  //   print(ao + f * V(rn:X, rn:Y, rn:Z)). 
  // }
  // Vecdraw({return V(0,0,0).}, {return ao + f * V(rn:X, rn:Y, rn:Z).}, green, "shiptoV0", 1, true).
  return list(ao + f * V(rn:X, rn:Y, rn:Z),ao + f * V(rn:X, rn:Y, rx:Z),ao + f * V(rn:X, rx:Y, rn:Z),ao + f * V(rn:X, rx:Y, rx:Z),ao + f * V(rx:X, rn:Y, rn:Z),ao + f * V(rx:X, rn:Y, rx:Z),ao + f * V(rx:X, rx:Y, rn:Z),ao + f * V(rx:X, rx:Y, rx:Z)).
}
function noboxintersect {
  parameter Box, a, b.
  return not lineboxintersects(Box, a, b).
  // return not lineboxintersects(Box, a, b) and not lineboxintersects(Box, b, a).
}
function getneighbors {
  parameter clearpath,//delegate returning a clearpath from a to b
  n_list, //list of all nodes.
  current.
  local returnlist to list().
  for n in n_list {
    if n <> current {
      if clearpath(current,n){
        // print(vector_tostring_rounded(current)+" has neigh "+vector_tostring_rounded(n)).
        returnlist:add(n).
      }
    }
  }
  return returnlist.
}
function get_path_to_apprpoint {
  parameter B to target:ship:bounds, apoint to target:nodeposition+target:PORTFACING:VECTOR *B:RELMAX:MAG.
  local c to get_corners(B).
  //c:add(ship:position).
  local c_copy to c:copy.
  c_copy:add(apoint).
  return a_star(ship:position,apoint,c,getneighbors@:bind(noboxintersect@:bind(B),c_copy)).
}
function a_star {
  parameter start, goal, nodes, neighbors.
  // print nodes[0].
  local infinity is 1.7976931348623157E+308.
  // print("goal is: "+vector_tostring_rounded(goal)).
  local F is lex().
  local G is lex().
  local H is lex().
  local parent is lex().
  local open_q is queue().
  // local closed is list().
  function compare_f_ascending {
  parameter a, b. return F[a] - F[b].
  }
  function node_dist {
  parameter a, b. return abs((a-b):MAG).
  }
  function h_score {
  parameter a. return node_dist(a,goal).
  }
  function reconstruct_path {
    parameter current. 
    local total_path to list().
    // print "top node is: "+current+" and its parent is "+parent[current].
    total_path:add(current).
    until not parent:haskey(current) {
      // print "next node is: "+current+" and its parent is "+parent[current].
      set current to parent[current].
      
      total_path:insert(0,current).
    }
    return total_path.
  }
  for n in nodes {
    F:add(n,infinity).
    G:add(n,infinity).
    H:add(n,infinity).
    parent:add(n,"").
  }
  G:add(goal,infinity).
  F:add(goal,infinity).
  F:add(start,h_score(start)).
  G:add(start,0).
  // print("this is Glex: "+G:keys).
  open_q:push(start).
  local i to 0.
  until open_q:length = 0 {

    set open_q to Enum["sort"](open_q,compare_f_ascending@).
    //     print("run "+i+" and queue looks like... ").
    // for o in open_q {
    //   print(vector_tostring_rounded(o)).
    // }
    // print("end q").
    local current to open_q:pop.
    if current = goal {return reconstruct_path(current).}
    for b in neighbors(current) {
 
      local temp_g to G[current] + node_dist(current,b).
      if temp_g < G[b] {
        set parent[b] to current.
        set G[b] to temp_g.
        set F[b] to temp_g + h_score(b).
        if not open_q:contains(b) {open_q:push(b).}
      }
    }
    set i to i+1.
  } 
  return list().
}
local edges is LIST().
function draw_box {
  // Draws a bounds box as a set of 12 non-pointy
  // vecdraws along the box edges:
  parameter B.

  // Wipe any old edge draws off the screen.
  for edge in edges { set edge:show to false. }
  wait 0.

  // These need to calculate using relative coords to find all the box edges:
  local rel_x_size is B:RELMAX:X - B:RELMIN:X.
  local rel_y_size is B:RELMAX:Y - B:RELMIN:Y.
  local rel_z_size is B:RELMAX:Z - B:RELMIN:Z.

  edges:CLEAR().

  // The 4 edges parallel to the relative X axis:

  edges:ADD(Vecdraw(
    {return B:ABSORIGIN + B:FACING * V(B:RELMIN:X, B:RELMIN:Y, B:RELMIN:Z).},
    {return B:FACING * V(rel_x_size, 0, 0).},
    RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
  edges:ADD(Vecdraw(
    {return B:ABSORIGIN + B:FACING * V(B:RELMIN:X, B:RELMIN:Y, B:RELMAX:Z).},
    {return B:FACING * V(rel_x_size, 0, 0).},
    RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
  edges:ADD(Vecdraw(
    {return B:ABSORIGIN + B:FACING * V(B:RELMIN:X, B:RELMAX:Y, B:RELMAX:Z).},
    {return B:FACING * V(rel_x_size, 0, 0).},
    RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
  edges:ADD(Vecdraw(
    {return B:ABSORIGIN + B:FACING * V(B:RELMIN:X, B:RELMAX:Y, B:RELMIN:Z).},
    {return B:FACING * V(rel_x_size, 0, 0).},
    RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).

  // The 4 edges parallel to the relative Y axis:
  edges:ADD(Vecdraw(
    {return B:ABSORIGIN + B:FACING * V(B:RELMIN:X, B:RELMIN:Y, B:RELMIN:Z).},
    {return B:FACING * V(0, rel_y_size, 0).},
    RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
  edges:ADD(Vecdraw(
    {return B:ABSORIGIN + B:FACING * V(B:RELMIN:X, B:RELMIN:Y, B:RELMAX:Z).},
    {return B:FACING * V(0, rel_y_size, 0).},
    RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
  edges:ADD(Vecdraw(
    {return B:ABSORIGIN + B:FACING * V(B:RELMAX:X, B:RELMIN:Y, B:RELMAX:Z).},
    {return B:FACING * V(0, rel_y_size, 0).},
    RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
  edges:ADD(Vecdraw(
    {return B:ABSORIGIN + B:FACING * V(B:RELMAX:X, B:RELMIN:Y, B:RELMIN:Z).},
    {return B:FACING * V(0, rel_y_size, 0).},
    RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).

  // The 4 edges parallel to the relative Z axis:
  edges:ADD(Vecdraw(
    {return B:ABSORIGIN + B:FACING * V(B:RELMIN:X, B:RELMIN:Y, B:RELMIN:Z).},
    {return B:FACING * V(0, 0, rel_z_size).},
    RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
  edges:ADD(Vecdraw(
    {return B:ABSORIGIN + B:FACING * V(B:RELMIN:X, B:RELMAX:Y, B:RELMIN:Z).},
    {return B:FACING * V(0, 0, rel_z_size).},
    RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
  edges:ADD(Vecdraw(
    {return B:ABSORIGIN + B:FACING * V(B:RELMAX:X, B:RELMAX:Y, B:RELMIN:Z).},
    {return B:FACING * V(0, 0, rel_z_size).},
    RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
  edges:ADD(Vecdraw(
    {return B:ABSORIGIN + B:FACING * V(B:RELMAX:X, B:RELMIN:Y, B:RELMIN:Z).},
    {return B:FACING * V(0, 0, rel_z_size).},
    RGBA(1,0,1,0.75), "", 1, true, 0.02, false, false)).
}

//
// ===============================
//        main program
// ===============================
//

local pNum is -1.
local keyPress is "".
// local tname is "Station - 1".
// set target to tname.
clearVecDraws().
until keyPress = "q" {

  local box is 0. // will get set to the bounds box in a moment.
  local description is "".

  clearscreen.

  if pNum = -1 {
    // PART NUMBER -1 will be a special flag this
    // example program uses to mean "entire vessel".
    if target:istype("Vessel"){set box to target:bounds.
    set description to target:TOSTRING().}
    else if target:istype("Part"){set box to target:ship:bounds.
    set description to target:ship:TOSTRING().
    }
    
  } else {
    local p is target:parts[pNum].
    set box to p:bounds.
    set description to "Part[" + pNum + "]:" + p:TOSTRING().
  }

  // These two functions do the actual drawing, and are defined
  // below in this file.  When trying to learn how this works,
  // look at draw_abs_to_box() first - it's the simpler one to
  // understand that just uses absolute coordinates.  The other
  // one, draw_box(), is more complex as it has to use the
  // relative coords to get all the other corners of the box:
  // draw_abs_to_box(box).
  // draw_box(box).
  local path_list is list().
  if target:istype("Part"){
  draw_app_point(box).
  set path_list to get_path_to_apprpoint(box).
  IF path_list:length > 0 {path_vectors(path_list).}
  }

  print "Showing bounds of: " + description.
  print "-----------------------------------------------------------".
  print "        ABSMIN: " + vector_tostring_rounded(box:ABSMIN).
  print "        ABSMAX: " + vector_tostring_rounded(box:ABSMAX).
  print "     ABSORIGIN: " + vector_tostring_rounded(box:ABSORIGIN).
  print "     ABSCENTER: " + vector_tostring_rounded(box:ABSCENTER).
  print "        RELMIN: " + vector_tostring_rounded(box:RELMIN).
  print "        RELMAX: " + vector_tostring_rounded(box:RELMAX).
  print "       EXTENTS: " + vector_tostring_rounded(box:EXTENTS).
  print "          SIZE: " + vector_tostring_rounded(box:SIZE).
  print "     RELCENTER: " + vector_tostring_rounded(box:RELCENTER).
  print "     BOTTOMALT: " + round(box:BOTTOMALT,2).
  print "BOTTOMALTRADAR: " + round(box:BOTTOMALTRADAR,2).
  // if target:istype("Part"){
  // // print "     INTERSECT: " + lineboxintersects(box).
  // for n in path_list{
  //   print vector_tostring_rounded(n).
  // }
  // }
  print "-----------------------------------------------------------".
  print "Press N for next, P for previous, Q for quit.".


  set keyPress to terminal:input:getchar().
  if keyPress = "n" set pNum to min(ship:parts:length-1, pNum + 1).
  if keyPress = "p" set pNum to max(-1, pNum - 1).

  clearvecdraws().
}