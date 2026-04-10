local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local Module = LT4:NewModule("Professions", "AceEvent-3.0", "AceHook-3.0", "AceConsole-3.0")

Module.description = "Quality-of-life improvements for professions, including tracker enhancements and utility commands."

-- Helper to find the tracker module
local function GetTrackerModule()
    return ProfessionsRecipeTracker or (ObjectiveTrackerFrame and ObjectiveTrackerFrame.ProfessionsRecipeTracker) or PROFESSIONS_RECIPE_TRACKER_MODULE
end

local function GetTrackedReagents()
    local summary = {}
    for _, isRecraft in ipairs({false, true}) do
        local trackedIDs = C_TradeSkillUI.GetRecipesTracked(isRecraft)
        if trackedIDs then
            for _, recipeID in ipairs(trackedIDs) do
                local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, isRecraft)
                if schematic and schematic.reagentSlotSchematics then
                    for _, slot in ipairs(schematic.reagentSlotSchematics) do
                        if slot.reagentType == Enum.CraftingReagentType.Basic and slot.reagents and slot.reagents[1] then
                            local primaryID = slot.reagents[1].itemID
                            if primaryID then
                                if not summary[primaryID] then summary[primaryID] = { required = 0, allIDs = {} } end
                                summary[primaryID].required = summary[primaryID].required + slot.quantityRequired
                                for _, r in ipairs(slot.reagents) do
                                    summary[primaryID].allIDs[r.itemID] = true
                                    C_Item.RequestLoadItemDataByID(r.itemID)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return summary
end

function Module:OnInitialize()
    local options = {
        type = "group",
        name = "Professions",
        args = {
        }
    }
    self.options = options
    LT4:RegisterModuleOptions(self:GetName(), options)
    -- Initialize sub-features if they exist
    if self.InitSkinning then self:InitSkinning() end

    if not LT4:GetModuleEnabled(self:GetName()) then self:SetEnabledState(false) end
end
function Module:HasSkinning()
    local prof1, prof2 = GetProfessions()
    for _, index in pairs({prof1, prof2}) do
        if index then
            local _, _, _, _, _, _, skillLine = GetProfessionInfo(index)
            if skillLine == 393 then return true end
        end
    end
    return false
end

function Module:OnEnable()
    local events = {"TRACKED_RECIPE_UPDATE", "BAG_UPDATE", "BAG_UPDATE_DELAYED", "PLAYER_ENTERING_WORLD", "GET_ITEM_INFO_RECEIVED", "SKILL_LINES_CHANGED"}
    for _, event in ipairs(events) do self:RegisterEvent(event, "RefreshAll") end
    
    local tracker = GetTrackerModule()
    if tracker and tracker.Update then self:SecureHook(tracker, "Update", "OnTrackerUpdate") end
    
    -- Enable sub-features
    if self.EnableSkinning then self:EnableSkinning() end
    
    self:RefreshAll()
    -- Delayed retry for login sequence
    C_Timer.After(2, function() self:RefreshAll() end)
    C_Timer.After(5, function() self:RefreshAll() end)
end

function Module:RefreshAll()
    self:UpdateTracker()
    if self.UpdateSkinningTracker then self:UpdateSkinningTracker() end
end

function Module:OnDisable()
    self:UnregisterAllEvents()
    self:UnhookAll()
    if self.toggleButton then self.toggleButton:Hide() end
    if self.summaryFrame then self.summaryFrame:Hide() end
    if self.UpdateSkinningTracker then self:UpdateSkinningTracker() end
    
    local tracker = GetTrackerModule()
    if tracker and tracker.ContentsFrame then tracker.ContentsFrame:Show() end
end

function Module:CreateToggleButton(header)
    if not header then return end
    if not self.toggleButton then
        local btn = CreateFrame("Button", "LT4_ProfessionsToggleButton", header)
        btn:SetSize(16, 16)
        btn:SetNormalAtlas("poi-workorders")
        btn:SetHighlightAtlas("poi-workorders")
        btn:SetScript("OnClick", function()
            LT4.db.profile.professionsSummaryView = not LT4.db.profile.professionsSummaryView
            self:UpdateTracker()
            LibStub("AceConfigRegistry-3.0"):NotifyChange("LT4")
        end)
        btn:SetScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Recipe Summary")
            GameTooltip:AddLine("Toggle between individual and total view.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", GameTooltip_Hide)
        self.toggleButton = btn
    end
    
    self.toggleButton:SetParent(header)
    if header.MinimizeButton then
        self.toggleButton:SetPoint("RIGHT", header.MinimizeButton, "LEFT", -2, 0)
    else
        self.toggleButton:SetPoint("RIGHT", header, "RIGHT", -25, 0)
    end
    self.toggleButton:Show()
end

function Module:UpdateTracker()
    if self.updateTimer then return end
    self.updateTimer = C_Timer.After(0.1, function()
        self:DisplaySummary()
        self.updateTimer = nil
    end)
end

function Module:OnTrackerUpdate()
    local tracker = GetTrackerModule()
    if tracker and tracker.Header and tracker:IsVisible() then
        self:CreateToggleButton(tracker.Header)
    elseif self.toggleButton then
        self.toggleButton:Hide()
    end
    self:UpdateTracker()
end

function Module:DisplaySummary()
    if not LT4:GetModuleEnabled(self:GetName()) or not LT4.db.profile.professionsSummaryView then
        if self.summaryFrame then self.summaryFrame:Hide() end
        local tracker = GetTrackerModule()
        if tracker and tracker.ContentsFrame then tracker.ContentsFrame:Show() end
        return 
    end

    local tracker = GetTrackerModule()
    if not tracker or not tracker:IsVisible() then
        if self.summaryFrame then self.summaryFrame:Hide() end
        return
    end

    local reagents = GetTrackedReagents()
    if not self.summaryFrame then
        self.summaryFrame = CreateFrame("Frame", "LT4_ProfessionsSummary", UIParent)
        self.summaryFrame:SetSize(250, 10)
        self.summaryFrame.content = self.summaryFrame:CreateFontString(nil, "OVERLAY", "ObjectiveFont")
        self.summaryFrame.content:SetPoint("TOPLEFT", 0, 0)
        self.summaryFrame.content:SetJustifyH("LEFT")
        self.summaryFrame.content:SetSpacing(2)
    end

    self.summaryFrame:SetPoint("TOPLEFT", tracker.Header or tracker, "BOTTOMLEFT", 20, -10)

    local lines = {}
    local sortedItems = {}
    for primaryID, data in pairs(reagents) do
        table.insert(sortedItems, { id = primaryID, required = data.required, allIDs = data.allIDs })
    end
    table.sort(sortedItems, function(a, b)
        return (C_Item.GetItemNameByID(a.id) or "") < (C_Item.GetItemNameByID(b.id) or "")
    end)

    for _, data in ipairs(sortedItems) do
        local itemName = C_Item.GetItemNameByID(data.id) or "Loading..."
        local currentCount = 0
        for itemID in pairs(data.allIDs) do currentCount = currentCount + (C_Item.GetItemCount(itemID, true, false, true, true) or 0) end
        
        if currentCount >= data.required then
            table.insert(lines, string.format("|cFF00FF00%d/%d %s|r", currentCount, data.required, itemName))
        else
            table.insert(lines, string.format("|cFFFFD100%d/%d|r |cFFFFFFFF%s|r", currentCount, data.required, itemName))
        end
    end
    
    if #lines == 0 then table.insert(lines, "|cFF888888No recipes tracked.|r") end
    
    self.summaryFrame.content:SetText(table.concat(lines, "\n"))
    self.summaryFrame:SetHeight(self.summaryFrame.content:GetHeight())
    self.summaryFrame:Show()
    if tracker.ContentsFrame then tracker.ContentsFrame:Hide() end
end
