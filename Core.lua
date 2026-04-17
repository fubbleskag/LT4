LT4 = LibStub("AceAddon-3.0"):NewAddon("LT4", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
LT4:SetDefaultModuleState(false)
local LDB = LibStub("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")

-- Define global module order (Sidebar and Toggle Sync)
LT4.moduleOrder = {
    ["LumiBar"]        = 10,
    ["SquareMinimap"]  = 20,
    ["Professions"]    = 30,
    ["Cursor"]         = 40,
    ["Window Control"]  = 50,
    ["Chat"]            = 60,
    ["Quality of Life"] = 99,
}

-- Get AddOn metadata
LT4.version = C_AddOns.GetAddOnMetadata("LT4", "Version") or "1.0.0"
LT4.title = C_AddOns.GetAddOnMetadata("LT4", "Title") or "LT4"

local defaults = {
    global = {
        altCharacters = {},
        chatHistory = {},
    },
    profile = {
        minimap = {
            hide = false,
            showInCompartment = true,
        },
        modules = {
            ["*"] = false, 
        },
        professionsSummaryView = false,
        skinningTrackerUI = true,
        skinningTrackerCollapsed = false,
        skinningTrackerPosition = {},
        qol = {
            showIDs = true,
            betterFishing = true,
            sitFishing = true,
            fishingClickButton = "RightButton",
            autoRepair = true,
            useGuildRepair = true,
            autoSellJunk = true,
            collectedIndicator = true,
            mailAlts = true,
            mailAltSort = "login",
            autoConfirmDelete = true,
            keystones = false,
            keystonesChannel = "BOTH",
            autoAcceptGroup = false,
            autoAcceptGroupFriends = false,
            autoAcceptGroupGuild = false,
            autoAcceptSummon = false,
            autoAcceptSummonFriends = false,
            autoAcceptSummonGuild = false,
            autoRejectDuel = false,
            autoRejectDuelFriends = false,
            autoRejectDuelGuild = false,
            autoRejectGuildInvite = false,
            autoRejectGuildInviteFriends = false,
        },
        windowControl = {
            positions = {},
        },
        chat = {
            history = {
                enabled = true,
                lines = 128,
            },
            copyWindow = {
                width = 500,
                height = 400,
            },
            style = {
                flatTabs = true,
                alwaysShowEditBox = true,
                font = {
                    enabled = false,
                    face = "Friz Quadrata TT",
                    size = 12,
                },
            },
        },
        cursor = {
            cursors = {
                [1] = {
                    enabled = true,
                    texture = "Ring 1",
                    color = { r = 1, g = 1, b = 1 },
                    scale = 1,
                    opacity = 1,
                    fadeIdle = false,
                    combatOnly = false,
                },
                [2] = {
                    enabled = true,
                    texture = "Ring Soft 1",
                    color = { r = 1, g = 0, b = 0 },
                    scale = 0.9,
                    opacity = 1,
                    fadeIdle = false,
                    combatOnly = true,
                },
            },
        },
    },
}

function LT4:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("LT4DB", defaults, true)
    self.moduleRegistry = {}

    -- Migration: Miscellaneous → Quality of Life
    for _, profile in pairs(self.db.profiles or {}) do
        if profile.miscellaneous then
            profile.qol = profile.miscellaneous
            profile.miscellaneous = nil
        end
        if profile.modules and profile.modules["Miscellaneous"] ~= nil then
            profile.modules["Quality of Life"] = profile.modules["Miscellaneous"]
            profile.modules["Miscellaneous"] = nil
        end
    end
    
    StaticPopupDialogs["LT4_RELOAD_UI"] = {
        text = "|cFF00AAFF" .. self.title .. "|r: A UI reload is required to fully apply these changes. Reload now?",
        button1 = "Reload",
        button2 = "Later",
        OnAccept = function() ReloadUI() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    
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
                    minimapIcon = {
                        type = "toggle",
                        name = "Hide Minimap Icon",
                        width = "full",
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
                        width = "full",
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
            moduleToggles = {
                type = "group",
                name = "Module Control",
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
        OnClick = function(_, button)
            if IsShiftKeyDown() and button == "LeftButton" then
                local LumiBar = self:GetModule("LumiBar", true)
                if LumiBar and not InCombatLockdown() then
                    LumiBar:InvalidateCaches()
                    LumiBar:RefreshConfig()
                    self:Print("|cff00ccffLumiBar|r refreshed and caches invalidated.")
                end
            else
                self:OpenOptions()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cFF00AAFF" .. LT4.title .. "|r")
            tooltip:AddLine("|cFFFFFFFFLeft-Click:|r Open Settings")
            tooltip:AddLine("|cFFFFFFFFShift + Left-Click:|r Refresh LumiBar & Rescan Caches")
        end,
    })
    icon:Register("LT4", LT4_LDB, self.db.profile.minimap)

    self:RegisterChatCommand("lt4", "OpenOptions")

    -- Setup module options after they have registered (deferred)
    self:ScheduleTimer("SetupAllOptions", 0.1)
end

function LT4:SetupAllOptions()
    -- 1. Sort the registry by defined order
    local sorted = {}
    for name, entry in pairs(self.moduleRegistry) do
        table.insert(sorted, { name = name, options = entry.options, order = entry.order })
    end
    table.sort(sorted, function(a, b) return a.order < b.order end)

    -- 2. Register in sorted order
    for _, entry in ipairs(sorted) do
        local name = entry.name
        local options = entry.options
        local order = entry.order

        -- Add toggle to main page
        self.options.args.moduleToggles.args[name] = {
            type = "toggle",
            name = "Enable " .. name,
            desc = "Enable or disable the " .. name .. " module.",
            width = "full",
            order = order,
            get = function() return self:GetModuleEnabled(name) end,
            set = function(_, val) self:SetModuleEnabled(name, val) end,
        }

        -- Register sidebar sub-category ONLY if it has meaningful arguments
        local hasArgs = false
        if options and options.args then
            for _, arg in pairs(options.args) do
                if arg.type ~= "description" and arg.type ~= "header" then
                    hasArgs = true
                    break
                end
            end
        end

        if hasArgs then
            local appName = "LT4_" .. name
            LibStub("AceConfig-3.0"):RegisterOptionsTable(appName, options)
            LibStub("AceConfigDialog-3.0"):AddToBlizOptions(appName, name, self.title)
        end
    end
end

function LT4:OnEnable()
    local enabledModules = {}
    for name, module in self:IterateModules() do
        if self:GetModuleEnabled(name) then
            module:Enable()
            table.insert(enabledModules, "|cFF00FF00" .. name .. "|r")
        end
    end

    local status = #enabledModules > 0 and ("Active Modules: " .. table.concat(enabledModules, ", ")) or "|cFFFF8800No modules enabled.|r"
    self:Print(string.format("|cFF00AAFFv%s Loaded.|r %s", self.version, status))
end

function LT4:OpenOptions()
    if InCombatLockdown() then
        self:Print("|cFFFF8800Cannot open settings during combat.|r")
        return
    end
    if self.categoryID then
        Settings.OpenToCategory(self.categoryID)
    else
        Settings.OpenToCategory(self.title)
    end
end

-- Shared Helpers
function LT4:GetModuleEnabled(name)
    if not self.db then return false end
    return self.db.profile.modules[name]
end

function LT4:SetModuleEnabled(name, value)
    if not self.db then return end
    self.db.profile.modules[name] = value
    local module = self:GetModule(name, true)
    if module then
        if value then 
            module:Enable() 
        else 
            module:Disable() 
            if module.requiresReload then
                StaticPopup_Show("LT4_RELOAD_UI")
            end
        end
    end
end

function LT4:RegisterModuleOptions(name, options, order)
    local finalOrder = order or self.moduleOrder[name] or 100
    self.moduleRegistry[name] = {
        options = options,
        order = finalOrder,
    }
end