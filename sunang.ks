
clearvecdraws().
clearscreen.
vecdraw({return body:position.},{return (sun:position):normalized * 10000000.},red,"",1,true).
vecdraw({return body:position.},{return ((-1*body:position)):normalized * 10000000.},blue,"",1,true).
vecdraw({return body:position.},{return solarprimevector:normalized * 10000000.},white,"",1,true).
vecdraw({return body:position.},{return vcrs(vcrs(ship:orbit:velocity:orbit,body:position),body:angularvel):normalized * 10000000.},green,"",1,true).
until false {
printat(vang(-1*(body:orbit:position-body:body:position),(ship:orbit:position-body:position)),0,0).
local ind to vcrs((body:body:position):normalized,(solarPrimeVector):normalized):y.
local ang is vang((body:body:position),(solarPrimeVector)).
if ind < 0 set ang to 360-ang.
printat("sunpos: "+ang,0,1).
printat("current lan: "+obt:lan,0,2).
printat("LAN for 90: "+getLANForSunAngle(90,90),0,3).
// printat("LAN for 90,45: "+getLANForSunAngle(90,45),0,4).
// printat("LAN for 90,90: "+getLANForSunAngle(90,90),0,5).
}

function getLANForSunAngle{
  parameter maxSunAngle is 90, minSunAngle is 0.
  local sunpos is vang((sun:position),(solarPrimeVector)).
  local ind is vcrs((sun:position):normalized,(solarPrimeVector):normalized):y.
  if ind < 0 set sunpos to 360-sunpos.
  local desiredSunAngle is (maxSunAngle+minSunAngle)/2.
  local lan1 is sunpos-desiredSunAngle.
  local lan2 is sunpos+desiredSunAngle.
  set lan1 to mod(lan1+720,360).
  until lan2<360 {set lan2 to lan2-360.}
  local curLan is obt:lan.
  if obt:inclination> 0 {
    if abs(curLan-lan1)<90 return lan1.
    else return lan2.
  } else {
    if abs(curLan-lan1)<90 return lan2.
    else return lan1.
  }
}