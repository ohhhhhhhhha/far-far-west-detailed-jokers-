package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;FFWTools/src/Common/?.lua;'..package.path
local I=require('Inventory');local P=require('Panel');local E=require('Effects')
local function snapshot(n,curves)
    local cards={};for j=1,n do cards[j]='jokerLunge' end
    return I.fromSnapshot{selected={primary='itemKnuckles',secondary='itemDualRevolver'},
        equipped={itemKnuckles=cards},runtime={},upgrades={},inputs={runtimeCurves=curves}}
end
local failures={}
local function check(ok,why) if not ok then failures[#failures+1]=why end end
local extended={C_Joker_Lunge={[0]=0,[2]=.3,[3]=.45,[5]=.7,[6]=.85}}
local s=snapshot(5,extended)
local text,style=P.description('jokerLunge',s,'itemKnuckles','pickup')
check(not style.noBonus and text:find('70',1,true) and text:find('85',1,true),'live 70% -> 85% was suppressed by the original curve endpoint')
text,style=P.description('jokerLunge',s,'itemKnuckles','current')
check(not style.noBonus and text:find('70',1,true),'owned total did not use the current game curve')
local page=P.page(s,1)
check(page.detail:find('70',1,true)~=nil,'F7 did not retain the modded five-card total')
text,style=P.description('jokerLunge',snapshot(2,extended),'itemKnuckles','equip')
check(not style.noBonus and text:find('30',1,true) and text:find('45',1,true),'equip preview was suppressed by the original equip limit')
local flat={C_Joker_Lunge={[0]=0,[5]=.55,[6]=.55}}
text,style=P.description('jokerLunge',snapshot(5,flat),'itemKnuckles','pickup')
check(style.noBonus==true,'a verified 55% -> 55% pickup must remain No bonus')
text,style=P.description('jokerLunge',snapshot(5,flat),'itemKnuckles','current')
check(not style.noBonus and text:find('55',1,true),'a capped owned stack lost its combined total')
text,style=P.description('jokerLunge',snapshot(5,{}),'itemKnuckles','pickup')
check(style.noBonus==false,'missing runtime curve data was treated as confirmed No bonus')
-- Exercise the real native snapshot adapter with only its engine boundary replaced.
local function array(t) return {ForEach=function(_,f) for k,v in ipairs(t) do f(k,v) end end} end
local function map(t) return {ForEach=function(_,f) for k,v in pairs(t) do f(k,v) end end} end
local cards={};for j=1,5 do cards[j]='jokerLunge' end
local F=I.fields
local gi={playerProgress={[F.primary]='itemKnuckles',[F.secondary]='itemDualRevolver',
    [F.equipped]=map{itemKnuckles={[F.jokers]=array(cards)}},[F.upgrades]=map{}}}
local ps={AC_PlayerStateJoker={playerLocalJokers=array{}}}
local calls={}
StaticFindObject=function(p)
    if p=='/Game/Spells/Jokers/JokerCurve/C_Joker_Lunge.C_Joker_Lunge' then
        return {IsValid=function() return true end,GetFloatValue=function(_,n) calls[n]=(calls[n] or 0)+1;return extended.C_Joker_Lunge[n] or n*.15 end}
    end
end
FName=function(s) return s end
local live=I.readObjects(gi,ps,{})
local group=I.group(live,'itemKnuckles')
local result=E.preview('jokerLunge',group.counts,group.inputs)
check(result.current.metrics.meleeRangeBonus.value==.7 and result.after.metrics.meleeRangeBonus.value==.85,'native curve values did not reach the evaluator')
check(calls[5]==1 and calls[6]==1,'native curve samples must be read once per requested count')
assert(#failures==0,table.concat(failures,'; '))
print('joker_dynamic_lunge_test: runtime curve, missing data, equip-limit and held-total checks passed')
