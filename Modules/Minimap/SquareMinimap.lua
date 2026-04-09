local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local Module = LT4:NewModule("SquareMinimap", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0")

Module.description = "Transforms the circular minimap into a sleek, square design and skins addon icons for a consistent flat look."
Module.requiresReload = true -- Changing the mask is best handled via reload for stability

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
                name = self.description,
                order = 0,
            },
            iconSize = {
                type = "range",
                name = "Icon Size",
                desc = "Adjust the size of the minimap addon icons.",
                min = 16, max = 64, step = 1,
                order = 1,
                get = function() return LT4.db.profile.minimap.iconSize or 20 end,
                set = function(_, val) 
                    LT4.db.profile.minimap.iconSize = val
                    self:UpdateAllIcons()
                end,
            },
        },
    })

    if not LT4:GetModuleEnabled(self:GetName()) then
        self:SetEnabledState(false)
    end
end

function Module:OnEnable()
    -- Initialize defaults if missing
    if LT4.db.profile.minimap.iconSize == nil then
        LT4.db.profile.minimap.iconSize = 20
    end

    self:UpdateMinimap()
    self:SkinAddonIcons()
    
    -- Register events for new icons
    self:RegisterEvent("ADDON_LOADED", "SkinAddonIcons")
    self:ScheduleRepeatingTimer("SkinAddonIcons", 5)
    
    -- Throttled updates (0.05s) as per project mandates
    self:ScheduleRepeatingTimer("ThrottledUpdate", 0.05)
end

function Module:OnDisable()
    -- Most changes require reload to fully revert, which is handled by Core.lua
end

function Module:ThrottledUpdate()
    -- Ensure elements stay positioned correctly
    self:PositionElements()

    -- Update Zone Text Alpha (Hover only)
    local zoneText = MinimapZoneText or (MinimapCluster and MinimapCluster.ZoneTextButton)
    if zoneText then
        if not zoneText.lt4MouseEnabled then
            zoneText:EnableMouse(true)
            zoneText.lt4MouseEnabled = true
        end
        if not zoneText:IsShown() then zoneText:Show() end
        local isOver = MouseIsOver(Minimap) or MouseIsOver(zoneText)
        zoneText:SetAlpha(isOver and 1 or 0)
    end
end

function Module:UpdateAllIcons()
    -- LibDBIcon support
    local LDI = LibStub("LibDBIcon-1.0", true)
    if LDI then
        -- Set radius to half of icon size to make them flush with the outside edge
        local size = LT4.db.profile.minimap.iconSize or 20
        LDI:SetButtonRadius(size / 2)

        for _, button in pairs(LDI.objects) do
            self:SkinButton(button, true)
        end
    end
end

function Module:UpdateMinimap()
    -- Apply square mask
    Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")

    -- Hide Blizzard art (borders, etc.)
    local borderElements = {
        MinimapBackdrop,
        MinimapCluster.BorderTop,
        TimeManagerClockButton,
        GameTimeFrame,
        MinimapCluster.InstanceDifficulty,
    }

    for _, frame in pairs(borderElements) do
        if frame then
            frame:Hide()
            frame:SetAlpha(0)
        end
    end

    -- Position elements
    self:PositionElements()

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

function Module:PositionElements()
    local frames = {
        -- Mail Icon
        { 
            frame = MiniMapMailIcon, 
            point = "TOPLEFT", 
            x = 4, y = -4 
        },
        -- Addon Compartment
        { 
            frame = AddonCompartmentFrame or (MinimapCluster and MinimapCluster.AddonCompartment), 
            point = "TOPRIGHT", 
            x = -4, y = -4 
        },
        -- LFG Eye (Queue Status)
        { 
            frame = QueueStatusButton, 
            point = "BOTTOMLEFT", 
            x = 4, y = 4 
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

function Module:SkinAddonIcons()
    -- LibDBIcon support
    local LDI = LibStub("LibDBIcon-1.0", true)
    if LDI then
        -- Set radius to half of icon size to make them flush with the outside edge
        local size = LT4.db.profile.minimap.iconSize or 20
        LDI:SetButtonRadius(size / 2)

        for _, button in pairs(LDI.objects) do
            self:SkinButton(button)
        end
    end

    -- Find other minimap children that look like buttons
    local children = {Minimap:GetChildren()}
    for _, child in ipairs(children) do
        if child:IsObjectType("Button") and child:IsShown() then
            local name = child:GetName()
            if (name and (name:find("MinimapButton") or name:find("LibDBIcon"))) or child.icon or child.Icon then
                -- self:SkinButton(child)
            end
        end
    end
end

function Module:SkinButton(button, forceUpdate)
    if not button or (button.isLT4Skinned and not forceUpdate) then return end

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

    button.isLT4Skinned = true
end
