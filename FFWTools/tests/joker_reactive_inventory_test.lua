package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;'..package.path
local I,E=require('Inventory'),require('Effects')
local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function near(a,b,m) checks=checks+1;assert(type(a)=='number' and math.abs(a-b)<1e-8,m or ('expected '..b..', got '..tostring(a))) end
local function array(values) return {ForEach=function(_,fn) for k,v in ipairs(values) do fn(k,v) end end} end
local pawn={GetFullName=function() return 'BP_Player_C Local' end,IsLocallyControlled=function() return true end}
local ps={playerHeal=50,playerMaxHeal=100,itemHeroJokers=array({'jokerThickSkin'}),GetPawn=function() return pawn end}
local component={PlayerState=ps,jokerFightOrFlightValue=.4,GetFullName=function() return 'AC_PlayerStateJoker_C Local' end,GetAddress=function() return 17 end}
ps.AC_PlayerStateJoker=component
local active,cumulative,drought=true,2,false
local queries=0
FName=function(v) return {fname=v} end
StaticFindObject=function(path)
    local library={}
    if path=='/Script/Engine.KismetSystemLibrary' then
        function library:K2_IsTimerActive(object,func) eq(object,component);eq(func,'F_JokerHitMeHeal');return active end
    elseif path=='/Game/Gamework/BPFL_Gameplay.BPFL_Gameplay_C' then
        function library:F_IsModifierActive(id,world,out) eq(id.fname,'modifierDrought');eq(world,pawn);out.Active=drought end
    elseif path=='/Game/Gamework/BPFL_FunctionLibrary.BPFL_FunctionLibrary_C' then
        function library:F_GetJokerEffects(gi,id,item,world,has,value)
            eq(id.fname,'jokerHitMe');eq(item.fname,'itemHero');eq(world,component)
            has.isJokerEquiped=cumulative>0;value.jokerCumulativeValue=cumulative;queries=queries+1
        end
    else error('unexpected native lookup '..path) end
    return {GetCDO=function() return library end}
end
local gi={}
local first=I.readObjects(gi,ps,pawn)
eq(first.inputs.fightOrFlightValue,.4)
eq(first.inputs.hitMeActive,true)
eq(first.inputs.hitMeCachedValue,nil,'first active observation must not invent an old timer cache')
eq(first.inputs.droughtActive,false);eq(first.inputs.healingThickSkinCount,1)
eq(first.inputs.healingTargetIsGhost,false)
eq(I.observeBelowHeal(component,gi),true)
local s=I.readObjects(gi,ps,pawn)
eq(s.inputs.hitMeCachedValue,2)
local p=E.preview('jokerHitMe',{jokerHitMe=2},s.inputs)
near(p.current.metrics.currentHealPerSecond.value,1.5)
near(p.after.metrics.currentHealPerSecond.value,1.5,'candidate does not rewrite stored recovery')
near(p.after.metrics.nextTriggerHealPerSecond.value,2.25)
near(p.current.metrics.effectiveHealNextTick.value,1.05)
cumulative=3
eq(I.readObjects(gi,ps,pawn).inputs.hitMeCachedValue,2,'polling never updates stored count')
ps.playerHeal=100
eq(I.observeBelowHeal(component,gi),false,'full health exits before aggregate in the game')
eq(queries,1);eq(I.readObjects(gi,ps,pawn).inputs.hitMeCachedValue,2)
ps.playerHeal=70
eq(I.observeBelowHeal(component,gi),true);eq(queries,2)
eq(I.readObjects(gi,ps,pawn).inputs.hitMeCachedValue,3)
active=false
eq(E.evaluate('jokerHitMe',3,I.readObjects(gi,ps,pawn).inputs).metrics.currentHealPerSecond.value,0)
function component:GetAddress() return 18 end
eq(I.readObjects(gi,ps,pawn).inputs.hitMeCachedValue,nil,'new component cannot inherit another mission cache')
function pawn:IsLocallyControlled() return false end
eq(I.observeBelowHeal(component,gi),false);eq(queries,2)
print('joker_reactive_inventory_test: '..checks..' checks passed')
