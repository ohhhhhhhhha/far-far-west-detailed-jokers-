package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;'..package.path
local I,P,C=require('Inventory'),require('Panel'),require('Cards')
local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local s=I.fromSnapshot({selected={primary='itemLongRanger',secondary='itemPistol'},
    equipped={itemHero={'jokerLightWeight','jokerLightWeight'}},upgrades={},runtime={},
    inputs={buffGravity=0,heldItemName='itemLongRanger',currentGravityScale=1.15}})
local original='重力 -5%'
local text=P.description('jokerLightWeight',s,nil,'pickup',original)
local start=assert(text:find(P.marker,1,true))
local body=text:sub(start+#P.marker)
local _,breaks=body:gsub('\n','')
eq(breaks+1<=7,true,'common original-card append must fit seven short logical lines')
eq(text:sub(1,start-1),original,'game original description is retained')
eq(text:find('当前 2 张',1,true),nil);eq(text:find('获得后 3 张',1,true),nil)
eq(text:find('1.15 → 1.1',1,true)~=nil,true)
eq(text:find('8%',1,true)~=nil,true);eq(text:find('12%',1,true)~=nil,true)
for _,hidden in ipairs({'20 张','0.25','大厅最多装备','任务拾取无张数上限','叠加','效果上限','详情 F7'}) do
    eq(text:find(hidden,1,true),nil,'compact description hides '..hidden)
end
eq(text:find('游戏当前读取',1,true),nil,'redundant raw diagnostic does not occupy the original tooltip')
eq(text:find('静态',1,true),nil)
eq(P.description('jokerLightWeight',s,nil,'pickup',text),text,'refresh never repeats appended blocks')
local current=P.description('jokerLightWeight',s,nil,'current',original)
eq(current:find('获得后',1,true),nil,'Tab still shows only currently held effects')
eq(current:find('→',1,true),nil)
eq(current:find('重力系数：1.15',1,true)~=nil,true)
local two=I.fromSnapshot({selected={primary='itemLongRanger',secondary='itemPistol'},
    equipped={itemLongRanger={'jokerCrackShot'},itemPistol={'jokerCrackShot','jokerCrackShot'}},upgrades={},runtime={}})
local damage=P.description('jokerCrackShot',two,nil,'pickup')
eq(damage:find('主武器',1,true)~=nil,true);eq(damage:find('副武器',1,true)~=nil,true)
eq(damage:find('+7% → +14%',1,true)~=nil,true);eq(damage:find('+14% → +21%',1,true)~=nil,true)
local magic=P.description('jokerMagicReload',s,'itemHero','pickup')
eq(magic:find('可叠加',1,true),nil,'presence-only MagicReload must not be labelled stackable')
local roulette=P.description('jokerSpellRoulette',s,'itemHero','pickup')
eq(roulette:find('额外张数不增强',1,true),nil,'one presence-only subeffect does not disable the scaling cooldown effect')

local function snapshot(cards,inputs,upgrades)
    return I.fromSnapshot({selected={primary='itemLongRanger',secondary='itemPistol'},
        equipped={itemHero=cards or {}},upgrades=upgrades or {},runtime={},inputs=inputs or {}})
end
local spellInputs={elementSpellCounts={Frost=1,Acid=1,Fire=1,Elec=0,Voodoo=0,Cactus=0},
    spells={{slot='A',element='Frost',baseCooldown=25},{slot='B',element='Acid',baseCooldown=40},{slot='C',element='Fire',baseCooldown=80}}}
local spells=snapshot({},spellInputs,{itemHero={jokerUpgradeSpellCooldownReduction=6}})
local frost=P.description('jokerCdrFrost',spells,'itemHero','pickup')
eq(frost,C.get('jokerCdrFrost').description..P.marker..'已装备冰系法术数：1\n法术 A（冰）完整冷却：21.75 秒 → 19.25 秒',
    'only the changed spell and plain element count appear')
local function noBonus(id,s,kind)
    local t,style=P.description(id,s,'itemHero',kind or 'pickup')
    eq(t,C.get(id).description..P.marker..'无加成','no-effect append contains only the red status')
    eq(style and style.noBonus,true,'renderer receives no-bonus styling separately from plain text')
    eq(style.plainText,C.get(id).description..'\n\n【奇术卡信息】','original description remains a separate normal-color block')
end
noBonus('jokerCdrElec',spells)
local electric=snapshot({'jokerCdrElec'},spellInputs)
noBonus('jokerCdrElec',electric,'current')
local floor={};for n=1,21 do floor[n]='jokerLightWeight' end
noBonus('jokerLightWeight',snapshot(floor,{buffGravity=0,heldItemName='itemLongRanger'}))
noBonus('jokerLightWeight',snapshot(floor,{buffGravity=0,heldItemName='itemLongRanger'}),'current')
noBonus('jokerMagicReload',snapshot({'jokerMagicReload'},
    {magazineAmmo=2,magazineMaximum=6,ammoCurrent=20,consumerEquipped=false,magicReloadProc=false}))
local reactive=snapshot({'jokerHitMe','jokerHitMe','jokerFightOrFlight','jokerFightOrFlight'},
    {hitMeActive=true,hitMeCachedValue=2,healingTargetIsGhost=false,droughtActive=false,healingThickSkinCount=0,
    health=70,maxHealth=100,fightOrFlightValue=.4})
local hit=P.description('jokerHitMe',reactive,'itemHero','pickup')
eq(hit,C.get('jokerHitMe').description..P.marker..'下次触发原始恢复／秒：1.5 点 → 2.25 点',
    'unchanged active cache and fixed duration are omitted')
local fight=P.description('jokerFightOrFlight',reactive,'itemHero','pickup')
eq(fight:find('当前近战攻速',1,true),nil)
eq(fight:find('+40% → +60%',1,true)~=nil,true)
eq(fight:find('6 秒 → 9 秒',1,true)~=nil,true)
local unknown,style=P.description('jokerLightWeight',snapshot({'jokerLightWeight'}),'itemHero','pickup')
eq(unknown:find('待读取',1,true)~=nil,true);eq(style and style.noBonus,false,'unknown never means no bonus')
local loading,loadingStyle=P.description('jokerCrackShot',I.fromSnapshot({}),nil,'pickup')
eq(loading:find('待读取',1,true)~=nil,true,'unread loadout is not proof of no applicable weapon')
eq(loadingStyle and loadingStyle.noBonus,false)
local tab=P.description('jokerCdrFrost',snapshot({'jokerCdrFrost'},spellInputs),'itemHero','current')
eq(tab:find('法术 A（冰）完整冷却：22.25 秒',1,true)~=nil,true)
eq(tab:find('法术 B',1,true),nil);eq(tab:find('法术 C',1,true),nil);eq(tab:find('→',1,true),nil)
local f7=P.page(s,1)
eq(f7.detail:find('当前同卡累计 2 份',1,true)~=nil,true)
eq(f7.detail:find('叠加方式：',1,true)~=nil,true)
eq(f7.detail:find('效果上限：',1,true)~=nil,true)
print('joker_compact_description_test: '..checks..' checks passed')
