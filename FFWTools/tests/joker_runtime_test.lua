local checks=0
local world={IsValid=function() return true end,GetFullName=function() return 'World /Game/Levels/L_Lobby.L_Lobby' end,GetAddress=function() return 1 end}
local function actor(o,name,address)
    o.IsValid=function() return true end;o.GetFullName=function() return name end
    o.GetAddress=function() return address end;o.GetWorld=function() return world end
    return o
end
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local keys,loops={},{}
Key={F1=1,F2=2,F3=3,F4=4,F5=5,F6=6,F7=7,F8=8};ModifierKey={SHIFT=16}
RegisterKeyBind=function(key,modifier,fn)
    local k=fn and key..':shift' or key
    assert(not keys[k],'duplicate binding');keys[k]=fn or modifier
end
LoopInGameThreadWithDelay=function(delay,fn) loops[#loops+1]=fn;eq(delay,1000) end
ExecuteInGameThread=function(fn) fn() end
FText=function(s) return s end
local text='伤害 +7%'
local textBlock={IsValid=function() return true end,GetText=function() return {ToString=function() return text end} end,
 SetText=function(_,s) text=s end,GetFullName=function() return 'TextBlock TestCard.Description' end}
local widget={IsValid=function() return true end,IsVisible=function() return true end,
 GetFullName=function() return 'UI_JokerCard_C TestCard' end,jokerName='jokerCrackShot',ItemName='itemQuadCylinder',TextBlock_Description=textBlock}
local function card(label)
    local t={value='重力 -5%',IsValid=function() return true end,GetFullName=function() return 'TextBlock '..label end}
    function t:GetText() return self.value end;function t:SetText(v) self.value=v end
    return {jokerName='jokerLightWeight',TextBlock_Description=t,IsValid=function() return true end,
        IsVisible=function() return true end,GetFullName=function() return 'UI_JokerCard_InGame_C '..label end},t
end
local hover,hoverText=card('Hover');local pickup,pickupText=card('Pickup');local obtained,obtainedText=card('Obtained')
local objects={UI_JokerCard_C={widget},UI_JokerCard_InGame_C={hover,pickup,obtained},
    UI_Joker_InGameOnScreen_C={{SizeBox_35={ToolTipWidget=hover}}},
    UI_SelectableJoker_C={{Button_Joker={GetChildAt=function(_,index) eq(index,0);return pickup end}}},
    UI_ObtainedJoker_C={{UI_JokerCard_InGame=obtained}}}
FindAllOf=function(name) return objects[name] or {} end
local function collection(values) return {ForEach=function(_,fn) for k,v in pairs(values) do fn(k,v) end end} end
local progress={
 selectedItemA_207_DB75D0B645F36A6C80EA10BC4BCAA457='itemQuadCylinder',
 selectedItemB_208_5EFA92804322145CAD0049B5E0A8B48D='itemKnuckles',
 itemJokers_221_B68401A4476969C408297F9FD92F3128=collection({itemQuadCylinder={jokers_13_7822C195413EA2810E969F8C260AA8B6=collection({'jokerCrackShot'})},
 itemHero={jokers_13_7822C195413EA2810E969F8C260AA8B6=collection({'jokerLightWeight','jokerLightWeight'})}}),
 itemsUpgrades_216_1E448EF04C663CC03DC815A885A3CB74=collection({}),
}
local ps={AC_PlayerStateJoker={playerLocalJokers=collection({})}}
local pawn={buffGravity=0,CharacterMovement={GravityScale=1.15},AC_PlayerItems={equipedItem={itemName='itemQuadCylinder'}}}
actor(ps,'PlayerState Local',2);actor(pawn,'Pawn Local',3)
local controller=actor({PlayerState=ps,Pawn=pawn},'PlayerController Local',4)
controller.IsLocalPlayerController=function() return true end
local instance=actor({playerProgress=progress},'GameInstance Local',5)
for _,list in pairs(objects) do for _,o in ipairs(list) do
    o.IsValid=function() return true end;o.GetWorld=function() return world end
end end
package.preload.UEHelpers=function() return {GetPlayerController=function() return controller end,GetGameInstance=function() return instance end} end
-- A sibling mod already owns this generic module name. The bootstrap must not steal it.
local sentinel={fromOtherMod=true};package.loaded.Panel=sentinel
local path='FFWTools/src/FFWJokerInfo/Scripts/main.lua'
local mod=dofile(path)
eq(keys[3],nil,'read-only Info must not register a spawn action')
eq(mod.spawnSelected,nil,'spawning belongs to the standalone Trainer')
eq(package.loaded.Panel,sentinel)
mod.update()
eq(mod.snapshot.complete,true)
eq(text:find('当前 1 张',1,true),nil)
eq(text:find('+7%',1,true)~=nil,true)
eq(text:find('+14%',1,true)~=nil,true)
eq(hoverText.value:find('当前 2 张',1,true),nil)
eq(hoverText.value:find('1.15',1,true)~=nil,true)
eq(hoverText.value:find('8%',1,true)~=nil,true)
eq(hoverText.value:find('获得后',1,true),nil,'Tab tooltip must not pretend to add another card')
eq(pickupText.value:find('获得后 3 张',1,true),nil)
eq(pickupText.value:find('1.15 → 1.1',1,true)~=nil,true)
eq(obtainedText.value:find('获得后',1,true),nil,'already obtained notification is current state')
local once=text
mod.update();eq(text,once,'polling must not append duplicate blocks')
eq(progress.selectedItemA_207_DB75D0B645F36A6C80EA10BC4BCAA457,'itemQuadCylinder')
dofile(path);eq(#loops,1,'smoke reload must not register a second refresh loop')
eq(package.loaded.Panel,sentinel)
mod.stop()
eq(text,'伤害 +7%','stop restores current game description')
eq(hoverText.value,'重力 -5%');eq(pickupText.value,'重力 -5%');eq(obtainedText.value,'重力 -5%')
loops[1]();eq(text,'伤害 +7%','disabled loop must not reapply')
print('joker_runtime_test: '..checks..' checks passed')
