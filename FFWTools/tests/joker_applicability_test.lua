-- BP_PlayerState.F_TriggerOnKillTweaks chooses the equipped A/B item name;
-- F_GetJokerEffects applies the DT allowlist before summing task/equipped cards.
package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;'..package.path
local I,P=require('Inventory'),require('Panel')
local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function snapshot(secondary,cards)
    return I.fromSnapshot{selected={primary='itemShotgun',secondary=secondary},equipped={},upgrades={},runtime=cards or {}}
end
local guns=snapshot('itemDualRevolver',{'jokerFrostBite'})
for _,item in ipairs({'itemShotgun','itemDualRevolver','itemMelee'}) do
    eq(I.applies('jokerFrostBite',item),false,'basic punches do not bypass the item allowlist')
end
local text,style=P.description('jokerFrostBite',guns,nil,'pickup')
eq(style.noBonus,true,'retain the original result for this incompatible loadout')
eq(text:find('0 点 → 2 点',1,true),nil,'do not invent an active bonus for ordinary fists')
local melee,meleeStyle=P.description('jokerFrostBite',snapshot('itemKnuckles',{'jokerFrostBite'}),nil,'pickup')
eq(meleeStyle.noBonus,false);eq(melee:find('2 点 → 4 点',1,true)~=nil,true)
local fists,fistsStyle=P.description('jokerFistFight',snapshot('itemDualRevolver'),'itemHero','pickup')
eq(fistsStyle.noBonus,false,'the dedicated hero bare-hand card is a different rule')
eq(fists:find('10 点 → 20 点',1,true)~=nil,true)
for _,item in ipairs({'itemQuadCylinder','itemLongRanger','itemPistol'}) do
    eq(I.applies('jokerConsumer',item),true)
end
eq(I.applies('jokerConsumer','itemShotgun'),false)
eq(I.applies('jokerConsumer','itemDualRevolver'),false)
print('joker_applicability_test: '..checks..' checks passed')
