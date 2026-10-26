-- Item rules backed by the retained, complete UE5.8 CUE bytecode.
return function(R)
local register,metric,conditional,clamp,Effects=R.register,R.metric,R.conditional,R.clamp,R.Effects
local function held(i,item)
    if i.heldItemName~=nil then return i.heldItemName:lower()==item:lower() end
end
local function enabled(n,active) if n==0 then return false end return active end
local function copies(i,id) if i.itemCounts~=nil then return Effects.count(i.itemCounts,id) end end
local elementNames={[7]='acid',[8]='fire',[9]='electric',[15]='ice',
    ['E_DamageCategory::NewEnumerator1']='acid',['E_DamageCategory::NewEnumerator2']='fire',
    ['E_DamageCategory::NewEnumerator3']='electric',['E_DamageCategory::NewEnumerator16']='ice'}
local function element(i) return elementNames[i.weaponElement] or i.weaponElement end
local puddleDuration={acid=14,fire=5,electric=14,ice=9}
local function puddleMetrics(result,n,i,fireTemplateMissing)
    local e=element(i);local duration=e~=nil and puddleDuration[e] or nil
    local missing='当前特殊武器元素'
    if e=='fire' and fireTemplateMissing then duration=nil;missing='本版本缺少火元素爆炸配置行' end
    if n==0 or e~=nil and not puddleDuration[e] then duration=0 end
    result.puddleActiveSeconds=metric('水洼通常保持搜索的时长',duration,'seconds','可被元素反应或地面销毁提前结束',nil,missing)
    result.puddleScanInterval=metric('水洼模板搜索新目标的间隔',n>0 and .2 or nil,'seconds','仅在成功生成水洼时适用')
    result.puddleFirstContactDamage=metric('水洼模板对每个新目标的原始接触伤害',n>0 and 2 or 0,'points','成功生成后适用；随后施加元素状态，已处理目标加入忽略列表')
    return result
end

register('jokerDestroyer','item','同卡伤害加值相加；命中时读取弹药','FL_Items.F_ApplyImpactDamages @6069–7579',function(n,i,c)
    local current,maximum
    if i.itemName=='itemMinigun' then current,maximum=i.ammoCurrent,i.ammoMaximum
    else current,maximum=i.magazineAmmo,i.magazineMaximum end
    local active;if current~=nil and maximum~=nil then active=current>=maximum*.75 end
    return {damageBonus=conditional('按当前弹药判定的伤害加成',n*c.value,'percent',active,
        '命中结算时剩余弹药 ≥ 上限的 75%；转轮机枪读取总弹药','对应武器当前弹药和上限')}
end,nil,'verified','普通射击先扣弹再生成弹丸；面板当前弹药值不等于下一发命中时的值。')

register('jokerExecute','item','处决阈值使用份数曲线；额外伤害按目标状态计算','FL_Items.F_ApplyImpactDamages @4349–6068; C_Joker_Execute',function(n,i)
    local threshold=n>0 and Effects.curve('C_Joker_Execute',n) or 1
    local active
    if n==0 or i.targetIsEnemy==false or i.targetIsBoss==true or i.targetIsElite==true then active=false
    elseif i.targetIsEnemy==true and i.targetIsBoss==false and i.targetIsElite==false and i.targetDefaultHealth~=nil and i.targetEstimatedDamage~=nil then
        active=i.targetEstimatedDamage>=i.targetDefaultHealth*threshold
    end
    local damage
    if active==false then damage=0 elseif active then damage=i.targetDefaultHealth-i.targetEstimatedDamage+1 end
    return {remainingHealthThreshold=metric('预计剩余生命达到的处决阈值',1-threshold,'chance','按 defaultHealRuntime − estimatedDealtDamages 判定'),
        executeEligible=metric('当前目标满足处决条件',active,'condition',nil,nil,'敌人类型与累计预计受伤值'),
        executionDamage=metric('满足条件时追加的原始处决伤害',damage,'points',nil,nil,'敌人 defaultHealRuntime / estimatedDealtDamages')}
end,'3 份后预计剩余生命阈值为 35%；精英与 Boss 不触发','verified','判定使用敌人预计受伤累计值，不能把当前生命比例直接代入。')

register('jokerSpeedster','item','两条消费路径分别补偿瞄准／游泳速度，再查曲线乘份数','FL_Items.F_ApplyImpactDamages @7580–9698; BP_Item.F_GetAttackSpeed @69–684,4495–5531',function(n,i)
    local damageSpeed,attackSpeed=i.speedsterSpeed,i.speedsterSpeed
    local aiming,slow=i.heldAiming,i.heldSlowPlayerDuringAim
    if aiming==nil then aiming=i.aiming end
    if slow==nil then slow=i.slowPlayerDuringAim end
    if i.maxWalkSpeed~=nil and aiming~=nil and i.swimming~=nil then
        local swim=i.swimming and 200 or 0
        attackSpeed=i.maxWalkSpeed+swim+(aiming and 250 or 0)
        if not aiming or slow~=nil then
            damageSpeed=i.maxWalkSpeed+swim+(aiming and slow and 250 or 0)
        end
    end
    local function bonus(speed) if n==0 then return 0 elseif speed~=nil then return clamp(Effects.curve('C_Joker_Speedster',speed)*n,0,1) end end
    return {damageBonus=metric('本卡伤害加成',bonus(damageSpeed),'percent',nil,nil,'MaxWalkSpeed、游泳、持用武器瞄准与瞄准减速标记'),
        attackSpeedBonus=metric('本卡攻击速度加成',i.canBeAffectedByPlayerFireRate==false and 0 or bonus(attackSpeed),'percent',nil,nil,'MaxWalkSpeed、游泳与持用武器瞄准状态')}
end,'曲线 550→0%、1210→40%；各项乘份数后最多 +100%','verified','伤害仅在武器会减速时补偿瞄准的 250；攻速只要瞄准就补偿 250。两者游泳均补偿 200。')

register('jokerJumpStar','item','每份增加 2 次跳跃；只读取当前持用武器','BP_Player.F_UpdateJumpCount @0–585',function(n,i,c)
    local active=held(i,'itemSheriffStar')
    if i.isSwappingWeapon==true then active=false elseif active==true and i.isSwappingWeapon==nil then active=nil end
    return {extraJumps=conditional('当前本卡额外跳跃次数',math.floor(n*c.value),'number',active,'持用警长徽章且不在切枪中','持用武器与 isSwappingWeapon'),
        extraJumpsWhenHeld=metric('持用且切枪结束时额外跳跃次数',math.floor(n*c.value))}
end,nil,'verified','F_UpdateJumpCount 重设为 1 + 角色额外跳跃 + 本卡加值；面板不把该上限当作当前剩余跳跃。')

register('jokerAimingBurst','item','只检测持有；额外份数不增加穿透或弱点倍率','BP_Item_QuadBarrel.ExecuteUbergraph @4151–4275; FL_Items.F_ApplyImpactDamages @11178–11441',function(n,i)
    return {weakpointDamageBonus=conditional('瞄准时本卡弱点伤害加成',n>0 and .3 or 0,'percent',i.aiming,'持用武器瞄准且命中弱点','持用武器瞄准状态'),
        piercing=metric('本次瞄准射击启用穿透',enabled(n,i.aiming),'boolean',nil,nil,'瞄准状态')}
end,'弱点伤害固定 +30%，穿透是开关')

register('jokerHomingBurst','item','只检测持有；计数与两发额外子弹不乘份数','BP_Item_QuadBarrel.F_ApplyHomingBurstJoker @91–3170',function(n,i)
    return {triggerEveryShots=metric('触发所需射击次数',n>0 and 8 or nil),extraBullets=metric('找到有效目标时额外子弹数',n>0 and 2 or 0),
        shotsUntilTrigger=metric('按已存储计数距下次触发的射击数',n>0 and i.homingBurstShot~=nil and 8-i.homingBurstShot or nil,'number',nil,nil,n>0 and 'homingBurstShot' or nil)}
end,'固定每 8 次计数触发；最多两发，额外份数不增加','verified','计数到 8 即重置；前方查询没有有效敌人时不生成额外弹。仅找到一个敌人时两发均可指向它。')

register('jokerOverBlast','item','只检测持有；额外弹丸由缺弹数量决定','BP_Item_Shotgun.F_ApplyJokerOverBlast @5–546; ExecuteUbergraph @7585–7874',function(n,i)
    local extra=0
    if n>0 then extra=i.magazineMaximum~=nil and i.magazineAmmo~=nil and math.modf((i.magazineMaximum-i.magazineAmmo)/4) or nil end
    return {extraProjectiles=metric('按当前缺弹数增加的弹丸',extra,'number','射击扣弹后的弹匣数据',nil,'当前弹匣及上限'),
        projectilesPerShot=metric('按当前缺弹数的一次射击总弹丸',extra~=nil and 7+extra or nil,'number',nil,nil,'当前弹匣及上限')}
end,nil,'verified','普通射击为 1 发带光弹丸加 6 发无光弹丸；本卡增加 floor(缺弹/4)，不按持有份数放大。')

register('jokerRushBlast','item','只检测持有；射击与下一发准星使用不同扣弹阶段','BP_Item_Shotgun.F_CanApplyJokerRushBlash, F_CanApplyJokerRushBlastCrosshair, F_SpawnBullets; BP_PlayerBullet_Shotgun[_JokerRushBlast].CDO',function(n,i)
    local atShot,nextShot
    if n==0 then atShot,nextShot=false,false elseif i.magazineMaximum~=nil and i.magazineAmmo~=nil then
        local missing=i.magazineMaximum-i.magazineAmmo;atShot=missing<=3;nextShot=missing<=2
    end
    local range;if atShot~=nil then range=atShot and 16384 or 8192 end
    return {zeroSpreadAtShot=metric('当前扣弹阶段满足零散布',atShot,'boolean','发射时缺弹数 ≤ 3',nil,'当前弹匣及上限'),
        nextShotCrosshair=metric('当前下一发精确准星条件',nextShot,'condition','准星更新时缺弹数 ≤ 2',nil,'当前弹匣及上限'),
        maxTraceDistance=metric('按当前射击分支的弹丸最大射程',range,'number','游戏距离单位',nil,'当前弹匣及上限')}
end,'零散布及射程翻倍固定；额外份数不延长前段弹药')

register('jokerElementalSpin','item','同卡概率相加；成功后从四种元素中随机选一种','BP_Item_Minigun.F_GetMinigunBullet @0–445',function(n,i,c)
    local chance=clamp(n*c.value,0,1)
    return {elementalChance=metric('本次使用元素弹的概率',chance,'chance'),
        eachElementChance=metric('酸／火／电／冰各自的无条件概率',chance/4,'chance')}
end,'总触发概率最多 100%；每次只替换为一种元素弹')

register('jokerFocusShot','item','每份弱点命中减 2 秒；直接相减，不在此处钳制为零','FL_Items.F_TriggerImpactJokers @7710–11053',function(n,i,c)
    local reduction=n*c.value
    local roulette=i.spellRouletteActive
    if roulette==nil and i.heroCounts then roulette=Effects.count(i.heroCounts,'jokerSpellRoulette')>0 end
    local cooldowns={i.spellCooldownA,i.spellCooldownB,i.spellCooldownC}
    local recheck
    if n==0 or roulette==false then recheck=false
    elseif roulette and cooldowns[1]~=nil and cooldowns[2]~=nil and cooldowns[3]~=nil then
        recheck=cooldowns[1]-reduction<=reduction+1 or cooldowns[2]-reduction<=reduction+1 or cooldowns[3]-reduction<=reduction+1
    end
    local result={cooldownReduction=metric('下次弱点命中的原始法术减冷却',reduction,'seconds'),
        rouletteRefreshCheck=metric('下次弱点命中会先检查法术轮盘',recheck,'boolean',nil,nil,'轮盘卡及三个当前法术冷却')}
    for index,key in ipairs({'A','B','C'}) do
        local v=cooldowns[index]
        if recheck==false and v~=nil then v=v-reduction elseif n>0 then v=nil end
        result['afterWeakpointCooldown'..key]=metric('下次弱点命中后法术 '..key..' 原始冷却',v,'seconds',nil,nil,
            recheck and '轮盘检查可能更换法术；需实际触发后读取' or '当前冷却与轮盘状态')
    end
    return result
end,nil,'verified','轮盘分支若任一（当前冷却−减值）≤（减值+1），先将 0<冷却≤减值+1 的槽设为 1、检查换法术，再对更新后的冷却相减。')

register('jokerMarkAce','item','只检测持有；重复命中刷新同一标记，不叠加倍率','FL_Items.F_TriggerImpactJokers @7361–7709; F_ApplyImpactDamages @570–2169; UO_Buff_JokerMarkAce→UO_Buff.duration',function(n,i)
    return {markDuration=metric('每次命中施加标记的持续时间',n>0 and 5 or 0,'seconds'),
        markedImpactDamageBonus=conditional('当前目标标记的命中伤害加成',.15,'percent',i.targetMarkAceActive,'目标已有标记；通过 F_ApplyImpactDamages 结算','目标当前标记状态')}
end,'单个标记固定 +15%；持有张数不放大','verified','已核对通用物品命中伤害路径；不把它泛称所有持续伤害或任意来源伤害增幅。')

for _,entry in ipairs({{'jokerOverDraw',2},{'jokerUltraDraw',4}}) do
    local id,threshold=entry[1],entry[2]
    register(id,'item','只检测持有；阈值和子弹数量不乘份数','BP_Item_Bow.F_ApplyJoker, F_ApplyOverDrawJoker, F_CanArrowExplodesOnHit; ExecuteUbergraph @3827–3929,8533–8831; BP_ArrowProjectile @4062–4142; DT_Explosions *_jokerUltraDraw',function(n,i)
        local active;if n==0 then active=false elseif i.timeHoldedDraw~=nil then active=i.timeHoldedDraw>=threshold end
        local seconds=n>0 and i.attackSpeed~=nil and i.attackSpeed>0 and threshold/i.attackSpeed or nil
        local result={chargeThreshold=metric('已存储蓄力值触发阈值',n>0 and threshold or nil),
            nextFullChargeSeconds=metric('按当前攻速下次从零蓄力所需时长',seconds,'seconds',nil,nil,n>0 and 'F_GetAttackSpeed(1) 的完整结果' or nil)}
        if id=='jokerOverDraw' then
            result.extraArrows=conditional('当前蓄力可额外发出的箭',n>0 and 2 or 0,'number',active,'timeHoldedDraw ≥ 2','当前 timeHoldedDraw')
        else
            result.explosiveArrowFlag=metric('当前蓄力启用爆炸箭标记',active,'boolean','timeHoldedDraw ≥ 4',nil,'当前 timeHoldedDraw')
            result.explosionBaseDamage=metric('酸／火／电／冰爆炸模板原始伤害',n>0 and 20 or 0,'points','满蓄力后的元素爆炸；不是最终命中伤害')
            result.explosionRadius=metric('元素爆炸模板半径',n>0 and 700 or 0,'number','游戏距离单位')
            result.maxResidualPuddles=metric('元素爆炸模板最多生成的水洼',n>0 and 3 or 0,'number','仍需有效地面及空间')
        end
        if id=='jokerUltraDraw' then puddleMetrics(result,n,i) end
        return result
    end,'张数不改变 2／4 蓄力阈值；攻速缩短实时时长','verified','两卡可同时作用；额外箭也读取爆炸资格。蓄力时间采用开始蓄力时缓存的攻速，当前缓存不得因选卡重写。')
end

register('jokerEcoTrick','item','只检测持有；关闭双枪换弹时的弃弹参数','BP_Item_DualRevolver.ExecuteUbergraph @1257–1372; BP_Item.F_ReloadAmmos',function(n,i)
    local consumer=copies(i,'jokerConsumer');local saved
    if n==0 or consumer~=nil and consumer>0 then saved=0 elseif consumer~=nil then saved=i.magazineAmmo end
    return {disablesDualReloadWaste=metric('本卡关闭双枪换弹弃弹',n>0,'boolean'),
        preservedMagazineRounds=metric('按当前弹匣可免于舍弃的弹数',saved,'number','Consumer 仍可强制舍弃余弹',nil,'当前弹匣及本武器 Consumer 份数')}
end,'开关效果；额外份数不重复返还弹药')

register('jokerSwampTrick','item','只检测持有；为换弹榴弹切换元素爆炸配置','BP_Item_DualRevolver.ExecuteUbergraph @585–671; BP_Grenade_DualRevolver.ExecuteUbergraph @166–313; DT_Explosions',function(n,i)
    local e=element(i);local puddles
    if n==0 then puddles=0 elseif e=='acid' or e=='electric' or e=='ice' then puddles=1
    elseif e~=nil and e~='fire' then puddles=0 end
    return puddleMetrics({enabled=metric('换弹榴弹请求带水洼配置',n>0,'boolean'),
        maxResidualPuddles=metric('当前元素每次爆炸最多生成的水洼',puddles,'number','仍需有效地面及空间',nil,
            e=='fire' and '本版本缺少 explosionFire1_noPlayerDamages 配置行' or '当前特殊武器元素')},n,i,true)
end,'酸／电／冰配置最多 1 个；额外份数不增加','verified','火元素请求的配置行在本版本 DT_Explosions 中缺失，因此不能保证火焰水洼。')

register('jokerChonkyThrow','item','只检测持有；模型缩放、实际判定和穿盾各为开关','BP_Item_Boomerang.F_HasJokerChonkyThrow; BP_PlayerBoomerang.F_GetTraceRadius, F_FindShield, ExecuteUbergraph @3008–3164,6471–6525,7399–7705',function(n)
    return {meshScaleMultiplier=metric('回旋镖模型尺寸倍率',n>0 and 2 or 1,'multiplier'),
        traceRadiusXYMultiplier=metric('实际命中盒水平半径倍率',n>0 and 1.5 or 1,'multiplier'),
        traceRadiusZ=metric('实际命中盒垂直半径',n>0 and 12 or 8),ignoresShields=metric('忽略盾牌阻挡',n>0,'boolean')}
end,'额外份数不放大；命中盒不是模型的两倍')

register('jokerLingeringThrow','item','持有时持续时间倍率为 2×份数，再乘升级倍率','BP_Item_Boomerang.F_GetLingeringTime @0–402; ExecuteUbergraph @446–551',function(n,i,c)
    local up=copies(i,'jokerUpgradeBoomerangLingeringTime');local mult=n>0 and n*c.value or 1
    return {durationMultiplier=metric('本卡滞留时间倍率',mult,'multiplier'),
        lingerSeconds=metric('下次投掷的滞留时间',up~=nil and .4*(1+.1*up)*mult or nil,'seconds',nil,nil,'本武器持续时长升级份数')}
end,nil,'verified','此值是飞至远端后的滞留段，不是整个往返飞行寿命；已投出的回旋镖使用生成时传入的持续时间。')

register('jokerSpellLash','item','施法触发时直接设为 1；额外份数不增加充能','AC_PlayerItems.F_TriggerJokerOnSpellCast @471–642',function(n,i)
    return {chargeAfterSpell=metric('下次施放法术后的绳索充能',n>0 and 1 or i.lassoCharge,'chance'),
        currentCharge=metric('当前已存储绳索充能',i.lassoCharge,'chance',nil,nil,'refItemManager.ragebar_Lasso')}
end,'充能直接设为 100%，不相加','verified','施法路径读取 itemLasso 上的卡，不要求当时持用绳索。当前缓存不会因选卡直接填满。')

register('jokerCanOpenener','item','本版本数据表禁用；正常流程不提供此卡','DT_PlayerJokers.jokerCanOpenener enabled=false',function()
    return {normalAcquisitionEnabled=metric('本版本正常获取已启用',false,'boolean')}
end,'本版本未启用','disabled','已确认的是禁用状态。未发现可用的正常消费路径；不据原描述推导强行注入后的护甲／护盾穿透数值。')

register('jokerScavengerStar','item','持用时每份 +165 步速；徽章回收范围与范围升级相加','BP_Player.F_UpdateSpeed @563–695; BP_SheriffStarProjectile.F_GetPickUpRange @0–532; ExecuteUbergraph @5532–5690',function(n,i,c)
    local active=held(i,'itemSheriffStar');local upgrade=copies(i,'jokerUpgradeSherrifStarPickUpRange');local range
    if active==false then range=1 elseif active and upgrade~=nil then range=1+.1*upgrade+n*c.value end
    return {moveSpeedDelta=conditional('持用时本卡步行速度加值',n*165,'number',active,'当前持用警长徽章','当前持用武器'),
        nextPickupRadiusMultiplier=metric('新生成徽章的回收球半径倍率',range,'multiplier','生成时读取当前持用武器卡',nil,'持用武器及徽章拾取范围升级份数')}
end,nil,'verified','扩大的是投出的警长徽章回收范围，不是所有资源拾取。已生成的回收球在生成时设定，不因之后选卡重算。')

register('jokerStackedLever','item','只检测持有；每次符合条件的击杀固定请求补 2 发','BP_PlayerState.F_TriggerOnKillTweaks @249–405,3281–4490',function(n,i)
    local added,spent
    if n==0 or i.ammoCurrent~=nil and i.ammoCurrent<2 then added,spent=0,0
    elseif i.ammoCurrent~=nil and i.magazineAmmo~=nil and i.magazineMaximum~=nil then
        spent=i.magazineAmmo==i.magazineMaximum-1 and 1 or 2
        added=clamp(i.magazineAmmo+spent,0,i.magazineMaximum)-i.magazineAmmo
    end
    return {roundsOnEligibleKill=metric('若现在满足击杀条件，弹匣实际增加',added,'number','子弹伤害击杀；当时持用此卡武器且 lastShotConsumedAmmo=true',nil,'弹匣、上限及备用弹药'),
        reserveSpentOnEligibleKill=metric('对应扣除的备用弹药',spent,'number','备用弹药至少 2 发才进入分支',nil,'弹匣、上限及备用弹药')}
end,'每次最多装入 2 发；多张不增加','verified','缺一发时只装／扣 1 发，但仍要求备用至少 2 发。已满弹匣时蓝图仍会扣 2 发备用，弹匣由上限截断。')

register('jokerFistRoDah','item','只检测持有；蓄力攻击附加固定冰霜和位移冲量','BP_Item_Knuckles.ExecuteUbergraph @1054–1816',function(n)
    return {chargedAttackAppliesIce=metric('蓄力攻击附加冰霜',n>0,'boolean'),
        backwardLaunchCoefficient=metric('蓄力攻击反向水平冲量系数',n>0 and 2048 or 0,'number','相机前向向量的水平分量乘负值'),
        upwardLaunchDelta=metric('蓄力攻击额外竖直速度',n>0 and 1024 or 0,'number','与现有速度相加；游戏单位')}
end,'固定附加效果；张数不放大','verified','LaunchCharacter 的 XYOverride、ZOverride 均为 false；这些数值不是移动距离或最终速度。')

register('jokerFistRage','item','只检测持有；攻速与时长固定，受伤充能只受蓄力升级影响','BP_Item_Knuckles.ExecuteUbergraph @2080–2199,5077–5775,7464; AC_PlayerStateJoker @16125–16303; BP_Item.F_GetAttackSpeed @2653–2895',function(n,i)
    local upgrade=copies(i,'jokerUpgradeChargingSpeed')
    local gain=n==0 and 0 or upgrade~=nil and .0935*(1+.15*upgrade) or nil
    return {attackSpeedBonus=conditional('当前狂怒之拳攻速加成',n>0 and .3 or 0,'percent',i.fistRageActive,'狂怒之拳激活中','jokerFistRageActive'),
        triggerDuration=metric('受伤触发后刷新持续时间',n>0 and 2 or nil,'seconds'),
        chargePerDamagePulse=metric('下次获准受伤脉冲增加的充能',gain,'chance',nil,nil,'本武器蓄力速度升级份数'),
        chargeAfterDamagePulse=metric('按当前缓存，下次受伤脉冲后充能',gain~=nil and i.knucklesCharge~=nil and i.knucklesCharge+gain or nil,'chance',nil,nil,'当前 rageBar_Knuckles 与蓄力速度升级'),
        damagePulseGateSeconds=metric('受伤充能脉冲门控间隔',n>0 and .2 or nil,'seconds')}
end,'攻速固定 +30%，刷新 2 秒；此充能写入分支没有 100% 钳制','verified','受到伤害事件需经过 0.2 秒门控；重复触发刷新现有 2 秒计时。当前攻速激活标记和充能必须读取，不随选卡伪造。')

register('jokerSkyLash','item','只检测持有；在蓄力攻击固有的 +500 步速上再加 275','BP_Item_Lasso.ExecuteUbergraph @102–638,711–1078; UO_Buff_Speed_JokerSkyLash @192–449; CDO',function(n,i)
    local current=i.skyLashBuffSpeed;if i.skyLashBuffActive==false then current=0 end
    return {nextCardMoveSpeedDelta=metric('下次蓄力攻击脉冲本卡增加的步速',n>0 and 275 or 0),
        nextBuffSpeed=metric('下次脉冲的完整临时步速加值',n>0 and 775 or 500),
        currentBuffSpeed=metric('当前已存储的临时步速加值',current,'number',nil,nil,'当前 SkyLash Buff 实例 speed 或明确未激活'),
        buffDuration=metric('每次临时速度增益持续时间',.4,'seconds'),
        flightEnabled=metric('蓄力攻击重复提供向上推力',n>0,'boolean'),
        launchVerticalBase=metric('向上速度设置的常数项',n>0 and 512 or 0,'number','另加角色前向向量 Z；ZOverride=true')}
end,'本卡步速额外 +275，张数不放大','verified','持续蓄力攻击循环间隔为 0.25/攻速。速度 Buff 本身基础 +500 即使未持卡也存在；本卡额外 +275，不把总增益当成单卡贡献。')

register('jokerLullabard','item','只检测持有；每次命中 +2 和弦并钳制到已缓存上限','BP_Item_Banjo.ExecuteUbergraph @879–1200,2726–3130,3656–3935,4467–4595,9918–10123',function(n,i)
    local after
    if i.banjoHitAmount~=nil and i.additionalChords~=nil then
        if n>0 then after=clamp(i.banjoHitAmount+2,0,7+i.additionalChords)
        else after=(i.banjoHitAmount+1)%(8+i.additionalChords) end
    end
    return {chordsPerHit=metric('每次成功命中请求增加的和弦',n>0 and 2 or 1),
        chordsAfterHit=metric('按当前缓存，下次命中后的和弦',after,'number',nil,nil,'refItemManager.banjoHitAmount 与武器 additionalChords'),
        healRadius=metric('治疗搜索半径',n>0 and 2048 or 1024,'number','游戏距离单位'),
        heavyAttackEnabled=metric('允许普通重砸或吟游蛮人蓄力重砸',n==0,'boolean')}
end,'持卡时上限 7 + 已缓存额外和弦；张数不增加每次产量','verified','未持卡的普通命中以 8+额外和弦取余；持卡后改为上限钳制。治疗量仍是原武器每次原始 4 点，本卡扩大范围。')

register('jokerBardbarian','item','只检测持有；伤害按蓄力曲线缓存，额外份数不放大','BP_Item_Banjo.CurveFloat_0, T_Bardbarian_Template; F_GetSpecialAttackDamages @0–848; ExecuteUbergraph @6527–6554,8067–8128,9918–10123',function(n,i)
    local chord=copies(i,'jokerUpgradeChordCapacity');local lull=copies(i,'jokerLullabard');local damage
    if lull~=nil and lull>0 then damage=0
    elseif lull~=nil then
        if n==0 and chord~=nil then damage=25*(1+.15*chord)
        elseif n>0 and i.bardbarianStoredDamage~=nil then
            if i.bardbarianStoredDamage<=0 then damage=25 elseif chord~=nil then damage=i.bardbarianStoredDamage*(1+.15*chord) end
        end
    end
    local speed=i.attackSpeed;local timing=n>0 and speed~=nil and speed>0
    return {currentSpecialBaseDamage=metric('按当前蓄力缓存可释放的原始重砸伤害',damage,'points','催眠诗人会禁用重砸；随后仍经过通用近战伤害计算',nil,'bardbarianDamages 与本武器和弦／催眠诗人卡'),
        peakCurveDamage=metric('本卡蓄力曲线的峰值',n>0 and 75 or 25,'points','不含和弦升级和通用伤害增幅'),
        peakWindowStartSeconds=metric('按当前攻速下次蓄力峰值窗口开始',timing and 2.51/speed or nil,'seconds',nil,nil,n>0 and '完整攻击速度' or nil),
        peakWindowEndSeconds=metric('按当前攻速下次蓄力峰值窗口结束',timing and 2.99/speed or nil,'seconds',nil,nil,n>0 and '完整攻击速度' or nil)}
end,'曲线峰值 75；和弦容量升级另乘 1+15%×份数','verified','曲线从 20 线性升至 2.5 秒的 50，2.51–2.99 秒为 75，3 秒降回 50。缓存 ≤0 的持卡路径返回基础 25，不读取该处未赋值的和弦升级分支。')

register('jokerTrailPack','item','只检测持有；每次尾迹弹丸落地最多请求一个对应元素水洼','BP_Item_Jetpack.F_ImpulsePuddles @189–903; BP_JetpackPuddleProjectile.ExecuteUbergraph @1880–3285',function(n,i)
    local e=element(i);local maximum
    if n==0 then maximum=0 elseif e~=nil then maximum=(e=='acid' or e=='fire' or e=='electric' or e=='ice') and 1 or 0 end
    return puddleMetrics({maxPuddlesPerImpact=metric('每次尾迹弹丸碰撞最多生成的水洼',maximum,'number','再次找到地面且附近有足够空间',nil,'当前特殊武器元素'),
        scatterRadius=metric('碰撞点水平随机偏移范围',n>0 and 128 or 0,'number','游戏距离单位')},n,i)
end,'每个有效碰撞至多一个；张数不增加数量','verified','先在碰撞点周围随机偏移，再向上下 64 单位找地面，并以 16 单位检查已有水洼空间；不保证每个碰撞都生成。')

register('jokerCrashPack','item','只检测持有；初始化燃料翻倍、单次飞行时长乘 0.5','BP_Item_Jetpack.ExecuteUbergraph @10359–10848,11566–12036; T_Fuel_Template',function(n,i)
    local upgrade=copies(i,'jokerUpgradeJetpackFlightDuration')
    return {initialFuelMultiplier=metric('武器初始化时燃料倍率',n>0 and 2 or 1,'multiplier'),
        nextFlightSeconds=metric('下次完整飞行的名义时长',upgrade~=nil and 2*(1+.05*upgrade)*(n>0 and .5 or 1) or nil,'seconds',nil,nil,'本武器飞行时长升级份数'),
        currentFuel=metric('游戏当前读取的剩余燃料',i.ammoCurrent,'number',nil,nil,'当前总弹药／燃料')}
end,'固定翻倍／减半；额外份数不继续翻倍或减半','verified','子类初始化先令弹匣等于总燃料，再把当时燃料乘 2 写入 current/max。已初始化的当前数值直接读取，选卡预览不再乘 2。')

register('jokerHoverPack','item','只检测持有；替换俯冲分支，消耗固定 1 燃料','BP_Item_Jetpack.ExecuteUbergraph @773–892,12037–12286; BP_JetpackAntigrav @102–215,1554–1839; BP_Manager_Items @476–516',function(n,i)
    return {fuelPerActivation=metric('下次悬浮推进消耗燃料',n>0 and 1 or 0),
        nextHoverDuration=metric('下次悬浮推进名义持续时间',n>0 and 3 or nil,'seconds'),
        switchesToPrimary=metric('悬浮触发时切回主武器',n>0,'boolean'),
        currentAntigravActive=metric('当前已存储的悬浮状态',i.jetpackAntigravActive,'boolean',nil,nil,'refItemManager.isUsingJetpackAntigrav')}
end,'固定 3 秒与 1 燃料；额外份数不增强','verified','悬浮 Actor 持续设置水平速度为当前速度的 0.9、竖直速度为 64，覆盖对应速度分量；不把它换算成固定移动距离。')
end
