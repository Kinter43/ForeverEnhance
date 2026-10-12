# Forever Enhance

Version 1.1.0 — WoW Forever, interface 16001. Open with **`/fe`**.

Forever Enhance checks your equipped gear and recommends permanent enchants,
armor kits, weapon oils, sharpening stones, weightstones, scopes, and selected
head/leg/shoulder enhancements. Its catalog contains 190 options, including
Forever's Forceful/Mystic kits, necklace enchants, held-offhand enchants, and
updated oil effects.

## Package layout

The game loads only the six Lua files listed in `ForeverEnhance.toc`. The `dev`
folder contains the mocked regression suite and is not loaded by WoW. Both the
standard manifest and the Forever-specific `_Camelot.toc` manifest are included.

## Install

1. Close WoW.
2. Extract the ZIP. Copy the **ForeverEnhance** folder into your Forever
   client's `Interface/AddOns` folder. The current beta folder is usually:
   `World of Warcraft/_classic_beta_/Interface/AddOns/ForeverEnhance/`.
3. Confirm that `ForeverEnhance.toc` is directly inside that folder. Avoid an
   extra `ForeverEnhance/ForeverEnhance/` nesting level.
4. Start WoW and enable **Forever Enhance** on the AddOns screen.
5. Log into your character and type **`/fe`**.

If your client uses a different installation directory, use the directory that
contains that client's executable. After a beta update, enable **Load out of
date AddOns** if the interface number changes. `/fe debug` prints your current
client/interface number. The package includes a matching `_Camelot.toc` file.

## Use the panel

- **Leveling value** is the default. It keeps expensive endgame enchants out of
  early recommendations. Its spending tiers are editorial categories, rather
  than auction-house price estimates.
- **Max performance** considers every supported option that passes the hard
  restrictions. It can suggest costly enchants for low-level characters when
  the enchant has no recipient-level restriction. It uses practical stat
  weights, not a simulation or a guaranteed best-in-slot ranking.
- **Role: Auto** reads the dominant talent group in Forever's active class
  trait configuration. Below your first talent points, it uses a class leveling
  profile. Split builds are labeled. Click Role to select a different purpose.
- **Feral druids** use the bear profile in Bear/Dire Bear Form and the cat
  profile in Cat Form. Outside those forms, a Feral build defaults to cat;
  choose **Feral bear** manually when planning tank gear.
- **Show: Missing / upgrades** focuses the view. Switch back to All gear to
  review unrecognized enhancements already on your gear.
- Click a row for its benefits, alternatives, source, and crafting materials.
  **Copy name / link** gives you a searchable name and a Wowhead Forever link.
- **Shopping list** groups missing and known upgrade options, plus the materials
  needed for enchanter services. Oils are counted as five-charge containers.
- Equipment tooltips show the current recommendations. They can be disabled.

The panel separates permanent enhancements from temporary oils/stones. The
Forever weapon API also separates class imbues/poisons, so a poison or Windfury
imbue is not mistaken for an active stone. It refreshes after equipment,
level, talents, form, reputation, and item-cache changes. Combat refreshes are
deferred; the visible panel rechecks temporary enhancements every 15 seconds.

## Status meanings

| Label | Meaning |
| --- | --- |
| Missing | The compatible enhancement layer is empty. |
| Already good | A recognized enhancement meets or beats this mode's choice. |
| Upgrade option | A recognized enhancement scores lower for your chosen role. |
| Present: review | An enhancement is present, but this catalog cannot confidently identify it. |
| Check in game | The client did not expose enough information to confirm the layer. |
| No suggestion | No supported choice passes the current level, gear, role, and spending filters. |

Applying a kit replaces an existing permanent enchant on that item. Oils and
stones occupy their own temporary layer. They can coexist with class imbues in
Forever. Different oils/stones compete with each other.

## Commands

| Command | Action |
| --- | --- |
| `/fe` | Open/close the panel. |
| `/fe mode leveling` | Use the default spending policy. |
| `/fe mode power` | Consider all eligible catalog tiers. |
| `/fe role auto` | Detect your build automatically. |
| `/fe role tank` | Plan survival-oriented tank gear. |
| `/fe role strength` | Plan Strength melee gear. |
| `/fe role agility` | Plan Agility melee gear. |
| `/fe role hunter` | Plan ranged hunter gear. |
| `/fe role bear` / `/fe role cat` | Choose a Feral role. |
| `/fe role caster` / `/fe role healer` | Choose spell damage or healing. |
| `/fe role paladintank` | Plan Protection paladin gear. |
| `/fe school frost` | Override the spell school for mixed builds. |
| `/fe school auto` | Restore the detected school. |
| `/fe list` | Print current suggestions in your own chat window. |
| `/fe shopping` | Open the copyable shopping list. |
| `/fe tooltips` | Toggle equipment-tooltip suggestions. |
| `/fe refresh` | Rescan equipped gear. |
| `/fe scale 0.8` | Resize the panel; supported range 0.5–1.5. |
| `/fe reset` | Reset addon settings and window position. |
| `/fe debug` | Print client/API/spec details locally for troubleshooting. |
| `/fe help` | Print command help. |

For a leveling Warrior, start with the default mode and automatic role. If
you're tanking with an Arms/Fury build, set `/fe role tank`; your talent tree
alone cannot tell whether you are tanking that run.

## Coverage and limits

The nine original classes are supported. English recommendation text is used
on every locale. Talent display names are matched first, with Forever's group
order as the locale fallback. You can override the role and spell school.

Quest and reputation enhancements depend on your realm's available content.
Shoulder reputation is checked; quest completion, recipe availability, legacy
bonuses, auction prices, exact damage breakpoints, and raid progression are not
fully modeled. No rating caps are inferred from your existing gear. Source and
reagent information is included so you can check a choice before buying it.

Character requirements and target item-level requirements are separate checks.
Profession requirements normally belong to the crafter; you do not need to
be an enchanter to receive an enchant. Unresolved client tooltip expressions
are omitted or resolved from the current client-data comparison. The live
in-game tooltip and server restrictions take priority during the beta.

The addon has no external dependencies and does not send chat messages,
purchase items, cast spells, or apply enhancements. Applying the selected
upgrade remains a normal in-game action.

## Validation

The included regression suite checks recommendations across 3,456 role,
level, mode, equipment, and enhancement-layer scenarios, plus API adapters,
talent groups, item loading, combat deferral, status tracking, and a mocked
UI/login/command flow. Run `python3 dev/run_tests.py` with a local Lua shared
library installed. It ran successfully under Lua 5.4; the addon source uses
Lua 5.1-compatible syntax and APIs from the Forever client reference.

**This package has not been run inside the actual WoW Forever client.** The
remaining smoke test is: open `/fe`, equip a different item, respec/switch
talent configurations, apply an oil or stone alongside a class imbue, and
confirm the displayed status updates. If a beta build changes an API, enable
`/console scriptErrors 1`, reproduce the error, and retain the error text plus
the `/fe debug` output.

## Source and maintenance

`SOURCES.md` records the client-data references. `Catalog.lua` contains the
enhancement facts and spending categories; `Profiles.lua` contains the role
weights. You can edit those files and `/reload` to adjust a choice. Hard
requirements are `minLevel` / `minItemLevel`; `suggestedLevel` is the leveling
spending policy. Unknown applied enchant IDs stay marked Present: review.
