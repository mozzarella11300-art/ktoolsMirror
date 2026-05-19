-- KTools/minimap.lua
local addonName = ...
local LDB    = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")

function KTools:SetupMinimap()
    local broker = LDB:NewDataObject(addonName, {
        type    = "launcher",
        text    = GetAddOnMetadata(addonName, "Title"),
        icon    = "Interface\\AddOns\\" .. addonName .. "\\media\\textures\\minimapButton_dx5",
        OnClick = function() KTools:ToggleWindow() end,
        OnTooltipShow = function(tt)
            tt:AddLine(GetAddOnMetadata(addonName, "Title"))
        end,
    })
    DBIcon:Register(addonName, broker, KToolsMinimapDB)
end
