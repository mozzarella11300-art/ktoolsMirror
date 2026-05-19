-- KTools_autoloot/core/autoloot.lua
-- Логика автоподбора лута. Слушает события WoW и решает, что брать.

-- itemClassID константы (Legion 7.x)
local CLASS_CONSUMABLE = 0   -- subclass 8 = Artifact Power (Other)
local CLASS_CONTAINER  = 1
local CLASS_WEAPON     = 2
local CLASS_ARMOR      = 4
local CLASS_TRADEGOOD  = 7   -- "Trade Goods" (реагенты)
local CLASS_RECIPE     = 9
local CLASS_QUEST      = 12
local CLASS_MISC       = 15  -- sub=0: лут-мешки Legion, sub=2: Pet, sub=4: токены, sub=5: Mount
local CLASS_BATTLEPET  = 17

-- GetLootSlotType: 1=item, 2=money, 3=currency (Legion 7.x WoW API)
local LOOT_SLOT_ITEM     = 1
local LOOT_SLOT_MONEY    = 2
local LOOT_SLOT_CURRENCY = 3

local function ItemIDFromLink(link)
    if not link then return nil end
    return tonumber(link:match("item:(%d+)"))
end

local function ItemQualityAndLevel(link)
    local _, _, quality, _, _, _, _, _, _, _, _, classID, subClassID = GetItemInfo(link)
    local ilvl = 0
    if GetDetailedItemLevelInfo then
        local effective = GetDetailedItemLevelInfo(link)
        ilvl = effective or 0
    end
    return quality, ilvl, classID, subClassID
end

local function IsEquipment(classID)
    return classID == CLASS_WEAPON or classID == CLASS_ARMOR
end

-- [bug-026] classID=1 (сумки) и classID=15/sub=0,4 (Legion лут-мешки и токены).
local function IsToken(classID, subClassID)
    if classID == CLASS_CONTAINER then return true end
    if classID == CLASS_MISC then
        return subClassID == 0 or subClassID == 4
    end
    return false
end

local function IsMount(classID, subClassID)
    return classID == CLASS_MISC and subClassID == 5
end

local function IsPet(classID, subClassID)
    if classID == CLASS_BATTLEPET then return true end
    if classID == CLASS_MISC and subClassID == 2 then return true end
    return false
end

-- classID/subClassID предварительная проверка для Силы артефакта.
local function IsArtifactPowerClass(classID, subClassID)
    return classID == CLASS_CONSUMABLE and subClassID == 8
end

-- [bug-031] Тултип-скан для точного определения Силы артефакта.
-- classID=0/sub=8 захватывает другие расходуемые, не являющиеся AP.
local _apScanTip = CreateFrame("GameTooltip", "KToolsLootAPScanTip", nil, "GameTooltipTemplate")
_apScanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
local _apCache = {}  -- [itemID] = true/false

local function IsArtifactPowerItem(itemID)
    if not itemID then return false end
    local cached = _apCache[itemID]
    if cached ~= nil then return cached end
    _apScanTip:ClearLines()
    _apScanTip:SetItemByID(itemID)
    if _apScanTip:NumLines() == 0 then
        -- данные предмета ещё не закэшированы — пропускаем, не кэшируем
        return false
    end
    for i = 1, _apScanTip:NumLines() do
        local line = _G["KToolsLootAPScanTipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                local lower = text:lower()
                if lower:find("artifact power", 1, true) or
                   lower:find("сила артефакта", 1, true) then
                    _apCache[itemID] = true
                    return true
                end
            end
        end
    end
    _apCache[itemID] = false
    return false
end

-- Проверяет, стоит ли подбирать слот.
function KToolsLoot:ShouldLoot(slot)
    local p = self:Profile()
    if not p or not p.enabled then return false end

    local slotType = GetLootSlotType and GetLootSlotType(slot)

    -- [bug-012] Деньги: тип 2 (LOOT_SLOT_MONEY), НЕ 1 (1 = обычный предмет).
    if (slotType == LOOT_SLOT_MONEY) or (LootSlotIsCoin and LootSlotIsCoin(slot)) then
        return p.gold
    end

    -- Валюта: тип 3 (LOOT_SLOT_CURRENCY).
    if (slotType == LOOT_SLOT_CURRENCY) or (LootSlotIsCurrency and LootSlotIsCurrency(slot)) then
        return p.currency
    end

    local _, _, _, _, _, _, isQuest = GetLootSlotInfo(slot)
    local link = GetLootSlotLink(slot)
    if not link then
        return isQuest and p.quest or false
    end

    local itemID = ItemIDFromLink(link)
    local quality, ilvl, classID, subClassID = ItemQualityAndLevel(link)

    -- Кастомный список (приоритет над всем кроме отключённого аддона)
    if p.useList and itemID and p.items[itemID] and p.items[itemID].active then
        local minIlvl = p.items[itemID].ilvl or 0
        if (ilvl or 0) >= minIlvl then return true end
    end

    if isQuest and p.quest then return true end
    if classID == CLASS_QUEST and p.quest then return true end

    if classID == CLASS_TRADEGOOD and p.reagents then return true end
    if classID == CLASS_RECIPE    and p.recipes  then return true end

    -- [bug-031] Сила артефакта: сначала быстрая проверка классов, затем скан тултипа.
    if p.artifact and IsArtifactPowerClass(classID, subClassID) then
        if IsArtifactPowerItem(itemID) then return true end
    end

    if IsToken(classID, subClassID) and p.tokens then return true end
    if IsMount(classID, subClassID)         and p.mounts   then return true end
    if IsPet(classID, subClassID)           and p.pets     then return true end

    -- [bug-014][bug-028] Фильтр качества — все предметы (не только экипировка).
    -- ilvl применяется только если задан (>0) и quality совпадает точно.
    if p.useQualityFilter then
        local minQ = p.quality or 2
        local minI = p.ilvl or 0
        if quality then
            if quality > minQ then
                return true
            elseif quality == minQ then
                if minI == 0 or (ilvl or 0) >= minI then
                    return true
                end
            end
        end
    end

    return false
end

-- [ref-032] Слоты с незакэшированными данными — повторная попытка при GET_ITEM_INFO_RECEIVED.
local pendingLootSlots = {}  -- [itemID] = slotIndex

-- [ref-036→bug-027] LOOT_OPENED: правильное состояние UI, нет пустых слотов.
-- [ref-035] Пустое окно закрываем мгновенно через CloseLoot().
function KToolsLoot:OnLootOpened()
    wipe(pendingLootSlots)
    local p = self:Profile()
    if not p or not p.enabled then return end
    local num = GetNumLootItems()
    if not num or num == 0 then
        CloseLoot()
        return
    end
    for slot = num, 1, -1 do
        if self:ShouldLoot(slot) then
            LootSlot(slot)
        else
            local link = GetLootSlotLink(slot)
            if link then
                local itemID = ItemIDFromLink(link)
                local _, _, _, _, _, _, _, _, _, _, _, classID = GetItemInfo(link)
                if classID == nil and itemID then
                    pendingLootSlots[itemID] = slot
                end
            end
        end
    end
end

function KToolsLoot:OnItemDataReceived(_, itemID)
    local slot = pendingLootSlots[itemID]
    if not slot then return end
    pendingLootSlots[itemID] = nil
    if not GetLootSlotLink(slot) then return end
    if self:ShouldLoot(slot) then LootSlot(slot) end
end

function KToolsLoot:OnLootClosed()
    wipe(pendingLootSlots)
end

-- [new-003] Снятие шкур: закрыть окно лута при начале каста.
-- В Legion UNIT_SPELLCAST_START: (event, unit, castGUID, spellID).
local SKINNING_SPELL_ID = 8613

function KToolsLoot:OnSpellcastStart(_, unit, _, spellID)
    if unit ~= "player" then return end
    local name = GetSpellInfo(spellID)
    if not name or name ~= GetSpellInfo(SKINNING_SPELL_ID) then return end
    local p = self:Profile()
    if not p or not p.enabled or not p.skinningClose then return end
    if IsLootWindowShown() then CloseLoot() end
end

function KToolsLoot:OnBindConfirm(_, slot)
    local p = self:Profile()
    if p and p.bopNoConfirm then
        ConfirmLootSlot(slot)
        StaticPopup_Hide("LOOT_BIND")
    end
end

function KToolsLoot:RegisterLootEvents()
    self:RegisterEvent("LOOT_OPENED",            "OnLootOpened")
    self:RegisterEvent("LOOT_CLOSED",            "OnLootClosed")
    self:RegisterEvent("LOOT_BIND_CONFIRM",      "OnBindConfirm")
    self:RegisterEvent("GET_ITEM_INFO_RECEIVED", "OnItemDataReceived")
    self:RegisterEvent("UNIT_SPELLCAST_START",   "OnSpellcastStart")
end
