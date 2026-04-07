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
            zones = { Left = {}, Center = {}, Right = {} },
            modules = {
                Time = {
                    localTime = true, twentyFour = true, timeFormat = "HH:MM", showRestingAnimation = true,
                    textOffset = 1, useAccent = true, flashColon = true, flashOnInvite = true,
                    infoEnabled = true, infoFontSize = 16, infoOffset = 24, infoUseAccent = true,
                    infoTextDisplayed = { mail = true, date = true, ampm = false },
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
        self.db.profile.zones = {
            Left = {"System", "Durability"},
            Center = {"SpecSwitch", "Time", "Profession"},
            Right = {"Hearthstone", "Currency"},
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
    for _, zName in ipairs({"Left", "Center", "Right"}) do
        if not self.Zones[zName] then self.Zones[zName] = CreateFrame("Frame", "LT4_LumiBarZone"..zName, self.bar) end
        local zone = self.Zones[zName]
        zone:SetHeight(barHeight)
        zone:ClearAllPoints()
        if zName == "Left" then zone:SetPoint("LEFT", self.bar, "LEFT", 10, 0)
        elseif zName == "Right" then zone:SetPoint("RIGHT", self.bar, "RIGHT", -10, 0)
        else zone:SetPoint("CENTER", self.bar, "CENTER", 0, 0) end
    end
    self.bar:Show()
end

-- Optimization: Throttled UpdateZoneLayout
local zoneUpdateTimer = {}
function LumiBar:UpdateZoneLayout(zName)
    if not self.db or zoneUpdateTimer[zName] then return end
    
    if InCombatLockdown() then
        self.needsRefresh = true
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    zoneUpdateTimer[zName] = true
    
    C_Timer.After(0.05, function()
        zoneUpdateTimer[zName] = nil
        if not self.db then return end
        local zoneFrame = self.Zones[zName]
        local moduleList = self.db.profile.zones[zName]
        if not zoneFrame or not moduleList then return end
        
        local visibleModules = {}
        for _, mName in ipairs(moduleList) do
            local module = self.Modules[mName]
            if module and module.frame and module.frame:IsShown() then
                table_insert(visibleModules, module.frame)
            end
        end
        
        local prevFrame, totalWidth, spacing = nil, 0, 10
        for i, mFrame in ipairs(visibleModules) do
            local mWidth = mFrame:GetWidth() or 0
            totalWidth = totalWidth + mWidth + (i > 1 and spacing or 0)
            mFrame:ClearAllPoints()
            if zName == "Center" then
                local count = #visibleModules
                if count % 2 == 1 then
                    if i == math_ceil(count / 2) then mFrame:SetPoint("CENTER", zoneFrame, "CENTER", 0, 0) end
                else
                    if i == count / 2 then mFrame:SetPoint("RIGHT", zoneFrame, "CENTER", -spacing/2, 0)
                    elseif i == (count / 2) + 1 then mFrame:SetPoint("LEFT", zoneFrame, "CENTER", spacing/2, 0) end
                end
            else
                if i == 1 then mFrame:SetPoint("LEFT", zoneFrame, "LEFT", 0, 0)
                else mFrame:SetPoint("LEFT", prevFrame, "RIGHT", spacing, 0) end
            end
            prevFrame = mFrame
        end

        if zName == "Center" and #visibleModules > 0 then
            local count = #visibleModules
            if count % 2 == 1 then
                local mid = math_ceil(count / 2)
                for i = mid - 1, 1, -1 do visibleModules[i]:SetPoint("RIGHT", visibleModules[i+1], "LEFT", -spacing, 0) end
                for i = mid + 1, count do visibleModules[i]:SetPoint("LEFT", visibleModules[i-1], "RIGHT", spacing, 0) end
            else
                local midL, midR = count / 2, (count / 2) + 1
                for i = midL - 1, 1, -1 do visibleModules[i]:SetPoint("RIGHT", visibleModules[i+1], "LEFT", -spacing, 0) end
                for i = midR + 1, count do visibleModules[i]:SetPoint("LEFT", visibleModules[i-1], "RIGHT", spacing, 0) end
            end
        end
        zoneFrame:SetWidth(math_max(totalWidth, 1))
    end)
end

function LumiBar:RefreshModules()
    if not self.db then return end
    local active = {}
    for zoneName, list in pairs(self.db.profile.zones) do
        for _, mName in ipairs(list) do active[mName] = zoneName end
    end

    for mName, module in pairs(self.Modules) do
        if not active[mName] then
            if module.Disable then pcall(module.Disable, module) end
        end
    end

    for mName, module in pairs(self.Modules) do
        if not active[mName] then
            if module.frame then
                module.frame:Hide()
                module.frame:SetParent(nil)
            end
        end
    end

    for zoneName, _ in pairs(self.db.profile.zones) do
        local list = self.db.profile.zones[zoneName]
        local frame = self.Zones[zoneName]
        for _, mName in ipairs(list) do
            local module = self.Modules[mName]
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
        self:UpdateZoneLayout(zoneName)
    end
end
