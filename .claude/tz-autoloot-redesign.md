# ТЗ: Полная переработка KToolsAutoloot

**Статус:** Формирование ТЗ  
**Сессия:** 2026-05-20  
**Тег:** [todo-036]  

---

## Цель

Полная переработка KToolsAutoloot:
- Модульная архитектура кода (разделение по файлам)
- Новая схема профиля (per-quality bind-type фильтр)
- Два режима UI: «Быстрые настройки» / «Пользовательский список»
- Импорт/экспорт через AceSerializer-3.0 + LibDeflate (ElvUI-подход), два формата

Работоспособность аддона в процессе шагов **не обязательна**.

---

## Библиотеки

### Уже есть в KTools/lib (доступны через LibStub)
- AceAddon-3.0, AceDB-3.0, AceGUI-3.0, AceLocale-3.0, AceEvent-3.0, AceConsole-3.0
- LibDataBroker-1.1, LibDBIcon-1.0

### Нужно добавить в KToolsAutoloot/lib
- `AceSerializer-3.0` — сериализация таблиц (`reference/lib/AceSerializer-3.0/`)
- `LibDeflate` — сжатие + EncodeForPrint/DecodeForPrint (`reference/lib/LibDeflate/`)

### Не используем (нет в lib, требуют слишком много зависимостей)
- AceConfig-3.0 / AceDBOptions-3.0 — профильный UI полностью кастомный

---

## Пайплайн импорта/экспорта (по образцу ElvUI)

### Источник
`reference/ElvUI/Modules/distributor.lua` — функции `GetProfileExport`, `Decode`, `CreateProfileExport`.

### Сжатый формат (binary safe через EncodeForPrint)
```
Экспорт: AceSerializer:Serialize(profileTable)
       → LibDeflate:CompressDeflate(str)
       → LibDeflate:EncodeForPrint(compressed)
       → итоговая строка

Импорт: LibDeflate:DecodeForPrint(str)
       → LibDeflate:DecompressDeflate(compressed)
       → AceSerializer:Deserialize(serialized)
       → применить таблицу к профилю
```

### Читаемый формат (plain text, legacy)
Текущий формат `name:ИмяПрофиля|i:id,active[,ilvl],name|...`  
Сохраняется для совместимости и ручного редактирования.  
Парсер: функции `SerializeItems(p)` / `ParseItemsString(str)` из текущего window.lua.

### Что сериализуется в сжатом формате
```lua
{
    profileName = GetDisplayName(currentUUID),
    mode        = p.mode,
    categories  = { quest, gold, currency, reagents, recipes,
                    artifact, mounts, pets, tokens },
    utility     = { bopNoConfirm, skinningClose },
    qualityRows = { [0]={enabled,ilvl,nob,boe,bop}, ...[5]=... },
    items       = p.items,  -- полная таблица
}
```

### UI IO-диалога (два режима в одном окне)
```
┌─────────────────────────────────────┐
│ [Export compressed] [Export plain]  │
│ [Import]                            │
│ ┌───────────────────────────────┐   │
│ │  <текстовое поле 100%>        │   │
│ └───────────────────────────────┘   │
└─────────────────────────────────────┘
```
- Три кнопки в шапке диалога: `Export (сжатый)`, `Export (читаемый)`, `Import`
- Кнопки экспорта заполняют поле и выделяют текст
- Кнопка Import берёт текст из поля, auto-detect формат (LibDeflate проверяет декодируемость → если ок — compressed, иначе — plain)

---

## Новая схема профиля

### Плоские ключи (AceDB-safe, нет вложенных defaults)

```lua
DEFAULTS = {
    profile = {
        enabled = true,
        mode    = "quick",  -- "quick" | "list"

        -- Категории
        quest    = true,  gold      = true,  currency = true,
        reagents = false, recipes   = false, artifact = false,
        mounts   = false, pets      = false, tokens   = false,

        -- Утилиты
        bopNoConfirm  = false,
        skinningClose = false,

        -- Per-quality bind-type фильтр (Legion: GetItemInfo pos 14 = bindType)
        -- bindType: 0=NoB, 1=BoP, 2=BoE
        -- Ключи: quality_N_<field>, N=0..5
        quality_0_enabled=false, quality_0_ilvl=0, quality_0_nob=false, quality_0_boe=false, quality_0_bop=false,
        quality_1_enabled=false, quality_1_ilvl=0, quality_1_nob=true,  quality_1_boe=true,  quality_1_bop=false,
        quality_2_enabled=false, quality_2_ilvl=0, quality_2_nob=true,  quality_2_boe=true,  quality_2_bop=false,
        quality_3_enabled=false, quality_3_ilvl=0, quality_3_nob=true,  quality_3_boe=true,  quality_3_bop=false,
        quality_4_enabled=false, quality_4_ilvl=0, quality_4_nob=true,  quality_4_boe=true,  quality_4_bop=true,
        quality_5_enabled=false, quality_5_ilvl=0, quality_5_nob=true,  quality_5_boe=true,  quality_5_bop=true,

        -- Кастомный список
        items = {},  -- [itemID] = { active, ilvl, name }
    },
}
```

### Почему плоские ключи, не вложенные таблицы
AceDB не выполняет deep merge defaults: если ключ отсутствует в SavedVars,
возвращается ссылка на дефолтную таблицу. Запись `profile.qualityRows[2].enabled = true`
изменила бы defaults для всех профилей. Плоские ключи — единственный безопасный паттерн.

### Убрать из DEFAULTS (старые поля)
`useQualityFilter`, `quality`, `ilvl`, `useList`

---

## Новые locale-ключи

| Ключ | enUS | ruRU |
|---|---|---|
| `MODE_QUICK` | `"Quick settings"` | `"Быстрые настройки"` |
| `MODE_LIST` | `"Custom list"` | `"Пользовательский список"` |
| `QUALITY_HDR_ILVL` | `"ilvl >="` | `"ilvl >="` |
| `QUALITY_HDR_NOB` | `"NoB"` | `"NoB"` |
| `QUALITY_HDR_BOE` | `"BoE"` | `"BoE"` |
| `QUALITY_HDR_BOP` | `"BoP"` | `"BoP"` |
| `UTIL_HEADER` | `"Other"` | `"Прочее"` |
| `IO_EXPORT_COMPRESSED` | `"Export (compressed)"` | `"Экспорт (сжатый)"` |
| `IO_EXPORT_PLAIN` | `"Export (plain)"` | `"Экспорт (текст)"` |

### Убрать из locale
`QUALITY_GE` (заменён на `QUALITY_HDR_ILVL`), `COLLECT_BY_LIST` (режим теперь через кнопку-свич)

---

## Структура файлов после переработки

```
KToolsAutoloot/
  KToolsAutoloot.toc          ← Dependencies добавляем? нет (LibStub решает)
  init.lua                    ← без изменений
  lib/
    load.xml                  ← NEW: загружает AceSerializer + LibDeflate
    AceSerializer-3.0/        ← NEW: скопировать из reference/lib/
    LibDeflate/               ← NEW: скопировать из reference/lib/
  locale/
    enUS.lua                  ← новые ключи, убрать устаревшие
    ruRU.lua                  ← новые ключи, убрать устаревшие
  core/
    profile.lua               ← новая схема DEFAULTS + QRow хелпер
    autoloot.lua              ← обновить ShouldLoot() под новую схему
  ui/
    window.lua                ← полная переработка (см. ниже)
    minimap.lua               ← без изменений
```

---

## Шаги реализации (порядок патчей)

### Шаг 1: Добавить библиотеки [new-036]
**Файлы:** `KToolsAutoloot/lib/` (новая директория), `KToolsAutoloot.toc`
- Скопировать `AceSerializer-3.0/` из `reference/lib/AceSerializer-3.0/`
- Скопировать `LibDeflate/` из `reference/lib/LibDeflate/`
- Создать `KToolsAutoloot/lib/load.xml` с загрузкой обеих библиотек
- **После этого шага:** `lib\load.xml` в TOC перестаёт быть мёртвой ссылкой;
  AceSerializer и LibDeflate доступны через LibStub

### Шаг 2: Обновить профиль [new-037]
**Файлы:** `core/profile.lua`
- Заменить DEFAULTS на новую схему (плоские quality_N_* ключи)
- Убрать: `useQualityFilter`, `quality`, `ilvl`, `useList`
- Добавить: `mode = "quick"`, 30 плоских quality-ключей
- Добавить хелпер `KToolsLoot:QRow(q)` для чтения/записи строки фильтра
- **После этого шага:** UI сломан (обращается к старым ключам),
  автолут работает частично (категории и список работают, quality-фильтр — нет)

### Шаг 3: Обновить логику автолута [new-038]
**Файлы:** `core/autoloot.lua`
- Обновить `GetItemData()`: добавить `bindType` из GetItemInfo (позиция 14 в Legion)
- Заменить старый блок `useQualityFilter` на per-quality проверку через `QRow(quality)`
- Проверка bindType: `0=NoB→row.nob`, `1=BoP→row.bop`, `2=BoE→row.boe`
- Убрать проверку `p.useList` (список всегда проверяется; режим влияет только на UI)
- **После этого шага:** автолут полностью функционален с новой схемой

### Шаг 4: Обновить locale [new-039]
**Файлы:** `locale/enUS.lua`, `locale/ruRU.lua`
- Добавить все новые ключи (см. таблицу выше)
- Убрать: `QUALITY_GE`, `COLLECT_BY_LIST`
- **После этого шага:** locale готова, UI всё ещё сломан (старый window.lua)

### Шаг 5: Реализовать новый window.lua — шапка и скелет [new-040]
**Файлы:** `ui/window.lua` (полная замена)
- Сохранить хелперы: `GenerateProfileID`, `GetDisplayName`, layout `KToolsListFill`,
  `RegisterAsSpecialFrame`, `RegisterIOFrame`, `BindCheckbox`, `AddSpacer`,
  `AddCenteredLabel`, `AddLeftLabel`, `CenterEditBox`
- Реализовать `BuildHeader(parent)`:
  - Чекбокс enabled
  - Dropdown активного профиля
  - Кнопка Create
  - Dropdown Delete
  - Кнопка Import (→ ShowIODialog)
  - Кнопка Export — убрать, перенести в IO-диалог
  - Кнопка-свич: текст = название **другого** режима; OnClick → переключить mode + перестроить панель
- `OpenWindow()`: создаёт Frame, вызывает BuildHeader, затем BuildActivePanel()
- `BuildActivePanel(frame)`: если `mode=="quick"` → BuildQuickPanel(frame), иначе BuildListPanel(frame)
- `RebuildPanel(frame)`: релизует старую панель, вызывает BuildActivePanel снова
- Статичные попапы (KTOOLSLOOT_CREATE_PROFILE, KTOOLSLOOT_DELETE_PROFILE) — без изменений
- **После этого шага:** окно открывается, шапка работает, основная панель пустая

### Шаг 6: BuildQuickPanel — категории и утилиты [new-041]
**Файлы:** `ui/window.lua`
- InlineGroup «категории» (2 колонки × 4 строки):
  ```
  Реагенты    Золото
  Рецепты     Валюта
  Маунты      Сила артефакта
  Питомцы     Квестовые предметы
  ```
  Токены — оставить за кадром или добавить 5-й строкой в 1-ю колонку
- InlineGroup «прочее» (1 строка):
  ```
  [x] Без подтверждения BoP   [x] Закрыть лут при снятии шкур
  ```
- **После этого шага:** «Быстрые настройки» показывает категории, таблица качества пустая

### Шаг 7: BuildQuickPanel — таблица фильтра качества [new-042]
**Файлы:** `ui/window.lua`
- InlineGroup «фильтр по качеству»
- Строка заголовка: пробел | Качество | ilvl >= | [поле] | NoB | BoE | BoP
- 6 строк качества (Poor..Legendary), каждая:
  ```
  [CheckBox enabled] [цветное имя качества] [EditBox ilvl] [CB nob] [CB boe] [CB bop]
  ```
  Цвет имени качества через качественные коды: Poor=серый, Common=белый, Uncommon=зелёный,
  Rare=синий, Epic=фиолетовый, Legendary=оранжевый
- Ширины: checkbox 26, имя 120, ilvl editbox 70, каждый bind CB 46
- Привязка к `KToolsLoot:QRow(q)` для чтения/записи
- **После этого шага:** «Быстрые настройки» полностью функционален

### Шаг 8: BuildListPanel [new-043]
**Файлы:** `ui/window.lua`
- Перенести из старого window.lua:
  - `BuildAddForm(parent)` — форма добавления
  - `BuildItems(parent)` — таблица предметов
  - `RefreshItemsList()` — обновление списка
  - `RefreshNameWidths()` — динамическая ширина колонки «Название»
  - `BuildItemRow(parent, id, item)` — строка предмета
- Убрать чекбокс `useList` из формы добавления (режим задаётся через кнопку-свич)
- **После этого шага:** «Пользовательский список» полностью функционален,
  переключение между режимами работает

### Шаг 9: IO-диалог с двумя форматами [new-044]
**Файлы:** `ui/window.lua`
- Заменить `ShowIODialog(mode, exportData)` на новую реализацию:
  - Убрать параметр mode (теперь кнопки в самом диалоге)
  - Три кнопки вверху: `[Экспорт (сжатый)]` `[Экспорт (текст)]` `[Импортировать]`
  - MultiLineEditBox во всю ширину и высоту
  - `[Экспорт (сжатый)]`: AceSerializer:Serialize(profileData) → LibDeflate compress → EncodeForPrint → set text
  - `[Экспорт (текст)]`: SerializeItems(p) → set text (текущий формат)
  - `[Импортировать]`: auto-detect формат → deserialize → применить
  - Auto-detect: попытка `LibDeflate:DecodeForPrint(text)` → если успешно и результат декомпрессируется → compressed; иначе → plain text
- Обновить кнопку Import в шапке: открывает диалог без предзаполнения
- **После этого шага:** полный функционал import/export

---

## Детали реализации

### Хелпер QRow (profile.lua)
```lua
-- Возвращает удобный accessor для строки фильтра качества q (0..5).
-- Не кэшировать — всегда обращается к актуальному profile.
function KToolsLoot:QRow(q)
    local p = self:Profile()
    local pfx = "quality_" .. q .. "_"
    return {
        enabled = p[pfx.."enabled"],
        ilvl    = p[pfx.."ilvl"],
        nob     = p[pfx.."nob"],
        boe     = p[pfx.."boe"],
        bop     = p[pfx.."bop"],
        set     = function(field, val) p[pfx..field] = val end,
    }
end
```

### Обновлённый ShouldLoot — блок quality (autoloot.lua)
```lua
-- Legion: GetItemInfo возвращает bindType на позиции 14
-- 0=NoB, 1=BoP, 2=BoE, 3=BoU/Quest
local function GetItemData(link)
    local _, _, quality, _, _, _, _, _, _, _, _, classID, subClassID, bindType =
        GetItemInfo(link)
    local ilvl = 0
    if GetDetailedItemLevelInfo then
        ilvl = GetDetailedItemLevelInfo(link) or 0
    end
    return quality, ilvl, classID, subClassID, bindType or 0
end

-- В ShouldLoot(), заменить старый блок useQualityFilter на:
if quality then
    local row = KToolsLoot:QRow(quality)
    if row.enabled then
        local minI = row.ilvl or 0
        if minI == 0 or (ilvl or 0) >= minI then
            local bt = bindType or 0
            if (bt == 0 and row.nob) or
               (bt == 2 and row.boe) or
               (bt == 1 and row.bop) then
                return true
            end
        end
    end
end
```

### Сжатый экспорт — функция (ui/window.lua)
```lua
local function ExportCompressed(p)
    local AceSer  = LibStub("AceSerializer-3.0")
    local LD      = LibStub("LibDeflate")
    local cur     = KToolsLoot.db:GetCurrentProfile()
    local data    = {
        profileName = GetDisplayName(cur),
        mode        = p.mode,
        categories  = {
            quest=p.quest, gold=p.gold, currency=p.currency,
            reagents=p.reagents, recipes=p.recipes, artifact=p.artifact,
            mounts=p.mounts, pets=p.pets, tokens=p.tokens,
        },
        utility = { bopNoConfirm=p.bopNoConfirm, skinningClose=p.skinningClose },
        qualityRows = {},
        items = p.items,
    }
    for q = 0, 5 do
        local row = KToolsLoot:QRow(q)
        data.qualityRows[q] = {
            enabled=row.enabled, ilvl=row.ilvl,
            nob=row.nob, boe=row.boe, bop=row.bop,
        }
    end
    local serialized  = AceSer:Serialize(data)
    local compressed  = LD:CompressDeflate(serialized)
    return LD:EncodeForPrint(compressed)
end
```

### Импорт — auto-detect формат (ui/window.lua)
```lua
local function ImportFromString(text)
    local LD = LibStub("LibDeflate")
    -- Пытаемся декодировать как сжатый
    local decoded = LD:DecodeForPrint(text)
    if decoded then
        local decompressed = LD:DecompressDeflate(decoded)
        if decompressed then
            local AceSer = LibStub("AceSerializer-3.0")
            local ok, data = AceSer:Deserialize(decompressed)
            if ok and type(data) == "table" then
                ApplyCompressedImport(data)
                return
            end
        end
    end
    -- Fallback: plain text формат
    local pname, items = ParseItemsString(text)
    ApplyPlainImport(pname, items)
end
```

---

## Mockup UI

### Режим «Быстрые настройки»
```
[x] [Профиль v] [Создать] [Удалить v] [Импорт/Экспорт]  [Пользовательский список]
─────────────────────────────────────────────────────────────────────────────────
 Категории
  [x] Реагенты          [x] Золото
  [ ] Рецепты           [x] Валюта
  [ ] Маунты            [ ] Сила артефакта
  [ ] Питомцы           [x] Квестовые предметы
  [ ] Токены

 Прочее
  [ ] Без подтверждения BoP    [ ] Закрыть лут при снятии шкур

 Фильтр по качеству
              ilvl >=          NoB   BoE   BoP
  [ ] Плохое        [    ]     [ ]   [ ]   [ ]
  [ ] Обычное       [    ]     [x]   [x]   [ ]
  [ ] Необычное     [    ]     [x]   [x]   [ ]
  [ ] Редкое        [    ]     [x]   [x]   [ ]
  [x] Эпическое     [ 200]     [x]   [x]   [x]
  [x] Легендарное   [    ]     [x]   [x]   [x]
```

### Режим «Пользовательский список»
```
[x] [Профиль v] [Создать] [Удалить v] [Импорт/Экспорт]  [Быстрые настройки]
─────────────────────────────────────────────────────────────────────────────────
 Добавить предмет
  [x] ID: [       ] Название: [                     ] [Добавить]

 Список предметов
  #    Иконка   ID      Название              ilvl>=   Тип      [X]
  ─────────────────────────────────────────────────────────────────
  [x]  [icon]   12345   Fel-Spotted Egg       0        -        [X]
  [ ]  [icon]   99887   Mark of Honor         0        -        [X]
```

### IO-диалог
```
┌─ Импорт / Экспорт ─────────────────────────────────────────────┐
│ [Экспорт (сжатый)]  [Экспорт (текст)]  [Импортировать]         │
│ ┌────────────────────────────────────────────────────────────┐  │
│ │                                                            │  │
│ │  <поле ввода/вывода>                                       │  │
│ │                                                            │  │
│ └────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────-┘
```

---

## Открытые вопросы (требуют ответа перед реализацией)

1. **Токены** — оставить в категориях или убрать? В mockup 8 категорий (без токенов).
2. **Кнопка-свич** — текст показывает ДРУГОЙ режим (текущая интерпретация) или ТЕКУЩИЙ?
3. **Экспорт из шапки** — одна кнопка «Импорт/Экспорт» открывает диалог, ИЛИ две отдельные?
4. **Переключение режима** — перестраивает панель без закрытия/открытия окна (предпочтительно)
   ИЛИ закрывает и открывает заново (проще реализовать)?
5. **Название колонки «ilvl»** в таблице качества — «ilvl >=» или просто «ilvl»?
