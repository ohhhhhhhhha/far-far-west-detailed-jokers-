local checks=0
local function eq(a,b,message) checks=checks+1;assert(a==b,(message or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local e=dofile('FFWTools/tests/joker_engine.lua').install()
local keys,loops={},{}
Key={F2=2,F4=4,F5=5,F6=6,F7=7,F8=8};ModifierKey={SHIFT=16}
RegisterKeyBind=function(key,modifier,fn) keys[fn and key..':shift' or key]=fn or modifier end
LoopInGameThreadWithDelay=function(_,fn) loops[#loops+1]=fn end
ExecuteInGameThread=function(fn) fn() end
FindAllOf=function() return {} end
package.preload.UEHelpers=function() return e.helpers end
local mod=dofile('FFWTools/src/FFWJokerInfo/Scripts/main.lua')
local cards={}
for _,card in ipairs(mod.Cards.all()) do
    if card.scope=='hero' and not card.id:find('Upgrade',1,true) and card.enabled and #cards<12 then cards[#cards+1]=card.id end
end
local snapshot=mod.Inventory.fromSnapshot({selected={primary='itemQuadCylinder'},equipped={itemHero=cards},runtime={},upgrades={}})
mod.Inventory.read=function() return snapshot end
local page=mod.page(snapshot)
eq(type(page.rows),'table','F7 exposes selectable rows without changing detail text')
eq(#page.rows,10);eq(page.rows[3].index,3)
keys[7]();eq(mod.visible,true);eq(e.controller.bShowMouseCursor,true)
eq(e.nativeRecentersMouse(),false,'F7 is mouse-operable without opening Esc')
local view=mod.view
eq(view.detail.parent,view.detailBox);eq(view.detailBox.parent,view.detailScroll,'full details are inside the native wheel scroll area')
eq(view.detailScroll.Slot.size.Y,540)
e.click(view.mouse.buttons['row-3'].button);eq(mod.index,3)
eq(view.detail.text,mod.page(snapshot).detail,'click selects the complete original F7 rules')
view.detailScroll.scrollOffset=140
mod.update();eq(view.detailScroll.scrollOffset,140,'periodic refresh retains scroll position')
e.click(view.mouse.buttons.nextPage.button);eq(mod.index,11)
eq(view.mouse.buttons['row-1'].value,11);eq(view.mouse.buttons['row-3'].host.Visibility,2,'unused page rows cannot intercept input')
eq(view.detailScroll.scrollOffset,0,'changing selected card resets detail scroll')
e.click(view.mouse.buttons['row-2'].button);eq(mod.index,12)
e.click(view.mouse.buttons.previous.button);eq(mod.index,11)
e.click(view.mouse.buttons.previousPage.button);eq(mod.index,1)
keys[6]();eq(mod.index,2,'keyboard navigation still selects immediately')
keys['6:shift']();eq(mod.index,12,'keyboard paging is retained')
local culture=StaticFindObject('/Script/Engine.KismetInternationalizationLibrary')
culture.GetCurrentLanguage=function() return 'en' end
mod.update();eq(view.mouse.buttons.close.label.text,'Close','controls follow game language without changing settings')
eq(view.pageLabel.text,'Page 2 / 2')
e.click(view.mouse.buttons.close.button);eq(mod.visible,false);eq(e.controller.bShowMouseCursor,false)
eq(view.widget.Visibility,2);e.click(view.mouse.buttons.previous.button);eq(mod.index,12,'hidden native events cannot navigate')
keys[7]();local old=e.controller;e.newController(false);mod.update()
eq(old.bShowMouseCursor,true,'retired controller is not called just to change its cursor flag')
eq(view.disposed,true);eq(mod.view,nil);eq(mod.visible,false,'travel closes the retired overlay')
eq(e.controller.bShowMouseCursor,false,'new controller keeps its native input until F7 is reopened')
keys[7]();eq(e.controller.bShowMouseCursor,true)
local travelView=mod.view;e.controller.world=e.object('World');mod.update()
eq(mod.view,nil,'mixed-world pawn/state prevent premature panel rebuild')
e.controller.Pawn.world=e.controller.world;e.controller.PlayerState.world=e.controller.world
mod.update();keys[7]();eq(mod.view~=travelView,true,'same-controller world travel can create a fresh input owner')
keys[8]();eq(mod.visible,false);eq(e.controller.bShowMouseCursor,false,'F8 switching releases F7')
mod.stop();e.restore()
print('joker_mouse_test: '..checks..' checks passed')
