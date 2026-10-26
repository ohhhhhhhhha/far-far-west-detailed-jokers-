-- Permanent-upgrade consumers from complete UE5.8 CUE exports; no runtime writes.
return function(R)
    local Cards=require('Cards')
    local register,metric,E=R.register,R.metric,R.Effects
    local count=E.count
    local function round(v) return math.floor(v+.5) end -- All capacity contributions are nonnegative.
    local function applies(card,item)
        for _,name in ipairs(card.availableOnItems) do if name:lower()==item:lower() then return true end end
        return false
    end
    local function weight(counts,id,item)
        local card=Cards.get(id)
        return applies(card,item) and count(counts,id)*card.value or 0
    end
    -- CDO defaultItemDatas, inheriting BP_Item fields where a child omits them.
    -- Three fixed-count weapons skip the whole F_InitItemDatas upgrade branch.
    local ammoBases={
        itemquadcylinder={24,216},itemlongranger={7,56},itempistol={6,60},itemshotgun={10,80},
        itemwinchester={10,90},itemminigun={300,300},itemdualrevolver={12,96},itembow={1,30},
        itemsheriffstar={20,20},itemboomerang={1,1},itemjetpack={8,8},
        itembanjo={1,1,true},itemknuckles={1,1,true},itemlasso={1,1,true},
    }
    function E.initialAmmoCapacities(counts,inputs)
        local item=inputs and inputs.itemName
        local base=type(item)=='string' and ammoBases[item:lower()]
        if not base then return {known=false,missing='已核对武器的基础弹药数据'} end
        local magazine,reserve=base[1],base[2]
        if not base[3] then
            local fuel=weight(counts,'jokerUpgradeJetpackFuel',item)
            magazine=magazine+round(base[1]*fuel)+round(base[1]*weight(counts,'jokerUpgradeClipSize',item))
            reserve=reserve+round(base[2]*weight(counts,'jokerUpgradeTotalAmmoBag','itemHero'))
                +round(base[2]*weight(counts,'jokerUpgradeTotalAmmoBagB',item))
                +round(base[2]*weight(counts,'jokerUpgradeTotalAmmoBagC',item))
                +round(base[2]*fuel)+round(base[2]*weight(counts,'jokerSpareBullets','itemHero'))
        end
        local startingMagazine=magazine
        if item:lower()=='itemjetpack' then
            startingMagazine=reserve -- F_Child_InitItemData first calls F_UpdateJetpackAmmo(0).
            if weight(counts,'jokerCrashPack',item)>0 then
                reserve=reserve*2;magazine=reserve;startingMagazine=reserve
            end
        end
        return {known=true,magazine=magazine,reserve=reserve,startingMagazine=startingMagazine}
    end
    local function ammoContext(n,i,c)
        local item=i.itemName
        local itemCounts=i.itemCounts
        if c.scope=='hero' then
            item=i.heldItemName
            itemCounts=i.heldItemCounts
        end
        if not item and #c.availableOnItems==1 and c.availableOnItems[1]~='itemHero' then item=c.availableOnItems[1] end
        local all,combined={},itemCounts~=nil and i.heroCounts~=nil
        if combined then
            for _,source in ipairs({i.heroCounts,itemCounts}) do
                for key,value in pairs(source) do all[key:lower()]=value end
            end
        end
        all[c.id:lower()]=n
        return E.initialAmmoCapacities(all,{itemName=item}),combined
    end
    local function ammoRule(id,key,label,scope)
        register(id,scope,'可叠加：同来源先累计，再按基础容量取整',
            'BP_Item.F_InitItemDatas @236–3465; BP_Item_Jetpack @11566–12036',function(n,i,c)
            local a,combined=ammoContext(n,i,c)
            local value=key=='magazineCapacity' and a.magazine or a.reserve
            return {[key]=metric((combined and '合并相关卡：' or '只计本项：')..label,value,'number','重新初始化时',nil,a.missing)}
        end,nil,'verified','各来源分别 Round(基础容量×累计权重) 后相加；不追溯修改已初始化的弹药。Banjo、Knuckles、Lasso 的固定数量分支不加容量。')
    end
    ammoRule('jokerUpgradeClipSize','magazineCapacity','弹匣容量','item')
    ammoRule('jokerUpgradeTotalAmmoBag','reserveCapacity','当前持用武器备弹容量','hero')
    ammoRule('jokerUpgradeTotalAmmoBagC','reserveCapacity','备弹容量','item')
    ammoRule('jokerUpgradeJetpackFuel','fuelCapacity','燃料容量','item')
    register('jokerUpgradeTotalAmmoBagB','item','本版本没有适用物品',
        'DT_PlayerJokers.availableOnItems; BPFL_FunctionLibrary.F_GetJokerEffects @775–844',function()
        return {reserveCapacityBonus=metric('本版本实际容量增量',0),applicable=metric('存在适用物品',false,'boolean')}
    end,'本版本不生效','verified','适用列表为空；F_GetJokerEffects 返回 0，不把 DT 的 2.5% 当实际加成。')
    register('jokerUpgradeShieldPoints','hero','本版本没有适用物品',
        'BP_Player.F_InitMaxShieldPoints @81–386; F_GetJokerEffects @775–844',function()
        return {maxShield=metric('本项初始化护盾基准',100,'points'),applicable=metric('存在适用物品',false,'boolean')}
    end,'本版本此升级不增加护盾上限','verified','适用列表为空，itemHero 聚合值恒为 0；初始化式 100+100×聚合值 得到 100。其他卡与当前运行时护盾上限另算。')
    register('jokerUpgradeDrawSpeed','item','可叠加：与快速拔枪的速率加值相加，耗时取倒数',
        'BP_Item.F_GetWeaponSwapSpeed @0–475',function(n,i,c)
        local speed=1+n*c.value
        if i.itemCounts then speed=speed+count(i.itemCounts,'jokerQuickDraw')*Cards.get('jokerQuickDraw').value end
        return {swapSpeedBonus=metric('本项切换速率加成',n*c.value,'percent'),
            swapDelayMultiplier=metric((i.itemCounts and '合并快速拔枪的' or '只计本项的')..'切换耗时倍率',1/speed,'multiplier'),
            swapDelay=metric('对应基础动作的切换耗时',i.baseSwapDelay and i.baseSwapDelay/speed,'seconds',nil,nil,'该动作 baseDelay')}
    end)
    register('jokerUpgradeJetpackForce','item','可叠加：每级增加 5% 启动时推力项',
        'BP_Item_Jetpack.ExecuteUbergraph @11006–11188, @3911–4340',function(n,i,c)
        local m={elevationForce=metric('下次启动的推力项',300*(1+n*c.value))}
        if i.jetpackElevationForce~=nil then m.storedElevationForce=metric('当前已保存推力项',i.jetpackElevationForce) end
        return m
    end,'推力项未见单项上限；最终垂直目标速度另限制到 groundHover–4096','verified',
        '启动时覆盖 elevationForce；候选不重写正在使用的缓存。消费还合并方向、地面状态与速度插值，推力项不等于最终移动速度。')
    register('jokerUpgradeJetpackFlightDuration','item','可叠加：时长倍率相加；坠击背包按持有开关减半',
        'BP_Item_Jetpack.ExecuteUbergraph @10359–10848; T_Fuel_Template.TimelineLength=1',function(n,i,c)
        local duration
        if i.itemCounts then duration=2*(1+n*c.value)*(count(i.itemCounts,'jokerCrashPack')>0 and .5 or 1) end
        return {flightDuration=metric('下次启动的名义飞行时长',duration,'seconds',nil,nil,'该物品卡片集合（坠击背包）'),
            durationMultiplier=metric('本项时长倍率',1+n*c.value,'multiplier')}
    end,nil,'verified','1 秒时间轴播放速率为时长的倒数；当前已启动时间轴不会因纯预览改变。')
    register('jokerUpgradeBoomerangLingeringTime','item','可叠加：升级倍率与余韵投掷累计倍率相乘',
        'BP_Item_Boomerang.F_GetLingeringTime @0–392; ExecuteUbergraph @446',function(n,i,c)
        local duration
        if i.itemCounts then
            local lingering=count(i.itemCounts,'jokerLingeringThrow')
            duration=.4*(1+n*c.value)*(lingering>0 and lingering*Cards.get('jokerLingeringThrow').value or 1)
        end
        return {lingeringTime=metric('新投掷的滞留时长',duration,'seconds',nil,nil,'该物品卡片集合（余韵投掷）'),
            durationMultiplier=metric('本项滞留倍率',1+n*c.value,'multiplier')}
    end)
    register('jokerUpgradeBoomerangRange','item','可叠加：范围系数加值相加',
        'BP_Item_Boomerang.F_GetRange @0–159; BP_PlayerBoomerang.ExecuteUbergraph @2771–2883',function(n,i,c)
        return {rangeMultiplier=metric('新投掷的范围系数',1+n*c.value,'multiplier'),
            forwardFlightDelay=metric('前进阶段名义延时',.5*(1+n*c.value),'seconds')}
    end,nil,'verified','武器以 baseRange=1 调用；弹体据此设置 0.5×范围系数 的延时，不将系数冒充实际世界距离。')
    register('jokerUpgradeSherrifStarPickUpRange','item','可叠加：与拾荒之星的半径加值相加',
        'BP_SheriffStarProjectile.F_GetPickUpRange @0–522; ExecuteUbergraph @5532–5690',function(n,i,c)
        local multiplier
        if i.heldItemName and i.heldItemName:lower()~='itemsheriffstar' then multiplier=1
        elseif i.heldItemName and i.itemCounts then multiplier=1+n*c.value+count(i.itemCounts,'jokerScavengerStar')*Cards.get('jokerScavengerStar').value end
        return {pickupRadius=metric('新生成徽章拾取半径',multiplier and 200*multiplier,'number','世界单位',nil,'当前持用物品及其卡片集合'),
            rangeBonus=metric('持用徽章时本项半径加成',n*c.value,'percent')}
    end,nil,'verified','初始 SphereOverlapPickup 半径 200；查询使用此刻持用物品 itemName，换到其他武器时这些升级和拾荒之星均不适用。')
    register('jokerUpgradeChargingSpeed','item','可叠加：增加每次合格命中的能量获得量',
        'BP_Item_Knuckles.ExecuteUbergraph @440–871, @5149–5417; BP_Item_Lasso @1297–1728',function(n,i,c)
        return {chargeGain=metric('每次合格命中获得能量',.0935*(1+n*c.value),'percent')}
    end,nil,'verified','不是蓄力动作时长。拳套与套索在 F_TraceMeleeDamages 返回 HasHit 后增加能量；拳套狂怒之拳受击分支也使用相同增量。')
    register('jokerUpgradeChordCapacity','item','可叠加：增加和弦上限，并影响特殊攻击伤害',
        'BP_Item_Banjo.ExecuteUbergraph @2195–2332, @2684, @3756–3935, @4467–4641; F_GetSpecialAttackDamages',function(n,i,c)
        local damage
        if i.itemCounts then
            if count(i.itemCounts,'jokerBardbarian')==0 then damage=25*(1+.15*n*c.value)
            elseif i.bardbarianStoredDamage~=nil then
                damage=i.bardbarianStoredDamage>0 and i.bardbarianStoredDamage*(1+.15*n*c.value) or 25
            end
        end
        return {currentChordCapacity=metric('当前已保存和弦上限',i.banjoAdditionalChords and 7+i.banjoAdditionalChords,'number',nil,nil,'武器 additionalChords'),
            nextDrawChordCapacity=metric('下次拔出后和弦上限',7+round(n*c.value)),
            specialAttackDamage=metric('本阶段特殊攻击原始伤害',damage,'points',nil,nil,'该物品卡片集合与吟游蛮者伤害缓存')}
    end,nil,'verified','拔出时缓存 additionalChords；候选不追溯改写。普通加弦使用余数循环，另一路按上限 clamp。特殊攻击使用 1+0.15×级数；吟游蛮者存在但缓存≤0时跳过该倍率，返回基础25。')
end
