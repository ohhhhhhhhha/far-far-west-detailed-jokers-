return function(R)
    local register,metric,conditional,clamp=R.register,R.metric,R.conditional,R.clamp
    local Effects,health=R.Effects,R.health
    local impact='FL_Items.F_ApplyImpactDamages'
    local state='AC_PlayerStateJoker.'
    local switchCap='仅检测持有；额外份数不增强此效果'

    register('jokerDeadlyStrong','hero','幽灵速度与攻击伤害分别为 1000／10 × 1.5 × 份数',
        'BP_PlayerGhost.F_UpdateGhostSpeed @0–670; ExecuteUbergraph @4765–5324',function(n)
        return {ghostSpeed=metric('幽灵步行速度',n>0 and 1500*n or 1000),
            ghostDamage=metric('幽灵攻击基础伤害',n>0 and 15*n or 10,'points')}
    end)
    register('jokerHelpingHand','hero','复活交互读条为 3 ÷ (2 × 份数)',
        'BP_PlayerGhost.F_GetInteractableDatas @0–971',function(n)
        return {reviveTime=metric('救援读条时间',n>0 and 3/(2*n) or 3,'seconds'),
            interactionDelay=metric('交互固定延迟',.5,'seconds')}
    end,nil,'verified','该数值属于对幽灵的救援交互，固定延迟不随本卡缩短。')
    register('jokerDwarf','hero','每份体型 −0.25、步速 +55、攻速 +30%、重力系数 −0.2',
        'BP_Player.F_UpdatePlayerScale @543–1490; F_UpdateSpeed @831–1943; F_UpdateGravity; BP_Item.F_GetAttackSpeed @3965–4417',function(n)
        return {sizeDelta=metric('体型系数加值',-.25*n),selfOnlyScale=metric('仅计本卡的体型系数',clamp(1-.25*n,.2,999)),
            moveSpeedDelta=metric('步行速度加值',55*n),attackSpeedBonus=metric('攻速加成',.3*n,'percent'),
            gravityScaleDelta=metric('重力系数加值',-.2*n)}
    end,'最终体型最低 0.2；仅本卡时 4 份达到。最终重力系数 0.25–2；攻速与步速路径未发现本卡单独上限',
        'verified','实际体型另加巨人 0.5／份及歌利亚最多 0.3。重力组合值由当前持用武器和临时增益共同决定。')
    register('jokerBouncingBall','hero','离地伤害倍率为 1 + 0.15 × 份数',impact..' @2536–2644,21100–21146',function(n,i)
        local active;if i.groundQueryPassed~=nil then active=not i.groundQueryPassed end
        if n==0 then active=false end
        return {damageMultiplier=conditional('离地武器伤害倍率',1+.15*n,'multiplier',active,
            'F_IsOnGround(1) 返回 false','角色地面查询结果',1)}
    end)
    register('jokerKnuckleDown','hero','当前持用近战武器命中时，伤害倍率为 1 + 0.1 × 份数',impact..' @18555–18783,20872–21026',function(n,i)
        local active
        if n==0 or i.meleeWeapon==false or i.heldItemMatchesDamage==false then active=false
        elseif i.meleeWeapon==true and i.heldItemMatchesDamage==true then active=true end
        return {damageMultiplier=conditional('本卡近战伤害倍率',1+.1*n,'multiplier',active,
            '持用物品有 meleeWeapon 标签，且其 itemName 等于伤害物品','近战标签与伤害物品匹配状态',1)}
    end)
    register('jokerShineBright','hero','每份色光参数 +0.25，灯光强度为该参数 × 3000',
        'BP_Player.ExecuteUbergraph @4138–4175,4964–5054; OnRep_chromaLightLevel',function(n)
        return {chromaticScalar=metric('材质 Chromatic 参数',.25*n),lightIntensity=metric('色光强度',750*n)}
    end)
    register('jokerSpareBullets','hero','分别对默认最大／初始备弹 × 0.1 × 份数四舍五入后相加',
        'BP_Item.F_InitItemDatas @236–3429',function(n,i)
        local capacity,initial
        if n==0 or i.isFixedAmountCount==true then capacity,initial=0,0
        elseif i.isFixedAmountCount==false then
            if i.defaultAmmoMaximum~=nil then capacity=math.floor(i.defaultAmmoMaximum*.1*n+.5) end
            if i.defaultAmmoCurrent~=nil then initial=math.floor(i.defaultAmmoCurrent*.1*n+.5) end
        end
        return {reserveAmmoBonus=metric('默认备弹增幅',.1*n,'percent'),
            reserveCapacityDelta=metric('备弹上限增加',capacity,nil,'非固定弹药数量物品初始化时',nil,'默认备弹上限与 isFixedAmountCount'),
            initialReserveDelta=metric('初始备弹增加',initial,nil,'非固定弹药数量物品初始化时',nil,'默认初始备弹与 isFixedAmountCount')}
    end,nil,'verified','不改变固定数量弹药物品；基数是物品默认数据，不能用已受其他卡影响的实时上限替代。')
    register('jokerMagicReload','hero','施法设置一次自动换弹标记；份数只决定是否持有',
        'AC_PlayerItems.F_TriggerJokerOnSpellCast @643–743; BP_Item.F_CheckJokerMagicReload @0–935; F_ReloadAmmos @5–3064',function(n,i)
        local used,after
        if n==0 then used=0;after=i.magazineAmmo
        elseif i.magazineAmmo~=nil and i.magazineMaximum~=nil and i.ammoCurrent~=nil and i.consumerEquipped~=nil then
            used=clamp(i.magazineMaximum-(i.consumerEquipped and 0 or i.magazineAmmo),0,i.ammoCurrent)
            if not i.consumerEquipped or i.consumerAvailable~=nil then
                after=clamp(((i.consumerEquipped and i.consumerAvailable) and 0 or i.magazineAmmo)+used,0,i.magazineMaximum)
            end
        end
        local pending=i.magicReloadProc;if n==0 then pending=false end
        return {enabled=metric('施法自动换弹',n>0,'boolean'),
            nextReloadReserveUsed=metric('下次有效施法换弹消耗备弹',used,nil,'换弹检查全部通过',nil,'弹匣、备弹及 Consumer 持有状态'),
            nextMagazineAmmo=metric('下次有效施法换弹后的弹匣',after,nil,'换弹检查全部通过',nil,'弹匣、备弹及 Consumer 可用状态'),
            pendingProc=metric('当前待消费施法标记',pending,'boolean',nil,nil,'magicReloadProc')}
    end,switchCap,'verified','要求本地控制、物品已初始化、弹匣未满、当前法术施放物品和待消费标记；排除 meleeWeaponSecondary、meleeWeapon、cancelJokerMagicReload 标签。调用普通换弹，使用备弹，并继承 Consumer 和空弹匣换弹触发效果。')
    register('jokerJokheal','hero','获得卡片的基础治疗 50 加每份本卡 35',
        state..'F_UpdateValuesWithNewJoker @563–1400',function(n,i)
        return {bonusHeal=metric('本卡额外拾卡治疗',35*n,'points'),
            pickupHeal=metric('非贪婪拾卡基础治疗',i.modifierGreed and 0 or 50+35*n,'points','UpdateHeal 为 true 且无贪婪词条')}
    end,nil,'verified','贪婪词条先进入扣除最大生命 20% 的分支，跳过这次治疗。数值为送入治疗函数的基础治疗，最终回复还受治疗倍率和生命上限影响。')
    register('jokerPricklyPear','hero','反伤为反馈事件伤害 + 曲线加值；曲线 15／30／45',
        'BP_Player.ExecuteUbergraph @21099–21846,25595–26078',function(n,i)
        local flat=Effects.curve('C_Joker_PricklyPear',n)
        local total
        if n==0 or i.damageCauserIsEnemy==false then total=0
        elseif i.damageCauserIsEnemy==true and i.incomingDamage~=nil then total=i.incomingDamage+flat end
        return {reflectFlatBonus=metric('反伤固定加值',flat,'points'),
            reflectDamage=metric('下一次符合条件的反伤',total,'points','伤害反馈触发且来源带 enemy 标签',
                i.incomingDamage~=nil and n>0 and (i.incomingDamage+flat) or nil,'该次调整后伤害与伤害来源')}
    end,'3 份起固定加值封顶 45；事件伤害部分不受此曲线上限限制','verified',
        '完全被护盾吸收的伤害不进入该反馈。incomingDamage 必须取难度与减伤计算后、护盾扣除前的反馈参数，不能用实际扣血量替代。')
    register('jokerScoutsHonor','hero','固定护盾恢复目标 10；受到伤害反馈后重新等待 10 秒',
        'AC_PlayerState_Shield.ExecuteUbergraph @177–573,844–967,1626–1746; BP_Player.ExecuteUbergraph @26137–26295',function(n,i)
        local active=i.scoutsHonorActive;if n==0 then active=false end
        return {shieldFloor=metric('启用后的护盾恢复目标',n>0 and 10 or 0,'points'),
            currentShieldFloor=conditional('当前本卡护盾恢复目标',n>0 and 10 or 0,'points',active,'侦察兵效果已恢复','isJokerScoutsHonorStillEnabled'),
            recoveryDelay=metric('受伤后等待',n>0 and 10 or 0,'seconds'),
            initialRecoverySpeed=metric('恢复启动时护盾变化速率',n>0 and 8 or 0)}
    end,switchCap,'verified','10 秒结束时非幽灵才启用；护盾通过 Tick 向目标值插值，不是立即加 10 点。后续速率还能被共享护盾计算更新。')
    register('jokerFinalEmber','hero','持有即在低生命命中时附加电击，额外份数不增强',impact..' @18022–18554',function(n,i)
        local h=health(i);local active;if n==0 then active=false elseif h~=nil then active=h<=.301 end
        return {healthThreshold=metric('触发生命比例上限',.301,'chance'),
            applyElectric=conditional('此次命中附加电击',n>0,'boolean',active,'生命比例 ≤ 30.1%','当前生命比例',false)}
    end,switchCap,'verified','向命中对象添加 UO_Buff_Elec；本卡不会按份数提高该电击的强度。')
    register('jokerColdBlooded','hero','符合条件的近战命中固定消耗 3 护盾并施加冰冻',impact..' @18555–18783,19461–20865',function(n,i)
        local active
        if n==0 or i.coldBloodedEligible==false or (i.shield~=nil and i.shield<3) then active=false
        elseif i.coldBloodedEligible==true and i.shield~=nil then active=true end
        return {requiredShield=metric('触发至少需要护盾',3,'points'),
            shieldCost=conditional('下一次符合条件命中的护盾消耗',n>0 and 3 or 0,'points',active,'合格目标且护盾 ≥ 3','目标资格与护盾'),
            applyFreeze=conditional('此次命中施加冰冻',n>0,'boolean',active,'合格目标且护盾 ≥ 3','目标资格与护盾',false)}
    end,switchCap,'verified','目标必须是尚未冰冻、能承受本次伤害后存活的普通敌人；排除首领、精英、cactusSpell。持用物品必须有 meleeWeapon 标签且 itemName 与伤害物品一致。')
    register('jokerTinMan','hero','超出生命上限的有效治疗按 1:1 转护盾，单次原始申请仅补到 15',
        'BP_PlayerState.ExecuteUbergraph @28656–29143; F_CalculateTinManHeal @0–629; AC_PlayerState_Shield.ExecuteUbergraph @3030–3270',function(n,i)
        local amount
        if n==0 then amount=0
        elseif i.health~=nil and i.maxHealth~=nil and i.shield~=nil and i.effectiveHeal~=nil then
            amount=clamp(math.max(0,i.health+i.effectiveHeal-i.maxHealth),0,math.max(0,15-i.shield))
        end
        return {shieldTarget=metric('本卡原始转换护盾目标',n>0 and 15 or 0,'points'),
            shieldFromOverheal=metric('下一次治疗的原始护盾转换',amount,'points',nil,nil,'当前生命、生命上限、护盾与经过倍率调整的治疗量')}
    end,'额外份数不提高 15 点目标；DoubleDown 等共享护盾增益可能使最终护盾超过此目标','verified',
        'effectiveHeal 是经过治疗倍率后送入 F_CalculateTinManHeal 的有效治疗增量。此处展示送给 F_AddShield_Server 的原始申请，最终护盾还经过共享加盾规则。')
    register('jokerLazy','hero','每 12 秒按容量 × 曲线份额四舍五入，至少 1，再裁到容量',
        state..'ExecuteUbergraph @2232–2255,10654–12019; F_JokerLazy_CalculateAmmoGive; F_JokerLazy_CalculateSheriffStar; BP_AmmoBox.ExecuteUbergraph @54–498,2272–2522; BP_AmmoBox_Utility.F_Interact',function(n,i)
        local fraction=n>0 and Effects.curve('C_Joker_Lazy',n) or 0
        local item=i.itemName
        if not item or item:lower()=='itemhero' then item=i.heldItemName end
        local name=(item or ''):lower()
        local maximum,current=i.ammoMaximum,i.ammoCurrent
        if name=='itemsheriffstar' then maximum,current=i.magazineMaximum,i.magazineAmmo end
        local quota,actual
        if n==0 or name=='itemboomerang' then quota,actual=0,0
        elseif maximum~=nil then quota=math.max(1,math.floor(maximum*fraction+.5));if current~=nil then actual=clamp(current+quota,0,maximum)-current end end
        local result={refillFraction=metric('每次补给容量份额',fraction,'percent'),
            ammoPerTick=metric('裁到容量前的每次补给量',quota,nil,nil,nil,'对应弹药容量'),
            actualAmmoRestored=metric('按当前弹药实际可补数量',actual,nil,nil,nil,'对应弹药当前数量与容量'),
            interval=metric('自动补给间隔',n>0 and 12 or 0,'seconds'),
            normalAmmoBoxesBlocked=metric('普通弹药箱拾取限制',n>0,'boolean'),
            utilityAmmoBoxesBlockedByLazy=metric('本卡限制工具弹药箱',false,'boolean')}
        if name=='itembow' then
            result.bowMagazineRestored=metric('弓的空弹匣额外补箭',n==0 and 0 or (i.magazineAmmo~=nil and (i.magazineAmmo==0 and 1 or 0) or nil),nil,nil,nil,'弓当前弹匣')
        elseif name=='itemminigun' then
            result.magazineAfterTick=metric('机枪补给后同步弹匣',actual and current+actual,nil,nil,nil,'当前备弹与容量')
        end
        return result
    end,'3 份起每次份额封顶 30%；实际回复不能超过对应容量','verified',
        '主副武器通常补备弹；警长之星改补弹匣，回旋镖跳过，弓另将空弹匣设为 1，机枪弹匣同步补给后的备弹。普通弹药箱被本卡阻止；工具箱覆写交互没有 Lazy 判断，仍受 ToolBox 等自身条件限制。')
    register('jokerHeavyDrinker','hero','每份使治疗瓶每次治疗 +2.5，共最多 7 次',
        'BP_Item_HealBottle.ExecuteUbergraph @502–1323',function(n)
        return {healPerPulse=metric('治疗瓶每次基础治疗',10+2.5*n,'points'),
            bottleBaseHeal=metric('完整 7 次基础治疗总量',70+17.5*n,'points'),
            pulseInterval=metric('治疗脉冲间隔',.1,'seconds')}
    end,nil,'verified','本地使用治疗瓶后，healedAmounts 从 0 到 6，每 0.1 秒调用一次治疗；0.75 秒停止循环。这里是未乘治疗倍率、未裁到生命上限的完整治疗量。')
    register('jokerSoulSiphon','hero','每份每个灵魂基础治疗 +2；拾取盒水平半宽 +128',
        'BP_Pickable_Soul.ExecuteUbergraph @30–476,2231–2425',function(n)
        return {healPerSoul=metric('每个灵魂的基础治疗',2*n,'points'),
            pickupBoxHalfWidth=metric('灵魂拾取盒水平半宽',256+128*n),
            pickupBoxHalfHeight=metric('灵魂拾取盒竖直半高',512)}
    end,nil,'verified','拾取范围是 BoxComponent 的半尺寸，不是球形半径。治疗仍经过共享治疗倍率及生命上限。')
    register('jokerCoinFlip','hero','每 10 秒独立掷币；伤害倍率按正反面曲线，不线性相加',
        'UI_JokerCoinFlip.ExecuteUbergraph @922–947,1909–2248; AC_PlayerStateJoker.ExecuteUbergraph @3072–3095,15630–16007; '..impact..' @11442–11899',function(n,i)
        local heads=Effects.curve('C_Joker_Coinflip_Bonus',n)
        local tails=Effects.curve('C_Joker_Coinflip_Malus',n)
        local current
        if n==0 then current=1 elseif i.coinFlipBonus~=nil then current=i.coinFlipBonus and heads or tails end
        return {headsDamageMultiplier=metric('正面伤害倍率',heads,'multiplier'),
            tailsDamageMultiplier=metric('反面伤害倍率',tails,'multiplier'),
            currentDamageMultiplier=metric('当前硬币伤害倍率',current,'multiplier',nil,nil,'jokerCoinFlipBonus'),
            headsChance=metric('每次掷币正面概率',.5,'chance'),interval=metric('掷币周期',n>0 and 10 or 0,'seconds')}
    end,'3 份起正面封顶 ×2.9、反面降至 ×0.1；概率和周期不随份数变化','verified',
        'UI 构造时 RandomBoolWithWeight(0.5)；动画事件通知结果后更新 jokerCoinFlipBonus。动画期间仍按上次已通知的结果计算伤害。')
    register('jokerFistFight','hero','徒手基础伤害为 10 × 2 × 份数；无卡为 10',
        'BP_Item_Melee.F_TraceDamages @5–367,3056–3111,3702–3901',function(n)
        local base=n>0 and 20*n or 10
        return {bareHandDamage=metric('徒手基础伤害',base,'points'),
            bareHandMultiplier=metric('徒手基础伤害倍率',n>0 and 2*n or 1,'multiplier')}
    end,nil,'verified','该基础伤害随后进入共享 F_ApplyImpactDamages；不会把指虎等其他近战武器的基伤改为此值。碰撞通道 14 的目标先将此基伤除以 5。')
    register('jokerStonks','hero','可掉落内容的普通宝箱：曲线概率替换为随机卡片',
        'BP_Chest_Loot.ExecuteUbergraph @642–1058,3679–4032,4704–5155',function(n,i)
        local chance=Effects.curve('C_Joker_Stonks',n)
        if i.chestIsFake==true or i.chestCanDropContent==false then chance=0 end
        return {jokerChestChance=metric('正常可掉落宝箱的本卡掉卡概率',chance,'chance','普通箱、允许掉落且未被大萧条销毁')}
    end,'1／2／3／4 份为 20%／40%／50%／55%；4 份起封顶 55%','verified',
        '成功走随机卡片分支，失败后才检查淘金狂热及普通内容。假箱爆炸、禁止掉落或大萧条销毁不会产出卡片；大萧条的销毁检查独立于本卡。')
    register('jokerChad','hero','折扣为每份 20%，先裁到免费再对实际价格取整；地图揭示只检测持有',
        'BP_NPC_WanderingTrader.F_GetPrice @0–625; UI_Map.F_InitWanderingTrader @0–929',function(n,i)
        local multiplier=clamp(1-.2*n,0,1)
        local prices={10,20,30,45,55}
        local current=i.traderTradesFinished~=nil and prices[i.traderTradesFinished+1] or nil
        local result={priceMultiplier=metric('商人价格倍率',multiplier,'multiplier'),
            currentPrice=metric('商人当前交易价格',current and math.floor(current*multiplier),nil,nil,nil,'商人的 amountTradesFinished（0–4）'),
            revealTrader=metric('地图揭示流浪商人',n>0,'boolean','游戏或加载地图、尚无商人 Ping 时')}
        for index,base in ipairs(prices) do result['tradePrice'..index]=metric('第 '..index..' 次交易价格',math.floor(base*multiplier)) end
        return result
    end,'5 份起价格倍率为 0；揭示位置的效果不随份数增强','verified',
        '原价依已完成交易数依次为 10、20、30、45、55，乘折扣后向零取整。地图遍历现存商人，没有按本卡份数计算距离。')
    register('jokerGoldProspector','hero','未花费任务金币先裁到 0–2000，再乘 1 + 0.2 × 份数并向零取整',
        'BP_GameState.F_GetLocalGolds @0–122; UI_Leaderboard.F_UpdateContract @14327–16322',function(n,i)
        local base=i.missionGold~=nil and clamp(i.missionGold,0,2000) or nil
        local total=base and math.floor(base*(1+.2*n))
        return {settlementMultiplier=metric('任务金币结算倍率',1+.2*n,'multiplier'),
            settlementGold=metric('按当前未花费金币的结算金额',total,nil,nil,nil,'F_GetLocalGolds 或 pickedUpGolds − localUsedGolds'),
            extraGold=metric('本卡增加的结算金币',total and total-base,nil,nil,nil,'当前未花费任务金币')}
    end,'计入倍率前的任务金币最多 2000；本卡倍率路径未见单卡上限','verified',
        '不直接增加途中拾取数量；基数是拾取金币减本地已花费金币。显示的是本次结算增加量，非账号钱包总额。')
    register('jokerSoulReaper','hero','未花费任务灵魂先裁到 0–4000，再乘 1 + 0.2 × 份数并向零取整',
        'BP_GameState.F_GetLocalSouls @0–122; UI_Leaderboard.F_UpdateContract @16586–18376',function(n,i)
        local base=i.missionSouls~=nil and clamp(i.missionSouls,0,4000) or nil
        local total=base and math.floor(base*(1+.2*n))
        return {settlementMultiplier=metric('任务灵魂结算倍率',1+.2*n,'multiplier'),
            settlementSouls=metric('按当前未花费灵魂的结算数量',total,nil,nil,nil,'F_GetLocalSouls 或 pickedUpSouls − localUsedSouls'),
            extraSouls=metric('本卡增加的结算灵魂',total and total-base,nil,nil,nil,'当前未花费任务灵魂')}
    end,'计入倍率前的任务灵魂最多 4000；本卡倍率路径未见单卡上限','verified',
        '不直接增加途中拾取数量；基数是拾取灵魂减本地已花费灵魂。显示的是本次结算增加量，非账号钱包总额。')
    register('jokerGoldCraze','hero','当前版本禁用；遗留金币分支仅检测持有，额外份数不增强',
        'DT_PlayerJokers.jokerGoldCraze.isEnabled=false; BP_Chest_Loot.ExecuteUbergraph @642–714,1333–2755,3809–4243; UI_Map.F_InitCloseChests @0–2',function(n,i)
        local chance
        if n==0 or i.chestIsFake==true or i.chestCanDropContent==false then chance=0
        elseif i.heroCounts~=nil then chance=1-Effects.curve('C_Joker_Stonks',Effects.count(i.heroCounts,'jokerStonks')) end
        return {availableInThisBuild=metric('当前版本正常获取',false,'boolean'),
            forcedGoldPickups=metric('遗留金币分支生成的金币拾取物',n>0 and 10 or 0,nil,'成功进入 wildcard=-2 分支'),
            forcedGoldBranchChance=metric('正常宝箱进入遗留金币分支的概率',chance,'chance','未被财富好运替换、允许掉落、非假箱且未被大萧条销毁',nil,'同一角色的财富好运份数'),
            mapRevealImplemented=metric('附近宝箱地图揭示实现',false,'boolean')}
    end,'遗留分支固定生成 10 个金币拾取物，不随份数增长','verified',
        '本卡在此版本被禁用。金币分支仍留在字节码内，先让财富好运判定，成功出卡后不再走金币分支。UI_Map.F_InitCloseChests 是空函数，不能承诺原描述的地图揭示。')
    register('jokerCrazyDeal','hero','当前版本禁用；不提供描述效果的数值预览',
        'DT_PlayerJokers.jokerCrazyDeal.isEnabled=false; UI_JokerShop.F_RefreshShop @1023; BP_CanyonGameInstance.F_FixSaveIssues @1113; BP_PlayerState.F_UpdatePlayerMaxHeal @176–514',function()
        return {availableInThisBuild=metric('当前版本正常获取',false,'boolean')}
    end,'不适用：当前版本禁用','disabled',
        '已检查版本 0.3.0.7：禁用标记使正常获取过滤此卡；已核对的角色生命与承伤路径没有该卡消费者。原描述的减伤 50%／锁血 30% 不作为可执行公式展示。DT 的 0.3 字段在通用路径仅触发重算，不能证明锁血。')
    register('jokerSpellRoulette','hero','每份增加 0.2 冷却权重；换法术只检测持有',
        'AC_PlayerItems.F_SpellCooldownTweak; '..state..'F_StoreAllUnlockedSpells; ExecuteUbergraph @2365–2767,12950–14125',function(n,i)
        local active;if n==0 then active=false elseif i.spellCooldownRemaining~=nil then active=i.spellCooldownRemaining>=1 and i.spellCooldownRemaining<2 end
        return {cooldownWeight=metric('冷却计算权重',.2*n),
            cooldownMultiplier=metric('仅本卡冷却倍率',clamp(math.floor((.3^(.2*n))*100+.5)/100,.1,1),'multiplier'),
            pollInterval=metric('换法术检查间隔',n>0 and .1 or 0,'seconds'),
            randomizingNow=conditional('当前冷却落在随机换法术区间',n>0,'boolean',active,'剩余冷却 ≥ 1 且 < 2 秒','该槽位的剩余冷却',false)}
    end,'冷却倍率最低 0.1；最终实际冷却另有 1 秒下限；换法术频率不随份数改变','verified',
        '启动等待 3 秒后，每 0.1 秒检查三个槽位，剩余冷却取整为 1 时重新随机。池包含等级解锁的法术，并在建池时排除三个已装备法术；不是每次施法立即只抽一次。')
end
