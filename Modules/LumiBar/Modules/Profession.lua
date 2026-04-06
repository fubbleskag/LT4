local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")
local Utils = LumiBar.Utils

local Prof = {}
LumiBar:RegisterModule("Profession", Prof)

function Prof:Init()
    self.db = LumiBar.db.profile.modules.Profession
    
    -- Set defaults
    if self.db.showProf1 == nil then self.db.showProf1 = true end
    if self.db.showProf2 == nil then self.db.showProf2 = true end
    if self.db.showIcons == nil then self.db.showIcons = true end

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
                name = "Show Primary Profession 1",
                type = "toggle",
                order = 1,
            },
            showProf2 = {
                name = "Show Primary Profession 2",
                type = "toggle",
                order = 2,
            },
            showIcons = {
                name = "Show Icons",
                type = "toggle",
                order = 3,
            },
        }
    }
    LumiBar:RegisterModuleOptions("Profession", options)
end

function Prof:UpdateProfession(index, bar, text)
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

    text:SetText(string.format("%s: %d/%d", name, rank, max))
    text:Show()
    
    if self.db.showIcons then
        bar.icon:SetTexture(icon)
        bar.icon:Show()
    else
        bar.icon:Hide()
    end
    
    bar:Show() -- Always show the frame for mouse interaction and anchoring

    -- Hide bar visuals (text-only module)
    bar:SetStatusBarColor(0, 0, 0, 0)
    
    -- Store index for click handling
    bar.profIndex = index
    bar.profID = id
    bar.profName = name
    
    return true
end

function Prof:UpdateStatus()
    local p1, p2 = GetProfessions()
    
    self.has1 = false
    if self.db.showProf1 and p1 then
        self.has1 = self:UpdateProfession(p1, self.bar1, self.text1)
    else
        self.bar1:Hide()
        self.text1:Hide()
    end
    
    self.has2 = false
    if self.db.showProf2 and p2 then
        self.has2 = self:UpdateProfession(p2, self.bar2, self.text2)
    else
        self.bar2:Hide()
        self.text2:Hide()
    end
    
    self:Refresh()
    self:UpdateWidth()
end

function Prof:UpdateWidth()
    if not self.frame then return end
    
    local width = 0
    local padding = 20
    local spacing = 20
    
    local w1 = self.has1 and (self.text1:GetStringWidth() + (self.db.showIcons and 24 or 0)) or 0
    local w2 = self.has2 and (self.text2:GetStringWidth() + (self.db.showIcons and 24 or 0)) or 0
    
    if self.has1 and self.has2 then
        width = w1 + w2 + spacing + padding
    elseif self.has1 then
        width = w1 + padding
    elseif self.has2 then
        width = w2 + padding
    end
    
    -- Ensure a minimum width for usability
    if width > 0 then width = math.max(width, 100) end
    
    Utils:UpdateModuleWidth(self, width, function() self:UpdateWidth() end)
end

function Prof:GetProfessionItems()
    local items = {}
    local prof1, prof2, arch, fish, cook = GetProfessions()
    local projs = {prof1, prof2, arch, fish, cook}
    
    local foundProfs = {}
    for _, p in ipairs(projs) do
        if p then table.insert(foundProfs, p) end
    end

    for i = #foundProfs, 1, -1 do
        local p = foundProfs[i]
        local name, icon, rank, max, _, _, id = GetProfessionInfo(p)
        
        local macro = "/cast " .. name
        if id and id > 0 then
            macro = "/run C_TradeSkillUI.OpenTradeSkill(" .. id .. ")"
        end

        table.insert(items, {
            name = string.format("%s (%d/%d)", name, rank, max),
            icon = icon,
            type = "macro",
            macrotext = macro,
        })
    end
    return items
end

function Prof:HandleClick(bar, button)
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

function Prof:Enable(slotFrame)
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

function Prof:Refresh(slotFrame)
    if not self.frame then return end
    slotFrame = slotFrame or self.frame:GetParent()
    if not slotFrame then return end
    
    local barHeight = slotFrame:GetHeight()
    self.frame:SetHeight(barHeight)
    
    Utils:SetFont(self.text1)
    Utils:SetFont(self.text2)
    Utils:ApplyBackground(self.frame, self.db)
    
    local has1 = self.has1
    local has2 = self.has2
    
    local innerBarHeight = barHeight - 8
    
    -- Update bar sizes based on content
    local w1 = has1 and (self.text1:GetStringWidth() + (self.db.showIcons and 24 or 0)) or 0
    local w2 = has2 and (self.text2:GetStringWidth() + (self.db.showIcons and 24 or 0)) or 0
    
    self.bar1:SetSize(math.max(w1, 1), innerBarHeight)
    self.bar2:SetSize(math.max(w2, 1), innerBarHeight)
    
    if has1 and has2 then
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
    
    if self.db.showIcons then
        local iconSize = innerBarHeight
        self.bar1.icon:SetSize(iconSize, iconSize)
        self.bar1.icon:ClearAllPoints()
        self.bar1.icon:SetPoint("LEFT", self.bar1, "LEFT", 0, 0)
        self.text1:SetPoint("LEFT", self.bar1.icon, "RIGHT", 4, 0)
        
        self.bar2.icon:SetSize(iconSize, iconSize)
        self.bar2.icon:ClearAllPoints()
        self.bar2.icon:SetPoint("LEFT", self.bar2, "LEFT", 0, 0)
        self.text2:SetPoint("LEFT", self.bar2.icon, "RIGHT", 4, 0)
    else
        self.text1:SetPoint("CENTER", self.bar1, "CENTER", 0, 0)
        self.text2:SetPoint("CENTER", self.bar2, "CENTER", 0, 0)
    end
end
