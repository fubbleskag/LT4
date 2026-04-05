local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local Module = LT4:NewModule("ElvUISkins", "AceEvent-3.0")

Module.description = "Provides ElvUI-style skinning for various third-party addons."

local E, S
local function GetSkins()
    if not S and C_AddOns.IsAddOnLoaded("ElvUI") then
        E = unpack(ElvUI)
        S = E:GetModule('Skins')
    end
    return S
end

local function SkinPGF()
    if not LT4.db.profile.elvuiSkins["PremadeGroupsFilter"] or not GetSkins() then return end
    
    local dialog = _G.PremadeGroupsFilterDialog
    if dialog and not dialog.IsSkinned then
        S:HandleFrame(dialog)
        if dialog.RefreshButton then S:HandleButton(dialog.RefreshButton) end
        if dialog.ResetButton then S:HandleButton(dialog.ResetButton) end
        if dialog.SettingsButton then S:HandleButton(dialog.SettingsButton) end
        if dialog.CloseButton then S:HandleCloseButton(dialog.CloseButton) end
        if dialog.MaximizeMinimizeFrame then S:HandleMaxMinFrame(dialog.MaximizeMinimizeFrame) end
        dialog.IsSkinned = true
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
                S:HandleCheckBox(child.Act); child.Act.IsSkinned = true
            end
            if child.Min and not child.Min.IsSkinned then 
                S:HandleEditBox(child.Min); child.Min.IsSkinned = true
            end
            if child.Max and not child.Max.IsSkinned then 
                S:HandleEditBox(child.Max); child.Max.IsSkinned = true
            end
            if child.DropDown and not child.DropDown.IsSkinned then
                child.DropDown:StripTextures()
                child.DropDown:CreateBackdrop('Transparent')
                if child.DropDown.Button then S:HandleNextPrevButton(child.DropDown.Button, 'down') end
                child.DropDown.IsSkinned = true
            end
            for _, btnName in ipairs({"SelectAll", "SelectNone", "SelectInvert"}) do
                if child[btnName] and not child[btnName].IsSkinned then
                    S:HandleButton(child[btnName]); child[btnName].IsSkinned = true
                end
            end
            if child.GetChildren then SkinPanelChildren(child) end
        end
    end

    for _, panelName in ipairs(panels) do
        local panel = _G[panelName]
        if panel then
            SkinPanelChildren(panel); if panel.Advanced and panel.Advanced.Expression and panel.Advanced.Expression.EditBox and not panel.Advanced.Expression.EditBox.IsSkinned then
                S:HandleEditBox(panel.Advanced.Expression.EditBox); panel.Advanced.Expression.EditBox.IsSkinned = true
            end
        end
    end

    if _G.UsePGFButton and not _G.UsePGFButton.IsSkinned then S:HandleCheckBox(_G.UsePGFButton); _G.UsePGFButton.IsSkinned = true end
    local popup = _G.PremadeGroupsFilterStaticPopup
    if popup and not popup.IsSkinned then
        S:HandleFrame(popup)
        if popup.Button1 then S:HandleButton(popup.Button1) end
        if popup.Button2 then S:HandleButton(popup.Button2) end
        popup.IsSkinned = true
    end
end

local function SkinBugSack()
    if not LT4.db.profile.elvuiSkins["BugSack"] or not GetSkins() then return end
    if not Module.BugSackHooksSet then
        if BugSack and BugSack.OpenSack then hooksecurefunc(BugSack, "OpenSack", SkinBugSack) end
        Module.BugSackHooksSet = true
    end
    local frame = _G.BugSackFrame
    if frame and not frame.IsSkinned then
        S:HandleFrame(frame)
        for _, child in ipairs({frame:GetChildren()}) do
            if child:IsObjectType("Button") then
                if select(1, child:GetPoint()) == "TOPRIGHT" then S:HandleCloseButton(child) else S:HandleButton(child) end
            elseif child:IsObjectType("EditBox") then S:HandleEditBox(child) end
        end
        for _, tab in ipairs({_G.BugSackTabAll, _G.BugSackTabSession, _G.BugSackTabLast}) do if tab then S:HandleTab(tab) end end
        if _G.BugSackScroll then S:HandleScrollBar(_G.BugSackScroll.ScrollBar); _G.BugSackScroll:CreateBackdrop('Transparent') end
        frame.IsSkinned = true
    end
end

local function SkinAuctionatorTabs()
    if not GetSkins() or not _G.Auctionator or not _G.Auctionator.Tabs or not _G.Auctionator.Tabs.State then return end
    for _, details in ipairs(_G.Auctionator.Tabs.State.knownTabs or {}) do
        local tabButton = _G["AuctionatorTabs_" .. details.name]
        if tabButton and not tabButton.IsSkinned then
            S:HandleTab(tabButton)
            tabButton.IsSkinned = true
        end
    end
end

local function SkinAuctionator()
    if not LT4.db.profile.elvuiSkins["Auctionator"] or not GetSkins() then return end
    if not Module.AuctionatorHooksSet then
        if _G.Auctionator and _G.Auctionator.CraftingInfo then
            hooksecurefunc(_G.Auctionator.CraftingInfo, "InitializeProfessionsFrame", SkinAuctionator)
            hooksecurefunc(_G.Auctionator.CraftingInfo, "InitializeCustomerOrdersFrame", SkinAuctionator)
        end
        if _G.AuctionatorAHFrameMixin then hooksecurefunc(_G.AuctionatorAHFrameMixin, "OnShow", function() C_Timer.After(0.1, SkinAuctionator) end) end
        if _G.AuctionatorShoppingTabFrameMixin then hooksecurefunc(_G.AuctionatorShoppingTabFrameMixin, "OnShow", SkinAuctionator) end
        if _G.AuctionatorTabContainerMixin then hooksecurefunc(_G.AuctionatorTabContainerMixin, "OnLoad", SkinAuctionatorTabs) end
        Module.AuctionatorHooksSet = true
    end

    SkinAuctionatorTabs()

    local shoppingFrame = _G.AuctionatorShoppingFrame or (AuctionHouseFrame and AuctionHouseFrame.AuctionatorShoppingTabFrame)
    if shoppingFrame and not shoppingFrame.IsSkinned then
        local opts = shoppingFrame.SearchOptions
        if opts then
            if opts.SearchString then S:HandleEditBox(opts.SearchString) end
            if opts.SearchButton then S:HandleButton(opts.SearchButton) end
            if opts.MoreButton then S:HandleButton(opts.MoreButton) end
            if opts.AddToListButton then S:HandleButton(opts.AddToListButton) end
            if opts.ResetSearchStringButton then S:HandleCloseButton(opts.ResetSearchStringButton) end
        end
        if shoppingFrame.ExportButton then S:HandleButton(shoppingFrame.ExportButton) end
        if shoppingFrame.ImportButton then S:HandleButton(shoppingFrame.ImportButton) end
        if shoppingFrame.NewListButton then S:HandleButton(shoppingFrame.NewListButton) end
        shoppingFrame.IsSkinned = true
    end

    if _G.AuctionatorTradeSkillSearch then S:HandleButton(_G.AuctionatorTradeSkillSearch) end
    for _, frame in ipairs({_G.AuctionatorCraftingInfoProfessionsFrame, _G.AuctionatorCraftingInfoObjectiveTrackerFrame}) do
        if frame and frame.SearchButton then S:HandleButton(frame.SearchButton) end
    end
end

local function SkinMacroToolkit()
    if not LT4.db.profile.elvuiSkins["MacroToolkit"] or not GetSkins() then return end
    local MT = _G.MacroToolkit
    if not MT then return end
    if not Module.MacroToolkitHooksSet then
        local framesToHook = {"CreateMTFrame", "CreateMTPopup", "CreateSharePopup", "CreateScriptFrame", "CreateRestoreFrame", "CreateCopyFrame", "CreateBindingFrame", "CreateBuilderFrame"}
        for _, funcName in ipairs(framesToHook) do if MT[funcName] then hooksecurefunc(MT, funcName, function() C_Timer.After(0.01, SkinMacroToolkit) end) end end
        Module.MacroToolkitHooksSet = true
    end
    if _G.MacroToolkitFrame and not _G.MacroToolkitFrame.IsSkinned then
        S:HandleFrame(_G.MacroToolkitFrame)
        for i = 1, 3 do if _G["MacroToolkitFrameTab" .. i] then S:HandleTab(_G["MacroToolkitFrameTab" .. i]) end end
        _G.MacroToolkitFrame.IsSkinned = true
    end
    if _G.MacroToolkitPopup and not _G.MacroToolkitPopup.IsSkinned then
        S:HandleFrame(_G.MacroToolkitPopup); if _G.MacroToolkitPopupScrollScrollBar then S:HandleScrollBar(_G.MacroToolkitPopupScrollScrollBar) end; _G.MacroToolkitPopup.IsSkinned = true
    end
end

function Module:OnInitialize()
    local skins = { Auctionator = "Auctionator", BugSack = "BugSack", MacroToolkit = "Macro Toolkit", PremadeGroupsFilter = "PGF" }
    local skinOptions = {}
    local order = 1
    for key, name in pairs(skins) do
        skinOptions[key] = {
            type = "toggle", name = name, order = order,
            get = function() return LT4.db.profile.elvuiSkins[key] end,
            set = function(_, val) LT4.db.profile.elvuiSkins[key] = val end,
        }
        order = order + 1
    end

    LT4:RegisterModuleOptions(self:GetName(), {
        type = "group", name = "ElvUI Skins", desc = self.description, order = 10,
        args = {
            skins = { type = "group", name = "Addon Skins", inline = true, order = 1, args = skinOptions },
        },
    })
    if not LT4:GetModuleEnabled(self:GetName()) then self:SetEnabledState(false) end
end

function Module:OnEnable()
    if not GetSkins() then return end
    local addonSkins = {
        { name = "PremadeGroupsFilter", callback = SkinPGF, id = "LT4_PGFSkin" },
        { name = "Auctionator", callback = SkinAuctionator, id = "LT4_AuctionatorSkin" },
        { name = "BugSack", callback = SkinBugSack, id = "LT4_BugSackSkin" },
        { name = "MacroToolkit", callback = SkinMacroToolkit, id = "LT4_MacroToolkitSkin" },
    }
    for _, data in ipairs(addonSkins) do
        S:AddCallbackForAddon(data.name, data.id, data.callback)
        if C_AddOns.IsAddOnLoaded(data.name) then data.callback() end
    end
end
