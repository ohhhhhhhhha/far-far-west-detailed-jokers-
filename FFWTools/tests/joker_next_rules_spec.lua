package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;'..package.path
local Effects,Cards=require('Effects'),require('Cards')
local checks,tests,failures=0,0,0
local function eq(actual,expected,message)
    checks=checks+1
    assert(actual==expected,(message or '')..' expected '..tostring(expected)..', got '..tostring(actual))
end
local function near(actual,expected,message)
    checks=checks+1
    assert(type(actual)=='number' and math.abs(actual-expected)<1e-6,
        (message or '')..' expected '..tostring(expected)..', got '..tostring(actual))
end
local function metric(result,key)
    assert(result.metrics[key],'missing verified metric: '..key)
    return result.metrics[key]
end
local function value(result,key) return metric(result,key).value end
local function test(name,fn)
    tests=tests+1
    local ok,err=pcall(fn)
    if ok then print('PASS '..name) else failures=failures+1;print('FAIL '..name..': '..tostring(err)) end
end

-- Expectations are hand-derived from retained CUE bytecode; see research/joker-next-rules-2026-10-26.md.
test('FanningAce unlocks the ability once instead of scaling burst length with copies',function()
    local counts={jokerFanningAce=0}
    local p=Effects.preview('jokerFanningAce',counts,{})
    eq(value(p.current,'enabled'),false)
    eq(value(p.after,'enabled'),true)
    eq(value(p.current,'burstInterval'),nil)
    near(value(p.after,'burstInterval'),.1)
    eq(counts.jokerFanningAce,0,'preview does not add a card')
end)
test('FanningAce window divides by current reload rate and extra copies do not improve it',function()
    local p=Effects.preview('jokerFanningAce',{jokerFanningAce=1},{reloadSpeed=2},2)
    eq(p.equipLimit,1)
    eq(p.afterCount,3,'hall equip limit does not clamp runtime copies')
    near(value(p.current,'triggerWindow'),.2)
    near(value(p.after,'triggerWindow'),.2)
    near(value(p.after,'burstInterval'),.1)
    eq(value(p.after,'enabled'),true)
end)
test('FanningAce never guesses a missing or invalid reload rate or a fixed burst count',function()
    for _,inputs in ipairs({{}, {reloadSpeed=0}, {reloadSpeed=-1}}) do
        local r=Effects.evaluate('jokerFanningAce',2,inputs)
        eq(value(r,'triggerWindow'),nil)
        eq(r.complete,false)
        eq(r.metrics.burstCount,nil,'Camper can extend a burst')
    end
end)
test('Camper weights add to fifty then one hundred percent without a holding cap',function()
    local inputs={groundQueryPassed=true,runningQueryResult=false,horizontalSpeed=16,consumeAllowsCamper=true}
    local p=Effects.preview('jokerCamper',{jokerCamper=1},inputs)
    near(value(p.current,'freeAmmoChance'),.5)
    near(value(p.after,'freeAmmoChance'),1)
    eq(p.equipLimit,1)
    near(value(Effects.evaluate('jokerCamper',5,inputs),'freeAmmoChance'),1)
end)
test('Camper rejects each real gate including disabled consume calls and the speed boundary',function()
    local base={groundQueryPassed=true,runningQueryResult=false,horizontalSpeed=16,consumeAllowsCamper=true}
    for _,change in ipairs({{'groundQueryPassed',false},{'runningQueryResult',true},
        {'horizontalSpeed',16.001},{'consumeAllowsCamper',false}}) do
        local inputs={};for k,v in pairs(base) do inputs[k]=v end;inputs[change[1]]=change[2]
        near(value(Effects.evaluate('jokerCamper',2,inputs),'freeAmmoChance'),0,change[1])
    end
    near(value(Effects.evaluate('jokerCamper',0,{}),'freeAmmoChance'),0)
    near(value(Effects.evaluate('jokerCamper',2,{groundQueryPassed=false}),'freeAmmoChance'),0,
        'a known failed gate is enough even when other gates are unread')
end)
test('Camper keeps unknown current eligibility separate from its known conditional chance',function()
    local p=Effects.preview('jokerCamper',{jokerCamper=1},{groundQueryPassed=true,
        runningQueryResult=false,horizontalSpeed=0})
    eq(value(p.current,'freeAmmoChance'),nil,'consumeAllowsCamper is not assumed')
    near(metric(p.current,'freeAmmoChance').potential,.5)
    near(metric(p.after,'freeAmmoChance').potential,1)
    eq(p.current.complete,false)
end)
test('FastDraw adds same-card bonuses before multiplying this damage stage',function()
    local p=Effects.preview('jokerFastDraw',{jokerFastDraw=1},{firstShotLoaded=true})
    near(value(p.current,'damageMultiplier'),1.3)
    near(value(p.after,'damageMultiplier'),1.6)
    near(value(Effects.evaluate('jokerFastDraw',6,{firstShotLoaded=true}),'damageMultiplier'),2.8)
    eq(p.equipLimit,2)
end)
test('FastDraw acquisition does not refresh a consumed shot but explicit after state is honored',function()
    local inputs={firstShotLoaded=false}
    local p=Effects.preview('jokerFastDraw',{jokerFastDraw=1},inputs)
    near(value(p.current,'damageMultiplier'),1)
    near(value(p.after,'damageMultiplier'),1)
    inputs.after={firstShotLoaded=true}
    p=Effects.preview('jokerFastDraw',{jokerFastDraw=1},inputs)
    near(value(p.after,'damageMultiplier'),1.6)
    eq(inputs.firstShotLoaded,false,'preview does not reload first-shot state')
end)
test('FastDraw unknown first-shot state is conditional while no card is neutral',function()
    local r=Effects.evaluate('jokerFastDraw',1,{})
    eq(value(r,'damageMultiplier'),nil)
    near(metric(r,'damageMultiplier').potential,1.3)
    eq(r.complete,false)
    near(value(Effects.evaluate('jokerFastDraw',0,{}),'damageMultiplier'),1)
end)
test('Clutch compares the actual held magazine against one then three remaining rounds',function()
    local inputs={heldMagazineAmmo=2,magazineAmmo=0}
    local p=Effects.preview('jokerClutch',{jokerClutch=1},inputs)
    near(value(p.current,'magazineThreshold'),1)
    near(value(p.after,'magazineThreshold'),3)
    eq(value(p.current,'magazineWithinThreshold'),false,'viewed weapon magazine is not the held magazine')
    eq(value(p.after,'magazineWithinThreshold'),true)
    eq(inputs.heldMagazineAmmo,2,'candidate does not consume ammunition')
    eq(Effects.formatMetric(metric(p.current,'magazineWithinThreshold')),'不满足')
    eq(Effects.formatMetric(metric(p.after,'magazineWithinThreshold')),'满足')
end)
test('Clutch includes the exact threshold and empty magazine but no-card state stays disabled',function()
    eq(value(Effects.evaluate('jokerClutch',2,{heldMagazineAmmo=3}),'magazineWithinThreshold'),true)
    eq(value(Effects.evaluate('jokerClutch',1,{heldMagazineAmmo=0}),'magazineWithinThreshold'),true)
    local empty=Effects.evaluate('jokerClutch',0,{heldMagazineAmmo=0})
    eq(value(empty,'magazineWithinThreshold'),false)
    eq(value(empty,'magazineThreshold'),nil)
    near(value(Effects.evaluate('jokerClutch',100,{}),'magazineThreshold'),199)
end)
test('Clutch requires held-magazine evidence and never substitutes explosion table damage or future shot counts',function()
    local r=Effects.evaluate('jokerClutch',1,{magazineAmmo=0,maxMagazineAmmo=6,consumeAllowsCamper=true})
    eq(value(r,'magazineWithinThreshold'),nil)
    near(value(r,'magazineThreshold'),1)
    eq(r.complete,false)
    eq(r.metrics.explosionDamage,nil)
    eq(r.metrics.explosiveShots,nil)
end)
test('Ricochet adds initial ricochet capacity while each homing attempt remains thirty percent',function()
    local p=Effects.preview('jokerRicochet',{jokerRicochet=1},{})
    near(value(p.current,'ricochets'),1)
    near(value(p.after,'ricochets'),2)
    near(value(p.current,'homingAttemptChance'),.3)
    near(value(p.after,'homingAttemptChance'),.3)
    near(value(p.after,'homingSearchRadius'),1024)
    eq(p.equipLimit,1)
    eq(p.status,'verified')
end)
test('Ricochet has no observed count clamp and no-card state cannot attempt homing',function()
    local r=Effects.evaluate('jokerRicochet',20,{})
    near(value(r,'ricochets'),20)
    near(value(r,'homingAttemptChance'),.3)
    r=Effects.evaluate('jokerRicochet',0,{})
    near(value(r,'ricochets'),0)
    near(value(r,'homingAttemptChance'),0)
    eq(value(r,'homingSearchRadius'),nil)
end)
test('the five verified metric rules retain original descriptions and static evidence scope',function()
    for _,id in ipairs({'jokerFanningAce','jokerCamper','jokerFastDraw','jokerClutch','jokerRicochet'}) do
        local card=Cards.get(id)
        local original=card.description
        local p=Effects.preview(id,{[id]=1},{})
        eq(p.status,'verified',id)
        eq(p.runtimeVerified,false,id)
        eq(p.lines[2],original,id..' retains original description')
        eq(p.scope,'item',id)
    end
end)

print(('joker_next_rules_spec: %d cases, %d assertions, %d failures'):format(tests,checks,failures))
assert(failures==0,'joker_next_rules_spec failed')
