-- KTools_autoloot/core/profile.lua
-- AceDB-3.0: дефолты профиля и доступ к данным.

local DEFAULTS = {
    profile = {
        enabled = true,
        mode    = "quick",  -- "quick" | "list"

        -- Категории
        quest    = true,  gold     = true,  currency = true,
        reagents = false, recipes  = false, artifact = false,
        mounts   = false, pets     = false,

        -- Утилиты
        bopNoConfirm  = false,
        skinningClose = false,

        -- Per-quality bind-type фильтр
        -- bindType (Legion 7.x, GetItemInfo pos 14): 0=NoB, 1=BoP, 2=BoE
        -- Ключи: quality_N_<field>, N=0..5 (Poor..Legendary)
        quality_0_enabled=false, quality_0_ilvl=0, quality_0_nob=false, quality_0_boe=false, quality_0_bop=false,
        quality_1_enabled=false, quality_1_ilvl=0, quality_1_nob=true,  quality_1_boe=true,  quality_1_bop=false,
        quality_2_enabled=false, quality_2_ilvl=0, quality_2_nob=true,  quality_2_boe=true,  quality_2_bop=false,
        quality_3_enabled=false, quality_3_ilvl=0, quality_3_nob=true,  quality_3_boe=true,  quality_3_bop=false,
        quality_4_enabled=false, quality_4_ilvl=0, quality_4_nob=true,  quality_4_boe=true,  quality_4_bop=true,
        quality_5_enabled=false, quality_5_ilvl=0, quality_5_nob=true,  quality_5_boe=true,  quality_5_bop=true,

        -- Кастомный список предметов
        items = {},  -- [itemID:number] = { active=bool, ilvl=number, name=string }
    },
}

function KToolsLoot:InitDB()
    self.db = LibStub("AceDB-3.0"):New("KToolsLootDB", DEFAULTS, true)
end

function KToolsLoot:Profile()
    return self.db and self.db.profile or nil
end

-- Accessor для строки фильтра качества q (0..5).
function KToolsLoot:QRow(q)
    local p   = self:Profile()
    local pfx = "quality_" .. q .. "_"
    return {
        enabled = p[pfx .. "enabled"],
        ilvl    = p[pfx .. "ilvl"],
        nob     = p[pfx .. "nob"],
        boe     = p[pfx .. "boe"],
        bop     = p[pfx .. "bop"],
        set     = function(field, val) p[pfx .. field] = val end,
    }
end
