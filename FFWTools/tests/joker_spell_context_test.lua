package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;'..package.path
local I,E,P=require('Inventory'),require('Effects'),require('Panel')
local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function near(a,b,m) checks=checks+1;assert(type(a)=='number' and math.abs(a-b)<1e-8,(m or '')..' expected '..b..', got '..tostring(a)) end
local function cls(element,cooldown) return {IsValid=function() return true end,GetCDO=function() return {element=element,spellCooldown=cooldown} end} end
local items={}
function items:F_GetEquipedSpellAmountByElement(acid,fire,elec,voodoo,cactus,frost)
    acid.Acid=1;fire.Fire=1;elec.Elec=0;voodoo.Voodoo=0;cactus.Cactus=0;frost.Frost=1
end
local runtime={cooldownSpellA_32_D8F383D94883A467CF929A9E452C176D=8,
    cooldownSpellB_31_CA70EE57499218F37A2F3F93523EDEC8=3,
    cooldownSpellC_30_C211B06A4A281EC29108A48303174C4C=20}
local s=I.readObjects({}, {spellARuntime=cls(15,25),spellBRuntime=cls(7,40),spellCRuntime=cls(8,80),playerRuntimeStats=runtime}, {AC_PlayerItems=items})
eq(type(s.inputs.elementSpellCounts),'table','six native element outs are wired')
eq(s.inputs.elementSpellCounts.Elec,0,'zero equipped spells is known, not missing')
eq(s.inputs.elementSpellCounts.Frost,1);eq(#s.inputs.spells,3)
eq(s.inputs.spells[1].element,'Frost');eq(s.inputs.spells[1].baseCooldown,25)
eq(s.inputs.spells[2].remaining,3);eq(s.inputs.spellCooldownC,20)
local inputs=s.inputs;inputs.heroCounts={jokerUpgradeSpellCooldownReduction=6};inputs.itemCounts=inputs.heroCounts
local p=E.preview('jokerCdrElec',inputs.heroCounts,inputs)
for _,slot in ipairs({'A','B','C'}) do
    near(p.current.metrics['spellCooldown'..slot].value,({A=21.75,B=34.8,C=69.6})[slot])
    near(p.after.metrics['spellCooldown'..slot].value,p.current.metrics['spellCooldown'..slot].value,'no electric spell means no effect on another element')
end
eq(p.after.metrics.cooldownWeight.value,0)
eq(p.after.metrics.equippedSameElementSpells.value,0)
eq(p.after.text:find('待读取',1,true),nil,'F7 text is rebuilt after per-slot results')
p=E.preview('jokerCdrFrost',inputs.heroCounts,inputs)
near(p.after.metrics.spellCooldownA.value,19.25)
near(p.after.metrics.spellCooldownB.value,34.8)
inputs.after={elementSpellCounts={Frost=2,Acid=1,Fire=0,Elec=0,Cactus=0,Voodoo=0}}
p=E.preview('jokerCdrFrost',inputs.heroCounts,inputs)
near(p.after.metrics.spellCooldownA.value,17,'explicit after context remains supported')
inputs.after=nil
p=E.preview('jokerCantRipOneTrick',inputs.heroCounts,inputs)
near(p.after.metrics.spellCooldownA.value,16)
near(p.after.metrics.spellCooldownB.value,34.8)
eq(p.after.text:find('待读取',1,true),nil)
p=E.preview('jokerCastAway',{jokerCastAway=1},inputs)
near(p.current.metrics.remainingAfterCastA.value,5);near(p.after.metrics.remainingAfterCastA.value,4)
near(p.after.metrics.remainingAfterCastB.value,3,'shorter remaining cooldown must never be raised')
p=E.preview('jokerBattleMage',{jokerBattleMage=1},inputs)
near(p.current.metrics.remainingAfterKillC.value,19.9)
p=E.preview('jokerSpellRoulette',{jokerSpellRoulette=1},inputs)
eq(p.current.metrics.randomizingNowA.value,false)
eq(p.current.metrics.randomizingNow,nil,'no ambiguous single-slot state remains')
local upgraded=I.fromSnapshot({selected={primary='itemPistol'},equipped={},upgrades={itemHero={jokerUpgradeSpellCooldownReduction=6}},runtime={},inputs=inputs})
local text=P.description('jokerUpgradeSpellCooldownReduction',upgraded,'itemHero','current')
eq(text:find('当前 6 级',1,true),nil,'native descriptions omit copy and level headings')
eq(P.page(upgraded,1).detail:find('当前升级 6 级',1,true)~=nil,true,'F7 retains permanent upgrade levels')
eq(text:find('任务拾取无张数上限',1,true),nil,'permanent upgrades are not task pickups')
eq(text:find('大厅最多装备',1,true),nil,'permanent upgrades are not equipped card stacks')
print('joker_spell_context_test: '..checks..' checks passed')
