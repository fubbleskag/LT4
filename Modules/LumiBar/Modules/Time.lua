local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
local LSM = LibStub("LibSharedMedia-3.0")
local Utils = LumiBar.Utils

local TimeModule = {}
LumiBar:RegisterModule("Time", TimeModule)

function TimeModule:Init()
    self.db = LumiBar.db.profile.modules.Time

    local options = {
        name = "Time",
        type = "group",
        get = function(info) return self.db[info[#info]] end,
        set = function(info, value)
            self.db[info[#info]] = value
            self:Refresh()
        end,
        args = {
            timeFormat = {
                name = "Time Format",
                desc = "Choose between 12-hour and 24-hour format.",
                type = "select",
                values = { ["12"] = "12 Hour", ["24"] = "24 Hour" },
                order = 1,
            },
            colorType = {
                name = "Color",
                desc = "Color used for the time display.",
                type = "select",
                values = { ["PRIMARY"] = "Primary", ["ACCENT"] = "Accent" },
                order = 2,
            },
            overrideFontFace = {
                name = "Override Font Face",
                desc = "Use a custom font face instead of the LumiBar default.",
                type = "toggle",
                order = 3,
            },
            fontFace = {
                name = "Font Face",
                type = "select",
                dialogControl = LSM and "LSM30_Font" or nil,
                values = LSM and LSM:HashTable("font") or { ["Arial Narrow"] = "Arial Narrow" },
                disabled = function() return not self.db.overrideFontFace end,
                order = 4,
            },
            overrideFontSize = {
                name = "Override Font Size",
                desc = "Use a custom font size instead of the LumiBar default.",
                type = "toggle",
                order = 5,
            },
            fontSize = {
                name = "Font Size",
                type = "range",
                min = 6, max = 32, step = 1,
                disabled = function() return not self.db.overrideFontSize end,
                order = 6,
            },
        }
    }
    LumiBar:RegisterModuleOptions("Time", options)
end

function TimeModule:GetTime()
    local hour, minute = tonumber(date("%H")), tonumber(date("%M"))

    local h = hour
    if self.db.timeFormat ~= "24" then
        if h == 0 then h = 12
        elseif h > 12 then h = h - 12 end
    end

    local hStr, mStr
    if self.db.timeFormat == "24" then
        hStr = string.format("%02d", h)
    else
        hStr = string.format("%d", h)
    end
    mStr = string.format("%02d", minute)

    return hStr, mStr
end

function TimeModule:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.Time

    if not self.frame then
        self.frame = CreateFrame("Frame", nil, slotFrame, "BackdropTemplate")

        self.hour = self.frame:CreateFontString(nil, "OVERLAY")
        self.colon = self.frame:CreateFontString(nil, "OVERLAY")
        self.minutes = self.frame:CreateFontString(nil, "OVERLAY")

        self.timeSinceLastUpdate = 0
        self.frame:SetScript("OnUpdate", function(f, elapsed)
            self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
            if self.timeSinceLastUpdate >= 1 then
                local h, m = self:GetTime()
                self.hour:SetText(h)
                self.minutes:SetText(m)

                self:UpdateWidth()
                self.timeSinceLastUpdate = 0
            end
        end)
    end

    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:Show()
    self:Refresh(slotFrame)
    self:UpdateStatus()
end

function TimeModule:UpdateStatus()
    local h, m = self:GetTime()
    if self.hour then self.hour:SetText(h) end
    if self.minutes then self.minutes:SetText(m) end
end

function TimeModule:UpdateWidth()
    if not self.hour then return end
    local hW = self.hour:GetStringWidth()
    local cW = self.colon:GetStringWidth()
    local mW = self.minutes:GetStringWidth()

    Utils:UpdateModuleWidth(self, hW + cW + mW + 16, function() self:UpdateWidth() end)
end

function TimeModule:Refresh(slotFrame)
    if not self.hour then return end
    slotFrame = slotFrame or self.frame:GetParent()
    if not slotFrame then return end
    local align = slotFrame.align or "CENTER"

    self.frame:SetHeight(slotFrame:GetHeight())

    local size = self.db.overrideFontSize and self.db.fontSize or nil
    local color = self.db.colorType == "ACCENT" and "ACCENT" or nil
    Utils:SetFont(self.hour, size, nil, color)
    Utils:SetFont(self.colon, size, nil, color)
    Utils:SetFont(self.minutes, size, nil, color)

    if self.db.overrideFontFace and self.db.fontFace then
        local face = LSM:Fetch("font", self.db.fontFace) or STANDARD_TEXT_FONT
        for _, fs in ipairs({ self.hour, self.colon, self.minutes }) do
            local _, curSize, curFlags = fs:GetFont()
            fs:SetFont(face, curSize, curFlags)
        end
    end

    self.colon:SetText(":")
    Utils:ApplyBackground(self.frame, self.db)

    -- Calculate and Set Width
    local hW = self.hour:GetStringWidth()
    local cW = self.colon:GetStringWidth()
    local mW = self.minutes:GetStringWidth()
    self.frame:SetWidth(hW + cW + mW + 12)

    self.colon:ClearAllPoints()
    self.colon:SetPoint(align, self.frame, align, 0, self.db.textOffset or 0)

    self.hour:ClearAllPoints()
    self.hour:SetPoint("RIGHT", self.colon, "LEFT", -2, 0)

    self.minutes:ClearAllPoints()
    self.minutes:SetPoint("LEFT", self.colon, "RIGHT", 2, 0)

    Utils:SetTooltip(self.frame, "Time", function()
        local sHour, sMinute = GetGameTime()
        return {
            {"Server Time:", string.format("%02d:%02d", sHour, sMinute)},
            {"Local Time:", date("%H:%M")},
            "",
            "|cffFFFFFFLeft Click:|r Toggle Calendar",
            "|cffFFFFFFMiddle Click:|r Reload UI"
        }
    end)

    self.frame:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            if ToggleCalendar then ToggleCalendar() end
        elseif button == "MiddleButton" then
            ReloadUI()
        end
    end)
end
