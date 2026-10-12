local addonName, FE = ...
FE.name = addonName
FE.version = "1.1.0"
FE.dataBuild = "1.60.1.70338"
FE.dataDate = "2026-10-11"

-- Recommendation weights are editorial defaults, not simulated DPS values.
-- Primary-stat weights include their usual contribution to attack power.
FE.Profiles = {
    strength = { label = "Strength melee", weights = { strength=2, agility=0.8, attackPower=1, stamina=0.35, crit=16, haste=16, weaponDamage=5, armor=0.003 }, procs={ crusader=90, fiery=23, recovery=6 } },
    agility = { label = "Agility melee", weights = { strength=0.8, agility=2, attackPower=1, stamina=0.3, crit=18, haste=18, weaponDamage=6, armor=0.003 }, procs={ crusader=48, fiery=24, recovery=5 } },
    hunter = { label = "Ranged hunter", weights = { agility=2.2, attackPower=1, rangedAttackPower=1, stamina=0.3, intellect=0.2, crit=20, haste=15, rangedDamage=8, armor=0.003 } },
    tank = { label = "Tank / survival", weights = { stamina=2.2, defense=3, dodge=22, block=13, armor=0.055, strength=0.6, agility=0.7, attackPower=0.2, weaponDamage=1.2, threat=12, resistance=0.7 }, procs={ crusader=40, recovery=22, lifestealing=12 } },
    bear = { label = "Feral bear", weights = { stamina=2.3, defense=2.5, dodge=20, armor=0.035, agility=1.3, strength=1, attackPower=0.5, resistance=0.5 }, procs={} },
    cat = { label = "Feral cat", weights = { strength=2, agility=1.6, attackPower=1, stamina=0.25, crit=16, haste=12, armor=0.002 }, procs={} },
    caster = { label = "Spell damage", weights = { spellPower=1, intellect=0.4, spirit=0.1, stamina=0.25, crit=12, haste=15, resistance=0.25, armor=0.002 }, procs={ revelation=24, insight=6 } },
    healer = { label = "Healer", weights = { healing=1, spellPower=1, intellect=0.75, spirit=0.4, mp5=4, stamina=0.3, crit=10, haste=15, resistance=0.25, armor=0.002 }, procs={ insight=25 } },
    paladintank = { label = "Protection paladin", weights = { stamina=2, defense=3, dodge=18, block=15, armor=0.05, spellPower=0.7, intellect=0.3, strength=0.3, threat=18, resistance=0.6 }, procs={ recovery=18, crusader=24 } },
}

FE.Classes = {
    WARRIOR = { default="strength", specs={{key="arms",name="Arms",role="strength"},{key="fury",name="Fury",role="strength"},{key="protection",name="Protection",role="tank"}} },
    PALADIN = { default="strength", specs={{key="holy",name="Holy",role="healer"},{key="protection",name="Protection",role="paladintank"},{key="retribution",name="Retribution",role="strength"}} },
    HUNTER = { default="hunter", specs={{key="beastmastery",name="Beast Mastery",role="hunter"},{key="marksmanship",name="Marksmanship",role="hunter"},{key="survival",name="Survival",role="hunter"}} },
    ROGUE = { default="agility", specs={{key="assassination",name="Assassination",role="agility"},{key="combat",name="Combat",role="agility"},{key="subtlety",name="Subtlety",role="agility"}} },
    PRIEST = { default="caster", specs={{key="discipline",name="Discipline",role="healer"},{key="holy",name="Holy",role="healer"},{key="shadow",name="Shadow",role="caster",school="shadow"}} },
    SHAMAN = { default="strength", specs={{key="elemental",name="Elemental",role="caster",school="nature"},{key="enhancement",name="Enhancement",role="strength"},{key="restoration",name="Restoration",role="healer"}} },
    MAGE = { default="caster", specs={{key="arcane",name="Arcane",role="caster",school="arcane"},{key="fire",name="Fire",role="caster",school="fire"},{key="frost",name="Frost",role="caster",school="frost"}} },
    WARLOCK = { default="caster", specs={{key="affliction",name="Affliction",role="caster",school="shadow"},{key="demonology",name="Demonology",role="caster"},{key="destruction",name="Destruction",role="caster",school="fire"}} },
    DRUID = { default="caster", specs={{key="balance",name="Balance",role="caster",school="nature"},{key="feral",name="Feral Combat",role="cat"},{key="restoration",name="Restoration",role="healer"}} },
}

FE.RoleOrder = { "auto", "strength", "agility", "hunter", "tank", "bear", "cat", "caster", "healer", "paladintank" }
for _, profile in pairs(FE.Profiles) do profile.weights.speed=5 end
FE.Profiles.caster.weights.damageSpellPower=1
FE.Profiles.paladintank.weights.damageSpellPower=0.7
FE.SlotOrder = { 1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 16, 17, 18 }
FE.SlotNames = { [1]="Head",[2]="Neck",[3]="Shoulders",[15]="Back",[5]="Chest",[9]="Wrists",[10]="Hands",[6]="Waist",[7]="Legs",[8]="Feet",[16]="Main hand",[17]="Off hand",[18]="Ranged" }
FE.Defaults = { mode="leveling", role="auto", school="auto", missingOnly=false, tooltips=true, scale=1, schema=1 }
