local FQoL = LibStub("AceAddon-3.0"):GetAddon("FQoL")
local Module = FQoL:GetModule("Professions")

local questData = {
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
        set = function(_, val) FQoL.db.profile.skinningEnabled = val end,
    }

    Module:RegisterChatCommand("skinning", "HandleSkinningCommand")
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
        
        for _, data in ipairs(questData) do
            local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(data.id)
            local status = isCompleted and "|TInterface\\RaidFrame\\ReadyCheck-Ready:14:14:0:0|t" or "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14:14:0:0|t"
            local displayName = string.format("%s (%s)", data.name, data.zone)
            
            if data.emphasize then
                displayName = "|cFFFFD100" .. displayName .. "|r"
            end

            -- Create a clickable map link (pin)
            local coords = ""
            if data.mapID and data.x and data.y then
                -- Map links use normalized coordinates multiplied by 10000
                -- Since our data is 0-100, we multiply by 100
                local payloadX = math.floor(data.x * 100)
                local payloadY = math.floor(data.y * 100)
                coords = string.format(" |Hworldmap:%d:%d:%d|h[|cff8888ff%.1f, %.1f|r]|h", data.mapID, payloadX, payloadY, data.x, data.y)
            end
            
            self:Print(string.format("%s %s%s", status, displayName, coords))
        end
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
