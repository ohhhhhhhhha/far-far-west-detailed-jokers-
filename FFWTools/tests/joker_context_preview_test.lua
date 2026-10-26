package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;'..package.path
local I,E,P,C=require('Inventory'),require('Effects'),require('Panel'),require('Cards')
local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function near(a,b,m) checks=checks+1;assert(type(a)=='number' and math.abs(a-b)<1e-8,(m or '')..' expected '..b..', got '..tostring(a)) end
local snapshot=I.fromSnapshot({selected={primary='itemBoomerang',secondary='itemJetpack'},
 equipped={itemHero={'jokerSpareBullets'},itemBoomerang={'jokerLingeringThrow'}},
 upgrades={itemBoomerang={jokerUpgradeBoomerangLingeringTime=2},itemJetpack={jokerUpgradeJetpackFlightDuration=2}},
 runtime={},inputs={heldItemName='itemBoomerang'}})
local g=I.group(snapshot,'itemBoomerang')
eq(g.inputs.itemCounts,g.counts,'rules receive the complete filtered viewed-item context')
local p=E.preview('jokerUpgradeBoomerangLingeringTime',g.counts,I.candidateInputs(g,'jokerUpgradeBoomerangLingeringTime','equip'))
near(p.current.metrics.lingeringTime.value,.96)
near(p.after.metrics.lingeringTime.value,1.04)
local counts={jokerUpgradeJetpackFlightDuration=2}
local inputs={itemName='itemJetpack',heldItemName='itemJetpack',itemCounts=counts,heldItemCounts=counts,heroCounts={},candidateKind='pickup'}
local seen={}
local rule=E.rule('jokerCrashPack');local original=rule.evaluate
rule.evaluate=function(n,i,c)
    seen[#seen+1]={n=n,item=E.count(i.itemCounts,'jokerCrashPack'),held=E.count(i.heldItemCounts,'jokerCrashPack')}
    return original(n,i,c)
end
E.preview('jokerCrashPack',counts,inputs)
rule.evaluate=original
eq(seen[1].item,0);eq(seen[2].item,1);eq(seen[2].held,1,'one pickup increments held context once')
eq(counts.jokerCrashPack,nil);eq(inputs.itemCounts,counts,'preview must preserve caller context')
local hero=I.group(snapshot,'itemHero')
local heroRule=E.rule('jokerSpareBullets');local evaluate=heroRule.evaluate
local heroSeen={}
heroRule.evaluate=function(n,i,c) heroSeen[#heroSeen+1]=E.count(i.heroCounts,'jokerSpareBullets');return evaluate(n,i,c) end
E.preview('jokerSpareBullets',hero.counts,I.candidateInputs(hero,'jokerSpareBullets','pickup'))
heroRule.evaluate=evaluate
eq(heroSeen[1],1);eq(heroSeen[2],2);eq(hero.counts.jokerSpareBullets,1)
local disabled=P.description('jokerCrazyDeal',snapshot,'itemHero','current')
eq(disabled:find('当前版本禁用',1,true)~=nil,true)
eq(disabled:find('待核实',1,true),nil,'verified disabled state must not be called unresolved')
eq(disabled:find('可叠加',1,true),nil,'disabled card has no claimed active stack formula')
eq(disabled:find('任务拾取无张数上限',1,true),nil,'disabled card is not normally collectible')
eq(disabled:sub(1,#C.get('jokerCrazyDeal').description),C.get('jokerCrazyDeal').description)
eq(E.preview('jokerCrazyDeal',{},{}).complete,true,'disabled determination is complete without claiming an effect')
local function lazy(item,ammo)
    local s=I.fromSnapshot({selected={primary=item},equipped={},upgrades={},runtime={'jokerLazy'},
        inputs={heldItemName=item},inputsByItem={itemHero=ammo}})
    local h=I.group(s,'itemHero')
    return E.preview('jokerLazy',h.counts,h.inputs,0).current.metrics
end
near(lazy('itemSheriffStar',{magazineAmmo=0,magazineMaximum=20,ammoCurrent=20,ammoMaximum=20}).actualAmmoRestored.value,2)
near(lazy('itemBow',{magazineAmmo=0,ammoCurrent=10,ammoMaximum=30}).bowMagazineRestored.value,1)
near(lazy('itemMinigun',{ammoCurrent=20,ammoMaximum=300}).magazineAfterTick.value,50)
near(lazy('itemBoomerang',{ammoCurrent=0,ammoMaximum=1}).actualAmmoRestored.value,0)
print('joker_context_preview_test: '..checks..' checks passed')
