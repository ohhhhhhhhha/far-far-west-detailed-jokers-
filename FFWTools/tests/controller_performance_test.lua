package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;'..package.path
local G=require('ControllerScroll')
local calls={parent=0,hover=0,axis=0,offsetWrites=0}
local function object(name,owner)
 local o={name=name,valid=true,Visibility=0,hover=false,focus=false}
 function o:IsValid() return self.valid end
 function o:GetFullName() return self.name end
 function o:GetAddress() return self.name end
 function o:GetParent() calls.parent=calls.parent+1;return self.parent end
 function o:GetOuter() return self.outer end
 function o:IsHovered() if owner then calls.hover=calls.hover+1 end;return self.hover end
 function o:HasUserFocus() return self.focus end
 function o:HasUserFocusedDescendants() return false end
 return o
end
local pc=object('pc');pc.y=0
function pc:GetInputAnalogKeyState() calls.axis=calls.axis+1;return self.y end
local menu=object('menu');menu.useRightStickInputs=true
FName=function(v)return v end
local records={}
for n=1,200 do
 local owner=object('card'..n,true);local s=object('scroll'..n)
 s.offset=0;s.finish=1000
 function s:GetScrollOffset() return self.offset end
 function s:GetScrollOffsetOfEnd() return self.finish end
 function s:SetScrollOffset(v) calls.offsetWrites=calls.offsetWrites+1;self.offset=v end
 local p=owner;for i=1,4 do p.parent=object('parent'..n..'-'..i);p=p.parent end
 s.parent=owner
 records[n]={scopeKey='world',widget=owner,scrollOwner=owner,scroll=s}
end
local failures={};local function check(v,m) if not v then failures[#failures+1]=m end end
local state={}
for n=1,180 do G.tick(state,pc,menu,'world',records,nil,1/30) end
print('idle: parents='..calls.parent..' hover='..calls.hover..' axis='..calls.axis)
check(calls.parent==0 and calls.hover==0,'neutral input traversed unselected card trees')
check(menu.useRightStickInputs,'neutral input without target changed cursor policy')
pc.y=-1;calls.parent=0;calls.hover=0
for n=1,180 do G.tick(state,pc,menu,'world',records,nil,1/30) end
print('no target: parents='..calls.parent..' hover='..calls.hover)
check(calls.parent==0,'non-hovered cards traversed parents before rejecting focus')
check(calls.hover<=200*61,'no-target search retried more than ten times per second')
-- A selected long card starts scrolling within one 100ms selection interval.
records[1].scrollOwner.hover=true
for n=1,4 do G.tick(state,pc,menu,'world',records,nil,1/30) end
check(records[1].scroll.offset>0 and not menu.useRightStickInputs,'selected long card failed to scroll')
local offset=records[1].scroll.offset;pc.y=0;calls.parent=0;calls.hover=0
for n=1,180 do G.tick(state,pc,menu,'world',records,nil,1/30) end
check(records[1].scroll.offset==offset,'neutral input moved a selected card')
check(calls.hover<=180,'neutral input rescanned other cards instead of validating its lease')
records[1].scrollOwner.parent.Visibility=2
G.tick(state,pc,menu,'world',records,nil,1/30)
check(menu.useRightStickInputs,'hiding selected ancestor failed to restore cursor')
-- Cached no-target delay must not survive a new menu mode or changed world.
G.nativeModeChanged(state,menu);records[2].scrollOwner.focus=true;pc.y=-1
for n=1,4 do G.tick(state,pc,menu,'world',records,nil,1/30) end
check(records[2].scroll.offset>0,'new focused target cannot resume')
records[2].scroll.offset=1000;calls.offsetWrites=0
for n=1,30 do G.tick(state,pc,menu,'world',records,nil,1/30) end
check(calls.offsetWrites==0,'clamped scrolling rewrote an unchanged Slate offset')
G.release(state,menu)
assert(#failures==0,table.concat(failures,'; '));print('controller_performance_test passed')
