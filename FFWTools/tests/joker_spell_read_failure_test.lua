package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;FFWTools/src/Common/?.lua;'..package.path
local I=require('Inventory');local P=require('Panel');local L=require('Locale')
local function map(values) return {ForEach=function(_,fn) for k,v in pairs(values) do fn(k,v) end end} end
local function spell(element,cd) return {IsValid=function() return true end,GetCDO=function() return {element=element,spellCooldown=cd} end} end
local F=I.fields
local gi={playerProgress={[F.primary]='itemShotgun',[F.secondary]='itemDualRevolver',[F.equipped]=map{},[F.upgrades]=map{}}}
local mode='error'
local ps=setmetatable({AC_PlayerStateJoker={playerLocalJokers=map{}},playerRuntimeStats={},spellARuntime=spell(8,60),spellBRuntime=spell(8,60)},
 {__index=function(_,k) if k=='spellCRuntime' then
    if mode=='error' then error('slot C field unavailable') end
    if mode=='loaded' then return spell(15,60) end
    if mode=='invalid' then return {IsValid=function() return false end} end
 end end})
local items={}
function items:F_GetEquipedSpellAmountByElement(a,f,e,v,c,ice)
 a.Acid=0;f.Fire=2;e.Elec=0;v.Voodoo=0;c.Cactus=0;ice.Frost=(mode=='empty' or mode=='invalid') and 0 or 1
end
local pawn={AC_PlayerItems=items}
StaticFindObject=function() return nil end;FName=function(s)return s end
local failures={};local function check(ok,why)if not ok then failures[#failures+1]=why end end
local s=I.readObjects(gi,ps,pawn)
local text,style=P.description('jokerCdrFrost',s,nil,'pickup')
check(not style.noBonus and text:find('待读取',1,true),'failed field read was dropped and reported as No bonus')
check(s.readErrors.SpellCCDO and s.readErrors.SpellCCDO:find('slot C field unavailable',1,true),'field failure lost its diagnostic')
check(#s.inputs.spells==3 and s.inputs.spells[3].readFailed,'failed slot must remain in per-slot comparison')
L.setCulture('en');text,style=P.description('jokerCdrFrost',s,nil,'pickup')
check(not style.noBonus and not text:find('[\228-\233]'),'unknown slot output must remain bilingual')
L.setCulture('zh');mode='loaded';s=I.readObjects(gi,ps,pawn)
text,style=P.description('jokerCdrFrost',s,nil,'pickup')
check(not style.noBonus and text:find('53.4',1,true) and not text:find('待读取',1,true),'restored slot must calculate its real cooldown without stale pending state')
check(not s.readErrors.SpellCCDO,'restored slot retained old error')
for _,empty in ipairs({'empty','invalid'}) do
 mode=empty;s=I.readObjects(gi,ps,pawn);text,style=P.description('jokerCdrFrost',s,nil,'pickup')
 check(style.noBonus and #s.inputs.spells==2 and not s.readErrors.SpellCCDO,'genuine empty slot must remain distinguishable from a read failure')
end
assert(#failures==0,table.concat(failures,'; '));print('joker_spell_read_failure_test passed')
