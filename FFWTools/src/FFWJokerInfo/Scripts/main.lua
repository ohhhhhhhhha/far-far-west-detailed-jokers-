-- Read-only UE4SS entry point: native descriptions and F7 details.
-- Private module loader also allows dofile smoke tests in another mod's Lua VM.
local directory=debug.getinfo(1,'S').source:sub(2):gsub('\\','/'):match('^(.*)/')
assert(directory,'FFWJokerInfo needs a file-backed entry point')
local modules,environment={},nil
local allowed={Cards=true,Effects=true,Inventory=true,Panel=true,HeroRules=true,WeaponRules=true,UpgradeRules=true,Locale=true,MousePanel=true}
local globalRequire=require
environment=setmetatable({require=function(name)
    if not allowed[name] then return globalRequire(name) end
    if not modules[name] then modules[name]=assert(loadfile(directory..'/'..name..'.lua','t',environment))() end
    return modules[name]
end},{__index=_G})
local I=environment.require('Inventory')
local P=environment.require('Panel')
local L=environment.require('Locale')
local S=_G.FFWJokerInfo or {visible=false,index=1,restores={},errors=0,patched=0}
_G.FFWJokerInfo=S
S.enabled=true;S.Inventory=I;S.Panel=P;S.Effects=environment.require('Effects');S.Cards=environment.require('Cards')
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
    if record.scroll and P.valid(record.scroll) then
        record.descriptionBox:SetWidthOverride(width and width-90 or 300)
        record.descriptionBox:SetHeightOverride(kind=='current' and 340 or 260)
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
    parent:RemoveChild(text);box:AddChild(scroll);scroll:AddChild(text);parent:AddChild(box)
    text:SetAutoWrapText(true)
    record.descriptionParent=parent;record.descriptionBox=box;record.scroll=scroll
end
local function patch(widget,snapshot,kind)
    if not P.valid(widget) then return end
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
        record=record or {widget=text};S.restores[key]=record
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
    local contexts={}
    local function mark(widget,kind)
        if P.valid(widget) then contexts[widget:GetFullName()]=kind end
    end
    -- Tab icons create the SAME card class used by the pickup selector. The
    -- owning widget is the evidence for current versus hypothetical +1 values.
    for _,owner in ipairs(FindAllOf('UI_Joker_InGameOnScreen_C') or {}) do
        mark(I.field(I.field(owner,'SizeBox_35'),'ToolTipWidget'),'current')
    end
    for _,owner in ipairs(FindAllOf('UI_ObtainedJoker_C') or {}) do
        mark(I.field(owner,'UI_JokerCard_InGame'),'current')
    end
    for _,owner in ipairs(FindAllOf('UI_SelectableJoker_C') or {}) do
        local ok,child=pcall(function() return I.field(owner,'Button_Joker'):GetChildAt(0) end)
        if ok then mark(child,'pickup') end
    end
    S.uiContexts=contexts
    S.tooltipOwners={}
    for _,descriptor in ipairs({{'UI_JokerCard_C','equip'},{'UI_JokerCard_InGame_C','current'},{'UI_Joker_Slot_C','slot'}}) do
        local found=FindAllOf(descriptor[1]) or {}
        for _,widget in ipairs(found) do
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
function S.refreshWidget(widget)
    if not S.enabled or not P.valid(widget) then return end
    local snapshot=S.snapshot
    if not snapshot then snapshot=I.read();S.snapshot=snapshot end
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
    if kind and P.valid(target) then
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
            if not old or old.address~=address then
                if old then pcall(UnregisterHook,path,old.pre,old.post) end
                local ok,pre,post=pcall(RegisterHook,path,function(context)
                    local current=_G.FFWJokerInfo
                    if current and current.enabled and (path==belowHealPath or not current.updating) then
                        -- A shop can construct many cards in one frame. Refresh
                        -- just this widget using the last snapshot; the 1s poll
                        -- remains the sole periodic full inventory/UI scan.
                        local success,err=pcall(function()
                            if path==belowHealPath then current.Inventory.observeBelowHeal(context:get())
                            else current.refreshWidget(context:get()) end
                        end)
                        if not success then reportError(err) end
                    end
                end)
                if ok then S.uiHooks[path]={address=address,pre=pre,post=post} else reportError(pre) end
            end
        end
    end
end
local function ensureView()
    if not P.isViewCurrent(S.view) then
        if S.view then P.destroyView(S.view);S.view=nil end
        S.view=P.createView(nil,function(action,value) S.mouse(action,value) end)
    end
end
function S.update()
    if not S.enabled or S.updating then return end
    S.updating=true
    local success,failure=pcall(function()
    L.refresh()
    S.registerUiHooks()
    local ok,snapshot=pcall(I.read)
    if not ok then reportError(snapshot);snapshot=I.fromSnapshot({}) end
    S.snapshot=snapshot
    S.scan(snapshot)
    if S.visible then
        ensureView()
        P.render(S.view,S.page(snapshot),true)
    end
    end)
    S.updating=false
    if not success then error(failure) end
end
function S.page(snapshot)
    local page=P.page(snapshot,S.index);S.index=page.index
    return page
end
function S.uiStatus()
    for _,class in ipairs({'UI_JokerCard_C','UI_JokerCard_InGame_C','UI_Joker_Slot_C'}) do
        for _,widget in ipairs(FindAllOf(class) or {}) do
            if P.valid(widget) and not widget:GetFullName():find('Default__',1,true) then
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
    ensureView()
    P.render(S.view,S.page(S.snapshot or I.fromSnapshot({})),S.visible)
end
function S.toggle()
    ExecuteInGameThread(function()
        local ok,err=pcall(function()
            S.visible=not S.visible;S.enabled=true
            S.update();S.prepareView()
            if S.visible then S.status(true) end
        end)
        if not ok then reportError(err) end
    end)
end
function S.hide()
    if not S.visible then return end
    ExecuteInGameThread(function()
        S.visible=false
        if S.view then
            if P.valid(S.view.widget) then P.render(S.view,S.page(S.snapshot),false)
            else P.destroyView(S.view);S.view=nil end
        end
    end)
end
function S.mouse(action,value)
    if not S.enabled or not S.visible then return end
    if action=='close' then S.hide();return end
    if action=='previous' or action=='next' then S.move(action=='previous' and -1 or 1);return end
    ExecuteInGameThread(function()
        local ok,err=pcall(function()
            if action=='select' and type(value)=='number' then S.index=value
            elseif action=='previousPage' or action=='nextPage' then
                local page=S.page(S.snapshot)
                local number=math.max(1,math.min(page.pageCount,page.pageNumber+(action=='previousPage' and -1 or 1)))
                S.index=(number-1)*10+1
            else return end
            S.update()
        end)
        if not ok then reportError(err) end
    end)
end
function S.move(delta)
    if not S.visible then return end
    ExecuteInGameThread(function()
        local ok,err=pcall(function()
            S.index=S.index+delta
            S.update()
        end)
        if not ok then reportError(err) end
    end)
end
function S.status(verbose)
    local s=S.snapshot or I.fromSnapshot({})
    log('enabled='..tostring(S.enabled)..' visible='..tostring(S.visible)..' complete='..tostring(s.complete)..
        ' missing='..table.concat(s.missing,',')..' patched='..S.patched..' errors='..S.errors..
        ' view='..tostring(S.view and P.valid(S.view.widget) or false))
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
    S.enabled=false;S.visible=false
    if S.view then P.destroyView(S.view) end
    S.view=nil
    for path,h in pairs(S.uiHooks) do pcall(UnregisterHook,path,h.pre,h.post);S.uiHooks[path]=nil end
    for key,record in pairs(S.restores) do
        if P.valid(record.widget) then
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
end
if not S.keysInstalled then
    RegisterKeyBind(Key.F7,function() _G.FFWJokerInfo.toggle() end)
    for _,key in ipairs({Key.F2,Key.F4,Key.F8}) do
        RegisterKeyBind(key,function() _G.FFWJokerInfo.hide() end)
    end
    RegisterKeyBind(Key.F5,function() _G.FFWJokerInfo.move(-1) end)
    RegisterKeyBind(Key.F6,function() _G.FFWJokerInfo.move(1) end)
    RegisterKeyBind(Key.F5,{ModifierKey.SHIFT},function() _G.FFWJokerInfo.move(-10) end)
    RegisterKeyBind(Key.F6,{ModifierKey.SHIFT},function() _G.FFWJokerInfo.move(10) end)
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
