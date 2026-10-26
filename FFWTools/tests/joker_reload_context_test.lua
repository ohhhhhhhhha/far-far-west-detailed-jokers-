package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;'..package.path
local I,E=require('Inventory'),require('Effects')
local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function near(a,b,m) checks=checks+1;assert(type(a)=='number' and math.abs(a-b)<1e-8,(m or '')..' expected '..b..', got '..tostring(a)) end
local snapshot=I.fromSnapshot({selected={primary='itemWinchester',secondary='itemPistol'},equipped={itemPistol={'jokerFanningAce'}},upgrades={},runtime={},
 inputs={heldItemName='itemWinchester'},inputsByItem={itemWinchester={reloadSpeed=1.2}}})
local pistol=I.group(snapshot,'itemPistol')
near(pistol.inputs.reloadSpeed,1,'unheld pistol uses its own complete combination, not held rate')
near(E.preview('jokerFanningAce',pistol.counts,pistol.inputs).current.metrics.triggerWindow.value,.4)
near(I.group(snapshot,'itemWinchester').inputs.reloadSpeed,1.2,'actual native read remains authoritative')
local m=E.reloadSpeed({jokerFastHands=2,jokerBracing=1,jokerUpgradeReloadSpeed=2},{heroCounts={},itemName='itemPistol'})
near(m.value,1.6) -- 1 + 2*.2 + .05 + 2*.075
m=E.reloadSpeed({jokerRampage=2,jokerReloadMastery=1},{heroCounts={jokerHealthyBoi=1,jokerSoulEater=1},
 health=100,maxHealth=100,soulEaterActive=true,rampageStack=.2,magazineAmmo=0,itemName='itemPistol'})
near(m.value,2.3) -- 1 + .2 healthy + .2 souls + 2*.2 stored rampage + .5 empty-magazine
eq(E.reloadSpeed({jokerReloadMastery=1},{heroCounts={},itemName='itemPistol'}).value,nil,'unknown unheld magazine remains unknown when it changes this rule')
eq(E.reloadSpeed({},{itemName='itemPistol'}).value,nil,'unread hero cards do not become an empty set')
print('joker_reload_context_test: '..checks..' checks passed')
