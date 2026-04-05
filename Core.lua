LT4 = LibStub("AceAddon-3.0"):NewAddon("LT4", "AceConsole-3.0", "AceEvent-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")

-- Get AddOn metadata
LT4.version = C_AddOns.GetAddOnMetadata("LT4", "Version") or "1.0.0"
LT4.title = C_AddOns.GetAddOnMetadata("LT4", "Title") or "LT4"

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

function LT4:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("LT4DB", defaults, true)
    
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
                            if val then icon:Hide("LT4") else icon:Show("LT4") end
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
                                icon:AddButtonToCompartment("LT4")
                            else
                                icon:RemoveButtonFromCompartment("LT4")
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

    LibStub("AceConfig-3.0"):RegisterOptionsTable("LT4", self.options)
    self.optionsFrame, self.categoryID = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("LT4", self.title)
    
    -- Register Minimap Button
    local LT4_LDB = LDB:NewDataObject("LT4", {
        type = "launcher",
        text = "<4",
        icon = "Interface\\Addons\\LT4\\Media\\LT4",
        OnClick = function() self:OpenOptions() end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cFF00AAFF" .. LT4.title .. "|r")
            tooltip:AddLine("|cFFFFFFFFLeft-Click:|r Open Settings")
        end,
    })
    icon:Register("LT4", LT4_LDB, self.db.profile.minimap)

    self:RegisterChatCommand("lt4", "OpenOptions")
end

function LT4:OnEnable()
    local enabledModules = {}
    for name, module in self:IterateModules() do
        if module:IsEnabled() then
            table.insert(enabledModules, "|cFF00FF00" .. name .. "|r")
        end
    end

    local status = #enabledModules > 0 and ("Active Modules: " .. table.concat(enabledModules, ", ")) or "|cFFFF8800No modules enabled.|r"
    self:Print(string.format("|cFF00AAFFv%s Loaded.|r %s", self.version, status))
end

function LT4:OpenOptions()
    if self.categoryID then
        Settings.OpenToCategory(self.categoryID)
    else
        Settings.OpenToCategory(self.title)
    end
end

-- Shared Helpers
function LT4:GetModuleEnabled(name)
    return self.db.profile.modules[name]
end

function LT4:SetModuleEnabled(name, value)
    self.db.profile.modules[name] = value
    local module = self:GetModule(name, true)
    if module then
        if value then module:Enable() else module:Disable() end
    end
end

function LT4:RegisterModuleOptions(name, options, order)
    self.options.args.modules.args[name] = options
    if order then self.options.args.modules.args[name].order = order end
end