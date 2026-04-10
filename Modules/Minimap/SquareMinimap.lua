local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local Module = LT4:NewModule("SquareMinimap", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local LDI = LibStub("LibDBIcon-1.0")

Module.description = "Transforms the circular minimap into a sleek, square design and skins addon icons for a consistent flat look."
Module.requiresReload = true -- Changing the mask is best handled via reload for stability

-- Throttle intervals (seconds)
local SKIN_ICONS_INTERVAL = 5
local QUEUE_UPDATE_INTERVAL = 3
local HOVER_UPDATE_INTERVAL = 0.05

-- Override global GetMinimapShape so LibDBIcon and other libs know we are square
function GetMinimapShape()
    if LT4:GetModuleEnabled("SquareMinimap") then
        return "SQUARE"
    else
        return "ROUND"
    end
end

function Module:OnInitialize()
    LT4:RegisterModuleOptions(self:GetName(), {
        type = "group",
        name = self:GetName(),
        desc = self.description,
        args = {
            description = {
                type = "description",
                name = self.description .. "\n\nSettings for this module can be found under Quality of Life.",
                order = 0,
            },
        },
    })

    if not LT4:GetModuleEnabled(self:GetName()) then
        self:SetEnabledState(false)
    end
end

function Module:OnEnable()
    -- Initialize defaults if missing
    if not LT4.db.profile.minimap.iconSize then
        LT4.db.profile.minimap.iconSize = 20
    end
    if not LT4.db.profile.minimap.buttons then
        LT4.db.profile.minimap.buttons = {}
    end

    self:UpdateMinimap()
    self:CreateMinimapButtons()
    self:SkinAddonIcons()

    -- Register events for new icons
    self:RegisterEvent("ADDON_LOADED", "SkinAddonIcons")
    self:ScheduleRepeatingTimer("SkinAddonIcons", SKIN_ICONS_INTERVAL)

    -- Mail events
    self:RegisterEvent("UPDATE_PENDING_MAIL", "UpdateMailButton")

    -- Queue events
    self:RegisterEvent("LFG_UPDATE", "UpdateQueueButton")
    self:RegisterEvent("LFG_QUEUE_STATUS_UPDATE", "UpdateQueueButton")
    self:RegisterEvent("LFG_COMPLETION_REWARD", "UpdateQueueButton")
    self:RegisterEvent("LFG_PROPOSAL_DONE", "UpdateQueueButton")
    self:RegisterEvent("LFG_PROPOSAL_FAILED", "UpdateQueueButton")
    self:RegisterEvent("LFG_PROPOSAL_SUCCEEDED", "UpdateQueueButton")
    self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS", "UpdateQueueButton")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateQueueButton")
    -- Periodic fallback for queue status (catches edge cases)
    self:ScheduleRepeatingTimer("UpdateQueueButton", QUEUE_UPDATE_INTERVAL)

    -- Throttled updates as per project mandates
    self:ScheduleRepeatingTimer("ThrottledUpdate", HOVER_UPDATE_INTERVAL)
end

function Module:OnDisable()
    -- Most changes require reload to fully revert, which is handled by Core.lua
end

function Module:ThrottledUpdate()
    -- Ensure minimap fills container and corner elements stay positioned
    self:ResizeToFillContainer()
    self:PositionElements()

    -- Hover-only elements: zone text, tracking, addon compartment
    local hoverFrames = {
        MinimapZoneText or (MinimapCluster and MinimapCluster.ZoneTextButton),
        MinimapCluster and MinimapCluster.Tracking and MinimapCluster.Tracking.Button,
        AddonCompartmentFrame or (MinimapCluster and MinimapCluster.AddonCompartment),
    }

    local isOver = MouseIsOver(Minimap)
    -- Also count hovering any of the hover frames themselves
    if not isOver then
        for _, f in ipairs(hoverFrames) do
            if f and MouseIsOver(f) then
                isOver = true
                break
            end
        end
    end

    for _, f in ipairs(hoverFrames) do
        if f then
            if not f.lt4MouseEnabled then
                f:EnableMouse(true)
                f.lt4MouseEnabled = true
            end
            if not f:IsShown() then f:Show() end
            f:SetAlpha(isOver and 1 or 0)
        end
    end
end

--------------------------------------------------------------------------------
-- Minimap Button Replacements (Mail & Queue as LibDBIcon draggable buttons)
--------------------------------------------------------------------------------

function Module:CreateMinimapButtons()
    local buttons = LT4.db.profile.minimap.buttons

    local defs = {
        {
            name = "LT4_Mail",
            key = "mail",
            defaultPos = 230,
            icon = "Interface\\Cursor\\Crosshair\\UIMailCrosshair2x",
            atlas = "crosshair_mail_96",
            label = "Mail",
            onClick = function() end, -- Indicator only
            onTooltip = function(tooltip)
                tooltip:AddLine("|cFFFFFFFFMail|r")
                if HasNewMail() then
                    tooltip:AddLine("You have unread mail", 0, 1, 0)
                else
                    tooltip:AddLine("No new mail", 0.5, 0.5, 0.5)
                end
            end,
        },
        {
            name = "LT4_Queue",
            key = "queue",
            defaultPos = 220,
            icon = "Interface\\HUD\\UIGroupFinderFlipbook",
            atlas = "groupfinder-eye-frame",
            label = "Queue Status",
            onClick = function(_, btn)
                if QueueStatusButton and QueueStatusButton.Click then
                    QueueStatusButton:Click(btn)
                end
            end,
            onTooltip = function(tooltip)
                tooltip:AddLine("|cFFFFFFFFQueue Status|r")
                tooltip:AddLine("Click to view queue info", 0.8, 0.8, 0.8)
            end,
        },
    }

    self.minimapButtons = {}

    for _, def in ipairs(defs) do
        -- Initialize saved position if missing
        if not buttons[def.key] then
            buttons[def.key] = { minimapPos = def.defaultPos }
        end

        -- Create LDB data object
        local dataObj = LDB:NewDataObject(def.name, {
            type = "launcher",
            icon = def.icon,
            text = def.label,
            OnClick = def.onClick,
            OnTooltipShow = def.onTooltip,
        })

        -- Register with LibDBIcon (positions around minimap edge, draggable)
        LDI:Register(def.name, dataObj, buttons[def.key])

        self.minimapButtons[def.key] = {
            name = def.name,
            dataObject = dataObj,
        }

        -- Apply atlas override if specified
        if def.atlas then
            local btn = LDI.objects[def.name]
            if btn and btn.icon then
                btn.icon:SetAtlas(def.atlas)
            end
        end
    end

    -- Set initial visibility for conditional buttons
    self:UpdateMailButton()
    self:UpdateQueueButton()
end

function Module:UpdateMailButton()
    if not self.minimapButtons or not self.minimapButtons.mail then return end
    local btn = LDI.objects[self.minimapButtons.mail.name]
    if not btn then return end

    if HasNewMail() then
        btn:SetAlpha(1)
        btn:Show()
    else
        btn:Hide()
    end
end

function Module:UpdateQueueButton()
    if not self.minimapButtons or not self.minimapButtons.queue then return end
    local btn = LDI.objects[self.minimapButtons.queue.name]
    if not btn then return end

    local hasQueue = false
    -- Check battlefield / BG queues
    for i = 1, GetMaxBattlefieldID() do
        local status = GetBattlefieldStatus(i)
        if status and status ~= "none" then
            hasQueue = true
            break
        end
    end
    -- Check LFG queues
    if not hasQueue then
        for i = 1, (NUM_LE_LFG_CATEGORYS or 0) do
            local mode = GetLFGMode(i)
            if mode and mode ~= "none" then
                hasQueue = true
                break
            end
        end
    end

    if hasQueue then
        btn:SetAlpha(1)
        btn:Show()
    else
        btn:Hide()
    end
end

--------------------------------------------------------------------------------
-- Minimap Setup
--------------------------------------------------------------------------------

function Module:UpdateMinimap()
    -- Apply square mask
    Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")

    -- Hide Blizzard art
    local hideFrames = {
        MinimapBackdrop,
        TimeManagerClockButton,
        GameTimeFrame,
        MinimapCluster.BorderTop,
        MinimapCluster.InstanceDifficulty,
        MinimapCluster.IndicatorFrame.MailFrame,
    }

    for _, frame in pairs(hideFrames) do
        if frame then
            frame:Hide()
            frame:SetAlpha(0)
        end
    end

    -- Fully hide mail and queue originals (we handle visibility ourselves)
    if MiniMapMailFrame then
        MiniMapMailFrame:Hide()
        MiniMapMailFrame:SetAlpha(0)
        -- Prevent Blizzard from re-showing the mail indicator
        if not self.mailShowHooked then
            hooksecurefunc(MiniMapMailFrame, "Show", function(f)
                f:Hide()
            end)
            self.mailShowHooked = true
        end
    end
    if QueueStatusButton then
        QueueStatusButton:Hide()
        QueueStatusButton:SetAlpha(0)
    end

    -- Style zone text: smaller, centered
    local zoneText = MinimapZoneText
    if zoneText then
        local font, _, flags = zoneText:GetFont()
        zoneText:SetFont(font, 10, flags)
        zoneText:SetJustifyH("CENTER")
    end

    -- Fill the container width (remain square)
    self:ResizeToFillContainer()

    -- Position corner elements
    self:PositionElements()

    -- Hook container size changes
    if not self.clusterSizeHooked then
        hooksecurefunc(MinimapCluster, "SetSize", function()
            self:ResizeToFillContainer()
        end)
        self.clusterSizeHooked = true
    end

    -- Enable mouse wheel zoom
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(_, delta)
        if delta > 0 then
            Minimap_ZoomIn()
        else
            Minimap_ZoomOut()
        end
    end)
end

function Module:ResizeToFillContainer()
    -- Explicit SetSize is required — the Minimap widget's internal rendering
    -- viewport only updates from SetSize, not from anchor-driven resizing.
    -- Divide by parent scale to account for EditMode size %.
    local parentScale = Minimap:GetParent():GetScale()
    local size = MinimapCluster:GetWidth() / parentScale
    Minimap:ClearAllPoints()
    Minimap:SetPoint("TOPLEFT", MinimapCluster, "TOPLEFT", 0, 0)
    Minimap:SetSize(size, size)
end

function Module:PositionElements()
    local frames = {
        -- Addon Compartment
        {
            frame = AddonCompartmentFrame or (MinimapCluster and MinimapCluster.AddonCompartment),
            point = "TOPRIGHT",
            x = -4, y = -4
        },
        -- Zone Text
        {
            frame = MinimapZoneText or (MinimapCluster and MinimapCluster.ZoneTextButton),
            point = "TOP",
            x = 0, y = -4
        },
        -- Tracking Button
        {
            frame = MinimapCluster and MinimapCluster.Tracking and MinimapCluster.Tracking.Button,
            point = "BOTTOMRIGHT",
            x = -4, y = 4
        },
    }

    for _, data in ipairs(frames) do
        local frame = data.frame
        if frame then
            if not frame.lt4HooksApplied then
                frame:SetParent(Minimap)
                -- Force the position and prevent Blizzard from overriding it
                hooksecurefunc(frame, "SetPoint", function(f)
                    if f.lt4IsPositioning then return end
                    f.lt4IsPositioning = true
                    f:ClearAllPoints()
                    f:SetPoint(data.point, Minimap, data.point, data.x, data.y)
                    f.lt4IsPositioning = nil
                end)
                frame.lt4HooksApplied = true
            end

            -- Manual update in case hooks aren't firing or for initial load
            frame.lt4IsPositioning = true
            frame:ClearAllPoints()
            frame:SetPoint(data.point, Minimap, data.point, data.x, data.y)
            frame.lt4IsPositioning = nil
        end
    end
end

--------------------------------------------------------------------------------
-- Addon Icon Skinning
--------------------------------------------------------------------------------

function Module:UpdateAllIcons()
    if LDI then
        local size = LT4.db.profile.minimap.iconSize or 20
        LDI:SetButtonRadius(size / 2)

        for _, button in pairs(LDI.objects) do
            self:SkinButton(button, true)
        end
    end
end

function Module:SkinAddonIcons()
    if LDI then
        local size = LT4.db.profile.minimap.iconSize or 20
        LDI:SetButtonRadius(size / 2 + 1)

        for _, button in pairs(LDI.objects) do
            self:SkinButton(button)
        end
    end

end

function Module:SkinButton(button, forceUpdate)
    if not button or (button.lt4Skinned and not forceUpdate) then return end

    -- Apply size
    local size = LT4.db.profile.minimap.iconSize or 20
    button:SetSize(size, size)

    -- Make it square
    if button.SetMaskTexture then
        button:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")
    end

    -- Identify the main icon
    local icon = button.icon or button.Icon or _G[button:GetName() .. "Icon"]

    -- Skin all textures
    local regions = {button:GetRegions()}
    for _, region in ipairs(regions) do
        if region:IsObjectType("Texture") then
            if region == icon then
                region:SetTexCoord(0, 1, 0, 1)
                region:SetDrawLayer("ARTWORK")
                region:SetAllPoints(button)
            else
                -- Hide everything else (borders, gloss, etc.)
                region:SetAlpha(0)
                if region.Hide then region:Hide() end
            end
        end
    end

    -- Apply flat backdrop
    if not button.lt4Backdrop then
        button.lt4Backdrop = CreateFrame("Frame", nil, button, "BackdropTemplate")
        button.lt4Backdrop:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
        button.lt4Backdrop:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
        button.lt4Backdrop:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        button.lt4Backdrop:SetBackdropColor(0, 0, 0, 0.5)
        button.lt4Backdrop:SetBackdropBorderColor(0, 0, 0, 1)
        button.lt4Backdrop:SetFrameLevel(button:GetFrameLevel() - 1)
    end

    button.lt4Skinned = true
end
