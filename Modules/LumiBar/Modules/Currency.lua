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
            showBagSpace = {
                name = "Show Bag Space",
                desc = "Show free bag slots next to gold.",
                type = "toggle",
                width = "full",
                order = 1,
            },
            useGoldColors = {
                name = "Use Gold Colors",
                desc = "Use colored gold/silver/copper icons.",
                type = "toggle",
                width = "full",
                order = 2,
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
    local gold = GetMoney()
    local str
    if self.db.useGoldColors then
        str = Utils:FormatMoney(gold)
    else
        str = Utils:FormatNumber(gold / 10000) .. "g"
    end

    if self.db.showBagSpace then
        local free, _ = self:GetBagSpace()
        local accent = "|cff" .. Utils:GetAccentColorHex()
        str = str .. " " .. accent .. "(" .. free .. ")|r"
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

        self.frame:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then
                ToggleAllBags()
            elseif button == "RightButton" then
                ToggleCharacter("TokenFrame")
            end
        end)

        self.frame:SetScript("OnEnter", function(f)
            local realm = GetRealmName()
            local position = LumiBar.db.profile.bar.position or "BOTTOM"
            local anchor = (position == "BOTTOM") and "ANCHOR_TOP" or "ANCHOR_BOTTOM"
            GameTooltip:SetOwner(f, anchor)
            GameTooltip:ClearLines()
            local r, g, b = Utils:GetAccentColor()
            GameTooltip:AddLine("Currency", r, g, b)

            -- Gold on all characters
            if LumiBar.db.global.goldData[realm] then
                GameTooltip:AddLine(" ")
                local r, g, b = Utils:GetAccentColor()
                GameTooltip:AddLine("Gold on " .. realm .. ":", r, g, b)
                local totalGold = 0
                local sortedNames = {}
                for name in pairs(LumiBar.db.global.goldData[realm]) do table.insert(sortedNames, name) end
                table.sort(sortedNames)

                for _, name in ipairs(sortedNames) do
                    local data = LumiBar.db.global.goldData[realm][name]
                    local classColor = RAID_CLASS_COLORS[data.class]
                    local nameStr = string.format("|cff%02x%02x%02x%s|r", classColor.r*255, classColor.g*255, classColor.b*255, name)
                    GameTooltip:AddDoubleLine(nameStr, Utils:FormatMoney(data.gold), 1, 1, 1, 1, 1, 1)
                    totalGold = totalGold + data.gold
                end
                GameTooltip:AddDoubleLine("|cff00ccffTotal:|r", Utils:FormatMoney(totalGold), 1, 1, 1, 1, 1, 1)
            end

            -- Tracked Currencies
            local headerAdded = false
            for i = 1, 10 do
                local info = C_CurrencyInfo.GetBackpackCurrencyInfo(i)
                if info then
                    if not headerAdded then
                        GameTooltip:AddLine(" ")
                        local r, g, b = Utils:GetAccentColor()
                        GameTooltip:AddLine("Tracked Currencies:", r, g, b)
                        headerAdded = true
                    end
                    local iconStr = string.format("|T%d:12:12:0:0|t ", info.iconFileID)
                    GameTooltip:AddDoubleLine(iconStr .. info.name, info.quantity, 1, 1, 1, 1, 1, 1)
                end
            end

            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffFFFFFFLeft Click:|r Open Bags", 0, 1, 0)
            GameTooltip:AddLine("|cffFFFFFFRight Click:|r Open Currencies", 0, 1, 0)
            GameTooltip:Show()
        end)
        self.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    
    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:Show()
    self:Refresh(slotFrame)
    self:UpdateCurrency()
end

function CurrencyModule:Refresh(slotFrame)
    Utils:RefreshBase(self, slotFrame)
end
