local _, FE = ...
local API = {}
FE.API = API
local unpack = unpack or table.unpack
local function pack(...) return { n=select("#",...), ... } end

-- The modern client may return secret values during combat. The addon only
-- refreshes out of combat, and still refuses to compare a secret value.
local function ordinary(value)
    return not (issecretvalue and issecretvalue(value))
end
API.Ordinary = ordinary
function API.Safe(fn, ...)
    if type(fn) ~= "function" then return nil end
    local result = pack(pcall(fn, ...))
    if not result[1] then return nil end
    return unpack(result,2,result.n)
end

function API.DetectSpec(class)
    if C_ClassTalents and C_Traits then
        local configID = API.Safe(C_ClassTalents.GetActiveConfigID)
        local config = configID and API.Safe(C_Traits.GetConfigInfo,configID)
        if config then
            for _, treeID in ipairs(config.treeIDs or {}) do
                local groups = API.Safe(C_Traits.GetGroupDisplayInfoByTreeID,treeID)
                if type(groups)=="table" and #groups>0 then
                    local ids = {}
                    for _, group in ipairs(groups) do ids[#ids+1]=group.groupID end
                    local currencies = API.Safe(C_Traits.GetGroupCurrencyInfo,configID,ids)
                    if type(currencies)=="table" then
                        local spec, points, tied = FE.Engine.SpecFromGroups(class,groups,currencies)
                        if spec then return spec, tied and "split talents" or "talent groups", points end
                    end
                end
            end
        end
    end
    -- Some future builds may expose each tree through SpecializationInfo.
    local classInfo = FE.Classes[class]
    if classInfo and C_SpecializationInfo then
        local selected, most = nil, 0
        for i, spec in ipairs(classInfo.specs) do
            local id, name, _, _, _, _, points = API.Safe(C_SpecializationInfo.GetSpecializationInfo,i,false,false)
            if ordinary(name) and ordinary(points) and type(name)=="string" and type(points)=="number" then
                if FE.Engine.Normalize(name)==FE.Engine.Normalize(spec.name) and points>most then selected,most=spec,points end
            end
        end
        if selected then return selected,"talent points",most end
    end
    -- Classic fallback is feature-tested; it is not the Forever main path.
    if classInfo and GetNumTalentTabs and GetTalentTabInfo then
        local selected, most=nil,0
        local count=API.Safe(GetNumTalentTabs) or 0
        for i=1,math.min(count,3) do
            local _,_,points=API.Safe(GetTalentTabInfo,i)
            if type(points)=="number" and points>most then selected,most=classInfo.specs[i],points end
        end
        if selected then return selected,"classic talent points",most end
    end
    return nil,"no dominant talents",0
end

function API.Context()
    local _, class = UnitClass("player")
    local classInfo = FE.Classes[class]
    local spec, method, points = API.DetectSpec(class)
    local role = spec and spec.role or (classInfo and classInfo.default) or "caster"
    local school = spec and spec.school
    local inferredBear = false
    if class=="DRUID" and GetShapeshiftFormID then
        local form=API.Safe(GetShapeshiftFormID)
        if form==5 or form==8 then role="bear";inferredBear=true
        elseif form==1 then role="cat" end
    end
    local db=ForeverEnhanceDB or FE.Defaults
    if db.role and db.role~="auto" and FE.Profiles[db.role] then role=db.role end
    if role=="caster" and class=="PRIEST" then school=spec and spec.key=="holy" and "holy" or "shadow" end
    if role=="paladintank" then school="holy" end
    if db.school and db.school~="auto" then school=db.school end
    local level=UnitLevel("player")
    if not ordinary(level) or type(level)~="number" or level<1 then level=1 end
    local context={class=class,level=level,role=role,school=school,mode=db.mode,missingOnly=db.missingOnly,spec=spec,method=method,points=points,reputations={},inferredBear=inferredBear}
    for _, id in ipairs({529,270}) do
        local data=C_Reputation and API.Safe(C_Reputation.GetFactionDataByID,id)
        if data and ordinary(data.reaction) then context.reputations[id]=data.reaction
        elseif GetFactionInfoByID then local _,_,standing=API.Safe(GetFactionInfoByID,id);context.reputations[id]=standing end
    end
    return context
end

function API.InventoryLink(slot)
    if GetInventoryItemLink then return API.Safe(GetInventoryItemLink,"player",slot) end
    if C_Item and ItemLocation then
        local location=ItemLocation:CreateFromEquipmentSlot(slot)
        if API.Safe(C_Item.DoesItemExist,location) then return API.Safe(C_Item.GetItemLink,location) end
    end
end

function API.TooltipData(slot)
    return C_TooltipInfo and API.Safe(C_TooltipInfo.GetInventoryItem,"player",slot)
end

function API.CleanText(text)
    if not ordinary(text) or type(text)~="string" then return "" end
    return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1"))
end

function API.CurrentPermanent(link,slot)
    local id=ordinary(link) and tonumber(link:match("item:%d+:(%d+)"))
    local state={known=id~=nil,present=id and id>0 or false,id=id,text=nil}
    local tooltip=API.TooltipData(slot)
    local permanentType=Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.ItemEnchantmentPermanent
    for _, line in ipairs(tooltip and tooltip.lines or {}) do
        if permanentType and ordinary(line.type) and line.type==permanentType then
            state.text=API.CleanText(line.leftText)
        end
    end
    return state
end

function API.Temporary(slot)
    local weaponSlot=slot==16 and 0 or (slot==17 and 1 or 2)
    local enums=Enum and Enum.WeaponSlot
    if enums then weaponSlot=slot==16 and enums.MainHand or (slot==17 and enums.OffHand or enums.Ranged) end
    local temporaryType=Enum and Enum.ItemEnchantType and Enum.ItemEnchantType.Temporary or 2
    if C_Item and C_Item.GetWeaponEnchantInfo and weaponSlot~=nil then
        local enchants=API.Safe(C_Item.GetWeaponEnchantInfo,weaponSlot)
        if type(enchants)=="table" then
            local state={known=true,present=false}
            for _, info in ipairs(enchants) do
                if ordinary(info.enchantType) and info.enchantType==temporaryType and ordinary(info.hasEnchant) and info.hasEnchant then
                    state.present=true
                    if ordinary(info.enchantID) then state.id=info.enchantID end
                    if ordinary(info.timeLeft) then state.timeLeft=info.timeLeft end
                    if ordinary(info.enchantIconID) then state.icon=info.enchantIconID end
                end
            end
            return state
        end
    end
    -- Legacy combines imbues and consumables. On classes with imbues its
    -- positive result cannot prove that a stone/oil is present.
    if GetWeaponEnchantInfo and slot~=18 then
        local a,at,_,ai,b,bt,_,bi=API.Safe(GetWeaponEnchantInfo)
        local present,id,remaining
        if slot==16 then present,id,remaining=a,ai,at else present,id,remaining=b,bi,bt end
        if ordinary(present) and present~=nil then
            local _,class=UnitClass("player")
            if present and (class=="ROGUE" or class=="SHAMAN" or class=="WARLOCK") then return {known=false,present=true,id=id} end
            return {known=true,present=present,id=id,timeLeft=remaining}
        end
    end
    return {known=false,present=false}
end

function API.ReadGear()
    local gearSet={}
    for _, slot in ipairs(FE.SlotOrder) do
        local link=API.InventoryLink(slot)
        if link and ordinary(link) then
            local infoFn=C_Item and C_Item.GetItemInfo or GetItemInfo
            local instantFn=C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
            local id,_,_,equipLoc,icon,classID,subclassID=API.Safe(instantFn,link)
            local name,_,quality,itemLevel,requiredLevel=API.Safe(infoFn,link)
            local gear={slot=slot,link=link,id=id,name=name,quality=quality,itemLevel=itemLevel,requiredLevel=requiredLevel,equipLoc=equipLoc,icon=icon,classID=classID,subclassID=subclassID,pending=not name}
            gear.permanent=API.CurrentPermanent(link,slot)
            if classID==2 and (slot==16 or slot==17) then gear.temporary=API.Temporary(slot) end
            if gear.pending and id and C_Item then API.Safe(C_Item.RequestLoadItemDataByID,id) end
            gearSet[slot]=gear
        end
    end
    return gearSet
end

function API.Refresh()
    if InCombatLockdown and InCombatLockdown() then FE.dirty=true;return false end
    FE.context=API.Context()
    FE.gearSet=API.ReadGear()
    FE.rows=FE.Engine.BuildRows(FE.gearSet,FE.context)
    FE.dirty=false
    return true
end
