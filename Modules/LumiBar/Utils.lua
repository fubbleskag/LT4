local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")

LumiBar.Utils = {}
local Utils = LumiBar.Utils

local LSM = LibStub("LibSharedMedia-3.0")

-- Performance: Cache common lookups
local string_format = string.format
local string_len = string.len
local string_sub = string.sub
local math_floor = math.floor
local math_abs = math.abs
local type = type
local ipairs = ipairs
local pairs = pairs
local UnitClass = UnitClass
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local C_Timer = C_Timer

-- Color Helpers
--- Get the player's class color.
-- @return r, g, b (0-1)
function Utils:GetClassColor()
    local _, class = UnitClass("player")
    local color = RAID_CLASS_COLORS[class]
    return color.r, color.g, color.b
end

--- Get the current accent color from settings.
-- @return r, g, b, a (0-1)
function Utils:GetAccentColor()
    local c = LumiBar.db.profile.general.accentColor
    return c.r, c.g, c.b, c.a
end

--- Convert RGB values to a Hex string.
-- @param r, g, b (0-1)
-- @return Hex string (e.g. "ffffff")
function Utils:RGBToHex(r, g, b)
    return string_format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

--- Get the current accent color as a Hex string.
-- @return Hex string
function Utils:GetAccentColorHex()
    local r, g, b = self:GetAccentColor()
    return self:RGBToHex(r, g, b)
end

-- Font & Text Helpers

--- Set the font and color for a FontString.
-- @param fs The FontString object.
-- @param size (Optional) Font size.
-- @param outline (Optional) Font outline.
-- @param colorType (Optional) "CLASS", "ACCENT", "WHITE", or nil for default.
function Utils:SetFont(fs, size, outline, colorType)
    if not fs then return end
    local db = LumiBar.db.profile.general.font
    local fontFace = LSM:Fetch("font", db.face) or STANDARD_TEXT_FONT
    local fontSize = size or db.size or 12
    local fontOutline = outline or db.outline or "OUTLINE"
    
    fs:SetFont(fontFace, fontSize, fontOutline)
    
    if colorType == "CLASS" then
        fs:SetTextColor(self:GetClassColor())
    elseif colorType == "ACCENT" then
        fs:SetTextColor(self:GetAccentColor())
    elseif colorType == "WHITE" then
        fs:SetTextColor(1, 1, 1, 1)
    else
        local c = db.color
        fs:SetTextColor(c.r, c.g, c.b, c.a)
    end
end

-- Number Formatting

--- Format a large number with 'k' or 'm' suffixes.
-- @param n The number to format.
-- @return Formatted string.
function Utils:FormatNumber(n)
    if not n then return "0" end
    if n >= 1e6 then
        return string_format("%.1fm", n / 1e6)
    elseif n >= 1e3 then
        return string_format("%.1fk", n / 1e3)
    else
        return tostring(math_floor(n))
    end
end

--- Format a money amount (copper) into a colored gold/silver/copper string.
-- @param amount Amount in copper.
-- @return Formatted string.
function Utils:FormatMoney(amount)
    local gold = math_floor(math_abs(amount) / 10000)
    local silver = math_floor((math_abs(amount) / 100) % 100)
    local copper = math_floor(math_abs(amount) % 100)
    
    local str = ""
    if gold > 0 then str = str .. gold .. "|cffffd700g|r " end
    if silver > 0 or gold > 0 then str = str .. silver .. "|cffc7c7c7s|r " end
    str = str .. copper .. "|cffeda55fc|r"
    
    return str
end

-- Background Helper

--- Apply a background texture and color to a frame.
-- @param frame The frame object.
-- @param moduleDB (Optional) Module-specific background settings.
function Utils:ApplyBackground(frame, moduleDB)
    if not frame or not frame.SetBackdrop then return end
    
    local db = moduleDB and moduleDB.background or nil
    local barDB = LumiBar.db.profile.bar
    
    -- If module background is disabled, hide it and return
    if db and not db.enabled then
        frame:SetBackdropColor(0, 0, 0, 0)
        return
    end

    local texture = (db and db.texture) or barDB.backgroundTexture
    local color = (db and db.color) or barDB.backgroundColor
    
    local bgFile = LSM:Fetch("statusbar", texture) or "Interface\\Buttons\\WHITE8X8"
    
    if not frame.backdrop then
        frame:SetBackdrop({
            bgFile = bgFile,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        frame.backdrop = true
    else
        local backdrop = frame:GetBackdrop()
        if backdrop then
            backdrop.bgFile = bgFile
            frame:SetBackdrop(backdrop)
        end
    end
    
    if not db and barDB.useClassColor then
        local r, g, b = self:GetClassColor()
        frame:SetBackdropColor(r, g, b, color.a)
    else
        frame:SetBackdropColor(color.r, color.g, color.b, color.a)
    end
end

-- Tooltip Helper
function Utils:SetTooltip(frame, title, lines)
    frame:SetScript("OnEnter", function(self)
        local position = LumiBar.db.profile.bar.position or "BOTTOM"
        local anchor = (position == "BOTTOM") and "ANCHOR_TOP" or "ANCHOR_BOTTOM"
        GameTooltip:SetOwner(self, anchor)
        GameTooltip:ClearLines()
        
        local currentTitle = (type(title) == "function") and title(self) or title
        if currentTitle then
            local r, g, b = Utils:GetAccentColor()
            GameTooltip:AddLine(currentTitle, r, g, b)
        end
        
        local currentLines = (type(lines) == "function") and lines(self) or lines
        if currentLines then
            for _, line in ipairs(currentLines) do
                if type(line) == "table" then
                    GameTooltip:AddDoubleLine(line[1], line[2], 1, 1, 1, 1, 1, 1)
                else
                    GameTooltip:AddLine(line, 1, 1, 1, true)
                end
            end
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- Common Refresh Preamble
--- Handles the shared boilerplate at the start of most module Refresh() calls.
-- Sets frame height, applies font to self.text, applies background, and aligns text.
-- @param module The module table (must have .frame, .text, .db).
-- @param slotFrame (Optional) The parent slot frame.
-- @return slotFrame, align — or nil if the refresh should abort.
function Utils:RefreshBase(module, slotFrame)
    if not module.text then return nil end
    slotFrame = slotFrame or module.frame:GetParent()
    if not slotFrame then return nil end
    local align = slotFrame.align or "CENTER"

    module.frame:SetHeight(slotFrame:GetHeight())
    self:SetFont(module.text)
    self:ApplyBackground(module.frame, module.db)

    module.text:ClearAllPoints()
    module.text:SetPoint(align, module.frame, align, 0, 0)

    return slotFrame, align
end

-- Shorten string
function Utils:ShortenString(str, limit)
    if not str then return "" end
    if string_len(str) > limit then
        return string_sub(str, 1, limit) .. ".."
    end
    return str
end

-- Update Module Width Helper
function Utils:UpdateModuleWidth(module, width, retryFunc)
    if not module or not module.frame then return end
    
    -- Retry if width is 0 (engine lag) but text is supposedly there
    if width == 0 then
        -- Check if there's any fontstring that might have content
        local hasText = false
        for _, obj in pairs(module) do
            if type(obj) == "table" and obj.GetText and obj:GetText() and obj:GetText() ~= "" then
                hasText = true
                break
            end
        end
        
        if hasText and retryFunc then
            C_Timer.After(0.1, retryFunc)
            return
        end
    end

    -- Block all layout changes in combat to prevent protected frame errors
    if InCombatLockdown() then
        LumiBar.needsRefresh = true
        LumiBar:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    module.frame:SetWidth(width)
    
    local zoneFrame = module.frame:GetParent()
    if zoneFrame and zoneFrame.GetName then
        local zName = zoneFrame:GetName():gsub("LT4_LumiBarZone", "")
        local validZones = { FarLeft = true, NearLeft = true, Center = true, NearRight = true, FarRight = true }
        if validZones[zName] then
            LumiBar:UpdateLayout()
        end
    end
end
