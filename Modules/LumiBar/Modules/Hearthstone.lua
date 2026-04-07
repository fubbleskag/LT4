local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
local Utils = LumiBar.Utils
local Data = LumiBar.Data
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

local HS = {}
LumiBar:RegisterModule("Hearthstone", HS)

-- Performance: Cache common lookups
local GetItemInfo = GetItemInfo
local GetItemIcon = GetItemIcon
local GetItemCount = GetItemCount
local GetItemCooldown = GetItemCooldown
local GetBindLocation = GetBindLocation
local IsSpellKnown = IsSpellKnown
local GetTime = GetTime
local C_Spell = C_Spell
local InCombatLockdown = InCombatLockdown
local string_format = string.format
local string_match = string.match
local table_insert = table.insert
local table_sort = table.sort
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber

-- Robust Resource Helper (Cached)
local function GetResourceInfo(key)
    if not key then return nil end
    local type, id = string_match(key, "(%a+):(%d+)")
    id = tonumber(id)
    if not type or not id then return nil end

    local name, icon
    if type == "spell" then
        name = Data.PortalNames[id]
        local info = C_Spell.GetSpellInfo(id)
        if info then
            name = name or info.name
            icon = info.iconID
        end
    else
        name = GetItemInfo(id)
        icon = GetItemIcon(id)
        if not name and id == 6948 then name = "Hearthstone" icon = 134400 end
    end
    return name, icon, type, id
end

function HS:ScanAvailable()
    -- Only re-scan if needed (could add event throttling here)
    local allKnown = { Standard = {}, Expansions = {}, Seasonal = {} }
    local class = select(2, UnitClass("player"))
    
    local expMap = { df = "Dragonflight", tww = "The War Within", sl = "Shadowlands", bfa = "BfA", legion = "Legion", wod = "Warlords", cata = "Cataclysm", wotlk = "WotLK", mop = "Pandaria" }

    -- 1. Whitelist (Hearthstones/Toys/Raids/Mythics)
    for id, info in pairs(Data.HearthstoneData) do
        local isKnown = false
        if info.type == "toy" then isKnown = PlayerHasToy(id)
        elseif info.type == "item" then isKnown = GetItemCount(id) > 0
        elseif info.type == "spell" then isKnown = IsSpellKnown(id) end

        if isKnown and (not info.class or info.class == class) then
            local key = info.type .. ":" .. id
            local name, icon = GetResourceInfo(key)
            
            if info.raid or info.mythic then
                local expName = info.expansion and expMap[info.expansion] or "Other"
                -- For mythic entries that might not have expansion field but have season field
                if not info.expansion and info.season then
                    if info.season:find("^df") then expName = "Dragonflight"
                    elseif info.season:find("^tww") then expName = "The War Within"
                    elseif info.season:find("^sl") then expName = "Shadowlands"
                    elseif info.season:find("^mid") then expName = "Midnight"
                    elseif info.season == "mop" then expName = "Pandaria"
                    elseif info.season == "wod" then expName = "Warlords"
                    end
                end

                allKnown.Expansions[expName] = allKnown.Expansions[expName] or {}
                allKnown.Expansions[expName][key] = { name = name or "Unknown Portal", icon = icon, type = info.type, id = id, isRaid = info.raid }
            else
                allKnown.Standard[key] = { name = name or "Unknown Item", icon = icon, type = info.type, id = id }
            end
        end
    end

    -- 2. Mage Spells
    if class == "MAGE" then
        for _, id in ipairs(Data.MageSpells) do
            if IsSpellKnown(id) then
                local key = "spell:" .. id
                local name, icon = GetResourceInfo(key)
                if name then
                    allKnown.Standard[key] = { name = name, icon = icon, type = "spell", id = id }
                end
            end
        end
    end

    -- 3. Additional Dungeon Portal sync (ensuring all from Data.DungeonPortals are caught if missed)
    for expName, ids in pairs(Data.DungeonPortals) do
        for _, id in ipairs(ids) do
            if IsSpellKnown(id) then
                local key = "spell:" .. id
                if not allKnown.Expansions[expName] or not allKnown.Expansions[expName][key] then
                    local name, icon = GetResourceInfo(key)
                    if name then
                        allKnown.Expansions[expName] = allKnown.Expansions[expName] or {}
                        allKnown.Expansions[expName][key] = { name = name, icon = icon, type = "spell", id = id }
                    end
                end
            end
        end
    end

    -- 4. Seasonal Portals
    for _, id in ipairs(Data.SeasonPortals) do
        if IsSpellKnown(id) then
            local key = "spell:" .. id
            local name, icon = GetResourceInfo(key)
            if name then
                allKnown.Seasonal[key] = { name = name, icon = icon, type = "spell", id = id }
            end
        end
    end

    return allKnown
end

function HS:Init()
    self.db = LumiBar.db.profile.modules.Hearthstone
    self.db.hiddenPortals = self.db.hiddenPortals or {}
    self.db.hiddenExpansions = self.db.hiddenExpansions or {}
    
    local options = {
        name = "Hearthstone",
        type = "group",
        get = function(info) return self.db[info[#info]] end,
        set = function(info, value) 
            self.db[info[#info]] = value
            self:Refresh()
            self:UpdateSecureAttributes()
        end,
        args = {
            primaryHS = {
                name = "Primary Hearthstone",
                type = "select",
                values = function() 
                    local all = self:ScanAvailable()
                    local vals = {}
                    for key, info in pairs(all.Standard) do vals[key] = info.name end
                    return vals
                end,
                order = 1,
            },
            cooldownEnabled = { name = "Show Cooldown", type = "toggle", order = 2 },
            visibilityGroup = {
                name = "Additional Portals",
                type = "group",
                inline = true,
                order = 10,
                args = {
                    standard = { name = "Hearthstones & Toys", type = "group", inline = true, order = 1, args = {} },
                    expansions = { 
                        name = "Dungeons and Raids", 
                        type = "group", 
                        inline = true, 
                        order = 2, 
                        args = {
                            showSeasonPortals = {
                                name = "|cff00ff00Current Season|r",
                                type = "toggle",
                                order = 0,
                            },
                            sep = { name = "", type = "description", order = 0.5 },
                        } 
                    },
                }
            }
        }
    }

    local all = self:ScanAvailable()
    for key, info in pairs(all.Standard) do
        options.args.visibilityGroup.args.standard.args[key:gsub(":", "_")] = {
            name = info.name,
            type = "toggle",
            get = function() return self.db.hiddenPortals[key] == true end,
            set = function(_, val) 
                self.db.hiddenPortals[key] = val or nil
                AceConfigRegistry:NotifyChange("LumiBar")
            end,
        }
    end
    
    local eOrder = 1
    -- Use a sorted list of expansion names for consistent order
    local sortedExps = {}
    for expName in pairs(all.Expansions) do table_insert(sortedExps, expName) end
    table_sort(sortedExps, function(a, b) 
        -- Custom sort to keep modern exps at top
        local weights = { ["Midnight"] = 1, ["The War Within"] = 2, ["Dragonflight"] = 3, ["Shadowlands"] = 4, ["BfA"] = 5, ["Legion"] = 6, ["Warlords"] = 7, ["Pandaria"] = 8, ["Cataclysm"] = 9, ["WotLK"] = 10 }
        return (weights[a] or 99) < (weights[b] or 99)
    end)

    for _, expName in ipairs(sortedExps) do
        options.args.visibilityGroup.args.expansions.args[expName:gsub(" ", "")] = {
            name = expName,
            type = "toggle",
            get = function() return self.db.hiddenExpansions[expName] == true end,
            set = function(_, val) 
                self.db.hiddenExpansions[expName] = val or nil
                AceConfigRegistry:NotifyChange("LumiBar")
            end,
            order = eOrder,
        }
        eOrder = eOrder + 1
    end

    LumiBar:RegisterModuleOptions("Hearthstone", options)
end

function HS:GetCooldown(type, id)
    local start, duration
    if type == "spell" then
        local cdInfo = C_Spell.GetSpellCooldown(id)
        if cdInfo then start, duration = cdInfo.startTime, cdInfo.duration end
    else
        start, duration = GetItemCooldown(id)
    end
    if start and duration > 0 then
        local cd = duration - (GetTime() - start)
        if cd > 0 then return cd end
    end
    return 0
end

function HS:UpdateStatus()
    local name, icon, type, id = GetResourceInfo(self.db.primaryHS)
    if not name then return end
    
    local cd = self:GetCooldown(type, id)
    if self.db.cooldownEnabled and cd > 0 then
        if cd > 60 then self.text:SetFormattedText("%dm", math.ceil(cd / 60))
        else self.text:SetFormattedText("%ds", math.ceil(cd)) end
        self.text:SetTextColor(1, 0.5, 0)
    else
        local displayText = name
        local itemData = id and Data.HearthstoneData[id]
        
        if itemData and itemData.hearthstone then
            displayText = GetBindLocation() or name
        elseif type == "spell" then
            displayText = displayText:gsub("Teleport: ", ""):gsub("Portal: ", "")
        end
        
        self.text:SetText(Utils:ShortenString(displayText, 12))
        self.text:SetTextColor(1, 1, 1)
    end
    self:UpdateWidth()
end

function HS:UpdateWidth()
    if not self.text then return end
    Utils:UpdateModuleWidth(self, 16 + 4 + self.text:GetStringWidth() + 12, function() self:UpdateWidth() end)
end

function HS:UpdateSecureAttributes()
    if InCombatLockdown() or not self.frame then return end
    local _, _, type, id = GetResourceInfo(self.db.primaryHS)
    if type and id then
        self.frame:SetAttribute("type1", type == "spell" and "spell" or "item")
        if type == "spell" then self.frame:SetAttribute("spell1", id)
        else self.frame:SetAttribute("item1", "item:" .. id) end
    end
end

function HS:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.Hearthstone
    if not self.frame then
        self.frame = CreateFrame("Button", "LumiBarHearthstoneBtn", slotFrame, "SecureActionButtonTemplate, BackdropTemplate")
        self.frame:RegisterForClicks("AnyUp", "AnyDown")
        self.icon = self.frame:CreateTexture(nil, "ARTWORK")
        self.text = self.frame:CreateFontString(nil, "OVERLAY")
        self.timeSinceLastUpdate = 0
        self.frame:SetScript("OnUpdate", function(f, elapsed)
            self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
            if self.timeSinceLastUpdate >= 1 then 
                self:UpdateStatus() 
                self.timeSinceLastUpdate = 0 
            end
        end)
        self.frame:SetScript("OnEnter", function(f)
            local name, icon, type, id = GetResourceInfo(self.db.primaryHS)
            if not name then return end
            GameTooltip:SetOwner(f, "ANCHOR_TOP")
            GameTooltip:AddLine(string_format("|T%d:14:14:0:0|t %s", icon or 134400, name), 1, 1, 1)
            local itemData = id and Data.HearthstoneData[id]
            if itemData and itemData.hearthstone then
                GameTooltip:AddDoubleLine("Destination:", GetBindLocation() or "Unknown", 1, 0.82, 0, 1, 1, 1)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string_format("|cffFFFFFFLeft-click:|r Use %s", name:gsub("Teleport: ", ""):gsub("Portal: ", "")), 0, 1, 0)
            GameTooltip:AddLine("|cffFFFFFFRight-click:|r Open teleport menu", 0, 1, 0)
            GameTooltip:Show()
        end)
        self.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
        self.frame:SetScript("OnMouseDown", function(f, button)
            if button == "RightButton" and not InCombatLockdown() then
                local all = self:ScanAvailable()
                local menuItems = {}
                
                for key, info in pairs(all.Standard) do
                    if self.db.hiddenPortals[key] == true then
                        table_insert(menuItems, { key = key, id = info.id, type = info.type, name = info.name, icon = info.icon })
                    end
                end
                
                if self.db.showSeasonPortals then
                    local seasonalItems = {}
                    for key, info in pairs(all.Seasonal) do
                        table_insert(seasonalItems, { key = key, id = info.id, type = info.type, name = info.name, icon = info.icon })
                    end
                    if #seasonalItems > 0 then
                        table_sort(seasonalItems, function(a, b) return a.name < b.name end)
                        table_insert(menuItems, { isCategory = true, name = "|cff00ff00Current Season|r", icon = Data.ExpansionIcons["SEASON"], subItems = seasonalItems })
                    end
                end

                for expName, portals in pairs(all.Expansions) do
                    if self.db.hiddenExpansions[expName] == true then
                        local items = {}
                        for key, info in pairs(portals) do
                            table_insert(items, { key = key, id = info.id, type = info.type, name = info.name, icon = info.icon })
                        end
                        if #items > 0 then
                            table_sort(items, function(a, b) return a.name < b.name end)
                            table_insert(menuItems, { isCategory = true, name = expName, icon = Data.ExpansionIcons[expName] or 134400, subItems = items })
                        end
                    end
                end
                
                table_sort(menuItems, function(a, b) 
                    if a.isCategory ~= b.isCategory then return b.isCategory end 
                    return a.name < b.name 
                end)
                LumiBar.SecureFlyout:ShowMenu(f, menuItems, LumiBar.db.profile.bar.position == "BOTTOM" and "UP" or "DOWN")
            end
        end)
    end
    self:UpdateSecureAttributes()
    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:Show()
    self:Refresh(slotFrame)
    self:UpdateStatus()
end

function HS:Refresh(slotFrame)
    if not self.icon or not self.text then return end
    slotFrame = slotFrame or self.frame:GetParent()
    if not slotFrame then return end
    self.frame:SetHeight(slotFrame:GetHeight())
    Utils:SetFont(self.text)
    Utils:ApplyBackground(self.frame, self.db)
    local _, icon = GetResourceInfo(self.db.primaryHS)
    self.icon:SetTexture(icon or 134400)
    self.icon:SetSize(16, 16)
    local textW = self.text:GetStringWidth()
    local align = slotFrame.align or "CENTER"
    self.icon:ClearAllPoints()
    self.text:ClearAllPoints()
    if align == "LEFT" then
        self.icon:SetPoint("LEFT", self.frame, "LEFT", 4, 0)
        self.text:SetPoint("LEFT", self.icon, "RIGHT", 4, 0)
    elseif align == "RIGHT" then
        self.text:SetPoint("RIGHT", self.frame, "RIGHT", -4, 0)
        self.icon:SetPoint("RIGHT", self.text, "LEFT", -4, 0)
    else
        self.icon:SetPoint("CENTER", self.frame, "CENTER", -(textW + 4)/2, 0)
        self.text:SetPoint("LEFT", self.icon, "RIGHT", 4, 0)
    end
end
