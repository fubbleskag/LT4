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
                order = 1,
            },
            showSpec2 = {
                name = "Show Loot Spec",
                type = "toggle",
                order = 2,
            },
            showLoadout = {
                name = "Show Loadout Name",
                type = "toggle",
                order = 3,
            },
        }
    }
    LumiBar:RegisterModuleOptions("SpecSwitch", options)
end

function Spec:UpdateStatus()
    local specIndex = GetSpecialization()
    local str = "No Spec"
    
    if specIndex then
        local id, name, _, icon = GetSpecializationInfo(specIndex)
        local lootSpec = GetLootSpecialization()
        
        str = ""
        if self.db.showSpec1 then
            str = name
        end
        
        if self.db.showSpec2 and lootSpec > 0 then
            local _, lootName = GetSpecializationInfoByID(lootSpec)
            if lootName then
                str = (str ~= "" and str .. " " or "") .. "(" .. lootName .. ")"
            end
        end
        
        if self.db.showLoadout then
            local configID = C_ClassTalents.GetActiveConfigID()
            if configID then
                local configInfo = C_Traits.GetConfigInfo(configID)
                if configInfo and configInfo.name ~= "" then
                    str = (str ~= "" and str .. " - " or "") .. configInfo.name
                end
            end
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

function Spec:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.SpecSwitch
    
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, slotFrame, "BackdropTemplate")
        self.text = self.frame:CreateFontString(nil, "OVERLAY")
        
        self.frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        self.frame:RegisterEvent("PLAYER_LOOT_SPEC_UPDATED")
        self.frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
        self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        self.frame:SetScript("OnEvent", function() self:UpdateStatus() end)
        
        self.frame:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then
                if not InCombatLockdown() then
                    ToggleTalentFrame()
                end
            elseif button == "RightButton" then
                -- Simplified cycle: active -> spec1 -> spec2 -> ...
            end
        end)
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
    
    Utils:SetTooltip(self.frame, "Specialization", {
        "|cffFFFFFFLeft Click:|r Toggle Talents",
        "|cffFFFFFFRight Click:|r Change Loot Spec"
    })
end
