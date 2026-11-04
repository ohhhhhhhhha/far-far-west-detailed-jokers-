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
    if not r or r.scopeKey~=scope or (r.widget and not valid(r.widget))
        or not valid(r.scrollOwner) or not valid(r.scroll) then return 0 end
    -- Most retained cards are not selected. Reject them before walking UMG parents.
    local rank=0
    if call(r.scroll,'IsHovered') then rank=3
    elseif call(r.scrollOwner,'IsHovered') or field(r.scrollOwner,'Hover')==true then rank=2
    elseif call(r.scrollOwner,'HasUserFocus',pc) or call(r.scrollOwner,'HasUserFocusedDescendants',pc) then rank=1 end
    if rank>0 and visible(r.scrollOwner) and visible(r.scroll) then return rank end
    return 0
end
function G.release(s,menu)
    if s.menuKey and key(menu)==s.menuKey and field(menu,'useRightStickInputs')==false then
        menu.useRightStickInputs=s.priorRight
    end
    s.menuKey=nil;s.priorRight=nil;s.target=nil;s.selectionTime=nil;s.moving=false
end
function G.nativeModeChanged(s,menu)
    -- The native menu just assigned its new policy. Relinquish the old lease
    -- without writing its previous value over that new policy.
    if s.menuKey==key(menu) then s.menuKey=nil;s.priorRight=nil;s.target=nil;s.selectionTime=nil;s.moving=false end
end
function G.tick(s,pc,menu,scope,records,detail,dt)
    if not valid(pc) or not valid(menu) then return end
    local elapsed=math.max(0,tonumber(dt) or 0)
    dt=math.min(.05,elapsed) -- clamp movement, not target-discovery time
    -- Poll the actual axis before touching retained card trees. Mouse-only users
    -- should not pay for controller target discovery on every menu update.
    local ok,y=pcall(function() return pc:GetInputAnalogKeyState({KeyName=FName('Gamepad_RightY')}) end)
    if not ok then G.release(s,menu);error(y) end
    if type(y)~='number' or y~=y then G.release(s,menu);return end
    s.moving=false
    if math.abs(y)<=.2 then
        if s.menuKey then
            local scroll=detail
            if not valid(scroll) then
                local cached=records[s.target]
                if score(cached,pc,scope)>0 then scroll=cached.scroll end
            end
            local finish=valid(scroll) and call(scroll,'GetScrollOffsetOfEnd')
            if type(finish)~='number' or finish<=0 then G.release(s,menu) end
        end
        s.selectionTime=nil -- new movement should select immediately
        return
    end
    local scroll=detail
    if not valid(scroll) then
        s.selectionTime=(s.selectionTime or .1)+elapsed
        local cached=records[s.target]
        local best=score(cached,pc,scope)
        if best>0 and s.selectionTime<.1-1e-9 then scroll=cached.scroll
        elseif not cached and s.selectionTime<.1-1e-9 then return
        else
            best=0;s.target=nil;s.selectionTime=0
            for id,r in pairs(records) do
                local n=score(r,pc,scope)
                if n>best then best=n;s.target=id;scroll=r.scroll end
            end
        end
    end
    local finish=valid(scroll) and call(scroll,'GetScrollOffsetOfEnd')
    if type(finish)~='number' or finish<=0 then
        local elapsed=s.selectionTime;G.release(s,menu);s.selectionTime=elapsed
        return
    end
    local mk=key(menu)
    if s.menuKey~=mk then
        local target,elapsed=s.target,s.selectionTime
        G.release(s,menu);s.menuKey=mk;s.priorRight=field(menu,'useRightStickInputs')
        s.target=target;s.selectionTime=elapsed
    end
    -- Reserve only the right-stick UI cursor; leave left-stick mappings intact.
    if field(menu,'useRightStickInputs')~=false then menu.useRightStickInputs=false end
    s.moving=true
    local magnitude=(math.min(1,math.abs(y))-.2)/.8
    local delta=(y>0 and -1 or 1)*magnitude*480*dt
    local moved,err=pcall(function()
        local offset=scroll:GetScrollOffset()
        local nextOffset=math.max(0,math.min(finish,offset+delta))
        if nextOffset~=offset then scroll:SetScrollOffset(nextOffset) end
    end)
    if not moved then G.release(s,menu);error(err) end
end
return G
