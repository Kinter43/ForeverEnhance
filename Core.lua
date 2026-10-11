local addonName, FE = ...
_G.ForeverEnhance = FE
local events=CreateFrame("Frame")
local initialized=false
local refreshQueued=false

function FE.Print(message)
    local target=DEFAULT_CHAT_FRAME
    if target then target:AddMessage("|cff9bd6ffForever Enhance:|r "..tostring(message)) end
end

function FE.Initialize()
    if initialized then return end
    if type(ForeverEnhanceDB)~="table" then ForeverEnhanceDB={} end
    for key,value in pairs(FE.Defaults) do if ForeverEnhanceDB[key]==nil then ForeverEnhanceDB[key]=value end end
    if ForeverEnhanceDB.mode~="leveling" and ForeverEnhanceDB.mode~="power" then ForeverEnhanceDB.mode="leveling" end
    if ForeverEnhanceDB.role~="auto" and not FE.Profiles[ForeverEnhanceDB.role] then ForeverEnhanceDB.role="auto" end
    if type(ForeverEnhanceDB.scale)~="number" then ForeverEnhanceDB.scale=1 end
    initialized=true
end

local function scheduleRefresh()
    FE.dirty=true
    if InCombatLockdown and InCombatLockdown() then if FE.UI.frame then FE.UI.Refresh() end;return end
    if refreshQueued then return end
    refreshQueued=true
    local function refresh()
        refreshQueued=false
        if not initialized then return end
        FE.API.Refresh();FE.UI.Refresh()
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.2,refresh) else refresh() end
end

function FE.ShoppingList()
    FE.API.Refresh()
    local list,counts,materials={},{},{}
    local context=FE.context
    if not context then return "Log into your character first." end
    local all=FE.Engine.BuildRows(FE.gearSet,setmetatable({missingOnly=false},{__index=context}))
    for _, row in ipairs(all) do
        local e=row.recommendation
        if e and (row.status=="missing" or row.status=="upgrade") then
            counts[e.key]=(counts[e.key] or 0)+1
            list[e.key]=e
            -- Finished consumables are listed separately; no double-counting
            -- their craft materials in the enchanter material total.
            if not e.itemID then
                for _, reagent in ipairs(e.reagents or {}) do materials[reagent.name]=(materials[reagent.name] or 0)+reagent.count end
            end
        end
    end
    local keys={}
    for key in pairs(list) do keys[#keys+1]=key end
    table.sort(keys,function(a,b) return list[a].name<list[b].name end)
    local lines={"Forever Enhance - level "..context.level.." "..FE.Profiles[context.role].label,"Mode: "..context.mode,"","Missing enhancements / known upgrade options:"}
    if #keys==0 then lines[#lines+1]="No missing or known upgrade options. Review unrecognized existing enhancements in All gear." end
    for _, key in ipairs(keys) do
        local e=list[key];local count=counts[key]
        local quantity=e.family=="oil" and math.ceil(count/5) or count
        lines[#lines+1]=quantity.." x "..e.name..(e.family=="oil" and " ("..count.." applications, 5 charges each)" or "")
    end
    local names={};for name in pairs(materials) do names[#names+1]=name end;table.sort(names)
    if #names>0 then
        lines[#lines+1]="";lines[#lines+1]="Materials for enchanter services (tips not included):"
        for _, name in ipairs(names) do lines[#lines+1]=materials[name].." x "..name end
    end
    lines[#lines+1]="";lines[#lines+1]="Buy finished kits/oils/stones, or craft them. Check quest/reputation sources before buying materials. Applying an upgrade replaces the current enhancement in that layer."
    return table.concat(lines,"\n")
end

local function addGearTooltip(tooltip)
    if tooltip~=GameTooltip or not initialized or not ForeverEnhanceDB.tooltips then return end
    if InCombatLockdown and InCombatLockdown() then return end
    if not FE.context then FE.API.Refresh() end
    local _,link=FE.API.Safe(tooltip.GetItem,tooltip)
    if not link or not FE.API.Ordinary(link) then return end
    for _, gear in pairs(FE.gearSet or {}) do
        if gear.link==link then
            local entries={}
            local ranked=FE.Engine.Rank(gear,FE.context,"permanent")
            if ranked[1] then entries[#entries+1]="Permanent: "..ranked[1].entry.name:gsub("^Enchant ","") end
            ranked=FE.Engine.Rank(gear,FE.context,"temporary")
            if ranked[1] then entries[#entries+1]="Oil / stone: "..ranked[1].entry.name end
            if #entries>0 then
                tooltip:AddLine(" ");tooltip:AddLine("Forever Enhance",0.6,0.83,1)
                for _, line in ipairs(entries) do tooltip:AddLine(line,1,0.87,0.55,true) end
                tooltip:AddLine("/fe for details and current enhancement status",0.72,0.76,0.82,true)
            end
            return
        end
    end
end

local function installHooks()
    if TooltipDataProcessor and Enum and Enum.TooltipDataType then
        FE.API.Safe(TooltipDataProcessor.AddTooltipPostCall,Enum.TooltipDataType.Item,function(tooltip) addGearTooltip(tooltip) end)
    elseif GameTooltip and FE.API.Safe(GameTooltip.HasScript,GameTooltip,"OnTooltipSetItem") then
        GameTooltip:HookScript("OnTooltipSetItem",addGearTooltip)
    end
    if AddonCompartmentFrame and AddonCompartmentFrame.RegisterAddon then
        FE.API.Safe(AddonCompartmentFrame.RegisterAddon,AddonCompartmentFrame,{
            text="Forever Enhance",icon="Interface\\Icons\\INV_Enchant_EssenceEternalLarge",notCheckable=true,
            func=function() FE.UI.Toggle() end,
        })
    end
end

local function help()
    FE.Print("/fe opens the gear panel. /fe mode leveling|power changes spending policy.")
    FE.Print("/fe role auto|strength|agility|hunter|tank|bear|cat|caster|healer|paladintank")
    FE.Print("/fe school auto|arcane|fire|frost|holy|nature|shadow overrides the spell school for mixed builds.")
    FE.Print("/fe list prints suggestions. /fe shopping copies a shopping list. /fe refresh rescans gear.")
    FE.Print("/fe tooltips toggles equipment tooltips. /fe scale 0.8 changes panel size. /fe reset restores settings.")
    FE.Print("/fe debug prints your client and detected talent groups for troubleshooting.")
end

function FE.Slash(input)
    FE.Initialize()
    local command,arg=(input or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command=command:lower();arg=arg:lower()
    if command=="" or command=="show" then FE.UI.Toggle()
    elseif command=="help" then help()
    elseif command=="mode" then
        if arg~="power" and arg~="leveling" then FE.Print("Use /fe mode leveling or /fe mode power.");return end
        ForeverEnhanceDB.mode=arg;scheduleRefresh();FE.Print("Mode: "..arg)
    elseif command=="role" then
        if arg~="auto" and not FE.Profiles[arg] then FE.Print("Unknown role. Use /fe help for the list.");return end
        ForeverEnhanceDB.role=arg;scheduleRefresh();FE.Print("Role: "..(arg=="auto" and "Automatic" or FE.Profiles[arg].label))
    elseif command=="school" then
        local schools={auto=true,arcane=true,fire=true,frost=true,holy=true,nature=true,shadow=true}
        if not schools[arg] then FE.Print("Use /fe school auto, arcane, fire, frost, holy, nature or shadow.");return end
        ForeverEnhanceDB.school=arg;scheduleRefresh();FE.Print("Spell school: "..arg)
    elseif command=="tooltips" then ForeverEnhanceDB.tooltips=not ForeverEnhanceDB.tooltips;FE.Print("Tooltips "..(ForeverEnhanceDB.tooltips and "on" or "off"))
    elseif command=="refresh" then scheduleRefresh()
    elseif command=="list" then
        FE.API.Refresh()
        for _, row in ipairs(FE.rows or {}) do
            if row.recommendation then FE.Print(FE.SlotNames[row.gear.slot].." ["..row.layer.."]: "..row.recommendation.name.." - "..row.statusLabel) end
        end
    elseif command=="shopping" or command=="shop" then FE.UI.Create();FE.UI.ShowShopping(FE.ShoppingList())
    elseif command=="scale" then
        local scale=tonumber(arg)
        if not scale or scale<0.5 or scale>1.5 then FE.Print("Use a scale between 0.5 and 1.5.");return end
        ForeverEnhanceDB.scale=scale;FE.UI.ApplyPosition()
    elseif command=="reset" then
        ForeverEnhanceDB={};initialized=false;FE.Initialize()
        if FE.UI.frame then FE.UI.frame:ClearAllPoints();FE.UI.frame:SetPoint("CENTER");FE.UI.ApplyPosition() end
        scheduleRefresh();FE.Print("Settings reset.")
    elseif command=="debug" then
        FE.API.Refresh()
        local version,build,_,interface=GetBuildInfo()
        local c=FE.context
        FE.Print("Addon "..FE.version.."; client "..tostring(version).." build "..tostring(build).."; interface "..tostring(interface))
        FE.Print("Class "..tostring(c.class).."; level "..c.level.."; spec "..(c.spec and c.spec.name or "none").."; "..c.method.."; role "..c.role)
        FE.Print("Modern trait groups: "..tostring(C_Traits and C_Traits.GetGroupCurrencyInfo~=nil).."; layered weapon enchants: "..tostring(C_Item and C_Item.GetWeaponEnchantInfo~=nil))
    else help() end
end
SLASH_FOREVERENHANCE1="/fe"
SLASH_FOREVERENHANCE2="/foreverenhance"
SlashCmdList.FOREVERENHANCE=FE.Slash

events:SetScript("OnEvent",function(_,event,arg)
    if event=="ADDON_LOADED" then if arg==addonName then FE.Initialize() end;return end
    if not initialized then FE.Initialize() end
    if event=="PLAYER_LOGIN" then installHooks();scheduleRefresh();FE.Print("Ready. Type /fe to check your gear.")
    elseif event=="UNIT_INVENTORY_CHANGED" and arg~="player" then return
    else scheduleRefresh() end
end)
for _, event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_EQUIPMENT_CHANGED","UNIT_INVENTORY_CHANGED","PLAYER_LEVEL_UP","TRAIT_CONFIG_UPDATED","TRAIT_CONFIG_LIST_UPDATED","PLAYER_TALENT_UPDATE","ACTIVE_TALENT_GROUP_CHANGED","PLAYER_SPECIALIZATION_CHANGED","UPDATE_SHAPESHIFT_FORM","GET_ITEM_INFO_RECEIVED","ITEM_DATA_LOAD_RESULT","UPDATE_FACTION","PLAYER_REGEN_ENABLED"}) do
    FE.API.Safe(events.RegisterEvent,events,event)
end
local elapsed=0
events:SetScript("OnUpdate",function(_,delta)
    elapsed=elapsed+delta
    -- Only the visible panel needs periodically refreshed consumable state.
    if elapsed>=15 then elapsed=0;if initialized and FE.UI.frame and FE.UI.frame:IsShown() then scheduleRefresh() end end
end)
