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
