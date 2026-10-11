local _, FE = ...
local E = {}
FE.Engine = E

function E.Normalize(text)
    return (tostring(text or ""):lower():gsub("[^%w]", ""))
end

function E.Score(entry, context, gear)
    local profile = FE.Profiles[context.role] or FE.Profiles.caster
    local score = 0
    for stat, value in pairs(entry.stats or {}) do
        local weight = profile.weights[stat] or 0
        if stat=="weaponDamage" and gear and gear.slot==17 then weight=weight*0.5 end
        if stat:match("^school_") and context.school == stat:sub(8) then weight = profile.weights.spellPower or 0 end
        score = score + value * weight
    end
    if entry.proc then score = score + ((profile.procs or {})[entry.proc] or 0) end
    return score
end

function E.SpendingTier(context)
    if context.mode == "power" then return 5 end
    local level = context.level or 1
    if level < 15 then return 1 end
    if level < 30 then return 2 end
    if level < 45 then return 3 end
    return 4
end

function E.Eligible(entry, gear, context, ignoreBudget)
    if not entry.slots[gear.slot] then return false end
    if (context.level or 1) < (entry.minLevel or 1) then return false end
    if (entry.minItemLevel or 0) > 0 and (not gear.itemLevel or gear.itemLevel < entry.minItemLevel) then return false end
    if entry.classes and not entry.classes[context.class] then return false end
    if entry.roles and not entry.roles[context.role] then return false end
    if entry.weaponTypes and not entry.weaponTypes[gear.subclassID] then return false end
    if entry.equipLocs and not entry.equipLocs[gear.equipLoc] then return false end
    if entry.requiresReputation then
        local rep = (context.reputations or {})[entry.requiresReputation.id]
        if not rep or rep < entry.requiresReputation.standing then return false end
    end
    -- Cat and bear attacks do not use ordinary weapon damage/proc effects.
    if (context.role == "cat" or context.role == "bear") and (entry.proc or entry.family == "stone") then return false end
    if not ignoreBudget and context.mode ~= "power" then
        if (entry.tier or 1) > E.SpendingTier(context) then return false end
        if (context.level or 1) < (entry.suggestedLevel or 1) then return false end
    end
    return E.Score(entry, context, gear) > 0
end

function E.Rank(gear, context, layer, ignoreBudget)
    local results = {}
    if not gear or not gear.link or gear.pending then return results end
    for _, entry in ipairs(FE.Catalog) do
        if entry.layer == layer and E.Eligible(entry, gear, context, ignoreBudget) then
            results[#results+1] = { entry=entry, score=E.Score(entry, context, gear) }
        end
    end
    table.sort(results, function(a,b)
        if math.abs(a.score-b.score) > 0.0001 then return a.score > b.score end
        if a.entry.tier ~= b.entry.tier then return a.entry.tier < b.entry.tier end
        return a.entry.key < b.entry.key
    end)
    return results
end

function E.Status(gear, layer, recommendation, context)
    if gear.pending then return "loading", "Loading item" end
    local state = layer == "temporary" and gear.temporary or gear.permanent
    state = state or { known=false }
    if not recommendation then return "none", "No suggestion" end
    if not state.known then return "unknown", "Check in game" end
    if not state.present then return "missing", "Missing" end
    local current = E.CurrentEntry(state.id,gear,context)
    if current and E.Eligible(current, gear, context, true) then
        if current.key == recommendation.key or E.Score(current,context,gear) >= E.Score(recommendation,context,gear)*0.97 then
            return "good", "Already good"
        end
        return "upgrade", "Upgrade option"
    end
    -- Unknown IDs are never treated as missing or safe to overwrite.
    return "present", "Present: review"
end

function E.CurrentEntry(id,gear,context)
    -- One buff ID can be used by enchants for several different slots.
    for _, entry in ipairs((FE.EnchantsByID or {})[id] or {}) do
        if E.Eligible(entry,gear,context,true) then return entry end
    end
    return FE.ByEnchantID[id]
end

function E.Reason(entry, context)
    if not entry then return "No supported enhancement is recommended for this slot at your current level." end
    local profile = FE.Profiles[context.role] or FE.Profiles.caster
    local text = entry.benefit .. ". Chosen for " .. profile.label:lower() .. "."
    if entry.note then text = text .. " " .. entry.note end
    if context.mode == "leveling" then text = text .. " Leveling mode limits spending on gear you may replace." end
    return text
end

function E.BuildRows(gearSet, context)
    local rows = {}
    for _, slot in ipairs(FE.SlotOrder) do
        local gear = gearSet[slot]
        if gear and gear.link then
            local layers = { "permanent" }
            if gear.classID == 2 and (slot==16 or slot==17) then layers[#layers+1] = "temporary" end
            for _, layer in ipairs(layers) do
                local ranking = E.Rank(gear,context,layer)
                local recommendation = ranking[1] and ranking[1].entry
                local status, label = E.Status(gear,layer,recommendation,context)
                local row = { gear=gear, layer=layer, ranked=ranking, recommendation=recommendation, status=status, statusLabel=label }
                if not context.missingOnly or status=="missing" or status=="upgrade" or status=="unknown" then rows[#rows+1]=row end
            end
        end
    end
    return rows
end

-- Matches the three groups inside Forever's active class trait tree.
-- Uses display names first; orderIndex is the locale-independent fallback.
function E.SpecFromGroups(class, groups, currencies)
    local classInfo = FE.Classes[class]
    if not classInfo then return nil end
    local spentByID = {}
    for _, group in ipairs(currencies or {}) do
        local spent = 0
        for _, currency in ipairs(group.currencyInfos or {}) do spent = spent + (currency.spent or 0) end
        spentByID[group.traitNodeGroupID] = spent
    end
    local best, most, tied = nil, 0, false
    for _, group in ipairs(groups or {}) do
        local matched
        local normalized = E.Normalize(group.displayName)
        for _, spec in ipairs(classInfo.specs) do
            if normalized == E.Normalize(spec.name) or normalized == spec.key or
               (spec.key=="elemental" and normalized=="elementalcombat") or
               (spec.key=="feral" and normalized=="feralcombat") then matched=spec; break end
        end
        if not matched and group.orderIndex and group.orderIndex>=0 and group.orderIndex<=2 then matched=classInfo.specs[group.orderIndex+1] end
        local spent = spentByID[group.groupID] or 0
        if matched and spent > most then best,most,tied=matched,spent,false
        elseif matched and spent>0 and spent==most then tied=true end
    end
    return best, most, tied
end
