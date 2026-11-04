FName=function(s) return s end
local e=dofile('FFWTools/tests/joker_engine.lua').install()
Key={F2=2,F4=4,F5=5,F6=6,F7=7,F8=8};ModifierKey={SHIFT=16}
RegisterKeyBind=function() end;LoopInGameThreadWithDelay=function() end;ExecuteInGameThread=function(f) f() end
RegisterLoadMapPreHook=function() end;RegisterLoadMapPostHook=function() end
FindAllOf=function(c) return c=='PlayerController' and e.controllers or {} end
package.preload.UEHelpers=function() return e.helpers end
_G.FFWJokerInfo=nil
local mod=dofile('FFWTools/src/FFWJokerInfo/Scripts/main.lua')
local inventories=0
mod.Inventory.read=function() inventories=inventories+1;return mod.Inventory.fromSnapshot{equipped={},runtime={},upgrades={}} end
local menu=e.controller.Pawn.refBpMenu;menu.isUiMode=true;menu.useRightStickInputs=true
local axis=0;function e.controller:GetInputAnalogKeyState() return axis end
mod.update()
local hook=e.hooks['/Game/Gamework/BP_Manager_Menu.BP_Manager_Menu_C:ReceiveTick'][1]
local now=0;e.objects['/Script/Engine.GameplayStatics'].GetRealTimeSeconds=function() return now end
local checks=0;local original=mod.checkContext
mod.checkContext=function() checks=checks+1;return original() end
local before=inventories
for frame=1,1440 do now=frame/240;hook({get=function()return menu end},{get=function()return 0 end}) end
print('6s menu without cards: context checks='..checks)
local emptyChecks=checks;checks=0
local owner=e.object('Card');local scroll=e.object('ScrollBox');scroll.finish=1000
mod.restores.card={scopeKey=mod.context.ownerKey,widget=owner,scrollOwner=owner,scroll=scroll}
for frame=1,1440 do now=frame/240;hook({get=function()return menu end},{get=function()return 0 end}) end
print('6s neutral 240Hz: context checks='..checks..' inventory reads='..(inventories-before))
local failures={};local function check(v,m) if not v then failures[#failures+1]=m end end
check(emptyChecks==0,'menu without any card performed controller work')
check(checks<=62,'full context queried per frame before the rate gate')
check(inventories==before,'scroll input must never read inventory')
local other=e.object('OtherMenu');other.useRightStickInputs=true
checks=0
for frame=1,1440 do now=12+frame/240;hook({get=function()return other end},{get=function()return 0 end}) end
print('6s other menu 240Hz: context checks='..checks)
check(checks==0,'unrelated menu queried local context')
-- Discovery uses the real 100ms sampling interval, independently of movement clamp.
axis=-1;now=18.1;hook({get=function()return menu end},{get=function()return 0 end})
owner.Hover=true;now=18.2;hook({get=function()return menu end},{get=function()return 0 end})
check(scroll:GetScrollOffset()>0,'a focused target missed the next 100ms discovery sample')
-- Paused game delta is zero, but real-time controller movement must still work.
mod.toggle();local view=mod.view;view.detailScroll.finish=1000;axis=-1
for frame=1,48 do now=18.2+frame/240;hook({get=function()return menu end},{get=function()return 0 end}) end
check(view.detailScroll.scrollOffset>0 and not menu.useRightStickInputs,'paused F7 no longer scrolls')
-- Tick itself must not traverse retired UI during travel.
mod.beginTravel();local before=checks
hook({get=function()error('retired event object')end},nil)
check(checks==before,'travel tick performed context work')
mod.endTravel();mod.stop();e.restore()
assert(#failures==0,table.concat(failures,'; '));print('joker_performance_runtime_test passed')
