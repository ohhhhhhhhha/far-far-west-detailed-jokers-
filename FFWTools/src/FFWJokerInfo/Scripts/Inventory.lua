-- Read-only snapshot adapter. Uses pure game getters; never mutates inventory.
local Cards=require('Cards')
local Effects=require('Effects')
local I={}
local hitMeCache={}
local F={
 primary='selectedItemA_207_DB75D0B645F36A6C80EA10BC4BCAA457',
 secondary='selectedItemB_208_5EFA92804322145CAD0049B5E0A8B48D',
 equipped='itemJokers_221_B68401A4476969C408297F9FD92F3128',
 upgrades='itemsUpgrades_216_1E448EF04C663CC03DC815A885A3CB74',
 jokers='jokers_13_7822C195413EA2810E969F8C260AA8B6',
 tweaks='tweaks_4_767FB08F43E69215549B2C890A7ECC9F',
 ammoA='datasWepA_24_C099A0F04138D662182F8D9C94DCA8C6',
 ammoB='datasWepB_25_EE50A5DA4381738DA8C10CB8353016D9',
 initialized='isInitialized_21_672D123E4B1D7C80BBD86083F97E9324',
 magazine='currentMagazineAmmos_10_76E089514907BA2E4DDB1CA16CEC4B6B',
 magazineMaximum='maxMagazineAmmos_8_E1B199D345F51D5DF152DBBB0371E153',
 ammoCurrent='currentTotalAmmos_17_DDF8963D42826C9B6D9A9E92E9563632',
 ammoMaximum='maxTotalAmmos_18_2EACEDBD42C653C7490D2F999719144E',
 itemDamage='itemDamages_37_459AA0EF4C7AEA0A0B4EEA816F22EDCB',
 cooldownA='cooldownSpellA_32_D8F383D94883A467CF929A9E452C176D',
 cooldownB='cooldownSpellB_31_CA70EE57499218F37A2F3F93523EDEC8',
 cooldownC='cooldownSpellC_30_C211B06A4A281EC29108A48303174C4C',
}
I.fields=F
local function usable(v) return v~=nil and not tostring(v):match('^TrivialObject:') end
local function unwrap(v)
    if not usable(v) then return nil end
    if type(v)=='table' and type(v.get)~='function' then return v end
    if type(v)=='string' or type(v)=='number' or type(v)=='boolean' then return v end
    local ok,x=pcall(function() return v:get() end)
    if ok and usable(x) then return x end
    return v
end
local function field(o,k)
    if not usable(o) then return nil end
    local ok,v=pcall(function() return o[k] end)
    if ok and usable(v) then return unwrap(v) end
end
local function name(v)
    v=unwrap(v); if not usable(v) then return nil end
    if type(v)=='string' then return v end
    local ok,s=pcall(function() return v:ToString() end)
    if ok and type(s)=='string' then return s end
end
I.name=name; I.field=field; I.unwrap=unwrap
local function number(v) v=unwrap(v); return type(v)=='number' and v or nil end
local function boolean(v) v=unwrap(v); if type(v)=='boolean' then return v end end
local function nonempty(v) return type(v)=='string' and v~='' and v:lower()~='none' end
local function find(t,k)
    if type(t)~='table' or not nonempty(k) then return nil end
    if t[k]~=nil then return t[k] end
    for key,v in pairs(t) do if type(key)=='string' and key:lower()==k:lower() then return v end end
end
local function copy(t) local r={}; for k,v in pairs(t or {}) do r[k]=v end; return r end
function I.applies(id,item)
    local card=Cards.get(id)
    if not card or not nonempty(item) then return false end
    for _,v in ipairs(card.availableOnItems) do if v:lower()==item:lower() then return true end end
    return false
end
function I.fromSnapshot(s)
    s=s or {}
    local r={selected=copy(s.selected),equipped=s.equipped,upgrades=s.upgrades,runtime=s.runtime,
        inputs=copy(s.inputs),inputsByItem=s.inputsByItem or {},missing={},groupsByItem={},
        readErrors=s.readErrors or {},context=s.context or {}}
    for _,key in ipairs({'equipped','upgrades','runtime'}) do
        if type(s[key])~='table' then r.missing[#r.missing+1]=key end
    end
    r.complete=#r.missing==0
    -- The game counts entries of A, B and Hero equipped arrays plus task array length.
    if s.equipped and s.runtime and nonempty(r.selected.primary) and nonempty(r.selected.secondary) then
        r.inputs.activeCardCount=#s.runtime
        for _,item in ipairs({r.selected.primary,r.selected.secondary,'itemHero'}) do
            r.inputs.activeCardCount=r.inputs.activeCardCount+#(find(s.equipped,item) or {})
        end
    end
    return r
end
function I.group(s,item)
    if not nonempty(item) then return nil end
    local key=item:lower()
    if s.groupsByItem[key] then return s.groupsByItem[key] end
    local g={itemName=item,counts={},parts={},complete=s.complete,missing=s.missing,inputs=copy(s.inputs),rarities={}}
    for k,v in pairs(find(s.inputsByItem,item) or {}) do g.inputs[k]=v end
    local function add(id,n,source)
        local card=Cards.get(id)
        if card and I.applies(card.id,item) and type(n)=='number' and n>0 then
            id=card.id
            g.counts[id]=(g.counts[id] or 0)+n
            local p=g.parts[id] or {equipped=0,upgrades=0,runtime=0};g.parts[id]=p;p[source]=p[source]+n
        end
    end
    for _,id in ipairs(find(s.equipped,item) or {}) do
        add(id,1,'equipped')
        local c=Cards.get(id); if c then g.rarities[c.rarity]=true end
    end
    for id,n in pairs(find(s.upgrades,item) or {}) do add(id,n,'upgrades') end
    for _,id in ipairs(s.runtime or {}) do add(id,1,'runtime') end
    if s.equipped then
        local n=0; for _ in pairs(g.rarities) do n=n+1 end
        g.inputs.distinctRarities=n
    end
    s.groupsByItem[key]=g
    -- Gravity combines hero cards with only the weapon currently in the hands.
    -- Cache first because forming this context may request another item group.
    g.inputs.itemName=item
    g.inputs.itemCounts=g.counts
    g.inputs.gravityContextComplete=s.complete
    g.inputs.heroCounts=key=='itemhero' and g.counts or I.group(s,'itemHero').counts
    if nonempty(s.inputs.heldItemName) then
        g.inputs.heldItemCounts=I.group(s,s.inputs.heldItemName).counts
    end
    if key~='itemhero' and g.complete and g.inputs.reloadSpeed==nil then
        g.inputs.reloadSpeed=Effects.reloadSpeed(g.counts,g.inputs).value
    end
    return g
end
function I.groups(s)
    local list,seen={},{}
    for _,pair in ipairs({{'角色','itemHero'},{'主武器',s.selected.primary},{'副武器',s.selected.secondary}}) do
        local label,item=pair[1],pair[2]
        if nonempty(item) and not seen[item:lower()] then
            local g=I.group(s,item); g.label=label; list[#list+1]=g; seen[item:lower()]=true
        end
    end
    return list
end
function I.candidateInputs(group,id,kind)
    local r=copy(group.inputs); r.after={};r.candidateKind=kind
    if r.activeCardCount~=nil then r.after.activeCardCount=r.activeCardCount+1 end
    local c=Cards.get(id)
    if r.distinctRarities~=nil then
        r.after.distinctRarities=r.distinctRarities
        if kind=='equip' and c and not group.rarities[c.rarity] then r.after.distinctRarities=r.distinctRarities+1 end
    end
    return r
end
local function each(value,callback)
    if not usable(value) then return false end
    local ok=pcall(function() value:ForEach(function(k,v) callback(unwrap(k),unwrap(v)) end) end)
    return ok
end
local function array(value)
    local r={}
    local ok=each(value,function(_,v) local n=name(v); assert(n,'Unreadable FName'); r[#r+1]=n end)
    if ok then return r end
end
local function itemMap(value,inside,convert)
    local r={}
    local ok=each(value,function(k,v)
        local item=name(k); assert(item,'Unreadable item key')
        local result=convert(field(v,inside)); assert(result,'Unreadable nested item collection')
        r[item]=result
    end)
    if ok then return r end
end
local function numberMap(value)
    local r={}
    local ok=each(value,function(k,v) local key,n=name(k),number(v); assert(key and n,'Unreadable number map'); r[key]=n end)
    if ok then return r end
end
local function componentKey(component)
    local ok,key=pcall(function() return component:GetFullName()..'@'..tostring(component:GetAddress()) end)
    if ok then return key end
end
function I.observeBelowHeal(component,gameInstance)
    local ps=field(component,'PlayerState')
    local hp,maximum=number(field(ps,'playerHeal')),number(field(ps,'playerMaxHeal'))
    if not hp or not maximum or hp<=0 or hp>=maximum then return false end
    local pawn=ps:GetPawn()
    if not pawn:IsLocallyControlled() then return false end
    local key=componentKey(component)
    if not key then return false end
    local lib=StaticFindObject('/Game/Gamework/BPFL_FunctionLibrary.BPFL_FunctionLibrary_C'):GetCDO()
    local has,value={},{}
    gameInstance=gameInstance or require('UEHelpers').GetGameInstance()
    lib:F_GetJokerEffects(gameInstance,FName('jokerHitMe'),FName('itemHero'),component,has,value)
    local cumulative=number(find(value,'jokerCumulativeValue'))
    if cumulative==nil then error('HitMe aggregate output unavailable') end
    hitMeCache={key=key,value=cumulative}
    return true
end
function I.readObjects(gameInstance,playerState,pawn)
    local progress=field(gameInstance,'playerProgress')
    local joker=field(playerState,'AC_PlayerStateJoker')
    local s={selected={primary=name(field(progress,F.primary)),secondary=name(field(progress,F.secondary))},
        equipped=itemMap(field(progress,F.equipped),F.jokers,array),
        upgrades=itemMap(field(progress,F.upgrades),F.tweaks,numberMap),
        runtime=array(field(joker,'playerLocalJokers')),inputs={},inputsByItem={},readErrors={},context={}}
    local input=s.inputs
    local function read(label,fn)
        local ok,value=pcall(fn)
        if ok then return value end
        s.readErrors[label]=tostring(value)
    end
    input.health=number(field(playerState,'playerHeal'))
    input.maxHealth=number(field(playerState,'playerMaxHeal'))
    if input.maxHealth and input.maxHealth<=0 then input.health=nil;input.maxHealth=nil end
    local shieldComponent=field(playerState,'AC_PlayerState_Shield')
    input.shield=number(field(shieldComponent,'shieldPoints'))
    input.scoutsHonorActive=boolean(field(shieldComponent,'isJokerScoutsHonorStillEnabled'))
    input.killCombo=number(field(playerState,'enemyKillCombo'))
    for key,property in pairs({rampageStack='jokerRampageTotalStack',bloodLustStack='jokerBloodLustTotalStack',
        riposteValue='jokerRiposteValue',cheapSkateBonusHealth='jokerCheapSkateBonusHealth',consecutiveHits='eagleLeverConsecutiveShot',fightOrFlightValue='jokerFightOrFlightValue'}) do
        input[key]=number(field(joker,property))
    end
    for key,property in pairs({fistRageActive='jokerFistRageActive',panicActive='jokerPanicAttackEnabled',soulEaterActive='isJokerSoulEaterActive',firstShotLoaded='firstShotLoaded',coinFlipBonus='jokerCoinFlipBonus',magicReloadProc='magicReloadProc'}) do
        input[key]=boolean(field(joker,property))
    end
    local heroJokers=array(field(playerState,'itemHeroJokers'))
    if heroJokers then
        input.heroJokerCounts={}
        for _,id in ipairs(heroJokers) do
            local c=Cards.get(id)
            if c then input.heroJokerCounts[c.id]=(input.heroJokerCounts[c.id] or 0)+1 end
        end
        input.healingThickSkinCount=input.heroJokerCounts.jokerThickSkin or 0
    end
    if componentKey(joker)==hitMeCache.key then input.hitMeCachedValue=hitMeCache.value end
    input.hitMeActive=boolean(read('HitMeTimer',function()
        return StaticFindObject('/Script/Engine.KismetSystemLibrary'):GetCDO():K2_IsTimerActive(joker,'F_JokerHitMeHeal')
    end))
    for key,id in pairs({droughtActive='modifierDrought',modifierGreed='modifierGreed'}) do
        input[key]=boolean(read(id,function()
            local out={}
            StaticFindObject('/Game/Gamework/BPFL_Gameplay.BPFL_Gameplay_C'):GetCDO():F_IsModifierActive(FName(id),pawn,out)
            return find(out,'Active')
        end))
    end
    input.healingTargetIsGhost=boolean(read('HealingPawnClass',function()
        local class=pawn:GetFullName():match('^(%S+)')
        if class=='BP_PlayerGhost_C' then return true end
        if class=='BP_Player_C' then return false end
    end))
    local gameState=field(pawn,'gameState')
    if gameState then
        input.missionGold=number(read('F_GetLocalGolds',function()
            local out={};gameState:F_GetLocalGolds(out);return find(out,'AvailableGolds')
        end))
        input.missionSouls=number(read('F_GetLocalSouls',function()
            local out={};gameState:F_GetLocalSouls(out);return find(out,'AvailableSouls')
        end))
        input.gold=input.missionGold
    end
    local damageMap=numberMap(field(field(playerState,'playerRuntimeLeaderboardLocal'),F.itemDamage))
    local runtimeStats=field(playerState,'playerRuntimeStats')
    local items=field(pawn,'AC_PlayerItems')
    if items then
        input.elementSpellCounts=read('F_GetEquipedSpellAmountByElement',function()
            local acid,fire,elec,voodoo,cactus,frost={},{},{},{},{},{}
            items:F_GetEquipedSpellAmountByElement(acid,fire,elec,voodoo,cactus,frost)
            local result={}
            for element,out in pairs({Acid=acid,Fire=fire,Elec=elec,Voodoo=voodoo,Cactus=cactus,Frost=frost}) do
                result[element]=assert(number(find(out,element)),'Missing element output: '..element)
            end
            return result
        end)
    end
    local spells={}
    local elements={[7]='Acid',[8]='Fire',[9]='Elec',[12]='Voodoo',[13]='Cactus',[15]='Frost'}
    for _,slot in ipairs({'A','B','C'}) do
        local remaining=number(field(runtimeStats,F['cooldown'..slot]))
        input['spellCooldown'..slot]=remaining
        local spell=read('Spell'..slot..'CDO',function()
            local cls=field(playerState,'spell'..slot..'Runtime')
            if not cls or not cls:IsValid() then return nil end
            local cdo=cls:GetCDO();local element=number(field(cdo,'element'))
            return {slot=slot,element=element and (elements[element] or 'None'),
                baseCooldown=number(field(cdo,'spellCooldown')),remaining=remaining}
        end)
        if spell then spells[#spells+1]=spell end
    end
    if #spells>0 then input.spells=spells end
    local manager=field(gameInstance,'refItemManager')
    for key,property in pairs({knucklesCharge='rageBar_Knuckles',lassoCharge='ragebar_Lasso',banjoHitAmount='banjoHitAmount'}) do
        input[key]=number(field(manager,property))
    end
    input.jetpackAntigravActive=boolean(field(manager,'isUsingJetpackAntigrav'))
    for _,pair in ipairs({{s.selected.primary,F.ammoA},{s.selected.secondary,F.ammoB}}) do
        local item,ammoField=pair[1],pair[2]
        if nonempty(item) then
            local values={};s.inputsByItem[item]=values
            if damageMap then values.itemDamage=find(damageMap,item) or 0 end
            local ammo=field(runtimeStats,ammoField)
            if boolean(field(ammo,F.initialized)) then
                values.magazineAmmo=number(field(ammo,F.magazine))
                values.magazineMaximum=number(field(ammo,F.magazineMaximum))
                values.ammoCurrent=number(field(ammo,F.ammoCurrent))
                values.ammoMaximum=number(field(ammo,F.ammoMaximum))
            end
        end
    end
    local held=field(items,'equipedItem')
    local heldName=name(field(held,'itemName'))
    input.heldItemName=heldName
    input.heldAiming=boolean(field(held,'isAiming'))
    input.heldSlowPlayerDuringAim=boolean(field(held,'slowPlayerDuringAim'))
    input.buffGravity=number(field(pawn,'buffGravity'))
    local movement=field(pawn,'CharacterMovement')
    input.currentGravityScale=number(field(movement,'GravityScale'))
    input.maxWalkSpeed=number(field(movement,'MaxWalkSpeed'))
    -- F_UpdateJumpCount's isSwappingWeapon is a call parameter, not a Pawn property.
    -- Without that event context show JumpStar's conditional 2n result only.
    if movement then input.swimming=boolean(read('IsSwimming',function() return movement:IsSwimming() end)) end
    local heldInputs=find(s.inputsByItem,heldName)
    if heldInputs then heldInputs.aiming=boolean(field(held,'isAiming')) end
    local function describe(o)
        local ok,result=pcall(function() return o:GetFullName() end)
        return ok and result or '<unavailable>'
    end
    s.context.pawn=describe(pawn);s.context.held=describe(held)
    -- Blueprint out parameters require a Lua table in this UE4SS build.
    -- These are the same getters used by the game's card condition paths.
    if nonempty(heldName) then
        if not heldInputs then heldInputs={};s.inputsByItem[heldName]=heldInputs end
        for key,property in pairs({aiming='isAiming',slowPlayerDuringAim='slowPlayerDuringAim',
            isFixedAmountCount='isFixedAmountCount',canBeAffectedByPlayerFireRate='canBeAffectedByPlayerFireRate'}) do
            heldInputs[key]=boolean(field(held,property))
        end
        for key,property in pairs({timeHoldedDraw='timeHoldedDraw',homingBurstShot='homingBurstShot',
            additionalChords='additionalChords',banjoAdditionalChords='additionalChords',
            bardbarianStoredDamage='bardbarianDamages',jetpackElevationForce='elevationForce',weaponElement='element'}) do
            heldInputs[key]=number(field(held,property))
        end
        local manager=field(field(held,'gameInstance'),'refItemManager')
        for key,property in pairs({knucklesCharge='rageBar_Knuckles',lassoCharge='ragebar_Lasso',banjoHitAmount='banjoHitAmount'}) do
            heldInputs[key]=number(field(manager,property))
        end
        heldInputs.jetpackAntigravActive=boolean(field(manager,'isUsingJetpackAntigrav'))
        input.meleeWeapon=boolean(read('MeleeWeaponTag',function() return held:ActorHasTag(FName('meleeWeapon')) end))
        local data=read('F_GetItemDatas',function() local out={};held:F_GetItemDatas(out);return out end)
        if boolean(field(data,F.initialized)) then
            input.heldMagazineAmmo=number(field(data,F.magazine))
            for key,property in pairs({magazineAmmo=F.magazine,magazineMaximum=F.magazineMaximum,ammoCurrent=F.ammoCurrent,ammoMaximum=F.ammoMaximum}) do
                heldInputs[key]=number(field(data,property))
            end
        end
        local defaults=read('OriginalItemCDO',function() return field(held:GetClass():GetCDO(),'defaultItemDatas') end)
        heldInputs.defaultAmmoMaximum=number(field(defaults,F.ammoMaximum))
        heldInputs.defaultAmmoCurrent=number(field(defaults,F.ammoCurrent))
        if heldInputs then
            heldInputs.reloadSpeed=number(read('F_GetReloadSpeed',function()
                local out={};held:F_GetReloadSpeed(out);return find(out,'ReloadSpeed')
            end))
            heldInputs.attackSpeed=number(read('F_GetAttackSpeed',function()
                local out={};held:F_GetAttackSpeed(1,out);return find(out,'AttackSpeed')
            end))
        end
        input.groundQueryPassed=boolean(read('F_IsOnGround',function()
            local out={};pawn:F_IsOnGround(1,out);return find(out,'OnGround')
        end))
        input.runningQueryResult=boolean(read('F_IsRunning',function()
            local out={};pawn:F_IsRunning(out);return find(out,'Running')
        end))
        input.horizontalSpeed=number(read('GetVelocity',function()
            local v=pawn:GetVelocity();return math.sqrt(v.X*v.X+v.Y*v.Y)
        end))
        -- Hero cards that affect a weapon use the actual held item's values.
        -- Keep those values off other weapon groups: a bow's cache is not a banjo's cache.
        s.inputsByItem.itemHero=copy(heldInputs)
    end
    local snapshot=I.fromSnapshot(s)
    if nonempty(heldName) then
        local heldGroup=I.group(snapshot,heldName)
        local heroValues=snapshot.inputsByItem.itemHero
        if heldGroup.complete then heroValues.consumerEquipped=(heldGroup.counts.jokerConsumer or 0)>0 end
        heroValues.consumerAvailable=I.applies('jokerConsumer',heldName)
        -- I.group builds the hero group while forming held-item context.
        local heroGroup=I.group(snapshot,'itemHero')
        heroGroup.inputs.consumerEquipped=heroValues.consumerEquipped
        heroGroup.inputs.consumerAvailable=heroValues.consumerAvailable
    end
    return snapshot
end
function I.resetContext() hitMeCache={} end
function I.read(context)
    if context then return I.readObjects(context.gameInstance,context.playerState,context.pawn) end
    local helpers=require('UEHelpers')
    local controller=helpers.GetPlayerController()
    return I.readObjects(helpers.GetGameInstance(),field(controller,'PlayerState'),field(controller,'Pawn'))
end
return I
