package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;'..package.path
local C=require('Scope');local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
for _,role in ipairs({'single-player','listen-host','guest-client'}) do
    local e=dofile('FFWTools/tests/joker_engine.lua').install()
    local localPc=e.controller
    local remote=e.object('RemotePlayerController');remote.world=localPc.world
    remote.IsLocalPlayerController=function() return false end;remote.IsPlayerController=function() return true end
    e.controllers={remote,localPc}
    StaticFindObject('/Script/Engine.GameplayStatics').GetPlayerController=function() return remote end
    local priorFind=FindAllOf
    FindAllOf=function(class) return class=='PlayerController' and e.controllers or {} end
    package.loaded.UEHelpers=nil;package.preload.UEHelpers=function() return e.helpers end
    local context=C.read()
    eq(context.controller,localPc,role..': remote-first enumeration still chooses the local player')
    eq(context.playerState,localPc.PlayerState);eq(context.pawn,localPc.Pawn)
    local stale=e.object('Widget');local old=localPc.world
    localPc.world=e.object('World');localPc.world.name='World /Game/Levels/L_Mission.L_Mission'
    localPc.world.OwningGameInstance=e.gameInstance
    eq(C.read(),nil,role..': mixed old pawn/state and new world is not ready')
    localPc.Pawn.world=localPc.world;localPc.PlayerState.world=localPc.world
    local current=C.read();eq(current~=nil,true);eq(C.matches(stale,current),false)
    local currentWidget=e.object('Widget');eq(C.matches(currentWidget,current),true)
    local savedPawn=localPc.Pawn;localPc.Pawn=nil;eq(C.read(),nil,'no pawn during loading is not a UI context');localPc.Pawn=savedPawn
    for _,map in ipairs({'L_OpeningCredits','L_Map_TitleScreen'}) do
        localPc.world.name='World /Game/Levels/'..map..'.'..map
        eq(C.read(),nil,'front-end map does not expose retained card UI')
    end
    e.controllers={remote};e.controller=nil;eq(C.read(),nil,'a remote player is not a local fallback')
    FindAllOf=priorFind;e.restore()
end
print('joker_scope_test: '..checks..' checks passed')
