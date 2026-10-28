-- Card-specific additions to the shared native boundary; no game process is used.
local E={}
function E.install()
    local e=dofile('FFWTools/tests/overlay_mouse_engine.lua').install()
    local create=e.object
    e.all={};e.controllers={};e.viewport={width=1280,height=800,dpiScale=1}
    function e.object(kind)
        local o=create(kind);e.all[#e.all+1]=o
        o.world=e.controller and e.controller.world
        function o:SetTextOverflowPolicy(value) self.TextOverflowPolicy=value end
        function o:GetViewportSize() return {X=e.viewport.width,Y=e.viewport.height} end
        function o:GetViewportScale() return e.viewport.dpiScale end
        function o:GetPlayerController() return e.controller end
        return o
    end
    local controller=e.newController
    function e.newController(cursor)
        local pc=controller(cursor);pc.localPlayer=true
        function pc:IsLocalPlayerController() return self.localPlayer end
        function pc:IsPlayerController() return true end
        pc.world.name='World /Game/Levels/L_Lobby.L_Lobby';pc.Pawn.world=pc.world
        pc.PlayerState=e.object('PlayerState');pc.PlayerState.world=pc.world
        e.gameInstance=e.gameInstance or e.object('GameInstance')
        pc.world.OwningGameInstance=e.gameInstance
        e.controllers={pc};return pc
    end
    e.newController(false)
    e.helpers={GetPlayerController=function() return e.controllers[1] end,
        GetGameInstance=function() return e.gameInstance end,
        GetWorld=function() return e.controller and e.controller.world end,
        GetGameViewportClient=function() return {IsValid=function() return true end,
            GetWorld=function() return e.controller and e.controller.world end} end}
    e.staleCalls=0
    function e.retire(object)
        if not object then return end
        -- IsValid remains true, matching the reported misleading wrapper state.
        object.IsValid=function() return true end
        for _,method in ipairs({'SetVisibility','RemoveFromParent','SetText','GetText','SetFont',
            'SetPosition','SetSize','SetColorAndOpacity','SetIsEnabled','SetBackgroundColor',
            'SetAutoWrapText','SetScrollOffset','SetPadding'}) do
            object[method]=function() e.staleCalls=e.staleCalls+1;error('retired UObject method '..method) end
        end
        if object.OnClicked then object.OnClicked.Remove=function() e.staleCalls=e.staleCalls+1;error('retired delegate') end end
    end
    function e.retireView(view)
        for _,key in ipairs({'widget','root','background','title','hint','list','detail','search','detailScroll','detailBox','pageLabel'}) do
            local o=view[key];if o then e.retire(o);e.retire(o.Slot) end
        end
        for _,entry in pairs(view.mouse.buttons) do
            for _,key in ipairs({'host','button','label','slot'}) do e.retire(entry[key]) end
        end
    end
    return e
end
return E
