local FQoL = LibStub("AceAddon-3.0"):GetAddon("FQoL")
local Module = FQoL:NewModule("HelloWorld", "AceEvent-3.0")

Module.description = "Prints a friendly greeting in chat upon login and loading screens to verify the addon is working."

function Module:OnInitialize()
    FQoL:RegisterModuleOptions(self:GetName(), {
        type = "toggle",
        name = self:GetName(),
        desc = self.description,
        descStyle = "tooltip",
        get = function() return FQoL:GetModuleEnabled(self:GetName()) end,
        set = function(_, val) FQoL:SetModuleEnabled(self:GetName(), val) end,
    })

    if not FQoL:GetModuleEnabled(self:GetName()) then
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