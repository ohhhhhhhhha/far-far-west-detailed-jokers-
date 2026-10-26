package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;'..package.path
local E=require('Effects');local I=require('Inventory');local P=require('Panel')
local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function near(a,b,m) checks=checks+1;assert(type(a)=='number' and math.abs(a-b)<1e-6,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local context={buffGravity=0,heldItemName='itemLongRanger',heldItemCounts={},itemName='itemHero'}
local p=E.preview('jokerLightWeight',{jokerLightWeight=2},context)
near(p.current.metrics.finalGravityScale.value,1.15,'two cards subtract .1 from 1.25')
near(p.current.metrics.gravityReduction.value,.08,'actual reduction is eight percent, not ten')
near(p.after.metrics.finalGravityScale.value,1.1)
near(p.after.metrics.gravityReduction.value,.12)
near(p.current.metrics.gravityFloorCardCount.value,20,'solo LightWeight effect floor is not holding cap')
local counts={jokerLightWeight=2,jokerLowGravity=1,jokerDwarf=1,jokerChonky=1}
context.heldItemCounts={jokerHeavyWeapon=2};context.buffGravity=.1
p=E.preview('jokerLightWeight',counts,context)
near(p.current.metrics.finalGravityScale.value,1.55,'all five cards and current buff combine before clamp')
near(p.after.metrics.finalGravityScale.value,1.5)
near(p.current.metrics.gravityFloorCardCount.value,28,'other current gravity changes threshold')
context.buffGravity=0;context.heldItemCounts={}
p=E.preview('jokerLightWeight',{jokerLightWeight=20},context)
near(p.current.metrics.finalGravityScale.value,.25)
near(p.after.metrics.finalGravityScale.value,.25)
eq(p.afterCount,21,'effect floor does not prevent holding more cards')
p=E.preview('jokerLightWeight',{jokerLightWeight=2},{})
eq(p.current.metrics.finalGravityScale.value,nil,'unknown buff/held item cannot be guessed as zero')
local s=I.fromSnapshot({selected={primary='itemLongRanger',secondary='itemPistol'},
    equipped={itemHero={'jokerLightWeight','jokerLightWeight'},itemLongRanger={},itemPistol={'jokerHeavyWeapon'}},
    upgrades={},runtime={},inputs={buffGravity=0,heldItemName='itemLongRanger',currentGravityScale=1.15}})
local g=I.group(s,'itemHero')
local preview=E.preview('jokerLightWeight',g.counts,I.candidateInputs(g,'jokerLightWeight','pickup'))
near(preview.current.metrics.finalGravityScale.value,1.15,'unheld Pistol heavy card does not affect current gravity')
near(preview.after.metrics.finalGravityScale.value,1.1)
near(preview.current.metrics.runtimeGravityScale.value,1.15)
eq(preview.after.metrics.runtimeGravityScale,nil,'runtime observation is not a candidate prediction')
local text=P.description('jokerLightWeight',s,nil,'current')
eq(text:sub(1,#'重力 -5%'),'重力 -5%')
eq(text:find('1.15',1,true)~=nil,true)
eq(text:find('8%',1,true)~=nil,true)
eq(text:find('当前 2 张',1,true),nil)
eq(text:find('获得后',1,true),nil)
eq(text:find('大厅最多装备 2 张',1,true),nil)
eq(text:find('任务拾取无张数上限',1,true),nil)
eq(text:find('可叠加',1,true),nil)
local pickup=P.description('jokerLightWeight',s,nil,'pickup')
eq(pickup:find('获得后 3 张',1,true),nil)
eq(pickup:find('1.15 → 1.1',1,true)~=nil,true)
local b=P.description('jokerBracing',I.fromSnapshot({selected={primary='itemLongRanger'},equipped={itemLongRanger={'jokerBracing'}},upgrades={},runtime={}}),'itemLongRanger','current')
eq(b:find('攻击速度',1,true)~=nil,true);eq(b:find('换弹速度',1,true)~=nil,true,'all confirmed metrics appear inside description')
print('joker_gravity_test: '..checks..' checks passed')
