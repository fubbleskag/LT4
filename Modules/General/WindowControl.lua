local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local Module = LT4:NewModule("Window Control", "AceHook-3.0", "AceEvent-3.0")

Module.description = "Move and resize Blizzard windows."

local db

local SCALE_STEP = 0.05
local SCALE_MIN  = 0.5
local SCALE_MAX  = 2.0

local FRAMES = {
    { name = "CharacterFrame" },
    { name = "ProfessionsBookFrame" },
    { name = "PlayerSpellsFrame" },
    { name = "AchievementFrame",  handle = "Header" },
    { name = "WorldMapFrame", },
    { name = "CommunitiesFrame" },
    { name = "PVEFrame" },
    { name = "CollectionsJournal" },
    { name = "EncounterJournal" },
    --{ name = "TransmogFrame" },
    { name = "MerchantFrame" },
    { name = "AuctionHouseFrame" },
    { name = "MailFrame" },
    { name = "SettingsPanel",     handle = "NineSlice.TopEdge" },
    { name = "BankFrame" },
    { name = "ContainerFrameCombinedBags" },
    { name = "ContainerFrame6" },
    { name = "GuildBankFrame",    handle = "Emblem" },
    { name = "ProfessionsFrame" },
    { name = "FriendsFrame" },
    { name = "QuestFrame" },
    { name = "HousingDashboardFrame" },
    { name = "HousingModelPreviewFrame", insets = { 0, 28, 0, 0 } },
    { name = "DressUpFrame" },
}

local function RefreshDB()
    db = LT4.db.profile.windowControl
end

local function ResolveHandle(frame, path)
    if not path then return frame.TitleContainer or frame end
    local obj = frame
    for key in path:gmatch("[^%.]+") do
        obj = obj[key]
        if not obj then return frame end
    end
    return obj
end

local function SavePosition(frameName, frame)
    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    local existing = db.positions[frameName] or {}
    db.positions[frameName] = {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y,
        scale = existing.scale,
    }
end

local function IsMaximized(frame)
    return frame.IsMaximized and frame:IsMaximized()
end

local function RestorePosition(frameName, frame)
    local pos = db.positions[frameName]
    if not pos then return end
    if pos.point then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    end
    if pos.scale and not IsMaximized(frame) then
        frame:SetScale(pos.scale)
    end
end

local function SetupFrame(entry)
    local frame = _G[entry.name]
    if not frame then return end

    local handle = ResolveHandle(frame, entry.handle)

    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    if not handle.RegisterForDrag then
        local overlay = CreateFrame("Frame", nil, frame)
        overlay:SetAllPoints(handle)
        overlay:SetFrameStrata(frame:GetFrameStrata())
        overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
        handle = overlay
    end

    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")

    if entry.insets then
        handle:SetHitRectInsets(unpack(entry.insets))
    end

    handle:HookScript("OnDragStart", function()
        if InCombatLockdown() then return end
        frame:StartMoving()
    end)

    handle:HookScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        SavePosition(entry.name, frame)
    end)

    handle:HookScript("OnMouseUp", function(_, button)
        if button == "RightButton" then
            db.positions[entry.name] = nil
            frame:SetScale(1)
            frame:ClearAllPoints()
            frame:SetUserPlaced(false)
            UpdateUIPanelPositions(frame)
        end
    end)

    local function onMouseWheel(_, delta)
        if not IsControlKeyDown() then return end
        if InCombatLockdown() then return end
        if IsMaximized(frame) then return end
        local current = frame:GetScale()
        local newScale = math.max(SCALE_MIN, math.min(SCALE_MAX, current + delta * SCALE_STEP))
        frame:SetScale(newScale)
        if not db.positions[entry.name] then
            db.positions[entry.name] = {}
        end
        db.positions[entry.name].scale = newScale
    end

    frame:EnableMouseWheel(true)
    frame:HookScript("OnMouseWheel", onMouseWheel)

    if handle ~= frame then
        handle:EnableMouseWheel(true)
        handle:HookScript("OnMouseWheel", onMouseWheel)
    end

    if frame:IsShown() then
        RestorePosition(entry.name, frame)
    end
end

local function TeardownFrame(entry)
    local frame = _G[entry.name]
    if not frame then return end

    frame:SetMovable(false)
    frame:EnableMouseWheel(false)

    local handle = ResolveHandle(frame, entry.handle)
    handle:EnableMouse(false)
end

local framesByName = {}
local pendingFrames = {}

function Module:OnInitialize()
    RefreshDB()
    LT4.db.RegisterCallback(self, "OnProfileChanged", RefreshDB)

    LT4:RegisterModuleOptions(self:GetName(), {
        type = "group",
        name = self:GetName(),
        desc = self.description,
        args = {
            description = {
                type = "description",
                name = self.description .. "\n\n|cFFFFFF00Drag|r a title bar to move.\n|cFFFFFF00Ctrl + Scroll Wheel|r to resize.\n|cFFFFFF00Right-click|r a title bar to reset position and scale.\n",
                order = 0,
            },
            resetAll = {
                type = "execute",
                name = "Reset All Positions",
                desc = "Clear all saved window positions.",
                order = 1,
                confirm = true,
                confirmText = "Reset all saved window positions?",
                func = function()
                    wipe(db.positions)
                    for name, frame in pairs(framesByName) do
                        frame:SetScale(1)
                        if frame:IsShown() then
                            frame:ClearAllPoints()
                            frame:SetUserPlaced(false)
                            UpdateUIPanelPositions(frame)
                        end
                    end
                end,
            },
        },
    })

    if not LT4:GetModuleEnabled(self:GetName()) then
        self:SetEnabledState(false)
    end
end

local function HookFrameShow(entry, frame)
    framesByName[entry.name] = frame
    frame:HookScript("OnShow", function()
        if InCombatLockdown() or not db.positions[entry.name] then return end
        RestorePosition(entry.name, frame)
    end)
    if frame.Maximize then
        hooksecurefunc(frame, "Maximize", function()
            local pos = db.positions[entry.name]
            if pos and pos.scale then
                frame:SetScale(1)
            end
        end)
    end
    if frame.Minimize then
        hooksecurefunc(frame, "Minimize", function()
            local pos = db.positions[entry.name]
            if pos and pos.scale then
                frame:SetScale(pos.scale)
            end
        end)
    end
end

local function TrySetupPending()
    for i = #pendingFrames, 1, -1 do
        local entry = pendingFrames[i]
        local frame = _G[entry.name]
        if frame then
            SetupFrame(entry)
            HookFrameShow(entry, frame)
            table.remove(pendingFrames, i)
        end
    end
end

function Module:OnEnable()
    RefreshDB()
    wipe(framesByName)
    wipe(pendingFrames)
    for _, entry in ipairs(FRAMES) do
        local frame = _G[entry.name]
        if frame then
            SetupFrame(entry)
            HookFrameShow(entry, frame)
        else
            table.insert(pendingFrames, entry)
        end
    end
    if #pendingFrames > 0 then
        self:RegisterEvent("ADDON_LOADED", function()
            TrySetupPending()
            if #pendingFrames == 0 then
                Module:UnregisterEvent("ADDON_LOADED")
            end
        end)
    end
    self:SecureHook("UpdateUIPanelPositions", function()
        if InCombatLockdown() then return end
        for name, frame in pairs(framesByName) do
            if frame:IsShown() and db.positions[name] then
                RestorePosition(name, frame)
            end
        end
    end)
end

function Module:OnDisable()
    for _, entry in ipairs(FRAMES) do
        TeardownFrame(entry)
    end
    self:UnhookAll()
end
