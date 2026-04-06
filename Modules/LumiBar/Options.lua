local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")

local LSM = LibStub("LibSharedMedia-3.0", true)

local options = {
    name = "LumiBar",
    handler = LumiBar,
    type = "group",
    childGroups = "tab",
    args = {
        general = {
            name = "General Settings",
            type = "group",
            order = 1,
            args = {
                barGroup = {
                    name = "Bar",
                    type = "group",
                    inline = true,
                    order = 10,
                    args = {
                        position = {
                            name = "Position",
                            desc = "Set the bar to the top or bottom of the screen",
                            type = "select",
                            values = { ["TOP"] = "Top", ["BOTTOM"] = "Bottom" },
                            get = function(info) return LumiBar.db.profile.bar.position end,
                            set = function(info, value) 
                                LumiBar.db.profile.bar.position = value
                                LumiBar:RefreshConfig()
                            end,
                            order = 1,
                        },
                        height = {
                            name = "Height",
                            type = "range",
                            min = 10, max = 100, step = 1,
                            get = function(info) return LumiBar.db.profile.bar.height end,
                            set = function(info, value) 
                                LumiBar.db.profile.bar.height = value
                                LumiBar:RefreshConfig()
                                LumiBar:RefreshModules()
                            end,
                            order = 2,
                        },
                        lineBreak = {
                            type = "header",
                            name = "",
                            order = 3,
                        },
                        backgroundColor = {
                            name = "Background Color",
                            type = "color",
                            hasAlpha = true,
                            get = function(info)
                                local c = LumiBar.db.profile.bar.backgroundColor
                                return c.r, c.g, c.b, c.a
                            end,
                            set = function(info, r, g, b, a)
                                local c = LumiBar.db.profile.bar.backgroundColor
                                c.r, c.g, c.b, c.a = r, g, b, a
                                LumiBar:RefreshConfig()
                            end,
                            order = 4,
                        },
                        useClassColor = {
                            name = "Use Class Color",
                            type = "toggle",
                            get = function(info) return LumiBar.db.profile.bar.useClassColor end,
                            set = function(info, value)
                                LumiBar.db.profile.bar.useClassColor = value
                                LumiBar:RefreshConfig()
                            end,
                            order = 5,
                        },
                        backgroundTexture = {
                            name = "Background Texture",
                            type = "select",
                            dialogControl = LSM and "LSM30_Statusbar" or nil,
                            values = LSM and LSM:HashTable("statusbar") or { ["Solid"] = "Solid" },
                            get = function(info) return LumiBar.db.profile.bar.backgroundTexture end,
                            set = function(info, value)
                                LumiBar.db.profile.bar.backgroundTexture = value
                                LumiBar:RefreshConfig()
                            end,
                            order = 6,
                        },
                    },
                },
                fontGroup = {
                    name = "Font",
                    type = "group",
                    inline = true,
                    order = 20,
                    args = {
                        face = {
                            name = "Font Face",
                            type = "select",
                            dialogControl = LSM and "LSM30_Font" or nil,
                            values = LSM and LSM:HashTable("font") or { ["Arial Narrow"] = "Arial Narrow" },
                            get = function(info) return LumiBar.db.profile.general.font.face end,
                            set = function(info, value)
                                LumiBar.db.profile.general.font.face = value
                                LumiBar:RefreshModules()
                            end,
                            order = 1,
                        },
                        size = {
                            name = "Font Size",
                            type = "range",
                            min = 6, max = 32, step = 1,
                            get = function(info) return LumiBar.db.profile.general.font.size end,
                            set = function(info, value)
                                LumiBar.db.profile.general.font.size = value
                                LumiBar:RefreshModules()
                            end,
                            order = 2,
                        },
                        outline = {
                            name = "Font Outline",
                            type = "select",
                            values = { ["NONE"] = "None", ["OUTLINE"] = "Outline", ["THICKOUTLINE"] = "Thick Outline", ["MONOCHROME"] = "Monochrome" },
                            get = function(info) return LumiBar.db.profile.general.font.outline end,
                            set = function(info, value)
                                LumiBar.db.profile.general.font.outline = value
                                LumiBar:RefreshModules()
                            end,
                            order = 3,
                        },
                        color = {
                            name = "Primary Color",
                            type = "color",
                            hasAlpha = true,
                            get = function(info)
                                local c = LumiBar.db.profile.general.font.color
                                return c.r, c.g, c.b, c.a
                            end,
                            set = function(info, r, g, b, a)
                                local c = LumiBar.db.profile.general.font.color
                                c.r, c.g, c.b, c.a = r, g, b, a
                                LumiBar:RefreshModules()
                            end,
                            order = 4,
                        },
                        accentColor = {
                            name = "Accent Color",
                            desc = "Used for icons and highlights",
                            type = "color",
                            hasAlpha = true,
                            get = function(info)
                                local c = LumiBar.db.profile.general.accentColor
                                return c.r, c.g, c.b, c.a
                            end,
                            set = function(info, r, g, b, a)
                                local c = LumiBar.db.profile.general.accentColor
                                c.r, c.g, c.b, c.a = r, g, b, a
                                LumiBar:RefreshModules()
                            end,
                            order = 5,
                        },
                    },
                },
            },
        },
        zones = {
            name = "Zone Layout",
            type = "group",
            order = 2,
            args = {},
        },
        modules = {
            name = "Module Settings",
            type = "group",
            order = 3,
            args = {},
        },
    },
}

-- Populate Zone Settings
local zoneNames = { "Left", "Center", "Right" }
for _, zName in ipairs(zoneNames) do
    options.args.zones.args[zName] = {
        name = zName,
        type = "group",
        order = (zName == "Left" and 1 or (zName == "Center" and 2 or 3)),
        args = {},
    }
end

-- This function will be called by LumiBar:OnInitialize or similar if needed, 
-- but here we just populate the table.
local function UpdateModuleOptions()
    for mName, module in pairs(LumiBar.Modules) do
        -- 1. Add to Module Settings Tab
        if LumiBar.moduleOptions and LumiBar.moduleOptions[mName] then
            local moduleOpts = LumiBar.moduleOptions[mName]
            
            -- Inject a wrapper for the 'set' function if it exists, or add one if it doesn't
            -- This ensures that whenever a module setting is changed, LumiBar:RefreshModules() is called.
            local originalSet = moduleOpts.set
            moduleOpts.set = function(info, ...)
                if originalSet then
                    originalSet(info, ...)
                else
                    -- Default set behavior if the module didn't provide one
                    local var = info[#info]
                    if module.db then
                        module.db[var] = ...
                    end
                end
                LumiBar:RefreshModules()
            end

            options.args.modules.args[mName] = moduleOpts
        end
        
        -- 2. Add to Zone Assignments
        for _, zName in ipairs(zoneNames) do
            options.args.zones.args[zName].args[mName] = {
                name = mName,
                type = "toggle",
                get = function(info)
                    local list = LumiBar.db.profile.zones[zName]
                    for _, activeName in ipairs(list) do
                        if activeName == mName then return true end
                    end
                    return false
                end,
                set = function(info, value)
                    local currentZones = LumiBar.db.profile.zones or LumiBar.defaults.profile.zones
                    local zones = {
                        Left = CopyTable(currentZones.Left or {}),
                        Center = CopyTable(currentZones.Center or {}),
                        Right = CopyTable(currentZones.Right or {}),
                    }
                    -- Remove from all zones first
                    for _, zoneKey in ipairs(zoneNames) do
                        local list = zones[zoneKey]
                        for idx = #list, 1, -1 do
                            if list[idx] == mName then
                                table.remove(list, idx)
                            end
                        end
                    end
                    -- Add to target zone if enabling
                    if value then
                        table.insert(zones[zName], mName)
                    end
                    LumiBar.db.profile.zones = zones
                    LumiBar:RefreshModules()
                end,
            }
        end
    end
end

-- We need to wait until modules are initialized to fully populate the options.
-- However, AceConfig can handle dynamic tables if we use functions.
-- For now, we'll just register it.

-- Initial population
function LumiBar:InitOptions()
    UpdateModuleOptions()
    LT4:RegisterModuleOptions("LumiBar", options)
end
