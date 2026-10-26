package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;'..package.path
local I,P,C,E,L=require('Inventory'),require('Panel'),require('Cards'),require('Effects'),require('Locale')
local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function snapshot(id,n,inputs,item)
    local cards={};for k=1,n do cards[k]=id end
    return I.fromSnapshot({selected={primary='itemLongRanger',secondary='itemPistol'},
        equipped={[item or 'itemHero']=cards},upgrades={},runtime={},inputs=inputs or {}})
end
local id='jokerBouncingBall'
for _,grounded in ipairs({true,false}) do
    local s=snapshot(id,0,{groundQueryPassed=grounded})
    local t,style=P.description(id,s,'itemHero','pickup')
    eq(style.noBonus,false,'first airborne card is useful even while standing on the ground')
    eq(t:find('×1 → ×1.15',1,true)~=nil,true,'preview compares the conditional multiplier')
    eq(t:find('离地时',1,true)~=nil,true,'condition is visible in plain language')
    eq(t:find('F_IsOnGround',1,true),nil,'native function names stay out of the compact card')
    local stacked=snapshot(id,1,{groundQueryPassed=grounded})
    local nextText,nextStyle=P.description(id,stacked,'itemHero','pickup')
    eq(nextStyle.noBonus,false);eq(nextText:find('×1.15 → ×1.3',1,true)~=nil,true)
    local current,currentStyle=P.description(id,stacked,'itemHero','current')
    eq(currentStyle.noBonus,false);eq(current:find('×1.15',1,true)~=nil,true)
    eq(current:find('→',1,true),nil,'held details never preview acquiring another copy')
    eq(current:find('无加成',1,true),nil)
end
local unknown,unknownStyle=P.description(id,snapshot(id,0),'itemHero','pickup')
eq(unknownStyle.noBonus,false);eq(unknown:find('×1 → ×1.15',1,true)~=nil,true,
    'known conditional formula does not need a live ground sample')
local held=snapshot(id,2,{groundQueryPassed=true})
local f7=P.page(held,1)
eq(f7.detail:find('离地武器伤害倍率：×1',1,true)~=nil,true,'F7 still reports the actual inactive multiplier')
eq(E.evaluate(id,2,{groundQueryPassed=true}).metrics.damageMultiplier.value,1,'formula layer is unchanged')
local floor=snapshot('jokerLightWeight',21,{buffGravity=0,heldItemName='itemLongRanger'})
local pickup,red=P.description('jokerLightWeight',floor,'itemHero','pickup')
eq(red.noBonus,true,'a new copy at the real gravity floor still has no bonus')
local current,currentStyle=P.description('jokerLightWeight',floor,'itemHero','current')
eq(currentStyle.noBonus,false,'owned cards never show the acquisition-only warning')
eq(current:find('重力系数：0.25',1,true)~=nil,true,'owned capped effects retain their current total')
local equip,equipStyle=P.description('jokerLightWeight',floor,'itemHero','equip')
eq(equipStyle.noBonus,false,'the owned-card equipment menu is not a new acquisition')
local noSpell=snapshot('jokerCdrElec',1,{elementSpellCounts={Elec=0,Frost=1,Fire=1,Acid=1},
    spells={{slot='A',element='Frost',baseCooldown=25},{slot='B',element='Fire',baseCooldown=80},{slot='C',element='Acid',baseCooldown=40}}})
local empty,emptyStyle=P.description('jokerCdrElec',noSpell,'itemHero','current')
eq(emptyStyle.noBonus,false);eq(empty,C.get('jokerCdrElec').description,'no empty information header in held descriptions')
-- The same shared comparison covers other conditional cards, including booleans.
for _,test in ipairs({
    {'jokerAvalanche',{shield=0},'itemLongRanger'},
    {'jokerGreatWall',{shield=0},'itemHero'},
    {'jokerLastStand',{health=100,maxHealth=100},'itemHero'},
    {'jokerHealthyBoi',{health=50,maxHealth=100},'itemHero'},
    {'jokerFinalEmber',{health=100,maxHealth=100},'itemHero'},
}) do
    local text,style=P.description(test[1],snapshot(test[1],0,test[2],test[3]),test[3],'pickup')
    eq(style.noBonus,false,test[1]..' retains its conditional benefit')
    eq(text:find('→',1,true)~=nil,true,test[1]..' exposes its conditional change')
end
L.setCulture('en-US')
local english,enStyle=P.description(id,held,'itemHero','pickup')
eq(enStyle.noBonus,false);eq(english:find('×1.3 → ×1.45',1,true)~=nil,true)
eq(english:find('While airborne',1,true)~=nil,true)
eq(english:find('离地',1,true),nil)
L.setCulture('zh-Hans')
-- A zero live resource is not proof that a newly acquired ability is useless.
for _,test in ipairs({
    {'jokerAllMighty','itemLongRanger',{shield=0},'+0% → +1%'},
    {'jokerCheapSkate','itemHero',{gold=0},'0 点 → 1 点'},
    {'jokerOverBlast','itemShotgun',{magazineAmmo=10,magazineMaximum=10},'0 → 1'},
    {'jokerEagleLever','itemWinchester',{consecutiveHits=0},'+0% → +10%'},
    {'jokerRushBlast','itemShotgun',{magazineAmmo=0,magazineMaximum=10},'未启用 → 启用'},
    {'jokerStackedLever','itemWinchester',{magazineAmmo=0,magazineMaximum=10,ammoCurrent=0},'0 → 2'},
    {'jokerSpellLash','itemLasso',{lassoCharge=1},'0% → 100%'},
    {'jokerSpeedster','itemLongRanger',{speedsterSpeed=550,canBeAffectedByPlayerFireRate=true},'+0% → +1%'},
    {'jokerStonks','itemHero',{chestIsFake=true,chestCanDropContent=false},'0% → 20%'},
}) do
    local t,style=P.description(test[1],snapshot(test[1],0,test[3],test[2]),test[2],'pickup')
    eq(style.noBonus,false,test[1]..' is currently inactive, not useless')
    eq(t:find(test[4],1,true)~=nil,true,test[1]..' shows a verified trigger/rate, not invented live damage')
    local heldText,heldStyle=P.description(test[1],snapshot(test[1],1,test[3],test[2]),test[2],'current')
    eq(heldStyle.noBonus,false);eq(heldText:find(P.marker,1,true)~=nil,true)
end
for _,test in ipairs({
    {'jokerAllMighty','itemLongRanger',{shield=0}},
    {'jokerOverBlast','itemShotgun',{magazineAmmo=10,magazineMaximum=10}},
    {'jokerRushBlast','itemShotgun',{magazineAmmo=0,magazineMaximum=10}},
    {'jokerStackedLever','itemWinchester',{magazineAmmo=0,magazineMaximum=10,ammoCurrent=0}},
    {'jokerSpellLash','itemLasso',{lassoCharge=1}},
}) do
    local _,style=P.description(test[1],snapshot(test[1],1,test[3],test[2]),test[2],'pickup')
    eq(style.noBonus,true,test[1]..' duplicate does not strengthen its presence-only ability')
end
local _,rarityStyle=P.description('jokerOneTrick',snapshot('jokerOneTrick',0,{},'itemLongRanger'),'itemLongRanger','pickup')
eq(rarityStyle.noBonus,true,'task pickups do not create a new equipped rarity')
local _,fuelStyle=P.description('jokerUpgradeJetpackFuel',snapshot('jokerUpgradeJetpackFuel',0,{},'itemJetpack'),'itemJetpack','pickup')
eq(fuelStyle.noBonus,true,'8 times 5% rounds to zero; the next upgrade level actually changes capacity')
local fuel=P.description('jokerUpgradeJetpackFuel',snapshot('jokerUpgradeJetpackFuel',1,{},'itemJetpack'),'itemJetpack','pickup')
eq(fuel:find('8 → 9',1,true)~=nil,true)
local mighty=snapshot('jokerAllMighty',1,{shield=0},'itemLongRanger')
local mightyF7=P.page(mighty,1)
eq(mightyF7.detail:find('本卡伤害加成：+0%',1,true)~=nil,true,'F7 keeps the live resource-dependent value')
local mixed,mixedStyle=P.description('jokerStackedLever',snapshot('jokerStackedLever',0,{ammoCurrent=0},'itemWinchester'),'itemWinchester','pickup')
eq(mixedStyle.noBonus,false,'zero reserve must not hide an unread magazine capacity')
eq(mixed:find('待读取',1,true)~=nil,true,'the conditional refill remains unknown until capacity is read')
-- Future event inputs are not required to explain the known retaliation rule.
local thorn,thornStyle=P.description('jokerPricklyPear',snapshot('jokerPricklyPear',0),'itemHero','pickup')
eq(thornStyle.noBonus,false)
eq(thorn:find('反伤固定加值：0 点 → 15 点',1,true)~=nil,true)
eq(thorn:find('待读取',1,true),nil,'compact card does not ask for a future damage event')
eq(thorn:find('反伤＝减伤后伤害＋附加值',1,true)~=nil,true)
eq(thorn:find('敌人造成生命伤害时触发',1,true)~=nil,true)
local thornNext=P.description('jokerPricklyPear',snapshot('jokerPricklyPear',2),'itemHero','pickup')
eq(thornNext:find('30 点 → 45 点',1,true)~=nil,true)
local _,thornCap=P.description('jokerPricklyPear',snapshot('jokerPricklyPear',3),'itemHero','pickup')
eq(thornCap.noBonus,true,'extra copies at the verified flat-damage cap add nothing')
local thornHeld=P.description('jokerPricklyPear',snapshot('jokerPricklyPear',2),'itemHero','current')
eq(thornHeld:find('反伤固定加值：30 点',1,true)~=nil,true);eq(thornHeld:find('→',1,true),nil)
eq(thornHeld:find('待读取',1,true),nil)
local thornF7=P.page(snapshot('jokerPricklyPear',1),1)
eq(thornF7.detail:find('待读取',1,true)~=nil,true,'F7 retains the full event-dependent diagnostics')
L.setCulture('en-US')
local thornEn=P.description('jokerPricklyPear',snapshot('jokerPricklyPear',0),'itemHero','pickup')
eq(thornEn:find('Retaliation = post-mitigation damage + bonus',1,true)~=nil,true)
eq(thornEn:find('[\228-\233][\128-\191][\128-\191]'),nil)
L.setCulture('zh-Hans')
print('joker_conditional_description_test: '..checks..' checks passed')
