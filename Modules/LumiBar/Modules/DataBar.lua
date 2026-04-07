local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
local Utils = LumiBar.Utils

-- Performance: Cache common lookups
local tonumber, tostring, ipairs, math_floor, table_insert, table_sort = tonumber, tostring, ipairs, math.floor, table.insert, table.sort
local string_format = string.format
local C_Reputation = C_Reputation
local C_MajorFactions = C_MajorFactions
local C_GossipInfo = C_GossipInfo
local UnitLevel = UnitLevel
local UnitXP = UnitXP
local UnitXPMax = UnitXPMax
local GetXPExhaustion = GetXPExhaustion
local ToggleEncounterJournal = ToggleEncounterJournal
local GameTooltip = GameTooltip
local FACTION_BAR_COLORS = FACTION_BAR_COLORS

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

local function IsMajorFaction(factionID)
    if not factionID then return false end
    if C_Reputation and C_Reputation.IsMajorFaction then
        return C_Reputation.IsMajorFaction(factionID)
    elseif C_MajorFactions and C_MajorFactions.IsMajorFaction then
        return C_MajorFactions.IsMajorFaction(factionID)
    end
    return false
end

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
            local row = math_floor(iconIndex / 4)

            table_insert(factions, {
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
    table_sort(factions, function(a, b) return a.id < b.id end)

    return factions
end

function DataBar:GetAvailableBars()
    local bars = {}
    
    -- 1. Experience
    table_insert(bars, { id = "xp", name = "Experience" })
    
    -- 2. Midnight Factions
    local midnight = self:GetMidnightFactions()
    local midnightIDs = {}
    for _, f in ipairs(midnight) do
        table_insert(bars, { 
            id = tostring(f.id), 
            name = f.name, 
            icon = f.icon,
            isMajor = true 
        })
        midnightIDs[f.id] = true
    end
    
    -- 3. Tracked Faction (Blizzard XP Bar tracking)
    local watchedData = C_Reputation.GetWatchedFactionData()
    if watchedData and watchedData.factionID and not midnightIDs[watchedData.factionID] then
        table_insert(bars, { 
            id = "tracked", 
            name = watchedData.name,
            factionID = watchedData.factionID,
            isMajor = IsMajorFaction(watchedData.factionID),
            icon = { texture = "Interface\\Icons\\INV_Misc_Book_07", coords = { 0, 1, 0, 1 } }
        })
    end
    
    return bars
end

function DataBar:Init()
    self.db = LumiBar.db.profile.modules.DataBar
    
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
            barHeight = {
                name = "Bar Height",
                type = "range",
                min = 1, max = 20, step = 1,
                order = 1,
            },
        }
    }
    LumiBar:RegisterModuleOptions("DataBar", options)
end

function DataBar:GetXP()
    local level = UnitLevel("player")
    if level >= 90 then -- Midnight Max Level
        return 1, 1, 0, true
    end
    local cur = UnitXP("player")
    local max = UnitXPMax("player")
    local rested = GetXPExhaustion() or 0
    return cur, max, rested, false
end

function DataBar:GetFactionProgress(factionID, isActive)
    if not factionID then return 0, 1, "Unknown", {r=0.5, g=0.5, b=0.5}, false end
    local data = C_Reputation.GetFactionDataByID(factionID)
    local majorData = C_MajorFactions.GetMajorFactionData(factionID)
    
    if not data and not majorData then return 0, 1, "Unknown", {r=0.5, g=0.5, b=0.5}, false end

    local name = (majorData and majorData.name) or (data and data.name) or "Unknown"
    local cur, max = 0, 1
    local color = { r = 0, g = 1, b = 0 }
    local isMajor = false

    -- 1. Try Renown (Major Faction)
    if majorData then
        isMajor = true
        cur = majorData.renownReputationEarned or majorData.progress or 0
        max = majorData.renownLevelThreshold or majorData.maxProgress or 2500
        
        local label = name
        if majorData.renownLevel then
            if isActive then
                local maxRenown = majorData.maxRenownLevel or majorData.renownMaxLevel or 25
                label = string_format("%s %d/%d", name, majorData.renownLevel, maxRenown)
            else
                label = string_format("%s (Renown %d)", name, majorData.renownLevel)
            end
        end
        
        -- Fallback for uninitialized major data
        if cur == 0 and max == 2500 and data and data.nextReactionThreshold > 0 then
            cur = data.currentStanding - data.currentReactionThreshold
            max = data.nextReactionThreshold - data.currentReactionThreshold
        end
        
        color = { r = 0, g = 0.8, b = 1 }
        return cur, max, label, color, isMajor
    end

    -- 2. Try Friendship Reputation (Common for special tracks)
    local friendship = C_GossipInfo.GetFriendshipReputation(factionID)
    if friendship and friendship.friendshipFactionID > 0 then
        local label = string_format("%s (%s)", name, friendship.reaction or "")
        cur = friendship.standing - friendship.reactionThreshold
        max = (friendship.nextThreshold or friendship.standing) - friendship.reactionThreshold
        if max <= 0 then cur, max = 1, 1 end
        color = { r = 1, g = 0.5, b = 0 }
        return cur, max, label, color, false
    end

    -- 3. Standard Reputation Fallback
    if data then
        cur = (data.currentStanding or 0) - (data.currentReactionThreshold or 0)
        max = (data.nextReactionThreshold or 0) - (data.currentReactionThreshold or 0)
        if max <= 0 then cur, max = 1, 1 end
        local reactionColor = FACTION_BAR_COLORS[data.reaction or 4]
        if reactionColor then color = reactionColor end
    end

    return cur, max, name, color, false
end

function DataBar:FormatText(cur, max, label, isMajor)
    local perc = (max > 0) and (cur / max) * 100 or 0
    
    if isMajor then
        return label -- Major factions show their custom "Renown X/Y" as the primary text
    end

    local str = string_format("%.1f%%", perc)
    if label then
        str = label .. ": " .. str
    end
    return str
end

function DataBar:UpdateStatus()
    local active = self.db.activeBar or "xp"
    local r, g, b = Utils:GetAccentColor()
    
    if active == "xp" then
        local cur, max, rested, isMax = self:GetXP()
        if isMax then
            self.text:SetText("XP: MAX")
            self.bar:SetMinMaxValues(0, 1)
            self.bar:SetValue(1)
            self.restedBar:Hide()
        else
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
        end
    else
        local factionID = tonumber(active)
        if active == "tracked" then
            local watchedData = C_Reputation.GetWatchedFactionData()
            factionID = watchedData and watchedData.factionID
        end

        if factionID then
            local cur, max, label, _, isMajor = self:GetFactionProgress(factionID, true)
            
            self.text:SetText(self:FormatText(cur, max, label, isMajor))
            self.bar:SetMinMaxValues(0, max)
            self.bar:SetValue(cur)
        else
            self.text:SetText("No Tracked Faction")
            self.bar:SetValue(0)
            self.bar:SetMinMaxValues(0, 1)
        end
        self.restedBar:Hide()
    end
    
    self.bar:SetStatusBarColor(r, g, b)
    self.bar.bg:SetVertexColor(r * 0.2, g * 0.2, b * 0.2, 0.8)
    if active == "xp" then
        self.restedBar:SetStatusBarColor(r, g, b, 0.4)
    end
end

function DataBar:OpenAdventureGuide()
    if ToggleEncounterJournal then
        ToggleEncounterJournal()
    end
end

function DataBar:GetFlyoutItems()
    local items = {}
    local available = self:GetAvailableBars()
    
    for _, bar in ipairs(available) do
        if bar.id == "xp" then
            local xpCur, xpMax, xpRested, isMax = self:GetXP()
            local xpPerc = isMax and 100 or ((xpMax > 0) and (xpCur / xpMax) * 100 or 0)
            table_insert(items, {
                name = "Experience",
                icon = "player", -- Special handling in SecureFlyout
                value = isMax and "MAX" or string_format("%d%%", xpPerc),
                bar = xpPerc,
                isActive = (self.db.activeBar == "xp"),
                type = "macro",
                leftMacrotext = "/run LibStub('AceAddon-3.0'):GetAddon('LT4'):GetModule('LumiBar').Modules['DataBar']:SetActiveBar('xp')",
            })
        else
            local factionID = bar.factionID or tonumber(bar.id)
            local isActive = (self.db.activeBar == bar.id)
            local cur, max, label, color = self:GetFactionProgress(factionID, isActive)
            local perc = (max > 0) and (cur / max) * 100 or 0
            
            table_insert(items, {
                name = bar.name,
                icon = bar.icon,
                value = string_format("%d%%", perc),
                bar = perc,
                isActive = isActive,
                type = "macro",
                leftMacrotext = "/run LibStub('AceAddon-3.0'):GetAddon('LT4'):GetModule('LumiBar').Modules['DataBar']:SetActiveBar('" .. bar.id .. "')",
            })
        end
    end

    return items
end

function DataBar:SetActiveBar(id)
    self.db.activeBar = id
    self:UpdateStatus()
end

function DataBar:CycleBar(delta)
    local available = self:GetAvailableBars()
    if #available <= 1 then return end

    local currentIdx = 1
    for i, bar in ipairs(available) do
        if bar.id == self.db.activeBar then
            currentIdx = i
            break
        end
    end

    local nextIdx = currentIdx - delta
    if nextIdx > #available then nextIdx = 1 end
    if nextIdx < 1 then nextIdx = #available end

    self:SetActiveBar(available[nextIdx].id)
end

function DataBar:ShowTooltip(f)
    local active = self.db.activeBar or "xp"
    local position = LumiBar.db.profile.bar.position or "BOTTOM"
    local anchor = (position == "BOTTOM") and "ANCHOR_TOP" or "ANCHOR_BOTTOM"
    GameTooltip:SetOwner(f, anchor)
    GameTooltip:ClearLines()
    local r, g, b = Utils:GetAccentColor()

    if active == "xp" then
        GameTooltip:AddLine("Experience", r, g, b)
        local cur, max, rested, isMax = self:GetXP()
        if isMax then
            GameTooltip:AddDoubleLine("Status:", "MAX LEVEL", 1, 1, 1, 0, 1, 0)
        else
            GameTooltip:AddDoubleLine("Current XP:", string_format("%s (%d)", Utils:FormatNumber(cur), cur), 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine("Max XP:", string_format("%s (%d)", Utils:FormatNumber(max), max), 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine("Rested XP:", string_format("%s (%d)", Utils:FormatNumber(rested), rested), 1, 1, 1, 1, 1, 1)
            if max > 0 then
                GameTooltip:AddDoubleLine("Progress:", string_format("%.1f%%", (cur/max)*100), 1, 1, 1, 1, 1, 1)
            end
        end
    else
        local factionID = tonumber(active)
        if active == "tracked" then
            local watchedData = C_Reputation.GetWatchedFactionData()
            factionID = watchedData and watchedData.factionID
        end

        if factionID then
            local cur, max, label = self:GetFactionProgress(factionID)
            local data = C_Reputation.GetFactionDataByID(factionID)
            local majorData = C_MajorFactions.GetMajorFactionData(factionID)
            local name = (data and data.name) or (majorData and majorData.name) or "Unknown Faction"
            
            GameTooltip:AddLine(name, r, g, b)
            GameTooltip:AddDoubleLine("Status:", label, 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine("Progress:", string_format("%s / %s", Utils:FormatNumber(cur), Utils:FormatNumber(max)), 1, 1, 1, 1, 1, 1)
            if max > 0 then
                GameTooltip:AddDoubleLine("Percentage:", string_format("%.1f%%", (cur/max)*100), 1, 1, 1, 1, 1, 1)
            end
        else
            GameTooltip:AddLine("No Tracked Faction", r, g, b)
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffFFFFFFScroll:|r Cycle available bars", 0, 1, 0)
    GameTooltip:AddLine("|cffFFFFFFLeft Click:|r Open Adventure Guide", 0, 1, 0)
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
            if f:IsMouseOver() then
                self:ShowTooltip(f)
            end
        end)

        self.frame:SetScript("OnMouseDown", function(f, button)
            if button == "RightButton" then
                local direction = LumiBar.db.profile.bar.position == "BOTTOM" and "UP" or "DOWN"
                LumiBar.SecureFlyout:ShowMenu(f, self:GetFlyoutItems(), direction)
            elseif button == "LeftButton" then
                self:OpenAdventureGuide()
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
    -- Set initial width. Since width is static for this module, we don't need UpdateModuleWidth in UpdateStatus.
    Utils:UpdateModuleWidth(self, barW + 24, function() self:Refresh(slotFrame) end)
    
    self.bar:SetSize(barW, self.db.barHeight or 10)
    self.bar:ClearAllPoints()
    self.bar:SetPoint(align, self.frame, align, 0, 0)
    
    self.text:ClearAllPoints()
    self.text:SetPoint("CENTER", self.bar, "CENTER", 0, 0)
end
