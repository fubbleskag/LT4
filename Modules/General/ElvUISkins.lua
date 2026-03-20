local FQoL = LibStub("AceAddon-3.0"):GetAddon("FQoL")
local Module = FQoL:NewModule("ElvUISkins", "AceEvent-3.0")

Module.description = "Provides ElvUI-style skinning for various third-party addons."

local function SkinPGF()
    if not FQoL.db.profile.elvuiSkins["PremadeGroupsFilter"] then return end
    
    local E, L, V, P, G = unpack(ElvUI)
    local S = E:GetModule('Skins')

    local dialog = _G.PremadeGroupsFilterDialog
    if dialog then
        if not dialog.IsSkinned then
            S:HandleFrame(dialog)
            if dialog.RefreshButton then S:HandleButton(dialog.RefreshButton) end
            if dialog.ResetButton then S:HandleButton(dialog.ResetButton) end
            if dialog.SettingsButton then S:HandleButton(dialog.SettingsButton) end
            if dialog.CloseButton then S:HandleCloseButton(dialog.CloseButton) end
            if dialog.MaximizeMinimizeFrame then S:HandleMaxMinFrame(dialog.MaximizeMinimizeFrame) end
            dialog.IsSkinned = true
        end
    end

    local panels = {
        "PremadeGroupsFilterDungeonPanel",
        "PremadeGroupsFilterRaidPanel",
        "PremadeGroupsFilterArenaPanel",
        "PremadeGroupsFilterRBGPanel",
        "PremadeGroupsFilterRolePanel",
        "PremadeGroupsFilterMiniPanel",
        "PremadeGroupsFilterDelvePanel",
    }

    local function SkinPanelChildren(panel)
        if not panel then return end
        for _, child in ipairs({panel:GetChildren()}) do
            if child.Act and not child.Act.IsSkinned then 
                S:HandleCheckBox(child.Act) 
                child.Act.IsSkinned = true
            end
            if child.Min and not child.Min.IsSkinned then 
                S:HandleEditBox(child.Min) 
                child.Min.IsSkinned = true
            end
            if child.Max and not child.Max.IsSkinned then 
                S:HandleEditBox(child.Max) 
                child.Max.IsSkinned = true
            end
            
            if child.DropDown and not child.DropDown.IsSkinned then
                child.DropDown:StripTextures()
                child.DropDown:CreateBackdrop('Transparent')
                if child.DropDown.Button then
                    S:HandleNextPrevButton(child.DropDown.Button, 'down')
                end
                child.DropDown.IsSkinned = true
            end
            
            if child.SelectAll and not child.SelectAll.IsSkinned then 
                S:HandleButton(child.SelectAll) 
                child.SelectAll.IsSkinned = true
            end
            if child.SelectNone and not child.SelectNone.IsSkinned then 
                S:HandleButton(child.SelectNone) 
                child.SelectNone.IsSkinned = true
            end
            if child.SelectInvert and not child.SelectInvert.IsSkinned then 
                S:HandleButton(child.SelectInvert) 
                child.SelectInvert.IsSkinned = true
            end
            
            -- Recurse for nested groups
            if child.GetChildren then
                SkinPanelChildren(child)
            end
        end
    end

    for _, panelName in ipairs(panels) do
        local panel = _G[panelName]
        if panel then
            SkinPanelChildren(panel)
            
            if panel.Advanced and panel.Advanced.Expression and panel.Advanced.Expression.EditBox then
                if not panel.Advanced.Expression.EditBox.IsSkinned then
                    S:HandleEditBox(panel.Advanced.Expression.EditBox)
                    panel.Advanced.Expression.EditBox.IsSkinned = true
                end
            end
        end
    end

    if _G.UsePGFButton and not _G.UsePGFButton.IsSkinned then
        S:HandleCheckBox(_G.UsePGFButton)
        _G.UsePGFButton.IsSkinned = true
    end
    
    if _G.PremadeGroupsFilterStaticPopup and not _G.PremadeGroupsFilterStaticPopup.IsSkinned then
        S:HandleFrame(_G.PremadeGroupsFilterStaticPopup)
        if _G.PremadeGroupsFilterStaticPopup.Button1 then S:HandleButton(_G.PremadeGroupsFilterStaticPopup.Button1) end
        if _G.PremadeGroupsFilterStaticPopup.Button2 then S:HandleButton(_G.PremadeGroupsFilterStaticPopup.Button2) end
        _G.PremadeGroupsFilterStaticPopup.IsSkinned = true
    end
end

local function SkinBugSack()
    if not FQoL.db.profile.elvuiSkins["BugSack"] then return end
    
    local E, L, V, P, G = unpack(ElvUI)
    local S = E:GetModule('Skins')

    if not Module.BugSackHooksSet then
        if BugSack and BugSack.OpenSack then
            hooksecurefunc(BugSack, "OpenSack", SkinBugSack)
        end
        Module.BugSackHooksSet = true
    end

    local frame = _G.BugSackFrame
    if frame and not frame.IsSkinned then
        S:HandleFrame(frame)
        
        for _, child in ipairs({frame:GetChildren()}) do
            if child:IsObjectType("Button") then
                local point = child:GetPoint()
                if point == "TOPRIGHT" then
                    S:HandleCloseButton(child)
                else
                    S:HandleButton(child)
                end
            elseif child:IsObjectType("EditBox") then
                S:HandleEditBox(child)
            end
        end

        if _G.BugSackTabAll then S:HandleTab(_G.BugSackTabAll) end
        if _G.BugSackTabSession then S:HandleTab(_G.BugSackTabSession) end
        if _G.BugSackTabLast then S:HandleTab(_G.BugSackTabLast) end

        if _G.BugSackScroll then
            S:HandleScrollBar(_G.BugSackScroll.ScrollBar)
            _G.BugSackScroll:CreateBackdrop('Transparent')
        end

        frame.IsSkinned = true
    end
end

local function SkinAuctionator()
    if not FQoL.db.profile.elvuiSkins["Auctionator"] then return end
    
    local E, L, V, P, G = unpack(ElvUI)
    local S = E:GetModule('Skins')

    if not Module.AuctionatorHooksSet then
        if _G.Auctionator and _G.Auctionator.CraftingInfo then
            hooksecurefunc(_G.Auctionator.CraftingInfo, "InitializeProfessionsFrame", SkinAuctionator)
            hooksecurefunc(_G.Auctionator.CraftingInfo, "InitializeCustomerOrdersFrame", SkinAuctionator)
        end
        if _G.AuctionatorAHFrameMixin then
            hooksecurefunc(_G.AuctionatorAHFrameMixin, "OnShow", function()
                C_Timer.After(0.1, SkinAuctionator)
            end)
        end
        if _G.AuctionatorShoppingTabFrameMixin then
            hooksecurefunc(_G.AuctionatorShoppingTabFrameMixin, "OnShow", SkinAuctionator)
        end
        Module.AuctionatorHooksSet = true
    end

    local shoppingFrame = _G.AuctionatorShoppingFrame or (AuctionHouseFrame and AuctionHouseFrame.AuctionatorShoppingTabFrame)
    if shoppingFrame and not shoppingFrame.IsSkinned then
        if shoppingFrame.SearchOptions then
            if shoppingFrame.SearchOptions.SearchString then S:HandleEditBox(shoppingFrame.SearchOptions.SearchString) end
            if shoppingFrame.SearchOptions.SearchButton then S:HandleButton(shoppingFrame.SearchOptions.SearchButton) end
            if shoppingFrame.SearchOptions.MoreButton then S:HandleButton(shoppingFrame.SearchOptions.MoreButton) end
            if shoppingFrame.SearchOptions.AddToListButton then S:HandleButton(shoppingFrame.SearchOptions.AddToListButton) end
            if shoppingFrame.SearchOptions.ResetSearchStringButton then S:HandleCloseButton(shoppingFrame.SearchOptions.ResetSearchStringButton) end
        end
        if shoppingFrame.ExportButton then S:HandleButton(shoppingFrame.ExportButton) end
        if shoppingFrame.ImportButton then S:HandleButton(shoppingFrame.ImportButton) end
        if shoppingFrame.NewListButton then S:HandleButton(shoppingFrame.NewListButton) end
        shoppingFrame.IsSkinned = true
    end

    if _G.AuctionatorTradeSkillSearch then S:HandleButton(_G.AuctionatorTradeSkillSearch) end
    if _G.AuctionatorCraftingInfoProfessionsFrame and _G.AuctionatorCraftingInfoProfessionsFrame.SearchButton then
        S:HandleButton(_G.AuctionatorCraftingInfoProfessionsFrame.SearchButton)
    end
    if _G.AuctionatorCraftingInfoObjectiveTrackerFrame and _G.AuctionatorCraftingInfoObjectiveTrackerFrame.SearchButton then
        S:HandleButton(_G.AuctionatorCraftingInfoObjectiveTrackerFrame.SearchButton)
    end
end

local function SkinMacroToolkit()
    if not FQoL.db.profile.elvuiSkins["MacroToolkit"] then return end
    
    local E, L, V, P, G = unpack(ElvUI)
    local S = E:GetModule('Skins')
    local MT = _G.MacroToolkit
    if not MT then return end

    if not Module.MacroToolkitHooksSet then
        local framesToHook = {"CreateMTFrame", "CreateMTPopup", "CreateSharePopup", "CreateScriptFrame", "CreateRestoreFrame", "CreateCopyFrame", "CreateBindingFrame", "CreateBuilderFrame"}
        for _, funcName in ipairs(framesToHook) do
            if MT[funcName] then
                hooksecurefunc(MT, funcName, function() C_Timer.After(0.01, SkinMacroToolkit) end)
            end
        end
        Module.MacroToolkitHooksSet = true
    end

    if _G.MacroToolkitFrame and not _G.MacroToolkitFrame.IsSkinned then
        S:HandleFrame(_G.MacroToolkitFrame)
        for i = 1, 3 do if _G["MacroToolkitFrameTab" .. i] then S:HandleTab(_G["MacroToolkitFrameTab" .. i]) end end
        _G.MacroToolkitFrame.IsSkinned = true
    end

    if _G.MacroToolkitPopup and not _G.MacroToolkitPopup.IsSkinned then
        S:HandleFrame(_G.MacroToolkitPopup)
        if _G.MacroToolkitPopupScrollScrollBar then S:HandleScrollBar(_G.MacroToolkitPopupScrollScrollBar) end
        _G.MacroToolkitPopup.IsSkinned = true
    end
end

function Module:OnInitialize()
    FQoL.options.args.modules.args[self:GetName()] = {
        type = "group",
        name = "ElvUI Skins",
        desc = self.description,
        order = 10,
        args = {
            enabled = {
                type = "toggle",
                name = "Enable Module",
                order = 1,
                get = function() return FQoL.db.profile.modules[self:GetName()] end,
                set = function(_, val) 
                    FQoL.db.profile.modules[self:GetName()] = val 
                    if val then Module:Enable() else Module:Disable() end
                end,
            },
            skins = {
                type = "group",
                name = "Addon Skins",
                inline = true,
                order = 3,
                args = {
                    Auctionator = {
                        type = "toggle", name = "Auctionator", order = 1,
                        get = function() return FQoL.db.profile.elvuiSkins["Auctionator"] end,
                        set = function(_, val) FQoL.db.profile.elvuiSkins["Auctionator"] = val end,
                    },
                    BugSack = {
                        type = "toggle", name = "BugSack", order = 2,
                        get = function() return FQoL.db.profile.elvuiSkins["BugSack"] end,
                        set = function(_, val) FQoL.db.profile.elvuiSkins["BugSack"] = val end,
                    },
                    MacroToolkit = {
                        type = "toggle", name = "Macro Toolkit", order = 3,
                        get = function() return FQoL.db.profile.elvuiSkins["MacroToolkit"] end,
                        set = function(_, val) FQoL.db.profile.elvuiSkins["MacroToolkit"] = val end,
                    },
                    PremadeGroupsFilter = {
                        type = "toggle", name = "PGF", order = 4,
                        get = function() return FQoL.db.profile.elvuiSkins["PremadeGroupsFilter"] end,
                        set = function(_, val) FQoL.db.profile.elvuiSkins["PremadeGroupsFilter"] = val end,
                    },
                },
            },
        },
    }
    if not FQoL.db.profile.modules[self:GetName()] then self:SetEnabledState(false) end
end

function Module:OnEnable()
    if not C_AddOns.IsAddOnLoaded("ElvUI") then return end
    local S = ElvUI[1]:GetModule('Skins')
    S:AddCallbackForAddon('PremadeGroupsFilter', 'FQoL_PGFSkin', SkinPGF)
    S:AddCallbackForAddon('Auctionator', 'FQoL_AuctionatorSkin', SkinAuctionator)
    S:AddCallbackForAddon('BugSack', 'FQoL_BugSackSkin', SkinBugSack)
    S:AddCallbackForAddon('MacroToolkit', 'FQoL_MacroToolkitSkin', SkinMacroToolkit)
    
    if C_AddOns.IsAddOnLoaded('PremadeGroupsFilter') then SkinPGF() end
    if C_AddOns.IsAddOnLoaded('BugSack') then SkinBugSack() end
    if C_AddOns.IsAddOnLoaded('Auctionator') then SkinAuctionator() end
    if C_AddOns.IsAddOnLoaded('MacroToolkit') then SkinMacroToolkit() end
end

function Module:OnDisable() end
