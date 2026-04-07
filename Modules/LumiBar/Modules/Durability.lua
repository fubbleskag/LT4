local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
local Utils = LumiBar.Utils

local Dur = {}
LumiBar:RegisterModule("Durability", Dur)

-- Caches
local GetInventoryItemDurability = GetInventoryItemDurability
local GetAverageItemLevel = GetAverageItemLevel
local C_MountJournal = C_MountJournal
local math_floor = math.floor
local math_min = math.min
local string_format = string.format
local ipairs = ipairs

function Dur:Init()
    self.db = LumiBar.db.profile.modules.Durability
    
    local options = {
        name = "Durability",
        type = "group",
        get = function(info) return self.db[info[#info]] end,
        set = function(info, value) 
            self.db[info[#info]] = value
            self:Refresh()
            self:UpdateStatus()
        end,
        args = {
            clickButton = {
                name = "Click Action Button",
                desc = "Which mouse button triggers the repair mount summoning.",
                type = "select",
                values = { ["Left"] = "Left Click", ["Right"] = "Right Click" },
                order = 1,
            },
            repairMount = {
                name = "Preferred Repair Mount",
                desc = "The mount to summon (Only known mounts shown).",
                type = "select",
                values = function()
                    local known = {}
                    for id, name in pairs(LumiBar.Data.RepairMounts) do
                        local isKnown = select(11, C_MountJournal.GetMountInfoByID(id))
                        if isKnown then
                            known[id] = name
                        end
                    end
                    -- If none known, show placeholder
                    if next(known) == nil then
                        known[0] = "None Known"
                    end
                    return known
                end,
                order = 2,
            },
            showItemLevel = {
                name = "Show Item Level",
                type = "toggle",
                order = 3,
            },
            itemLevelShort = {
                name = "Short Item Level",
                desc = "Hide decimals for item level.",
                type = "toggle",
                order = 4,
            },
        }
    }
    LumiBar:RegisterModuleOptions("Durability", options)
end

function Dur:UpdateStatus()
    if not self.durText then return end
    
    local minDur = 100
    local slots = {1, 3, 5, 6, 7, 8, 9, 10, 16, 17}
    local hasItems = false
    
    for _, i in ipairs(slots) do
        local cur, max = GetInventoryItemDurability(i)
        if cur and max and max > 0 then
            minDur = math_min(minDur, (cur / max) * 100)
            hasItems = true
        end
    end
    
    if not hasItems then minDur = 100 end
    
    local r, g, b = LumiBar:ColorGradient(minDur / 100, 1, 0, 0, 1, 1, 0, 0, 1, 0)
    self.durText:SetFormattedText("%d%%", math_floor(minDur))
    self.durText:SetTextColor(r, g, b)
    
    if self.db.showItemLevel then
        local _, equipped = GetAverageItemLevel()
        local fmt = self.db.itemLevelShort and "%d" or "%.1f"
        self.ilvlText:SetFormattedText(fmt, equipped)
        self.ilvlText:Show()
    else
        self.ilvlText:Hide()
    end
    
    self:UpdateWidth()
end

function Dur:UpdateWidth()
    if not self.durText then return end
    local durW = self.durText:GetStringWidth()
    local iconW = 16
    local ilvlW = self.db.showItemLevel and (self.ilvlText:GetStringWidth() + 4) or 0
    local spacing = 12
    
    Utils:UpdateModuleWidth(self, durW + iconW + ilvlW + spacing + 16, function() self:UpdateWidth() end)
end

function Dur:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.Durability
    
    if not self.frame then
        self.frame = CreateFrame("Button", nil, slotFrame, "SecureActionButtonTemplate, BackdropTemplate")
        self.frame:RegisterForClicks("AnyUp", "AnyDown")
        
        self.icon = self.frame:CreateTexture(nil, "ARTWORK")
        self.durText = self.frame:CreateFontString(nil, "OVERLAY")
        self.ilvlText = self.frame:CreateFontString(nil, "OVERLAY")
        
        self.frame:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
        self.frame:RegisterEvent("PLAYER_AVG_ITEM_LEVEL_UPDATE")
        self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.frame:SetScript("OnEvent", function() self:UpdateStatus() end)
        
        Utils:SetTooltip(self.frame, "Durability & iLvl", function()
            local avg, equipped = GetAverageItemLevel()
            local clickText = (self.db.clickButton or "Left") == "Right" and "Right-click" or "Left-click"
            return {
                {"Equipped iLvl:", string_format("%.2f", equipped)},
                {"Average iLvl:", string_format("%.2f", avg)},
                "",
                string_format("|cffFFFFFF%s:|r Summon Repair Mount", clickText)
            }
        end)
    end
    
    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:Show()
    self:Refresh(slotFrame)
    self:UpdateStatus()
end

function Dur:Refresh(slotFrame)
    if not self.durText then return end
    slotFrame = slotFrame or self.frame:GetParent()
    if not slotFrame then return end
    local align = slotFrame.align or "CENTER"
    
    self.frame:SetHeight(slotFrame:GetHeight())
    
    Utils:SetFont(self.durText)
    Utils:SetFont(self.ilvlText, nil, nil, "ACCENT")
    
    Utils:ApplyBackground(self.frame, self.db)
    
    self.icon:SetTexture("Interface\\Icons\\INV_Chest_Plate04")
    self.icon:SetSize(16, 16)
    
    local spacing = 4
    
    self.durText:ClearAllPoints()
    self.durText:SetPoint(align, self.frame, align, 0, 0)
    
    self.icon:ClearAllPoints()
    self.icon:SetPoint("RIGHT", self.durText, "LEFT", -spacing, 0)
    
    self.ilvlText:ClearAllPoints()
    self.ilvlText:SetPoint("LEFT", self.durText, "RIGHT", spacing, 0)
    
    -- Re-bind mount based on clickButton setting
    local mountID = self.db.repairMount
    local buttonSuffix = (self.db.clickButton or "Left") == "Right" and "2" or "1"
    local otherSuffix = buttonSuffix == "2" and "1" or "2"

    self.frame:SetAttribute("type"..buttonSuffix, "spell")
    self.frame:SetAttribute("type"..otherSuffix, nil)
    self.frame:SetAttribute("spell"..otherSuffix, nil)

    if mountID and mountID > 0 then
        local mountName = C_MountJournal.GetMountInfoByID(mountID)
        if mountName then
            self.frame:SetAttribute("spell"..buttonSuffix, mountName)
        else
            self.frame:SetAttribute("spell"..buttonSuffix, nil)
        end
    else
        self.frame:SetAttribute("spell"..buttonSuffix, nil)
    end
end
