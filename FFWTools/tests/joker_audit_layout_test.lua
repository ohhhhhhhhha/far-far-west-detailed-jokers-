-- Models only the UMG calls used for retaining the actual description widget.
local checks=0
local world={IsValid=function() return true end,GetFullName=function() return 'World /Game/Levels/L_Lobby.L_Lobby' end,GetAddress=function() return 1 end}
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function obj(name)
    return {IsValid=function() return true end,GetFullName=function() return name end,IsVisible=function() return true end,
        GetAddress=function() return name end,GetWorld=function() return world end}
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
    function p:SetConsumeMouseWheel(n) self.ConsumeMouseWheel=n end
    function p:SetWheelScrollMultiplier(n) self.WheelScrollMultiplier=n end
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
for key,value in pairs(obj('Pawn Local')) do pawn[key]=value end
for key,value in pairs(obj('PlayerState Local')) do ps[key]=value end
local controller=obj('PlayerController Local');controller.Pawn=pawn;controller.PlayerState=ps
controller.IsLocalPlayerController=function() return true end
local instance=obj('GameInstance Local');instance.playerProgress=progress
package.preload.UEHelpers=function() return {
    GetPlayerController=function() reads=reads+1;return controller end,
    GetGameInstance=function() return instance end} end
local mod=dofile('FFWTools/src/FFWJokerInfo/Scripts/main.lua');mod.update()
eq(mod.errors,0);eq(root.WidthOverride,300,'three candidates keep original width');eq(root.HeightOverride,500)
eq(text.parent:GetFullName(),'/Script/UMG.ScrollBox','same original TextBlock is retained inside ScrollBox')
eq(text.Font.Size,15);eq(text.value:find('1.15 → 1.1',1,true)~=nil,true)
local record=mod.restores[text:GetFullName()]
eq(record.scroll.ConsumeMouseWheel,0);eq(record.scroll.WheelScrollMultiplier,1)
eq(record.scrollOwner,selector,"pickup owner drives controller focus")
eq(record.descriptionBox.WidthOverride,210);eq(record.descriptionBox.HeightOverride,260)
eq(text.Justification,0,'long descriptions align left')
eq(text.RenderTransform.Translation.Y,0,'the original four-pixel offset is removed inside the scroll area')
eq(text.AutoWrapText,true,'wrap uses the bounded scroll geometry')
eq(text.Slot.HorizontalAlignment,0);eq(text.Slot.Padding.Right,12)

local failures={};local function check(v,m) if not v then failures[#failures+1]=m end end
record.scroll.SetScrollOffset=function(self,v) self.offset=v end
record.scroll.offset=180
card.jokerName='jokerHealthyBoi';text.value='new card';mod.refreshWidget(card)
check(record.scroll.offset==0,'reused card retains old scroll position')
record.scroll.offset=70;mod.refreshWidget(card);check(record.scroll.offset==70,'ordinary refresh lost scroll position')
for i=1,40 do mod.restores['dead'..i]={scopeKey=mod.context.ownerKey,widget={IsValid=function()return false end}} end
mod.update();local dead=0;for k in pairs(mod.restores) do if k:find('dead') then dead=dead+1 end end
check(dead==0,'invalid restoration records accumulate')
local replacement=textBlock(text:GetFullName(),'replacement',21);replacement.GetAddress=function()return 'replacement-address' end
descriptionParent:AddChild(replacement);card.TextBlock_Description=replacement
text.IsValid=function() return false end
mod.update()
local wrappers=0;for _,child in ipairs(descriptionParent.children) do if child:GetFullName()=='/Script/UMG.SizeBox' then wrappers=wrappers+1 end end
check(wrappers==1,'invalid record prune left a blank description wrapper')
check(mod.restores[replacement:GetFullName()].widget==replacement,'same-name replacement reuses old TextBlock')
local construct=StaticConstructObject
StaticConstructObject=function(class)
 local o=construct(class)
 if class:GetFullName()=='/Script/UMG.ScrollBox' then o.AddChild=function() error('scroll insertion failure') end end
 return o
end
local failedText=textBlock('TextBlock Failed.Description','failure fallback',19)
descriptionParent:AddChild(failedText);card.TextBlock_Description=failedText;mod.refreshWidget(card)
check(failedText.parent==descriptionParent,'failed reparenting orphaned native description')
-- A failure after style writes must restore original styling independently of
-- whether the temporary scroll wrapper survived rollback.
StaticConstructObject=construct
local styled=textBlock('TextBlock Styled.Description','styled fallback',20);styled.AutoWrapText=false
local translate=styled.SetRenderTranslation
styled.SetRenderTranslation=function() error('translation failure') end
descriptionParent:AddChild(styled);card.TextBlock_Description=styled;mod.refreshWidget(card)
styled.SetRenderTranslation=translate
mod.stop()
check(styled.AutoWrapText==false and styled.Justification==1,'rollback lost the original native text style')
check(replacement.Font.Size==21,'replacement original font not restored')
check(not replacement.value:find('【奇术卡信息】',1,true),'replacement description not restored')
check(failedText.parent==descriptionParent,'stop failed to recover orphaned description')
assert(#failures==0,table.concat(failures,'; '));print('joker_audit_layout_test passed')
