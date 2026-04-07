local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local Module = LT4:NewModule("Miscellaneous", "AceEvent-3.0", "AceHook-3.0")

Module.description = "A collection of miscellaneous quality-of-life tweaks."

local function AddID(tooltip, id, typeLabel)
    if not id or not LT4:GetModuleEnabled("Miscellaneous") or not LT4.db.profile.miscellaneous.showIDs then return end
    
    local name = tooltip:GetName()
    if not name then return end

    -- Check if we already added it to prevent duplicates
    for i = 1, tooltip:NumLines() do
        local line = _G[name .. "TextLeft" .. i]
        if line and line:GetText() and line:GetText():find(typeLabel .. " ID:") then
            return
        end
    end

    tooltip:AddDoubleLine(typeLabel .. " ID:", "|cffffffff" .. id .. "|r")
    tooltip:Show()
end

function Module:OnInitialize()
    LT4:RegisterModuleOptions(self:GetName(), {
        type = "group",
        name = self:GetName(),
        desc = self.description,
        args = {
            description = {
                type = "description",
                name = self.description,
                order = 0,
            },
            showIDs = {
                type = "toggle",
                name = "Show IDs in Tooltips",
                desc = "Adds Item, Spell, Currency, and Achievement IDs to all tooltips globally.",
                get = function() return LT4.db.profile.miscellaneous.showIDs end,
                set = function(_, val) LT4.db.profile.miscellaneous.showIDs = val end,
                order = 1,
            },
        },
    })

    if not LT4:GetModuleEnabled(self:GetName()) then
        self:SetEnabledState(false)
    end
end

function Module:OnEnable()
    -- TooltipDataProcessor is the modern (Dragonflight+) way to hook all tooltips globally
    -- We'll catch everything that returns an ID via the modern system
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if data and data.id then AddID(tooltip, data.id, "Item") end
    end)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip, data)
        if data and data.id then AddID(tooltip, data.id, "Spell") end
    end)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Achievement, function(tooltip, data)
        if data and data.id then AddID(tooltip, data.id, "Achievement") end
    end)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Currency, function(tooltip, data)
        if data and data.id then AddID(tooltip, data.id, "Currency") end
    end)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Toy, function(tooltip, data)
        if data and data.id then AddID(tooltip, data.id, "Item") end
    end)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Mount, function(tooltip, data)
        if data and data.id then AddID(tooltip, data.id, "Mount") end
    end)
end

function Module:OnDisable()
    -- TooltipDataProcessor.AddTooltipPostCall doesn't have an easy "un-register" for a closure.
    -- However, we handle the enabled check inside AddID().
end
