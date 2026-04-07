local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
local Utils = LumiBar.Utils

local DataBar = {}
LumiBar:RegisterModule("DataBar", DataBar)

-- Midnight Expansion ID is 11
local MIDNIGHT_EXPANSION_ID = 11

-- Midnight Faction Icon Mapping (Sheet 7446932)
local MIDNIGHT_FACTION_ICONS = {
    [2710] = 0, -- Silvermoon
    [2696] = 1, -- Amani
    [2704] = 2, -- Harati
    [2742] = 8, -- Delves
    [2699] = 4, -- Singularity
    [2764] = 5, -- Prey
}

function DataBar:GetMidnightFactions()
    local factions = {}
    local ids = C_MajorFactions.GetMajorFactionIDs()
    if not ids then return factions end

    for _, id in ipairs(ids) do
        local majorData = C_MajorFactions.GetMajorFactionData(id)
        -- Expansion 11 is Midnight
        if majorData and majorData.expansionID == MIDNIGHT_EXPANSION_ID then
            local factionData = C_Reputation.GetFactionDataByID(id)
            local name = (majorData.name) or (factionData and factionData.name) or "Unknown Faction"
            
            local iconIndex = MIDNIGHT_FACTION_ICONS[id] or 0
            local col = iconIndex % 4
            local row = math.floor(iconIndex / 4)

            table.insert(factions, {
                id = id,
                name = name,
                icon = {
                    texture = 7446932,
                    coords = { col * 0.25, (col + 1) * 0.25, row * 0.25, (row + 1) * 0.25 }
                }
            })
        end
    end

    -- Sort for consistency in lists
    table.sort(factions, function(a, b) return a.id < b.id end)

    return factions
end

function DataBar:Init()
    self.db = LumiBar.db.profile.modules.DataBar
    
    -- Ensure defaults for new fields
    if self.db.selectedBars == nil then
        self.db.selectedBars = { ["xp"] = true }
    end
    if self.db.activeBar == nil then
        self.db.activeBar = "xp"
    end

    local options = {
        name = "DataBar",
        type = "group",
        get = function(info) return self.db[info[#info]] end,
        set = function(info, value) 
            self.db[info[#info]] = value
            self:Refresh()
            self:UpdateStatus()
        end,
        args = {
            selection = {
                name = "Selected Bars (Scroll to Cycle)",
                type = "multiselect",
                order = 1,
                values = function()
                    local vals = { ["xp"] = "Experience" }
                    local midnight = self:GetMidnightFactions()
                    for _, f in ipairs(midnight) do
                        vals[tostring(f.id)] = f.name
                    end
                    return vals
                end,
                get = function(info, key)
                    return self.db.selectedBars[key]
                end,
                set = function(info, key, value)
                    self.db.selectedBars[key] = value
                    self:UpdateStatus()
                end,
            },
            textDisplay = {
                name = "Text Display",
                type = "select",
                values = { ["PERCENT"] = "Percentage", ["VALUE"] = "Current Value", ["HIDE"] = "Hide" },
                order = 2,
            },
            barHeight = {
                name = "Bar Height",
                type = "range",
                min = 1, max = 20, step = 1,
                order = 3,
            },
        }
    }
    LumiBar:RegisterModuleOptions("DataBar", options)
end

function DataBar:GetXP()
    local cur = UnitXP("player")
    local max = UnitXPMax("player")
    local rested = GetXPExhaustion() or 0
    return cur, max, rested
end

function DataBar:GetFactionProgress(factionID)
    local data = C_Reputation.GetFactionDataByID(factionID)
    local majorData = C_MajorFactions.GetMajorFactionData(factionID)
    
    if not data and not majorData then return 0, 1, "Unknown", {r=0.5, g=0.5, b=0.5} end

    local label = (data and data.name) or (majorData and "Expansion Track") or "Unknown"
    local cur, max = 0, 1
    local color = { r = 0, g = 1, b = 0 }

    -- 1. Try Renown (Major Faction)
    if majorData then
        cur = majorData.renownReputationEarned or majorData.progress or 0
        max = majorData.renownLevelThreshold or majorData.maxProgress or 2500
        
        if majorData.renownLevel then
            label = string.format("%s (Renown %d)", label, majorData.renownLevel)
        end
        
        -- Fallback for uninitialized major data
        if cur == 0 and max == 2500 and data and data.nextReactionThreshold > 0 then
            cur = data.currentStanding - data.currentReactionThreshold
            max = data.nextReactionThreshold - data.currentReactionThreshold
        end
        
        color = { r = 0, g = 0.8, b = 1 }
        return cur, max, label, color
    end

    -- 2. Try Friendship Reputation (Common for special tracks)
    local friendship = C_GossipInfo.GetFriendshipReputation(factionID)
    if friendship and friendship.friendshipFactionID > 0 then
        label = string.format("%s (%s)", label, friendship.reaction or "")
        cur = friendship.standing - friendship.reactionThreshold
        max = (friendship.nextThreshold or friendship.standing) - friendship.reactionThreshold
        if max <= 0 then cur, max = 1, 1 end
        color = { r = 1, g = 0.5, b = 0 }
        return cur, max, label, color
    end

    -- 3. Standard Reputation Fallback
    if data then
        cur = (data.currentStanding or 0) - (data.currentReactionThreshold or 0)
        max = (data.nextReactionThreshold or 0) - (data.currentReactionThreshold or 0)
        if max <= 0 then cur, max = 1, 1 end
        local reactionColor = FACTION_BAR_COLORS[data.reaction or 4]
        if reactionColor then color = reactionColor end
    end

    return cur, max, label, color
end

function DataBar:FormatText(cur, max, label)
    local display = self.db.textDisplay or "PERCENT"
    if display == "HIDE" then return "" end
    
    local perc = (max > 0) and (cur / max) * 100 or 0
    local str = ""
    
    if display == "PERCENT" then
        str = string.format("%.1f%%", perc)
    elseif display == "VALUE" then
        str = string.format("%s / %s", Utils:FormatNumber(cur), Utils:FormatNumber(max))
    end
    
    if label then
        str = label .. ": " .. str
    end
    return str
end

function DataBar:UpdateStatus()
    local active = self.db.activeBar or "xp"
    local color = { r = 0, g = 0.4, b = 1 } -- Default XP Blue
    
    if active == "xp" then
        local cur, max, rested = self:GetXP()
        self.text:SetText(self:FormatText(cur, max, "XP"))
        self.bar:SetMinMaxValues(0, max)
        self.bar:SetValue(cur)
        
        if rested > 0 then
            self.restedBar:SetMinMaxValues(0, max)
            self.restedBar:SetValue(math.min(cur + rested, max))
            self.restedBar:Show()
        else
            self.restedBar:Hide()
        end
    else
        local factionID = tonumber(active)
        if factionID then
            local cur, max, label, fColor = self:GetFactionProgress(factionID)
            color = fColor
            self.text:SetText(self:FormatText(cur, max, label))
            self.bar:SetMinMaxValues(0, max)
            self.bar:SetValue(cur)
        else
            self.text:SetText("Invalid Bar")
            self.bar:SetValue(0)
            self.bar:SetMinMaxValues(0, 1)
        end
        self.restedBar:Hide()
    end
    
    self.bar:SetStatusBarColor(color.r, color.g, color.b)
    self.bar.bg:SetVertexColor(color.r * 0.2, color.g * 0.2, color.b * 0.2, 0.8)
    if active == "xp" then
        self.restedBar:SetStatusBarColor(color.r, color.g, color.b, 0.4)
    end
    
    self:UpdateWidth()
end

function DataBar:UpdateWidth()
    if not self.bar then return end
    local barW = 150
    Utils:UpdateModuleWidth(self, barW + 24, nil)
end

function DataBar:GetFlyoutItems()
    local items = {}
    
    -- XP Item
    local xpCur, xpMax, xpRested = self:GetXP()
    local xpPerc = (xpMax > 0) and (xpCur / xpMax) * 100 or 0
    table.insert(items, {
        name = "Experience",
        icon = "player", -- Special handling in SecureFlyout
        value = string.format("%d%%", xpPerc),
        bar = xpPerc,
        isActive = (self.db.activeBar == "xp"),
        type = "macro",
        macrotext = "/run LibStub('AceAddon-3.0'):GetAddon('LT4'):GetModule('LumiBar').Modules['DataBar']:SetActiveBar('xp')",
    })

    -- Midnight Factions
    local midnight = self:GetMidnightFactions()
    for _, f in ipairs(midnight) do
        local cur, max, label, color = self:GetFactionProgress(f.id)
        local perc = (max > 0) and (cur / max) * 100 or 0
        table.insert(items, {
            name = f.name,
            icon = f.icon,
            value = string.format("%d%%", perc),
            bar = perc,
            isActive = (self.db.activeBar == tostring(f.id)),
            type = "macro",
            macrotext = "/run LibStub('AceAddon-3.0'):GetAddon('LT4'):GetModule('LumiBar').Modules['DataBar']:SetActiveBar('" .. f.id .. "')",
        })
    end

    return items
end

function DataBar:SetActiveBar(id)
    self.db.activeBar = id
    self:UpdateStatus()
end

function DataBar:CycleBar(delta)
    local available = {}
    if self.db.selectedBars["xp"] then table.insert(available, "xp") end
    
    local midnight = self:GetMidnightFactions()
    for _, f in ipairs(midnight) do
        if self.db.selectedBars[tostring(f.id)] then
            table.insert(available, tostring(f.id))
        end
    end

    if #available <= 1 then return end

    local currentIdx = 1
    for i, id in ipairs(available) do
        if id == self.db.activeBar then
            currentIdx = i
            break
        end
    end

    local nextIdx = currentIdx - delta
    if nextIdx > #available then nextIdx = 1 end
    if nextIdx < 1 then nextIdx = #available end

    self:SetActiveBar(available[nextIdx])
end

function DataBar:ShowTooltip(f)
    local active = self.db.activeBar or "xp"
    local position = LumiBar.db.profile.bar.position or "BOTTOM"
    local anchor = (position == "BOTTOM") and "ANCHOR_TOP" or "ANCHOR_BOTTOM"
    GameTooltip:SetOwner(f, anchor)
    GameTooltip:ClearLines()
    local r, g, b = Utils:GetAccentColor()
    GameTooltip:AddLine("DataBar", r, g, b)

    if active == "xp" then
        local cur, max, rested = self:GetXP()
        GameTooltip:AddDoubleLine("Current XP:", string.format("%s (%d)", Utils:FormatNumber(cur), cur), 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine("Max XP:", string.format("%s (%d)", Utils:FormatNumber(max), max), 1, 1, 1, 1, 1, 1)
        GameTooltip:AddDoubleLine("Rested XP:", string.format("%s (%d)", Utils:FormatNumber(rested), rested), 1, 1, 1, 1, 1, 1)
        if max > 0 then
            GameTooltip:AddDoubleLine("Progress:", string.format("%.1f%%", (cur/max)*100), 1, 1, 1, 1, 1, 1)
        end
    else
        local factionID = tonumber(active)
        if factionID then
            local cur, max, label = self:GetFactionProgress(factionID)
            GameTooltip:AddDoubleLine("Faction:", label, 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine("Progress:", string.format("%s / %s", Utils:FormatNumber(cur), Utils:FormatNumber(max)), 1, 1, 1, 1, 1, 1)
            if max > 0 then
                GameTooltip:AddDoubleLine("Percentage:", string.format("%.1f%%", (cur/max)*100), 1, 1, 1, 1, 1, 1)
            end
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffFFFFFFScroll:|r Cycle selected bars", 0, 1, 0)
    GameTooltip:AddLine("|cffFFFFFFRight Click:|r Show all available bars", 0, 1, 0)
    GameTooltip:Show()
end

function DataBar:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.DataBar
    
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, slotFrame, "BackdropTemplate")
        
        self.bar = CreateFrame("StatusBar", nil, self.frame)
        self.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        
        self.bar.bg = self.bar:CreateTexture(nil, "BACKGROUND")
        self.bar.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        self.bar.bg:SetAllPoints(self.bar)
        
        self.restedBar = CreateFrame("StatusBar", nil, self.frame)
        self.restedBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        self.restedBar:SetAllPoints(self.bar)
        
        self.text = self.bar:CreateFontString(nil, "OVERLAY")
        self.text:SetDrawLayer("OVERLAY", 7)
        
        self.frame:RegisterEvent("PLAYER_XP_UPDATE")
        self.frame:RegisterEvent("UPDATE_FACTION")
        self.frame:RegisterEvent("PLAYER_LEVEL_UP")
        self.frame:SetScript("OnEvent", function() self:UpdateStatus() end)

        self.frame:SetScript("OnMouseWheel", function(f, delta)
            self:CycleBar(delta)
        end)

        self.frame:SetScript("OnMouseDown", function(f, button)
            if button == "RightButton" then
                local direction = LumiBar.db.profile.bar.position == "BOTTOM" and "UP" or "DOWN"
                LumiBar.SecureFlyout:ShowMenu(f, self:GetFlyoutItems(), direction)
            end
        end)

        self.frame:SetScript("OnEnter", function(f)
            self:ShowTooltip(f)
        end)
        self.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    
    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:Show()
    self:Refresh(slotFrame)
    self:UpdateStatus()
end

function DataBar:Refresh(slotFrame)
    if not self.bar then return end
    slotFrame = slotFrame or self.frame:GetParent()
    if not slotFrame then return end
    local align = slotFrame.align or "CENTER"
    
    self.frame:SetHeight(slotFrame:GetHeight())
    
    Utils:SetFont(self.text)
    
    Utils:ApplyBackground(self.frame, self.db)
    
    local barW = 150
    self.frame:SetWidth(barW + 20)
    
    self.bar:SetSize(barW, self.db.barHeight or 10)
    self.bar:ClearAllPoints()
    self.bar:SetPoint(align, self.frame, align, 0, 0)
    
    self.text:ClearAllPoints()
    self.text:SetPoint("CENTER", self.bar, "CENTER", 0, 0)
end
