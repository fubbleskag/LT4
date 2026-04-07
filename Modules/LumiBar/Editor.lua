local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local LumiBar = LT4:GetModule("LumiBar")

-- Lua functions
local _G = _G
local ipairs, pairs, unpack = ipairs, pairs, unpack
local math_floor, math_max = math.floor, math.max
local table_insert, table_remove = table.insert, table.remove
local wipe = wipe

-- GOBALS: UIParent, CreateFrame, hooksecurefunc, InCombatLockdown, C_Timer

-- Drag and Drop Globals
local activeZones = {}
local availablePool = nil
local draggingBtn = nil

local function UpdateDBFromEditor()
    local layout = LumiBar.db.profile.layoutV2
    
    local newFarLeft = {}
    local newNearLeft = {}
    local newNearRight = {}
    local newFarRight = {}

    local function Populate(zoneName, targetTable)
        local zone = activeZones[zoneName]
        if zone and zone.modules then
            for _, btn in ipairs(zone.modules) do
                table_insert(targetTable, btn.mName)
            end
        end
    end

    Populate("FarLeft", newFarLeft)
    Populate("NearLeft", newNearLeft)
    Populate("NearRight", newNearRight)
    Populate("FarRight", newFarRight)

    layout.Left.Far = newFarLeft
    layout.Left.Near = newNearLeft
    layout.Right.Near = newNearRight
    layout.Right.Far = newFarRight
    
    LumiBar:RefreshModules()
end

local function OnUpdate(self)
    if draggingBtn == self then
        for zName, zone in pairs(activeZones) do
            if zone:IsMouseOver() then
                zone:SetBackdropBorderColor(1, 1, 0, 1)
            else
                zone:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.2)
            end
        end
    end
end

local function OnDragStart(self)
    self:StartMoving()
    self:SetFrameStrata("TOOLTIP")
    draggingBtn = self
    self:SetScript("OnUpdate", OnUpdate)
end

local function OnDragStop(self)
    self:StopMovingOrSizing()
    self:SetFrameStrata("DIALOG")
    self:SetScript("OnUpdate", nil)
    draggingBtn = nil

    local oldList = self.parentList
    local newList = nil
    local droppedSomewhere = false
    
    for zName, zone in pairs(activeZones) do
        if zone:IsMouseOver() then
            newList = zone.modules
            droppedSomewhere = true
            break
        end
    end

    if not droppedSomewhere and availablePool:IsMouseOver() then
        newList = nil
        droppedSomewhere = true
    end

    if droppedSomewhere then
        if oldList then
            for i, btn in ipairs(oldList) do
                if btn == self then
                    table_remove(oldList, i)
                    break
                end
            end
        end

        if newList then
            table_insert(newList, self)
            self.parentList = newList
        else
            self.parentList = nil
        end

        UpdateDBFromEditor()
    end

    for _, zone in pairs(activeZones) do
        zone:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.2)
    end

    LumiBar:RefreshEditor()
end

function LumiBar:OpenLayoutEditor()
    if not self.EditorFrame then
        local f = CreateFrame("Frame", "LT4_LumiBarEditor", UIParent, "BackdropTemplate")
        f:SetSize(900, 520)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        
        f:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        f:SetBackdropColor(0, 0, 0, 0.95)
        f:SetBackdropBorderColor(0, 0.8, 1, 1)

        f.CloseButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        f.CloseButton:SetPoint("TOPRIGHT", f, "TOPRIGHT")

        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -15)
        f.title:SetText("LumiBar Layout Editor")

        -- 1. Bar Representation (Now at the TOP)
        local bar = CreateFrame("Frame", nil, f, "BackdropTemplate")
        bar:SetSize(870, 180)
        bar:SetPoint("TOP", f, "TOP", 0, -50)
        bar:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        bar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        bar:SetBackdropBorderColor(0, 0.8, 1, 0.2)

        local zoneWidth = (870 - 160) / 4
        local zNames = {"FarLeft", "NearLeft", "NearRight", "FarRight"}
        
        for i, zName in ipairs(zNames) do
            local z = CreateFrame("Frame", nil, bar, "BackdropTemplate")
            z:SetHeight(170)
            z:SetWidth(zoneWidth)
            z:EnableMouse(true)
            z:SetBackdrop({
                bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            z:SetBackdropColor(0.2, 0.2, 0.2, 0.4)
            z:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.2)
            
            if zName == "FarLeft" then z:SetPoint("LEFT", bar, "LEFT", 10, 0)
            elseif zName == "NearLeft" then z:SetPoint("RIGHT", bar, "CENTER", -80, 0)
            elseif zName == "NearRight" then z:SetPoint("LEFT", bar, "CENTER", 80, 0)
            elseif zName == "FarRight" then z:SetPoint("RIGHT", bar, "RIGHT", -10, 0) end
            
            local zLabel = z:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            zLabel:SetPoint("TOP", z, "TOP", 0, -5)
            zLabel:SetTextColor(0, 0.8, 1, 1)
            zLabel:SetText(zName)
            
            z.modules = {}
            activeZones[zName] = z
        end

        -- Visual marker for where TIME is (Fixed Gap)
        local timeMarker = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        timeMarker:SetPoint("CENTER", bar, "CENTER", 0, 0)
        timeMarker:SetTextColor(0.5, 0.5, 0.5, 0.5)
        timeMarker:SetText("TIME\n(FIXED)")

        -- 2. Available Modules Pool (Now at the BOTTOM)
        local pool = CreateFrame("Frame", nil, f, "BackdropTemplate")
        pool:SetSize(870, 200)
        pool:SetPoint("BOTTOM", f, "BOTTOM", 0, 20)
        pool:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12, insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        pool:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
        pool:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.5)
        availablePool = pool

        local pTitle = pool:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        pTitle:SetPoint("BOTTOMLEFT", pool, "TOPLEFT", 5, 2)
        pTitle:SetText("Available Modules (Drag into zones above, or back here to remove)")

        self.EditorFrame = f
        self.ModuleButtons = {}
    end

    self.EditorFrame:Show()
    self:RefreshEditor()
end

function LumiBar:RefreshEditor()
    local f = self.EditorFrame
    if not f then return end

    local layout = self.db.profile.layoutV2
    local activeMap = {}
    
    for _, z in pairs(activeZones) do wipe(z.modules) end

    local zoneKeys = {
        FarLeft = { side = "Left", key = "Far" },
        NearLeft = { side = "Left", key = "Near" },
        NearRight = { side = "Right", key = "Near" },
        FarRight = { side = "Right", key = "Far" },
    }

    for zName, data in pairs(zoneKeys) do
        local dbList = layout[data.side][data.key]
        local zone = activeZones[zName]
        if dbList and zone then
            for _, mName in ipairs(dbList) do
                local btn = self.ModuleButtons[mName]
                if not btn then
                    btn = CreateFrame("Button", nil, f, "BackdropTemplate")
                    btn:SetSize(130, 26)
                    btn:SetBackdrop({
                        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                        edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
                    })
                    btn:SetBackdropColor(0, 0.4, 0.7, 0.9)
                    btn:SetBackdropBorderColor(0, 0.8, 1, 1)
                    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    btn.text:SetPoint("CENTER")
                    btn.text:SetText(mName)
                    btn:EnableMouse(true)
                    btn:SetMovable(true)
                    btn:RegisterForDrag("LeftButton")
                    btn:SetScript("OnDragStart", OnDragStart)
                    btn:SetScript("OnDragStop", OnDragStop)
                    btn.mName = mName
                    self.ModuleButtons[mName] = btn
                end
                table_insert(zone.modules, btn)
                btn.parentList = zone.modules
                activeMap[mName] = true
            end
        end
    end

    for mName, _ in pairs(self.Modules) do
        if mName ~= "Time" and not activeMap[mName] then
            local btn = self.ModuleButtons[mName]
            if not btn then
                btn = CreateFrame("Button", nil, f, "BackdropTemplate")
                btn:SetSize(130, 26)
                btn:SetBackdrop({
                    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    edgeSize = 10, insets = { left = 2, right = 2, top = 2, bottom = 2 }
                })
                btn:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
                btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                btn.text:SetPoint("CENTER")
                btn.text:SetText(mName)
                btn:EnableMouse(true)
                btn:SetMovable(true)
                btn:RegisterForDrag("LeftButton")
                btn:SetScript("OnDragStart", OnDragStart)
                btn:SetScript("OnDragStop", OnDragStop)
                btn.mName = mName
                self.ModuleButtons[mName] = btn
            end
            btn.parentList = nil
            btn:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
            btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        end
    end

    for zName, zone in pairs(activeZones) do
        for i, btn in ipairs(zone.modules) do
            btn:SetParent(zone)
            btn:ClearAllPoints()
            btn:SetPoint("TOP", zone, "TOP", 0, -30 - (i-1)*28)
            btn:SetBackdropColor(0, 0.4, 0.7, 0.9)
            btn:SetBackdropBorderColor(0, 0.8, 1, 1)
            btn:Show()
        end
    end

    local poolIdx = 0
    for mName, btn in pairs(self.ModuleButtons) do
        if not activeMap[mName] then
            btn:SetParent(availablePool)
            btn:ClearAllPoints()
            local col = poolIdx % 6
            local row = math_floor(poolIdx / 6)
            btn:SetPoint("TOPLEFT", availablePool, "TOPLEFT", 15 + col*142, -15 - row*30)
            btn:Show()
            poolIdx = poolIdx + 1
        end
    end
end
