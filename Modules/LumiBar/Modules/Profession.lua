local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
local Utils = LumiBar.Utils

local Profession = {}
LumiBar:RegisterModule("Profession", Profession)

local GATHERING_SKILL_LINES = {
    [182] = true, -- Herbalism
    [186] = true, -- Mining
    [393] = true, -- Skinning
}

local function IsGatheringIndex(index)
    if not index then return false end
    local _, _, _, _, _, _, skillLine = GetProfessionInfo(index)
    return skillLine ~= nil and GATHERING_SKILL_LINES[skillLine] == true
end

function Profession:Init()
    self.db = LumiBar.db.profile.modules.Profession
    
    local options = {
        name = "Profession",
        type = "group",
        get = function(info) return self.db[info[#info]] end,
        set = function(info, value) 
            self.db[info[#info]] = value
            self:UpdateStatus()
        end,
        args = {
            showProf1 = {
                name = "Profession 1",
                type = "toggle",
                width = "double",
                order = 1,
            },
            showProf2 = {
                name = "Profession 2",
                type = "toggle",
                width = "double",
                order = 2,
            },
            sortMode = {
                name = "Sort",
                type = "select",
                --width = "double",
                order = 3,
                values = {
                    ["default"] = "None",
                    ["gatherFirst"] = "Gathering First",
                    ["craftFirst"] = "Crafting First",
                },
                sorting = { "default", "gatherFirst", "craftFirst" },
            },
        }
    }
    LumiBar:RegisterModuleOptions("Profession", options)
end

function Profession:UpdateProfession(index, bar, text)
    if not index or index == 0 then
        bar:Hide()
        text:Hide()
        return false
    end

    local name, icon, rank, max, _, _, id = GetProfessionInfo(index)
    if not name then
        bar:Hide()
        text:Hide()
        return false
    end

    text:SetText(name)
    text:SetAlpha(1)
    text:Show()

    bar.icon:SetTexture(icon)
    bar.icon:SetAlpha(1)
    bar.icon:Show()

    bar:Show() -- Always show the frame for mouse interaction and anchoring

    -- Hide bar visuals (text-only module)
    bar:SetStatusBarColor(0, 0, 0, 0)

    -- Store index for click handling
    bar.profIndex = index
    bar.profID = id
    bar.profName = name

    return true
end

function Profession:SetPlaceholder(bar, text)
    text:SetText("Not Learned")
    text:SetAlpha(0)
    text:Show()

    bar.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    bar.icon:SetAlpha(0)
    bar.icon:Show()

    bar:Show()
    bar:SetStatusBarColor(0, 0, 0, 0)

    bar.profIndex = nil
    bar.profID = nil
    bar.profName = nil
end

function Profession:UpdateStatus()
    local p1, p2 = GetProfessions()
    local mode = self.db.sortMode or "default"
    if mode == "gatherFirst" or mode == "craftFirst" then
        local g1 = IsGatheringIndex(p1)
        local g2 = IsGatheringIndex(p2)
        if mode == "gatherFirst" and g2 and not g1 then
            p1, p2 = p2, p1
        elseif mode == "craftFirst" and g1 and not g2 then
            p1, p2 = p2, p1
        end
    end

    self.has1 = false
    self.show1 = false
    if self.db.showProf1 then
        if p1 then
            self.has1 = self:UpdateProfession(p1, self.bar1, self.text1)
            self.show1 = self.has1
        else
            self:SetPlaceholder(self.bar1, self.text1)
            self.show1 = true
        end
    else
        self.bar1:Hide()
        self.text1:Hide()
    end

    self.has2 = false
    self.show2 = false
    if self.db.showProf2 then
        if p2 then
            self.has2 = self:UpdateProfession(p2, self.bar2, self.text2)
            self.show2 = self.has2
        else
            self:SetPlaceholder(self.bar2, self.text2)
            self.show2 = true
        end
    else
        self.bar2:Hide()
        self.text2:Hide()
    end

    if self.show1 or self.show2 then
        self.frame:Show()
    else
        self.frame:Hide()
    end

    self:Refresh()
    self:UpdateWidth()
end

function Profession:UpdateWidth()
    if not self.frame then return end

    local width = 0
    local padding = 20
    local spacing = 20

    local w1 = self.show1 and (self.text1:GetStringWidth() + 24) or 0
    local w2 = self.show2 and (self.text2:GetStringWidth() + 24) or 0

    if self.show1 and self.show2 then
        width = w1 + w2 + spacing + padding
    elseif self.show1 then
        width = w1 + padding
    elseif self.show2 then
        width = w2 + padding
    end

    -- Ensure a minimum width for usability
    if width > 0 then width = math.max(width, 100) end

    Utils:UpdateModuleWidth(self, width, function() self:UpdateWidth() end)
end

function Profession:GetProfessionItems()
    local items = {}
    local prof1, prof2, arch, fish, cook = GetProfessions()
    local projs = {prof1, prof2, arch, fish, cook}
    
    local foundProfs = {}
    for i = 1, 5 do
        local p = projs[i]
        if p then 
            table.insert(foundProfs, p) 
        end
    end

    for i = #foundProfs, 1, -1 do
        local p = foundProfs[i]
        local name, icon, rank, max, _, _, id = GetProfessionInfo(p)
        
        local macro = "/cast " .. name
        if id and id > 0 then
            macro = "/run C_TradeSkillUI.OpenTradeSkill(" .. id .. ")"
        end

        table.insert(items, {
            name = name,
            value = string.format("%d / %d", rank, max),
            icon = icon,
            type = "macro",
            macrotext = macro,
            bar = (max > 0) and (rank / max * 100) or 0,
        })
    end
    return items
end

function Profession:HandleClick(bar, button)
    if not bar.profIndex or bar.profIndex == 0 then return end
    if InCombatLockdown() then return end
    
    if button == "LeftButton" then
        local id = bar.profID
        local name = bar.profName
        if id and id > 0 then
            C_TradeSkillUI.OpenTradeSkill(id)
        else
            CastSpellByName(name)
        end
    elseif button == "RightButton" then
        local items = self:GetProfessionItems()
        local direction = (LumiBar.db.profile.bar.position == "BOTTOM") and "UP" or "DOWN"
        LumiBar.SecureFlyout:ShowMenu(self.frame, items, direction)
    end
end

function Profession:Enable(slotFrame)
    self.db = LumiBar.db.profile.modules.Profession
    
    if not self.frame then
        self.frame = CreateFrame("Frame", nil, slotFrame, "BackdropTemplate")
        
        local function CreateProfBar(id)
            local bar = CreateFrame("StatusBar", nil, self.frame)
            
            bar.icon = bar:CreateTexture(nil, "OVERLAY")
            bar.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            
            -- Parent text to the bar so it's always on top of the bar's texture
            local text = bar:CreateFontString(nil, "OVERLAY")
            text:SetDrawLayer("OVERLAY", 7)
            
            bar:EnableMouse(true)
            bar:SetScript("OnMouseDown", function(s, button) self:HandleClick(s, button) end)
            
            return bar, text
        end

        self.bar1, self.text1 = CreateProfBar(1)
        self.bar2, self.text2 = CreateProfBar(2)
        
        self.frame:RegisterEvent("TRADE_SKILL_SHOW")
        self.frame:RegisterEvent("SKILL_LINES_CHANGED")
        self.frame:RegisterEvent("CHAT_MSG_SKILL")
        self.frame:SetScript("OnEvent", function() self:UpdateStatus() end)
    end
    
    self.frame:SetParent(slotFrame)
    self.frame:SetHeight(slotFrame:GetHeight())
    self.frame:Show()
    self:Refresh(slotFrame)
    self:UpdateStatus()
end

function Profession:Refresh(slotFrame)
    if not self.frame then return end
    slotFrame = slotFrame or self.frame:GetParent()
    if not slotFrame then return end
    
    local barHeight = slotFrame:GetHeight()
    self.frame:SetHeight(barHeight)
    
    Utils:SetFont(self.text1)
    Utils:SetFont(self.text2)
    if self.show1 and not self.has1 then
        self.text1:SetAlpha(0)
        self.bar1.icon:SetAlpha(0)
    end
    if self.show2 and not self.has2 then
        self.text2:SetAlpha(0)
        self.bar2.icon:SetAlpha(0)
    end
    Utils:ApplyBackground(self.frame, self.db)
    
    local show1 = self.show1
    local show2 = self.show2

    local innerBarHeight = barHeight - 8

    -- Update bar sizes based on content (always include icon width)
    local w1 = show1 and (self.text1:GetStringWidth() + 24) or 0
    local w2 = show2 and (self.text2:GetStringWidth() + 24) or 0

    self.bar1:SetSize(math.max(w1, 1), innerBarHeight)
    self.bar2:SetSize(math.max(w2, 1), innerBarHeight)

    if show1 and show2 then
        self.bar1:ClearAllPoints()
        self.bar1:SetPoint("LEFT", self.frame, "LEFT", 10, 0)

        self.bar2:ClearAllPoints()
        self.bar2:SetPoint("RIGHT", self.frame, "RIGHT", -10, 0)
    else
        self.bar1:ClearAllPoints()
        self.bar1:SetPoint("CENTER", self.frame, "CENTER", 0, 0)

        self.bar2:ClearAllPoints()
        self.bar2:SetPoint("CENTER", self.frame, "CENTER", 0, 0)
    end
    
    self.text1:ClearAllPoints()
    self.text2:ClearAllPoints()
    
    local iconSize = innerBarHeight
    self.bar1.icon:SetSize(iconSize, iconSize)
    self.bar1.icon:ClearAllPoints()
    self.bar1.icon:SetPoint("LEFT", self.bar1, "LEFT", 0, 0)
    self.text1:SetPoint("LEFT", self.bar1.icon, "RIGHT", 4, 0)
    
    self.bar2.icon:SetSize(iconSize, iconSize)
    self.bar2.icon:ClearAllPoints()
    self.bar2.icon:SetPoint("LEFT", self.bar2, "LEFT", 0, 0)
    self.text2:SetPoint("LEFT", self.bar2.icon, "RIGHT", 4, 0)
end
