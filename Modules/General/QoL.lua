local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local Module = LT4:NewModule("Quality of Life", "AceEvent-3.0", "AceHook-3.0")

Module.description = "A collection of quality-of-life tweaks."

local function AddID(tooltip, id, typeLabel)
    if InCombatLockdown() or not id or not LT4:GetModuleEnabled("Quality of Life") or not LT4.db.profile.qol.showIDs then return end
    
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
    
    -- Handle Battle Pet links directly
    if itemLink:find("battlepet:") then
        local speciesID = tonumber(itemLink:match("battlepet:(%d+)"))
        if speciesID and speciesID > 0 then
            local numCollected = C_PetJournal.GetNumCollectedInfo(speciesID)
            return numCollected and numCollected > 0
        end
        return false
    end

    local itemID = C_Item.GetItemInfoInstant(itemLink)
    if not itemID then return false end

    -- Mounts
    local mountID = C_MountJournal.GetMountFromItem(itemID)
    if type(mountID) == "number" and mountID > 0 then
        local isCollected = select(11, C_MountJournal.GetMountInfoByID(mountID))
        if isCollected then return true end
    end

    -- Pets
    local speciesID = C_PetJournal.GetPetInfoByItemID(itemID)
    if type(speciesID) == "number" and speciesID > 0 then
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
            betterFishing = {
                type = "group",
                name = "Better Fishing",
                inline = true,
                order = 1,
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Enable",
                        desc = "Double-right-click while not in combat to cast your fishing rod.",
                        order = 1,
                        get = function() return LT4.db.profile.qol.betterFishing end,
                        set = function(_, val) LT4.db.profile.qol.betterFishing = val end,
                    },
                    sit = {
                        type = "toggle",
                        name = "Sit to fish",
                        desc = "Automatically sit before casting your fishing rod.",
                        order = 2,
                        disabled = function() return not LT4.db.profile.qol.betterFishing end,
                        get = function() return LT4.db.profile.qol.sitFishing end,
                        set = function(_, val) LT4.db.profile.qol.sitFishing = val end,
                    },
                },
            },
            automation = {
                type = "group",
                name = "Merchant Automation",
                inline = true,
                order = 2,
                args = {
                    autoRepair = {
                        type = "toggle",
                        name = "Auto Repair",
                        desc = "Automatically repair your gear when visiting a merchant.",
                        order = 1,
                        get = function() return LT4.db.profile.qol.autoRepair end,
                        set = function(_, val) LT4.db.profile.qol.autoRepair = val end,
                    },
                    useGuildRepair = {
                        type = "toggle",
                        name = "Use Guild Funds",
                        desc = "Use guild funds for auto-repairs if available.",
                        order = 2,
                        disabled = function() return not LT4.db.profile.qol.autoRepair end,
                        get = function() return LT4.db.profile.qol.useGuildRepair end,
                        set = function(_, val) LT4.db.profile.qol.useGuildRepair = val end,
                    },
                    autoSellJunk = {
                        type = "toggle",
                        name = "Auto Sell Junk",
                        desc = "Automatically sell all grey items when visiting a merchant.",
                        width = "full",
                        order = 3,
                        get = function() return LT4.db.profile.qol.autoSellJunk end,
                        set = function(_, val) LT4.db.profile.qol.autoSellJunk = val end,
                    },
                    collectedIndicator = {
                        type = "toggle",
                        name = "Show Collected Indicator",
                        desc = "Adds a green checkmark to items you already own (mounts, pets, toys, etc) in the merchant window.",
                        width = "full",
                        order = 4,
                        get = function() return LT4.db.profile.qol.collectedIndicator end,
                        set = function(_, val) LT4.db.profile.qol.collectedIndicator = val end,
                    },
                },
            },
            squareMinimap = {
                type = "group",
                name = "Square Minimap",
                inline = true,
                order = 3,
                args = {
                    iconSize = {
                        type = "range",
                        name = "Icon Size",
                        desc = "Adjust the size of the minimap addon icons.",
                        min = 16, max = 64, step = 1,
                        order = 1,
                        disabled = function() return not LT4:GetModuleEnabled("SquareMinimap") end,
                        get = function() return LT4.db.profile.minimap.iconSize or 20 end,
                        set = function(_, val)
                            LT4.db.profile.minimap.iconSize = val
                            local sm = LT4:GetModule("SquareMinimap", true)
                            if sm and sm:IsEnabled() then sm:UpdateAllIcons() end
                        end,
                    },
                },
            },
            other = {
                type = "group",
                name = "Other",
                inline = true,
                order = 99,
                args = {
                    showIDs = {
                        type = "toggle",
                        name = "Add IDs to Tooltips",
                        desc = "Adds Item, Spell, Currency, and Achievement IDs to all tooltips globally.",
                        width = "full",
                        order = 1,
                        get = function() return LT4.db.profile.qol.showIDs end,
                        set = function(_, val) LT4.db.profile.qol.showIDs = val end,
                    },
                    mailAlts = {
                        type = "toggle",
                        name = "Show alt list in Mail Send",
                        desc = "Shows a clickable list of your alts beside the Send Mail frame for quick addressing.",
                        width = "full",
                        order = 2,
                        get = function() return LT4.db.profile.qol.mailAlts end,
                        set = function(_, val)
                            LT4.db.profile.qol.mailAlts = val
                            if self.mailAltFrame then
                                if val then
                                    self:UpdateMailAltVisibility()
                                else
                                    self.mailAltFrame:Hide()
                                end
                            end
                        end,
                    },
                    autoConfirmDelete = {
                        type = "toggle",
                        name = "Auto-fill DELETE Confirmation",
                        desc = "Automatically fills in \"DELETE\" when the item deletion confirmation dialog appears.",
                        width = "full",
                        order = 3,
                        get = function() return LT4.db.profile.qol.autoConfirmDelete end,
                        set = function(_, val) LT4.db.profile.qol.autoConfirmDelete = val end,
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
        
        local moduleEnabled = LT4:GetModuleEnabled("Quality of Life")
        local fishingEnabled = LT4.db.profile.qol.betterFishing
        
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
                if LT4.db.profile.qol.sitFishing then
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
    local enabled = LT4:GetModuleEnabled("Quality of Life") and LT4.db.profile.qol.collectedIndicator
    
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
                -- Clear stale originalText from previous pages before checking
                if nameText and nameText.originalText then
                    nameText.originalText = nil
                end

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
    if not LT4:GetModuleEnabled("Quality of Life") then return end

    -- Auto Repair
    if LT4.db.profile.qol.autoRepair and CanMerchantRepair() then
        local repairCost, canRepair = GetRepairAllCost()
        if canRepair and repairCost > 0 then
            local useGuild = LT4.db.profile.qol.useGuildRepair and CanGuildBankRepair()
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
    if LT4.db.profile.qol.autoSellJunk then
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

function Module:RegisterCurrentAlt()
    local name = UnitName("player")
    local realm = GetNormalizedRealmName()
    if not name or not realm then return end
    local key = name .. "-" .. realm
    local classFilename = select(2, UnitClass("player"))
    LT4.db.global.altCharacters[key] = {
        name = name,
        realm = realm,
        class = classFilename,
        lastLogin = time(),
    }
end

function Module:GetSortedAlts()
    local currentName = UnitName("player")
    local currentRealm = GetNormalizedRealmName()
    local currentKey = currentName and currentRealm and (currentName .. "-" .. currentRealm) or ""

    local alts = {}
    for key, data in pairs(LT4.db.global.altCharacters) do
        if key ~= currentKey then
            data.key = key
            table.insert(alts, data)
        end
    end

    local sortMode = LT4.db.profile.qol.mailAltSort
    if sortMode == "alpha" then
        table.sort(alts, function(a, b) return a.name < b.name end)
    else
        table.sort(alts, function(a, b) return (a.lastLogin or 0) > (b.lastLogin or 0) end)
    end
    return alts
end

function Module:GetSortLabel()
    if LT4.db.profile.qol.mailAltSort == "alpha" then
        return "Alts (A-Z)"
    else
        return "Alts (Recent)"
    end
end

function Module:CreateMailAltFrame()
    if self.mailAltFrame then return end

    local frame = CreateFrame("Frame", "LT4MailAltFrame", SendMailFrame, "BackdropTemplate")
    frame:SetSize(130, 200)
    frame:SetPoint("TOPLEFT", SendMailFrame, "TOPRIGHT", 2, -1)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local sortBtn = CreateFrame("Button", nil, frame)
    sortBtn:SetPoint("TOP", 0, -6)
    sortBtn:SetSize(114, 16)
    sortBtn:SetNormalFontObject("GameFontNormalSmall")
    sortBtn:SetHighlightFontObject("GameFontHighlightSmall")
    sortBtn:SetText(self:GetSortLabel())
    sortBtn:GetFontString():SetTextColor(1, 0.82, 0)
    sortBtn:SetScript("OnClick", function()
        if LT4.db.profile.qol.mailAltSort == "alpha" then
            LT4.db.profile.qol.mailAltSort = "login"
        else
            LT4.db.profile.qol.mailAltSort = "alpha"
        end
        sortBtn:SetText(self:GetSortLabel())
        self:RefreshMailAltButtons()
    end)
    sortBtn:SetScript("OnEnter", function(s)
        GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
        GameTooltip:SetText("Click to toggle sort order")
        GameTooltip:Show()
    end)
    sortBtn:SetScript("OnLeave", GameTooltip_Hide)
    frame.sortBtn = sortBtn

    local scrollChild = CreateFrame("Frame", nil, frame)
    scrollChild:SetPoint("TOPLEFT", 8, -24)
    scrollChild:SetPoint("BOTTOMRIGHT", -8, 6)

    frame.scrollChild = scrollChild
    frame.buttons = {}
    self.mailAltFrame = frame
    frame:Hide()
end

function Module:RefreshMailAltButtons()
    if not self.mailAltFrame then return end
    local parent = self.mailAltFrame.scrollChild

    for _, btn in ipairs(self.mailAltFrame.buttons) do
        btn:Hide()
    end

    local alts = self:GetSortedAlts()
    local currentRealm = GetNormalizedRealmName()
    local BUTTON_HEIGHT = 18
    local yOffset = 0

    for i, data in ipairs(alts) do
        local btn = self.mailAltFrame.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, parent)
            btn:SetHeight(BUTTON_HEIGHT)
            btn:SetPoint("TOPLEFT", 0, -yOffset)
            btn:SetPoint("TOPRIGHT", 0, -yOffset)
            btn:SetNormalFontObject("GameFontNormalSmall")
            btn:SetHighlightFontObject("GameFontHighlightSmall")
            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

            local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetColorTexture(1, 1, 1, 0.1)

            self.mailAltFrame.buttons[i] = btn
        end

        btn:SetPoint("TOPLEFT", 0, -yOffset)
        btn:SetPoint("TOPRIGHT", 0, -yOffset)

        local classColor = RAID_CLASS_COLORS[data.class]
        local colorCode = classColor and classColor.colorStr or "ffffffff"
        btn:SetText("|c" .. colorCode .. data.name .. "|r")

        local recipient = data.name
        if data.realm ~= currentRealm then
            recipient = data.name .. "-" .. data.realm
        end

        local altKey = data.key
        btn:SetScript("OnClick", function(_, button)
            if button == "RightButton" then
                LT4.db.global.altCharacters[altKey] = nil
                self:RefreshMailAltButtons()
            else
                SendMailNameEditBox:SetText(recipient)
                SendMailNameEditBox:SetCursorPosition(0)
            end
        end)

        btn:SetScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_RIGHT")
            GameTooltip:AddLine(recipient)
            GameTooltip:AddLine("Right-click to remove", 0.5, 0.5, 0.5)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", GameTooltip_Hide)

        btn:Show()
        yOffset = yOffset + BUTTON_HEIGHT
    end

    -- Resize frame to fit content
    local contentHeight = yOffset + 30
    local minHeight = 50
    self.mailAltFrame:SetHeight(math.max(minHeight, contentHeight))
end

function Module:UpdateMailAltVisibility()
    if not self.mailAltFrame then return end
    local enabled = LT4:GetModuleEnabled("Quality of Life") and LT4.db.profile.qol.mailAlts

    if enabled and MailFrame:IsShown() and SendMailFrame:IsVisible() then
        self:RefreshMailAltButtons()
        self.mailAltFrame:Show()
    else
        self.mailAltFrame:Hide()
    end
end

function Module:MAIL_SHOW()
    self:CreateMailAltFrame()
    self:UpdateMailAltVisibility()
end

function Module:MAIL_CLOSED()
    if self.mailAltFrame then
        self.mailAltFrame:Hide()
    end
end

function Module:OnEnable()
    self:RegisterCurrentAlt()
    self:RegisterEvent("MERCHANT_SHOW")
    self:RegisterEvent("MAIL_SHOW")
    self:RegisterEvent("MAIL_CLOSED")
    self:SecureHook("MerchantFrame_UpdateMerchantInfo", "UpdateMerchantCollectedIndicators")

    -- Update alt list visibility when switching between Inbox/Send Mail tabs
    self:SecureHook("SendMailFrame_Update", "UpdateMailAltVisibility")

    -- Auto-fill DELETE confirmation
    self:SecureHook("StaticPopup_Show", function(which)
        if which ~= "DELETE_GOOD_ITEM" and which ~= "DELETE_GOOD_QUEST_ITEM" and which ~= "DELETE_MAIL" then return end
        if not LT4.db.profile.qol.autoConfirmDelete then return end
        local i = 1
        while true do
            local dialog = _G["StaticPopup" .. i]
            if not dialog then break end
            if dialog.which == which and dialog:IsShown() then
                local editBox = dialog.editBox or _G["StaticPopup" .. i .. "EditBox"]
                if editBox then
                    editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
                end
                break
            end
            i = i + 1
        end
    end)

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
