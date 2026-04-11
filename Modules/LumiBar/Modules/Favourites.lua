local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
local Utils = LumiBar.Utils
local Data = LumiBar.Data

local Favourites = {}
LumiBar:RegisterModule("Favourites", Favourites)

-- Performance: Cache common lookups
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local InCombatLockdown = InCombatLockdown
local PlayerHasToy = PlayerHasToy
local GetItemCooldown = GetItemCooldown
local GetItemInfo = GetItemInfo
local GetTime = GetTime
local C_MountJournal = C_MountJournal
local C_PetJournal = C_PetJournal
local C_ToyBox = C_ToyBox
local C_TransmogOutfitInfo = C_TransmogOutfitInfo
local C_Timer = C_Timer
local UIParent = UIParent
local ipairs = ipairs
local type = type
local wipe = wipe
local unpack = unpack
local table_insert = table.insert
local table_sort = table.sort
local string_format = string.format
local math_ceil = math.ceil

local categories = {
    {
        id = "Mounts",
        label = "Mounts",
        atlas = "category-icons_mounts_inactive",
    },
    {
        id = "Pets",
        label = "Pets",
        atlas = "category-icons_pets_inactive",
    },
    {
        id = "Toys",
        label = "Toys",
        atlas = "category-icons_interactive_inactive",
    },
    {
        id = "Outfits",
        label = "Outfits",
        atlas = "category-icons_storage_inactive",
    },
}

-- Cached lists per category, invalidated by events
local cache = {}

function Favourites:InvalidateCache(which)
    if which then cache[which] = nil else cache = {} end
end

local function GetCooldownInfo(itemID)
    local start, duration = GetItemCooldown(itemID)
    if start and duration and duration > 0 then
        local remain = duration - (GetTime() - start)
        if remain > 0 then return remain, duration end
    end
    return 0, 0
end

function Favourites:BuildMountList()
    if cache.Mounts then return cache.Mounts end
    local items = {}
    local mountIDs = C_MountJournal.GetMountIDs() or {}
    for _, mountID in ipairs(mountIDs) do
        local name, spellID, icon, _, isUsable, _, isFavorite, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
        if isCollected and isFavorite and isUsable and spellID then
            local sID = spellID
            table_insert(items, {
                type = "macro",
                macrotext = string_format("/run C_MountJournal.SummonByID(%d)", mountID),
                name = name or "Unknown Mount",
                icon = icon,
                tooltip = function(tt) tt:SetMountBySpellID(sID) end,
            })
        end
    end
    table_sort(items, function(a, b) return a.name < b.name end)
    cache.Mounts = items
    return items
end

function Favourites:BuildPetList()
    if cache.Pets then return cache.Pets end
    local items = {}
    local numPets = C_PetJournal.GetNumPets() or 0
    for i = 1, numPets do
        local petID, _, owned, customName, _, favorite, _, speciesName, icon = C_PetJournal.GetPetInfoByIndex(i)
        if owned and favorite and petID then
            local displayName = (customName and customName ~= "" and customName) or speciesName or "Unknown Pet"
            local id = petID
            table_insert(items, {
                type = "macro",
                macrotext = string_format("/run C_PetJournal.SummonPetByGUID(\"%s\")", petID),
                name = displayName,
                icon = icon,
                tooltip = function(tt) tt:SetCompanionPet(id) end,
            })
        end
    end
    table_sort(items, function(a, b) return a.name < b.name end)
    cache.Pets = items
    return items
end

function Favourites:BuildToyList()
    if cache.Toys then return cache.Toys end
    local items = {}
    -- Note: iterates within current ToyBox filter state
    local numToys = C_ToyBox.GetNumToys() or 0
    for i = 1, numToys do
        local itemID = C_ToyBox.GetToyFromIndex(i)
        if itemID and itemID ~= 0 then
            local _, toyName, icon, isFavorite = C_ToyBox.GetToyInfo(itemID)
            if isFavorite and PlayerHasToy(itemID) and not Data.HearthstoneData[itemID] then
                table_insert(items, {
                    type = "toy",
                    id = itemID,
                    name = toyName or GetItemInfo(itemID) or "Unknown Toy",
                    icon = icon,
                })
            end
        end
    end
    table_sort(items, function(a, b) return a.name < b.name end)
    cache.Toys = items
    return items
end

-- Outfit click-forwarding: stage TransmogFrame hidden to populate its ScrollBox,
-- then forward clicks to the real OutfitIcon buttons so outfits apply in one click.
local outfitButtonCache = {}
local transmogStaged = false
local savedTransmogState = {}

local function StageTransmogFrame()
    if InCombatLockdown() then return false end
    if not TransmogFrame and Transmog_LoadUI then Transmog_LoadUI() end
    if not TransmogFrame then return false end
    if transmogStaged then return true end
    if TransmogFrame:IsShown() then return true end

    savedTransmogState.alpha = TransmogFrame:GetAlpha()
    savedTransmogState.points = {}
    for i = 1, TransmogFrame:GetNumPoints() do
        savedTransmogState.points[i] = { TransmogFrame:GetPoint(i) }
    end

    TransmogFrame:SetAlpha(0)
    TransmogFrame:ClearAllPoints()
    TransmogFrame:SetPoint("CENTER", UIParent, "CENTER", 100000, 0)
    TransmogFrame:Show()
    transmogStaged = true
    return true
end

local function UnstageTransmogFrame()
    if not transmogStaged then return end
    if InCombatLockdown() then return end
    if TransmogFrame then
        TransmogFrame:Hide()
        TransmogFrame:SetAlpha(savedTransmogState.alpha or 1)
        TransmogFrame:ClearAllPoints()
        if savedTransmogState.points and #savedTransmogState.points > 0 then
            for _, p in ipairs(savedTransmogState.points) do
                TransmogFrame:SetPoint(unpack(p))
            end
        else
            TransmogFrame:SetPoint("CENTER")
        end
    end
    transmogStaged = false
    wipe(savedTransmogState)
    wipe(outfitButtonCache)
end

local function ScanOutfitIcons()
    wipe(outfitButtonCache)
    if not TransmogFrame or not TransmogFrame.OutfitCollection then return end
    local list = TransmogFrame.OutfitCollection.OutfitList
    if not list or not list.ScrollBox then return end
    local sb = list.ScrollBox
    if not sb.ForEachFrame then return end
    sb:ForEachFrame(function(frame, elementData)
        local id
        if elementData then
            id = elementData.outfitID or elementData.id
        end
        if not id and frame.GetElementData then
            local ed = frame:GetElementData()
            if ed then id = ed.outfitID or ed.id end
        end
        if id and frame.OutfitIcon then
            outfitButtonCache[id] = frame.OutfitIcon
        end
    end)
end

local function OpenTransmogForOutfit(outfitID)
    if InCombatLockdown() then return end
    if not TransmogFrame and Transmog_LoadUI then
        Transmog_LoadUI()
    end
    if not TransmogFrame then return end
    if C_TransmogOutfitInfo and C_TransmogOutfitInfo.ChangeViewedOutfit then
        C_TransmogOutfitInfo.ChangeViewedOutfit(outfitID)
    end
    if not TransmogFrame:IsShown() then
        TransmogFrame:Show()
    end
end

function Favourites:BuildOutfitList()
    if cache.Outfits then return cache.Outfits end
    local items = {}
    local outfits = C_TransmogOutfitInfo and C_TransmogOutfitInfo.GetOutfitsInfo() or {}
    local activeID = C_TransmogOutfitInfo and C_TransmogOutfitInfo.GetActiveOutfitID and C_TransmogOutfitInfo.GetActiveOutfitID()
    for _, info in ipairs(outfits) do
        if info.outfitID and not info.isDisabled then
            local outfitName = info.name or "Outfit"
            local outfitID = info.outfitID
            local isActive = (activeID == outfitID)
            local clickTarget = outfitButtonCache[outfitID]
            local item = {
                name = outfitName,
                icon = info.icon,
                isActive = isActive,
                tooltip = function(tt)
                    local r, g, b = Utils:GetAccentColor()
                    tt:AddLine(outfitName, r, g, b)
                    if isActive then
                        tt:AddLine("|cff00ff00Currently active|r")
                    end
                    tt:AddLine(" ")
                    if clickTarget then
                        tt:AddLine("|cffFFFFFFLeft-click:|r Apply outfit", 0, 1, 0)
                    else
                        tt:AddLine("|cffFFFFFFLeft-click:|r Open transmog & preview", 0, 1, 0)
                    end
                end,
            }
            if clickTarget then
                item.type = "click"
                item.clickTarget = clickTarget
            else
                item.preClick = function() OpenTransmogForOutfit(outfitID) end
            end
            table_insert(items, item)
        end
    end
    table_sort(items, function(a, b) return a.name < b.name end)
    cache.Outfits = items
    return items
end

local function AddToyCooldowns(items)
    for _, item in ipairs(items) do
        if item.type == "toy" and item.id then
            local remain, total = GetCooldownInfo(item.id)
            if remain > 0 and total > 0 then
                item.bar = (remain / total) * 100
                if remain > 60 then
                    item.value = string_format("%dm", math_ceil(remain / 60))
                else
                    item.value = string_format("%ds", math_ceil(remain))
                end
            else
                item.bar = nil
                item.value = nil
            end
        end
    end
    return items
end

function Favourites:BuildList(catID)
    if catID == "Mounts" then return self:BuildMountList()
    elseif catID == "Pets" then return self:BuildPetList()
    elseif catID == "Toys" then return AddToyCooldowns(self:BuildToyList())
    elseif catID == "Outfits" then return self:BuildOutfitList() end
    return {}
end

function Favourites:Init()
    self.db = LumiBar.db.profile.modules.Favourites

    local options = {
        name = "Favourites",
        type = "group",
        get = function(info) return self.db[info[#info]] end,
        set = function(info, value)
            self.db[info[#info]] = value
            self:Refresh()
        end,
        args = {
            displayGroup = {
                name = "Display",
                type = "group",
                inline = true,
                order = 1,
                args = {
                    autoSize = {
                        name = "Auto Size to Bar",
                        desc = "Match the height of the LumiBar automatically.",
                        type = "toggle",
                        width = "full",
                        order = 1,
                    },
                    iconSize = {
                        name = "Custom Icon Size",
                        type = "range",
                        width = "full",
                        min = 10, max = 100, step = 1,
                        hidden = function() return self.db.autoSize end,
                        order = 2,
                    },
                    spacing = { name = "Spacing", type = "range", width = "full", min = -10, max = 20, step = 1, order = 3 },
                },
            },
            categoryGroup = {
                name = "Categories",
                type = "group",
                inline = true,
                order = 2,
                args = {
                    showMounts  = { name = "Mounts",         type = "toggle", width = "full", order = 1 },
                    showPets    = { name = "Pets",           type = "toggle", width = "full", order = 2 },
                    showToys    = { name = "Toys",           type = "toggle", width = "full", order = 3 },
                    showOutfits = { name = "Transmog", type = "toggle", width = "full", order = 4 },
                },
            },
        },
    }

    LumiBar:RegisterModuleOptions("Favourites", options)
end

function Favourites:ShowCategoryTooltip(btn, cat)
    local anchor = (LumiBar.db.profile.bar.position == "BOTTOM") and "ANCHOR_TOP" or "ANCHOR_BOTTOM"
    GameTooltip:SetOwner(btn, anchor)
    local r, g, b = Utils:GetAccentColor()
    GameTooltip:AddLine(cat.label, r, g, b)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffFFFFFFRight-click:|r Open favourites", 0, 1, 0)
    GameTooltip:Show()
end

function Favourites:OpenFlyout(btn, cat)
    if InCombatLockdown() then return end
    local direction = (LumiBar.db.profile.bar.position == "BOTTOM") and "UP" or "DOWN"

    if cat.id == "Outfits" then
        self:InvalidateCache("Outfits")
        wipe(outfitButtonCache)
        local staged = StageTransmogFrame()
        local function finish()
            if InCombatLockdown() then return end
            ScanOutfitIcons()
            self:InvalidateCache("Outfits")
            local items = self:BuildList(cat.id)
            if #items == 0 then
                items = { { name = "|cff888888No " .. cat.label:lower() .. "|r" } }
            end
            LumiBar.SecureFlyout:ShowMenu(btn, items, direction)
        end
        if staged and C_Timer and C_Timer.After then
            C_Timer.After(0, finish)
        else
            finish()
        end
        return
    end

    local items = self:BuildList(cat.id)
    if #items == 0 then
        items = { { name = "|cff888888No " .. cat.label:lower() .. "|r" } }
    end
    LumiBar.SecureFlyout:ShowMenu(btn, items, direction)
end

function Favourites:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.Favourites
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, slotFrame, "BackdropTemplate")
        self.btns = {}
        for _, cat in ipairs(categories) do
            local btn = CreateFrame("Button", nil, self.frame)
            btn.icon = btn:CreateTexture(nil, "ARTWORK")
            btn.icon:SetAllPoints()
            btn.icon:SetAtlas(cat.atlas)

            btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            btn.highlight:SetAllPoints()
            btn.highlight:SetAtlas(cat.atlas)
            btn.highlight:SetBlendMode("ADD")
            btn.highlight:SetAlpha(0.3)

            local category = cat
            btn:SetScript("OnMouseDown", function(f, button)
                if button == "RightButton" then
                    self:OpenFlyout(f, category)
                end
            end)
            btn:SetScript("OnEnter", function(f) self:ShowCategoryTooltip(f, category) end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

            self.btns[cat.id] = btn
        end
    end

    if not self.flyoutHooked and LumiBar.SecureFlyout then
        LumiBar.SecureFlyout:HookScript("OnHide", function()
            UnstageTransmogFrame()
        end)
        self.flyoutHooked = true
    end

    if not self.eventsRegistered then
        self.frame:RegisterEvent("NEW_MOUNT_ADDED")
        self.frame:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
        self.frame:RegisterEvent("COMPANION_LEARNED")
        self.frame:RegisterEvent("NEW_PET_ADDED")
        self.frame:RegisterEvent("PET_JOURNAL_LIST_UPDATE")
        self.frame:RegisterEvent("NEW_TOY_ADDED")
        self.frame:RegisterEvent("TOYS_UPDATED")
        self.frame:SetScript("OnEvent", function(_, event)
            if event == "NEW_MOUNT_ADDED" or event == "MOUNT_JOURNAL_USABILITY_CHANGED" then
                self:InvalidateCache("Mounts")
            elseif event == "COMPANION_LEARNED" or event == "NEW_PET_ADDED" or event == "PET_JOURNAL_LIST_UPDATE" then
                self:InvalidateCache("Pets")
            elseif event == "NEW_TOY_ADDED" or event == "TOYS_UPDATED" then
                self:InvalidateCache("Toys")
            end
        end)
        self.eventsRegistered = true
    end

    self:InvalidateCache()
    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:Show()
    self:Refresh(slotFrame)
end

function Favourites:Refresh(slotFrame)
    if not self.frame then return end
    slotFrame = slotFrame or self.frame:GetParent()
    if not slotFrame then return end

    self.frame:SetHeight(slotFrame:GetHeight())
    Utils:ApplyBackground(self.frame, self.db)

    local prevBtn = nil
    local totalWidth = 0
    local spacing = self.db.spacing or 2

    local iconHeight
    if self.db.autoSize then
        iconHeight = slotFrame:GetHeight()
    else
        iconHeight = self.db.iconSize or 20
    end
    local iconWidth = iconHeight

    for _, cat in ipairs(categories) do
        local btn = self.btns[cat.id]
        if self.db["show" .. cat.id] then
            btn:Show()
            btn:SetSize(iconWidth, iconHeight)
            btn:ClearAllPoints()
            if not prevBtn then
                btn:SetPoint("LEFT", self.frame, "LEFT", 0, 0)
            else
                btn:SetPoint("LEFT", prevBtn, "RIGHT", spacing, 0)
            end
            totalWidth = totalWidth + iconWidth + (prevBtn and spacing or 0)
            prevBtn = btn
        else
            btn:Hide()
        end
    end

    self:UpdateWidth(totalWidth)
end

function Favourites:UpdateWidth(width)
    Utils:UpdateModuleWidth(self, width, function() self:Refresh() end)
end

function Favourites:Disable()
    cache = {}
    UnstageTransmogFrame()
    if self.frame then
        self.frame:UnregisterAllEvents()
        self.eventsRegistered = false
    end
end
