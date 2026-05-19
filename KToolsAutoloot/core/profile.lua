-- KTools_autoloot/core/profile.lua
-- AceDB-3.0: дефолты профиля и доступ к данным.

local DEFAULTS = {
    profile = {
        enabled        = true,

        -- Быстрые категории
        quest          = true,
        gold           = true,
        currency       = true,
        reagents       = false,
        recipes        = false,
        artifact       = false,
        mounts         = false,
        pets           = false,
        tokens         = false,
        bopNoConfirm   = false,
        skinningClose  = false,

        -- Фильтр экипировки по качеству и ilvl
        useQualityFilter = false,
        quality          = 2,   -- 0..5 (Poor..Legendary)
        ilvl             = 0,

        -- Кастомный список предметов
        useList        = false,
        items          = {},  -- [itemID:number] = { active=bool, ilvl=number, name=string }
    },
}

function KToolsLoot:InitDB()
    self.db = LibStub("AceDB-3.0"):New("KToolsLootDB", DEFAULTS, true)
end

function KToolsLoot:Profile()
    return self.db and self.db.profile or nil
end
