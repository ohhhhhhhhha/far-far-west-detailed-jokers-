package.path='FFWTools/src/FFWJokerInfo/Scripts/?.lua;'..package.path
local I=require('Inventory')
local checks=0
local function eq(a,b,message) checks=checks+1; assert(a==b,(message or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local s={selected={primary='itemQuadCylinder',secondary='itemKnuckles'},
 equipped={itemQuadCylinder={'jokerCrackShot','jokerCrackShot','jokerOneTrick'},itemKnuckles={'jokerBerserker'},itemHero={'jokerWellFed'}},
 upgrades={itemQuadCylinder={jokerUpgradeDamage=3},itemKnuckles={},itemHero={jokerUpgradeHeal=2}},
 runtime={'jokerCrackShot','jokerWellFed','jokerOverDraw'},inputs={health=40,maxHealth=100},
 inputsByItem={itemQuadCylinder={magazineAmmo=4},itemKnuckles={}}}
local snapshot=I.fromSnapshot(s)
local a=I.group(snapshot,'ITEMQUADCYLINDER')
eq(a.complete,true)
eq(a.counts.jokerCrackShot,3,'per-item equipped plus global task copies')
eq(a.counts.jokerUpgradeDamage,3,'permanent upgrades included')
eq(a.counts.jokerWellFed,nil,'hero card must not leak into weapon counts')
eq(a.counts.jokerOverDraw,nil,'bow-only task card must not apply to gun')
eq(a.parts.jokerCrackShot.equipped,2)
eq(a.parts.jokerCrackShot.runtime,1)
eq(I.group(snapshot,'itemHero').counts.jokerWellFed,2)
eq(I.group(snapshot,'itemKnuckles').counts.jokerCrackShot,1)
eq(a.inputs.health,40)
eq(a.inputs.magazineAmmo,4)
eq(a.inputs.activeCardCount,8,'equipped A+B+hero copies plus global task entries, excludes upgrades')
eq(a.inputs.distinctRarities,2,'only equipped card rarities')
local before=a.inputs.distinctRarities
local input=I.candidateInputs(a,'jokerWeakLink','equip')
eq(input.after.activeCardCount,9)
eq(input.after.distinctRarities,3)
eq(a.inputs.distinctRarities,before,'preview must not change snapshot')
eq(I.candidateInputs(a,'jokerWeakLink','pickup').after.distinctRarities,before,'task pickup does not enter equipped rarity set')
eq(I.applies('jokerCrackShot','itemHero'),false)
eq(I.applies('jokerUpgradeShieldPoints','itemHero'),false,'empty whitelist means no applicability')
eq(#I.groups(snapshot),3)
eq(s.equipped.itemQuadCylinder[1],'jokerCrackShot','source snapshot unchanged')
local missing=I.fromSnapshot({selected=s.selected,equipped=s.equipped,runtime=s.runtime})
eq(I.group(missing,'itemQuadCylinder').complete,false,'unread upgrades cannot silently mean zero')
eq(I.group(missing,'itemQuadCylinder').counts.jokerCrackShot,3,'known contributions retained')
eq(#missing.missing>0,true)
local empty=I.fromSnapshot({selected=s.selected,equipped={},upgrades={},runtime={}})
eq(I.group(empty,'itemHero').complete,true,'successfully read empty collections are known empty')
eq(next(I.group(empty,'itemHero').counts),nil)
local normalized=I.fromSnapshot({selected=s.selected,equipped={ITEMQUADCYLINDER={'JOKERCRACKSHOT'}},upgrades={},runtime={'jokerCrackShot'}})
eq(I.group(normalized,'itemQuadCylinder').counts.jokerCrackShot,2,'FName case normalization')
local fields=I.fields
local function remote(v) return {get=function() return v end} end
local function collection(v) return {ForEach=function(_,fn) for k,value in pairs(v) do fn(remote(k),remote(value)) end end} end
local p={}
p[fields.primary]='itemQuadCylinder';p[fields.secondary]='itemKnuckles'
p[fields.equipped]=collection({itemQuadCylinder={[fields.jokers]=collection({'jokerCrackShot'})}})
p[fields.upgrades]=collection({itemQuadCylinder={[fields.tweaks]=collection({jokerUpgradeDamage=2})}})
local ps={playerHeal=50,playerMaxHeal=100,enemyKillCombo=12,AC_PlayerStateJoker={playerLocalJokers=collection({'jokerCrackShot'}),jokerBloodLustTotalStack=.1,jokerPanicAttackEnabled=false},AC_PlayerState_Shield={shieldPoints=20}}
local observed=I.readObjects({playerProgress=p},ps,{})
local g=I.group(observed,'itemQuadCylinder')
eq(g.complete,true)
eq(g.counts.jokerCrackShot,2)
eq(g.counts.jokerUpgradeDamage,2)
eq(g.inputs.panicActive,false,'false bool is known, not missing')
eq(g.inputs.shield,20)
eq(g.inputs.bloodLustStack,.1)
p[fields.upgrades]={ForEach=function() error('unsupported map') end}
eq(I.group(I.readObjects({playerProgress=p},ps,{}),'itemQuadCylinder').complete,false,'failed read never falls back to zero')
p[fields.upgrades]=collection({})
p[fields.secondary]='itemPistol'
ps.AC_PlayerStateJoker.firstShotLoaded=false
local held={itemName='itemPistol',isAiming=false}
function held:F_GetItemDatas(out)
    assert(type(out)=='table','Blueprint struct out parameter requires a table')
    out[fields.initialized]=true;out[fields.magazine]=3
end
function held:F_GetReloadSpeed(out)
    assert(type(out)=='table','Blueprint scalar out parameter requires a table')
    out.ReloadSpeed=2
end
local pawn={AC_PlayerItems={equipedItem=held},buffGravity=0,CharacterMovement={GravityScale=1.25}}
function pawn:F_IsOnGround(height,out) eq(height,1);out.OnGround=true end
function pawn:F_IsRunning(out) out.Running=false end
function pawn:GetVelocity() return {X=3,Y=4,Z=100} end
local live=I.readObjects({playerProgress=p},ps,pawn)
eq(live.inputs.firstShotLoaded,false,'spent first-shot flag is a known false')
eq(live.inputs.heldMagazineAmmo,3,'Clutch observes actually held weapon data')
eq(I.group(live,'itemPistol').inputs.reloadSpeed,2)
eq(I.group(live,'itemQuadCylinder').inputs.reloadSpeed,1,'unheld weapon derives its own base rate instead of borrowing held rate 2')
eq(live.inputs.groundQueryPassed,true);eq(live.inputs.runningQueryResult,false)
eq(live.inputs.horizontalSpeed,5,'Camper uses XY speed only')
function held:F_GetItemDatas() error('runtime data unavailable') end
local failed=I.readObjects({playerProgress=p},ps,pawn)
eq(failed.inputs.heldMagazineAmmo,nil,'failed actual read must not fall back to another item magazine')
eq(failed.readErrors.F_GetItemDatas:find('runtime data unavailable',1,true)~=nil,true,'record source of missing read for manual test diagnostics')
print('joker_inventory_test: '..checks..' checks passed')
