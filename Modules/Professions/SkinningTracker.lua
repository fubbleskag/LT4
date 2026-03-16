local FQoL = LibStub("AceAddon-3.0"):GetAddon("FQoL")
local Module = FQoL:GetModule("Professions")

local trackerFrame = nil
local buttons = {}
local refreshTicker = nil

local function UpdateTracker()
    if not trackerFrame then return end
    
    local isCollapsed = FQoL.db.profile.skinningTrackerCollapsed
    local rowHeight = 20
    local yOffset = -22
    
    -- Sync scale with MKPT if possible
    if trackerFrame.isMKPT and _G.MKPT_Frame then
        trackerFrame:SetScale(_G.MKPT_Frame:GetScale())
    end

    local remainingCount = 0
    for _, data in ipairs(Module.skinningQuestData) do
        if not C_QuestLog.IsQuestFlaggedCompleted(data.id) then
            remainingCount = remainingCount + 1
        end
    end
    
    -- Update "D:N" count and Timer in title
    if trackerFrame.titleBtn and trackerFrame.titleBtn.leftText then
        trackerFrame.titleBtn.leftText:SetText(string.format("|cFF006FDDD:%d|r", remainingCount))
        
        local seconds = C_DateAndTime.GetSecondsUntilDailyReset()
        if seconds and seconds > 0 then
            local hours = math.floor(seconds / 3600)
            local mins = math.floor((seconds % 3600) / 60)
            trackerFrame.titleBtn.rightText:SetText(string.format("|cFF888888%dh %dm|r", hours, mins))
        else
            trackerFrame.titleBtn.rightText:SetText("")
        end
    end
    
    -- Start ticker if not already running
    if not refreshTicker then
        refreshTicker = C_Timer.NewTicker(60, function()
            UpdateTracker()
        end)
    end

    for i, data in ipairs(Module.skinningQuestData) do
        local btn = buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, trackerFrame)
            btn:SetHeight(rowHeight)
            btn:SetPropagateMouseClicks(true)
            
            -- Row Background
            btn.background = btn:CreateTexture(nil, "BACKGROUND")
            btn.background:SetAllPoints()
            btn.background:SetTexture("Interface/BUTTONS/WHITE8X8")
            btn.background:SetVertexColor(0, 0, 0, 0.5)
            
            -- Icon (using quest icon or generic)
            btn.icon = btn:CreateTexture(nil, "OVERLAY")
            btn.icon:SetPoint("LEFT")
            btn.icon:SetSize(rowHeight, rowHeight)
            btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            
            -- Name Text
            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 4, 0)
            btn.text:SetJustifyH("LEFT")
            btn.text:SetJustifyV("MIDDLE")
            btn.text:SetFont(btn.text:GetFont(), 13)
            btn.text:SetShadowColor(0, 0, 0, 1)
            btn.text:SetShadowOffset(2, -2)
            
            -- Highlight (MKPT Style)
            btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            btn.highlight:SetAtlas("Professions_Recipe_Hover", false)
            btn.highlight:SetPoint("TOPLEFT", btn.icon, "TOPRIGHT", 0, 0)
            btn.highlight:SetPoint("BOTTOMRIGHT")
            btn.highlight:SetAlpha(0.7)
            
            btn:SetScript("OnClick", function()
                Module:SetRareWaypoint(data.id)
            end)
            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Toggle Waypoint for " .. data.name)
                GameTooltip:AddLine(data.zone, 1, 1, 1)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", GameTooltip_Hide)
            
            buttons[i] = btn
        end
        
        if isCollapsed then
            btn:Hide()
        else
            btn:Show()
            btn:SetPoint("TOPLEFT", trackerFrame, "TOPLEFT", 0, yOffset)
            btn:SetPoint("TOPRIGHT", trackerFrame, "TOPRIGHT", 0, yOffset)
            
            local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(data.id)
            btn.icon:SetTexture(isCompleted and "Interface\\RaidFrame\\ReadyCheck-Ready" or "Interface\\RaidFrame\\ReadyCheck-NotReady")
            
            local displayName = string.format("%s (%s) |cFF888888[%.0f, %.0f]|r", data.name, data.zone, data.x, data.y)
            if data.emphasize then
                displayName = "|cFFFFD100" .. displayName .. "|r"
            else
                displayName = "|cFFFFFFFF" .. displayName .. "|r"
            end
            btn.text:SetText(displayName)
            
            yOffset = yOffset - (rowHeight + 1)
        end
    end
    
    if isCollapsed then
        trackerFrame:SetHeight(22)
    else
        trackerFrame:SetHeight(math.abs(yOffset) + 2)
    end
end

local function HasSkinning()
    local prof1, prof2 = GetProfessions()
    local profs = {prof1, prof2}
    for _, index in pairs(profs) do
        if index then
            local _, _, _, _, _, _, skillLine = GetProfessionInfo(index)
            if skillLine == 393 then -- Skinning
                return true
            end
        end
    end
    return false
end

function Module:UpdateSkinningTracker()
    if not HasSkinning() or not FQoL.db.profile.modules["Professions"] or not FQoL.db.profile.skinningEnabled or not FQoL.db.profile.skinningTrackerUI then
        if trackerFrame then trackerFrame:Hide() end
        return
    end

    if not trackerFrame then
        local function CreateTitle(parent, isMKPT)
            local titleBtn = CreateFrame("Button", nil, parent)
            titleBtn:SetHeight(22)
            titleBtn:SetPropagateMouseClicks(true)
            
            titleBtn.background = titleBtn:CreateTexture(nil, "BACKGROUND")
            titleBtn.background:SetAllPoints()
            titleBtn.background:SetTexture("Interface/BUTTONS/WHITE8X8")
            titleBtn.background:SetVertexColor(0, 0, 0, 0.5)

            if isMKPT then
                titleBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
                titleBtn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
            else
                titleBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
                titleBtn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -25, 0)
            end

            -- Skinning Icon
            titleBtn.icon = titleBtn:CreateTexture(nil, "OVERLAY")
            titleBtn.icon:SetPoint("LEFT", titleBtn, "LEFT", 0, 0)
            titleBtn.icon:SetSize(22, 22)
            titleBtn.icon:SetTexture(4620680) -- Updated FileID
            titleBtn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            
            -- Left Text (D:N)
            titleBtn.leftText = titleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            titleBtn.leftText:SetPoint("LEFT", titleBtn.icon, "RIGHT", 4, 0)
            titleBtn.leftText:SetFont(titleBtn.leftText:GetFont(), 13)
            titleBtn.leftText:SetShadowColor(0, 0, 0, 1)
            titleBtn.leftText:SetShadowOffset(2, -2)
            
            -- Right Text (Timer)
            titleBtn.rightText = titleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            titleBtn.rightText:SetPoint("RIGHT", -4, 0)
            titleBtn.rightText:SetFont(titleBtn.rightText:GetFont(), 13)
            titleBtn.rightText:SetShadowColor(0, 0, 0, 1)
            titleBtn.rightText:SetShadowOffset(2, -2)
            titleBtn.rightText:SetJustifyH("RIGHT")

            -- Main Title Text
            titleBtn.text = titleBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            titleBtn.text:SetPoint("CENTER", titleBtn, "CENTER", 0, 0)
            titleBtn.text:SetText("Renowned Beasts")
            titleBtn.text:SetFont(titleBtn.text:GetFont(), 13)
            titleBtn.text:SetTextColor(1, 1, 1) -- White like MKPT

            -- Highlight (MKPT Style)
            titleBtn.highlight = titleBtn:CreateTexture(nil, "HIGHLIGHT")
            titleBtn.highlight:SetAtlas("Professions_Recipe_Hover", false)
            titleBtn.highlight:SetPoint("TOPLEFT", titleBtn.icon, "TOPRIGHT", 0, 0)
            titleBtn.highlight:SetPoint("BOTTOMRIGHT")
            titleBtn.highlight:SetAlpha(0.7)

            titleBtn:SetScript("OnClick", function()
                FQoL.db.profile.skinningTrackerCollapsed = not FQoL.db.profile.skinningTrackerCollapsed
                UpdateTracker()
            end)
            
            titleBtn:SetScript("OnEnter", function(self)
                -- Stay white like MKPT
            end)
            titleBtn:SetScript("OnLeave", function(self)
                -- Stay white like MKPT
            end)

            return titleBtn
        end

        if C_AddOns.IsAddOnLoaded("MyusKnowledgePointsTracker") and _G.MKPT_Frame then
            local mkpt = _G.MKPT_Frame
            trackerFrame = CreateFrame("Frame", "FQoL_SkinningTracker_MKPT", mkpt, "BackdropTemplate")
            trackerFrame:SetPoint("TOPLEFT", mkpt, "BOTTOMLEFT", 0, -2)
            trackerFrame:SetPoint("TOPRIGHT", mkpt, "BOTTOMRIGHT", 0, -2)
            trackerFrame.isMKPT = true
            
            trackerFrame:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                insets = { left = -3, right = -3, top = -1, bottom = -2 }
            })
            trackerFrame:SetBackdropColor(0, 0, 0, 0.6)
            
            trackerFrame.titleBtn = CreateTitle(trackerFrame, true)
        else
            trackerFrame = CreateFrame("Frame", "FQoL_SkinningTracker", UIParent, "BackdropTemplate")
            trackerFrame:SetSize(340, 150) -- Match MKPT default width
            
            -- Restore Position
            local pos = FQoL.db.profile.skinningTrackerPosition
            if pos and pos.point then
                trackerFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
            else
                trackerFrame:SetPoint("CENTER")
            end
            
            trackerFrame:SetMovable(true)
            trackerFrame:EnableMouse(true)
            trackerFrame:RegisterForDrag("LeftButton")
            trackerFrame:SetScript("OnDragStart", trackerFrame.StartMoving)
            trackerFrame:SetScript("OnDragStop", function(self)
                self:StopMovingOrSizing()
                local point, _, relativePoint, x, y = self:GetPoint()
                FQoL.db.profile.skinningTrackerPosition = {
                    point = point,
                    relativePoint = relativePoint,
                    x = x,
                    y = y
                }
            end)
            
            trackerFrame:SetBackdrop({
                bgFile = "Interface/Tooltips/UI-Tooltip-Background",
                insets = { left = -3, right = -3, top = -1, bottom = -2 }
            })
            trackerFrame:SetBackdropColor(0, 0, 0, 0.6)
            
            trackerFrame.titleBtn = CreateTitle(trackerFrame, false)
            
            trackerFrame.closeBtn = CreateFrame("Button", nil, trackerFrame, "UIPanelCloseButton")
            trackerFrame.closeBtn:SetPoint("TOPRIGHT", trackerFrame, "TOPRIGHT", 2, 2)
            trackerFrame.closeBtn:SetScale(0.8)
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