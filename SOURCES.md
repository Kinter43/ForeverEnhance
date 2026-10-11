# Data and API provenance

Snapshot reviewed on October 11, 2026. Target interface: 16001. Recipe catalog
snapshot: Forever client 1.60.1.70338, published October 10, 2026.

Names, item IDs, spell IDs, effects, and recipe reagents are factual game data.
Recommendations, spending tiers, stat weights, and proc preferences are the
addon's own editorial policy. No third-party addon source or libraries are
included.

## Blizzard client APIs

- Blizzard UI source mirror, Forever branch:
  https://github.com/Gethe/wow-ui-source/tree/forever
- Item API and the distinct Permanent / Temporary / Imbue enchant layers:
  https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua
  https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemConstantsDocumentation.lua
- Client-generated API reference (including trait group display/currency data):
  https://github.com/Atraeau/WoW-Addons/blob/main/types/WowForeverAPI.lua
  https://github.com/Atraeau/WoW-Addons

The addon uses `C_ClassTalents.GetActiveConfigID`,
`C_Traits.GetGroupDisplayInfoByTreeID`, and `C_Traits.GetGroupCurrencyInfo`.
Forever's classic-style trees are trait groups; assuming Retail spec IDs or
requiring old `GetTalentTabInfo` would miss the primary Forever path.

## Enhancement facts

Recipe names, current enchant effects, item/spell IDs, and reagents:

- https://wowforevertalents.com/professions/enchanting/chest-enchants/
- https://wowforevertalents.com/professions/enchanting/bracer-enchants/
- https://wowforevertalents.com/professions/enchanting/glove-enchants/
- https://wowforevertalents.com/professions/enchanting/boots-enchants/
- https://wowforevertalents.com/professions/enchanting/cloak-enchants/
- https://wowforevertalents.com/professions/enchanting/shield-enchants/
- https://wowforevertalents.com/professions/enchanting/weapon-enchants/
- https://wowforevertalents.com/professions/enchanting/two-handed-weapon-enchants/
- https://wowforevertalents.com/professions/enchanting/smaller-headings/
- https://wowforevertalents.com/professions/leatherworking/armor-kits/
- https://wowforevertalents.com/professions/blacksmithing/weapon-stones/
- https://wowforevertalents.com/professions/engineering/smaller-headings/

Item tooltips and character-level requirements were checked using Wowhead's
Forever database and tooltip data. Its dynamic armor-kit placeholders were
resolved against ForeverDiff's current client-data comparisons. Important
kit checks include:

- https://www.wowhead.com/forever/item=252437/forceful-medium-armor-kit
- https://www.wowhead.com/forever/item=252436/mystic-medium-armor-kit
- https://foreverdiff.com/items/forceful-heavy-armor-kit-252453/
- https://foreverdiff.com/items/mystic-heavy-armor-kit-252452/
- https://foreverdiff.com/items/forceful-thick-armor-kit-252463/
- https://foreverdiff.com/items/mystic-thick-armor-kit-252462/
- https://foreverdiff.com/items/forceful-rugged-armor-kit-252488/
- https://foreverdiff.com/items/mystic-rugged-armor-kit-252487/
- https://foreverdiff.com/items/wild-leather-armor-kit-279258/
- https://foreverdiff.com/items/heavy-armor-kit-4265/
- https://foreverdiff.com/items/thick-armor-kit-8173/
- https://foreverdiff.com/items/rugged-armor-kit-15564/

Applied-enchant identifiers were read from the corresponding Wowhead Forever
spell-effect pages where available. Some identifiers are unresolved and are
deliberately not guessed; these applied effects are labeled Present: review.
Several recipes share the same enchant identifier, so applied-enchant matching
checks the actual equipment slot and weapon type.

## Forever stacking rules

Blizzard's class deep dives describe temporary consumables coexisting with
rogue poisons and shaman weapon imbues:

- https://worldofwarcraft.blizzard.com/en-us/news/24310968
- https://worldofwarcraft.blizzard.com/en-us/news/24302097

Quest/reputation enhancements carry explicit source notes. The presence of an
item in beta client data does not establish that a particular realm currently
offers its quest, recipe, vendor, or raid. Treat those sources as conditional.
