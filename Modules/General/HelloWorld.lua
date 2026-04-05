local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local Module = LT4:NewModule("HelloWorld", "AceEvent-3.0")

Module.description = "Prints a friendly greeting in chat upon login and loading screens to verify the addon is working."

function Module:OnInitialize()
    LT4:RegisterModuleOptions(self:GetName(), {
        type = "toggle",
        name = self:GetName(),
        desc = self.description,
        descStyle = "tooltip",
        get = function() return LT4:GetModuleEnabled(self:GetName()) end,
        set = function(_, val) LT4:SetModuleEnabled(self:GetName(), val) end,
    })

    if not LT4:GetModuleEnabled(self:GetName()) then
        self:SetEnabledState(false)
    end
end

function Module:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "Welcome")
end

function Module:OnDisable()
    self:UnregisterAllEvents()
end

function Module:Welcome()
    self:Print("Welcome to Midnight, Fubbleskag!")
end