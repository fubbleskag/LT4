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

local function IsItemCollected(itemLink)
    if not itemLink then return false end
    local itemID = C_Item.GetItemInfoInstant(itemLink)
    if not itemID then return false end

    -- Mounts
    local mountID = C_MountJournal.GetMountFromItem(itemID)
    if mountID then
        local isCollected = select(11, C_MountJournal.GetMountInfoByID(mountID))
        if isCollected then return true end
    end

    -- Pets
    local speciesID = C_PetJournal.GetPetInfoByItemID(itemID)
    if speciesID then
        local numCollected = C_PetJournal.GetNumCollectedInfo(speciesID)
        if numCollected and numCollected > 0 then return true end
    end

    -- Toys
    if PlayerHasToy(itemID) then return true end

    -- Heirlooms
    if C_Heirloom.IsItemHeirloom(itemID) and C_Heirloom.PlayerHasHeirloom(itemID) then
        return true
    end

    -- Recipes and generic "Already Known" check via Tooltip scanning
    local tooltipData = C_TooltipInfo.GetHyperlink(itemLink)
    if tooltipData then
        for _, line in ipairs(tooltipData.lines) do
            if line.leftText and (line.leftText == ITEM_SPELL_KNOWN or line.leftText:find(ITEM_SPELL_KNOWN)) then
                return true
            end
        end
    end

    -- Transmog
    if C_TransmogCollection.PlayerHasTransmog(itemID) then return true end

    return false
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
                type = "group",
                name = "Better Fishing",
                inline = true,
                order = 2,
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Enable Better Fishing",
                        desc = "Double-right-click while not in combat to cast your fishing rod.",
                        order = 1,
                        get = function() return LT4.db.profile.miscellaneous.betterFishing end,
                        set = function(_, val) LT4.db.profile.miscellaneous.betterFishing = val end,
                    },
                    sit = {
                        type = "toggle",
                        name = "Sit while fishing",
                        desc = "Automatically sit before casting your fishing rod.",
                        order = 2,
                        disabled = function() return not LT4.db.profile.miscellaneous.betterFishing end,
                        get = function() return LT4.db.profile.miscellaneous.sitFishing end,
                        set = function(_, val) LT4.db.profile.miscellaneous.sitFishing = val end,
                    },
                },
            },
            automation = {
                type = "group",
                name = "Merchant Automation",
                inline = true,
                order = 3,
                args = {
                    autoRepair = {
                        type = "toggle",
                        name = "Auto Repair",
                        desc = "Automatically repair your gear when visiting a merchant.",
                        order = 1,
                        get = function() return LT4.db.profile.miscellaneous.autoRepair end,
                        set = function(_, val) LT4.db.profile.miscellaneous.autoRepair = val end,
                    },
                    useGuildRepair = {
                        type = "toggle",
                        name = "Use Guild Funds",
                        desc = "Use guild funds for auto-repairs if available.",
                        order = 2,
                        disabled = function() return not LT4.db.profile.miscellaneous.autoRepair end,
                        get = function() return LT4.db.profile.miscellaneous.useGuildRepair end,
                        set = function(_, val) LT4.db.profile.miscellaneous.useGuildRepair = val end,
                    },
                    autoSellJunk = {
                        type = "toggle",
                        name = "Auto Sell Junk",
                        desc = "Automatically sell all grey items when visiting a merchant.",
                        order = 3,
                        get = function() return LT4.db.profile.miscellaneous.autoSellJunk end,
                        set = function(_, val) LT4.db.profile.miscellaneous.autoSellJunk = val end,
                    },
                    collectedIndicator = {
                        type = "toggle",
                        name = "Show Collected Indicator",
                        desc = "Adds a green checkmark to items you already own (mounts, pets, toys, etc) in the merchant window.",
                        order = 4,
                        get = function() return LT4.db.profile.miscellaneous.collectedIndicator end,
                        set = function(_, val) LT4.db.profile.miscellaneous.collectedIndicator = val end,
                    },
                },
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
    fishingButton:SetAttribute("type", "macro")
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
                local macrotext = "/cast " .. fishingSpellName
                if LT4.db.profile.miscellaneous.sitFishing then
                    macrotext = "/sit\n" .. macrotext
                end
                fishingButton:SetAttribute("macrotext", macrotext)
                
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

function Module:UpdateMerchantCollectedIndicators()
    local enabled = LT4:GetModuleEnabled("Miscellaneous") and LT4.db.profile.miscellaneous.collectedIndicator
    
    for i = 1, MERCHANT_ITEMS_PER_PAGE do
        local index = (((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE) + i)
        local itemButton = _G["MerchantItem"..i.."ItemButton"]
        local slot = _G["MerchantItem"..i]
        local nameText = _G["MerchantItem"..i.."Name"]
        
        if not enabled then
            -- Cleanup
            if itemButton then
                if itemButton.collectedChecked then itemButton.collectedChecked:Hide() end
                if itemButton.collectedCheckedBG then itemButton.collectedCheckedBG:Hide() end
            end
            if nameText and nameText.originalText then
                nameText:SetText(nameText.originalText)
                nameText.originalText = nil
            end
        else
            if slot and slot:IsShown() and itemButton then
                local itemLink = GetMerchantItemLink(index)
                local isCollected = itemLink and IsItemCollected(itemLink)
                
                -- Checkmark Indicator
                if isCollected then
                    if not itemButton.collectedChecked then
                        itemButton.collectedChecked = itemButton:CreateTexture(nil, "OVERLAY", nil, 7)
                        itemButton.collectedChecked:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
                        itemButton.collectedChecked:SetSize(34, 34)
                        itemButton.collectedChecked:SetPoint("CENTER", itemButton, "CENTER")
                        itemButton.collectedChecked:SetAlpha(0.75)
                    end
                    if itemButton.collectedCheckedBG then itemButton.collectedCheckedBG:Hide() end
                    itemButton.collectedChecked:Show()
                else
                    if itemButton.collectedChecked then itemButton.collectedChecked:Hide() end
                    if itemButton.collectedCheckedBG then itemButton.collectedCheckedBG:Hide() end
                end

                -- Text Injection
                if nameText then
                    local currentText = nameText:GetText()
                    if isCollected then
                        if currentText and not currentText:find("|cffff0000%[Known%]|r") then
                            nameText.originalText = currentText
                            nameText:SetText("|cffff0000[Known]|r " .. currentText)
                        end
                    elseif nameText.originalText then
                        nameText:SetText(nameText.originalText)
                        nameText.originalText = nil
                    end
                end
            else
                if itemButton then
                    if itemButton.collectedChecked then itemButton.collectedChecked:Hide() end
                    if itemButton.collectedCheckedBG then itemButton.collectedCheckedBG:Hide() end
                end
                if nameText and nameText.originalText then
                    nameText:SetText(nameText.originalText)
                    nameText.originalText = nil
                end
            end
        end
    end
end

function Module:MERCHANT_SHOW()
    if not LT4:GetModuleEnabled("Miscellaneous") then return end

    -- Auto Repair
    if LT4.db.profile.miscellaneous.autoRepair and CanMerchantRepair() then
        local repairCost, canRepair = GetRepairAllCost()
        if canRepair and repairCost > 0 then
            local useGuild = LT4.db.profile.miscellaneous.useGuildRepair and CanGuildBankRepair()
            if useGuild then
                local guildMoney = GetGuildBankMoney()
                local amount = GetGuildBankWithdrawMoney() -- -1 means unlimited
                if guildMoney >= repairCost and (amount == -1 or amount >= repairCost) then
                    RepairAllItems(true)
                    LT4:Print(string.format("Repaired items using guild funds: %s", GetCoinTextureString(repairCost)))
                elseif GetMoney() >= repairCost then
                    RepairAllItems()
                    LT4:Print(string.format("Repaired items: %s", GetCoinTextureString(repairCost)))
                end
            elseif GetMoney() >= repairCost then
                RepairAllItems()
                LT4:Print(string.format("Repaired items: %s", GetCoinTextureString(repairCost)))
            end
        end
    end

    -- Auto Sell Junk
    if LT4.db.profile.miscellaneous.autoSellJunk then
        local profit = 0
        for bag = 0, 5 do
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.quality == 0 and not info.hasNoValue and not info.isLocked then
                    local sellPrice = select(11, C_Item.GetItemInfo(info.hyperlink))
                    if sellPrice then
                        profit = profit + (info.stackCount * sellPrice)
                    end
                    C_Container.UseContainerItem(bag, slot)
                end
            end
        end
        if profit > 0 then
            LT4:Print(string.format("Sold junk for: %s", GetCoinTextureString(profit)))
        end
    end
end

function Module:OnEnable()
    self:RegisterEvent("MERCHANT_SHOW")
    self:SecureHook("MerchantFrame_UpdateMerchantInfo", "UpdateMerchantCollectedIndicators")

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
    self:UnhookAll()
    -- TooltipDataProcessor.AddTooltipPostCall doesn't have an easy "un-register" for a closure.
    -- However, we handle the enabled check inside AddID().
end
