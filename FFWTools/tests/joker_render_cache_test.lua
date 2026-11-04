local e=dofile('FFWTools/tests/joker_engine.lua').install()
local writes=0;local create=e.object
function e.object(kind)
 local o=create(kind)
 for _,name in ipairs({'SetText','SetHintText','SetFont','SetVisibility','SetPosition','SetSize','SetColorAndOpacity','SetBackgroundColor','SetIsEnabled'})do
  local method=o[name]
  o[name]=function(self,...) writes=writes+1;return method(self,...)end
 end
 return o
end
Key={F2=2,F4=4,F5=5,F6=6,F7=7,F8=8};ModifierKey={SHIFT=16}
RegisterKeyBind=function()end;LoopInGameThreadWithDelay=function()end;ExecuteInGameThread=function(f)f()end
RegisterLoadMapPreHook=function()end;RegisterLoadMapPostHook=function()end
FindAllOf=function(c)return c=='PlayerController' and e.controllers or {}end
package.preload.UEHelpers=function()return e.helpers end
_G.FFWJokerInfo=nil
local mod=dofile('FFWTools/src/FFWJokerInfo/Scripts/main.lua')
local cards={'jokerPlasticDuck'}
local function snapshot()return mod.Inventory.fromSnapshot{selected={primary='itemPistol',secondary='itemBow'},equipped={itemHero=cards},upgrades={},runtime={}}end
mod.Inventory.read=snapshot
mod.toggle();local view=mod.view
local failures={};local function check(v,m)if not v then failures[#failures+1]=m end end
writes=0;for n=1,6 do mod.update(true)end
print('six unchanged F7 refreshes: control writes='..writes)
check(writes==0,'unchanged F7 repeatedly rewrote text, style and layout')
-- Reloading the module must apply its new rendering code once, even for identical data.
mod=dofile('FFWTools/src/FFWJokerInfo/Scripts/main.lua');mod.Inventory.read=snapshot
writes=0;mod.update(true);check(writes>0,'module reload retained the old rendered-state cache')
writes=0;mod.update(true);check(writes==0,'reloaded renderer did not settle')
-- Changed count still refreshes full detail, then settles again.
cards[2]='jokerPlasticDuck';writes=0;mod.update(true)
check(writes>0 and view.detail.text:find('2',1,true),'changed count did not update detail')
writes=0;mod.update(true);check(writes==0,'new stable state was not cached')
-- Controls must notice a row-caption-only change even with an unchanged list.
local page=mod.page(mod.snapshot);page.rows[1].buttonText='Changed caption';writes=0
mod.Panel.render(view,page,true)
check(writes>0 and view.mouse.buttons['row-1'].label.text=='Changed caption','row-only update was skipped')
-- Repainting must recover after a transient setter exception, even if content reverts.
mod.update(true);local original=view.detail.SetText;local fail=true
view.detail.SetText=function(self,value)if fail then fail=false;error('injected text write failure')end;return original(self,value)end
local page=mod.page(mod.snapshot);page.title='partial changed title';page.detail='new detail'
local ok=pcall(mod.Panel.render,view,page,true);check(not ok,'fault did not reach renderer')
mod.update(true);check(view.title.text==mod.page(mod.snapshot).title,'old render cache hid a partial-update failure')
view.detail.SetText=original
local culture=StaticFindObject('/Script/Engine.KismetInternationalizationLibrary');culture.GetCurrentLanguage=function()return 'en'end
writes=0;mod.update(true);check(writes>0 and view.mouse.buttons.close.label.text=='Close','language update was skipped')
e.viewport.width=800;e.viewport.height=600;writes=0;mod.update(true)
check(writes>0 and view.widget.desired.X<800,'viewport layout update was skipped')
mod.hide();mod.toggle();check(view.widget.Visibility==4 and view.mouse.active and e.controller.bShowMouseCursor,'reopen failed after cached hide')
view.widget:RemoveFromParent();mod.update(true);check(view.widget:IsInViewport(),'detached F7 did not reattach')
view.widget:SetVisibility(2);mod.update(true);check(view.widget.Visibility==4,'native hidden root stayed hidden')
mod.hide();check(not e.controller.bShowMouseCursor and e.controller.lookIgnores==0,'close left input captured')
mod.stop();e.restore();assert(#failures==0,table.concat(failures,'; '));print('joker_render_cache_test passed')
