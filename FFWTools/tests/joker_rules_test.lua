package.path = 'FFWTools/src/FFWJokerInfo/Scripts/?.lua;' .. package.path
local ok, Effects = pcall(require, 'Effects')
assert(ok, 'Joker effects module must expose verified pure preview calculations: ' .. tostring(Effects))
local Cards = require('Cards')
local checks = 0
local function eq(a,b,m) checks=checks+1; assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function near(a,b,m) checks=checks+1; assert(type(a)=='number' and math.abs(a-b)<1e-6,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function val(p,stage,key) return p[stage].metrics[key].value end
-- Catches the incorrect but tempting maxAvailable effect clamp and repeated multiplication.
local counts = {jokerCrackShot=3}
local p = Effects.preview('jokerCrackShot',counts,{})
near(val(p,'current','damageBonus'),.21)
near(val(p,'after','damageBonus'),.28)
eq(p.equipLimit,2)
eq(counts.jokerCrackShot,3,'preview is read-only')
-- FNames compare case insensitively; a real DT spelling differs in consumer bytecode.
p = Effects.preview('jokerUpgradeFirerate',{jokerUpgradeFireRate=2},{},1)
near(val(p,'current','attackSpeedBonus'),.1)
near(val(p,'after','attackSpeedBonus'),.15)
-- AllMighty is presence-gated, not multiplied by number of copies, and caps at 80%.
p = Effects.preview('jokerAllMighty',{jokerAllMighty=1},{shield=100})
near(val(p,'current','damageBonus'),.8)
near(val(p,'after','damageBonus'),.8)
p = Effects.preview('jokerAllMighty',{jokerAllMighty=1},{shield=.5})
near(val(p,'current','damageBonus'),0)
-- Same-card LuckyStrike weights add; two copies are 20%, not 19% independent trials.
p = Effects.preview('jokerLuckyStrike',{jokerLuckyStrike=1},{})
near(val(p,'after','doubleDamageChance'),.2)
p = Effects.preview('jokerLuckyStrike',{jokerLuckyStrike=20},{})
near(val(p,'current','doubleDamageChance'),1)
-- Unknown context remains unknown; it must not look like a currently active buff.
p = Effects.preview('jokerAvalanche',{jokerAvalanche=2},{})
eq(val(p,'current','damageBonus'),nil)
near(p.current.metrics.damageBonus.potential,.3)
p = Effects.preview('jokerAvalanche',{jokerAvalanche=2},{shield=0})
near(val(p,'current','damageBonus'),0)
-- Linear curve and distinct multiplicative reduction, not a sum of percentages.
near(Effects.curve('C_Joker_ThickSkin',2.5),.55)
near(Effects.curve('C_Joker_ThickSkin',9),.45)
local total = Effects.damageReduction({jokerThickSkin=1,jokerLastStand=1,jokerGreatWall=1},{healthRatio=.3,shield=1})
near(total.value,.504)
total = Effects.damageReduction({jokerThickSkin=4,jokerLastStand=4,jokerGreatWall=5},{healthRatio=.3,shield=1})
near(total.value,.102375)
total = Effects.damageReduction({jokerThickSkin=1,jokerLastStand=1,jokerGreatWall=1},{healthRatio=.8,shield=0})
near(total.value,.8)
-- CheapSkate caps gold before multiplying copies: two copies can grant 40, not 20.
p = Effects.preview('jokerCheapSkate',{jokerCheapSkate=1},{gold=420})
near(val(p,'current','flatHealth'),20)
near(val(p,'after','flatHealth'),40)
p = Effects.preview('jokerCheapSkate',{jokerCheapSkate=1},{gold=29})
near(val(p,'current','flatHealth'),1)
-- Rampage's stored history is not retroactively recomputed after taking a card.
p = Effects.preview('jokerRampage',{jokerRampage=1},{rampageStack=.15})
near(val(p,'current','reloadSpeedBonus'),.15)
near(val(p,'after','reloadSpeedBonus'),.30)
near(val(p,'after','perKillBonus'),.1)
p = Effects.preview('jokerBloodLust',{jokerBloodLust=1},{bloodLustStack=.45})
near(val(p,'after','attackSpeedBonus'),.45)
near(val(p,'after','perKillBonus'),.1)
-- Integer threshold and fixed time: no partial bonus before the next 50 damage.
p = Effects.preview('jokerMachineGun',{jokerMachineGun=1},{itemDamage=149})
near(val(p,'current','attackSpeedBonus'),.006)
near(val(p,'after','attackSpeedBonus'),.012)
-- Curves use beyond-equip copies, and a no-card state has no cooldown effect.
p = Effects.preview('jokerSecondWind',{jokerSecondWind=1},{})
near(val(p,'after','cooldown'),120)
p = Effects.preview('jokerSecondWind',{}, {})
near(val(p,'current','heal'),0)
eq(val(p,'current','cooldown'),nil)
near(val(p,'after','heal'),50)
-- Attack/reload speed is a rate increase; swap delay is reciprocal, not -40%.
p = Effects.preview('jokerQuickDraw',{jokerQuickDraw=1},{})
near(val(p,'current','swapDelayMultiplier'),1/1.4)
near(val(p,'after','swapDelayMultiplier'),1/1.8)
-- Unknown IDs stay incomplete; HoverPack now has a verified downstream rule.
p = Effects.preview('jokerDoesNotExist',{jokerDoesNotExist=1},{})
eq(p.status,'unresolved')
eq(next(p.current.metrics),nil)
eq(#Cards.all(),183)
for _,card in ipairs(Cards.all()) do
    local rule=Effects.rule(card.id)
    eq(rule~=nil and (rule.status=='verified' or rule.status=='disabled'),true,card.id..' coverage')
end
eq(Cards.get('jokerCrackShot').description,'伤害 +7%')
print('joker_rules_test: '..checks..' checks passed')
