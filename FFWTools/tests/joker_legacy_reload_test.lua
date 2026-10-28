-- A beta.4-shaped live state: no context getters/scope keys and cleanup ignores
-- the new abandon argument. Also model an already queued beta.4 toggle closure.
local e=dofile('FFWTools/tests/joker_engine.lua').install();local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
Key={F2=2,F4=4,F5=5,F6=6,F7=7,F8=8};ModifierKey={SHIFT=16}
RegisterKeyBind=function() end;LoopInGameThreadWithDelay=function() end
ExecuteInGameThread=function(fn) fn() end
local texts={}
FindAllOf=function(class) return class=='PlayerController' and e.controllers or (class=='TextBlock' and texts or {}) end
package.preload.UEHelpers=function() return e.helpers end
_G.FFWJokerInfo=nil
local old=dofile('FFWTools/src/FFWJokerInfo/Scripts/main.lua')
local sample=old.Inventory.fromSnapshot{selected={primary='itemShotgun',secondary='itemDualRevolver'},equipped={itemHero={'jokerLightWeight'}},upgrades={},runtime={}}
old.Inventory.read=function() return sample end;old.update();old.toggle()
local oldView=old.view;oldView.getController=nil;oldView.getContext=nil;oldView.contextKey=nil
oldView.mouse.options.getController=nil
local dispose=oldView.mouse.dispose;oldView.mouse.dispose=function(self) return dispose(self,false) end
local text=e.object('TextBlock');text.text='Original\n\n【奇术卡信息】\nPatched';text.Font.Size=15
function text:GetParent() return self.parent end
local parent,box,scroll=e.object('VerticalBox'),e.object('SizeBox'),e.object('ScrollBox')
parent:AddChild(box);box:AddChild(scroll);scroll:AddChild(text);texts={text}
local record={widget=text,descriptionParent=parent,descriptionBox=box,scroll=scroll,fontSize=19}
old.restores={[text:GetFullName()]=record};old.context=nil;old.stateSchema=nil
local queuedOld=function() old.visible=not old.visible;old.enabled=true;old.update();old.prepareView() end
local current=dofile('FFWTools/src/FFWJokerInfo/Scripts/main.lua')
current.Inventory.read=function() return sample end
current.update()
eq(current.errors,0,'upgrade from beta.4 does not call a missing view getter')
eq(oldView.widget.onScreen,false,'same-world beta.4 root is retired')
eq(current.restores[text:GetFullName()],record,'freshly rediscovered description retains its original restoration data')
eq(record.scopeKey,current.context.ownerKey)
current.toggle();local active=current.view;queuedOld()
eq(current.visible,true,'queued beta.4 callback cannot mutate the replacement state')
eq(current.view,active)
current.stop();eq(text.text,'Original');eq(text.Font.Size,19)
eq(e.controller.lookIgnores,0,'legacy and new input leases are balanced')
e.restore();print('joker_legacy_reload_test: '..checks..' checks passed')
