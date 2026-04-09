local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:NewModule("LumiBar", "AceEvent-3.0", "AceConsole-3.0", "AceTimer-3.0")
LumiBar.Data = {} -- Will be populated by Data.lua if needed, but we'll refactor Data.lua too

-- Performance: Cache common lookups
local pairs = pairs
local ipairs = ipairs
local type = type
local pcall = pcall
local select = select
local table_insert = table.insert
local math_ceil = math.ceil
local math_max = math.max
local math_modf = math.modf
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown
local StaticPopup_Show = StaticPopup_Show
local C_Timer = C_Timer

LumiBar.Modules = {}

function LumiBar:RegisterModule(name, module)
    self.Modules[name] = module
end

function LumiBar:OnInitialize()
    if not LT4.db then return end
    
    -- Base defaults shared by all modules
    local moduleDefaultsBase = {
        background = { enabled = false, color = { r = 0, g = 0, b = 0, a = 0.5 }, texture = "Solid" },
    }

    -- Default Settings
    local defaults = {
        profile = {
            bar = {
                position = "BOTTOM",
                height = 30,
                yOffset = 0,
                backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
                useClassColor = false,
                backgroundTexture = "Solid",
            },
            general = {
                font = {
                    face = "Arial Narrow",
                    size = 12,
                    color = { r = 1, g = 1, b = 1, a = 1 },
                    outline = "OUTLINE",
                },
                accentColor = { r = 0, g = 0.8, b = 1, a = 1 },
            },
            minimap = { hide = false },
            layoutV2 = {
                Left = {
                    Far = {},
                    Near = {},
                },
                Right = {
                    Near = {},
                    Far = {},
                },
            },
            modules = {
                Time = {
                    timeFormat = "12",
                    colorType = "PRIMARY",
                    overrideFontFace = false, fontFace = "Arial Narrow",
                    overrideFontSize = false, fontSize = 12,
                    textOffset = 1, flashColon = true, flashOnInvite = true,
                },
                System = {
                    showFPS = true,
                    showMS = true,
                    showCPU = false,
                    showMEM = false,
                },

                DataBar = {
                    mode = "auto", icon = "", iconFontSize = 18, infoEnabled = true,
                    infoFontSize = 17, infoOffset = 13, infoUseAccent = true, showCompletedXP = false,
                    showIcon = true, barHeight = 10, barOffset = 0, textDisplay = "PERCENT",
                },
                Profession = {
                    useUppercase = true, selectedProf1 = 1, selectedProf2 = 1, iconFontSize = 18,
                    abbreviate = false, limitChar = 16, showIcons = true, showBars = true,
                    barHeight = 2, barOffset = -4, barSpacing = 4,
                },
                Currency = {
                    icon = "", iconFontSize = 18, displayedCurrency = "GOLD",
                    enabledCurrencies = { [3383]=true, [3347]=true, [3345]=true, [3343]=true, [3341]=true, [3316]=true, [3028]=true },
                    showIcon = true, showSmall = true, showBagSpace = true, useGoldColors = true,
                },
                Volume = { showIcon = true, useUppercase = true, textColor = "GREEN", icon = "", iconColor = false, iconFontSize = 18 },
                Hearthstone = {
                    showIcon = true, iconFontSize = 18, cooldownEnabled = true, cooldownFontSize = 18,
                    primaryHS = "item:6948", hiddenPortals = {}, hiddenExpansions = {}, showSeasonPortals = true,
                },
                Durability = {
                    icon = "", iconColor = false, iconFontSize = 18, repairMount = 460, textColor = true,
                    textColorFadeFromNormal = true, showIcon = true, showPerc = true, showItemLevel = true,
                    itemLevelShort = true, animateLow = true, animateThreshold = 20, clickButton = "Left",
                },
                SpecSwitch = {
                    useUppercase = true, showIcons = true, showSpec1 = true, showSpec2 = false,
                    showLoadout = true, iconFontSize = 18, infoEnabled = true, infoShowIcon = false,
                    infoIcon = "", infoFontSize = 12, infoOffset = 18, infoUseAccent = true,
                },
                MicroMenu = {
                    showCharacter = true,
                    showProfessions = true,
                    showPlayerSpells = true,
                    showAchievements = true,
                    showQuests = true,
                    showGuild = true,
                    showLFD = true,
                    showCollections = true,
                    showEJ = true,
                    showStore = true,
                    showMenu = true,
                    autoSize = true,
                    iconSize = 20,
                    spacing = 2,
                },
            }
        },
        global = { goldData = {} }
    }

    -- Optimization: Inject base defaults efficiently
    for _, mData in pairs(defaults.profile.modules) do
        for k, v in pairs(moduleDefaultsBase) do
            if mData[k] == nil then mData[k] = v end
        end
    end
    
    self.db = LT4.db:RegisterNamespace("LumiBar", defaults)
    self.defaults = defaults
    
    -- First Run Population
    if not self.db.global.firstRunCompleted then
        self.db.profile.layoutV2 = {
            Left = {
                Far = {"System", "Durability"},
                Near = {},
            },
            Right = {
                Near = {"SpecSwitch", "Profession"},
                Far = {"Hearthstone", "Currency"},
            },
        }
        self.db.global.firstRunCompleted = true
    end

    -- Init Modules
    for _, module in pairs(self.Modules) do
        if module.Init then pcall(module.Init, module) end
    end
    
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    if self.InitOptions then self:InitOptions() end

    StaticPopupDialogs["LT4_LUMIBAR_RELOAD_UI"] = {
        text = "|cff00ccffLumiBar|r: A UI reload is required to apply changes. Reload now?",
        button1 = "Reload", button2 = "Later",
        OnAccept = function() ReloadUI() end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }

    if not LT4:GetModuleEnabled(self:GetName()) then self:SetEnabledState(false) end
end

function LumiBar:RegisterModuleOptions(name, options)
    -- Options are handled in Options.lua now via LT4:RegisterModuleOptions
    if not self.moduleOptions then self.moduleOptions = {} end
    self.moduleOptions[name] = options
end

function LumiBar:OnEnable()
    self:ConstructBar()
    self:RefreshModules()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        self:RefreshConfig()
        -- Staggered refreshes to ensure layout settles after all modules and fonts load
        C_Timer.After(0.5, function() self:RefreshConfig() end)
        C_Timer.After(2.0, function() self:RefreshConfig() end)
        C_Timer.After(5.0, function() self:RefreshConfig() end)
    end)
    self:RegisterEvent("DISPLAY_SIZE_CHANGED", "RefreshConfig")
    self:RegisterEvent("UI_SCALE_CHANGED", "RefreshConfig")
end

function LumiBar:ColorGradient(perc, ...)
    if perc >= 1 then
        local r, g, b = select(select("#", ...) - 2, ...)
        return r, g, b
    elseif perc <= 0 then
        return ...
    end
    local num = select("#", ...) / 3
    local segment, relperc = math_modf(perc * (num - 1))
    local r1, g1, b1, r2, g2, b2 = select((segment * 3) + 1, ...)
    return r1 + (r2 - r1) * relperc, g1 + (g2 - g1) * relperc, b1 + (b2 - b1) * relperc
end

function LumiBar:RefreshConfig()
    if InCombatLockdown() then
        self.needsRefresh = true
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    if not self.bar then return end
    self:ConstructBar()
    self:RefreshModules()
end

function LumiBar:OnDisable()
    for _, module in pairs(self.Modules) do
        if module.Disable then pcall(module.Disable, module) end
    end
    
    if self.bar then self.bar:Hide() end
    for _, module in pairs(self.Modules) do
        if module.frame then
            module.frame:Hide()
            module.frame:SetParent(nil)
        end
    end
    self:UnregisterAllEvents()
end

function LumiBar:PLAYER_REGEN_ENABLED()
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    if self.needsRefresh then
        self.needsRefresh = false
        self:RefreshConfig()
    end
end

function LumiBar:OpenOptions()
    LT4:OpenOptions() -- Open main LT4 options, LumiBar will be there
end

function LumiBar:ConstructBar()
    if not self.db then return end
    if not self.bar then self.bar = CreateFrame("Frame", "LT4_LumiBarMain", UIParent, "BackdropTemplate") end
    
    local barHeight = self.db.profile.bar.height
    self.bar:SetHeight(barHeight)
    self.bar:ClearAllPoints()
    
    local yOffset = self.db.profile.bar.yOffset
    if self.db.profile.bar.position == "BOTTOM" then
        self.bar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, yOffset)
        self.bar:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, yOffset)
    else
        self.bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, yOffset)
        self.bar:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", 0, yOffset)
    end
    
    self.bar:SetBackdrop({
        bgFile = LibStub("LibSharedMedia-3.0"):Fetch("statusbar", self.db.profile.bar.backgroundTexture),
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    LumiBar.Utils:ApplyBackground(self.bar)

    if not self.Zones then self.Zones = {} end
    local zoneNames = {"FarLeft", "NearLeft", "Center", "NearRight", "FarRight"}
    for _, zName in ipairs(zoneNames) do
        if not self.Zones[zName] then self.Zones[zName] = CreateFrame("Frame", "LT4_LumiBarZone"..zName, self.bar) end
        local zone = self.Zones[zName]
        zone:SetHeight(barHeight)
        zone:ClearAllPoints()
        
        if zName == "FarLeft" then
            zone:SetPoint("LEFT", self.bar, "LEFT", 10, 0)
        elseif zName == "FarRight" then
            zone:SetPoint("RIGHT", self.bar, "RIGHT", -10, 0)
        elseif zName == "Center" then
            zone:SetPoint("CENTER", self.bar, "CENTER", 0, 0)
        end
    end
    -- Anchor Near zones to Center (must be after all zones are created; UpdateLayout will re-anchor these with proper spacing)
    self.Zones["NearLeft"]:SetPoint("RIGHT", self.Zones["Center"], "LEFT", -10, 0)
    self.Zones["NearRight"]:SetPoint("LEFT", self.Zones["Center"], "RIGHT", 10, 0)
    self.bar:Show()
end

-- Layout Logic
local layoutUpdateTimer = false
function LumiBar:UpdateLayout()
    if not self.db or layoutUpdateTimer then return end
    
    if InCombatLockdown() then
        self.needsRefresh = true
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    layoutUpdateTimer = true
    
    C_Timer.After(0.05, function()
        layoutUpdateTimer = false
        if not self.db or InCombatLockdown() then 
            if InCombatLockdown() then
                self.needsRefresh = true
                self:RegisterEvent("PLAYER_REGEN_ENABLED")
            end
            return 
        end
        
        local spacing = 10
        local layout = self.db.profile.layoutV2
        
        -- 1. Handle Center (Time)
        local centerZone = self.Zones["Center"]
        local timeModule = self.Modules["Time"]
        if timeModule and timeModule.frame then
            timeModule.frame:ClearAllPoints()
            timeModule.frame:SetPoint("CENTER", centerZone, "CENTER", 0, 0)
            centerZone:SetWidth(timeModule.frame:GetWidth() or 50)
        end
        
        -- 2. Position Near Zones relative to Center
        local nearLeftZone = self.Zones["NearLeft"]
        nearLeftZone:ClearAllPoints()
        nearLeftZone:SetPoint("RIGHT", centerZone, "LEFT", -spacing, 0)
        
        local nearRightZone = self.Zones["NearRight"]
        nearRightZone:ClearAllPoints()
        nearRightZone:SetPoint("LEFT", centerZone, "RIGHT", spacing, 0)

        -- 3. Layout modules in each zone
        local zoneMapping = {
            FarLeft = { list = layout.Left.Far, align = "LEFT", float = "RIGHT" },
            NearLeft = { list = layout.Left.Near, align = "RIGHT", float = "LEFT" },
            NearRight = { list = layout.Right.Near, align = "LEFT", float = "RIGHT" },
            FarRight = { list = layout.Right.Far, align = "RIGHT", float = "LEFT" },
        }

        for zName, data in pairs(zoneMapping) do
            local zoneFrame = self.Zones[zName]
            local visibleFrames = {}
            for _, mName in ipairs(data.list) do
                local module = self.Modules[mName]
                if module and module.frame and module.frame:IsShown() then
                    table_insert(visibleFrames, module.frame)
                end
            end
            
            local totalWidth = 0
            local prevFrame = nil
            
            if data.align == "LEFT" then
                for i, mFrame in ipairs(visibleFrames) do
                    mFrame:ClearAllPoints()
                    if i == 1 then
                        mFrame:SetPoint("LEFT", zoneFrame, "LEFT", 0, 0)
                    else
                        mFrame:SetPoint("LEFT", prevFrame, "RIGHT", spacing, 0)
                    end
                    totalWidth = totalWidth + (mFrame:GetWidth() or 0) + (i > 1 and spacing or 0)
                    prevFrame = mFrame
                end
            else -- RIGHT align
                for i, mFrame in ipairs(visibleFrames) do
                    mFrame:ClearAllPoints()
                    if i == 1 then
                        mFrame:SetPoint("RIGHT", zoneFrame, "RIGHT", 0, 0)
                    else
                        mFrame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
                    end
                    totalWidth = totalWidth + (mFrame:GetWidth() or 0) + (i > 1 and spacing or 0)
                    prevFrame = mFrame
                end
            end
            zoneFrame:SetWidth(math_max(totalWidth, 1))
        end
    end)
end

function LumiBar:RefreshModules()
    if not self.db then return end

    local active = { ["Time"] = "Center" }
    local layout = self.db.profile.layoutV2
    for _, mName in ipairs(layout.Left.Far) do active[mName] = "FarLeft" end
    for _, mName in ipairs(layout.Left.Near) do active[mName] = "NearLeft" end
    for _, mName in ipairs(layout.Right.Near) do active[mName] = "NearRight" end
    for _, mName in ipairs(layout.Right.Far) do active[mName] = "FarRight" end

    for mName, module in pairs(self.Modules) do
        if not active[mName] then
            if module.Disable then pcall(module.Disable, module) end
            if module.frame then
                module.frame:Hide()
                module.frame:SetParent(nil)
            end
        end
    end

    for mName, zName in pairs(active) do
        local module = self.Modules[mName]
        local frame = self.Zones[zName]
        if module then
            if not module.frame or not module.frame:IsShown() then
                if module.Enable then pcall(module.Enable, module, frame) end
            else
                if module.Refresh then pcall(module.Refresh, module, frame) end
                local update = module.UpdateStatus or module.UpdateCurrency or module.UpdateCounts
                if update then pcall(update, module) end
            end
        end
    end
    self:UpdateLayout()
end
