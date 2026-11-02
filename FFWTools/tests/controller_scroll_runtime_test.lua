FName=function(s) return s end
local e=dofile('FFWTools/tests/joker_engine.lua').install()
Key={F2=2,F4=4,F5=5,F6=6,F7=7,F8=8};ModifierKey={SHIFT=16}
RegisterKeyBind=function() end;LoopInGameThreadWithDelay=function() end;ExecuteInGameThread=function(f) f() end
RegisterLoadMapPreHook=function() end;RegisterLoadMapPostHook=function() end
FindAllOf=function(c) return c=='PlayerController' and e.controllers or {} end
package.preload.UEHelpers=function() return e.helpers end
_G.FFWJokerInfo=nil
local mod=dofile('FFWTools/src/FFWJokerInfo/Scripts/main.lua')
mod.Inventory.read=function() return mod.Inventory.fromSnapshot{equipped={},runtime={},upgrades={}} end
mod.update()
local tick='/Game/Gamework/BP_Manager_Menu.BP_Manager_Menu_C:ReceiveTick'
assert(e.hooks[tick],'card menus have no right-stick input integration')
mod.toggle();local view=mod.view
assert(view.detailScroll.ConsumeMouseWheel==0 and view.detailScroll.WheelScrollMultiplier==1,'F7 must preserve native mouse wheel routing')
view.detailScroll.finish=1000
local pc=e.controller;pc.y=-1
function pc:GetInputAnalogKeyState(k) assert(k.KeyName=='Gamepad_RightY');return self.y end
local menu=pc.Pawn.refBpMenu;menu.useRightStickInputs=true
local time=0
e.objects['/Script/Engine.GameplayStatics'].GetRealTimeSeconds=function() return time end
local invoke=function() time=time+.05;e.hooks[tick][1]({get=function() return menu end},{get=function() return 0 end}) end
invoke();invoke();assert(view.detailScroll.scrollOffset>0,'paused native tick must scroll F7')
local saved=view.detailScroll.scrollOffset;pc.y=0;invoke();assert(view.detailScroll.scrollOffset==saved)
-- Native wheel remains separate, not injected a second time by the stick handler.
view.detailScroll:SetScrollOffset(saved+40);invoke();assert(view.detailScroll.scrollOffset==saved+40)
mod.hide();assert(menu.useRightStickInputs==true,'closing restores native right-stick cursor')
local slot=e.object('UI_Joker_Slot_C');slot.jokerName='jokerCrackShot';slot.itemName='itemPistol'
local tooltip=e.object('UI_EpicTweakTooltip_C');tooltip.WidgetTree=e.object('WidgetTree')
local description=e.object('TextBlock');description.Font=nil;description.text='base';tooltip.TextBlock_Description=description
slot.Button_Tweak=e.object('Button');slot.Button_Tweak.ToolTipWidget=tooltip
mod.refreshWidget(slot);mod.refreshWidget(tooltip)
assert(mod.restores[description:GetFullName()].scrollOwner==slot,'tooltip refresh must keep the hovered slot as scroll owner')
local retiredReads=0
mod.beginTravel();e.hooks[tick][1]({get=function() retiredReads=retiredReads+1;error('old object') end},nil)
assert(retiredReads==0,'travel callback touched retired UI')
mod.endTravel();mod.stop();e.restore()
print('controller_scroll_runtime_test: native tick, paused time, F7 wheel and cleanup passed')
