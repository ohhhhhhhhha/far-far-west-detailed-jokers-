-- Read-only UE4SS entry point: native descriptions and F7 details.
-- Private module loader also allows dofile smoke tests in another mod's Lua VM.
local directory=debug.getinfo(1,'S').source:sub(2):gsub('\\','/'):match('^(.*)/')
assert(directory,'FFWJokerInfo needs a file-backed entry point')
local modules,environment={},nil
local allowed={Cards=true,Effects=true,Inventory=true,Panel=true,HeroRules=true,WeaponRules=true,UpgradeRules=true,Locale=true,MousePanel=true,Scope=true}
local globalRequire=require
environment=setmetatable({require=function(name)
    if not allowed[name] then return globalRequire(name) end
    if not modules[name] then modules[name]=assert(loadfile(directory..'/'..name..'.lua','t',environment))() end
    return modules[name]
end},{__index=_G})
local I=environment.require('Inventory')
local P=environment.require('Panel')
local L=environment.require('Locale')
local Scope=environment.require('Scope')
local previous=_G.FFWJokerInfo
local S=previous or {visible=false,index=1,restores={},errors=0,patched=0}
if previous and previous.stateSchema~=2 then
    -- Old ExecuteInGameThread closures captured the old table without a token.
    -- Keep it inert rather than letting those closures drive the replacement.
    S={visible=false,index=previous.index or 1,restores={},errors=previous.errors or 0,patched=previous.patched or 0,
        instance=previous.instance or 0,epoch=previous.epoch or 0,
        keysInstalled=previous.keysInstalled,loopInstalled=previous.loopInstalled,
        travelHooksInstalled=previous.travelHooksInstalled,uiHooks=previous.uiHooks,
        legacy={view=previous.view,restores=previous.restores or {}}}
    previous.enabled=false;previous.visible=false;previous.view=nil;previous.snapshot=nil;previous.restores={};previous.uiHooks={}
    local noop=function() end
    for _,name in ipairs({'update','prepareView','status','toggle','hide','move','mouse','refreshWidget','stop'}) do previous[name]=noop end
    previous.page=function() return {index=1,pageNumber=1,pageCount=1,pageSize=10,rows={}} end
end
S.stateSchema=2
_G.FFWJokerInfo=S
S.enabled=true;S.Inventory=I;S.Panel=P;S.Effects=environment.require('Effects');S.Cards=environment.require('Cards')
S.instance=(S.instance or 0)+1;S.epoch=S.epoch or 0
local function log(s) print('[FFWJokerInfo] '..s..'\n') end
local function reportError(err)
    S.errors=S.errors+1
    if S.lastError~=tostring(err) then S.lastError=tostring(err);log('ERROR '..S.lastError) end
end
local function stringValue(v)
    if type(v)=='string' then return v end
    local ok,text=pcall(function() return v:ToString() end)
    if ok and type(text)=='string' then return text end
end
local function className(widget)
    -- GetFullName starts with the actual class; the remainder can contain any
    -- number of differently typed outer widgets (notably the pickup selector).
    return widget:GetFullName():match('^(%S+)')
end
function S.invalidate(sameOwner)
    S.epoch=S.epoch+1;S.visible=false
    local view=S.view;S.view=nil
    S.context=nil;S.snapshot=nil;S.uiContexts={};S.tooltipOwners={}
    if not sameOwner then S.restores={};S.ownerKey=nil end
    I.resetContext()
    if view then P.destroyView(view,not sameOwner,sameOwner) end
end
function S.beginTravel() S.loading=true;S.invalidate() end
function S.endTravel() S.loading=false end
function S.checkContext()
    if not S.enabled or S.loading or S.migrating then return end
    local owner=Scope.owner();local context=Scope.read(owner)
    if S.legacy then
        local legacy=S.legacy;S.legacy=nil;S.migrating=true
        local adopted={}
        if owner then
            for _,text in ipairs(FindAllOf('TextBlock') or {}) do
                if Scope.matches(text,owner) then
                    local key=text:GetFullName();local record=legacy.restores[key]
                    if record and record.widget==text and (not record.scroll or text:GetParent()==record.scroll) then
                        record.scopeKey=owner.ownerKey;adopted[key]=record
                    end
                end
            end
        end
        local epoch=S.epoch
        if legacy.view then P.retireLegacyView(legacy.view,owner) end
        S.migrating=false
        if S.loading or S.epoch~=epoch then return end
        S.restores=adopted
        S.ownerKey=owner and owner.ownerKey
    end
    if not context then
        local sameOwner=owner and owner.ownerKey==S.ownerKey
        if S.context or S.view or S.snapshot or (S.ownerKey and not sameOwner) then S.invalidate(sameOwner) end
        S.ownerKey=owner and owner.ownerKey
        return
    end
    if S.ownerKey and S.ownerKey~=context.ownerKey then S.invalidate()
    elseif S.context and S.context.key~=context.key then S.invalidate(true) end
    S.ownerKey=context.ownerKey
    S.context=context;return context
end
local observeBelowHeal=I.observeBelowHeal
I.observeBelowHeal=function(component,gameInstance)
    -- beta.4's old listener can exist until its function is safely re-registered.
    -- Guard at the receiver too, before any reflected call on its component.
    if not S.enabled or S.loading or S.migrating then return false end
    local context=S.checkContext()
    if not context or not Scope.matches(component,context) then return false end
    return observeBelowHeal(component,gameInstance or context.gameInstance)
end
local function enqueue(action,view)
    local instance,epoch,key=S.instance,S.epoch,S.context and S.context.key
    ExecuteInGameThread(function()
        if not S.enabled or S.loading or S.instance~=instance or S.epoch~=epoch then return end
        local ok,err=pcall(function()
            local context=S.checkContext()
            if not context or S.instance~=instance or S.epoch~=epoch or (key and key~=context.key) then return end
            if view and S.view~=view then return end
            action(context)
        end)
        if not ok then reportError(err) end
    end)
end
local function fitDescription(widget,text,kind,record)
    local font=I.field(text,'Font');local size=I.field(font,'Size')
    if type(size)~='number' then return end
    record.fontSize=record.fontSize or size
    font.Size=math.min(record.fontSize,15);text:SetFont(font)
    local cardBox,width
    if className(widget)=='UI_JokerCard_InGame_C' then
        cardBox=I.field(I.field(widget,'WidgetTree'),'RootWidget');width=kind=='pickup' and 300 or 340
    elseif kind=='equip' then
        local holder=I.field(widget,'VerticalBox_Holder')
        if P.valid(holder) then cardBox=holder:GetChildAt(0);width=I.field(cardBox,'WidthOverride') end
    end
    if P.valid(cardBox) and type(width)=='number' then
        if not record.cardBox then
            record.cardBox=cardBox;record.cardWidth=I.field(cardBox,'WidthOverride');record.cardHeight=I.field(cardBox,'HeightOverride')
        end
        cardBox:SetWidthOverride(width);cardBox:SetHeightOverride(kind=='current' and 580 or 500)
    end
    -- A private-module reload may reuse records made before these fields existed.
    -- Capture their original values before either layout path changes them.
    if record.justification==nil then record.justification=I.field(text,'Justification') end
    if not record.translation then
        local translation=I.field(I.field(text,'RenderTransform'),'Translation')
        if translation then record.translation={X=translation.X,Y=translation.Y} end
    end
    if record.scroll and P.valid(record.scroll) then
        record.descriptionBox:SetWidthOverride(width and width-90 or 300)
        record.descriptionBox:SetHeightOverride(kind=='current' and 340 or 260)
        text:SetJustification(0)
        text:SetRenderTranslation({X=0,Y=0})
        return
    end
    -- The original TextBlock stays in the original description area. Its parent
    -- is a VerticalBox and the description is its final child in all three
    -- verified widget assets. A bounded ScrollBox avoids growing beyond screen.
    local parent=text:GetParent();local tree=I.field(widget,'WidgetTree')
    local scrollClass=StaticFindObject('/Script/UMG.ScrollBox');local sizeClass=StaticFindObject('/Script/UMG.SizeBox')
    if not P.valid(parent) or not P.valid(tree) or not P.valid(scrollClass) or not P.valid(sizeClass) then return end
    local box=StaticConstructObject(sizeClass,tree);local scroll=StaticConstructObject(scrollClass,tree)
    assert(P.valid(box) and P.valid(scroll),'创建原描述滚动区失败')
    box:SetWidthOverride(width and width-90 or 300)
    box:SetHeightOverride(kind=='current' and 340 or 260)
    local oldSlot=I.field(text,'Slot');local padding=I.field(oldSlot,'Padding')
    if padding then record.padding={Left=padding.Left,Top=padding.Top,Right=padding.Right,Bottom=padding.Bottom} end
    record.horizontalAlignment=I.field(oldSlot,'HorizontalAlignment')
    record.autoWrap=I.field(text,'AutoWrapText')
    parent:RemoveChild(text);box:AddChild(scroll)
    local scrollSlot=scroll:AddChild(text)
    scrollSlot:SetHorizontalAlignment(0)
    scrollSlot:SetPadding({Left=0,Top=0,Right=12,Bottom=6})
    local boxSlot=parent:AddChild(box)
    boxSlot:SetHorizontalAlignment(2)
    text:SetAutoWrapText(true)
    text:SetJustification(0)
    text:SetRenderTranslation({X=0,Y=0})
    record.descriptionParent=parent;record.descriptionBox=box;record.scroll=scroll
end
local function patch(widget,snapshot,kind)
    if not Scope.matches(widget,S.context) then return end
    local fullName=widget:GetFullName()
    if fullName:find('Default__',1,true) then return end
    local visibleOk,visible=pcall(function() return widget:IsVisible() end)
    if visibleOk and not visible then return end
    local id=I.name(I.field(widget,'jokerName'))
    if not S.Cards.get(id) then return end
    local item=I.name(I.field(widget,'itemName')) or I.name(I.field(widget,'ItemName'))
    if item and (item=='' or item:lower()=='none') then item=nil end
    local text=I.field(widget,'TextBlock_Description');local textHost=widget
    if kind=='slot' then
        local button=I.field(widget,'Button_Tweak')
        textHost=I.field(button,'ToolTipWidget')
        text=I.field(textHost,'TextBlock_Description')
        kind='current'
    end
    if not P.valid(text) then return end
    local current=stringValue(text:GetText())
    if not current then return end
    local changed,style=P.description(id,snapshot,item,kind,current)
    local noBonus=style and style.noBonus or false
    local displayed=noBonus and style.plainText or changed
    local key=text:GetFullName();local record=S.restores[key]
    if displayed and (displayed~=current or not record or record.kind~=kind or record.noBonus~=noBonus
        or (noBonus and not P.valid(record.noBonusText))) then
        record=record or {widget=text,scopeKey=S.context.ownerKey};S.restores[key]=record
        local fitOk,fitError=pcall(function()
            fitDescription(textHost,text,kind,record)
            record.noBonusText=P.setNoBonusText(record.scroll,I.field(textHost,'WidgetTree'),text,record.noBonusText,noBonus)
        end)
        if fitOk then
            text:SetText(FText(displayed));record.kind=kind;record.noBonus=noBonus
        else
            text:SetText(FText(changed));reportError('description layout: '..tostring(fitError))
        end
        S.patched=S.patched+1
        S.patchedByKind=S.patchedByKind or {};S.patchedByKind[kind]=(S.patchedByKind[kind] or 0)+1
    end
end
function S.scan(snapshot)
    if not S.enabled or S.loading or not S.context then return end
    local contexts={}
    local function mark(widget,kind)
        if Scope.matches(widget,S.context) then contexts[widget:GetFullName()]=kind end
    end
    -- Tab icons create the SAME card class used by the pickup selector. The
    -- owning widget is the evidence for current versus hypothetical +1 values.
    for _,owner in ipairs(FindAllOf('UI_Joker_InGameOnScreen_C') or {}) do
        if Scope.matches(owner,S.context) then mark(I.field(I.field(owner,'SizeBox_35'),'ToolTipWidget'),'current') end
    end
    for _,owner in ipairs(FindAllOf('UI_ObtainedJoker_C') or {}) do
        if Scope.matches(owner,S.context) then mark(I.field(owner,'UI_JokerCard_InGame'),'current') end
    end
    for _,owner in ipairs(FindAllOf('UI_SelectableJoker_C') or {}) do
        local ok,child=pcall(function() if Scope.matches(owner,S.context) then return I.field(owner,'Button_Joker'):GetChildAt(0) end end)
        if ok then mark(child,'pickup') end
    end
    S.uiContexts=contexts
    S.tooltipOwners={}
    for _,descriptor in ipairs({{'UI_JokerCard_C','equip'},{'UI_JokerCard_InGame_C','current'},{'UI_Joker_Slot_C','slot'}}) do
        local found=FindAllOf(descriptor[1]) or {}
        for _,widget in ipairs(found) do
            if Scope.matches(widget,S.context) then
            if descriptor[2]=='slot' then
                local tooltip=I.field(I.field(widget,'Button_Tweak'),'ToolTipWidget')
                if P.valid(tooltip) then S.tooltipOwners[tooltip:GetFullName()]=widget end
            end
            local kind=contexts[widget:GetFullName()] or descriptor[2]
            local ok,err=pcall(patch,widget,snapshot,kind)
            if not ok then reportError(err) end
            end
        end
    end
end
function S.refreshWidget(widget)
    if not S.checkContext() or not Scope.matches(widget,S.context) then return end
    local snapshot=S.snapshot
    if not snapshot then snapshot=I.read(S.context);S.snapshot=snapshot end
    S.uiContexts=S.uiContexts or {};S.tooltipOwners=S.tooltipOwners or {}
    local full=widget:GetFullName();local class=className(widget);local target,kind=widget,nil
    if class=='UI_Joker_InGameOnScreen_C' then
        target=I.field(I.field(widget,'SizeBox_35'),'ToolTipWidget');kind='current'
    elseif class=='UI_SelectableJoker_C' then
        local button=I.field(widget,'Button_Joker')
        if not P.valid(button) then return end
        target=button:GetChildAt(0);kind='pickup'
    elseif class=='UI_ObtainedJoker_C' then
        target=I.field(widget,'UI_JokerCard_InGame');kind='current'
    elseif class=='UI_Joker_Slot_C' then
        local tooltip=I.field(I.field(widget,'Button_Tweak'),'ToolTipWidget')
        if P.valid(tooltip) then S.tooltipOwners[tooltip:GetFullName()]=widget end
        kind='slot'
    elseif class=='UI_EpicTweakTooltip_C' then
        target=S.tooltipOwners[full];kind='slot'
    elseif class=='UI_JokerCard_InGame_C' then kind=S.uiContexts[full] or 'current'
    elseif class=='UI_JokerCard_C' then kind='equip' end
    if kind and Scope.matches(target,S.context) then
        if kind=='pickup' or kind=='current' then S.uiContexts[target:GetFullName()]=kind end
        patch(target,snapshot,kind)
    end
end
S.uiHooks=S.uiHooks or {}
local belowHealPath='/Game/Spells/Jokers/AC_PlayerStateJoker.AC_PlayerStateJoker_C:F_TriggerJokerBelowHeal'
local uiHookPaths={
    '/Game/Interfaces/Tweaks/UI_JokerCard.UI_JokerCard_C:F_Update',
    '/Game/Interfaces/Tweaks/UI_JokerCard_InGame.UI_JokerCard_InGame_C:Construct',
    '/Game/Interfaces/Tweaks/UI_JokerCard_InGame.UI_JokerCard_InGame_C:F_Refresh',
    '/Game/Interfaces/Tweaks/UI_Joker_InGameOnScreen.UI_Joker_InGameOnScreen_C:Construct',
    '/Game/Interfaces/Tweaks/UI_SelectableJoker.UI_SelectableJoker_C:Construct',
    '/Game/Interfaces/Tweaks/UI_ObtainedJoker.UI_ObtainedJoker_C:Construct',
    '/Game/Interfaces/Equipment/UI_Joker_Slot.UI_Joker_Slot_C:F_Refresh',
    '/Game/Interfaces/Equipment/UI_EpicTweakTooltip.UI_EpicTweakTooltip_C:PreConstruct',
    belowHealPath,
}
function S.registerUiHooks()
    if type(RegisterHook)~='function' or type(StaticFindObject)~='function' then return end
    for _,path in ipairs(uiHookPaths) do
        local fn=StaticFindObject(path)
        if P.valid(fn) then
            local address=fn:GetAddress();local old=S.uiHooks[path]
            if not old or old.address~=address or old.instance~=S.instance then
                if old and old.address==address then pcall(UnregisterHook,path,old.pre,old.post) end
                local listener=S.instance
                local ok,pre,post=pcall(RegisterHook,path,function(context)
                    local current=_G.FFWJokerInfo
                    if current and current.enabled and not current.loading and not current.migrating and current.instance==listener
                        and (path==belowHealPath or not current.updating) then
                        -- A shop can construct many cards in one frame. Refresh
                        -- just this widget using the last snapshot; the 1s poll
                        -- remains the sole periodic full inventory/UI scan.
                        local success,err=pcall(function()
                            if not current.checkContext() then return end
                            local object=context:get()
                            if not Scope.matches(object,current.context) then return end
                            if path==belowHealPath then current.Inventory.observeBelowHeal(object,current.context.gameInstance)
                            else current.refreshWidget(object) end
                        end)
                        if not success then reportError(err) end
                    end
                end)
                if ok then S.uiHooks[path]={address=address,pre=pre,post=post,instance=listener} else reportError(pre) end
            end
        end
    end
end
local function ensureView()
    if not P.isViewCurrent(S.view,S.context) then
        if S.view then local old=S.view;S.view=nil;P.destroyView(old,true) end
        local view;local epoch,key=S.epoch,S.context.key
        local function current() return S.enabled and not S.loading and S.epoch==epoch and S.context and S.context.key==key end
        view=P.createView(nil,function(action,value)
            if S.view==view then S.mouse(action,value) end
        end,{context=S.context,getController=Scope.controller,getContext=Scope.read,isCurrent=current})
        if not current() then if view then P.destroyView(view,true) end;return end
        S.view=view
    end
end
function S.update()
    if not S.enabled or S.updating then return end
    if not S.checkContext() then return end
    local epoch,context=S.epoch,S.context
    local function current() return S.enabled and not S.loading and S.epoch==epoch and S.context and S.context.key==context.key end
    S.updating=true
    local success,failure=pcall(function()
    L.refresh()
    if not current() then return end
    S.registerUiHooks()
    if not current() then return end
    local ok,snapshot=pcall(I.read,context)
    if not current() then return end
    if not ok then reportError(snapshot);snapshot=I.fromSnapshot({}) end
    S.snapshot=snapshot
    S.scan(snapshot)
    if S.visible and current() then
        ensureView()
        if current() and S.view then
            local layout=P.refreshLayout(S.view)
            P.render(S.view,S.page(snapshot),true,layout)
        end
    end
    end)
    S.updating=false
    if not success then error(failure) end
end
function S.page(snapshot)
    local page=P.page(snapshot,S.index,S.view and S.view.layout and S.view.layout.rows);S.index=page.index
    return page
end
function S.uiStatus()
    if not S.checkContext() then return end
    for _,class in ipairs({'UI_JokerCard_C','UI_JokerCard_InGame_C','UI_Joker_Slot_C'}) do
        for _,widget in ipairs(FindAllOf(class) or {}) do
            if Scope.matches(widget,S.context) and not widget:GetFullName():find('Default__',1,true) then
                local kind=(S.uiContexts or {})[widget:GetFullName()] or (class=='UI_JokerCard_C' and 'equip' or 'current')
                local target=I.field(widget,'TextBlock_Description')
                if class=='UI_Joker_Slot_C' then target=I.field(I.field(I.field(widget,'Button_Tweak'),'ToolTipWidget'),'TextBlock_Description') end
                local text=P.valid(target) and stringValue(target:GetText()) or ''
                log('UI '..kind..' '..tostring(I.name(I.field(widget,'jokerName')))..' appended='..tostring(text:find(P.heading,1,true)~=nil)..' '..widget:GetFullName())
            end
        end
    end
end
function S.prepareView()
    if not S.checkContext() then return end
    ensureView()
    if S.view then P.render(S.view,S.page(S.snapshot or I.fromSnapshot({})),S.visible) end
end
function S.toggle()
    enqueue(function()
        S.visible=not S.visible
        if S.visible then S.update()
        elseif S.view then P.hideView(S.view) end
    end)
end
function S.hide()
    enqueue(function()
        S.visible=false
        if S.view then P.hideView(S.view) end
    end)
end
function S.mouse(action,value)
    if not S.enabled or not S.visible then return end
    if action=='close' then S.hide();return end
    if action=='previous' or action=='next' then S.move(action=='previous' and -1 or 1);return end
    enqueue(function()
            if not S.visible then return end
            if action=='select' and type(value)=='number' then S.index=value
            elseif action=='previousPage' or action=='nextPage' then
                local page=S.page(S.snapshot)
                local number=math.max(1,math.min(page.pageCount,page.pageNumber+(action=='previousPage' and -1 or 1)))
                S.index=(number-1)*page.pageSize+1
            else return end
            S.update()
    end,S.view)
end
function S.move(delta,pages)
    if not S.visible then return end
    enqueue(function()
            if not S.visible then return end
            S.index=S.index+delta*(pages and S.page(S.snapshot).pageSize or 1)
            S.update()
    end,S.view)
end
function S.status(verbose)
    local s=S.snapshot or I.fromSnapshot({})
    log('enabled='..tostring(S.enabled)..' visible='..tostring(S.visible)..' complete='..tostring(s.complete)..
        ' missing='..table.concat(s.missing,',')..' patched='..S.patched..' errors='..S.errors..
        ' view='..tostring(S.view~=nil and not S.view.disposed))
    if verbose then
        log('CONTEXT pawn='..tostring(s.context.pawn)..' held='..tostring(s.context.held)..
            ' heldItemName='..tostring(s.inputs.heldItemName)..' buffGravity='..tostring(s.inputs.buffGravity)..
            ' currentGravityScale='..tostring(s.inputs.currentGravityScale))
        for key,err in pairs(s.readErrors) do log('READ '..key..' '..err) end
        for _,g in ipairs(I.groups(s)) do
            local names={};for id,n in pairs(g.counts) do names[#names+1]=id..'='..n end;table.sort(names)
            log('COUNTS '..g.label..' '..g.itemName..' '..table.concat(names,', '))
            local values={};for key,v in pairs(g.inputs) do if type(v)~='table' then
                values[#values+1]=(key=='itemDamage' and 'itemDamage(本任务累计伤害)' or key)..'='..tostring(v)
            end end
            table.sort(values);log('INPUTS '..g.itemName..' '..table.concat(values,', '))
        end
    end
end
function S.stop()
    local current=not S.loading and Scope.owner() or nil
    local same=current and current.ownerKey==S.ownerKey
    local newPawn=same and (not S.context or not Scope.read(current) or current.key~=S.context.key)
    S.enabled=false;S.visible=false;S.instance=S.instance+1
    if S.view then P.destroyView(S.view,not same,newPawn) end
    S.view=nil
    if same then
        for path,h in pairs(S.uiHooks) do pcall(UnregisterHook,path,h.pre,h.post);S.uiHooks[path]=nil end
    end
    for key,record in pairs(S.restores) do
        if same and record.scopeKey==current.ownerKey and P.valid(record.widget) then
            local ok,err=pcall(function()
                local text=stringValue(record.widget:GetText())
                if text then record.widget:SetText(FText(P.stripDescription(text))) end
                if P.valid(record.descriptionParent) and P.valid(record.scroll) then
                    record.descriptionParent:RemoveChild(record.descriptionBox)
                    record.scroll:RemoveChild(record.widget)
                    if P.valid(record.noBonusText) then record.scroll:RemoveChild(record.noBonusText) end
                    local slot=record.descriptionParent:AddChild(record.widget)
                    if record.padding then slot:SetPadding(record.padding) end
                    if record.horizontalAlignment~=nil then slot:SetHorizontalAlignment(record.horizontalAlignment) end
                    if record.autoWrap~=nil then record.widget:SetAutoWrapText(record.autoWrap) end
                    if record.justification~=nil then record.widget:SetJustification(record.justification) end
                    if record.translation then record.widget:SetRenderTranslation(record.translation) end
                end
                if record.fontSize then local font=record.widget.Font;font.Size=record.fontSize;record.widget:SetFont(font) end
                if P.valid(record.cardBox) then
                    if record.cardWidth then record.cardBox:SetWidthOverride(record.cardWidth) end
                    if record.cardHeight then record.cardBox:SetHeightOverride(record.cardHeight) end
                end
            end)
            if not ok then reportError(err) end
        end
        S.restores[key]=nil
    end
    S.snapshot=nil;S.context=nil;S.ownerKey=nil;S.uiContexts={};S.tooltipOwners={};I.resetContext()
end
if not S.travelHooksInstalled and type(RegisterLoadMapPreHook)=='function' and type(RegisterLoadMapPostHook)=='function' then
    RegisterLoadMapPreHook(function()
        local current=_G.FFWJokerInfo;if current and current.enabled then current.beginTravel() end
    end)
    RegisterLoadMapPostHook(function()
        local current=_G.FFWJokerInfo;if current then current.endTravel() end
    end)
    S.travelHooksInstalled=true
end
if not S.keysInstalled then
    RegisterKeyBind(Key.F7,function() _G.FFWJokerInfo.toggle() end)
    for _,key in ipairs({Key.F2,Key.F4,Key.F8}) do
        RegisterKeyBind(key,function() _G.FFWJokerInfo.hide() end)
    end
    RegisterKeyBind(Key.F5,function() _G.FFWJokerInfo.move(-1) end)
    RegisterKeyBind(Key.F6,function() _G.FFWJokerInfo.move(1) end)
    RegisterKeyBind(Key.F5,{ModifierKey.SHIFT},function() _G.FFWJokerInfo.move(-1,true) end)
    RegisterKeyBind(Key.F6,{ModifierKey.SHIFT},function() _G.FFWJokerInfo.move(1,true) end)
    S.keysInstalled=true
end
if not S.loopInstalled then
    LoopInGameThreadWithDelay(1000,function()
        local current=_G.FFWJokerInfo
        if current and current.enabled then
            local ok,err=pcall(current.update)
            if not ok then reportError(err) end
        end
    end)
    S.loopInstalled=true
end
log('loaded, hidden. F7 current cards; F5/F6 select, Shift to page. Formula evidence: static game bytecode.')
return S
