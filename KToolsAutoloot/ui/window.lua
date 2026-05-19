-- KTools_autoloot/ui/window.lua
-- Главное окно: настройки, форма добавления и таблица предметов.

local AceGUI = LibStub("AceGUI-3.0")
local L      = LibStub("AceLocale-3.0"):GetLocale("KToolsLoot")

local QUALITIES = {
    [0] = L["QUALITY_POOR"],
    [1] = L["QUALITY_COMMON"],
    [2] = L["QUALITY_UNCOMMON"],
    [3] = L["QUALITY_RARE"],
    [4] = L["QUALITY_EPIC"],
    [5] = L["QUALITY_LEGENDARY"],
}

local function ItemTypeLabel(classID)
    if not classID then return "-" end
    if classID == 1 then return L["TYPE_REAGENT"]   end
    if classID == 2 or classID == 4 then return L["TYPE_EQUIPMENT"] end
    if classID == 7 then return L["TYPE_REAGENT"]   end
    if classID == 9 then return L["TYPE_RECIPE"]    end
    return "-"
end

-- [ref-021][ref-024] Ширины колонок — все фиксированы в px, кроме «Название».
local COL_NUM_W      = 50
local COL_ICON_W     = 50
local COL_ID_W       = 100
local COL_NAME_INIT  = 10    -- [bug-016] placeholder; RefreshNameWidths выставит точное px
local COL_ILVL_W     = 100
local COL_TYPE_W     = 100
local COL_DEL_W      = 50
local FIXED_COLS_W   = COL_NUM_W + COL_ICON_W + COL_ID_W + COL_ILVL_W + COL_TYPE_W + COL_DEL_W

-- [bug-019] Единственный открытый IO-диалог.
local ioDialog = nil

-- Хранилище функций обновления дропдаунов (инициализируется в BuildHeader).
local refreshDeleteDropdown  = nil
local refreshActiveDropdown  = nil

-- ─────────────────────────────── ширина колонки «Название» ────────────────
-- [bug-016] Пересчёт: rawNameW = scrollWidth - FIXED_COLS_W; nameW = rawNameW * 0.80.
-- Вызывается при ресайзе И при каждом открытии окна / перестройке списка.
local function RefreshNameWidths()
    local sf = KToolsLoot.itemsScroll
    if not sf or not sf.scrollframe then return end
    local w = sf.scrollframe:GetWidth()
    if not w or w <= FIXED_COLS_W + 10 then return end
    local nameW = math.max(40, (w - FIXED_COLS_W) * 0.80)
    for _, entry in ipairs(KToolsLoot.nameColumns or {}) do
        entry.label:SetWidth(nameW)
        if entry.row.DoLayout then entry.row:DoLayout() end
    end
end

-- ─────────────────────────────── UUID профилей ────────────────────────────
-- [ref-025] Профиль хранится в AceDB под внутренним ID (UUID-like).
-- Имя профиля — в SavedVariable KToolsLootProfileNames[id] = displayName.

local function GenerateProfileID()
    return string.format("k%d%06d", time(), math.random(100000, 999999))
end

local function GetDisplayName(uuid)
    if uuid == "Default" then return "Default" end
    return (KToolsLootProfileNames and KToolsLootProfileNames[uuid]) or uuid
end

-- ─────────────────────────────── сериализация ─────────────────────────────
-- [ref-025] Экспорт: только имя профиля + список предметов (active, id, ilvl?).
-- Формат строки:  name:ИмяПрофиля|i:id,active[,ilvl],name|...

local function SerializeItems(p)
    local t   = {}
    local cur = KToolsLoot.db and KToolsLoot.db:GetCurrentProfile() or ""
    t[#t+1]   = "name:" .. GetDisplayName(cur):gsub("[|]", "")
    for id, item in pairs(p.items or {}) do
        local iname  = (item.name or ""):gsub("[|,]", "")
        local active = item.active and "1" or "0"
        if item.ilvl and item.ilvl > 0 then
            t[#t+1] = "i:" .. id .. "," .. active .. "," .. item.ilvl .. "," .. iname
        else
            t[#t+1] = "i:" .. id .. "," .. active .. "," .. iname
        end
    end
    return table.concat(t, "|")
end

-- Парсинг строки импорта: возвращает (displayName, items).
local function ParseItemsString(str)
    local pname = nil
    local items = {}
    for part in str:gmatch("[^|]+") do
        local k, v = part:match("^([^:]+):(.*)$")
        if k == "name" then
            pname = v
        elseif k == "i" then
            local fields = {}
            for f in v:gmatch("[^,]+") do fields[#fields+1] = f end
            local id     = tonumber(fields[1])
            local active = fields[2] == "1"
            local ilvl, iname
            -- Если третье поле — число и полей >= 4, это ilvl; иначе ilvl=0.
            if #fields >= 4 and tonumber(fields[3]) then
                ilvl = tonumber(fields[3])
                local parts = {}
                for i = 4, #fields do parts[#parts+1] = fields[i] end
                iname = table.concat(parts, ",")
            else
                ilvl = 0
                local parts = {}
                for i = 3, #fields do parts[#parts+1] = fields[i] end
                iname = table.concat(parts, ",")
            end
            if id then
                items[id] = { active = active, ilvl = ilvl or 0,
                              name = iname ~= "" and iname or "?" }
            end
        end
    end
    return pname, items
end

-- ─────────────────────────────── IO-диалог ────────────────────────────────
-- [bug-019] Только один диалог. [ref-028] Заполняет почти весь фрейм.
-- [bug-020] Скрываем встроенную кнопку MultiLineEditBox.

-- [bug-023] Forward-declaration — ShowIODialog вызывает RegisterIOFrame,
-- которая определена позже в файле.
local RegisterIOFrame

local function ShowIODialog(mode, exportData)
    if ioDialog then return end                         -- singleton

    local dlg = AceGUI:Create("Frame")
    dlg:SetTitle(mode == "export" and L["IO_EXPORT_TITLE"] or L["IO_IMPORT_TITLE"])
    dlg:SetWidth(600)
    dlg:SetHeight(480)
    dlg:SetLayout("Flow")
    dlg.frame:SetFrameStrata("FULLSCREEN_DIALOG")
    dlg:SetCallback("OnClose", function(w)
        _G[IO_FRAME_NAME] = nil
        AceGUI:Release(w)
        ioDialog = nil
    end)
    ioDialog = dlg
    RegisterIOFrame(dlg.frame)

    -- [ref-028] Текстовое поле занимает почти весь фрейм.
    local boxH = (mode == "import") and 350 or 390
    local box  = AceGUI:Create("MultiLineEditBox")
    box:SetFullWidth(true)
    box:SetHeight(boxH)
    box:SetLabel("")
    box:SetMaxLetters(0)
    if exportData then box:SetText(exportData) end
    -- [bug-020] Убираем встроенную кнопку «Accept».
    if box.button then box.button:Hide() end
    dlg:AddChild(box)

    if mode == "import" then
        local btn = AceGUI:Create("Button")
        btn:SetText(L["IO_IMPORT_BTN"])
        btn:SetWidth(180)
        btn:SetCallback("OnClick", function()
            local text = (box:GetText() or ""):match("^%s*(.-)%s*$")
            if text == "" then return end
            local pname, items = ParseItemsString(text)
            if not pname or pname == "" then pname = "Imported" end
            -- [ref-025] Создать профиль, активировать, открыть окно заново.
            local newID = GenerateProfileID()
            KToolsLootProfileNames = KToolsLootProfileNames or {}
            KToolsLootProfileNames[newID] = pname
            KToolsLoot.db:SetProfile(newID)
            KToolsLoot.db.profile.items = items
            -- [bug-025] Hide() вместо Release() — триггерит OnClose для правильного cleanup.
            dlg:Hide()
            KToolsLoot:CloseWindow()
            KToolsLoot:OpenWindow()
        end)
        dlg:AddChild(btn)
    else
        -- Выделить весь текст экспорта для удобного копирования.
        C_Timer.After(0.05, function()
            if box.editBox then
                box.editBox:SetFocus()
                box.editBox:HighlightText()
            end
        end)
    end
end

-- ─────────────────────────────── layout ───────────────────────────────────
local LAYOUT_NAME      = "KToolsListFill"
local layoutRegistered = false
local function EnsureLayout()
    if layoutRegistered then return end
    layoutRegistered = true
    AceGUI:RegisterLayout(LAYOUT_NAME, function(content, children)
        local n = #children
        if n == 0 then return end
        local y = 0
        for i = 1, n - 1 do
            local child = children[i]
            local f = child.frame
            f:ClearAllPoints()
            f:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, -y)
            f:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -y)
            if child.DoLayout then child:DoLayout() end
            y = y + (f:GetHeight() or 0) + 4
        end
        local last = children[n]
        local lf   = last.frame
        lf:ClearAllPoints()
        lf:SetPoint("TOPLEFT",     content, "TOPLEFT",     0, -y)
        lf:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0,  0)
        if last.DoLayout then last:DoLayout() end
    end)
end

local SPECIAL_FRAME_NAME = "KToolsLootMainFrame"
local function RegisterAsSpecialFrame(uiFrame)
    _G[SPECIAL_FRAME_NAME] = uiFrame
    for i = 1, #UISpecialFrames do
        if UISpecialFrames[i] == SPECIAL_FRAME_NAME then return end
    end
    tinsert(UISpecialFrames, SPECIAL_FRAME_NAME)
end

-- [ref-029] IO-диалог тоже закрывается по ESC.
local IO_FRAME_NAME = "KToolsLootIOFrame"
RegisterIOFrame = function(uiFrame)
    _G[IO_FRAME_NAME] = uiFrame
    for i = 1, #UISpecialFrames do
        if UISpecialFrames[i] == IO_FRAME_NAME then return end
    end
    tinsert(UISpecialFrames, IO_FRAME_NAME)
end

-- ─────────────────────────────── хелперы ─────────────────────────────────
local function Profile() return KToolsLoot:Profile() end

local function BindCheckbox(parent, label, relWidth, key)
    local cb = AceGUI:Create("CheckBox")
    cb:SetLabel(label)
    cb:SetRelativeWidth(relWidth or 1)
    if key then
        cb:SetValue(Profile()[key] and true or false)
        cb:SetCallback("OnValueChanged", function(_, _, value)
            Profile()[key] = value and true or false
        end)
    end
    parent:AddChild(cb)
    return cb
end

-- [ref-024] Хелперы: width > 1 → SetWidth(px), иначе SetRelativeWidth.
local function AddSpacer(parent, width, height)
    local s = AceGUI:Create("Label")
    s:SetText(" ")
    if width > 1 then s:SetWidth(width) else s:SetRelativeWidth(width) end
    if height then s:SetHeight(height) end
    parent:AddChild(s)
    return s
end

local function AddCenteredLabel(parent, text, width)
    local l = AceGUI:Create("Label")
    l:SetText(text)
    if width > 1 then l:SetWidth(width) else l:SetRelativeWidth(width) end
    if l.label and l.label.SetJustifyH then l.label:SetJustifyH("CENTER") end
    parent:AddChild(l)
    return l
end

local function AddLeftLabel(parent, text, width)
    local l = AceGUI:Create("Label")
    l:SetText(text)
    if width > 1 then l:SetWidth(width) else l:SetRelativeWidth(width) end
    parent:AddChild(l)
    return l
end

local function CenterEditBox(widget)
    if widget.editbox and widget.editbox.SetJustifyH then
        widget.editbox:SetJustifyH("CENTER")
    end
end

-- ─────────────────────────────── шапка ───────────────────────────────────
-- [ref-025][ref-026][ref-018][bug-017][bug-019][bug-020]
local function BuildHeader(parent)
    local header = AceGUI:Create("SimpleGroup")
    header:SetFullWidth(true)
    header:SetLayout("Flow")
    parent:AddChild(header)

    -- [ref-026] Чекбокс включения — создаём напрямую, без BindCheckbox,
    -- чтобы избежать конфликта relWidth/width.
    local enableCb = AceGUI:Create("CheckBox")
    enableCb:SetLabel("")
    enableCb:SetWidth(36)
    enableCb:SetValue(Profile().enabled and true or false)
    enableCb:SetCallback("OnValueChanged", function(_, _, value)
        Profile().enabled = value and true or false
    end)
    header:AddChild(enableCb)

    -- Активный профиль
    local activeDD = AceGUI:Create("Dropdown")
    activeDD:SetLabel(L["PROFILE"])
    activeDD:SetWidth(140)
    activeDD:SetCallback("OnValueChanged", function(_, _, key)
        KToolsLoot.db:SetProfile(key)
        KToolsLoot:CloseWindow()
        KToolsLoot:OpenWindow()
    end)
    header:AddChild(activeDD)

    -- [bug-024] Список активного профиля перестраивается при каждом открытии.
    local function RebuildActiveList()
        local list = {}
        for _, uuid in ipairs(KToolsLoot.db:GetProfiles()) do
            list[uuid] = GetDisplayName(uuid)
        end
        activeDD:SetList(list)
        activeDD:SetValue(KToolsLoot.db:GetCurrentProfile())
    end
    if activeDD.button_cover then
        activeDD.button_cover:HookScript("OnClick", RebuildActiveList)
    elseif activeDD.button then
        activeDD.button:HookScript("OnClick", RebuildActiveList)
    end

    -- Создать профиль
    local createBtn = AceGUI:Create("Button")
    createBtn:SetText(L["CREATE"])
    createBtn:SetWidth(80)
    createBtn:SetCallback("OnClick", function()
        StaticPopup_Show("KTOOLSLOOT_CREATE_PROFILE")
    end)
    header:AddChild(createBtn)

    -- [bug-022] Дропдаун удаления: список строится в момент открытия,
    -- исключая только текущий профиль. Нет значения по умолчанию.
    local deleteDD = AceGUI:Create("Dropdown")
    deleteDD:SetWidth(150)
    deleteDD:SetCallback("OnValueChanged", function(_, _, key)
        if not key or key == "" then return end
        KToolsLoot._pendingDeleteProfile = key
        StaticPopup_Show("KTOOLSLOOT_DELETE_PROFILE", GetDisplayName(key))
    end)
    header:AddChild(deleteDD)

    local function RebuildDeleteList()
        local list = {}
        local cur = KToolsLoot.db:GetCurrentProfile()
        for _, uuid in ipairs(KToolsLoot.db:GetProfiles()) do
            if uuid ~= cur then
                list[uuid] = GetDisplayName(uuid)
            end
        end
        deleteDD:SetList(list)
        -- Не вызываем SetValue — пользователь сам выбирает профиль.
    end
    -- Перестраиваем список каждый раз при открытии дропдауна.
    if deleteDD.button_cover then
        deleteDD.button_cover:HookScript("OnClick", RebuildDeleteList)
    elseif deleteDD.button then
        deleteDD.button:HookScript("OnClick", RebuildDeleteList)
    end
    RebuildDeleteList()  -- начальное наполнение без SetValue

    -- Import / Export
    local importBtn = AceGUI:Create("Button")
    importBtn:SetText(L["IMPORT_PROFILE"])
    importBtn:SetWidth(100)
    importBtn:SetCallback("OnClick", function() ShowIODialog("import") end)
    header:AddChild(importBtn)

    local exportBtn = AceGUI:Create("Button")
    exportBtn:SetText(L["EXPORT_PROFILE"])
    exportBtn:SetWidth(100)
    exportBtn:SetCallback("OnClick", function()
        ShowIODialog("export", SerializeItems(Profile()))
    end)
    header:AddChild(exportBtn)

    -- Функции обновления дропдаунов (используются из StaticPopup callbacks).
    -- [bug-024] Оба дропдауна делегируют в Rebuild-функции; deleteDD дополнительно сбрасывает выбор.
    refreshActiveDropdown = RebuildActiveList

    refreshDeleteDropdown = function()
        RebuildDeleteList()
        deleteDD:SetValue(nil)
    end

    RebuildActiveList()
    RebuildDeleteList()
end

-- ─────────────────────────────── настройки ────────────────────────────────
local function BuildSettings(parent)
    local group = AceGUI:Create("InlineGroup")
    group:SetFullWidth(true)
    group:SetLayout("Flow")
    parent:AddChild(group)

    BindCheckbox(group, L["QUEST_ITEMS"],    0.5, "quest")
    BindCheckbox(group, L["GOLD"],           0.5, "gold")
    BindCheckbox(group, L["REAGENTS"],       0.5, "reagents")
    BindCheckbox(group, L["CURRENCY"],       0.5, "currency")
    BindCheckbox(group, L["RECIPES"],        0.5, "recipes")
    BindCheckbox(group, L["ARTIFACT_POWER"], 0.5, "artifact")
    BindCheckbox(group, L["BOP_NO_CONFIRM"], 0.5, "bopNoConfirm")
    BindCheckbox(group, L["MOUNTS"],         0.5, "mounts")
    BindCheckbox(group, L["TOKENS"],         0.5, "tokens")
    BindCheckbox(group, L["PETS"],           0.5, "pets")
    BindCheckbox(group, L["SKINNING_CLOSE"], 0.5, "skinningClose")

    local qcell = AceGUI:Create("SimpleGroup")
    qcell:SetRelativeWidth(0.5)
    qcell:SetLayout("Flow")
    group:AddChild(qcell)

    local qFilter = AceGUI:Create("CheckBox")
    qFilter:SetLabel("")
    qFilter:SetWidth(26)
    qFilter:SetValue(Profile().useQualityFilter and true or false)
    qFilter:SetCallback("OnValueChanged", function(_, _, value)
        Profile().useQualityFilter = value and true or false
    end)
    qcell:AddChild(qFilter)

    local quality = AceGUI:Create("Dropdown")
    quality:SetList(QUALITIES)
    quality:SetValue(Profile().quality or 2)
    quality:SetRelativeWidth(0.55)
    quality:SetCallback("OnValueChanged", function(_, _, key)
        Profile().quality = tonumber(key) or 2
    end)
    qcell:AddChild(quality)

    AddCenteredLabel(qcell, L["QUALITY_GE"], 0.1)

    -- [ref-022][bug-015] Фиксированная ширина 100px; 0 → пустая строка.
    local ilvlVal = Profile().ilvl or 0
    local ilvl    = AceGUI:Create("EditBox")
    ilvl:SetLabel("ilvl")
    ilvl:SetWidth(100)
    ilvl:SetText(ilvlVal > 0 and tostring(ilvlVal) or "")
    ilvl:SetCallback("OnEnterPressed", function(widget, _, text)
        Profile().ilvl = tonumber(text) or 0
        widget:ClearFocus()
    end)
    qcell:AddChild(ilvl)

end

-- ─────────────────────────────── форма добавления ─────────────────────────
local function BuildAddForm(parent)
    local group = AceGUI:Create("InlineGroup")
    group:SetFullWidth(true)
    group:SetLayout("Flow")
    parent:AddChild(group)

    BindCheckbox(group, L["COLLECT_BY_LIST"], 0.30, "useList")

    local idBox = AceGUI:Create("EditBox")
    idBox:SetLabel(L["ITEM_ID"])
    idBox:SetRelativeWidth(0.20)
    group:AddChild(idBox)

    local nameBox = AceGUI:Create("EditBox")
    nameBox:SetLabel(L["ITEM_NAME"])
    nameBox:SetRelativeWidth(0.35)
    group:AddChild(nameBox)

    local addBtn = AceGUI:Create("Button")
    addBtn:SetText(L["ADD"])
    addBtn:SetRelativeWidth(0.15)
    group:AddChild(addBtn)

    local function TryAddItem()
        local idText   = idBox:GetText()
        local nameText = nameBox:GetText()
        local id = tonumber(idText)
        if not id and nameText and nameText ~= "" then
            local _, link = GetItemInfo(nameText)
            if link then id = tonumber(link:match("item:(%d+)")) end
        end
        if not id or id <= 0 then return end
        local cachedName   = GetItemInfo(id)
        local resolvedName = (nameText ~= "" and nameText) or cachedName or "?"
        Profile().items[id] = { active = true, ilvl = 0, name = resolvedName }
        idBox:SetText("")
        nameBox:SetText("")
        KToolsLoot:RefreshItemsList()
    end

    addBtn:SetCallback("OnClick",           TryAddItem)
    idBox:SetCallback("OnEnterPressed",     function() TryAddItem() end)
    nameBox:SetCallback("OnEnterPressed",   function() TryAddItem() end)
end

-- ─────────────────────────────── строка предмета ─────────────────────────
local function BuildItemRow(parent, id, item)
    local row = AceGUI:Create("SimpleGroup")
    row:SetFullWidth(true)
    row:SetLayout("Flow")
    parent:AddChild(row)

    -- [bug-018] Явно задаём пустой label, чтобы не было лишнего текста.
    local cb = AceGUI:Create("CheckBox")
    cb:SetLabel("")
    cb:SetValue(item.active and true or false)
    cb:SetWidth(COL_NUM_W)
    cb:SetCallback("OnValueChanged", function(_, _, value)
        if Profile().items[id] then Profile().items[id].active = value and true or false end
    end)
    row:AddChild(cb)

    local icon = AceGUI:Create("Icon")
    icon:SetImage(GetItemIcon and GetItemIcon(id) or "Interface\\Icons\\INV_Misc_QuestionMark")
    icon:SetImageSize(24, 24)
    icon:SetWidth(COL_ICON_W)
    row:AddChild(icon)

    AddCenteredLabel(row, tostring(id), COL_ID_W)

    -- [ref-019] Название — левый край; ссылка для динамической ширины.
    -- [bug-016] COL_NAME_INIT=10px чтобы layout не переполнялся до RefreshNameWidths.
    local nameLabel = AddLeftLabel(row, item.name or (GetItemInfo and GetItemInfo(id)) or "?", COL_NAME_INIT)
    if KToolsLoot.nameColumns then
        KToolsLoot.nameColumns[#KToolsLoot.nameColumns + 1] = { row = row, label = nameLabel }
    end

    local ilvlBox = AceGUI:Create("EditBox")
    ilvlBox:SetText(item.ilvl and item.ilvl > 0 and tostring(item.ilvl) or "")
    ilvlBox:SetWidth(COL_ILVL_W)
    ilvlBox:SetCallback("OnEnterPressed", function(widget, _, text)
        if Profile().items[id] then Profile().items[id].ilvl = tonumber(text) or 0 end
        widget:ClearFocus()
    end)
    row:AddChild(ilvlBox)
    CenterEditBox(ilvlBox)

    local _, _, _, _, _, _, _, _, _, _, _, classID = GetItemInfo(id)
    AddCenteredLabel(row, ItemTypeLabel(classID), COL_TYPE_W)

    local del = AceGUI:Create("Button")
    del:SetText("X")
    del:SetWidth(COL_DEL_W)
    del:SetCallback("OnClick", function()
        Profile().items[id] = nil
        KToolsLoot:RefreshItemsList()
    end)
    row:AddChild(del)
end

-- ─────────────────────────────── таблица предметов ────────────────────────
local function BuildItems(parent)
    local group = AceGUI:Create("InlineGroup")
    group:SetTitle(L["ITEM_LIST"])
    group:SetFullWidth(true)
    group:SetFullHeight(true)
    group:SetLayout("Fill")
    parent:AddChild(group)

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List")
    group:AddChild(scroll)
    KToolsLoot.itemsScroll = scroll

    -- [ref-031] Скроллбар виден всегда.
    C_Timer.After(0, function()
        if scroll.scrollbar then
            scroll.scrollbar:Show()
            scroll.scrollbar:HookScript("OnHide", function(self) self:Show() end)
        end
    end)

    local head = AceGUI:Create("SimpleGroup")
    head:SetFullWidth(true)
    head:SetLayout("Flow")
    scroll:AddChild(head)

    local hNum = AceGUI:Create("Label")
    hNum:SetText("#")
    hNum:SetWidth(COL_NUM_W)
    head:AddChild(hNum)

    AddSpacer(head, COL_ICON_W)
    AddCenteredLabel(head, L["ITEM_ID"], COL_ID_W)

    KToolsLoot.nameColumns = {}
    local headName = AddLeftLabel(head, L["ITEM_NAME"], COL_NAME_INIT)
    KToolsLoot.nameColumns[1] = { row = head, label = headName }

    AddCenteredLabel(head, L["QUALITY_GE"] .. L["ITEM_ILVL"], COL_ILVL_W)
    AddCenteredLabel(head, L["ITEM_TYPE"],                    COL_TYPE_W)

    local hDel = AceGUI:Create("Label")
    hDel:SetText(L["DELETE"])
    hDel:SetWidth(COL_DEL_W)
    if hDel.label and hDel.label.SetJustifyH then hDel.label:SetJustifyH("CENTER") end
    head:AddChild(hDel)

    KToolsLoot.itemsHeader = head
    KToolsLoot:RefreshItemsList()
end

-- ─────────────────────────────── обновление списка ────────────────────────
function KToolsLoot:RefreshItemsList()
    local scroll = self.itemsScroll
    if not scroll then return end

    local header    = self.itemsHeader
    local toRelease = {}
    for _, child in ipairs(scroll.children) do
        if child ~= header then toRelease[#toRelease + 1] = child end
    end
    for _, w in ipairs(toRelease) do
        for i = #scroll.children, 1, -1 do
            if scroll.children[i] == w then table.remove(scroll.children, i); break end
        end
        AceGUI:Release(w)
    end

    -- Сохраняем только запись заголовка (index 1).
    local cols = self.nameColumns
    if cols then for i = #cols, 2, -1 do cols[i] = nil end end

    local sorted = {}
    for id in pairs(Profile().items) do sorted[#sorted + 1] = id end
    table.sort(sorted)
    for _, id in ipairs(sorted) do BuildItemRow(scroll, id, Profile().items[id]) end

    if scroll.DoLayout then scroll:DoLayout() end
    C_Timer.After(0, RefreshNameWidths)
end

-- ─────────────────────────────── открытие окна ────────────────────────────
function KToolsLoot:OpenWindow()
    if self.window then
        self.window.frame:Show()
        return
    end

    EnsureLayout()

    local frame = AceGUI:Create("Frame")
    frame:SetTitle(L["WINDOW_TITLE"])
    frame:SetWidth(800)
    frame:SetHeight(640)
    frame:SetLayout(LAYOUT_NAME)
    frame.frame:SetMinResize(800, 520)
    -- [bug-017] HIGH < DIALOG — StaticPopup'ы отображаются поверх нашего окна.
    frame.frame:SetFrameStrata("HIGH")
    frame:SetCallback("OnClose", function(widget)
        -- [bug-025] Закрыть IO-диалог если он открыт.
        if ioDialog then ioDialog:Hide() end
        AceGUI:Release(widget)
        _G[SPECIAL_FRAME_NAME] = nil
        KToolsLoot.window        = nil
        KToolsLoot.itemsScroll   = nil
        KToolsLoot.itemsHeader   = nil
        KToolsLoot.nameColumns   = nil
        refreshDeleteDropdown    = nil
        refreshActiveDropdown    = nil
    end)

    RegisterAsSpecialFrame(frame.frame)

    BuildHeader(frame)
    BuildSettings(frame)
    BuildAddForm(frame)
    BuildItems(frame)

    self.window = frame

    -- [bug-016] Обновлять ширину «Название» при ресайзе и сразу после открытия.
    frame.frame:HookScript("OnSizeChanged", function()
        C_Timer.After(0, RefreshNameWidths)
    end)
    C_Timer.After(0, RefreshNameWidths)
end

function KToolsLoot:CloseWindow()
    if self.window then self.window:Hide() end
end

-- ─────────────────────────────── попапы ──────────────────────────────────
StaticPopupDialogs["KTOOLSLOOT_CREATE_PROFILE"] = {
    text         = L["CREATE"] .. ": " .. L["PROFILE"],
    button1      = ACCEPT,
    button2      = CANCEL,
    hasEditBox   = true,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
    OnAccept = function(self)
        local name = self.editBox and self.editBox:GetText() or ""
        if #name < 1 then return end
        local newID = GenerateProfileID()
        KToolsLootProfileNames = KToolsLootProfileNames or {}
        KToolsLootProfileNames[newID] = name
        KToolsLoot.db:SetProfile(newID)
        KToolsLoot:CloseWindow()
        KToolsLoot:OpenWindow()
    end,
    EditBoxOnEnterPressed = function(self)
        local name = self:GetText()
        if #name >= 1 then
            local newID = GenerateProfileID()
            KToolsLootProfileNames = KToolsLootProfileNames or {}
            KToolsLootProfileNames[newID] = name
            KToolsLoot.db:SetProfile(newID)
            KToolsLoot:CloseWindow()
            KToolsLoot:OpenWindow()
        end
        self:GetParent():Hide()
    end,
}

-- [ref-025] Удаление: только удаляет, обновляет дропдаун в окне без перезапуска.
StaticPopupDialogs["KTOOLSLOOT_DELETE_PROFILE"] = {
    text         = L["DELETE_PROFILE_CONFIRM"],
    button1      = ACCEPT,
    button2      = CANCEL,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
    OnAccept = function()
        local uuid = KToolsLoot._pendingDeleteProfile
        if uuid then
            if KToolsLootProfileNames then KToolsLootProfileNames[uuid] = nil end
            KToolsLoot.db:DeleteProfile(uuid)
            KToolsLoot._pendingDeleteProfile = nil
            if refreshDeleteDropdown then refreshDeleteDropdown() end
        end
    end,
    OnCancel = function()
        KToolsLoot._pendingDeleteProfile = nil
        -- [bug-030] Сбросить выбор в дропдауне после отказа.
        if refreshDeleteDropdown then refreshDeleteDropdown() end
    end,
}
