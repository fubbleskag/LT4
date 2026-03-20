FQoL = LibStub("AceAddon-3.0"):NewAddon("FQoL", "AceConsole-3.0", "AceEvent-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")

-- Get AddOn metadata
FQoL.version = C_AddOns.GetAddOnMetadata("FQoL", "Version") or "1.0.0"
FQoL.title = C_AddOns.GetAddOnMetadata("FQoL", "Title") or "FQoL"

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
        name = self.title,
        args = {
            general = {
                type = "group",
                name = "General Settings",
                inline = true,
                order = 1,
                args = {
                    version = {
                        type = "description",
                        name = "|cFF00AAFFVersion:|r " .. self.version,
                        order = 0,
                    },
                    minimapIcon = {
                        type = "toggle",
                        name = "Hide Minimap Icon",
                        order = 1,
                        get = function() return self.db.profile.minimap.hide end,
                        set = function(_, val)
                            self.db.profile.minimap.hide = val
                            if val then icon:Hide("FQoL") else icon:Show("FQoL") end
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
                                icon:AddButtonToCompartment("FQoL")
                            else
                                icon:RemoveButtonFromCompartment("FQoL")
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
                args = {}
            },
        },
    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable("FQoL", self.options)
    self.optionsFrame, self.categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("FQoL", self.title)
    
    -- Register Minimap Button
    local FQoL_LDB = LDB:NewDataObject("FQoL", {
        type = "launcher",
        text = "FQoL",
        icon = "Interface\\Addons\\FQoL\\Media\\FQoL",
        OnClick = function() self:OpenOptions() end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cFF00AAFF" .. FQoL.title .. "|r")
            tooltip:AddLine("|cFFFFFFFFLeft-Click:|r Open Settings")
        end,
    })
    icon:Register("FQoL", FQoL_LDB, self.db.profile.minimap)

    self:RegisterChatCommand("fqol", "OpenOptions")
end

function FQoL:OnEnable()
    local enabledModules = {}
    for name, module in self:IterateModules() do
        if module:IsEnabled() then
            table.insert(enabledModules, "|cFF00FF00" .. name .. "|r")
        end
    end

    local status = #enabledModules > 0 and ("Active Modules: " .. table.concat(enabledModules, ", ")) or "|cFFFF8800No modules enabled.|r"
    self:Print(string.format("|cFF00AAFFv%s Loaded.|r %s", self.version, status))
end

function FQoL:OpenOptions()
    if self.categoryID then
        Settings.OpenToCategory(self.categoryID)
    else
        Settings.OpenToCategory(self.title)
    end
end

-- Shared Helpers
function FQoL:GetModuleEnabled(name)
    return self.db.profile.modules[name]
end

function FQoL:SetModuleEnabled(name, value)
    self.db.profile.modules[name] = value
    local module = self:GetModule(name, true)
    if module then
        if value then module:Enable() else module:Disable() end
    end
end

function FQoL:RegisterModuleOptions(name, options, order)
    self.options.args.modules.args[name] = options
    if order then self.options.args.modules.args[name].order = order end
end