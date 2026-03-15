local FQoL = LibStub("AceAddon-3.0"):GetAddon("FQoL")
local Module = FQoL:GetModule("Professions")

Module.skinningQuestData = {
    { id = 88545, name = "Ghostclaw Elder", zone = "Eversong", mapID = 2395, x = 41.95, y = 80.05 },
    { id = 88526, name = "Silverscale", zone = "Zul'Aman", mapID = 2437, x = 47.69, y = 53.25 },
    { id = 88531, name = "Lumenfin", zone = "Harandar", mapID = 2413, x = 66.28, y = 47.91 },
    { id = 88532, name = "Umbrafang", zone = "Voidstorm", mapID = 2405, x = 54.60, y = 65.80 },
    { id = 88524, name = "Netherscythe", zone = "Voidstorm", mapID = 2405, x = 43.25, y = 82.75, emphasize = true },
}

-- We use a local hook to initialize when the parent module does, 
-- or immediately if it's already initialized.
local function Initialize()
    if FQoL.db.profile.skinningEnabled == nil then
        FQoL.db.profile.skinningEnabled = true
    end
    if FQoL.db.profile.skinningTrackerUI == nil then
        FQoL.db.profile.skinningTrackerUI = true
    end
    if FQoL.db.profile.skinningTrackerCollapsed == nil then
        FQoL.db.profile.skinningTrackerCollapsed = false
    end
    if FQoL.db.profile.skinningTrackerPosition == nil then
        FQoL.db.profile.skinningTrackerPosition = {}
    end

    -- Add to Professions options
    local options = FQoL.options.args.modules.args["Professions"].args
    options.skinningHeader = {
        type = "header",
        name = "Skinning",
        order = 10,
    }
    options.skinningEnabled = {
        type = "toggle",
        name = "Enable Skinning Utilities",
        desc = "Enables the /skinning command and other skinning-specific features.",
        order = 11,
        get = function() return FQoL.db.profile.skinningEnabled end,
        set = function(_, val) 
            FQoL.db.profile.skinningEnabled = val 
            if Module.UpdateSkinningTracker then Module:UpdateSkinningTracker() end
        end,
    }
    options.skinningTrackerUI = {
        type = "toggle",
        name = "Show Tracker UI",
        desc = "Shows a standalone UI or integrates with MKPT.",
        order = 12,
        get = function() return FQoL.db.profile.skinningTrackerUI end,
        set = function(_, val) 
            FQoL.db.profile.skinningTrackerUI = val 
            if Module.UpdateSkinningTracker then Module:UpdateSkinningTracker() end
        end,
    }

    Module:RegisterChatCommand("skinning", "HandleSkinningCommand")
end

-- Using a separate function for the hook to ensure it only happens once
local function HookHyperlinks()
    if Module.isWaypointHooked then return end
    
    -- SetItemRef is the global engine-level handler for all link clicks
    hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
        -- Format: addon:FQoL:rare:ID
        local linkType, addon, action, rareID = strsplit(":", link)
        if linkType == "addon" and addon == "FQoL" and action == "rare" then
            Module:SetRareWaypoint(tonumber(rareID))
        end
    end)
    
    Module.isWaypointHooked = true
end

function Module:SetRareWaypoint(rareID)
    -- Toggle: If clicking the same one, clear it
    if self.currentRareWaypointID == rareID then
        if C_AddOns.IsAddOnLoaded("TomTom") and TomTom and TomTom.RemoveWaypoint then
            if self.currentTomTomWaypoint then
                TomTom:RemoveWaypoint(self.currentTomTomWaypoint)
            end
        else
            C_Map.ClearUserWaypoint()
        end
        self.currentRareWaypointID = nil
        self.currentTomTomWaypoint = nil
        return
    end

    local data = nil
    for _, d in ipairs(Module.skinningQuestData) do
        if d.id == rareID then
            data = d
            break
        end
    end

    if not data then return end

    if C_AddOns.IsAddOnLoaded("TomTom") and TomTom and TomTom.AddWaypoint then
        -- Clear previous if exists
        if self.currentTomTomWaypoint then
            TomTom:RemoveWaypoint(self.currentTomTomWaypoint)
        end
        -- TomTom API expects x and y as 0.0 to 1.0
        self.currentTomTomWaypoint = TomTom:AddWaypoint(data.mapID, data.x / 100, data.y / 100, {
            title = string.format("%s (%s)", data.name, data.zone),
            persistent = false,
            arrivaldistance = 15,
        })
    else
        -- Native Blizzard Waypoint (User Waypoint)
        local point = UiMapPoint.CreateFromCoordinates(data.mapID, data.x / 100, data.y / 100)
        C_Map.SetUserWaypoint(point)
        self:Print(string.format("Waypoint set for |cFFFFD100%s|r. (TomTom not found for named labels)", data.name))
    end
    self.currentRareWaypointID = rareID
end

function Module:HandleSkinningCommand(input)
    -- Check if both the main module and the skinning sub-feature are enabled
    if not FQoL.db.profile.modules["Professions"] or not FQoL.db.profile.skinningEnabled then
        self:Print("|cFFFF0000Error:|r The Skinning utility is currently disabled.")
        return
    end

    if not input or input:trim() == "" then
        self:Print("Available parameters:")
        self:Print("  |cFFFFD100rares|r - Check completion of daily skinning rare quests.")
        self:Print("  |cFFFFD100tracker|r - Toggle the standalone tracker UI.")
        return
    end

    local arg1 = self:GetArgs(input, 1)
    if arg1 == "rares" then
        local seconds = C_DateAndTime.GetSecondsUntilDailyReset()
        local timeStr = ""
        if seconds and seconds > 0 then
            local hours = math.floor(seconds / 3600)
            local mins = math.floor((seconds % 3600) / 60)
            timeStr = string.format(" (|cFFFFD100%dh %dm|r remaining)", hours, mins)
        end

        self:Print("Daily Skinning Rares" .. timeStr .. ":")
        
        for _, data in ipairs(Module.skinningQuestData) do
            local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(data.id)
            local status = isCompleted and "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14:0:0|t" or "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14:14:0:0|t"
            local displayName = string.format("%s (%s)", data.name, data.zone)
            
            if data.emphasize then
                displayName = "|cFFFFD100" .. displayName .. "|r"
            end

            -- Create our custom fqolrare clickable link
            local coords = string.format(" |Haddon:FQoL:rare:%d|h[|cff8888ff%.1f, %.1f|r]|h", data.id, data.x, data.y)
            
            self:Print(string.format("%s %s%s", status, displayName, coords))
        end
    elseif arg1 == "tracker" then
        FQoL.db.profile.skinningTrackerUI = not FQoL.db.profile.skinningTrackerUI
        if Module.UpdateSkinningTracker then Module:UpdateSkinningTracker() end
        self:Print("Skinning Tracker UI: " .. (FQoL.db.profile.skinningTrackerUI and "|cFF00FF00Enabled|r" or "|cFFFF0000Disabled|r"))
    else
        self:Print(string.format("Unknown parameter '|cFFFF0000%s|r'. Use |cFFFFD100/skinning|r for help.", arg1))
    end
end

-- Register the initialization with the parent module
local oldInit = Module.OnInitialize
function Module:OnInitialize()
    if oldInit then oldInit(self) end
    Initialize()
end

local oldEnable = Module.OnEnable
function Module:OnEnable()
    if oldEnable then oldEnable(self) end
    HookHyperlinks()
end
