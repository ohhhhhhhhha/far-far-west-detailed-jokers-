local e=dofile('FFWTools/tests/joker_engine.lua').install()
local pending,keys={},{}
Key={F2=2,F4=4,F5=5,F6=6,F7=7,F8=8};ModifierKey={SHIFT=16}
RegisterKeyBind=function(k,m,f)keys[f and k..':shift' or k]=f or m end
LoopInGameThreadWithDelay=function()end;ExecuteInGameThread=function(f)pending[#pending+1]=f end
RegisterLoadMapPreHook=function()end;RegisterLoadMapPostHook=function()end
local reads,scans=0,0
FindAllOf=function(c)if c:find('UI_',1,true)==1 then scans=scans+1 end;return c=='PlayerController' and e.controllers or {} end
package.preload.UEHelpers=function()return e.helpers end
_G.FFWJokerInfo=nil
local mod=dofile('FFWTools/src/FFWJokerInfo/Scripts/main.lua')
local pool={};for _,c in ipairs(mod.Cards.all())do if c.scope=='hero' and c.enabled and not c.id:lower():find('jokerupgrade',1,true)then pool[#pool+1]=c end end
table.sort(pool,function(a,b)return a.name<b.name end)
local cards={};for n=3,14 do cards[#cards+1]=pool[n].id end
local function snapshot()return mod.Inventory.fromSnapshot{selected={primary='itemPistol',secondary='itemBow'},equipped={itemHero=cards},upgrades={},runtime={}}end
local latest=snapshot();mod.Inventory.read=function()reads=reads+1;return latest end
local function drain()while #pending>0 do table.remove(pending,1)()end end
local failures={};local function check(v,m)if not v then failures[#failures+1]=m end end
keys[7]();drain();local view=mod.view
local beforeRead,beforeScan=reads,scans
for n=1,5 do keys[6]()end;drain()
print('five selection actions: inventory='..(reads-beforeRead)..' scans='..(scans-beforeScan))
check(reads==beforeRead and scans==beforeScan,'navigation repeated full inventory/global scans')
check(mod.index==6,'queued navigation lost repeated key presses')
e.click(view.mouse.buttons.nextPage.button);drain()
local selected=mod.page(mod.snapshot).selected.card.id
view.detailScroll.scrollOffset=73
cards[#cards+1]=pool[2].id;latest=snapshot();mod.update(true)
check(mod.page(mod.snapshot).selected.card.id==selected,'background insertion changed the selected card')
check(view.detailScroll.scrollOffset==73,'background insertion reset unchanged card scroll position')
-- Enqueue a click, then let a background insertion change absolute indices.
local row=view.mouse.buttons['row-1'];local wanted=mod.page(mod.snapshot).entries[row.value].card.id
e.click(row.button)
cards[#cards+1]=pool[1].id;latest=snapshot();mod.update(true)
beforeRead,beforeScan=reads,scans;drain()
check(mod.page(mod.snapshot).selected.card.id==wanted,'queued click selected the new occupant of an old row index')
check(reads==beforeRead and scans==beforeScan,'queued selection ignored the current snapshot')
-- A temporarily incomplete read is not evidence that the selected card vanished.
local complete=latest;latest=mod.Inventory.fromSnapshot{};mod.update(true)
latest=complete;mod.update(true)
check(mod.page(mod.snapshot).selected.card.id==wanted,'temporary missing inventory lost the selected card identity')
-- Losing an entry clamps to a real remaining item, and an empty list is valid.
local kept={};for _,id in ipairs(cards)do if id~=wanted then kept[#kept+1]=id end end;cards=kept;latest=snapshot();mod.update(true)
local page=mod.page(mod.snapshot)
check(page.selected and page.selected.card.id~=wanted and page.index<=page.count,'removed selection left an invalid index')
cards={};latest=snapshot();mod.update(true);check(mod.page(mod.snapshot).count==0,'empty inventory did not render')
e.click(view.mouse.buttons.close.button);drain();check(not mod.visible and not e.controller.bShowMouseCursor,'close failed to restore input')
mod.stop();e.restore();assert(#failures==0,table.concat(failures,'; '));print('joker_navigation_snapshot_test passed')
