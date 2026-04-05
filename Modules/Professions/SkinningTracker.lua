local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local Module = LT4:GetModule("Professions")

local trackerFrame, buttons, refreshTicker = nil, {}, nil

local function InternalUpdate()
    if not LT4.db or not trackerFrame then return end
    
    local isCollapsed = LT4.db.profile.skinningTrackerCollapsed
    local rowHeight, yOffset = 20, -22
    
    if trackerFrame.isMKPT and _G.MKPT_Frame then trackerFrame:SetScale(_G.MKPT_Frame:GetScale()) end

    local remaining = 0
    for _, data in ipairs(Module.skinningQuestData) do if not C_QuestLog.IsQuestFlaggedCompleted(data.id) then remaining = remaining + 1 end end
    
    if trackerFrame.titleBtn then
        trackerFrame.titleBtn.leftText:SetText(string.format("|cFF006FDDD:%d|r", remaining))
        local s = C_DateAndTime.GetSecondsUntilDailyReset() or 0
        trackerFrame.titleBtn.rightText:SetText(s > 0 and string.format("|cFF888888%dh %dm|r", math.floor(s/3600), math.floor((s%3600)/60)) or "")
    end
    
    if not refreshTicker then refreshTicker = C_Timer.NewTicker(60, InternalUpdate) end

    for i, data in ipairs(Module.skinningQuestData) do
        local btn = buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, trackerFrame)
            btn:SetHeight(rowHeight)
            btn:SetPropagateMouseClicks(true)
            btn.background = btn:CreateTexture(nil, "BACKGROUND"); btn.background:SetAllPoints(); btn.background:SetTexture("Interface/BUTTONS/WHITE8X8"); btn.background:SetVertexColor(0, 0, 0, 0.5)
            btn.icon = btn:CreateTexture(nil, "OVERLAY"); btn.icon:SetPoint("LEFT"); btn.icon:SetSize(rowHeight, rowHeight); btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal"); btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 4, 0); btn.text:SetJustifyH("LEFT"); btn.text:SetFont(btn.text:GetFont(), 13); btn.text:SetShadowOffset(2, -2)
            btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT"); btn.highlight:SetAtlas("Professions_Recipe_Hover", false); btn.highlight:SetPoint("TOPLEFT", btn.icon, "TOPRIGHT", 0, 0); btn.highlight:SetPoint("BOTTOMRIGHT"); btn.highlight:SetAlpha(0.7)
            btn:SetScript("OnClick", function() Module:SetRareWaypoint(data.id) end)
            btn:SetScript("OnEnter", function(s) GameTooltip:SetOwner(s, "ANCHOR_RIGHT"); GameTooltip:AddLine("Toggle Waypoint for " .. data.name); GameTooltip:AddLine(data.zone, 1, 1, 1); GameTooltip:Show() end)
            btn:SetScript("OnLeave", GameTooltip_Hide)
            buttons[i] = btn
        end
        
        if isCollapsed then btn:Hide() else
            btn:Show(); btn:SetPoint("TOPLEFT", trackerFrame, "TOPLEFT", 0, yOffset); btn:SetPoint("TOPRIGHT", trackerFrame, "TOPRIGHT", 0, yOffset)
            btn.icon:SetTexture(C_QuestLog.IsQuestFlaggedCompleted(data.id) and "Interface\\RaidFrame\\ReadyCheck-Ready" or "Interface\\RaidFrame\\ReadyCheck-NotReady")
            local name = string.format("%s (%s) |cFF888888[%.0f, %.0f]|r", data.name, data.zone, data.x, data.y)
            btn.text:SetText(data.emphasize and ("|cFFFFD100" .. name .. "|r") or ("|cFFFFFFFF" .. name .. "|r"))
            yOffset = yOffset - (rowHeight + 1)
        end
    end
    trackerFrame:SetHeight(isCollapsed and 22 or (math.abs(yOffset) + 2))
end

function Module:UpdateSkinningTracker()
    if not self:HasSkinning() or not LT4:GetModuleEnabled("Professions") or not LT4.db.profile.skinningTrackerUI then
        if trackerFrame then trackerFrame:Hide() end
        return
    end

    if not trackerFrame then
        local function CreateTitle(parent, isMKPT)
            local b = CreateFrame("Button", nil, parent); b:SetHeight(22); b:SetPropagateMouseClicks(true)
            b.background = b:CreateTexture(nil, "BACKGROUND"); b.background:SetAllPoints(); b.background:SetTexture("Interface/BUTTONS/WHITE8X8"); b.background:SetVertexColor(0, 0, 0, 0.5)
            b:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0); b:SetPoint("TOPRIGHT", parent, "TOPRIGHT", isMKPT and 0 or -25, 0)
            b.icon = b:CreateTexture(nil, "OVERLAY"); b.icon:SetPoint("LEFT", b, "LEFT", 0, 0); b.icon:SetSize(22, 22); b.icon:SetTexture(4620680); b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            b.leftText = b:CreateFontString(nil, "OVERLAY", "GameFontNormal"); b.leftText:SetPoint("LEFT", b.icon, "RIGHT", 4, 0); b.leftText:SetFont(b.leftText:GetFont(), 13); b.leftText:SetShadowOffset(2, -2)
            b.rightText = b:CreateFontString(nil, "OVERLAY", "GameFontNormal"); b.rightText:SetPoint("RIGHT", -4, 0); b.rightText:SetFont(b.rightText:GetFont(), 13); b.rightText:SetShadowOffset(2, -2); b.rightText:SetJustifyH("RIGHT")
            b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); b.text:SetPoint("CENTER", b, "CENTER", 0, 0); b.text:SetText("Renowned Beasts"); b.text:SetFont(b.text:GetFont(), 13)
            b.highlight = b:CreateTexture(nil, "HIGHLIGHT"); b.highlight:SetAtlas("Professions_Recipe_Hover", false); b.highlight:SetPoint("TOPLEFT", b.icon, "TOPRIGHT", 0, 0); b.highlight:SetPoint("BOTTOMRIGHT"); b.highlight:SetAlpha(0.7)
            b:SetScript("OnClick", function() LT4.db.profile.skinningTrackerCollapsed = not LT4.db.profile.skinningTrackerCollapsed; InternalUpdate() end)
            return b
        end

        local mkpt = _G.MKPT_Frame
        if C_AddOns.IsAddOnLoaded("MyusKnowledgePointsTracker") and mkpt then
            trackerFrame = CreateFrame("Frame", "LT4_SkinningTracker_MKPT", mkpt, "BackdropTemplate")
            trackerFrame:SetPoint("TOPLEFT", mkpt, "BOTTOMLEFT", 0, -2); trackerFrame:SetPoint("TOPRIGHT", mkpt, "BOTTOMRIGHT", 0, -2)
            trackerFrame.isMKPT = true
        else
            trackerFrame = CreateFrame("Frame", "LT4_SkinningTracker", UIParent, "BackdropTemplate")
            trackerFrame:SetSize(340, 150)
            local pos = LT4.db.profile.skinningTrackerPosition
            if pos and pos.point then trackerFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y) else trackerFrame:SetPoint("CENTER") end
            trackerFrame:SetMovable(true); trackerFrame:EnableMouse(true); trackerFrame:RegisterForDrag("LeftButton")
            trackerFrame:SetScript("OnDragStart", trackerFrame.StartMoving)
            trackerFrame:SetScript("OnDragStop", function(s) s:StopMovingOrSizing(); local p, _, rp, x, y = s:GetPoint(); LT4.db.profile.skinningTrackerPosition = {point=p, relativePoint=rp, x=x, y=y} end)
            trackerFrame.closeBtn = CreateFrame("Button", nil, trackerFrame, "UIPanelCloseButton"); trackerFrame.closeBtn:SetPoint("TOPRIGHT", trackerFrame, "TOPRIGHT", 2, 2); trackerFrame.closeBtn:SetScale(0.8)
            trackerFrame.closeBtn:SetScript("OnClick", function() LT4.db.profile.skinningTrackerUI = false; Module:UpdateSkinningTracker() end)
        end
        
        trackerFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", insets = { left = -3, right = -3, top = -1, bottom = -2 }})
        trackerFrame:SetBackdropColor(0, 0, 0, 0.6)
        trackerFrame.titleBtn = CreateTitle(trackerFrame, trackerFrame.isMKPT)
        self:RegisterEvent("QUEST_LOG_UPDATE", InternalUpdate)
    end
    
    trackerFrame:Show()
    InternalUpdate()
end