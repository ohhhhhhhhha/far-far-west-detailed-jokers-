package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;FFWTools/src/Common/?.lua;'..package.path
local I,P,L=require('Inventory'),require('Panel'),require('Locale')
local failures={};local function check(ok,msg)if not ok then failures[#failures+1]=msg end end
for _,language in ipairs({'zh','en'}) do
 L.setCulture(language)
 local s=I.fromSnapshot{selected={primary='itemPistol'},equipped={},upgrades={},runtime={}}
 local text,style=P.description('jokerConsumer',s,nil,'pickup')
 local known=text:find(L.text('主武器：'),1,true)
 local missing=text:find(L.text('副武器：效果待读取'),1,true)
 local value=text:find('25%',text:find(P.marker,1,true)+#P.marker,true)
 check(not style.noBonus and known and missing and value and known<value,'mixed known/unknown effects need an explicit primary weapon heading: '..language)
 -- Apply the symmetric case: only secondary is available.
 s=I.fromSnapshot{selected={secondary='itemPistol'},equipped={},upgrades={},runtime={}}
 text,style=P.description('jokerConsumer',s,nil,'pickup')
 known=text:find(L.text('副武器：'),text:find(P.marker,1,true)+#P.marker,true)
 missing=text:find(L.text('主武器：效果待读取'),1,true)
 value=text:find('25%',text:find(P.marker,1,true)+#P.marker,true)
 check(not style.noBonus and known and missing and value and known<value,'known secondary effect is unlabeled: '..language)
 -- Exact applicability comes from the card whitelist and does not need card counts.
 s=I.fromSnapshot{selected={primary='itemShotgun',secondary='itemDualRevolver'}}
 text,style=P.description('jokerConsumer',s,'itemShotgun','pickup')
 check(style.noBonus,'explicit excluded target should not depend on unavailable inventory: '..language)
 text,style=P.description('jokerConsumer',s,nil,'pickup')
 check(style.noBonus,'two known excluded weapons should not wait for irrelevant counts: '..language)
 text,style=P.description('jokerConsumer',s,'itemShotgun','current')
 check(not style.noBonus and not text:find(P.marker,1,true),'excluded held-card view should retain its original description: '..language)
 s=I.fromSnapshot{selected={primary='itemPistol',secondary='itemDualRevolver'}}
 text,style=P.description('jokerConsumer',s,nil,'pickup')
 check(not style.noBonus and text:lower():find(L.text('效果待读取'):lower(),1,true),'eligible but unread counts must remain unknown: '..language)
 s=I.fromSnapshot{}
 text,style=P.description('jokerConsumer',s,nil,'pickup')
 check(not style.noBonus and text:lower():find(L.text('效果待读取'):lower(),1,true),'unread weapon selection is not proven inapplicable: '..language)
 text,style=P.description('jokerWellFed',s,nil,'pickup')
 check(not style.noBonus and text:lower():find(L.text('效果待读取'):lower(),1,true),'unread hero counts must remain unknown: '..language)
end
assert(#failures==0,table.concat(failures,'; '));print('joker_partial_context_labels_test passed')
