FQoL = LibStub("AceAddon-3.0"):NewAddon("FQoL", "AceConsole-3.0", "AceEvent-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")

local defaults = {
    profile = {
        minimap = {
            hide = false,
            showInCompartment = true,
        },
        modules = {
            ["*"] = false, 
        },
        elvuiSkins = {
            ["*"] = true,
        },
    },
}

function FQoL:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("FQoLDB", defaults, true)
    
    self.options = {
        type = "group",
        name = "FQoL",
        args = {
            general = {
                type = "group",
                name = "General Settings",
                inline = true,
                order = 1,
                args = {
                    minimapIcon = {
                        type = "toggle",
                        name = "Hide Minimap Icon",
                        order = 1,
                        get = function() return self.db.profile.minimap.hide end,
                        set = function(_, val)
                            self.db.profile.minimap.hide = val
                            if val then LibStub("LibDBIcon-1.0"):Hide("FQoL") else LibStub("LibDBIcon-1.0"):Show("FQoL") end
                        end,
                    },
                    compartmentIcon = {
                        type = "toggle",
                        name = "Hide in Addon Compartment",
                        order = 2,
                        get = function() return not self.db.profile.minimap.showInCompartment end,
                        set = function(_, val)
                            self.db.profile.minimap.showInCompartment = not val
                            if not val then
                                LibStub("LibDBIcon-1.0"):AddButtonToCompartment("FQoL")
                            else
                                LibStub("LibDBIcon-1.0"):RemoveButtonFromCompartment("FQoL")
                            end
                        end,
                    },
                },
            },
            modules = { 
                type = "group", 
                name = "Modules", 
                inline = true, 
                order = 2,
                args = {} -- We'll fill this in a second
            },
        },
    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable("FQoL", self.options)
    self.optionsFrame, self.categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("FQoL", "FQoL")
    
    -- Register Minimap Button
    local FQoL_LDB = LDB:NewDataObject("FQoL", {
        type = "launcher",
        text = "FQoL",
        icon = "Interface\\Addons\\FQoL\\Media\\FQoL",
        OnClick = function() self:OpenOptions() end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cFF00AAFFFQoL|r")
            tooltip:AddLine("|cFFFFFFFFLeft-Click:|r Open Settings")
        end,
    })
    icon:Register("FQoL", FQoL_LDB, self.db.profile.minimap)

    self:RegisterChatCommand("fqol", "OpenOptions")

end

function FQoL:OnEnable()
    local enabledModules = {}

    -- Iterate through all registered modules
    for name, module in self:IterateModules() do
        if module:IsEnabled() then
            table.insert(enabledModules, "|cFF00FF00" .. name .. "|r")
        end
    end

    -- Construct the message logic properly
    local status
    if #enabledModules > 0 then
        status = "Active Modules: " .. table.concat(enabledModules, ", ")
    else
        status = "|cFFFF8800No modules enabled.|r"
    end

    self:Print("|cFF00AAFFv1.0.0 Loaded.|r " .. status)
end

function FQoL:OpenOptions()
    if self.categoryID then
        Settings.OpenToCategory(self.categoryID)
    else
        -- This is the fallback if the settings window is already open
        Settings.OpenToCategory("FQoL")
    end
end