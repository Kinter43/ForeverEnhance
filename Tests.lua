local FE={}
for _, file in ipairs({"Profiles.lua","Catalog.lua","Engine.lua","API.lua"}) do assert(loadfile(file))("ForeverEnhance",FE) end
local E=FE.Engine
local passed=0
local function test(name,fn)
    local ok,err=pcall(fn)
    if not ok then error(name..": "..tostring(err)) end
    passed=passed+1;print("PASS "..name)
end
local function equal(a,b) assert(a==b,tostring(a).." ~= "..tostring(b)) end
local function context(role,level,mode) return {role=role,level=level or 60,mode=mode or "leveling",class="WARRIOR",reputations={}} end
local function gear(slot,loc,subclass,ilvl)
    return {slot=slot,equipLoc=loc or "INVTYPE_CHEST",subclassID=subclass or 0,classID=(slot>=16 and 2 or 4),itemLevel=ilvl or 60,quality=3,name="Test gear",link="item:123:0:0:0:0",permanent={known=true,present=false},temporary={known=true,present=false}}
end
local byKey={};for _, e in ipairs(FE.Catalog) do byKey[e.key]=e end
test("Catalog identities and target restrictions",function()
    local seen={}
    for _, e in ipairs(FE.Catalog) do
        assert(not seen[e.key],"duplicate key "..e.key);seen[e.key]=true
        assert(e.name and e.benefit and e.source and e.slots)
        assert(e.tier>=1 and e.tier<=5)
        assert(e.layer=="permanent" or e.layer=="temporary")
        for stat,n in pairs(e.stats) do assert(type(n)=="number" and n>0,e.key.." invalid stat") end
    end
end)
test("Character level and target item level are distinct",function()
    local e=byKey.item_252488
    assert(not E.Eligible(e,gear(7,nil,nil,34),context("strength",60),true))
    assert(E.Eligible(e,gear(7,nil,nil,35),context("strength",50),true))
    assert(not E.Eligible(e,gear(7,nil,nil,60),context("strength",49),true))
end)
test("Kits cannot enchant head, wrists or waist",function()
    for _, slot in ipairs({1,9,6}) do assert(not E.Eligible(byKey.item_252437,gear(slot),context("strength",60),true)) end
end)
test("Sharp and blunt stones never cross weapon types",function()
    local c=context("strength",35,"power")
    assert(E.Eligible(byKey.item_12404,gear(16,"INVTYPE_WEAPON",7),c))
    assert(not E.Eligible(byKey.item_12404,gear(16,"INVTYPE_WEAPON",4),c))
    assert(E.Eligible(byKey.item_12643,gear(16,"INVTYPE_WEAPON",4),c))
    assert(not E.Eligible(byKey.item_12643,gear(16,"INVTYPE_WEAPON",7),c))
end)
test("2H enchants cannot target one-handed weapons",function()
    assert(not E.Eligible(byKey.spell_1248607,gear(16,"INVTYPE_WEAPON",15),context("caster",60,"power")))
    assert(E.Eligible(byKey.spell_1248607,gear(16,"INVTYPE_2HWEAPON",10),context("caster",60,"power")))
end)
test("Held offhand and shield enchants stay separate",function()
    local c=context("healer",60,"power")
    assert(E.Eligible(byKey.spell_1219577,gear(17,"INVTYPE_HOLDABLE"),c))
    assert(not E.Eligible(byKey.spell_1219577,gear(17,"INVTYPE_SHIELD"),c))
    assert(not E.Eligible(byKey.spell_1219581,gear(17,"INVTYPE_HOLDABLE"),c))
end)
test("Scope excludes wands and melee weapons",function()
    local c=context("hunter",60,"power")
    for _, sub in ipairs({2,3,18}) do assert(E.Eligible(byKey.item_279272,gear(18,"INVTYPE_RANGED",sub),c)) end
    for _, sub in ipairs({7,19,20}) do assert(not E.Eligible(byKey.item_279272,gear(18,"INVTYPE_RANGED",sub),c)) end
end)
test("Hunter does not get melee damage stone recommendations",function()
    equal(#E.Rank(gear(16,"INVTYPE_2HWEAPON",6),context("hunter",60,"power"),"temporary"),0)
end)
test("Feral excludes on-hit procs and ordinary weapon stones",function()
    for _,role in ipairs({"bear","cat"}) do
        local c=context(role,60,"power")
        assert(not E.Eligible(byKey.spell_20034,gear(16,"INVTYPE_2HWEAPON",10),c))
        assert(not E.Eligible(byKey.item_7965,gear(16,"INVTYPE_2HWEAPON",10),c))
        equal(#E.Rank(gear(16,"INVTYPE_2HWEAPON",10),c,"temporary"),0)
    end
end)
test("Spell school influences gloves",function()
    local c=context("caster",60,"power");c.school="frost"
    assert(E.Score(byKey.spell_25074,c)>E.Score(byKey.spell_25078,c))
    c.school="fire";assert(E.Score(byKey.spell_25078,c)>E.Score(byKey.spell_25074,c))
end)
test("Healer prefers healing oil, damage caster prefers wizard oil",function()
    equal(E.Rank(gear(16,"INVTYPE_2HWEAPON",10),context("healer",60,"power"),"temporary")[1].entry.itemID,20748)
    equal(E.Rank(gear(16,"INVTYPE_2HWEAPON",10),context("caster",60,"power"),"temporary")[1].entry.itemID,20749)
end)
test("Leveling policy avoids Crusader on replaceable early gear",function()
    local g=gear(16,"INVTYPE_WEAPON",7)
    assert(E.Rank(g,context("strength",20),"permanent")[1].entry.name~="Enchant Weapon - Crusader")
    equal(E.Rank(g,context("strength",60,"power"),"permanent")[1].entry.name,"Enchant Weapon - Crusader")
end)
test("Off-hand flat damage uses an off-hand penalty",function()
    local e=byKey.item_12404;local c=context("strength",60,"power")
    assert(E.Score(e,c,gear(17,"INVTYPE_WEAPON",7))<E.Score(e,c,gear(16,"INVTYPE_WEAPON",7)))
    equal(E.Rank(gear(17,"INVTYPE_WEAPON",7),c,"temporary")[1].entry.itemID,18262)
end)
test("Reputation-bound shoulders are not suggested before unlock",function()
    local c=context("strength",60,"power");local g=gear(3)
    assert(not E.Eligible(byKey.item_20077,g,c))
    c.reputations[270]=7;assert(not E.Eligible(byKey.item_20077,g,c))
    c.reputations[270]=8;assert(E.Eligible(byKey.item_20077,g,c))
end)
test("Unknown existing enhancement is present, never missing",function()
    local g=gear(9);g.permanent={known=true,present=true,id=999999}
    local c=context("strength");local e=E.Rank(g,c,"permanent")[1].entry
    equal(E.Status(g,"permanent",e,c),"present")
    g.permanent={known=false};equal(E.Status(g,"permanent",e,c),"unknown")
end)
test("Better existing enchants are retained across budget mode changes",function()
    local g=gear(9);local e=byKey.spell_20010;FE.ByEnchantID[1885]=e
    g.permanent={known=true,present=true,id=1885}
    local c=context("strength",35)
    equal(E.Status(g,"permanent",E.Rank(g,c,"permanent")[1].entry,c),"good")
end)
test("Shared enchant IDs resolve to the correct equipped slot",function()
    local c=context("agility",35,"power");local g=gear(15)
    local id=byKey.spell_13419.enchantIDs[1]
    g.permanent={known=true,present=true,id=id}
    equal(E.CurrentEntry(id,g,c).key,"spell_13419")
    equal(E.Status(g,"permanent",byKey.spell_13419,c),"good")
end)
test("Fishing rods are excluded from normal weapon enhancements",function()
    for _, role in ipairs({"strength","caster"}) do
        local g=gear(16,"INVTYPE_2HWEAPON",20)
        equal(#E.Rank(g,context(role,60,"power"),"permanent"),0)
        equal(#E.Rank(g,context(role,60,"power"),"temporary"),0)
    end
end)
test("Recommendations exist and satisfy restrictions across profiles and levels",function()
    local count=0
    for role in pairs(FE.Profiles) do
        for _,level in ipairs({1,5,15,20,25,30,35,40,45,50,55,60}) do
            for _,mode in ipairs({"leveling","power"}) do
                local c=context(role,level,mode)
                for _,g in ipairs({gear(5),gear(7),gear(8),gear(9),gear(16,"INVTYPE_WEAPON",7),gear(16,"INVTYPE_2HWEAPON",10),gear(17,"INVTYPE_SHIELD"),gear(18,"INVTYPE_RANGED",3)}) do
                    for _,layer in ipairs({"permanent","temporary"}) do
                        local ranking=E.Rank(g,c,layer)
                        for i,r in ipairs(ranking) do
                            assert(E.Eligible(r.entry,g,c));assert(r.entry.layer==layer)
                            if i>1 then assert(r.score<=ranking[i-1].score+0.00001) end
                        end
                        count=count+1
                    end
                end
            end
        end
    end
    print("  "..count.." recommendation scenarios checked")
end)
test("Forever trait groups choose the dominant committed tree",function()
    local spec,points,tied=E.SpecFromGroups("WARRIOR",{{groupID=100,orderIndex=0,displayName="Arms"},{groupID=200,orderIndex=1,displayName="Fury"},{groupID=300,orderIndex=2,displayName="Protection"}},{{traitNodeGroupID=100,currencyInfos={{spent=5}}},{traitNodeGroupID=200,currencyInfos={{spent=20}}},{traitNodeGroupID=300,currencyInfos={{spent=0}}}})
    equal(spec.key,"fury");equal(points,20);assert(not tied)
end)
test("Zero talents and split talents are explicitly handled",function()
    local groups={{groupID=10,orderIndex=0,displayName="Holy"},{groupID=20,orderIndex=1,displayName="Protection"}}
    equal(E.SpecFromGroups("PALADIN",groups,{}),nil)
    local _,_,tied=E.SpecFromGroups("PALADIN",groups,{{traitNodeGroupID=10,currencyInfos={{spent=5}}},{traitNodeGroupID=20,currencyInfos={{spent=5}}}})
    assert(tied)
end)
test("Safe API wrapper preserves nils in tuple returns",function()
    local a,b,c,d=FE.API.Safe(function() return 5,nil,7,nil end)
    equal(a,5);equal(b,nil);equal(c,7);equal(d,nil)
    equal(FE.API.Safe(function() error("unavailable") end),nil)
end)

local mockClass="WARRIOR"
UnitClass=function() return "Warrior",mockClass end
UnitLevel=function() return 35 end
InCombatLockdown=function() return false end
Enum={WeaponSlot={MainHand=0,OffHand=1,Ranged=2},ItemEnchantType={Permanent=1,Temporary=2,Imbue=3},TooltipDataType={Item=0},TooltipDataLineType={ItemEnchantmentPermanent=18}}
C_Item={}
test("Modern enchant tracking separates imbues from oils and stones",function()
    C_Item.GetWeaponEnchantInfo=function(slot)
        equal(slot,0)
        return {{hasEnchant=true,enchantType=1,enchantID=1900},{hasEnchant=true,enchantType=3,enchantID=283},{hasEnchant=false,enchantType=2}}
    end
    local state=FE.API.Temporary(16);assert(state.known and not state.present)
    C_Item.GetWeaponEnchantInfo=function() return {{hasEnchant=true,enchantType=3,enchantID=283},{hasEnchant=true,enchantType=2,enchantID=1643,timeLeft=250000}} end
    state=FE.API.Temporary(16);assert(state.known and state.present);equal(state.id,1643)
end)
test("Legacy rogue poison does not falsely prove a stone is active",function()
    C_Item.GetWeaponEnchantInfo=nil;mockClass="ROGUE"
    GetWeaponEnchantInfo=function() return true,1000,0,7,false,0,0,0 end
    assert(not FE.API.Temporary(16).known)
    mockClass="WARRIOR";assert(FE.API.Temporary(16).known)
end)
test("Spec detection uses Forever's active config and group IDs",function()
    C_ClassTalents={GetActiveConfigID=function() return 99 end}
    C_Traits={GetConfigInfo=function(id) equal(id,99);return {treeIDs={77}} end,
        GetGroupDisplayInfoByTreeID=function() return {{groupID=123,orderIndex=2,displayName="Protection"}} end,
        GetGroupCurrencyInfo=function(id,groups) equal(id,99);equal(groups[1],123);return {{traitNodeGroupID=123,currencyInfos={{spent=20}}}} end}
    equal(FE.API.DetectSpec("WARRIOR").key,"protection")
end)
test("Missing item cache delays recommendations and requests data",function()
    local requested
    GetInventoryItemLink=function(_,slot) if slot==5 then return "item:98765:0:0:0:0" end end
    C_Item.GetItemInfoInstant=function() return 98765,"Armor","Plate","INVTYPE_CHEST",123,4,4 end
    C_Item.GetItemInfo=function() return nil end
    C_Item.RequestLoadItemDataByID=function(id) requested=id end
    local g=FE.API.ReadGear()[5];assert(g.pending);equal(requested,98765)
    equal(#E.Rank(g,context("strength"),"permanent"),0)
end)
test("Combat refresh is deferred and does not read gear",function()
    InCombatLockdown=function() return true end
    assert(not FE.API.Refresh());assert(FE.dirty)
    InCombatLockdown=function() return false end
end)

-- UI/event smoke test. Rendering still requires the real WoW client.
local frames={}
local objectMethods={}
local function widget(name)
    local o={name=name,scripts={},shown=false,scale=1}
    return setmetatable(o,{__index=function(_,k) return objectMethods[k] or function() end end})
end
function objectMethods:SetScript(k,v) self.scripts[k]=v end
function objectMethods:HookScript(k,v) self.scripts[k]=v end
function objectMethods:Show() self.shown=true;if self.scripts.OnShow then self.scripts.OnShow(self) end end
function objectMethods:Hide() self.shown=false end
function objectMethods:IsShown() return self.shown end
function objectMethods:SetShown(v) if v then self:Show() else self:Hide() end end
function objectMethods:SetScale(v) self.scale=v end
function objectMethods:GetScale() return self.scale end
function objectMethods:GetHeight() return 1080 end
function objectMethods:GetWidth() return 1920 end
function objectMethods:GetPoint() return "CENTER",UIParent,"CENTER",0,0 end
function objectMethods:SetText(v) self.value=v end
function objectMethods:GetStringHeight() return 250 end
function objectMethods:CreateTexture() return widget() end
function objectMethods:CreateFontString() return widget() end
function objectMethods:HasScript() return true end
function objectMethods:GetItem() return "Test gear","item:98765:0:0:0:0" end
function objectMethods:AddMessage(v) self.lastMessage=v end
CreateFrame=function(_,name,parent,template) local o=widget(name);frames[#frames+1]=o;if name then _G[name]=o end;return o end
UIParent=widget("UIParent");GameTooltip=widget("GameTooltip");DEFAULT_CHAT_FRAME=widget("ChatFrame")
GameFontHighlight={};GameFontNormal={};ChatFontNormal={};UISpecialFrames={};SlashCmdList={};tinsert=table.insert
C_Timer={After=function(_,fn) fn() end}
GetBuildInfo=function() return "1.60.1","70338","",16001 end
TooltipDataProcessor={AddTooltipPostCall=function(_,fn) TooltipDataProcessor.handler=fn end}
C_Item.GetItemInfo=function() return "Test chest",nil,3,35,25 end
C_Item.GetWeaponEnchantInfo=function() return {} end
GetInventoryItemLink=function(_,slot) if slot==5 then return "item:98765:0:0:0:0" end end
for _,file in ipairs({"UI.lua","Core.lua"}) do assert(loadfile(file))("ForeverEnhance",FE) end
test("Addon login and UI creation",function()
    FE.Initialize()
    local dispatcher=frames[#frames]
    dispatcher.scripts.OnEvent(dispatcher,"PLAYER_LOGIN")
    assert(FE.context and FE.rows)
    FE.Slash("");assert(FE.UI.frame:IsShown())
    assert(#FE.UI.rowWidgets>0)
    FE.UI.ShowDetails(FE.rows[1]);assert(FE.UI.detail:IsShown())
    FE.UI.CopyEntry(FE.rows[1].recommendation);assert(FE.UI.copy:IsShown())
    assert(TooltipDataProcessor.handler)
    TooltipDataProcessor.handler(GameTooltip)
end)
test("Shopping list and role overrides",function()
    FE.Slash("role healer");equal(FE.context.role,"healer")
    FE.Slash("mode power");equal(FE.context.mode,"power")
    FE.Slash("shopping");assert(FE.UI.shopping:IsShown());assert(FE.UI.shopping.edit.value:find("Materials for enchanter services",1,true))
    FE.Slash("role nonsense");equal(ForeverEnhanceDB.role,"healer")
    FE.Slash("school frost");equal(FE.context.school,"frost")
    FE.Slash("reset");equal(ForeverEnhanceDB.role,"auto")
end)
test("Filter, resize and empty gear UI",function()
    FE.Slash("scale 0.8");equal(FE.UI.frame:GetScale(),0.8)
    FE.UI.filter.scripts.OnClick();assert(ForeverEnhanceDB.missingOnly)
    GetInventoryItemLink=function() return nil end
    FE.API.Refresh();FE.UI.Refresh();assert(FE.UI.empty:IsShown())
    FE.Slash("debug");assert(DEFAULT_CHAT_FRAME.lastMessage)
end)
print("RESULT: "..passed.." regression tests passed; real client smoke test still required.")
