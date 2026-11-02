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
G.tick(state,pc,menu,'world',records,nil,.05)
assert(menu.useRightStickInputs==false,'targeted long card must reserve right stick')
pc.y=-1;G.tick(state,pc,menu,'world',records,nil,.05)
assert(sa.offset==24 and sb.offset==0,'down must scroll only hovered card')
pc.y=1;G.tick(state,pc,menu,'world',records,nil,.05);assert(sa.offset==0)
pc.y=.15;G.tick(state,pc,menu,'world',records,nil,.05);assert(sa.offset==0,'deadzone drift')
a.hover=false;b.focus=true;pc.y=-1;G.tick(state,pc,menu,'world',records,nil,.05);assert(sb.offset==24,'focus follows selection')
sb.offset=999;G.tick(state,pc,menu,'world',records,nil,.05);assert(sb.offset==1000)
sb.offset=0;G.tick(state,pc,menu,'world',records,nil,5);assert(sb.offset==24,'long frame clamp')
b.parent=object('hidden');b.parent.Visibility=2;local reads=pc.reads
G.tick(state,pc,menu,'world',records,nil,.05);assert(menu.useRightStickInputs and pc.reads==reads,'hidden cards do not steal stick')
b.parent=nil;b.focus=false;sa.finish=0;a.hover=true
G.tick(state,pc,menu,'world',records,nil,.05);assert(menu.useRightStickInputs,'short card leaves cursor alone')
sa.finish=1000;local f7=scroll('F7');G.tick(state,pc,menu,'world',records,f7,.05);assert(f7.offset==24 and sa.offset==0,'F7 priority')
G.release(state,menu);assert(menu.useRightStickInputs==true)
menu.useRightStickInputs=false;G.tick(state,pc,menu,'world',records,f7,.05);G.release(state,menu);assert(menu.useRightStickInputs==false,'preserve original false')
menu.useRightStickInputs=true;G.tick(state,pc,menu,'world',records,f7,.05)
local other=object('newmenu');other.useRightStickInputs=true;menu.valid=false
G.tick(state,pc,other,'newworld',records,nil,.05);assert(other.useRightStickInputs,'old-world targets ignored')
print('controller_scroll_test: target selection, directions, deadzone, bounds, lease and world checks passed')
