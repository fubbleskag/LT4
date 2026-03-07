local FQoL = LibStub("AceAddon-3.0"):GetAddon("FQoL")
local Module = FQoL:NewModule("HelloWorld", "AceEvent-3.0")

-- Set the description here
Module.description = "Prints a friendly greeting in chat upon login and loading screens to verify the addon is working."

function Module:OnInitialize()
    -- Add the toggle to the main options table dynamically
    FQoL.options.args.modules.args[self:GetName()] = {
        type = "toggle",
        name = self:GetName(),
        desc = self.description, -- This pulls the description above
        descStyle = "tooltip",   -- Shows description when hovering
        get = function() return FQoL.db.profile.modules[self:GetName()] end,
        set = function(_, val) 
            FQoL.db.profile.modules[self:GetName()] = val 
            if val then Module:Enable() else Module:Disable() end
        end,
    }

    if not FQoL.db.profile.modules[self:GetName()] then
        self:SetEnabledState(false)
    end
end

function Module:OnEnable()
    print("|cFF00FF00FQoL:|r Hello World module is now active!")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "Welcome")
end

function Module:OnDisable()
    self:UnregisterAllEvents()
end

function Module:Welcome()
    print("Welcome to Midnight, Fubbleskag!")
end