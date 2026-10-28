local Cards=require('Cards')
local Effects=require('Effects')
local Inventory=require('Inventory')
local L=require('Locale')
local P={}
local headings={'\n\n【奇术卡信息】','\n\n[Joker Info]'}
setmetatable(P,{__index=function(_,key)
    if key=='heading' then return L.choose(headings[1],headings[2]) end
    if key=='marker' then return L.choose(headings[1],headings[2])..'\n' end
end})
local statusText={verified='已显示指标的公式已核对',partial='部分规则待核实',unresolved='规则待核实',disabled='当前版本禁用'}
local function isUpgrade(c) return c.id:lower():find('jokerupgrade',1,true)~=nil end
local function strip(s)
    local first
    for _,heading in ipairs(headings) do
        local p=s:find(heading,1,true);if p and (not first or p<first) then first=p end
    end
    return first and s:sub(1,first-1) or s
end
P.stripDescription=strip
local function originalDescription(c,original)
    local text=strip(original or L.card(c.id,'description') or c.description)
    if text==L.card(c.id,'description','zh') or text==L.card(c.id,'description','en') then
        return L.card(c.id,'description')
    end
    return text
end
local function groupsFor(s,id,item)
    if item and Inventory.applies(id,item) then
        local g=Inventory.group(s,item)
        for _,known in ipairs(Inventory.groups(s)) do if known.itemName:lower()==item:lower() then g.label=known.label end end
        return {g}
    end
    if item then return {} end
    local result={}
    for _,g in ipairs(Inventory.groups(s)) do if Inventory.applies(id,g.itemName) then result[#result+1]=g end end
    return result
end
-- These rules depend on a consumable resource or a temporary combat state.
-- If their live values are unchanged, compare a labelled trigger/rate instead
-- of treating a zero resource as proof that acquiring the ability is useless.
-- Reuse the verified evaluator; never write these example inputs to the game
-- or substitute them for F7's live metrics.
local resourceCases={
    jokerAllMighty={key='damageBonus',inputs={shield=1},zh='每 1 点护盾的伤害加成',en='Damage bonus per 1 shield point'},
    jokerCheapSkate={key='flatHealth',inputs={gold=15},zh='每 15 枚任务金币的生命加值',en='Health bonus per 15 mission gold'},
    jokerEagleLever={key='damageBonus',inputs={consecutiveHits=1},zh='1 层连击时的伤害加成',en='Damage bonus at 1 combo stack'},
    jokerSpellLash={key='chargeAfterSpell',inputs={lassoCharge=0},zh='从空蓄力条施法后的充能',en='Charge after casting from an empty bar'},
    jokerStonks={key='jokerChestChance',inputs={chestIsFake=false,chestCanDropContent=true},zh='普通可掉落宝箱的掉卡概率',en='Joker chance in a normal lootable chest'},
}
local function conditionalSummary(id,n,inputs)
    local entry=resourceCases[id]
    if id=='jokerOverBlast' and inputs.magazineMaximum and inputs.magazineMaximum>=4 then
        entry={key='extraProjectiles',inputs={magazineAmmo=inputs.magazineMaximum-4},
            zh='缺少 4 发弹药时的额外弹丸',en='Extra pellets with 4 missing rounds'}
    elseif id=='jokerRushBlast' and inputs.magazineMaximum then
        entry={key='zeroSpreadAtShot',inputs={magazineAmmo=inputs.magazineMaximum},
            zh='发射时缺弹 ≤ 3：零散布',en='Zero spread with at most 3 missing rounds at firing'}
    elseif id=='jokerStackedLever' then
        if inputs.magazineMaximum==nil then
            return {label=L.choose('满足击杀条件时的补弹','Reload on an eligible kill'),
                value=n==0 and 0 or nil,unit='number',missing=L.choose('该武器弹匣容量','weapon magazine capacity')}
        end
        entry={key='roundsOnEligibleKill',inputs={ammoCurrent=2,magazineAmmo=0},
            zh='备弹 ≥ 2、弹匣空时的击杀补弹',en='Kill reload with reserve ≥ 2 and an empty magazine'}
    elseif id=='jokerSpeedster' then
        -- Its verified curve rises 0.4 over 660 effective speed. An extra 3%
        -- of the 550 base is 16.5, hence 1% per copy before the consumer clamp.
        return {label=L.choose(inputs.canBeAffectedByPlayerFireRate==false and
            '每 +3% 有效移速的增伤（未封顶时）' or '每 +3% 有效移速的伤害／攻速加成（未封顶时）',
            inputs.canBeAffectedByPlayerFireRate==false and 'Damage per +3% effective speed (before saturation)' or
            'Damage / attack speed per +3% effective speed (before saturation)'),
            value=n*Effects.curve('C_Joker_Speedster',566.5),unit='percent'}
    end
    if not entry then return end
    local context={};for k,v in pairs(inputs) do context[k]=v end
    for k,v in pairs(entry.inputs) do context[k]=v end
    local m=Effects.evaluate(id,n,context).metrics[entry.key]
    return {label=L.choose(entry.zh,entry.en),value=m.value,unit=m.unit}
end
function P.description(id,s,item,kind,original)
    local c=Cards.get(id)
    if not c then return original end
    local r=Effects.rule(id)
    local upgrade=isUpgrade(c)
    local originalText=originalDescription(c,original)
    local base=originalText..P.marker
    if r and r.status=='disabled' then
        return base..L.text('当前版本禁用；不提供正常获取或效果预览'),{noBonus=false}
    end
    local lines={};local groups=groupsFor(s,id,item)
    if #groups==0 and not s.complete then return base..L.text('效果待读取'),{noBonus=false} end
    local function differs(a,b)
        if type(a)=='number' and type(b)=='number' then return math.abs(a-b)>1e-8 end
        return a~=b
    end
    local function unknown(m)
        return m and m.value==nil and m.potential==nil and m.missing~=nil
    end
    local function displayValue(m)
        if m.potential~=nil then return m.potential end
        return m.value
    end
    local function displayMetric(m)
        -- Acquisition/current-card summaries describe the effect when its stated
        -- condition is met. F7 continues to use the live value via formatMetric.
        if m.potential==nil then return Effects.formatMetric(m) end
        return Effects.formatMetric({value=m.potential,unit=m.unit})
    end
    for _,g in ipairs(groups) do
        local label=g.label or g.itemName
        if not g.complete then lines[#lines+1]=label..'：效果待读取'
        else
            local equipped=(g.parts[c.id] or {}).equipped or 0
            local atEquipLimit=not upgrade and kind=='equip' and equipped>=c.maxAvailable
            local current=kind=='current'
            -- A held stack remains useful at a cap even if removing just one
            -- copy would not lower its total. Compare with having none of it.
            local increment=current and -Effects.count(g.counts,c.id) or 1
            local inputs
            if current then
                inputs={};for k,v in pairs(g.inputs) do inputs[k]=v end
                inputs.candidateKind=kind;inputs.after={}
                if not upgrade and inputs.activeCardCount then inputs.after.activeCardCount=inputs.activeCardCount+increment end
            else inputs=Inventory.candidateInputs(g,id,kind) end
            local p=Effects.preview(id,g.counts,inputs,increment)
            local keys={}
            for key in pairs(p.current.metrics) do
                local gravityDetail=p.current.metrics.finalGravityScale and
                    (key=='gravityScaleDelta' or key=='runtimeGravityScale' or key=='gravityFloorCardCount')
                -- The next incoming hit does not exist yet. Its raw event total
                -- belongs in F7; the compact card can state the exact flat bonus
                -- and formula without filling its scroll area with missing data.
                local futureRetaliation=c.id=='jokerPricklyPear' and key=='reflectDamage'
                if not gravityDetail and not futureRetaliation and not p.current.metrics[key].detailOnly and key~='equippedSameElementSpells' then keys[#keys+1]=key end
            end
            local priority={finalGravityScale=1,gravityReduction=2}
            table.sort(keys,function(a,b)
                if priority[a] or priority[b] then return (priority[a] or 99)<(priority[b] or 99) end
                return a<b
            end)
            local details={}
            if not atEquipLimit and increment~=0 then
                if #keys==0 and p.status~='verified' then details[1]='效果规则待核实' end
                for _,key in ipairs(keys) do
                    local m,nextMetric=p.current.metrics[key],p.after.metrics[key]
                    local changed=nextMetric and differs(displayValue(m),displayValue(nextMetric))
                    local missing=unknown(m) or unknown(nextMetric)
                    if changed or missing then
                        local metricLabel=({finalGravityScale='重力系数',gravityReduction='相比基础重力'})[key]
                            or (L.language()=='zh' and m.label:gsub('^本卡','') or m.label)
                        local detail=metricLabel..'：'..displayMetric(m)
                        -- Tab shows current values; its removal comparison is only
                        -- a relevance filter, never another acquisition preview.
                        if not current and nextMetric and changed then
                            detail=detail..' → '..displayMetric(nextMetric)
                        end
                        if m.condition and key~='finalGravityScale' then
                            local condition=m.condition
                            if c.id=='jokerBouncingBall' then condition=L.choose('离地时','While airborne') end
                            detail=detail..'\n（'..condition..'）'
                        end
                        details[#details+1]=detail
                    end
                end
                if #details==0 then
                    local now=conditionalSummary(c.id,p.currentCount,inputs)
                    local after=conditionalSummary(c.id,p.afterCount,inputs)
                    if now and after and (differs(now.value,after.value) or unknown(now) or unknown(after)) then
                        local detail=now.label..'：'..Effects.formatMetric(now)
                        if not current then detail=detail..' → '..Effects.formatMetric(after) end
                        details[1]=detail
                    end
                end
            end
            if #details>0 then
                if c.id=='jokerPricklyPear' then
                    details[#details+1]=L.choose('反伤＝减伤后伤害＋附加值','Retaliation = post-mitigation damage + bonus')
                    details[#details+1]=L.choose('敌人造成生命伤害时触发','Triggers when an enemy damages your health')
                end
                if #groups>1 then lines[#lines+1]=label..'：' end
                local elementCount=p.current.metrics.equippedSameElementSpells
                if elementCount then lines[#lines+1]=elementCount.label..'：'..Effects.formatMetric(elementCount) end
                for _,detail in ipairs(details) do lines[#lines+1]=detail end
            end
        end
    end
    if #lines==0 then
        if kind=='pickup' then return base..L.text('无加成'),{noBonus=true,plainText=base:sub(1,-2)} end
        return originalText,{noBonus=false}
    end
    return base..L.text(table.concat(lines,'\n')),{noBonus=false}
end
function P.entries(s)
    local entries={}
    for _,g in ipairs(Inventory.groups(s)) do
        -- Preserve DT order, with permanent upgrades after collectible cards.
        local ids={};for id in pairs(g.counts) do ids[#ids+1]=id end
        table.sort(ids,function(a,b)
            local ua=a:lower():find('jokerupgrade',1,true)~=nil
            local ub=b:lower():find('jokerupgrade',1,true)~=nil
            if ua~=ub then return not ua end
            return Cards.get(a).name<Cards.get(b).name
        end)
        for _,id in ipairs(ids) do entries[#entries+1]={card=Cards.get(id),group=g,count=g.counts[id]} end
    end
    return entries
end
function P.page(s,index,pageSize)
    pageSize=math.max(1,math.min(10,math.floor(pageSize or 10)))
    local entries=P.entries(s)
    index=math.max(1,math.min(index or 1,math.max(1,#entries)))
    local page={index=index,count=#entries,entries=entries,rows={},pageSize=pageSize,pageNumber=math.floor((index-1)/pageSize)+1,
        pageCount=math.max(1,math.ceil(#entries/pageSize)),title=L.text('当前奇术卡'),list='',detail=''}
    if #entries==0 then
        page.detail=L.text(s.complete and '当前没有已生效的奇术卡或升级。' or '总份数待读取：'..table.concat(s.missing,'、'))
        return page
    end
    local selected=entries[index];page.selected=selected
    local g,c=selected.group,selected.card
    local start=math.floor((index-1)/pageSize)*pageSize+1
    local list={}
    for k=start,math.min(start+pageSize-1,#entries) do
        local e=entries[k]
        local caption=L.text(e.group.label)..' · '..(L.card(e.card.id,'name') or e.card.name)
            ..(isUpgrade(e.card) and (' '..e.count..L.text('级')) or (' ×'..e.count))
        list[#list+1]=(k==index and '▶ ' or '   ')..caption
        page.rows[#page.rows+1]={index=k,text=list[#list],buttonText=caption,selected=k==index}
    end
    page.list=table.concat(list,'\n\n')
    page.title=L.text(g.label)..' · '..(L.card(c.id,'name') or c.name)..'  ['..index..'/'..#entries..']'
    local parts=g.parts[c.id]
    local lines={'适用：'..g.label,
        '份数来源：装备 '..parts.equipped..' ＋ 任务 '..parts.runtime..' ＋ 升级 '..parts.upgrades}
    if not g.complete then
        lines[#lines+1]='总份数待读取；缺少来源：'..table.concat(g.missing,'、')
    else
        local p=Effects.preview(c.id,g.counts,g.inputs,0)
        lines[#lines+1]=isUpgrade(c) and ('当前升级 '..p.currentCount..' 级') or ('当前同卡累计 '..p.currentCount..' 份')
        lines[#lines+1]='当前：'..p.current.text
        lines[#lines+1]='叠加方式：'..(p.stacking or '待核实')
        if not isUpgrade(c) then lines[#lines+1]='大厅装备份数上限：'..c.maxAvailable..'（不是任务效果上限）' end
        lines[#lines+1]='效果上限：'..(p.effectCap or (p.status=='unresolved' and '待核实' or '已核对路径未发现单卡上限'))
        if p.conditions then lines[#lines+1]=p.conditions end
        if p.status~='verified' then lines[#lines+1]=statusText[p.status] end
    end
    page.detail=(L.card(c.id,'description') or c.description)..'\n\n'..L.text(table.concat(lines,'\n\n'))
    return page
end

-- UMG presentation and the search panel's temporary input focus.
local function valid(o)
    local ok,value=pcall(function() return o and o:IsValid() end);return ok and value
end
local function color(r,g,b,a) return {R=r,G=g,B=b,A=a or 1} end
function P.layout(viewport)
    local dpi=viewport.dpiScale or 1
    local screenW,screenH=viewport.width/dpi,viewport.height/dpi
    local margin=math.max(4,math.min(24,math.floor(math.min(screenW,screenH)*.025)))
    local w,h=math.min(1080,screenW-margin*2),math.min(680,screenH-margin*2)
    local compact=w<960 or h<600
    local pad,gap=compact and 16 or 24,compact and 16 or 30
    local listWidth=math.min(316,math.floor((w-pad*2-gap)*.32))
    local top=compact and 124 or 112
    local navY=h-78;local area=math.max(24,navY-top-10)
    local rows=math.max(1,math.min(10,math.floor((area+4)/(compact and 40 or 48))))
    local rowHeight=math.min(44,math.floor((area-(rows-1)*4)/rows))
    local navWidth=math.floor((listWidth-12)/4)
    return {width=w,height=h,margin=margin,dpiScale=dpi,compact=compact,pad=pad,gap=gap,
        listWidth=listWidth,detailX=pad+listWidth+gap,detailWidth=w-(pad+listWidth+gap)-gap,
        bodyTop=top,detailHeight=math.max(24,h-top-28),navY=navY,navWidth=navWidth,
        rows=rows,rowHeight=rowHeight,rowGap=4,titleSize=compact and 18 or 26,
        listSize=compact and 14 or 16,listTextSize=compact and 14 or 17,detailSize=compact and 16 or 18,hintSize=compact and 12 or 16,
        controlSize=math.min(18,math.max(8,math.floor((navWidth-16)/1.8)))}
end
local function viewport(controller)
    local ok,result=pcall(function()
        local lib=StaticFindObject('/Script/UMG.WidgetLayoutLibrary'):GetCDO()
        local size,dpi=lib:GetViewportSize(controller),lib:GetViewportScale(controller)
        if size.X>0 and size.Y>0 and dpi>0 then return {width=size.X,height=size.Y,dpiScale=dpi} end
    end)
    return ok and result or {width=1280,height=800,dpiScale=1}
end
function P.refreshLayout(view)
    local layout=P.layout(viewport(view.getController()))
    local old=view.layout
    if old and old.width==layout.width and old.height==layout.height and old.dpiScale==layout.dpiScale then return old end
    view.layout=layout
    local function place(widget,x,y,w,h,size)
        widget.Slot:SetPosition({X=x,Y=y});widget.Slot:SetSize({X=w,Y=h})
        if size then local f=widget.Font;f.Size=size;widget:SetFont(f) end
    end
    local w,h,p=layout.width,layout.height,layout.pad
    place(view.background,0,0,w,h)
    place(view.title,p,layout.compact and 10 or 18,w-p*2-102,layout.compact and 60 or 46,layout.titleSize)
    place(view.hint,p,layout.compact and 76 or 63,w-p*2,layout.compact and 36 or 32,layout.hintSize)
    place(view.list,p,layout.bodyTop,layout.listWidth,layout.detailHeight,layout.listTextSize)
    place(view.detailScroll,layout.detailX,layout.bodyTop,layout.detailWidth,layout.detailHeight)
    local f=view.detail.Font;f.Size=layout.detailSize;view.detail:SetFont(f)
    place(view.search,p,layout.bodyTop-4,layout.listWidth,40)
    place(view.pageLabel,p,h-36,layout.listWidth,24,layout.compact and 12 or 14)
    view.widget:SetDesiredSizeInViewport({X=w,Y=h})
    -- Position and desired size are logical Slate units; do not divide by DPI twice.
    view.widget:SetPositionInViewport({X=layout.margin,Y=layout.margin},false)
    return layout
end
function P.setNoBonusText(parent,tree,source,text,visible)
    if visible and not valid(text) then
        assert(valid(parent) and valid(tree),'无加成文字缺少描述容器')
        text=StaticConstructObject(StaticFindObject('/Script/UMG.TextBlock'),tree)
        assert(valid(text),'创建无加成文字失败')
        text:SetFont(source.Font);text:SetAutoWrapText(true)
        local tint=text.ColorAndOpacity;tint.SpecifiedColor=color(1,.2,.2);text:SetColorAndOpacity(tint)
        parent:AddChild(text)
    end
    if valid(text) then text:SetText(FText(L.text('无加成')));text:SetVisibility(visible and 3 or 2) end
    return text
end
function P.setSearchInput(view,active)
    if view.mouse then
        if active then view.mouse:show(view.search) else view.mouse:hide() end
        return
    end
    local prior=view.searchInput
    if active and not prior then
        local controller=require('UEHelpers').GetPlayerController()
        assert(valid(controller) and valid(view.search),'搜索输入尚未就绪')
        prior={controller=controller,cursor=controller.bShowMouseCursor==true}
        view.searchInput=prior
        controller.bShowMouseCursor=true
        if prior.cursor then
            -- A game menu already owns input. Give its mode to the search field
            -- without replacing that mode, and release only focus on close.
            view.search:SetUserFocus(controller)
        else view.library:SetInputMode_GameAndUIEx(controller,view.search,0,false,false) end
    elseif not active and prior then
        if valid(prior.controller) then
            if prior.cursor then view.library:SetFocusToGameViewport()
            else view.library:SetInputMode_GameOnly(prior.controller,false) end
            prior.controller.bShowMouseCursor=prior.cursor
        end
        view.searchInput=nil
    end
end
function P.createView(query,onAction,options)
    options=options or {}
    local getController=options.getController or require('UEHelpers').GetPlayerController
    local controller=options.context and options.context.controller or getController()
    local host=StaticFindObject('/Game/Interfaces/UI_Joker_Informations.UI_Joker_Informations_C')
    local library=StaticFindObject('/Script/UMG.WidgetBlueprintLibrary')
    assert(valid(controller) and valid(host) and valid(library),'玩家控制器或 UMG 宿主未加载')
    local widget=library:GetCDO():Create(controller,host,controller)
    if options.isCurrent and not options.isCurrent() then return end
    assert(valid(widget),'创建奇术卡面板失败')
    widget.bHasScriptImplementedPaint=false;widget.bIsFocusable=true
    local tree=widget.WidgetTree
    local inheritedVisibility=tree.RootWidget.Visibility
    local canvas=StaticConstructObject(StaticFindObject('/Script/UMG.CanvasPanel'),tree)
    assert(valid(canvas),'创建奇术卡 CanvasPanel 失败')
    canvas.Visibility=inheritedVisibility;tree.RootWidget=canvas
    local textClass=StaticFindObject('/Script/UMG.TextBlock')
    local barClass=StaticFindObject('/Script/UMG.ProgressBar')
    local font=StaticFindObject('/Game/Materials/Fonts/Font_Text.Font_Text')
    assert(valid(font) and valid(textClass) and valid(barClass),'UMG 字体或控件类未加载')
    local function place(o,x,y,w,h)
        assert(valid(o),'创建 UMG 控件失败')
        local slot=canvas:AddChildToCanvas(o)
        slot:SetPosition({X=x,Y=y});slot:SetSize({X=w,Y=h})
        return o
    end
    local background=place(StaticConstructObject(barClass,tree),0,0,1080,680)
    background:SetPercent(1);background:SetFillColorAndOpacity(color(.025,.035,.05,.98))
    local function label(x,y,w,h,size)
        local text=place(StaticConstructObject(textClass,tree),x,y,w,h)
        local fi=text.Font;fi.FontObject=font;fi.Size=size;text:SetFont(fi)
        local tint=text.ColorAndOpacity;tint.SpecifiedColor=color(.94,.95,.97);text:SetColorAndOpacity(tint)
        text:SetAutoWrapText(true)
        return text
    end
    local view={widget=widget,root=canvas,background=background,getController=getController,
        getContext=options.getContext,contextKey=options.context and options.context.ownerKey,
        title=label(24,18,930,46,26),hint=label(24,63,1030,32,16),
        list=label(24,112,316,540,17),detail=label(370,112,680,540,18)}
    -- The same width and position keep the F7 detail layout. The F4 preview
    -- can add a separately colored status below the ordinary description.
    view.tree=tree;view.library=library:GetCDO()
    view.detailScroll=place(StaticConstructObject(StaticFindObject('/Script/UMG.ScrollBox'),tree),370,112,680,540)
    view.detailScroll:SetVisibility(0)
    view.detailBox=StaticConstructObject(StaticFindObject('/Script/UMG.VerticalBox'),tree)
    view.detailScroll:AddChild(view.detailBox)
    canvas:RemoveChild(view.detail);view.detailBox:AddChild(view.detail)
    view.detail:SetVisibility(3);view.detailBox:SetVisibility(4)
    -- Lazy loading preserves Panel.description's pure use in the desktop bridge.
    view.mouse=require('MousePanel').new({host=widget,root=canvas,tree=tree,font=font,controller=controller,
        library=view.library,onAction=onAction,getController=getController})
    view.pageLabel=label(24,644,316,24,14)
    local search=StaticConstructObject(StaticFindObject('/Script/UMG.EditableTextBox'),tree)
    assert(valid(search),'创建卡牌搜索框失败')
    -- EditableTextBox in UE5.8 stores its font in WidgetStyle.TextStyle.
    -- Configure reflected properties before the Slate widget is constructed.
    search.WidgetStyle.TextStyle.Font=view.list.Font
    search.WidgetStyle.BackgroundColor.SpecifiedColor=color(.06,.08,.12)
    search.ClearKeyboardFocusOnCommit=false;search.SelectAllTextWhenFocused=true
    search:SetHintText(FText(L.text('搜索卡名 / 英文 ID')));search:SetText(FText(query or ''))
    search:SetForegroundColor(color(.94,.95,.97))
    view.search=place(search,24,108,316,40);search:SetVisibility(2)
    canvas:SetVisibility(4)
    view.hint:SetText(FText(L.text('F7 显示／隐藏   F5 上一项   F6 下一项   每秒刷新；仅显示，不更改装备')))
    P.refreshLayout(view)
    widget:SetColorAndOpacity(color(1,1,1,0))
    widget:SetVisibility(2)
    widget:AddToViewport(9950)
    if options.isCurrent and not options.isCurrent() then P.destroyView(view,true);return end
    return view
end
function P.render(view,page,visible,layout)
    if not P.isViewCurrent(view) then P.destroyView(view,true);return false end
    if not visible then P.hideView(view);return true end
    assert(valid(view.widget),'面板已失效')
    layout=layout or P.refreshLayout(view)
    view.title:SetText(FText(page.title))
    local hint=layout.compact and L.choose('F7 开关 · F5/F6 选卡 · Shift 翻页','F7 Toggle · F5/F6 Select · Shift Page') or
        L.choose('点击选卡／翻页；详情区滚轮滚动   F7 开关   F5/F6 选卡   Shift 翻页',
        'Click cards / pages; scroll details   F7 Toggle   F5/F6 Select   Shift Page')
    view.hint:SetText(FText(page.hint or hint))
    view.list:SetText(FText(page.list))
    view.detail:SetText(FText(page.plainDetail or page.detail))
    view.noBonusText=P.setNoBonusText(view.detailBox,view.tree,view.detail,view.noBonusText,page.noBonus)
    local searching=visible and page.searchable and valid(view.search)
    if valid(view.search) then
        view.search:SetHintText(FText(page.inputHint or L.text('搜索卡名 / 英文 ID')))
        view.search:SetVisibility(searching and 0 or 2)
        view.list.Slot:SetPosition({X=layout.pad,Y=layout.bodyTop+(page.searchable and 50 or 0)})
        view.list.Slot:SetSize({X=layout.listWidth,Y=layout.detailHeight-(page.searchable and 50 or 0)})
    end
    view.list:SetVisibility(page.searchable and 3 or 2)
    local controls=not page.searchable
    for index=1,10 do
        local row=(page.rows or {})[index]
        view.mouse:button('row-'..index,{text=row and (row.buttonText or row.text) or '',action='select',value=row and row.index,
            selected=row and row.selected,visible=controls and row~=nil and index<=layout.rows,x=layout.pad,
            y=layout.bodyTop+(index-1)*(layout.rowHeight+layout.rowGap),width=layout.listWidth,height=layout.rowHeight,size=layout.listSize})
    end
    local count=page.count or 0
    for _,control in ipairs({
        {'previousPage','<<',page.pageNumber and page.pageNumber>1},
        {'previous','<',count>0 and page.index>1},
        {'next','>',count>0 and page.index<count},
        {'nextPage','>>',page.pageNumber and page.pageNumber<page.pageCount},
    }) do
        local index=({previousPage=0,previous=1,next=2,nextPage=3})[control[1]]
        view.mouse:button(control[1],{text=control[2],action=control[1],enabled=control[3]==true,visible=controls,
            x=layout.pad+index*(layout.navWidth+4),y=layout.navY,width=layout.navWidth,height=34,size=layout.controlSize})
    end
    view.mouse:button('close',{text=L.choose('关闭','Close'),action='close',x=layout.width-layout.pad-90,
        y=layout.compact and 10 or 18,width=90,height=36,size=layout.compact and 14 or 16})
    view.pageLabel:SetText(FText(controls and string.format(L.choose('第 %d / %d 页','Page %d / %d'),page.pageNumber or 1,page.pageCount or 1) or ''))
    local selected=page.selected
    local detailKey=selected and selected.card and ((selected.group and selected.group.itemName or '')..':'..selected.card.id) or page.index
    if view.detailKey~=detailKey then view.detailScroll:SetScrollOffset(0);view.detailKey=detailKey end
    -- SelfHitTestInvisible lets native buttons and the ScrollBox receive mouse
    -- input; Collapsed removes every hidden hit target.
    view.widget:SetVisibility(visible and 4 or 2)
    view.widget:SetColorAndOpacity(color(1,1,1,visible and 1 or 0))
    if visible then view.mouse:show(searching and view.search or view.widget) else view.mouse:hide() end
end
function P.isViewCurrent(view)
    if not view or view.disposed or not view.mouse then return false end
    if view.getContext then
        local context=view.getContext()
        if not context or context.ownerKey~=view.contextKey then return false end
        return view.mouse:isCurrent(context.controller)
    end
    return view.getController~=nil and view.mouse:isCurrent(view.getController())
end
function P.hideView(view)
    if not P.isViewCurrent(view) then P.destroyView(view,true);return false end
    if view.mouse then view.mouse:hide() else P.setSearchInput(view,false) end
    local ok=pcall(function() view.widget:SetVisibility(2) end)
    if not ok then P.destroyView(view,true) end
    return ok
end
function P.destroyView(view,abandon,refreshInput)
    if not view or view.disposed then return end
    if abandon==nil then abandon=not P.isViewCurrent(view) end
    view.disposed=true
    if view.mouse then
        view.mouse.options.onAction=nil
        -- A new pawn can retire its menu while the viewport widgets survive.
        -- Release input through the fresh controller, then remove current UI.
        if refreshInput then view.mouse:hide(true) end
        view.mouse:dispose(abandon)
    elseif not abandon then P.setSearchInput(view,false) end
    if not abandon then
        -- Lua binding failures must not interrupt later cleanup; this does not
        -- catch or claim to prevent native C++ access violations.
        pcall(function() if valid(view.widget) then view.widget:SetVisibility(2) end end)
        pcall(function() if valid(view.widget) then view.widget:RemoveFromParent() end end)
    end
end
function P.retireLegacyView(view,context)
    local mouse=view.mouse
    local sameController=context and mouse and mouse.controllerKey==context.controllerKey
    local sameOwner=sameController and mouse.worldKey==context.worldKey
    if mouse then
        local original=mouse.buttons or {}
        local routesOnly={}
        for key,entry in pairs(original) do routesOnly[key]={routeKey=entry.routeKey} end
        local currentMenu=sameController and Inventory.field(context.pawn,'refBpMenu') or nil
        if mouse.menu~=currentMenu then mouse.priorUiMode=Inventory.field(currentMenu,'isUiMode')==true end
        mouse.options.controller=sameController and context.controller or nil
        mouse.options.onAction=nil;mouse.menu=currentMenu
        if not sameOwner then mouse.buttons=routesOnly end
        local ok=pcall(function() mouse:dispose() end)
        if not ok then
            -- beta.4 cleanup could stop at the first missing native binding.
            -- Retry only Lua route/lease removal, with no native object targets.
            mouse.options.controller=nil;mouse.menu=nil;mouse.buttons=routesOnly;mouse.active=true
            pcall(function() mouse:dispose() end)
        end
    end
    if sameOwner then
        pcall(function() view.widget:SetVisibility(2) end)
        pcall(function() view.widget:RemoveFromParent() end)
    end
    view.disposed=true
end
P.valid=valid
return P
