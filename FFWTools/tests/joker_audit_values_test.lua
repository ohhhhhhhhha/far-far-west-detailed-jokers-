package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;FFWTools/src/Common/?.lua;'..package.path
local E=require('Effects');local I=require('Inventory');local P=require('Panel')
local errors={};local function check(v,m) if not v then errors[#errors+1]=m end end
local ok,r=pcall(E.evaluate,'jokerLazy',0,{itemName='itemMinigun'})
check(ok and r.metrics.magazineAfterTick.value==nil,'missing minigun ammo must not crash or fabricate a total')
local s=I.fromSnapshot{selected={primary='itemPistol',secondary='itemBow'},equipped={},upgrades={},runtime={},inputs={spells={{slot='A',element='Fire',remaining=20}}}}
local t,style=P.description('jokerApprentice',s,nil,'pickup')
check(not style.noBonus,'missing base cooldown must remain unknown')
local prev=E.preview('jokerApprentice',I.group(s,'itemHero').counts,I.group(s,'itemHero').inputs)
check(not prev.complete,'missing base cooldown cannot be complete')
local cards={};for n=1,129 do cards[n]='jokerWellFed' end
s=I.fromSnapshot{selected={primary='itemPistol',secondary='itemBow'},equipped={},upgrades={},runtime=cards}
t,style=P.description('jokerWellFed',s,nil,'pickup');check(style.noBonus,'999 -> 999 health must not show extra benefit')
t,style=P.description('jokerWellFed',s,nil,'current');check(not style.noBonus and t:find('999',1,true),'held capped health must retain current total')
s=I.fromSnapshot{selected={primary='itemPistol',secondary='itemBow'},equipped={},upgrades={},runtime=cards,inputs={gold=0}};t,style=P.description('jokerCheapSkate',s,nil,'pickup');check(style.noBonus,'health at 999 must not reintroduce a hypothetical gold bonus')
s=I.fromSnapshot{selected={primary='itemMinigun'},equipped={},upgrades={itemMinigun={jokerUpgradeAccuracy=20}},runtime={}}
t,style=P.description('jokerUpgradeAccuracy',s,'itemMinigun','pickup');check(style.noBonus,'zero spread at 20 -> 21 accuracy must remain capped')
s=I.fromSnapshot{selected={primary='itemBanjo'},equipped={itemBanjo={'jokerLullabard'}},upgrades={},runtime={},inputs={attackSpeed=1}}
t,style=P.description('jokerBardbarian',s,'itemBanjo','pickup');check(style.noBonus,'disabled heavy attack cannot gain usable Bardbarian damage')
s=I.fromSnapshot{equipped={},upgrades={},runtime=cards,inputs={maxHealth=850}}
t,style=P.description('jokerWellFed',s,nil,'pickup');check(not style.noBonus and t:find('850',1,true),'unmodelled live health correction must not be declared capped')
s=I.fromSnapshot{equipped={},upgrades={},runtime={},inputs={modifierGreed=true}}
t,style=P.description('jokerJokheal',s,nil,'pickup');check(style.noBonus,'Greed blocks actual pickup healing even if raw card contribution rises')
local uncertain=E.evaluate('jokerJokheal',1,{})
check(uncertain.metrics.pickupHeal.value==nil and uncertain.metrics.pickupHeal.potential==85,'unknown Greed must remain a labelled potential')
-- A valid spell whose CDO fails must stay represented, unlike an empty slot.
local function map(v) return {ForEach=function(_,f) for k,x in pairs(v) do f(k,x) end end} end
local F=I.fields
local gi={playerProgress={[F.primary]='itemPistol',[F.secondary]='itemBow',[F.equipped]=map{},[F.upgrades]=map{}}}
local function spell(element,cd) return {IsValid=function() return true end,GetCDO=function() return {element=element,spellCooldown=cd} end} end
local ps={AC_PlayerStateJoker={playerLocalJokers=map{}},playerRuntimeStats={[F.cooldownC]=20},spellARuntime=spell(8,60),spellBRuntime=spell(7,60),spellCRuntime={IsValid=function() return true end,GetCDO=function() error('unavailable CDO') end}}
StaticFindObject=function() end;FName=function(s)return s end
s=I.readObjects(gi,ps,{})
t,style=P.description('jokerCantripOneTrick',s,nil,'pickup');check(not style.noBonus,'failed spell C must not disappear from comparison')
ps.spellCRuntime=nil;s=I.readObjects(gi,ps,{})
t,style=P.description('jokerCantripOneTrick',s,nil,'pickup');check(style.noBonus,'genuinely empty C slot is not a read failure')
assert(#errors==0,table.concat(errors,'; '));print('joker_audit_values_test passed')
