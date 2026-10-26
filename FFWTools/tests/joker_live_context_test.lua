package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;'..package.path
local I,E=require('Inventory'),require('Effects')
local F=I.fields;local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function near(a,b,m) checks=checks+1;assert(type(a)=='number' and math.abs(a-b)<1e-8,m or ('expected '..b..', got '..tostring(a))) end
local function collection(t) return {ForEach=function(_,fn) for k,v in pairs(t) do fn(k,v) end end} end
local progress={[F.primary]='itemBow',[F.secondary]='itemBanjo',[F.equipped]=collection({}),[F.upgrades]=collection({})}
local manager={rageBar_Knuckles=.4,ragebar_Lasso=.6,isUsingJetpackAntigrav=false,banjoHitAmount=4}
local gi={playerProgress=progress,refItemManager=manager}
local gameState={F_GetLocalGolds=function(_,out) out.AvailableGolds=80 end,F_GetLocalSouls=function(_,out) out.AvailableSouls=125 end}
local cdodata={[F.ammoMaximum]=30,[F.ammoCurrent]=30}
local cdo={defaultItemDatas=cdodata}
local held={itemName='itemBow',isAiming=false,slowPlayerDuringAim=true,canBeAffectedByPlayerFireRate=true,
 isFixedAmountCount=false,timeHoldedDraw=1.25,element=9,gameInstance=gi,
 defaultItemDatas={[F.ammoMaximum]=999,[F.ammoCurrent]=999}}
function held:GetClass() return {GetCDO=function() return cdo end} end
function held:GetFullName() return 'BP_Item_Bow_C Held' end
function held:ActorHasTag(tag) eq(type(tag),'table');return false end
function held:F_GetItemDatas(out)
 out[F.initialized]=true;out[F.magazine]=1;out[F.ammoMaximum]=36;out[F.ammoCurrent]=20
 out.maxMagazineAmmos_8_E1B199D345F51D5DF152DBBB0371E153=1
end
function held:F_GetReloadSpeed(out) out.ReloadSpeed=2 end
function held:F_GetAttackSpeed(base,out) eq(base,1);out.AttackSpeed=1.4 end
local pawn={AC_PlayerItems={equipedItem=held},gameState=gameState,buffGravity=0,
 CharacterMovement={GravityScale=1.25,MaxWalkSpeed=660,IsSwimming=function() return false end}}
function pawn:GetFullName() return 'BP_Player_C Local' end
function pawn:F_IsOnGround(_,out) out.OnGround=true end
function pawn:F_IsRunning(out) out.Running=false end
function pawn:GetVelocity() return {X=0,Y=0,Z=0} end
local joker={playerLocalJokers=collection({'jokerSpareBullets','jokerSpeedster'}),jokerCoinFlipBonus=false,magicReloadProc=true}
local ps={playerHeal=60,playerMaxHeal=100,AC_PlayerStateJoker=joker,itemHeroJokers=collection({}),
 AC_PlayerState_Shield={shieldPoints=5,isJokerScoutsHonorStillEnabled=false}}
FName=function(s) return {fname=s} end
StaticFindObject=function(path)
 local lib={}
 if path=='/Script/Engine.KismetSystemLibrary' then function lib:K2_IsTimerActive() return false end
 elseif path=='/Game/Gamework/BPFL_Gameplay.BPFL_Gameplay_C' then
  function lib:F_IsModifierActive(id,world,out) eq(world,pawn);out.Active=id.fname=='modifierGreed' end
 else error('unexpected library '..path) end
 return {GetCDO=function() return lib end}
end
local s=I.readObjects(gi,ps,pawn);local bow=I.group(s,'itemBow');local hero=I.group(s,'itemHero')
eq(bow.inputs.magazineMaximum,1);eq(bow.inputs.ammoMaximum,36)
eq(bow.inputs.defaultAmmoMaximum,30,'capacity base is CDO, never mutated instance defaultItemDatas')
eq(hero.inputs.defaultAmmoCurrent,30);eq(hero.inputs.isFixedAmountCount,false)
eq(hero.inputs.magazineAmmo,1);eq(hero.inputs.consumerEquipped,false);eq(hero.inputs.consumerAvailable,I.applies('jokerConsumer','itemBow'))
eq(s.inputs.coinFlipBonus,false);eq(s.inputs.magicReloadProc,true);eq(s.inputs.scoutsHonorActive,false)
eq(s.inputs.modifierGreed,true);eq(s.inputs.missionGold,80);eq(s.inputs.missionSouls,125)
eq(s.inputs.maxWalkSpeed,660);eq(s.inputs.swimming,false)
eq(s.inputs.isSwappingWeapon,nil,'function-local jump-update argument is not a persistent Pawn field')
eq(bow.inputs.timeHoldedDraw,1.25);eq(bow.inputs.weaponElement,9);near(bow.inputs.attackSpeed,1.4)
eq(I.group(s,'itemBanjo').inputs.attackSpeed,nil,'held-bow cache cannot leak into an unequipped Banjo')
near(E.evaluate('jokerSpareBullets',2,hero.inputs).metrics.reserveCapacityDelta.value,6)
near(E.evaluate('jokerSpeedster',1,bow.inputs).metrics.damageBonus.value,1/15)
held.itemName='itemBanjo';held.additionalChords=2;held.bardbarianDamages=50
s=I.readObjects(gi,ps,pawn);local banjo=I.group(s,'itemBanjo')
eq(banjo.inputs.additionalChords,2);eq(banjo.inputs.banjoAdditionalChords,2)
eq(banjo.inputs.bardbarianStoredDamage,50);eq(banjo.inputs.banjoHitAmount,4)
eq(banjo.inputs.knucklesCharge,.4);eq(banjo.inputs.lassoCharge,.6);eq(banjo.inputs.jetpackAntigravActive,false)
function held:GetClass() error('class unavailable') end
s=I.readObjects(gi,ps,pawn)
eq(I.group(s,'itemHero').inputs.defaultAmmoMaximum,nil,'CDO read failure must not use boosted instance data')
eq(next(s.readErrors)~=nil,true)
print('joker_live_context_test: '..checks..' checks passed')
