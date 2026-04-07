local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local Module = LT4:NewModule("Miscellaneous", "AceEvent-3.0", "AceHook-3.0")

Module.description = "A collection of miscellaneous quality-of-life tweaks."

local function AddID(tooltip, id, typeLabel)
    if InCombatLockdown() or not id or not LT4:GetModuleEnabled("Miscellaneous") or not LT4.db.profile.miscellaneous.showIDs then return end
    
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
            betterFishing = {
                type = "toggle",
                name = "Better Fishing",
                desc = "Double-right-click while not in combat to cast your fishing rod.",
                get = function() return LT4.db.profile.miscellaneous.betterFishing end,
                set = function(_, val) LT4.db.profile.miscellaneous.betterFishing = val end,
                order = 2,
            },
        },
    })

    if not LT4:GetModuleEnabled(self:GetName()) then
        self:SetEnabledState(false)
    end

    -- Setup Better Fishing
    self:SetupBetterFishing()
end

function Module:SetupBetterFishing()
    local fishingButton = CreateFrame("Button", "LT4BetterFishingButton", UIParent, "SecureActionButtonTemplate")
    fishingButton:SetAttribute("type", "spell")
    fishingButton:RegisterForClicks("AnyDown", "AnyUp")

    local lastClickTime = 0
    
    self:RegisterEvent("GLOBAL_MOUSE_DOWN", function(_, button)
        if button ~= "RightButton" then return end
        if IsMouseButtonDown("LeftButton") then return end -- Don't trigger if left button is also down
        
        local moduleEnabled = LT4:GetModuleEnabled("Miscellaneous")
        local fishingEnabled = LT4.db.profile.miscellaneous.betterFishing
        
        if not moduleEnabled or not fishingEnabled then return end
        if InCombatLockdown() then return end
        
        -- Safety checks
        if IsPlayerMoving() or IsMounted() or IsFalling() or IsStealthed() or IsSwimming() then return end

        local now = GetTime()
        local diff = now - lastClickTime

        if diff > 0.05 and diff < 0.4 then
            local spellInfo = C_Spell.GetSpellInfo(131474)
            local fishingSpellName = spellInfo and spellInfo.name
            
            if fishingSpellName then
                fishingButton:SetAttribute("spell", fishingSpellName)
                
                -- Set override for the Up event of this click
                -- Use the button itself as the owner for the binding
                SetOverrideBindingClick(fishingButton, true, "BUTTON2", "LT4BetterFishingButton")
                
                -- Clear the override after a short delay
                C_Timer.After(1, function()
                    ClearOverrideBindings(fishingButton)
                end)
            end
        end
        lastClickTime = now
    end)

    fishingButton:SetScript("PostClick", function()
        ClearOverrideBindings(fishingButton)
    end)
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
