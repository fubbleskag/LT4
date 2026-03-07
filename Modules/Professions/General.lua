local FQoL = LibStub("AceAddon-3.0"):GetAddon("FQoL")
local Module = FQoL:NewModule("Professions", "AceEvent-3.0", "AceHook-3.0", "AceConsole-3.0")

Module.description = "Quality-of-life improvements for professions, including tracker enhancements and utility commands."

-- Helper to find the tracker module in Midnight (12.0)
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
                        if slot.reagentType == Enum.CraftingReagentType.Basic then
                            local reagents = slot.reagents
                            if reagents and reagents[1] then
                                local primaryID = reagents[1].itemID
                                if primaryID then
                                    if not summary[primaryID] then
                                        summary[primaryID] = {
                                            required = 0,
                                            allIDs = {}
                                        }
                                    end
                                    summary[primaryID].required = summary[primaryID].required + slot.quantityRequired
                                    for _, r in ipairs(reagents) do
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
    end
    
    return summary
end

function Module:OnInitialize()
    FQoL.options.args.modules.args[self:GetName()] = {
        type = "group",
        name = "Professions",
        args = {
            enable = {
                type = "toggle",
                name = "Enable Module",
                order = 1,
                get = function() return FQoL.db.profile.modules[self:GetName()] end,
                set = function(_, val) 
                    FQoL.db.profile.modules[self:GetName()] = val 
                    if val then Module:Enable() else Module:Disable() end
                end,
            },
            summaryView = {
                type = "toggle",
                name = "Summary View",
                desc = "Toggle between individual recipe reagents and a total summary of all tracked recipes.",
                order = 2,
                get = function() return FQoL.db.profile.professionsSummaryView end,
                set = function(_, val) 
                    FQoL.db.profile.professionsSummaryView = val
                    self:UpdateTracker()
                end,
            },
        }
    }

    if FQoL.db.profile.professionsSummaryView == nil then
        FQoL.db.profile.professionsSummaryView = false
    end

    if not FQoL.db.profile.modules[self:GetName()] then
        self:SetEnabledState(false)
    end
end

function Module:OnEnable()
    self:RegisterEvent("TRACKED_RECIPE_UPDATE", "UpdateTracker")
    self:RegisterEvent("BAG_UPDATE", "UpdateTracker")
    self:RegisterEvent("BAG_UPDATE_DELAYED", "UpdateTracker")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateTracker")
    self:RegisterEvent("GET_ITEM_INFO_RECEIVED", "UpdateTracker")
    
    local tracker = GetTrackerModule()
    if tracker and tracker.Update then
        self:SecureHook(tracker, "Update", "OnTrackerUpdate")
    end
    
    self:UpdateTracker()
end

function Module:OnDisable()
    self:UnregisterAllEvents()
    self:UnhookAll()
    if self.toggleButton then self.toggleButton:Hide() end
    if self.summaryFrame then self.summaryFrame:Hide() end
    
    local tracker = GetTrackerModule()
    if tracker and tracker.ContentsFrame then
        tracker.ContentsFrame:Show()
    end
end

function Module:CreateToggleButton(header)
    if not header then return end
    
    if not self.toggleButton then
        local btn = CreateFrame("Button", "FQoL_ProfessionsToggleButton", header, "UIPanelInfoButton")
        btn:SetSize(16, 16)
        
        btn:SetScript("OnClick", function()
            FQoL.db.profile.professionsSummaryView = not FQoL.db.profile.professionsSummaryView
            self:UpdateTracker()
            LibStub("AceConfigRegistry-3.0"):NotifyChange("FQoL")
        end)
        
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
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
    self:DisplaySummary()
end

function Module:OnTrackerUpdate()
    local tracker = GetTrackerModule()
    if tracker and tracker.Header and tracker:IsVisible() then
        self:CreateToggleButton(tracker.Header)
    elseif self.toggleButton then
        self.toggleButton:Hide()
    end
    
    self:DisplaySummary()
end

function Module:DisplaySummary()
    if not FQoL.db.profile.modules[self:GetName()] or not FQoL.db.profile.professionsSummaryView then
        if self.summaryFrame then self.summaryFrame:Hide() end
        local tracker = GetTrackerModule()
        if tracker and tracker.ContentsFrame then
            tracker.ContentsFrame:Show()
        end
        return 
    end

    local tracker = GetTrackerModule()
    if not tracker or not tracker:IsVisible() then
        if self.summaryFrame then self.summaryFrame:Hide() end
        return
    end

    local reagents = GetTrackedReagents()
    
    if not self.summaryFrame then
        -- NATIVE STYLE: No backdrop, just a plain frame for organization
        self.summaryFrame = CreateFrame("Frame", "FQoL_ProfessionsSummary", UIParent)
        self.summaryFrame:SetSize(250, 10)
        
        -- Use the same font as objective lines
        self.summaryFrame.content = self.summaryFrame:CreateFontString(nil, "OVERLAY", "ObjectiveFont")
        self.summaryFrame.content:SetPoint("TOPLEFT", 0, 0)
        self.summaryFrame.content:SetJustifyH("LEFT")
        self.summaryFrame.content:SetSpacing(2)
    end

    -- Align it exactly where the first recipe name would start
    -- In Retail, blocks are indented by about 20px
    self.summaryFrame:SetPoint("TOPLEFT", tracker.Header or tracker, "BOTTOMLEFT", 20, -10)

    local text = ""
    local hasAny = false
    
    local sortedItems = {}
    for primaryID, data in pairs(reagents) do
        table.insert(sortedItems, { id = primaryID, required = data.required, allIDs = data.allIDs })
    end
    table.sort(sortedItems, function(a, b)
        local nameA = C_Item.GetItemNameByID(a.id) or ""
        local nameB = C_Item.GetItemNameByID(b.id) or ""
        return nameA < nameB
    end)

    for _, data in ipairs(sortedItems) do
        local itemName = C_Item.GetItemNameByID(data.id) or "Loading..."
        local currentCount = 0
        for itemID in pairs(data.allIDs) do
            currentCount = currentCount + (C_Item.GetItemCount(itemID, true, false, true, true) or 0)
        end
        
        -- Match Native Objective Colors:
        -- Completed: Green (|cFF00FF00)
        -- Incomplete: White/Grey (|cFFFFFFFF) for name, Gold/Orange for numbers
        if currentCount >= data.required then
            text = text .. string.format("|cFF00FF00%d/%d %s|r\n", currentCount, data.required, itemName)
        else
            -- Native style often puts the progress number in front and colored
            text = text .. string.format("|cFFFFD100%d/%d|r |cFFFFFFFF%s|r\n", currentCount, data.required, itemName)
        end
        hasAny = true
    end
    
    if not hasAny then
        text = "|cFF888888No recipes tracked.|r"
    end
    
    self.summaryFrame.content:SetText(text)
    self.summaryFrame:SetHeight(self.summaryFrame.content:GetHeight())
    self.summaryFrame:Show()
    
    if tracker.ContentsFrame then
        tracker.ContentsFrame:Hide()
    end
end
