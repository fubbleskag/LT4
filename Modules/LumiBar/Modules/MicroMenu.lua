local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
local Utils = LumiBar.Utils

local MicroMenu = {}
LumiBar:RegisterModule("MicroMenu", MicroMenu)

local blizzardButtons = {
    "CharacterMicroButton",
    "ProfessionMicroButton",
    "PlayerSpellsMicroButton",
    "AchievementMicroButton",
    "QuestLogMicroButton",
    "GuildMicroButton",
    "LFDMicroButton",
    "EJMicroButton",
    "CollectionsMicroButton",
    "StoreMicroButton",
    "MainMenuMicroButton",
    "HelpMicroButton",
}

local function SetBlizzardMicroMenuAlpha(alpha)
    if _G.MicroMenuContainer then
        _G.MicroMenuContainer:SetAlpha(alpha)
    end
    local buttons = _G.MICRO_BUTTONS or blizzardButtons
    for _, name in ipairs(buttons) do
        local btn = _G[name]
        if btn then
            btn:SetAlpha(alpha)
        end
    end
end

-- Performance: Cache common lookups
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local ipairs = ipairs
local pairs = pairs
local table_insert = table.insert
local InCombatLockdown = InCombatLockdown

-- Updated buttons to match modern Retail HUD names and Atlases
local buttons = {
    { id = "Character",    name = CHARACTER_BUTTON or "Character",           func = function() ToggleCharacter("PaperDollFrame") end, atlas = "UI-HUD-MicroMenu-Character-Up", binding = "TOGGLECHARACTER0" },
    { id = "Professions",  name = PROFESSIONS_BUTTON or "Professions",       func = function() ToggleProfessionsBook() end,           atlas = "UI-HUD-MicroMenu-Professions-Up", binding = "TOGGLEPROFESSIONBOOK" },
    { id = "PlayerSpells", name = TALENTS_BUTTON or "Spells & Talents",       func = function() TogglePlayerSpellsFrame() end,         atlas = "UI-HUD-MicroMenu-SpecTalents-Up", binding = "TOGGLETALENTS" },
    { id = "Achievements", name = ACHIEVEMENT_BUTTON or "Achievements",         func = function() ToggleAchievementFrame() end,          atlas = "UI-HUD-MicroMenu-Achievements-Up", binding = "TOGGLEACHIEVEMENT" },
    { id = "Quests",       name = QUESTLOG_BUTTON or "Quests",            func = function() ToggleQuestLog() end,                  atlas = "UI-HUD-MicroMenu-Questlog-Up", binding = "TOGGLEQUESTLOG" },
    { id = "Guild",        name = GUILD_BUTTON or "Guild",               func = function() ToggleGuildFrame() end,                atlas = "UI-HUD-MicroMenu-GuildCommunities-GuildColor-Up", binding = "TOGGLEGUILDTAB" },
    { id = "LFD",          name = DUNGEONS_BUTTON or LOOKINGFORGROUP or "Group Finder",            func = function() PVEFrame_ToggleFrame() end,            atlas = "UI-HUD-MicroMenu-Groupfinder-Up", binding = "TOGGLEGROUPFINDER" },
    { id = "Collections",  name = COLLECTIONS or "Collections",                func = function() ToggleCollectionsJournal() end,        atlas = "UI-HUD-MicroMenu-Collections-Up", binding = "TOGGLECOLLECTIONS" },
    { id = "EJ",           name = ADVENTURE_JOURNAL or ENCOUNTER_JOURNAL or "Encounter Journal",          func = function() ToggleEncounterJournal() end,          atlas = "UI-HUD-MicroMenu-AdventureGuide-Up", binding = "TOGGLEENCOUNTERJOURNAL" },
    { id = "Store",        name = BLIZZARD_STORE or "Store",             func = function() ToggleStoreUI() end,                   atlas = "UI-HUD-MicroMenu-Shop-Up", binding = "TOGGLESTORE" },
    { id = "Menu",         name = MAINMENU_BUTTON or "Main Menu",            func = function() ToggleGameMenu() end,                  atlas = "UI-HUD-MicroMenu-GameMenu-Up", binding = "TOGGLEGAMEMENU" },
}

function MicroMenu:Init()
    self.db = LumiBar.db.profile.modules.MicroMenu
    
    -- Set defaults if missing
    if self.db.useAccent == nil then self.db.useAccent = true end
    if not self.db.customColor then self.db.customColor = { r = 1, g = 0.8, b = 0 } end -- Default to a gold-ish color if not using accent

    local options = {
        name = "Micro Menu",
        type = "group",
        get = function(info) return self.db[info[#info]] end,
        set = function(info, value) 
            self.db[info[#info]] = value
            self:Refresh()
        end,
        args = {
            displayGroup = {
                name = "Display Elements",
                type = "group",
                inline = true,
                order = 1,
                args = {
                    autoSize = {
                        name = "Auto Size to Bar",
                        desc = "Match the height of the LumiBar automatically.",
                        type = "toggle",
                        order = 1,
                    },
                    iconSize = {
                        name = "Custom Icon Size",
                        type = "range",
                        min = 10, max = 100, step = 1,
                        hidden = function() return self.db.autoSize end,
                        order = 2,
                    },
                    spacing = { name = "Spacing", type = "range", min = -10, max = 20, step = 1, order = 3 },
                }
            },
            colorGroup = {
                name = "Colors",
                type = "group",
                inline = true,
                order = 1.5,
                args = {
                    useAccent = {
                        name = "Use Global Accent Color",
                        desc = "Use the global accent color for keyboard shortcuts.",
                        type = "toggle",
                        order = 1,
                    },
                    customColor = {
                        name = "Custom Color",
                        desc = "Custom color for keyboard shortcuts if not using global accent.",
                        type = "color",
                        hasAlpha = false,
                        hidden = function() return self.db.useAccent end,
                        get = function(info)
                            local c = self.db.customColor or { r = 1, g = 1, b = 1 }
                            return c.r, c.g, c.b
                        end,
                        set = function(info, r, g, b)
                            self.db.customColor = { r = r, g = g, b = b }
                            self:Refresh()
                        end,
                        order = 2,
                    },
                }
            },
            buttonsGroup = {
                name = "Buttons",
                type = "group",
                inline = true,
                order = 2,
                args = {}
            }
        }
    }

    for i, btn in ipairs(buttons) do
        options.args.buttonsGroup.args["show"..btn.id] = {
            name = btn.name or btn.id,
            type = "toggle",
            order = i,
        }
    end

    LumiBar:RegisterModuleOptions("MicroMenu", options)
end

function MicroMenu:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.MicroMenu
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, slotFrame, "BackdropTemplate")
        self.btns = {}
        for i, btnData in ipairs(buttons) do
            local btn = CreateFrame("Button", nil, self.frame)
            
            btn.icon = btn:CreateTexture(nil, "ARTWORK")
            btn.icon:SetAllPoints()
            btn.icon:SetAtlas(btnData.atlas)
            
            -- Special handling for Character Portrait
            if btnData.id == "Character" then
                btn.portrait = btn:CreateTexture(nil, "OVERLAY")
                -- Apply padding to match the built-in padding of other micro menu atlases (roughly 5px per side)
                local padding = 5
                btn.portrait:SetPoint("TOPLEFT", btn, "TOPLEFT", padding, -padding)
                btn.portrait:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -padding, padding)
                
                local function UpdatePortrait()
                    SetPortraitTexture(btn.portrait, "player")
                    btn.portrait:SetTexCoord(0.1, 0.9, 0, 1)
                end
                
                btn:RegisterEvent("UNIT_PORTRAIT_UPDATE")
                btn:RegisterEvent("PLAYER_ENTERING_WORLD")
                btn:SetScript("OnEvent", function(s, event, unit)
                    if event == "PLAYER_ENTERING_WORLD" or unit == "player" then
                        UpdatePortrait()
                    end
                end)
                UpdatePortrait()
            end
            
            -- Add highlight texture
            btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            btn.highlight:SetAllPoints()
            btn.highlight:SetAtlas(btnData.atlas)
            btn.highlight:SetBlendMode("ADD")
            btn.highlight:SetAlpha(0.3)

            btn:SetScript("OnClick", function()
                if not InCombatLockdown() then
                    btnData.func()
                end
            end)
            
            btn:SetScript("OnEnter", function(f)
                self:ShowTooltip(f, btnData)
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            
            self.btns[btnData.id] = btn
        end
    end
    
    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:Show()
    self:Refresh(slotFrame)
    SetBlizzardMicroMenuAlpha(0)
end

function MicroMenu:Disable()
    SetBlizzardMicroMenuAlpha(1)
end

function MicroMenu:Refresh(slotFrame)
    if not self.frame then return end
    slotFrame = slotFrame or self.frame:GetParent()
    if not slotFrame then return end
    
    self.frame:SetHeight(slotFrame:GetHeight())
    Utils:ApplyBackground(self.frame, self.db)
    
    local prevBtn = nil
    local totalWidth = 0
    local spacing = self.db.spacing or 0
    
    local iconHeight
    if self.db.autoSize then
        iconHeight = slotFrame:GetHeight()
    else
        iconHeight = self.db.iconSize or 20
    end
    local iconWidth = iconHeight * 0.8
    
    for _, btnData in ipairs(buttons) do
        local btn = self.btns[btnData.id]
        if self.db["show"..btnData.id] then
            btn:Show()
            btn:SetSize(iconWidth, iconHeight)
            btn:ClearAllPoints()
            if not prevBtn then
                btn:SetPoint("LEFT", self.frame, "LEFT", 0, 0)
            else
                btn:SetPoint("LEFT", prevBtn, "RIGHT", spacing, 0)
            end
            totalWidth = totalWidth + iconWidth + (prevBtn and spacing or 0)
            prevBtn = btn
        else
            btn:Hide()
        end
    end
    
    self:UpdateWidth(totalWidth)
end

function MicroMenu:UpdateWidth(width)
    Utils:UpdateModuleWidth(self, width, function() self:Refresh() end)
end

function MicroMenu:ShowTooltip(f, btnData)
    local anchor = (LumiBar.db.profile.bar.position == "BOTTOM") and "ANCHOR_TOP" or "ANCHOR_BOTTOM"
    GameTooltip:SetOwner(f, anchor)
    GameTooltip:ClearLines()
    
    -- Font and Color Logic
    local fontDB = LumiBar.db.profile.general.font
    local LSM = LibStub("LibSharedMedia-3.0")
    local fontFace = LSM:Fetch("font", fontDB.face) or STANDARD_TEXT_FONT
    local fontSize = fontDB.size or 12
    local fontOutline = fontDB.outline or "OUTLINE"
    
    -- Main Text Color
    local textColor = fontDB.color or { r = 1, g = 1, b = 1 }
    
    -- Highlight (Keybind) Color
    local highlightHex
    if self.db.useAccent then
        highlightHex = Utils:GetAccentColorHex()
    elseif self.db.customColor then
        highlightHex = Utils:RGBToHex(self.db.customColor.r, self.db.customColor.g, self.db.customColor.b)
    else
        highlightHex = "ffffff"
    end

    local title = btnData.name
    if btnData.binding then
        local key = GetBindingKey(btnData.binding)
        if key then
            title = title .. " |cff" .. highlightHex .. "(" .. key .. ")|r"
        end
    end
    
    -- We can't easily change the font of the entire tooltip without skinning it, 
    -- but we can set the line text and color.
    GameTooltip:AddLine(title, textColor.r, textColor.g, textColor.b)
    
    -- Apply font to the tooltip line if possible (standard tooltips are limited)
    local line = _G["GameTooltipTextLeft1"]
    if line then
        line:SetFont(fontFace, fontSize, fontOutline)
    end
    
    GameTooltip:Show()
end
