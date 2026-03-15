local FQoL = LibStub("AceAddon-3.0"):GetAddon("FQoL")
local Module = FQoL:GetModule("Professions")

local trackerFrame = nil
local buttons = {}

local function UpdateTracker()
    if not trackerFrame then return end
    
    local yOffset = -30
    for i, data in ipairs(Module.skinningQuestData) do
        local btn = buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, trackerFrame)
            btn:SetSize(trackerFrame:GetWidth() - 20, 20)
            btn:SetPoint("TOPLEFT", trackerFrame, "TOPLEFT", 10, yOffset)
            
            btn.icon = btn:CreateTexture(nil, "OVERLAY")
            btn.icon:SetSize(14, 14)
            btn.icon:SetPoint("LEFT", btn, "LEFT", 0, 0)
            
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 5, 0)
            btn.text:SetJustifyH("LEFT")
            
            btn:SetScript("OnClick", function()
                Module:SetRareWaypoint(data.id)
            end)
            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Set Waypoint for " .. data.name)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", GameTooltip_Hide)
            
            buttons[i] = btn
        end
        
        btn:SetWidth(trackerFrame:GetWidth() - 20)
        local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(data.id)
        btn.icon:SetTexture(isCompleted and "Interface\\RaidFrame\\ReadyCheck-Ready" or "Interface\\RaidFrame\\ReadyCheck-NotReady")
        
        local displayName = string.format("%s (%s)", data.name, data.zone)
        if data.emphasize then
            displayName = "|cFFFFD100" .. displayName .. "|r"
        else
            displayName = "|cFFFFFFFF" .. displayName .. "|r"
        end
        btn.text:SetText(displayName)
        
        yOffset = yOffset - 20
    end
    
    trackerFrame:SetHeight(math.abs(yOffset) + 10)
end

function Module:UpdateSkinningTracker()
    if not FQoL.db.profile.modules["Professions"] or not FQoL.db.profile.skinningEnabled or not FQoL.db.profile.skinningTrackerUI then
        if trackerFrame then trackerFrame:Hide() end
        return
    end

    if not trackerFrame then
        if C_AddOns.IsAddOnLoaded("MyusKnowledgePointsTracker") and _G.MKPT_Frame then
            local mkpt = _G.MKPT_Frame
            trackerFrame = CreateFrame("Frame", "FQoL_SkinningTracker_MKPT", mkpt, "BackdropTemplate")
            trackerFrame:SetPoint("TOPLEFT", mkpt, "BOTTOMLEFT", 0, -5)
            trackerFrame:SetPoint("TOPRIGHT", mkpt, "BOTTOMRIGHT", 0, -5)
            
            if mkpt.GetBackdrop then
                trackerFrame:SetBackdrop(mkpt:GetBackdrop())
                trackerFrame:SetBackdropColor(mkpt:GetBackdropColor())
                trackerFrame:SetBackdropBorderColor(mkpt:GetBackdropBorderColor())
            end
            
            trackerFrame.title = trackerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            trackerFrame.title:SetPoint("TOPLEFT", 10, -10)
            trackerFrame.title:SetText("Skinning Rares")
        else
            trackerFrame = CreateFrame("Frame", "FQoL_SkinningTracker", UIParent, "BackdropTemplate")
            trackerFrame:SetSize(220, 150)
            trackerFrame:SetPoint("CENTER")
            trackerFrame:SetMovable(true)
            trackerFrame:EnableMouse(true)
            trackerFrame:RegisterForDrag("LeftButton")
            trackerFrame:SetScript("OnDragStart", trackerFrame.StartMoving)
            trackerFrame:SetScript("OnDragStop", trackerFrame.StopMovingOrSizing)
            
            trackerFrame:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            trackerFrame:SetBackdropColor(0, 0, 0, 0.8)
            
            trackerFrame.title = trackerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            trackerFrame.title:SetPoint("TOP", 0, -10)
            trackerFrame.title:SetText("Daily Skinning Rares")
            
            trackerFrame.closeBtn = CreateFrame("Button", nil, trackerFrame, "UIPanelCloseButton")
            trackerFrame.closeBtn:SetPoint("TOPRIGHT", trackerFrame, "TOPRIGHT", -2, -2)
            trackerFrame.closeBtn:SetScript("OnClick", function()
                FQoL.db.profile.skinningTrackerUI = false
                Module:UpdateSkinningTracker()
            end)
        end

        Module:RegisterEvent("QUEST_LOG_UPDATE", UpdateTracker)
    end
    
    trackerFrame:Show()
    UpdateTracker()
end

local oldEnable = Module.OnEnable
function Module:OnEnable()
    if oldEnable then oldEnable(self) end
    -- Delaying execution slightly to ensure MKPT is fully loaded if it exists
    C_Timer.After(1, function() Module:UpdateSkinningTracker() end)
end