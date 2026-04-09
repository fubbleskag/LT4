local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
local Utils = LumiBar.Utils

local Spec = {}
LumiBar:RegisterModule("SpecSwitch", Spec)

function Spec:Init()
    self.db = LumiBar.db.profile.modules.SpecSwitch
    
    local options = {
        name = "SpecSwitch",
        type = "group",
        get = function(info) return self.db[info[#info]] end,
        set = function(info, value) 
            self.db[info[#info]] = value
            self:Refresh()
            self:UpdateStatus()
        end,
        args = {
            showSpec1 = {
                name = "Show Active Spec",
                type = "toggle",
                width = "full",
                order = 1,
            },
            showSpec2 = {
                name = "Show Loot Spec",
                type = "toggle",
                width = "full",
                order = 2,
            },
            showLoadout = {
                name = "Show Loadout Name",
                type = "toggle",
                width = "full",
                order = 3,
            },
        }
    }
    LumiBar:RegisterModuleOptions("SpecSwitch", options)
end

function Spec:UpdateStatus()
    local specIndex = GetSpecialization()
    local str = ""
    
    if specIndex then
        local specID, name, _, icon = GetSpecializationInfo(specIndex)
        local lootSpec = GetLootSpecialization()
        
        local activeLoadoutName = nil
        if self.db.showLoadout then
            local configID = C_ClassTalents.GetLastSelectedSavedConfigID(specID)
            if configID then
                if C_ClassTalents.GetStarterBuildActive() then
                    activeLoadoutName = "Starter Build"
                else
                    local configInfo = C_Traits.GetConfigInfo(configID)
                    if configInfo then
                        activeLoadoutName = (configInfo.name ~= "") and configInfo.name or "Unnamed Loadout"
                    end
                end
            end
        end

        if self.db.showSpec1 then
            str = name
        end
        
        if self.db.showSpec2 and lootSpec > 0 then
            local _, lootName = GetSpecializationInfoByID(lootSpec)
            if lootName then
                local accent = "|cff" .. Utils:GetAccentColorHex()
                str = (str ~= "" and str .. " " or "") .. accent .. "(" .. lootName .. ")|r"
            end
        end

        if self.db.showLoadout then
            local loadoutText = activeLoadoutName or "No Loadout"
            str = (str ~= "" and str .. " - " or "") .. loadoutText
        end
    end
    
    if str == "" then str = "Spec" end
    self.text:SetText(str)
    self:UpdateWidth()
end

function Spec:UpdateWidth()
    if not self.text then return end
    local textW = self.text:GetStringWidth()
    Utils:UpdateModuleWidth(self, textW + 16, function() self:UpdateWidth() end)
end

function Spec:GetSpecItems()
    local items = {}
    local currentSpec = GetSpecialization()
    for i = 1, GetNumSpecializations() do
        local id, name, _, icon = GetSpecializationInfo(i)
        table.insert(items, {
            name = name,
            isActive = (i == currentSpec),
            type = "macro",
            macrotext = "/run C_SpecializationInfo.SetSpecialization(" .. i .. ")",
        })
    end
    return items
end

function Spec:LoadConfig(configID)
    if InCombatLockdown() then return end
    
    -- Ensure Blizzard ClassTalentUI is loaded
    if not _G.PlayerSpellsFrame then
        if _G.PlayerSpellsFrame_LoadUI then
            _G.PlayerSpellsFrame_LoadUI()
        else
            C_AddOns.LoadAddOn("Blizzard_ClassTalentUI")
        end
    end

    if _G.PlayerSpellsFrame and _G.PlayerSpellsFrame.TalentsFrame and _G.PlayerSpellsFrame.TalentsFrame.LoadConfigByPredicate then
        _G.PlayerSpellsFrame.TalentsFrame:LoadConfigByPredicate(function(_, id) 
            return id == configID 
        end)
    else
        -- Fallback to direct API if UI logic not reachable
        if configID == (Constants.TraitConsts.STARTER_BUILD_TRAIT_CONFIG_ID or -1) then
            C_ClassTalents.SetStarterBuildActive(true)
        else
            C_ClassTalents.LoadConfig(configID, true)
        end
    end
end

function Spec:GetLoadoutItems()
    local items = {}
    local specIndex = GetSpecialization()
    if not specIndex then return items end
    local specID = GetSpecializationInfo(specIndex)
    
    local currentConfigID = C_ClassTalents.GetLastSelectedSavedConfigID(specID)
    local isStarterActive = C_ClassTalents.GetStarterBuildActive()
    local configIDs = C_ClassTalents.GetConfigIDsBySpecID(specID)
    
    local path = "LibStub('AceAddon-3.0'):GetAddon('LT4'):GetModule('LumiBar').Modules['SpecSwitch']"

    for _, configID in ipairs(configIDs) do
        local configInfo = C_Traits.GetConfigInfo(configID)
        if configInfo then
            local name = configInfo.name ~= "" and configInfo.name or "Unnamed Loadout"
            table.insert(items, {
                name = name,
                isActive = (configID == currentConfigID and not isStarterActive),
                type = "macro",
                macrotext = "/lon " .. name,
            })
        end
    end

    if C_ClassTalents.GetHasStarterBuild() then
        table.insert(items, {
            name = "Starter Build",
            isActive = isStarterActive,
            type = "macro",
            macrotext = "/lon Starter Build",
        })
    end
    return items
end

function Spec:GetLootItems()
    local items = {}
    local currentLoot = GetLootSpecialization()
    for i = 1, GetNumSpecializations() do
        local id, name, _, icon = GetSpecializationInfo(i)
        table.insert(items, {
            name = name,
            isActive = (id == currentLoot),
            type = "macro",
            macrotext = "/run SetLootSpecialization(" .. id .. ")",
        })
    end
    table.insert(items, {
        name = "Current Specialization",
        isActive = (currentLoot == 0),
        type = "macro",
        macrotext = "/run SetLootSpecialization(0)",
    })
    return items
end

function Spec:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.SpecSwitch
    
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, slotFrame, "BackdropTemplate")
        self.text = self.frame:CreateFontString(nil, "OVERLAY")
        
        self.frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        self.frame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
        self.frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
        self.frame:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED")
        self.frame:RegisterEvent("PLAYER_TALENT_UPDATE")
        self.frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
        self.frame:RegisterEvent("ACTIVE_COMBAT_CONFIG_CHANGED")
        self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.frame:SetScript("OnEvent", function() 
            C_Timer.After(0.1, function() self:UpdateStatus() end)
        end)
        
        self.frame:SetScript("OnMouseDown", function(_, button)
            if InCombatLockdown() then return end
            local direction = (LumiBar.db.profile.bar.position == "BOTTOM") and "UP" or "DOWN"
            
            if button == "LeftButton" then
                if IsShiftKeyDown() then
                    LumiBar.SecureFlyout:ShowMenu(self.frame, self:GetLootItems(), direction)
                else
                    LumiBar.SecureFlyout:ShowMenu(self.frame, self:GetSpecItems(), direction)
                end
            elseif button == "RightButton" then
                LumiBar.SecureFlyout:ShowMenu(self.frame, self:GetLoadoutItems(), direction)
            end
        end)

        self.frame:SetScript("OnEnter", function(f)
            local position = LumiBar.db.profile.bar.position or "BOTTOM"
            local anchor = (position == "BOTTOM") and "ANCHOR_TOP" or "ANCHOR_BOTTOM"
            GameTooltip:SetOwner(f, anchor)
            GameTooltip:ClearLines()
            local r, g, b = Utils:GetAccentColor()
            GameTooltip:AddLine("Specialization & Loadout", r, g, b)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffFFFFFFLeft Click:|r Change Specialization", 0, 1, 0)
            GameTooltip:AddLine("|cffFFFFFFRight Click:|r Change Loadout", 0, 1, 0)
            GameTooltip:AddLine("|cffFFFFFFShift+Left Click:|r Change Loot Spec", 0, 1, 0)
            GameTooltip:Show()
        end)
        self.frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    
    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:Show()
    self:Refresh(slotFrame)
    self:UpdateStatus()
end

function Spec:Refresh(slotFrame)
    if not self.text then return end
    slotFrame = slotFrame or self.frame:GetParent()
    if not slotFrame then return end
    
    self.frame:SetHeight(slotFrame:GetHeight())
    
    Utils:SetFont(self.text)
    Utils:ApplyBackground(self.frame, self.db)
    
    self.text:ClearAllPoints()
    self.text:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
end
