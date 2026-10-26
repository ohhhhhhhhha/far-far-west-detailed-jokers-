-- Synthetic catalog audit: no game objects, personal data or runtime save files.
package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;FFWTools/tests/?.lua;'..package.path
local C,E,I,P,L,J=require('Cards'),require('Effects'),require('Inventory'),require('Panel'),require('Locale'),require('Json')
local checks,cases=0,0
local function check(ok,label) checks=checks+1;assert(ok,label) end
local function inputs(mode,item)
    if mode=='mixed' then return {heldItemName=item=='itemHero' and 'itemLongRanger' or item,
        ammoCurrent=0,health=100,maxHealth=100,shield=0,groundQueryPassed=true} end
    local active=mode=='active'
    return {heldItemName=item=='itemHero' and 'itemLongRanger' or item,
        health=active and 20 or 100,maxHealth=100,shield=active and 50 or 0,gold=active and 75 or 0,
        itemDamage=active and 500 or 0,killCombo=active and 11 or 0,groundQueryPassed=not active,
        aiming=active,heldAiming=active,heldSlowPlayerDuringAim=true,slowPlayerDuringAim=true,swimming=false,
        maxWalkSpeed=active and 960 or 550,speedsterSpeed=active and 1210 or 550,buffGravity=0,
        isSwappingWeapon=false,meleeWeapon=active,heldItemMatchesDamage=true,
        rampageStack=active and .2 or 0,bloodLustStack=active and .2 or 0,riposteValue=active and 2 or 1,
        fightOrFlightValue=active and .4 or 0,hitMeActive=active,hitMeCachedValue=2,
        fistRageActive=active,panicActive=active,soulEaterActive=active,scoutsHonorActive=active,coinFlipBonus=active,
        magazineAmmo=mode=='empty' and 0 or 6,magazineMaximum=10,ammoCurrent=mode=='empty' and 0 or 60,ammoMaximum=60,
        defaultAmmoMaximum=60,defaultAmmoCurrent=60,isFixedAmountCount=false,
        droughtActive=false,healingTargetIsGhost=false,healingThickSkinCount=0,
        consumerEquipped=false,consumerAvailable=false,magicReloadProc=false,
        elementSpellCounts={Frost=1,Fire=1,Acid=1,Elec=0,Voodoo=0,Cactus=0},
        spells={{slot='A',element='Frost',baseCooldown=25,remaining=active and 15 or 0},
            {slot='B',element='Fire',baseCooldown=80,remaining=active and 30 or 0},
            {slot='C',element='Acid',baseCooldown=40,remaining=active and 20 or 0}},
        spellCooldownA=0,spellCooldownB=0,spellCooldownC=0,spellCooldownRemaining=0,spellRemaining=0,otherSpellRemaining=0,
        modifierGreed=false,consecutiveHits=active and 5 or 0,weaponElement='fire',canBeAffectedByPlayerFireRate=true,
        lassoCharge=mode=='empty' and 1 or 0,timeHoldedDraw=active and 4 or 0,attackSpeed=1,knucklesCharge=0,
        additionalChords=0,banjoHitAmount=0,bardbarianStoredDamage=active and 75 or 0,
        skyLashBuffActive=active,skyLashBuffSpeed=active and 775 or 0,jetpackAntigravActive=active,
        traderTradesFinished=0,missionGold=active and 100 or 0,missionSouls=active and 100 or 0,
        targetIsEnemy=true,targetIsBoss=false,targetIsElite=false,targetDefaultHealth=100,
        targetEstimatedDamage=active and 90 or 0,targetMarkAceActive=active,coldBloodedEligible=active,
        chestIsFake=false,chestCanDropContent=true,luckMultiplier=1}
end
for _,card in ipairs(C.all()) do
    -- Each rule is audited; weapon-specific capacity/dispatch combinations have
    -- separate numeric tests in the upgrade/weapon/hero suites.
    local items={card.availableOnItems[1] or 'itemHero'}
    if card.id=='jokerDestroyer' then items[#items+1]='itemMinigun' end
    for _,item in ipairs(items) do
        for _,n in ipairs({0,1,2,20,100}) do
            for _,mode in ipairs({'resting','active','empty','unknown','mixed'}) do
                local equipped,upgrades,runtime={},{},{}
                if card.id:lower():find('jokerupgrade',1,true) then upgrades[item]={[card.id]=n}
                elseif n>0 then equipped[item]={card.id};for index=2,n do runtime[#runtime+1]=card.id end end
                local s=I.fromSnapshot{selected={primary=item=='itemHero' and 'itemLongRanger' or item,secondary='itemPistol'},
                    equipped=equipped,upgrades=upgrades,runtime=runtime,inputs=mode=='unknown' and {} or inputs(mode,item)}
                local before=J.encode{equipped=equipped,upgrades=upgrades,runtime=runtime,inputs=s.inputs}
                for _,culture in ipairs({'zh-Hans','en-US'}) do
                    L.setCulture(culture)
                    for _,kind in ipairs({'pickup','current','equip'}) do
                        local label=card.id..'/'..item..'/'..n..'/'..mode..'/'..culture..'/'..kind
                        local text,style=P.description(card.id,s,item,kind)
                        check(type(text)=='string' and type(style)=='table',label..': valid description')
                        if kind~='pickup' then check(style.noBonus==false,label..': warning is acquisition-only') end
                        local p=text:find(P.marker,1,true)
                        local body=p and text:sub(p+#P.marker) or ''
                        if kind=='current' then check(not body:find('→',1,true),label..': no acquisition arrow in current detail') end
                        check(not (style.noBonus and body:find('待读取',1,true)),label..': unknown is not no bonus')
                        local repeated=P.description(card.id,s,item,kind,text)
                        check(repeated==text,label..': refresh is idempotent')
                        if culture=='en-US' then
                            check(not text:find('[\228-\233][\128-\191][\128-\191]'),label..': translated compact description')
                        end
                        cases=cases+1
                    end
                end
                check(before==J.encode{equipped=equipped,upgrades=upgrades,runtime=runtime,inputs=s.inputs},card.id..': preview leaves inputs unchanged')
                local group=I.group(s,item)
                local preview=E.preview(card.id,group.counts,group.inputs,1)
                for _,stage in ipairs({preview.current,preview.after}) do
                    for key,m in pairs(stage.metrics) do
                        for _,field in ipairs({'value','potential'}) do
                            local value=m[field]
                            if type(value)=='number' then check(value==value and math.abs(value)<math.huge,card.id..'.'..key..': finite numeric metric') end
                        end
                    end
                end
            end
        end
    end
end
L.setCulture('zh-Hans')
check(#C.all()==183,'retained catalog size')
print('joker_catalog_description_test: '..#C.all()..' rows, '..cases..' descriptions, '..checks..' checks passed')
