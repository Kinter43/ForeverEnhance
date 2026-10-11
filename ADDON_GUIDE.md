# Creating and maintaining the Forever Enhance add-on

## Install this build

1. Close World of Warcraft.
2. Extract `ForeverEnhance-1.0.1.zip`.
3. Copy the extracted `ForeverEnhance` folder to the Forever client's `Interface/AddOns` directory.
4. Verify this exact path exists: `Interface/AddOns/ForeverEnhance/ForeverEnhance.toc`.
5. Start the client, enable **Forever Enhance** in AddOns, log in, and type `/fe`.

Do not leave an extra nesting level such as `ForeverEnhance/ForeverEnhance/ForeverEnhance.toc`.

## How the add-on is assembled

A WoW add-on needs a folder, a `.toc` manifest, and one or more Lua files. The manifest metadata identifies the client interface and SavedVariables. The remaining lines load Lua files in dependency order:

1. `Profiles.lua` — version, settings defaults, class/spec mappings, role weights.
2. `Catalog.lua` — enhancement records and enchant-ID indexes.
3. `Engine.lua` — eligibility, scoring, ranking, and status logic.
4. `API.lua` — safe wrappers around game APIs and gear/spec detection.
5. `UI.lua` — panel, detail views, shopping list, and copy fields.
6. `Core.lua` — initialization, events, tooltips, and `/fe` commands.

The table passed as the second value in `local addonName, FE = ...` is shared by every Lua file because WoW loads them under the same add-on manifest.

## Make a new build

1. Edit the relevant Lua file.
2. Keep the manifest load order unchanged unless dependencies change.
3. Increase `FE.version` in `Profiles.lua` and `## Version` in both `.toc` files.
4. From the directory that contains the `ForeverEnhance` folder, create the archive:

   ```bash
   zip -r ForeverEnhance-1.0.1.zip ForeverEnhance \
     -x '*/.DS_Store' '*/__pycache__/*' '*.pyc'
   ```

5. Run the regression suite from the add-on root:

   ```bash
   python3 dev/run_tests.py
   ```

6. Perform the in-client smoke test: open `/fe`, change equipment, change talents, apply/remove an oil or stone, and confirm the recommendations and statuses refresh.

## Add or change an enhancement

Add a record inside `FE.Catalog` in `Catalog.lua`. Use a unique `key` and provide at least `name`, `layer`, `family`, `slots`, `stats`, `tier`, `minLevel`, `suggestedLevel`, `source`, and `benefit`. Add `spellID` or `itemID` as appropriate. Optional restrictions include `minItemLevel`, `classes`, `roles`, `weaponTypes`, `equipLocs`, and `requiresReputation`. Only add `enchantIDs` that are verified from client data; an incorrect ID can misidentify an equipped enhancement.

Example development record:

```lua
{
    key = "item_123456",
    name = "Example Sharpening Stone",
    itemID = 123456,
    layer = "temporary",
    family = "stone",
    slots = { [16]=true, [17]=true },
    stats = { weaponDamage=5 },
    tier = 3,
    minLevel = 25,
    suggestedLevel = 30,
    source = "Blacksmithing craft; buy the finished stone.",
    benefit = "+5 weapon damage",
    roles = { strength=true, agility=true, tank=true },
    equipLocs = {
        INVTYPE_WEAPON=true,
        INVTYPE_WEAPONMAINHAND=true,
        INVTYPE_WEAPONOFFHAND=true,
        INVTYPE_2HWEAPON=true,
    },
}
```

Add regression coverage in `dev/Tests.lua` for every new targeting or eligibility rule. Catalog facts should also be documented in `SOURCES.md`.

## Add a command

Add another `elseif command=="..."` branch in `FE.Slash` in `Core.lua`, then update the `help()` output, the README command table, and the mocked command tests.

## Add UI behavior

Keep display code in `UI.lua`, game-state reads in `API.lua`, and recommendation policy in `Engine.lua`. Avoid reading protected/secret values in combat; `API.Safe` and the existing combat deferral are intentional safeguards.
