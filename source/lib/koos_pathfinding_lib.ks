//@lazyglobal off.
runOncePath(DATAVOLUME+":/lib/lib_enum").
 
	function get_path_to_apprpoint {
    parameter tgt to target.
    LOCAL B TO "".
    // local tshooting to true.
    local buffer to ship:bounds:relmax:mag * 2.
    if tgt:istype("Vessel"){set B to tgt:bounds.}
      else if tgt:istype("Part"){set B to tgt:ship:bounds.
      }
    local apoint to tgt:nodeposition+tgt:PORTFACING:VECTOR*(B:RELMAX:MAG+(ship:bounds:relmax:mag * 2)).
    local c to get_corners(B,buffer).
    // if tshooting {
    //   runPath("0:/koos_tgt_bounds_tshoot.ks").
    // }
     
    local c_copy to c:copy.
    c_copy:add(apoint).
    return a_star(ship:position,apoint,c,getneighbors@:bind(noboxintersect@:bind(B),c_copy)).
  }
function lineboxintersects{
  parameter B, v0 to ship:position, v1 to target:nodeposition+target:PORTFACING:VECTOR *B:RELMAX:MAG.
  local a_corr to target:ship:facing:inverse. //axis corection
  set v0 to v0 * a_corr.
  set v1 to v1 * a_corr.
    local infinity is 1.7976931348623157E+308.
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
  
    if v1:y<>0{
    local ty1 to (vmin:y - v0:y)/v1:y.
    local ty2 to (vmax:y - v0:y)/v1:y.
    set tmin to max(tmin, min(ty1, ty2)).
    set tmax to min(tmax, max(ty1, ty2)).
    } 
  
    return tmax>tmin.
}
function get_corners {
  parameter B, buffer to ship:bounds:relmax:mag.
  local rn to B:relmin:normalized * (B:relmin:mag + buffer).
  local rx to B:relmax:normalized * (B:relmax:mag + buffer).
  local ao to B:ABSORIGIN.
  local f to B:FACING.
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
        returnlist:add(n).
      }
    }
  }
  return returnlist.
}
function a_star {
  parameter start, goal, nodes, neighbors.
  local infinity is 1.7976931348623157E+308.
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
    total_path:add(current).
    until not parent:haskey(current) {
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
  open_q:push(start).
  local i to 0.
  until open_q:length = 0 {
    set open_q to Enum["sort"](open_q,compare_f_ascending@).
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