local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
local Utils = LumiBar.Utils

local MM = {}
LumiBar:RegisterModule("MicroMenu", MM)

local microButtons = {
    { id = "CharacterMicroButton", name = "Character" },
    { id = "ProfessionMicroButton", name = "Professions" },
    { id = "PlayerSpellsMicroButton", name = "Spells/Talents" },
    { id = "AchievementMicroButton", name = "Achievements" },
    { id = "QuestLogMicroButton", name = "Quest Log" },
    { id = "GuildMicroButton", name = "Guild" },
    { id = "LFDMicroButton", name = "LFD" },
    { id = "EJMicroButton", name = "Encounter Journal" },
    { id = "CollectionsMicroButton", name = "Collections" },
    { id = "StoreMicroButton", name = "Shop" },
    { id = "HousingMicroButton", name = "Housing" },
    { id = "MainMenuMicroButton", name = "Main Menu" },
}

function MM:Init()
    self.db = LumiBar.db.profile.modules.MicroMenu
    
    -- Safety check: Ensure buttons table exists
    if not self.db.buttons then self.db.buttons = {} end
    for _, btnInfo in ipairs(microButtons) do
        if self.db.buttons[btnInfo.id] == nil then
            self.db.buttons[btnInfo.id] = true
        end
    end
    
    local options = {
        name = "MicroMenu",
        type = "group",
        args = {
            iconSpacing = {
                name = "Icon Spacing",
                type = "range",
                min = -20, max = 20, softMin = -10, softMax = 10, step = 1,
                get = function(info) return self.db.iconSpacing end,
                set = function(info, value) 
                    self.db.iconSpacing = value
                    self:Refresh()
                end,
                order = 1,
            },
            iconSizeGroup = {
                name = "Icon Size",
                type = "group",
                inline = true,
                order = 2,
                args = {
                    useCustomScale = {
                        name = "Use Custom Size",
                        desc = "Override the bar height and set a manual pixel size for micro menu icons.",
                        type = "toggle",
                        get = function(info) return self.db.useCustomScale end,
                        set = function(info, value)
                            self.db.useCustomScale = value
                            self:Refresh()
                        end,
                        order = 1,
                    },
                    iconSize = {
                        name = "Size (px)",
                        type = "range",
                        min = 16, max = 64, step = 1,
                        hidden = function() return not self.db.useCustomScale end,
                        get = function(info) return self.db.iconSize end,
                        set = function(info, value)
                            self.db.iconSize = value
                            self:Refresh()
                        end,
                        order = 2,
                    },
                }
            },
            buttonToggles = {
                name = "Visible Buttons",
                type = "group",
                inline = true,
                order = 10,
                args = {}
            }
        }
    }

    -- Add a toggle for every button
    for i, btnInfo in ipairs(microButtons) do
        options.args.buttonToggles.args[btnInfo.id] = {
            name = btnInfo.name,
            type = "toggle",
            disabled = (btnInfo.id == "MainMenuMicroButton"), -- Always true safety
            get = function(info) return self.db.buttons[btnInfo.id] end,
            set = function(info, value)
                self.db.buttons[btnInfo.id] = value
                self:Refresh()
            end,
            order = i,
        }
    end

    LumiBar:RegisterModuleOptions("MicroMenu", options)
end

function MM:UpdateWidth()
    if not self.frame then return end
    
    local btnHeight
    if self.db.useCustomScale then
        btnHeight = self.db.iconSize or 24
    else
        btnHeight = self.frame:GetHeight()
    end
    
    local btnWidth = btnHeight * 0.75
    local spacing = self.db.iconSpacing or 0
    
    local visibleCount = 0
    for _, btnInfo in ipairs(microButtons) do
        local btn = _G[btnInfo.id]
        if btn and self.db.buttons[btnInfo.id] then
            visibleCount = visibleCount + 1
        end
    end
    
    local totalWidth = (visibleCount * btnWidth) + (math.max(0, visibleCount - 1) * spacing) + 8
    Utils:UpdateModuleWidth(self, totalWidth, nil)
end

function MM:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.MicroMenu
    
    if not self.frame then
        self.frame = CreateFrame("Frame", "LumiBarMicroMenuContainer", slotFrame, "BackdropTemplate")
    end
    
    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:SetAlpha(1)
    self.frame:EnableMouse(true)
    self.frame:Show()
    
    -- Hook buttons to stay in our container ONLY if module is active
    for _, btnInfo in ipairs(microButtons) do
        local btn = _G[btnInfo.id]
        if btn and not btn.__LumiBarHooked then
            hooksecurefunc(btn, "SetParent", function(s, parent)
                local module = LumiBar.Modules["MicroMenu"]
                if module and not module.isDisabling and module.frame and module.frame:IsShown() and module.frame:GetParent() then
                    if parent ~= module.frame then
                        s:SetParent(module.frame)
                    end
                end
            end)
            btn.__LumiBarHooked = true
        end
    end

    self:Refresh(slotFrame)
    self:UpdateWidth()
end

function MM:Disable(slotFrame)
    self.isDisabling = true
    -- 1. Restore buttons to default parent FIRST
    local parent = _G["MicroMenuContainer"]
    if parent then
        for _, btnInfo in ipairs(microButtons) do
            local btn = _G[btnInfo.id]
            if btn then
                pcall(function()
                    btn:SetParent(parent)
                    btn:SetSize(22, 22) -- rough default
                    btn:ClearAllPoints()
                    btn:SetAlpha(1)
                    btn:EnableMouse(true)
                    btn:Show()
                    if btn.Background then btn.Background:SetAlpha(1) end
                    if btn.Shadow then btn.Shadow:SetAlpha(1) end
                    if btn.PushedBackground then btn.PushedBackground:SetAlpha(1) end
                    if btn.OverrideBackground then btn.OverrideBackground:SetAlpha(1) end
                    if btn:GetName() == "HousingMicroButton" then
                        if btn.PortraitMask then btn.PortraitMask:Show() end
                        if btn.Portrait then btn.Portrait:SetAlpha(1) end
                    end
                end)
            end
        end
        -- Trigger Blizzard's layout update while buttons are in parent
        if parent.Layout then pcall(parent.Layout, parent) end
    end

    -- 2. NOW hide our container
    if self.frame then 
        self.frame:Hide()
        self.frame:SetParent(nil)
    end
    self.isDisabling = false
end

function MM:Refresh(slotFrame)
    if not self.frame then return end
    slotFrame = slotFrame or self.frame:GetParent()
    if not slotFrame then return end
    
    -- Aggressively restore container state
    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:SetAlpha(1)
    self.frame:Show()
    self.frame:EnableMouse(true)
    
    Utils:ApplyBackground(self.frame, self.db)
    
    local btnHeight
    if self.db.useCustomScale then
        btnHeight = self.db.iconSize or 24
    else
        btnHeight = slotFrame:GetHeight()
    end
    local btnWidth = btnHeight * 0.75
    local spacing = self.db.iconSpacing or 0
    
    local currentX = 0
    for _, btnInfo in ipairs(microButtons) do
        local btn = _G[btnInfo.id]
        if btn then
            pcall(function()
                if self.db.buttons[btnInfo.id] then
                    btn:SetParent(self.frame)
                    btn:SetSize(btnWidth, btnHeight)
                    btn:ClearAllPoints()
                    btn:SetPoint("LEFT", self.frame, "LEFT", currentX, 0)
                    btn:SetAlpha(1)
                    btn:EnableMouse(true)
                    btn:Show()
                    
                    -- Aggressive Skinning
                    local function hideTextures(obj)
                        if not obj then return end
                        if obj.Background then obj.Background:SetAlpha(0) end
                        if obj.PushedBackground then obj.PushedBackground:SetAlpha(0) end
                        if obj.Shadow then obj.Shadow:SetAlpha(0) end
                        if obj.OverrideBackground then obj.OverrideBackground:SetAlpha(0) end
                        for _, texName in ipairs({"Background", "PushedBackground", "Shadow", "OverrideBackground"}) do
                            if obj[texName] and obj[texName].SetAlpha then obj[texName]:SetAlpha(0) end
                        end
                    end
                    hideTextures(btn)
                    if btn:GetName() == "HousingMicroButton" then
                        if btn.PortraitMask then btn.PortraitMask:Hide() end
                        if btn.Portrait then btn.Portrait:SetAlpha(0) end
                    end
                    
                    currentX = currentX + btnWidth + spacing
                else
                    -- TRUE GHOSTING: Keeps Blizzard code from crashing
                    btn:SetParent(self.frame)
                    btn:SetSize(0.001, 0.001) -- effectively gone
                    btn:SetAlpha(0)
                    btn:EnableMouse(false)
                    btn:Show() 
                end
            end)
        end
    end
    self:UpdateWidth()
end
