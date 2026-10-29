-- Read-only formula layer. Evidence is static CUE4Parse UE5.8 bytecode, not a live test.
local Cards = require('Cards')
local Effects = {}
local rules = {}
local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end
local function count(counts, id)
    if type(counts) == 'number' then return math.max(0, counts) end
    if type(counts) ~= 'table' then return 0 end
    if counts[id] ~= nil then return math.max(0, tonumber(counts[id]) or 0) end
    local lower = id:lower()
    for k, v in pairs(counts) do
        if type(k)=='string' and k:lower()==lower then return math.max(0, tonumber(v) or 0) end
    end
    return 0
end
Effects.count = count

function Effects.curve(name, x)
    local keys = assert(Cards.curves[name], 'Unknown verified curve: '..tostring(name))
    if x <= keys[1][1] then return keys[1][2] end
    for i=2,#keys do
        local a,b=keys[i-1],keys[i]
        if x <= b[1] and b[1]>a[1] then
            return a[2] + (b[2]-a[2]) * (x-a[1])/(b[1]-a[1])
        end
    end
    return keys[#keys][2]
end
local function metric(label, value, unit, condition, potential, missing)
    return {label=label,value=value,unit=unit or 'number',condition=condition,
        potential=potential,missing=missing,known=value~=nil}
end
local function conditional(label, potential, unit, active, condition, missing, neutral)
    local value
    if potential == 0 then value=0
    elseif active~=nil then
        if active then value=potential
        elseif neutral~=nil then value=neutral
        elseif unit=='boolean' or unit=='condition' then value=false
        else value=0 end
    end
    return metric(label,value,unit,condition,potential,active==nil and missing or nil)
end
local function health(i)
    if i.healthRatio~=nil then return i.healthRatio end
    if i.health~=nil and i.maxHealth and i.maxHealth>0 then return i.health/i.maxHealth end
end
local function hasShield(i) if i.shield~=nil then return i.shield>0 end end
-- BP_Item.F_GetReloadSpeed, all branches @5–1611. This also works for an
-- unequipped weapon without borrowing the held item's native getter result.
function Effects.reloadSpeed(counts,i)
    i=i or {}
    local function unknown(why) return metric('组合换弹速率',nil,'multiplier',nil,nil,why) end
    if type(counts)~='table' or type(i.heroCounts)~='table' then return unknown('完整武器与角色卡片集合') end
    local function value(id,source) return count(source or counts,id)*Cards.get(id).value end
    local speed=1+value('jokerFastHands')+value('jokerBracing')+value('jokerUpgradeReloadSpeed')
    local healthy=value('jokerHealthyBoi',i.heroCounts)
    if healthy>0 then
        if i.health==nil or i.maxHealth==nil then return unknown('当前生命与生命上限') end
        if i.health==i.maxHealth then speed=speed+.2*healthy end
    end
    local soul=value('jokerSoulEater',i.heroCounts)
    if soul>0 then
        if i.soulEaterActive==nil then return unknown('灵魂吞噬当前状态') end
        if i.soulEaterActive then speed=speed+soul end
    end
    local rampage=value('jokerRampage')
    if rampage>0 then
        if i.rampageStack==nil then return unknown('狂暴击杀已保存加成') end
        speed=speed+clamp(rampage*i.rampageStack,0,1)
    end
    local mastery=value('jokerReloadMastery')
    if mastery>0 then
        if i.magazineAmmo==nil then return unknown('该武器当前弹匣') end
        if i.magazineAmmo==0 then speed=speed+mastery end
    end
    return metric('组合换弹速率',speed,'multiplier')
end
local function register(id, scope, stacking, source, evaluate, cap, status, note)
    rules[id:lower()]={scope=scope,stacking=stacking,source=source,evaluate=evaluate,
        cap=cap,status=status or 'verified',note=note}
end
local item='BP_Item.'
local impact='FL_Items.F_ApplyImpactDamages'
local component='AC_PlayerStateJoker.ExecuteUbergraph_AC_PlayerStateJoker'
local function linear(id,key,label,unit,source,scope,scale)
    register(id,scope or 'item','同卡数值相加',source,function(n,i,c)
        return {[key]=metric(label,n*(scale or c.value),unit)}
    end)
end

linear('jokerCrackShot','damageBonus','本卡伤害加成','percent',impact..' @643–2399')
linear('jokerUpgradeFireRate','attackSpeedBonus','攻击速度加成','percent',item..'F_GetAttackSpeed @4101–4463')
register('jokerMachineGun','item','按累计伤害的完整 50 点档位相加',item..'F_GetAttackSpeed @717–1171',function(n,i,c)
    local v = i.itemDamage and math.floor(math.max(0,i.itemDamage)/50)*n*c.value
    return {attackSpeedBonus=metric('本武器本任务攻击速度加成',n==0 and 0 or v,'percent',nil,nil,'本武器累计伤害'),
        per50DamageBonus=metric('每累计 50 点伤害的攻速加成',n*c.value,'percent')}
end)
register('jokerAllMighty','item','仅检测是否持有；额外份数不增强',impact..' @11900–12423',function(n,i)
    local bonus
    if n==0 then bonus=0 elseif i.shield~=nil then bonus=i.shield>=1 and clamp(i.shield/100,0,.8) or 0 end
    return {damageBonus=metric('本卡伤害加成',bonus,'percent','至少 1 点护盾',nil,'当前护盾值')}
end,'本卡伤害最多 +80%')
register('jokerLuckyStrike','item','同卡概率相加；每次命中只进行一次判定',impact..' @1640–1932',function(n,i,c)
    return {doubleDamageChance=metric('双倍伤害概率',clamp(n*c.value,0,1),'chance')}
end,'触发概率最多 100%')
register('jokerAvalanche','item','同卡数值相加；与其他伤害卡相乘',impact..' @12912–13222',function(n,i,c)
    return {damageBonus=conditional('本卡伤害加成',n*c.value,'percent',hasShield(i),'护盾 > 0','当前护盾值')}
end)
register('jokerCheapSkate','hero','金币先限制到 300，再每 15 枚提供每份 +1 生命',component..' @9122–9704',function(n,i)
    local v=i.gold and math.floor(clamp(i.gold,0,300)/15)*n
    return {flatHealth=metric('本卡生命上限加值',n==0 and 0 or v,'points',nil,nil,'任务金币')}
end,'每份最多 +20 生命；总加值随份数增长')
register('jokerRampage','item','击杀时存入增益；已有栈不随拿卡重算',component..' @14495–14734; F_JokerRampageRecalculateBonus @280–390; '..item..'F_GetReloadSpeed @630–895',function(n,i)
    return {reloadSpeedBonus=metric('当前狂暴换弹速度加成',n==0 and 0 or (i.rampageStack and clamp(n*clamp(i.rampageStack,0,1),0,1)),
            'percent','尚未过期的击杀增益',nil,'已存储 jokerRampageTotalStack'),
        perKillBonus=metric('下一次击杀存入的增益',n*.05,'percent'),
        duration=metric('每次击杀增益有效时长',n>0 and 10 or nil,'seconds')}
end,'存储栈最多 +100%；换弹消费时再次乘份数并限制到 +100%')
register('jokerBloodLust','item','击杀时存入增益；已有栈不随拿卡重算',component..' @16402–16523; F_JokerBloodLustRecalculateBonus @280–390; '..item..'F_GetAttackSpeed @3368–3547',function(n,i)
    return {attackSpeedBonus=metric('当前嗜血近战攻速加成',i.bloodLustStack and clamp(i.bloodLustStack,0,.5) or (n==0 and 0 or nil),
            'percent','近战武器；尚未过期的击杀增益',nil,'已存储 jokerBloodLustTotalStack'),
        perKillBonus=metric('下一次击杀存入的增益',n*.05,'percent'),
        duration=metric('每次击杀增益有效时长',n>0 and 5 or nil,'seconds')}
end,'当前嗜血攻速加成最多 +50%')
register('jokerSecondWind','hero','恢复量固定；冷却按递减曲线',component..' @7785–8276; F_JokerSecondWindHeal',function(n)
    return {heal=metric('致命伤触发的原始治疗量',n>0 and 50 or 0,'points','冷却可用时'),
        cooldown=metric('触发冷却',n>0 and Effects.curve('C_Joker_SecondWInd',n) or nil,'seconds')}
end,'曲线 6 份后冷却为 30 秒')
register('jokerQuickDraw','item','切换速率加成相加；时间除以速率',item..'F_GetWeaponSwapSpeed @0–475',function(n,i,c)
    return {swapSpeedBonus=metric('本卡切换速度加成',n*c.value,'percent'),
        swapDelayMultiplier=metric('只计本卡的切换耗时倍率',1/(1+n*c.value),'multiplier')}
end)

for _,id in ipairs({'jokerUpgradeFirerateB','jokerUpgradeFirerateC','jokerPewPewPew'}) do
    linear(id,'attackSpeedBonus','攻击速度加成','percent',item..'F_GetAttackSpeed @3575–4463')
end
for _,id in ipairs({'jokerFastHands','jokerUpgradeReloadSpeed'}) do
    linear(id,'reloadSpeedBonus','换弹速度加成','percent',item..'F_GetReloadSpeed @1169–1611')
end
linear('jokerUpgradeDamage','damageBonus','本卡伤害加成','percent',impact..' @1734–1987')
linear('jokerHeadBang','weakpointDamageBonus','弱点命中伤害加成','percent',impact..' @1390–1530')
linear('jokerSharpShooter','weakpointDamageBonus','弱点命中伤害加成','percent',impact..' @10231–10437')
linear('jokerWellFed','flatHealth','本卡生命上限加值','points','BP_PlayerState.F_RecomputeHeal @2670–2816','hero')
linear('jokerUpgradeHeal','flatHealth','本卡生命上限加值','points','BP_PlayerState.F_RecomputeHeal @2116–2252','hero')
linear('jokerUpgradeWeaponMeleeRange','meleeRangeBonus','近战判定距离加成','percent',item..'F_GetMeleeWeaponAttackTraceRadius')
linear('jokerUpgradeAccuracy','spreadReduction','散布角度减少比例','percent',item..'F_GetWeaponSpreadAngle @328–653')
linear('jokerUpgradeLifesteal','lifesteal','命中原始治疗／伤害比','percent','FL_Items.F_TriggerImpactJokers @11358–11602')
linear('jokerExtraJump','extraJumps','额外跳跃次数','number','BP_Player.F_UpdateJumpCount','hero')
linear('jokerHop','jumpVelocityBonus','本卡跳跃初速度加成','percent','BP_Player.F_GetJumpHeight','hero')
linear('jokerUpgradeJumpHeight','jumpVelocityBonus','本卡跳跃初速度加成','percent','BP_Player.F_GetJumpHeight','hero')
register('jokerLightWeight','hero','可叠加；每张重力系数减 0.05，与其他重力项相加','BP_Player.F_UpdateGravity @146–1342',function(n)
    return {gravityScaleDelta=metric('本卡重力系数加值',-.05*n)}
end,'最终重力系数 0.25–2；仅此卡、无临时增益时 20 张到达下限，20 不是持有上限')
register('jokerLowGravity','hero','可叠加；每张重力系数减 0.25，与其他重力项相加','BP_Player.F_UpdateGravity @146–1342',function(n)
    return {gravityScaleDelta=metric('本卡重力系数加值',-.25*n)}
end,'最终重力系数 0.25–2；仅此卡、无临时增益时 4 张到达下限，4 不是持有上限')
register('jokerDwarf','hero','重力项可叠加；每张重力系数减 0.2','BP_Player.F_UpdateGravity @756–1342',function(n)
    return {gravityScaleDelta=metric('本卡重力系数加值',-.2*n)}
end,'最终重力系数 0.25–2','partial','已核对重力组合；体型、移动及攻击速度规则待核实。')
linear('jokerSpeedyGunzales','moveSpeedDelta','步行速度加值（基础为 550）','number','BP_Player.F_UpdateSpeed @1486–1666','hero')
linear('jokerUpgradeHeroSpeed','moveSpeedDelta','步行速度加值（基础为 550）','number','BP_Player.F_UpdateSpeed @695–785','hero',22)
linear('jokerDisgrace','moveSpeedDelta','步行速度加值（基础为 550）','number','BP_Player.F_UpdateSpeed @372–508','hero',165)
register('jokerBracing','item','同卡与其他攻速／换弹速率加值相加',item..'F_GetAttackSpeed @3879–4463; F_GetReloadSpeed @1301–1611',function(n,i,c)
    return {attackSpeedBonus=metric('攻击速度加成',n*c.value,'percent'),reloadSpeedBonus=metric('换弹速度加成',n*c.value,'percent')}
end)
register('jokerWeakLink','item','同卡分别累加弱点增益和普通命中减益',impact..' @9726–10203',function(n)
    return {weakpointDamageBonus=metric('弱点命中伤害加成',n*.35,'percent'),
        normalDamageMultiplier=metric('普通命中伤害倍率',clamp(1-n*.2,.1,999),'multiplier')}
end,'普通命中伤害倍率最低 ×0.1；弱点分支未见单卡上限')
for _,entry in ipairs({{'jokerHeavyWeapon','item',.1,.3},{'jokerChonky','hero',.2,.15}}) do
    local id,scope,dmg,gravity=table.unpack(entry)
    register(id,scope,'同卡加值相加；不同伤害卡相乘',impact..' @15243–16257; BP_Player.F_UpdateGravity',function(n)
        return {damageBonus=metric('本卡伤害加成',n*dmg,'percent'),
            gravityScaleDelta=metric('重力系数加值（基础为 1.25）',n*gravity,'number','持用该武器时')}
    end,'重力组合最终限制在 0.25–2；伤害分支未见单卡上限')
end
register('jokerConsumer','item','伤害加值相加；换弹副作用为开关',impact..' @15791–15987; BP_Item.F_ReloadAmmos @5–408, @893–1770',function(n,i,c)
    return {damageBonus=metric('本卡伤害加成',n*c.value,'percent'),
        discardMagazineOnReload=metric('换弹舍弃弹匣余弹',n>0,'boolean')}
end,nil,'verified','对适用武器，换弹计算将弹匣余弹按 0 处理；额外份数不重复舍弃。')
register('jokerThickSkin','hero','承伤与受影响治疗分别使用递减曲线','BP_PlayerState.F_GetDamageReduction @420–675; ExecuteUbergraph_BP_PlayerState @27788–27999',function(n)
    return {damageReceivedMultiplier=metric('本卡承伤倍率',Effects.curve('C_Joker_ThickSkin',n),'multiplier'),
        healingMultiplier=metric('受本卡影响的治疗倍率',Effects.curve('C_Joker_ThickSkin_Heal',n),'multiplier')}
end,'4 份后承伤 ×0.45、受影响治疗 ×0.25；减伤组合最低 ×0.1')
register('jokerGreatWall','hero','承伤倍率按递减曲线，与其他减伤卡相乘','BP_PlayerState.F_GetDamageReduction @707–987',function(n,i)
    local active
    if i.shield~=nil then active=i.shield>=1 end
    if n==0 then active=false end
    return {damageReceivedMultiplier=conditional('本卡承伤倍率',Effects.curve('C_Joker_GreatWall_Damage',n),'multiplier',
        active,'护盾至少 1 点','当前护盾值',1)}
end,'5 份后本卡承伤 ×0.65；减伤组合最低 ×0.1')
register('jokerLastStand','hero','承伤与吸血分别使用递减曲线','BP_PlayerState.F_GetDamageReduction @42–346; FL_Items.F_TriggerImpactJokers @11768–12108; '..component..' @17579–17840',function(n,i)
    local ratio=health(i); local active
    if ratio~=nil then active=ratio<=.3 end
    if n==0 then active=false end
    return {damageReceivedMultiplier=conditional('本卡承伤倍率',Effects.curve('C_Joker_LastStand_Damage',n),'multiplier',active,'生命比例 ≤ 30%','当前生命比例',1),
        meleeLifesteal=conditional('近战原始吸血／伤害比',Effects.curve('C_Joker_LastStand_LifeSteal',n),'percent',active,'生命比例 ≤ 30%，近战命中','当前生命比例')}
end,'4 份后本卡承伤 ×0.35、吸血 30%；吸血分支不能把生命补到 30% 以上')
register('jokerDeathsDance','hero','护盾自然衰减速率减去曲线值','AC_PlayerState_Shield.F_CalculateShieldDecreaseSpeed',function(n)
    return {shieldDecayPerSecond=metric('护盾自然衰减／秒',8-Effects.curve('C_Joker_DeathsDance',n),'points')}
end,'4 份后自然衰减为 3.5 点／秒')
linear('jokerDoubleDown','shieldGainBonus','本次护盾增加量的额外比例','percent','AC_PlayerState_Shield.ExecuteUbergraph_AC_PlayerState_Shield @3078–3270','hero',.3)
register('jokerUpgradeShieldPoints','hero','每份在 100 基础上增加 10','BP_Player.F_InitMaxShieldPoints @81–263',function(n,i,c)
    return {maxShield=metric('初始护盾上限',100+100*n*c.value,'points')}
end,nil,'partial','已核对初始化公式；任务中直接调整上限的路径仍以实际读取值为准。')
register('jokerExtraDash','hero','额外次数相加','BP_Player.F_ResetAndUpdateDash',function(n,i,c)
    return {dashCount=metric('可用冲刺次数上限',1+math.floor(n*c.value),'number')}
end)
register('jokerCarePackage','hero','额外容量相加','BP_PlayerState.ExecuteUbergraph_BP_PlayerState @1547–1629; '..component..' @5588–5757',function(n,i,c)
    return {utilityCapacity=metric('辅助道具容量',1+math.floor(n*c.value),'number')}
end)
register('jokerHitMe','hero','可叠加：每张原始恢复 +0.75 点／秒；持续时间固定',
    component..' @6584–7317, @10502–10653; BP_PlayerState.F_HealSelf_Server @27392–29166',function(n,i,c)
    -- The timer reads a persistent-frame result, not the current inventory count.
    local raw,effective
    if i.hitMeActive==false then raw=0
    elseif i.hitMeActive==true and i.hitMeCachedValue~=nil then raw=.75*i.hitMeCachedValue end
    if raw==0 or i.healingTargetIsGhost==true then effective=0
    elseif raw~=nil and i.healingTargetIsGhost==false and i.droughtActive~=nil
        and i.healingThickSkinCount~=nil and i.health~=nil and i.maxHealth~=nil then
        local adjusted=raw*(i.droughtActive and .75 or 1)
        if i.healingThickSkinCount>0 then adjusted=adjusted*Effects.curve('C_Joker_ThickSkin_Heal',i.healingThickSkinCount) end
        effective=math.max(0,clamp(i.health+adjusted,0,i.maxHealth)-i.health)
    end
    return {currentHealPerSecond=metric('当前原始恢复／秒',raw,'points',nil,nil,'治疗计时状态与实际缓存'),
        nextTriggerHealPerSecond=metric('下次触发原始恢复／秒',.75*n*c.value,'points'),
        triggerDuration=metric('下次触发持续时间',n>0 and 20 or nil,'seconds'),
        effectiveHealNextTick=metric('下一跳有效生命恢复',effective,'points','按当前缺血量与治疗修正',nil,'当前治疗修正、Pawn 状态与生命读数')}
end,'生命恢复不超过当前生命上限；重触发刷新 20 秒，不累加时长','verified',
    '当前速率读取计时器使用的缓存；获得新卡不直接重算，下次有效生命检查才刷新缓存。纯护盾吸收通常不触发。干旱和皮糙肉厚影响实际治疗；溢出转护盾不计生命恢复。')
register('jokerFightOrFlight','hero','可叠加：下次受伤每张 +20% 近战攻速、持续 3 秒',
    component..' @17041–17543, @3217; BP_Item.F_GetAttackSpeed @2923–3367',function(n,i,c)
    local current
    if n==0 then current=0 elseif i.fightOrFlightValue~=nil then current=math.max(0,i.fightOrFlightValue) end
    return {attackSpeedBonus=metric('当前近战攻速加成',current,'percent','可受攻速影响的近战，非法术',nil,'jokerFightOrFlightValue'),
        nextTriggerAttackSpeedBonus=metric('下次受伤近战攻速加成',.2*n*c.value,'percent'),
        triggerDuration=metric('下次受伤持续时间',n>0 and 3*n*c.value or nil,'seconds')}
end,nil,'verified','当前加成直接使用受击时保存值，不再乘当前张数；重复触发覆盖加值并刷新 3×张数秒，结束后清零。常规任务纯护盾吸收在反馈前返回；大厅反馈路径不要求实际扣血。')
register('jokerRage','hero','冷却时间按递减曲线',component..' @6018–6256; @7318–7551',function(n)
    return {cooldown=metric('触发冷却',n>0 and Effects.curve('C_Joker_Rage',n) or nil,'seconds','生命比例 < 25%')}
end,'5 份后冷却为 10 秒')
register('jokerFreezeOver','hero','护盾总量按曲线；固定 60 秒冷却',component..' @3345–3568; @4793–4847; @7318–7656',function(n)
    return {shield=metric('一次触发分 10 次提供的原始护盾合计',Effects.curve('C_Joker_FreezeOver',n),'points','生命比例 < 25%'),
        cooldown=metric('触发冷却',n>0 and 60 or nil,'seconds')}
end,'6 份后每次触发原始护盾合计 200；仍受实际护盾容量限制')
register('jokerToolBox','hero','补充间隔等于 90 秒乘份数',component..' @5072–5175; @5478–5568',function(n,i,c)
    return {refillInterval=metric('辅助道具自动补充间隔',n>0 and n*c.value or nil,'seconds')}
end,nil,'verified','本版本蓝图中额外份数会延长间隔。')
register('jokerSlowAndSteady','item','攻速损失、散布减少分别使用曲线',item..'F_GetAttackSpeed @1835–2087; F_GetWeaponSpreadAngle @94–653',function(n)
    return {attackSpeedBonus=metric('攻击速度加值',n>0 and -Effects.curve('C_Joker_SlowAndSteady_FireRate',n) or 0,'percent'),
        spreadReduction=metric('散布角度减少比例',n>0 and Effects.curve('C_Joker_SlowAndSteady_Accuracy',n) or 0,'percent')}
end,'4 份后攻速 -30%、散布角度 -70%；总散布角度限制在 0–20 度')
register('jokerLunge','item','近战距离和判定范围使用同一曲线',item..'F_GetMeleeWeaponAttackTraceRadius',function(n,i)
    local v
    if i.runtimeCurves then
        v=(i.runtimeCurves.C_Joker_Lunge or {})[n]
    else
        v=Effects.curve('C_Joker_Lunge',n)
    end
    return {meleeRangeBonus=metric('近战判定距离加成',v,'percent',nil,nil,'C_Joker_Lunge'),
        meleeAngleBonus=metric('近战判定范围加成',v,'percent',nil,nil,'C_Joker_Lunge')}
end,'4 份后本卡两项均为 +55%')
register('jokerCoinFlip','hero','正反两面伤害倍率分别使用曲线',impact..' @11442–11872',function(n)
    return {headsDamageMultiplier=metric('硬币正面时伤害倍率',Effects.curve('C_Joker_Coinflip_Bonus',n),'multiplier'),
        tailsDamageMultiplier=metric('硬币反面时伤害倍率',Effects.curve('C_Joker_Coinflip_Malus',n),'multiplier')}
end,'3 份后正面 ×2.9、反面 ×0.1', 'partial','已核对伤害倍率；抛掷时点与当前硬币结果由游戏状态决定。')
register('jokerFanningAce','item','仅检测是否持有；额外份数不增强',
    'BP_Item_Pistol.F_CanTriggerJokerFanningAce @0–105; ExecuteUbergraph @1236–1828, @3246–3344, @10535–10626',function(n,i)
    local window
    if n>0 and i.reloadSpeed and i.reloadSpeed>0 then window=.4/i.reloadSpeed end
    return {enabled=metric('扇击能力',n>0,'boolean'),
        burstInterval=metric('连射循环间隔',n>0 and .1 or nil,'seconds'),
        triggerWindow=metric('触发标志持续时间',window,'seconds','换弹动画通知后',nil,
            n>0 and window==nil and '当前手枪换弹速率' or nil)}
end,'1 张启用；额外份数不缩短 0.1 秒连射间隔，也不扩大窗口','verified',
    '准确触发还受换弹状态、输入和 DoOnce 门控；0.4/换弹速率是通知标志持续时间，不是从换弹开始计时。每轮允许蹲守免耗，连射总发数不固定。')
register('jokerCamper','item','可叠加：同卡免耗权重相加；每次允许的消费调用独立判定',
    item..'F_ApplyCamperJoker @0–625; F_ConsumeAmmos @214–251',function(n,i,c)
    local active
    if n==0 or i.groundQueryPassed==false or i.runningQueryResult==true or i.consumeAllowsCamper==false
        or (i.horizontalSpeed~=nil and i.horizontalSpeed>16) then active=false
    elseif i.groundQueryPassed==true and i.runningQueryResult==false and i.consumeAllowsCamper==true
        and i.horizontalSpeed~=nil then active=true end
    return {freeAmmoChance=conditional('当前射击免耗概率',clamp(n*c.value,0,1),'chance',active,
        '着地、非奔跑、水平速度≤16，且消费调用允许蹲守','准确的地面／跑步查询、水平速度及消费调用开关')}
end,'有效免耗概率最多 100%；2 张达到概率上限，不是持有上限','verified',
    '着地使用 F_IsOnGround(1) 球形查询，奔跑使用 F_IsRunning；不能用相似状态或最近一次 lastShotConsumedAmmo 代替。')
register('jokerFastDraw','item','可叠加：同卡伤害加值相加；首发未消耗时乘入伤害',
    impact..' @10465–10807; AC_PlayerStateJoker.F_StoreInfoOnWeaponSpawn, F_ResetValueAfterDamages',function(n,i,c)
    local active=i.firstShotLoaded
    if n==0 then active=false end
    return {damageMultiplier=conditional('本卡当前伤害倍率',1+n*c.value,'multiplier',active,
        'firstShotLoaded 尚未消耗','当前 firstShotLoaded',1)}
end,nil,'verified','候选卡不自动刷新首发状态。已核对普通弹丸落空和护盾早退也会清除首发；多弹丸清除由原攻击末段标志控制。本倍率仅指此卡所在伤害阶段。')
register('jokerClutch','item','可叠加：每张将触发弹匣阈值提高 2',
    'FL_Items.F_TriggerImpactJokers @1929–2556',function(n,i,c)
    local threshold=n>0 and math.floor(n*c.value*2-1) or nil
    local within
    if n==0 then within=false elseif i.heldMagazineAmmo~=nil then within=i.heldMagazineAmmo<=threshold end
    return {magazineThreshold=metric('爆炸触发时弹匣剩余弹药≤',threshold,'number'),
        magazineWithinThreshold=metric('当前持用弹匣符合阈值',within,'condition',nil,nil,
            n>0 and within==nil and '当前实际持用物品的弹匣弹药' or nil)}
end,nil,'verified','impact 时读取当前持用物品弹匣。已核对普通手枪、长程步枪及扇击先扣弹；免耗、补弹、穿透和换枪会影响触发次数，不显示固定未来爆炸发数。爆炸表的原始 15 伤害不是最终伤害。')
register('jokerRicochet','item','可叠加：增加初始弹射次数；每段寻敌概率固定',
    item..'F_GetRicochetsAmount; BP_PlayerBullet.F_Ricochet @0–366, F_GetNearestEnemyAtImpactPoint @0–392',function(n,i,c)
    return {ricochets=metric('新发射子弹最多弹射次数',math.floor(n*c.value),'number'),
        homingAttemptChance=metric('每段寻敌尝试概率',n>0 and .3 or 0,'chance','仍有弹射次数且当前持用武器持卡'),
        homingSearchRadius=metric('寻敌最大距离',n>0 and 1024 or nil,'number','世界单位；需通过遮挡检查')}
end,'寻敌尝试概率固定 30%；弹射次数未见单卡上限','verified',
    '每段延迟 0.075 秒后检查当前持用武器；寻敌排除本次碰撞目标，距离不超过 1024。寻敌失败或受阻时退回普通反弹，30% 不是实际命中率；候选不重写已发射弹丸的剩余次数。')
linear('jokerScrubBullet','elementRemovalDamage','一次元素清除的原始伤害','points','FL_Items.F_TriggerImpactJokers @14103–14149','item',10)
register('jokerVampire','item','同卡吸血比相加；过量伤害不增加本卡吸血',impact..' @16285–17933',function(n,i,c)
    return {lifesteal=metric('原始治疗／有效目标剩余生命内伤害比',n*c.value,'percent')}
end,nil,'verified','治疗计算使用 min(本次计算伤害, 目标当前生命)；最终治疗仍受生命上限和治疗修正影响。')
local impactChances={jokerPigshot=4385,jokerExplosiveRounds=2557,jokerExplosiveRoundsAcid=3014,
    jokerExplosiveRoundsElec=3471,jokerExplosiveRoundsFrost=3928,jokerPartyShot=4992,
    jokerBellShot=5543,jokerChickshot=6446,jokerPickPick=6908,jokerHeadshotRefund=11064,jokerMindShot=1462}
for id,offset in pairs(impactChances) do
    register(id,'item','同卡权重相加，再乘武器传入的 LuckMultiplier；一次判定',
        'FL_Items.F_TriggerImpactJokers @'..offset,function(n,i,c)
        local weight=n*c.value
        return {baseChance=metric('LuckMultiplier = 1 时的单次概率',clamp(weight,0,1),'chance'),
            effectiveChance=metric('当前武器单次有效概率',n==0 and 0 or (i.luckMultiplier and clamp(weight*i.luckMultiplier,0,1)),
                'chance','满足原文的命中／弱点条件',nil,'当前攻击的 LuckMultiplier')}
    end,'有效概率最多 100%')
end
register('jokerRelentless','hero','同卡加值相加；与其他伤害卡相乘',impact..' @14877–15215',function(n,i,c)
    local h=health(i); local active; if h~=nil then active=h<=.301 end
    return {damageBonus=conditional('本卡伤害加成',n*c.value,'percent',active,'生命比例 ≤ 30.1%（蓝图阈值）','当前生命比例')}
end)
register('jokerLastDance','hero','低生命时每份直接加 200 步行速度','BP_Player.F_UpdateSpeed @1158–1805',function(n,i)
    local h=health(i); local active; if h~=nil then active=h<=.301 end
    return {moveSpeedDelta=conditional('本卡步行速度加值（基础为 550）',n*200,'number',active,'生命比例 ≤ 30.1%（蓝图阈值）','当前生命比例')}
end,nil,'verified','本版本蓝图的每份实际加值为 200，约为基础步行速度的 36.36%。原始描述仍保留。')
register('jokerFistRage','item','攻击速度只检测是否持有',item..'F_GetAttackSpeed @2653–2895',function(n,i)
    return {attackSpeedBonus=conditional('当前狂怒之拳攻速加成',n>0 and .3 or 0,'percent',i.fistRageActive,'狂怒之拳激活中','jokerFistRageActive')}
end,'攻击速度最多 +30%，额外份数不增强该项','partial','已核对攻击速度；蓄力和持续时间的武器专属分支待核对。')
register('jokerPanicAttack','item','伤害加值与下一次触发时长均乘份数',impact..' @783–969; '..component..' @14126–14338',function(n,i)
    return {damageBonus=conditional('当前恐慌攻击伤害加成',n*.2,'percent',i.panicActive,'恐慌攻击激活中','jokerPanicAttackEnabled'),
        triggerDuration=metric('下一次触发持续时间',n>0 and n*3 or nil,'seconds')}
end,nil,'verified','重复触发会刷新延时；选卡不会追溯更改已开始的计时。')
register('jokerSoulEater','hero','同卡加值相加；触发后刷新固定 5 秒',impact..' @1068–1272; '..item..'F_GetReloadSpeed @424–602; '..component..' @12203–12294',function(n,i,c)
    return {damageBonus=conditional('当前噬魂者伤害加成',n*c.value,'percent',i.soulEaterActive,'噬魂者激活中','isJokerSoulEaterActive'),
        reloadSpeedBonus=conditional('当前噬魂者换弹速度加成',n*c.value,'percent',i.soulEaterActive,'噬魂者激活中','isJokerSoulEaterActive'),
        triggerDuration=metric('触发持续时间',n>0 and 5 or nil,'seconds')}
end)
register('jokerRiposte','item','护盾事件发生时按曲线存入下一击倍率',component..' @16785–16967; '..impact..' @12451–12781',function(n,i)
    local actual
    if n==0 then actual=1 elseif i.riposteValue~=nil then actual=math.max(1,i.riposteValue) end
    return {damageMultiplier=metric('当前已存储的下一击伤害倍率',actual,'multiplier',nil,nil,'jokerRiposteValue'),
        nextTriggerDamageMultiplier=metric('下次护盾触发时存入的伤害倍率',n>0 and 1+Effects.curve('C_Joker_Riposte',n) or 1,'multiplier')}
end,'4 份后下次护盾触发的倍率为 ×3.5')
register('jokerBerserker','item','生命损失比例乘份数曲线',impact..' @19004–19433',function(n,i)
    local h=health(i); local max=n>0 and Effects.curve('C_Joker_Berserker',n) or 0
    return {meleeDamageBonus=metric('当前本卡近战伤害加成',n==0 and 0 or (h and (1-clamp(h,0,1))*max),'percent',nil,nil,'当前生命比例'),
        maxMeleeDamageBonus=metric('生命降至零时的理论加成',max,'percent')}
end,'3 份后最大理论近战伤害加成为 +150%')
register('jokerSpeedster','item','有效速度先查曲线，再乘份数并限制到 +100%',impact..' @7580–9698; '..item..'F_GetAttackSpeed @69–684, @4495–5531',function(n,i)
    local bonus
    if n==0 then bonus=0 elseif i.speedsterSpeed~=nil then bonus=clamp(Effects.curve('C_Joker_Speedster',i.speedsterSpeed)*n,0,1) end
    return {damageBonus=metric('本卡伤害加成',bonus,'percent',nil,nil,'传给疾行者曲线的有效速度'),
        attackSpeedBonus=metric('本卡攻击速度加成',bonus,'percent',nil,nil,'传给疾行者曲线的有效速度')}
end,'单份曲线最多 +40%；多份消费后的最终两项最多 +100%','partial','不同攻击路径对瞄准／游泳速度补偿略有区别；仅接受已确认的 speedsterSpeed，不从显示移动速度猜测。')
register('jokerOneTrick','item','累计值乘该物品已装备的不同稀有度数量',impact..' @10808–11150; '..item..'F_GetAttackSpeed @1527–1807',function(n,i,c)
    local v=n==0 and 0 or (i.distinctRarities and n*c.value*i.distinctRarities)
    return {damageBonus=metric('本卡伤害加成',v,'percent',nil,nil,'该物品已装备的不同稀有度数'),
        attackSpeedBonus=metric('本卡攻击速度加成',v,'percent',nil,nil,'该物品已装备的不同稀有度数')}
end,nil,'verified','统计已装备栏的不同稀有度；若候选会改变该集合，调用者需提供 inputs.after.distinctRarities。')
register('jokerEagleLever','item','连击数乘同卡累计值后限制到 +50%',impact..' @13250–14559',function(n,i,c)
    local bonus=n==0 and 0 or (i.consecutiveHits and clamp(i.consecutiveHits*n*c.value,0,.5))
    return {damageBonus=metric('当前鹰眼连击伤害加成',bonus,'percent',nil,nil,'武器当前连续命中数')}
end,'伤害最多 +50%')
local healthCurves={jokerGlassCannon='C_Joker_GlassCannon',jokerLifePact='C_Joker_LifePact',jokerWestWizard='C_Joker_WestWizard',jokerGiant='C_Joker_Giant'}
for id,curve in pairs(healthCurves) do
    register(id,'hero','生命倍率加值查曲线后，与其他生命倍率加值相加','BP_PlayerState.F_RecomputeHeal @1454–2583; '..impact,function(n)
        local m={healthMultiplierDelta=metric('生命倍率加值',Effects.curve(curve,n),'percent')}
        if id=='jokerGlassCannon' then m.damageBonus=metric('本卡武器／近战伤害加成',n*.4,'percent') end
        if id=='jokerGiant' then m.damageBonus=metric('本卡武器伤害加成',n*.3,'percent'); m.sizeDelta=metric('体型系数加值',n*.5,'number') end
        return m
    end,'生命组合的倍率最低 ×0.1，最终最大生命限制为 1–999',id=='jokerGlassCannon' and 'verified' or 'partial',
        id=='jokerLifePact' and '已核对生命上限；击杀治疗分支待核对。' or
        (id~='jokerGlassCannon' and '已核对以上数值；法术冷却消费分支待核对。' or nil))
end
register('jokerGoliath','hero','生命倍率加值相加；体型只增加最多 0.3','BP_PlayerState.F_RecomputeHeal @1318–1408; BP_Player.F_UpdatePlayerScale',function(n)
    return {healthMultiplierDelta=metric('生命倍率加值',n*.25,'percent'),sizeDelta=metric('体型系数加值',clamp(n*.3,0,.3),'number')}
end,'本卡体型加值最多 0.3；生命组合最终最大生命限制为 1–999')

register('jokerHoarder','hero','概率使用递减收益公式：1 − 1 / (1 + 0.15/0.85 × 份数)','BP_Pickable_Joker.F_Hoarder @0–377',function(n)
    return {extraCardChance=metric('拾取时额外卡片概率',1-1/(1+(.15/.85)*n),'chance')}
end,'概率随份数趋近 100%，有限份数不达到 100%')
local spellSource='AC_PlayerItems.F_SpellCooldownTweak'
local spellWeights={jokerUpgradeSpellCooldownReduction=.02,jokerApprentice=.1,jokerSpellRoulette=.2,jokerWestWizard=.3,jokerGiant=.1}
local mastery={Acid='jokerCdrAcid',Fire='jokerCdrFire',Elec='jokerCdrElec',Voodoo='jokerCdrVoodoo',Cactus='jokerCdrCactus',Frost='jokerCdrFrost'}
local elementLabels={Acid='酸',Fire='火',Elec='电',Voodoo='巫毒',Cactus='仙人掌',Frost='冰',None='无元素'}
local function cooldownMultiplier(weight) return clamp(math.floor((.3^weight)*100+.5)/100,.1,1) end
function Effects.spellCooldown(counts,i)
    i=i or {}; local weight=0
    for id,w in pairs(spellWeights) do weight=weight+count(counts,id)*w end
    local short=count(counts,'jokerCantRipOneTrick')
    if short>0 then
        if i.baseSpellCooldown==nil then return metric('组合冷却倍率',nil,'multiplier',nil,nil,'法术基础冷却') end
        if i.baseSpellCooldown<=35 then weight=weight+short*.25 end
    end
    local anyMastery=false
    for _,id in pairs(mastery) do if count(counts,id)>0 then anyMastery=true end end
    if anyMastery then
        if i.spellElement==nil then return metric('组合冷却倍率',nil,'multiplier',nil,nil,'法术元素') end
        local id=mastery[i.spellElement]
        if id and count(counts,id)>0 then
            local amount=i.elementSpellCounts and i.elementSpellCounts[i.spellElement]
            if amount==nil then return metric('组合冷却倍率',nil,'multiplier',nil,nil,'相应元素已装备法术数') end
            weight=weight+amount*count(counts,id)*.1
        end
    end
    local m=metric('所核对冷却卡组合的冷却倍率',cooldownMultiplier(weight),'multiplier')
    m.weight=weight
    if i.baseSpellCooldown~=nil then m.seconds=clamp(i.baseSpellCooldown*m.value,1,9999) end
    return m
end
local spellRules={}
for id,w in pairs(spellWeights) do
    spellRules[id:lower()]=true
    local prior=rules[id:lower()]
    local priorEval=prior and prior.evaluate
    register(id,'hero','参数相加后计算 round(0.3^参数 × 100) / 100',spellSource..' @30–789',function(n,i,c)
        local m=priorEval and priorEval(n,i,c) or {}
        m.cooldownWeight=metric('本卡冷却参数（不是直接减免百分比）',w*n,'number')
        m.cooldownMultiplier=metric('只计本卡的冷却倍率',cooldownMultiplier(w*n),'multiplier')
        return m
    end,'冷却组合倍率最低 ×0.1；实际法术冷却最低 1 秒',id=='jokerSpellRoulette' and 'partial' or 'verified',
        id=='jokerSpellRoulette' and '冷却公式已核对；随机法术池和轮换细节待核对。' or
        '冷却参数在组合后统一取幂和舍入；不要把各卡舍入后的显示倍率直接相乘。')
end
for element,id in pairs(mastery) do
    spellRules[id:lower()]=true
    register(id,'hero','每个相应元素法术提供 0.1 × 份数的冷却参数',spellSource..' @1483–3188',function(n,i)
        local amount=i.elementSpellCounts and i.elementSpellCounts[element]
        local weight=n==0 and 0 or (amount and amount*n*.1)
        return {equippedSameElementSpells=metric('已装备'..elementLabels[element]..'系法术数',amount,'number',nil,nil,'已装备法术元素'),
            cooldownWeight=metric('本卡对'..elementLabels[element]..'系法术的冷却参数',weight,'number',nil,nil,'该元素已装备法术数'),
            cooldownMultiplier=metric('只计本卡的相应元素冷却倍率',weight and cooldownMultiplier(weight),'multiplier',nil,nil,'该元素已装备法术数')}
    end,'所有冷却参数合计后，倍率最低 ×0.1')
end
spellRules.jokercantriponetrick=true
register('jokerCantRipOneTrick','hero','符合基础冷却条件时提供每份 0.25 冷却参数',spellSource..' @1261–1455',function(n,i,c)
    local weight
    if n==0 then weight=0 elseif i.baseSpellCooldown~=nil then weight=i.baseSpellCooldown<=35 and n*c.value or 0 end
    return {cooldownWeight=metric('本卡冷却参数',weight,'number','法术基础冷却 ≤ 35 秒',nil,'法术基础冷却'),
        cooldownMultiplier=metric('只计本卡的冷却倍率',weight and cooldownMultiplier(weight),'multiplier',nil,nil,'法术基础冷却')}
end,'所有冷却参数合计后，倍率最低 ×0.1')
register('jokerCastAway','hero','每份 3 秒，单次缩短量最多 10 秒','AC_PlayerItems.F_TriggerJokerOnSpellCast @144–299, @821–1989',function(n,i,c)
    local reduction=n>0 and clamp(n*c.value,3,10) or 0
    local remains=i.otherSpellRemaining
    local result=remains and math.min(remains,math.max(remains-reduction,4))
    return {secondsReduced=metric('一次施放对其他法术的缩短量',reduction,'seconds'),
        remainingAfterCast=metric('另一法术在施放后的剩余冷却',result,'seconds',nil,nil,'另一法术当前剩余冷却')}
end,'单次最多缩短 10 秒；原剩余 ≥ 4 秒时不降到 4 秒以下，较短冷却不被抬高')
register('jokerBattleMage','hero','每次击杀将当前剩余冷却乘曲线倍率','BP_PlayerState.F_TriggerOnKillTweaks @2310–2944',function(n,i)
    local mult=n>0 and Effects.curve('C_Joker_BattleMage',n) or 1
    return {remainingMultiplier=metric('每次击杀后的剩余冷却倍率',mult,'multiplier'),
        remainingAfterKill=metric('击杀后的剩余冷却',i.spellRemaining and i.spellRemaining*mult,'seconds',nil,nil,'法术当前剩余冷却')}
end,'5 份后每次击杀乘 ×0.975')
for _,id in ipairs({'jokerShroomGrave','jokerGoldTooth','jokerAmmoSupply','jokerCactusDay','jokerAntiGravityFalls','jokerPreciousRush'}) do
    register(id,'item','同卡概率相加；每次符合条件的击杀一次判定','BP_PlayerState.F_TriggerOnKillTweaks',function(n,i,c)
        local unit=id=='jokerPreciousRush' and .1 or c.value
        return {killChance=metric('每次符合条件击杀的触发概率',clamp(n*unit,0,1),'chance')}
    end,'有效概率最多 100%')
end
do
    local prior=rules.jokerlifepact.evaluate
    register('jokerLifePact','hero','生命倍率查曲线；每份提供 2 点击杀治疗','BP_PlayerState.F_RecomputeHeal; F_TriggerOnKillTweaks @2099–2283',function(n,i,c)
        local m=prior(n,i,c); m.healPerKill=metric('每次击杀的原始治疗量',n*2,'points'); return m
    end,'生命组合倍率最低 ×0.1；击杀治疗仍受生命上限与治疗修正影响')
end
linear('jokerEatAPunch','healPerMeleeKill','每次近战击杀的原始治疗量','points','BP_PlayerState.F_TriggerOnKillTweaks @6799–6895')
linear('jokerFrostBite','shieldPerFrozenMeleeKill','每次近战击杀冰封目标的原始护盾','points','BP_PlayerState.F_TriggerOnKillTweaks @7094–7283')
linear('jokerSnackAPunch','shieldPerMeleeKill','每次近战击杀的原始护盾','points','BP_PlayerState.F_TriggerOnKillTweaks @7820–7916')
linear('jokerFreeCocktail','healPerEmptyReload','空弹匣换弹的原始治疗量','points',item..'F_ReloadAmmos @1853–2060')
for _,id in ipairs({'jokerRunAndGun','jokerRunAndReload'}) do
    local curve=id=='jokerRunAndGun' and 'C_Joker_RunAndGun' or 'C_Joker_RunAndReload'
    register(id,'item','触发时按份数曲线提供速度加值',item..'ExecuteUbergraph_BP_Item @4520–4670, @9367–9544',function(n)
        return {activeMoveSpeedDelta=metric('触发有效期间的步行速度加值',Effects.curve(curve,n),'number')}
    end,id=='jokerRunAndGun' and '6 份后加值为 850' or '8 份后加值为 1710')
end
register('jokerMagicFriendship','hero','每 2 秒提供与份数相同的原始治疗',component..' @1916–1939, @12349–12649',function(n)
    return {healPerTick=metric('附近人数含自己至少 2 人时，每次原始治疗',n,'points','检查半径 2048'),
        tickInterval=metric('治疗检查间隔',n>0 and 2 or nil,'seconds')}
end)
register('jokerLazy','hero','比例查曲线；补充量四舍五入且至少 1 发',component..' @2255, @10654–11592; F_JokerLazy_CalculateAmmoGive',function(n,i)
    local fraction=n>0 and Effects.curve('C_Joker_Lazy',n) or 0
    local quota,actual
    if n==0 then quota=0; actual=0
    elseif i.ammoMaximum~=nil then
        quota=math.max(1,math.floor(i.ammoMaximum*fraction+.5))
        if i.ammoCurrent~=nil then actual=clamp(i.ammoCurrent+quota,0,i.ammoMaximum)-i.ammoCurrent end
    end
    return {refillFraction=metric('每次补充比例',fraction,'chance'),ammoPerTick=metric('每次计划补充弹药',quota,'number',nil,nil,'相应弹药容量'),
        actualAmmoRestored=metric('按当前缺额实际可补充弹药',actual,'number',nil,nil,'当前弹药与容量'),
        interval=metric('补充间隔',n>0 and 12 or nil,'seconds')}
end,'3 份后补充比例为 30%；补充后不得超过容量','partial','警长徽章使用弹匣容量；普通武器使用弹药袋容量；弓和回旋镖分支不由此通用预览替代。')
register('jokerTweakDealer','hero','卡片计数乘本卡份数','BP_PlayerState.F_RecomputeHeal @105–1290',function(n,i)
    return {flatHealth=metric('本卡生命上限加值',n==0 and 0 or (i.activeCardCount and i.activeCardCount*n),'points',nil,nil,'主副武器与角色装备份数加任务卡条目数')}
end,nil,'verified','任务卡计数使用 playerLocalJokers 的条目数；永久升级不计入。候选若改变此计数，需提供 inputs.after.activeCardCount。')
for _,entry in ipairs({{'jokerBigBoots','fallDamageImmune','坠落伤害免疫','BP_Player.F_PlayerLandEffect @1709–1818'},
    {'jokerPlasticDuck','duckSound','行走橡皮鸭音效','BP_Player.F_TraceFootstep @1607–1697'}}) do
    local id,key,label,src=table.unpack(entry)
    register(id,'hero','仅检测持有，额外份数不增强',src,function(n) return {[key]=metric(label,n>0,'boolean')} end,'开关效果：持有至少 1 份即启用')
end
register('jokerHealthyBoi','hero','满血时每份攻速／换弹 +20%，步速 +110',item..'F_GetAttackSpeed @2115–2445; F_GetReloadSpeed @112–396; BP_Player.F_UpdateSpeed',function(n,i)
    local h=health(i); local full; if h~=nil then full=h==1 end
    return {attackSpeedBonus=conditional('满血攻速加成',n*.2,'percent',full,'满血','当前生命比例'),
        reloadSpeedBonus=conditional('满血换弹速率加成',n*.2,'percent',full,'满血','当前生命比例'),
        moveSpeedDelta=conditional('满血步行速度加值',n*110,'number',full,'满血','当前生命比例')}
end)
register('jokerFocusedFeet','item','瞄准时同卡加值相加',item..'F_GetAttackSpeed @2473–2625',function(n,i,c)
    return {attackSpeedBonus=conditional('瞄准攻速加成',n*c.value,'percent',i.aiming,'瞄准中','isAiming')}
end)
register('jokerReloadMastery','item','空弹匣时同卡加值相加',item..'F_GetReloadSpeed @923–1141',function(n,i,c)
    local empty; if i.magazineAmmo~=nil then empty=i.magazineAmmo==0 end
    return {reloadSpeedBonus=conditional('空弹匣换弹速率加成',n*c.value,'percent',empty,'弹匣弹药 = 0','当前弹匣弹药')}
end)
register('jokerFrenzySpin','item','连杀 > 10 时添加 2 × 份数 − 1 的攻速加值',item..'F_GetAttackSpeed @1199–1499',function(n,i,c)
    local active; if i.killCombo~=nil then active=i.killCombo>10 end
    return {attackSpeedBonus=conditional('狂暴回旋攻速加成',n>0 and n*c.value-1 or 0,'percent',active,'连杀数 > 10','enemyKillCombo')}
end)

function Effects.maxHealth(counts, inputs)
    inputs=inputs or {}
    local flat=100+5*count(counts,'jokerUpgradeHeal')+7*count(counts,'jokerWellFed')
    local dealer,cheap=count(counts,'jokerTweakDealer'),count(counts,'jokerCheapSkate')
    if dealer>0 then
        if inputs.activeCardCount==nil then return metric('组合最大生命',nil,'points',nil,nil,'主副武器与角色装备份数加任务卡条目数') end
        flat=flat+inputs.activeCardCount*dealer
    end
    if cheap>0 then
        local bonus=inputs.cheapSkateBonusHealth
        if bonus==nil and inputs.gold~=nil then bonus=math.floor(clamp(inputs.gold,0,300)/15)*cheap end
        if bonus==nil then return metric('组合最大生命',nil,'points',nil,nil,'jokerCheapSkateBonusHealth 或任务金币') end
        flat=flat+bonus
    end
    local multiplier=1+.25*count(counts,'jokerGoliath')
    for id,curve in pairs(healthCurves) do multiplier=multiplier+Effects.curve(curve,count(counts,id)) end
    return metric('所核对生命卡组合的最大生命',clamp(flat*clamp(multiplier,.1,9999),1,999),'points')
end

function Effects.damageReduction(counts, inputs)
    inputs=inputs or {}
    local last,wall,thick=count(counts,'jokerLastStand'),count(counts,'jokerGreatWall'),count(counts,'jokerThickSkin')
    local ratio=health(inputs)
    if last>0 and ratio==nil then return metric('这三类卡合计承伤倍率',nil,'multiplier',nil,nil,'当前生命比例') end
    if wall>0 and inputs.shield==nil then return metric('这三类卡合计承伤倍率',nil,'multiplier',nil,nil,'当前护盾值') end
    local value=Effects.curve('C_Joker_ThickSkin',thick)
    if last>0 and ratio<=.3 then value=value*Effects.curve('C_Joker_LastStand_Damage',last) end
    if wall>0 and inputs.shield>=1 then value=value*Effects.curve('C_Joker_GreatWall_Damage',wall) end
    return metric('背水一战／坚壁长城／皮糙肉厚合计承伤倍率',clamp(value,.1,1),'multiplier')
end

local gravityCards={jokerlightweight=true,jokerlowgravity=true,jokerdwarf=true,jokerchonky=true,jokerheavyweapon=true}
function Effects.gravity(counts,inputs)
    inputs=inputs or {}
    local hero=inputs.heroCounts or counts
    local held=inputs.heldItemCounts
    if inputs.gravityContextComplete==false or inputs.buffGravity==nil or not held then
        return metric('最终重力系数',nil,'number',nil,nil,'临时重力、角色卡与当前持用武器卡')
    end
    -- F_UpdateGravity's parameter and instance field share the name buffGravity.
    -- The stored instance field already includes the parameter's incremental change.
    local v=1.25+inputs.buffGravity-.25*count(hero,'jokerLowGravity')-.05*count(hero,'jokerLightWeight')
        -.2*count(hero,'jokerDwarf')+.15*count(hero,'jokerChonky')+.3*count(held,'jokerHeavyWeapon')
    return metric('最终重力系数',clamp(v,.25,2),'number','合并角色卡、当前持用武器与临时增益')
end

local function numberText(n)
    return (string.format('%.3f',n):gsub('0+$',''):gsub('%.$',''))
end
function Effects.formatMetric(m)
    local function formatted(v)
        if m.unit=='percent' then return (v>=0 and '+' or '')..numberText(v*100)..'%' end
        if m.unit=='chance' then return numberText(v*100)..'%' end
        if m.unit=='multiplier' then return '×'..numberText(v) end
        if m.unit=='seconds' then return numberText(v)..' 秒' end
        if m.unit=='cards' then return numberText(v)..' 张' end
        if m.unit=='boolean' then return v and '启用' or '未启用' end
        if m.unit=='condition' then return v and '满足' or '不满足' end
        if m.unit=='gravityChange' then return (v>=0 and '降低 ' or '提高 ')..numberText(math.abs(v)*100)..'%' end
        return numberText(v)..(m.unit=='points' and ' 点' or '')
    end
    if m.value~=nil then return formatted(m.value) end
    if m.potential~=nil then return '条件成立时 '..formatted(m.potential)..'；当前条件未知' end
    return m.missing and ('待读取：'..m.missing) or '不适用'
end
local function refreshResult(result)
    local lines,keys={},{}
    result.complete=true
    for key in pairs(result.metrics) do keys[#keys+1]=key end
    table.sort(keys)
    for _,key in ipairs(keys) do
        local m=result.metrics[key]
        lines[#lines+1]=m.label..'：'..Effects.formatMetric(m)
        if m.value==nil and (m.missing or m.potential~=nil) then result.complete=false end
    end
    result.text=table.concat(lines,'；')
    return result
end
function Effects.evaluate(id,n,inputs)
    local card=Cards.get(id)
    if not card then return {status='unresolved',metrics={},text='未知卡片：'..tostring(id),complete=false} end
    local rule=rules[card.id:lower()]
    if not rule then return {status='unresolved',metrics={},text='此卡的下游计算规则待核实',complete=false} end
    local metrics=rule.evaluate(math.max(0,n or 0),inputs or {},card)
    return refreshResult({status=rule.status,metrics=metrics})
end
function Effects.preview(id,counts,inputs,increment)
    inputs=inputs or {}; increment=increment==nil and 1 or increment
    local card=Cards.get(id)
    if not card then
        return {status='unresolved',current=Effects.evaluate(id,0,inputs),after=Effects.evaluate(id,0,inputs),
            currentCount=0,afterCount=0,lines={'未知卡片：'..tostring(id)},scope='unknown'}
    end
    local n=count(counts,card.id)
    local currentInputs={};for k,v in pairs(inputs) do currentInputs[k]=v end
    currentInputs.itemCounts=inputs.itemCounts or counts
    if card.scope=='hero' then currentInputs.heroCounts=inputs.heroCounts or counts end
    inputs=currentInputs
    local afterInputs={}; for k,v in pairs(inputs) do afterInputs[k]=v end
    for k,v in pairs(inputs.after or {}) do afterInputs[k]=v end
    local function changed(source)
        local result={};for k,v in pairs(source or {}) do result[k]=v end
        for k in pairs(result) do if type(k)=='string' and k:lower()==card.id:lower() then result[k]=nil end end
        result[card.id]=count(source,card.id)+increment
        return result
    end
    afterInputs.itemCounts=changed(inputs.itemCounts)
    if card.scope=='hero' then afterInputs.heroCounts=changed(inputs.heroCounts)
    elseif inputs.heldItemCounts and inputs.heldItemName then
        local applies=false
        for _,item in ipairs(card.availableOnItems) do if item:lower()==inputs.heldItemName:lower() then applies=true end end
        if applies and (inputs.candidateKind=='pickup' or
            (inputs.itemName and inputs.itemName:lower()==inputs.heldItemName:lower())) then
            afterInputs.heldItemCounts=changed(inputs.heldItemCounts)
        end
    end
    local rule=rules[card.id:lower()]
    local current=Effects.evaluate(card.id,n,inputs)
    local after=Effects.evaluate(card.id,n+increment,afterInputs)
    if gravityCards[card.id:lower()] then
        local function add(result,context)
            local total=Effects.gravity(counts,context)
            result.metrics.finalGravityScale=total
            result.metrics.gravityReduction=metric('较基础 1.25 的重力变化',total.value and (1-total.value/1.25),'gravityChange',nil,nil,total.missing)
            local coefficient=({jokerlightweight=.05,jokerlowgravity=.25,jokerdwarf=.2})[card.id:lower()]
            if total.value and coefficient then
                local hero=context.heroCounts or counts;local held=context.heldItemCounts
                local without=1.25+context.buffGravity-.25*count(hero,'jokerLowGravity')-.05*count(hero,'jokerLightWeight')
                    -.2*count(hero,'jokerDwarf')+.15*count(hero,'jokerChonky')+.3*count(held,'jokerHeavyWeapon')
                    +coefficient*count(hero,card.id)
                result.metrics.gravityFloorCardCount=metric('按当前其他效果，达到重力下限需本卡总数',math.max(0,math.ceil((without-.25)/coefficient-1e-9)),'cards')
            end
            result.complete=result.complete and total.value~=nil
            result.text=result.text..'；'..total.label..'：'..Effects.formatMetric(total)..'；较基础 1.25：'..Effects.formatMetric(result.metrics.gravityReduction)
            if result.metrics.gravityFloorCardCount then result.text=result.text..'；达到下限需本卡总数：'..Effects.formatMetric(result.metrics.gravityFloorCardCount) end
        end
        add(current,inputs);add(after,afterInputs)
        if inputs.currentGravityScale~=nil then
            current.metrics.runtimeGravityScale=metric('游戏当前读取的重力系数',inputs.currentGravityScale)
            current.text=current.text..'；游戏读取：'..numberText(inputs.currentGravityScale)
        end
    end
    local spellId=card.id:lower()
    local perSlot=type(inputs.spells)=='table' and #inputs.spells>0
    if spellRules[spellId] and not perSlot then
        local copied={}
        if type(counts)=='table' then for k,v in pairs(counts) do copied[k]=v end end
        for k in pairs(copied) do if type(k)=='string' and k:lower()==card.id:lower() then copied[k]=nil end end
        copied[card.id]=n+increment
        current.metrics.combinedCooldownMultiplier=Effects.spellCooldown(counts,inputs)
        after.metrics.combinedCooldownMultiplier=Effects.spellCooldown(copied,afterInputs)
        current.complete=current.complete and current.metrics.combinedCooldownMultiplier.value~=nil
        after.complete=after.complete and after.metrics.combinedCooldownMultiplier.value~=nil
        current.text=current.text..'；组合冷却倍率：'..Effects.formatMetric(current.metrics.combinedCooldownMultiplier)
        after.text=after.text..'；组合冷却倍率：'..Effects.formatMetric(after.metrics.combinedCooldownMultiplier)
    end
    if perSlot and (spellRules[spellId] or spellId=='jokercastaway' or spellId=='jokerbattlemage') then
        for _,spell in ipairs(inputs.spells) do
            local label='法术 '..spell.slot..'（'..(elementLabels[spell.element] or '元素未读')..'）'
            local context={};for k,v in pairs(inputs) do context[k]=v end
            context.baseSpellCooldown=spell.baseCooldown;context.spellElement=spell.element
            local nextContext={};for k,v in pairs(afterInputs) do nextContext[k]=v end
            local nextSpell=spell
            for _,candidate in ipairs(afterInputs.spells or {}) do if candidate.slot==spell.slot then nextSpell=candidate;break end end
            nextContext.baseSpellCooldown=nextSpell.baseCooldown;nextContext.spellElement=nextSpell.element
            if spellRules[spellId] then
                local currentCd=Effects.spellCooldown(counts,context)
                local nextCd=Effects.spellCooldown(changed(counts),nextContext)
                current.metrics['spellCooldown'..spell.slot]=metric(label..'完整冷却',currentCd.seconds,'seconds',nil,nil,currentCd.missing)
                after.metrics['spellCooldown'..spell.slot]=metric(label..'完整冷却',nextCd.seconds,'seconds',nil,nil,nextCd.missing)
            end
            local key
            if spellId=='jokercastaway' then context.otherSpellRemaining=spell.remaining;nextContext.otherSpellRemaining=nextSpell.remaining;key='remainingAfterCast'
            elseif spellId=='jokerbattlemage' then context.spellRemaining=spell.remaining;nextContext.spellRemaining=nextSpell.remaining;key='remainingAfterKill'
            elseif spellId=='jokerspellroulette' then context.spellCooldownRemaining=spell.remaining;nextContext.spellCooldownRemaining=nextSpell.remaining;key='randomizingNow' end
            if key then
                for _,entry in ipairs({{current,n,context},{after,n+increment,nextContext}}) do
                    local m=Effects.evaluate(card.id,entry[2],entry[3]).metrics[key]
                    m.label=label..(key=='remainingAfterCast' and '施放其他法术后剩余冷却' or
                        (key=='remainingAfterKill' and '击杀后剩余冷却' or '当前进入随机区间'))
                    entry[1].metrics[key..spell.slot]=m
                    entry[1].metrics[key]=nil
                end
            end
        end
        for _,result in ipairs({current,after}) do
            if spellId=='jokercantriponetrick' then
                -- This card's gate differs for each slot; a single missing base
                -- cooldown would contradict the three actual results above.
                result.metrics.cooldownWeight=nil;result.metrics.cooldownMultiplier=nil
            else
                if result.metrics.cooldownWeight then result.metrics.cooldownWeight.detailOnly=true end
                if result.metrics.cooldownMultiplier then result.metrics.cooldownMultiplier.detailOnly=true end
            end
        end
    end
    refreshResult(current);refreshResult(after)
    local lines={card.name,card.description,'当前 '..numberText(n)..' 份 → 选取后 '..numberText(n+increment)..' 份',
        '大厅装备份数上限：'..tostring(card.maxAvailable)..'（不代表任务中的效果上限）',
        '叠加方式：'..(rule and rule.stacking or '待核实'),
        '效果上限：'..(rule and rule.cap or '所核对路径未发现单卡上限；不代表全局无上限'),
        '当前：'..current.text,'选取后：'..after.text}
    if not rule then lines[6]='效果上限：待核实' end
    if rule and rule.note then lines[#lines+1]=rule.note end
    return {card=card,currentCount=n,afterCount=n+increment,current=current,after=after,lines=lines,
        status=rule and rule.status or 'unresolved',scope=rule and rule.scope or card.scope,
        equipLimit=card.maxAvailable,effectCap=rule and rule.cap,stacking=rule and rule.stacking,
        source=rule and rule.source,evidence='static-bytecode',runtimeVerified=false,
        conditions=rule and rule.note,complete=current.complete and after.complete and rule and
            (rule.status=='verified' or rule.status=='disabled') or false}
end
function Effects.rule(id)
    local card=Cards.get(id); return card and rules[card.id:lower()] or nil
end
local ruleApi={register=register,metric=metric,conditional=conditional,clamp=clamp,
    Effects=Effects,health=health,hasShield=hasShield}
require('HeroRules')(ruleApi)
require('WeaponRules')(ruleApi)
require('UpgradeRules')(ruleApi)
for id in pairs(spellRules) do
    if rules[id] then rules[id].inlineStacking='冷却效果可叠加；各法术实际值见上' end
end
rules.jokerspellroulette.inlineStacking='冷却可叠加；随机更换的频率不变'
return Effects
