-- Right-stick routing for existing scroll boxes. State retains no engine objects.
local G={}
local function valid(o) local ok,v=pcall(function() return o and o:IsValid() end);return ok and v==true end
local function field(o,k) local ok,v=pcall(function() return o and o[k] end);if ok then return v end end
local function key(o) if valid(o) then return o:GetFullName()..'@'..tostring(o:GetAddress()) end end
local function call(o,method,arg) local ok,v=pcall(function() return o[method](o,arg) end);if ok then return v end end
local function visible(o)
    local seen={}
    for _=1,48 do
        if not valid(o) or seen[o] then return false end
        seen[o]=true
        local v=field(o,'Visibility')
        if v==1 or v==2 or field(o,'RenderOpacity')==0 then return false end
        local parent=call(o,'GetParent')
        if not valid(parent) then
            local outer=call(o,'GetOuter')
            if valid(outer) and outer:GetFullName():match('^WidgetTree%s') then parent=call(outer,'GetOuter') end
        end
        if not valid(parent) then return true end
        o=parent
    end
    return false
end
local function score(r,pc,scope)
    if not r or (r.widget and not valid(r.widget)) or r.scopeKey~=scope or not visible(r.scrollOwner) or not visible(r.scroll) then return 0 end
    if call(r.scroll,'IsHovered') then return 3 end
    if call(r.scrollOwner,'IsHovered') or field(r.scrollOwner,'Hover')==true then return 2 end
    if call(r.scrollOwner,'HasUserFocus',pc) or call(r.scrollOwner,'HasUserFocusedDescendants',pc) then return 1 end
    return 0
end
function G.release(s,menu)
    if s.menuKey and key(menu)==s.menuKey and field(menu,'useRightStickInputs')==false then
        menu.useRightStickInputs=s.priorRight
    end
    s.menuKey=nil;s.priorRight=nil;s.target=nil;s.selectionTime=0
end
function G.nativeModeChanged(s,menu)
    -- The native menu just assigned its new policy. Relinquish the old lease
    -- without writing its previous value over that new policy.
    if s.menuKey==key(menu) then s.menuKey=nil;s.priorRight=nil;s.target=nil;s.selectionTime=0 end
end
function G.tick(s,pc,menu,scope,records,detail,dt)
    if not valid(pc) or not valid(menu) then return end
    dt=math.max(0,math.min(.05,tonumber(dt) or 0))
    local scroll=detail
    if not valid(scroll) then
        s.selectionTime=(s.selectionTime or 0)+dt
        local cached=records[s.target]
        local best=score(cached,pc,scope)
        if best>0 and s.selectionTime<.1 then scroll=cached.scroll
        else
            best=0;s.target=nil;s.selectionTime=0
            for id,r in pairs(records) do
                local n=score(r,pc,scope)
                if n>best then best=n;s.target=id;scroll=r.scroll end
            end
        end
    end
    local finish=valid(scroll) and call(scroll,'GetScrollOffsetOfEnd')
    if type(finish)~='number' or finish<=0 then G.release(s,menu);return end
    local mk=key(menu)
    if s.menuKey~=mk then
        G.release(s,menu);s.menuKey=mk;s.priorRight=field(menu,'useRightStickInputs')
    end
    -- This flag controls only the native right-stick UI cursor. Left-stick UI
    -- movement and game input mappings are untouched.
    local ok,y=pcall(function() return pc:GetInputAnalogKeyState({KeyName=FName('Gamepad_RightY')}) end)
    if not ok then G.release(s,menu);error(y) end
    if type(y)~='number' or y~=y then G.release(s,menu);return end
    menu.useRightStickInputs=false
    if math.abs(y)<=.2 then return end
    local magnitude=(math.min(1,math.abs(y))-.2)/.8
    local delta=(y>0 and -1 or 1)*magnitude*480*dt
    local moved,err=pcall(function()
        local offset=scroll:GetScrollOffset()
        scroll:SetScrollOffset(math.max(0,math.min(finish,offset+delta)))
    end)
    if not moved then G.release(s,menu);error(err) end
end
return G
