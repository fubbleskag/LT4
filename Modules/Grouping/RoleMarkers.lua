local FQoL = LibStub("AceAddon-3.0"):GetAddon("FQoL")
local Module = FQoL:NewModule("RoleMarkers", "AceConsole-3.0", "AceEvent-3.0")

Module.description = "Midnight 12.0 Version: Correctly rewrites the 'FQoL_Mark' macro with /tm [unit] [icon] syntax."

local TANK_DEFAULT = 6 
local HEALER_DEFAULT = 5

function Module:OnInitialize()
    self:RegisterChatCommand("fmark", "UpdateMarkMacro")
    
    -- Register events to auto-update when the group changes
    self:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdateMarkMacro")

    FQoL.options.args.modules.args[self:GetName()] = {
        type = "group",
        name = "Role Markers",
        args = {
            enable = {
                type = "toggle",
                name = "Enable Module",
                get = function() return FQoL.db.profile.modules[self:GetName()] end,
                set = function(_, val) 
                    FQoL.db.profile.modules[self:GetName()] = val 
                    if val then Module:Enable() else Module:Disable() end
                end,
            },
        }
    }
end

function Module:UpdateMarkMacro()
    -- Cannot edit macros in combat
    if InCombatLockdown() or not IsInGroup() then return end

    local tankIcon = FQoL.db.profile.tankMarker or TANK_DEFAULT
    local healerIcon = FQoL.db.profile.healerMarker or HEALER_DEFAULT
    
    -- #showtooltip makes the macro icon match the first target
    local macroBody = "#showtooltip\n/stopmacro [combat]\n"

    local function check(unit)
        if UnitExists(unit) then
            local role = UnitGroupRolesAssigned(unit)
            -- CORRECTED SYNTAX: /tm [unit] [icon]
            if role == "TANK" then
                macroBody = macroBody .. "/tm " .. unit .. " " .. tankIcon .. "\n"
            elseif role == "HEALER" then
                macroBody = macroBody .. "/tm " .. unit .. " " .. healerIcon .. "\n"
            end
        end
    end

    -- Check player first
    check("player")
    
    -- Check party/raid
    local prefix = IsInRaid() and "raid" or "party"
    local maxMembers = IsInRaid() and 40 or 4
    for i = 1, maxMembers do 
        check(prefix .. i) 
    end

    -- Final safety: if no roles found, macro does nothing
    if macroBody == "#showtooltip\n/stopmacro [combat]\n" then
        macroBody = macroBody .. "/print FQoL: No Tank/Healer found."
    end

    local macroIndex = GetMacroIndexByName("FQoL_Mark")
    if macroIndex == 0 then
        -- Use icon 134400 (Question Mark) as default
        CreateMacro("FQoL_Mark", 134400, macroBody, nil)
        self:Print("Macro 'FQoL_Mark' created! Please drag it to your action bar.")
    else
        EditMacro(macroIndex, "FQoL_Mark", nil, macroBody)
    end
end