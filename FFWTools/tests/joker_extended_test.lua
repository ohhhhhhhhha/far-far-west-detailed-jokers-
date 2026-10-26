package.path = 'FFWTools/src/FFWJokerInfo/Scripts/?.lua;' .. package.path
local Effects=require('Effects')
local checks=0
local function near(a,b,m) checks=checks+1; assert(type(a)=='number' and math.abs(a-b)<1e-6,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function eq(a,b,m) checks=checks+1; assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local function value(id,n,i,key)
    local p=Effects.preview(id,{[id]=n},i or {},0)
    assert(p.current.metrics[key],id..' must calculate '..key)
    return p.current.metrics[key].value,p
end
-- Every expected value is hand-derived from retained consumer bytecode, not from DT descriptions.
local cases={
 {'jokerUpgradeFirerateB',2,'attackSpeedBonus',.1},
 {'jokerUpgradeFirerateC',2,'attackSpeedBonus',.2},
 {'jokerPewPewPew',2,'attackSpeedBonus',.4},
 {'jokerBracing',2,'attackSpeedBonus',.1},
 {'jokerBracing',2,'reloadSpeedBonus',.1},
 {'jokerFastHands',2,'reloadSpeedBonus',.4},
 {'jokerUpgradeReloadSpeed',2,'reloadSpeedBonus',.15},
 {'jokerUpgradeDamage',2,'damageBonus',.1},
 {'jokerHeadBang',2,'weakpointDamageBonus',.6},
 {'jokerSharpShooter',2,'weakpointDamageBonus',.4},
 {'jokerWeakLink',2,'weakpointDamageBonus',.7},
 {'jokerWeakLink',8,'normalDamageMultiplier',.1},
 {'jokerHeavyWeapon',2,'damageBonus',.2},
 {'jokerHeavyWeapon',2,'gravityScaleDelta',.6},
 {'jokerChonky',2,'damageBonus',.4},
 {'jokerChonky',2,'gravityScaleDelta',.3},
 {'jokerConsumer',2,'damageBonus',.5},
 {'jokerWellFed',2,'flatHealth',14},
 {'jokerUpgradeHeal',2,'flatHealth',10},
 -- Empty current-version whitelist makes F_GetJokerEffects return zero.
 {'jokerUpgradeShieldPoints',2,'maxShield',100},
 {'jokerExtraDash',2,'dashCount',3},
 {'jokerExtraJump',2,'extraJumps',2},
 {'jokerHop',2,'jumpVelocityBonus',.4},
 {'jokerUpgradeJumpHeight',2,'jumpVelocityBonus',.14},
 {'jokerLightWeight',2,'gravityScaleDelta',-.1},
 {'jokerLowGravity',2,'gravityScaleDelta',-.5},
 {'jokerSpeedyGunzales',2,'moveSpeedDelta',110},
 {'jokerUpgradeHeroSpeed',2,'moveSpeedDelta',44},
 {'jokerDisgrace',2,'moveSpeedDelta',330},
 {'jokerThickSkin',2,'damageReceivedMultiplier',.6},
 {'jokerThickSkin',2,'healingMultiplier',.4},
 {'jokerDeathsDance',2,'shieldDecayPerSecond',4.4},
 {'jokerDoubleDown',2,'shieldGainBonus',.6},
 {'jokerCarePackage',2,'utilityCapacity',3},
 {'jokerRage',2,'cooldown',30},
 {'jokerFreezeOver',3,'shield',125},
 {'jokerToolBox',2,'refillInterval',180},
 {'jokerSlowAndSteady',3,'attackSpeedBonus',-.25},
 {'jokerSlowAndSteady',3,'spreadReduction',.6},
 {'jokerLunge',4,'meleeRangeBonus',.55},
 {'jokerUpgradeWeaponMeleeRange',3,'meleeRangeBonus',.12},
 {'jokerUpgradeAccuracy',3,'spreadReduction',.15},
 {'jokerCoinFlip',2,'headsDamageMultiplier',2.5},
 {'jokerCoinFlip',2,'tailsDamageMultiplier',.25},
 {'jokerRicochet',3,'ricochets',3},
 {'jokerScrubBullet',3,'elementRemovalDamage',30},
 {'jokerUpgradeLifesteal',2,'lifesteal',.02},
 {'jokerVampire',2,'lifesteal',.08},
 {'jokerGlassCannon',2,'damageBonus',.8},
 {'jokerGlassCannon',2,'healthMultiplierDelta',-.5},
 {'jokerLifePact',2,'healthMultiplierDelta',-.6},
 {'jokerWestWizard',2,'healthMultiplierDelta',-.6},
 {'jokerGiant',2,'healthMultiplierDelta',.6},
 {'jokerGoliath',2,'healthMultiplierDelta',.5},
 {'jokerGoliath',2,'sizeDelta',.3},
}
for _,c in ipairs(cases) do near(value(c[1],c[2],{},c[3]),c[4],c[1]..'/'..c[3]) end
-- Impact weights depend on the weapon's LuckMultiplier; missing it is not assumed to be 1.
near(value('jokerPigshot',3,{luckMultiplier=.5},'effectiveChance'),.075)
near(value('jokerExplosiveRounds',3,{luckMultiplier=2},'effectiveChance'),.3)
near(value('jokerHeadshotRefund',3,{luckMultiplier=2},'effectiveChance'),1)
eq(value('jokerBellShot',2,{},'effectiveChance'),nil)
near(value('jokerBellShot',2,{},'baseChance'),.1)
-- Actual low-health code uses two different boundaries; preserve them.
near(value('jokerRelentless',2,{healthRatio=.301},'damageBonus'),.6)
near(value('jokerRelentless',2,{healthRatio=.302},'damageBonus'),0)
near(value('jokerLastStand',2,{healthRatio=.301},'damageReceivedMultiplier'),1)
near(value('jokerLastStand',2,{healthRatio=.3},'damageReceivedMultiplier'),.5)
near(value('jokerLastDance',2,{healthRatio=.3},'moveSpeedDelta'),400)
-- FistRage attack bonus uses presence, whereas PanicAttack duration scales with copies.
near(value('jokerFistRage',4,{fistRageActive=true},'attackSpeedBonus'),.3)
near(value('jokerPanicAttack',2,{panicActive=true},'damageBonus'),.4)
near(value('jokerPanicAttack',2,{},'triggerDuration'),6)
near(value('jokerSoulEater',2,{soulEaterActive=true},'reloadSpeedBonus'),.4)
near(value('jokerSoulEater',2,{},'triggerDuration'),5)
-- Riposte stores its multiplier when the shield event occurs. A new card cannot rewrite it.
local p=Effects.preview('jokerRiposte',{jokerRiposte=1},{riposteValue=2})
near(p.after.metrics.damageMultiplier.value,2)
near(p.after.metrics.nextTriggerDamageMultiplier.value,3)
-- Berserker and Speedster combine a runtime amount with a retained curve.
near(value('jokerBerserker',2,{healthRatio=.25},'meleeDamageBonus'),.75)
near(value('jokerSpeedster',2,{speedsterSpeed=1210},'damageBonus'),.8)
near(value('jokerSpeedster',3,{speedsterSpeed=1210},'damageBonus'),1)
near(value('jokerOneTrick',2,{distinctRarities=3},'damageBonus'),.42)
near(value('jokerEagleLever',2,{consecutiveHits=4},'damageBonus'),.5)
-- Max health sums percentage deltas before multiplication, and uses a 10% multiplier floor.
local hp=Effects.maxHealth({jokerUpgradeHeal=2,jokerWellFed=2,jokerTweakDealer=1,jokerCheapSkate=2,
    jokerGiant=1,jokerGlassCannon=1,jokerLifePact=1,jokerWestWizard=1,jokerGoliath=1},
    {activeCardCount=6,gold=300})
near(hp.value,119)
near(Effects.maxHealth({jokerLifePact=5},{}).value,10)
eq(Effects.maxHealth({jokerTweakDealer=1},{}).value,nil)
print('joker_extended_test: '..checks..' checks passed')
