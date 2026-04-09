local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
local Utils = LumiBar.Utils

local SystemModule = {}
LumiBar:RegisterModule("System", SystemModule)

-- Performance: Cache common lookups
local GetFramerate = GetFramerate
local GetNetStats = GetNetStats
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage
local GetAddOnMemoryUsage = GetAddOnMemoryUsage
local C_AddOns = C_AddOns
local C_AddOnProfiler = C_AddOnProfiler
local math_floor = math.floor
local string_format = string.format
local table_concat = table.concat
local table_insert = table.insert
local GetTime = GetTime

function SystemModule:Init()
    self.db = LumiBar.db.profile.modules.System

    local options = {
        name = "System",
        type = "group",
        get = function(info) return self.db[info[#info]] end,
        set = function(info, value) 
            self.db[info[#info]] = value
            self:Refresh()
        end,
        args = {
            displayGroup = {
                name = "Display Elements",
                type = "group",
                inline = true,
                order = 1,
                args = {
                    showFPS = { name = "Show FPS", type = "toggle", width = "full", order = 1 },
                    showMS = { name = "Show Latency (ms)", type = "toggle", width = "full", order = 2 },
                    showMEM = { name = "Show Memory (MB)", type = "toggle", width = "full", order = 3 },
                    showCPU = { name = "Show CPU (%)", type = "toggle", width = "full", order = 4 },
                }
            },
        }
    }
    LumiBar:RegisterModuleOptions("System", options)
end

-- Optimization: Throttle memory updates (expensive)
local lastMemUpdate = 0
local cachedMem = 0
function SystemModule:GetMemoryUsage(force)
    local now = GetTime()
    if force or (now - lastMemUpdate > 30) then
        UpdateAddOnMemoryUsage()
        local total = 0
        for i = 1, C_AddOns.GetNumAddOns() do
            total = total + GetAddOnMemoryUsage(i)
        end
        cachedMem = total / 1024
        lastMemUpdate = now
    end
    return cachedMem
end

function SystemModule:GetCPUUsage()
    if C_AddOnProfiler and C_AddOnProfiler.IsEnabled() then
        -- Recent Average CPU % (Index 1)
        return math_floor((C_AddOnProfiler.GetApplicationMetric(1) or 0) + 0.5)
    end
    return 0
end

function SystemModule:UpdateStatus()
    if not self.text then return end
    
    local fps = math_floor(GetFramerate())
    local _, _, latencyHome, _ = GetNetStats()
    local mem = self:GetMemoryUsage()
    local cpu = self:GetCPUUsage()
    
    local accent = Utils:GetAccentColorHex()
    local parts = {}
    
    if self.db.showFPS then
        table_insert(parts, string_format("%d|cff%s%s|r", fps, accent, "fps"))
    end
    
    if self.db.showMS then
        table_insert(parts, string_format("%d|cff%s%s|r", latencyHome, accent, "ms"))
    end
    
    if self.db.showMEM then
        table_insert(parts, string_format("%d|cff%s%s|r", math_floor(mem), accent, "mb"))
    end
    
    if self.db.showCPU then
        table_insert(parts, string_format("%d|cff%s%%|r", cpu, accent))
    end
    
    self.text:SetText(table_concat(parts, "  "))
    self:UpdateWidth()
end

function SystemModule:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.System
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, slotFrame, "BackdropTemplate")
        self.text = self.frame:CreateFontString(nil, "OVERLAY")
        
        self.timeSinceLastUpdate = 0
        self.frame:SetScript("OnUpdate", function(f, elapsed)
            self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
            if self.timeSinceLastUpdate >= 1 then
                self:UpdateStatus()
                self.timeSinceLastUpdate = 0
            end
        end)
        
        self.frame:SetScript("OnEnter", function(f)
            local fps = math_floor(GetFramerate())
            local _, _, latencyHome, latencyWorld = GetNetStats()
            -- Force memory update on hover for accuracy
            local mem = self:GetMemoryUsage(true)
            
            local cpuSession = C_AddOnProfiler and C_AddOnProfiler.GetApplicationMetric(0) or 0
            local cpuRecent = C_AddOnProfiler and C_AddOnProfiler.GetApplicationMetric(1) or 0
            
            local anchor = (LumiBar.db.profile.bar.position == "BOTTOM") and "ANCHOR_TOP" or "ANCHOR_BOTTOM"
            GameTooltip:SetOwner(f, anchor)
            GameTooltip:ClearLines()
            local r, g, b = Utils:GetAccentColor()
            GameTooltip:AddLine("System Performance", r, g, b)
            
            GameTooltip:AddDoubleLine("Framerate:", fps .. " fps", 1, 1, 1, 1, 1, 1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("Latency (Home):", latencyHome .. " ms", 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine("Latency (World):", latencyWorld .. " ms", 1, 1, 1, 1, 1, 1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("Total Memory:", string_format("%.2f MB", mem), 1, 1, 1, 1, 1, 1)
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("CPU (Recent):", string_format("%.2f%%", cpuRecent), 1, 1, 1, 1, 1, 1)
            GameTooltip:AddDoubleLine("CPU (Session):", string_format("%.2f%%", cpuSession), 1, 1, 1, 1, 1, 1)
            
            GameTooltip:Show()
        end)
        self.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    
    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:Show()
    self:Refresh(slotFrame)
    self:UpdateStatus()
end

function SystemModule:UpdateWidth()
    if not self.text then return end
    Utils:UpdateModuleWidth(self, self.text:GetStringWidth() + 16, function() self:UpdateWidth() end)
end

function SystemModule:Refresh(slotFrame)
    if not self.text then return end
    slotFrame = slotFrame or self.frame:GetParent()
    if not slotFrame then return end
    
    self.frame:SetHeight(slotFrame:GetHeight())
    Utils:SetFont(self.text)
    Utils:ApplyBackground(self.frame, self.db)
    
    local align = slotFrame.align or "CENTER"
    self.text:ClearAllPoints()
    self.text:SetPoint(align, self.frame, align, 0, 0)
    
    self:UpdateStatus()
end
