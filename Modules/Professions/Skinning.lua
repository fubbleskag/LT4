local FQoL = LibStub("AceAddon-3.0"):GetAddon("FQoL")
local Module = FQoL:GetModule("Professions")

Module.skinningQuestData = {
    { id = 88545, name = "Gloomclaw", zone = "Eversong", mapID = 2395, x = 41.95, y = 80.05 },
    { id = 88526, name = "Silverscale", zone = "Zul'Aman", mapID = 2437, x = 47.69, y = 53.25 },
    { id = 88531, name = "Lumenfin", zone = "Harandar", mapID = 2413, x = 66.28, y = 47.91 },
    { id = 88532, name = "Umbrafang", zone = "Voidstorm", mapID = 2405, x = 54.60, y = 65.80 },
    { id = 88524, name = "Netherscythe", zone = "Voidstorm", mapID = 2405, x = 43.25, y = 82.75, emphasize = true },
}

local function HasSkinning()
    local prof1, prof2 = GetProfessions()
    for _, index in pairs({prof1, prof2}) do
        if index then
            local _, _, _, _, _, _, skillLine = GetProfessionInfo(index)
            if skillLine == 393 then return true end
        end
    end
    return false
end

function Module:InitSkinning()
    if not HasSkinning() then return end

    local p = FQoL.db.profile
    if p.skinningEnabled == nil then p.skinningEnabled = true end
    if p.skinningTrackerUI == nil then p.skinningTrackerUI = true end
    if p.skinningTrackerCollapsed == nil then p.skinningTrackerCollapsed = false end
    if p.skinningTrackerPosition == nil then p.skinningTrackerPosition = {} end

    local options = FQoL.options.args.modules.args["Professions"].args
    options.skinningHeader = { type = "header", name = "Skinning", order = 10 }
    options.skinningEnabled = {
        type = "toggle", name = "Enable Skinning Utilities", order = 11,
        get = function() return FQoL.db.profile.skinningEnabled end,
        set = function(_, val) 
            FQoL.db.profile.skinningEnabled = val 
            if self.UpdateSkinningTracker then self:UpdateSkinningTracker() end
        end,
    }
    options.skinningTrackerUI = {
        type = "toggle", name = "Show Tracker UI", order = 12,
        get = function() return FQoL.db.profile.skinningTrackerUI end,
        set = function(_, val) 
            FQoL.db.profile.skinningTrackerUI = val 
            if self.UpdateSkinningTracker then self:UpdateSkinningTracker() end
        end,
    }

    self:RegisterChatCommand("skinning", "HandleSkinningCommand")
end

function Module:EnableSkinning()
    if not HasSkinning() or self.isWaypointHooked then return end
    hooksecurefunc("SetItemRef", function(link)
        local linkType, addon, action, rareID = strsplit(":", link)
        if linkType == "addon" and addon == "FQoL" and action == "rare" then
            self:SetRareWaypoint(tonumber(rareID))
        end
    end)
    self.isWaypointHooked = true
end

function Module:SetRareWaypoint(rareID)
    if self.currentRareWaypointID == rareID then
        if C_AddOns.IsAddOnLoaded("TomTom") and TomTom and TomTom.RemoveWaypoint then
            if self.currentTomTomWaypoint then TomTom:RemoveWaypoint(self.currentTomTomWaypoint) end
        else
            C_Map.ClearUserWaypoint()
        end
        self.currentRareWaypointID, self.currentTomTomWaypoint = nil, nil
        return
    end

    local data
    for _, d in ipairs(Module.skinningQuestData) do if d.id == rareID then data = d; break end end
    if not data then return end

    if C_AddOns.IsAddOnLoaded("TomTom") and TomTom and TomTom.AddWaypoint then
        if self.currentTomTomWaypoint then TomTom:RemoveWaypoint(self.currentTomTomWaypoint) end
        self.currentTomTomWaypoint = TomTom:AddWaypoint(data.mapID, data.x / 100, data.y / 100, {
            title = string.format("%s (%s)", data.name, data.zone),
            persistent = false, arrivaldistance = 15,
        })
    else
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(data.mapID, data.x / 100, data.y / 100))
        self:Print(string.format("Waypoint set for |cFFFFD100%s|r.", data.name))
    end
    self.currentRareWaypointID = rareID
end

function Module:HandleSkinningCommand(input)
    if not FQoL:GetModuleEnabled("Professions") or not FQoL.db.profile.skinningEnabled then
        self:Print("|cFFFF0000Error:|r The Skinning utility is currently disabled.")
        return
    end

    local arg1 = self:GetArgs(input, 1)
    if arg1 == "rares" then
        local seconds = C_DateAndTime.GetSecondsUntilDailyReset() or 0
        local timeStr = seconds > 0 and string.format(" (|cFFFFD100%dh %dm|r remaining)", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60)) or ""
        self:Print("Daily Skinning Rares" .. timeStr .. ":")
        for _, data in ipairs(Module.skinningQuestData) do
            local status = C_QuestLog.IsQuestFlaggedCompleted(data.id) and "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14:0:0|t" or "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14:14:0:0|t"
            local name = data.emphasize and ("|cFFFFD100" .. data.name .. "|r") or data.name
            local coords = string.format(" |Haddon:FQoL:rare:%d|h[|cff8888ff%.0f, %.0f|r]|h", data.id, data.x, data.y)
            self:Print(string.format("%s %s (%s)%s", status, name, data.zone, coords))
        end
    elseif arg1 == "tracker" then
        FQoL.db.profile.skinningTrackerUI = not FQoL.db.profile.skinningTrackerUI
        self:UpdateSkinningTracker()
        self:Print("Skinning Tracker UI: " .. (FQoL.db.profile.skinningTrackerUI and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))
    else
        self:Print("Available parameters: |cFFFFD100rares|r, |cFFFFD100tracker|r")
    end
end
