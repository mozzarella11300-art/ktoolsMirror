# KTools — Reference Map

Репозиторий: `/home/user/ktoolsMirror/`
Все пути абсолютные. Цель — быстрый поиск паттернов при реализации компонентов KTools.

---

## 1. Текущая структура KTools

### Аддоны проекта

| Аддон | TOC Interface | Путь |
|---|---|---|
| KTools (фреймворк) | 70300 (Legion 7.3) | `/home/user/ktoolsMirror/KTools/` |
| KToolsAutoloot | 70300 | `/home/user/ktoolsMirror/KToolsAutoloot/` |
| KToolsTPH | — (пустой stub) | `/home/user/ktoolsMirror/KToolsTPH/` |

### KTools — ядро фреймворка

| Файл | Назначение |
|---|---|
| `/home/user/ktoolsMirror/KTools/KTools.toc` | TOC, SavedVariables: `KToolsMinimapDB` |
| `/home/user/ktoolsMirror/KTools/init.lua` | `KTools` (AceAddon), `RegisterModule`, `_onModuleSelected` |
| `/home/user/ktoolsMirror/KTools/window.lua` | `BuildWindow` (AceGUI Frame + TreeGroup), `OpenWindow`/`CloseWindow`/`ToggleWindow`, `_refreshNav` |
| `/home/user/ktoolsMirror/KTools/minimap.lua` | LibDataBroker + LibDBIcon, кнопка миникарты |
| `/home/user/ktoolsMirror/KTools/locale/enUS.lua` | `L["ERR_MODULE"]` |
| `/home/user/ktoolsMirror/KTools/locale/ruRU.lua` | Перевод ERR_MODULE |
| `/home/user/ktoolsMirror/KTools/locale/load.xml` | Загрузчик локалей |
| `/home/user/ktoolsMirror/KTools/lib/load.xml` | Загрузчик библиотек |

**Паттерн регистрации модуля в KTools:**
```lua
-- В стороннем аддоне (например KToolsAutoloot):
KTools:RegisterModule("autoloot", {
    title    = "Auto Loot",
    buildUI  = function(container) ... end,
})
```

**Паттерн окна (window.lua):**
- AceGUI `Frame` (800×600, minResize 800×600, strata HIGH)
- Внутри — AceGUI `TreeGroup` (layout Fill)
- При выборе узла дерева вызывается `KTools:_onModuleSelected(key, container)`
- Регистрация в `UISpecialFrames` → закрывается по Escape

### KToolsAutoloot

| Файл | Назначение |
|---|---|
| `/home/user/ktoolsMirror/KToolsAutoloot/KToolsAutoloot.toc` | TOC, SavedVariables: `KToolsLootDB KToolsLootProfileNames` |
| `/home/user/ktoolsMirror/KToolsAutoloot/init.lua` | `KToolsLoot` (AceAddon + AceEvent), `/ktloot`, `OnEnable → RegisterLootEvents` |
| `/home/user/ktoolsMirror/KToolsAutoloot/core/autoloot.lua` | `ShouldLoot`, `OnLootOpened`, `OnItemDataReceived`, `OnLootClosed`, `OnBindConfirm`, `OnSpellcastStart`, `RegisterLootEvents` |
| `/home/user/ktoolsMirror/KToolsAutoloot/core/profile.lua` | `DEFAULTS`, `InitDB` (AceDB-3.0), `Profile()` |
| `/home/user/ktoolsMirror/KToolsAutoloot/core/load.xml` | Загрузчик ядра |
| `/home/user/ktoolsMirror/KToolsAutoloot/ui/window.lua` | Полный UI: настройки, форма добавления, таблица предметов, IO-диалог, профили |
| `/home/user/ktoolsMirror/KToolsAutoloot/ui/minimap.lua` | Кнопка миникарты Autoloot |
| `/home/user/ktoolsMirror/KToolsAutoloot/ui/load.xml` | Загрузчик UI |
| `/home/user/ktoolsMirror/KToolsAutoloot/locale/enUS.lua` | ~50 строк EN |
| `/home/user/ktoolsMirror/KToolsAutoloot/locale/ruRU.lua` | ~50 строк RU |
| `/home/user/ktoolsMirror/KToolsAutoloot/locale/load.xml` | Загрузчик локалей |

---

## 2. ElvUI Plugin Registration (как подключить плагин к окну ElvUI Options)

### Механизм: LibElvUIPlugin-1.0

**Файл библиотеки:**
`/home/user/ktoolsMirror/reference/ElvUI/Libraries/LibElvUIPlugin-1.0/LibElvUIPlugin-1.0.lua`

Библиотека регистрирует плагин в секции «Plugins» окна ElvUI Options.  
Если `ElvUI_Config` уже загружен — callback вызывается немедленно.  
Если не загружен — callback ставится в очередь на событие `ADDON_LOADED` для `ElvUI_Config`.

**Ключевые функции:**

| Функция | Строка | Описание |
|---|---|---|
| `lib:RegisterPlugin(name, callback, isLib)` | 70 | Главная точка входа. `name` = имя аддона, `callback` = функция добавляющая опции |
| `lib:GetPluginOptions()` | 114 | Создаёт секцию `E.Options.args.plugins` (вызывается автоматически) |
| `lib:GeneratePluginList()` | 192 | Генерирует список плагинов с версиями (зелёный/красный) |
| `lib:VersionCheck(...)` | 154 | Проверяет версии плагинов в группе через addon message |

**Минимальный паттерн регистрации (по образцу ElvUI_LocPlus):**
```lua
-- В файле core.lua плагина:
local E, L, V, P, G = unpack(ElvUI)
local EP = LibStub("LibElvUIPlugin-1.0")
local addon, ns = ...

local MyModule = E:NewModule("MyModuleName", "AceEvent-3.0")

function MyModule:AddOptions()
    E.Options.args.myplugin = {
        order = 9000,
        type  = "group",
        name  = "My Plugin",
        args  = { ... },
    }
end

function MyModule:Initialize()
    -- инициализация...
    EP:RegisterPlugin(addon, MyModule.AddOptions)
end

local function InitializeCallback()
    MyModule:Initialize()
end

E:RegisterModule(MyModule:GetName(), InitializeCallback)
```

### ElvUI_Config — как устроено окно опций

**Файлы:**

| Файл | Назначение |
|---|---|
| `/home/user/ktoolsMirror/reference/ElvUI_Config/core.lua` | Создаёт `E.Options`, регистрирует в AceConfig-3.0, размер окна 890×651 |
| `/home/user/ktoolsMirror/reference/ElvUI_Config/profiles.lua` | Пресетные профили (Minimalistic и др.) |
| `/home/user/ktoolsMirror/reference/ElvUI_Config/General.lua` | Секция General в дереве |
| `/home/user/ktoolsMirror/reference/ElvUI_Config/actionbars.lua` | Секция ActionBars |
| `/home/user/ktoolsMirror/reference/ElvUI_Config/unitframes.lua` | Секция UnitFrames |
| `/home/user/ktoolsMirror/reference/ElvUI_Config/datatexts.lua` | Секция DataTexts |
| `/home/user/ktoolsMirror/reference/ElvUI_Config/auras.lua` | Секция Auras |
| `/home/user/ktoolsMirror/reference/ElvUI_Config/bags.lua` | Секция Bags |
| `/home/user/ktoolsMirror/reference/ElvUI_Config/chat.lua` | Секция Chat |
| `/home/user/ktoolsMirror/reference/ElvUI_Config/nameplates.lua` | Секция Nameplates |
| `/home/user/ktoolsMirror/reference/ElvUI_Config/skins.lua` | Секция Skins |
| `/home/user/ktoolsMirror/reference/ElvUI_Config/tooltip.lua` | Секция Tooltip |
| `/home/user/ktoolsMirror/reference/ElvUI_Config/tag_info.lua` | Информация о тегах |
| `/home/user/ktoolsMirror/reference/ElvUI_Config/maps.lua` | Секция Maps |
| `/home/user/ktoolsMirror/reference/ElvUI_Config/DataBars.lua` | Секция DataBars |
| `/home/user/ktoolsMirror/reference/ElvUI_Config/filters.lua` | Секция Filters |

**Ключевые строки в core.lua:**
```lua
-- строка 9-10
local AC  = LibStub("AceConfig-3.0-ElvUI")
local ACD = LibStub("AceConfigDialog-3.0-ElvUI")
local ACR = LibStub("AceConfigRegistry-3.0-ElvUI")

-- строка 22-23
AC:RegisterOptionsTable("ElvUI", E.Options)
ACD:SetDefaultSize("ElvUI", 890, 651)

-- строка 26-29: обновление GUI после смены профиля
function E:RefreshGUI()
    self:RefreshCustomTextsConfigs()
    ACR:NotifyChange("ElvUI")
end

-- строка 31: корневые args (плагины добавляются сюда же)
E.Options.args = { ... }
```

### ElvUI_LocPlus — простой однофайловый плагин

**Файлы:**

| Файл | Назначение |
|---|---|
| `/home/user/ktoolsMirror/reference/ElvUI_LocPlus/core.lua` | Модуль `LocationPlus`, `Initialize`, `RegisterPlugin` на строке 543 |
| `/home/user/ktoolsMirror/reference/ElvUI_LocPlus/options.lua` | `P['locplus']` defaults (стр. 11–63), `LP:AddOptions()` (стр. 69+) |
| `/home/user/ktoolsMirror/reference/ElvUI_LocPlus/tooltip.lua` | Логика тултипа |

**Паттерн AddOptions (options.lua, строка 69):**
```lua
function LP:AddOptions()
    E.Options.args.locplus = {
        order = 9000,          -- позиция в левом дереве
        type  = "group",
        name  = L["Location Plus"],
        args  = {
            -- header
            name = { order = 1, type = "header", name = "..." },
            -- inline-группа настроек
            general = {
                order      = 5,
                type       = "group",
                name       = SHOW,
                guiInline  = true,
                get = function(info) return E.db.locplus[ info[#info] ] end,
                set = function(info, value) E.db.locplus[ info[#info] ] = value end,
                args = {
                    LoginMsg = {
                        order = 1,
                        name  = L["Login Message"],
                        type  = "toggle",
                        width = "full",
                    },
                },
            },
        },
    }
end
```

**Паттерн defaults (options.lua, строка 11):**
```lua
P['locplus'] = {
    ['LoginMsg'] = true,
    ['lpfont']   = E.db.general.font,
    ['lpwidth']  = 200,
    -- ...
}
```

### ElvUI_SLE — многомодульный плагин с deferred config

**Файлы — ядро:**

| Файл | Назначение |
|---|---|
| `/home/user/ktoolsMirror/reference/ElvUI_SLE/core/core.lua` | `SLE` (AceAddon), `GetOptions()`, `RegisterPlugin`, `PLAYER_LOGIN → Initialize` |
| `/home/user/ktoolsMirror/reference/ElvUI_SLE/core/globals.lua` | `SLE.Configs = {}` (стр. 61), глобальные переменные |
| `/home/user/ktoolsMirror/reference/ElvUI_SLE/core/toolkit.lua` | Утилиты (`Toolkit.pairs`, `Toolkit.tinsert` и др.) |
| `/home/user/ktoolsMirror/reference/ElvUI_SLE/core/communicate.lua` | AceComm коммуникация |
| `/home/user/ktoolsMirror/reference/ElvUI_SLE/core/dropdown.lua` | Кастомный dropdown |
| `/home/user/ktoolsMirror/reference/ElvUI_SLE/core/gameMenu.lua` | Интеграция с игровым меню |
| `/home/user/ktoolsMirror/reference/ElvUI_SLE/core/install.lua` | Установщик/визард |
| `/home/user/ktoolsMirror/reference/ElvUI_SLE/core/media.lua` | LSM медиа |
| `/home/user/ktoolsMirror/reference/ElvUI_SLE/core/staticpopups.lua` | StaticPopup диалоги |
| `/home/user/ktoolsMirror/reference/ElvUI_SLE/defaults/private.lua` | Private DB defaults (V) |
| `/home/user/ktoolsMirror/reference/ElvUI_SLE/defaults/profile.lua` | Profile DB defaults (P) |

**Paттерн deferred config (core.lua, строки 37–52):**
```lua
-- Все модули добавляют свои config-функции в этот массив
SLE.Configs = {}   -- инициализируется в globals.lua

-- Callback для RegisterPlugin: вызывает все накопленные config-функции
local function GetOptions()
    for _, func in Toolkit.pairs(SLE.Configs) do
        func()
    end
end

-- Запуск по PLAYER_LOGIN
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function() SLE:Initialize() end)

-- В SLE:Initialize():
LibStub("LibElvUIPlugin-1.0"):RegisterPlugin(AddOnName, GetOptions)
```

**Паттерн модульного config-файла (например, actionbars_c.lua):**
```lua
local function configTable()
    if not SLE.initialized then return end
    E.Options.args.sle.args.modules.args.actionbars = {
        type = "group",
        name = L["ActionBars"],
        args = { ... },
    }
end

T.tinsert(SLE.Configs, configTable)   -- добавляем в очередь
```

**Файлы — опции (каждый вставляет в SLE.Configs):**

| Файл | Секция |
|---|---|
| `/home/user/ktoolsMirror/reference/ElvUI_SLE/options/core_c.lua` | Инициализирует `E.Options.args.sle` |
| `/home/user/ktoolsMirror/reference/ElvUI_SLE/options/actionbars_c.lua` | ActionBars |

---

## 3. ElvUI Import/Export профилей

Эталонная реализация. Для KTools следует применять аналогичный подход.

### Основной файл

`/home/user/ktoolsMirror/reference/ElvUI/core/distributor.lua` (548 строк)

**Ключевые функции:**

| Функция | Строка | Описание |
|---|---|---|
| `D:Initialize()` | 33 | Регистрирует comm-префиксы, создаёт statusBar |
| `D:Distribute(target, otherServer, isGlobal)` | 50 | Шаринг профиля через AceComm (whisper/raid/party) |
| `GetProfileData(profileType)` | ~240 | Извлекает данные профиля по типу |
| `GetProfileExport(profileType, exportFormat)` | 295 | **Генерирует строку экспорта с кодированием** |
| `D:CreateProfileExport(dataString, profileType, profileKey)` | 322 | Формирует строку `data::type::key` |
| `D:GetImportStringType(dataString)` | 334 | Определяет формат: `"Base64"` или `"Table"` |
| `D:Decode(dataString)` | 346 | **Декодирует строку импорта** |
| `SetImportedProfile(...)` | 407 | Применяет импортированный профиль |
| `D:ExportProfile(profileType, exportFormat)` | 450 | Публичный API экспорта |
| `D:ImportProfile(dataString)` | 461 | Публичный API импорта |

**Форматы экспорта:**
- `"text"` — Base64(Compress(Serialize(table))) — самый компактный
- `"luaTable"` — Lua table string — читаемый
- `"luaPlugin"` — plugin format

**Пайплайн экспорта (строки 304–309, формат "text"):**
```
Table Data
  → D:Serialize()          [AceSerializer-3.0]  → serialized string
  → LibCompress:Compress() [LibCompress]         → binary
  → LibBase64:Encode()     [LibBase64-1.0]       → base64 string
  → D:CreateProfileExport()                      → "base64data::profile::ProfileName"
```

**Пайплайн импорта (строки 346–405):**
```
Base64 string
  → LibBase64:Decode()         → compressed binary
  → LibCompress:Decompress()   → "serialized^^::profile::ProfileName"
  → E:SplitString(..., "^^::") → отделяем сериализованные данные от метаданных
  → D:Deserialize()            → table
  → SetImportedProfile()       → применяем к БД
```

**Разделители в строке импорта:**
- `"^^"` — конец AceSerializer данных
- `"^^::"` — разделитель data/metadata (Base64 формат)
- `"}::"` — разделитель data/metadata (Table формат)
- `"::"` — разделитель type::key внутри metadata

### Библиотеки кодирования

| Библиотека | Файл | Ключевые функции |
|---|---|---|
| AceSerializer-3.0 | `/home/user/ktoolsMirror/reference/ElvUI/Libraries/AceSerializer-3.0/AceSerializer-3.0.lua` | `Serialize(...)`, `Deserialize(data)` |
| LibCompress | `/home/user/ktoolsMirror/reference/ElvUI/Libraries/LibCompress/LibCompress.lua` | `Compress(text)`, `Decompress(text)` |
| LibBase64-1.0 | `/home/user/ktoolsMirror/reference/ElvUI/Libraries/LibBase64-1.0/LibBase64-1.0.lua` | `Encode(text)`, `Decode(text)`, `IsBase64(text)` |

### Типы маркеров AceSerializer (AceSerializer-3.0.lua, строки 54–100)

| Маркер | Тип |
|---|---|
| `^S` | string |
| `^N` | number |
| `^F` / `^f` | float (mantissa / exponent) |
| `^T` / `^t` | table (start / end) |
| `^B` / `^b` | boolean true / false |
| `^~` | nil |

### IO-диалог в KToolsAutoloot (текущая реализация без ElvUI)

Реализован в `/home/user/ktoolsMirror/KToolsAutoloot/ui/window.lua`.

**Формат строки:** `name:ProfileName|i:itemID,active[,ilvl],itemName|...`

**Функции:**

| Функция | Строка | Описание |
|---|---|---|
| `SerializeItems(p)` | ~74 | Сериализует профиль в строку |
| `ParseItemsString(str)` | ~91 | Парсит строку обратно в таблицу |
| `ShowIODialog(mode, exportData)` | ~133 | AceGUI Frame с MultiLineEditBox (600×480) |

---

## 4. Auto-Loot (автоподбор предметов)

### AutoLootPlus — минималистичная реализация

**Файл:** `/home/user/ktoolsMirror/reference/AutoLootPlus/AutoLootPlus.lua`

```lua
local LOOT_DELAY = 0.3
local frame = CreateFrame("Frame")
frame:RegisterEvent("LOOT_READY")   -- срабатывает дважды при открытии контейнера
frame:SetScript("OnEvent", function()
    if GetCVarBool("autoLootDefault") ~= IsModifiedClick("AUTOLOOTTOGGLE") then
        if (GetTime() - epoch) >= LOOT_DELAY then
            for i = GetNumLootItems(), 1, -1 do
                LootSlot(i)
            end
            epoch = GetTime()
        end
    end
end)
```

**Особенности:**
- Событие: `LOOT_READY` (не `LOOT_OPENED`)
- Задержка 0.3 сек для предотвращения дисконнекта
- Уважает CVar `autoLootDefault` + toggle key
- Итерация в обратном порядке (с конца)

### Leatrix_Plus — аналогичный подход

**Файл:** `/home/user/ktoolsMirror/reference/Leatrix_Plus/Leatrix_Plus.lua`

Строки 1510–1529 — идентичная логика:
- Событие: `LOOT_READY`
- Задержка: 0.3 сек
- Те же условия с `autoLootDefault` / `AUTOLOOTTOGGLE`
- Именуется "Faster Auto Loot"

### XLoot_Frame — расширенный автолут с фильтрами

**Файл:** `/home/user/ktoolsMirror/reference/XLoot_Frame/Frame.lua`

**Настройки автолута (строки 128–134):**
```lua
autoloots = {
    currency   = 'never',   -- валюта
    tradegoods = 'never',   -- реагенты
    quest      = 'never',   -- квест-предметы
    list       = 'solo',    -- из списка пользователя
    all        = 'never',   -- все предметы
}
autoloot_item_list = ''     -- список по именам, через запятую
```

**Состояния (строки 1068–1075):**
```lua
local auto_states = {
    always = true,   -- всегда
    group  = true,   -- в группе (фактически always)
    never  = false,  -- никогда
    solo   = nil,    -- только соло (nil = проверяется отдельно)
    party  = nil,    -- только в пати
    raid   = nil,    -- только в рейде
}
```

**Событие входа:** `LOOT_OPENED` (строка 1273) — главная точка входа.
**Задержка для BoP рефреша:** `C_Timer.After(0.8, BoPRefresh)` (строки 1240–1242).

**Фильтрация по типу слота (строки 1140–1211):**
```lua
local slotType = GetLootSlotType(slot)  -- 1=item, 2=money, 3=currency

-- Деньги и валюта
if (auto.all or auto.currency) and (slotType == LOOT_SLOT_MONEY or slotType == LOOT_SLOT_CURRENCY) then
    autoloot = true

-- Квест-предметы
elseif (auto.all or auto.quest) and (isQuestItem or startsQuest) then
    autoloot = true

-- Реагенты/список (с проверкой инвентаря)
elseif auto.all or (auto.list and auto_items[name]) or (auto.tradegoods and slotData.isCraftingReagent) then
    -- Проверка свободных ячеек по bag family
    if bag_slots[0] > 0 or (bag_slots[family] and bag_slots[family] > 0) then
        autoloot = true
    else
        -- Проверка частичных стаков
        local partial = GetItemCount(link) % stackCount
        if partial > 0 and (partial + quantity < stackCount) then autoloot = true end
    end
end

if autoloot then LootSlot(slot) end
```

**Добавление в список из окна лута (строки 505–514):**
```lua
function RowPrototype:Auto_OnClick(button)
    opt.autoloot_item_list = opt.autoloot_item_list ~= '' and
        opt.autoloot_item_list .. ',' .. self.parent.item_name or
        self.parent.item_name
    self.parent.owner:ParseAutolootList()
    self.parent:OnClick(button)
end
```

**Дополнительные файлы XLoot:**

| Файл | Назначение |
|---|---|
| `/home/user/ktoolsMirror/reference/XLoot_Frame/Frame.lua` | Основной фрейм лута + автолут |
| `/home/user/ktoolsMirror/reference/XLoot_Frame/localization.lua` | Локализация XLoot_Frame |
| `/home/user/ktoolsMirror/reference/XLoot_Master/Master.lua` | Master loot distribution: `GetMasterLootCandidate`, `GiveMasterLoot` |
| `/home/user/ktoolsMirror/reference/XLoot_Monitor/Monitor.lua` | Мониторинг: `LibStub("LootEvents"):RegisterLootCallback(...)` |
| `/home/user/ktoolsMirror/reference/XLoot_Monitor/events.lua` | `LootEvents` lib — парсинг чат-событий лута |
| `/home/user/ktoolsMirror/reference/XLoot_Options/` | UI опций XLoot |
| `/home/user/ktoolsMirror/reference/XLoot_Group/` | Group loot |

### KToolsAutoloot — текущая реализация

**Файл:** `/home/user/ktoolsMirror/KToolsAutoloot/core/autoloot.lua`

**Событие входа:** `LOOT_OPENED` (Legion API, не LOOT_READY).

**Ключевые константы:**
```lua
-- Slot types (Legion 7.x)
LOOT_SLOT_ITEM     = 1
LOOT_SLOT_MONEY    = 2
LOOT_SLOT_CURRENCY = 3

-- Item class IDs (Legion 7.x)
CLASS_CONSUMABLE = 0   -- sub=8: Artifact Power
CLASS_CONTAINER  = 1   -- сумки
CLASS_WEAPON     = 2
CLASS_ARMOR      = 4
CLASS_TRADEGOOD  = 7   -- реагенты
CLASS_RECIPE     = 9
CLASS_QUEST      = 12
CLASS_MISC       = 15  -- sub=0: loot bags, sub=2: Pet, sub=4: tokens, sub=5: Mount
CLASS_BATTLEPET  = 17
```

**Функция решения `ShouldLoot(slot)` (строка 98):**
1. Деньги → `p.gold`
2. Валюта → `p.currency`
3. Кастомный список (приоритет) → `p.useList && p.items[itemID].active`
4. Квест-предмет → `p.quest`
5. Реагенты `classID=7` → `p.reagents`
6. Рецепты `classID=9` → `p.recipes`
7. Сила артефакта `classID=0/sub=8` + tooltip-scan → `p.artifact`
8. Токены / Mount / Pet → `p.tokens / p.mounts / p.pets`
9. Фильтр качества + ilvl → `p.useQualityFilter, p.quality, p.ilvl`

**Обработка незакэшированных предметов:**
- Незакэшированные (GetItemInfo вернул nil для classID) → `pendingLootSlots[itemID] = slot`
- `GET_ITEM_INFO_RECEIVED` → повторная попытка для pending слотов

**Все события:**
```lua
"LOOT_OPENED"            → OnLootOpened
"LOOT_CLOSED"            → OnLootClosed
"LOOT_BIND_CONFIRM"      → OnBindConfirm      (p.bopNoConfirm)
"GET_ITEM_INFO_RECEIVED" → OnItemDataReceived  (retry uncached)
"UNIT_SPELLCAST_START"   → OnSpellcastStart    (skinning: spellID=8613)
```

**Профиль (profile.lua):**
```lua
-- AceDB defaults
profile = {
    enabled = true,
    -- Quick categories
    quest=true, gold=true, currency=true,
    reagents=false, recipes=false, artifact=false,
    mounts=false, pets=false, tokens=false,
    bopNoConfirm=false, skinningClose=false,
    -- Quality filter
    useQualityFilter=false, quality=2, ilvl=0,
    -- Custom list
    useList=false,
    items={},   -- [itemID] = { active, ilvl, name }
}
```

---

## 5. AceConfig options — типы и свойства

Используется в ElvUI и любом AceConfig-3.0 плагине.

### Типы

| type | Описание | Пример |
|---|---|---|
| `"group"` | Контейнер для дочерних опций | Секция, подраздел |
| `"toggle"` | Чекбокс (boolean) | Enable/Disable |
| `"range"` | Слайдер (min/max/step) | Размер шрифта |
| `"select"` | Выпадающий список | Выбор значения |
| `"color"` | Color picker (r,g,b,a) | Цвет рамки |
| `"input"` | Текстовое поле | Имя профиля |
| `"execute"` | Кнопка | Reset, Install |
| `"description"` | Статический текст | Описание секции |
| `"header"` | Жирный заголовок | Название секции |
| `"multiselect"` | Множественный выбор | Флаги |

### Стандартные свойства

```lua
{
    order    = 1,                              -- порядок в родительском args
    type     = "toggle",
    name     = L["Option Name"],              -- лейбл
    desc     = L["Tooltip"],                  -- подсказка при наведении
    width    = "full",                        -- "half", "full", "double"
    get      = function(info) return E.db.plugin[ info[#info] ] end,
    set      = function(info, value)
                    E.db.plugin[ info[#info] ] = value
                    MyModule:Update()
               end,
    hidden   = function() return not condition end,
    disabled = function() return not condition end,
}
```

### guiInline — инлайн-группа

```lua
general = {
    order     = 5,
    type      = "group",
    name      = "General",
    guiInline = true,     -- рендерится внутри родителя, не как отдельный пункт дерева
    get = function(info) return E.db.plugin[ info[#info] ] end,
    set = function(info, value) E.db.plugin[ info[#info] ] = value end,
    args = { ... },
}
```

---

## 6. Библиотеки в reference/lib

`/home/user/ktoolsMirror/reference/lib/` — эталонные копии внешних библиотек.

| Библиотека | Путь | Применение |
|---|---|---|
| AceAddon-3.0 | `reference/lib/AceAddon-3.0/` | Основа любого аддона |
| AceDB-3.0 | `reference/lib/AceDB-3.0/` | SavedVariables с профилями |
| AceEvent-3.0 | `reference/lib/AceEvent-3.0/` | `RegisterEvent`, `UnregisterEvent` |
| AceGUI-3.0 | `reference/lib/AceGUI-3.0/` | Виджеты: Frame, TreeGroup, Button, etc. |
| AceLocale-3.0 | `reference/lib/AceLocale-3.0/` | Локализация |
| AceConsole-3.0 | `reference/lib/AceConsole-3.0/` | Chat commands |
| AceTimer-3.0 | `reference/lib/AceTimer-3.0/` | `ScheduleTimer`, `ScheduleRepeatingTimer` |
| AceHook-3.0 | `reference/lib/AceHook-3.0/` | `Hook`, `SecureHook` |
| AceComm-3.0 | `reference/lib/AceComm-3.0/` | Addon messages |
| AceSerializer-3.0 | `reference/lib/AceSerializer-3.0/` | Serialize/Deserialize |
| AceConfig-3.0 | `reference/lib/AceConfig-3.0/` | Options registration |
| AceDBOptions-3.0 | `reference/lib/AceDBOptions-3.0/` | Profile UI panel |
| LibStub | `reference/lib/LibStub/` | Загрузчик библиотек |
| LibDBIcon-1.0 | `reference/lib/LibDBIcon-1.0/` | Кнопка миникарты |
| LibDataBroker-1.1 | `reference/lib/LibDataBroker-1.1/` | Data broker launcher |
| LibSharedMedia-3.0 | `reference/lib/LibSharedMedia-3.0/` | Шрифты, текстуры, звуки |
| LibDeflate | `reference/lib/LibDeflate/` | Альтернативная компрессия |
| LibWindow-1.1 | `reference/lib/LibWindow-1.1/` | Позиционирование окон |
| LibItemCache-1.1 | `reference/lib/LibItemCache-1.1/` | Кэш предметов |
| LibItemSearch-1.2 | `reference/lib/LibItemSearch-1.2/` | Поиск предметов |
| CallbackHandler-1.0 | `reference/lib/CallbackHandler-1.0/` | Events/callbacks |

---

## 7. Другие reference-аддоны (краткий обзор)

### Bagnon / Bagnon_Config

| Файл | Назначение |
|---|---|
| `/home/user/ktoolsMirror/reference/Bagnon/` | Расширенные сумки |
| `/home/user/ktoolsMirror/reference/Bagnon_Config/` | Конфиг Bagnon |
| `/home/user/ktoolsMirror/reference/Bagnon_GuildBank/` | Банк гильдии |
| `/home/user/ktoolsMirror/reference/Bagnon_VoidStorage/` | Войд-хранилище |
| `/home/user/ktoolsMirror/reference/BagBrother/` | Shared bag data |

### HandyNotes

| Файл | Назначение |
|---|---|
| `/home/user/ktoolsMirror/reference/HandyNotes/` | Заметки на карте |
| `/home/user/ktoolsMirror/reference/HandyNotes_LegionRaresTreasures/` | Legion rares/treasures |

### ExRT (Exorsus Raid Tools)

`/home/user/ktoolsMirror/reference/ExRT/` — рейдовый инструментарий.

---

## 8. Паттерн E, L, V, P, G (ElvUI globals)

```lua
local E, L, V, P, G = unpack(ElvUI)
-- E = Engine (основной объект ElvUI)
-- L = Locales (переводы)
-- V = PrivateDB defaults (персонажные данные)
-- P = ProfileDB defaults (профильные настройки)
-- G = GlobalDB defaults (аккаунтные настройки)
```

Дефолты плагина добавляются в соответствующую таблицу:
```lua
P['myplugin'] = { enabled = true, size = 12 }   -- профильные
G['myplugin'] = { globalSetting = false }        -- аккаунтные
V['myplugin'] = { privateData = {} }             -- персонажные
```

---

## 9. AceDB-3.0 — система профилей (deep dive)

**Файлы:**
- `/home/user/ktoolsMirror/reference/lib/AceDB-3.0/AceDB-3.0.lua` (747 строк)
- `/home/user/ktoolsMirror/reference/lib/AceDB-3.0/AceDB-3.0.xml`

### Инициализация

```lua
db = LibStub("AceDB-3.0"):New(tbl, defaults, defaultProfile)
```

| Параметр | Тип | Описание |
|---|---|---|
| `tbl` | string или table | Имя SavedVariables (строка) или таблица |
| `defaults` | table | `{ profile={}, global={}, char={}, ... }` |
| `defaultProfile` | string или `true` | Имя профиля или `true` для системного "Default" |

### Scopes — области хранения

| Scope | Когда применяется | Ключ разделения |
|---|---|---|
| `profile` | Активный пользовательский профиль | profileKeys[charKey] → имя профиля |
| `char` | Конкретный персонаж | `"Name - Realm"` |
| `realm` | Все персонажи сервера | GetRealmName() |
| `class` | Все персонажи класса | UnitClass("player") |
| `race` | Все персонажи расы | UnitRace("player") |
| `faction` | Фракция | UnitFactionGroup |
| `factionrealm` | Фракция × сервер | faction.."-"..realm |
| `factionrealmregion` | + регион (новый) | + region |
| `locale` | Язык клиента | GetLocale() |
| `global` | Аккаунт целиком | без разделения |

`charKey = UnitName("player").." - "..GetRealmName()` (`AceDB-3.0.lua` строки 259–263).

### Структура SavedVariables после инициализации

```lua
KToolsLootDB = {
    profileKeys = {
        ["Имя - Сервер"] = "k1716259401234567",   -- [charKey] = profile UUID
    },
    profiles = {
        ["Default"]            = { ... },          -- AceDB системный default
        ["k1716259401234567"] = { ... },          -- наш UUID-профиль
    },
    global = { ... },
    char   = { ["Имя - Сервер"] = { ... } },
    -- другие scopes по мере использования
}
```

### Методы DBObject

| Метод | Сигнатура | Строка | Описание |
|---|---|---|---|
| `SetProfile` | `db:SetProfile(name)` | 430 | Переключает активный профиль |
| `GetCurrentProfile` | `db:GetCurrentProfile()` | 503 | Возвращает имя активного |
| `GetProfiles` | `db:GetProfiles(tbl?)` → table, count | 472 | Массив всех имён |
| `DeleteProfile` | `db:DeleteProfile(name, silent?)` | 510 | Не позволяет удалить текущий |
| `CopyProfile` | `db:CopyProfile(name, silent?)` | 549 | В активный из указанного |
| `ResetProfile` | `db:ResetProfile(noChildren?, noCallbacks?)` | 584 | Очистка + применение defaults |
| `ResetDB` | `db:ResetDB(defaultProfile?)` | 612 | Полный сброс БД |
| `RegisterDefaults` | `db:RegisterDefaults(defaults)` | 398 | Обновление defaults |
| `RegisterNamespace` | `db:RegisterNamespace(name, defaults?)` | 648 | Child-БД с общим профилем |
| `GetNamespace` | `db:GetNamespace(name, silent?)` | 678 | Получить существующий namespace |

### Smart defaults (метатаблицы, строки 92–135)

При обращении к отсутствующему ключу автоматически возвращается значение из `defaults`. Поддерживаются wildcard-ключи:

```lua
defaults = {
    profile = {
        items = {
            ["*"]  = { active = true, ilvl = 0 },  -- для любого ключа
            ["**"] = { ... },                      -- рекурсивно для вложенных
        },
    },
}
```

`["*"]` — шаблон одного уровня. `["**"]` — шаблон рекурсивно для всех вложенных таблиц.

### Callbacks (AceDB)

| Callback | Параметры | Когда |
|---|---|---|
| `OnNewProfile` | `(db, profileKey)` | Первый доступ к ранее не существовавшему профилю |
| `OnProfileChanged` | `(db, profileKey)` | После `SetProfile()` |
| `OnProfileShutdown` | `(db)` | Перед сменой профиля, чтобы сохранить состояние |
| `OnProfileCopied` | `(db, sourceProfileKey)` | После `CopyProfile()` |
| `OnProfileReset` | `(db)` | После `ResetProfile()` |
| `OnProfileDeleted` | `(db, profileKey)` | После `DeleteProfile()` |
| `OnDatabaseReset` | `(db)` | После `ResetDB()` |
| `OnDatabaseShutdown` | `(db)` | На PLAYER_LOGOUT (строка 362) |

**Регистрация:**
```lua
db.callbacks:RegisterCallback("OnProfileChanged", function(event, db, profileKey)
    MyAddon:RefreshUI()
end)
```

---

## 10. AceDBOptions-3.0 — готовый UI профилей

**Файл:** `/home/user/ktoolsMirror/reference/lib/AceDBOptions-3.0/AceDBOptions-3.0.lua` (461 строка)

### Применение

```lua
local AceDBOptions = LibStub("AceDBOptions-3.0")
local profilesTable = AceDBOptions:GetOptionsTable(db, noDefaultProfiles?)
-- Встроить в свою options table:
myOptions.args.profiles = profilesTable
```

### Встроенные опции (строки 353–434)

| Ключ | Тип | Назначение |
|---|---|---|
| `desc` | description | Шапка с инфо |
| `reset` | execute | Сброс активного профиля |
| `current` | description | Имя текущего профиля |
| `new` | input | Создать новый из defaults |
| `choose` | select | Переключить активный |
| `copyfrom` | select | Скопировать из другого |
| `delete` | select | Удалить (не текущий) |

### Handler-методы (OptionsHandlerPrototype, строки 268–322)

```lua
function OptionsHandlerPrototype:Reset()                       self.db:ResetProfile() end
function OptionsHandlerPrototype:SetProfile(info, value)       self.db:SetProfile(value) end
function OptionsHandlerPrototype:GetCurrentProfile()           return self.db:GetCurrentProfile() end
function OptionsHandlerPrototype:ListProfiles(info)            ... end
function OptionsHandlerPrototype:CopyProfile(info, value)      self.db:CopyProfile(value) end
function OptionsHandlerPrototype:DeleteProfile(info, value)    self.db:DeleteProfile(value) end
```

### Локализация

Встроена для: enUS (default), deDE, frFR, koKR, esES, esMX, zhTW, zhCN, ruRU, itIT, ptBR. Определение через `GetLocale()`.

### Двухуровневая схема профилей в KToolsAutoloot

Проблема: AceDB хранит профили по строковому имени, но пользователь может захотеть переименовать без потери данных.

Решение (`/home/user/ktoolsMirror/KToolsAutoloot/ui/window.lua` строки 57–68):

1. AceDB хранит данные под внутренним UUID: `db.profiles["k1716259401234567"]`
2. Отдельный SavedVariable `KToolsLootProfileNames[uuid] = "ИмяПрофиля"` хранит человекочитаемые имена

```lua
local function GenerateProfileID()
    return string.format("k%d%06d", time(), math.random(100000, 999999))
end

local function GetDisplayName(uuid)
    if uuid == "Default" then return "Default" end
    return (KToolsLootProfileNames and KToolsLootProfileNames[uuid]) or uuid
end
```

При создании профиля (window.lua строки 695–725):
```lua
local newID = GenerateProfileID()
KToolsLootProfileNames[newID] = userInputName
KToolsLoot.db:SetProfile(newID)
```

При удалении (строки 728–749):
```lua
KToolsLootProfileNames[uuid] = nil
KToolsLoot.db:DeleteProfile(uuid)
```

---

## 11. API библиотек (подробно)

### 11.1. LibStub

**Файл:** `/home/user/ktoolsMirror/reference/lib/LibStub/LibStub.lua`

```lua
LibStub:NewLibrary(major, minor)   -- создаёт/обновляет; (lib, oldminor) или nil
LibStub:GetLibrary(major, silent?) -- получает существующую; (lib, minor)
LibStub(major, silent?)            -- shorthand для GetLibrary
LibStub:IterateLibraries()         -- итератор по всем
```

`minor` — числовое ревью. Новая регистрация с меньшим/равным minor возвращает nil → старая версия остаётся.

### 11.2. CallbackHandler-1.0

**Файл:** `/home/user/ktoolsMirror/reference/lib/CallbackHandler-1.0/CallbackHandler-1.0.lua`

```lua
local CB = LibStub("CallbackHandler-1.0")
target.callbacks = CB:New(target, "RegisterCallback", "UnregisterCallback", "UnregisterAllCallbacks")
-- встраивает в target:
target:RegisterCallback(event, method [, arg])  -- method = string или function
target:UnregisterCallback(event)
target:UnregisterAllCallbacks([owner...])
-- внутри source:
target.callbacks:Fire(event, ...)
```

### 11.3. LibDataBroker-1.1

**Файл:** `/home/user/ktoolsMirror/reference/lib/LibDataBroker-1.1/LibDataBroker-1.1.lua`

```lua
local LDB = LibStub("LibDataBroker-1.1")
local dataobj = LDB:NewDataObject(name, {
    type    = "launcher",   -- или "data source"
    text    = "...",
    icon    = "Interface\\...",
    label   = "...",        -- опционально
    OnClick       = function(self, button) ... end,
    OnEnter       = function(self) ... end,
    OnLeave       = function(self) ... end,
    OnTooltipShow = function(tt) ... end,
})

LDB:DataObjectIterator()
LDB:GetDataObjectByName(name)
LDB:GetNameByDataObject(obj)
LDB:pairs(name_or_obj)   -- по атрибутам
```

**Callbacks (через CallbackHandler):**
- `LibDataBroker_DataObjectCreated`
- `LibDataBroker_AttributeChanged`
- `LibDataBroker_AttributeChanged_{name}`
- `LibDataBroker_AttributeChanged_{name}_{key}`
- `LibDataBroker_AttributeChanged__{key}`

### 11.4. LibDBIcon-1.0

**Файл:** `/home/user/ktoolsMirror/reference/lib/LibDBIcon-1.0/LibDBIcon-1.0.lua`

```lua
local DBIcon = LibStub("LibDBIcon-1.0")
DBIcon:Register(name, dataobj, savedDB)
-- savedDB = { hide=false, minimapPos=220, lock=false, radius=80 }

DBIcon:Hide(name)
DBIcon:Show(name)
DBIcon:Lock(name)
DBIcon:Unlock(name)
DBIcon:Refresh(name, db?)
DBIcon:IsRegistered(name)
DBIcon:GetMinimapButton(name)   -- возвращает frame
```

**Поддерживаемые поля dataobj:** `icon`, `iconCoords = {l,r,t,b}`, `iconR`, `iconG`, `iconB`.

**Применение в KTools** (`/home/user/ktoolsMirror/KTools/minimap.lua`):
```lua
function KTools:SetupMinimap()
    local broker = LDB:NewDataObject(addonName, {
        type    = "launcher",
        text    = GetAddOnMetadata(addonName, "Title"),
        icon    = "Interface\\AddOns\\"..addonName.."\\media\\textures\\minimapButton_dx5",
        OnClick = function() KTools:ToggleWindow() end,
        OnTooltipShow = function(tt) tt:AddLine(...) end,
    })
    DBIcon:Register(addonName, broker, KToolsMinimapDB)
end
```

### 11.5. LibSharedMedia-3.0

**Файл:** `/home/user/ktoolsMirror/reference/lib/LibSharedMedia-3.0/LibSharedMedia-3.0.lua`

```lua
local LSM = LibStub("LibSharedMedia-3.0")
LSM:Register(mediatype, key, data, langmask?)
LSM:Fetch(mediatype, key, noDefault?)        -- путь или дефолт
LSM:HashTable(mediatype)                      -- { key=path, ... }
LSM:List(mediatype)                           -- {"key1","key2",...} (отсортирован)
LSM:IsValid(mediatype, key)
LSM:GetGlobal(mediatype)
LSM:SetGlobal(mediatype, key)
LSM:GetDefault(mediatype)
LSM:SetDefault(mediatype, key)
```

**Mediatypes:** `"font"`, `"statusbar"`, `"sound"`, `"border"`, `"background"`.

**Callbacks:** `LibSharedMedia_Registered`, `LibSharedMedia_SetGlobal`.

Локализованные дефолты шрифтов: для ruRU — "Friz Quadrata TT", "2002", "Morpheus", "Skurri".

### 11.6. AceAddon-3.0

**Файл:** `/home/user/ktoolsMirror/reference/lib/AceAddon-3.0/AceAddon-3.0.lua`

```lua
addon = LibStub("AceAddon-3.0"):NewAddon([object,] name [, lib1, lib2, ...])
-- lib1...: "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0", ...

-- Lifecycle (вызываются автоматически):
function addon:OnInitialize() end   -- сразу после загрузки
function addon:OnEnable()    end   -- на PLAYER_LOGIN
function addon:OnDisable()   end   -- при выключении

-- Модули:
local mod = addon:NewModule(name [, prototype] [, lib1, ...])
addon:GetModule(name, silent?)
for n, m in addon:IterateModules() do end
addon:EnableModule(name)
addon:DisableModule(name)

-- Defaults для дочерних модулей:
addon:SetDefaultModuleLibraries(lib1, lib2, ...)
addon:SetDefaultModuleState(true_or_false)
addon:SetDefaultModulePrototype(proto)

-- Управление:
addon:Enable() / addon:Disable() / addon:IsEnabled() / addon:GetName()

-- Доступ из любого места:
LibStub("AceAddon-3.0"):GetAddon(name, silent?)
```

### 11.7. AceEvent-3.0

**Файл:** `/home/user/ktoolsMirror/reference/lib/AceEvent-3.0/AceEvent-3.0.lua`

После embed в объект:
```lua
self:RegisterEvent(event [, callback [, arg]])
self:UnregisterEvent(event)
self:UnregisterAllEvents()

-- Внутренние сообщения AceEvent:
self:RegisterMessage(msg [, callback [, arg]])
self:UnregisterMessage(msg)
self:UnregisterAllMessages()
self:SendMessage(msg, ...)
```

`callback` — строка (имя метода) или функция. По умолчанию ищется метод `self[event]`.

### 11.8. AceTimer-3.0

**Файл:** `/home/user/ktoolsMirror/reference/lib/AceTimer-3.0/AceTimer-3.0.lua`

```lua
local handle = self:ScheduleTimer(func, delay, ...)           -- однократно
local handle = self:ScheduleRepeatingTimer(func, delay, ...)  -- повторяющийся
self:CancelTimer(handle)
self:CancelAllTimers()
local left = self:TimeLeft(handle)
```

`delay` минимум 0.01 сек.

### 11.9. AceHook-3.0

**Файл:** `/home/user/ktoolsMirror/reference/lib/AceHook-3.0/AceHook-3.0.lua`

```lua
-- Safe hook (pre): не модифицирует аргументы, оригинал вызывается автоматически
self:Hook([obj], method [, handler] [, hookSecure])

-- Raw hook: оригинал в self.hooks[obj][method] (или self.hooks[method]); надо вызвать вручную
self:RawHook([obj], method [, handler] [, hookSecure])

-- Secure hook (post): после оригинала, без вмешательства
self:SecureHook([obj], method [, handler])

-- Для скриптов фреймов:
self:HookScript(frame, script [, handler])
self:RawHookScript(frame, script [, handler])
self:SecureHookScript(frame, script [, handler])

self:Unhook([obj], method)
self:UnhookAll()
self:IsHooked([obj], method)
```

### 11.10. AceLocale-3.0

**Файл:** `/home/user/ktoolsMirror/reference/lib/AceLocale-3.0/AceLocale-3.0.lua`

```lua
-- Регистрация (в enUS-файле):
local L = LibStub("AceLocale-3.0"):NewLocale("MyAddon", "enUS", true)
if L then
    L["KEY_FOO"] = true           -- true заменится на "KEY_FOO"
    L["KEY_BAR"] = "English text"
end

-- Регистрация (в ruRU-файле):
local L = LibStub("AceLocale-3.0"):NewLocale("MyAddon", "ruRU")
if not L then return end
L["KEY_BAR"] = "Русский текст"

-- Использование:
local L = LibStub("AceLocale-3.0"):GetLocale("MyAddon")
print(L["KEY_BAR"])
```

**Поведение при отсутствующем ключе:**
- По умолчанию — warning + возврат самого ключа
- `silent=true` — молча возвращает ключ
- `silent="raw"` — возвращает nil

### 11.11. LibDeflate

**Файл:** `/home/user/ktoolsMirror/reference/lib/LibDeflate/LibDeflate.lua`

Современная альтернатива LibCompress (RFC1950/1951):

```lua
local LD = LibStub("LibDeflate")

-- Компрессия:
local c = LD:CompressDeflate(str [, configs])
local c = LD:CompressZlib(str [, configs])        -- + zlib header + Adler-32
local c = LD:CompressDeflateWithDict(str, dict [, configs])
local c = LD:CompressZlibWithDict(str, dict [, configs])

-- Декомпрессия:
local s = LD:DecompressDeflate(c)
local s = LD:DecompressZlib(c)
local s = LD:DecompressDeflateWithDict(c, dict)
local s = LD:DecompressZlibWithDict(c, dict)

-- Кодирование для передачи:
LD:EncodeForPrint(str) / DecodeForPrint(str)                       -- безопасные печатные символы
LD:EncodeForWoWAddonChannel(str) / DecodeForWoWAddonChannel(str)   -- для CHAT_MSG_ADDON
LD:EncodeForWoWChatChannel(str) / DecodeForWoWChatChannel(str)     -- для обычного чата

LD:Adler32(str)
LD:CreateDictionary(str, strlen, adler32)
LD:CreateCodec(reserved, escape)
```

**Когда вместо LibCompress + LibBase64:** Современный код, лучшая совместимость с внешними утилитами, ниже размер.

### 11.12. LibWindow-1.1

**Файл:** `/home/user/ktoolsMirror/reference/lib/LibWindow-1.1/LibWindow-1.1.lua`

Сохраняет позицию окна между сессиями:

```lua
LibWindow.RegisterConfig(frame, storage, names?)
-- storage обычно из SavedVariables
-- names = { prefix = "myaddon_" } для уникальности

LibWindow.SavePosition(frame)   -- сохранить текущую позицию
```

Автоматически определяет ближайший якорь экрана (LEFT/RIGHT/CENTER × TOP/BOTTOM/CENTER), сохраняет масштаб.

### 11.13. LibItemCache-1.1 и LibItemSearch-1.2

**Файлы:**
- `/home/user/ktoolsMirror/reference/lib/LibItemCache-1.1/Core.lua`
- `/home/user/ktoolsMirror/reference/lib/LibItemSearch-1.2/LibItemSearch-1.2.lua`

**LibItemCache:**
```lua
local cls, race, sex, faction = Lib:GetPlayerInfo(player)
local money, isCached = Lib:GetPlayerMoney(player)
local guild = Lib:GetPlayerGuild(player)
local realm, player = Lib:GetPlayerAddress(addr)
for i, p in Lib:IteratePlayers() do end
for i, p in Lib:IterateAlliedPlayers() do end
for i, r in Lib:IterateRealms() do end
Lib:DeletePlayer(player)
Lib:IsPlayerCached(player)
Lib:GetBagInfo(player, bag)
-- Константы: Lib.PLAYER, Lib.FACTION, Lib.REALM
```

**LibItemSearch:**
```lua
local ok = Lib:Matches(link, search)
local ok = Lib:Tooltip(link, search)
local ok = Lib:TooltipPhrase(link, search)
local ok = Lib:InSet(link, search)
```

Поддерживаемые фильтры: `name`/`n`, `type`/`t`, `slot`/`s`, `level`/`l`/`lvl`/`ilvl`, `requiredlevel`/`r`/`req`/`rl`/`reqlvl`, `quality`/`q`, `usable`, `tooltip`/`tt`/`tip`.

Синтаксис: `n:sword & q:epic`, `level:>100`, `~quest`.

### 11.14. CustomSearch-1.0

**Файл:** `/home/user/ktoolsMirror/reference/lib/CustomSearch-1.0/CustomSearch-1.0.lua`

Кастомный движок поиска:

```lua
Lib:Matches(object, search, filters)
-- filter = {
--     tags     = {"n", "name"},
--     onlyTags = true_or_nil,
--     canSearch(filter, operator, search, object) → bool,
--     match(filter, object, operator, data)        → bool,
-- }

Lib:Clean(s)                  -- lowercase, escape, без акцентов
Lib:Find(search, str1, ...)   -- ищет search в строках
Lib.ACCENTS                   -- таблица замен (é → e и т.д.)
```

Операторы: `&` (AND), `|` (OR), `!`/`~`/`~=` (NOT), `<`/`>`/`<=`/`>=`/`=` (сравнение).

### 11.15. Unfit-1.0

**Файл:** `/home/user/ktoolsMirror/reference/lib/Unfit-1.0/Unfit-1.0.lua`

Может ли текущий класс использовать предмет:

```lua
Lib:IsItemUnusable(link_or_itemInfo)            -- true = не может
Lib:IsClassUnusable(classID, subClassID, slot)
-- Данные:
Lib.unusable                                     -- {class={subclass=true,...}}
Lib.cannotDual                                   -- может ли класс two-hand в каждой руке
```

---

## 12. Архитектура reference-аддонов (deep dive)

### 12.1. Bagnon — модульный фреймворк сумок

**Корень:** `/home/user/ktoolsMirror/reference/Bagnon/`

**TOC:** `## Interface: 70300`, `## SavedVariables: Bagnon_Sets`, `## OptionalDeps: BagBrother, ItemRack, Wardrobe, WoWUnit`

**Файлы:**
- `/home/user/ktoolsMirror/reference/Bagnon/Bagnon.toc`
- `/home/user/ktoolsMirror/reference/Bagnon/main.lua` — точка входа, `OnEnable`, создание фреймов
- `/home/user/ktoolsMirror/reference/Bagnon/Bindings.xml`
- `/home/user/ktoolsMirror/reference/Bagnon/components/brokerDisplay.lua`
- `/home/user/ktoolsMirror/reference/Bagnon/components/brokerPlugin.lua`
- `/home/user/ktoolsMirror/reference/Bagnon/components/components.xml`
- `/home/user/ktoolsMirror/reference/Bagnon/components/frame.lua` — главный фрейм
- `/home/user/ktoolsMirror/reference/Bagnon/components/itemFrame.lua`
- `/home/user/ktoolsMirror/reference/Bagnon/components/optionsToggle.lua`
- `/home/user/ktoolsMirror/reference/Bagnon/components/playerSelector.lua`
- `/home/user/ktoolsMirror/reference/Bagnon/components/searchFrame.lua`
- `/home/user/ktoolsMirror/reference/Bagnon/components/searchToggle.lua`
- `/home/user/ktoolsMirror/reference/Bagnon/components/titleFrame.lua`
- `/home/user/ktoolsMirror/reference/Bagnon/components/style.xml`
- `/home/user/ktoolsMirror/reference/Bagnon/external/external.xml`
- `/home/user/ktoolsMirror/reference/Bagnon/external/Wildpants/` — встроенная база (классы, кеш, поиск)

**Паттерн модулей:**
```lua
-- main.lua
local Guild = Bagnon:NewModule("GuildBank", Addon)
local Vault = Bagnon:NewModule("VoidStorage", Addon)
```

**Wildpants** — внутренний движок:
- `external/Wildpants/core/classes.lua` — `NewClass`, messaging
- `external/Wildpants/core/bags.lua`, `frames.lua`, `events.lua`
- `external/Wildpants/libs/LibItemCache-1.1`, `LibItemSearch-1.2`

**Доступ к профилю фрейма** (`components/frame.lua` стр. 19–23):
```lua
function Frame:New(id)
    local f = self:Bind(CreateFrame("Frame", ADDON.."Frame"..id, UIParent))
    f.profile = Addon.profile[id]
    f.frameID = id
    ...
end
```

### 12.2. Bagnon_Config — конфиг на Sushi-3.0

**Корень:** `/home/user/ktoolsMirror/reference/Bagnon_Config/`

**TOC:** `## Dependencies: Bagnon`, `## LoadOnDemand: 1`

**Файлы:**
- `/home/user/ktoolsMirror/reference/Bagnon_Config/Bagnon_Config.toc`
- `/home/user/ktoolsMirror/reference/Bagnon_Config/main.lua`
- `/home/user/ktoolsMirror/reference/Bagnon_Config/common/Wildpants_Config.xml`
- `/home/user/ktoolsMirror/reference/Bagnon_Config/common/group.lua`
- `/home/user/ktoolsMirror/reference/Bagnon_Config/common/panels.lua`
- `/home/user/ktoolsMirror/reference/Bagnon_Config/common/libs/Poncho-1.0/`
- `/home/user/ktoolsMirror/reference/Bagnon_Config/common/libs/Sushi-3.0/`

**Особенность:** НЕ использует AceGUI. **Sushi-3.0** — кастомная UI-библиотека с виджетами: Dropdown, CheckButton, Slider, Group, Tab, ColorPicker. **Poncho-1.0** — слой управления Sushi.

### 12.3. ExRT — собственный фреймворк

**Корень:** `/home/user/ktoolsMirror/reference/ExRT/`

**TOC:** `## Interface: 70300`, `## SavedVariables: VExRT`

**Файлы ядра:**
- `/home/user/ktoolsMirror/reference/ExRT/ExRT.toc`
- `/home/user/ktoolsMirror/reference/ExRT/core.lua` — `ExRT.mod`, `ExRT.Modules`, `ExRT.Options`, `ExRT.A`
- `/home/user/ktoolsMirror/reference/ExRT/Functions.lua`
- `/home/user/ktoolsMirror/reference/ExRT/ExLib.lua` — `ExRT.lib:Template()` (свои фреймы)
- `/home/user/ktoolsMirror/reference/ExRT/BlizzFix.lua`
- `/home/user/ktoolsMirror/reference/ExRT/Options.lua` — главное окно, `:Add(moduleName, frameName)`
- `/home/user/ktoolsMirror/reference/ExRT/Bindings.xml`
- `/home/user/ktoolsMirror/reference/ExRT/embeds.xml`

**Файлы модулей (24 модуля):**
- `/home/user/ktoolsMirror/reference/ExRT/Arrow.lua`
- `/home/user/ktoolsMirror/reference/ExRT/AutoLogging.lua`
- `/home/user/ktoolsMirror/reference/ExRT/BattleRes.lua`
- `/home/user/ktoolsMirror/reference/ExRT/BossWatcher.lua`
- `/home/user/ktoolsMirror/reference/ExRT/Bossmods.lua`
- `/home/user/ktoolsMirror/reference/ExRT/Coins.lua`
- `/home/user/ktoolsMirror/reference/ExRT/Encounter.lua`
- `/home/user/ktoolsMirror/reference/ExRT/ExCD2.lua`
- `/home/user/ktoolsMirror/reference/ExRT/InspectViewer.lua`
- `/home/user/ktoolsMirror/reference/ExRT/InviteTool.lua`
- `/home/user/ktoolsMirror/reference/ExRT/LootLink.lua`
- `/home/user/ktoolsMirror/reference/ExRT/Marks.lua`
- `/home/user/ktoolsMirror/reference/ExRT/MarksBar.lua`
- `/home/user/ktoolsMirror/reference/ExRT/Note.lua`
- `/home/user/ktoolsMirror/reference/ExRT/Pets.lua`
- `/home/user/ktoolsMirror/reference/ExRT/Profiles.lua`
- `/home/user/ktoolsMirror/reference/ExRT/RaidAttendance.lua`
- `/home/user/ktoolsMirror/reference/ExRT/RaidCheck.lua`
- `/home/user/ktoolsMirror/reference/ExRT/Timers.lua`
- `/home/user/ktoolsMirror/reference/ExRT/WAChecker.lua`
- `/home/user/ktoolsMirror/reference/ExRT/WhoPulled.lua`
- `/home/user/ktoolsMirror/reference/ExRT/Blank.lua`
- `/home/user/ktoolsMirror/reference/ExRT/Bindings.lua`
- `/home/user/ktoolsMirror/reference/ExRT/libs/` — собственные CallbackHandler, LibDataBroker, LibStub
- `/home/user/ktoolsMirror/reference/ExRT/localization/` — 8 языков
- `/home/user/ktoolsMirror/reference/ExRT/media/` — 95+ файлов

**Паттерн модуля (НЕ Ace3, собственная система):**
```lua
local module = ExRT.mod:New("ModuleName", "Localized Name")
function module:OnEnable()
    self:RegisterEvents("EVENT_NAME", "HandlerMethod")
    self:RegisterTimer(0.5, "OnTick")
    self:RegisterSlash("/cmd", "OnSlash")
    self:RegisterAddonMessage("PREFIX", "OnAddonMsg")
end
```

**Регистрация в окне опций:**
```lua
ExRT.Options:Add("ModuleName", frameName)   -- появляется в дереве слева
```

### 12.4. HandyNotes — паттерн плагинов

**Корень:** `/home/user/ktoolsMirror/reference/HandyNotes/`

**TOC:** `## SavedVariables: HandyNotesDB, HandyNotes_HandyNotesDB`, `## OptionalDeps: Ace3, TomTom, HereBeDragons-1.0`

**Файлы:**
- `/home/user/ktoolsMirror/reference/HandyNotes/HandyNotes.toc`
- `/home/user/ktoolsMirror/reference/HandyNotes/HandyNotes.lua` — AceAddon
- `/home/user/ktoolsMirror/reference/HandyNotes/HandyNotes_HandyNotes.lua` — встроенный плагин для пользовательских пинов
- `/home/user/ktoolsMirror/reference/HandyNotes/HandyNotes_EditFrame.lua`
- `/home/user/ktoolsMirror/reference/HandyNotes/Locales/` — 8 языков
- `/home/user/ktoolsMirror/reference/HandyNotes/Libs/AceAddon-3.0/`
- `/home/user/ktoolsMirror/reference/HandyNotes/Libs/AceDB-3.0/`
- `/home/user/ktoolsMirror/reference/HandyNotes/Libs/AceConfig-3.0/`
- `/home/user/ktoolsMirror/reference/HandyNotes/Libs/AceGUI-3.0/`
- `/home/user/ktoolsMirror/reference/HandyNotes/Libs/HereBeDragons-1.0/` — координаты карт
- `/home/user/ktoolsMirror/reference/HandyNotes/Libs/CallbackHandler-1.0/`
- `/home/user/ktoolsMirror/reference/HandyNotes/Libs/LibStub/`

**Plugin pattern:**
```lua
HandyNotes:RegisterPluginDB(pluginName, pluginHandler, optionsTable)

-- pluginHandler должен реализовать:
function pluginHandler:GetNodes(mapFile)
    -- возвращает таблицу пинов: { [coordEncoded] = nodeData, ... }
end
function pluginHandler:OnEnter(pin, mapFile, coord) end
function pluginHandler:OnLeave(pin, mapFile, coord) end
function pluginHandler:OnClick(pin, button, down, mapFile, coord) end
```

**Пример плагина:** `/home/user/ktoolsMirror/reference/HandyNotes_LegionRaresTreasures/HandyNotes_LegionRaresTreasures.lua`

**TOC плагина:**
```
## Interface: 70100
## RequiredDeps: HandyNotes
## SavedVariables: LegionRaresTreasuresDB
```

**Кодирование координат:** `coord = floor(x*10000)*10000 + floor(y*10000)` (например `58381229` = x:58.38 y:12.29).

### 12.5. XLoot_Options — BetterOptions

**Корень:** `/home/user/ktoolsMirror/reference/XLoot_Options/`

**TOC:** `## Dependencies: XLoot`, `## LoadOnDemand: 1`

**Файлы:**
- `/home/user/ktoolsMirror/reference/XLoot_Options/XLoot_Options.toc`
- `/home/user/ktoolsMirror/reference/XLoot_Options/Options.lua`
- `/home/user/ktoolsMirror/reference/XLoot_Options/localization.lua`
- `/home/user/ktoolsMirror/reference/XLoot_Options/load.xml`
- `/home/user/ktoolsMirror/reference/XLoot_Options/Libs/AceConfig-3.0/`
- `/home/user/ktoolsMirror/reference/XLoot_Options/Libs/AceDBOptions-3.0/`
- `/home/user/ktoolsMirror/reference/XLoot_Options/Libs/AceGUI-3.0/`

**Паттерн BetterOptions** — упрощённый формат для AceConfig:
```lua
XLootOptions:RegisterOptions(module_data, {
    section = {
        type = "group",
        args = {
            -- кастомные поля:
            -- .requires / .requires_inverse — условная видимость
            -- .subtable — сохранение в вложенный ключ БД
        },
    },
})
-- внутри: BetterOptions.Compile() → стандартный AceOptionsTable
-- BetterOptions.Finalize() → регистрация в AceConfig
```

### 12.6. BagBrother — кеш предметов

**Корень:** `/home/user/ktoolsMirror/reference/BagBrother/`

**TOC:** `## SavedVariables: BrotherBags`, `## OptionalDeps: WoWUnit`

**Файлы:**
- `/home/user/ktoolsMirror/reference/BagBrother/BagBrother.toc`
- `/home/user/ktoolsMirror/reference/BagBrother/Startup.lua` — `CreateFrame("Frame", "BagBrother")`, `ADDON_LOADED`, `PLAYER_LOGIN`
- `/home/user/ktoolsMirror/reference/BagBrother/Events.lua` — `BAG_UPDATE`, `BANKFRAME_*`, `VOID_STORAGE_*`, `GUILDBANKFRAME_*`
- `/home/user/ktoolsMirror/reference/BagBrother/API.lua` — `SaveBag`, `SaveEquip`, `ParseItem`

**Назначение:** Кеш инвентаря/банка/войда/банка-гильдии. Доступен через LibItemCache-1.1.

**Структура SavedVariables:** `BrotherBags[Realm][Player] = { equip = {...}, [bag] = {...}, ... }`

### 12.7. Bagnon_GuildBank / Bagnon_VoidStorage

**Файлы Bagnon_GuildBank:**
- `/home/user/ktoolsMirror/reference/Bagnon_GuildBank/Bagnon_GuildBank.toc`
- `/home/user/ktoolsMirror/reference/Bagnon_GuildBank/main.lua` — `Bagnon:NewModule("GuildBank", Addon)`
- `/home/user/ktoolsMirror/reference/Bagnon_GuildBank/components/components.xml`
- `/home/user/ktoolsMirror/reference/Bagnon_GuildBank/components/editFrame.lua`
- `/home/user/ktoolsMirror/reference/Bagnon_GuildBank/components/frame.lua`
- `/home/user/ktoolsMirror/reference/Bagnon_GuildBank/components/item.lua`
- `/home/user/ktoolsMirror/reference/Bagnon_GuildBank/components/itemFrame.lua`
- `/home/user/ktoolsMirror/reference/Bagnon_GuildBank/components/logFrame.lua`
- `/home/user/ktoolsMirror/reference/Bagnon_GuildBank/components/logToggle.lua`
- `/home/user/ktoolsMirror/reference/Bagnon_GuildBank/components/moneyFrame.lua`
- `/home/user/ktoolsMirror/reference/Bagnon_GuildBank/components/tab.lua`

**Файлы Bagnon_VoidStorage:**
- `/home/user/ktoolsMirror/reference/Bagnon_VoidStorage/Bagnon_VoidStorage.toc`
- `/home/user/ktoolsMirror/reference/Bagnon_VoidStorage/main.lua` — `Bagnon:NewModule("VoidStorage", Addon)`
- `/home/user/ktoolsMirror/reference/Bagnon_VoidStorage/components/components.xml`
- `/home/user/ktoolsMirror/reference/Bagnon_VoidStorage/components/dialogs.lua`
- `/home/user/ktoolsMirror/reference/Bagnon_VoidStorage/components/frame.lua`
- `/home/user/ktoolsMirror/reference/Bagnon_VoidStorage/components/item.lua`
- `/home/user/ktoolsMirror/reference/Bagnon_VoidStorage/components/itemFrame.lua`
- `/home/user/ktoolsMirror/reference/Bagnon_VoidStorage/components/transferButton.lua`
- `/home/user/ktoolsMirror/reference/Bagnon_VoidStorage/localization/`

**Общий паттерн расширения Bagnon:**
- `## RequiredDeps: Bagnon`, `## LoadOnDemand: 1`
- `local Mod = Bagnon:NewModule("ModName", Addon)`
- Хуки `OnEnable`, `OnOpen`, `OnClose`
- События: `GUILDBANKFRAME_CLOSED` / `VOID_STORAGE_CLOSE`

---

## 13. Сравнение архитектурных подходов

| Аддон | Framework | UI | Module pattern | SavedVars |
|---|---|---|---|---|
| Bagnon | Ace3 (AceAddon) | Custom (Wildpants) | `NewModule()` | `Bagnon_Sets` |
| Bagnon_Config | Ace3 | Sushi-3.0 + Poncho | модуль Bagnon | — |
| ExRT | свой | свой UI (ExLib) | `ExRT.mod:New()` | `VExRT` |
| HandyNotes | Ace3 | AceGUI-3.0 | Plugin registry (`RegisterPluginDB`) | `HandyNotesDB` |
| HN_LegionRaresTreasures | Ace3 (плагин) | AceGUI (от HN) | плагин HN | `LegionRaresTreasuresDB` |
| XLoot_Options | AceConfig | AceGUI | BetterOptions → Finalize | — |
| BagBrother | EventFrame | нет UI | API-методы | `BrotherBags` |
| Bagnon_GuildBank / VoidStorage | Ace3 (модуль Bagnon) | Wildpants | `NewModule()` | — |
| **KTools** | **Ace3 (AceAddon)** | **AceGUI-3.0** | **`RegisterModule()` (свой)** | **`KToolsMinimapDB`** |
| **KToolsAutoloot** | **Ace3 (AceAddon)** | **AceGUI-3.0** | **отдельный аддон** | **`KToolsLootDB`, `KToolsLootProfileNames`** |

---

## 14. AceGUI-3.0 — виджеты (deep dive)

**Основной файл:** `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/AceGUI-3.0.lua` (≈6600 строк)
**Директория виджетов:** `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/` (23 файла)

### 14.1. Жизненный цикл виджета

```
AceGUI:Create("Type")             -- получить из пула или создать
  → OnAcquire()                   -- инициализация виджета
  → SetWidth/SetText/...          -- конфигурация
  → container:AddChild(widget)    -- SetParent + DoLayout
  → SetCallback("OnEvent", func)  -- обработчики
... использование ...
AceGUI:Release(widget)            -- или widget:Release()
  → OnRelease()                   -- очистка
  → возврат в пул
```

### 14.2. Структура любого виджета

```lua
widget.frame      -- WoW Frame (видимый)
widget.content    -- (только для контейнеров) frame для размещения детей
widget.type       -- "Button" / "Frame" / ...
widget.userdata   -- произвольные данные пользователя
widget.events     -- callbacks

-- Пользовательские данные:
widget:SetUserData(key, value)
widget:GetUserData(key)

-- Прямой доступ к WoW frame (когда AceGUI не хватает):
widget.frame:SetFrameStrata("HIGH")
widget.frame:SetMinResize(800, 600)
widget.frame:HookScript("OnEnter", function() ... end)
```

### 14.3. Контейнеры

**Полные пути:**
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIContainer-Frame.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIContainer-Window.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIContainer-SimpleGroup.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIContainer-InlineGroup.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIContainer-ScrollFrame.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIContainer-TabGroup.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIContainer-TreeGroup.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIContainer-DropDownGroup.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIContainer-BlizOptionsGroup.lua`

#### Frame

Основное окно с заголовком, статус-баром, drag/resize.

Layouts: `List` (default), `Fill`, `Flow`.

```lua
local f = AceGUI:Create("Frame")
f:SetTitle("...")
f:SetStatusText("...")
f:EnableResize(true_or_false)
f:SetWidth(800); f:SetHeight(600)
f:SetStatusTable(savedTable)     -- внешнее хранение позиции/размера
f:ApplyStatus()                  -- применить сохранённое
f:SetLayout("Fill")
f:AddChild(child); f:AddChildren(c1, c2, ...)
f:ReleaseChildren()
f:DoLayout()
f:SetFullWidth(true); f:SetFullHeight(true)

f:SetCallback("OnClose", function(w) AceGUI:Release(w) end)
f:SetCallback("OnShow", ...)
f:SetCallback("OnEnterStatusBar", ...)
f:SetCallback("OnLeaveStatusBar", ...)
```

#### Window

Упрощённый Frame без статус-бара.

#### SimpleGroup

Без визуального оформления — просто группировка с layout.

Layouts: `List` (default), `Flow`, `Fill`.

```lua
local g = AceGUI:Create("SimpleGroup")
g:SetFullWidth(true)
g:SetLayout("Flow")
parent:AddChild(g)
```

#### InlineGroup

Как SimpleGroup, но с рамкой и опциональным заголовком.

```lua
local g = AceGUI:Create("InlineGroup")
g:SetTitle("...")
g:SetFullWidth(true)
g:SetLayout("Flow")
g:SetAutoAdjustHeight(true)
```

#### ScrollFrame

Вертикальный скролл, дети без ограничения по высоте.

```lua
local sf = AceGUI:Create("ScrollFrame")
sf:SetFullWidth(true)
sf:SetHeight(300)
sf:SetLayout("List")
sf:SetScroll(value)          -- 0..1000
sf:MoveScroll(delta)
sf:FixScroll()                -- пересчёт после изменений
```

#### TabGroup

Вкладки сверху.

```lua
local tg = AceGUI:Create("TabGroup")
tg:SetTabs({
    { value="t1", text="Tab 1" },
    { value="t2", text="Tab 2" },
})
tg:SelectTab("t1")
tg:SetCallback("OnGroupSelected", function(w, _, key)
    w:ReleaseChildren()
    -- наполнить вкладку
end)
```

#### TreeGroup

Иерархическое дерево слева, контент справа.

```lua
local tree = AceGUI:Create("TreeGroup")
tree:SetTree({
    { value="key1", text="Item 1" },
    { value="key2", text="Item 2", children = {
        { value="key2a", text="Sub" },
    }},
})
tree:SelectByValue("key1")
tree:SetCallback("OnGroupSelected", function(w, _, key)
    w:ReleaseChildren()
    -- наполнить правую панель
end)
```

#### DropdownGroup

Как TreeGroup, но переключатель — dropdown сверху.

```lua
local dg = AceGUI:Create("DropdownGroup")
dg:SetGroupList(listTable, orderTable)
dg:SetGroup(key)
dg:SetDropdownWidth(180)
dg:SetCallback("OnGroupSelected", function(w, _, key) ... end)
```

#### BlizOptionsGroup

Для встраивания в стандартное окно Blizzard Interface Options.

```lua
local bg = AceGUI:Create("BlizOptionsGroup")
bg:SetName("My Addon", parentName)
bg:SetTitle("...")
-- callbacks: okay, cancel, default, refresh
```

### 14.4. Layouts (механизм)

```lua
AceGUI:RegisterLayout(name, function(content, children) ... end)
```

Встроенные:

| Layout | Поведение |
|---|---|
| `List` | Дети стопятся вертикально, каждый — full width |
| `Fill` | Только первый ребёнок, заполняет всю площадь |
| `Flow` | Слева направо с переносом; `child.width == "fill"` → перенос на новую строку |
| `Manual` | (опционально) ручное позиционирование через SetPoint |

**Кастомный layout (из KToolsAutoloot):**

```lua
AceGUI:RegisterLayout("LastFillRow", function(content, children)
    local n = #children
    if n == 0 then return end
    local y = 0
    for i = 1, n - 1 do
        local f = children[i].frame
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, -y)
        f:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -y)
        if children[i].DoLayout then children[i]:DoLayout() end
        y = y + (f:GetHeight() or 0) + 4
    end
    local lf = children[n].frame
    lf:ClearAllPoints()
    lf:SetPoint("TOPLEFT",     content, "TOPLEFT",     0, -y)
    lf:SetPoint("BOTTOMRIGHT", content, "BOTTOMRIGHT", 0,  0)
    if children[n].DoLayout then children[n]:DoLayout() end
end)
```

### 14.5. Базовые виджеты

**Полные пути:**
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIWidget-Button.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIWidget-Button-ElvUI.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIWidget-CheckBox.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIWidget-EditBox.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIWidget-MultiLineEditBox.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIWidget-Slider.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIWidget-DropDown.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIWidget-DropDown-Items.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIWidget-ColorPicker.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIWidget-Label.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIWidget-Icon.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIWidget-Heading.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIWidget-InteractiveLabel.lua`
- `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/AceGUIWidget-Keybinding.lua`

#### Button

```lua
local b = AceGUI:Create("Button")
b:SetText("...")
b:SetAutoWidth(true_or_false)
b:SetDisabled(true_or_false)
b:SetWidth(120); b:SetRelativeWidth(0.5)
b:SetCallback("OnClick", function(w, _, mouseButton) end)
b:SetCallback("OnEnter", ...)
b:SetCallback("OnLeave", ...)
```

#### CheckBox

```lua
local cb = AceGUI:Create("CheckBox")
cb:SetLabel("...")
cb:SetValue(true_false_or_nil)    -- nil для tri-state
cb:SetTriState(true_or_false)
cb:ToggleChecked()
cb:SetDescription("multi-line description")
cb:SetImage(texture)               -- иконка вместо checkbox
cb:SetCallback("OnValueChanged", function(w, _, checked) end)
```

#### EditBox

```lua
local eb = AceGUI:Create("EditBox")
eb:SetText("..."); eb:GetText()
eb:SetLabel("...")
eb:SetMaxLetters(100)
eb:SetWidth(200); eb:SetRelativeWidth(0.3)
eb:SetFocus(); eb:ClearFocus()
eb:SetCallback("OnEnterPressed", function(w, _, text) end)
eb:SetCallback("OnTextChanged", function(w, _, text) end)
eb:SetCallback("OnEscapePressed", function(w, _) end)
```

#### MultiLineEditBox

```lua
local mle = AceGUI:Create("MultiLineEditBox")
mle:SetText("..."); mle:GetText()
mle:SetLabel("")
mle:SetNumLines(28)
mle:SetMaxLetters(0)              -- 0 = без ограничений
mle:SetFullWidth(true)
mle:DisableButton(true)           -- скрыть встроенную кнопку OK
mle:SetCallback("OnEnterPressed", function(w, _, text) end)
mle:SetCallback("OnEditFocusLost", ...)
```

#### Slider

```lua
local s = AceGUI:Create("Slider")
s:SetLabel("...")
s:SetMin(0); s:SetMax(100); s:SetStep(1)
s:SetValue(50); s:GetValue()
s:SetIsPercent(true_or_false)
s:SetCallback("OnValueChanged", function(w, _, value) end)
s:SetCallback("OnMouseUp", function(w, _, value) end)
```

#### Dropdown

```lua
local dd = AceGUI:Create("Dropdown")
dd:SetLabel("...")
dd:SetWidth(140)
dd:SetList({                       -- { [key]=text, ... }
    key1 = "Display 1",
    key2 = "Display 2",
}, orderTable)                     -- опционально { "key1","key2" } для порядка
dd:SetValue(key); dd:GetValue()
dd:SetMultiselect(true_or_false)
dd:SetCallback("OnValueChanged", function(w, _, key) end)
```

#### ColorPicker

```lua
local cp = AceGUI:Create("ColorPicker")
cp:SetLabel("...")
cp:SetColor(r, g, b, a)            -- 0..1
cp:SetHasAlpha(true_or_false)
cp:SetCallback("OnValueChanged",   function(w, _, r,g,b,a) end)  -- в процессе
cp:SetCallback("OnValueConfirmed", function(w, _, r,g,b,a) end)  -- окно закрыто
```

#### Label / Icon / Heading / InteractiveLabel / Keybinding

```lua
-- Label
local l = AceGUI:Create("Label")
l:SetText("...")
l:SetImage(texture, l, r, t, b)
l:SetImageSize(w, h)
l:SetRelativeWidth(0.4)
-- justify (через подлежащий FontString):
if l.label and l.label.SetJustifyH then l.label:SetJustifyH("CENTER") end

-- Icon
local i = AceGUI:Create("Icon")
i:SetImage(texture)
i:SetImageSize(24, 24)
i:SetLabel("name")
i:SetCallback("OnClick", function(w, _, btn) end)

-- Heading
local h = AceGUI:Create("Heading")
h:SetText("...")
h:SetFullWidth(true)

-- InteractiveLabel
local il = AceGUI:Create("InteractiveLabel")
il:SetText("...")
il:SetHighlight(texture)
il:SetHighlightTexCoord(l, r, t, b)
il:SetCallback("OnClick", function(w, _, btn) end)

-- Keybinding
local kb = AceGUI:Create("Keybinding")
kb:SetLabel("...")
kb:SetKey("CTRL-SHIFT-A"); kb:GetKey()
kb:SetCallback("OnKeyChanged", function(w, _, key) end)
```

### 14.6. Ширина и высота

```lua
-- Абсолютная (px):
w:SetWidth(150); w:SetHeight(24)

-- Относительная (доля родителя):
w:SetRelativeWidth(0.5)   -- 50%
w:SetRelativeWidth(1)     -- 100%

-- Эквивалент:
w:SetFullWidth(true)      -- == SetRelativeWidth(1), внутри: width = "fill"
w:SetFullHeight(true)     -- для контейнеров
```

### 14.7. Layout-control

```lua
-- Пересчёт расположения (обычно автоматически после AddChild):
container:DoLayout()

-- При массовом добавлении — пауза/возобновление:
container:PauseLayout()
for _, item in ipairs(items) do
    container:AddChild(BuildRow(item))
end
container:ResumeLayout()
container:DoLayout()
```

### 14.8. Применение в KTools

**`/home/user/ktoolsMirror/KTools/window.lua`** — TreeGroup внутри Frame, layout Fill:

```lua
local f = AceGUI:Create("Frame")
f:SetTitle(...)
f:SetStatusText(...)
f:SetWidth(800); f:SetHeight(600)
f:SetLayout("Fill")
f.frame:SetMinResize(800, 600)
f.frame:SetFrameStrata("HIGH")

local tree = AceGUI:Create("TreeGroup")
tree:SetFullWidth(true); tree:SetFullHeight(true)
tree:SetLayout("Fill")
tree:SetTree({})
tree:SetCallback("OnGroupSelected", function(w, _, key)
    w:ReleaseChildren()
    KTools:_onModuleSelected(key, w)
end)
f:AddChild(tree)

f:SetCallback("OnClose", function(w) AceGUI:Release(w) end)
```

**`/home/user/ktoolsMirror/KToolsAutoloot/ui/window.lua`** — Frame с кастомным layout `LastFillRow`, SimpleGroup+Flow для шапки, ScrollFrame+List для таблицы предметов.

### 14.9. Сводная таблица виджетов

| Тип | Файл (в `/home/user/ktoolsMirror/reference/lib/AceGUI-3.0/widgets/`) | Layout |
|---|---|---|
| Frame | AceGUIContainer-Frame.lua | List/Fill/Flow |
| Window | AceGUIContainer-Window.lua | Fill |
| SimpleGroup | AceGUIContainer-SimpleGroup.lua | List/Flow/Fill |
| InlineGroup | AceGUIContainer-InlineGroup.lua | Flow |
| ScrollFrame | AceGUIContainer-ScrollFrame.lua | List |
| TabGroup | AceGUIContainer-TabGroup.lua | List/Flow/Fill |
| TreeGroup | AceGUIContainer-TreeGroup.lua | Fill |
| DropdownGroup | AceGUIContainer-DropDownGroup.lua | List/Flow/Fill |
| BlizOptionsGroup | AceGUIContainer-BlizOptionsGroup.lua | List/Flow/Fill |
| Button | AceGUIWidget-Button.lua | — |
| CheckBox | AceGUIWidget-CheckBox.lua | — |
| EditBox | AceGUIWidget-EditBox.lua | — |
| MultiLineEditBox | AceGUIWidget-MultiLineEditBox.lua | — |
| Slider | AceGUIWidget-Slider.lua | — |
| Dropdown | AceGUIWidget-DropDown.lua | — |
| ColorPicker | AceGUIWidget-ColorPicker.lua | — |
| Label | AceGUIWidget-Label.lua | — |
| Icon | AceGUIWidget-Icon.lua | — |
| Heading | AceGUIWidget-Heading.lua | — |
| InteractiveLabel | AceGUIWidget-InteractiveLabel.lua | — |
| Keybinding | AceGUIWidget-Keybinding.lua | — |

### 14.10. AceGUI-3.0-SharedMediaWidgets

В ElvUI_Config есть дополнительные виджеты для выбора медиа из LibSharedMedia:

- `/home/user/ktoolsMirror/reference/ElvUI_Config/Libraries/AceGUI-3.0-SharedMediaWidgets/BackgroundWidget.lua`
- `/home/user/ktoolsMirror/reference/ElvUI_Config/Libraries/AceGUI-3.0-SharedMediaWidgets/BorderWidget.lua`
- `/home/user/ktoolsMirror/reference/ElvUI_Config/Libraries/AceGUI-3.0-SharedMediaWidgets/FontWidget.lua`
- `/home/user/ktoolsMirror/reference/ElvUI_Config/Libraries/AceGUI-3.0-SharedMediaWidgets/SoundWidget.lua`
- `/home/user/ktoolsMirror/reference/ElvUI_Config/Libraries/AceGUI-3.0-SharedMediaWidgets/StatusbarWidget.lua`
- `/home/user/ktoolsMirror/reference/ElvUI_Config/Libraries/AceGUI-3.0-SharedMediaWidgets/prototypes.lua`

Регистрируют типы `LSM30_Font`, `LSM30_Statusbar`, `LSM30_Sound`, `LSM30_Border`, `LSM30_Background` для AceConfig dropdown с превью.
