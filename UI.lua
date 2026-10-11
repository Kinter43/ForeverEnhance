local _, FE = ...
local UI = {}
FE.UI=UI
local colors={ missing={1,0.76,0.35}, upgrade={0.6,0.8,1}, good={0.7,0.87,0.92}, present={0.78,0.78,0.82}, unknown={1,0.8,0.5}, none={0.6,0.62,0.67}, loading={0.7,0.7,0.75} }
local function text(parent,font,size)
    local f=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight")
    if size then f:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",size) end
    f:SetJustifyH("LEFT");f:SetJustifyV("TOP")
    return f
end
local function background(frame)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    frame:SetBackdropColor(0.065,0.075,0.1,0.98)
    frame:SetBackdropBorderColor(0.22,0.3,0.4,1)
end
local function button(parent,label,width,action)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(width or 115,24);b:SetText(label);b:SetScript("OnClick",action)
    return b
end
function UI.Changed()
    FE.API.Refresh();UI.Refresh()
end

function UI.Create()
    if UI.frame then return UI.frame end
    local f=CreateFrame("Frame","ForeverEnhanceFrame",UIParent,"BackdropTemplate")
    UI.frame=f
    f:SetSize(890,625);f:SetPoint("CENTER");background(f)
    f:SetFrameStrata("DIALOG");f:SetMovable(true);f:EnableMouse(true)
    f:SetClampedToScreen(true);f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",function(self)
        self:StopMovingOrSizing()
        local point,_,relative,x,y=self:GetPoint()
        ForeverEnhanceDB.position={point=point,relative=relative,x=x,y=y}
    end)
    f:SetScript("OnShow",function() FE.API.Refresh();UI.Refresh() end)
    f:Hide()
    tinsert(UISpecialFrames,"ForeverEnhanceFrame")
    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",-3,-3)
    local title=text(f,"GameFontNormalLarge",22);title:SetPoint("TOPLEFT",20,-18);title:SetText("FOREVER ENHANCE")
    local sub=text(f,nil,12);sub:SetPoint("TOPLEFT",20,-48);sub:SetWidth(840)
    UI.subtitle=sub
    local helper=text(f,nil,11);helper:SetPoint("TOPLEFT",20,-70);helper:SetWidth(840)
    helper:SetText("Pick an upgrade for your equipped gear. Click any row for benefits, alternatives, and materials.")
    helper:SetTextColor(0.7,0.74,0.8)
    UI.mode=button(f,"",152,function()
        ForeverEnhanceDB.mode=ForeverEnhanceDB.mode=="power" and "leveling" or "power";UI.Changed()
    end);UI.mode:SetPoint("TOPLEFT",20,-94)
    UI.role=button(f,"",195,function()
        local current=ForeverEnhanceDB.role or "auto"
        for i,v in ipairs(FE.RoleOrder) do if v==current then ForeverEnhanceDB.role=FE.RoleOrder[i % #FE.RoleOrder + 1];break end end
        UI.Changed()
    end);UI.role:SetPoint("LEFT",UI.mode,"RIGHT",8,0)
    UI.filter=button(f,"",146,function() ForeverEnhanceDB.missingOnly=not ForeverEnhanceDB.missingOnly;UI.Changed() end)
    UI.filter:SetPoint("LEFT",UI.role,"RIGHT",8,0)
    UI.tooltips=button(f,"",125,function() ForeverEnhanceDB.tooltips=not ForeverEnhanceDB.tooltips;UI.Refresh() end)
    UI.tooltips:SetPoint("LEFT",UI.filter,"RIGHT",8,0)
    local refresh=button(f,"Refresh",92,UI.Changed);refresh:SetPoint("LEFT",UI.tooltips,"RIGHT",8,0)
    local headings={{"SLOT",20,82},{"EQUIPPED ITEM",110,208},{"RECOMMENDATION",330,364},{"STATUS",710,134}}
    for _, h in ipairs(headings) do local label=text(f,"GameFontNormal",11);label:SetPoint("TOPLEFT",h[2],-134);label:SetWidth(h[3]);label:SetText(h[1]);label:SetTextColor(0.6,0.78,0.9) end
    local scroll=CreateFrame("ScrollFrame","ForeverEnhanceScrollFrame",f,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",14,-154);scroll:SetPoint("BOTTOMRIGHT",-34,60)
    UI.scroll=scroll
    local child=CreateFrame("Frame",nil,scroll)
    child:SetSize(840,1);scroll:SetScrollChild(child);UI.child=child;UI.rowWidgets={}
    UI.empty=text(child,nil,14);UI.empty:SetPoint("TOPLEFT",8,-14);UI.empty:SetWidth(815)
    UI.summary=text(f,nil,12);UI.summary:SetPoint("BOTTOMLEFT",20,38);UI.summary:SetWidth(670)
    local shop=button(f,"Shopping list",135,function() UI.ShowShopping(FE.ShoppingList()) end)
    shop:SetPoint("BOTTOMRIGHT",-20,31)
    local footer=text(f,nil,10);footer:SetPoint("BOTTOMLEFT",20,16);footer:SetWidth(840)
    footer:SetText("One permanent enhancement per item. Oils/stones can coexist with class imbues. /fe help")
    footer:SetTextColor(0.65,0.7,0.76)
    UI.ApplyPosition()
    return f
end

function UI.ApplyPosition()
    local f=UI.frame
    if not f then return end
    local scale=math.max(0.5,math.min(1.5,ForeverEnhanceDB.scale or 1))
    local height=UIParent:GetHeight();local width=UIParent:GetWidth()
    if height and width then scale=math.min(scale,(height-35)/625,(width-35)/890) end
    f:SetScale(math.max(0.4,scale))
    local p=ForeverEnhanceDB.position
    if p and type(p.point)=="string" and type(p.x)=="number" and type(p.y)=="number" then
        f:ClearAllPoints();f:SetPoint(p.point,UIParent,p.relative or p.point,p.x,p.y)
    end
end

function UI.MakeRow(index)
    local row=CreateFrame("Button",nil,UI.child)
    row:SetSize(838,66);row:SetPoint("TOPLEFT",4,-(index-1)*68)
    local fill=row:CreateTexture(nil,"BACKGROUND");fill:SetAllPoints();fill:SetColorTexture(index%2==0 and 0.085 or 0.105,0.115,0.15,0.95)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
    row.slot=text(row,nil,11);row.slot:SetPoint("TOPLEFT",2,-9);row.slot:SetSize(82,44)
    row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetPoint("TOPLEFT",94,-11);row.icon:SetSize(30,30)
    row.item=text(row,nil,11);row.item:SetPoint("TOPLEFT",130,-8);row.item:SetSize(174,28)
    row.itemLevel=text(row,nil,10);row.itemLevel:SetPoint("TOPLEFT",130,-40);row.itemLevel:SetSize(174,15);row.itemLevel:SetTextColor(0.66,0.7,0.77)
    row.best=text(row,"GameFontNormal",12);row.best:SetPoint("TOPLEFT",314,-8);row.best:SetSize(369,28)
    row.benefit=text(row,nil,10);row.benefit:SetPoint("TOPLEFT",314,-39);row.benefit:SetSize(369,20)
    row.status=text(row,nil,11);row.status:SetPoint("TOPLEFT",694,-10);row.status:SetSize(138,43)
    row:SetScript("OnClick",function(self) if self.data then UI.ShowDetails(self.data) end end)
    row:SetScript("OnEnter",function(self)
        local data=self.data
        if not data then return end
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        GameTooltip:SetText((FE.SlotNames[data.gear.slot] or "Gear").." - "..data.statusLabel,1,1,1)
        local e=data.recommendation
        if e then GameTooltip:AddLine(e.name,0.65,0.85,1,true);GameTooltip:AddLine(e.benefit,1,1,1,true);GameTooltip:AddLine(e.source,0.8,0.8,0.8,true) end
        GameTooltip:AddLine("Click for details and alternatives.",1,0.85,0.4,true)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave",function() GameTooltip:Hide() end)
    return row
end

function UI.Refresh()
    if not UI.frame or not UI.frame:IsShown() then return end
    local context=FE.context
    if not context then
        UI.subtitle:SetText("Recommendations will load after combat.")
        return
    end
    local profile=FE.Profiles[context.role]
    local spec=context.spec and context.spec.name or "Leveling / no dominant spec"
    if context.method=="split talents" then spec=spec.." (split talents)" end
    UI.subtitle:SetText("Level "..context.level.." "..(context.class or "").."  |  "..spec.."  |  "..profile.label..(ForeverEnhanceDB.role~="auto" and " (manual role)" or " (auto)"))
    UI.mode:SetText(context.mode=="power" and "Mode: Max performance" or "Mode: Leveling value")
    UI.role:SetText("Role: "..(ForeverEnhanceDB.role=="auto" and "Auto" or profile.label))
    UI.filter:SetText(context.missingOnly and "Show: Missing / upgrades" or "Show: All gear")
    UI.tooltips:SetText(ForeverEnhanceDB.tooltips and "Tooltips: On" or "Tooltips: Off")
    local missing,review,rows=0,0,FE.rows or {}
    for i,data in ipairs(rows) do
        local row=UI.rowWidgets[i] or UI.MakeRow(i);UI.rowWidgets[i]=row;row.data=data
        local e,gear=data.recommendation,data.gear
        row.slot:SetText((FE.SlotNames[gear.slot] or "Gear")..(data.layer=="temporary" and "\nOil / stone" or "\nPermanent"))
        row.icon:SetTexture(gear.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.item:SetText(gear.name or "Loading item...")
        row.itemLevel:SetText(gear.itemLevel and "Item level "..gear.itemLevel or "Item info loading")
        row.best:SetText(e and e.name:gsub("^Enchant ","") or (data.status=="loading" and "Loading..." or "No suggestion at this level"))
        row.benefit:SetText(e and e.benefit or (gear.slot==6 and "No supported waist enhancement" or "Click for guidance"))
        local rgb=colors[data.status] or colors.none
        row.status:SetText(data.statusLabel);row.status:SetTextColor(rgb[1],rgb[2],rgb[3])
        row:Show()
    end
    for i=#rows+1,#UI.rowWidgets do UI.rowWidgets[i]:Hide() end
    for _, data in ipairs(FE.Engine.BuildRows(FE.gearSet, setmetatable({missingOnly=false},{__index=context}))) do
        if data.status=="missing" then missing=missing+1 end
        if data.status=="present" or data.status=="upgrade" or data.status=="unknown" then review=review+1 end
    end
    UI.child:SetHeight(math.max(1,#rows*68))
    UI.empty:SetShown(#rows==0)
    if #rows==0 then UI.empty:SetText(context.missingOnly and "No missing or known upgrade options in this view. Switch to All gear to review current enhancements." or "Equip some gear, then click Refresh.") end
    UI.summary:SetText(FE.dirty and "In combat: recommendations will refresh when combat ends." or missing.." missing enhancements  |  "..review.." to review  |  Data: "..FE.dataDate)
end

function UI.Toggle()
    local f=UI.Create()
    if f:IsShown() then f:Hide() else f:Show() end
end

function UI.ShowDetails(row)
    if not UI.detail then
        local d=CreateFrame("Frame","ForeverEnhanceDetails",UIParent,"BackdropTemplate")
        UI.detail=d;d:SetSize(600,465);d:SetPoint("CENTER");d:SetFrameStrata("FULLSCREEN_DIALOG");background(d)
        d:SetClampedToScreen(true);d:SetMovable(true);d:EnableMouse(true);d:RegisterForDrag("LeftButton")
        d:SetScript("OnDragStart",d.StartMoving);d:SetScript("OnDragStop",d.StopMovingOrSizing)
        tinsert(UISpecialFrames,"ForeverEnhanceDetails")
        local close=CreateFrame("Button",nil,d,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-2,-2)
        local scroll=CreateFrame("ScrollFrame",nil,d,"UIPanelScrollFrameTemplate");scroll:SetPoint("TOPLEFT",18,-20);scroll:SetPoint("BOTTOMRIGHT",-36,48)
        local child=CreateFrame("Frame",nil,scroll);child:SetSize(538,1);scroll:SetScrollChild(child)
        d.body=text(child,nil,12);d.body:SetPoint("TOPLEFT");d.body:SetWidth(530);d.child=child;d.scroll=scroll
        d.copy=button(d,"Copy name / link",164,function() if d.entry then UI.CopyEntry(d.entry) end end);d.copy:SetPoint("BOTTOMLEFT",18,14)
        local tip=text(d,nil,10);tip:SetPoint("BOTTOMLEFT",200,20);tip:SetText("Click Copy, then Ctrl+C / Cmd+C.")
    end
    local e=row.recommendation;local gear=row.gear
    local current=row.layer=="temporary" and gear.temporary or gear.permanent
    local lines={"|cff9bd6ff"..(FE.SlotNames[gear.slot] or "Gear").." - "..row.statusLabel.."|r",gear.name or "Gear",""}
    if current and current.present then
        local known=FE.Engine.CurrentEntry(current.id,gear,FE.context)
        lines[#lines+1]="Current: "..(known and known.name or current.text or "Enhancement present (unrecognized)")
        lines[#lines+1]="Replacing an enhancement removes the existing effect in that layer."
        lines[#lines+1]=""
    end
    if e then
        lines[#lines+1]="|cffffd78a"..e.name.."|r"
        lines[#lines+1]=FE.Engine.Reason(e,FE.context)
        lines[#lines+1]=""
        lines[#lines+1]="|cff9bd6ffHow to get it|r"
        lines[#lines+1]=e.source
        if (e.minLevel or 1)>1 then lines[#lines+1]="Use at character level "..e.minLevel.."+." end
        if (e.minItemLevel or 0)>0 then lines[#lines+1]="Target item must be item level "..e.minItemLevel.."+." end
        if e.reagents and #e.reagents>0 then
            local materials={}
            for _, reagent in ipairs(e.reagents) do materials[#materials+1]=reagent.count.." x "..reagent.name end
            lines[#lines+1]="Materials per craft: "..table.concat(materials,", ")
        end
        lines[#lines+1]=""
        lines[#lines+1]="|cff9bd6ffOther options|r"
        for i=2,math.min(4,#row.ranked) do local a=row.ranked[i].entry;lines[#lines+1]=a.name.." - "..a.benefit end
        if #row.ranked<=1 then lines[#lines+1]="No other eligible option in the current mode." end
    else
        lines[#lines+1]=FE.Engine.Reason(nil,FE.context)
        if gear.slot==1 then lines[#lines+1]="Head arcanums enter the catalog at level 50; check their quest availability." end
        if gear.slot==3 then lines[#lines+1]="Shoulder options require the relevant reputation and content unlock. Reputation is checked automatically." end
        if gear.slot==6 then lines[#lines+1]="This catalog has no verified, general-purpose waist enhancement for Forever." end
        if gear.slot==18 and gear.subclassID==19 then lines[#lines+1]="Wands cannot take bow/gun scopes or melee-weapon oils/stones." end
        if row.layer=="temporary" and FE.context.role=="hunter" then lines[#lines+1]="Melee weapon damage stones do not enhance your ranged weapon attacks." end
        if row.layer=="temporary" and (FE.context.role=="cat" or FE.context.role=="bear") then lines[#lines+1]="Ordinary melee damage stones are not recommended for shapeshift attacks." end
    end
    lines[#lines+1]="";lines[#lines+1]="Recommendations use role weights and a spending policy, not a gear simulation or live auction prices. The current in-game tooltip and server rules take priority."
    local d=UI.detail;d.entry=e;d.copy:SetEnabled(e~=nil)
    d.body:SetText(table.concat(lines,"\n"));d.child:SetHeight(math.max(1,d.body:GetStringHeight()+15));d.scroll:SetVerticalScroll(0)
    d:SetScale(UI.frame:GetScale());d:Show()
end

function UI.CopyEntry(entry)
    if not UI.copy then
        local f=CreateFrame("Frame","ForeverEnhanceCopy",UIParent,"BackdropTemplate");UI.copy=f
        f:SetSize(565,142);f:SetPoint("CENTER");f:SetFrameStrata("TOOLTIP");background(f)
        tinsert(UISpecialFrames,"ForeverEnhanceCopy")
        local close=CreateFrame("Button",nil,f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-2,-2)
        local title=text(f,nil,12);title:SetPoint("TOPLEFT",16,-18);title:SetText("Copy this name and source link")
        f.edit=CreateFrame("EditBox",nil,f,"InputBoxTemplate");f.edit:SetSize(525,30);f.edit:SetPoint("TOPLEFT",22,-52);f.edit:SetAutoFocus(false)
        f.edit:SetScript("OnEscapePressed",function() f:Hide() end)
        local help=text(f,nil,11);help:SetPoint("TOPLEFT",16,-102);help:SetText("Ctrl+C / Cmd+C to copy. Paste into a browser or your notes.")
    end
    local url="https://www.wowhead.com/forever/"..(entry.itemID and "item="..entry.itemID or "spell="..entry.spellID)
    local f=UI.copy;f:Show();f.edit:SetText(entry.name.." - "..url);f.edit:SetFocus();f.edit:HighlightText()
end

function UI.ShowShopping(value)
    if not UI.shopping then
        local f=CreateFrame("Frame","ForeverEnhanceShopping",UIParent,"BackdropTemplate");UI.shopping=f
        f:SetSize(610,450);f:SetPoint("CENTER");f:SetFrameStrata("FULLSCREEN_DIALOG");background(f)
        tinsert(UISpecialFrames,"ForeverEnhanceShopping")
        local close=CreateFrame("Button",nil,f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-2,-2)
        local title=text(f,"GameFontNormalLarge",17);title:SetPoint("TOPLEFT",18,-20);title:SetText("Shopping list")
        local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate");scroll:SetPoint("TOPLEFT",22,-54);scroll:SetPoint("BOTTOMRIGHT",-38,52)
        f.edit=CreateFrame("EditBox",nil,scroll)
        f.edit:SetMultiLine(true);f.edit:SetAutoFocus(false);f.edit:SetFontObject(ChatFontNormal or GameFontHighlight)
        f.edit:SetWidth(540);f.edit:SetHeight(310);scroll:SetScrollChild(f.edit)
        f.edit:SetScript("OnEscapePressed",function() f:Hide() end)
        local selectAll=button(f,"Select all",115,function() f.edit:SetFocus();f.edit:HighlightText() end);selectAll:SetPoint("BOTTOMLEFT",18,15)
        local help=text(f,nil,11);help:SetPoint("BOTTOMLEFT",151,21);help:SetText("Ctrl+C / Cmd+C to copy the list.")
    end
    local f=UI.shopping;f:SetScale(UI.frame and UI.frame:GetScale() or 1);f:Show();f.edit:SetText(value);f.edit:SetFocus();f.edit:HighlightText()
end
