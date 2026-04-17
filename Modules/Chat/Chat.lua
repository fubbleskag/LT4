local LT4 = LibStub("AceAddon-3.0"):GetAddon("LT4")
local Module = LT4:NewModule("Chat", "AceEvent-3.0", "AceHook-3.0")
local LSM = LibStub("LibSharedMedia-3.0", true)
Module.description = "Chat enhancements: history persistence, copy support, and flat styling."
Module.requiresReload = true

local db, chatHistory
local copyFrame, buttonBar
local styledTabs, styledEditBoxes = {}, {}
local isReplaying = false
local originalChatFont = nil

local FLAT_BG = { 0, 0, 0, 0.596 }
local FLAT_BORDER = { 0.3, 0.3, 0.3, 1 }

local frameColors = {}

local function GetChatFrameIndex(cf)
    if not cf then return nil end
    local name = cf:GetName() or ""
    return tonumber(name:match("ChatFrame(%d+)$"))
end

local function LoadFrameColorsFromWoW()
    for i = 1, NUM_CHAT_WINDOWS do
        local _, _, r, g, b, a = GetChatWindowInfo(i)
        if r then
            frameColors[i] = { r = r, g = g, b = b, a = a }
        end
    end
end

local function GetFrameColor(cf)
    if not cf then return unpack(FLAT_BG) end
    local n = GetChatFrameIndex(cf)
    local c = n and frameColors[n]
    if c then
        return (c.r or FLAT_BG[1]), (c.g or FLAT_BG[2]), (c.b or FLAT_BG[3]), (c.a or FLAT_BG[4])
    end
    return unpack(FLAT_BG)
end

local function GetEditBoxForFrame(cf)
    local n = GetChatFrameIndex(cf)
    return n and _G["ChatFrame" .. n .. "EditBox"]
end

local function GetFrameForEditBox(eb)
    local name = (eb and eb:GetName()) or ""
    local n = tonumber(name:match("ChatFrame(%d+)EditBox"))
    return n and _G["ChatFrame" .. n]
end

local function RefreshDB()
    db = LT4.db.profile.chat
    chatHistory = LT4.db.global.chatHistory
end

local function GetCharKey()
    return UnitName("player") .. "-" .. GetRealmName()
end

local function GetCharHistory()
    local key = GetCharKey()
    if not chatHistory[key] then
        chatHistory[key] = {}
    end
    return chatHistory[key]
end

local function StripFormatting(text)
    if not text then return "" end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    text = text:gsub("|H.-|h(.-)|h", "%1")
    text = text:gsub("|T.-|t", "")
    text = text:gsub("|A.-|a", "")
    text = text:gsub("|K.-|k", "")
    text = text:gsub("{.-}", "")
    return strtrim(text)
end

local function StripFormattingKeepColors(text)
    if not text then return "" end
    text = text:gsub("|H.-|h(.-)|h", "%1")  -- hyperlinks: keep display text
    text = text:gsub("|T.-|t", "")
    text = text:gsub("|A.-|a", "")
    text = text:gsub("|K.-|k", "")
    text = text:gsub("{.-}", "")
    return strtrim(text)
end

-- ============================================================
-- History
-- ============================================================

local function CaptureMessage(frame, msg, r, g, b)
    if isReplaying or not db.history.enabled then return end
    if frame ~= ChatFrame1 then return end

    local messages = GetCharHistory()
    messages[#messages + 1] = {
        msg = msg,
        r = r or 1,
        g = g or 1,
        b = b or 1,
    }

    while #messages > db.history.lines do
        table.remove(messages, 1)
    end
end

local function ReplayHistory()
    if not db.history.enabled then return end
    local messages = GetCharHistory()
    if #messages == 0 then return end

    isReplaying = true
    local cf = ChatFrame1
    cf:AddMessage(" ")
    cf:AddMessage("|cFF666666--- Chat History ---|r", 0.4, 0.4, 0.4)
    for _, entry in ipairs(messages) do
        cf:AddMessage(entry.msg, entry.r, entry.g, entry.b)
    end
    cf:AddMessage("|cFF666666--- End History ---|r", 0.4, 0.4, 0.4)
    cf:AddMessage(" ")
    isReplaying = false
end

-- ============================================================
-- Copy Frame
-- ============================================================

local function SaveCopyWindowState(f)
    local cw = db.copyWindow
    cw.x = f:GetLeft()
    cw.y = f:GetTop()
    cw.width  = f:GetWidth()
    cw.height = f:GetHeight()
end

local function RestoreCopyWindowState(f)
    local cw = db.copyWindow
    f:SetSize(cw.width or 500, cw.height or 400)
    if cw.x and cw.y then
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", cw.x, cw.y)
    end
end

local function CreateCopyFrame()
    local f = CreateFrame("Frame", "LT4ChatCopyFrame", UIParent, "BackdropTemplate")
    f:SetSize(500, 400)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:SetResizable(true)
    f:SetResizeBounds(300, 200)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveCopyWindowState(self)
    end)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(unpack(FLAT_BG))
    f:SetBackdropBorderColor(unpack(FLAT_BORDER))
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 10, -8)
    title:SetText("|cFF00AAFFChat Copy|r")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    local scroll = CreateFrame("ScrollFrame", "LT4ChatCopyScroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -30)
    scroll:SetPoint("BOTTOMRIGHT", -30, 16)

    local editBox = CreateFrame("EditBox", "LT4ChatCopyEditBox", scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(scroll:GetWidth() or 440)
    editBox:SetScript("OnEscapePressed", function() f:Hide() end)
    scroll:SetScrollChild(editBox)

    local grip = CreateFrame("Button", nil, f)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -2, 2)
    grip:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
        editBox:SetWidth(scroll:GetWidth())
        SaveCopyWindowState(f)
    end)
    local gripTex = grip:CreateTexture(nil, "OVERLAY")
    gripTex:SetAllPoints()
    gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    f:SetScript("OnSizeChanged", function()
        editBox:SetWidth(scroll:GetWidth())
    end)

    f.editBox = editBox
    f.scroll = scroll
    RestoreCopyWindowState(f)
    f:Hide()
    tinsert(UISpecialFrames, "LT4ChatCopyFrame")
    return f
end

local function ShowCopyFrame(chatFrame)
    chatFrame = chatFrame or SELECTED_CHAT_FRAME or ChatFrame1
    if not copyFrame then
        copyFrame = CreateCopyFrame()
    end

    local numMessages = chatFrame:GetNumMessages()
    local lines = {}
    for i = 1, numMessages do
        local msg = chatFrame:GetMessageInfo(i)
        if msg then
            lines[#lines + 1] = StripFormattingKeepColors(msg)
        end
    end

    copyFrame.editBox:SetText(table.concat(lines, "\n"))
    copyFrame:Show()
    C_Timer.After(0, function()
        copyFrame.scroll:SetVerticalScroll(copyFrame.scroll:GetVerticalScrollRange())
    end)
end

-- ============================================================
-- Style: Flat Tabs
-- ============================================================

local function UpdateTabBackground(tab)
    if not tab or not tab.flatBg then return end
    local cf = _G["ChatFrame" .. tab:GetID()]
    local selected = cf and cf == SELECTED_CHAT_FRAME
    local r, g, b, a = GetFrameColor(cf)
    tab.flatBg:SetColorTexture(r, g, b, selected and a or a * 0.65)
    local text = tab.Text or _G[(tab:GetName() or "") .. "Text"]
    if text then
        text:SetTextColor(1, 1, 1, 1)
    end
    tab:SetAlpha(selected and 1 or 0.85)
end

local function UpdateAllTabBackgrounds()
    for i = 1, NUM_CHAT_WINDOWS do
        local tab = _G["ChatFrame" .. i .. "Tab"]
        if tab then UpdateTabBackground(tab) end
    end
end

local function SyncEditBoxToSelected()
    local cf = SELECTED_CHAT_FRAME or ChatFrame1
    local editBox = ChatFrame1EditBox
    if editBox and editBox.flatBg then
        editBox.flatBg:SetColorTexture(GetFrameColor(cf))
    end
end

local function StyleTab(tab)
    if not tab or styledTabs[tab] then return end

    for _, region in pairs({ tab:GetRegions() }) do
        if region:IsObjectType("Texture") then
            region:SetAlpha(0)
        end
    end

    local name = tab:GetName()
    if name then
        for _, suffix in ipairs({
            "Left", "Middle", "Right",
            "SelectedLeft", "SelectedMiddle", "SelectedRight",
            "HighlightLeft", "HighlightMiddle", "HighlightRight",
            "ActiveLeft", "ActiveMiddle", "ActiveRight",
        }) do
            local tex = _G[name .. suffix]
            if tex and tex.SetAlpha then tex:SetAlpha(0) end
        end
    end

    local bg = tab:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetPoint("TOPLEFT", 2, -4)
    bg:SetPoint("BOTTOMRIGHT", -2, 2)
    bg:SetColorTexture(0, 0, 0, 0)
    tab.flatBg = bg

    tab:HookScript("OnEnter", function(self)
        if self.flatBg then
            self.flatBg:SetColorTexture(0.2, 0.2, 0.2, 0.85)
        end
    end)
    tab:HookScript("OnLeave", function(self)
        UpdateTabBackground(self)
    end)
    tab:HookScript("OnClick", function()
        C_Timer.After(0, UpdateAllTabBackgrounds)
        C_Timer.After(0, SyncEditBoxToSelected)
    end)

    local function IsTabFrame(f)
        if not f then return false end
        local n = f:GetName() or ""
        return n:match("^ChatFrame%d+Tab$") ~= nil
    end

    if db.style.flatTabs then
        local offsetting = false
        hooksecurefunc(tab, "SetPoint", function(self, p, r, rp, x, y)
            if offsetting or IsTabFrame(r) then return end
            offsetting = true
            self:SetPoint(p, r, rp, x, (y or 0) - 2)
            offsetting = false
        end)

        for i = 1, tab:GetNumPoints() do
            local p, r, rp, x, y = tab:GetPoint(i)
            if p and not IsTabFrame(r) then
                offsetting = true
                tab:SetPoint(p, r, rp, x, (y or 0) - 2)
                offsetting = false
            end
        end

        local h = tab:GetHeight()
        if h and h > 2 then tab:SetHeight(h - 2) end
    end

    styledTabs[tab] = true
end

local function SyncFrameColor(cf)
    if not cf then return end
    local n = GetChatFrameIndex(cf)
    if n then
        local tab = _G["ChatFrame" .. n .. "Tab"]
        if tab then UpdateTabBackground(tab) end
    end
    local editBox = GetEditBoxForFrame(cf)
    if editBox and editBox.flatBg then
        editBox.flatBg:SetColorTexture(GetFrameColor(cf))
    end
end

local function StyleAllTabs()
    for i = 1, NUM_CHAT_WINDOWS do
        local tab = _G["ChatFrame" .. i .. "Tab"]
        if tab then StyleTab(tab) end
    end
    UpdateAllTabBackgrounds()
    SyncEditBoxToSelected()
end

-- ============================================================
-- Style: Edit Box
-- ============================================================

local function StyleEditBox(editBox)
    if not editBox or styledEditBoxes[editBox] then return end

    local name = editBox:GetName()
    if name then
        for _, suffix in ipairs({ "Left", "Right", "Mid", "FocusLeft", "FocusRight", "FocusMid" }) do
            local tex = _G[name .. suffix]
            if tex then tex:SetAlpha(0) end
        end
    end

    for _, region in pairs({ editBox:GetRegions() }) do
        if region:IsObjectType("Texture") then
            local layer = region:GetDrawLayer()
            if layer == "BACKGROUND" or layer == "BORDER" then
                region:SetAlpha(0)
            end
        end
    end

    if editBox.SetBackdropBorderColor then
        editBox:SetBackdropBorderColor(0, 0, 0, 0)
    end

    local bg = editBox:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints()
    bg:SetColorTexture(GetFrameColor(GetFrameForEditBox(editBox)))
    editBox.flatBg = bg

    local topLine = editBox:CreateTexture(nil, "BORDER", nil, -7)
    topLine:SetHeight(1)
    topLine:SetPoint("TOPLEFT", editBox, "TOPLEFT", 0, 0)
    topLine:SetPoint("TOPRIGHT", editBox, "TOPRIGHT", 0, 0)
    topLine:SetColorTexture(0, 0, 0, 0.8)

    if editBox == ChatFrame1EditBox then
        local point, rel, relPoint, x, y = editBox:GetPoint(1)
        if point then
            editBox:SetPoint(point, rel, relPoint, x - 27, y - 4)
        end
        local numPoints = editBox:GetNumPoints()
        for i = 1, numPoints do
            local p, r, rp, px, py = editBox:GetPoint(i)
            if p == "RIGHT" or p == "TOPRIGHT" or p == "BOTTOMRIGHT" then
                editBox:SetPoint(p, r, rp, px - 1, py)
                break
            end
        end
    end

    styledEditBoxes[editBox] = true
end

local function StyleChatFrame(cf)
    if not cf then return end
    for _, region in pairs({ cf:GetRegions() }) do
        if region:IsObjectType("Texture") then
            local layer = region:GetDrawLayer()
            if layer == "BORDER" then
                region:SetAlpha(0)
            end
        end
    end
    if cf.SetBackdropBorderColor then
        cf:SetBackdropBorderColor(0, 0, 0, 0)
    end
    if cf.SetBackdropColor then
        hooksecurefunc(cf, "SetBackdropColor", function(self)
            SyncFrameColor(self)
        end)
    end
end

local function SetupAlwaysVisibleEditBox()
    local editBox = ChatFrame1EditBox
    if not editBox then return end

    -- Hook Hide directly on the instance to catch all code paths
    hooksecurefunc(editBox, "Hide", function(self)
        if db.style.alwaysShowEditBox and not InCombatLockdown() then
            self:Show()
        end
    end)

    -- Also hook DeactivateChat to clear focus without hiding
    hooksecurefunc("ChatEdit_DeactivateChat", function(eb)
        if eb == ChatFrame1EditBox and db.style.alwaysShowEditBox and not InCombatLockdown() then
            eb:Show()
        end
    end)

    editBox:Show()
end

-- ============================================================
-- Copy Button
-- ============================================================

local function CreateCopyButton()
    local bf = ChatFrame1ButtonFrame
    if not bf then return end

    local menuBtn = ChatFrameMenuButton
    local btn = CreateFrame("Button", nil, bf)
    btn:SetSize(20, 20)
    if menuBtn then
        btn:SetPoint("BOTTOM", menuBtn, "TOP", 0, 2)
    else
        btn:SetPoint("BOTTOM", bf, "BOTTOM", 0, 4)
    end

    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    tex:SetDesaturated(true)
    btn.icon = tex

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.15)

    btn:SetScript("OnClick", function()
        ShowCopyFrame()
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Copy Chat")
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)
end

local function RepositionQuickJoinButton()
    local qj = QuickJoinToastButton
    local channelBtn = ChatFrameChannelButton
    if not qj or not channelBtn then return end

    qj:ClearAllPoints()
    qj:SetPoint("TOP", channelBtn, "BOTTOM", 0, -2)
end

-- ============================================================
-- Font
-- ============================================================

local function ApplyChatFont()
    local fontCfg = db.style.font
    local path, size, flags = ChatFontNormal:GetFont()

    if not originalChatFont then
        originalChatFont = { path = path, size = size, flags = flags or "" }
    end

    local newPath, newSize, newFlags
    if fontCfg and fontCfg.enabled then
        newPath  = (fontCfg.face and LSM and LSM:Fetch("font", fontCfg.face)) or originalChatFont.path
        newSize  = fontCfg.size or originalChatFont.size
        newFlags = originalChatFont.flags
    else
        newPath  = originalChatFont.path
        newSize  = originalChatFont.size
        newFlags = originalChatFont.flags
    end

    ChatFontNormal:SetFont(newPath, newSize, newFlags)
    for i = 1, NUM_CHAT_WINDOWS do
        local cf = _G["ChatFrame" .. i]
        if cf then cf:SetFont(newPath, newSize, newFlags) end
    end
end

-- ============================================================
-- Lifecycle
-- ============================================================

function Module:OnInitialize()
    RefreshDB()
    LT4.db.RegisterCallback(self, "OnProfileChanged", function()
        RefreshDB()
    end)

    LT4:RegisterModuleOptions(self:GetName(), {
        type = "group",
        name = self:GetName(),
        desc = self.description,
        args = {
            description = {
                type = "description",
                name = self.description,
                order = 0,
            },
            history = {
                type = "group",
                name = "Chat History",
                inline = true,
                order = 1,
                args = {
                    enabled = {
                        type = "toggle",
                        name = "Enable History",
                        desc = "Save chat messages and display them on login or reload.",
                        width = "full",
                        order = 1,
                        get = function() return db.history.enabled end,
                        set = function(_, val) db.history.enabled = val end,
                    },
                    lines = {
                        type = "range",
                        name = "History Lines",
                        desc = "Number of chat lines to keep in history.",
                        min = 32, max = 1024, step = 32,
                        order = 2,
                        get = function() return db.history.lines end,
                        set = function(_, val) db.history.lines = val end,
                    },
                },
            },
            style = {
                type = "group",
                name = "Style",
                inline = true,
                order = 2,
                args = {
                    flatTabs = {
                        type = "toggle",
                        name = "Flat Tabs",
                        desc = "Replace default tab textures with a flat style.",
                        width = "full",
                        order = 1,
                        get = function() return db.style.flatTabs end,
                        set = function(_, val)
                            db.style.flatTabs = val
                            StaticPopup_Show("LT4_RELOAD_UI")
                        end,
                    },
                    alwaysShowEditBox = {
                        type = "toggle",
                        name = "Always Show Edit Box",
                        desc = "Keep the chat edit box visible at all times.",
                        width = "full",
                        order = 2,
                        get = function() return db.style.alwaysShowEditBox end,
                        set = function(_, val)
                            db.style.alwaysShowEditBox = val
                            StaticPopup_Show("LT4_RELOAD_UI")
                        end,
                    },
                    fontEnabled = {
                        type = "toggle",
                        name = "Override Font",
                        desc = "Apply a custom font to chat frames.",
                        width = "full",
                        order = 3,
                        get = function() return db.style.font.enabled end,
                        set = function(_, val)
                            db.style.font.enabled = val
                            ApplyChatFont()
                        end,
                    },
                    fontFace = {
                        type = "select",
                        name = "Font Face",
                        width = "full",
                        order = 4,
                        dialogControl = LSM and "LSM30_Font" or nil,
                        values = LSM and LSM:HashTable("font") or { ["Friz Quadrata TT"] = "Friz Quadrata TT" },
                        disabled = function() return not db.style.font.enabled end,
                        get = function() return db.style.font.face end,
                        set = function(_, val)
                            db.style.font.face = val
                            ApplyChatFont()
                        end,
                    },
                    fontSize = {
                        type = "range",
                        name = "Font Size",
                        min = 6, max = 32, step = 1,
                        width = "full",
                        order = 5,
                        disabled = function() return not db.style.font.enabled end,
                        get = function() return db.style.font.size end,
                        set = function(_, val)
                            db.style.font.size = val
                            ApplyChatFont()
                        end,
                    },
                },
            },
        },
    })

    if not LT4:GetModuleEnabled(self:GetName()) then
        self:SetEnabledState(false)
    end
end

function Module:OnEnable()
    RefreshDB()

    if db.history.enabled then
        self:SecureHook(ChatFrame1, "AddMessage", CaptureMessage)
        ReplayHistory()
    end

    LoadFrameColorsFromWoW()

    StyleAllTabs()
    self:SecureHook("FCF_OpenNewWindow", function()
        C_Timer.After(0.1, StyleAllTabs)
    end)
    if FCF_SetWindowColor then
        self:SecureHook("FCF_SetWindowColor", function(cf, r, g, b)
            local n = GetChatFrameIndex(cf)
            if n then
                frameColors[n] = frameColors[n] or {}
                frameColors[n].r, frameColors[n].g, frameColors[n].b = r, g, b
                SyncFrameColor(cf)
            end
        end)
    end
    if FCF_SetWindowAlpha then
        self:SecureHook("FCF_SetWindowAlpha", function(cf, a)
            local n = GetChatFrameIndex(cf)
            if n then
                frameColors[n] = frameColors[n] or {}
                frameColors[n].a = a
                SyncFrameColor(cf)
            end
        end)
    end
    for i = 1, NUM_CHAT_WINDOWS do
        local tab = _G["ChatFrame" .. i .. "Tab"]
        if tab then
            tab:HookScript("OnUpdate", function(self)
                local cf = _G["ChatFrame" .. self:GetID()]
                local target = (cf and cf == SELECTED_CHAT_FRAME) and 1 or 0.85
                if self:GetAlpha() ~= target then self:SetAlpha(target) end
            end)
        end
    end

    if db.style.alwaysShowEditBox then
        SetupAlwaysVisibleEditBox()
    end

    for i = 1, NUM_CHAT_WINDOWS do
        local editBox = _G["ChatFrame" .. i .. "EditBox"]
        if editBox then StyleEditBox(editBox) end
    end

    ApplyChatFont()
    CreateCopyButton()
    RepositionQuickJoinButton()
    StyleChatFrame(ChatFrame1)

    self:RegisterEvent("PLAYER_ENTERING_WORLD", function(_, _, isLogin, isReload)
        C_Timer.After(0.5, StyleAllTabs)
    end)
end

function Module:OnDisable()
    self:UnhookAll()
    self:UnregisterAllEvents()
end
