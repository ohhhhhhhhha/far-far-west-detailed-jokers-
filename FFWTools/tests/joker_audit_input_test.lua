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

local faults={};local function check(v,m) if not v then faults[#faults+1]=m end end
-- Native F_SetInput_Game resets these fields while the overlay remains open.
menu.isUiMode=false;menu.isMenuOpened=false;menu.isAnySpecialMenuOpened=false;pc.bShowMouseCursor=false;pc:SetIgnoreLookInput(false)
local gamePath='/Game/Gamework/BP_Manager_Menu.BP_Manager_Menu_C:F_SetInput_Game'
for _,f in ipairs(e.hooks[gamePath] or {}) do if f then f({get=function() return menu end}) end end
mod.update()
check(pc.bShowMouseCursor and menu.isUiMode and pc.lookIgnores==1,'visible F7 must reacquire input after native GameOnly')
mod.hide();check(not pc.bShowMouseCursor and not menu.isUiMode and pc.lookIgnores==0,'closing F7 must use the new native baseline')
-- Failure part-way through input acquisition must roll back preceding writes.
local old=pc.SetIgnoreLookInput
pc.SetIgnoreLookInput=function(_,value) if value then error('look lock failed') end end
local ok=pcall(function() mod.view.mouse:show(mod.view.widget) end)
check(not ok and not menu.isUiMode and not mod.view.mouse.active,'failed acquisition leaked native UI mode')
pc.SetIgnoreLookInput=old
mod.stop();e.restore();assert(#faults==0,table.concat(faults,'; '));print('joker_audit_input_test passed')
