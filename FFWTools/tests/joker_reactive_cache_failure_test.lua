package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;'..package.path
local I,E=require('Inventory'),require('Effects')
local pawn={GetFullName=function()return 'BP_Player_C Local'end,IsLocallyControlled=function()return true end}
local ps={playerHeal=50,playerMaxHeal=100,GetPawn=function()return pawn end}
local component={PlayerState=ps,GetFullName=function()return 'AC_PlayerStateJoker_C Local'end,GetAddress=function()return 41 end}
ps.AC_PlayerStateJoker=component
local amount,fail=2,false
FName=function(s)return s end
StaticFindObject=function(p)
 local lib={}
 function lib:K2_IsTimerActive()return true end
 function lib:F_IsModifierActive(_,_,out)out.Active=false end
 function lib:F_GetJokerEffects(_,_,_,_,has,value)
  if fail then error('new aggregate read failed') end
  has.isJokerEquiped=amount>0;value.jokerCumulativeValue=amount
 end
 return {GetCDO=function()return lib end,IsValid=function()return false end}
end
local failures={};local function check(v,m)if not v then failures[#failures+1]=m end end
local gi={}
check(I.observeBelowHeal(component,gi),'initial cache observation failed')
check(I.readObjects(gi,ps,pawn).inputs.hitMeCachedValue==2,'initial cache missing')
amount=3;fail=true
local ok,err=pcall(I.observeBelowHeal,component,gi)
check(not ok and tostring(err):find('new aggregate read failed',1,true),'new observation failure must retain diagnostic')
local inputs=I.readObjects(gi,ps,pawn).inputs
check(inputs.hitMeCachedValue==nil,'failed new trigger reused an old known cache')
check(E.evaluate('jokerHitMe',3,inputs).metrics.currentHealPerSecond.value==nil,'failed observation displayed stale healing as current')
fail=false;check(I.observeBelowHeal(component,gi),'cache did not recover')
inputs=I.readObjects(gi,ps,pawn).inputs
check(inputs.hitMeCachedValue==3 and E.evaluate('jokerHitMe',3,inputs).metrics.currentHealPerSecond.value==2.25,'successful later trigger did not restore actual rate')
ps.playerHeal=100
check(not I.observeBelowHeal(component,gi),'known full-health event must not recalculate')
check(I.readObjects(gi,ps,pawn).inputs.hitMeCachedValue==3,'known ineligible event wrongly discarded valid cache')
ps.playerHeal=nil
check(not I.observeBelowHeal(component,gi),'unknown eligibility must not invent a trigger')
check(I.readObjects(gi,ps,pawn).inputs.hitMeCachedValue==nil,'unread eligibility retained stale current rate')
assert(#failures==0,table.concat(failures,'; '));print('joker_reactive_cache_failure_test passed')
