local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local e=dofile('FFWTools/tests/joker_engine.lua').install()
local pending,keys,loops,preMap,postMap={},{},{},{},{}
Key={F2=2,F4=4,F5=5,F6=6,F7=7,F8=8};ModifierKey={SHIFT=16}
RegisterKeyBind=function(key,mod,fn) keys[fn and key..':shift' or key]=fn or mod end
LoopInGameThreadWithDelay=function(delay,fn) eq(delay,1000);loops[#loops+1]=fn end
ExecuteInGameThread=function(fn) pending[#pending+1]=fn end
RegisterLoadMapPreHook=function(fn) preMap[#preMap+1]=fn end
RegisterLoadMapPostHook=function(fn) postMap[#postMap+1]=fn end
local objects={}
FindAllOf=function(class) return class=='PlayerController' and e.controllers or (objects[class] or {}) end
package.loaded.UEHelpers=nil;package.preload.UEHelpers=function() return e.helpers end
_G.FFWJokerInfo=nil
local mod=dofile('FFWTools/src/FFWJokerInfo/Scripts/main.lua')
local ids={};for _,c in ipairs(mod.Cards.all()) do if c.scope=='hero' and c.enabled and #ids<14 then ids[#ids+1]=c.id end end
mod.Inventory.read=function() return mod.Inventory.fromSnapshot{selected={primary='itemShotgun',secondary='itemDualRevolver'},
    equipped={itemHero=ids},upgrades={},runtime={}} end
local function drain()
    while #pending>0 do local fn=table.remove(pending,1);local ok,err=pcall(fn);eq(ok,true,tostring(err)) end
end
local function fire(list) for _,fn in ipairs(list) do fn() end end
mod.update();keys[7]();drain();eq(mod.visible,true)
local firstSnapshot=mod.snapshot
local uiPath='/Game/Interfaces/Tweaks/UI_JokerCard_InGame.UI_JokerCard_InGame_C:F_Refresh'
local oldUiHook=e.hooks[uiPath][1]
local pawnView=mod.view;local kept={widget=e.object('TextBlock'),scopeKey=mod.context.ownerKey or mod.context.key}
mod.restores.kept=kept
local savedPawn=e.controller.Pawn;e.controller.Pawn=nil
mod.update()
eq(pawnView.widget.onScreen,false,'unpossessed interval removes the surviving F7 root')
eq(mod.restores.kept,kept,'unpossessed interval preserves same-owner descriptions')
eq(e.controller.lookIgnores,0,'unpossessed current controller can release the overlay lock')
e.controller.Pawn=savedPawn;mod.update();keys[7]();drain();pawnView=mod.view
local pawn=e.object('Pawn');pawn.refBpMenu=e.object('Menu');e.controller.Pawn=pawn
mod.update()
eq(pawnView.widget.onScreen,false,'pawn-only replacement removes the surviving same-world F7 root')
eq(mod.restores.kept,kept,'same-world description restoration records are preserved')
eq(mod.view,nil);keys[7]();drain();eq(mod.visible,true)
local first=mod.view;mod.hide();e.retireView(first)
e.newController(false);e.controller.world.name='World /Game/Levels/L_Mission.L_Mission'
drain()
eq(e.staleCalls,0,'a delayed hide after travel must not render or hide retired controls')
eq(mod.view,nil);eq(mod.visible,false)
keys[7]();drain();eq(mod.visible,true);eq(mod.view~=first,true)
local second=mod.view
e.click(second.mouse.buttons['row-2'].button)
fire(preMap);e.retireView(second)
local unwrapped=0
oldUiHook({get=function() unwrapped=unwrapped+1;error('old event unwrapped during travel') end})
eq(unwrapped,0,'UI callback checks loading before retrieving its object parameter')
drain();eq(e.staleCalls,0,'queued old-world mouse selection is discarded before native work')
eq(mod.visible,false);eq(mod.snapshot,nil)
loops[1]();eq(e.staleCalls,0,'periodic update is suspended between LoadMap pre/post')
fire(postMap);e.newController(false);e.controller.world.name='World /Game/Levels/L_Lobby.L_Lobby'
mod.update();keys[7]();drain();eq(mod.visible,true,'F7 can rebuild after returning to the lobby')
local third=mod.view;local same=e.controller
fire(preMap);e.retireView(third)
same.world=e.object('World');same.world.name='World /Game/Levels/L_Mission2.L_Mission2'
same.world.OwningGameInstance=e.gameInstance;same.Pawn.world=same.world;same.PlayerState.world=same.world
fire(postMap);mod.update();eq(mod.visible,false);eq(e.staleCalls,0)
eq(same.lookIgnores,0,'same-controller travel releases only the overlay look lock through a fresh owner')
keys[7]();drain();eq(mod.visible,true);e.click(mod.view.mouse.buttons.close.button);drain()
eq(same.lookIgnores,0);eq(same.bShowMouseCursor,false)
-- Widget construction can reenter game code; a world change during a read
-- must not republish a retired snapshot or continue into a full UI scan.
local ordinaryRead=mod.Inventory.read
mod.Inventory.read=function() mod.beginTravel();return firstSnapshot end
mod.update();eq(mod.snapshot,nil,'reentrant travel discards the in-progress inventory result')
eq(mod.updating,false);mod.endTravel();mod.Inventory.read=ordinaryRead;mod.update()
-- Re-evaluating main retires the previous instance's queued actions/hooks.
keys[7]();drain();mod.hide()
local replaced=mod;mod=dofile('FFWTools/src/FFWJokerInfo/Scripts/main.lua');mod.Inventory.read=ordinaryRead
drain();eq(mod.visible,true,'old-instance delayed hide cannot close the current instance')
oldUiHook({get=function() unwrapped=unwrapped+1;error('old instance event') end})
eq(unwrapped,0,'replaced instance callbacks do not unwrap old objects')
mod.hide();drain()
-- A new map with a valid-looking local controller may still be the title UI.
fire(preMap);same.world.name='World /Game/Levels/L_OpeningCredits.L_OpeningCredits';fire(postMap)
mod.update();keys[7]();drain();eq(mod.view,nil);eq(mod.visible,false)
-- Old description records must not be restored after a map transition.
local retired=e.object('TextBlock');e.retire(retired)
mod.restores.old={widget=retired};fire(preMap);mod.stop();eq(e.staleCalls,0)
-- Pending actions from a disabled or replaced module instance cannot re-enable it.
fire(postMap);e.newController(false);keys[7]();mod.stop();drain();eq(mod.enabled,false);eq(mod.visible,false)
eq(#preMap,1);eq(#postMap,1);eq(#loops,1,'no new periodic timer was introduced')
e.restore()
print('joker_lifecycle_test: '..checks..' checks passed')
