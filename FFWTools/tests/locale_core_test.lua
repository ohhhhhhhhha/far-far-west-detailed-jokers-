local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local dictionary={['无加成']='No bonus',['当前']='Current',['秒']='s',['冰']='Frost',['已装备']='Equipped ',['系法术数']=' spells',
    ['当前近战攻速加成']='Current melee attack speed bonus'}
local cards={jokerLightWeight={zhName='轻盈体态',enName='Lightweight',zhDescription='重力 -5%',enDescription='Gravity -5%'}}
local nativeCulture='zh-Hans-CN'
local env=setmetatable({loadfile=function(path)
    if path:match('/English.lua$') then return function() return dictionary end end
    if path:match('/CardText.lua$') then return function() return cards end end
    error('unexpected dependency '..path)
end,StaticFindObject=function(path)
    eq(path,'/Script/Engine.KismetInternationalizationLibrary')
    return {IsValid=function() return true end,GetCDO=function() return {
        IsValid=function() return true end,GetCurrentLanguage=function() return {ToString=function() return nativeCulture end} end} end}
end},{__index=_G})
local L=assert(loadfile('FFWTools/src/FFWJokerInfo/Scripts/Locale.lua','t',env))()
eq(L.language(),'zh');eq(L.text('无加成'),'无加成')
eq(L.refresh(),false)
nativeCulture='en-US';eq(L.refresh(),true);eq(L.language(),'en')
eq(L.text('无加成'),'No bonus')
eq(L.text('当前近战攻速加成：+20%'),'Current melee attack speed bonus: +20%','longest match wins over fragments')
eq(L.text('已装备冰系法术数：1'),'Equipped Frost spells: 1')
eq(L.card('JOKERLIGHTWEIGHT','name'),'Lightweight')
eq(L.matches('jokerLightWeight','轻盈'),true);eq(L.matches('jokerLightWeight',' LIGHTWEIGHT '),true)
eq(L.matches('jokerLightWeight','['),false);eq(L.matches('jokerLightWeight',''),true)
eq(L.refresh(),false,'unchanged culture does not invalidate all panels')
nativeCulture='zh-CN';eq(L.refresh(),true);eq(L.card('jokerLightWeight','description'),'重力 -5%')
eq(L.matches('jokerLightWeight','lightweight'),true,'both languages work in Chinese UI')
eq(L.setCulture('en-GB'),true);eq(L.choose('红色','red'),'red')
print('locale_core_test: '..checks..' checks passed')
