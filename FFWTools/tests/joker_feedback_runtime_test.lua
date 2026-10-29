local e=dofile('FFWTools/tests/joker_engine.lua').install()
local pending,keys,loops={},{},{}
local reads,scans=0,0
Key={F2=2,F4=4,F5=5,F6=6,F7=7,F8=8};ModifierKey={SHIFT=16}
RegisterKeyBind=function(k,m,f) keys[f and k..':shift' or k]=f or m end
LoopInGameThreadWithDelay=function(_,f) loops[#loops+1]=f end
ExecuteInGameThread=function(f) pending[#pending+1]=f end
RegisterLoadMapPreHook=function() end;RegisterLoadMapPostHook=function() end
local widgets={}
FindAllOf=function(class) if class:find('UI_',1,true)==1 then scans=scans+1 end;return class=='PlayerController' and e.controllers or (widgets[class] or {}) end
package.loaded.UEHelpers=nil;package.preload.UEHelpers=function() return e.helpers end
local make=e.object
function e.object(kind)
    local o=make(kind)
    function o:IsInViewport() return self.onScreen==true end
    return o
end
_G.FFWJokerInfo=nil
local mod=dofile('FFWTools/src/FFWJokerInfo/Scripts/main.lua')
mod.Inventory.read=function()
    reads=reads+1
    return mod.Inventory.fromSnapshot{selected={primary='itemKnuckles',secondary='itemDualRevolver'},
        equipped={itemKnuckles={'jokerLunge','jokerLunge','jokerLunge','jokerLunge','jokerLunge'}},upgrades={},runtime={}}
end
local function drain() while #pending>0 do table.remove(pending,1)() end end
local failures={}
local function check(ok,why) if not ok then failures[#failures+1]=why end end
mod.update();keys[7]();drain()
assert(mod.visible and mod.view and mod.view.widget.onScreen,'baseline F7 did not open')
check(mod.view.detail.text:find('55',1,true)~=nil,'five held Lunge cards must retain their current total')
local view=mod.view
view.widget:RemoveFromParent() -- Native RemoveAllWidgets can detach a still-valid current-world root.
mod.update()
check(view.widget.onScreen==true,'F7 did not recover after its live root was detached from the viewport')
mod.hide();drain()
e.controller.Pawn.refBpMenu.isUiMode=false
e.controller.Pawn.refBpMenu.isMenuOpened=false
e.controller.Pawn.refBpMenu.isAnySpecialMenuOpened=false
local beforeReads,beforeScans=reads,scans
for _=1,6 do loops[1]() end
check(reads==beforeReads,'hidden gameplay performed '..(reads-beforeReads)..' full inventory reads')
check(scans==beforeScans,'hidden gameplay performed '..(scans-beforeScans)..' global card scans')
-- The idle gate must not prevent native menu updates or reopening F7.
e.controller.Pawn.refBpMenu.isMenuOpened=true
local before=reads;loops[1]();check(reads>before,'native menu did not refresh live data')
e.controller.Pawn.refBpMenu.isMenuOpened=false
keys[7]();drain();check(mod.visible and mod.view.widget.onScreen,'F7 did not reopen after idle gameplay')
-- A native card event still refreshes while all menu flags are false.
mod.hide();drain();loops[1]()
local reader=function()
    reads=reads+1
    return mod.Inventory.fromSnapshot{selected={primary='itemPistol',secondary='itemKnuckles'},
        equipped={itemPistol={'jokerCrackShot','jokerCrackShot'}},upgrades={},runtime={}}
end
mod.Inventory.read=reader
local widget=e.object('UI_JokerCard_C');widget.jokerName='jokerCrackShot';widget.ItemName='itemPistol'
local text=e.object('TextBlock');text.Font=nil;text.text='base';widget.TextBlock_Description=text
widgets.UI_JokerCard_C={widget}
local before=reads
local hook=e.hooks['/Game/Interfaces/Tweaks/UI_JokerCard.UI_JokerCard_C:F_Update'][1]
hook({get=function() return widget end})
check(reads==before+1 and mod.nativeUiDirty,'native card event did not reread after idle')
check(text.text:find('+14%',1,true) and text.text:find('+21%',1,true),'native event did not use fresh card counts')
local br,bs=reads,scans;loops[1]()
check(reads==br+1 and scans==bs+6,'native event must receive one follow-up scan')
br,bs=reads,scans;loops[1]()
check(reads==br and scans==bs,'native event demand was not consumed')
mod=dofile('FFWTools/src/FFWJokerInfo/Scripts/main.lua');mod.Inventory.read=reader
loops[1]();check(reads==br+1 and scans==bs+6,'reload must bootstrap existing native cards once')
br,bs=reads,scans;loops[1]();check(reads==br and scans==bs,'reload did not return to idle')
e.newController(false);loops[1]();check(reads==br+1 and scans==bs+6,'new context did not bootstrap native cards')
mod.stop();e.restore()
assert(#failures==0,table.concat(failures,'; '))
print('joker_feedback_runtime_test: detached viewport, idle work and five-card F7 passed')
