package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;FFWTools/src/Common/?.lua;'..package.path
local I=require('Inventory');local P=require('Panel');local L=require('Locale')
local errors={};local function check(v,msg) if not v then errors[#errors+1]=msg end end
local function snapshot(selected) return I.fromSnapshot{selected=selected,equipped={},upgrades={},runtime={}} end
for _,missing in ipairs({{}, {primary='itemShotgun'}, {primary='itemShotgun',secondary='None'}, {secondary='itemDualRevolver'}}) do
    local text,style=P.description('jokerConsumer',snapshot(missing),nil,'pickup')
    check(not style.noBonus,'unread weapon selection must not be proof of no bonus')
    check(text:find('待读取',1,true),'unread weapon selection needs a pending explanation')
end
local text,style=P.description('jokerConsumer',snapshot{primary='itemShotgun',secondary='itemDualRevolver'},nil,'pickup')
check(style.noBonus,'known excluded weapons must still show no bonus')
text,style=P.description('jokerConsumer',snapshot{},'itemShotgun','pickup')
check(style.noBonus,'explicit excluded target must not depend on unrelated equipment reads')
text,style=P.description('jokerConsumer',snapshot{},'itemPistol','pickup')
check(not style.noBonus and text:find('25%',1,true),'explicit supported target must still calculate')
text,style=P.description('jokerWellFed',snapshot{},nil,'pickup')
check(not style.noBonus and text:find('107',1,true) and not text:find('待读取',1,true),'hero-only rules do not require weapon selection')
text,style=P.description('jokerConsumer',snapshot{primary='itemPistol'},nil,'pickup')
check(not style.noBonus and text:find('25%',1,true) and text:find('待读取',1,true),'show known target while preserving unknown other target')
L.setCulture('en')
text,style=P.description('jokerConsumer',snapshot{primary='itemShotgun'},nil,'pickup')
check(not style.noBonus and not text:find('[\228-\233]'),'pending equipment text must be bilingual')
assert(#errors==0,table.concat(errors,'; '));print('joker_partial_selection_test passed')
