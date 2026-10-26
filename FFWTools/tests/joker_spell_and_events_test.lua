package.path = 'FFWTools/src/FFWJokerInfo/Scripts/?.lua;' .. package.path
local E=require('Effects')
local checks=0
local function near(a,b,m) checks=checks+1; assert(type(a)=='number' and math.abs(a-b)<1e-6,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function eq(a,b,m) checks=checks+1; assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function v(id,n,i,k)
 local p=E.preview(id,{[id]=n},i or {},0); assert(p.current.metrics[k],id..' must calculate '..k); return p.current.metrics[k].value
end
-- Hoarder uses diminishing odds, not independent 15% rolls or a linear 30%.
near(v('jokerHoarder',2,{},'extraCardChance'),.2608695652173913)
near(v('jokerHoarder',1,{},'extraCardChance'),.15)
-- The actual cooldown transformation is rounded 0.3^weight, not 1 - weight.
near(E.spellCooldown({jokerApprentice=1},{}).value,.89)
near(E.spellCooldown({jokerWestWizard=1},{}).value,.70)
near(E.spellCooldown({jokerApprentice=1,jokerWestWizard=1},{}).value,.62)
near(E.spellCooldown({jokerApprentice=50},{}).value,.1)
near(E.spellCooldown({jokerCantRipOneTrick=1},{baseSpellCooldown=35}).value,.74)
near(E.spellCooldown({jokerCantRipOneTrick=1},{baseSpellCooldown=36}).value,1)
near(E.spellCooldown({jokerCdrFire=2},{spellElement='Fire',elementSpellCounts={Fire=3}}).value,.49)
near(E.spellCooldown({jokerCdrFire=2},{spellElement='Acid',elementSpellCounts={Acid=1}}).value,1)
eq(E.spellCooldown({jokerCdrFire=1},{}).value,nil)
near(E.spellCooldown({jokerApprentice=50},{baseSpellCooldown=3}).seconds,1)
local p=E.preview('jokerApprentice',{jokerApprentice=1,jokerWestWizard=1},{})
near(p.current.metrics.combinedCooldownMultiplier.value,.62)
near(p.after.metrics.combinedCooldownMultiplier.value,.55)
-- CastAway never raises an already shorter cooldown, nor lowers a longer one below 4.
near(v('jokerCastAway',2,{otherSpellRemaining=8},'remainingAfterCast'),4)
near(v('jokerCastAway',2,{otherSpellRemaining=3},'remainingAfterCast'),3)
near(v('jokerCastAway',5,{},'secondsReduced'),10)
near(v('jokerBattleMage',3,{spellRemaining=50},'remainingAfterKill'),49.25)
-- Kill probabilities and healing consume cumulative values directly.
for _,c in ipairs({{'jokerShroomGrave',.3},{'jokerGoldTooth',.3},{'jokerAmmoSupply',.15},
 {'jokerCactusDay',.15},{'jokerAntiGravityFalls',.06},{'jokerPreciousRush',.3}}) do
 near(v(c[1],3,{},'killChance'),c[2],c[1])
end
near(v('jokerLifePact',2,{},'healPerKill'),4)
near(v('jokerEatAPunch',2,{},'healPerMeleeKill'),4)
near(v('jokerFrostBite',2,{},'shieldPerFrozenMeleeKill'),4)
near(v('jokerSnackAPunch',2,{},'shieldPerMeleeKill'),2)
near(v('jokerFreeCocktail',2,{},'healPerEmptyReload'),4)
near(v('jokerRunAndGun',4,{},'activeMoveSpeedDelta'),630)
near(v('jokerRunAndReload',4,{},'activeMoveSpeedDelta'),990)
near(v('jokerMagicFriendship',2,{},'healPerTick'),2)
near(v('jokerMagicFriendship',2,{},'tickInterval'),2)
near(v('jokerLazy',1,{ammoMaximum=15,ammoCurrent=14},'actualAmmoRestored'),1)
near(v('jokerLazy',1,{ammoMaximum=15,ammoCurrent=0},'ammoPerTick'),2)
near(v('jokerTweakDealer',2,{activeCardCount=10},'flatHealth'),20)
near(v('jokerGreatWall',0,{},'damageReceivedMultiplier'),1)
eq(v('jokerBigBoots',2,{},'fallDamageImmune'),true)
eq(v('jokerPlasticDuck',2,{},'duckSound'),true)
near(v('jokerHealthyBoi',2,{healthRatio=1},'attackSpeedBonus'),.4)
near(v('jokerFocusedFeet',2,{aiming=false},'attackSpeedBonus'),0)
near(v('jokerReloadMastery',2,{magazineAmmo=0},'reloadSpeedBonus'),1)
near(v('jokerFrenzySpin',2,{killCombo=10},'attackSpeedBonus'),0)
near(v('jokerFrenzySpin',2,{killCombo=11},'attackSpeedBonus'),3)
-- Data-table item scope remains available even when a formula is unresolved.
eq(E.preview('jokerHoverPack',{},{}).scope,'item')
eq(v('jokerConsumer',0,{},'discardMagazineOnReload'),false)
eq(v('jokerConsumer',2,{},'discardMagazineOnReload'),true)
near(v('jokerConsumer',2,{},'damageBonus'),.5)
eq(E.preview('jokerApprentice',{jokerApprentice=1,jokerCdrFire=1},{}).complete,false,'missing mastery element context keeps combined cooldown incomplete')
print('joker_spell_and_events_test: '..checks..' checks passed')
