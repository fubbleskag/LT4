local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")

local LSM = LibStub("LibSharedMedia-3.0", true)

local options = {
    name = "LumiBar",
    handler = LumiBar,
    type = "group",
    childGroups = "tree",
    args = {
        general = {
            name = "General",
            type = "group",
            order = 1,
            args = {
                moduleLayout = {
                    name = "Module Layout",
                    desc = "Open the module layout editor",
                    type = "execute",
                    width = "full",
                    func = function()
                        if LumiBar.OpenLayoutEditor then
                            LumiBar:OpenLayoutEditor()
                        end
                    end,
                    order = 0,
                },
                position = {
                    name = "Position",
                    desc = "Set the bar to the top or bottom of the screen",
                    type = "select",
                    width = "full",
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
                    width = "full",
                    min = 10, max = 100, step = 1,
                    get = function(info) return LumiBar.db.profile.bar.height end,
                    set = function(info, value)
                        LumiBar.db.profile.bar.height = value
                        LumiBar:RefreshConfig()
                        LumiBar:RefreshModules()
                    end,
                    order = 2,
                },
                lineBreak1 = {
                    type = "header",
                    name = "Background",
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
                    width = "full",
                    dialogControl = LSM and "LSM30_Statusbar" or nil,
                    values = LSM and LSM:HashTable("statusbar") or { ["Solid"] = "Solid" },
                    get = function(info) return LumiBar.db.profile.bar.backgroundTexture end,
                    set = function(info, value)
                        LumiBar.db.profile.bar.backgroundTexture = value
                        LumiBar:RefreshConfig()
                    end,
                    order = 6,
                },
                lineBreak2 = {
                    type = "header",
                    name = "Font",
                    order = 10,
                },
                fontFace = {
                    name = "Font Face",
                    type = "select",
                    width = "full",
                    dialogControl = LSM and "LSM30_Font" or nil,
                    values = LSM and LSM:HashTable("font") or { ["Arial Narrow"] = "Arial Narrow" },
                    get = function(info) return LumiBar.db.profile.general.font.face end,
                    set = function(info, value)
                        LumiBar.db.profile.general.font.face = value
                        LumiBar:RefreshModules()
                    end,
                    order = 11,
                },
                fontSize = {
                    name = "Font Size",
                    type = "range",
                    width = "full",
                    min = 6, max = 32, step = 1,
                    get = function(info) return LumiBar.db.profile.general.font.size end,
                    set = function(info, value)
                        LumiBar.db.profile.general.font.size = value
                        LumiBar:RefreshModules()
                    end,
                    order = 12,
                },
                fontOutline = {
                    name = "Font Outline",
                    type = "select",
                    width = "full",
                    values = { ["NONE"] = "None", ["OUTLINE"] = "Outline", ["THICKOUTLINE"] = "Thick Outline", ["MONOCHROME"] = "Monochrome" },
                    get = function(info) return LumiBar.db.profile.general.font.outline end,
                    set = function(info, value)
                        LumiBar.db.profile.general.font.outline = value
                        LumiBar:RefreshModules()
                    end,
                    order = 13,
                },
                primaryColor = {
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
                    order = 14,
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
                    order = 15,
                },
            },
        },
    },
}

local function UpdateModuleOptions()
    local sortedNames = {}
    for mName in pairs(LumiBar.Modules) do
        table.insert(sortedNames, mName)
    end
    table.sort(sortedNames, function(a, b)
        if a == "General" then return true end
        if b == "General" then return false end
        return a < b
    end)

    local moduleOrder = 10
    for _, mName in ipairs(sortedNames) do
        local module = LumiBar.Modules[mName]
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

            -- Add as its own tab
            moduleOpts.order = moduleOrder
            options.args[mName] = moduleOpts
            moduleOrder = moduleOrder + 1
        end
    end
end

-- Initial population
function LumiBar:InitOptions()
    UpdateModuleOptions()
    LT4:RegisterModuleOptions("LumiBar", options)
end
