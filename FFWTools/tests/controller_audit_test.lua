package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;'..package.path
local G=require('ControllerScroll')
local function object(name)
 local o={name=name,Visibility=0,hover=false,focus=false,valid=true}
 function o:IsValid() return self.valid end
 function o:GetFullName() return self.name end
 function o:GetAddress() return self.name end
 function o:GetParent() return self.parent end
 function o:GetOuter() return self.outer end
 function o:IsHovered() return self.hover end
 function o:HasUserFocus() return self.focus end
 function o:HasUserFocusedDescendants() return false end
 return o
end
local function scroll(name)
 local s=object(name);s.offset=0;s.finish=1000
 function s:GetScrollOffset() return self.offset end
 function s:GetScrollOffsetOfEnd() return self.finish end
 function s:SetScrollOffset(v) self.offset=v end
 return s
end
FName=function(s) return s end
local pc=object('pc');pc.y=0;pc.reads=0
function pc:GetInputAnalogKeyState(key) assert(key.KeyName=='Gamepad_RightY');self.reads=self.reads+1;return self.y end
local menu=object('menu');menu.useRightStickInputs=true
local a,b=object('cardA'),object('cardB');a.hover=true
local sa,sb=scroll('a'),scroll('b')
local records={a={scopeKey='world',scroll=sa,scrollOwner=a},b={scopeKey='world',scroll=sb,scrollOwner=b}}
local state={}

local failures={};local function check(v,m) if not v then failures[#failures+1]=m end end
pc.y=-1
G.tick(state,pc,menu,'world',records,nil,.05)
local original=sa.GetScrollOffset
sa.GetScrollOffset=function() error('native read failed') end
local ok=pcall(G.tick,state,pc,menu,'world',records,nil,.05)
check(not ok and menu.useRightStickInputs==true and state.menuKey==nil,'scroll failure must restore right-stick cursor')
sa.GetScrollOffset=original
menu.useRightStickInputs=true;G.tick(state,pc,menu,'world',records,nil,.05)
menu.useRightStickInputs=false -- explicit policy of a newly opened native menu
if G.nativeModeChanged then G.nativeModeChanged(state,menu) end
G.release(state,menu)
check(menu.useRightStickInputs==false,'old lease must not overwrite new native menu policy')
assert(#failures==0,table.concat(failures,'; '));print('controller_audit_test passed')
