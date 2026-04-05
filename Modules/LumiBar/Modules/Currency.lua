local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
local Utils = LumiBar.Utils

local CurrencyModule = {}
LumiBar:RegisterModule("Currency", CurrencyModule)

-- Expansion compatibility
local GetNumFreeSlots = C_Container and C_Container.GetContainerNumFreeSlots or GetContainerNumFreeSlots
local GetNumSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots

function CurrencyModule:Init()
    self.db = LumiBar.db.profile.modules.Currency
    
    local options = {
        name = "Currency",
        type = "group",
        get = function(info) return self.db[info[#info]] end,
        set = function(info, value) 
            self.db[info[#info]] = value
            self:Refresh()
            self:UpdateCurrency()
        end,
        args = {
            displayedCurrency = {
                name = "Displayed Currency",
                desc = "Select what to show on the bar.",
                type = "select",
                values = { ["GOLD"] = "Gold", ["BAGS"] = "Bags Space" },
                order = 1,
            },
            showBagSpace = {
                name = "Show Bag Space",
                desc = "Show free bag slots next to gold.",
                type = "toggle",
                order = 2,
            },
            useGoldColors = {
                name = "Use Gold Colors",
                desc = "Use colored gold/silver/copper icons.",
                type = "toggle",
                order = 3,
            },
        }
    }
    LumiBar:RegisterModuleOptions("Currency", options)
end

function CurrencyModule:GetBagSpace()
    local free, total = 0, 0
    -- Bag 0 is backpack, 1-4 are standard bags, 5 is reagent bag (Retail)
    local maxBags = NUM_BAG_SLOTS
    if NUM_REAGENT_BAG_SLOTS then maxBags = maxBags + NUM_REAGENT_BAG_SLOTS end
    
    for i = 0, maxBags do
        local f = GetNumFreeSlots(i)
        local t = GetNumSlots(i)
        if f and t then
            free = free + f
            total = total + t
        end
    end
    return free, total
end

function CurrencyModule:UpdateGoldData()
    local realm = GetRealmName()
    local name = UnitName("player")
    local _, class = UnitClass("player")
    
    LumiBar.db.global.goldData[realm] = LumiBar.db.global.goldData[realm] or {}
    LumiBar.db.global.goldData[realm][name] = {
        gold = GetMoney(),
        class = class,
    }
end

function CurrencyModule:UpdateCurrency()
    local str = ""
    if self.db.displayedCurrency == "GOLD" then
        local gold = GetMoney()
        if self.db.useGoldColors then
            str = Utils:FormatMoney(gold)
        else
            str = Utils:FormatNumber(gold / 10000) .. "g"
        end
        
        if self.db.showBagSpace then
            local free, _ = self:GetBagSpace()
            local accent = "|cff" .. Utils:GetAccentColorHex()
            str = str .. accent .. " (" .. free .. ")|r"
        end
    elseif self.db.displayedCurrency == "BAGS" then
        local free, total = self:GetBagSpace()
        local accent = "|cff" .. Utils:GetAccentColorHex()
        str = string.format("%sBags:|r %d/%d", accent, free, total)
    end
    
    self.text:SetText(str)
    self:UpdateGoldData()
    self:UpdateWidth()
end

function CurrencyModule:UpdateWidth()
    if not self.text then return end
    local textW = self.text:GetStringWidth()
    Utils:UpdateModuleWidth(self, textW + 16, function() self:UpdateWidth() end)
end

function CurrencyModule:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.Currency
    
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, slotFrame, "BackdropTemplate")
        self.text = self.frame:CreateFontString(nil, "OVERLAY")
        
        self.frame:RegisterEvent("PLAYER_MONEY")
        self.frame:RegisterEvent("BAG_UPDATE")
        self.frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
        self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.frame:SetScript("OnEvent", function() self:UpdateCurrency() end)
    end
    
    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:Show()
    self:Refresh(slotFrame)
    self:UpdateCurrency()
end

function CurrencyModule:Refresh(slotFrame)
    if not self.text then return end
    slotFrame = slotFrame or self.frame:GetParent()
    if not slotFrame then return end
    local align = slotFrame and slotFrame.align or "CENTER"
    
    self.frame:SetHeight(slotFrame:GetHeight())
    
    Utils:SetFont(self.text)
    Utils:ApplyBackground(self.frame, self.db)
    
    self.text:ClearAllPoints()
    self.text:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
    
    -- Tooltip logic for gold on all chars
    self.frame:SetScript("OnEnter", function(f)
        local realm = GetRealmName()
        local lines = {}
        local totalGold = 0
        
        if LumiBar.db.global.goldData[realm] then
            for name, data in pairs(LumiBar.db.global.goldData[realm]) do
                local classColor = RAID_CLASS_COLORS[data.class]
                local nameStr = string.format("|cff%02x%02x%02x%s|r", classColor.r*255, classColor.g*255, classColor.b*255, name)
                table.insert(lines, {nameStr, Utils:FormatMoney(data.gold)})
                totalGold = totalGold + data.gold
            end
        end
        
        table.insert(lines, "")
        table.insert(lines, {"Total:", Utils:FormatMoney(totalGold)})
        
        Utils:SetTooltip(f, "Gold on " .. realm, lines)
        local script = f:GetScript("OnEnter")
        if script then script(f) end
    end)
end
