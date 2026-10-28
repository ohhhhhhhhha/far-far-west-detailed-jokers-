-- Fresh engine context only. Never use a retained widget/controller to discover
-- the current world, and never treat IsValid() as proof a reflected call is safe.
local C={}
local function valid(o)
    local ok,v=pcall(function() return o and o:IsValid() end);return ok and v==true
end
local function field(o,key)
    local ok,v=pcall(function() return o and o[key] end)
    if ok and v~=nil and not tostring(v):match('^TrivialObject:') then return v end
end
function C.identity(o)
    if not valid(o) then return end
    local ok,name,address=pcall(function() return o:GetFullName(),o:GetAddress() end)
    if ok and type(name)=='string' and address~=nil then return name..'@'..tostring(address),name end
end
local function objectWorld(o)
    if not valid(o) then return end
    local ok,w=pcall(function() return o:GetWorld() end);if ok and valid(w) then return w end
end
function C.controller()
    local h=require('UEHelpers');local world
    if type(h.GetGameViewportClient)=='function' then
        world=objectWorld(h.GetGameViewportClient())
        if not world then return end -- no viewport during teardown/dedicated server
    elseif type(h.GetWorld)=='function' then world=h.GetWorld() end
    local expected=C.identity(world)
    local function accept(pc)
        if not valid(pc) then return end
        local ok,localPlayer=pcall(function() return pc:IsLocalPlayerController() end)
        if not ok or localPlayer~=true then return end
        local w=objectWorld(pc);local key=C.identity(w)
        if key and (not expected or key==expected) then return pc,w end
    end
    if world and type(StaticFindObject)=='function' then
        local ok,pc=pcall(function()
            local class=StaticFindObject('/Script/Engine.GameplayStatics')
            if valid(class) then return class:GetCDO():GetPlayerController(world,0) end
        end)
        if ok then local current,w=accept(pc);if current then return current,w end end
    end
    -- UEHelpers v3 accepts any IsPlayerController(), including a remote host.
    -- Explicitly select the local controller when the statics path is unavailable.
    for _,pc in ipairs(type(FindAllOf)=='function' and (FindAllOf('PlayerController') or {}) or {}) do
        local current,w=accept(pc);if current then return current,w end
    end
    if type(h.GetPlayerController)=='function' then return accept(h.GetPlayerController()) end
end
function C.owner()
    local controller,world=C.controller();if not controller then return end
    local worldKey,worldName=C.identity(world)
    local controllerKey=C.identity(controller)
    if not worldKey or not controllerKey then return end
    local instance=field(world,'OwningGameInstance')
    if not valid(instance) then
        local h=require('UEHelpers');instance=type(h.GetGameInstance)=='function' and h.GetGameInstance() or nil
    end
    local instanceKey=C.identity(instance);if not instanceKey then return end
    return {controller=controller,gameInstance=instance,world=world,worldName=worldName,
        worldKey=worldKey,controllerKey=controllerKey,ownerKey=table.concat({worldKey,controllerKey,instanceKey},'|')}
end
function C.read(owner)
    local c=owner or C.owner();if not c then return end
    if c.worldName:find('L_OpeningCredits',1,true) or c.worldName:find('L_Map_TitleScreen',1,true) then return end
    local pawn,playerState=field(c.controller,'Pawn'),field(c.controller,'PlayerState')
    if C.identity(objectWorld(pawn))~=c.worldKey or C.identity(objectWorld(playerState))~=c.worldKey then return end
    local pawnKey,stateKey=C.identity(pawn),C.identity(playerState)
    if not pawnKey or not stateKey then return end
    c.pawn=pawn;c.playerState=playerState;c.key=table.concat({c.ownerKey,pawnKey,stateKey},'|')
    return c
end
function C.matches(object,context)
    -- Used for freshly enumerated or native-event objects, not saved old views.
    return context~=nil and C.identity(objectWorld(object))==context.worldKey
end
return C
