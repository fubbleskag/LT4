local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local Module = LT4:NewModule("Cursor", "AceEvent-3.0")

Module.description = "Anchors customizable textures to the mouse cursor."

local TEXTURE_PATH = "Interface\\AddOns\\LT4\\Modules\\Cursor\\Textures\\"

local TEXTURE_LIST = {
    "Circle 1", "Circle 2",
    "Cross 1", "Cross 2", "Cross 3",
    "Glow", "Glow 1", "Glow Reversed",
    "Ring 1", "Ring 2", "Ring 3", "Ring 4",
    "Ring Soft 1", "Ring Soft 2", "Ring Soft 3", "Ring Soft 4",
    "Sphere Edge 2",
    "Star 1",
    "Swirl",
}

local TEXTURE_VALUES = {}
for _, name in ipairs(TEXTURE_LIST) do
    TEXTURE_VALUES[name] = name
end

local BASE_SIZE = 64
local FADE_IDLE_DELAY = 1.5
local FADE_DURATION = 0.5

local db
local frames = {}

local function RefreshDB()
    db = LT4.db.profile.cursor
end

local function GetCursorUIPosition()
    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    return x / scale, y / scale
end

local function ApplyStaticConfig(index)
    local frame = frames[index]
    if not frame then return end
    local cfg = db.cursors[index]

    frame.texture:SetTexture(TEXTURE_PATH .. cfg.texture .. ".tga")
    frame.texture:SetVertexColor(cfg.color.r, cfg.color.g, cfg.color.b, 1)
    local size = BASE_SIZE * cfg.scale
    frame:SetSize(size, size)
end

local function UpdateVisibility(index)
    local frame = frames[index]
    if not frame then return end
    local cfg = db.cursors[index]

    local visible = cfg.enabled and (not cfg.combatOnly or InCombatLockdown())
    if visible then
        frame.lastX, frame.lastY = GetCursorUIPosition()
        frame.lastMove = GetTime()
        frame:Show()
    else
        frame:Hide()
    end
end

local function CreateCursorFrame(index)
    local frame = CreateFrame("Frame", "LT4CursorFrame" .. index, UIParent)
    frame:SetFrameStrata("TOOLTIP")
    frame:SetSize(BASE_SIZE, BASE_SIZE)
    frame:SetMouseClickEnabled(false)
    frame:SetMouseMotionEnabled(false)

    local tex = frame:CreateTexture(nil, "OVERLAY")
    tex:SetAllPoints()
    frame.texture = tex

    frame.lastX, frame.lastY, frame.lastMove = 0, 0, 0

    frame:SetScript("OnUpdate", function(self)
        local cfg = db.cursors[index]
        local x, y = GetCursorUIPosition()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)

        local alpha = cfg.opacity
        if cfg.fadeIdle then
            if x ~= self.lastX or y ~= self.lastY then
                self.lastX, self.lastY = x, y
                self.lastMove = GetTime()
            else
                local idle = GetTime() - self.lastMove
                if idle > FADE_IDLE_DELAY then
                    local fade = 1 - math.min(1, (idle - FADE_IDLE_DELAY) / FADE_DURATION)
                    alpha = alpha * fade
                end
            end
        end
        self.texture:SetVertexColor(cfg.color.r, cfg.color.g, cfg.color.b, alpha)
    end)

    frames[index] = frame
    return frame
end

local function RefreshCursor(index)
    if not frames[index] then return end
    ApplyStaticConfig(index)
    UpdateVisibility(index)
end

local function RefreshAll()
    for i = 1, 2 do
        RefreshCursor(i)
    end
end

local function BuildCursorOptions(index, defaultOrder)
    return {
        type = "group",
        name = "Cursor " .. index,
        inline = true,
        order = defaultOrder,
        args = {
            enabled = {
                type = "toggle",
                name = "Enable",
                order = 1,
                get = function() return db.cursors[index].enabled end,
                set = function(_, val)
                    db.cursors[index].enabled = val
                    RefreshCursor(index)
                end,
            },
            texture = {
                type = "select",
                name = "Texture",
                order = 2,
                values = TEXTURE_VALUES,
                sorting = TEXTURE_LIST,
                disabled = function() return not db.cursors[index].enabled end,
                get = function() return db.cursors[index].texture end,
                set = function(_, val)
                    db.cursors[index].texture = val
                    RefreshCursor(index)
                end,
            },
            color = {
                type = "color",
                name = "Color",
                order = 3,
                hasAlpha = false,
                disabled = function() return not db.cursors[index].enabled end,
                get = function()
                    local c = db.cursors[index].color
                    return c.r, c.g, c.b
                end,
                set = function(_, r, g, b)
                    local c = db.cursors[index].color
                    c.r, c.g, c.b = r, g, b
                    RefreshCursor(index)
                end,
            },
            scale = {
                type = "range",
                name = "Scale",
                order = 4,
                min = 0.1, max = 2, step = 0.05,
                isPercent = true,
                disabled = function() return not db.cursors[index].enabled end,
                get = function() return db.cursors[index].scale end,
                set = function(_, val)
                    db.cursors[index].scale = val
                    RefreshCursor(index)
                end,
            },
            opacity = {
                type = "range",
                name = "Opacity",
                order = 5,
                min = 0, max = 1, step = 0.05,
                isPercent = true,
                disabled = function() return not db.cursors[index].enabled end,
                get = function() return db.cursors[index].opacity end,
                set = function(_, val)
                    db.cursors[index].opacity = val
                    RefreshCursor(index)
                end,
            },
            fadeIdle = {
                type = "toggle",
                name = "Fade when idle",
                order = 6,
                disabled = function() return not db.cursors[index].enabled end,
                get = function() return db.cursors[index].fadeIdle end,
                set = function(_, val)
                    db.cursors[index].fadeIdle = val
                    RefreshCursor(index)
                end,
            },
            combatOnly = {
                type = "toggle",
                name = "Show only in combat",
                order = 7,
                disabled = function() return not db.cursors[index].enabled end,
                get = function() return db.cursors[index].combatOnly end,
                set = function(_, val)
                    db.cursors[index].combatOnly = val
                    RefreshCursor(index)
                end,
            },
        },
    }
end

function Module:OnInitialize()
    RefreshDB()
    LT4.db.RegisterCallback(self, "OnProfileChanged", function()
        RefreshDB()
        RefreshAll()
    end)
    LT4.db.RegisterCallback(self, "OnProfileCopied", function()
        RefreshDB()
        RefreshAll()
    end)
    LT4.db.RegisterCallback(self, "OnProfileReset", function()
        RefreshDB()
        RefreshAll()
    end)

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
            cursor1 = BuildCursorOptions(1, 1),
            cursor2 = BuildCursorOptions(2, 2),
        },
    })

    if not LT4:GetModuleEnabled(self:GetName()) then
        self:SetEnabledState(false)
    end
end

function Module:OnEnable()
    for i = 1, 2 do
        if not frames[i] then CreateCursorFrame(i) end
        RefreshCursor(i)
    end
    self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnCombatChanged")
    self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnCombatChanged")
end

function Module:OnDisable()
    self:UnregisterEvent("PLAYER_REGEN_DISABLED")
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    for _, frame in pairs(frames) do
        frame:Hide()
    end
end

function Module:OnCombatChanged()
    for i = 1, 2 do
        UpdateVisibility(i)
    end
end
