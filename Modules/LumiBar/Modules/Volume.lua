local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
local Utils = LumiBar.Utils

local Volume = {}
LumiBar:RegisterModule("Volume", Volume)

-- Caches
local math_floor = math.floor
local tonumber = tonumber
local GetCVar = GetCVar
local SetCVar = SetCVar
local CreateFrame = CreateFrame
local string_format = string.format

function Volume:Init()
    self.db = LumiBar.db.profile.modules.Volume
    
    local options = {
        name = "Volume",
        type = "group",
        get = function(info) return self.db[info[#info]] end,
        set = function(info, value) 
            self.db[info[#info]] = value
            self:Refresh()
            self.lastVol, self.lastMuted, self.lastBG = nil, nil, nil -- Force update
            self:UpdateStatus()
        end,
        args = {
            textColor = {
                name = "Volume Color Mode",
                desc = "Color of the volume % when not muted.",
                type = "select",
                width = "full",
                values = { ["NONE"] = "None", ["GREEN"] = "Green", ["ACCENT"] = "Accent" },
                order = 1,
            },
        }
    }
    LumiBar:RegisterModuleOptions("Volume", options)
end

-- Pre-defined colors
local RED_HEX = "ff4444"
local GREEN_HEX = "00ff00"

function Volume:UpdateStatus()
    if not self.text then return end
    
    local masterVolRaw = GetCVar("Sound_MasterVolume")
    local vol = math_floor(tonumber(masterVolRaw) * 100)
    local isMuted = masterVolRaw == "0"
    local bgEnabled = GetCVar("Sound_EnableSoundWhenGameIsInBG") == "1"
    
    -- Optimization: Only update if state changed
    if vol == self.lastVol and isMuted == self.lastMuted and bgEnabled == self.lastBG then
        return
    end
    
    self.lastVol, self.lastMuted, self.lastBG = vol, isMuted, bgEnabled
    
    -- Master Volume Part
    local volText
    local color = "ffffff"
    if isMuted then
        color = RED_HEX
    elseif self.db.textColor == "GREEN" then
        color = GREEN_HEX
    elseif self.db.textColor == "ACCENT" then
        color = Utils:GetAccentColorHex()
    end
    volText = string_format("|cff%s%d%%|r", color, vol)
    
    -- Background Sound Part
    local bgText = bgEnabled and "[BG]" or string_format("|cff%s[BG]|r", RED_HEX)
    
    self.text:SetText(string_format("%s  %s", volText, bgText))
    self:UpdateWidth()
end

function Volume:UpdateWidth()
    if not self.text then return end
    Utils:UpdateModuleWidth(self, self.text:GetStringWidth() + 16, function() self:UpdateWidth() end)
end

function Volume:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.Volume
    
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, slotFrame, "BackdropTemplate")
        self.text = self.frame:CreateFontString(nil, "OVERLAY")
        
        self.frame:EnableMouseWheel(true)
        self.frame:SetScript("OnMouseWheel", function(_, delta)
            local vol = tonumber(GetCVar("Sound_MasterVolume"))
            vol = delta > 0 and math.min(vol + 0.05, 1) or math.max(vol - 0.05, 0)
            SetCVar("Sound_MasterVolume", vol)
            self:UpdateStatus()
        end)
        
        self.frame:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then
                local vol = tonumber(GetCVar("Sound_MasterVolume"))
                if vol > 0 then
                    self.oldVol = vol
                    SetCVar("Sound_MasterVolume", 0)
                else
                    SetCVar("Sound_MasterVolume", self.oldVol or 0.5)
                end
            elseif button == "RightButton" then
                SetCVar("Sound_EnableSoundWhenGameIsInBG", GetCVar("Sound_EnableSoundWhenGameIsInBG") == "1" and "0" or "1")
            end
            self:UpdateStatus()
        end)
        
        self.frame:RegisterEvent("CVAR_UPDATE")
        self.frame:SetScript("OnEvent", function(_, _, name)
            if name == "Sound_MasterVolume" or name == "Sound_EnableSoundWhenGameIsInBG" then
                self:UpdateStatus()
            end
        end)
    end
    
    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:Show()
    self:Refresh(slotFrame)
    self:UpdateStatus()
end

function Volume:Refresh(slotFrame)
    if not Utils:RefreshBase(self, slotFrame) then return end

    Utils:SetTooltip(self.frame, "Volume Control", {
        "|cffFFFFFFScroll:|r Adjust Volume",
        "|cffFFFFFFLeft Click:|r Toggle Mute",
        "|cffFFFFFFRight Click:|r Toggle BG Sound"
    })
    
    self.lastVol, self.lastMuted, self.lastBG = nil, nil, nil -- Force update
    self:UpdateStatus()
end
