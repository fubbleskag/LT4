local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
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
            localTime = {
                name = "Local Time",
                desc = "Display local time instead of server time.",
                type = "toggle",
                order = 1,
            },
            twentyFour = {
                name = "24 Hour Format",
                desc = "Display time in 24-hour format.",
                type = "toggle",
                order = 2,
            },
            timeFormat = {
                name = "Time Format",
                type = "select",
                values = { ["HH:MM"] = "HH:MM", ["H:MM"] = "H:MM", ["HH:M"] = "HH:M" },
                order = 3,
            },
            showRestingAnimation = {
                name = "Resting Animation",
                desc = "Show a resting icon when in a rested area.",
                type = "toggle",
                order = 4,
            },
            useAccent = {
                name = "Use Accent Color",
                desc = "Use the accent color for the colon.",
                type = "toggle",
                order = 5,
            },
            infoEnabled = {
                name = "Enable Info Text",
                desc = "Display additional info (like date) above/below the time.",
                type = "toggle",
                order = 6,
            },
            infoOffset = {
                name = "Info Y Offset",
                type = "range",
                min = -50, max = 50, step = 1,
                order = 7,
            },
        }
    }
    LumiBar:RegisterModuleOptions("Time", options)
end

function TimeModule:GetTime()
    local hour, minute
    if self.db.localTime then
        hour, minute = tonumber(date("%H")), tonumber(date("%M"))
    else
        hour, minute = GetGameTime()
    end
    
    local h = hour
    if not self.db.twentyFour then
        if h == 0 then h = 12
        elseif h > 12 then h = h - 12 end
    end
    
    local hStr, mStr
    if self.db.timeFormat == "HH:MM" then
        hStr = string.format("%02d", h)
        mStr = string.format("%02d", minute)
    elseif self.db.timeFormat == "H:MM" then
        hStr = string.format("%d", h)
        mStr = string.format("%02d", minute)
    elseif self.db.timeFormat == "HH:M" then
        hStr = string.format("%02d", h)
        mStr = string.format("%d", minute)
    else
        hStr = string.format("%d", h)
        mStr = string.format("%d", minute)
    end
    
    return hStr, mStr
end

function TimeModule:UpdateInfoText()
    if not self.db.infoEnabled or not self.colon then
        if self.infoText then self.infoText:Hide() end
        return
    end
    
    if not self.infoText then
        self.infoText = self.frame:CreateFontString(nil, "OVERLAY")
    end
    
    Utils:SetFont(self.infoText, self.db.infoFontSize or 10, "OUTLINE", self.db.infoUseAccent and "ACCENT" or nil)
    
    local dateTime = date("*t")
    self.infoText:SetText(string.format("%02d/%02d", dateTime.day, dateTime.month))
    
    self.infoText:ClearAllPoints()
    local yOffset = self.db.infoOffset or 15
    if LumiBar.db.profile.bar.position == "TOP" then
        self.infoText:SetPoint("TOP", self.colon, "BOTTOM", 0, -yOffset)
    else
        self.infoText:SetPoint("BOTTOM", self.colon, "TOP", 0, yOffset)
    end
    
    self.infoText:Show()
end

function TimeModule:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.Time
    
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, slotFrame, "BackdropTemplate")
        
        self.hour = self.frame:CreateFontString(nil, "OVERLAY")
        self.colon = self.frame:CreateFontString(nil, "OVERLAY")
        self.minutes = self.frame:CreateFontString(nil, "OVERLAY")
        
        self.resting = self.frame:CreateTexture(nil, "OVERLAY")
        self.resting:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
        self.resting:SetTexCoord(0, 0.5, 0, 0.421875)
        self.resting:SetSize(16, 16)
        
        self.timeSinceLastUpdate = 0
        self.frame:SetScript("OnUpdate", function(f, elapsed)
            self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
            if self.timeSinceLastUpdate >= 1 then
                local h, m = self:GetTime()
                self.hour:SetText(h)
                self.minutes:SetText(m)
                
                if self.db.showRestingAnimation and IsResting() then
                    self.resting:Show()
                else
                    self.resting:Hide()
                end
                
                self:UpdateInfoText()
                self:UpdateWidth()
                self.timeSinceLastUpdate = 0
            end
        end)
    end
    
    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:Show()
    self:Refresh(slotFrame) -- Refresh sets fonts
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
    local rW = (self.db.showRestingAnimation and IsResting()) and 20 or 0
    
    Utils:UpdateModuleWidth(self, hW + cW + mW + rW + 16, function() self:UpdateWidth() end)
end

function TimeModule:Refresh(slotFrame)
    if not self.hour then return end
    slotFrame = slotFrame or self.frame:GetParent()
    if not slotFrame then return end
    local align = slotFrame.align or "CENTER"
    
    self.frame:SetHeight(slotFrame:GetHeight())
    
    Utils:SetFont(self.hour)
    Utils:SetFont(self.colon, nil, nil, self.db.useAccent and "ACCENT" or nil)
    Utils:SetFont(self.minutes)
    
    self.colon:SetText(":")
    Utils:ApplyBackground(self.frame, self.db)
    
    -- Calculate and Set Width
    local hW = self.hour:GetStringWidth()
    local cW = self.colon:GetStringWidth()
    local mW = self.minutes:GetStringWidth()
    local rW = (self.db.showRestingAnimation and IsResting()) and 20 or 0
    self.frame:SetWidth(hW + cW + mW + rW + 12)
    
    self.colon:ClearAllPoints()
    self.colon:SetPoint(align, self.frame, align, 0, self.db.textOffset or 0)
    
    self.hour:ClearAllPoints()
    self.hour:SetPoint("RIGHT", self.colon, "LEFT", -2, 0)
    
    self.minutes:ClearAllPoints()
    self.minutes:SetPoint("LEFT", self.colon, "RIGHT", 2, 0)
    
    self.resting:ClearAllPoints()
    self.resting:SetPoint("LEFT", self.minutes, "RIGHT", 4, 0)
    
    local sHour, sMinute = GetGameTime()
    local lines = {
        {"Server Time:", string.format("%02d:%02d", sHour, sMinute)},
        {"Local Time:", date("%H:%M")},
        "",
        "|cffFFFFFFLeft Click:|r Toggle Calendar",
        "|cffFFFFFFMiddle Click:|r Reload UI"
    }
    Utils:SetTooltip(self.frame, "Time", lines)
    
    self.frame:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            if ToggleCalendar then ToggleCalendar() end
        elseif button == "MiddleButton" then
            ReloadUI()
        end
    end)
end
