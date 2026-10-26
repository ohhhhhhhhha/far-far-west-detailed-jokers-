-- Models only the UMG calls used for retaining the actual description widget.
local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function obj(name)
    return {IsValid=function() return true end,GetFullName=function() return name end,IsVisible=function() return true end,
        GetAddress=function() return name end}
end
local function panel(name)
    local p=obj(name);p.children={}
    function p:AddChild(child)
        self.children[#self.children+1]=child;child.parent=self
        local slot={Padding={Left=0,Top=0,Right=0,Bottom=0},HorizontalAlignment=2}
        function slot:SetPadding(v) self.Padding=v end;function slot:SetHorizontalAlignment(v) self.HorizontalAlignment=v end
        child.Slot=slot;return slot
    end
    function p:RemoveChild(child)
        for i,v in ipairs(self.children) do if v==child then table.remove(self.children,i);child.parent=nil;return true end end
        return false
    end
    function p:GetChildAt(i) return self.children[i+1] end
    function p:SetWidthOverride(n) self.WidthOverride=n end
    function p:SetHeightOverride(n) self.HeightOverride=n end
    return p
end
local function textBlock(name,value,size)
    local text=obj(name);text.value=value or '';text.Font={Size=size or 19};text.AutoWrapText=true
    text.Justification=1;text.RenderTransform={Translation={X=0,Y=4}}
    text.ColorAndOpacity={SpecifiedColor={R=.94,G=.95,B=.97,A=1}}
    function text:GetText() return self.value end;function text:SetText(v) self.value=v end
    function text:GetParent() return self.parent end;function text:SetFont(v) self.Font=v end
    function text:SetAutoWrapText(v) self.AutoWrapText=v end
    function text:SetJustification(v) self.Justification=v end
    function text:SetRenderTranslation(v) self.RenderTransform.Translation=v end
    function text:SetColorAndOpacity(v) self.ColorAndOpacity=v end
    function text:SetVisibility(v) self.Visibility=v end
    return text
end
local text=textBlock('TextBlock Candidate.Description','重力 -5%',19)
local descriptionParent=panel('VerticalBox CardBody');descriptionParent:AddChild(obj('Title'));descriptionParent:AddChild(obj('Icon'));descriptionParent:AddChild(text)
local root=panel('SizeBox CardRoot');root.WidthOverride=300;root.HeightOverride=450
local tree=obj('WidgetTree');tree.RootWidget=root
-- Real GetFullName includes the owning selector class in the object path.
-- Dispatching on substrings of the whole name mistakes this child for its owner.
local card=obj('UI_JokerCard_InGame_C /Engine/Transient.UI_SelectableJoker_C_1.WidgetTree.UI_JokerCard_InGame_C_2');card.jokerName='jokerLightWeight';card.TextBlock_Description=text;card.WidgetTree=tree
local button=panel('Button_Joker');button:AddChild(card)
local selector=obj('UI_SelectableJoker_C Selector');selector.Button_Joker=button
local selectors={selector};local scans,reads=0,0
FindAllOf=function(class)
    scans=scans+1
    if class=='UI_JokerCard_InGame_C' then return {card} end
    if class=='UI_SelectableJoker_C' then return selectors end
    return {}
end
local callbacks={}
StaticFindObject=function(path) return obj(path) end
StaticConstructObject=function(class)
    if class:GetFullName()=='/Script/UMG.TextBlock' then return textBlock('TextBlock NoBonus') end
    return panel(class:GetFullName())
end
RegisterHook=function(path,fn) callbacks[path]=fn;return 1,2 end
UnregisterHook=function(path) callbacks[path]=nil end
Key={F3=3,F4=4,F5=5,F6=6,F7=7};ModifierKey={SHIFT=16};RegisterKeyBind=function() end
LoopInGameThreadWithDelay=function() end;ExecuteInGameThread=function(fn) fn() end;FText=function(v) return v end
local function collection(v) return {ForEach=function(_,fn) for k,x in pairs(v) do fn(k,x) end end} end
local progress={selectedItemA_207_DB75D0B645F36A6C80EA10BC4BCAA457='itemLongRanger',selectedItemB_208_5EFA92804322145CAD0049B5E0A8B48D='itemPistol',
    itemJokers_221_B68401A4476969C408297F9FD92F3128=collection({itemHero={jokers_13_7822C195413EA2810E969F8C260AA8B6=collection({'jokerLightWeight','jokerLightWeight'})}}),
    itemsUpgrades_216_1E448EF04C663CC03DC815A885A3CB74=collection({})}
local pawn={buffGravity=0,CharacterMovement={GravityScale=1.15},AC_PlayerItems={equipedItem={itemName='itemLongRanger'}}}
local ps={AC_PlayerStateJoker={playerLocalJokers=collection({})}}
package.preload.UEHelpers=function() return {
    GetPlayerController=function() reads=reads+1;return {Pawn=pawn,PlayerState=ps} end,
    GetGameInstance=function() return {playerProgress=progress} end} end
local mod=dofile('FFWTools/src/FFWJokerInfo/Scripts/main.lua');mod.update()
eq(mod.errors,0);eq(root.WidthOverride,300,'three candidates keep original width');eq(root.HeightOverride,500)
eq(text.parent:GetFullName(),'/Script/UMG.ScrollBox','same original TextBlock is retained inside ScrollBox')
eq(text.Font.Size,15);eq(text.value:find('1.15 → 1.1',1,true)~=nil,true)
local record=mod.restores[text:GetFullName()]
eq(record.descriptionBox.WidthOverride,210);eq(record.descriptionBox.HeightOverride,260)
eq(text.Justification,0,'long descriptions align left')
eq(text.RenderTransform.Translation.Y,0,'the original four-pixel offset is removed inside the scroll area')
eq(text.AutoWrapText,true,'wrap uses the bounded scroll geometry')
eq(text.Slot.HorizontalAlignment,0);eq(text.Slot.Padding.Right,12)
-- A dofile replacement can inherit a scroll record made by the previous build.
-- That build left the original alignment/translation intact and did not save them.
record.justification=nil;record.translation=nil
text.Justification=1;text.RenderTransform.Translation={X=0,Y=4}
text.value='重力 -5%'
mod=dofile('FFWTools/src/FFWJokerInfo/Scripts/main.lua');mod.update()
eq(record.justification,1,'existing records capture the original alignment before changing it')
eq(record.translation and record.translation.Y,4,'existing records capture the original offset before changing it')
selectors={};mod.update();eq(root.WidthOverride,340);eq(record.descriptionBox.HeightOverride,340,'changing ownership resizes existing scroll region')
eq(record.descriptionBox.WidthOverride,250,'Tab uses the wider current-card text region')
selectors={selector};mod.update();eq(root.WidthOverride,300);eq(record.descriptionBox.HeightOverride,260)
local beforeScans,beforeReads=scans,reads
text.value='重力 -5%'
callbacks['/Game/Interfaces/Tweaks/UI_JokerCard_InGame.UI_JokerCard_InGame_C:F_Refresh']({get=function() return card end})
eq(mod.errors,0,'nested card refresh must dispatch by its own class')
eq(scans,beforeScans,'construct/refresh callback must not scan all objects');eq(reads,beforeReads,'callback reuses 1s snapshot')
eq(text.value:find('1.15 → 1.1',1,true)~=nil,true,'game refreshing original text is patched immediately')
local building=obj('UI_SelectableJoker_C /Engine/Transient.UI_SelectableJoker_C_3')
callbacks['/Game/Interfaces/Tweaks/UI_SelectableJoker.UI_SelectableJoker_C:Construct']({get=function() return building end})
eq(mod.errors,0,'selector without a constructed button is deferred without an error')
local normal=mod.snapshot
local floor={};for i=1,21 do floor[i]='jokerLightWeight' end
mod.snapshot=mod.Inventory.fromSnapshot({selected={primary='itemLongRanger',secondary='itemPistol'},
    equipped={itemHero=floor},upgrades={},runtime={},inputs={buffGravity=0,heldItemName='itemLongRanger'}})
mod.refreshWidget(card)
eq(text.value,'重力 -5%\n\n【奇术卡信息】','ordinary text is separated from the colored status')
local red=record.noBonusText
eq(type(red),'table','no-bonus status is a real TextBlock')
eq(red.value,'无加成');eq(red.Visibility,3);eq(red.parent,record.scroll)
eq(red.Font.Size,15);eq(red.ColorAndOpacity.SpecifiedColor.R,1)
eq(red.ColorAndOpacity.SpecifiedColor.G,.2);eq(red.ColorAndOpacity.SpecifiedColor.B,.2)
eq(text.ColorAndOpacity.SpecifiedColor.G,.95,'original description color is unchanged')
mod.refreshWidget(card);eq(record.noBonusText,red,'polling reuses the same status widget')
eq(text.value,'重力 -5%\n\n【奇术卡信息】','split red text does not duplicate headers on refresh')
local noEffect=mod.snapshot
mod.snapshot=normal;mod.refreshWidget(card)
eq(red.Visibility,2,'positive effects collapse the old red status')
eq(text.value:find('1.15 → 1.1',1,true)~=nil,true)
mod.snapshot=noEffect;mod.refreshWidget(card)
eq(red.Visibility,3,'reuse of a card widget shows no-bonus status again')
eq(#record.scroll.children,2,'one ordinary and one status text without duplicates')
selectors={};mod.update()
-- The existing red widget is reused by a non-acquisition owner and must hide.
mod.snapshot=noEffect;mod.refreshWidget(card)
eq(red.Visibility,2,'switching from pickup to held hides the red warning')
eq(text.value:find('重力系数：0.25',1,true)~=nil,true)
mod.stop()
eq(text.value,'重力 -5%');eq(text.Font.Size,19);eq(text.parent,descriptionParent)
eq(descriptionParent:GetChildAt(2),text,'original child order restored');eq(#descriptionParent.children,3)
eq(root.WidthOverride,300);eq(root.HeightOverride,450);eq(next(callbacks),nil)
eq(text.Justification,1);eq(text.RenderTransform.Translation.Y,4,'stop restores original game layout')
print('joker_inline_layout_test: '..checks..' checks passed')
