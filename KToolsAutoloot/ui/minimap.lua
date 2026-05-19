-- KTools/ui/minimap.lua
-- Кнопка у миникарты. ЛКМ/ПКМ — открыть/закрыть окно.

local LDB    = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")

function KToolsLoot:SetupMinimap()
    KToolsLootMinimapDB = KToolsLootMinimapDB or { hide = false }

    local broker = LDB:NewDataObject("KToolsLoot", {
        type    = "launcher",
        text    = "KTools Loot",
        icon    = "Interface\\AddOns\\KTools_autoloot\\core\\media\\minimapButton_dx5",
        OnClick = function() KToolsLoot:ToggleWindow() end,
        OnTooltipShow = function(tt)
            tt:AddLine("KTools: Auto Loot")
        end,
    })

    DBIcon:Register("KToolsLoot", broker, KToolsLootMinimapDB)
end
